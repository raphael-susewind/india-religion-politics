#!/usr/bin/perl

use utf8;

use WWW::Mechanize;
my $ua = WWW::Mechanize->new(agent=>'Mozilla/5.0 (X11; U; Linux i686; de; rv:1.9.0.16)',cookie_jar=>{},onerror=>undef);          

use DBI;
my $dbh = DBI->connect("dbi:SQLite:dbname=booths-locality.sqlite","","",{sqlite_unicode => 1});
$dbh->do ("CREATE TABLE booths (district INTEGER, district_name CHAR, constituency INTEGER, constituency_name CHAR, station_name CHAR, booth INTEGER, latitude FLOAT, longitude FLOAT)");

sub normalizecase {
    my @temp=split(/ /,$_[0]);
    my $return;
    foreach my $temp (@temp) {
	$temp=~/(.)(.*)/gs;
	$return.= $1.lc($2)." ";
    }
    $return=~s/ $//;
    return $return;
}

#
# Get corrections from manually identified typos and the like
#

open(COR,"corrections.csv");
my @cor=<COR>;
close(COR);

my %corlat;
my %corlong;
foreach my $string (@cor) {
    chomp ($string);
    my @fields=split(/,/,$string);
    $corlat{$fields[0]}=$fields[1];
    $corlong{$fields[0]}=$fields[2];
}

#
# Download raw files
#

for ($i=1;$i<=71;$i++) { # TODO
    $ua->get("http://gis.up.nic.in:8080/srishti/psmapping/index.php?district=$i");
    my $list=$ua->get("http://gis.up.nic.in:8080/srishti/psmapping/trackhp.php?district=$i");
    my @list=split (/\n/,$list->content);
    my @finalid=();
    my %finalname=();
    my $district='';
    while (scalar(@list)>0) {
	my $line=shift(@list);
	next if $line =~/Embed This Code/;
	if ($district eq '' && $line=~/\<td\>([A-Z ]+)\<\/td\>/) {$district=normalizecase($1);$district=~s/^\s+//gs;$district=~s/\s+$//gs}
	next if $line !~ /\<td \>(\d+)\<\/td\>/;
	my $id=$1;
	my $name=shift(@list);
	next if $name =~/Embed This Code/;
	next if $name !~ /\<td \>([A-Z ]+)\<\/td\>/;
	$name=normalizecase($1);
	push (@finalid,$id);
	$finalname{$id}=$name;
    }
    $ua->get("http://gis.up.nic.in:8080/srishti/psmapping/index.php?district=$i");
    print "Downloading district $i - $district: ";
    foreach my $u (@finalid) {
	print "$u ";
	#
	# Process each raw file
	#
	$ua->get( "http://gis.up.nic.in:8080/srishti/psmapping/trackhp.php?vehicle=$u", ':content_file' => "$u" );
	open (FILE,$u);
	my @data=<FILE>;
	close (FILE);
	my $data=join("",@data);
	$data=~s/\n//gs;
	$data=~s/\s+/ /gs;
	my @stations=split(/\$/,$data);
	foreach my $station (@stations) {
	    my @fields=split(/_/,$station);
	    next if $station=~/javascript/;
	    my $statid=$fields[3].'-'.$fields[2];
	    my $statidold=$fields[3]*10000+$fields[2];
	    if ($fields[3]<10) {$statidold="00$statid"}
	    elsif ($fields[3]<100) {$statidold="0$statid"}
	    if (defined($corlat{$statidold})) {$fields[0]=$corlat{$statid}}
	    if (defined($corlong{$statidold})) {$fields[1]=$corlong{$statid}}
#	    $fields[4]=~s/\d//gs;
	    $fields[4]=~s/,/ /gs;
	    $dbh->do ("INSERT INTO booths VALUES (?, ?, ?, ?, ?, ?, ?, ?)", undef, $i, $district, $fields[3], $finalname{$fields[3]}, $fields[4] , $fields[2], $fields[0], $fields[1]);
    
	}
#	system("rm $u");
    }
    print "\n";
}

