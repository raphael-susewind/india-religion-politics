#!/usr/bin/perl

my $line = "tar -czf ox.tgz ";

for ($i=4;$i<=323;$i++) {$line.= "/data/area-mnni/rsusewind/2011/$i/$i.sqlite"}

system ($line);
