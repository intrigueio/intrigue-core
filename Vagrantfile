Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/focal64"

  config.vm.define "intrigue-core" do |x|

    # install all deps 
    x.vm.provision :shell, privileged: false, path: "util/bootstrap.sh"

    # run setup and start the service
    x.vm.provision "shell", privileged: false, inline: <<-SHELL
      cd /home/ubuntu/core
      sudo -u postgres createuser intrigue -s
      sudo -u postgres createdb intrigue_dev
      bundle install
      bundle exec rake setup
      bundle exec rake db:migrate
      rbenv rehash
      foreman start
    SHELL
 
    x.vm.synced_folder ".", "/home/ubuntu/core"
    x.vm.hostname = "intrigue-core"
    x.vm.network :private_network, ip: "10.0.0.10"
    x.vm.network "forwarded_port", guest: 7777, host: 7777

    x.vm.provider :virtualbox do |vb|
      vb.name = "core-dev"
      vb.memory = 8096
      vb.cpus = 2
    end

end

end
