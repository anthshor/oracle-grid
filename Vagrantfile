# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure(2) do |config|
  config.vm.box = "kikitux/oracle65-4disk"
  config.vm.network "private_network", ip: "192.168.33.11"
# Thanks Alvaro https://github.com/racattack/vagrantfile/blob/master/OracleLinux/racattack12cR1/Vagrantfile
  config.vm.provider :virtualbox do |vb|
    vb.customize ['createhd', '--filename', 'asmdisk1', '--size', '5120', '--variant', 'fixed']
    vb.customize ['modifyhd', 'asmdisk1.vdi', '--type', 'shareable']
    vb.customize ['storageattach', :id, '--storagectl', 'SATA Controller', '--port', 2, '--device', 0, '--type', 'hdd', '--medium', 'asmdisk1.vdi']
    vb.customize ['createhd', '--filename', 'asmdisk2', '--size', '5120', '--variant', 'fixed']
    vb.customize ['modifyhd', 'asmdisk2.vdi', '--type', 'shareable']
    vb.customize ['storageattach', :id, '--storagectl', 'SATA Controller', '--port', 3, '--device', 0, '--type', 'hdd', '--medium', 'asmdisk2.vdi']
  end
  config.vm.provision "shell",  path: "provision.sh"
end
