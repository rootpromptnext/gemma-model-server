#!/bin/bash
set -e

echo "[Step 1] Updating system packages..."
sudo apt-get update -y
sudo apt-get upgrade -y

echo "[Step 2] Installing MicroK8s..."
sudo snap install microk8s --classic

echo "[Step 3] Adding current user to microk8s group..."
sudo usermod -a -G microk8s $USER
sudo chown -f -R $USER ~/.kube

echo "[Step 4] Enabling common addons (DNS, storage, ingress)..."
microk8s enable dns storage ingress

echo "[Step 5] Setting up kubectl alias..."
echo "alias kubectl='microk8s kubectl'" >> ~/.bashrc
source ~/.bashrc

echo "[Step 6] Checking cluster status..."
microk8s status --wait-ready

echo "[Step 7] Verifying nodes and pods..."
microk8s kubectl get nodes
microk8s kubectl get pods -A

echo "✅ MicroK8s installation complete!"
