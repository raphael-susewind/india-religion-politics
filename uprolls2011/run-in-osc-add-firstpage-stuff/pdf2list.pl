#!/usr/bin/perl

use DBI;
use utf8;

my $file=$ARGV[0];

chomp $file;

$file =~ /(\d+)-(\d+)/gs;
$constituency=$1/1;
$booth=$2;

my $dbh1 = DBI->connect("dbi:SQLite:dbname=$constituency.sqlite","","",{sqlite_unicode => 1});
my $dbh2 = DBI->connect("dbi:SQLite:dbname=../../2012/$constituency/$constituency.sqlite","","",{sqlite_unicode => 1});
my $dbh3 = DBI->connect("dbi:SQLite:dbname=../../2013/$constituency/$constituency.sqlite","","",{sqlite_unicode => 1});

#
# lastupdate
#

system("./pdftotext -nopgbrk -f 1 -l 1 -layout -r 100 -x 233 -y 238 -W 203 -H 27 $file out.txt");
open (FILE,"<:utf8","out.txt");
my @raw=<FILE>;
close (FILE);
system("rm -f out.txt");
my $raw = join("",@raw);

$raw =~ s/\s//gs;
if ($raw =~ /:/) {$raw =~ s/.*?://gs}

$dbh1->do ("UPDATE booths SET lastupdate = ? WHERE booth = ?",undef,$raw,$booth);
$dbh2->do ("UPDATE booths SET lastupdate = ? WHERE booth = ?",undef,$raw,$booth);
$dbh3->do ("UPDATE booths SET lastupdate = ? WHERE booth = ?",undef,$raw,$booth);

#
# village / town, circlecourt / ward, thana, tehsil, district, pincode
#

system("./pdftotext -nopgbrk -f 1 -l 1 -layout -r 100 -x 479 -y 558 -W 298 -H 190 $file out.txt");
open (FILE,"<:utf8","out.txt");
my @raw=<FILE>;
close (FILE);
system("rm -f out.txt");
my $raw = join("",@raw);

$raw[$i]=~s/^\s*//gs; $raw[$i]=~s/\s*$//gs;

my @raw = split(/\n\s*/, $raw);

for ($i=0;$i<=5;$i++) {$raw[$i]=~s/^.*?:\s*//gs; $raw[$i]=~s/\s*$//gs; $raw[$i]=~s/\s+/ /gs;}

if ($raw =~ /मुख्य नगर/gs) {
    $dbh1->do ("UPDATE booths SET town = ? WHERE booth = ?",undef,$raw[0],$booth);
    $dbh2->do ("UPDATE booths SET town = ? WHERE booth = ?",undef,$raw[0],$booth);
    $dbh3->do ("UPDATE booths SET town = ? WHERE booth = ?",undef,$raw[0],$booth);
    $dbh1->do ("UPDATE booths SET ward = ? WHERE booth = ?",undef,$raw[1],$booth);
    $dbh2->do ("UPDATE booths SET ward = ? WHERE booth = ?",undef,$raw[1],$booth);
    $dbh3->do ("UPDATE booths SET ward = ? WHERE booth = ?",undef,$raw[1],$booth);
} else {
    $dbh1->do ("UPDATE booths SET village = ? WHERE booth = ?",undef,$raw[0],$booth);
    $dbh2->do ("UPDATE booths SET village = ? WHERE booth = ?",undef,$raw[0],$booth);
    $dbh3->do ("UPDATE booths SET village = ? WHERE booth = ?",undef,$raw[0],$booth);
    $dbh1->do ("UPDATE booths SET circlecourt = ? WHERE booth = ?",undef,$raw[1],$booth);
    $dbh2->do ("UPDATE booths SET circlecourt = ? WHERE booth = ?",undef,$raw[1],$booth);
    $dbh3->do ("UPDATE booths SET circlecourt = ? WHERE booth = ?",undef,$raw[1],$booth);
}

$dbh1->do ("UPDATE booths SET thana = ? WHERE booth = ?",undef,$raw[2],$booth);
$dbh2->do ("UPDATE booths SET thana = ? WHERE booth = ?",undef,$raw[2],$booth);
$dbh3->do ("UPDATE booths SET thana = ? WHERE booth = ?",undef,$raw[2],$booth);

$dbh1->do ("UPDATE booths SET tehsil = ? WHERE booth = ?",undef,$raw[3],$booth);
$dbh2->do ("UPDATE booths SET tehsil = ? WHERE booth = ?",undef,$raw[3],$booth);
$dbh3->do ("UPDATE booths SET tehsil = ? WHERE booth = ?",undef,$raw[3],$booth);

$dbh1->do ("UPDATE booths SET district = ? WHERE booth = ?",undef,$raw[4],$booth);
$dbh2->do ("UPDATE booths SET district = ? WHERE booth = ?",undef,$raw[4],$booth);
$dbh3->do ("UPDATE booths SET district = ? WHERE booth = ?",undef,$raw[4],$booth);

$dbh1->do ("UPDATE booths SET pincode = ? WHERE booth = ?",undef,$raw[5],$booth);
$dbh2->do ("UPDATE booths SET pincode = ? WHERE booth = ?",undef,$raw[5],$booth);
$dbh3->do ("UPDATE booths SET pincode = ? WHERE booth = ?",undef,$raw[5],$booth);

#
# station_name
#

system("./pdftotext -nopgbrk -f 1 -l 1 -layout -r 100 -x 87 -y 806 -W 416 -H 43 $file out.txt");
open (FILE,"<:utf8","out.txt");
my @raw=<FILE>;
close (FILE);
system("rm -f out.txt");
my $raw = join("",@raw);

if ($raw =~ /:/) {$raw =~ s/.*?://gs}
$raw=~s/^\s*//gs; $raw=~s/\s*$//gs; $raw=~s/\n/, /gs;  $raw=~s/\s+/ /gs;

$dbh1->do ("UPDATE booths SET station_name = ? WHERE booth = ?",undef,$raw,$booth);
$dbh2->do ("UPDATE booths SET station_name = ? WHERE booth = ?",undef,$raw,$booth);
$dbh3->do ("UPDATE booths SET station_name = ? WHERE booth = ?",undef,$raw,$booth);

#
# station_address
#

system("./pdftotext -nopgbrk -f 1 -l 1 -layout -r 100 -x 87 -y 865 -W 416 -H 64 $file out.txt");
open (FILE,"<:utf8","out.txt");
my @raw=<FILE>;
close (FILE);
system("rm -f out.txt");
my $raw = join("",@raw);

if ($raw =~ /:/) {$raw =~ s/.*?://gs}
$raw=~s/^\s*//gs; $raw=~s/\s*$//gs; $raw=~s/\n/, /gs;  $raw=~s/\s+/ /gs;

$dbh1->do ("UPDATE booths SET station_address = ? WHERE booth = ?",undef,$raw,$booth);
$dbh2->do ("UPDATE booths SET station_address = ? WHERE booth = ?",undef,$raw,$booth);
$dbh3->do ("UPDATE booths SET station_address = ? WHERE booth = ?",undef,$raw,$booth);

#
# areas
#

system("./pdftotext -nopgbrk -f 1 -l 1 -layout -r 100 -x 87 -y 387 -W 390 -H 360 $file out.txt");
open (FILE,"<:utf8","out.txt");
my @raw=<FILE>;
close (FILE);
system("rm -f out.txt");
my $raw = join("",@raw);

if ($raw =~ /:/) {$raw =~ s/.*?://gs}
$raw=~s/^\s*//gs; $raw=~s/\s*$//gs; $raw=~s/\n/, /gs;  $raw=~s/\s+/ /gs;

$dbh1->do ("UPDATE booths SET areas = ? WHERE booth = ?",undef,$raw,$booth);
$dbh2->do ("UPDATE booths SET areas = ? WHERE booth = ?",undef,$raw,$booth);
$dbh3->do ("UPDATE booths SET areas = ? WHERE booth = ?",undef,$raw,$booth);


$dbh1->disconnect;
$dbh2->disconnect;
$dbh3->disconnect;
