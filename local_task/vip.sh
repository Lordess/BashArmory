#function get_dev_mask_by_ip <ip>
#stdout : "<dev> <netmask>"
#{{{
function get_dev_mask_by_ip() {
	ip -4 -o a s scope global | tr -s ' ' | \
		sed -nre "s#.* ([a-z0-9]+) inet ${1//\./\\.}/([0-9]|[1-3][0-9]) .*#\1 \2#p"
} #}}}

#function get_gw_by_dev <dev>
#stdout : "<gateway_address>"
#{{{
function get_gw_by_dev() {
	ip -4 -o route show scope global dev "$1" | \
		sed -nre "s#.* via (([0-9]{1,3}\.){3}[0-9]{1,3}) .*#\1#p"
} #}}}

#function get_meta_by_ip <ip>
#stdout : <metadata> in "<dev> <netmask_len> <gateway>" format
#         "FAILED_TO_GET_DEV_NETMASK" when cannot get dev and/or netmask by ip
#         "FAILED_TO_GET_GW" when cannot get gateway by dev
#return : 0 for successful
#         1 for error 
#{{{
function get_meta_by_ip() {
	local vip="$1"
	
	local dev="" mask_len="" gw=""
	
	read dev mask_len < <( get_dev_mask_by_ip "$vip" )
	if [[ -z "$dev" || -z "$mask_len" ]]; then
		echo "FAILED_TO_GET_DEV_NETMASK"
		return 1
	fi
	
	gw="`get_gw_by_dev "$dev"`"
	if [[ -z "$gw" ]]; then
		echo "FAILED_TO_GET_GW"
		return 1
	fi
	
	echo "$dev $mask_len $gw"
	return 0
} #}}}

#function local_remove_vip <vip>
#return : 0 for successful
#         1 for error  
#{{{
function local_remove_vip() {

	local vip="$1"

	local dev="" mask_len="" gw=""
	local ip_meta=""
	
	#detect vip and get metadata of it
	if ! ip_meta="`get_meta_by_ip "$vip"`" ; then
		log_warn "it seems no vip($vip) here"
		return 0
	fi
	read dev mask_len gw <<<"$ip_meta"
	
	#remove vip
	if ! ip -4 a d "$vip"/"$mask_len" dev "$dev" label "$dev":vip_man ; then
		log_error "failed in removing vip($vip)"
		return 1
	fi
	log_info "removed vip($vip) here"
	
	#free arp gratuitous
	arping -c 1 -I "$dev" "$vip" 1>/dev/null
	log_info "sent arp gratuitous sot that neighbours to refresh their own arp caches of vip($vip)"
	return 0
} #}}}

#function local_bind_vip <physical_ip> <vip>
#return : 0 for successful
#         1 for error  
#{{{
function local_bind_vip() {
	local pip="$1" vip="$2"
	
	local dev="" mask_len="" gw=""
	local ip_meta=""
	
	#detect vip
	if ip_meta="`get_meta_by_ip "$vip"`" ; then
		log_warn "it seems the vip($vip) is already here"
		return 0
	fi

	#get metadata from specified ip and its interface(dev)
	if ! ip_meta="`get_meta_by_ip "$pip"`" ; then
		log_error "it seems no physical ip($pip) here"
		return 1
	fi
	read dev mask_len gw <<<"$ip_meta"

	#bind vip
	if ! ip -4 a a "$vip"/"$mask_len" dev "$dev" label "$dev":vip_man ; then
		log_error "failed in binding vip($vip)"
		return 1
	fi
	log_info "bound vip($vip) here"
	
	#free arp gratuitous
	if ! arping -c 1 -I "$dev" -U "$vip" 1>/dev/null ; then
		log_warn "failed to sent arp gratuitous for vip($vip), but the program will continue"
		return 0
	fi
	log_info "sent arp gratuitous sot that neighbours to refresh their own arp caches of vip($vip)"
	return 0
} #}}}