#! /bin/bash
curl https://releases.rancher.com/install-docker/20.10.sh | sh
curl -sfL https://get.k3s.io | sh -s - server \
    --docker \
    --cluster-init \
    --write-kubeconfig-mode 644 \
    --token "${token}" \
    --tls-san "${internal_ip_address}" \
    --tls-san "${external_ip_address}" \
    --node-taint "CriticalAddonsOnly=true:NoExecute" \
    --disable traefik
