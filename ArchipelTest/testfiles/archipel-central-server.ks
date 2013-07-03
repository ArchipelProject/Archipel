#insert here centos minimal ks file
lang en_US.UTF-8
keyboard us
timezone US/Pacific
auth --useshadow --enablemd5
selinux --enforcing
firewall --disabled
repo --name=base   --baseurl=http://mirror.centos.org/centos/6/os/x86_64/
repo --name=EPEL --baseurl=http://dl.fedoraproject.org/pub/epel/6/x86_64/
bootloader --location=mbr
network --bootproto=dhcp --device=eth0

zerombr
clearpart --drives=vda all

# Create primary partitions
part /boot --fstype ext4 --size=500 --asprimary --ondisk=vda
part swap --size=4096 --asprimary --ondisk=vda
part pv.01 --size=100 --grow --asprimary --ondisk=vda

# Create LVM logical volumes
volgroup system --pesize=32768 pv.01
logvol  /var  --vgname=system  --size=8196  --name=var_vol
logvol  /tmp  --vgname=system  --size=2048  --name=tmp_vol
logvol  /  --vgname=system  --size=100  --grow  --name=root_vol

rootpw archipel
reboot

%packages
@core
ejabberd

# for xmlrpc
#erlang-dev
erlang-xmerl
erlang-xmlrpc
erlang-tools
python-setuptools

%end

%post


%end

%post --nochroot
cp testfiles/ejabberd.cfg $INSTALL_ROOT/etc/ejabberd/

%end
