#!/bin/bash
# sorme user communication
echo "Creating $(wc -l acl.txt) access lists"
# calculate the curent highest ACL number
curent_acl_max=$( tmsh list apm acl | grep acl-order | grep -v 999 | awk '{print $2}' | sort -rn | head -1)
echo $curent_acl_max
# set the idex to the next value...
index=`expr $curent_acl_max + 1` # where to insert the ACL
echo $index
# create empty acl command file
cat /dev/null > command_acl.txt
while read p; do
  name=$p
  host=$(echo "$p" | awk -F "_"  '{print $3}')/32
  protocol_name=$(echo "$p" | awk -F "_"  '{print $4}')
  case $protocol_name in
        tcp )
        protocol_nr=6;;
        udp )
        protocol_nr=17;;
        icmp )
        protocol_nr=1;;
        any )
        protocol_nr=0;;
  esac
  total_nr_of_ports=$(echo $p |awk -F'_' '{print NF; exit}')
  nr_of_ports=`expr $total_nr_of_ports - 5`
# print the tmsh command
  printf "tmsh create apm acl $name {  acl-order $index entries { "  >> command_acl.txt
  counter=1
  v=4
  if [ $protocol_nr = 0 ]; then
        printf " { action allow dst-end-port 0 dst-start-port 0 dst-subnet $host protocol $protocol_nr src-subnet 0.0.0.0/0 }"  >> command_acl.txt
  else
     while [[ $counter -le "$nr_of_ports" ]]; do
        port_id=`expr $v + $counter`
        port_number=$(echo "$p" | awk -F "_" -v var="$port_id" '{print $var}')
#       if [ $port_number = "any" ]; then
#         printf " { action allow dst-end-port 0 dst-start-port 0 dst-subnet $host protocol $protocol_nr src-subnet 0.0.0.0/0 }" >> command_acl.txt
          printf " { action allow dst-end-port $port_number dst-start-port $port_number dst-subnet $host protocol $protocol_nr src-subnet 0.0.0.0/0 }" >> command_acl.txt
        counter=$[$counter+1]
      done
  fi
  printf '}}%b\n' >> command_acl.txt
  index=$[$index+1]
done <acl.txt
# now run all the commands from the generated file
while read p; do
$p
done < command_acl.txt
