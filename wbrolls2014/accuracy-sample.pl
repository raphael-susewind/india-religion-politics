#!/usr/bin/perl

# Accuracy of the automated classification against a manual classification of a random sample
# of 1000 West Bengal electors' names (Muslim / non-Muslim). Only the aggregate counts are kept;
# the sample itself was personal data and was removed from this repository (see README.md).

open (FILE,"accuracy-sample.csv");
my @file = <FILE>;
close (FILE);

shift(@file);

my %n;
foreach my $line (@file) {
    chomp $line;
    my ($algorithm, $manual, $count) = split(/,/, $line);
    $n{"$algorithm|$manual"} = $count;
}

my $tp = $n{"Muslim|Muslim"}; my $fp = $n{"Muslim|Non-Muslim"};
my $fn = $n{"Non-Muslim|Muslim"}; my $tn = $n{"Non-Muslim|Non-Muslim"};

print "Total lines: ".($tn+$fn+$fp+$tp)."\n";
print "True Negative: $tn\n";
print "False Negative: $fn\n";
print "True Positive: $tp\n";
print "False Positive: $fp\n";

print "Sensitivity: ".($tp/($tp+$fn))."\n";
print "Specificity: ".($tn/($tn+$fp))."\n";
print "PPV: ".($tp/($tp+$fp))."\n";
print "NPV: ".($tn/($tn+$fn))."\n";
