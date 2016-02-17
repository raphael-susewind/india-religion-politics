#!/usr/bin/perl

use DBD::SQLite;
use Text::CSV;
use Text::WagnerFischer 'distance';

use utf8;

$dbh = DBI->connect("DBI:SQLite:dbname=:memory:", "","", {sqlite_unicode=>1});
$dbh->sqlite_backup_from_file('actopc.sqlite');
$dbh->do ("CREATE TABLE results (pc INTEGER, ac INTEGER, booth INTEGER, candidate CHAR, votes INTEGER)");
$dbh->do ("CREATE TABLE candidates (id INTEGER PRIMARY KEY AUTOINCREMENT, pc INTEGER, rank INTEGER, name CHAR, party CHAR, shortparty CHAR)");

# first read candidate list prepared by Dilip Damle

print "Read in candidate list\n";

my $csv = Text::CSV->new();

open (CSV,"Political_parties.csv");
my @csv=<CSV>;
close (CSV);

my $header=shift(@csv);

my %party;
foreach my $line (@csv) {
    $csv->parse($line);
    my @fields=$csv->fields();
    $party{$fields[0]}=$fields[1];
}

my $csv = Text::CSV->new();

open (CSV,"Candidates.csv");
my @csv=<CSV>;
close (CSV);

my $header=shift(@csv);

foreach my $line (@csv) {
    $csv->parse($line);
    my @fields=$csv->fields();
    $fields[0] =~ /(...)PC(\d+)CA(\d+)/gs;
    my $state=$1; my $pc=$2/1; my $rank=$3/1;
    next if $state ne 'S24';
    next if $fields[1] =~ /none of the above/i;
    $dbh->do ("INSERT INTO candidates (pc,rank,name,party) VALUES (?,?,?,?)",undef,$pc,$rank,$fields[1],$party{$fields[2]});
}

# then read actual form20 results

print "Read in actual results\n";

undef(my %print); undef(my %troubleac);

$dbh->begin_work;

