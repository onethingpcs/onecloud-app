#!/bin/sh

##$1=0 Extranet is not access
##$2=1 Extranet is access and $3 is ip 

m_file=$1
if [ $# -ne 1 ]
then
	exit 1
fi

m_Dir=`dirname $0`
cd $m_Dir
m_Nsl="./nslookup"
m_Wc="/thunder/scripts/wc"

m_tmp1=`cat $m_file |$m_Wc -l`
if [ $m_tmp1 -gt 0 ]
then
	m_flag=1
else
	m_flag=0
fi


f_iptables() {

#m_flag=$1
m_Ip=$1


m_br0=`/sbin/ifconfig |grep br0 -A 1 |grep Bcast |cut -d: -f2 |cut -d\  -f1`
#echo $m_br0
if [ -z $m_br0 ]
then
	exit 0
fi

if [ "$m_br0" = "$m_Ip" ]
then
	exit 2
fi


if [ "$m_flag" -eq 0 ]
then
	#echo $m_flag
  m_flag_2=`/usr/sbin/iptables -t nat -vnL |grep "udp dpt:53" |grep $m_br0 |$m_Wc -l`
  if [ $m_flag_2 -lt 1 ]
  then
		/usr/sbin/iptables -t nat -A PREROUTING -p udp --dport=53 -j DNAT --to $m_br0
  elif [ $m_flag_2 -gt 1 ]
  then
		/usr/sbin/iptables -t nat -D PREROUTING -p udp --dport=53 -j DNAT --to $m_br0
  fi
#	/usr/sbin/iptables -t nat -vnL
	
elif [ "${m_flag}" -eq 1 ]
then
	#echo "$m_flag  $m_Ip"
	/usr/sbin/iptables -t nat -D PREROUTING -p udp --dport=53 -j DNAT --to $m_br0

	m_flag_2=`/usr/sbin/iptables -t nat -vnL |grep "tcp dpt:80" |grep $m_Ip |$m_Wc -l `
	if [ $m_flag_2 -lt 1 ]
	then
		/usr/sbin/iptables -t nat -A PREROUTING  -d $m_Ip -p tcp --dport 80 -j DNAT --to $m_br0 
	elif [ $m_flag_2 -gt 1 ]
	then
		/usr/sbin/iptables -t nat -D PREROUTING  -d $m_Ip -p tcp --dport 80 -j DNAT --to $m_br0 
	fi
else
	/usr/sbin/iptables -t nat -vnL
	exit 1
fi
		

}




if [ $m_flag -eq 1 ]
then
	cat $m_file | while read IP
	do
		echo $IP
		f_iptables  $IP
	done
else
	f_iptables 
fi


/usr/sbin/iptables -t nat -vnL
