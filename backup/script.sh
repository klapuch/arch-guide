#!/bin/bash
set -eu

# source: https://wiki.archlinux.org/index.php/Full_system_backup_with_tar
# restore like `tar --acls --xattrs -xpf backup_file`

backup_destination=/home/dom/backup

type='full'
date=$(date "+%F")
backup_file="$backup_destination/arch-$type-$date.tar.gz"

exclude_file='/home/dom/Projects/arch-guide/backup/exclude.txt'

echo -n 'First chroot from a LiveCD.  Are you ready to backup? (y/n): '
read executeback

# Check if exclude file exists
if [ ! -f $exclude_file ]; then
  echo -n 'No exclude file exists, continue? (y/n): '
  read continue
  if [ $continue == "n" ]; then exit; fi
fi

if [ $executeback = "y" ]; then
  tar --exclude-from=$exclude_file --acls --xattrs -cpf $backup_file /
fi
