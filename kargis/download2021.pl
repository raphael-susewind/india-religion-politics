#!/usr/bin/perl

#
# psleci.nic.in did not have all data uploaded in 2021; but this I dug up from electoralsearch.in to transform State & AC & polling booth ID into LatLong!
#

use DBI;
use JSON;
use Data::Dumper;

my $dbh = DBI->connect("dbi:SQLite:dbname=electoralsearch.in.sqlite","","",{sqlite_unicode => 1});
$dbh->do("CREATE TABLE electoralsearch (state CHAR, ac INTEGER, booth INTEGER, latitude REAL, longitude REAL)");

use IO::Socket::SSL;
use WWW::Mechanize;

#
# This is from the original search interface
#

$state{'S01'} = "Andhra Pradesh";
$state{'S02'} = "Arunachal Pradesh";
$state{'S03'} = "Assam";
$state{'S04'} = "Bihar";
$state{'S05'} = "Goa";
$state{'S06'} = "Gujarat";
$state{'S07'} = "Haryana";
$state{'S08'} = "Himachal Pradesh";
$state{'S10'} = "Karnataka";
$state{'S11'} = "Kerala";
$state{'S12'} = "Madhya Pradesh";
$state{'S13'} = "Maharashtra";
$state{'S14'} = "Manipur";
$state{'S15'} = "Meghalaya";
$state{'S16'} = "Mizoram";
$state{'S17'} = "Nagaland";
$state{'S18'} = "Odisha";
$state{'S19'} = "Punjab";
$state{'S20'} = "Rajasthan";
$state{'S21'} = "Sikkim";
$state{'S22'} = "Tamil Nadu";
$state{'S23'} = "Tripura";
$state{'S24'} = "Uttar Pradesh";
$state{'S25'} = "West Bengal";
$state{'S26'} = "Chattisgarh";
$state{'S27'} = "Jharkhand";
$state{'S28'} = "Uttarakhand";
$state{'S29'} = "Telangana";
$state{'U01'} = "Andaman & Nicobar Islands";
$state{'U02'} = "Chandigarh";
$state{'U03'} = "Dadra & Nagar Haveli";
$state{'U04'} = "Daman & Diu";
$state{'U05'} = "Delhi";
$state{'U06'} = "Lakshadweep";
$state{'U07'} = "Puducherry";
$state{'U08'} = "Jammu and Kashmir";
$state{'U09'} = "Ladakh";

#
# Loop through all possible GIS localities, based on 2014 locations (the website gives everything in a radius around, so should overall get everything)
#

statelabel: foreach my $state (keys(%state)) {
    my $stateatall=0;
    aclabel: for (my $ac = 1; $ac <= 500; $ac++) {
	my $ua = WWW::Mechanize->new(agent=>'Mozilla/5.0 (X11; U; Linux i686; de; rv:1.9.0.16)',cookie_jar=>{},onerror=>undef, 'ssl_opts' => {SSL_verify_mode => IO::Socket::SSL::SSL_VERIFY_NONE, 'verify_hostname' => 0 });
#	my $ua = WWW::Mechanize->new();
	my $acatall=0;
	boothlabel: for (my $booth = 1; $booth <= 500; $booth++) {
	    
	    my @check = $dbh->selectrow_array("SELECT count(*) FROM electoralsearch WHERE state = ? AND ac = ? AND booth = ?",undef,$state{$state},$ac,$booth);
	    if ($check[0]>0) {print $state{$state}." AC $ac booth $booth already done\n"; $acatall = 0; $stateatall=0; next}

	    if ($stateatall > 4) {print $state{$state}." too many erros; skipped\n"; $stateatall++; next statelabel}

	    if ($acatall > 4) {print $state{$state}." AC $ac too many erros; skipped\n"; $stateatall++; next aclabel}
	    
	    my $response = $ua->get("https://electoralsearch.in/Home/SearchLatLong?acno=$ac&partno=$booth&st_code=$state");
	    
	    if ($ua->content !~/latlong/) {print $state{$state}." AC $ac booth $booth download error\n"; $acatall++; next boothlabel}
	    
	    $acatall=0; $stateatall=0;
	    
	    my $json = JSON->new;
	    my $data = $json->decode($ua->content);
	    
	    my ($lat,$long)=split(/[,\-\ ]+/,$data->{latlong});
	    
	    $dbh->do("INSERT INTO electoralsearch VALUES (?,?,?,?,?)", undef, $state{$data->{st_code}}, $data->{ac_no}, $data->{partno}, $lat, $long);
	    
	    print $state{$state}." AC $ac booth $booth added\n";
	    
	}
    }
}

$dbh->disconnect;

#
# Dump specific table
#

system("echo 'create table kargis as select distinct ac \"ac_id_09\", booth \"booth_id_21\", latitude, longitude from electoralsearch where state = \"Karnataka\";' | sqlite3 electoralsearch.in.sqlite");
system("echo 'ALTER TABLE kargis ADD COLUMN booth_id_21 INTEGER;' > kargis2021.sql");
system("echo '.dump kargis' | sqlite3 electoralsearch.in.sqlite >> kargis2021.sql");
system("sed -i 's/VALUES/(ac_id_09, booth_id_21, latitude, longitude) VALUES/g' kargis2021.sql");
