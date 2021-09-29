#!/bin/bash
if [ -z $1 ]
then
    RUN_BY=`who | awk '{print $1}'`
else
    RUN_BY=$1
fi
RUN_BY_HOME=`/bin/bash -c "echo ~$RUN_BY"`
echo "Run by $RUN_BY with home $RUN_BY_HOME"

apt-get update
apt-get install -y software-properties-common

# Install VPN
apt-get install -y openconnect vpnc-scripts

# Install Java
apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 0xB1998361219BD9C9
apt-add-repository 'deb http://repos.azulsystems.com/ubuntu stable main'
sudo apt-get install -y zulu-11 zulu-8

# Install Maven
wget -c https://downloads.apache.org/maven/maven-3/3.6.3/binaries/apache-maven-3.6.3-bin.tar.gz
tar -xzf apache-maven-3.6.3-bin.tar.gz -C /opt/
echo 'export PATH=/opt/apache-maven-3.6.3/bin:$PATH' >> /etc/profile
echo 'export PATH=/opt/apache-maven-3.6.3/bin:$PATH' >> $RUN_BY_HOME/.profile

# Install Ngrok
snap install ngrok

# Add VPNC scripts
mkdir -p /etc/vpnc/pre-init.d
cat << 'EOF' > /etc/vpnc/pre-init.d/banque-misr
#!/bin/bash
echo "pre-init"
EOF
mkdir -p /etc/vpnc/post-connect.d
cat << 'EOF' > /etc/vpnc/post-connect.d/banque-misr
#!/bin/bash
echo "post-connect"
route del -net 0.0.0.0 dev $TUNDEV
route add -net 192.168.0.0/16 dev $TUNDEV
echo "nameserver 8.8.8.8" > /etc/resolve.conf
EOF

# Install Docker
apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg-agent \
    software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"
apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io
usermod -G docker $RUN_BY

mkdir -p /etc/systemd/system/docker.service.d/
cat << EOF > /etc/systemd/system/docker.service.d/override.conf
[Service]
ExecStart=
ExecStart=/usr/bin/dockerd $DOCKER_OPTS
EOF

echo 'DOCKER_OPTS="-H tcp://0.0.0.0:2375 -H unix:///var/run/docker.sock"' > /etc/default/docker
systemctl daemon-reload
echo '{"hosts": ["tcp://0.0.0.0:2375", "unix:///var/run/docker.sock"]}' > /etc/docker/daemon.json
service docker restart

if [[ -f /usr/local/bin/k3s-uninstall.sh ]]; then
    /usr/local/bin/k3s-uninstall.sh
fi

# Install k3s
curl -sfL https://get.k3s.io | sh -s - --docker --no-deploy traefik --write-kubeconfig-mode 644
echo "export KUBECONFIG=/etc/rancher/k3s/k3s.yaml" >> /etc/profile
echo "export KUBECONFIG=/etc/rancher/k3s/k3s.yaml" >> $RUN_BY_HOME/.profile
echo 'Defaults env_keep += "KUBECONFIG"' > /etc/sudoers.d/100_kubeconfig
chmod 666 /etc/rancher/k3s/k3s.yaml

source /etc/profile
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/nginx-0.30.0/deploy/static/mandatory.yaml
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/nginx-0.30.0/deploy/static/provider/cloud-generic.yaml

# Install Skaffold
curl -Lo /usr/local/bin/skaffold https://storage.googleapis.com/skaffold/releases/latest/skaffold-linux-amd64
chmod +x /usr/local/bin/skaffold

# Install ZSH
apt-get install -y zsh
chsh -s /bin/zsh $RUN_BY
ZSH="$RUN_BY_HOME/.oh-my-zsh" sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
cp $RUN_BY_HOME/.oh-my-zsh/templates/zshrc.zsh-template $RUN_BY_HOME/.zshrc
echo "source $RUN_BY_HOME/.profile" >> $RUN_BY_HOME/.zshrc