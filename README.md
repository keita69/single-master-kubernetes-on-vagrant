# single-master-kubernetes-on-vagrant
create kubernetes cluseter on vagrant with single master-node and multi worker-node 

Vagrant で作成した仮想マシンに Kubernetes 環境を kubeadm を使用して構築します。
- 参考URL
https://github.com/mmumshad/kubernetes-the-hard-way

# 環境
- Master Node x 1 (CPU:x2 MEM:4096MB)
- Worker Node x 1 (CPU:x2 MEM:2048MB)

# Quick Start
## A. Create Virtual Machine on VirtualBox :computer:
```
# ---------------------------------------- 
# 1. Create Virtual Machine
# ---------------------------------------- 
git clone https://github.com/keita69/single-master-kubernetes-on-vagrant.git
cd single-master-kubernetes-on-vagrant/vagrant
vagrant up

```

#### clear files
```
rm -rf ~/VirtualBox\ VMs ; rm -rf ~/.vagrant.d ; rm -rf ; rm -rf ~/.VirtualBox ; rm -rf ./.vagrant
```

## B. setup kubernetes at Master & Worker Node :crown::man_office_worker:
### - [ ] Copy & Paste at Master & Worker Node
```
# ---------------------------------------- 
# 2. Installing runtime (containerd)
# ---------------------------------------- 

# https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/#installing-runtime

# https://kubernetes.io/docs/setup/production-environment/container-runtimes/#containerd

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

sleep 3
# Apply sysctl params without reboot
sudo sysctl --system
sleep 3

# 1. Install the containerd.io package 
sudo apt-get update
sudo apt-get install \
   ca-certificates \
   curl \
   gnupg \
   lsb-release
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --yes --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
sleep 3
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sleep 3
sudo apt-get update
sudo apt-get install containerd.io

```
### - [ ] Copy & Paste at Master & Worker Node
```
# ---------------------------------------- 
# 3. Installing kubeadm, kubelet and kubectl
# ---------------------------------------- 
# https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/#installing-kubeadm-kubelet-and-kubectl

sudo apt-get update
sleep 3
sudo apt-get install -y apt-transport-https ca-certificates curl

```
### - [ ] Copy & Paste at Master & Worker Node
```
sudo curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl
kubectl version

```

### - [ ] Copy & Paste at Master & Worker Node
```
# ---------------------------------------- 
# 4. set up containerd at Master & Worker Node 
# ---------------------------------------- 

sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml

sudo systemctl restart containerd

# edit by sed command.  
#   sudo vi /etc/containerd/config.toml
#   # [plugins."io.containerd.grpc.v0.cri".containerd.runtimes.runc]
#   #   ...
#   #   [plugins."io.containerd.grpc.v0.cri".containerd.runtimes.runc.options]
#   #     SystemdCgroup = true
sudo sed -i -e "/.containerd.runtimes.runc.options/a \
            SystemdCgroup = true" /etc/containerd/config.toml

sudo systemctl restart containerd


# 2. Configure containerd:
sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml

# 3. Restart containerd:
sudo systemctl restart containerd

```

## C. execute "kubeadm init" command at Master Node :crown:
### - [ ] Copy & Paste at Master Node
```
# ---------------------------------------- 
# 4. execute "kubeadm init" command at Master Node 
# ---------------------------------------- 

sudo kubeadm init \
--apiserver-advertise-address=192.168.5.11 \
--control-plane-endpoint=192.168.5.11 \
--pod-network-cidr=10.32.0.0/12

```

## D. Execute "kubeadm join" command at Worker Node :man_office_worker:
### - [ ] Copy & Paste at Worker Node
```
# ---------------------------------------- 
# 5. kubeadm join
# ---------------------------------------- 
# output of kubeadm join
# ex) sudo kubeadm join 192.168.5.11:6443 --token n37vrm.1ln4nzo7jnvsmgfb \
#       --discovery-token-ca-cert-hash sha256:3dcdff8........

```


## E. set kubectl config at Master Node :crown:
### - [ ] Copy & Paste at Master Node
```
# ---------------------------------------- 
# 6. set kubectl config
# ---------------------------------------- 
mkdir -p $HOME/.kube
sudo cp /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
export KUBECONFIG=$HOME/.kube/config

source <(kubectl completion bash) # setup autocomplete in bash into the current shell, bash-completion package should be installed first.
echo "source <(kubectl completion bash)" >> ~/.bashrc # add autocomplete permanently to your bash shell.

alias k=kubectl
complete -F __start_kubectl k



# ---------------------------------------- 
# 7. install weave net (Integrating Kubernetes via the Addon)
# ---------------------------------------- 

# https://www.weave.works/docs/net/latest/kubernetes/kube-addon/#-installation

sudo bash
kubectl apply -f "https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d '\n')"
exit


# ---------------------------------------- 
# 8. install helm
# ---------------------------------------- 
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh


# ---------------------------------------- 
# 9. install nginx-ingress 
# ---------------------------------------- 
# pattern 1
# helm upgrade --install ingress-nginx ingress-nginx \
#   --repo https://kubernetes.github.io/ingress-nginx \
#   --namespace ingress-nginx --create-namespace \
#   --set controller.service.externalIPs={192.168.5.21} 
  
# # pattern 2
# helm repo add bitnami https://charts.bitnami.com/bitnami
# helm install ingress-nginx bitnami/nginx-ingress-controller \
#   --namespace ingress-nginx --create-namespace \
#   --set controller.service.externalIPs={192.168.5.21} 

# pattern 3  (https://docs.nginx.com/nginx-ingress-controller/installation/installation-with-helm/)
helm repo add nginx-stable https://helm.nginx.com/stable
helm repo update
helm install my-ingress nginx-stable/nginx-ingress \
  --namespace ingress-nginx --create-namespace \
  --set controller.service.loadBalancerIP=192.168.5.21 \
  --set controller.service.externalIPs={192.168.5.21} 

```


