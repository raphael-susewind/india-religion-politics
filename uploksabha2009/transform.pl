#!/usr/bin/perl -CSDA

use DBI;

use Text::WagnerFischer 'distance';
use Text::CSV;
use List::Util 'min';
use List::MoreUtils 'indexes';

#
# First read manually compiled results and rewrite into useful format in fake memory CSV
# (originally this went into a real CSV, hence the weirdish processing chain here)
#

open (FILE, "results.csv");
my @in = <FILE>;
my $header = shift (@in);
close (FILE);

my $csv = Text::CSV->new();

my $oldconst=0; my $i=1; my %out; my %parties; my $oldboothname; my %oldparty;

while (my $line = shift(@in)) {
    $csv->parse($line);
    my @columns = $csv->fields();
    $out{$i}->{'constituency_id'}=shift(@columns);
    next if $out{$i}->{'constituency_id'} !~ /\d/;
    $out{$i}->{'constituency_name'}=shift(@columns);
    $out{$i}->{'constituency_reserved'}=shift(@columns);
    $out{$i}->{'booth_id'}=shift(@columns);
    $out{$i}->{'booth_name'}=shift(@columns);
    if ($out{$i}->{'booth_name'} =~ /^,,/) {$out{$i}->{'booth_name'}=$oldboothname}
    $oldboothname = $out{$i}->{'booth_name'};
    $out{$i}->{'electors'}=shift(@columns);
    $out{$i}->{'turnout_male'}=shift(@columns);
    $out{$i}->{'turnout_female'}=shift(@columns);
    shift (@columns);
    shift (@columns);
    shift (@columns);
    my $indcount=1;
    for ($p=0;$p<scalar(@columns)/3;$p++) {
	shift (@columns);
	if ($oldconst == $out{$i}->{'constituency_id'}) { 
	    shift (@columns);
	    $party = $oldparty{$p};
	    $votes = shift (@columns);
	    $votes =~ s/\D//gs;
	} else {
	    $party = shift (@columns);
	    $party =~ s/\.//gs;
	    $party =~ s/\,//gs;
	    $party =~ s/\)//gs;
	    $party =~ s/\(/-/gs;
	    $party =~ s/\s//gs;
	    $party = lc($party);
	    if ($party =~ /\d/) {print $out{$i}->{'constituency_id'};}
	    if ($party eq 'nir') {$party = 'ind'}
	    if ($party eq 'ind') {$party = $party.$indcount; $indcount++}
	    if ($party eq 'a-p-') {$party = 'ap'}
	    if ($party eq 'a-p') {$party = 'ap'}
	    if ($party eq 'apnadal') {$party = 'ad'}
	    if ($party eq 'b-j-') {$party = 'bj'}
	    if ($party eq 'bahujansamajparty') {$party = 'bsp'}
	    if ($party eq 'bhartiyajantaparty') {$party = 'bjp'}
	    if ($party eq 'bhartiyasatyarthsangthan') {$party = 'bss'}
	    if ($party eq 'cpi-ml-l') {$party = 'cpi-mll'}
	    if ($party eq 'cpim') {$party = 'cpi-m'}
	    if ($party eq 'cpiml') {$party = 'cpi-ml'}
	    if ($party eq 'cpoi-ml-l') {$party = 'cpi-mll'}
	    if ($party eq 'hasiya,hatoda,sitara') {$party = 'hhs'}
	    if ($party eq 'indianjp') {$party = 'ijp'}
	    if ($party eq 'indiannationalcongres') {$party = 'inc'}
	    if ($party eq 'janmorch') {$party = 'jm'}
	    if ($party eq 'janmorcha') {$party = 'jm'}
	    if ($party eq 'janmo') {$party = 'jm'}
	    if ($party eq 'jd-secular') {$party = 'jd-s'}
	    if ($party eq 'l-d') {$party = 'ld'}
	    if ($party eq 'lokdal') {$party = 'ld'}
	    if ($party eq 'lokjanp') {$party = 'ljp'}
	    if ($party eq 'rastriyalokdal') {$party = 'rld'}
	    if ($party eq 'samajwadiparty') {$party = 'sp'}
	    if ($party eq 'samta') {$party = 's'}
	    if ($party eq 'samtap') {$party = 's'}
	    if ($party eq 's-p-') {$party = 'sp'}
	    if ($party eq 'samtaparty') {$party = 's'}
	    if ($party eq 'samtapartyp') {$party = 's'}
	    if ($party eq 'samyawadiparty') {$party = 'sap'}
	    if ($party eq 'shivsena') {$party = 'ss'}
	    if ($party eq 'shivsenap') {$party = 'ss'}
	    if ($party =~ /sjp./gs && $party ne 'sjpr' && $party ne 'sjp-r') {$party = 'sjp'}
	    if ($party eq 'hasiyahatodasitara') {$party='hhs'}
	    if ($party eq '') {$party = 'unknown'}
	    $parties{$party}=1;
	    $oldparty{$p}=$party;
	    $votes = shift (@columns);
	    $votes =~ s/\D//gs;
	}
	$out{$i}->{$party}=$votes;
    }
    $oldconst = $out{$i}->{'constituency_id'};
    $i++;
}

