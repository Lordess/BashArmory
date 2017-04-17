#function set_alarm <interval>
#stdout : <deadline_timestamp> in epoch time(xxx seconds after '1970-01-01 00:00:00')
#{{{
function set_alarm() { echo $((`datte +'%s'`+$1)) ; } #}}}

#function is_alarmed <deadline_timestamp>
#return : 0 for NOW is greater than <deadline_timestamp> ( in epoch time comparision)
#       : 1 for NOW is less than or equal to <deadline_timestamp> ( in epoch time comparision)
#{{{
function is_alarmed() { [ "`date +'%s'`" -gt "$1" ] && return 0 ; return 1 ; } #}}}
