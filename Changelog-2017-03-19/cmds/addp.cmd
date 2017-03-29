#!/usr/bin/sh

# Script for picking P arrival for teleseismic data

# Author: Jia Zhe;
# Modification and annotation made by Chen Weiwen
# Current Version: 2014/10/10
# Contact jiazhe@mail.ustc.edu.cn vincentc@mail.ustc.edu.cn for more info

# Input: SAC files with dist value in header
# Output: SAC files with P arrival in header

ls -1 $* | gawk '{print "sh ../cmds/pickp.cmd "$1;}' | sh
cat ptime.tmp | gawk '{filename=$1;print "r",filename;print "ch t1 "$3;print "wh"}; END { print "quit" }'  | sac
