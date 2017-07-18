#!/bin/dash
# Compatible /bin/sh /bin/bash busybox ash
# Copyright (C) 2017 step
# License: GPL2

# This file is sourced, not run.

set +f

# {{{1}}}
# IFACE_other_n ::= '0' .. number of "other" interfaces found.
# IFACE_other_index ::= <integer> [<integer> ...]
# IFACE_other_path ::= list of '/sys/class/net/<iface>'
# IFACE_other_bus ::= list of 'NA' | 'pci' | 'usb' | ...
# Similarly as above for IFACE_wireless_<> and IFACE_wired_<>.
# IFACE_wireless_phy ::= list of 'phy'<integer>
# IFACE_wireless_rfkill_index ::= list of <integer>

enum_interfaces() # {{{1
{
	local p x bus
	IFACE_other_n=0 IFACE_wired_n=0 IFACE_wireless_n=0
	unset IFACE_other_index IFACE_wired_index IFACE_wireless_index # [0..$IFACE_<x>_n - 1]
	unset IFACE_other_path IFACE_wired_path IFACE_wireless_path
	unset IFACE_other_bus IFACE_wired_bus IFACE_wireless_bus
	unset IFACE_wireless_phy IFACE_wireless_rfkill_index
	for p in /sys/class/net/*; do
		case $p in *\* ) return 1 ;; esac # no interfaces
		x=$(ls -l $p/device/subsystem 2>/dev/null)
		bus=${x##*/}
		bus=${bus:-NA}
		case ${p##*/} in
			lo|teredo)
				IFACE_other_index="$IFACE_other_index $IFACE_other_n"
				IFACE_other_n=$(($IFACE_other_n + 1))
				IFACE_other_path="$IFACE_other_path $p"
				IFACE_other_bus="$IFACE_other_bus $bus"
				;;
			*)
				if [ -e $p/wireless ]; then
					IFACE_wireless_index="$IFACE_wireless_index $IFACE_wireless_n"
					IFACE_wireless_n=$(($IFACE_wireless_n + 1))
					IFACE_wireless_path="$IFACE_wireless_path $p"
					IFACE_wireless_bus="$IFACE_wireless_bus $bus"
					read x < $p/phy80211/name
					IFACE_wireless_phy="$IFACE_wireless_phy ${x:-NA}"
					for x in $p/phy80211/rfkill*/index; do read x < $x; done
					IFACE_wireless_rfkill_index="$IFACE_wireless_rfkill_index ${x:-NA}"
				else
					IFACE_wired_index="$IFACE_wired_index $IFACE_wired_n"
					IFACE_wired_n=$(($IFACE_wired_n + 1))
					IFACE_wired_path="$IFACE_wired_path $p"
					IFACE_wired_bus="$IFACE_wired_bus $bus"
				fi
				;;
		esac
	done
}
# {{{1}}}
# IFACE_list ::= 'other' | 'wireless' | 'wired'
# IFACE_which ::= '0' .. IFACE_<IFACE_list>_n - 1
# IFACE_path ::= <IFACE_which>'th element of IFACE_<IFACE_list>_path
# IFACE_iface ::= basename of IFACE_path
# IFACE_bus ::= 'NA' | <IFACE_which>'th element of IFACE_<IFACE_list>_bus
# Ditto for IFACE_phy and IFACE_rfkill_index when IFACE_list == 'wireless'

init_get_iface() # {{{1
{
	unset IFACE_list IFACE_which IFACE_iface
	unset IFACE_path IFACE_bus
	unset IFACE_phy IFACE_rfkill_index
}

get_iface_other() # [-e] $1-index {{{1
{
	local opt_e index
	if [ "$1" = -e ]; then opt_e=echo; shift; fi
	index=${1:-error}
	init_get_iface
	[ $index = error -o $index -gt $IFACE_other_n ] && return 1
	$opt_e IFACE_list=other
	$opt_e IFACE_which=$index
	set -- $IFACE_other_path; shift $index; $opt_e IFACE_path=$1
	$opt_e IFACE_iface=${IFACE_other_path##*/}
	set -- $IFACE_other_bus; shift $index; $opt_e IFACE_bus=$1
}

get_iface_wireless() # [-e] $1-index {{{1
{
	local opt_e index
	if [ "$1" = -e ]; then opt_e=echo; shift; fi
	index=${1:-error}
	init_get_iface
	[ $index = error -o $index -gt $IFACE_wireless_n ] && return 1
	$opt_e IFACE_list=wireless
	$opt_e IFACE_which=$index
	set -- $IFACE_wireless_path; shift $index; $opt_e IFACE_path=$1
	$opt_e IFACE_iface=${IFACE_wireless_path##*/}
	set -- $IFACE_wireless_bus; shift $index; $opt_e IFACE_bus=$1
	set -- $IFACE_wireless_phy; shift $index; $opt_e IFACE_phy=$1
	set -- $IFACE_wireless_rfkill_index; shift $index; $opt_e IFACE_rfkill_index=$1
}


get_iface_wired() # [-e] $1-index {{{1
{
	local opt_e index
	if [ "$1" = -e ]; then opt_e=echo; shift; fi
	index=${1:-error}
	init_get_iface
	[ $index = error -o $index -gt $IFACE_wired_n ] && return 1
	$opt_e IFACE_list=wired
	$opt_e IFACE_which=$index
	set -- $IFACE_wired_path; shift $index; $opt_e IFACE_path=$1
	$opt_e IFACE_iface=${IFACE_wired_path##*/}
	set -- $IFACE_wired_bus; shift $index; $opt_e IFACE_bus=$1
}