my @headers = ('constituency_id','constituency_name','constituency_reserved','booth_id','booth_name','electors','turnout_male','turnout_female',sort(keys(%parties)));

$csv->combine(@headers);
my @tempcsv = ($csv->string."\n");

foreach my $line (sort {$a <=> $b} (keys(%out))) {
    undef(my @line);
    push (@line, $out{$line}->{'constituency_id'});
    push (@line, $out{$line}->{'constituency_name'});
    push (@line, $out{$line}->{'constituency_reserved'});
    push (@line, $out{$line}->{'booth_id'});
    push (@line, $out{$line}->{'booth_name'});
    push (@line, $out{$line}->{'electors'});
    push (@line, $out{$line}->{'turnout_male'});
    push (@line, $out{$line}->{'turnout_female'});
    foreach my $party (sort(keys(%parties))) { push (@line, $out{$line}->{$party}) }
    $csv->combine(@line);
    push (@tempcsv,$csv->string."\n");
}

#
# Now create temporary sqlite table structure
#

my $dbh = DBI->connect("dbi:SQLite:dbname=:memory:","","",{sqlite_unicode => 1});

$dbh->do ("CREATE TABLE uploksabha2009 (id INTEGER PRIMARY KEY)");

$dbh->do ("CREATE TABLE upid (ac_id_09 INTEGER)");

print "Adding 2009 Parliamentary results\n";

my $csv=Text::CSV->new();

$dbh->begin_work;

my $header=shift(@tempcsv);
chomp($header);
$csv->parse($header);
my @header=$csv->fields();
my @realheader=();

$dbh->do ("ALTER TABLE upid ADD COLUMN ac_id_09 INTEGER");
$dbh->do ("ALTER TABLE upid ADD COLUMN ac_name_09 CHAR");
$dbh->do ("ALTER TABLE upid ADD COLUMN ac_reserved_09 CHAR");
$dbh->do ("ALTER TABLE upid ADD COLUMN booth_id_09 INTEGER");
$dbh->do ("ALTER TABLE upid ADD COLUMN station_name_09 CHAR");

$dbh->do ("ALTER TABLE uploksabha2009 ADD COLUMN ac_id_09 INTEGER");
push(@realheader,'ac_id_09');
$dbh->do ("ALTER TABLE uploksabha2009 ADD COLUMN booth_id_09 INTEGER");
push(@realheader,'booth_id_09');
$dbh->do ("ALTER TABLE uploksabha2009 ADD COLUMN electors_09 INTEGER");
push(@realheader,'electors_09');
$dbh->do ("ALTER TABLE uploksabha2009 ADD COLUMN turnout_09 INTEGER");
push(@realheader,'turnout_09');
$dbh->do ("ALTER TABLE uploksabha2009 ADD COLUMN turnout_percent_09 FLOAT");
push(@realheader,'turnout_percent_09');
$dbh->do ("ALTER TABLE uploksabha2009 ADD COLUMN male_votes_09 INTEGER");
push(@realheader,'male_votes_09');
$dbh->do ("ALTER TABLE uploksabha2009 ADD COLUMN female_votes_09 INTEGER");
push(@realheader,'female_votes_09');
$dbh->do ("ALTER TABLE uploksabha2009 ADD COLUMN female_votes_percent_09 FLOAT");
push(@realheader,'female_votes_percent_09');

