#!/usr/bin/perl
use WWW::Mechanize;

my $const=$ARGV[0];

my $ua = WWW::Mechanize->new(agent=>'Mozilla/5.0 (X11; U; Linux i686; de; rv:1.9.0.16)',cookie_jar=>{},onerror=>undef);

if ($const <10) {$const="00$const"}
elsif ($const <100) {$const="0$const"}

for ($no=1;$no<500;$no++) {
    if ($no <10) {$part="00$no"}
    elsif ($no <100) {$part="0$no"}
    else {$part="$no"}
    
    if (!-e "$const-$part-Mother.pdf") {
	my $result = $ua->get( "http://164.100.180.88/Rollpdf/A$const/P$const"."0".$part.".pdf", ':content_file' => $const."-".$part."-Mother.pdf" );
	next if $result->code == 404;
	if ($result->is_error) {
	    open (REPORT,">>$const.failure");
	    print REPORT "downloadpdf.pl: failed to download roll $part: ".$result->status_line."\n";
	    close (REPORT);
	}
    }
    
}
