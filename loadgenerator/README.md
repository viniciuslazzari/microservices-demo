# Load Generator

## Initialization

Variables to configure the deployment are defined in the file `setup.sh`. You can change the GCP project, the Region, the Zone, the machine type, and the instance name.
If necessary, modify the file and run:

```bash
source ./setup.sh
```

## Creating a service account

It might be necessary to create a service account to enable Terraform to allocate resources inside the project.

```bash
gcloud iam service-accounts create [SERVICE_NAME]
gcloud projects add-iam-policy-binding [PROJECT_NAME] \
    --member serviceAccount:[SERVICE_NAME]@[PROJECT_NAME].iam.gserviceaccount.com \
    --role roles/editor
gcloud iam service-accounts keys create ./[SERVICE_NAME].json \
    --iam-account [SERVICE_NAME]@[PROJECT_NAME].iam.gserviceaccount.com
```


Set Google Cloud credentials for Terraform and scripts:

```bash
export GOOGLE_APPLICATION_CREDENTIALS="/full/path/to/[SERVICE_NAME].json"
```

## Deployment

Execute the Python deployment script to automatically provision a VM, start the load generator, collect results, and destroy the VM afterwards.

```bash
python deploy.py <frontend_ip> <nb_users> <rate> [run_time] [csv_prefix]
```

## Connecting through SSH

Enable OS Login:

```bash
gcloud compute project-info add-metadata --metadata enable-oslogin=TRUE
```

Add your SSH key:

```bash
gcloud compute os-login ssh-keys add --key-file [PATH_TO_KEY]/[PUB_KEY_FILE] --ttl 0
```

Connect to the VM:
- `USERNAME` is your Google login where `.` and `@` are replaced with `_`.

```bash
ssh -i [PATH_TO_PRIVATE_KEY] [USERNAME]@[EXTERNAL_IP_ADDRESS]
```

## Cleaning

The code in `deploy.py` already destroys the VM, but if necessary it can be destroyed with the following script:

```bash
python destroy.py
```
