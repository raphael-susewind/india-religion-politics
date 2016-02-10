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
    
    if (!-e "$const-$part-Supp-2.pdf") {
	my $result=$ua->get( "http://164.100.180.88/Rollpdf/AC$const"."_Sup2/P$const"."0".$part."_Sup2.pdf", ':content_file' => $const."-".$part."-Supp-2.pdf" );
	next if $result->code == 404;
	if ($result->is_error) {
	    open (REPORT,">>\$HOME/$const.failure");
	    print REPORT "downloadpdf.pl: failed to download supplementary roll $part: ".$result->status_line."\n";
	    close (REPORT);
	}
    }
     
    if (!-e "$const-$part-Supp-3.pdf") {
	my $result=$ua->get( "http://164.100.180.88/Rollpdf/AC$const"."_Sup3/P$const"."0".$part."_Sup3.pdf", ':content_file' => $const."-".$part."-Supp-3.pdf" );
	next if $result->code == 404;
	if ($result->is_error) {
	    open (REPORT,">>\$HOME/$const.failure");
	    print REPORT "downloadpdf.pl: failed to download supplementary roll $part: ".$result->status_line."\n";
	    close (REPORT);
	}
    }

    if (!-e "$const-$part-Supp-4.pdf") {
	my $result=$ua->get( "http://164.100.180.88/Rollpdf/AC$const"."_Sup4/P$const"."0".$part."_Sup4.pdf", ':content_file' => $const."-".$part."-Supp-4.pdf" );
	next if $result->code == 404;
	if ($result->is_error) {
	    open (REPORT,">>\$HOME/$const.failure");
	    print REPORT "downloadpdf.pl: failed to download supplementary roll $part: ".$result->status_line."\n";
	    close (REPORT);
	}
    }
        
}
