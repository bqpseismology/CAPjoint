#!/usr/bin/sh

# Script for computing P arrival by Tau-P code
# request by addp.cmd

# Author: Jia Zhe;
# Modification and annotation made by Chen Weiwen
# Current Version: 2014/10/10
# Contact jiazhe@mail.ustc.edu.cn vincentc@mail.ustc.edu.cn for more info

# Input: event depth and great circle arc length in SAC header
# Output: P arrival time in a temp file

NAM=$1
saclst evdp gcarc f $NAM | gawk ' { print "h";print $2;print $3;print "q"; } ' | taup_time | gawk ' {if ($3=="P"||$3=="p") print $4}' | sort -n > taup.tmp
cat taup.tmp | gawk -v var=$NAM '{if (NR==1) print var,"P",$1;}' >> ptime.tmp
