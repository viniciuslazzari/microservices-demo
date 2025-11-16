#!/bin/bash


### Main variables


# User ID on GCP
# export GCP_userID="XXXX"

# Private key to use to connect to GCP
# export GCP_privateKeyFile="XXXX"

# ID of your GCP project
export TF_VAR_project="cloudcomputing-478119"

# Name of your selected GCP region
export TF_VAR_region="europe-west6"

# Name of your selected GCP zone
export TF_VAR_zone="europe-west6-a"



### Other variables used by Terraform

# Number of VMs created
# export TF_VAR_machineCount=1

# VM type
export TF_VAR_machine_type="e2-medium"

# Prefix for you VM instances
export TF_VAR_instance_name="loadgenerator"

# Prefix of your GCP deployment key
# export TF_VAR_deployKeyName="deployment-key.json"
