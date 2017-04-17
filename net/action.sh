#usage: net_listen <listen_port> <timeout_in_second>
#return : 0 for successful
#         1 for error
#{{{
function net_listen()
{
  netcat -l -w ${2} -p ${1} 2>/dev/null
} #}}}

#usage: net_send <remote_ip> <remote_port> <send_msg> <timeout_in_second>
#return : 0 for successful
#         1 for error
#{{{
function net_send()
{
  for ((i=0; i<${4}; i++));
  do
    echo "$3" | netcat $1 $2 >/dev/null 2>&1 && return 0
    sleep 1
  done
  return 1
} #}}}

#function get_net_msg <listen_port> <timeout_in_second>
#stdout : <net_msg> which may has space
#         "FAILED" for net_listen() failed 
#{{{
function get_net_msg() {
	local listen_port="$1"
	local timeout="$2"
	
	local net_msg="`net_listen $listen_port ${timeout}`"
	local net_ret=$?
	
	if [[ $net_ret -ne 0 ]]; then
		echo "FAILED"
	else
		echo "$net_msg"
	fi
} #}}}

#function net_sync <listen_port> <remote_ip> <remote_port> <timeout_in_second> <send_msg> <wait_msg>
#return : 0 for success
#         1 for failure
#{{{
function net_sync()
{
	local ret_val

	net_send $2 $3 "$5" "$4" &
	ret_val="x`net_listen $1 $4`"

	wait %net_send
	if [ $? -ne 0 ]; then
		Log "Failed to send \"$5\" to remote" "ERROR"
		return 1
	elif [ "$ret_val" != "x$6" ]; then
		Log "Expected to receive \"$6\", but got \"${ret_val:6}\" actually." "ERROR"
		return 1
	fi

	return 0
} #}}}