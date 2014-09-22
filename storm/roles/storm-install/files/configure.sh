#!/bin/bash

FLAG="/var/log/firstboot.log"
if [ ! -f $FLAG ]; then
   #Put here your initialization sentences
   echo "This is the first boot"

   #Run ansible to configure the instance for the first time
   ansible-playbook -i /opt/storm/inv /opt/storm/configure.yml

   #the next line creates an empty file so it won't run the next boot
   touch $FLAG
else
   echo "Do nothing"
fi
