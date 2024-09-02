#!/bin/bash

#Print Title
printf "%-8s  %-3s  %-5s  %-10s  %-30s  %s\n" "COMM" "PID" "TYPE" "NODE" "NAME"

#List of processes
proc_pid=($( ls /proc/ | egrep "^[0-9]" | sort -n ))

#Collect info about processes from /proc/
for i in ${!proc_pid[@]}
  do
    # Check proc file exist
    if test -f "/proc/${proc_pid[$i]}/status";
      then 
      
      # Collect command
      proc_cmd=$( cat /proc/${proc_pid[$i]}/comm )
      
      # Collect work directory
      proc_cwd=$( ls -l /proc/${proc_pid[$i]}/cwd | awk '{print $NF}' )
      
      # Print first part results for n proc
      printf "%-8s  %-3s  %-5s  %-10s  %-30s  %s\n" "$proc_cmd" "${proc_pid[$i]}" "DIR" "-" "$proc_cwd"
      
      # Collect info from maps
      proc_fd_reg_node=($( cat /proc/${proc_pid[$i]}/maps | awk '$5 > 0 {print $5 " " $6}' | uniq ))
      q=0
      while [ $q -lt ${#proc_fd_reg_node[*]} ]
        do
          # Print second part results for n proc
          printf "%-8s  %-3s  %-5s  %-10s  %-30s  %s\n" "$proc_cmd" "${proc_pid[$i]}" "REG" "${proc_fd_reg_node[$q]}" "${proc_fd_reg_node[$q+1]}"
          q=$[ $q + 2 ]
      done
      
      # Collect info unix
      proc_fd_unix_name=($( cat /proc/${proc_pid[$i]}/net/unix | awk 'NR>1 {print $8}' | sort | uniq ))
      for x in ${!proc_fd_unix_name[@]}
        do
          proc_fd_unix_node=$( cat /proc/${proc_pid[$i]}/net/unix | awk -v "UN=${proc_fd_unix_name[$x]}" '{if ($8~UN) print $7}' | awk 'NR==1 {print $0}' )
          # Print third part results for n proc
          printf "%-8s  %-3s  %-5s  %-10s  %-30s  %s\n" "$proc_cmd" "${proc_pid[$i]}" "unix" "${proc_fd_unix_node}" "${proc_fd_unix_name[$x]}"
      done
      
    fi
done