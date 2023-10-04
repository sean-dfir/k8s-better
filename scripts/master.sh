#!/bin/bash
#
# Setup for Control Plane (Master) servers

set -exo pipefail

NODENAME=$(hostname -s)

sudo kubeadm config images pull

echo "Preflight Check Passed: Downloaded All Required Images"

sudo kubeadm init --apiserver-advertise-address=$CONTROL_IP --apiserver-cert-extra-sans=$CONTROL_IP --pod-network-cidr=$POD_CIDR --service-cidr=$SERVICE_CIDR --node-name "$NODENAME" --ignore-preflight-errors Swap

mkdir -p "$HOME"/.kube
sudo cp -i /etc/kubernetes/admin.conf "$HOME"/.kube/config
sudo chown "$(id -u)":"$(id -g)" "$HOME"/.kube/config

# Save Configs to shared /Vagrant location

# For Vagrant re-runs, check if there is existing configs in the location and delete it for saving new configuration.

config_path="/vagrant/configs"

if [ -d $config_path ]; then
  rm -f $config_path/*
else
  mkdir -p $config_path
fi

cp -i /etc/kubernetes/admin.conf $config_path/config
touch $config_path/join.sh
chmod +x $config_path/join.sh

kubeadm token create --print-join-command > $config_path/join.sh

sudo -i -u vagrant bash << EOF
whoami
mkdir -p /home/vagrant/.kube
sudo cp -i $config_path/config /home/vagrant/.kube/
sudo chown 1000:1000 /home/vagrant/.kube/config
EOF

# Install Helm
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh

# Add and update Cilium Helm repo
helm repo add cilium https://helm.cilium.io
helm repo update

# Install Cilium
helm install cilium cilium/cilium --version ${CILIUM_VERSION}  --namespace kube-system

# Install Tetragon 
helm install tetragon cilium/tetragon --version ${TETRAGON_VERSION} --namespace kube-system
#kubectl rollout status -n kube-system ds/tetragon -w

# Install go
wget -c https://dl.google.com/go/${GO_VERSION}.linux-amd64.tar.gz
sudo tar -xzf ${GO_VERSION}.linux-amd64.tar.gz -C /usr/local
su vagrant
export PATH=$PATH:/usr/local/go/bin
source ~/.profile

# Install Cilium CLI
CILIUM_CLI_VERSION=$(curl -s https://raw.githubusercontent.com/cilium/cilium-cli/main/stable.txt)
CLI_ARCH=amd64
if [ "$(uname -m)" = "aarch64" ]; then CLI_ARCH=arm64; fi
curl -L --fail --remote-name-all https://github.com/cilium/cilium-cli/releases/download/${CILIUM_CLI_VERSION}/cilium-linux-${CLI_ARCH}.tar.gz{,.sha256sum}
sha256sum --check cilium-linux-${CLI_ARCH}.tar.gz.sha256sum
sudo tar xzvfC cilium-linux-${CLI_ARCH}.tar.gz /usr/local/bin
rm cilium-linux-${CLI_ARCH}.tar.gz{,.sha256sum}

# Install Tetra CLI
GOOS=$(go env GOOS)
GOARCH=$(go env GOARCH)
curl -L --remote-name-all https://github.com/cilium/tetragon/releases/latest/download/tetra-${GOOS}-${GOARCH}.tar.gz{,.sha256sum}
sha256sum --check tetra-${GOOS}-${GOARCH}.tar.gz.sha256sum
sudo tar -C /usr/local/bin -xzvf tetra-${GOOS}-${GOARCH}.tar.gz
rm tetra-${GOOS}-${GOARCH}.tar.gz{,.sha256sum}

# Install TracingPolicy for monitoring sys_write syscalls
# More TracingPolicies available at https://github.com/cilium/tetragon/tree/main/examples/tracingpolicy
# kubectl apply -f https://raw.githubusercontent.com/cilium/tetragon/main/examples/tracingpolicy/write.yaml

# Install Demo Applications
kubectl create -f https://raw.githubusercontent.com/cilium/cilium/v1.11/examples/minikube/http-sw-app.yaml
#kubectl create -f https://raw.githubusercontent.com/GoogleCloudPlatform/microservices-demo/main/release/kubernetes-manifests.yaml

# Install Metrics Server

kubectl apply -f https://raw.githubusercontent.com/techiescamp/kubeadm-scripts/main/manifests/metrics-server.yaml

# K8s audit logs notes
# Manual: https://signoz.io/blog/kubernetes-audit-logs/
# Possible kubeadm lead: https://stackoverflow.com/questions/51602458/how-do-i-set-audit-related-flags-on-kubeapi-server-when-using-kubeadm