# iterate through PCs
for ($pc=1;$pc<=80;$pc++) {
    
    print "  PC $pc\n";
    
    $dbh->do ("INSERT INTO candidates (pc,party) VALUES (?,?)",undef,$pc,'station');
    $dbh->do ("INSERT INTO candidates (pc,party) VALUES (?,?)",undef,$pc,'electors');
    $dbh->do ("INSERT INTO candidates (pc,party) VALUES (?,?)",undef,$pc,'valid');
    $dbh->do ("INSERT INTO candidates (pc,party) VALUES (?,?)",undef,$pc,'nota');
    $dbh->do ("INSERT INTO candidates (pc,party) VALUES (?,?)",undef,$pc,'tendered');
    $dbh->do ("INSERT INTO candidates (pc,party) VALUES (?,?)",undef,$pc,'male');
    $dbh->do ("INSERT INTO candidates (pc,party) VALUES (?,?)",undef,$pc,'female');
    
    my $ref = $dbh->selectcol_arrayref("SELECT ac FROM actopc WHERE state_name = 'Uttar Pradesh' AND pc = ?",undef,$pc);

    # iterate through relevant ACs
    foreach my $ac (@$ref) {
		
	my $code=$ac;

	my $csv = Text::CSV->new({binary=>1});
	
	# read in CSV file, prepare stuff
	open (CSV,"$code.csv");
	my @csv = <CSV>;
	close (CSV);

	undef(my %cand);
	undef(my $pscol);
	my $toggle=0;
	
	# iterate through CSV file
	my $oldstationname='';
	foreach my $line (@csv) {
	    
	    if ($toggle == 0) { # filter garbage and register general names
		if ($line =~ /Polling Station/gsi) {
		    $toggle=1; 
		    $csv->parse($line);
		    my @fields=$csv->fields();
		    for ($i=0;$i<scalar(@fields);$i++) {if ($fields[$i] ne '') {if (!defined($cand{$i})) {$cand{$i}=$fields[$i]}}}
		}
	    } elsif ($toggle == 1) { # read in candidate names
		$toggle=2; 
		$csv->parse($line);
		my @fields=$csv->fields();
		if ($fields[0] =~ /\d/ and $fields[0] !~ /\D/ and $fields[0] ne '') {push (@csv,$line)}
		else {for ($i=0;$i<scalar(@fields);$i++) {if ($fields[$i] ne '') {$cand{$i}=$fields[$i]}}}		
		
		my $whichone=0; my $female=0; my $valid=0;
		key: foreach my $key (sort(keys(%cand))) {
		    $cand{$key} =~ s/\s*\(.*//gs;
		    $cand{$key} =~ s/[^A-Za-z\.\(\) ]/ /gs;
		    $cand{$key} =~ s/\s+/ /gs;
		    $cand{$key} =~ s/\s+$//gs;
		    $cand{$key} =~ s/^\s+//gs;
		    
		    $pscol=0;
		    
		    if ($cand{$key} eq 'Tendered Voter' ) {$cand{$key}='tendered'}
		    elsif ($cand{$key} =~ /None of the Above/) {$cand{$key}='nota'}
		    elsif ($cand{$key} eq 'Total No. of electors') {$cand{$key}='electors'}
		    elsif ($cand{$key} eq 'Part Name') {$cand{$key} = 'station'}
		    elsif ($cand{$key} eq 'Total Votes Secured') {$cand{$key}='valid'}
		    elsif ($cand{$key} eq 'Female' and $female==0) {$female=1;next key}
		    elsif ($cand{$key} eq 'Female') {$cand{$key}='female'}
		    elsif ($cand{$key} eq 'Male' and $female==1) {$cand{$key}='male'}
		    elsif ($key<12) {undef($cand{$key})}
		    else {
			$cand{$key} =~ s/^\d+ - //gs;
			if ($pc==1 && $cand{$key} eq 'MOHD. FIROZ AFTAB') {$cand{$key}='MOHD FIROZ AFTAB'}
			elsif ($pc==1 && $cand{$key} eq 'SHAZAN MASOOD URF SHADAN MASOOD') {$cand{$key}='SHAZAN MASOOD ALIAS SHADAN MASOOD'}
			elsif ($pc==10 && $cand{$key} eq 'DR. EX. MAJ HIMANSHU SINGH') {$cand{$key}='DR. (EX. MAJ) HIMANSHU SINGH'}
			elsif ($pc==10 && $cand{$key} eq 'MOHD. SAJID SAIFI') {$cand{$key}='MOHD SAJID SAIFI'}
			elsif ($pc==10 && $cand{$key} eq 'MOHD.SHAHID AKHLAK') {$cand{$key}='MOHD SHAHID AKHLAK'}
			elsif ($pc==10 && $cand{$key} eq 'MOHD.USMAN GHAZI') {$cand{$key}='MOHD USMAN GHAZI'}
			elsif ($pc==13 && $cand{$key} eq 'DR.MAHESH SHARMA') {$cand{$key}='DR. MAHESH SHARMA'}
			elsif ($pc==13 && $cand{$key} eq 'MOHD. SABIR ANSARI') {$cand{$key}='MOHD SABIR ANSARI'}
			elsif ($pc==14 && $cand{$key} eq 'ANJU URF MUSKAN') {$cand{$key}='ANJU ALIAS MUSKAN'}
			elsif ($pc==15 && $cand{$key} eq 'MOHD. SABIR RAHI') {$cand{$key}='MOHD SABIR RAHI'}
			elsif ($pc==17 && $cand{$key} eq 'FAKKAR BABA RAMAYANI') {$cand{$key}='FAKKAR BABA (RAMAYANI)'}
			elsif ($pc==17 && $cand{$key} eq 'HEMA MALINI') {$cand{$key}='HEMA MALINI'}
			elsif ($pc==17 && $cand{$key} eq 'PT. UDYAN SHARMA') {$cand{$key}='PT. UDYAN SHARMA (MUNNA)'}
			elsif ($pc==20 && $cand{$key} eq 'PROF. S.P. SINGH BAGHEL') {$cand{$key}='Prof. S. P. SINGH BAGHEL'}
			elsif ($pc==22 && $cand{$key} eq 'RAJVEER SINGH RAJU BHAIYA') {$cand{$key}='RAJVEER SINGH (RAJU BHAIYA)'}
			elsif ($pc==23 && $cand{$key} eq 'AKMAL KHAN URF CHAMAN') {$cand{$key}='AKMAL KHAN ALIAS CHAMAN'}
			elsif ($pc==23 && $cand{$key} eq 'SANTOSH KUMAR GUPTA SATYMARGI') {$cand{$key}='SANTOSH KUMAR GUPTA (SATYMARGI)'}
			elsif ($pc==24 && $cand{$key} eq 'CAPTAIN P.C. SHARMA') {$cand{$key}='CAPTAIN P. C. SHARMA'}
			elsif ($pc==24 && $cand{$key} eq 'MOHD. ZARRAR KHAN') {$cand{$key}='MOHD ZARRAR KHAN'}
			elsif ($pc==25 && $cand{$key} eq 'MASSARAT WARSI PAPPU BHAI') {$cand{$key}='MASSARAT WARSI (PAPPU BHAI)'}
			elsif ($pc==28 && $cand{$key} eq 'AJAY KUMAR') {$cand{$key}='AJAY'}
			elsif ($pc==29 && $cand{$key} eq 'REKHA') {$cand{$key}='REKHA Verma'}
			elsif ($pc==32 && $cand{$key} eq 'RAJESH KUMAR S O BABOORAM') {$cand{$key}='RAJESH KUMAR S/O BABOORAM'}
			elsif ($pc==32 && $cand{$key} eq 'RAJESH KUMAR S O PARMESHWAR DEEN') {$cand{$key}='RAJESH KUMAR S/O PARMESHWAR DEEN'}
			elsif ($pc==33 && $cand{$key} eq 'GIRJA SHANKAR RAJU') {$cand{$key}='GIRJA SHANKAR Alias RAJU'}
			elsif ($pc==33 && $cand{$key} eq 'SWAMI SACHCHIDANAND HARI SAKSHI') {$cand{$key}='SAKSHI Maharaj'}
			elsif ($pc==34 && $cand{$key} eq 'R.K CHAUDHARY') {$cand{$key}='R. K. CHAUDHARY'}
			elsif ($pc==35 && $cand{$key} eq 'MOHD. SARWAR MALIK') {$cand{$key}='MOHD SARWAR MALIK'}
			elsif ($pc==37 && $cand{$key} eq 'C L MAURYA') {$cand{$key}='C. L. MAURYA'}
			elsif ($pc==39 && $cand{$key} eq 'ASHOK SHUKLA SENANI') {$cand{$key}='ASHOK SHUKLA (SENANI)'}
			elsif ($pc==4 && $cand{$key} eq 'KUNWAR BHARTENDRA') {$cand{$key}='KUNWAR BHARATENDRA'}
			elsif ($pc==40 && $cand{$key} eq 'MUKESH RAJPUT') {$cand{$key}='MUKESH RAJPUT'}
			elsif ($pc==43 && $cand{$key} eq 'DR.MURLI MANOHAR JOSHI') {$cand{$key}='DR. MURLI MANOHAR JOSHI'}
			elsif ($pc==43 && $cand{$key} eq 'DR.NIKHIL GUPTA') {$cand{$key}='DR. NIKHIL GUPTA'}
			elsif ($pc==43 && $cand{$key} eq 'MOHD.NASIR KHAN') {$cand{$key}='MOHD NASIR KHAN'}
			elsif ($pc==44 && $cand{$key} eq 'DEVENDRA SINGH BHOLE SINGH') {$cand{$key}='DEVENDRA SINGH Alias BHOLE SINGH'}
			elsif ($pc==46 && $cand{$key} eq 'PRADEEP JAIN ADITYA') {$cand{$key}='PRADEEP JAIN (ADITYA)'}
			elsif ($pc==46 && $cand{$key} eq 'RAM KUMAR ANK SHASTRI') {$cand{$key}='RAM KUMAR (ANK SHASTRI)'}
			elsif ($pc==47 && $cand{$key} eq 'KUNWAR PUSHPENDRA SINGH CHANDEL') {$cand{$key}='KUNWAR CHANDEL PUSHPENDRA SINGH'}
			elsif ($pc==47 && $cand{$key} eq 'PRITAM SINGH LODHI') {$cand{$key}='PRITAM SINGH LODHI (KISAAN)'}
			elsif ($pc==5 && $cand{$key} eq 'YASHWANT SINGH') {$cand{$key}='Dr. YASHWANT SINGH'}
			elsif ($pc==51 && $cand{$key} eq 'GYANENDRA KUMAR SRIVASTAVA GYANI BHAI') {$cand{$key}='GYANENDRA KUMAR SRIVASTAVA (GYANI BHAI)'}
			elsif ($pc==51 && $cand{$key} eq 'MOHD. KAIF') {$cand{$key}='MOHD KAIF'}
			elsif ($pc==52 && $cand{$key} eq 'CHANDRA PRAKASH TIWARI ALIAS C. P. TIWARI ADVOCATE') {$cand{$key}='CHANDRA PRAKASH TIWARI ALIAS C. P. TIWARI (ADVOCATE)'}
			elsif ($pc==52 && $cand{$key} eq 'MOHD. AMEEN AZHAR ANSARI') {$cand{$key}='MOHD AMEEN AZHAR ANSARI'}
			elsif ($pc==54 && $cand{$key} eq 'JITENDRA KUMAR SINGH BABLU BHAIYA') {$cand{$key}='JITENDRA KUMAR SINGH (BABLU BHAIYA)'}
			elsif ($pc==55 && $cand{$key} eq 'JAHAR SINGH KASHYAP') {$cand{$key}='J. S. KASHYAP(JAHAR SINGH KASHYAP)'}
			elsif ($pc==56 && $cand{$key} eq 'COMANDO KAMAL KISHOR') {$cand{$key}='(COMANDO) KAMAL KISHOR'}
			elsif ($pc==56 && $cand{$key} eq 'DR.VIJAY KUMAR') {$cand{$key}='DR. VIJAY KUMAR'}
			elsif ($pc==58 && $cand{$key} eq 'VINAY KUMAR PANDEY') {$cand{$key}='VINAY KUMAR PANDEY (VINNU)'}
			elsif ($pc==6 && $cand{$key} eq 'BEGUM NOOR BANO URF MEHTAB') {$cand{$key}='BEGUM NOOR BANO ALIAS MEHTAB'}
			elsif ($pc==6 && $cand{$key} eq 'DR S T HASAN') {$cand{$key}='DR S. T. HASAN'}
			elsif ($pc==60 && $cand{$key} eq 'DR. MOHD. AYUB') {$cand{$key}='DR. MOHD AYUB'}
			elsif ($pc==60 && $cand{$key} eq 'MUKESH NARAYAN SHUKLA URF GYANESH NARAYAN SHUKLA') {$cand{$key}='MUKESH NARAYAN SHUKLA ALIAS GYANESH NARAYAN SHUKLA'}
			elsif ($pc==61 && $cand{$key} eq 'BRIJ KISHOR SINGH') {$cand{$key}='BRIJ KISHOR SINGH (DIMPAL)'}
			elsif ($pc==61 && $cand{$key} eq 'RAM KARAN ALIAS R.K. GAUTAM') {$cand{$key}='RAM KARAN ALIAS R. K. GAUTAM'}
			elsif ($pc==62 && $cand{$key} eq 'LOTAN URF LAUTAN PRASAD') {$cand{$key}='LOTAN ALIAS LAUTAN PRASAD'}
			elsif ($pc==64 && $cand{$key} eq 'MOHD. WASEEM KHAN') {$cand{$key}='MOHD WASEEM KHAN'}
			elsif ($pc==65 && $cand{$key} eq 'RAJESH PANDEY URF GUDDU') {$cand{$key}='RAJESH PANDEY ALIAS GUDDU'}
			elsif ($pc==71 && $cand{$key} eq 'DR.BHOLA PANDEY') {$cand{$key}='DR. BHOLA PANDEY'}
			elsif ($pc==71 && $cand{$key} eq 'RAVI SHANKER SINGH') {$cand{$key}='RAVI SHANKER SINGH (PAPPU)'}
			elsif ($pc==72 && $cand{$key} eq 'COL RETD. BHARAT SINGH SHAURYA CHAKRA') {$cand{$key}='COL(RETD) BHARAT SINGH SHAURYA CHAKRA'}
			elsif ($pc==73 && $cand{$key} eq 'KRISHNA PRATAP') {$cand{$key}='KRISHNA PRATAP (K. P.)'}
			elsif ($pc==74 && $cand{$key} eq 'BHOLANATH ALIAS B.P. SAROJ') {$cand{$key}='BHOLANATH ALIAS B. P. SAROJ'}
			elsif ($pc==75 && $cand{$key} eq 'DHARM YADAV') {$cand{$key}='DHARM YADAV ALIAS D. P. YADAV'}
			elsif ($pc==76 && $cand{$key} eq 'DR MAHENDRA NATH PANDEY') {$cand{$key}='DR. MAHENDRA NATH PANDEY'}
			elsif ($pc==76 && $cand{$key} eq 'TARUN PATEL URF TARUNENDRA CHAND PATEL') {$cand{$key}='TARUN PATEL ALIAS TARUNENDRA CHAND PATEL'}
			elsif ($pc==77 && $cand{$key} eq 'A.K. AGGARWAL') {$cand{$key}='A. K. AGGARWAL'}
			elsif ($pc==77 && $cand{$key} eq 'RAJENDRA PRASAD GARIB DAS') {$cand{$key}='RAJENDRA PRASAD (GARIB DAS)'}
			elsif ($pc==79 && $cand{$key} eq 'GIRJA SHANKAR URF CHUNMUN') {$cand{$key}='GIRJA SHANKAR ALIAS CHUNMUN'}
			elsif ($pc==79 && $cand{$key} eq 'SUKCHARA NAND URF AALOO BABA') {$cand{$key}='SUKCHARA NAND ALIAS AALOO BABA'}
			elsif ($pc==8 && $cand{$key} eq 'AQEEL UR REHMAN KHAN') {$cand{$key}='AQEEL-UR -REHMAN KHAN'}
			elsif ($pc==8 && $cand{$key} eq 'DHARAM YADAV') {$cand{$key}='DHARAM YADAV ALIAS D. P. YADAV'}
			elsif ($pc==8 && $cand{$key} eq 'DR SHAFIQ UR RAHMAN BARQ') {$cand{$key}='DR SHAFIQ- UR RAHMAN BARQ'}
			elsif ($pc==8 && $cand{$key} eq 'MOHD ASLAM URF PASHA') {$cand{$key}='MOHD ASLAM ALIAS PASHA'}
			elsif ($pc==80 && $cand{$key} eq 'ARUN SINGH CHERO') {$cand{$key}='ARUN SINGH(CHERO)'}
			elsif ($pc==80 && $cand{$key} eq 'GUN DEVI GYANI DEVI') {$cand{$key}='GUN DEVI (. GYANI DEVI)'}
			
			# check if candidate remains unknown
			my $re2f = $dbh->selectcol_arrayref("SELECT id FROM candidates WHERE pc = ? AND name LIKE ?",undef,$pc,$cand{$key});
			if (scalar(@$re2f) == 2) {$cand{$key}=$$re2f[$whichone];$whichone++;}
			elsif (scalar(@$re2f) != 1) {$print{'elsif ($pc=='.$pc.' && $cand{$key} eq \''.$cand{$key}.'\') {$cand{$key}=\''."'} # in AC $ac\n"}++;  $troubleac{$ac}=1; undef($cand{$key}); next key;}
			$cand{$key}=$$re2f[0];
		    }
		}
	    } else { # read in results
		$csv->parse($line);
		my @fields=$csv->fields();
		
		$fields[$pscol]=~s/^(\d+)*/$1/gs;
		
		my $booth = $fields[$pscol]/1;
		undef(my $total); undef(my $control);
		for ($i=0;$i<scalar(@fields);$i++) {
		    if ($fields[$i] =~ /\d/) {
			next if !defined($cand{$i});
#			$fields[$i] =~ s/\D//gs;
			if ($cand{$i} eq 'total') {$total=$fields[$i]} 
			elsif ($cand{$i} eq 'valid' or $cand{$i} eq 'tendered') {}
			elsif ($cand{$i} eq 'station') {
			    $fields[$i] =~ s/[1-9]//gs; # this is to enable easier integration later on - we are interested in station_name, not booth_name
			    $fields[$i] =~ s/^\d//gs;
			    # remove identical substrings of words - to fetch at least some of the cases where this happens...
			    $fields[$i] =~s/^(.+) (.*) \1 /$1 $2 /gsi;
			    $fields[$i] =~s/ (.+) (.*) \1$/ $1 $2/gsi;
			    $fields[$i] =~s/^(.+) (.*) \1$/$1 $2/gsi;
			    $fields[$i] =~s/ (.+) (.*) \1 / $1 $2 /gsi;
			    $fields[$i] =~s/ (.+) (.*) \1 / $1 $2 /gsi;
			    $fields[$i] =~s/^(.+) \1 /$1 /gsi;
			    $fields[$i] =~s/ (.+) \1$/ $1/gsi;
			    $fields[$i] =~s/^(.+) \1$/$1/gsi;
			    $fields[$i] =~s/ (.+) \1 / $1 /gsi;
			    $fields[$i] =~s/ (.+) \1 / $1 /gsi;
			    
			    $fields[$i] =~ s/^izk[ \-]ik[ \-]\]*/izk ik/gs; # unify "primary school"
			    $fields[$i] =~ s/^izk[ \-]fo[ \-]\]*/izk ik/gs;
			    $fields[$i] =~ s/^izkfo\|ky\;/izk ik/gs;
			    $fields[$i] =~ s/^izkikB\'kkyk/izk ik/gs;
			    $fields[$i] =~ s/^izk\s*ikB\'kkyk/izk ik/gs;
			    $fields[$i] =~ s/^izk\s*fo\|ky\;/izk ik/gs;
			    
			    my $temp = distance($oldstationname,$fields[$i]);
			    if ($temp <= 1 || $temp < length($fields[$i])/7.5) {$fields[$i] = $oldstationname} else {$oldstationname = $fields[$i]}
			    
			}
			else {$control=$control+$fields[$i]}
			$dbh->do("INSERT INTO results VALUES (?,?,?,?,?)",undef,$pc,$ac,$booth,$cand{$i},$fields[$i]);
		    }
		}
		# check if vote counts add up
#		if ($total != $control) {$print{"Vote count mismatch in AC $ac, booth ".$fields[$pscol].": votes add up to $control, but total column says $total!\n"}++;  $troubleac{$ac}=1; }
	    }
	    
	}
	
	# check if AC has all relevant candidates!
	if (defined($pscol)) {
	    my $re2f = $dbh->selectcol_arrayref("select name from candidates where id not in (select candidate from results where ac=? group by candidate) and pc=? and name is not null",undef,$ac,$pc);
	    foreach my $candidate (@$re2f) {$print{"Missing candidate $candidate from AC $ac!\n"}++; $troubleac{$ac}=1;}
	# TODO implement boothcount check, using GIS data as reference
	} else {
	    $print{"Empty file for AC $ac!\n"}=1; # $troubleac{$ac}=1;
	}
	    
    }
    
}

