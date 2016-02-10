#!/usr/bin/perl

use DBI;
use utf8;

$dbh = DBI->connect("DBI:SQLite:dbname=:memory:", "","", {sqlite_unicode=>1});
$dbh->sqlite_backup_from_file('names.sqlite');

my %quality;
$qualdevlast=0.98;
$qualdevfirstm=0.93;
$qualdevfirstf=0.93;
$qualdevfirstu=0.92;
$qualsoundlast=0.96;
$qualsoundfirstm=0.92;
$qualsoundfirstf=0.91;
$qualsoundfirstu=0.9;

open(PYTHON,"|python3.3 -u soundex.py");
binmode(PYTHON,":utf8");
open(FIFO,"fifo");
binmode(FIFO,":utf8");

# create indicsoundex from devanagari, first try buffered results, if not found, insert in database after generation
my %soundex; 
sub soundex {
    if (defined($soundex{$_[0]})) {return $soundex{$_[0]}}
    syswrite PYTHON, $_[0]."\n";
    sysread FIFO, $soundex, 9; 
    chomp($soundex); 
    $soundex{$_[0]}=$soundex;
    return $soundex;
}

# match against devanagari last name
sub devanagarilast {
    my %result;
    my $sth = $dbh->prepare("SELECT community, count(*) 'count' FROM names WHERE name_hi = ? AND namepart = 'l' GROUP BY community");
    $sth->execute($_[0]);
    while (my $row=$sth->fetchrow_hashref) {$result{$row->{community}}=$row->{count};}
    $sth->finish ();
    return %result;
}

# match against devanagari first name_hi gendered male
sub devanagarifirstm {
    my %result;
    my $sth = $dbh->prepare("SELECT community, count(*) 'count' FROM names WHERE name_hi = ? AND namepart = 'f' AND gender = 'm' GROUP BY community");
    $sth->execute($_[0]);
    while (my $row=$sth->fetchrow_hashref) {$result{$row->{community}}=$row->{count};}
    $sth->finish ();
    return %result;
}

# match against devanagari first name_hi gendered female
sub devanagarifirstf {
    my %result;
    my $sth = $dbh->prepare("SELECT community, count(*) 'count' FROM names WHERE name_hi = ? AND namepart = 'f' AND gender = 'f' GROUP BY community");
    $sth->execute($_[0]);
    while (my $row=$sth->fetchrow_hashref) {$result{$row->{community}}=$row->{count};}
    $sth->finish ();
    return %result;
}

# match against devanagari first name
sub devanagarifirst {
    my %result;
    my $sth = $dbh->prepare("SELECT community, count(*) 'count' FROM names WHERE name_hi = ? AND namepart = 'f' GROUP BY community");
    $sth->execute($_[0]);
    while (my $row=$sth->fetchrow_hashref) {$result{$row->{community}}=$row->{count};}
    $sth->finish ();
    return %result;
}

# match against soundex last name
sub soundexlast {
    my %result;
    my $sth = $dbh->prepare("SELECT community, count(*) 'count' FROM names WHERE name_soundex = ? AND namepart = 'l' GROUP BY community");
    $sth->execute($_[0]);
    while (my $row=$sth->fetchrow_hashref) {$result{$row->{community}}=$row->{count};}
    $sth->finish ();
    return %result;
}

# match against soundex first name gendered male
sub soundexfirstm {
    my %result;
    my $sth = $dbh->prepare("SELECT community, count(*) 'count' FROM names WHERE name_soundex = ? AND namepart = 'f' AND gender = 'm' GROUP BY community");
    $sth->execute($_[0]);
    while (my $row=$sth->fetchrow_hashref) {$result{$row->{community}}=$row->{count};}
    $sth->finish ();
    return %result;
}

# match against soundex first name gendered female
sub soundexfirstf {
    my %result;
    my $sth = $dbh->prepare("SELECT community, count(*) 'count' FROM names WHERE name_soundex = ? AND namepart = 'f' AND gender = 'f' GROUP BY community");
    $sth->execute($_[0]);
    while (my $row=$sth->fetchrow_hashref) {$result{$row->{community}}=$row->{count};}
    $sth->finish ();
    return %result;
}

# match against soundex first name
sub soundexfirst {
    my %result;
    my $sth = $dbh->prepare("SELECT community, count(*) 'count' FROM names WHERE name_soundex = ? AND namepart = 'f' GROUP BY community");
    $sth->execute($_[0]);
    while (my $row=$sth->fetchrow_hashref) {$result{$row->{community}}=$row->{count};}
    $sth->finish ();
    return %result;
}

#
# Run the namechecking per se
#

