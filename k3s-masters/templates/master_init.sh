#! /bin/bash
curl https://releases.rancher.com/install-docker/20.10.sh | sh
RDM_STR=$(cat /dev/random | tr -dc '[:alpha:]' | fold -w $${1:-15} | head -n 1)
curl -sfL https://get.k3s.io | sh -s - server \
    --docker \
    --server "https://${main_master_ip}:6443" \
    --write-kubeconfig-mode 644 \
    --token "${token}" \
    --disable traefik \
    --node-name "$${HOSTNAME}-$${RDM_STR}"
