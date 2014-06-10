# -*- mode: ruby -*-
# # vi: set ft=ruby :
#

class Imelbox
  def Imelbox.configure(config,settings)
    #Configure the Box
    config.vm.box = "ibx-wheezy64_vb"
    config.vm.box_url = "http://gt-adminsys.s3.amazonaws.com/box/ibx-wheezy64_vb.box"
    config.ssh.shell = "bash -s"

#    server_ip = settings["ip"] ||= "192.168.10.10"

    #Configure A private Network
    #config.vm.network :private_network, ip: settings["ip"] ||= "192.168.10.10"

    # Configure A Few VmWare-Fusion Settings
    config.vm.provider "vmware_fusion" do |v, override|
      override.vm.box = "wheezy"
      override.vm.box_url = "http://vbox.imelbox.com.s3.amazonaws.com/vagrant-debian71-x64.box"
      v.vmx["memsize"] = settings["memory"] ||= "2048"
      v.vmx["numvcpus"] = settings["cpus"] ||= "1"
    end

    # Configure A Few VirtualBox Settings
    config.vm.provider "virtualbox" do |vb|
      vb.customize ["modifyvm", :id, "--memory", settings["memory"] ||= "2048"]
      vb.customize ["modifyvm", :id, "--cpus", settings["cpus"] ||= "1"]
      vb.customize ["modifyvm", :id, "--natdnsproxy1", "on"]
      vb.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
    end


    # Configure Port Forwarding
    config.vm.network :forwarded_port, guest: 80, host: 8080

    # Configure The Public Key For SSH Access
    settings["authkeys"].each do |authkey|
      config.vm.provision "shell" do |s|
        s.inline = "echo $1 | tee -a /home/vagrant/.ssh/authorized_keys"
        s.args = [File.read(authkey)]
      end
    end

    # Copy The SSH Private Keys To The Box
    settings["keys"].each do |key|
      config.vm.provision "shell" do |s|
        s.privileged = false
        s.inline = "echo \"$1\" > /home/vagrant/.ssh/$2 && chmod 600 /home/vagrant/.ssh/$2"
        s.args = [File.read(key), key.split('/').last]
      end
    end

    # Register All Of The Configured Shared Folders
    settings["folders"].each do |folder|
      config.vm.synced_folder folder["map"], folder["to"]
    end

    #Provision with puppet
    config.vm.provision :puppet, :module_path => "modules" do |puppet|
      puppet.manifests_path = "manifests"
      puppet.manifest_file  = settings["manifest"] ||= "default.pp"
    end
    #Install All The Configured Nginx Sites
    settings["sites"].each do |site|
      config.vm.provision "shell" do |s|
        s.inline = "bash /vagrant/scripts/serve.sh $1 $2"
        s.args = [site["servername"], site["docroot"]]
      end
    end

  end
end
