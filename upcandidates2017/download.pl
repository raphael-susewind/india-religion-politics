#!/usr/bin/perl -CSDA

use utf8;
use Text::CSV;
use WWW::Mechanize;
use DBI qw(:utils);

system("rm -f candidates.sqlite");

########### This is the guesscommunity.pl stuff, actual download script starts way below

# 
# Preparatory stuff
#

$dbh = DBI->connect("DBI:SQLite:dbname=names.sqlite", "","", {sqlite_unicode=>1});

#
# Calculate quality factors for different algorithms
# These are mostly deactivated here to speed up things - but thats how they were originally calculated
#

my %quality;

# my $sth = $dbh->prepare("SELECT name FROM names WHERE namepart = 'l' GROUP by name");
# $sth->execute();
# my $ref = $sth->fetchall_arrayref;
# my @full =  @{$ref};
# $sth->finish ();
# my $sth = $dbh->prepare("SELECT name FROM names WHERE namepart = 'l' AND community != '' GROUP BY name HAVING count(DISTINCT community)=1");
# $sth->execute();
# my $ref = $sth->fetchall_arrayref;
# my @part = @{$ref};
# $sth->finish ();
# my $ratio=int(scalar(@part)/scalar(@full)*100)/100;
# print "Quality for englishlast $ratio\n";
# $quality{'englishlast'}=$ratio;
$quality{'englishlast'}=0.41;

# my $sth = $dbh->prepare("SELECT name FROM names WHERE namepart = 'f' AND gender = 'm' GROUP by name");
# $sth->execute();
# my $ref = $sth->fetchall_arrayref;
# my @full =  @{$ref};
# $sth->finish ();
# my $sth = $dbh->prepare("SELECT name FROM names WHERE namepart = 'f' AND gender = 'm' GROUP BY name HAVING count(DISTINCT community)=1");
# $sth->execute();
# my $ref = $sth->fetchall_arrayref;
# my @part = @{$ref};
# $sth->finish ();
# my $ratio=int(scalar(@part)/scalar(@full)*100)/100;
# print "Quality for englishfirstm $ratio\n";
# $quality{'englishfirstm'}=$ratio;
$quality{'englishfirstm'}=0.94;

# my $sth = $dbh->prepare("SELECT name FROM names WHERE namepart = 'f' AND gender = 'f' GROUP by name");
# $sth->execute();
# my $ref = $sth->fetchall_arrayref;
# my @full =  @{$ref};
# $sth->finish ();
# my $sth = $dbh->prepare("SELECT name FROM names WHERE namepart = 'f' AND gender = 'f' GROUP BY name HAVING count(DISTINCT community)=1");
# $sth->execute();
# my $ref = $sth->fetchall_arrayref;
# my @part = @{$ref};
# $sth->finish ();
# my $ratio=int(scalar(@part)/scalar(@full)*100)/100;
# print "Quality for englishfirstf $ratio\n";
# $quality{'englishfirstf'}=$ratio;
$quality{'englishfirstf'}=0.94;

# my $sth = $dbh->prepare("SELECT name FROM names WHERE namepart = 'f' GROUP by name");
# $sth->execute();
# my $ref = $sth->fetchall_arrayref;
# my @full =  @{$ref};
# $sth->finish ();
# my $sth = $dbh->prepare("SELECT name FROM names WHERE namepart = 'f' GROUP BY name HAVING count(DISTINCT community)=1");
# $sth->execute();
# my $ref = $sth->fetchall_arrayref;
# my @part = @{$ref};
# $sth->finish ();
# my $ratio=int(scalar(@part)/scalar(@full)*100)/100;
# print "Quality for englishfirst $ratio\n";
# $quality{'englishfirst'}=$ratio;
$quality{'englishfirst'}=0.93;

# my $sth = $dbh->prepare("SELECT name_hi FROM names WHERE namepart = 'l' GROUP by name_hi");
# $sth->execute();
# my $ref = $sth->fetchall_arrayref;
# my @full =  @{$ref};
# $sth->finish ();
# my $sth = $dbh->prepare("SELECT name_hi FROM names WHERE namepart = 'l' GROUP BY name_hi HAVING count(DISTINCT community)=1");
# $sth->execute();
# my $ref = $sth->fetchall_arrayref;
# my @part = @{$ref};
# $sth->finish ();
# my $ratio=int(scalar(@part)/scalar(@full)*100)/100;
# print "Quality for devanagarilast $ratio\n";
# $quality{'devanagarilast'}=$ratio;
$quality{'devanagarilast'}=0.42;

# my $sth = $dbh->prepare("SELECT name_hi FROM names WHERE namepart = 'f' AND gender = 'm' GROUP by name_hi");
# $sth->execute();
# my $ref = $sth->fetchall_arrayref;
# my @full =  @{$ref};
# $sth->finish ();
# my $sth = $dbh->prepare("SELECT name_hi FROM names WHERE namepart = 'f' AND gender = 'm' GROUP BY name_hi HAVING count(DISTINCT community)=1");
# $sth->execute();
# my $ref = $sth->fetchall_arrayref;
# my @part = @{$ref};
# $sth->finish ();
# my $ratio=int(scalar(@part)/scalar(@full)*100)/100;
# print "Quality for devanagarifirstm $ratio\n";
# $quality{'devanagarifirstm'}=$ratio;
$quality{'devanagarifirstm'}=0.93;

# my $sth = $dbh->prepare("SELECT name_hi FROM names WHERE namepart = 'f' AND gender = 'f' GROUP by name_hi");
# $sth->execute();
# my $ref = $sth->fetchall_arrayref;
# my @full =  @{$ref};
# $sth->finish ();
# my $sth = $dbh->prepare("SELECT name_hi FROM names WHERE namepart = 'f' AND gender = 'f' GROUP BY name_hi HAVING count(DISTINCT community)=1");
# $sth->execute();
# my $ref = $sth->fetchall_arrayref;
# my @part = @{$ref};
# $sth->finish ();
# my $ratio=int(scalar(@part)/scalar(@full)*100)/100;
# print "Quality for devanagarifirstf $ratio\n";
# $quality{'devanagarifirstf'}=$ratio;
$quality{'devanagarifirstf'}=0.93;

