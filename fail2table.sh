#!/bin/bash

#save the existing filter section, becasue iptables-save does not append
iptables-save > /tmp/ips.txt

#isolate fail2ban rules
cat /tmp/ips.txt | grep f2b > /tmp/f2bRules.txt

#pull out only the filter seciton and set it aside, also remove the f2b rules because they will get added in later
cat /tmp/ips.txt | sed '1,/\*filter/d' | sed -n '/COMMIT/q;p' | sed '/f2b/d' > /tmp/first.txt


#pull all the BAN status that are curently in the fail2ban log and format them correctly for IPTABLES
cat /var/log/fail2ban.log | grep 'Ban' | sed 's/.*Ban /-A INPUT -s /'| sed 's/$/ -j DROP/' >> /tmp/f2b.txt

#add in our original list
cat /tmp/first.txt >> /tmp/f2b.txt

#remove duplicates
cat /tmp/f2b.txt | sort -u > /tmp/tmp.txt

#reformat properly for iptables
echo "*filter" | cat - /tmp/tmp.txt > /tmp/mtmp.txt && mv /tmp/mtmp.txt /tmp/tmp.txt

#add in f2b rule section
cat /tmp/f2bRules.txt >> /tmp/tmp.txt

echo "COMMIT" >> /tmp/tmp.txt

#load the new ip's into the filter section 
iptables-restore < /tmp/tmp.txt

#update the file for persistence 
iptables-save > /etc/iptables/rules.v4


#clean up
rm /tmp/f2b.txt
rm /tmp/ips.txt
rm /tmp/first.txt
rm /tmp/tmp.txt
rm /tmp/f2bRules.txt
