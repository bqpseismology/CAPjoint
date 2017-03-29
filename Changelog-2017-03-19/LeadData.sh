#!/bin/bash

# Scripts for converting original IRIS Wilber seed file (input)
# to data compatible for CAP inversion (output, in folder "data")

# Author: Jia Zhe; 
# Modification and annotation made by Chen Weiwen
# Current Version: 2014/10/10
# Contact jiazhe@mail.ustc.edu.cn vincentc@mail.ustc.edu.cn for more info

# Input: single SEED file
# Output: true ground velocity sac files in radical/tangential/vertical components
#	  in the form of STA.r STA.t STA.z

# --- Usage: ---
# sh LeadData.cmd *.seed

if [ $# -ne 1 ]; then
	echo "Usage:"
	echo "       sh LeadData.cmd *.seed"
	exit 1;
fi


# extract Wilber data , rename the SAC files 
rdseed -f $1 -c |grep -i Event > event.location.info

# write the event infomation into each SAC files
cat event.location.info | gawk '
 /origin/ {x=$5;
 split(x,aa,",");
 split(aa[3],bb,":");
 print "r $1";
 print "chnhdr o gmt ",aa[1],aa[2],bb[1],bb[2],bb[3];
 print "evaluate to tt1 &1,o * -1";
 print "chnhdr allt %tt1";
}
/latitude/ {print "ch evla",$4}
/longitude/ {print "ch evlo",$4}
/depth/ {print "ch evdp",$5; print "ch lcalda TRUE";}
END{
 print "w over";
}' >cho.sm

# Extract seed file into SACs and rename SACs into proper name format
rdseed -pdf $1;
find . -name "*.SAC" > 1SAC1
cat 1SAC1 | awk 'BEGIN {FS="/";} {if (!$3) print $2;}' >1SAC2
cat 1SAC2 | gawk '{split($1,m,".");print "mv "$1, m[7]"."m[8]"."m[9]"."m[10]}' | sh
find . -name "*.?[LH][ENZ12]" > 1BH
cat 1BH | awk 'BEGIN {FS="/";} {if (!$3) print $2;}' > 2BH
cat 2BH | gawk '{print "r ",$1;print "m cho.sm ",$1;} END {print "quit"}' | sac
rm cho.sm rdseed.err_log event.location.info

# remove the instrument response
if [ -d RESP ]; then
echo "found RESP/"
else
mkdir RESP
fi
if [ -d data ]; then
echo "found Vel/";
else
mkdir data;
fi
if [ -d Vel ]; then
echo "found Vel/";
else
mkdir Vel;
fi
find . -name "SAC_PZs*" > 1PZs
cat 1PZs | awk '
BEGIN {FS="/";} 
{	if (!$3) print $2;
}' > 2PZs
cat 2PZs | gawk '
{	split($1,mm,"_");
	print "mv",$1,"RESP/"mm[3]"."mm[4]"."mm[6]"."mm[5]
}' | sh
find . -name "*.?[LH][ENZ12]" > BH1
cat BH1 | awk 'BEGIN {FS="/";} {if (!$3) print $2;}' > BH2

# remove the linear trench, rotate the horizontal components to the great arc paths
# then remove the instrument responses from RESP files contained in the SEED
# SAC files transfered into velocity
cat BH2 |gawk '{
	print "r",$1;
	print "rmean";
	print "rtr";
	print "transfer from polezero subtype RESP/"$1,"to vel ";print "w Vel/"$1
}
END{print "q"}' | sac

# remove intermediate process files
rm [12]PZs BH[12] 1SAC[12] [12]BH *.?[LH][12ENZ]
cd Vel/

# change the sampling rate of data to 20 points per second
saclst delta f *.*.*.* | gawk '{
	if($2==0.1){
		print "r",$1;
		print "stretch 2";
		print "w over";
	}
	if($2==0.025){
		print "r",$1;
		print "decimate 2";
		print "w over"
	}
	if($2==0.01){
		print "r",$1;
		print "decimate 5";
		print "w over";
	}
	if($2==0.005){ 
		print "r",$1;
		print"decimate 2";
		print "decimate 5";
		print "w over";
	}
	if($2==0.02){
		print "r",$1;
		print "stretch 2";
		print "decimate 5";
		print "w over";
	}
} END{print "quit"}' | sac

