#!/bin/dash
# Compatible /bin/sh /bin/bash busybox ash
# Copyright (C) 2017 step
# License: GPL2

# This file is sourced, not run.

set +f

# {{{1}}}
# <path> ::= paths '/sys/class/net/'*
# <iface> ::= basenames '/sys/class/net/'*
# <list> ::= 'other' | 'wireless' | 'wired'
# <list_which> ::= <integer> >= 0
# IFACE_<list>_n ::= '0' .. number of <list> interfaces detected
# IFACE_<list>_which ::= list of <list_which> (enumeration index [0..IFACE_<list>_n - 1])
# IFACE_<list>_path ::= <path>
# IFACE_<list>_bus ::= list of 'NA' | 'pci' | 'usb' | ...
# Similarly as above for each member of <list>.
# IFACE_wireless_phy ::= list of 'phy'<integer>
# IFACE_wireless_rfkill_index ::= list of <integer> for rfkill command

enum_interfaces() # {{{1
{
	local p x bus list which
	IFACE_other_n=0 IFACE_wired_n=0 IFACE_wireless_n=0
	unset IFACE_other_which IFACE_wired_which IFACE_wireless_which # [0..$IFACE_<>_n - 1]
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
				list=other which=$IFACE_other_n
				IFACE_other_which="$IFACE_other_which $IFACE_other_n"
				IFACE_other_n=$(($IFACE_other_n + 1))
				IFACE_other_path="$IFACE_other_path $p"
				IFACE_other_bus="$IFACE_other_bus $bus"
				;;
			*)
				if [ -e $p/wireless ]; then
					list=wireless which=$IFACE_wireless_n
					IFACE_wireless_which="$IFACE_wireless_which $IFACE_wireless_n"
					IFACE_wireless_n=$(($IFACE_wireless_n + 1))
					IFACE_wireless_path="$IFACE_wireless_path $p"
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

get_iface_other() # [--export] $1-which {{{1
{
	local opt_e which
	if [ "$1" = --export ]; then opt_e=echo; shift; fi
	which=${1:-error}
	init_get_iface
	[ $which = error -o $which -gt $IFACE_other_n ] && return 1
	$opt_e IFACE_list=other # begin
	set -- $IFACE_other_path; shift $which; $opt_e IFACE_path=$1
	$opt_e IFACE_iface=${IFACE_other_path##*/}
	set -- $IFACE_other_bus; shift $which; $opt_e IFACE_bus=$1
	$opt_e IFACE_which=$which # end
}

get_iface_wireless() # [--export] $1-which {{{1
{
	local opt_e which
	if [ "$1" = --export ]; then opt_e=echo; shift; fi
	which=${1:-error}
	init_get_iface
	[ $which = error -o $which -gt $IFACE_wireless_n ] && return 1
	$opt_e IFACE_list=wireless # begin
	set -- $IFACE_wireless_path; shift $which; $opt_e IFACE_path=$1
	$opt_e IFACE_iface=${IFACE_wireless_path##*/}
	set -- $IFACE_wireless_bus; shift $which; $opt_e IFACE_bus=$1
	set -- $IFACE_wireless_phy; shift $which; $opt_e IFACE_phy=$1
	set -- $IFACE_wireless_rfkill_index; shift $which; $opt_e IFACE_rfkill_index=$1
	$opt_e IFACE_which=$which # end
}


get_iface_wired() # [--export] $1-which {{{1
{
	local opt_e which
	if [ "$1" = --export ]; then opt_e=echo; shift; fi
	which=${1:-error}
	init_get_iface
	[ $which = error -o $which -gt $IFACE_wired_n ] && return 1
	$opt_e IFACE_list=wired # begin
	set -- $IFACE_wired_path; shift $which; $opt_e IFACE_path=$1
	$opt_e IFACE_iface=${IFACE_wired_path##*/}
	set -- $IFACE_wired_bus; shift $which; $opt_e IFACE_bus=$1
	$opt_e IFACE_which=$which # end
}

