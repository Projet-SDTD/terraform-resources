# Terraform Resources

This repo contains all the terraform files needed to deploy the SDTD infrastructure in GCP.

TODO : Better documentation/graphs for usage

# How to use

## Prerequisites

In order to use the files, you must have a few things before :
- terraform installed and a valid gcp account.
- enable the 'Compute Engine API', 'Cloud Logging API', 'Identity Access Management' and 'Cloud Resource Manager API' in google compute APIs (https://console.cloud.google.com/apis/api/compute.googleapis.com/)
- create a dedicated service account with Editor rights (https://console.cloud.google.com/iam-admin/serviceaccounts)
- create and download a key for your service account : click on the service account, go to 'key' tab and click 'create key' and the 'json key'. Then rename the file 'credentials.json' and copy it to this folder.
- Retrieve the ID of the project in gcp (example : red-apple-354022)
- Create a ssh key (that you will use to connect to VMs when created) and copy the public key to this folder with the name 'terraform_key.pub'
- Copy the file 'main.example.tfvars' to 'main.auto.tfvars'
- Fill the file 'main.auto.tfvars' with the relevant informations : the project ID and the username you want to use along with the public ssh key.

## Usage

Once everything is configured, you can run `terraform init` in the folder to initialize the terraform plugins (gcp).

Once initialization completes, you can run `terraform apply` and say 'yes' when asked to confirm. This will create the infrastructure in you gcp project.

Don't forget to destroy the infrastructure with `terraform destroy` when you are done playing with it (otherwise you will spend gcp credits).