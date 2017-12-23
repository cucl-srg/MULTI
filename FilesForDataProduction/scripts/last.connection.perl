open(FILELIST,"$ARGV[0]");

@filelist=<FILELIST>;



foreach $line (@filelist)
{ 
  $i++;	
  print STDERR "\b\b\b\b\b$i";
  split /([\/\-])/, $line;
  $ip1=$_[4];
  $ip2=$_[6];

  $t=$_[8];
  split('\.',$t); $timetofind=sprintf "%d.%06d\n",$_[0],$_[1];

  @found=grep /$ip1\/$ip2|$ip2\/$ip1/i, @filelist;

  foreach $l (@found)
  { 
    $k++;
    split /([\/\-])/, $l;
    $t=$_[8];
    split('\.',$t);
    $time[$k-1]=sprintf "%d.%06d\n",$_[0],$_[1];
  }

  @timesorted = sort {$a <=> $b} @time;

  $n=0;
  while ( $timetofind != $timesorted[$n] )
  {
    $n++;
  }
  if ( $n == 0 )
  {
    $lastconnection="?";
  }
  else
  {
    $lastconnection=$timesorted[$n]-$timesorted[$n-1];
  }

print "$lastconnection\n";
}

