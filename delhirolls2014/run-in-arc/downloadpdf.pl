#!/usr/bin/perl

if (!-d 'ceodelhi.gov.in') {system("mkdir ceodelhi.gov.in");}
if (!-d 'ceodelhi.gov.in/Voter-List-2014') {system("mkdir ceodelhi.gov.in/Voter-List-2014");}

use WWW::Mechanize;
my $ua = WWW::Mechanize->new(agent=>'Mozilla/5.0 (X11; U; Linux i686; de; rv:1.9.0.16)',cookie_jar=>{},onerror=>undef);

$ua->get("http://ceodelhi.gov.in/Content/AccemblyConstituenty.aspx");

for ($c=1;$c<=70;$c++) {
    
    print "Download constituency $c\n";
    
    if (!-d 'ceodelhi.gov.in/Voter-List-2014/'.$c)  {system("mkdir ceodelhi.gov.in/Voter-List-2014/$c");}
    
    my $const = $c;
    
    if ($const <10) {$const="0$const"}
    
    for ($no=1;$no<300;$no++) {
	my $part;
	if ($no <10) {$part="00$no"}
	elsif ($no <100) {$part="0$no"}
	else {$part="$no"}
	
	if (!-e "ceodelhi.gov.in/Voter-List-2014/$c/$const-$part.pdf") {
	    my $result=$ua->get( "http://ceodelhi.gov.in/WriteReadData/AssemblyConstituency/AC".$const."/A0".$const."0".$part.".pdf", ':content_file' => 'ceodelhi.gov.in/Voter-List-2014/'.$c.'/'.$const."-".$part.".pdf" );
	    next if $result->code == 404;
	    if ($result->is_error) {
		open (REPORT,">>ceodelhi.gov.in/Voter-List-2014/".$c.'/$const.failure');
		print REPORT "Failed to download roll $part: ".$result->status_line."\n";
		close (REPORT);
	    }
	}
        
    }
}
