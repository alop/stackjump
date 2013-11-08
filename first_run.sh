#!/bin/sh
export HOME="/root"
export FQDN=`hostname -f`
update-grub
dpkg -i /root/extras/*.deb # install chef-client|server
/usr/bin/chef-server-ctl reconfigure > /root/reconfigure.out 2>&1
echo "Waiting 60 seconds before configuring knife..."
sleep 60
chmod 755 /root/knife_first_run
if [ -d /root/.chef ]; then
  rm -rf /root/.chef
fi
/root/knife_first_run
knife configure client /etc/chef && chef-client
apt-get -q -y update
apt-get -q -y install ruby1.9.1
apt-get -q -y install git
apt-get -q -y purge ruby1.8
gem install bundler
cd /root/extras/chef-repo/
bundle
bundle exec berks upload
knife upload roles/
knife upload environments/
knife cookbook upload -o /root/extras/chef-repo/cookbooks --all
knife node run_list add $FQDN "recipe[chef-client]"
knife node run_list add $FQDN "role[booted]"
sleep 2
chef-client
sed -i 's,sh /root/first_run.sh,exit 0,' /etc/rc.local
reboot
# stackjump default first_run.sh
