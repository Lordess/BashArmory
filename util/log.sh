#function log_info() <msg> {{{
function log_info() { date +"[%F %T] [INFO] $1" | tee -a $LOG_FILE ; } #}}}
#function log_warn() <msg> {{{
function log_warn() { date +"[%F %T] [WARN] $1" | tee -a $LOG_FILE ; } #}}}
#function log_error() <msg> {{{
function log_error() { date +"[%F %T] [ERROR] $1" | tee -a $LOG_FILE ; } #}}}

#function log_mysqlrpladmin <log_file> switchover|failover
#stdin  : log stream of the stdout of a mysqlrpladmin
#stdout : log stream in "[yyyy-mm-dd HH:MM:SS] - <log_entry>" format
#return : 0 for mysqlrpladmin suceeded its task
#         1 for mysqlrpladmin failed its task
#{{{
function log_mysqlrpladmin() {
case "$2" in
"switchover")
	gawk -v isSuccessful=0 -v log_file=$1 '
/^# Switchover complete./ { isSuccessful=1 ; }
/^WARNING: Using a password on the command line interface can be insecure./ { next ; }
{ s_time=strftime("%Y-%m-%d %H:%M:%S") ;
	printf "[%s] mysqlrpladmin %s\n",s_time,$0 >> log_file ; 
  printf "[%s] - %s\n",s_time,$0 ; }
END { if(isSuccessful) exit 0 ; else exit 1 ; }'
;;
"failover")
	gawk -v isSuccessful=0 -v log_file=$1 '
/^# Failover complete./ { isSuccessful=1 ; }
/^WARNING: Using a password on the command line interface can be insecure./ { next ; }
{ s_time=strftime("%Y-%m-%d %H:%M:%S") ;
	printf "[%s] mysqlrpladmin %s\n",s_time,$0 >> log_file ; 
  printf "[%s] - %s\n",s_time,$0 ; }
END { if(isSuccessful) exit 0 ; else exit 1 ; }'
;;
esac
} #}}}