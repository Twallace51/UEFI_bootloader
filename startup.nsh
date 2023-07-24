## UEFI Shell startup.nsh
# This script is always run by firmware on bootup, if found in its %path%

# Sections that may require updates for current system are marked with # UPDATE
#   screen size
#   filesystem drivers
#   alias assignments/comments


echo -off

# UPDATE
########

# set screen resolution to maximum
# ========================
# Note: use `shell> mode` to see options

mode 320 75      # office
# mode 160 53      # home

# display current shell version - latest is EDK 2.2
# =================================================

echo " "
ver
echo " "

# mount ESP so can find EFI\boot files
# ====================================
for %A run (0 20)
  if exist fs%A:\startup.nsh then
    fs%A:
  endif
endfor

# uncomment filesystem drivers that should be loaded
# ==================================================

# UPDATE
########
load efi\tools\ext4_x64.efi
load efi\tools\btrfs_x64.efi
#load iso6690_x64.efi
#load exfat_x64.efi

# remap current file systems and enabled partitions
# =================================================

echo " "
map -r -sfo > null
echo " "


# show p*.nsh scripts in partitions
# ==================================

echo "Available boot scripts:"
echo "================================="
echo " "

for %A run (0 20)

if exist fs%A:\ then
  fs%A:
else
  goto continue
endif

if exist *.nsh then

  ls *.nsh -sfo | parse FileInfo 2 >v FILES

  if exist @ then
    set -v FSTYPE "btrfs "
  else
    if exist boot then
      set -v FSTYPE "ext4 "
    else
      if exist EFI then
        set -v FSTYPE "ESP fat32 "
      else
        set -v FSTYPE "unkown"
      endif
    endif
  endif

  ls -sfo | parse VolumeInfo 2 >v Label

  set PART -v "%Label% - %FSTYPE%"
  set PART
  echo %FILES%

  set -v FILES " "  
  set -v PART " "
  set -v Label " "
 
  echo " "

endif

endfor
:continue

# UPDATE
########

echo "Comments:"
echo "================================="
echo " "
echo "p4        alias for working favorite - ext4  "
echo "p7        alias for working - btrfs "
echo " "

alias -v p3 p3.nsh
alias -v p4 p4.nsh
alias -v p6 p6.nsh
alias -v p7 p7.nsh

echo -off

# remount ESP partition
# =====================
# since was remapped above

for %B run (0 20)
  if exist fs%B:\startup.nsh then
    fs%B:
    goto finish
  endif
endfor
:finish


echo "Any key for default boot - Q to cancel"
pause -q
p4.nsh

