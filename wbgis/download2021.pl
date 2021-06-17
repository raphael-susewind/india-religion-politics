#!/usr/bin/perl

#
# psleci.nic.in did not have data uploaded for West Bengal in spring 2021; hence this was run against a WB-specific
# platform advertised at the time of the 2021 assembly elections on the CEO website
#

use DBI;
use JSON;
# use Data::Dumper;

my $dbh = DBI->connect("dbi:SQLite:dbname=westbengal-gis-2021.sqlite","","",{sqlite_unicode => 1});
$dbh->do("CREATE TABLE wbgis (district_id_21 INTEGER, district_name_21 CHAR, ac_id_09 INTEGER, ac_name_21 CHAR, booth_id_21 INTEGER, booth_name_21 CHAR, section_name_21 CHAR, para_name_21 CHAR, pincode_21 INTEGER, policestation_21 CHAR, postoffice_21 CHAR, latitude REAL, longitude REAL)");
$dbh->do("CREATE INDEX wbgisindex ON wbgis (ac_id_09, booth_id_21)");

use WWW::Mechanize;

#
# Loop through all possible GIS localities, based on 2014 locations (the website gives everything in a radius around, so should overall get everything)
#

my %donealready;

open (FILE,"westbengal-gis-2014.csv"); # this is simply latitude,longitude as extracted from wbgis table
my @coord = <FILE>;
foreach my $coord (@coord) {

chomp $coord;
my ($lat,$long) = split(/,/,$coord);

my $la = sprintf("%.7f", $lat);
my $lo = sprintf("%.7f", $long);

print "$la - $lo\n"; 

my $ua = WWW::Mechanize->new(agent=>'Mozilla/5.0 (X11; U; Linux i686; de; rv:1.9.0.16)',cookie_jar=>{},onerror=>undef);

my $response = $ua->post("https://wbceo.in/wb-pssearch/CEOService.asmx/FetchSearchResult", 
'Referer' => "https://wbceo.in/wb-pssearch/",
'Content-Type' => "application/json; charset=UTF-8",
'X-Requested-With' => "XMLHttpRequest",
'Accept' => 'application/json, text/javascript, */*; q=0.01',
'Origin' => 'https://wbceo.in',
'Sec-Fetch-Site' => 'same-origin',
'Sec-Fetch-Mode' => 'cors',
'Sec-Fetch-Dest' => 'empty',
content=>'{"searchparam":{"LocationLat":'.$la.',"LocationLong":'.$lo.'}}');

    next if $ua->content !~ /LocationLat/;


    
my $json = JSON->new;
my $data = $json->decode($ua->content); 

for (@{$data->{d}}) {


    
    if ($donealready{$_->{ACNo}."-".$_->{PARTNO}} == 1) {print "double\n";next}
    
    next if $_->{LocationLat} < 20; # to check whether we have an actual result or an error
    
    $dbh->do("INSERT INTO wbgis VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?)", undef, $_->{DISTRICTID}, $_->{DistrictName}, $_->{ACNo}, $_->{ACName}, $_->{PARTNO}, $_->{PSName}, $_->{SectionName}, $_->{LocalMohaPara}, $_->{Pincode}, $_->{PoliceStationName}, $_->{PostOfficeName}, $_->{LocationLat}, $_->{LocationLong});

    $donealready{$_->{ACNo}."-".$_->{PARTNO}} = 1;      
    

	
	}

}

$dbh->disconnect;

#
# The resulting SQLite file was then cleaned up for duplicates and dumped into wbgis2021.sql using this:
#

