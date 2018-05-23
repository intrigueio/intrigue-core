Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/xenial64"

  config.vm.define "intrigue-core" do |x|

    x.vm.provision :shell, privileged: false, path: "util/bootstrap.sh"
    x.vm.synced_folder ".", "/core"
    x.vm.hostname = "intrigue-core"
    x.vm.network :private_network, ip: "10.0.0.10"
    x.vm.network "forwarded_port", guest: 7777, host: 7777

    x.vm.provider :virtualbox do |vb|
      vb.name = "core-dev"
      vb.memory = 2048
      vb.cpus = 2
    end

  end

end
