#!/usr/bin/perl -w
#this needs to be performed in bash
#$j is a member of the filelist
#
#tcpdump -tt -vv -nn -q -r $j | awk '{print $2}' > tmp/ip
#tcpdump -tt -vv -nn -q -r $j | awk '{print $1}' > tmp/time
#tcpdump -tt -vv -nn -q -r $j | awk '{print $6}' > tmp/data


#---------------------
#this is the perl script

#read the names of the files that we will be using
$ip=$ARGV[0];
$time=$ARGV[1];
$data=$ARGV[2];


#open all the files in use
open(IP,"$ip");
open(TIME,"$time");
open(DATA,"$data");

#read the files by lines
@ip = <IP>;
@time = <TIME>;
@data = <DATA>;

#defining the variables in use.
$Y=0;
$B=0;
$D=0;
$duration=0;
$idle=0;
$ACK=0;
$pR="NA";

if( $#ip != 0 )
  {

$timestamp=$time[0];
chomp($timestamp);



$d=$data[0];

if ( $d != 0 ){
  $pR=$ip[0];
  $B=1;
  $timeS=$time[0];
}

$t1=$time[0];
$t2=$time[$#time];
$DUR = $t2 - $t1;



#deals with the case when there is only one packet transfered.
if ( $#data == 0 ){
   print "$timestamp 0 0 0 0 0 0\n";
}
else{

for ( $i = 1; $i <= $#time; $i++ )
  {
    if ( $data[$i] != 0 ){
       if ( $B == 0 ){
          $timeS=$time[$i];
       }

       $p=$ip[$i];

       if ( $p eq $pR ){
          $B=$B+1;
       }
       else {
          if ( $B >= 3 ){
             $Y=$Y+1;
             $timeF=$time[$i-$ACK-1];
             $duration=$timeF-$timeS;
             $D=$D+$duration;
          }
          $timeS=$time[$i];
          $B=1;
          $pR=$p;
       }
       $ACK=0;
     }
     else {
       $ACK=$ACK+1;
     }
  $ts=$time[$i-1];
  $tf=$time[$i];
  $diff=$tf-$ts;
  if ( $diff > 2 ){
     $idle=$idle+$diff;
  }
$j=$i;
}
if ( $B >= 3 ){
   $Y=$Y+1;
   $timeF=$time[$j-$ACK];
   $duration=$timeF-$timeS;
   $D=$D+$duration;
}
else{
   if ( $Y != 0 ){
      $Y=$Y+1;
   }
}

$percent_bulk=$D/$DUR*100;
$percent_idle=$idle/$DUR*100;
print "$Y $D $DUR $percent_bulk $idle $percent_idle\n";
}
}
else
  {
    print "0 0 0 0 0 0\n";
  }

