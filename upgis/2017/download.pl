#!/usr/bin/perl

use utf8;

use WWW::Mechanize;
my $ua = WWW::Mechanize->new(agent=>'Mozilla/5.0 (X11; U; Linux i686; de; rv:1.9.0.16)',cookie_jar=>{},onerror=>undef);          

use DBI;
my $dbh = DBI->connect("dbi:SQLite:dbname=booths-locality.sqlite","","",{sqlite_unicode => 1});
$dbh->do ("CREATE TABLE booths (district INTEGER, district_name CHAR, constituency INTEGER, constituency_name CHAR, booth INTEGER, latitude FLOAT, longitude FLOAT)");

#
# Get corrections from manually identified "unavailable stations"
#

open(COR,"unavailable.csv");
my @cor=<COR>;
close(COR);

my %corlat;
my %corlong;
foreach my $string (@cor) {
    chomp ($string);
    my @fields=split(/,/,$string);
    $corlat{$fields[1]."-".$fields[2]}=$fields[3];
    $corlong{$fields[1]."-".$fields[2]}=$fields[4];
}

#
# Download raw files
#

for ($i=1;$i<=403;$i++) {
    $ua->get("http://gis.up.nic.in/srishti/election2017/ac_showpolling.php?ac_common=$i");
    my $data = $ua->content;
    $data=~s/\n//gs;
    $data=~s/\s+/ /gs;
    my @stations=split(/\$/,$data);
    foreach my $station (@stations) {
	my @fields=split(/,/,$station);
	if (defined($corlat{$fields[3]."-".$fields[2]})) {$fields[0]=$corlat{$fields[3]."-".$fields[2]}; $fields[1]=$corlong{$fields[3]."-".$fields[2]}; undef($corlat{$fields[3]."-".$fields[2]}); undef($corlong{$fields[3]."-".$fields[2]})}
	$dbh->do ("INSERT INTO booths VALUES (?, ?, ?, ?, ?, ?, ?)", undef, $fields[6], $fields[4], $i, $fields[5] , $fields[2], $fields[0], $fields[1]);
    }
    print "Processed AC $i\n";
}

#
# Add the latlong for "unavailable stations" that had indeed been unavailable rather than mere corrections
#

foreach my $code (keys(%corlat)) {
    my ($ac,$booth)=split(/-/,$code);
    $dbh->do ("INSERT INTO booths VALUES (?, ?, ?, ?, ?, ?, ?)", undef, undef, undef, $ac, undef, $booth, $corlat{$code}, $corlong{$code});
}
