#!/usr/bin/perl

if (!-d 'ceoandhra.nic.in') {system("mkdir ceoandhra.nic.in");}
if (!-d 'ceoandhra.nic.in/Voter-List-2014') {system("mkdir ceoandhra.nic.in/Voter-List-2014");}

use WWW::Mechanize;
my $ua = WWW::Mechanize->new(agent=>'Mozilla/5.0 (X11; U; Linux i686; de; rv:1.9.0.16)',cookie_jar=>{},onerror=>undef,stack_depth=>5);

$ua->add_header(Referer => undef);

const: for ($c=263;$c<=294;$c++) {

    print "Download constituency $c\n";
    
    if (!-d 'ceoandhra.nic.in/Voter-List-2014/'.$c)  {system("mkdir ceoandhra.nic.in/Voter-List-2014/$c");}
    
    my $const = $c;
    
    if ($const <10) {$const="00$const"}
    elsif ($const <100) {$const="0$const"}

    my $error=0; my $errortel=0;
    
    for ($no=1;$no<266;$no++) {
	my $part;
	if ($no <10) {$part="00$no"}
	elsif ($no <100) {$part="0$no"}
	else {$part="$no"}

	if (!-e "ceoandhra.nic.in/Voter-List-2014/$const/$const-$part-English.pdf") {
	    my $result=$ua->get( "http://ceoaperms.ap.gov.in/Electoral_Rolls/PDFGeneration.aspx?urlPath=D:/FinalRolls_2014/AC_".$const."/English/AC".$const."_FIN_E_".$part.".PDF", ':content_file' => 'ceoandhra.nic.in/Voter-List-2014/'.$c.'/'.$const."-".$part."-English.pdf" );
	    next if $result->code == 404;
	    sleep 1;
	    my $file = `file ceoandhra.nic.in/Voter-List-2014/$c/$const-$part-English.pdf`;
	    if ($file !~ /PDF document/ or $result->is_error) {
		system("rm -f ceoandhra.nic.in/Voter-List-2014/$c/$const-$part-English.pdf");
		$error++;
	    }
	}
	
	if (!-e "ceoandhra.nic.in/Voter-List-2014/".$const."/".$const."-$part-Telugu.pdf") {
	    my $result=$ua->get( "http://ceoaperms.ap.gov.in/Electoral_Rolls/PDFGeneration.aspx?urlPath=D:/FinalRolls_2014/AC_".$const."/Telugu/AC".$const."_FIN_T_".$part.".PDF", ':content_file' => 'ceoandhra.nic.in/Voter-List-2014/'.$c.'/'.$const."-".$part."-Telugu.pdf" );
	    next if $result->code == 404;
	    sleep 1;
	    my $file = `file ceoandhra.nic.in/Voter-List-2014/$c/$const-$part-Telugu.pdf`;
	    if ($file !~ /PDF document/ or $result->is_error) {
		system("rm -f ceoandhra.nic.in/Voter-List-2014/$c/$const-$part-Telugu.pdf");
		$errortel++;
	    }
	}
	
	if ($error>5 && $errortel>5) {last}

    }
}

exit; # TODO - the below script was used for a long while, until I discovered the above option for the remaining few ACs

my $startd=21;
my $startc=263;
my $startp=1;

use WWW::Mechanize::Firefox;
my $ua = WWW::Mechanize::Firefox->new();

my $unlock=0;
for ($d=$startd;$d<23;$d++) { # TODO was: $d=1...

    $ua->get("http://ceoaperms.ap.gov.in/Electoral_Rolls/Rolls.aspx");

    $ua->form_name("form1");
    $ua->set_fields("ddlDist" => $d);
    
    sleep 1; while ($ua->content !~ /\<\/html\>\s*$/) {}
    
    my @acraw = $ua->xpath('.//select[@id="ddlAC"]/option/@value');
    my @ac;
    foreach my $temp (@acraw) {push (@ac,$temp->{'value'});}
    
    foreach my $c (@ac) {
	next if $c < 1;

	undef(my %missinglang);
	
	print "Download constituency $c\n";

	$ua->form_name("form1");
	$ua->set_fields("ddlAC" => "$c");
	$ua->click({id=>'btnGetPollingStations'});

	sleep 1; while ($ua->content !~ /\<\/html\>\s*$/) {}
	
	if (!-d 'ceoandhra.nic.in/Voter-List-2014/'.$c)  {system("mkdir ceoandhra.nic.in/Voter-List-2014/$c");}
	
	my $const = $c;
	
	if ($const <10) {$const="00$const"}
	elsif ($const <100) {$const="0$const"}
	
	my @links=$ua->find_all_links(text=>'View');
	
	links: foreach my $link (@links) {
	    $link->url() =~ /\$ctl(\d+)\$lnk(.*?)\'/gs;
	    my $part=$1; my $lang=$2;

	    if ($c == $startc && $part == $startp) {$unlock=1;}
	    next if $unlock==0;

	    next if defined($missinglang{$lang});
	    
	    $ua->click({ xpath => '//a[@id="GridView1_ctl'.$part.'_lnk'.$lang.'"]' });
	    
	    $part--;
	    if ($part <10) {$part="00$part"}
	    elsif ($part <100) {$part="0$part"}
	    
	    print "Booth $part in $lang\n";
	    
	    until (-e '/home/raphael/PDFGeneration.aspx') {
		if ($ua->content =~ /Data will be uploa/) {
		    $missinglang{$lang}=1;
		    print "Revert\n";
		    $ua->back;
		    until (-e '/home/raphael/PDFGeneration.aspx') {}
		    system("rm /home/raphael/PDFGeneration.aspx");
		    next links;
		}
	    }
	    
	    while (-e '/home/raphael/PDFGeneration.aspx' && -e '/home/raphael/PDFGeneration.aspx.part') {}
	    
	    system("mv /home/raphael/PDFGeneration.aspx /home/raphael/ceoandhra.nic.in/Voter-List-2014/$c/$const-$part-$lang.pdf");
	}
	
    }

}
