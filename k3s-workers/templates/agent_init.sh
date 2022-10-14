#! /bin/bash

curl -sfL https://get.k3s.io | K3S_TOKEN="${token}" K3S_URL="https://${server_address}:6443" sh -s -