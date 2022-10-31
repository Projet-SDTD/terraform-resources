#! /bin/bash
curl https://releases.rancher.com/install-docker/20.10.sh | sh
ZONE=$(gcloud compute instances list --filter="name=$${HOSTNAME}" --format "get(zone)" | awk -F/ '{print $NF}')
gcloud compute instances add-tags $HOSTNAME --tags=$HOSTNAME --zone=$ZONE
curl -sfL https://get.k3s.io | sh -s - server \
    --docker \
    --cluster-init \
    --write-kubeconfig-mode 644 \
    --token "${token}" \
    --tls-san "${internal_ip_address}" \
    --tls-san "${external_ip_address}" \
    --node-taint "CriticalAddonsOnly=true:NoExecute" \
    --disable traefik \
    --disable-cloud-controller \
    --disable servicelb \
    --disable metrics-server \
    --disable coredns \
    --kubelet-arg cloud-provider=external \
    --kubelet-arg provider-id=gce://${project_id}/$ZONE/$HOSTNAME
