#! /usr/bin/perl

system("pdftotext -layout VolIII_DetailsOfAssemblySegmentsOfPC.pdf");

sub normalizecase {
    my @temp=split(/[ \.\-]/,$_[0]);
    my $return;
    foreach my $temp (@temp) {
	$temp=~/(.)(.*)/gs;
	$return.= $1.lc($2)." ";
    }
    $return=~s/ $//;
    return $return;
}

use DBI;
our $dbh = DBI->connect("dbi:SQLite:dbname=actopc.sqlite","","",{sqlite_unicode => 1});
$dbh->do("CREATE TABLE actopc (state INTEGER, state_name CHAR, pc INTEGER, pc_name CHAR, pc_reserved CHAR, ac INTEGER, ac_name CHAR, ac_reserved CHAR)");    

open(FILE,"VolIII_DetailsOfAssemblySegmentsOfPC.txt");
my @file = <FILE>;
close(FILE);

my $state; my $statename; my $pc; my $pcname; my $pcreserved; my $ac; my $acname; my $acreserved;
while (my $line = shift(@file)) {
    chomp($line);
    
    if ($line =~ /^State-UT Code \& Name \:\s+(...) - (.*?)\s*$/) {$state=$1; $statename=normalizecase($2)}
    elsif ($line =~ /^PC No. & Name \:\s+(\d+) - (.*?)\s*$/) {
	$pc=$1; $pcname=normalizecase($2);
	if ($pcname =~s/\s*\(st\)//gs) {$pcreserved = 'ST'} 
	elsif ($pcname =~s/\s*\(sc\)//gs) {$pcreserved = 'SC'} 
	else {$pcreserved=''}
    }
    elsif ($line =~ /^AC Number and AC Name \:\s+(\d+) - (.*?)\s*$/) {
	$ac=$1; $acname=normalizecase($2);
	if ($acname =~s/\s*\(st\)//gs) {$acreserved = 'ST'} 
	elsif ($acname =~s/\s*\(sc\)//gs) {$acreserved = 'SC'} 
	else {$acreserved=''}
	next if $statename ne 'Orissa';
	$dbh->do("INSERT INTO actopc VALUES (?,?,?,?,?,?,?,?)",undef,$state,$statename,$pc,$pcname,$pcreserved,$ac,$acname,$acreserved);
    }
    
}

$dbh->disconnect;
