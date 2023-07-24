#!/bin/bash

# Bash script for an installed Linux distribution,
# for generating a corresponding UEFI boot script

# Usage:
#   run this script as regular user, from a currently running distribution

# Assumes:
#   correct microcode in distribution's /tools folder
#   assumes kernel has this regex format  `vmlinuz*-x86_64`
#   only the first kernel and initramfs found in /boot will be used
#       any others are ignored
#   only ext4 and btrfs file system types are handled
#   principal drive is nvme0n1,   not sda, sdb, nvme0n2
#   boot script placed in root/ of distribution,  which is on Shell default path


clear

# run script in $USER directory of target partition!
cd ~

# find where ESP has been mounted
if [[ -d /mnt/esp ]]; then
  ESP=/mnt/esp
elif [[ -d /mnt/ESP ]]; then      # my prefered
  ESP=/mnt/ESP
elif [[ -d /boot/efi/EFI ]]; then # deprecated
  ESP=/boot/efi/EFI
elif [[ -d /boot/EFI ]]; then     # recommended
  ESP=/boot
else
  echo "ERROR - Can't find ESP"
  exit
fi

# confirm startup.nsh is available so can add aliases below
if [[ -f $ESP/startup.nsh ]]; then
  STARTUP=$ESP/startup.nsh
else
  echo "ERROR - Can't find ESP/startup.nsh "
  exit
fi


# get device for current working directory
DEVICE=$( df --output=source . | grep dev )
echo -e "DEVICE => $DEVICE\n"

# get partition number

#PARTN=$(lsblk -n -o PARTN $DEVICE)    # some vesions of lsblk do not have this ???
#PARTN=${PARTN##*( )}                  # remove spaces with bash parameter expansion

if [[  $DEVICE==*nvme0n1* ]]; then
   PARTN=${DEVICE:13}
   echo -e "PARTN => $PARTN\n"
else
   echo "ERROR - primary drive is not /dev/nvme0n1"
   exit
fi

# get FSTYPE for $DEVICE
FSTYPE=$( df --output=fstype . )
FSTYPE=${FSTYPE:5}                     # remove header 'TYPE'
echo -e "FSTYPE => $FSTYPE\n"

# get GUID of $DEVICE
GUID=$(lsblk -n -o PARTUUID $DEVICE)
echo -e "GUID => $GUID\n"

# get cpu name
MBOARD=$(lscpu | grep "Model name")
MBOARD=${MBOARD:33}                         # remove 'Model name'
echo -e "MBOARD => $MBOARD\n"

# get type
if [[ $MBOARD==*AMD* ]]; then
   CPU="amd"
elif [[ $MBOARD==*INTEL* || $MBOARD==*Intel*  ]]; then
   CPU="intel"
else
   echo "ERROR - CPU not assigned for mother board"
   exit
fi

# set microcode for cpu
if [[ $CPU=="amd" ]]; then
   UCODE="amd-ucode.img"
elif [[ $CPU=="intel" ]]; then
   UCODE="intel-ucode.img"
else
   echo "ERROR ucode not assigned"
   exit
fi
echo -e "UCODE => $UCODE\n"

if [[ ! -f /boot/$UCODE ]] ; then
   echo "ERROR - /boot/$UCODE was not found"
   exit
fi

# get kernel
cd /boot

RAMFS=$(ls init*-x86_64.img)
KERN=$(ls vmlinuz*-x86_64)

RAMFS=$(echo $RAMFS | sed -n '1p')
KERN=$(echo $KERN | sed -n '1p')

echo -e "KERNEL => $KERN\n"
echo -e "RAMFS => $RAMFS\n"

cd ~

# generate boot script

SCRIPT=p${PARTN}.nsh

# Note: correct output requires escaping two backslashes before $SCRIPT and $KERN below

echo "# UEFI shell boot script for:

# Partition:    $DEVICE   $FSTYPE
# GUID:         $GUID
# Motherboard:  $MBOARD
# Kernel:       $KERN   $UCODE     $RAMFS

# look for and mount the Shell filesystem containing this script

echo -off
for %A run (0 20)
  if exist fs%A:\\\\${SCRIPT} then
    fs%A:
  endif
endfor

# run UEFI shell boot code
" > $SCRIPT

# adjust boot command for FSTYPE

if [[ $FSTYPE == "ext4" ]]; then
  echo "boot\\\\$KERN root=PARTUUID=$GUID rw initrd=/boot/$UCODE initrd=/boot/$RAMFS" >> $SCRIPT
elif [[ $FSTYPE == "btrfs" ]]; then
  echo "@\\\\boot\\\\$KERN root=PARTUUID=$GUID rw rootflags=subvol=@ initrd=@/boot/$UCODE initrd=@/boot/$RAMFS" >> $SCRIPT
fi

# preview script
echo    "##############################################################"
cat $SCRIPT
echo -e "##############################################################\n"

# move to root/
sudo mv $SCRIPT /

# add alias
echo -e "\nalias -v p${PARTN} $SCRIPT" >> $STARTUP


echo