$dbh->commit;

# print diagnostics
foreach my $key (sort(keys(%print))) {print $key}
# foreach my $key (sort {$a <=> $b} (keys(%troubleac))) {print "Troubling AC: ".$key."\n"}

# Finally calculate the actual upid / ukloksabha2014 table

print "Calculate upid table\n";

$dbh->do ("CREATE TABLE upid (ac_id_09 INTEGER)");

$dbh->do ("CREATE TABLE uploksabha2014 (id INTEGER PRIMARY KEY)");

my @idheader;
my @idselect;

push(@idheader,'ac_id_09');
push(@idselect,'results.ac');
$dbh->do ("ALTER TABLE upid ADD COLUMN ac_name_14 CHAR");
push(@idheader,'ac_name_14');
push(@idselect,'actopc.ac_name');
$dbh->do ("ALTER TABLE upid ADD COLUMN ac_reserved_14 CHAR");
push(@idheader,'ac_reserved_14');
push(@idselect,'actopc.ac_reserved');
$dbh->do ("ALTER TABLE upid ADD COLUMN booth_id_14 INTEGER");
push(@idheader,'booth_id_14');
push(@idselect,'results.booth');
$dbh->do ("ALTER TABLE upid ADD COLUMN station_name_14 CHAR");
push(@idheader,'station_name_14');
push(@idselect,'case when results.candidate = "station" then results.votes end');

