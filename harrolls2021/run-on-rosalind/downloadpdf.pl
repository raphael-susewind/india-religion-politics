#!/usr/bin/perl

my $c = $ARGV[0];

#
# if (!-d 'ceoharyana.nic.in') {system("mkdir ceoharyana.nic.in");}
# if (!-d 'ceoharyana.nic.in/Voter-List-2014') {system("mkdir ceoharyana.nic.in/Voter-List-2014");}
# 
# use WWW::Mechanize;
# my $ua = WWW::Mechanize->new(agent=>'Mozilla/5.0 (X11; U; Linux i686; de; rv:1.9.0.16)',cookie_jar=>{},onerror=>undef);
# 
# $ua->get("http://ceoharyana.nic.in/?module=electoralroll");
# 
# for ($c=81;$c<=90;$c++) {
#     
#     print "Download constituency $c\n";
#     
#     if (!-d 'ceoharyana.nic.in/Voter-List-2014/'.$c)  {system("mkdir ceoharyana.nic.in/Voter-List-2014/$c");}
#     
#     my $const = $c;
#     
#     if ($const <10) {$const="00$const"}
#     elsif ($const <100) {$const="0$const"}
#     
#     for ($no=1;$no<500;$no++) {
# 	my $part;
# 	if ($no <10) {$part="00$no"}
# 	elsif ($no <100) {$part="0$no"}
# 	else {$part="$no"}
# 	
# 	if (!-e "ceoharyana.nic.in/Voter-List-2014/$c/$const-$part.pdf") {
# 	    my $result=$ua->get( "http://ceoharyana.nic.in/docs/pdf/DRAFT_HR".$const."WP/w".$const."0".$part.".pdf", ':content_file' => 'ceoharyana.nic.in/Voter-List-2014/'.$c.'/'.$const."-".$part.".pdf" );
# 	    next if $result->code == 404;
# 	    if ($result->is_error) {
# 		open (REPORT,">>ceoharyana.nic.in/Voter-List-2014/".$c.'/$const.failure');
# 		print REPORT "Failed to download roll $part: ".$result->status_line."\n";
# 		close (REPORT);
# 	    }
# 	}
#         
#     }
# }


# if (!-d 'ceoharyana.nic.in') {system("mkdir ceoharyana.nic.in");}
# if (!-d 'ceoharyana.nic.in/Voter-List-2021') {system("mkdir ceoharyana.nic.in/Voter-List-2021");}

use WWW::Mechanize;
my $ua = WWW::Mechanize->new(agent=>'Mozilla/5.0 (X11; U; Linux i686; de; rv:1.9.0.16)',cookie_jar=>{},onerror=>undef);

# $ua->get("https://ceoharyana.gov.in/WebCMS/Start/1519");

# for ($c=1;$c<=9;$c++) { # up to 90
    
    print "Download constituency $c\n";
    
 #   if (!-d 'ceoharyana.nic.in/Voter-List-2021/'.$c)  {system("mkdir ceoharyana.nic.in/Voter-List-2021/$c");}
    
    my $const = $c;
    
    if ($const <10) {$const="00$const"}
    elsif ($const <100) {$const="0$const"}

my $cac = $c; if ($cac<10) {$cac="0$cac"}
    
    for ($no=1;$no<500;$no++) {
	my $part;
	if ($no <10) {$part="00$no"}
	elsif ($no <100) {$part="0$no"}
	else {$part="$no"}
	
	if (!-e "rolls.$part.sqlite") {
	print "Getting part $part\n";
	    my $result=$ua->get( "http://ceoharyana.gov.in/Finalroll2021/CMB".$cac."/CMB".$const."0".$part.".PDF", ':content_file' => $const."-".$part.".pdf" );
	    if ($result->code == 404) {next}
	    if ($result->is_error) {
		open (REPORT,">>failure");
		print REPORT "Failed to download roll $part: ".$result->status_line."\n";
		close (REPORT);
	    }
	}
        
    }
# }
