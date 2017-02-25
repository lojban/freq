#!/bin/bash

if [ ! "$1" ]
then
  echo "First argument should be the userid.  This should be automatic if you're using the run scripts."
  exit 1
fi

uid=$1
shift

if [ ! "$1" ]
then
  echo "Second argument should be the group.  This should be automatic if you're using the run scripts."
  exit 1
fi

gid=$1
shift

groupadd -g $gid freq
useradd -g $gid -u $uid -m freq

cd /srv/freq
if [ "$1" = 'shell' ]
then
  sudo -u freq bash
else
  sudo -u freq /srv/freq/build.sh "$@"
fi
