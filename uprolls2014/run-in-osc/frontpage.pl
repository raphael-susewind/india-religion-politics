#!/usr/bin/perl

use DBI;
use Text::Unidecode;
# use Unicode::Transliterate;
use utf8;

my $file=$ARGV[0];

chomp $file;

$file =~ /(\d+)-(\d+)/gs;
$constituency=$1/1;
$booth=$2;

# my $transliterate = new Unicode::Transliterate (from => 'Devanagari', to => 'Latin');

my $dbh1 = DBI->connect("dbi:SQLite:dbname=$constituency.sqlite","","",{sqlite_unicode => 1});

$dbh1->do ("ALTER TABLE booths ADD COLUMN lastupdate CHAR");
$dbh1->do ("ALTER TABLE booths ADD COLUMN areas CHAR");
$dbh1->do ("ALTER TABLE booths ADD COLUMN station_name CHAR");
$dbh1->do ("ALTER TABLE booths ADD COLUMN station_address CHAR");

$dbh1->do ("ALTER TABLE booths ADD COLUMN village CHAR");
$dbh1->do ("ALTER TABLE booths ADD COLUMN panchayat CHAR");
$dbh1->do ("ALTER TABLE booths ADD COLUMN town CHAR");
$dbh1->do ("ALTER TABLE booths ADD COLUMN ward CHAR");
$dbh1->do ("ALTER TABLE booths ADD COLUMN block CHAR");
$dbh1->do ("ALTER TABLE booths ADD COLUMN thana CHAR");
$dbh1->do ("ALTER TABLE booths ADD COLUMN tehsil CHAR");
$dbh1->do ("ALTER TABLE booths ADD COLUMN district CHAR");
$dbh1->do ("ALTER TABLE booths ADD COLUMN postoffice CHAR");

$dbh1->do ("ALTER TABLE booths ADD COLUMN village_en CHAR");
$dbh1->do ("ALTER TABLE booths ADD COLUMN panchayat_en CHAR");
$dbh1->do ("ALTER TABLE booths ADD COLUMN town_en CHAR");
$dbh1->do ("ALTER TABLE booths ADD COLUMN ward_en CHAR");
$dbh1->do ("ALTER TABLE booths ADD COLUMN block_en CHAR");
$dbh1->do ("ALTER TABLE booths ADD COLUMN thana_en CHAR");
$dbh1->do ("ALTER TABLE booths ADD COLUMN tehsil_en CHAR");
$dbh1->do ("ALTER TABLE booths ADD COLUMN district_en CHAR");
$dbh1->do ("ALTER TABLE booths ADD COLUMN postoffice_en CHAR");

$dbh1->do ("ALTER TABLE booths ADD COLUMN pincode INTEGER");

$dbh1->do("INSERT INTO booths (booth) VALUES (?)", undef, $booth); # create new entry, later it will be merged

# ocr subroutine
sub ocr {
    my $bufferx=$_[0];
    my $buffery=841-$_[1];
    my $width=$_[2];
    my $height=$_[3];
    system("./gs -q -r600 -dFirstPage=1 -dLastPage=1 -sDEVICE=tifflzw -o temp.tif -g".$width."x".$height." -c '<</Install {-$bufferx -$buffery translate}>> setpagedevice' -f $file");
    my $ocr = `tesseract -psm 4 -l hin --tessdata-dir tesseract temp.tif stdout`;
#    system("tesseract -psm 4 -l hin --tessdata-dir tesseract temp.tif temp >/dev/null");
#    open (FILE,"<:utf8","temp.txt");
#    my @temp=<FILE>;
#    close (FILE);
#    my $ocr=join("",@temp);
    system("rm temp.tif");
    return $ocr;
}

#
# lastupdate
#

$raw = ocr(177,215,800,125);
$raw =~ s/\s//gs;

$dbh1->do ("UPDATE booths SET lastupdate = ? WHERE booth = ?",undef,$raw,$booth);

