

#!/usr/bin/env bash

#the following scripts should be executed in the entry0. directory in DZ/multientries/entry0./

#-------------------------------------------------------
#This script calculates data stats in both directions.

k=0;for a in `cat filelist`;do tcpdump -e -tt -nn -v -r $a | grep -A 1 ^10 --no-group-separator |paste -s -d' \n' | ../scripts/npu_len_extract | perl ../scripts/datastats.perl;done 1> data.stats.all

#--------------------------------------------------------
#This script calculates data stats from a to b.

k=0;
for i in `cat filelist`;do

#changing f3 to f5 and vica versa for datstats  !!!!!

if [ "X"`echo $i | cut -d'/' -f5` == "X"`tcpdump -nn -r $i -F ./SiteA_src -c1 | awk '{print $3}' | cut -d'.' -f1,2,3,4` ]; then
tcpdump -e -tt -nn -v -r $i -F ./SiteA_src | grep -A 1 ^10 --no-group-separator |paste -s -d' \n' | ../scripts/npu_len_extract | perl ../scripts/datastats.perl


else
tcpdump -e -tt -nn -v -r $i -F ./SiteA_notsrc |grep -A 1 ^10 --no-group-separator |paste -s -d' \n' | ../scripts/npu_len_extract | perl ../scripts/datastats.perl
fi;

done 1>data.stats_a-b


#--------------------------------------------------------
#This script calculates data stats from b to a.

k=0;
for i in `cat filelist`;do



if [ "X"`echo $i | cut -d'/' -f3` == "X"`tcpdump -nn -r $i -F ./SiteA_src -c1 | awk '{print $3}' | cut -d'.' -f1,2,3,4` ]; then

tcpdump -e -tt -nn -v -r $i -F ./SiteA_src |grep -A 1 ^10 --no-group-separator |paste -s -d' \n' | ../scripts/npu_len_extract | perl ../scripts/datastats.perl

else

tcpdump -e -tt -nn -v -r $i -F ./SiteA_notsrc |grep -A 1 ^10 --no-group-separator |paste -s -d' \n' |../scripts/npu_len_extract | perl ../scripts/datastats.perl
fi;

done 1>data.stats_b-a

#--------------------------------------------------------
#This script calculates transfer mode values.

while read -r i;do

j=$(echo $i | cut -d' ' -f1 | sed -re 's/(^[0-9]+)/out\/\1/')

if [ `echo $i | cut -d' ' -f 2 | cut -d'/' -f1` == server ]  ; then

tcpdump -tt -vv -nn -q -r $j | grep -A 1 ^10 --no-group-separator |paste -s -d' \n' | awk '{print $18}' > tmp/ip;tcpdump -tt -vv -nn -q -r $j |grep -A 1 ^10 --no-group-separator |paste -s -d' \n' | awk '{print $1}' > tmp/time;tcpdump -tt -vv -nn -q -r $j |  grep -A 1 ^10 --no-group-separator |paste -s -d' \n' | awk '{print $22}'| sed 's/\n//'  > tmp/data;perl ../scripts/transfer.mode.scpt.perl tmp/ip tmp/time tmp/data

elif  [ `echo $i | cut -d' ' -f 2 | cut -d'/' -f2` == server ]  ; then

tcpdump -tt -vv -nn -q -r $j | grep -A 1 ^10 --no-group-separator |paste -s -d' \n' | awk '{print $22}' > tmp/ip;tcpdump -tt -vv -nn -q -r $j |grep -A 1 ^10 --no-group-separator |paste -s -d' \n' | awk '{print $1}' > tmp/time;tcpdump -tt -vv -nn -q -r $j |  grep -A 1 ^10 --no-group-separator |paste -s -d' \n' | awk '{print $18}'| sed 's/\n//'  > tmp/data;perl ../scripts/transfer.mode.scpt.perl tmp/ip tmp/time tmp/data

fi;
done < senses 1>transfer.mode



#--------------------------------------------------------
#This script calculates time stats in both directions.

