#!/bin/bash

set +e

#########################
# Set user and password #
#########################

FIRSTUSER=`getent passwd 1000 | cut -d: -f1`
FIRSTUSERHOME=`getent passwd 1000 | cut -d: -f6`

echo "$FIRSTUSER:"'$5$/FyMAa8yqx$PTwWMHhRVT2qehwE7dofGINbuOH5NHrV27HfK0St9QB' | chpasswd -e

if [ "$FIRSTUSER" != "pi" ]; then
  usermod -l "pi" "$FIRSTUSER"
  usermod -m -d "/home/pi" "pi"
  groupmod -n "pi" "$FIRSTUSER"
  if grep -q "^autologin-user=" /etc/lightdm/lightdm.conf ; then
     sed /etc/lightdm/lightdm.conf -i -e "s/^autologin-user=.*/autologin-user=pi/"
  fi
  if [ -f /etc/systemd/system/getty@tty1.service.d/autologin.conf ]; then
     sed /etc/systemd/system/getty@tty1.service.d/autologin.conf -i -e "s/$FIRSTUSER/pi/"
  fi
  if [ -f /etc/sudoers.d/010_pi-nopasswd ]; then
     sed -i "s/^$FIRSTUSER /pi /" /etc/sudoers.d/010_pi-nopasswd
  fi
fi

##############
# Set locale #
##############

rm -f /etc/localtime
echo "America/New_York" >/etc/timezone
dpkg-reconfigure -f noninteractive tzdata
cat >/etc/default/keyboard <<'KBEOF'
XKBMODEL="pc105"
XKBLAYOUT="us"
XKBVARIANT=""
XKBOPTIONS=""

KBEOF
dpkg-reconfigure -f noninteractive keyboard-configuration

####################
# Set wifi country #
####################

raspi-config nonint do_wifi_country US

###########
# Cleanup #
###########

rm -f /boot/firstrun.sh

###################
# Don't run again #
###################

sed -i 's| systemd.run.*||g' /boot/cmdline.txt

exit 0
