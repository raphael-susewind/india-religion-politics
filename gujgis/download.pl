#!/usr/bin/perl

# system("rm -f booths-locality.sqlite");
system("rm -f touched");

use DBI;
our $dbh = DBI->connect("dbi:SQLite:dbname=booths-locality.sqlite","","",{sqlite_unicode => 1});
$dbh->do ("CREATE TABLE booths (state CHAR, district INTEGER, district_name CHAR, constituency INTEGER, constituency_name CHAR, booth INTEGER, station_name CHAR, latitude FLOAT, longitude FLOAT)");

$|=1;
use utf8;

use WWW::Mechanize::Firefox;

#
# Iterate through everything while simultaenously saving everything of relevance with a hidden proxy - pretty neat!
#

system("./proxy.pl &");

my $ua = WWW::Mechanize::Firefox->new(autodie=>0,activate=>1,autoclose=>0);          
our $pageloaded=0;

$ua->get("http://www.eci-polldaymonitoring.nic.in/psleci/default.aspx");

my @statesraw = $ua->xpath(".//select[\@name='ddlState']/option");
my @states; my %statesname; foreach my $state (@statesraw) {next if $state->{'textContent'} =~ /Select/; push(@states,$state->{'value'}); $statesname{$state->{'value'}}=$state->{'textContent'};}

my $done=0;
foreach my $state (@states) {
        
    repeat:
      
    next if ($done == 0 && $state ne "S24"); # TODO - to speed up crawling if almost all states are done ;-)
    $done=1;
    
    print "Processing State ".$statesname{$state}."\n";
    
    my @forms = $ua->forms();
    if (scalar(@forms) == 0) {$ua->get("http://www.eci-polldaymonitoring.nic.in/psleci/default.aspx"); goto repeat}
    
    $ua->form_name('form1');
    $ua->field('ddlState' => $state);
    $ua->eval('javascript:setTimeout("__doPostBack(\"ddlState\",\"\")", 0)'); 
    
    my $waittime=0;
    districtsraw: sleep 1;  $waittime++; if ($waittime > 180) {goto repeat}
    my @districtsraw = $ua->xpath(".//select[\@name='ddlDistrict']/option");
    if (scalar(@districtsraw == 1)) {goto districtsraw}
    sleep 1;
    
    my @districts=(); my %districtname; foreach my $district (@districtsraw) {next if $district->{'textContent'} =~ /Select/; push(@districts,$district->{'value'}); $districtname{$district->{'value'}}=$district->{'textContent'}}
    if (scalar(@districts) ==0) {goto repeat}
    
    district: foreach my $district (@districts) {
	my @check = $dbh->selectrow_array("SELECT * from booths WHERE state = ? AND district = ?",undef,$statesname{$state},$district);
	if (scalar(@check)>1) {	print "|--> District ".$districtname{$district}." skipped\n"; next}
	    
	repeatdistrict:
	  
	print "|--> District ".$districtname{$district}."\n";
	
	$ua->form_name('form1');
	
	if ($ua->value('ddlState') ne $state) { # crashed somehow, redo it
	    
	    $ua->form_name('form1');
	    $ua->field('ddlState' => $state);
	    $ua->eval('javascript:setTimeout("__doPostBack(\"ddlState\",\"\")", 0)'); 
	    my $waittime=0;
	    districtsrawagain: sleep 1; $waittime++; if ($waittime > 180) {goto repeatdistrict}
	    my @districtsraw = $ua->xpath(".//select[\@name='ddlDistrict']/option");
	    if (scalar(@districtsraw == 1)) {goto districtsrawagain}
	    sleep 1;
	}
	
	$ua->form_name('form1');
	$ua->field('ddlDistrict' => $district);
	$ua->eval('javascript:setTimeout("__doPostBack(\"ddlDistrict\",\"\")", 0)');
	
	my $waittime=0;
	acraw: sleep 1;
	my @acraw = $ua->xpath(".//select[\@name='ddlAC']/option");
	$waittime++; if ($waittime > 180) {goto repeatdistrict}
	if (scalar(@acraw == 1)) {goto acraw}
	sleep 5;
	
	$ua->click({xpath=>".//input[\@name='imgbtnFind']",synchronize=>0});
	
	my $waittime=0;
	while (!-e "touched") {
	    sleep 1; $waittime++; if ($waittime > 180) {
		system("echo '".$statesname{$state}." ($state) - ".$districtname{$district}." ($district)' >> crashlog");
		print "|--> Crashed, continue with next district\n"; 
		next district;
	    }
	} 
	system("rm -f touched");
	
    }
}

$dbh->disconnect;

system("killall proxy.pl");