k=0;for j in `cat filelist`; do  tcpdump -tt -vv  -nn -r  $j | grep -A 1 ^10 --no-group-separator |paste -s -d' \n' | awk '{print $1}' | perl -w -n -e 'chomp; if( ! defined($i)) { print $_,"\n";$i=$_;} else { printf"%.06f\n",($_-$i);$i=$_;};' | perl ../scripts/timestats.perl; done 1> time.stats.all

#--------------------------------------------------------
#This script calculates time stats from a to b.

k=0;
for i in `cat filelist`;do



if [ "X"`echo $i | cut -d'/' -f3` == "X"`tcpdump -nn -r $i -F ./SiteA_src -c1 | awk '{print $3}' | cut -d'.' -f1,2,3,4` ]; then

tcpdump -tt -vv  -nn -r  $i |  grep -A 1 ^10 --no-group-separator |paste -s -d' \n' | awk '{print $1}' | perl -w -n -e 'chomp; if( ! defined($i)) { print $_,"\n";$i=$_;} else { printf"%.06f\n",($_-$i);$i=$_;};' | perl ../scripts/timestats.perl

else

tcpdump -tt -vv  -nn -r  $i | grep -A 1 ^10 --no-group-separator |paste -s -d' \n' | awk '{print $1}' | perl -w -n -e 'chomp; if( ! defined($i)) { print $_,"\n";$i=$_;} else { printf"%.06f\n",($_-$i);$i=$_;};' | perl ../scripts/timestats.perl

fi;

done 1>time.stats_a-b

#--------------------------------------------------------
#This script calculates time stats from b to a.

k=0;
for i in `cat filelist`;do



if [ "X"`echo $i | cut -d'/' -f5` == "X"`tcpdump -nn -r $i -F ./SiteA_src -c1 | awk '{print $3}' | cut -d'.' -f1,2,3,4` ]; then

tcpdump -tt -vv  -nn -r  $i | grep -A 1 ^10 --no-group-separator |paste -s -d' \n' |  awk '{print $1}' | perl -w -n -e 'chomp; if( ! defined($i)) { print $_,"\n";$i=$_;} else { printf"%.06f\n",($_-$i);$i=$_;};' | perl ../scripts/timestats.perl

else

tcpdump -tt -vv  -nn -r  $i | grep -A 1 ^10 --no-group-separator |paste -s -d' \n' | awk '{print $1}' | perl -w -n -e 'chomp; if( ! defined($i)) { print $_,"\n";$i=$_;} else { printf"%.06f\n",($_-$i);$i=$_;};' | perl ../scripts/timestats.perl

fi;

done 1>time.stats_b-a

#----------------------------------------------------------
#This script collects tcptrace data into one single file.

k=0;for i in `cat filelist`; do

tcptrace_len_bottom=$(tcptrace -rln $i | grep -n "sdv retr"| cut -d':' -f1)
tcptrace_len_top=$(tcptrace -rln $i | grep -n "a->b"| cut -d':' -f1)

if  tcptrace -rln $i | grep "req 1323"  ; then

 echo `tcptrace -rln $i | tail -$((tcptrace_len_bottom - tcptrace_len_top)) | sed -e 's/Bps/ /g' -e 's/SYN\/FIN/ /g' -e 's/RTT/ /g' -e 's/3WHS/ /g' -e 's/req 1323/ /g' -e 's/[[:lower:]]/ /g' -e 's/[\/\:\_\#-]/ /g' -e '17 s/NA/NA NA/g' -e 's/  */ /g' | tr -s \\n ' '` 1>tcptrace.char

else

echo `tcptrace -rln $i | tail -$((tcptrace_len_bottom - tcptrace_len_top)) | sed -e 's/Bps/ /g' -e 's/SYN\/FIN/ /g' -e 's/RTT/ /g' -e 's/3WHS/ /g' -e 's/req 1323/ /g' -e 's/[[:lower:]]/ /g' -e 's/[\/\:\_\#-]/ /g' -e '17 s/NA/NA NA/g' -e 's/  */ /g' | tr -s \\n ' ' | sed 's/\([YN]\)/? ? ? ? ? ? \1/'` 1> tcptrace.char