foreach my $header (@header) {
    if ($header eq 'constituency_id' or $header eq 'constituency_name' or $header eq 'constituency_reserved' or $header eq 'booth_id' or $header eq 'booth_name' or $header eq 'electors' or $header eq 'turnout_male' or $header eq 'turnout_female' or $header =~ /[^A-Za-z0\-]/) {next}
    $header=~s/-/_/gs;
    my $statement="ALTER TABLE uploksabha2009 ADD COLUMN votes_".$header."_09 INTEGER";
    $dbh->do ($statement);
    push(@realheader,'votes_'.$header.'_09');
    my $statement="ALTER TABLE uploksabha2009 ADD COLUMN votes_".$header."_percent_09 FLOAT";
    $dbh->do ($statement);
    push(@realheader,'votes_'.$header.'_percent_09');
}

$dbh->commit;

#
# Fill table with 2009 results
#

$dbh->do ("CREATE INDEX ac_booth_id_09 ON uploksabha2009 (ac_id_09, booth_id_09)");

$dbh->begin_work;

my $oldstationname='';
my $oldconst = 0;
foreach my $line (@tempcsv) {
    chomp($line);
    
    $csv->parse($line);
    my @fields=$csv->fields();
    
    my $constituency_id = shift(@fields);
    next if $constituency_id !~ /\d/;
    if ($constituency_id != $oldconst) {print "  $constituency_id\n"; $oldconst = $constituency_id}
    my $constituency_name = shift(@fields);
    my $constituency_reserved = uc(shift(@fields));
    my $booth_id = shift (@fields);

    my $station_name = shift (@fields);
    $station_name =~ s/[1-9]//gs; # this is to enable easier integration later on - we are interested in station_name, not booth_name
    $station_name =~ s/^\d//gs;
    # remove identical substrings of words - to fetch at least some of the cases where this happens...
    $station_name =~s/^(.+) (.*) \1 /$1 $2 /gsi;
    $station_name =~s/ (.+) (.*) \1$/ $1 $2/gsi;
    $station_name =~s/^(.+) (.*) \1$/$1 $2/gsi;
    $station_name =~s/ (.+) (.*) \1 / $1 $2 /gsi;
    $station_name =~s/ (.+) (.*) \1 / $1 $2 /gsi;
    $station_name =~s/^(.+) \1 /$1 /gsi;
    $station_name =~s/ (.+) \1$/ $1/gsi;
    $station_name =~s/^(.+) \1$/$1/gsi;
    $station_name =~s/ (.+) \1 / $1 /gsi;
    $station_name =~s/ (.+) \1 / $1 /gsi;
    
    $station_name =~ s/^izk[ \-]ik[ \-]\]*/izk ik/gs; # unify "primary school"
    $station_name =~ s/^izk[ \-]fo[ \-]\]*/izk ik/gs;
    $station_name =~ s/^izkfo\|ky\;/izk ik/gs;
    $station_name =~ s/^izkikB\'kkyk/izk ik/gs;
    $station_name =~ s/^izk\s*ikB\'kkyk/izk ik/gs;
    $station_name =~ s/^izk\s*fo\|ky\;/izk ik/gs;
  
    my $temp = distance($oldstationname,$station_name);
    if ($temp <= 1 || $temp < length($station_name)/7.5) {$station_name = $oldstationname} else {$oldstationname = $station_name}
    
    my $electors = int(shift (@fields));
    my $male_votes = int(shift (@fields));
    my $female_votes = int(shift (@fields));
    my $turnout = $male_votes + $female_votes;
    my $turnout_percent = 0; if ($electors > 0) {$turnout_percent=int($turnout/$electors*10000)/100;}
    my $female_votes_percent = 0; if ($turnout > 0) {$female_votes_percent=int($female_votes/$turnout*10000)/100;}
    
    my @add=();
    foreach my $party (@fields) {
	push (@add,int($party));
	if ($turnout>0) {push (@add,int($party/$turnout*10000)/100);} else  {push (@add,0);}
   }
    
    $booth_id=~s/\D//gs; # this is to integrate polling booths spread across several rolls (110 and 110v etc)
    
    my $sth = $dbh->prepare("SELECT * FROM uploksabha2009 WHERE ac_id_09 = ? AND booth_id_09 = ?");
    $sth->execute($constituency_id, $booth_id);
    my $found=undef;
    while (my $row=$sth->fetchrow_hashref) {
	$found=1; 
	my $i=0;
	my $updateline = 'UPDATE uploksabha2009 SET '; my @updates = ();
	foreach my $header (@realheader) {
	    if ($header eq 'ac_id_09' or $header eq 'ac_name_09' or $header eq 'ac_reserved_09' or $header eq 'booth_id_09' or $header eq 'station_name_09') {next}
	    elsif ($header eq 'electors_09') {$updateline .=  " electors_09 = ?"; push(@updates, $electors + $row->{electors_09});next}
	    elsif ($header eq 'turnout_09') {$updateline .=  " , turnout_09 = ?"; push(@updates, $turnout + $row->{turnout_09});next}
	    elsif ($header eq 'turnout_percent_09' && ($row->{electors_09} > 0 || $electors > 0)) {$updateline .=  " , turnout_percent_09 = ?"; push(@updates, int(($turnout + $row->{turnout_09})/($electors + $row->{electors_09})*10000)/100);next}
	    elsif ($header eq 'male_votes_09') {$updateline .= " , male_votes_09 = ?"; push(@updates, $male_votes + $row->{male_votes_09});next}
	    elsif ($header eq 'female_votes_09') {$updateline .= " , female_votes_09 = ?"; push(@updates, $female_votes + $row->{female_votes_09});next}
	    elsif ($header eq 'female_votes_percent_09' && ($row->{turnout_09} > 0 || $turnout > 0)) {$updateline .= ", female_votes_percent_09 = ?"; push(@updates, int(($female_votes + $row->{female_votes_09})/($turnout + $row->{turnout_09})*10000)/100);next}
	    elsif ($header !~ /percent/) {$updateline .= ", $header = ?"; push(@updates, $add[$i] + $row->{$header});}
	    elsif (($row->{turnout_09} > 0 || $turnout > 0) and ($add[$i] + $row->{$header}) > 0) {$updateline .= " , $header = ?"; push(@updates, int(($add[$i]*$turnout/100 + $row->{$header}*$row->{turnout_09}/100)/($turnout + $row->{turnout_09})*10000)/100);}
	    $i++;
	}
	$updateline .= ' WHERE ac_id_09 = ? AND booth_id_09 = ?';
	push (@updates, $row->{ac_id_09}); push(@updates, $row->{booth_id_09});
	$dbh->do ($updateline,undef,@updates);
    }

    if ($found != 1) {$dbh->do ("INSERT INTO uploksabha2009 (".join(',',@realheader).") VALUES (".join(',',('?') x scalar(@realheader)).")",undef, $constituency_id, $booth_id, $electors, $turnout, $turnout_percent, $male_voters, $female_voters, $female_voters_percent, @add);}
    
    if ($found != 1) {$dbh->do ("INSERT INTO upid (ac_id_09, ac_name_09, ac_reserved_09, booth_id_09, station_name_09) VALUES (?,?,?,?,?)",undef, $constituency_id, $constituency_name, $constituency_reserved, $booth_id, $station_name);}

}

