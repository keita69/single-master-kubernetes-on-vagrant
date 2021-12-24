sudo apt-get update
sudo apt-get install \
   ca-certificates \
   curl \
   gnupg \
   lsb-release
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --yes --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install containerd.io

sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml

sudo systemctl restart containerd

# edit by sed command.  
#   sudo vi /etc/containerd/config.toml
#   # [plugins."io.containerd.grpc.v0.cri".containerd.runtimes.runc]
#   #   ...
#   #   [plugins."io.containerd.grpc.v0.cri".containerd.runtimes.runc.options]
#   #     SystemdCgroup = true
sudo sed -i -e "/.containerd.runtimes.runc.options/a \            SystemdCgroup = true" /etc/containerd/config.toml

sudo systemctl restart containerd

# containerd 
# This section contains the necessary steps to use containerd as CRI runtime.
# Use the following commands to install Containerd on your system:

# Install and configure prerequisites:
cat <<EOF | sudo tee /etc/modules-load.d/containerd.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

# Setup required sysctl params, these persist across reboots.
cat <<EOF | sudo tee /etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF

# Apply sysctl params without reboot
sudo sysctl --system
