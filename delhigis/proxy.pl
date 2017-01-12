#! /usr/bin/perl

use HTTP::Proxy;
use HTTP::Proxy::BodyFilter::complete;

#
# Get corrections from manually identified typos and the like
#

open(COR,"corrections.csv");
my @cor=<COR>;
close(COR);

our %corlat;
our %corlong;
foreach my $string (@cor) {
    chomp ($string);
    my @fields=split(/,/,$string);
    $corlat{$fields[0]}=$fields[1];
    $corlong{$fields[0]}=$fields[2];
}

# CORRUPTED, SINCE BASED ON 2009 IDs - either program new or leave it !!!
# our %townpart; # this was manually identified on map, and now gets incorporated from the very beginning: within MODIS shape, which booths are in old LKO, which in new?
# open (LKO,"old-lucknow.csv");
# my @lko=<LKO>;
# close (LKO);
# foreach my $lko (@lko) {chomp($lko);$townpart{$lko}='Old'}
# open (LKO,"new-lucknow.csv");
# my @lko=<LKO>;
# close (LKO);
# foreach my $lko (@lko) {chomp($lko);$townpart{$lko}='New'}

my $proxy = HTTP::Proxy->new(host => "localhost");
$proxy->logmask(32); # 32 - FILTERS
$proxy->push_filter(
    mime => 'application/json',
    response => HTTP::Proxy::BodyFilter::complete->new(),
    response => Spy::BodyFilter->new()
);
$proxy->timeout(900);
$proxy->start;

package Spy::BodyFilter;
use utf8;
use base qw(HTTP::Proxy::BodyFilter);
use JSON;
use DBI;

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


sub will_modify { 0 }

sub filter
{
    my ($me, $dataref, $message) = @_;
    my $raw = $$dataref;
    return unless $raw =~ /InfoHTML/;

    my $json = decode_json( $raw );

    my $touched =0;
    our $dbh = DBI->connect("dbi:SQLite:dbname=booths-locality.sqlite","","",{sqlite_unicode => 1});
    
    foreach my $point (@{${$json}{'d'}{'Points'}}) {
	$touched =1;
	my $description = ${$point}{'InfoHTML'};
	
	$description=~/State\/UT Name\:\Wb\W(.*?)\W\/b\W/gs;
	my $state=$1;
	$description=~/District No and Name \:\Wb\W(\d+?)-(.*?)\W\/b\W/gs;
	my $district=$1;
	my $district_name=$2;
	$description=~/AC No and Name \:\Wb\W(\d+?)-(.*?)\W\/b\W/gs;
	my $constituency=$1;
	my $constituency_name=$2;
	$description=~/PS NO and Name \: \Wb\W(\d+?)-(.*?)\W\/b\W/gs;
	my $booth=$1;
	my $booth_name=normalizecase($2);
	my $latitude=${$point}{'Latitude'};
	my $longitude=${$point}{'Longitude'};
	
	my $statidold=$constituency*10000+$booth;
	if ($constituency<10) {$statidold="00$statidold"}
	elsif ($constituency<100) {$statidold="0$statidold"}
	if (defined($corlat{$statidold}) && $state eq 'Uttar Pradesh') {$latitude=$corlat{$statidold}}
	if (defined($corlong{$statidold}) && $state eq 'Uttar Pradesh') {$longitude=$corlong{$statidold}}
#	my $townpart=$townpart{$statidold};
	
	$dbh->do ("INSERT INTO booths VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)", undef, $state, $district, $district_name, $constituency, $constituency_name, $booth, $booth_name, $latitude, $longitude);
    }
    
    if ($touched == 1) {system("touch touched");}
    $dbh->disconnect();

}