my $idsql = 'INSERT INTO upid ('.join(",",@idheader).') SELECT '.join(",",@idselect).' FROM results LEFT JOIN actopc ON results.ac = actopc.ac GROUP BY results.ac,results.booth';

$dbh->begin_work;
$dbh->do($idsql);
$dbh->commit;

print "Calculate uploksabha2014 table\n";

my @realheader;
my @realselect;

$dbh->do ("ALTER TABLE uploksabha2014 ADD COLUMN ac_id_09 INTEGER");
push(@realheader,'ac_id_09');
push(@realselect,'results.ac');
$dbh->do ("ALTER TABLE uploksabha2014 ADD COLUMN booth_id_14 INTEGER");
push(@realheader,'booth_id_14');
push(@realselect,'results.booth');
$dbh->do ("ALTER TABLE uploksabha2014 ADD COLUMN electors_14 INTEGER");
push(@realheader,'electors_14');
push(@realselect,'sum(case when results.candidate = "electors" then results.votes end)');
$dbh->do ("ALTER TABLE uploksabha2014 ADD COLUMN turnout_14 INTEGER");
push(@realheader,'turnout_14');
push(@realselect,'sum(case when results.candidate = "valid" then results.votes end)');
$dbh->do ("ALTER TABLE uploksabha2014 ADD COLUMN nota_14 INTEGER");
push(@realheader,'nota_14');
push(@realselect,'sum(case when results.candidate = "nota" then results.votes end)');
$dbh->do ("ALTER TABLE uploksabha2014 ADD COLUMN tendered_14 INTEGER");
push(@realheader,'tendered_14');
push(@realselect,'sum(case when results.candidate = "tendered" then results.votes end)');
$dbh->do ("ALTER TABLE uploksabha2014 ADD COLUMN male_votes_14 INTEGER");
push(@realheader,'male_votes_14');
push(@realselect,'sum(case when results.candidate = "male" then results.votes end)');
$dbh->do ("ALTER TABLE uploksabha2014 ADD COLUMN female_votes_14 INTEGER");
push(@realheader,'female_votes_14');
push(@realselect,'sum(case when results.candidate = "female" then results.votes end)');