# my $sth = $dbh->prepare("SELECT name_hi FROM names WHERE namepart = 'f' GROUP by name_hi");
# $sth->execute();
# my $ref = $sth->fetchall_arrayref;
# my @full =  @{$ref};
# $sth->finish ();
# my $sth = $dbh->prepare("SELECT name_hi FROM names WHERE namepart = 'f' GROUP BY name_hi HAVING count(DISTINCT community)=1");
# $sth->execute();
# my $ref = $sth->fetchall_arrayref;
# my @part = @{$ref};
# $sth->finish ();
# my $ratio=int(scalar(@part)/scalar(@full)*100)/100;
# print "Quality for devanagarifirst $ratio\n";
# $quality{'devanagarifirst'}=$ratio;
$quality{'devanagarifirst'}=0.92;

# my $sth = $dbh->prepare("SELECT name_soundex FROM names WHERE namepart = 'l' GROUP by name_soundex");
# $sth->execute();
# my $ref = $sth->fetchall_arrayref;
# my @full =  @{$ref};
# $sth->finish ();
# my $sth = $dbh->prepare("SELECT name_soundex FROM names WHERE namepart = 'l' GROUP BY name_soundex HAVING count(DISTINCT community)=1");
# $sth->execute();
# my $ref = $sth->fetchall_arrayref;
# my @part = @{$ref};
# $sth->finish ();
# my $ratio=int(scalar(@part)/scalar(@full)*100)/100;
# print "Quality for soundexlast $ratio\n";
# $quality{'soundexlast'}=$ratio;
$quality{'soundexlast'}=0.41;

# my $sth = $dbh->prepare("SELECT name_soundex FROM names WHERE namepart = 'f' AND gender = 'm' GROUP by name_soundex");
# $sth->execute();
# my $ref = $sth->fetchall_arrayref;
# my @full =  @{$ref};
# $sth->finish ();
# my $sth = $dbh->prepare("SELECT name_soundex FROM names WHERE namepart = 'f' AND gender = 'm' GROUP BY name_soundex HAVING count(DISTINCT community)=1");
# $sth->execute();
# my $ref = $sth->fetchall_arrayref;
# my @part = @{$ref};
# $sth->finish ();
# my $ratio=int(scalar(@part)/scalar(@full)*100)/100;
# print "Quality for soundexfirstm $ratio\n";
# $quality{'soundexfirstm'}=$ratio;
$quality{'soundexfirstm'}=0.92;

# my $sth = $dbh->prepare("SELECT name_soundex FROM names WHERE namepart = 'f' AND gender = 'f' GROUP by name_soundex");
# $sth->execute();
# my $ref = $sth->fetchall_arrayref;
# my @full =  @{$ref};
# $sth->finish ();
# my $sth = $dbh->prepare("SELECT name_soundex FROM names WHERE namepart = 'f' AND gender = 'f' GROUP BY name_soundex HAVING count(DISTINCT community)=1");
# $sth->execute();
# my $ref = $sth->fetchall_arrayref;
# my @part = @{$ref};
# $sth->finish ();
# my $ratio=int(scalar(@part)/scalar(@full)*100)/100;
# print "Quality for soundexfirstf $ratio\n";
# $quality{'soundexfirstf'}=$ratio;
$quality{'soundexfirstf'}=0.91;

# my $sth = $dbh->prepare("SELECT name_soundex FROM names WHERE namepart = 'f' GROUP by name_soundex");
# $sth->execute();
# my $ref = $sth->fetchall_arrayref;
# my @full =  @{$ref};
# $sth->finish ();
# my $sth = $dbh->prepare("SELECT name_soundex FROM names WHERE namepart = 'f' GROUP BY name_soundex HAVING count(DISTINCT community)=1");
# $sth->execute();
# my $ref = $sth->fetchall_arrayref;
# my @part = @{$ref};
# $sth->finish ();
# my $ratio=int(scalar(@part)/scalar(@full)*100)/100;
# print "Quality for soundexfirst $ratio\n";
# $quality{'soundexfirst'}=$ratio;
$quality{'soundexfirst'}=0.9;

#
# Algorithm functions
#

