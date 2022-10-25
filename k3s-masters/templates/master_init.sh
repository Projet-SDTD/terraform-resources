#! /bin/bash
#     --node-name "$${HOSTNAME}-$${RDM_STR}" \
curl https://releases.rancher.com/install-docker/20.10.sh | sh
RDM_STR=$(cat /dev/random | tr -dc '[:alpha:]' | fold -w $${1:-15} | head -n 1)
ZONE=$(gcloud compute instances list --filter="name=$${HOSTNAME}" --format "get(zone)" | awk -F/ '{print $NF}')
gcloud compute instances add-tags $HOSTNAME --tags=$HOSTNAME --zone=$ZONE
curl -sfL https://get.k3s.io | sh -s - server \
    --docker \
    --server "https://${main_master_ip}:6443" \
    --write-kubeconfig-mode 644 \
    --token "${token}" \
    --disable traefik \
    --disable-cloud-controller \
    --no-deploy servicelb \
    --no-deploy metrics-server \
    --kubelet-arg cloud-provider=external \
    --kubelet-arg provider-id=gce://${project_id}/$ZONE/$HOSTNAME