## F. set up rook at Master Node :crown:
### - [ ] Copy & Paste at Master Node

```
# ---------------------------------------- 
# 10. set up rook
# ---------------------------------------- 
# https://rook.io/docs/rook/v1.7/quickstart.html#tldr

git clone --single-branch --branch v1.7.8 https://github.com/rook/rook.git
cd rook/cluster/examples/kubernetes/ceph
kubectl create -f crds.yaml -f common.yaml -f operator.yaml
kubectl create -f cluster-test.yaml
kubectl get pod -n rook-ceph -w

```

## G. check status of ceph at Master Node :crown:
### - [ ] Copy & Paste at Master Node
```
# ---------------------------------------- 
# 11. ceph toolbox
# ---------------------------------------- 
kubectl apply -f toolbox.yaml
sleep 3
kubectl get pod -n rook-ceph
ROOK_POD_ID=$(kubectl get pod -n rook-ceph | grep rook-ceph-tools |cut -d' ' -f 1)
kubectl exec -it -n rook-ceph $ROOK_POD_ID -- ceph status

```


## H. set up ceph dashboard at Master Node :crown:
```
# create self-signed certificate
touch $HOME/.rnd
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -out rook-ceph-ingress-tls.crt \
    -keyout rook-ceph-ingress-tls.key \
    -subj "/CN=rook-ceph.example.com"

# create tls seclet
kubectl -n rook-ceph create secret tls --save-config rook-ceph.example.com --key rook-ceph-ingress-tls.key --cert rook-ceph-ingress-tls.crt

# create ingress resouce
sed -i 's/https-dashboard/http-dashboard/' dashboard-ingress-https.yaml
# required "spec.rolues.host"
kubectl apply -f dashboard-ingress-https.yaml

# check
curl https://192.168.5.21 -H "HOST: rook-ceph.example.com"

# '==========================================================================='
# '==========================================================================='
#    When you access ceph-dashboard by your blowser, 
#    add "192.168.5.21   rook-ceph.example.com" in hosts file of your PC '
# '==========================================================================='
# '==========================================================================='

# get password (user name: admin)
kubectl -n rook-ceph get secret rook-ceph-dashboard-password -o jsonpath="{['data']['password']}" | base64 --decode && echo

```

## 試したいこと
### - [ ] 共有ファイル NFS
https://rook.io/docs/rook/v1.7/ceph-filesystem.html
### - [ ] ブロックストレージ
https://rook.io/docs/rook/v1.7/ceph-block.html
### - [ ] オブジェクトストレージ (ノードが３つ必要)
https://rook.io/docs/rook/v1.7/ceph-object.html




## Zabbix helm 動作検証
https://github.com/cetic/helm-zabbix (非公式)

### NFSサーバ作成
https://www.digitalocean.com/community/tutorials/how-to-set-up-an-nfs-mount-on-ubuntu-20-04-ja


### provisioner 作成

#### storageclass "example-nfs" 作成

```
git clone https://github.com/kubernetes-sigs/nfs-ganesha-server-and-external-provisioner.git
cd nfs-ganesha-server-and-external-provisioner

# Choose a provisioner name for a StorageClass to specify and set it in deploy/kubernetes/deployment.yaml (L:108)  
# default provisioner name is "example.com/nfs"
kubectl create -f deploy/kubernetes/deployment.yaml

kubectl create -f deploy/kubernetes/rbac.yaml

# Create a StorageClass named "example-nfs" with provisioner: example.com/nfs.
kubectl create -f deploy/kubernetes/class.yaml

```

```
cat << EOF | kubectl apply -f -
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name:  data-zabbix-postgresql-0
  namespace: monitoring
spec:
  storageClassName: example-nfs
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 1Mi
EOF

```



# Istio Install (demo App)
```
cd
curl -L https://istio.io/downloadIstio | sh -
cd $(ls -d istio-*)
export PATH=$PWD/bin:$PATH

# demo profile
istioctl install --set profile=demo -y

kubectl label namespace default istio-injection=enabled

kubectl apply -f samples/bookinfo/platform/kube/bookinfo.yaml

sleep 60

kubectl get services
kubectl get pods
kubectl exec "$(kubectl get pod -l app=ratings -o jsonpath='{.items[0].metadata.name}')" -c ratings -- curl -sS productpage:9080/productpage | grep -o "<title>.*</title>"
 
kubectl apply -f samples/bookinfo/networking/bookinfo-gateway.yaml

```