# create devanagari from english, first try buffered results, if not found, insert in database after generation
sub devanagari {
    my $devanagari = $dbh->selectrow_array("SELECT name_hi FROM names WHERE name = ?",undef,$_[0]);
    if ($devanagari eq '') {
	my $ua = WWW::Mechanize->new(agent=>'Mozilla/5.0 (X11; U; Linux i686; de; rv:1.9.0.16)',cookie_jar=>undef,onerror=>undef);                                                                                
	my $counter = 0;
	devagain:
	  $counter++;
	my $result = $ua->get('http://www.google.com/transliterate/indic?tlqt=1&langpair=en|hi&text='.$_[0].'&&tl_app=1'); 
	if ($result->is_error && $counter<10) {print "Error connecting to google, trying again\n"; sleep 1; goto devagain}
	elsif ($counter<10) {
	    my $json=$ua->content;
	    $json=~/\:\s+\[\s+\"(.*?)\"/gs;
	    $devanagari=$1;
	} else {$devanagari=""}
	# $dbh->do ("INSERT INTO names VALUES (?, ?, ?, ?, ?, ?)", undef, $_[0], $devanagari, undef,undef,undef,'b');
    }
    return $devanagari;
}


# create indicsoundex from devanagari, first try buffered results, if not found, insert in database after generation
sub soundex {
    my $soundex = $dbh->selectrow_array("SELECT name_soundex FROM names WHERE name_hi = ?",undef,$_[0]);
    my $orig=$_[0];
    if ($soundex eq '') {
	open (FILE,">soundextmp");
	print FILE $orig;
	close (FILE);
	system("python soundex.py");
	open (FILE,"soundextmp");
	$soundex=<FILE>;
	close (FILE);
	chomp($soundex); 
	system("rm -f soundextmp");
#	my $exists = $dbh->selectrow_array("SELECT * FROM names WHERE name_hi = ?",undef,$orig);
#	if ($exists > 0) {$dbh->do ("UPDATE names SET name_soundex = ? WHERE name_hi = ?", undef, $soundex, $orig);}
#	else {$dbh->do ("INSERT INTO names VALUES (?, ?, ?, ?, ?, ?)", undef, undef, $orig,$soundex,undef,undef,'b')}
    }
    return $soundex;
}

# match against english last name
sub englishlast {
    my %result;
    my $sth = $dbh->prepare("SELECT * FROM names WHERE name = ? AND namepart = 'l'");
    $sth->execute($_[0]);
    while (my $row=$sth->fetchrow_hashref) {$result{$row->{community}}=$result{$row->{community}}+1;}
    $sth->finish ();
    return %result;
}

# match against english first name_hi gendered male
sub englishfirstm {
    my %result;
    my $sth = $dbh->prepare("SELECT * FROM names WHERE name = ? AND namepart = 'f' AND gender = 'm'");
    $sth->execute($_[0]);
    while (my $row=$sth->fetchrow_hashref) {$result{$row->{community}}=$result{$row->{community}}+1;}
    $sth->finish ();
    return %result;
}

# match against english first name_hi gendered female
sub englishfirstf {
    my %result;
    my $sth = $dbh->prepare("SELECT * FROM names WHERE name = ? AND namepart = 'f' AND gender = 'f'");
    $sth->execute($_[0]);
    while (my $row=$sth->fetchrow_hashref) {$result{$row->{community}}=$result{$row->{community}}+1;}
    $sth->finish ();
    return %result;
}

# match against english first name
sub englishfirst {
    my %result;
    my $sth = $dbh->prepare("SELECT * FROM names WHERE name = ? AND namepart = 'f'");
    $sth->execute($_[0]);
    while (my $row=$sth->fetchrow_hashref) {$result{$row->{community}}=$result{$row->{community}}+1;}
    $sth->finish ();
    return %result;
}

# match against devanagari last name
sub devanagarilast {
    my %result;
    my $sth = $dbh->prepare("SELECT * FROM names WHERE name_hi = ? AND namepart = 'l'");
    $sth->execute($_[0]);
    while (my $row=$sth->fetchrow_hashref) {$result{$row->{community}}=$result{$row->{community}}+1;}
    $sth->finish ();
    return %result;
}

# match against devanagari first name_hi gendered male
sub devanagarifirstm {
    my %result;
    my $sth = $dbh->prepare("SELECT * FROM names WHERE name_hi = ? AND namepart = 'f' AND gender = 'm'");
    $sth->execute($_[0]);
    while (my $row=$sth->fetchrow_hashref) {$result{$row->{community}}=$result{$row->{community}}+1;}
    $sth->finish ();
    return %result;
}

# match against devanagari first name_hi gendered female
sub devanagarifirstf {
    my %result;
    my $sth = $dbh->prepare("SELECT * FROM names WHERE name_hi = ? AND namepart = 'f' AND gender = 'f'");
    $sth->execute($_[0]);
    while (my $row=$sth->fetchrow_hashref) {$result{$row->{community}}=$result{$row->{community}}+1;}
    $sth->finish ();
    return %result;
}

# match against devanagari first name
sub devanagarifirst {
    my %result;
    my $sth = $dbh->prepare("SELECT * FROM names WHERE name_hi = ? AND namepart = 'f'");
    $sth->execute($_[0]);
    while (my $row=$sth->fetchrow_hashref) {$result{$row->{community}}=$result{$row->{community}}+1;}
    $sth->finish ();
    return %result;
}

# match against soundex last name
sub soundexlast {
    my %result;
    my $sth = $dbh->prepare("SELECT * FROM names WHERE name_soundex = ? AND namepart = 'l'");
    $sth->execute($_[0]);
    while (my $row=$sth->fetchrow_hashref) {$result{$row->{community}}=$result{$row->{community}}+1;}
    $sth->finish ();
    return %result;
}

# match against soundex first name gendered male
sub soundexfirstm {
    my %result;
    my $sth = $dbh->prepare("SELECT * FROM names WHERE name_soundex = ? AND namepart = 'f' AND gender = 'm'");
    $sth->execute($_[0]);
    while (my $row=$sth->fetchrow_hashref) {$result{$row->{community}}=$result{$row->{community}}+1;}
    $sth->finish ();
    return %result;
}

# match against soundex first name gendered female
sub soundexfirstf {
    my %result;
    my $sth = $dbh->prepare("SELECT * FROM names WHERE name_soundex = ? AND namepart = 'f' AND gender = 'f'");
    $sth->execute($_[0]);
    while (my $row=$sth->fetchrow_hashref) {$result{$row->{community}}=$result{$row->{community}}+1;}
    $sth->finish ();
    return %result;
}

# match against soundex first name
sub soundexfirst {
    my %result;
    my $sth = $dbh->prepare("SELECT * FROM names WHERE name_soundex = ? AND namepart = 'f'");
    $sth->execute($_[0]);
    while (my $row=$sth->fetchrow_hashref) {$result{$row->{community}}=$result{$row->{community}}+1;}
    $sth->finish ();
    return %result;
}

#
# Run the namechecking per se
#

sub checkname {

# get arguments from command line
my $fullname=$_[0];
my $gender='';

# calculate soundex codes and separate first and lastnames list
    my @names=split(/ /,$fullname);
    my %soundex; my @firstnames; my @lastnames;
    
    my $name=pop(@names); # guess that last or only name is lastname, rest is rather firstname - but check
    if (length($name)<3) {goto tooshort}
    
    if ($name=~/\p{Devanagari}/) {
    if ($name=~/उद्दीन$/) {$name=~s/उद्दीन$//gs; push(@lastnames,'Uddin')} # CHECK FOR MUSLIM LAST NAME CONJUNCTS -uddin and -ullah
    elsif ($name=~/उदीन$/) {$name=~s/उदीन$//gs; push(@lastnames,'Uddin')}
    elsif ($name=~/उल्लह$/) {$name=~s/उल्लह$//gs; push(@lastnames,'Ullah')}
    elsif ($name=~/\x{0941}द्दीन$/) {$name=~s/\x{0941}द्दीन$//gs; push(@lastnames,'Uddin')}
    elsif ($name=~/\x{0941}दीन$/) {$name=~s/\x{0941}दीन$//gs; push(@lastnames,'Uddin')}
    elsif ($name=~/\x{0941}ल्लह$/) {$name=~s/\x{0941}ल्लह$//gs; push(@lastnames,'Ullah')}
    $soundex{$name}=soundex($name)
} else {
    if ($name=~/uddin$/) {$name=~s/uddin$//gs; push(@lastnames,'Uddin')}
    elsif ($name=~/uddeen$/) {$name=~s/uddeen$//gs; push(@lastnames,'Uddin')}
    elsif ($name=~/ullah$/) {$name=~s/ullah$//gs; push(@lastnames,'Ullah')}
    $soundex{$name}=soundex(devanagari($name))
}
my $last = $dbh->selectrow_array("SELECT count(*) FROM names WHERE name_soundex = ? AND namepart = 'l'",undef,$soundex{$name});
if ($last<0) {
    my $first = $dbh->selectrow_array("SELECT count(*) FROM names WHERE name_soundex = ? AND namepart = 'f'",undef,$soundex{$name});
    if ($first>0) {push(@firstnames,$name)}
} else {push(@lastnames,$name)}

    tooshort:
    
foreach my $name (@names) { # Favour firstname if in doubt for all other names
    next if (length($name)<3);
    if ($name=~/\p{Devanagari}/) {
	if ($name=~/उद्दीन$/) {$name=~s/उद्दीन$//gs; push(@lastnames,'Uddin')} # CHECK FOR MUSLIM LAST NAME CONJUNCTS -uddin and -ullah
	elsif ($name=~/उदीन$/) {$name=~s/उदीन$//gs; push(@lastnames,'Uddin')}
	elsif ($name=~/उल्लह$/) {$name=~s/उल्लह$//gs; push(@lastnames,'Ullah')}
	elsif ($name=~/\x{0941}द्दीन$/) {$name=~s/\x{0941}द्दीन$//gs; push(@lastnames,'Uddin')}
	elsif ($name=~/\x{0941}दीन$/) {$name=~s/\x{0941}दीन$//gs; push(@lastnames,'Uddin')}
	elsif ($name=~/\x{0941}ल्लह$/) {$name=~s/\x{0941}ल्लह$//gs; push(@lastnames,'Ullah')}
	$soundex{$name}=soundex($name)
    } else {
	if ($name=~/uddin$/) {$name=~s/uddin$//gs; push(@lastnames,'Uddin')}
	elsif ($name=~/uddeen$/) {$name=~s/uddeen$//gs; push(@lastnames,'Uddin')}
	elsif ($name=~/ullah$/) {$name=~s/ullah$//gs; push(@lastnames,'Ullah')}
	$soundex{$name}=soundex(devanagari($name))
    }
    my $first = $dbh->selectrow_array("SELECT count(*) FROM names WHERE name_soundex = ? AND namepart = 'f'",undef,$soundex{$name});
    if ($first<0) {
	my $last = $dbh->selectrow_array("SELECT count(*) FROM names WHERE name_soundex = ? AND namepart = 'l'",undef,$soundex{$name});
	if ($last>0) {push(@lastnames,$name)}
    } else {push(@firstnames,$name)}
}

my %community;
my $jaga=0;

# identify all lastnames
foreach my $lastname (@lastnames) {
    if ($lastname=~/\p{Devanagari}/) {
	my %devanagarilast = devanagarilast($lastname);
	my $devanagaricount=0;
	my %soundexlast = soundexlast(soundex($lastname));
	my $soundexcount=0;
	foreach my $com (keys(%devanagarilast)) {$devanagaricount=$devanagaricount+$devanagarilast{$com}}
	foreach my $com (keys(%soundexlast)) {$soundexcount=$soundexcount+$soundexlast{$com}}
	if ($devanagaricount>0 and $soundexcount>0) {
	    foreach my $com ((keys(%devanagarilast),keys(%soundexlast))) {$community{$lastname}{$com}=1-($devanagaricount-$devanagarilast{$com})/$devanagaricount*($soundexcount-$soundexlast{$com})/$soundexcount;$jaga=1;$match=1}
	    foreach my $com (keys(%devanagarilast)) {$community{$lastname}{$com}=$community{$lastname}{$com}*$quality{'devanagarilast'}}
	    foreach my $com (keys(%soundexlast)) {$community{$lastname}{$com}=$community{$lastname}{$com}*$quality{'soundexlast'}}
	} elsif ($devanagaricount>0) {
	    foreach my $com (keys(%devanagarilast)) {$community{$lastname}{$com}=1-($devanagaricount-$devanagarilast{$com})/$devanagaricount;$jaga=1;$match=1}
	    foreach my $com (keys(%devanagarilast)) {$community{$lastname}{$com}=$community{$lastname}{$com}*$quality{'devanagarilast'}}
	} elsif ($soundexcount>0) {
	    foreach my $com (keys(%soundexlast)) {$community{$lastname}{$com}=1-($soundexcount-$soundexlast{$com})/$soundexcount;$jaga=1;$match=1}
	    foreach my $com (keys(%soundexlast)) {$community{$lastname}{$com}=$community{$lastname}{$com}*$quality{'soundexlast'}}
	}
    } else {
	my %englishlast = englishlast($lastname);
	my $englishcount=0;
	my %soundexlast = soundexlast(soundex(devanagari($lastname)));
	my $soundexcount=0;
	foreach my $com (keys(%englishlast)) {$englishcount=$englishcount+$englishlast{$com}}
	foreach my $com (keys(%soundexlast)) {$soundexcount=$soundexcount+$soundexlast{$com}}
	if ($englishcount>0 and $soundexcount>0) {
	    foreach my $com ((keys(%englishlast),keys(%soundexlast))) {$community{$lastname}{$com}=1-($englishcount-$englishlast{$com})/$englishcount*($soundexcount-$soundexlast{$com})/$soundexcount;$jaga=1;$match=1}
	    foreach my $com (keys(%englishlast)) {$community{$lastname}{$com}=$community{$lastname}{$com}*$quality{'englishlast'}}
	    foreach my $com (keys(%soundexlast)) {$community{$lastname}{$com}=$community{$lastname}{$com}*$quality{'soundexlast'}}
	} elsif ($englishcount>0) {
	    foreach my $com (keys(%englishlast)) {$community{$lastname}{$com}=1-($englishcount-$englishlast{$com})/$englishcount;$jaga=1;$match=1}
	    foreach my $com (keys(%englishlast)) {$community{$lastname}{$com}=$community{$lastname}{$com}*$quality{'englishlast'}}
	} elsif ($soundexcount>0) {
	    foreach my $com (keys(%soundexlast)) {$community{$lastname}{$com}=1-($soundexcount-$soundexlast{$com})/$soundexcount;$jaga=1;$match=1}
	    foreach my $com (keys(%soundexlast)) {$community{$lastname}{$com}=$community{$lastname}{$com}*$quality{'soundexlast'}}
	}
    }
    # if no matching lastname found at all, it might be a firstname
    if ($jaga==0) {push(@firstnames,$lastname)}
}
    
# identify all firstnames
foreach my $firstname (@firstnames) {
    if ($firstname=~/\p{Devanagari}/ && $gender eq 'm') {
	my %devanagarifirstm = devanagarifirstm($firstname);
	my $devanagaricount=0;
	my %soundexfirstm = soundexfirstm(soundex($firstname));
	my $soundexcount=0;
	foreach my $com (keys(%devanagarifirstm)) {$devanagaricount=$devanagaricount+$devanagarifirstm{$com}}
	foreach my $com (keys(%soundexfirstm)) {$soundexcount=$soundexcount+$soundexfirstm{$com}}
	if ($devanagaricount>0 and $soundexcount>0) {
	    foreach my $com ((keys(%devanagarifirstm),keys(%soundexfirstm))) {$community{$firstname}{$com}=1-($devanagaricount-$devanagarifirstm{$com})/$devanagaricount*($soundexcount-$soundexfirstm{$com})/$soundexcount;$jaga=1;$match=1}
	    foreach my $com (keys(%devanagarifirstm)) {$community{$firstname}{$com}=$community{$firstname}{$com}*$quality{'devanagarifirstm'}}
	    foreach my $com (keys(%soundexfirstm)) {$community{$firstname}{$com}=$community{$firstname}{$com}*$quality{'soundexfirstm'}}
	} elsif ($devanagaricount>0) {
	    foreach my $com (keys(%devanagarifirstm)) {$community{$firstname}{$com}=1-($devanagaricount-$devanagarifirstm{$com})/$devanagaricount;$jaga=1;$match=1}
	    foreach my $com (keys(%devanagarifirstm)) {$community{$firstname}{$com}=$community{$firstname}{$com}*$quality{'devanagarifirstm'}}
	} elsif ($soundexcount>0) {
	    foreach my $com (keys(%soundexfirstm)) {$community{$firstname}{$com}=1-($soundexcount-$soundexfirstm{$com})/$soundexcount;$jaga=1;$match=1}
	    foreach my $com (keys(%soundexfirstm)) {$community{$firstname}{$com}=$community{$firstname}{$com}*$quality{'soundexfirstm'}}
	} else { # ignore gender if nothing found
	    my %devanagarifirst = devanagarifirst($firstname);
	    my $devanagaricount=0;
	    my %soundexfirst = soundexfirst(soundex($firstname));
	    my $soundexcount=0;
	    foreach my $com (keys(%devanagarifirst)) {$devanagaricount=$devanagaricount+$devanagarifirst{$com}}
	    foreach my $com (keys(%soundexfirst)) {$soundexcount=$soundexcount+$soundexfirst{$com}}
	    if ($devanagaricount>0 and $soundexcount>0) {
		foreach my $com ((keys(%devanagarifirst),keys(%soundexfirst))) {$community{$firstname}{$com}=1-($devanagaricount-$devanagarifirst{$com})/$devanagaricount*($soundexcount-$soundexfirst{$com})/$soundexcount;$jaga=1;$match=1}
		foreach my $com (keys(%devanagarifirst)) {$community{$firstname}{$com}=$community{$firstname}{$com}*$quality{'devanagarifirst'}}
		foreach my $com (keys(%soundexfirst)) {$community{$firstname}{$com}=$community{$firstname}{$com}*$quality{'soundexfirst'}}
	    } elsif ($devanagaricount>0) {
		foreach my $com (keys(%devanagarifirst)) {$community{$firstname}{$com}=1-($devanagaricount-$devanagarifirst{$com})/$devanagaricount;$jaga=1;$match=1}
		foreach my $com (keys(%devanagarifirst)) {$community{$firstname}{$com}=$community{$firstname}{$com}*$quality{'devanagarifirst'}}
	    } elsif ($soundexcount>0) {
		foreach my $com (keys(%soundexfirst)) {$community{$firstname}{$com}=1-($soundexcount-$soundexfirst{$com})/$soundexcount;$jaga=1;$match=1}
		foreach my $com (keys(%soundexfirst)) {$community{$firstname}{$com}=$community{$firstname}{$com}*$quality{'soundexfirst'}}
	    }
	}
    } elsif ($firstname=~/\p{Devanagari}/ && $gender eq 'f') {
	my %devanagarifirstf = devanagarifirstf($firstname);
	my $devanagaricount=0;
	my %soundexfirstf = soundexfirstf(soundex($firstname));
	my $soundexcount=0;
	foreach my $com (keys(%devanagarifirstf)) {$devanagaricount=$devanagaricount+$devanagarifirstf{$com}}
	foreach my $com (keys(%soundexfirstf)) {$soundexcount=$soundexcount+$soundexfirstf{$com}}
	if ($devanagaricount>0 and $soundexcount>0) {
	    foreach my $com ((keys(%devanagarifirstf),keys(%soundexfirstf))) {$community{$firstname}{$com}=1-($devanagaricount-$devanagarifirstf{$com})/$devanagaricount*($soundexcount-$soundexfirstf{$com})/$soundexcount;$jaga=1;$match=1}
	    foreach my $com (keys(%devanagarifirstf)) {$community{$firstname}{$com}=$community{$firstname}{$com}*$quality{'devanagarifirstf'}}
	    foreach my $com (keys(%soundexfirstf)) {$community{$firstname}{$com}=$community{$firstname}{$com}*$quality{'soundexfirstf'}}
	} elsif ($devanagaricount>0) {
	    foreach my $com (keys(%devanagarifirstf)) {$community{$firstname}{$com}=1-($devanagaricount-$devanagarifirstf{$com})/$devanagaricount;$jaga=1;$match=1}
	    foreach my $com (keys(%devanagarifirstf)) {$community{$firstname}{$com}=$community{$firstname}{$com}*$quality{'devanagarifirstf'}}
	} elsif ($soundexcount>0) {
	    foreach my $com (keys(%soundexfirstf)) {$community{$firstname}{$com}=1-($soundexcount-$soundexfirstf{$com})/$soundexcount;$jaga=1;$match=1}
	    foreach my $com (keys(%soundexfirstf)) {$community{$firstname}{$com}=$community{$firstname}{$com}*$quality{'soundexfirstf'}}
	} else { # ignore gender if nothing found
	    my %devanagarifirst = devanagarifirst($firstname);
	    my $devanagaricount=0;
	    my %soundexfirst = soundexfirst(soundex($firstname));
	    my $soundexcount=0;
	    foreach my $com (keys(%devanagarifirst)) {$devanagaricount=$devanagaricount+$devanagarifirst{$com}}
	    foreach my $com (keys(%soundexfirst)) {$soundexcount=$soundexcount+$soundexfirst{$com}}
	    if ($devanagaricount>0 and $soundexcount>0) {
		foreach my $com ((keys(%devanagarifirst),keys(%soundexfirst))) {$community{$firstname}{$com}=1-($devanagaricount-$devanagarifirst{$com})/$devanagaricount*($soundexcount-$soundexfirst{$com})/$soundexcount;$jaga=1;$match=1}
		foreach my $com (keys(%devanagarifirst)) {$community{$firstname}{$com}=$community{$firstname}{$com}*$quality{'devanagarifirst'}}
		foreach my $com (keys(%soundexfirst)) {$community{$firstname}{$com}=$community{$firstname}{$com}*$quality{'soundexfirst'}}
	    } elsif ($devanagaricount>0) {
		foreach my $com (keys(%devanagarifirst)) {$community{$firstname}{$com}=1-($devanagaricount-$devanagarifirst{$com})/$devanagaricount;$jaga=1;$match=1}
		foreach my $com (keys(%devanagarifirst)) {$community{$firstname}{$com}=$community{$firstname}{$com}*$quality{'devanagarifirst'}}
	    } elsif ($soundexcount>0) {
		foreach my $com (keys(%soundexfirst)) {$community{$firstname}{$com}=1-($soundexcount-$soundexfirst{$com})/$soundexcount;$jaga=1;$match=1}
		foreach my $com (keys(%soundexfirst)) {$community{$firstname}{$com}=$community{$firstname}{$com}*$quality{'soundexfirst'}}
	    }
	}
    } elsif ($firstname=~/\p{Devanagari}/) {
	my %devanagarifirst = devanagarifirst($firstname);
	my $devanagaricount=0;
	my %soundexfirst = soundexfirst(soundex($firstname));
	my $soundexcount=0;
	foreach my $com (keys(%devanagarifirst)) {$devanagaricount=$devanagaricount+$devanagarifirst{$com}}
	foreach my $com (keys(%soundexfirst)) {$soundexcount=$soundexcount+$soundexfirst{$com}}
	my %devanagarifirst = devanagarifirst($firstname);
	my $devanagaricount=0;
	my %soundexfirst = soundexfirst(soundex($firstname));
	my $soundexcount=0;
	foreach my $com (keys(%devanagarifirst)) {$devanagaricount=$devanagaricount+$devanagarifirst{$com}}
	foreach my $com (keys(%soundexfirst)) {$soundexcount=$soundexcount+$soundexfirst{$com}}
	if ($devanagaricount>0 and $soundexcount>0) {
	    foreach my $com ((keys(%devanagarifirst),keys(%soundexfirst))) {$community{$firstname}{$com}=1-($devanagaricount-$devanagarifirst{$com})/$devanagaricount*($soundexcount-$soundexfirst{$com})/$soundexcount;$jaga=1;$match=1}
	    foreach my $com (keys(%devanagarifirst)) {$community{$firstname}{$com}=$community{$firstname}{$com}*$quality{'devanagarifirst'}}
	    foreach my $com (keys(%soundexfirst)) {$community{$firstname}{$com}=$community{$firstname}{$com}*$quality{'soundexfirst'}}
	} elsif ($devanagaricount>0) {
	    foreach my $com (keys(%devanagarifirst)) {$community{$firstname}{$com}=1-($devanagaricount-$devanagarifirst{$com})/$devanagaricount;$jaga=1;$match=1}
	    foreach my $com (keys(%devanagarifirst)) {$community{$firstname}{$com}=$community{$firstname}{$com}*$quality{'devanagarifirst'}}
	} elsif ($soundexcount>0) {
	    foreach my $com (keys(%soundexfirst)) {$community{$firstname}{$com}=1-($soundexcount-$soundexfirst{$com})/$soundexcount;$jaga=1;$match=1}
	    foreach my $com (keys(%soundexfirst)) {$community{$firstname}{$com}=$community{$firstname}{$com}*$quality{'soundexfirst'}}
	}
    } elsif ($gender eq 'm') {
	my %englishfirstm = englishfirstm($firstname);
	my $englishcount=0;
	my %soundexfirstm = soundexfirstm(soundex(devanagari($firstname)));
	my $soundexcount=0;
	foreach my $com (keys(%englishfirstm)) {$englishcount=$englishcount+$englishfirstm{$com}}
	foreach my $com (keys(%soundexfirstm)) {$soundexcount=$soundexcount+$soundexfirstm{$com}}
	if ($englishcount>0 and $soundexcount>0) {
	    foreach my $com ((keys(%englishfirstm),keys(%soundexfirstm))) {$community{$firstname}{$com}=1-($englishcount-$englishfirstm{$com})/$englishcount*($soundexcount-$soundexfirstm{$com})/$soundexcount;$jaga=1;$match=1}
	    foreach my $com (keys(%englishfirstm)) {$community{$firstname}{$com}=$community{$firstname}{$com}*$quality{'englishfirstm'}}
	    foreach my $com (keys(%soundexfirstm)) {$community{$firstname}{$com}=$community{$firstname}{$com}*$quality{'soundexfirstm'}}
	} elsif ($englishcount>0) {
	    foreach my $com (keys(%englishfirstm)) {$community{$firstname}{$com}=1-($englishcount-$englishfirstm{$com})/$englishcount;$jaga=1;$match=1}
	    foreach my $com (keys(%englishfirstm)) {$community{$firstname}{$com}=$community{$firstname}{$com}*$quality{'englishfirstm'}}
	} elsif ($soundexcount>0) {
	    foreach my $com (keys(%soundexfirstm)) {$community{$firstname}{$com}=1-($soundexcount-$soundexfirstm{$com})/$soundexcount;$jaga=1;$match=1}
	    foreach my $com (keys(%soundexfirstm)) {$community{$firstname}{$com}=$community{$firstname}{$com}*$quality{'soundexfirstm'}}
	} else { # ignore gender if nothing found
	    my %englishfirst = englishfirst($firstname);
	    my $englishcount=0;
	    my %soundexfirst = soundexfirst(soundex(devanagari($firstname)));
	    my $soundexcount=0;
	    foreach my $com (keys(%englishfirst)) {$englishcount=$englishcount+$englishfirst{$com}}
	    foreach my $com (keys(%soundexfirst)) {$soundexcount=$soundexcount+$soundexfirst{$com}}
	    if ($englishcount>0 and $soundexcount>0) {
		foreach my $com ((keys(%englishfirst),keys(%soundexfirst))) {$community{$firstname}{$com}=1-($englishcount-$englishfirst{$com})/$englishcount*($soundexcount-$soundexfirst{$com})/$soundexcount;$jaga=1;$match=1}
		foreach my $com (keys(%englishfirst)) {$community{$firstname}{$com}=$community{$firstname}{$com}*$quality{'englishfirst'}}
		foreach my $com (keys(%soundexfirst)) {$community{$firstname}{$com}=$community{$firstname}{$com}*$quality{'soundexfirst'}}
	    } elsif ($englishcount>0) {
		foreach my $com (keys(%englishfirst)) {$community{$firstname}{$com}=1-($englishcount-$englishfirst{$com})/$englishcount;$jaga=1;$match=1}
		foreach my $com (keys(%englishfirst)) {$community{$firstname}{$com}=$community{$firstname}{$com}*$quality{'englishfirst'}}
	    } elsif ($soundexcount>0) {
		foreach my $com (keys(%soundexfirst)) {$community{$firstname}{$com}=1-($soundexcount-$soundexfirst{$com})/$soundexcount;$jaga=1;$match=1}
		foreach my $com (keys(%soundexfirst)) {$community{$firstname}{$com}=$community{$firstname}{$com}*$quality{'soundexfirst'}}
	    }
	}
    } elsif ($gender eq 'f') {
	my %englishfirstf = englishfirstf($firstname);
	my $englishcount=0;
	my %soundexfirstf = soundexfirstf(soundex(devanagari($firstname)));
	my $soundexcount=0;
	foreach my $com (keys(%englishfirstf)) {$englishcount=$englishcount+$englishfirstf{$com}}
	foreach my $com (keys(%soundexfirstf)) {$soundexcount=$soundexcount+$soundexfirstf{$com}}
	if ($englishcount>0 and $soundexcount>0) {
	    foreach my $com ((keys(%englishfirstf),keys(%soundexfirstf))) {$community{$firstname}{$com}=1-($englishcount-$englishfirstf{$com})/$englishcount*($soundexcount-$soundexfirstf{$com})/$soundexcount;$jaga=1;$match=1}
	    foreach my $com (keys(%englishfirstf)) {$community{$firstname}{$com}=$community{$firstname}{$com}*$quality{'englishfirstf'}}
	    foreach my $com (keys(%soundexfirstf)) {$community{$firstname}{$com}=$community{$firstname}{$com}*$quality{'soundexfirstf'}}
	} elsif ($englishcount>0) {
	    foreach my $com (keys(%englishfirstf)) {$community{$firstname}{$com}=1-($englishcount-$englishfirstf{$com})/$englishcount;$jaga=1;$match=1}
	    foreach my $com (keys(%englishfirstf)) {$community{$firstname}{$com}=$community{$firstname}{$com}*$quality{'englishfirstf'}}
	} elsif ($soundexcount>0) {
	    foreach my $com (keys(%soundexfirstf)) {$community{$firstname}{$com}=1-($soundexcount-$soundexfirstf{$com})/$soundexcount;$jaga=1;$match=1}
	    foreach my $com (keys(%soundexfirstf)) {$community{$firstname}{$com}=$community{$firstname}{$com}*$quality{'soundexfirstf'}}
	} else { # ignore gender if nothing found
	    my %englishfirst = englishfirst($firstname);
	    my $englishcount=0;
	    my %soundexfirst = soundexfirst(soundex(devanagari($firstname)));
	    my $soundexcount=0;
	    foreach my $com (keys(%englishfirst)) {$englishcount=$englishcount+$englishfirst{$com}}
	    foreach my $com (keys(%soundexfirst)) {$soundexcount=$soundexcount+$soundexfirst{$com}}
	    if ($englishcount>0 and $soundexcount>0) {
		foreach my $com ((keys(%englishfirst),keys(%soundexfirst))) {$community{$firstname}{$com}=1-($englishcount-$englishfirst{$com})/$englishcount*($soundexcount-$soundexfirst{$com})/$soundexcount;$jaga=1;$match=1}
		foreach my $com (keys(%englishfirst)) {$community{$firstname}{$com}=$community{$firstname}{$com}*$quality{'englishfirst'}}
		foreach my $com (keys(%soundexfirst)) {$community{$firstname}{$com}=$community{$firstname}{$com}*$quality{'soundexfirst'}}
	    } elsif ($englishcount>0) {
		foreach my $com (keys(%englishfirst)) {$community{$firstname}{$com}=1-($englishcount-$englishfirst{$com})/$englishcount;$jaga=1;$match=1}
		foreach my $com (keys(%englishfirst)) {$community{$firstname}{$com}=$community{$firstname}{$com}*$quality{'englishfirst'}}
	    } elsif ($soundexcount>0) {
		foreach my $com (keys(%soundexfirst)) {$community{$firstname}{$com}=1-($soundexcount-$soundexfirst{$com})/$soundexcount;$jaga=1;$match=1}
		foreach my $com (keys(%soundexfirst)) {$community{$firstname}{$com}=$community{$firstname}{$com}*$quality{'soundexfirst'}}
	    }
	}
    } else {
	my %englishfirst = englishfirst($firstname);
	my $englishcount=0;
	my %soundexfirst = soundexfirst(soundex(devanagari($firstname)));
	my $soundexcount=0;
	foreach my $com (keys(%englishfirst)) {$englishcount=$englishcount+$englishfirst{$com}}
	foreach my $com (keys(%soundexfirst)) {$soundexcount=$soundexcount+$soundexfirst{$com}}
	if ($englishcount>0 and $soundexcount>0) {
	    foreach my $com ((keys(%englishfirst),keys(%soundexfirst))) {$community{$firstname}{$com}=1-($englishcount-$englishfirst{$com})/$englishcount*($soundexcount-$soundexfirst{$com})/$soundexcount;$jaga=1;$match=1}
	    foreach my $com (keys(%englishfirst)) {$community{$firstname}{$com}=$community{$firstname}{$com}*$quality{'englishfirst'}}
	    foreach my $com (keys(%soundexfirst)) {$community{$firstname}{$com}=$community{$firstname}{$com}*$quality{'soundexfirst'}}
	} elsif ($englishcount>0) {
	    foreach my $com (keys(%englishfirst)) {$community{$firstname}{$com}=1-($englishcount-$englishfirst{$com})/$englishcount;$jaga=1;$match=1}
	    foreach my $com (keys(%englishfirst)) {$community{$firstname}{$com}=$community{$firstname}{$com}*$quality{'englishfirst'}}
	} elsif ($soundexcount>0) {
	    foreach my $com (keys(%soundexfirst)) {$community{$firstname}{$com}=1-($soundexcount-$soundexfirst{$com})/$soundexcount;$jaga=1;$match=1}
	    foreach my $com (keys(%soundexfirst)) {$community{$firstname}{$com}=$community{$firstname}{$com}*$quality{'soundexfirst'}}
	}
    }
}


#
# Combine names and print out results
#

if ($jaga>0) {
    my %communitylist;
    my $count;
    foreach my $name ((@firstnames,@lastnames)) {foreach my $community (keys(%{$community{$name}})) {$communitylist{$community}=1;$count=$count+1;}}
    foreach my $community (keys(%communitylist)) {
	foreach my $name (@firstnames) {$communitylist{$community}=$communitylist{$community}*($count-$community{$name}{$community})/$count}
	foreach my $name (@lastnames) {$communitylist{$community}=$communitylist{$community}*($count-$community{$name}{$community})/$count}
	$communitylist{$community}=int((1-$communitylist{$community})*100);
    }
    my @sorted=sort {$communitylist{$b} <=> $communitylist{$a}} (keys(%communitylist));
    my $diff=$communitylist{$sorted[0]}-$communitylist{$sorted[1]};
    if ($diff>0) {
	return ($sorted[0],$diff);
    } else {return ("Unknown",0)}
    
} else {
    return ("Unknown",0);
}

}

########### This is the actual script

$dbh_cand = DBI->connect("DBI:SQLite:dbname=candidates.sqlite", "","", {sqlite_unicode=>1});
$dbh_cand->do ("CREATE TABLE raw (ac INTEGER, serial INTEGER, name CHAR, party CHAR, shortparty CHAR, religion CHAR, certainty INTEGER)");

my $ua = WWW::Mechanize->new(agent=>'Mozilla/5.0 (X11; U; Linux i686; de; rv:1.9.0.16)',cookie_jar=>{},onerror=>undef);
my %headersql;

# iterate through ACs and download raw candidate names
for ($ac=1;$ac<=403;$ac++) {

    print "Processing AC $ac\n";
    
    $ua->get("http://affidavitarchive.nic.in/CANDIDATEAFFIDAVIT.aspx?YEARID=March-2017%20%28%20GEN%20%29&AC_No=".$ac."&st_code=S24&constType=AC");
    my $html = $ua->content;

    $html =~ s/^.*?PARTY NAME\<\/b\>\<\/td\>//gs;
    $html =~ s/\<\/table\>.*//gs;
    
    my @html = split (/\<\/tr\>/,$html);
    
    foreach my $line (@html) {
	next unless $line =~ /javascript/;
	
	$line =~ /\>(\d+)\</gs;
	my $serial = $1;
	$line =~ /\'\'\)\"\>(.*?)\<\/a\>\<\/td\>\<td\>(.*?)\<\/td\>/gs;
	my $name = $1; my $longparty = $2;

	my $party = $longparty;
	$party =~ s/\.//gs;
	$party =~ s/\,//gs;
	$party =~ s/\)//gs;
	$party =~ s/\(/-/gs;
	$party =~ s/\s//gs;
	$party = lc($party);
	$party =~ s/\d//gs;
	if ($party eq 'independent') {$party = 'ind'}
	if ($party eq 'bahujansamajparty') {$party = 'bsp'}
	if ($party eq 'bharatiyajanataparty') {$party = 'bjp'}
	if ($party eq 'indiannationalcongress') {$party = 'inc'}
        if ($party eq 'samajwadiparty') {$party = 'sp'}        
	$party=~s/-/_/gs;
	$party=~s/[^a-z0-9 -]//gs;
	$headersql{$party}=1;
    	
	my ($religion,$certainty) = checkname($name);
	
	print "-- $serial $name ($longparty = $party) as $religion ($certainty)\n";

	$dbh_cand->do ("INSERT INTO raw VALUES (?,?,?,?,?,?,?)",undef,$ac,$serial,$name,$longparty,$party,$religion,$certainty);
    }
}

# transform into proper table format
$dbh_cand->do ("CREATE TABLE upcandidates2017 (id INTEGER PRIMARY KEY,ac_id_09 INTEGER)");

foreach my $key (keys(%headersql)) {
    $dbh_cand->do ("ALTER TABLE upcandidates2017 ADD COLUMN candidate_".$key."_name_17 CHAR");
    $dbh_cand->do ("ALTER TABLE upcandidates2017 ADD COLUMN candidate_".$key."_religion_17 CHAR");
    $dbh_cand->do ("ALTER TABLE upcandidates2017 ADD COLUMN candidate_".$key."_religion_certainty_17 INTEGER");
}

my $sth = $dbh_cand->prepare("SELECT * FROM raw");
$sth->execute();
my $oldconst;
while (my $row=$sth->fetchrow_hashref) { 
    if ($oldconst == $row->{ac}) {
	$dbh_cand->do("UPDATE upcandidates2017 SET candidate_".$row->{shortparty}."_name_17 = ?, candidate_".$row->{shortparty}."_religion_17 = ?, candidate_".$row->{shortparty}."_religion_certainty_17 = ? WHERE ac_id_09 = ?",undef,$row->{name},$row->{religion},$row->{certainty},$row->{ac});
    } else { 
	$dbh_cand->do ("INSERT INTO upcandidates2017 (ac_id_09, candidate_".$row->{shortparty}."_name_17, candidate_".$row->{shortparty}."_religion_17, candidate_".$row->{shortparty}."_religion_certainty_17) VALUES (?,?,?,?)",undef,$row->{ac},$row->{name},$row->{religion},$row->{certainty});
	$oldconst=$row->{ac};
    }
}

$sth->finish();
$dbh_cand->disconnect;
$dbh->disconnect;


# integrate into main dataset
system("sqlite3 candidates.sqlite '.dump upcandidates2017' > upcandidates2017.sql");

open (FILE, ">>upcandidates2017.sql");

print FILE ".mode csv\n";
print FILE ".headers on\n";
print FILE ".once upcandidates2017/upcandidates2017.csv\n";
print FILE "SELECT * FROM upcandidates2017;\n";

close (FILE);