fi;

done
#----------------------------------------------------------
#This script computes the time since the last connection between same host pairs.

perl ../scripts/last.connection.perl filelist 1> last.connection
#this is done by andrew now

#----------------------------------------------------------
#This script calculates the basic characteristics.

## need to check senses if its server to client or client to server
k=1;

paste -d'|' senses transfer.mode tcptrace.char > basic.char
cat basic.char | tr ' ' ',' > basic.att
for i in `cat basic.att`; do


	if [ `echo $i | cut -d'|' -f1 | cut -d',' -f2 | cut -d'/' -f1` == server ]; then

		echo $i |cut -d'|' -f2 | cut -d',' -f4 >> tmp/dur
		echo $i |cut -d'|' -f1 | cut -d'/' -f2 >> tmp/ipsvr
		echo $i |cut -d'|' -f1 | cut -d'/' -f4 >> tmp/ipcl
		echo $i |cut -d'|' -f1 | cut -d'/' -f3 >> tmp/portsvr
		echo $i |cut -d'|' -f1 | cut -d'/' -f5 >> tmp/portcl
		echo $i |cut -d'|' -f3 | cut -d',' -f1 >> tmp/packcl
		echo $i |cut -d'|' -f3 | cut -d',' -f2 >> tmp/packsvr
		echo $i |cut -d'|' -f3 | cut -d',' -f18>> tmp/paycl
		echo $i |cut -d'|' -f3 | cut -d',' -f19>> tmp/paysvr

	elif [ `echo $i | cut -d'|' -f1 | cut -d',' -f2 | cut -d'/' -f2` == server ]; then

		echo $i |cut -d'|' -f2 | cut -d',' -f4 >> tmp/dur
                echo $i |cut -d'|' -f1 | cut -d'/' -f4 >> tmp/ipsvr
                echo $i |cut -d'|' -f1 | cut -d'/' -f2 >> tmp/ipcl
                echo $i |cut -d'|' -f1 | cut -d'/' -f5 >> tmp/portsvr
                echo $i |cut -d'|' -f1 | cut -d'/' -f3 >> tmp/portcl
                echo $i |cut -d'|' -f3 | cut -d',' -f2 >> tmp/packcl
                echo $i |cut -d'|' -f3 | cut -d',' -f1 >> tmp/packsvr
                echo $i |cut -d'|' -f3 | cut -d',' -f19>> tmp/paycl
                echo $i |cut -d'|' -f3 | cut -d',' -f18>> tmp/paysvr


	fi;
done

paste -d' ' tmp/dur tmp/ipsvr tmp/portsvr tmp/packsvr tmp/paysvr tmp/ipcl tmp/portcl tmp/packcl tmp/paycl > basic.char

rm  tmp/dur tmp/ipsvr tmp/portsvr tmp/packsvr tmp/paysvr tmp/ipcl tmp/portcl tmp/packcl tmp/paycl basic.att

#----------------------------------------------------------
#This script applies arctan to the values in the dft transform and copies the effective bandwidth files into the main directory.

./dft/sc2
./effbw/sc

cp dft/fft* .
cp effbw/eff.band* .

R --vanilla CMD BATCH ../scripts/fft.all.R
R --vanilla CMD BATCH ../scripts/fft_a-b.R
R --vanilla CMD BATCH ../scripts/fft_b-a.R

rm *.Rout

#----------------------------------------------------------
#This script picks out data classes.

#awk '{print $1" "$12}' < category2 > tmp/classes
#k=0;for i in `cat filelist`; do grep -m1 $i tmp/classes | awk '{print $1}';done > classes

#awk '{print $1" "$12}' < category2-with-extra-BULK-classes > tmp/subclasses
#k=0;for i in `cat filelist`; do grep -m1 $i tmp/subclasses | awk '{print $1}';done > subclasses

