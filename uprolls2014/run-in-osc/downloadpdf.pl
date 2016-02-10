#!/usr/bin/perl
use WWW::Mechanize;

my $const=$ARGV[0];

my $ua = WWW::Mechanize->new(agent=>'Mozilla/5.0 (X11; U; Linux i686; de; rv:1.9.0.16)',cookie_jar=>{},onerror=>undef);

$ua->get("http://ceouttarpradesh.nic.in/Default.aspx");
 
$ua->get("http://ceouttarpradesh.nic.in/_RollPDF.aspx");

if ($const <10) {$const="00$const"}
elsif ($const <100) {$const="0$const"}

for ($no=1;$no<500;$no++) {
    if ($no <10) {$part="00$no"}
    elsif ($no <100) {$part="0$no"}
    else {$part="$no"}
    
    if (!-e "$const-$part-Map.pdf") {
	my $result=$ua->get( "http://164.100.180.82/Rollpdf/AC$const"."_Map/P$const"."0".$part."_Map.pdf", ':content_file' => $const."-".$part."-Map.pdf" );
	next if $result->code == 404;
	if ($result->is_error) {
	    open (REPORT,">>\$HOME/$const.failure");
	    print REPORT "downloadpdf.pl: failed to download map $part: ".$result->status_line."\n";
	    close (REPORT);
	}
    }

    if (!-e "$const-$part-Mother.pdf") {
	my $result=$ua->get( "http://164.100.180.82/Rollpdf/AC$const"."/S24A$const"."P".$part.".pdf", ':content_file' => $const."-".$part."-Mother.pdf" );
	next if $result->code == 404;
	if ($result->is_error) {
	    open (REPORT,">>\$HOME/$const.failure");
	    print REPORT "downloadpdf.pl: failed to download roll $part: ".$result->status_line."\n";
	    close (REPORT);
	}
    }
        
}
