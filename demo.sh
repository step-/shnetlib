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
. "${0%/*}/usr/sbin/net-lib.sh"
enum_interfaces
for i in $IFACE_other_index; do
  get_iface_other -e $i
done
for i in $IFACE_wired_index; do
  get_iface_wired -e $i
done
for i in $IFACE_wireless_index; do
  get_iface_wireless -e $i
done
