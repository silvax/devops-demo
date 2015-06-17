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
  config.vm.synced_folder "./base", "/home/ec2-user/base", type: "rsync"

  config.vm.provider :aws do |aws, override|
    config.ini.file = ENV['HOME'] + '/.aws/credentials'
    aws_profile = 'profile dev'
    access_key_id = config.ini.config[aws_profile]['aws_access_key_id']
    secret_access_key = config.ini.config[aws_profile]['aws_secret_access_key']
    aws.access_key_id = access_key_id
    aws.secret_access_key = secret_access_key
    aws.keypair_name = "dev.ops"
    aws.ami = "ami-1ecae776"
    aws.instance_type = "m3.medium"
    aws.security_groups = ["sg-cf66d3aa"]
    aws.iam_instance_profile_name = "default"
    aws.subnet_id = "subnet-bbf02f90"
    aws.user_data = File.read("./user-data.sh")
    aws.tags = {
      'Name' => 'base_vagrant_test',
      'role' => 'devopsservicetest',
      'environment' => 'stage',
      'Owner' => 'DevOps-CloudApplications@inin.com'
      #'opsworks:instance' => 'mongoinstance',
      #'opsworks:stack' => 'mongostack'
    }
    aws.block_device_mapping = [
      {
        'DeviceName' => '/dev/sdo',
        'Ebs.VolumeSize' => 10,
        'Ebs.SnapshotId' => 'snap-86ece438'
      },
      {
        'DeviceName' => '/dev/sdp',
        'Ebs.VolumeSize' => 10,
        'Ebs.SnapshotId' => 'snap-86ece438'
      }
    ]
    aws.ssh_host_attribute = :private_ip_address
    override.ssh.username = "ec2-user"
    override.ssh.private_key_path = "/Users/asilva/.ssh/keys/devops-old.pem"
  end

  #config.vm.provision "shell", inline: "sudo easy_install pip"
  config.vm.provision "shell", inline: "sudo easy_install --upgrade pip"
  config.vm.provision "shell", inline: "sudo pip install ansible"

  config.vm.provision "ansible" do |ansible|
    ansible.playbook = "base/build.yml"
    ansible.verbose = "vvvv"
    ansible.extra_vars = {
      # The ansible dictionary can be used to pass varibles that are found in Custom JSON in OpsWorks
      ansible: { environment: 'stage' },
      Name: "base_vagrant_test",
      Owner: "DevOps",
      # The opsworks dictionary can be used to mimic the stack info passed by opsworks
      opsworks: {
        stack: { name: "base-stack" },
        instance: {
          hostname: "base-host",
          layers: "base-layer"
        },
        layers: {
          "base-layer" => {
            instances: {
              #"base-instance"=> {}
            }
          }
        }
      }
    }
  end
end
