#!/usr/bin/perl -CSDA

open (FILE,"random-names2.csv");
my @file = <FILE>;
close (FILE);

shift(@file);

my $tn; my $fn; my $tp; my $fp;
foreach my $line (@file) {
    if ($line =~ /Non-Muslim/ && $line =~ /,$/) {$tn++}
    elsif ($line =~ /Non-Muslim/) {$fn++}
    elsif ($line =~ /,$/) {$fp++}
    else {$tp++}
}

print "Total lines: ".($tn+$fn+$fp+$tp)."\n";
print "True Negative: $tn\n";
print "False Negative: $fn\n";
print "True Positive: $tp\n";
print "False Positive: $fp\n";

print "Sensitivity: ".($tp/($tp+$fn))."\n";
print "Specificity: ".($tn/($tn+$fp))."\n";
print "PPV: ".($tp/($tp+$fp))."\n";
print "NPV: ".($tn/($tn+$fn))."\n";
