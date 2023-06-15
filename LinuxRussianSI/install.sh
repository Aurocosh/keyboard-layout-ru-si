#!/bin/sh

if [ $(id -u) != 0 ]; then
   echo "This script requires root permissions"
   sudo "$0" "$@"
   exit
fi

USER_HOME="$(getent passwd $SUDO_USER | cut -d: -f6)"
X_COMPOSE_FILE=$USER_HOME/.XCompose
SYMBOL_FILE=/usr/share/X11/xkb/symbols/rusi
EVDEV_XML=/usr/share/X11/xkb/rules/evdev.xml

if ! test -f "$X_COMPOSE_FILE"; then
  touch $X_COMPOSE_FILE
  chown $SUDO_USER:$SUDO_USER $X_COMPOSE_FILE
  echo "Created XCompose file"
fi

if grep -Fq "include \"%L\"" $X_COMPOSE_FILE; then
  echo "Skipped XCompose include write"
else
  echo "include \"%L\"   # import the default Compose file for your locale\n\n" >> $X_COMPOSE_FILE
  echo "Written include to XCompose"
fi


if grep -Fq "Russian SI keyboard layout" $X_COMPOSE_FILE ; then
  echo "Removing old settings from XCompose"
  sed -i "/### Russian SI keyboard layout START/,/### Russian SI keyboard layout END/d" $X_COMPOSE_FILE
fi

cat ./XCompose.txt >> $X_COMPOSE_FILE
echo "Written new settings to XCompose"

if test -f $SYMBOL_FILE; then
  if ! grep -Fq "Custom russian phonetic keyboard layout" $SYMBOL_FILE ; then
    echo "Symbol file not recognized. Backing up"
    cp $SYMBOL_FILE $SYMBOL_FILE.backup."$(date +%Y%m%d-%H%M%S)"
  fi
fi

cp -f ./rusi.txt $SYMBOL_FILE
echo "Copied layout symbol file"

if ! grep -Fq "<description>Russian SI</description>" $EVDEV_XML ; then
  echo "Layout is not present in evdev.xml. Backing up evdev.xml and adding layout."
  cp $EVDEV_XML $EVDEV_XML.backup."$(date +%Y%m%d-%H%M%S)"
  sed -n -i -e '/<\/layoutList>/r evdev.txt' -e 1x -e '2,${x;p}' -e '${x;p}' $EVDEV_XML
else
  echo "Layout is present in evdev.xml"
fi

udevadm trigger --subsystem-match=input --action=change
