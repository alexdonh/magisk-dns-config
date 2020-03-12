#!/system/bin/sh

ui_print "- Performing additional changes"
bin=xbin
if [ ! -d /system/xbin ]; then
  bin=bin
  mkdir $MODPATH/system/$bin
  mv $MODPATH/system/xbin/dnsconfig $MODPATH/system/$bin
  rm -rf $MODPATH/system/xbin/*
  rmdir $MODPATH/system/xbin
fi

ui_print "- Setting permissions"
set_perm $MODPATH/system/$bin/dnsconfig 0 0 0755