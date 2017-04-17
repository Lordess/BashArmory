#function decode_host_string <host_string>
#stdout : <user> <password> <host> <port> of "<user>[:<password>]@<host>:<port>" format
#         if no password, <password> will be "<NO_PASS>"
#{{{
function decode_host_string() {
	sed -nr \
-e "s/^([[:alnum:]._-]+)(:([[:alnum:]._-]+))@(([0-9]{1,3}\.){3}[0-9]{1,3}):([1-9][0-9]*)$/\1 \3 \4 \6/p" \
-e "s/^([[:alnum:]._-]+)@(([0-9]{1,3}\.){3}[0-9]{1,3}):([1-9][0-9]*)$/\1 <NO_PASS> \2 \4/p" <<<"$1"
} #}}}