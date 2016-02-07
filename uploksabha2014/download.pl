#!/usr/bin/perl

use WWW::Mechanize::Firefox;
use DBD::SQLite;
use Text::CSV;
use HTML::TableExtract;

use utf8;

my $ua = WWW::Mechanize::Firefox->new();
$dbh = DBI->connect("DBI:SQLite:dbname=actopc.sqlite", "","", {sqlite_unicode=>1});

for ($pc=1;$pc<=80;$pc++) {

    my $ref = $dbh->selectcol_arrayref("SELECT ac FROM actopc WHERE state_name = 'Uttar Pradesh' AND pc = ?",undef,$pc);
    
    # iterate through relevant ACs
    foreach my $c (@$ref) {

	next if -e "$c.csv";
	
	undef(my $csv);
	undef(my $te);
	
	print "Download constituency $c\n";

	$ua->get("http://164.100.180.4/ceouptemp/districtwiseform20report.aspx");
	$ua->form_name("aspnetForm");
	$ua->set_fields('ctl00$ContentPlaceHolder1$ddlPCName' => $pc);
	
	sleep 5; while ($ua->content !~ /ddlAcNo/) {sleep 2}
	
	$ua->form_name("aspnetForm");
	$ua->set_fields('ctl00$ContentPlaceHolder1$ddlAcNo' => "$c");
	
	sleep 5; while ($ua->content !~ /grdCandidateVotes/) {sleep 2} 
	sleep 5; while ($ua->content !~ /\<\/table\>/) {sleep 2}

	$csv = Text::CSV->new;
	$te = HTML::TableExtract->new( attribs => {id => 'grdCandidateVotes'} );
	$te->parse($ua->content);

	open (FILE, ">:utf8","$c.csv");
	foreach my $row ($te->rows) {
	    $csv->print(\*FILE,$row);
	    print FILE "\n";
	}
	close (FILE);
	
    }
    
}

$dbh->disconnect;
