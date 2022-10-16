#! /bin/bash
sudo apt update && sudo apt upgrade
curl -sfL https://get.k3s.io | sh -s - server \
    --cluster-init \
    --write-kubeconfig-mode 644 \
    --token "${token}" \
    --tls-san "${internal_ip_address}" \
    --tls-san "${external_ip_address}" \
    --node-taint "CriticalAddonsOnly=true:NoExecute" \
    --disable traefik \
    --with-node-id

# cat > /root/script.py <<- EOM
# #!/bin/python3
# import subprocess
# t = subprocess.run(["kubectl", "get", "nodes"], capture_output=True).stdout.decode().split("\n")
# name = []
# for i in range(1, len(t)):
#     currw = [w for w in t[i].split() if w != '']
#     if len(currw) == 5:
#         if currw[1] != 'Ready' and ('m' in currw[3] or ('s' in currw[3] and int(currw[3][:len(currw[3])-1])) >= 30):
#             name.append(currw[0])
# for n in name:
#     subprocess.run(["kubectl", "delete", "node", n])
# EOM

# #write out current crontab
# crontab -l > /root/mycron
# #echo new cron into cron file
# echo "* * * * * python3 /root/script.py" >> /root/mycron
# #install new cron file
# crontab /root/mycron
# rm /root/mycron