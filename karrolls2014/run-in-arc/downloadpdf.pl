#!/usr/bin/perl

if (!-d 'ceokarnataka.kar.nic.in') {system("mkdir ceokarnataka.kar.nic.in");}
if (!-d 'ceokarnataka.kar.nic.in/Voter-List-2014') {system("mkdir ceokarnataka.kar.nic.in/Voter-List-2014");}

use WWW::Mechanize;
my $ua = WWW::Mechanize->new(agent=>'Mozilla/5.0 (X11; U; Linux i686; de; rv:1.9.0.16)',cookie_jar=>{},onerror=>undef);

$ua->get("http://ceokarnataka.kar.nic.in/draftroll2014/dist_list.aspx");

for ($c=1;$c<=224;$c++) {
    
    print "Download constituency $c\n";
    
    if (!-d 'ceokarnataka.kar.nic.in/Voter-List-2014/'.$c)  {system("mkdir ceokarnataka.kar.nic.in/Voter-List-2014/$c");}
    
    my $const = $c;
    
    if ($const <10) {$const="00$const"}
    elsif ($const <100) {$const="0$const"}
    
    for ($no=1;$no<500;$no++) {
	my $part;
	if ($no <10) {$part="00$no"}
	elsif ($no <100) {$part="0$no"}
	else {$part="$no"}
	
	if (!-e "ceokarnataka.kar.nic.in/Voter-List-2014/$c/$const-$part.pdf") {
	    my $result=$ua->get( "http://ceokarnataka.kar.nic.in/draftroll2014/Kannada/WOIMG/AC".$const."/AC".$const."0".$part.".pdf", ':content_file' => 'ceokarnataka.kar.nic.in/Voter-List-2014/'.$c.'/'.$const."-".$part.".pdf" );
	    next if $result->code == 404;
	    if ($result->is_error) {
		open (REPORT,">>ceokarnataka.kar.nic.in/Voter-List-2014/".$c.'/$const.failure');
		print REPORT "Failed to download roll $part: ".$result->status_line."\n";
		close (REPORT);
	    }
	}
        
    }
}
