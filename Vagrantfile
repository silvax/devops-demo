# -*- mode: ruby -*-
# vi: set ft=ruby :
# This is a Vagrant configuration file. It can be used to set up and manage
# virtual machines on your local system or in the cloud. See http://downloads.vagrantup.com/
# for downloads and installation instructions, and see http://docs.vagrantup.com/v2/
# for more information and configuring and using Vagrant.

Vagrant.configure("2") do |config|
  ##### Added for ec2 ######
  config.ssh.pty = true
  config.vm.box = "dummy"
  #config.vm.synced_folder ".", "/vagrant", type: "rsync"
  config.vm.synced_folder "./setup", "/home/ec2-user/setup", type: "rsync"

  config.vm.provider :aws do |aws, override|
    aws.keypair_name = "andres"
    aws.ami = "ami-256c1d32"
    aws.instance_type = "m4.large"
    aws.security_groups = ["sg-7c3a7c1b"]
    aws.subnet_id = "subnet-6285e349"
    aws.user_data = File.read("./user-data.sh")
    aws.iam_instance_profile_name = "vagrant"
    aws.tags = {
      'Name' => 'apache_test',
      'env' => 'dev',
      'Owner' => 'andress@amazon.com'
    }
    override.ssh.username = "ec2-user"
    override.ssh.private_key_path = "/Users/andress/.ssh/keys/andres.pem"
  end

  config.vm.provision "ansible" do |ansible|
    ansible.playbook = "setup/site.yml"
    ansible.verbose = "vvvv"
    ansible.extra_vars = {
      ansible: { env: 'dev' },
      Name: "apache_server",
      Owner: "andress",
      appversion: "1.0.2"
    }
  end
end
