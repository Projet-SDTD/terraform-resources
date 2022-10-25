#! /bin/bash
curl https://releases.rancher.com/install-docker/20.10.sh | sh
RDM_STR=$(cat /dev/random | tr -dc '[:alpha:]' | fold -w $${1:-15} | head -n 1)
ZONE=$(gcloud compute instances list --filter="name=$${HOSTNAME}" --format "get(zone)" | awk -F/ '{print $NF}')
gcloud compute instances add-tags $HOSTNAME --tags=$HOSTNAME --zone=$ZONE
curl -sfL https://get.k3s.io | K3S_TOKEN="${token}" K3S_URL="https://${server_address}:6443" sh -s - agent \
    --docker \
    --kubelet-arg cloud-provider=external \
    --kubelet-arg provider-id=gce://${project_id}/$ZONE/$HOSTNAME