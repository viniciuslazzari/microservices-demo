#!/usr/bin/env python3
import os
import subprocess
import time
import sys

def run(cmd, cwd=None):
    print(f"Running: {' '.join(cmd)}")
    subprocess.check_call(cmd, cwd=cwd)

def wait_for_ssh(ip):
    print("Waiting for SSH to become available...")
    while True:
        ret = subprocess.call(["ssh", "-o", "StrictHostKeyChecking=no",
                               "-i", "keys/id_rsa", f"ubuntu@{ip}", "true"],
                               stdout=subprocess.DEVNULL,
                               stderr=subprocess.DEVNULL)
        if ret == 0:
            print("SSH is ready!")
            return
        time.sleep(3)

def main():
    if len(sys.argv) != 4:
        print("Usage: python deploy.py <frontend_ip> <users> <rate>")
        sys.exit(1)

    frontend_ip = sys.argv[1]
    users = sys.argv[2]
    rate = sys.argv[3]

    # Create SSH key pair
    os.makedirs("keys", exist_ok=True)
    if not os.path.exists("keys/id_rsa"):
        print("Generating SSH key...")
        run(["ssh-keygen", "-t", "rsa", "-f", "keys/id_rsa", "-N", ""])

    # Read public key content
    with open("keys/id_rsa.pub") as f:
        public_key = f.read().strip()

    # Run Terraform with public key content
    print("Deploying VM with Terraform...")
    run([
        "terraform", "init"
    ], cwd="terraform")

    run([
        "terraform", "apply", "-auto-approve",
        f"-var=public_key={public_key}",
        "-var=project=cloudcomputing-478315",
        "-var=region=europe-west6",
        "-var=zone=europe-west6-a"
    ], cwd="terraform")

    # Get IP from Terraform
    ip = subprocess.check_output(
        ["terraform", "output", "-raw", "loadgenerator_ip"], cwd="terraform"
    ).decode().strip()

    print(f"VM IP: {ip}")

    # Patch Ansible inventory
    with open("ansible/inventory.ini", "w") as f:
        f.write(f"[loadgen]\n{ip} ansible_user=ubuntu "
                f"ansible_private_key_file=../keys/id_rsa "
                f"ansible_ssh_common_args='-o StrictHostKeyChecking=no'\n")

    wait_for_ssh(ip)

    print("Running Ansible playbook...")
    run([
        "ansible-playbook",
        "-i", "inventory.ini",
        "--extra-vars", f"frontend_ip={frontend_ip} users={users} rate={rate}",
        "playbook.yml"
    ], cwd="ansible")

    print("\n🚀 Deployment completed successfully!")
    print(f"Load generator running at VM: {ip}")

if __name__ == "__main__":
    main()