bash ./create_complex_categories_modified



cut -d' ' -f1,10 complex_category  > tmp/f  #10 is the time stamp
cut -d'/' -f7 filelist | cut -d'.' -f2 >tmp/utime
for j in `cat filelist`;do echo Z;done > tmp/crap
paste -d' ' tmp/f tmp/crap | column -t | sed 's/  / /g' > tmp/f2
paste -d' ' tmp/utime tmp/crap  > tmp/utime2
k=0
while read i
do
		 fgrep -m1 $i tmp/f2 | awk '{print $1}' | cut -d':' -f2 ;
done < tmp/utime2 > subsubclasses
sed -e's/ATTACK/OTHER/g' -e's/GAMES/OTHER/g' -e's/MULTIMEDIA/OTHER/g' -e's/P2P/OTHER/g' subsubclasses > subclasses

sed -e's/FTP-PASV/BULK/g' -e's/FTP-DATA/BULK/g' -e's/FTP-CONTROL/BULK/g'  subclasses > classes

#-----------------------------------------------------------
#Merging everything together (autoclass input)

cut -d'/' -f7 filelist | perl -n -e' chomp; @time=split("\\."); printf "%d.%06d\n",$time[0],$time[1];' > utime

paste -d' ' utime basic.char classes time.stats.all data.stats.all utime tcptrace.char data.stats_a-b data.stats_b-a time.stats_a-b time.stats_b-a last.connection subclasses transfer.mode eff.band.all eff.band_a-b eff.band_b-a fft.all.atan fft_a-b.atan fft_b-a.atan subsubclasses > filelist.all


#-----------------------------------------------------------
#Replacing all NA's with "?"

perl -n -w -e'chomp; s/NA/?/g; print "$_\n";' < filelist.all > tmp/tmp
mv tmp/tmp filelist.all

#-----------------------------------------------------------
#Making a csv file

tr ' ' \, < filelist.all > filelist.all.csv

#-----------------------------------------------------------
#Making a csv file

#sed 's/ /,/g' < filelist.all > filelist.all.csv

#-----------------------------------------------------------
#Adding a header to the csv file

perl -e'print "1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,52,53,54,55,56,57,58,59,60,61,62,63,64,65,66,67,68,69,70,71,72,73,74,75,76,77,78,79,80,81,82,83,84,85,86,87,88,89,90,91,92,93,94,95,96,97,98,99,100,101,102,103,104,105,106,107,108,109,110,111,112,113,114,115,116,117,118,119,120,121,122,123,124,125,126,127,128,129,130,131,132,133,134,135,136,137,138,139,140,141,142,143,144,145,146,147,148,149,150,151,152,153,154,155,156,157,158,159,160,161,162,163,164,165,166,167,168,169,170,171,172,173,174,175,176,177,178,179,180,181,182,183,184,185,186,187,188,189,190,191,192,193,194,195,196,197,198,199,200,201,202,203,204,205,206,207,208,209,210,211,212,213,214,215,216,217,218,219,220,221,222,223,224,225,226,227,228,229,230,231,232,233,234,235,236,237,238,239,240,241,242,243,244,245,246,247,248,249,250,251,252,253,254,255,256,257,258,259,260,261,262,263,264,265,266\n";foreach $line (<STDIN>){print $line}' < filelist.all.csv > tmp/tmp

mv tmp/tmp filelist.all.csv


#---------------------------------
#keeps only useful parameters in the dataset. This removes all utime attributes, #packets+payload+duration+ip and class attributes.