my $ref = $dbh->selectcol_arrayref("SELECT party FROM candidates WHERE name IS NOT NULL GROUP BY party");

foreach my $party (@$ref) {
    my $oldparty = $party;
    $party =~ s/\.//gs;
    $party =~ s/\,//gs;
    $party =~ s/\)//gs;
    $party =~ s/\(/-/gs;
    $party =~ s/\s//gs;
    $party = lc($party);
    if ($party eq 'indep') {$party = 'ind'}
    if ($party eq 'indipendent') {$party = 'ind'}
    if ($party eq 'indp') {$party = 'ind'}
    if ($party eq 'indpendent') {$party = 'ind'}
    if ($party eq 'indpt') {$party = 'ind'}
    if ($party eq 'indt') {$party = 'ind'}
    if ($party eq 'independent') {$party = 'ind'}
    if ($party eq 'nir') {$party = 'ind'}
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
    if ($party eq 'adarsadarshrashtriyavikasparty') {$party = 'arvp'}
    if ($party eq 'adarshrashtriyavikasdal') {$party = 'arvd'}
    if ($party eq 'adarshrashtriyavikashparty') {$party = 'arvp'}
    if ($party eq 'adarshrashtriyavikasparty') {$party = 'arvp'}
    if ($party eq 'adarshsamajparty') {$party = 'asp'}
    if ($party eq 'addal') {$party = 'add'}
    if ($party eq 'ait-c') {$party = 'aitc'}
    if ($party eq 'akhilbharathindumahasabha') {$party = 'abhm'}
    if ($party eq 'akhilbharatiyadeshbhaktmorcha') {$party = 'abdbm'}
    if ($party eq 'akhilbhartiyaloktantrikcongress') {$party = 'abltc'}
    if ($party eq 'al-hindparty') {$party = 'ahp'}
    if ($party eq 'allindiaforwardblock') {$party = 'aifb'}
    if ($party eq 'allindiaminoritiesfront') {$party = 'aimf'}
    if ($party eq 'allindiantrinamoolcongress') {$party = 'aitc'}
    if ($party eq 'allindiatranmoolcongress') {$party = 'aitc'}
    if ($party eq 'allindiatrinamoolcogress') {$party = 'aitc'}
    if ($party eq 'allindiatrinamoolcongress') {$party = 'aitc'}
    if ($party eq 'allindiatrinmoolcongress') {$party = 'aitc'}
    if ($party eq 'ambedakarsamajparty') {$party = 'asp'}
    if ($party eq 'ambedkarnationalcongress') {$party = 'anc'}
    if ($party eq 'ambedkarsamajparty') {$party = 'asp'}
    if ($party eq 'ambedkarsamajpatry') {$party = 'asp'}
    if ($party eq 'apanadal') {$party = 'ad'}
    if ($party eq 'asankhyasamajparty') {$party = 'assp'}
    if ($party eq 'bahujansagharshparty-kanshiram') {$party = 'bsp-k'}
    if ($party eq 'bahujansamajparty-ambedkar') {$party = 'bsp-a'}
    if ($party eq 'bahujansangharshparty-kanshiram') {$party = 'bsp-k'}
    if ($party eq 'bahujanshakti') {$party = 'bs'}
    if ($party eq 'bharatiyaeklavyaparty') {$party = 'bep'}
    if ($party eq 'bharatiyajanataparty') {$party = 'bjp'}
    if ($party eq 'bharatiyajanberojgarchhatradal') {$party = 'bjbgd'}
    if ($party eq 'bharatiyajantaparty') {$party = 'bjp'}
    if ($party eq 'bharatiyakrishakdal') {$party = 'bkd'}
    if ($party eq 'bharatiyaprajatantranirmanparty') {$party = 'bptnp'}
    if ($party eq 'bharatiyarashtriyabahujansamajvikasparty') {$party = 'bsbsvp'}
    if ($party eq 'bharatiyarepublicanpaksh') {$party = 'brp'}
    if ($party eq 'bharatiyarepublicanpaksha') {$party = 'brp'}
    if ($party eq 'bharatiyasamajdal') {$party = 'bsd'}
    if ($party eq 'bhartiyabanchitsamajparty') {$party = 'bbsp'}
    if ($party eq 'bhartiyajanataparty') {$party = 'bjp'}
    if ($party eq 'bhartiyakrishakdal') {$party = 'bkd'}
    if ($party eq 'bhartiyaprajatantranirmanparty') {$party = 'bptnp'}
    if ($party eq 'bhartiyarashtriyamorcha') {$party = 'brm'}
    if ($party eq 'bhartiyarepublicanpaksha') {$party = 'brp'}
    if ($party eq 'bhartiyasamajikkrantidal') {$party = 'bskd'}
    if ($party eq 'bhartiyasarvodayakrantiparty') {$party = 'bskd'}
    if ($party eq 'bhartiyasarvodaykrantiparty') {$party = 'bskd'}
    if ($party eq 'bhartiyasubhashsena') {$party = 'bss'}
    if ($party eq 'bhartiyavanchitsamajparty') {$party = 'bvsp'}
    if ($party eq 'bhartiyavidasparty') {$party = 'bvp'}
    if ($party eq 'bhartiyjanataparty') {$party = 'bjp'}
    if ($party eq 'bhartiyjantaparty') {$party = 'bjp'}
    if ($party eq 'brajvikasparty') {$party = 'bravp'}
    if ($party eq 'bsp-kanshiram') {$party = 'bsp-k'}
    if ($party eq 'buladelkhandcongress') {$party = 'bkc'}
    if ($party eq 'bundelkhandcongress') {$party = 'bkc'}
    if ($party eq 'bunndelkhandcongress') {$party = 'bkc'}
    if ($party eq 'communistpartyofindia') {$party = 'cpi'}
    if ($party eq 'communistpartyofindia-marxist') {$party = 'cpi-m'}
    if ($party eq 'communistpartyofindia-marxist-leninist-liberation') {$party = 'cpi-mll'}
    if ($party eq 'communistpartyofindia-marxistleninist-libration') {$party = 'cpi-mll'}
    if ($party eq 'congress') {$party = 'inc'}
    if ($party eq 'cpi-m-l') {$party = 'cpi-ml'}
    if ($party eq 'cpi-m-l-l') {$party = 'cpi-mll'}
    if ($party eq 'cpimll') {$party = 'cpi-mll'}
    if ($party eq 'cpm') {$party = 'cpi-m'}
    if ($party eq 'dalitsamajparty') {$party = 'dsp'}
    if ($party eq 'eklavyasamajparty') {$party = 'esp'}
    if ($party eq 'gareebsamanaparty') {$party = 'gsp'}
    if ($party eq 'indiajusticeparty') {$party = 'ijp'}
    if ($party eq 'indiancongressparty') {$party = 'inc'}
    if ($party eq 'indianjusticeparty') {$party = 'ijp'}
    if ($party eq 'indiannationalcongress') {$party = 'inc'}
    if ($party eq 'indiannationalistcongress') {$party = 'inc'}
    if ($party eq 'indiannationalleague') {$party = 'inl'}
    if ($party eq 'indiannationlcongress') {$party = 'inc'}
    if ($party eq 'indianoceanicparty') {$party = 'iop'}
    if ($party eq 'inqalabvikasdal') {$party = 'ivs'}
    if ($party eq 'ittehad-e-millattcouncil') {$party = 'iemc'}
    if ($party eq 'ittehademillatcouncil') {$party = 'iemc'}
    if ($party eq 'jagratbharatparty') {$party = 'jbp'}
    if ($party eq 'jaimahabharatparty') {$party = 'jmbp'}
    if ($party eq 'jammu&kashmirnationalpanthersparty') {$party = 'jknpp'}
    if ($party eq 'jan-krantiparty-rashtrawadi') {$party = 'jkp-r'}
    if ($party eq 'janatadal-u') {$party = 'jd-u'}
    if ($party eq 'janatadal-united') {$party = 'jd-u'}
    if ($party eq 'janatadalunited') {$party = 'jd-u'}
    if ($party eq 'janatavikasmanch') {$party = 'jvm'}
    if ($party eq 'jankarantiparty') {$party = 'jkp'}
    if ($party eq 'jankarantiparty-rashtrawadi') {$party = 'jkp-r'}
    if ($party eq 'jankrantiparty') {$party = 'jkp'}
    if ($party eq 'jankrantiparty-nationalist') {$party = 'jkp-n'}
    if ($party eq 'jankrantiparty-rashtravadi') {$party = 'jkp-r'}
    if ($party eq 'jankrantiparty-rashtrawadi') {$party = 'jkp-r'}
    if ($party eq 'jankrantiparty-rastravadi') {$party = 'jkp-r'}
    if ($party eq 'jankrantiparty-rastrawadi') {$party = 'jkp-r'}
    if ($party eq 'jankrantiparty-rastrawady') {$party = 'jkp-r'}
    if ($party eq 'jankrantipartyrashtrawadi') {$party = 'jkp-r'}
    if ($party eq 'jankrantipartyrastrawadi') {$party = 'jkp-r'}
    if ($party eq 'jansanghparty') {$party = 'jsp'}
    if ($party eq 'jantadal-secular') {$party = 'jd-s'}
    if ($party eq 'jantadal-united') {$party = 'jd-u'}
    if ($party eq 'jantadalsecular') {$party = 'jd-s'}
    if ($party eq 'jantadalunited') {$party = 'jd-u'}
    if ($party eq 'janvadiparty-socialist') {$party = 'jvp-s'}
    if ($party eq 'janvadiparty-sociolist') {$party = 'jvp-s'}
    if ($party eq 'janvadipartyofindia-socialist') {$party = 'jvp-s'}
    if ($party eq 'janwadiparty-socialist') {$party = 'jvp-s'}
    if ($party eq 'javankisanmorcha') {$party = 'jkm'}
    if ($party eq 'jawankisanmorcha') {$party = 'jkm'}
    if ($party eq 'jharkhandmuktimorcha') {$party = 'jkmm'}
    if ($party eq 'jd-uni') {$party = 'jd-u'}
    if ($party eq 'jd-united') {$party = 'jd-u'}
    if ($party eq 'jdu') {$party = 'jd-u'}
    if ($party eq 'jkp®') {$party = 'jkp-r'}
    if ($party eq 'jkp¼r½') {$party = 'jkp-r'}
    if ($party eq 'jnd') {$party = 'jd'}
    if ($party eq 'jp[r]') {$party = 'jp-r'}
    if ($party eq 'jpr') {$party = 'jp-r'}
    if ($party eq 'jps') {$party = 'jp-s'}
    if ($party eq 'jp®') {$party = 'jp-r'}
    if ($party eq 'jwaladal') {$party = 'jwd'}
    if ($party eq 'kisansena') {$party = 'ks'}
    if ($party eq 'kis') {$party = 'ks'}
    if ($party eq 'kpimll') {$party = 'cpi-mll'}
    if ($party eq 'krantikarisamataparty') {$party = 'kksp'}
    if ($party eq 'krantikarisamtaparty') {$party = 'kksp'}
    if ($party eq 'labourpartyofindia-vvprasad') {$party = 'lpi-vvp'}
    if ($party eq 'lokjansaktiparty') {$party = 'ljsp'}
    if ($party eq 'lokjanshaktiparty') {$party = 'ljsp'}
    if ($party eq 'lokjanshkatiparty') {$party = 'ljsp'}
    if ($party eq 'loknirmanparty') {$party = 'lnp'}
    if ($party eq 'lokpriyasamajparty') {$party = 'lpsp'}
    if ($party eq 'lokpriysamajparty') {$party = 'lpsp'}
    if ($party eq 'mahandal') {$party = 'md'}
    if ($party eq 'manavadhikarjanshaktiparty') {$party = 'majsp'}
    if ($party eq 'manavtawadisamajparti') {$party = 'masp'}
    if ($party eq 'manavtawadisamajparty') {$party = 'masp'}
    if ($party eq 'maulikadhikarparty') {$party = 'map'}
    if ($party eq 'meydhaaparty') {$party = 'mdp'}
    if ($party eq 'mominconference') {$party = 'mmc'}
    if ($party eq 'mostbackwardclassesofindia') {$party = 'mbci'}
    if ($party eq 'muslimmajlisuttarpradesh') {$party = 'mmup'}
    if ($party eq 'naitikparty') {$party = 'naitikp'}
    if ($party eq 'nakibharatiyaekataparty') {$party = 'nbep'}
    if ($party eq 'nakibharatiyaektaparty') {$party = 'nbep'}
    if ($party eq 'nakibhartiyaeaktaparty') {$party = 'nbep'}
    if ($party eq 'nakibhartiyaektaparty') {$party = 'nbep'}
    if ($party eq 'nationalbackwardparty') {$party = 'nbp'}
    if ($party eq 'nationalcongressparty') {$party = 'ncp'}
    if ($party eq 'nationalistcongressparty') {$party = 'ncp'}
    if ($party eq 'nationalistloktantrikparty') {$party = 'nltp'}
    if ($party eq 'nationalloktantrikparty') {$party = 'nltp'}
    if ($party eq 'parivartandal') {$party = 'pvd'}
    if ($party eq 'parivartansamajparty') {$party = 'pvsp'}
    if ($party eq 'peaceparty') {$party = 'pp'}
    if ($party eq 'pragatisheelmanavsamajparty') {$party = 'psmsp'}
    if ($party eq 'pragitisheelmanavsamajparty') {$party = 'psmsp'}
    if ($party eq 'prajatantrikbahujanshaktidal') {$party = 'prbd'}
    if ($party eq 'progressivedemocraticparty') {$party = 'pdp'}
    if ($party eq 'qaumiektadal') {$party = 'qed'}
    if ($party eq 'quamiektadal') {$party = 'qed'}
    if ($party eq 'rahtriyasmamantadal') {$party = 'rsd'}
    if ($party eq 'rajlokparty') {$party = 'rlp'}
    if ($party eq 'rashtraloknirmanparty') {$party = 'rlnp'}
    if ($party eq 'rashtranirmanparty') {$party = 'rnp'}
    if ($party eq 'rashtravadicommunistparty') {$party = 'rcp'}
    if ($party eq 'rashtrawadilabourparty') {$party = 'rlp'}
    if ($party eq 'rashtraylokmanch') {$party = 'rlm'}
    if ($party eq 'rashtriyaambedkardal') {$party = 'rad'}
    if ($party eq 'rashtriyaapnadal') {$party = 'rapd'}
    if ($party eq 'rashtriyabackwardparty') {$party = 'rbp'}
    if ($party eq 'rashtriyabahujanhitayparty') {$party = 'rbhp'}
    if ($party eq 'rashtriyagondwanaparty') {$party = 'rgp'}
    if ($party eq 'rashtriyainsafparty') {$party = 'rip'}
    if ($party eq 'rashtriyajansewakparty') {$party = 'rjsp'}
    if ($party eq 'rashtriyajanvadiparty-krantikari') {$party = 'rjvp-k'}
    if ($party eq 'rashtriyajanwadiparty-krantikari') {$party = 'rjvp-k'}
    if ($party eq 'rashtriyakrantikarisamajwadiparty') {$party = 'rksp'}
    if ($party eq 'rashtriyalokdal') {$party = 'rld'}
    if ($party eq 'rashtriyalokmanch') {$party = 'rlm'}
    if ($party eq 'rashtriyalokmanchparty') {$party = 'rlm'}
    if ($party eq 'rashtriyaloknirmanparty') {$party = 'rlnp'}
    if ($party eq 'rashtriyamahandal') {$party = 'rmd'}
    if ($party eq 'rashtriyamahangantantraparty') {$party = 'rmgtp'}
    if ($party eq 'rashtriyamanavsammanparty') {$party = 'rmsp'}
    if ($party eq 'rashtriyaparivartandal') {$party = 'rpd'}
    if ($party eq 'rashtriyasamantadal') {$party = 'rsd'}
    if ($party eq 'rashtriyaswabhimaanparty') {$party = 'rswp'}
    if ($party eq 'rashtriyaswabhimanparty') {$party = 'rswp'}
    if ($party eq 'rashtriyaulamaamacouncil') {$party = 'ruc'}
    if ($party eq 'rashtriyaulamacouncil') {$party = 'ruc'}
    if ($party eq 'rashtriyaulamadal') {$party = 'rud'}
    if ($party eq 'rashtriyaulemacouncil') {$party = 'ruc'}
    if ($party eq 'rashtriyaviklangparty') {$party = 'rvlp'}
    if ($party eq 'rashtriyjanwadiparty-krantikari') {$party = 'rjp-k'}
    if ($party eq 'rastriyagondawanaparty') {$party = 'rgp'}
    if ($party eq 'rastriyajan-tantrapaksh') {$party = 'rjtp'}
    if ($party eq 'rastriyakrantikarisamajwadiparty') {$party = 'rkksp'}
    if ($party eq 'rastriyalikmanch') {$party = 'rlm'}
    if ($party eq 'rastriyalokmanch') {$party = 'rlm'}
    if ($party eq 'rastriyaloknirmanparty') {$party = 'rlnp'}
    if ($party eq 'rastriyamahandal') {$party = 'rmd'}
    if ($party eq 'rastriyamahangantantraparty') {$party = 'rmgtp'}
    if ($party eq 'rastriyaparivartandal') {$party = 'rpd'}
    if ($party eq 'rastriyaprivartandal') {$party = 'rpd'}
    if ($party eq 'rastriyasamanatadal') {$party = 'rsd'}
    if ($party eq 'rastriyasuryaprakashparty') {$party = 'rspp'}
    if ($party eq 'rastriyaviklangparty') {$party = 'rvlp'}
    if ($party eq 'ravidasparty') {$party = 'rp'}
    if ($party eq 'republicanpartyofindia-a') {$party = 'rpi-a'}
    if ($party eq 'republicanpartyofindiaa') {$party = 'rpi-a'}
    if ($party eq 'republicnpartyofindia') {$party = 'rpi'}
    if ($party eq 'repubnlicanpartyofindia-democratic') {$party = 'rpi-d'}
    if ($party eq 'rlokmanch') {$party = 'rlm'}
    if ($party eq 'samajawadiparty') {$party = 'sp'}
    if ($party eq 'samajvadiparty') {$party = 'sp'}
    if ($party eq 'samajwadijanataparty-rashtriya') {$party = 'sjp-r'}
    if ($party eq 'samajwadijanataparty-rastriya') {$party = 'sjp-r'}
    if ($party eq 'samajwadijanparishad') {$party = 'sjp'}
    if ($party eq 'samastbharatiyaparty') {$party = 'sbp'}
    if ($party eq 'samastbhartiyaparty') {$party = 'sbp'}
    if ($party eq 'samtasamajwadicongressparty') {$party = 'sscp'}
    if ($party eq 'sarwajanmahasabha') {$party = 'sms'}
    if ($party eq 'sdpoi') {$party = 'sdpi'}
    if ($party eq 'shoshitsamajdal') {$party = 'ssd'}
    if ($party eq 'shositsamajdal') {$party = 'ssd'}
    if ($party eq 'smajwadiparty') {$party = 'sp'}
    if ($party eq 'socialdemocraticpartyofindia') {$party = 'sdpi'}
    if ($party eq 'socialistparty-india') {$party = 'spi'}
    if ($party eq 'socialistpartyindia') {$party = 'spi'}
    if ($party eq 'socialistunitycenterofindia-communist') {$party = 'suci-c'}
    if ($party eq 'socialistunitycentreofindia-communist') {$party = 'suci-c'}
    if ($party eq 'sociolistpartyindia') {$party = 'spi'}
    if ($party eq 'socp-i') {$party = 'spi'}
    if ($party eq 'sp-i') {$party = 'spi'}
    if ($party eq 'suheildevbhartiyasamajparty') {$party = 'sdbsp'}
    if ($party eq 'suheldeobhartiyasamajparty') {$party = 'sdbsp'}
    if ($party eq 'suheldevbharatiyasamajparty') {$party = 'sdbsp'}
    if ($party eq 'suheldevbhartiyasamajparty') {$party = 'sdbsp'}
    if ($party eq 'swarahtrajanparty') {$party = 'swtp'}
    if ($party eq 'swarajdal') {$party = 'swd'}
    if ($party eq 'swarajparty-scbosh') {$party = 'swp-scb'}
    if ($party eq 'vanchitjamatparty') {$party = 'vjp'}
    if ($party eq 'vanchitsamaj') {$party = 'vs'}
    if ($party eq 'vanchitsamajinsaafparty') {$party = 'vsip'}
    if ($party eq 'vanchitsamajinsafparty') {$party = 'vsip'}
    if ($party eq 'yuvavikashparty') {$party = 'ysp'}
    if ($party eq 'yuvavikasparty') {$party = 'yvp'}
    if ($party eq '') {print "$party\n"}
    
    $party=~s/-/_/gs;
    my $statement="ALTER TABLE uploksabha2014 ADD COLUMN votes_".$party."_14 INTEGER";
    $dbh->do ($statement);
    push(@realheader,'votes_'.$party.'_14');
    push(@realselect,'sum(case when candidates.shortparty = "'.$party.'" then results.votes end)');
    my $statement="ALTER TABLE uploksabha2014 ADD COLUMN votes_".$party."_percent_14 FLOAT";
    $dbh->do ($statement);
    push(@realheader,'votes_'.$party.'_percent_14');
    push(@realselect,'sum(case when candidates.shortparty = "'.$party.'" then cast(results.votes as float) end) / sum(case when results.candidate = "valid" then cast(results.votes as float) end)');
    
    $dbh->do("UPDATE candidates SET shortparty = ? WHERE party = ?",undef,$party,$oldparty);
}