$dbh->commit;

#
# Add station_id and station_name
#

$dbh->do ("ALTER TABLE upid ADD COLUMN station_id_09 INTEGER");

$dbh->do ("CREATE INDEX ac_id_09 ON upid (ac_id_09)");
$dbh->do ("CREATE INDEX booth_id_09 ON upid (booth_id_09)");

my $sth = $dbh->prepare("SELECT ac_id_09 FROM upid WHERE ac_id_09 IS NOT NULL GROUP BY ac_id_09");
$sth->execute();
my $count=0;
my %result;
while (my $row=$sth->fetchrow_hashref) {
    my $tempold='';
    my $sth2 = $dbh->prepare("SELECT station_name_09 FROM upid WHERE ac_id_09 = ?");
    $sth2->execute($row->{ac_id_09});
    while (my $row2=$sth2->fetchrow_hashref) {
	my $temp=$row2->{station_name_09};
	$temp=~s/\d//gs;
	next if ($temp eq $tempold);
	$tempold = $temp;
	$result{$row->{ac_id_09}.$temp}=$count;
	$count++;
    }
}
$sth->finish ();

$dbh->begin_work;

my $sth = $dbh->prepare("SELECT * FROM upid WHERE ac_id_09 IS NOT NULL");
$sth->execute();
while (my $row=$sth->fetchrow_hashref) {
    my $temp=$row->{station_name_09};
    $temp=~s/\d//gs;
    $dbh->do ("UPDATE upid SET station_id_09 = ? WHERE ac_id_09 = ? AND booth_id_09 = ?", undef, $result{$row->{ac_id_09}.$temp}, $row->{ac_id_09}, $row->{booth_id_09});
}
$sth->finish ();