# make directory for the temperary storage of true ground velocity files
mkdir rtr_mul_100/

# t1 and t2 time arrival mark for teleseismic waves
saclst gcarc kstnm f *.?[LH]Z | gawk '$2>30{
	print "sh ../cmds/addp.cmd "$1; 
	print "sh ../cmds/adds.cmd *"$3"*?[LH][EN12]";
}' | sh

# cut the files into proper time windows, rotate the horizontal components
# for local and teleseismic waveforms, respectively
# unit change from m/s to cm/s 

saclst t1 gcarc f *.BH1 | gawk '$3>30{print "cut t1 -10 t1 50";a=$1; b=$1; gsub("BH1", "BH1",a); gsub("BH1","BH2", b);print "r",a,b; print "rtr" ; print "mul 100"; print "rot to gcp"; gsub("BH1","r",a); gsub("BH2","t",b);print "ch b 0 a 10 t1 8 t2 52 t3 8 t4 52"; print "w rtr_mul_100/"a, "rtr_mul_100/"b;print "cut t1 -10 t1 50" ;a=$1;gsub("BH1", "BHZ",a);print "r "a ;print "rtr" ;print "lh stna" ;print "mul 100"; gsub("BHZ","z",a);print "ch b 0 a 10 t1 8 t2 52 t3 8 t4 52";print "w rtr_mul_100/"a ;} END {print "quit"}' | sac

saclst t1 gcarc f *.BHE | gawk '$3>30{print "cut t1 -10 t1 50";a=$1; b=$1; gsub("BHE", "BHE",a); gsub("BHE","BHN", b);print "r",a,b; print "rtr" ; print "mul 100"; print "rot to gcp"; gsub("BHE","r",a); gsub("BHN","t",b);print "ch b 0 a 10 t1 8 t2 52 t3 8 t4 52"; print "w rtr_mul_100/"a, "rtr_mul_100/"b;print "cut t1 -10 t1 50" ;a=$1;gsub("BHE", "BHZ",a);print "r "a ;print "rtr" ;print "lh stna" ;print "mul 100"; gsub("BHZ","z",a);print "ch b 0 a 10 t1 8 t2 52 t3 8 t4 52";print "w rtr_mul_100/"a ;} END {print "quit"}' | sac

saclst gcarc f *.BH1 | gawk 'BEGIN {print "cut O 0 180"}$2<5 {a=$1; b=$1; gsub("BH1", "BH1",a); gsub("BH1","BH2", b);print "r",a,b; print "rtr" ; print "mul 100"; print "rot to gcp"; gsub("BH1","r",a); gsub("BH2","t",b);print "w rtr_mul_100/"a, "rtr_mul_100/"b;a=$1;gsub("BH1", "BHZ",a);print "r "a ;print "rtr" ;print "lh stna" ;print "mul 100"; gsub("BHZ","z",a);print "w rtr_mul_100/"a ;} END {print "quit"}' | sac

saclst gcarc f *.BHE | gawk 'BEGIN {print "cut O 0 180"} $2<5 {a=$1; b=$1; gsub("BHE", "BHE",a); gsub("BHE","BHN", b);print "r",a,b; print "rtr" ; print "mul 100"; print "rot to gcp"; gsub("BHE","r",a); gsub("BHN","t",b);print "w rtr_mul_100/"a, "rtr_mul_100/"b;a=$1;gsub("BHE", "BHZ",a);print "r "a ;print "rtr" ;print "lh stna" ;print "mul 100"; gsub("BHZ","z",a);print "w rtr_mul_100/"a ;} END {print "quit"}' | sac

# cp prossessed files into data folder

cp rtr_mul_100/*.[rtz] ../data/
cd ../
rm -rf RESP
rm -rf Vel
#ls -1 ./data/* | wc -l | gawk '{if ($1<=12) {print "echo data not enough at all!";} else {print "sh LeadCAP.cmd";}
