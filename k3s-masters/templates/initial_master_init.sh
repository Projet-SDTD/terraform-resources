#! /bin/bash
apt install -y open-iscsi util-linux nfs-common jq
curl https://releases.rancher.com/install-docker/20.10.sh | sh
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
ZONE=$(gcloud compute instances list --filter="name=$${HOSTNAME}" --format "get(zone)" | awk -F/ '{print $NF}')
gcloud compute instances add-tags $HOSTNAME --tags=$HOSTNAME --zone=$ZONE
curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION=v1.24.9+k3s1 sh -s - server \
    --docker \
    --cluster-init \
    --write-kubeconfig-mode 644 \
    --node-label "master=true" \
    --token "${token}" \
    --tls-san "${internal_ip_address}" \
    --tls-san "${external_ip_address}" \
    --tls-san "${external_lb_address}" \
    --node-taint "CriticalAddonsOnly=true:NoExecute" \
    --disable traefik \
    --disable-cloud-controller \
    --disable servicelb \
    --disable metrics-server \
    --disable coredns \
    --prefer-bundled-bin \
    --kubelet-arg cloud-provider=external \
    --kubelet-arg provider-id=gce://${project_id}/$ZONE/$HOSTNAME
