#!/usr/bin/env python3
import os
import subprocess
import time
import sys

def run(cmd, cwd=None):
    subprocess.check_call(cmd, cwd=cwd)


def run_quiet(cmd, cwd=None):
    """Run a command and suppress stdout/stderr, but raise on error."""
    try:
        subprocess.run(cmd, cwd=cwd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=True)
    except subprocess.CalledProcessError as e:
        raise

def wait_for_ssh(ip):
    while True:
        ret = subprocess.call(
            ["ssh", "-o", "StrictHostKeyChecking=no", "-o", "ConnectTimeout=5",
             "-i", "keys/id_rsa", f"ubuntu@{ip}", "true"],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL
        )
        if ret == 0:
            return
        time.sleep(3)

def main():
    if len(sys.argv) not in (4, 5, 6):
        print("Usage: python deploy.py <frontend_ip> <users> <rate> [run_time] [csv_prefix]")
        print("  run_time example: 10m, 30s (optional, default: 10m)")
        print("  csv_prefix example: run1 (optional, default: run)")
        sys.exit(1)

    frontend_ip, users, rate = sys.argv[1], sys.argv[2], sys.argv[3]
    run_time = sys.argv[4] if len(sys.argv) >= 5 else "10m"
    csv_prefix = sys.argv[5] if len(sys.argv) == 6 else "run"

    # Setup SSH key
    os.makedirs("keys", exist_ok=True)
    if not os.path.exists("keys/id_rsa"):
        run(["ssh-keygen", "-t", "rsa", "-f", "keys/id_rsa", "-N", ""])

    with open("keys/id_rsa.pub") as f:
        public_key = f.read().strip()

    # Deploy VM
    run(["terraform", "init"], cwd="terraform")
    run([
        "terraform", "apply", "-auto-approve",
        f"-var=public_key={public_key}",
        "-var=project=cloudcomputing-478315",
        "-var=region=europe-west6",
        "-var=zone=europe-west6-a"
    ], cwd="terraform")

    # Get VM IP
    ip = subprocess.check_output(
        ["terraform", "output", "-raw", "loadgenerator_ip"],
        cwd="terraform"
    ).decode().strip()

    # Configure Ansible
    with open("ansible/inventory.ini", "w") as f:
        f.write(
            f"[loadgen]\n{ip} ansible_user=ubuntu "
            f"ansible_private_key_file=../keys/id_rsa "
            f"ansible_ssh_common_args='-o StrictHostKeyChecking=no'\n"
        )

    wait_for_ssh(ip)

    # Deploy load generator
    run([
        "ansible-playbook",
        "-i", "inventory.ini",
        "--extra-vars", f"frontend_addr={frontend_ip} users={users} rate={rate} time={run_time}",
        "playbook.yml"
    ], cwd="ansible")

    # Run Locust headless on the remote VM and collect CSVs
    print("Running Locust headless on remote VM...")
    remote_cmd = (
        "mkdir -p ~/locust_results && sudo docker rm -f locust-run || true && "
        "sudo docker run --rm --name locust-run -v ~/locust_results:/results "
        "--entrypoint locust locust-loadgen "
        f"-f /loadgen/locustfile.py --headless -u {users} -r {rate} --run-time {run_time} "
        f"--csv /results/{csv_prefix} --host=\"http://{frontend_ip}\""
    )

    # Execute remote command (will block until Locust run completes)
    print("Starting remote Locust run (headless). I will wait until it finishes...")
    try:
        # Execute remote command quietly (no real-time logs shown)
        run_quiet(["ssh", "-i", "keys/id_rsa", "-o", "StrictHostKeyChecking=no", f"ubuntu@{ip}", remote_cmd])
    except subprocess.CalledProcessError:
        print("Remote Locust run failed. Check the VM logs for details.")
        # Attempt to continue to collect whatever results are present

    # Create local results folder and copy CSVs from remote (quietly)
    local_results_dir = os.path.join("results", csv_prefix)
    os.makedirs(local_results_dir, exist_ok=True)
    remote_pattern = f"ubuntu@{ip}:/home/ubuntu/locust_results/{csv_prefix}_*.csv"
    print("Collecting CSV results from remote VM...")
    try:
        run_quiet(["scp", "-i", "keys/id_rsa", "-o", "StrictHostKeyChecking=no", remote_pattern, local_results_dir])
    except subprocess.CalledProcessError:
        print("Failed to copy results via scp. Check remote path and permissions.")
    else:
        print(f"Results copied to {local_results_dir}")

    # Destroy the VM to clean up
    print("Destroying remote VM via Terraform...")
    try:
        run([
            "terraform", "destroy", "-auto-approve",
            f"-var=public_key={public_key}",
            "-var=project=cloudcomputing-478315",
            "-var=region=europe-west6",
            "-var=zone=europe-west6-a"
        ], cwd="terraform")
    except subprocess.CalledProcessError:
        print("Terraform destroy failed. You may need to remove the VM manually.")
    else:
        print("Remote VM destroyed.")

if __name__ == "__main__":
    main()
