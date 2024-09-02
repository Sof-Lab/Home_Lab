#!/bin/bash

# Print Title
printf "%-8s  %-15s  %-30s  %s\n" "PID" "STAT" "COMM" "DEV"

# List of processes
# proc_pid=($( find /proc -type d -name '[0-9]*' | grep -E -o '[0-9]*' | sort -n | uniq ))
proc_pid=($( ls /proc/ | egrep "^[0-9]" | sort -n ))

#Collect info about processes from /proc/
for i in ${!proc_pid[@]}
  do
  
    # Check proc file exist
    if test -f "/proc/${proc_pid[$i]}/status"; then
    
      # Collect status
      proc_state=$( cat /proc/${proc_pid[$i]}/status | awk '/State/ {print $2 $3}' )
      
      # Collect command
      proc_cmd=$( cat /proc/${proc_pid[$i]}/comm )

      # Collect fd
      if [ -z "`ls /proc/${proc_pid[$i]}/fd`" ]; then
          proc_dev="?";
        else
          proc_dev=$( ls -l /proc/${proc_pid[$i]}/fd | awk '/dev.*/ {print $NF}' | uniq | tr -s '\n' ',');
      fi
      
      # Print results
      printf "%-8s  %-15s  %-30s  %s\n" "${proc_pid[$i]}" "$proc_state" "$proc_cmd" "$proc_dev" 
    fi
done

