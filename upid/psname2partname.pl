#!/usr/bin/perl -CSDA

use DBI;
use WWW::Mechanize::Firefox;
use HTML::TableExtract;

our $dbh = DBI->connect("DBI:SQLite:dbname=psname2partname.sqlite", "","", {sqlite_unicode=>1});

$dbh->do("CREATE TABLE psname2partname (ac INTEGER, ac_name CHAR, booth INTEGER, booth_name CHAR, part INTEGER, part_name CHAR)");
our $sth=$dbh->prepare("INSERT INTO psname2partname VALUES (?,?,?,?,?,?)");

our $ua = WWW::Mechanize::Firefox->new();
$ua->get("http://164.100.180.82/blosearch/bloSearching.aspx");

my @districtsraw = $ua->xpath('.//select/option/@value');

my @districts;
foreach my $temp (@districtsraw) {push (@districts,$temp->{'value'})}

foreach my $district (@districts) {
    next if ($district eq '0');
    print "Setup district $district\n";
    
#    $dbh->begin_work;

    reruncomplete:
    
    our $ua = WWW::Mechanize::Firefox->new();
    $ua->get("http://164.100.180.82/blosearch/bloSearching.aspx");
    
    $ua->form_name('aspnetForm');
    $ua->set_fields('ctl00$ContentPlaceHolder1$ddlDistrict' => $district);
    
    sleep 5; while ($ua->content !~ /\<\/html\>\s*$/) {}
    
    $ua->form_name('aspnetForm');
    $ua->set_fields('ctl00$ContentPlaceHolder1$ddlAcNo' => 0);

    sleep 5; while ($ua->content !~ /\<\/html\>\s*$/) {}
    
    $ua->click({id=>'ctl00_ContentPlaceHolder1_btnSearch'});

    our $done=0;
    while ($done==0) {
	my $return = eval { 
	    rerun: while ($ua->content !~ /\<\/html\>\s*$/) {}

	    our $te = HTML::TableExtract->new( attribs => {id => 'ctl00_ContentPlaceHolder1_grdDisplay'} );
	    $te->parse($ua->content);
	    
	    foreach $row ($te->rows) {
		my @field=@$row;
		next if $field[7] !~ /BLO\'s Details/;
		$sth->execute($field[1],$field[2],$field[3],$field[4],$field[5],$field[6]);
	    }
	    
	    my @temp=$ua->find_all_links(text=>'Next');
	    if (scalar(@temp)>0) {
		$ua->follow_link(text=>'Next',synchronize=>0);
		goto rerun;
	    } else {
		sleep 5;
		my @temp=$ua->find_all_links(text=>'Next');
		if (scalar(@temp)>0) {
		    $ua->follow_link(text=>'Next',synchronize=>0);
		    goto rerun;
		} elsif ($ua->content !~ /BLO\'s Details/) {
		    goto reruncomplete;
		} else {
		    return 'doneit';
		}
	    }
	} ;
	if ($return eq 'doneit') {$done=1;last}
    }
    
#    $dbh->commit;
    
}

$sth->finish;

$dbh->do("delete from psname2partname where rowid not in (select max(rowid) from psname2partname group by ac,booth,part)"); # delete duplicates
$dbh->do("VACUUM");

$dbh->disconnect;
