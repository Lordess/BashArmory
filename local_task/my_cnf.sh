##function UpdateMySQLConfig <my_cnf_file> <local_node_role>
#function UpdateMySQLConfig()
#{
#
##"server-id"
##	"read_only"
##	"innodb_buffer_pool_size"
##	"innodb_thread_concurrency")
##	
##		innodb_buffer_pool_size="`sed -nre "s/MemTotal:[ \t]*([0-9]+)[ \t]*kB/\1/p" /proc/meminfo | awk '{ printf "%d\n",$1*0.7}'`K"
##	innodb_thread_concurrency="$((`grep -cE "^processor" /proc/cpuinfo` * 2 + 1))"
#
#	local my_cnf_file="$1"
#	local local_node_role="$2"
#	
#	local last_mysqld_blk_last_line=0 ln_readonly=0 \
#		ln_ib_buf_pool_size=0 ln_ib_thd_con=0
#
##get the line numbers of configs in my.cnf
#read last_mysqld_blk_last_line ln_readonly \
#	ln_ib_buf_pool_size ln_ib_thd_con < <(gawk '
#BEGIN {
#	ln_readonly=0; ln_ib_buf_pool_size=0; ln_ib_thd_con=0; 
#	in_mysqld_block=0; last_mysqld_blk_last_line=0; }
#
#/^[[:blank:]]*\[[^\[\]]*\][[:blank:]]*$/ {
#	if ($0 ~ /\[mysqld\]/) { 
#		in_mysqld_block=1; }
#	else {
#		if(in_mysqld_block) { 
#			last_mysqld_blk_last_line=FNR-1; in_mysqld_block=0;}}}
#
#/^read_only[[:blank:]]*=[[:blank:]]*[01][[:blank:]]*$/ {
#	if(in_mysqld_block) {ln_readonly=FNR; }}
#
#/^innodb_buffer_pool_size[[:blank:]]*=[[:blank:]]*[1-9][0-9]*[BbKkMmGg]?[[:blank:]]*$/ {
#	if(in_mysqld_block) {ln_ib_buf_pool_size=FNR; }}
#
#/^innodb_thread_concurrency[[:blank:]]*=[[:blank:]]*[1-9][0-9]*[[:blank:]]*$/ {
#	if(in_mysqld_block) {ln_ib_thd_con=FNR; }}
#
#END {
#	if (in_mysqld_block) last_mysqld_blk_last_line=FNR;
#	if(!ln_readonly) ln_readonly=last_mysqld_blk_last_line;
#	if(!ln_ib_buf_pool_size) ln_ib_buf_pool_size=last_mysqld_blk_last_line;
#	if(!ln_ib_thd_con) ln_ib_thd_con=last_mysqld_blk_last_line;
#	printf "%d %d %d %d\n", last_mysqld_blk_last_line, ln_readonly, ln_ib_buf_pool_size, ln_ib_thd_con;}
#' awk.test)
#
##resolve user configs
##TODO:
#v_readonly=1
#v_ib_buf_pool_size=200
#v_ib_thd_con=5
#
##update configs in in my.cnf
##TODO: 
#cat << EOF > awk.test
#`gawk -v last_mysqld_blk_last_line=$last_mysqld_blk_last_line \
#	-v ln_readonly=$ln_readonly -v ln_ib_buf_pool_size=$ln_ib_buf_pool_size \
#	-v ln_ib_thd_con=$ln_ib_thd_con \
#	-v v_readonly=$v_readonly -v v_ib_buf_pool_size=$v_ib_buf_pool_size '
#{
#	if(FNR==ln_readonly)
#		{ printf "read_only\t=\t%s\n", v_readonly; next; }
#	if(FNR==ln_ib_buf_pool_size)
#		{ printf "innodb_buffer_pool_size\t=\t%s\n", v_ib_buf_pool_size; next; }
#	if(FNR==ln_ib_thd_con)
#		{ printf "innodb_thread_concurrency\t=\t%s\n", v_ib_thd_con; next; }
#	print;
#} 
#' awk.test`
#EOF
#
##set 
#
#}

