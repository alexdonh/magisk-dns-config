#!/system/bin/sh

MODDIR=${0%/*}

if [[ -f /system/etc/resolv.conf && -f $MODDIR/system/etc/resolv.conf ]]; then
  rm -rf $MODDIR/system/etc
fi

if [ -f $MODDIR/service.sh ]; then
  rm -f $MODDIR/service.sh
fi

if [ -f $MODDIR/nameservers ]; then
  if [ -f /system/etc/resolv.conf ]; then
    mkdir -p $MODDIR/system/etc
    cp -f /system/etc/resolv.conf $MODDIR/system/etc
    set_perm $MODDIR/system/etc/resolv.conf 0 0 0644
  fi

  touch $MODDIR/service.sh
  set_perm $MODDIR/service.sh 0 0 0644
  
  echo '#!/system/bin/sh\n' >> $MODDIR/service.sh 2>&1
  echo 'until [ $(getprop sys.boot_completed) -eq 1 ]; do' >> $MODDIR/service.sh 2>&1
  echo '  sleep 1' >> $MODDIR/service.sh 2>&1
  echo 'done\n' >> $MODDIR/service.sh 2>&1

  nameservers=($(cat $MODDIR/nameservers | tr ":" "\n"))
  index=0

  for i in "${nameservers[@]}" ; do
    ((index++))

    resetprop net.eth0.dns$index $i
    resetprop net.dns$index $i
    resetprop net.ppp0.dns$index $i
    resetprop net.rmnet0.dns$index $i
    resetprop net.rmnet1.dns$index $i
    resetprop net.pdpbr1.dns$index $i

    if [[ -f /system/etc/resolv.conf && -f $MODDIR/system/etc/resolv.conf ]]; then
      echo "nameserver $i" >> $MODDIR/system/etc/resolv.conf 2>&1
    fi

    echo "iptables -t nat -A OUTPUT -p tcp --dport 53 -j DNAT --to-destination $i:53" >> $MODDIR/service.sh 2>&1
    echo "iptables -t nat -A OUTPUT -p udp --dport 53 -j DNAT --to-destination $i:53" >> $MODDIR/service.sh 2>&1
    echo "iptables -t nat -D OUTPUT -p tcp --dport 53 -j DNAT --to-destination $i:53 || true" >> $MODDIR/service.sh 2>&1
    echo "iptables -t nat -D OUTPUT -p udp --dport 53 -j DNAT --to-destination $i:53 || true" >> $MODDIR/service.sh 2>&1
    echo "iptables -t nat -I OUTPUT -p tcp --dport 53 -j DNAT --to-destination $i:53" >> $MODDIR/service.sh 2>&1
    echo "iptables -t nat -I OUTPUT -p udp --dport 53 -j DNAT --to-destination $i:53" >> $MODDIR/service.sh 2>&1
  done
fi