# login with root:voidlinux

# use bash shell
bash

# configure keyboard and font
loadkeys colemak
setfont latarcyrheb-sun32

# wifi details
wpa_passphrase 'ssid' 'password' >> /etc/wpa_supplicant/wpa_supplicant.conf
ln -s /etc/sv/wpa_supplicant /etc/runit/runsvdir/default/
sv restart dhcpcd
ping voidlinux.org

# full disk encryption guide:
# https://docs.voidlinux.org/installation/guides/fde.html

fdisk -l /dev/nvme0n1
# /dev/nvme0n1p1    2048     1026047   1024000    500M  EFI System
# /dev/nvme0n1p2  102648  1000215182 999189134  476.5G  Linux Filesystem

cryptsetup luksFormat --type luks1 /dev/nvme0n1p2
cryptsetup luksOpen /dev/nvme0n1p2 voidvm
vgcreate voidvm /dev/mapper/voidvm
lvcreate --name swap -L 2G voidvm
lvcreate --name home -l 100%FREE voidvm
mkswap /dev/voidvm/swap
mkfs.xfs -L root /dev/voidvm/root

# mount root
mount /dev/voidvm/root /mnt
for dir in dev proc sys run
do
  mkdir -p /mnt/$dir
  mount --rbind /$dir /mnt/$dir
  mount --make-rslave /mnt/$dir
done

# mount efi
mkfs.vfat /dev/nvme0n1p1
mkdir -p /mnt/boot/efi
mount /dev/nvme0n1p1 /mnt/boot/efi

# install void linux (using AU mirror)
xbps-install -Sy -R https://mirror.aarnet.edu.au/pub/voidlinux/current -r /mnt base-system cryptsetup grub-x86_64-efi lvm2

# chroot inside
chroot /mnt
bash
chown root:root /
chmod 755 /
passwd root
echo voidvm > /etc/hostname
echo "LANG=en_US.UTF-8" > /etc/locale.conf
echo "en_US.UTF-8 UTF-8" >> /etc/default/libc-locales
xbps-reconfigure -f glibc-locales

vi /etc/fstab
# <file system>	    <dir>     <type>  <options>             <dump>  <pass>
# tmpfs             /tmp      tmpfs   defaults,nosuid,nodev 0       0
# /dev/voidvm/swap  swap      swap    defaults              0       0
# /dev/voidvm/root  /         xfs     defaults              0       0
# /dev/nvme0n1p1	  /boot/efi	vfat	  defaults	            0	      0

# edit /etc/default/grub
echo "GRUB_ENABLE_CRYPTODISK=y" >> /etc/default/grub
echo "GRUB_CMDLINE_LINUX_DEFAULT=\"rd.lvm.vg=voidvm rd.luks.uuid=$(blkid -o value -s UUID /dev/nvme0n1p2)\"" >> /etc/default/grub

dd bs=1 count=64 if=/dev/urandom of=/boot/volume.key
cryptsetup luksAddKey /dev/sda1 /boot/volume.key
chmod 000 /boot/volume.key
chmod -R g-rwx,o-rwx /boot
echo 'voidvm   /dev/nvme0n1p2   /boot/volume.key   luks' >> /etc/crypttab
echo 'install_items+=" /boot/volume.key /etc/crypttab "' > /etc/dracut.conf.d/10-crypt.conf

grub-install /dev/nvme0n1
xbps-reconfigure -fa

exit
umount -R /mnt
reboot
