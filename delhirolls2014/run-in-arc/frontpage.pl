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
$dbh->do ("ALTER TABLE booths ADD COLUMN ward INTEGER");
$dbh->do ("ALTER TABLE booths ADD COLUMN thana CHAR");
$dbh->do ("ALTER TABLE booths ADD COLUMN tehsil CHAR");
$dbh->do ("ALTER TABLE booths ADD COLUMN town CHAR");
$dbh->do ("ALTER TABLE booths ADD COLUMN district CHAR");
$dbh->do ("ALTER TABLE booths ADD COLUMN pincode INTEGER");

# Iterate through frontpages
my @files= `ls *.pdf`;

foreach my $file (@files) {
    $file =~ /(\d+)-(\d+)/gs;
    $booth=$2;
    chomp ($file);

    $xml = `PYTHONPATH=/home/area-mnni/rsusewind/lib/python2.6/site-packages:/system/software/linux-x86_64/lib/python2.6/site-packages python2.6 /home/area-mnni/rsusewind/bin/pdf-table-extract -i $file -p 1 -r 300 -l 0.7 -t cells_xml`;

    my @xml=split(/<\/cell>/,$xml);
    
    my $parts;
    my $ward;
    my $thana;
    my $tehsil;
    my $town;
    my $district;
    my $pincode;
    my $name;
    my $address;
    
    foreach my $cell (@xml) {
	
	if ($cell =~ /No. \&amp\; Name of Sections in the part : (.*)/) {$parts=$1}
	elsif ($cell =~ /Main Town : (.*?) Ward Number : (\d+) Police Station : (.*?) Tehsil: (.*?) District : (.*?) Pin : (\d\d\d\d\d\d)/) {
	    $town = $1;
	    $ward = $2;
	    $thana = $3;
	    $tehsil = $4;
	    $district = $5;
	    $pincode = $6;
	} elsif ($cell =~ /No. and Name of Polling Station : \d+ (.*?) Address of Polling Station : (.*)/) {
            $name = $1;
            $address = $2;
        }   
    }
    
    $dbh->do("UPDATE booths SET name = ?, address = ?, parts = ?, ward = ?, thana = ?, tehsil = ?, town = ?, district = ?, pincode = ? WHERE booth = ?",undef,$name,$address,$parts,$ward,$thana,$tehsil,$town,$district,$pincode,$booth);
}

system("rm temp.tif");

$dbh->disconnect;
undef($dbh);
