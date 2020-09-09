#!/bin/sh
m_br0=`grep www.peiluyou.com /etc/hosts | cut -f1 | cut -d ' ' -f1`

m_Wc="/thunder/scripts/wc"

#echo $m_br0
if [ -z $m_br0 ]
then
	exit 0
fi


m_flag_2=`/usr/sbin/iptables -t nat -vnL |grep "udp dpt:53" |grep $m_br0 |$m_Wc -l`
if [ $m_flag_2 -lt 1 ]
then
  /usr/sbin/iptables -t nat -A PREROUTING -p udp --dport=53 -j DNAT --to $m_br0
elif [ $m_flag_2 -gt 1 ]
then
	/usr/sbin/iptables -t nat -D PREROUTING -p udp --dport=53 -j DNAT --to $m_br0
fi

/usr/sbin/iptables -t nat -vnL

