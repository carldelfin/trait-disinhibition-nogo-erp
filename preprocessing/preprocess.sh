#!/bin/bash

# start timer
start=`date +%s`

# create directories
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
mkdir -p $DIR/preprocess/tmp/{cropped,filtered,cleaned,epoched,cleaned_epoched,evoked}
mkdir -p $DIR/preprocess/output/{data,raw_data,logs,plots}

# preprocess and plot
python3 $DIR/preprocess/01_preprocess.py
python3 $DIR/preprocess/02_topoplot.py

# stop timer
end=`date +%s`
now=$(date)
runtime=$(( (end-start)/60 ))

# print to system info
echo "Preprocessing and analysis finished after $runtime minute(s) on $now" >> $DIR/preprocess/output/logs/system_info.txt
echo >> $DIR/preprocess/output/logs/system_info.txt
echo "Linux kernel:" >> $DIR/preprocess/output/logs/system_info.txt
cat /proc/version >> $DIR/preprocess/output/logs/system_info.txt
echo "" >> $DIR/preprocess/output/logs/system_info.txt
echo "CPU:" >> $DIR/preprocess/output/logs/system_info.txt
lscpu >> $DIR/preprocess/output/logs/system_info.txt
echo "" >> $DIR/preprocess/output/logs/system_info.txt