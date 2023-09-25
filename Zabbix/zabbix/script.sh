#!/bin/bash
if [ "$1" = "metric1" ];then echo $(($RANDOM%100))
elif [ "$1" = "metric2" ];then echo $(($RANDOM%100))
elif [ "$1" = "metric3" ];then echo $(($RANDOM%100))
fi