sub checkname {
# get arguments from command line
    my $gender=$_[0];
    my $votername=$_[1];
    my $voterfathername=$_[2];
    
    # calculate soundex codes and separate first and lastnames list
    my @names=split(/ /,$votername);
    
    undef(my @firstnames); undef(my @lastnames);
    #   tooshort: 
    my $name=pop(@names); # guess that last or only name is lastname, rest is rather firstname - but check
#    if (length($name) < 2 && scalar(@names)>0) {goto tooshort} elsif (scalar(@names)==0) {goto furthernames}
    if ($name=~/उद्दीन$/) {$name=~s/उद्दीन$//s; push(@lastnames,'उद्दीन')} # CHECK FOR MUSLIM LAST NAME CONJUNCTS -uddin and -ullah
    elsif ($name=~/उदीन$/) {$name=~s/उदीन$//s; push(@lastnames,'उद्दीन')}
    elsif ($name=~/उल्लह$/) {$name=~s/उल्लह$//s; push(@lastnames,'उल्लाह')}
    elsif ($name=~/\x{0941}द्दीन$/) {$name=~s/\x{0941}द्दीन$//s; push(@lastnames,'उद्दीन')}
    elsif ($name=~/\x{0941}दीन$/) {$name=~s/\x{0941}दीन$//s; push(@lastnames,'उद्दीन')}
    elsif ($name=~/\x{0941}ल्लह$/) {$name=~s/\x{0941}ल्लह$//s; push(@lastnames,'उल्लाह')}
    $soundex{$name}=soundex($name);
    my @last = $dbh->selectrow_array("SELECT count(*) FROM names WHERE name_soundex = ? AND namepart = 'l'",undef,$soundex{$name});
    if (scalar(@last)<1) {
	my @first = $dbh->selectrow_array("SELECT count(*) FROM names WHERE name_soundex = ? AND namepart = 'f'",undef,$soundex{$name});
	if (scalar(@first)>0) {push(@firstnames,$name)}
    } else {push(@lastnames,$name)}
    
    foreach my $name (@names) { # Favour firstname if in doubt for all other names
#	next if (length($name) < 2);
	if ($name=~/उद्दीन$/) {$name=~s/उद्दीन$//s; push(@lastnames,'उद्दीन')} # CHECK FOR MUSLIM LAST NAME CONJUNCTS -uddin and -ullah
	elsif ($name=~/उदीन$/) {$name=~s/उदीन$//s; push(@lastnames,'उद्दीन')}
	elsif ($name=~/उल्लह$/) {$name=~s/उल्लह$//s; push(@lastnames,'उल्लाह')}
	elsif ($name=~/\x{0941}द्दीन$/) {$name=~s/\x{0941}द्दीन$//s; push(@lastnames,'उद्दीन')}
	elsif ($name=~/\x{0941}दीन$/) {$name=~s/\x{0941}दीन$//s; push(@lastnames,'उद्दीन')}
	elsif ($name=~/\x{0941}ल्लह$/) {$name=~s/\x{0941}ल्लह$//s; push(@lastnames,'उल्लाह')}
	$soundex{$name}=soundex($name);
	my @first = $dbh->selectrow_array("SELECT count(*) FROM names WHERE name_soundex = ? AND namepart = 'f'",undef,$soundex{$name});
	if (scalar(@first)<1) {
	    my @last = $dbh->selectrow_array("SELECT count(*) FROM names WHERE name_soundex = ? AND namepart = 'l'",undef,$soundex{$name});
	    if (scalar(@last)>0) {push(@lastnames,$name)}
	} else {push(@firstnames,$name)}
    }
    my %community;
    my %communityvoter;
    my %communityvoterfather;
    
    my $jaga1=0;
    
# identify all lastnames
    foreach my $lastname (@lastnames) {
	my %devanagarilast = devanagarilast($lastname);
	my $devanagaricount=0;
	my %soundexlast = soundexlast(soundex($lastname));
	my $soundexcount=0;
	foreach my $com (keys(%devanagarilast)) {$devanagaricount=$devanagaricount+$devanagarilast{$com}}
	foreach my $com (keys(%soundexlast)) {$soundexcount=$soundexcount+$soundexlast{$com}}
	if ($devanagaricount>0 and $soundexcount>0) {
	    foreach my $com ((keys(%devanagarilast),keys(%soundexlast))) {$community{$lastname}{$com}=1-($devanagaricount-$devanagarilast{$com})/$devanagaricount*($soundexcount-$soundexlast{$com})/$soundexcount;$jaga1=1;$match=1}
	    foreach my $com (keys(%devanagarilast)) {$community{$lastname}{$com}=$community{$lastname}{$com}*$qualdevlast;$communityvoter{$lastname}{$com}=$community{$lastname}{$com}}
	    foreach my $com (keys(%soundexlast)) {$community{$lastname}{$com}=$community{$lastname}{$com}*$qualsoundlast;$communityvoter{$lastname}{$com}=$community{$lastname}{$com}}
	} elsif ($devanagaricount>0) {
	    foreach my $com (keys(%devanagarilast)) {$community{$lastname}{$com}=1-($devanagaricount-$devanagarilast{$com})/$devanagaricount;$jaga1=1;$match=1}
	    foreach my $com (keys(%devanagarilast)) {$community{$lastname}{$com}=$community{$lastname}{$com}*$qualdevlast;$communityvoter{$lastname}{$com}=$community{$lastname}{$com}}
	} elsif ($soundexcount>0) {
	    foreach my $com (keys(%soundexlast)) {$community{$lastname}{$com}=1-($soundexcount-$soundexlast{$com})/$soundexcount;$jaga1=1;$match=1}
	    foreach my $com (keys(%soundexlast)) {$community{$lastname}{$com}=$community{$lastname}{$com}*$qualsoundlast;$communityvoter{$lastname}{$com}=$community{$lastname}{$com}}
	}
	# if no matching lastname found at all, it might be a firstname
	if ($jaga1==0) {push(@firstnames,$lastname)}
    }
    
# identify all firstnames
    foreach my $firstname (@firstnames) {
	if ($gender eq 'm') {
	    my %devanagarifirstm = devanagarifirstm($firstname);
	    my $devanagaricount=0;
	    my %soundexfirstm = soundexfirstm(soundex($firstname));
	    my $soundexcount=0;
	    foreach my $com (keys(%devanagarifirstm)) {$devanagaricount=$devanagaricount+$devanagarifirstm{$com}}
	    foreach my $com (keys(%soundexfirstm)) {$soundexcount=$soundexcount+$soundexfirstm{$com}}
	    if ($devanagaricount>0 and $soundexcount>0) {
		foreach my $com ((keys(%devanagarifirstm),keys(%soundexfirstm))) {$community{$firstname}{$com}=1-($devanagaricount-$devanagarifirstm{$com})/$devanagaricount*($soundexcount-$soundexfirstm{$com})/$soundexcount;$jaga1=1;$match=1}
		foreach my $com (keys(%devanagarifirstm)) {$community{$firstname}{$com}=$community{$firstname}{$com}*$qualdevfirstm;$communityvoter{$firstname}{$com}=$community{$firstname}{$com}}
		foreach my $com (keys(%soundexfirstm)) {$community{$firstname}{$com}=$community{$firstname}{$com}*$qualsoundfirstm;$communityvoter{$firstname}{$com}=$community{$firstname}{$com}}
	    } elsif ($devanagaricount>0) {
		foreach my $com (keys(%devanagarifirstm)) {$community{$firstname}{$com}=1-($devanagaricount-$devanagarifirstm{$com})/$devanagaricount;$jaga1=1;$match=1}
		foreach my $com (keys(%devanagarifirstm)) {$community{$firstname}{$com}=$community{$firstmname}{$com}*$qualdevfirstm;$communityvoter{$firstname}{$com}=$community{$firstname}{$com}}
	    } elsif ($soundexcount>0) {
		foreach my $com (keys(%soundexfirstm)) {$community{$firstname}{$com}=1-($soundexcount-$soundexfirstm{$com})/$soundexcount;$jaga1=1;$match=1}
		foreach my $com (keys(%soundexfirstm)) {$community{$firstname}{$com}=$community{$firstname}{$com}*$qualsoundfirstm;$communityvoter{$firstname}{$com}=$community{$firstname}{$com}}
	    } else { # ignore gender if nothing found
		my %devanagarifirst = devanagarifirst($firstname);
		my $devanagaricount=0;
		my %soundexfirst = soundexfirst(soundex($firstname));
		my $soundexcount=0;
		foreach my $com (keys(%devanagarifirst)) {$devanagaricount=$devanagaricount+$devanagarifirst{$com}}
		foreach my $com (keys(%soundexfirst)) {$soundexcount=$soundexcount+$soundexfirst{$com}}
		if ($devanagaricount>0 and $soundexcount>0) {
		    foreach my $com ((keys(%devanagarifirst),keys(%soundexfirst))) {$community{$firstname}{$com}=1-($devanagaricount-$devanagarifirst{$com})/$devanagaricount*($soundexcount-$soundexfirst{$com})/$soundexcount;$jaga1=1;$match=1}
		    foreach my $com (keys(%devanagarifirst)) {$community{$firstname}{$com}=$community{$firstname}{$com}*$qualdevfirstu;$communityvoter{$firstname}{$com}=$community{$firstname}{$com}}
		    foreach my $com (keys(%soundexfirst)) {$community{$firstname}{$com}=$community{$firstname}{$com}*$qualsoundfirstu;$communityvoter{$firstname}{$com}=$community{$firstname}{$com}}
		} elsif ($devanagaricount>0) {
		    foreach my $com (keys(%devanagarifirst)) {$community{$firstname}{$com}=1-($devanagaricount-$devanagarifirst{$com})/$devanagaricount;$jaga1=1;$match=1}
		    foreach my $com (keys(%devanagarifirst)) {$community{$firstname}{$com}=$community{$firstname}{$com}*$qualdevfirstu;$communityvoter{$firstname}{$com}=$community{$firstname}{$com}}
		} elsif ($soundexcount>0) {
		    foreach my $com (keys(%soundexfirst)) {$community{$firstname}{$com}=1-($soundexcount-$soundexfirst{$com})/$soundexcount;$jaga1=1;$match=1}
		    foreach my $com (keys(%soundexfirst)) {$community{$firstname}{$com}=$community{$firstname}{$com}*$qualsoundfirstu;$communityvoter{$firstname}{$com}=$community{$firstname}{$com}}
		}
	    }
	} elsif ($gender eq 'f') {
	    my %devanagarifirstf = devanagarifirstf($firstname);
	    my $devanagaricount=0;
	    my %soundexfirstf = soundexfirstf(soundex($firstname));
	    my $soundexcount=0;
	    foreach my $com (keys(%devanagarifirstf)) {$devanagaricount=$devanagaricount+$devanagarifirstf{$com}}
	    foreach my $com (keys(%soundexfirstf)) {$soundexcount=$soundexcount+$soundexfirstf{$com}}
	    if ($devanagaricount>0 and $soundexcount>0) {
		foreach my $com ((keys(%devanagarifirstf),keys(%soundexfirstf))) {$community{$firstname}{$com}=1-($devanagaricount-$devanagarifirstf{$com})/$devanagaricount*($soundexcount-$soundexfirstf{$com})/$soundexcount;$jaga1=1;$match=1}
		foreach my $com (keys(%devanagarifirstf)) {$community{$firstname}{$com}=$community{$firstname}{$com}*$qualdevfirstf;$communityvoter{$firstname}{$com}=$community{$firstname}{$com}}
		foreach my $com (keys(%soundexfirstf)) {$community{$firstname}{$com}=$community{$firstname}{$com}*$qualsoundfirstf;$communityvoter{$firstname}{$com}=$community{$firstname}{$com}}
	    } elsif ($devanagaricount>0) {
		foreach my $com (keys(%devanagarifirstf)) {$community{$firstname}{$com}=1-($devanagaricount-$devanagarifirstf{$com})/$devanagaricount;$jaga1=1;$match=1}
		foreach my $com (keys(%devanagarifirstf)) {$community{$firstname}{$com}=$community{$firstname}{$com}*$qualdevfirstf;$communityvoter{$firstname}{$com}=$community{$firstname}{$com}}
	    } elsif ($soundexcount>0) {
		foreach my $com (keys(%soundexfirstf)) {$community{$firstname}{$com}=1-($soundexcount-$soundexfirstf{$com})/$soundexcount;$jaga1=1;$match=1}
		foreach my $com (keys(%soundexfirstf)) {$community{$firstname}{$com}=$community{$firstname}{$com}*$qualsoundfirstf;$communityvoter{$firstname}{$com}=$community{$firstname}{$com}}
	    } else { # ignore gender if nothing found
		my %devanagarifirst = devanagarifirst($firstname);
		my $devanagaricount=0;
		my %soundexfirst = soundexfirst(soundex($firstname));
		my $soundexcount=0;
		foreach my $com (keys(%devanagarifirst)) {$devanagaricount=$devanagaricount+$devanagarifirst{$com}}
		foreach my $com (keys(%soundexfirst)) {$soundexcount=$soundexcount+$soundexfirst{$com}}
		if ($devanagaricount>0 and $soundexcount>0) {
		    foreach my $com ((keys(%devanagarifirst),keys(%soundexfirst))) {$community{$firstname}{$com}=1-($devanagaricount-$devanagarifirst{$com})/$devanagaricount*($soundexcount-$soundexfirst{$com})/$soundexcount;$jaga1=1;$match=1}
		    foreach my $com (keys(%devanagarifirst)) {$community{$firstname}{$com}=$community{$firstname}{$com}*$qualdevfirstu;$communityvoter{$firstname}{$com}=$community{$firstname}{$com}}
		    foreach my $com (keys(%soundexfirst)) {$community{$firstname}{$com}=$community{$firstname}{$com}*$qualsoundfirstu;$communityvoter{$firstname}{$com}=$community{$firstname}{$com}}
		} elsif ($devanagaricount>0) {
		    foreach my $com (keys(%devanagarifirst)) {$community{$firstname}{$com}=1-($devanagaricount-$devanagarifirst{$com})/$devanagaricount;$jaga1=1;$match=1}
		    foreach my $com (keys(%devanagarifirst)) {$community{$firstname}{$com}=$community{$firstname}{$com}*$qualdevfirstu;$communityvoter{$firstname}{$com}=$community{$firstname}{$com}}
		} elsif ($soundexcount>0) {
		    foreach my $com (keys(%soundexfirst)) {$community{$firstname}{$com}=1-($soundexcount-$soundexfirst{$com})/$soundexcount;$jaga1=1;$match=1}
		    foreach my $com (keys(%soundexfirst)) {$community{$firstname}{$com}=$community{$firstname}{$com}*$qualsoundfirstu;$communityvoter{$firstname}{$com}=$community{$firstname}{$com}}
		}
	    }
	} else {
	    my %devanagarifirst = devanagarifirst($firstname);
	    my $devanagaricount=0;
	    my %soundexfirst = soundexfirst(soundex($firstname));
	    my $soundexcount=0;
	    foreach my $com (keys(%devanagarifirst)) {$devanagaricount=$devanagaricount+$devanagarifirst{$com}}
	    foreach my $com (keys(%soundexfirst)) {$soundexcount=$soundexcount+$soundexfirst{$com}}
	    if ($devanagaricount>0 and $soundexcount>0) {
		foreach my $com ((keys(%devanagarifirst),keys(%soundexfirst))) {$community{$firstname}{$com}=1-($devanagaricount-$devanagarifirst{$com})/$devanagaricount*($soundexcount-$soundexfirst{$com})/$soundexcount;$jaga1=1;$match=1}
		foreach my $com (keys(%devanagarifirst)) {$community{$firstname}{$com}=$community{$firstname}{$com}*$qualdevfirstu;$communityvoter{$firstname}{$com}=$community{$firstname}{$com}}
		foreach my $com (keys(%soundexfirst)) {$community{$firstname}{$com}=$community{$firstname}{$com}*$qualsoundfirstu;$communityvoter{$firstname}{$com}=$community{$firstname}{$com}}
	    } elsif ($devanagaricount>0) {
		foreach my $com (keys(%devanagarifirst)) {$community{$firstname}{$com}=1-($devanagaricount-$devanagarifirst{$com})/$devanagaricount;$jaga1=1;$match=1}
		foreach my $com (keys(%devanagarifirst)) {$community{$firstname}{$com}=$community{$firstname}{$com}*$qualdevfirstu;$communityvoter{$firstname}{$com}=$community{$firstname}{$com}}
	    } elsif ($soundexcount>0) {
		foreach my $com (keys(%soundexfirst)) {$community{$firstname}{$com}=1-($soundexcount-$soundexfirst{$com})/$soundexcount;$jaga1=1;$match=1}
		foreach my $com (keys(%soundexfirst)) {$community{$firstname}{$com}=$community{$firstname}{$com}*$qualsoundfirstu;$communityvoter{$firstname}{$com}=$community{$firstname}{$com}}
	    }
	} 
    }
    
    #
    # RUN FATHER NAMES
    #

#    furthernames:
    
    my @voterfirstnames=@firstnames;
    my @voterlastnames=@lastnames;
    undef(@firstnames);
    undef(@lastnames);
    
    # calculate soundex codes and separate first and lastnames list
    my @names=split(/ /,$voterfathername);
#    waytooshort:
      my $name=pop(@names); # guess that last or only name is lastname, rest is rather firstname - but check
#    if (length($name) < 2 && scalar(@names)>0) {goto waytooshort} elsif (scalar(@names)==0) {goto wayfurthernames}
    
    if ($name=~/उद्दीन$/) {$name=~s/उद्दीन$//s; push(@lastnames,'उद्दीन')} # CHECK FOR MUSLIM LAST NAME CONJUNCTS -uddin and -ullah
    elsif ($name=~/उदीन$/) {$name=~s/उदीन$//s; push(@lastnames,'उद्दीन')}
    elsif ($name=~/उल्लह$/) {$name=~s/उल्लह$//s; push(@lastnames,'उल्लाह')}
    elsif ($name=~/\x{0941}द्दीन$/) {$name=~s/\x{0941}द्दीन$//s; push(@lastnames,'उद्दीन')}
    elsif ($name=~/\x{0941}दीन$/) {$name=~s/\x{0941}दीन$//s; push(@lastnames,'उद्दीन')}
    elsif ($name=~/\x{0941}ल्लह$/) {$name=~s/\x{0941}ल्लह$//s; push(@lastnames,'उल्लाह')}
    $soundex{$name}=soundex($name);
    my @last = $dbh->selectrow_array("SELECT count(*) FROM names WHERE name_soundex = ? AND namepart = 'l'",undef,$soundex{$name});
# my $first = $dbh->selectrow_array("SELECT count(*) FROM names WHERE name_soundex = ? AND namepart = 'f'",undef,$soundex{$name});
    if (scalar(@last)<1) {
	my @first = $dbh->selectrow_array("SELECT count(*) FROM names WHERE name_soundex = ? AND namepart = 'f'",undef,$soundex{$name});
	if (scalar(@first)>0) {push(@firstnames,$name)}
    } else {push(@lastnames,$name)}
    foreach my $name (@names) { # Favour firstname if in doubt for all other names
#	next if (length($name)<2);
	if ($name=~/उद्दीन$/) {$name=~s/उद्दीन$//s; push(@lastnames,'उद्दीन')} # CHECK FOR MUSLIM LAST NAME CONJUNCTS -uddin and -ullah
	elsif ($name=~/उदीन$/) {$name=~s/उदीन$//s; push(@lastnames,'उद्दीन')}
	elsif ($name=~/उल्लह$/) {$name=~s/उल्लह$//s; push(@lastnames,'उल्लाह')}
	elsif ($name=~/\x{0941}द्दीन$/) {$name=~s/\x{0941}द्दीन$//s; push(@lastnames,'उद्दीन')}
	elsif ($name=~/\x{0941}दीन$/) {$name=~s/\x{0941}दीन$//s; push(@lastnames,'उद्दीन')}
	elsif ($name=~/\x{0941}ल्लह$/) {$name=~s/\x{0941}ल्लह$//s; push(@lastnames,'उल्लाह')}

	$soundex{$name}=soundex($name);
	my @first = $dbh->selectrow_array("SELECT count(*) FROM names WHERE name_soundex = ? AND namepart = 'f'",undef,$soundex{$name});
	if (scalar(@first)<1) {
	    my @last = $dbh->selectrow_array("SELECT count(*) FROM names WHERE name_soundex = ? AND namepart = 'l'",undef,$soundex{$name});
	    if (scalar(@last)>0) {push(@lastnames,$name)}
	} else {push(@firstnames,$name)}
    }

    my $jaga2=0;
    
# identify all lastnames
    foreach my $lastname (@lastnames) {
	my %devanagarilast = devanagarilast($lastname);
	my $devanagaricount=0;
	my %soundexlast = soundexlast(soundex($lastname));
	my $soundexcount=0;
	foreach my $com (keys(%devanagarilast)) {$devanagaricount=$devanagaricount+$devanagarilast{$com}}
	foreach my $com (keys(%soundexlast)) {$soundexcount=$soundexcount+$soundexlast{$com}}
	if ($devanagaricount>0 and $soundexcount>0) {
	    foreach my $com ((keys(%devanagarilast),keys(%soundexlast))) {$community{$lastname}{$com}=1-($devanagaricount-$devanagarilast{$com})/$devanagaricount*($soundexcount-$soundexlast{$com})/$soundexcount;$jaga2=1;$match=1}
	    foreach my $com (keys(%devanagarilast)) {$community{$lastname}{$com}=$community{$lastname}{$com}*$qualdevlast;$communityvoterfather{$lastname}{$com}=$community{$lastname}{$com}}
	    foreach my $com (keys(%soundexlast)) {$community{$lastname}{$com}=$community{$lastname}{$com}*$qualsoundlast;$communityvoterfather{$lastname}{$com}=$community{$lastname}{$com}}
	} elsif ($devanagaricount>0) {
	    foreach my $com (keys(%devanagarilast)) {$community{$lastname}{$com}=1-($devanagaricount-$devanagarilast{$com})/$devanagaricount;$jaga2=1;$match=1}
	    foreach my $com (keys(%devanagarilast)) {$community{$lastname}{$com}=$community{$lastname}{$com}*$qualdevlast;$communityvoterfather{$lastname}{$com}=$community{$lastname}{$com}}
	} elsif ($soundexcount>0) {
	    foreach my $com (keys(%soundexlast)) {$community{$lastname}{$com}=1-($soundexcount-$soundexlast{$com})/$soundexcount;$jaga2=1;$match=1}
	    foreach my $com (keys(%soundexlast)) {$community{$lastname}{$com}=$community{$lastname}{$com}*$qualsoundlast;$communityvoterfather{$lastname}{$com}=$community{$lastname}{$com}}
	}
	# if no matching lastname found at all, it might be a firstname
	if ($jaga2==0) {push(@firstnames,$lastname)}
    }
    
# identify all firstnames - can only be male because its the father...
    foreach my $firstname (@firstnames) {
	my %devanagarifirstm = devanagarifirstm($firstname);
	my $devanagaricount=0;
	my %soundexfirstm = soundexfirstm(soundex($firstname));
	my $soundexcount=0;
	foreach my $com (keys(%devanagarifirstm)) {$devanagaricount=$devanagaricount+$devanagarifirstm{$com}}
	foreach my $com (keys(%soundexfirstm)) {$soundexcount=$soundexcount+$soundexfirstm{$com}}
	if ($devanagaricount>0 and $soundexcount>0) {
	    foreach my $com ((keys(%devanagarifirstm),keys(%soundexfirstm))) {$community{$firstname}{$com}=1-($devanagaricount-$devanagarifirstm{$com})/$devanagaricount*($soundexcount-$soundexfirstm{$com})/$soundexcount;$jaga2=1;$match=1}
	    foreach my $com (keys(%devanagarifirstm)) {$community{$firstname}{$com}=$community{$firstname}{$com}*$qualdevfirstm;$communityvoterfather{$firstname}{$com}=$community{$firstname}{$com}}
	    foreach my $com (keys(%soundexfirstm)) {$community{$firstname}{$com}=$community{$firstname}{$com}*$qualsoundfirstm;$communityvoterfather{$firstname}{$com}=$community{$firstname}{$com}}
	} elsif ($devanagaricount>0) {
	    foreach my $com (keys(%devanagarifirstm)) {$community{$firstname}{$com}=1-($devanagaricount-$devanagarifirstm{$com})/$devanagaricount;$jaga2=1;$match=1}
	    foreach my $com (keys(%devanagarifirstm)) {$community{$firstname}{$com}=$community{$firstname}{$com}*$qualdevfirstm;$communityvoterfather{$firstname}{$com}=$community{$firstname}{$com}}
	} elsif ($soundexcount>0) {
	    foreach my $com (keys(%soundexfirstm)) {$community{$firstname}{$com}=1-($soundexcount-$soundexfirstm{$com})/$soundexcount;$jaga2=1;$match=1}
	    foreach my $com (keys(%soundexfirstm)) {$community{$firstname}{$com}=$community{$firstname}{$com}*$qualsoundfirstm;$communityvoterfather{$firstname}{$com}=$community{$firstname}{$com}}
	} else { # ignore gender if nothing found
	    my %devanagarifirst = devanagarifirst($firstname);
	    my $devanagaricount=0;
	    my %soundexfirst = soundexfirst(soundex($firstname));
	    my $soundexcount=0;
	    foreach my $com (keys(%devanagarifirst)) {$devanagaricount=$devanagaricount+$devanagarifirst{$com}}
	    foreach my $com (keys(%soundexfirst)) {$soundexcount=$soundexcount+$soundexfirst{$com}}
	    if ($devanagaricount>0 and $soundexcount>0) {
		foreach my $com ((keys(%devanagarifirst),keys(%soundexfirst))) {$community{$firstname}{$com}=1-($devanagaricount-$devanagarifirst{$com})/$devanagaricount*($soundexcount-$soundexfirst{$com})/$soundexcount;$jaga2=1;$match=1}
		foreach my $com (keys(%devanagarifirst)) {$community{$firstname}{$com}=$community{$firstname}{$com}*$qualdevfirstu;$communityvoterfather{$firstname}{$com}=$community{$firstname}{$com}}
		foreach my $com (keys(%soundexfirst)) {$community{$firstname}{$com}=$community{$firstname}{$com}*$qualsoundfirstu;$communityvoterfather{$firstname}{$com}=$community{$firstname}{$com}}
	    } elsif ($devanagaricount>0) {
		foreach my $com (keys(%devanagarifirst)) {$community{$firstname}{$com}=1-($devanagaricount-$devanagarifirst{$com})/$devanagaricount;$jaga2=1;$match=1}
		foreach my $com (keys(%devanagarifirst)) {$community{$firstname}{$com}=$community{$firstname}{$com}*$qualdevfirstu;$communityvoterfather{$firstname}{$com}=$community{$firstname}{$com}}
	    } elsif ($soundexcount>0) {
		foreach my $com (keys(%soundexfirst)) {$community{$firstname}{$com}=1-($soundexcount-$soundexfirst{$com})/$soundexcount;$jaga2=1;$match=1}
		foreach my $com (keys(%soundexfirst)) {$community{$firstname}{$com}=$community{$firstname}{$com}*$qualsoundfirstu;$communityvoterfather{$firstname}{$com}=$community{$firstname}{$com}}
	    }
	}
	
    }

  
#
# Combine names and print out results
#
#wayfurthernames:
      
    if ($jaga1>0 or $jaga2>0) {
	my %communitylist; # overall result
	my $count=0;

# weigh voters name double as heavy as fathers name
	foreach my $name ((@firstnames,@lastnames,@firstnames,@lastnames,@voterfirstnames,@voterlastnames)) {foreach my $community (keys(%{$community{$name}})) {$communitylist{$community}=1;$count++;}}
	foreach my $community (keys(%communitylist)) {
	    foreach my $name ((@firstnames,@voterfirstnames)) {$communitylist{$community}=$communitylist{$community}*($count-$community{$name}{$community})/$count}
	    foreach my $name ((@lastnames,@voterlastnames)) {$communitylist{$community}=$communitylist{$community}*($count-$community{$name}{$community})/$count}
	    $communitylist{$community}=int((1-$communitylist{$community})*100);
	}
	my @sorted=sort {$communitylist{$b} <=> $communitylist{$a}} (keys(%communitylist));
	my $percent = 0; if ($communitylist{$sorted[0]} != 0) {$percent = int((1-$communitylist{$sorted[1]}/$communitylist{$sorted[0]})*100);}	    else {@sorted=('Undecidable');}

	
	my %votercommunitylist;
	my @votersorted;
	my $voterpercent=0;
	if ($jaga1>0) { # voter name
	    my $count=0;
	    foreach my $name ((@voterfirstnames,@voterlastnames)) {foreach my $community (keys(%{$communityvoter{$name}})) {$votercommunitylist{$community}=1;$count=$count+1;}}
	    foreach my $community (keys(%votercommunitylist)) {
		foreach my $name (@voterfirstnames) {$votercommunitylist{$community}=$votercommunitylist{$community}*($count-$communityvoter{$name}{$community})/$count}
		foreach my $name (@voterlastnames) {$votercommunitylist{$community}=$votercommunitylist{$community}*($count-$communityvoter{$name}{$community})/$count}
		$votercommunitylist{$community}=int((1-$votercommunitylist{$community})*100);
	    }
	    @votersorted=sort {$votercommunitylist{$b} <=> $votercommunitylist{$a}} (keys(%votercommunitylist));
	    if ($votercommunitylist{$votersorted[0]} > 0) {$voterpercent = int((1-$votercommunitylist{$votersorted[1]}/$votercommunitylist{$votersorted[0]})*100);}
	    else {@voterfathersorted=('Undecidable');}
	} else {
	    push(@votersorted,'Unknown');
	    $votercommunitylist{'Unknown'}=0;
	    $voterpercent=0;
	}

	my %voterfathercommunitylist;
	my @voterfathersorted;
	my $voterfatherpercent=0;
	if ($jaga2>0) { # voterfather name
	    my $count=0;
	    foreach my $name ((@firstnames,@lastnames)) {foreach my $community (keys(%{$communityvoterfather{$name}})) {$voterfathercommunitylist{$community}=1;$count=$count+1;}}
	    foreach my $community (keys(%voterfathercommunitylist)) {
		foreach my $name (@firstnames) {$voterfathercommunitylist{$community}=$voterfathercommunitylist{$community}*($count-$communityvoterfather{$name}{$community})/$count}
		foreach my $name (@lastnames) {$voterfathercommunitylist{$community}=$voterfathercommunitylist{$community}*($count-$communityvoterfather{$name}{$community})/$count}
		$voterfathercommunitylist{$community}=int((1-$voterfathercommunitylist{$community})*100);
	    }
	    @voterfathersorted=sort {$voterfathercommunitylist{$b} <=> $voterfathercommunitylist{$a}} (keys(%voterfathercommunitylist));
	    if ($voterfathercommunitylist{$voterfathersorted[0]}>0) {$voterfatherpercent = int((1-$voterfathercommunitylist{$voterfathersorted[1]}/$voterfathercommunitylist{$voterfathersorted[0]})*100);}
	    else {@voterfathersorted=('Undecidable');}
	} else {
	    push(@voterfathersorted,'Unknown');
	    $voterfathercommunitylist{'Unknown'}=0;
	    $voterfatherpercent=0;
	}
	
	return ($sorted[0],$communitylist{$sorted[0]},$percent,$votersorted[0],$votercommunitylist{$votersorted[0]},$voterpercent,$voterfathersorted[0],$voterfathercommunitylist{$voterfathersorted[0]},$voterfatherpercent,\@voterfirstnames,\@voterlastnames,\@firstnames,\@lastnames);
    } else {
	return ("Unknown",0,0,'Unknown',0,0,'Unknown',0,0,\@voterfirstnames,\@voterlastnames,\@firstnames,\@lastnames);
    }
}
    
###################################################################### Here starts the actual stuff - all the above is from guessvotercommunity.pl ##################################

my $file=$ARGV[0];

chomp $file;

$file =~ /(\d+)-(\d+)/gs;
$constituency=$1/1;
$const=$1;
$booth=$2;

# Extract the three data columns and re-load the respective data, putting it all into @raw, deleting temp files
system("./pdftotext -nopgbrk -x 22 -y 73 -W 258 -H 1020 -layout -r 100 $file out1.txt");
system("./pdftotext -nopgbrk -x 280 -y 73 -W 260 -H 1020 -layout -r 100 $file out2.txt");
system("./pdftotext -nopgbrk -x 540 -y 73 -W 258 -H 1020 -layout -r 100 $file out3.txt");

open (FILE,"<:utf8","out1.txt");
my @raw1=<FILE>;
close (FILE);
open (FILE,"<:utf8","out2.txt");
my @raw2=<FILE>;
close (FILE);
open (FILE,"<:utf8","out3.txt");
my @raw3=<FILE>;
close (FILE);

my @raw=(@raw1,@raw2,@raw3);

system("rm -f out1.txt out2.txt out3.txt");

my $test=join("",@raw);
exit if (scalar(@raw)==0 or $test !~ /1/);

# Create TIFFs and skip empty ones...

my $pagecount=`./gs -q -dNODISPLAY -c "($file) (r) file runpdfbegin pdfpagecount = quit" `;
chomp($pagecount);

my $rollno=0;
for ($page=3;$page<$pagecount;$page++) {
    for ($row=1;$row<=10;$row++) {
	for ($col=1;$col<=3;$col++) {
	    my $buffery = int(741-($row-1)*72);
	    my $bufferx = int(40+($col-1)*186.5);
	    my $empty = `./gs -q -r300 -dFirstPage=$page -dLastPage=$page -sDEVICE=bbox -o /dev/null -g450x105 -c '<</Install {-$bufferx -$buffery translate}>> setpagedevice' -f $file 2>&1`;
	    next if $empty =~ /BoundingBox: 0 0 0 0/;
	    $rollno++;
	    system("./gs -q -r600 -dFirstPage=$page -dLastPage=$page -sDEVICE=tifflzw -o $const-$booth-Mother-$rollno.tif -g900x210 -c '<</Install {-$bufferx -$buffery translate}>> setpagedevice' -f $file");
	}
    }
}

# Connect to database
my $dbh_rolls = DBI->connect("DBI:SQLite:dbname=:memory:", "","", {sqlite_unicode=>1}); # AT THE END BACKUP TO FILE - MASSIVE SPEEDUP!

# if (-e "rolls.$booth.sqlite") {$dbh_rolls->sqlite_backup_from_file("rolls.$booth.sqlite");}

$dbh_rolls->do("CREATE TABLE names (id INTEGER, firstname CHAR,lastname CHAR,father_firstname CHAR,father_lastname CHAR,soundex CHAR)");
$dbh_rolls->do("CREATE TABLE rolls (id INTEGER PRIMARY KEY AUTOINCREMENT, booth INTEGER, nameparts INTEGER, age INTEGER, gender CHAR, community CHAR, certainty FLOAT, gap FLOAT, name CHAR, fathername CHAR, voter_nameparts INTEGER, voter_community CHAR, voter_certainty FLOAT, voter_gap FLOAT, father_nameparts INTEGER, father_community CHAR, father_certainty FLOAT, father_gap FLOAT, voterid CHAR, rollno INTEGER, ngram INTEGER, revision12 CHAR, revision13 CHAR, revision14 CHAR, booth13 INTEGER)");

$dbh_rolls->do("ALTER TABLE rolls ADD COLUMN foobar INTEGER");

my $sth = $dbh_rolls->prepare("INSERT INTO rolls (rollno, voterid, nameparts, age, gender, community, certainty, gap, name, fathername, voter_nameparts, voter_community, voter_certainty, voter_gap, father_nameparts, father_community, father_certainty, father_gap, ngram, revision12, revision13, booth13,foobar) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,1)");
my $sth2 = $dbh_rolls->prepare("INSERT INTO names (id,firstname,lastname,father_firstname,father_lastname,soundex) VALUES (?,?,?,?,?,?)");
my $sth4 = $dbh_rolls->prepare("SELECT * from names WHERE id = ?");

# Connect to OLD rolls database for this constituency
my $dbh_old = DBI->connect("dbi:SQLite:dbname=rolls.old.sqlite","","",{sqlite_unicode => 1});
my $sth3 = $dbh_old->prepare("SELECT * FROM rolls WHERE voterid = ?");

my $addednew=0;

# Build Database by extracting relevant values
my $voterid; my $rollno; my $reset; my $firstrun = 0;
while (scalar(@raw)>0) {
    $first=shift(@raw);    chomp($first);
    if (scalar(@raw)==0) {last}
    if ($first !~ /^\s*(\d+)\s*$/gs) {next}
    
    $rollno = int($1);
    next if $rollno == 0;
    
  #  tragain1: $second = shift(@raw);
  #  if (scalar(@raw)==0) {last}
  #  $second =~ /\s+(\w\w.*?)\s*$/gs;
  #  $voterid = $1;
  #  goto tragain1 if $second !~ /\d/;
    
    my $voterid='';
    tragain2: $secondhalf = shift (@raw);
    if (scalar(@raw)==0) {last}
    if ($secondhalf !~ /\:/) {$voterid.=$secondhalf; goto tragain2}
  #  $secondhalf =~ /\:\s*(.*?)\s*\n/gs;
  #  $name=$1; 
  #  $name=~s/\.//gs;
  #  $name=~s/\s+/ /gs;
  #  $name =~s/\P{Devanagari}/ /gs;
    $voterid=~s/\s//gs;
    $voterid=~s/\p{Devanagari}//gs;
    
    tragain3: $third=shift(@raw);
    if (scalar(@raw)==0) {last}
    goto tragain3 if $third !~ /\:/;
  #  $third=~/.*?\:\s*(.*?)\s*\n/gs;
  #  $fathername=$1; 
  #  $fathername=~s/\.//gs;
  #  $fathername=~s/\s+/ /gs;
  #  $fathername =~s/\P{Devanagari}/ /gs;
    
    tragain4: $fourth=shift(@raw);
    if (scalar(@raw)==0) {last}
    goto tragain4 if $fourth !~ /\:/;
    tragain5: $fifth=shift(@raw);
    goto tragain5 if $fifth !~ /\:/;
    $fifth=~/.*?(\d+).*?\: (.*?)\s*\n/gs;
    $age=$1; $gender=$2; 
    if ($age=~/[^0-9]/) {$age=''}
    if ($gender =~ /पकरष/) {$gender='m'} else {$gender='f'}

    
#    my @first = $dbh_rolls->selectrow_array("SELECT community FROM rolls WHERE voterid = ?",undef,$voterid);
#   if (scalar(@first)>0) {
#	$dbh_rolls->do("UPDATE rolls SET rollno = ?, foobar = 1 WHERE voterid = ?",undef,$rollno,$voterid);
#	next;
#    }

    my $name = shift(@names);
    my $fathername = shift(@fathernames);
    my $checkage = shift(@checkage);

  #  if ($checkage != $age) {print "DANGEROUS: in $voterid age $age != $checkage; check if real name was OCRed!\n"}
    
    $sth3->execute($voterid);
    
    my $revision14='N';    
    while (my $row=$sth3->fetchrow_hashref) {
	$sth->execute($rollno, $voterid, $row->{nameparts}, $row->{age}+1, $row->{gender}, $row->{community}, $row->{certainty}, $row->{gap}, $row->{name}, $row->{fathername}, $row->{voter_nameparts}, $row->{voter_community}, $row->{voter_certainty}, $row->{voter_gap}, $row->{father_nameparts}, $row->{father_community}, $row->{father_certainty}, $row->{father_gap}, $row->{ngram}, $row->{revision12}, $row->{revision13},  $row->{booth});
	my $id=$dbh_rolls->last_insert_id("","","","");
	$sth4->execute($row->{id});
	while (my $row2=$sth4->fetchrow_hashref) {
	    $sth2->execute($id,$row2->{firstname},$row2->{lastname},$row2->{father_firstname},$row2->{father_lastname},$row2->{soundex});
	}
	$revision14='';
	last;
    }
    
    if ($revision14 ne '') {

#	system("tesseract -psm 4 -l hin --tessdata-dir tesseract $const-$booth-Mother-$rollno.tif $const-$booth-Mother-$rollno >/dev/null");
#	open (FILE,"<:utf8","$const-$booth-Mother-$rollno.txt");
#	my @temp=<FILE>;
#	close (FILE);

	my $temp= `tesseract -psm 4 -l hin --tessdata-dir tesseract $const-$booth-Mother-$rollno.tif stdout`;
	my @temp=split(/\n/,$temp);
	
	my $name=''; my $fathername='';
	foreach my $temp (@temp) {
	    next unless $temp =~ /\p{Devanagari}/;
	    chomp($temp);
	    $temp=~s/^.*?\:\s*//gs;
	    $temp=~s/\P{Devanagari}/ /gs;
	    $temp=~s/\s+/ /gs;
	    $temp=~s/^\s*//gs;
	    $temp=~s/\s*$//gs;
	    if ($name eq '') {$name=$temp}
	    else {$fathername=$temp;last}
	}
	
	my ($community,$certainty,$percent,$voter_community,$voter_certainty,$voter_percent,$father_community,$father_certainty,$father_percent,$voterf,$voterl,$fatherf,$fatherl) = checkname($gender,$name,$fathername);
	my $voter_nameparts=scalar(@$voterf)+scalar(@$voterl);
	my $father_nameparts=scalar(@$fatherf)+scalar(@$fatherl);
	my $nameparts=$voter_nameparts+$father_nameparts;
	$dbh_rolls->do ("INSERT INTO rolls (rollno, voterid, nameparts, age, gender, community, certainty, gap, name, fathername, voter_nameparts, voter_community, voter_certainty, voter_gap, father_nameparts, father_community, father_certainty, father_gap, revision14) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)", undef, $rollno, $voterid, $nameparts, $age, $gender, $community, $certainty, $percent,$name,$fathername,$voter_nameparts,$voter_community,$voter_certainty, $voter_percent,$father_nameparts,$father_community,$father_certainty,$father_percent, $revision14);
	my $id=$dbh_rolls->last_insert_id("","","","");
	foreach my $name (@$voterf) {$dbh_rolls->do("INSERT INTO names (id, firstname, soundex) VALUES (?, ?, ?)",undef,$id, $name, soundex($name));}
	foreach my $name (@$voterl) {$dbh_rolls->do("INSERT INTO names (id, lastname, soundex) VALUES (?, ?, ?)",undef,$id, $name, soundex($name));}
	foreach my $name (@$fatherf) {$dbh_rolls->do("INSERT INTO names (id, father_firstname, soundex) VALUES (?, ?, ?)",undef,$id, $name, soundex($name));}
	foreach my $name (@$fatherl) {$dbh_rolls->do("INSERT INTO names (id, father_lastname, soundex) VALUES (?, ?, ?)",undef,$id, $name, soundex($name));}
	
    }

    system("rm $const-$booth-Mother-$rollno.tif");

}

$sth->finish();
$sth2->finish();
$sth3->finish();
$sth4->finish();

$dbh_rolls->do("DELETE FROM rolls WHERE foobar IS NULL");

$dbh_rolls->sqlite_backup_to_file("rolls.$booth.sqlite");

system("rm $const-$booth-Mother*tif");

$dbh_rolls->disconnect;
$dbh_old->disconnect;

undef($dbh_rolls);
undef($dbh_old);

close(FIFO);
close(PYTHON);
