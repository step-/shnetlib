#!/bin/dash
# Compatible /bin/sh /bin/bash busybox ash
# Copyright (C) 2017 step
# License: GPL2

# exec >>/tmp/${0##*/}.log 2>&1
# echo ========================
# date +%Y%m%d-%H%M%S
# echo "$0 $*"
# echo ========================
# set -x

# Main {{{1
. "${0%/*}/usr/sbin/shnetlib.sh"
enum_interfaces
echo "*** $IFACE_other_n other interface(s) found:"
for w in $IFACE_other_which; do
  get_iface_other --export $w
done
echo "*** $IFACE_wired_n wired interface(s) found:"
for w in $IFACE_wired_which; do
  get_iface_wired --export $w
done
echo "*** $IFACE_wireless_n wireless interface(s) found:"
for w in $IFACE_wireless_which; do
  get_iface_wireless --export $w
done
echo "*** $BUS_pci_n PCI network interfaces(s) found:"
for lw in $BUS_pci; do
  get_iface_by_bus --export $lw
done
echo "*** $BUS_usb_n USB network interfaces(s) found:"
for lw in $BUS_usb; do
  get_iface_by_bus --export $lw
done
