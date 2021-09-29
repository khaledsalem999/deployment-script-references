Vagrant.configure("2") do |config|
  config.vm.define :vpn do |vpn|
    vpn.vm.box = "bento/fedora-31"

    vpn.vm.network "forwarded_port", guest: 22, host: 2223, id: "ssh"
    vpn.ssh.forward_agent = true
    vpn.ssh.guest_port = 22
    vpn.vm.network "private_network", ip: "10.111.10.112"

    vpn.vm.provider "virtualbox" do |v, override|
      v.gui = false
      v.memory = "256"
      v.cpus = 1
    end

    vpn.vm.provider "hyperv" do |v|
      v.gui = false
      v.memory = "256"
      v.cpus = 1
    end

    vpn.vm.provider "parallels" do |v|
      v.memory = "256"
      v.cpus = 1
    end

    vpn.vm.provision "shell", path: "router-fedora-setup.sh", args: "vagrant"
  end

  config.vm.define :skaffold do |skaffold|
    skaffold.vm.box = "bento/ubuntu-18.04"

    skaffold.ssh.forward_agent = true
    skaffold.vm.network "private_network", ip: "10.111.10.111"
    skaffold.vm.synced_folder ".", "/home/vagrant/monorepo"

    skaffold.vm.provider "virtualbox" do |v|
      v.gui = false
      v.memory = "8192"
      v.cpus = 4
    end

    skaffold.vm.provider "hyperv" do |v|
      v.gui = false
      v.memory = "4096"
      v.cpus = 2
    end

    skaffold.vm.provider "parallels" do |v|
      v.memory = "8192"
      v.cpus = 4
    end

    skaffold.vm.provision "shell", path: "linux-ubuntu-setup.sh", args: "vagrant"
  end
end
