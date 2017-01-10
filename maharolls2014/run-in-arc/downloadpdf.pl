#!/usr/bin/perl

if (!-d 'ceo.maharashtra.gov.in') {system("mkdir ceo.maharashtra.gov.in");}
if (!-d 'ceo.maharashtra.gov.in/Voter-List-2014-Assembly-Elections') {system("mkdir ceo.maharashtra.gov.in/Voter-List-2014-Assembly-Elections");}

use WWW::Mechanize;
my $ua = WWW::Mechanize->new(agent=>'Mozilla/5.0 (X11; U; Linux i686; de; rv:1.9.0.16)',cookie_jar=>{},onerror=>undef,stack_depth=>5);

# $ua->get("http://ceo.maharashtra.gov.in/?module=electoralroll");

ac: for ($c=1;$c<=187;$c++) {
    
    my $errorcount=0;
    
    print "Download constituency $c\n";
    
    if (!-d 'ceo.maharashtra.gov.in/Voter-List-2014-Assembly-Elections/'.$c)  {system("mkdir ceo.maharashtra.gov.in/Voter-List-2014-Assembly-Elections/$c");}
    
    my $const = $c;
    
    if ($const <10) {$const="00$const"}
    elsif ($const <100) {$const="0$const"}
    
    for ($no=1;$no<500;$no++) {
	my $part;
	if ($no <10) {$part="00$no"}
	elsif ($no <100) {$part="0$no"}
	else {$part="$no"}
	
	if (!-e "ceo.maharashtra.gov.in/Voter-List-2014-Assembly-Elections/$c/$const-$part.pdf") {
	    my $result=$ua->get( "http://www.ceo.maharashtra.gov.in/searchpdf/pdf/A$const/A".$const."0$part.pdf", ':content_file' => 'ceo.maharashtra.gov.in/Voter-List-2014-Assembly-Elections/'.$c.'/'.$const."-".$part.".pdf" );
 
	    if ($result->code == 404){
		$errorcount++;
		if ($errorcount>5) {next ac}
		next
	    }
	    if ($result->is_error) {
		open (REPORT,">>ceo.maharashtra.gov.in/Voter-List-2014-Assembly-Elections/".$c.'/$const.failure');
		print REPORT "Failed to download roll $part: ".$result->status_line."\n";
		close (REPORT);
	    }
	}
        
    }
}
