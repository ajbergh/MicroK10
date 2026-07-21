text
lang en_US.UTF-8
keyboard us
timezone UTC --utc
network --bootproto=dhcp --device=link --activate --hostname=microk10
rootpw --lock
user --name=microk10 --groups=wheel --lock
sshkey --username=microk10 "${ssh_public_key}"
firewall --enabled --service=ssh
selinux --enforcing
bootloader --location=mbr
zerombr
clearpart --all --initlabel
autopart --type=lvm
reboot

%packages
@^minimal-environment
openssh-server
open-vm-tools
NetworkManager
curl
ca-certificates
podman
openssl
dialog
git
sudo
%end

%post
systemctl enable sshd NetworkManager vmtoolsd
printf 'microk10 ALL=(ALL) NOPASSWD: ALL\n' >/etc/sudoers.d/microk10-build
chmod 0440 /etc/sudoers.d/microk10-build
%end
