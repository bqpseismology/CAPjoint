#!/usr/bin/perl
use strict;
#
# A user-friendly PERL interface to the teleseismic Green's function
# computing program: tel3
# written by Zhenjie Wang
# 
# revision history
#	2014/04/02 Weiwen Chen	add usage and documentation
#


# defaults
my $code = "teles";
my $dt=0.05;		# sampling rate
my $nt=2048;
my $deg2km = 111.2;		# distances are in km 
my $dir = ".";

my ($model,$s_depth,$dist);

# command-line inputs
@ARGV > 1 or die "Usage: tel3.pl -Mmodel/depth [-D] [-Nnt[/dt]] [-Odir] distances
	-M:  set model name and source depth.
	-D:  distances are in degrees (default is km).
	-N:  set time duration ($nt ), dt ($dt s), $nt must be 2^n
	-O:  set output directory name ($dir).\n";

foreach (grep(/^-/,@ARGV)) {
   my $opt = substr($_,1,1);
   my @value = split(/\//,substr($_,2));
   if ($opt eq "D") {
     $deg2km = 1;
   } elsif ($opt eq "N") {
     $nt = $value[0];
     $dt = $value[1] if $#value > 0;
   } elsif ($opt eq "M") {
     $model = $value[0];
     $s_depth = $value[1] if $#value > 0;
   } elsif ($opt eq "O") {
     $dir = join('/',@value);
   } else {
     printf STDERR "wrong option\n";
     exit(0);
   }
}
my (@ddd) = grep(!/^-/,@ARGV);
my $name = "$dir/${model}_${s_depth}";
#my $name = "$dir/${dir}_${s_depth}";
mkdir($dir,0777) unless -d $dir;
mkdir($name,0777) unless -d $name;

open(TEL3,"| $code");
print TEL3 "$model\n";
printf TEL3 "%d %f\n",$nt,$dt;
printf TEL3 "%f %f %f %f\n",$s_depth,0,0,0;
foreach $dist (@ddd) {
  printf TEL3 "%f %f %s\n",0.0,$dist/$deg2km,$dist;
  printf TEL3 "$name/$dist.grn.\n";
}
close(TEL3);

exit(0);
