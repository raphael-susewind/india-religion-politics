#!/usr/bin/perl

if (!-d 'ceorajasthan.nic.in') {system("mkdir ceorajasthan.nic.in");}
if (!-d 'ceorajasthan.nic.in/Voter-List-2014') {system("mkdir ceorajasthan.nic.in/Voter-List-2014");}

use WWW::Mechanize;
my $ua = WWW::Mechanize->new(agent=>'Mozilla/5.0 (X11; U; Linux i686; de; rv:1.9.0.16)',cookie_jar=>{},onerror=>undef,stack_depth=>5);

# $ua->get("http://ceorajasthan.nic.in/?module=electoralroll");

for ($c=1;$c<=200;$c++) {
    
    print "Download constituency $c\n";
    
    if (!-d 'ceorajasthan.nic.in/Voter-List-2014/'.$c)  {system("mkdir ceorajasthan.nic.in/Voter-List-2014/$c");}
    
    my $const = $c;
    
    if ($const <10) {$const="00$const"}
    elsif ($const <100) {$const="0$const"}
    
    for ($no=1;$no<500;$no++) {
	my $part;
	if ($no <10) {$part="00$no"}
	elsif ($no <100) {$part="0$no"}
	else {$part="$no"}
	
	if (!-e "ceorajasthan.nic.in/Voter-List-2014/$c/$const-$part.pdf") {
	    my $result=$ua->get( "http://www.ceorajasthan.nic.in/erolls/pdf/dper/A$const/A$const$part.pdf", ':content_file' => 'ceorajasthan.nic.in/Voter-List-2014/'.$c.'/'.$const."-".$part.".pdf" );
	    next if $result->code == 404;
	    if ($result->is_error) {
		open (REPORT,">>ceorajasthan.nic.in/Voter-List-2014/".$c.'/$const.failure');
		print REPORT "Failed to download roll $part: ".$result->status_line."\n";
		close (REPORT);
	    }
	}
        
    }
}
