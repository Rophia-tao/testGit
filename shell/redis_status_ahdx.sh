MYNAME=`basename $0`
#DEBUG_FLAG=DEBUG
DEBUG_FLAG=""

status_help()
{
echo -e "\n usage : $MYNAME [option] "
echo " demo  : $MYNAME -v ##节点状态"
echo " demo  : $MYNAME -m ##节点内存使用率"
echo " demo  : $MYNAME -s ##节点链接数 "
echo ""
}

IP_LIST="172.21.5.110 172.21.5.111 172.21.5.112"
PORT_LIST="7000 7001 7002 7003"
TMP_LOG=./tmp_check.log

>$TMP_LOG

_echo()
{
if [ "x$DEBUG_FLAG" = "xDEBUG" ]
then
        echo "$*"
fi
}

status_s()
{
for T_IP in $IP_LIST
do
        for T_PORT in $PORT_LIST
        do
                echo -n "$T_IP:$T_PORT  "
                $REDIS_HOME/bin/redis-cli -h $T_IP -p $T_PORT info Clients |grep connected_clients
        done
done
echo ""
}
status_v()
{

for T_IP in $IP_LIST
do
        for T_PORT in $PORT_LIST
        do
                echo "redis-cli -h $T_IP -p $T_PORT cluster nodes"
                $REDIS_HOME/bin/redis-cli -h $T_IP -p $T_PORT cluster nodes >> $TMP_LOG 2>&1
                if [ $? -eq 0 ]
                then
                        b_flag=1;break;
                else
                        echo "checkfailed ! $T_IP:$T_PORT"
                fi
        done
        if [ "x$b_flag" = "x1" ]; then break ;fi
done

echo ""
date +"             ##########    节点状态 %Y-%m-%d %H:%M:%S    ##########"
echo -e "\n----------------------------------------------------------------------------------"
printf "%-10s %-25s %-25s %-9s %-9s\n" "节点" "主库" "备库" "主库状态" "备库状态"

cat $TMP_LOG|awk 'BEGIN{mnum=0;snum=0;err_flag=0}{
 if(substr($3,1,6)=="master"|| substr($3,8,6)=="master"){ mast[$1]=$2; Mstat[$1]=("connected"==$(NF-1))?"Y":"N";hash[mnum]=$1;mnum++}else 
 if(substr($3,1,5)=="slave" || substr($3,8,5)=="slave" ){ slav[$4]=$2; Sstat[$4]=("connected"==$NF    )?"Y":"N";snum++}else {print $0}
}END{
 if(mnum==snum){ max=mnum }else 
 if(mnum  if(mnum>snum) { max=mnum ; no_s_flag=1;};
 for(i=0;i    if( Mstat[hash[i]]=="N" || Sstat[hash[i]]=="N" ){ printf "\033[1;31m" ; err_flag=1}
   printf("rd%02d       %-25s %-25s %-9s %-9s\n",i+1,mast[hash[i]],slav[hash[i]], Mstat[hash[i]],Sstat[hash[i]]);
   if( Mstat[hash[i]]=="N" || Sstat[hash[i]]=="N" ) printf "\033[0m"
 }
 if(err_flag==1){printf("\nsome nodes disconnected\n\n");exit 1}
}'
if [ $? == 1 ] ;then status_s |grep -v connected_clients ; fi
#cat $TMP_LOG
rm $TMP_LOG
}

status_m()
{
TOU1="HOST_IP"; TOU2="PORT"
printf "%15s:%-5s   总大小   内存大小   使用率  主机总内存\n" $TOU1 $TOU2
echo "----------------------------------------------------------------"
for T_IP in $IP_LIST
do
        for T_PORT in $PORT_LIST
        do
                _echo "T_IP=$T_IP T_PORT$T_PORT"
                MEMORY_INFO=`$REDIS_HOME/bin/redis-cli  -h $T_IP -p $T_PORT info memory `
                M_used=`echo "$MEMORY_INFO"|grep  used_memory_human:|awk -F: '{print $2}'|sed 's/\r//'`
                M_used_size=`echo "$MEMORY_INFO"|grep  used_memory:|awk -F: '{print $2}'|sed 's/\r//'`
                M_Host_TT=`echo "$MEMORY_INFO"|grep  total_system_memory_human:|awk -F: '{print $2}'|sed 's/\r//'`
                M_TT_set=`echo "$MEMORY_INFO"|grep  maxmemory_human:|awk -F: '{print $2}'|sed 's/\r//'`
                M_TT_size=`echo "$MEMORY_INFO"|grep  maxmemory:|awk -F: '{print $2}'|sed 's/\r//'`
                if [ "x$M_used" = "x" ] || [ "x$M_Host_TT" = "x" ] 
                then
                        echo -e "used=$M_used or total=$M_Host_TT size is null !! please check: $MEMORY_INFO \n $REDIS_HOME/bin/redis-cli  -h $T_IP -p $T_PORT info memory"
                        continue
                fi

                printf "%15s:%-5s  %8s %8s %8.2f%% %8s \n" $T_IP $T_PORT $M_TT_set $M_used $(($M_used_size*100/$M_TT_size)) $M_Host_TT
        done
done
echo "----------------------------------------------------------------"
}

if [ $# -lt 1 ] || [ "$1" = "-h" ] || [ "$1" = "--help" ]
then
        status_help
        exit 1
fi

if [ "$1" = "-m" ]
then
        status_m