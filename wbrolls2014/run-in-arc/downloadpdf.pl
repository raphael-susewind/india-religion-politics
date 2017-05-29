#!/usr/bin/perl

if (!-d 'ceowestbengal.nic.in') {system("mkdir ceowestbengal.nic.in");}
if (!-d 'ceowestbengal.nic.in/Voter-List-2014') {system("mkdir ceowestbengal.nic.in/Voter-List-2014");}

use DBI;

my $dbh = DBI->connect("dbi:SQLite:dbname=/home/raphael/Promotion/Election-Data/eci-polldaymonitoring.nic.in/all-india/booths-locality.sqlite","","",{sqlite_unicode => 1});
my %shouldbe;
my $sth = $dbh->prepare("SELECT constituency,count(*) 'count' FROM booths WHERE state = 'West Bengal' GROUP BY constituency");
$sth->execute();
while (my $row=$sth->fetchrow_hashref) {
    $shouldbe{$row->{constituency}}=$row->{count};
}
$sth->finish();
$dbh->disconnect();

use WWW::Mechanize;
my $ua = WWW::Mechanize->new(agent=>'Mozilla/5.0 (X11; U; Linux i686; de; rv:1.9.0.16)',cookie_jar=>{},onerror=>undef);

for ($c=1;$c<=294;$c++) {

    print "Download constituency $c\n";

    $ua->get("http://ceowestbengal.nic.in/DistrictList.aspx");
    $ua->add_header(Referer => "http://ceowestbengal.nic.in/DistrictList.aspx");
    
    if (!-d 'ceowestbengal.nic.in/Voter-List-2014/'.$c)  {system("mkdir ceowestbengal.nic.in/Voter-List-2014/$c");}
    
    my $const = $c;
    
    if ($const <10) {$const="00$const"}
    elsif ($const <100) {$const="0$const"}
    
    for ($no=1;$no<=$shouldbe{$c};$no++) {
	my $part;
	if ($no <10) {$part="00$no"}
	elsif ($no <100) {$part="0$no"}
	else {$part="$no"}
	
#	if (!-e "ceowestbengal.nic.in/Voter-List-2014/$c/$const-$part-Map.pdf") {
#	    my $result=$ua->get( "http://www.ceowestbengal.nic.in/sketchmap/m$const"."/m$const"."0".$part.".pdf", ':content_file' => 'ceowestbengal.nic.in/Voter-List-2014/'.$c.'/'.$const."-".$part."-Map.pdf" );
#	   # next if $result->code == 404;
#	    if ($result->is_error) {
#		open (REPORT,">>ceowestbengal.nic.in/Voter-List-2014/".$c.'/$const.failure');
#		print REPORT "Failed to download map $part: ".$result->status_line."\n";
#		close (REPORT);
#	    }
#	}
	
	if (!-e "ceowestbengal.nic.in/Voter-List-2014/$c/$const-$part-Mother.pdf") {
	    my $result=$ua->get( "http://www.ceowestbengal.nic.in/EROLLS/PDF/Bengali/A$const"."/a$const"."0".$part.".pdf", ':content_file' => 'ceowestbengal.nic.in/Voter-List-2014/'.$c.'/'.$const."-".$part."-Mother.pdf" );
	  #  next if $result->code == 404;
	    if ($result->is_error) {
		open (REPORT,">>ceowestbengal.nic.in/Voter-List-2014/".$c.'/$const.failure');
		print REPORT "Failed to download roll $part: ".$result->status_line."\n";
		print "Failed to download roll $part: ".$result->status_line."\n";
		close (REPORT);
	    } else {print "Downloaded AC $const, booth $part\n"}
	}
        
    }
}
