#!/bin/bash
hostnamectl set-hostname --static "$(curl -s http://169.254.169.254/latest/meta-data/local-hostname)"

export DEBIAN_FRONTEND=noninteractive

#
# Install soft
#
apt-get update

# utils
apt-get install -y \
  apt-transport-https \
  ca-certificates curl \
  gnupg2 \
  software-properties-common \
  wget

# kube
curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | \
  tee /etc/apt/sources.list.d/kubernetes.list
apt-get update
apt-get install -y kubelet kubeadm kubectl
apt-mark hold kubelet kubeadm kubectl

# docker runtime
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt update
sudo apt install -y containerd.io docker-ce docker-ce-cli

# Set up node
swapoff -a

modprobe overlay
modprobe br_netfilter

tee /etc/sysctl.d/kubernetes.conf<<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF
sysctl --system

sudo mkdir -p /etc/systemd/system/docker.service.d
sudo tee /etc/docker/daemon.json <<EOF
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2"
}
EOF
sudo systemctl daemon-reload
sudo systemctl restart docker
sudo systemctl enable docker

tee /etc/modules-load.d/k8s.conf <<EOF
overlay
br_netfilter
EOF

modprobe overlay
modprobe br_netfilter

sudo tee /etc/sysctl.d/kubernetes.conf<<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF

wget https://github.com/Mirantis/cri-dockerd/releases/download/v0.2.6/cri-dockerd_0.2.6.3-0.ubuntu-jammy_amd64.deb
dpkg -i cri-dockerd_0.2.6.3-0.ubuntu-jammy_amd64.deb
rm -f cri-dockerd_0.2.6.3-0.ubuntu-jammy_amd64.deb
systemctl daemon-reload
systemctl enable cri-docker.service
systemctl enable --now cri-docker.socket


# init control plane
metadata="http://169.254.169.254/latest/meta-data"
mac=$(curl -s $metadata/network/interfaces/macs/ | head -n1 | tr -d '/')
cidr=$(curl -s "$metadata/network/interfaces/macs/$mac/subnet-ipv4-cidr-block")
public_ipv4=$(curl -s "$metadata/public-ipv4")
local_ipv4=$(curl -s "$metadata/local-ipv4")
kubeadm init \
  --pod-network-cidr="$cidr" \
  --apiserver-cert-extra-sans="$public_ipv4" \
  --cri-socket /run/cri-dockerd.sock \
  --control-plane-endpoint="$local_ipv4"

mkdir -p "$HOME/.kube"
cp -i /etc/kubernetes/admin.conf "$HOME/.kube/config"
chown "$(id -u):$(id -g)" "$HOME/.kube/config"
export KUBECONFIG=/etc/kubernetes/admin.conf
echo "KUBECONFIG=/etc/kubernetes/admin.conf" >> /etc/environment

wget https://raw.githubusercontent.com/flannel-io/flannel/master/Documentation/kube-flannel.yml
sed -i -e "s/10.244.0.0\/16/${cidr//\//\\\/}/g" kube-flannel.yml
kubectl apply -f kube-flannel.yml
rm -f kube-flannel.yml
