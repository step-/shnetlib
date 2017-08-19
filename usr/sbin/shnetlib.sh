# Compatible sh bash busybox-ash dash
# Copyright (C) 2017 step
# License: GNU GPL2
# Version 1.0.0
# Homepage: https://github.com/step-/shnetlib

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
# IFACE_wireless_rfkill_index ::= list of (<integer>|'NA') for rfkill command

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
					case x in *\** ) x=NA ;; esac
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
# When SHNETLIB_MODE==detailed also:
#  IFACE_module_path ::= 'NA' | driver module path
# When IFACE_list == 'wireless' also:
#  IFACE_phy ::= 'phy'<digit>
#  IFACE_rfkill_index ::= 'NA' | <digit> (unrelated to phy above)
#  and if the driver module supports rfkill (IFACE_rfkill_index != 'NA'):
#  IFACE_rfkill_state ::= <digit>, '1'(enabled) <>'1'(disabled:reason)
#  IFACE_rfkill_soft ::= '0'|'1', '0'(unblocked), '1'(soft-blocked)
#  IFACE_rfkill_hard ::= '0'|'1', '0'(unblocked), '1'(hard-blocked)

init_get_iface() # {{{1
{
	unset IFACE_list IFACE_which IFACE_iface
	unset IFACE_path IFACE_bus
	IFACE_module_path=NA
	unset IFACE_phy IFACE_rfkill_index
	unset IFACE_rfkill_hard IFACE_rfkill_soft IFACE_rfkill_state
}

get_iface_details_common() # $1-iface_path => $IFACE_module_path {{{1
{
	local path=$1 p
	if [ detailed = "$SHNETLIB_MODE" ]; then
		p=$path/device/driver/module
		[ -L $p ] && IFACE_module_path=$(readlink -f $p)
	fi
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
	get_iface_details_common $IFACE_path
	IFACE_which=$which # end
	[ "$opt_e" ] && printf "%s='%s'\n" IFACE_list $IFACE_list \
		IFACE_path $IFACE_path IFACE_iface $IFACE_iface IFACE_bus $IFACE_bus \
		IFACE_module_path "$IFACE_module_path" \
		IFACE_which $IFACE_which
}

get_iface_wireless() # [--export] $1-which {{{1
{
	local opt_e which p
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
	get_iface_details_common $IFACE_path
	if ! [ NA = $IFACE_rfkill_index ]; then
		p=$IFACE_path/phy80211/rfkill$IFACE_rfkill_index
		read IFACE_rfkill_hard < $p/hard
		read IFACE_rfkill_soft < $p/soft
		read IFACE_rfkill_state < $p/state
	fi
	IFACE_which=$which # end
	if [ "$opt_e" ]; then
		printf "%s='%s'\n" IFACE_list $IFACE_list \
		IFACE_path $IFACE_path IFACE_iface $IFACE_iface IFACE_bus $IFACE_bus \
		IFACE_module_path "$IFACE_module_path" \
		IFACE_phy $IFACE_phy IFACE_rfkill_index $IFACE_rfkill_index
		if ! [ NA = $IFACE_rfkill_index ]; then
			printf "%s='%s'\n" \
			IFACE_rfkill_hard $IFACE_rfkill_hard IFACE_rfkill_soft $IFACE_rfkill_soft \
			IFACE_rfkill_state $IFACE_rfkill_state
		fi
		printf "%s='%s'\n" IFACE_which $IFACE_which
	fi
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
	get_iface_details_common $IFACE_path
	IFACE_which=$which # end
	[ "$opt_e" ] && printf "%s='%s'\n" IFACE_list $IFACE_list \
		IFACE_path $IFACE_path IFACE_iface $IFACE_iface IFACE_bus $IFACE_bus \
		IFACE_module_path "$IFACE_module_path" \
		IFACE_which $IFACE_which
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
