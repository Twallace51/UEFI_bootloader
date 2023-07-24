# UEFI Shell as Primary Linux Bootloader

## Motive

I like trying different Linux distributions and keep messing up the Grub bootloader files.

I never liked configuring Grub2 all the time, so I switched to Refind.

Refind is great,  but confusing,  since I didn't understand the different things it was doing with the UEFI.

So I investigated and found that the UEFI includes a shell that is perfectly capable as a bootloader by itself.

In the interest of sharing what I have learned,  I include the files I use to boot my computers.

## Background

An ESP is a small fat32 formated partition,  with flags `boot,esp`

On bootup,  a UEFI capable computer runs the motherboard's firmware,  which after initializing whatever systems and devices that might be present, looks at a list of efi programs,  that can be managed by a user.  

The firmware will  try to run each program, if found in the ESP, until it is successful.  These programs  could be diagnostics, kernels, bootloaders, whatever....

If all fail, the firmware runs the anti-bricking/failsafe program `/efi/boot/bootx64.efi` ,  which by default is the UEFI OS Shell.

When the OS Shell runs and before opening a terminal,  it will mount any file systems it can load  and then run the script `startup.nsh`, if present.

OS Shell is ~ not ~ Bash,  but has commands sufficient to 

- load additional file system drivers (ext4, ntfs, btrfs, etc)
- mount the corresponding partitions
- look in it's %path% for any additional scripts
- show a list of options in terminal
- wait for user input

[sarcastic tone] For any details that I ~ may ~ have skipped here ,  read https://uefi.org/specifications 

## Usage

- [ ] Read the comments in the my Shell and Bash scripts to better understand what they do.

      startup.nsh 
      bootscripts.sh

  In any case, usage of these files will not have any adverse effect on any other bootloader systems that might be installed/used in the ESP.

- [ ] Find where the ESP has been mounted in your system,  probably on either `/boot` or `/boot/efi`.
  Then as root,  copy the above  to the mount point,  next to the preexisting EFI folder.

- [  ] Confirm/add following drivers to EFI/tools folder  -  download from  https://efi.akeo.ie/downloads/efifs-1.9/x64/

  ext4_x64.efi
  btrfs_x64.efi

- [ ] Run  `sudo bash bootscripts.sh` ,  to analyze your current system and put the corresponding Shell boot script in the system's root/.

Then either:

- [ ] Update efi boot list and place UEFI OS is ~first~ by using `sudo efibootmgr` ,
  followed by rebooting

- [ ] install Refind and on rebooting,   selecting the  UEFI OS icon
- [ ] reboot, interrupt the firmware bootup and select UEFI OS in the UEFI Interface

