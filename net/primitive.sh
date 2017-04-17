#function decode_net_msg <msg_type> <msg>
#stdout : "FAILED" for invalid message
#         "INVALID_TYPE" for invalid message type
#         <net_msg_args> when suceeded decode the message
#{{{
function decode_net_msg() {

	local net_msg_args=""
	
	case "$1" in
	"SYN") # return <sid> of "SYN <sid>"
		net_msg_args="`sed -nre "s/^SYN ([0-9]+)$/\1/p" 2>/dev/null <<<"$2"`"
		if [[ -z "$net_msg_args" ]]; then
			echo "FAILED"
		else
			echo "$net_msg_args"
		fi
	;;
	"ACK") # return <sid> of "ACK <sid>"
		net_msg_args="`sed -nre "s/^ACK ([0-9]+)$/\1/p" 2>/dev/null <<<"$2"`"
		if [[ -z "$net_msg_args" ]]; then
			echo "FAILED"
		else
			echo "$net_msg_args"
		fi
	;;
	"FIN") # return <return_value> of "FIN <return_value>"
		net_msg_args="`sed -nre "s/^FIN ([0-9]+)$/\1/p" 2>/dev/null <<<"$2"`"
		if [[ -z "$net_msg_args" ]]; then
			echo "FAILED"
		else
			echo "$net_msg_args"
		fi
	;;
	"VIP_OP") # return <cmd> <vip> <timeout> of "VIP_OP <cmd> <vip> <timeout>"
	#tips: comma in regular expression here must be escaped by "\", I am not sure whether sed or bash parser need it
		net_msg_args="`sed -nre "s/^VIP_OP (BD|RM) (([0-9]{1\,3}\.){3}[0-9]{1\,3}) ([0-9]+)$/\1 \2 \4/p" 2>/dev/null <<<"$2"`"
		if [[ -z "$net_msg_args" ]]; then
			echo "FAILED"
		else
			echo "$net_msg_args"
		fi
	;;
	"SET_MY_CNF") #return <config_item> of "SET_MY_CNF <config_item>"
		net_msg_args="`sed -nre "s/^SET_MY_CNF (RO|RW)$/\1/p" 2>/dev/null <<<"$2"`"
		if [[ -z "$net_msg_args" ]]; then
			echo "FAILED"
		else
			echo "$net_msg_args"
		fi
	;;
	"CLONE") # return <msg_rcv_node_type> <another_node_ip> <clone_port> <timeout>
           #  of "CLONE <msg_rcv_node_type> <another_node_ip> <clone_port> <timeout>"
		net_msg_args="`sed -nre "s/^CLONE (SRC|DST) (([0-9]{1\,3}\.){3}[0-9]{1\,3}) ([0-9]+) ([0-9]+)$/\1 \2 \4 \5/p" 2>/dev/null <<<"$2"`"
		if [[ -z "$net_msg_args" ]]; then
			echo "FAILED"
		else
			echo "$net_msg_args"
		fi
	;;
	"PROGRESS") # return <sender_node_type> <message> of "PROGRESS <sender_node_type> <message>"
		net_msg_args="`sed -nre "s/^PROGRESS (SRC|DST) ([[:alnum:] _:\.\[\]-]+)$/\1 \2/p" 2>/dev/null <<<"$2"`"
		if [[ -z "$net_msg_args" ]]; then
			echo "FAILED"
		else
			echo "$net_msg_args"
		fi
	;;
	*) # return "INVALID_TYPE" if it is invalid net message type
		echo "INVALID_TYPE"
		return 1
	esac
	
	return 0
} #}}}

#function encode_net_msg <msg_type> <net_msg_args>
#stdout : "INVALID_TYPE" for invalid message type
#         <net_msg> when suceeded decode the message
#{{{
function encode_net_msg() {
	
	local msg_type="$1"
	shift 1
	
	case "$msg_type" in
	"SYN") # return "SYN <sid>"
		echo "SYN $1"
	;;
	"ACK") # return "ACK <sid>"
		echo "ACK $1"
	;;
	"FIN") # return	"FIN <return_value>"
		echo "FIN $1"
	;;
	"VIP_OP") # return "VIP_OP <cmd> <vip> <timeout>"
						#        <cmd> : BD|RM
		echo "VIP_OP $1 $2 $3"
	;;
	"SET_MY_CNF") #return "SET_MY_CNF <config_item>"
	              #       <config_item> : RO|RW
		echo "SET_MY_CNF $1"
	;;
	"CLONE") # return "CLONE <msg_rcv_node_type> <another_node_ip> <clone_port> <timeout>"
	         #        <msg_rcv_node_type> : SRC|DST
		echo "CLONE $1 $2 $3 $4"
	;;
	"PROGRESS") # return	"PROGRESS <local_node_type> <message>"
		echo "PROGRESS $1 $2"
	;;
	*) # return "INVALID_TYPE" if it is invalid net message type
		echo "INVALID_TYPE"
		return 1
	esac
	
	return 0
	
} #}}}