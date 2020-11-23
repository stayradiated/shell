# config
loadkeys colemak
setfont /usr/share/kbd/consolefonts/Lat2-Terminus16.psfu.gz

# wifi
systemctl start netctl-auto@wlan0
wifi-menu
systemctl start dhcpcd
ping archlinux.org

# time
timedatectl set-ntp true

# when did you last check your backups?
mkfs.ext4 /dev/nvme0n1p5

# mount disk
mount /dev/nvme0n1p5 /mnt
mkdir /mnt/efi
mount /dev/nvme0n1p1 /mnt/efi

# configure pacman mirrors
pacman -Sy
pacman -S pacman-contrib
cd /etc/pacman.d
cp mirrorlist mirrorlist.backup
vim mirrorlist.backup # keep only nearby servers
rankmirrors mirrorlist.backup | tee mirrorlist.sorted
mv mirrorlist.sorted mirrorlist

# install base system
pacstrap /mnt base linux linux-firmware

# generate fstab
genfstab -U /mnt >> /mnt/etc/fstab

# enter the matrix
arch-chroot /mnt

# set timezone
ln -sf /usr/share/zoneinfo/Pacific/Auckland  /etc/localtime
hwclock --systohc

# configure language
pacman -S vi
vi /etc/locale.gen # uncomment en_NZ.UTF-8
echo 'LANG=en_NZ.UTF-8' >> /etc/locale.conf

# configure keyboard
echo 'KEYMAP=colemak' >> /etc/vconsole.conf
echo 'FONT=Lat2-Terminus16' >> /etc/vconsole.conf

# hostname
echo 'carbon' > /etc/hostname
cat << EOF > /etc/hosts
127.0.0.1 localhost
::1       localhost
127.0.1.1 carbon.localdomain carbon
EOF

# install networking tools
pacman -S openresolv dhcpcd netctl dialog wpa_supplicant

# configure dhcpcd to ignore arp
echo 'noarp' >> /etc/dhcpcd.conf

# set root password
passwd

# grub
pacman -S grub efibootmgr intel-ucode
grub-install --target=x86_64-efi --efi-directory=/efi --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg

exit
umount -R /mnt
reboot

# reconfigure wifi
systemctl start netctl-auto@wlp2s0
wifi-menu
systemctl enable dhcpcd
systemctl start dhcpcd

# install base for x11docker
pacman -S docker xorg-server xf86-video-intel xpra xdotool xorg-xinit xorg-xhost xorg-xrandr xorg-xdpyinfo xorg-xauth xclip

echo '{ "experimental": true }' > /etc/docker/daemon.json
systemctl enable docker
systemctl start docker

# install x11docker
curl -fsSL https://raw.githubusercontent.com/mviereck/x11docker/master/x11docker | bash -s -- --update

# sudo
pacman -S sudo
visudo # allow group sudo

# admin user -- do we need them?
useradd admin -G audio,video,docker,sudo

# ssh
pacman -S openssh
cat << EOF > /etc/ssh/sshd_config
Port 				22
ListenAddress 			127.0.0.1
AuthorizedKeysFile 		.ssh/authorized_keys
PubkeyAuthentication 		yes
PasswordAuthentication 		no
PermitEmptyPasswords 		no
ChallengeResponseAuthentication no
UsePAM 				no
EOF
mkdir -p ~/.ssh
systemctl enable sshd
systemctl start sshd
docker exec $(docker ps -q) cat /home/admin/.ssh/sshkey.pub > ~/.ssh/authorized_keys

# wacom driver (requires reboot)
pacman -S xf86-input-wacom

# bluetooth mouse
# pacman -S bluez bluez-utils bluez-hid2hci
# bluetoothctl
# 	default-agent
# 	power on
# 	scan on
# 	connect D6:34:95:34:81:8E
# 	trust D6:34:95:34:81:8E
# 	pair D6:34:95:34:81:8E
# 	scan off
