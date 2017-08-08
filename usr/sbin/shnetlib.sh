#!/bin/dash
# Compatible /bin/sh /bin/bash busybox ash
# Copyright (C) 2017 step
# License: GPL2

# This file is sourced, not run.

set +f

# {{{1}}}
# <path> ::= path in '/sys/class/net/'*
# <iface> ::= basename in '/sys/class/net/'*
# <list> ::= 'other' | 'wireless' | 'wired'
# <list_which> ::= <integer> >= 0
# IFACE_<list>_n ::= '0' .. number of <list> interfaces detected
# IFACE_<list>_which ::= list of <list_which> (enumeration index [0..IFACE_<list>_n - 1])
# IFACE_<list>_path ::= list of <path>
# IFACE_<list>_iface ::= list of <iface>
# IFACE_<list>_bus ::= list of 'NA' | 'pci' | 'usb' | ...
# Similarly as above for each member of <list>.
# IFACE_wireless_phy ::= list of 'phy'<integer>
# IFACE_wireless_rfkill_index ::= list of <integer> for rfkill command

# <bus> ::= 'pci' | 'usb' | 'other'
# <bus_which> ::= <integer> >= 0
# BUS_<bus>_n ::= '0' .. number of <bus> network interfaces detected
# BUS_<bus_which> ::= list of <integer> (enumeration index [0..BUS_<bus>_n - 1])
# BUS_<bus> ::= list of <list>':'<list_which> for a given <bus>

enum_interfaces() # {{{1
{
	local p x bus list which
	IFACE_other_n=0 IFACE_wired_n=0 IFACE_wireless_n=0
	unset IFACE_other_which IFACE_wired_which IFACE_wireless_which
	unset IFACE_other_path IFACE_wired_path IFACE_wireless_path
	unset IFACE_other_iface IFACE_wired_iface IFACE_wireless_iface
	unset IFACE_other_bus IFACE_wired_bus IFACE_wireless_bus
	unset IFACE_wireless_phy IFACE_wireless_rfkill_index
	BUS_other_n=0 BUS_pci_n=0 BUS_usb_n=0
	unset BUS_other_which BUS_pci_which BUS_usb_which
	for p in /sys/class/net/*; do
		case $p in *\* ) return 1 ;; esac # no interfaces
		x=$(ls -l $p/device/subsystem 2>/dev/null)
		bus=${x##*/}
		bus=${bus:-NA}
		case ${p##*/} in
			lo|teredo)
				list=other which=$IFACE_other_n
				IFACE_other_which="$IFACE_other_which $IFACE_other_n"
				IFACE_other_n=$(($IFACE_other_n + 1))
				IFACE_other_path="$IFACE_other_path $p"
				IFACE_other_iface="$IFACE_other_iface ${p##*/}"
				IFACE_other_bus="$IFACE_other_bus $bus"
				;;
			*)
				if [ -e $p/wireless ]; then
					list=wireless which=$IFACE_wireless_n
					IFACE_wireless_which="$IFACE_wireless_which $IFACE_wireless_n"
					IFACE_wireless_n=$(($IFACE_wireless_n + 1))
					IFACE_wireless_path="$IFACE_wireless_path $p"
					IFACE_wireless_iface="$IFACE_wireless_iface ${p##*/}"
					IFACE_wireless_bus="$IFACE_wireless_bus $bus"
					read x < $p/phy80211/name
					IFACE_wireless_phy="$IFACE_wireless_phy ${x:-NA}"
					for x in $p/phy80211/rfkill*/index; do read x < $x; done
					IFACE_wireless_rfkill_index="$IFACE_wireless_rfkill_index ${x:-NA}"
				else
					list=wired which=$IFACE_wired_n
					IFACE_wired_which="$IFACE_wired_which $IFACE_wired_n"
					IFACE_wired_n=$(($IFACE_wired_n + 1))
					IFACE_wired_path="$IFACE_wired_path $p"
					IFACE_wired_iface="$IFACE_wired_iface ${p##*/}"
					IFACE_wired_bus="$IFACE_wired_bus $bus"
				fi
				;;
		esac
		case $bus in
			pci )
				BUS_pci_which="$BUS_pci_which $BUS_pci_n"
				BUS_pci_n=$(($BUS_pci_n + 1))
				BUS_pci="$BUS_pci $list:$which"
				;;
			usb )
				BUS_usb_which="$BUS_usb_which $BUS_usb_n"
				BUS_usb_n=$(($BUS_usb_n + 1))
				BUS_usb="$BUS_usb $list:$which"
				;;
			* )
				BUS_other_which="$BUS_other_which $BUS_other_n"
				BUS_other_n=$(($BUS_other_n + 1))
				BUS_other="$BUS_other $list:$which"
				;;
		esac
	done
}
# {{{1}}}
# IFACE_list ::= 'other' | 'wireless' | 'wired'
# IFACE_which ::= '0' .. IFACE_<IFACE_list>_n - 1
# IFACE_path ::= <IFACE_which>'th element of IFACE_<IFACE_list>_path
# IFACE_iface ::= <IFACE_which>'th element of IFACE_<IFACE_list>_iface (basename of IFACE_path)
# IFACE_bus ::= 'NA' | <IFACE_which>'th element of IFACE_<IFACE_list>_bus
# Ditto for IFACE_phy and IFACE_rfkill_index when IFACE_list == 'wireless'