cut -d',' -f4,8,13,14,15,16,17,18,19,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,43,44,45,46,47,48,49,50,51,52,53,54,55,56,57,58,59,60,61,62,63,64,65,66,67,68,69,70,71,72,73,74,75,76,77,78,79,80,81,82,83,84,85,86,87,88,89,90,91,92,93,94,95,96,97,98,99,100,101,102,103,104,105,106,107,108,109,110,111,112,113,114,115,116,117,118,119,120,121,122,123,124,125,126,127,128,129,130,131,132,133,134,135,136,137,138,139,140,141,142,143,144,145,146,147,148,149,150,151,152,153,154,155,156,157,158,159,160,161,162,163,164,166,167,168,169,170,171,172,173,174,175,176,177,178,179,180,181,182,183,184,185,186,188,189,190,191,192,193,194,195,196,197,198,199,200,201,202,203,204,205,206,207,208,210,211,212,213,214,215,216,218,219,220,221,222,223,224,225,226,227,228,229,230,231,232,233,234,235,236,237,238,239,240,241,242,243,244,245,246,247,248,249,250,251,252,253,254,255,256,257,258,259,260,261,262,263,264,265 < filelist.all.csv > filelist.weka.class.csv

#---------------------------------
#keeps only useful parameters in the dataset. This removes all utime attributes, #packets+payload+duration+ip and subclass attributes.

cut -d',' -f4,8,11,13,14,15,16,17,18,19,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,43,44,45,46,47,48,49,50,51,52,53,54,55,56,57,58,59,60,61,62,63,64,65,66,67,68,69,70,71,72,73,74,75,76,77,78,79,80,81,82,83,84,85,86,87,88,89,90,91,92,93,94,95,96,97,98,99,100,101,102,103,104,105,106,107,108,109,110,111,112,113,114,115,116,117,118,119,120,121,122,123,124,125,126,127,128,129,130,131,132,133,134,135,136,137,138,139,140,141,142,143,144,145,146,147,148,149,150,151,152,153,154,155,156,157,158,159,160,161,162,163,164,166,167,168,169,170,171,172,173,174,175,176,177,178,179,180,181,182,183,184,185,186,188,189,190,191,192,193,194,195,196,197,198,199,200,201,202,203,204,205,206,207,208,210,211,212,213,214,215,216,218,219,220,221,222,223,224,225,227,228,229,230,231,232,233,234,235,236,237,238,239,240,241,242,243,244,245,246,247,248,249,250,251,252,253,254,255,256,257,258,259,260,261,262,263,264,265 < filelist.all.csv > filelist.weka.subclass.csv

#---------------------------------
#keeps only useful parameters in the dataset. This removes all utime attributes, #packets+payload+duration+ip and subclass+class attributes.

cut -d',' -f4,8,13,14,15,16,17,18,19,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,43,44,45,46,47,48,49,50,51,52,53,54,55,56,57,58,59,60,61,62,63,64,65,66,67,68,69,70,71,72,73,74,75,76,77,78,79,80,81,82,83,84,85,86,87,88,89,90,91,92,93,94,95,96,97,98,99,100,101,102,103,104,105,106,107,108,109,110,111,112,113,114,115,116,117,118,119,120,121,122,123,124,125,126,127,128,129,130,131,132,133,134,135,136,137,138,139,140,141,142,143,144,145,146,147,148,149,150,151,152,153,154,155,156,157,158,159,160,161,162,163,164,166,167,168,169,170,171,172,173,174,175,176,177,178,179,180,181,182,183,184,185,186,188,189,190,191,192,193,194,195,196,197,198,199,200,201,202,203,204,205,206,207,208,210,211,212,213,214,215,216,218,219,220,221,222,223,224,225,227,228,229,230,231,232,233,234,235,236,237,238,239,240,241,242,243,244,245,246,247,248,249,250,251,252,253,254,255,256,257,258,259,260,261,262,263,264,265,266 < filelist.all.csv > filelist.weka.allclass.csv

#-----------------------------------
# creating arff files

cat ./data/headerlist.all.weka filelist.all.csv > filelist.weka.all.arff
cat ./data/headerlist.allclass.weka filelist.weka.allclass.csv > filelist.weka.allclass.arff


#moving all the data that we will be working with to a new directory

mkdir data
mv filelist.all data
mv filelist.all.csv data
mv filelist.weka.* data


