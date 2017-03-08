#!/usr/bin/perl

my $i=$ARGV[0];

system("perl -CSDA -Mlocal::lib -I$HOME/perl5/lib/perl5 frontpage.pl $i");
system("rm -r *.pl");
system("touch donefront");
