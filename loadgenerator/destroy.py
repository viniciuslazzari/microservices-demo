#!/usr/bin/env python3
import subprocess
import os

def run(cmd, cwd=None):
    subprocess.check_call(cmd, cwd=cwd)

def main():
    terraform_dir = "terraform"

    if not os.path.exists(f"{terraform_dir}/terraform.tfstate"):
        print("No VM deployed")
        return

    # Read public key (same as deploy script)
    if os.path.exists("keys/id_rsa.pub"):
        with open("keys/id_rsa.pub") as f:
            public_key = f.read().strip()
    else:
        public_key = "dummy"

    # Destroy VM with same variables as deploy
    run([
        "terraform", "destroy", "-auto-approve",
        f"-var=public_key={public_key}"
    ], cwd=terraform_dir)

    print("VM destroyed")

if __name__ == "__main__":
    main()