#
# village / town, circlecourt / ward, block, thana, tehsil, district, postoffice, pincode
#

my $raw = ocr(308,491,2150,1565);
$raw=~s/\n\s+\n/\n/gs;

my @raw = split(/\n\s*/, $raw);

for ($i=0;$i<=7;$i++) {$raw[$i]=~s/.*?:\s*//gs; $raw[$i]=~s/\s*$//gs; $raw[$i]=~s/\s+/ /gs;}

if ($raw =~ /नगर\s+:/gs) {
    $dbh1->do ("UPDATE booths SET town = ?, town_en = ? WHERE booth = ?",undef,$raw[0],unidecode($raw[0]),$booth);
    $dbh1->do ("UPDATE booths SET ward = ?, ward_en = ? WHERE booth = ?",undef,$raw[1],unidecode($raw[1]),$booth);
} else {
    $dbh1->do ("UPDATE booths SET village = ?, village_en = ? WHERE booth = ?",undef,$raw[0],unidecode($raw[0]),$booth);
    $dbh1->do ("UPDATE booths SET panchayat = ?, panchayat_en = ? WHERE booth = ?",undef,$raw[1],unidecode($raw[1]),$booth);
}

$dbh1->do ("UPDATE booths SET block = ?, block_en = ? WHERE booth = ?",undef,$raw[2],unidecode($raw[2]),$booth);
$dbh1->do ("UPDATE booths SET thana = ?, thana_en = ? WHERE booth = ?",undef,$raw[3],unidecode($raw[3]),$booth);
$dbh1->do ("UPDATE booths SET tehsil = ?, tehsil_en = ? WHERE booth = ?",undef,$raw[4],unidecode($raw[4]),$booth);
$dbh1->do ("UPDATE booths SET district = ?, district_en = ? WHERE booth = ?",undef,$raw[5],unidecode($raw[5]),$booth);
$dbh1->do ("UPDATE booths SET postoffice = ?, postoffice_en = ? WHERE booth = ?",undef,$raw[6],unidecode($raw[6]),$booth);

$raw[7]=~s/\D//gs;
$dbh1->do ("UPDATE booths SET pincode = ? WHERE booth = ?",undef,$raw[7],$booth);

#
# station_name
#

$raw = ocr(31,568,2300,265);
$raw =~ s/^\s//gs;
$raw =~ s/\s$//gs;
$raw =~ s/\n/ /gs;

$dbh1->do ("UPDATE booths SET station_name = ? WHERE booth = ?",undef,$raw,$booth);

#
# station_address
#

$raw = ocr(31,609,2300,265);
$raw =~ s/^\s//gs;
$raw =~ s/\s$//gs;
$raw =~ s/\n/ /gs;

$dbh1->do ("UPDATE booths SET station_address = ? WHERE booth = ?",undef,$raw,$booth);

#
# areas
#

$raw = ocr(31,492,2250,1800);
$raw =~ s/^\s//gs;
$raw =~ s/\s$//gs;
$raw=~s/\n\s+\n/\n/gs;
$raw=~s/\n/, /gs;  $raw=~s/\s+/ /gs;

$dbh1->do ("UPDATE booths SET station_address = ? WHERE booth = ?",undef,$raw,$booth);

system("./pdftotext -nopgbrk -f 1 -l 1 -layout -r 100 -x 39 -y 384 -W 389 -H 305 $file out.txt");
open (FILE,"<:utf8","out.txt");
my @raw=<FILE>;
close (FILE);
system("rm -f out.txt");
my $raw = join("",@raw);

if ($raw =~ /:/) {$raw =~ s/.*?://gs}
$raw=~s/^\s*//gs; $raw=~s/\s*$//gs; 

$dbh1->do ("UPDATE booths SET areas = ? WHERE booth = ?",undef,$raw,$booth);

#
# Done!
#

$dbh1->disconnect;
