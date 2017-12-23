#!/usr/bin/perl
#this script calculates data statistics. Run it in the following way: for i in `cat filelist`; do tcpdump -e -tt -nn -v -r $i | ../scripts/npu_len_extract | perl datastats.perl;done > ...


use Statistics::Descriptive;

$stat=Statistics::Descriptive::Full->new();
$stat_ip=Statistics::Descriptive::Full->new();
$stat_control=Statistics::Descriptive::Full->new();
$i=0;
@lines=<STDIN>;
$l=length($lines[0]);

if ($l > 6)
{

@words=split(/ /,$lines[0]);
$time=$words[0];

foreach $_ (@lines)
{
  next if /^[ \t]*$/;
		
		
  $i++;
  @splitlist=split(/ /,$_);
  ($str1 = @splitlist[8])=~ s/[;():]//;  #modifying to get correct format for ip and wire
  ($str2 = @splitlist[23])=~ s/[;():]//;
  $data_wire[$i-1]=$str1;
  $data_ip[$i-1]=$str2;
  $data_control[$i-1]=$data_wire[$i-1]-$data_ip[$i-1];
  $stat->add_data($str1);
  $stat_ip->add_data($data_ip[$i-1]);
  $stat_control->add_data($data_control[$i-1]);
}


if ( $#data_wire==0 )
{
  $min=$data_wire[0];
  $q1=$data_wire[0];
  $med =$data_wire[0];
  $mean=$data_wire[0];
  $q3=$data_wire[0];
  $max=$data_wire[0];
  $var=0;
  $min_ip=$data_ip[0];
  $q1_ip=$data_ip[0];
  $med_ip=$data_ip[0];
  $mean_ip=$data_ip[0];
  $q3_ip=$data_ip[0];
  $max_ip=$data_ip[0];
  $var_ip=0;
  $min_control=$data_control[0];
  $q1_control=$data_control[0];
  $med_control=$data_control[0];
  $mean_control=$data_control[0];
  $q3_control=$data_control[0];
  $max_control=$data_control[0];
  $var_control=0;
}
else
{
#calculating quartiles
@sorted=sort { $a <=> $b } @data_wire;

$location1=$#data_wire/4;
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


#calculating quartiles
@sorted_ip=sort { $a <=> $b } @data_ip;

$q1_ip=$sorted_ip[$index1]+($sorted_ip[$index1+1]-$sorted_ip[$index1])*$fraction1;
$q3_ip=$sorted_ip[$index3]+($sorted_ip[$index3+1]-$sorted_ip[$index3])*$fraction3;

$min_ip=$stat_ip->min();
$med_ip=$stat_ip->median();
$mean_ip=$stat_ip->mean();
$var_ip=$stat_ip->variance();
$max_ip=$stat_ip->max();

#calculating quartiles
@sorted_control=sort { $a <=> $b } @data_control;

$q1_control=$sorted_control[$index1]+($sorted_control[$index1+1]-$sorted_control[$index1])*$fraction1;
$q3_control=$sorted_control[$index3]+($sorted_control[$index3+1]-$sorted_control[$index3])*$fraction3;

$min_control=$stat_control->min();
$med_control=$stat_control->median();
$mean_control=$stat_control->mean();
$var_control=$stat_control->variance();
$max_control=$stat_control->max();
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
  $min_ip=0;
  $q1_ip=0;
  $med_ip=0;
  $mean_ip=0;
  $q3_ip=0;
  $max_ip=0;
  $var_ip=0;
  $min_control=0;
  $q1_control=0;
  $med_control=0;
  $mean_control=0;
  $q3_control=0;
  $max_control=0;
  $var_control=0;
}


print "$time $min $q1 $med $mean $q3 $max $var $min_ip $q1_ip $med_ip $mean_ip $q3_ip $max_ip $var_ip $min_control $q1_control $med_control $mean_control $q3_control $max_control $var_control\n";