#function set_my_cnf_readonly <my_cnf_file> RO|RW
#reutrn: 0 for sucess
#        1 for error 
#{{{
function set_my_cnf_readonly() {

	local my_cnf_file="$1"
	local readonly_flag="$2"
	
	local last_mysqld_blk_last_line ln_readonly
	
	#check if my.cnf readable and writable
	if [[ ! -r "$my_cnf_file" ]] || [[ ! -w "$my_cnf_file" ]]; then
		log_error "my.cnf($my_cnf_file) should be readable and writable"
		return 1
	fi
	
	#resolve readonly flag
	case "$readonly_flag" in
	"RO") readonly_flag=1 ;;
	"RW") readonly_flag=0 ;;
	"*") 
		log_error "set_my_cnf_readonly(): 2nd argument(\"readonly_flag\") can only be RO or RW"
		return 1
	;;
	esac
	
	#get the line numbers of configs in my.cnf
	read last_mysqld_blk_last_line ln_readonly < <(gawk '
BEGIN {
	ln_readonly=0; in_mysqld_block=0; last_mysqld_blk_last_line=0; }

/^[[:blank:]]*\[[^\[\]]*\][[:blank:]]*$/ {
	if ($0 ~ /\[mysqld\]/) { 
		in_mysqld_block=1; }
	else {
		if(in_mysqld_block) { 
			last_mysqld_blk_last_line=FNR-1; in_mysqld_block=0;}}}

/^read_only[[:blank:]]*=[[:blank:]]*[01][[:blank:]]*$/ {
	if(in_mysqld_block) {ln_readonly=FNR; }}

END {
	if(in_mysqld_block) last_mysqld_blk_last_line=FNR;
	if(!last_mysqld_blk_last_line) { print "NO_MYSQLD_BLK"; exit 1; }
	if(!ln_readonly) ln_readonly=last_mysqld_blk_last_line;
	printf "%d %d\n", last_mysqld_blk_last_line, ln_readonly;}
' "$my_cnf_file")

	if [[ "$last_mysqld_blk_last_line" == "NO_MYSQLD_BLK" ]]; then
		log_error "[mysqld] block not found in my.cnf($my_cnf_file)"
		return 1
	fi

	#update configs in in my.cnf
	cat << EOF > "$my_cnf_file"
`gawk -v last_mysqld_blk_last_line=$last_mysqld_blk_last_line \
	-v ln_readonly=$ln_readonly -v v_readonly=$readonly_flag '
BEGIN { config_prefix=""; }
{
	if(FNR==ln_readonly) {
		if(last_mysqld_blk_last_line==ln_readonly && \
			!match($0, /^read_only[[:blank:]]*=[[:blank:]]*[01][[:blank:]]*$/))
			print;
		printf "read_only\t=\t%d\n", v_readonly;
		next;
	}
	print;
}
' "$my_cnf_file"`
EOF

	if [[ $? -ne 0 ]]; then
		log_warn "something wrong in setting read_only=$readonly_flag in my.cnf($my_cnf_file)"
		reutrn 1
	fi
	log_info "set read_only=$readonly_flag in my.cnf($my_cnf_file)"
	return 0
} #}}}

#function get_config_by_mysqld <mysqld_file> <my_cnf_file> <config_name>
#stdout: <config_value> if found
#        "" if not found
#return: 0 for found
#        1 for not found or other errors
#{{{
function get_config_by_mysqld() {
	$1 --defaults-file=$2 -v -? | gawk -v found=1 -v cfg_name=$3 '
/^-+ +-+$/ { 
	#duel with cfg_name has "-" or "_" in it
	if ( cfg_name ~ /-/ )
		cfg_name_alias=gensub(/-/, "_", "g", cfg_name);
	else
		cfg_name_alias=gensub(/_/, "-", "g", cfg_name);
	while( $0 != "") {
		getline; sub(/ +/, " "); 
		if($1 == cfg_name || $1 == cfg_name_alias ) { print $2; found=0; nextfile; }
	}
}
END { exit found; }'
} #}}}

ps --no-header -wwo pid,args -C mysqld | sed -nre 's/^ *([0-9]+) .* --port=3321.*$/\1/p'