$dbh->commit;

$dbh->do ("CREATE INDEX station_id_09 ON upid (station_id_09)");

#
# Finally create sqlite dump 
#

$dbh->sqlite_backup_to_file("temp.sqlite");

system("sqlite3 temp.sqlite '.dump uploksabha2009' > uploksabha2009-a.sql");
system("sqlite3 temp.sqlite '.dump upid' > uploksabha2009-b.sql");

system("rm -f temp.sqlite");

open (FILE, ">>uploksabha2009-a.sql");

print FILE ".mode csv\n";
print FILE ".headers on\n";
print FILE ".once uploksabha2009/uploksabha2009-a.csv\n";
print FILE "SELECT * FROM uploksabha2009 LIMIT 50000;\n";
print FILE ".once uploksabha2009/uploksabha2009-b.csv\n";
print FILE "SELECT * FROM uploksabha2009 LIMIT 50000 OFFSET 50000;\n";
print FILE ".once uploksabha2009/uploksabha2009-c.csv\n";
print FILE "SELECT * FROM uploksabha2009 LIMIT -1 OFFSET 100000;\n";

close (FILE);

system("split -l 40000 uploksabha2009-a.sql");
system("mv xaa uploksabha2009-a.sql");
system("echo 'COMMIT;' >> uploksabha2009-a.sql");
system("echo 'BEGIN TRANSACTION;' > uploksabha2009-b.sql");
system("cat xab >> uploksabha2009-b.sql");
system("echo 'COMMIT;' >> uploksabha2009-b.sql");
system("rm xab");
system("echo 'BEGIN TRANSACTION;' > uploksabha2009-c.sql");
system("cat xac >> uploksabha2009-c.sql");
system("rm xac");

open (FILE, "uploksabha2009-d.sql");
my @file = <FILE>;
close (FILE);

open (FILE, ">uploksabha2009-d.sql");

print FILE "ALTER TABLE upid ADD COLUMN ac_id_09 INTEGER;\n";
print FILE "ALTER TABLE upid ADD COLUMN ac_name_09 CHAR;\n";
print FILE "ALTER TABLE upid ADD COLUMN ac_reserved_09 CHAR;\n";
print FILE "ALTER TABLE upid ADD COLUMN booth_id_09 INTEGER;\n";
print FILE "ALTER TABLE upid ADD COLUMN station_name_09 CHAR;\n";
print FILE "ALTER TABLE upid ADD COLUMN station_id_09 INTEGER;\n";

my $insert;
foreach my $line (@file) {
    if ($line =~ /^CREATE TABLE upid (.*?);/) {$insert=$1;$insert=~s/ CHAR//gs; $insert=~s/ INTEGER//gs; next}
    if ($line =~ /^ALTER TABLE upid/) {next}
    if ($line =~ /^INSERT INTO \"upid\"/) {$line =~ s/^INSERT INTO \"upid\"/INSERT INTO \"upid\" $insert/}
    print FILE $line;
}

close (FILE);