my $realsql = 'INSERT INTO uploksabha2014 ('.join(",",@realheader).') SELECT '.join(",",@realselect).' FROM results left join candidates on results.candidate=candidates.id GROUP BY results.ac,results.booth';

$dbh->begin_work;
$dbh->do($realsql);
$dbh->commit;

$dbh->do ("ALTER TABLE uploksabha2014 ADD COLUMN turnout_percent_14 FLOAT");
$dbh->do ("UPDATE uploksabha2014 SET turnout_percent_14 = turnout_14 / electors_14");
$dbh->do ("ALTER TABLE uploksabha2014 ADD COLUMN female_votes_percent_14 FLOAT");
$dbh->do ("UPDATE uploksabha2014 SET female_votes_percent_14 = female_votes_14 / turnout_14");

#
# Add station_id
#

print "Add station_id_14\n";

$dbh->do ("ALTER TABLE upid ADD COLUMN station_id_14 INTEGER");

# $dbh->do ("CREATE INDEX ac_id_09 ON upid (ac_id_09)");
$dbh->do ("CREATE INDEX booth_id_14 ON upid (booth_id_14)");

my $sth = $dbh->prepare("SELECT ac_id_09 FROM upid WHERE ac_id_09 IS NOT NULL GROUP BY ac_id_09");
$sth->execute();
my $count=0;
my %result;
while (my $row=$sth->fetchrow_hashref) {
    my $tempold='';
    my $sth2 = $dbh->prepare("SELECT station_name_14 FROM upid WHERE ac_id_09 = ?");
    $sth2->execute($row->{ac_id_09});
    while (my $row2=$sth2->fetchrow_hashref) {
	my $temp=$row2->{station_name_14};
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
    my $temp=$row->{station_name_14};
    $temp=~s/\d//gs;
    $dbh->do ("UPDATE upid SET station_id_14 = ? WHERE ac_id_09 = ? AND booth_id_14 = ?", undef, $result{$row->{ac_id_09}.$temp}, $row->{ac_id_09}, $row->{booth_id_14});
}
$sth->finish ();

$dbh->commit;

$dbh->do ("CREATE INDEX station_id_14 ON upid (station_id_14)");

#
# Finally create sqlite dump 
#

print "Create dumps and CSV\n";

$dbh->sqlite_backup_to_file("temp.sqlite");

system("sqlite3 temp.sqlite '.dump uploksabha2014' > uploksabha2014-a.sql");

open (FILE, ">>uploksabha2014-a.sql");

print FILE ".mode csv\n";
print FILE ".headers on\n";
print FILE ".once uploksabha2014/uploksabha2014.csv\n";
print FILE "SELECT * FROM uploksabha2014;\n";

close (FILE);

system("split -l 50000 uploksabha2014-a.sql");
system("mv xaa uploksabha2014-a.sql");
system("echo 'COMMIT;' >> uploksabha2014-a.sql");
system("echo 'BEGIN TRANSACTION;' > uploksabha2014-b.sql");
system("cat xab >> uploksabha2014-b.sql");
system("echo 'COMMIT;' >> uploksabha2014-b.sql");
system("rm xab");
system("echo 'BEGIN TRANSACTION;' > uploksabha2014-c.sql");
system("cat xac >> uploksabha2014-c.sql");
# system("echo 'COMMIT;' >> uploksabha2014-c.sql");
system("rm xac");
# system("echo 'BEGIN TRANSACTION;' > uploksabha2014-d.sql");
# system("cat xad >> uploksabha2014-d.sql");
# system("rm xad");

system("sqlite3 temp.sqlite '.dump upid' > uploksabha2014-d.sql");

open (FILE, "uploksabha2014-d.sql");
my @file = <FILE>;
close (FILE);

open (FILE, ">uploksabha2014-d.sql");

print FILE "ALTER TABLE upid ADD COLUMN ac_name_14 CHAR;\n";
print FILE "ALTER TABLE upid ADD COLUMN ac_reserved_14 CHAR;\n";
print FILE "ALTER TABLE upid ADD COLUMN booth_id_14 INTEGER;\n";
print FILE "ALTER TABLE upid ADD COLUMN station_name_14 CHAR;\n";
print FILE "ALTER TABLE upid ADD COLUMN station_id_14 INTEGER;\n";

my $insert;
foreach my $line (@file) {
    if ($line =~ /^CREATE TABLE upid (.*?);/) {$insert=$1;$insert=~s/ CHAR//gs; $insert=~s/ INTEGER//gs; next}
    if ($line =~ /^INSERT INTO \"upid\"/) {$line =~ s/^INSERT INTO \"upid\"/INSERT INTO \"upid\" $insert/}
    print FILE $line;
}

close (FILE);

system("rm temp.sqlite");
