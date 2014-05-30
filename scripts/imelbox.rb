# -*- mode: ruby -*-
# # vi: set ft=ruby :
#

class Imelbox
  def Imelbox.configure(config,settings)
    #Configure the Box
    config.vm.box = "wheezy"
    config.vm.box_url = "http://vbox.imelbox.com.s3.amazonaws.com/vagrant-debian71-x64.box"

#    server_ip = settings["ip"] ||= "192.168.10.10"

    #Configure A private Network
    #config.vm.network :private_network, ip: settings["ip"] ||= "192.168.10.10"

    # Configure A Few VirtualBox Settings
    config.vm.provider "vmware_fusion" do |v|
      v.vmx["memsize"] = settings["memory"] ||= "2048"
      v.vmx["numvcpus"] = settings["cpus"] ||= "1"
    end

    # Configure Port Forwarding
    config.vm.network :forwarded_port, guest: 80, host: 8080

    # Register All Of The Configured Shared Folders
    settings["folders"].each do |folder|
      config.vm.synced_folder folder["map"], folder["to"]
    end

    #Provision with puppet
    config.vm.provision :puppet, :module_path => "modules" do |puppet|
      puppet.manifests_path = "manifests"
      puppet.manifest_file  = "default.pp"
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