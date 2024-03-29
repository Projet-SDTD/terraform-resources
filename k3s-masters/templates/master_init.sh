#! /bin/bash
apt install -y open-iscsi util-linux nfs-common jq
curl https://releases.rancher.com/install-docker/20.10.sh | sh
ZONE=$(gcloud compute instances list --filter="name=$${HOSTNAME}" --format "get(zone)" | awk -F/ '{print $NF}')
gcloud compute instances add-tags $HOSTNAME --tags=$HOSTNAME --zone=$ZONE
sleep $((RANDOM % 20))
curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION=v1.24.9+k3s1 sh -s - server \
    --docker \
    --server "https://${main_master_ip}:6443" \
    --node-label "master=true" \
    --write-kubeconfig-mode 644 \
    --token "${token}" \
    --prefer-bundled-bin \
    --disable traefik \
    --disable-cloud-controller \
    --disable servicelb \
    --disable metrics-server \
    --disable coredns \
    --kubelet-arg cloud-provider=external \
    --kubelet-arg provider-id=gce://${project_id}/$ZONE/$HOSTNAME
