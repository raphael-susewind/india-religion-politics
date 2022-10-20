#!/usr/bin/perl

my $c = $ARGV[0];

use WWW::Mechanize;
my $ua = WWW::Mechanize->new(agent=>'Mozilla/5.0 (X11; U; Linux i686; de; rv:1.9.0.16)',cookie_jar=>{},onerror=>undef);

print "Download constituency $c\n";

my $const = $c;

if ($const <10) {$const="00$const"}
elsif ($const <100) {$const="0$const"}

for ($no=1;$no<=500;$no++) {
    my $part;
    if ($no <10) {$part="00$no"}
    elsif ($no <100) {$part="0$no"}
    else {$part="$no"}
    
    if (!-e "$const-$part.pdf" && !-e "$const-$part-ocr.pdf") {
	my $result=$ua->get( "http://ceowestbengal.nic.in/FinalRoll?DCID=11%20&ACID=$c&PSID=$part", ':content_file' => $const."-".$part.".pdf" );
	next if $result->code == 404;
	if ($result->is_error) {
	    open (REPORT,">>$const.failure");
	    print REPORT "Failed to download roll $part: ".$result->status_line."\n";
	    print "Failed to download roll $part: ".$result->status_line."\n";
	    close (REPORT);
	} else {print "Downloaded AC $const, booth $part\n"}
    }
   
}