init_get_iface() # {{{1
{
	unset IFACE_list IFACE_which IFACE_iface
	unset IFACE_path IFACE_bus
	unset IFACE_phy IFACE_rfkill_index
}

get_iface_other() # [--export] $1-which {{{1
{
	local opt_e which
	if [ "$1" = --export ]; then opt_e=echo; shift; fi
	which=${1:-error}
	init_get_iface
	[ $which = error -o $which -gt $IFACE_other_n ] && return 1
	IFACE_list=other # begin
	set -- $IFACE_other_path; shift $which; IFACE_path=$1
	set -- $IFACE_other_iface; shift $which; IFACE_iface=$1
	set -- $IFACE_other_bus; shift $which; IFACE_bus=$1
	IFACE_which=$which # end
  [ "$opt_e" ] && printf "%s='%s'\n" IFACE_list $IFACE_list IFACE_path $IFACE_path IFACE_iface $IFACE_iface IFACE_bus $IFACE_bus IFACE_which $IFACE_which
}

get_iface_wireless() # [--export] $1-which {{{1
{
	local opt_e which
	if [ "$1" = --export ]; then opt_e=echo; shift; fi
	which=${1:-error}
	init_get_iface
	[ $which = error -o $which -gt $IFACE_wireless_n ] && return 1
	IFACE_list=wireless # begin
	set -- $IFACE_wireless_path; shift $which; IFACE_path=$1
	set -- $IFACE_wireless_iface; shift $which; IFACE_iface=$1
	set -- $IFACE_wireless_bus; shift $which; IFACE_bus=$1
	set -- $IFACE_wireless_phy; shift $which; IFACE_phy=$1
	set -- $IFACE_wireless_rfkill_index; shift $which; IFACE_rfkill_index=$1
	IFACE_which=$which # end
  [ "$opt_e" ] && printf "%s='%s'\n" IFACE_list $IFACE_list IFACE_path $IFACE_path IFACE_iface $IFACE_iface IFACE_bus $IFACE_bus IFACE_phy $IFACE_phy IFACE_rfkill_index $IFACE_rfkill_index IFACE_which $IFACE_which
}


get_iface_wired() # [--export] $1-which {{{1
{
	local opt_e which
	if [ "$1" = --export ]; then opt_e=echo; shift; fi
	which=${1:-error}
	init_get_iface
	[ $which = error -o $which -gt $IFACE_wired_n ] && return 1
	IFACE_list=wired # begin
	set -- $IFACE_wired_path; shift $which; IFACE_path=$1
	set -- $IFACE_wired_iface; shift $which; IFACE_iface=$1
	set -- $IFACE_wired_bus; shift $which; IFACE_bus=$1
	IFACE_which=$which # end
  [ "$opt_e" ] && printf "%s='%s'\n" IFACE_list $IFACE_list IFACE_path $IFACE_path IFACE_iface $IFACE_iface IFACE_bus $IFACE_bus IFACE_which $IFACE_which
}

get_iface_by_bus() # [--export] $1-list:which {{{1
{
	local opt_e list which
	if [ "$1" = --export ]; then opt_e=echo; shift; fi
	list=${1%:*} which=${1#*:}
	case $list in
		other ) get_iface_other $which ;;
		wireless ) get_iface_wireless $which ;;
		wired ) get_iface_wired $which ;;
	esac
}
