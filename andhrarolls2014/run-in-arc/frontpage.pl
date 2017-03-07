#!/usr/bin/perl

use DBI;
use utf8;

my $constituency=$ARGV[0];
chomp $constituency;

# Connect to database and alter structure
my $dbh = DBI->connect("dbi:SQLite:dbname=$constituency.sqlite","","",{sqlite_unicode => 1});

$dbh->do ("ALTER TABLE booths ADD COLUMN name CHAR");
$dbh->do ("ALTER TABLE booths ADD COLUMN address CHAR");
$dbh->do ("ALTER TABLE booths ADD COLUMN parts CHAR");
$dbh->do ("ALTER TABLE booths ADD COLUMN village CHAR");
$dbh->do ("ALTER TABLE booths ADD COLUMN thana CHAR");
$dbh->do ("ALTER TABLE booths ADD COLUMN mandal CHAR");
$dbh->do ("ALTER TABLE booths ADD COLUMN revenue CHAR");
$dbh->do ("ALTER TABLE booths ADD COLUMN district CHAR");
$dbh->do ("ALTER TABLE booths ADD COLUMN pincode INTEGER");

# Iterate through frontpages
my @files= `ls *English.pdf`;

foreach my $file (@files) {
    $file =~ /(\d+)-(\d+)/gs;
    $booth=$2;
    chomp ($file);

    $xml = `PYTHONPATH=/home/area-mnni/rsusewind/lib/python2.6/site-packages:/system/software/linux-x86_64/lib/python2.6/site-packages python2.6 /home/area-mnni/rsusewind/bin/pdf-table-extract -i $file -p 1 -r 300 -l 0.7 -t cells_xml`;

    my @xml=split(/<\/cell>/,$xml);
    
    my $parts;
    my $village;
    my $thana;
    my $mandal;
    my $revenue;
    my $district;
    my $pincode;
    my $name;
    my $address;
    
    foreach my $cell (@xml) {
	
	if ($cell =~ /No \&amp\; name of sections in the part: (.*)/) {$parts=$1}
	elsif ($cell =~ /Main Town : (.*?) Police Station : (.*?) Mandal : (.*?) Revenue Division : (.*?) District : (.*?) Pin Code : (\d\d\d\d\d\d)/) {
	    $village = $1;
	    $thana = $2;
	    $mandal = $3;
	    $revenue = $4;
	    $district = $5;
	    $pincode = $6;
	} elsif ($cell =~ /No. \&amp\; name of Polling Station \d+ (.*?) Address of Polling Station (.*)/) {
            $name = $1;
            $address = $2;
        }   
    }
    
    $dbh->do("UPDATE booths SET name = ?, address = ?, parts = ?, village = ?, thana = ?, mandal = ?, revenue = ?, district = ?, pincode = ? WHERE booth = ?",undef,$name,$address,$parts,$village,$thana,$mandal,$revenue,$district,$pincode,$booth);
}

system("rm temp.tif");

$dbh->disconnect;
undef($dbh);
