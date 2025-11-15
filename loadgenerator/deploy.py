#!/usr/bin/env python3
import os
import subprocess
import time
import sys

def run(cmd, cwd=None):
    subprocess.check_call(cmd, cwd=cwd)

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
    if len(sys.argv) != 4:
        print("Usage: python deploy.py <frontend_ip> <users> <rate>")
        sys.exit(1)

    frontend_ip, users, rate = sys.argv[1], sys.argv[2], sys.argv[3]

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
        "--extra-vars", f"frontend_addr={frontend_ip} users={users} rate={rate}",
        "playbook.yml"
    ], cwd="ansible")

    print(f"Load generator deployed at {ip}")

if __name__ == "__main__":
    main()
