Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/xenial64"
  config.vm.provision :shell, privileged: false, path: "util/bootstrap.sh"
  config.vm.synced_folder ".", "/core"
  config.vm.network "forwarded_port", guest: 7777, host: 7777
end
