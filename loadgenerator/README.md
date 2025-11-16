# Load Generator

## Initialization
Variables to configure the deployment are defined in the file setup.sh. You can change the the GCP project, the Region, the Zone, the machine type, and the instance name.
If necessary, modify the file and run:

```
source ./setup.sh
```

## Configuring Terraform

It might be necessary to create a service account.

```
gcloud iam service-accounts create [SERVICE_NAME]
gcloud projects add-iam-policy-binding [PROJECT_NAME] --member serviceAccount:[SERVICE_NAME]@[PROJECT_NAME].iam.gserviceaccount.com --role roles/editor
gcloud iam service-accounts keys create ./[SERVICE_NAME].json --iam-account [SERVICE_NAME]@[PROJECT_NAME].iam.gserviceaccount.com
```

## Deployment
Execute the python script:

```
python deploy.py <frontend_ip> <users> <rate>
```

## Connecting through SSH

```
gcloud compute project-info add-metadata --metadata enable-oslogin=TRUE
```

```
gcloud compute os-login ssh-keys add --key-file [PATH_TO_KEY]/[PUB_KEY_FILE] --ttl 0
```

```
ssh -i [PATH_TO_PRIVATE_KEY] [USERNAME]@[EXTERNAL_IP_ADDRESS]
```

USERNAME is your google login where . and @ are replaced with _

## Cleaning
The code in `deploy.py` already destroys the VM, but if necessary it can be destroyed with the following script:

```
python destroy.py
```
