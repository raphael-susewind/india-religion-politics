#!/usr/bin/perl

my $i=$ARGV[0];

use DBI;

my $dbh = DBI->connect("dbi:SQLite:dbname=$i.sqlite","","",{sqlite_unicode => 1});

$dbh->do ("ALTER TABLE booths ADD COLUMN lastupdate CHAR");
$dbh->do ("ALTER TABLE booths ADD COLUMN district CHAR");
$dbh->do ("ALTER TABLE booths ADD COLUMN town CHAR");
$dbh->do ("ALTER TABLE booths ADD COLUMN ward CHAR");
$dbh->do ("ALTER TABLE booths ADD COLUMN thana CHAR");
$dbh->do ("ALTER TABLE booths ADD COLUMN tehsil CHAR");
$dbh->do ("ALTER TABLE booths ADD COLUMN village CHAR");
$dbh->do ("ALTER TABLE booths ADD COLUMN circlecourt CHAR");
$dbh->do ("ALTER TABLE booths ADD COLUMN station_name CHAR");
$dbh->do ("ALTER TABLE booths ADD COLUMN station_address CHAR");
$dbh->do ("ALTER TABLE booths ADD COLUMN areas CHAR");
$dbh->do ("ALTER TABLE booths ADD COLUMN pincode INTEGER");

$dbh->disconnect;

my $dbh = DBI->connect("dbi:SQLite:dbname=../../2012/$i/$i.sqlite","","",{sqlite_unicode => 1});

$dbh->do ("ALTER TABLE booths ADD COLUMN lastupdate CHAR");
$dbh->do ("ALTER TABLE booths ADD COLUMN district CHAR");
$dbh->do ("ALTER TABLE booths ADD COLUMN town CHAR");
$dbh->do ("ALTER TABLE booths ADD COLUMN ward CHAR");
$dbh->do ("ALTER TABLE booths ADD COLUMN thana CHAR");
$dbh->do ("ALTER TABLE booths ADD COLUMN tehsil CHAR");
$dbh->do ("ALTER TABLE booths ADD COLUMN village CHAR");
$dbh->do ("ALTER TABLE booths ADD COLUMN circlecourt CHAR");
$dbh->do ("ALTER TABLE booths ADD COLUMN station_name CHAR");
$dbh->do ("ALTER TABLE booths ADD COLUMN station_address CHAR");
$dbh->do ("ALTER TABLE booths ADD COLUMN areas CHAR");
$dbh->do ("ALTER TABLE booths ADD COLUMN pincode INTEGER");

$dbh->disconnect;

my $dbh = DBI->connect("dbi:SQLite:dbname=../../2013/$i/$i.sqlite","","",{sqlite_unicode => 1});

$dbh->do ("ALTER TABLE booths ADD COLUMN lastupdate CHAR");
$dbh->do ("ALTER TABLE booths ADD COLUMN district CHAR");
$dbh->do ("ALTER TABLE booths ADD COLUMN town CHAR");
$dbh->do ("ALTER TABLE booths ADD COLUMN ward CHAR");
$dbh->do ("ALTER TABLE booths ADD COLUMN thana CHAR");
$dbh->do ("ALTER TABLE booths ADD COLUMN tehsil CHAR");
$dbh->do ("ALTER TABLE booths ADD COLUMN village CHAR");
$dbh->do ("ALTER TABLE booths ADD COLUMN circlecourt CHAR");
$dbh->do ("ALTER TABLE booths ADD COLUMN station_name CHAR");
$dbh->do ("ALTER TABLE booths ADD COLUMN station_address CHAR");
$dbh->do ("ALTER TABLE booths ADD COLUMN areas CHAR");
$dbh->do ("ALTER TABLE booths ADD COLUMN pincode INTEGER");

$dbh->disconnect;

my @files= `ls *pdf`;

foreach my $file (@files) {
    $file =~ /(\d+)-(\d+)/gs;
    $constituency=$1/1;
    $booth=$2;
    chomp ($file);
    system("perl -CSDA -Mlocal::lib -Iperl5/lib/perl5 pdf2list.pl $file");
}

system("rm -r perl5 *.pl pdftotext");
