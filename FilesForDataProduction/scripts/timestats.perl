#!/usr/bin/perl
#this script calculates data statistics. Run it in the following way: for j in `cat filelist`; do tcpdump -tt -vv  -nn -r  $j | awk '{print $1}' | perl -w -n -e 'chomp; if( ! defined($i)) { print $_,"\n";$i=$_;} else { printf"%.06f\n",($_-$i);$i=$_;};' | perl ../scripts/timestats.perl; done 1>...



use Statistics::Descriptive;

$stat=Statistics::Descriptive::Full->new();
$i=0;
@lines=<STDIN>;

$l=length($lines[0]);

$time=$lines[0];


if ($l > 6 )
{

foreach $_ (@lines)
{
  $i++;
  if ( $i != 1 )
  {
    $timedata[$i-2]=$_;
    $stat->add_data($_);
   }
}

if ( $#timedata==0 )
{
  $min=$timedata[0];
  $q1=$timedata[0];
  $med =$timedata[0];
  $mean=$timedata[0];
  $q3=$timedata[0];
  $max=$timedata[0];
  $var=0;
}
elsif ($i==1)
{
  $time="NA";
  $min=0;
  $q1=0;
  $med=0;
  $mean=0;
  $q3=0;
  $max=0;
  $var=0;
}
else
{
@sorted=sort { $a <=> $b } @timedata;

$location1=$#timedata/4;
$index1=int $location1;
$fraction1=$location1 - $index1;

$location3=$location1*3;
$index3=int $location3;
$fraction3=$location3-$index3;

$q1=$sorted[$index1]+($sorted[$index1+1]-$sorted[$index1])*$fraction1;
$q3=$sorted[$index3]+($sorted[$index3+1]-$sorted[$index3])*$fraction3;

$min=$stat->min();
$med=$stat->median();
$mean=$stat->mean();
$var=$stat->variance();
$max=$stat->max();
}
}
else
{
  $time="NA";
  $min=0;
  $q1=0;
  $med=0;
  $mean=0;
  $q3=0;
  $max=0;
  $var=0;
}

chomp($time,$min,$q1,$med,$mean,$q3,$max,$var);

print "$time $min $q1 $med $mean $q3 $max $var\n";
