echo "## Applying terraform"
terraform init && terraform apply

echo "## Waiting 1m for cluster creation"
sleep 1m

echo "## Executing ansible"
ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i inventory playbooks/main.yaml