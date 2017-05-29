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

open(PYTHON,"|python3.4 -u soundex.py");
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
    my $sth = $dbh->prepare("SELECT community, count(*) 'count' FROM names WHERE name_bn = ? AND namepart = 'l' GROUP BY community");
    $sth->execute($_[0]);
    while (my $row=$sth->fetchrow_hashref) {$result{$row->{community}}=$row->{count};}
    $sth->finish ();
    return %result;
}

# match against devanagari first name_bn gendered male
sub devanagarifirstm {
    my %result;
    my $sth = $dbh->prepare("SELECT community, count(*) 'count' FROM names WHERE name_bn = ? AND namepart = 'f' AND gender = 'm' GROUP BY community");
    $sth->execute($_[0]);
    while (my $row=$sth->fetchrow_hashref) {$result{$row->{community}}=$row->{count};}
    $sth->finish ();
    return %result;
}

# match against devanagari first name_bn gendered female
sub devanagarifirstf {
    my %result;
    my $sth = $dbh->prepare("SELECT community, count(*) 'count' FROM names WHERE name_bn = ? AND namepart = 'f' AND gender = 'f' GROUP BY community");
    $sth->execute($_[0]);
    while (my $row=$sth->fetchrow_hashref) {$result{$row->{community}}=$row->{count};}
    $sth->finish ();
    return %result;
}

# match against devanagari first name
sub devanagarifirst {
    my %result;
    my $sth = $dbh->prepare("SELECT community, count(*) 'count' FROM names WHERE name_bn = ? AND namepart = 'f' GROUP BY community");
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
#    if ($name=~/उद्दीन$/) {$name=~s/उद्दीन$//s; push(@lastnames,'उद्दीन')} # CHECK FOR MUSLIM LAST NAME CONJUNCTS -uddin and -ullah
#    elsif ($name=~/उदीन$/) {$name=~s/उदीन$//s; push(@lastnames,'उद्दीन')}
#    elsif ($name=~/उल्लह$/) {$name=~s/उल्लह$//s; push(@lastnames,'उल्लाह')}
#    elsif ($name=~/\x{0941}द्दीन$/) {$name=~s/\x{0941}द्दीन$//s; push(@lastnames,'उद्दीन')}
#    elsif ($name=~/\x{0941}दीन$/) {$name=~s/\x{0941}दीन$//s; push(@lastnames,'उद्दीन')}
#    elsif ($name=~/\x{0941}ल्लह$/) {$name=~s/\x{0941}ल्लह$//s; push(@lastnames,'उल्लाह')}
    $soundex{$name}=soundex($name);
    my @last = $dbh->selectrow_array("SELECT count(*) FROM names WHERE name_soundex = ? AND namepart = 'l'",undef,$soundex{$name});
    if (scalar(@last)<1) {
	my @first = $dbh->selectrow_array("SELECT count(*) FROM names WHERE name_soundex = ? AND namepart = 'f'",undef,$soundex{$name});
	if (scalar(@first)>0) {push(@firstnames,$name)}
    } else {push(@lastnames,$name)}
    
    foreach my $name (@names) { # Favour firstname if in doubt for all other names
#	next if (length($name) < 2);
#	if ($name=~/उद्दीन$/) {$name=~s/उद्दीन$//s; push(@lastnames,'उद्दीन')} # CHECK FOR MUSLIM LAST NAME CONJUNCTS -uddin and -ullah#
#	elsif ($name=~/उदीन$/) {$name=~s/उदीन$//s; push(@lastnames,'उद्दीन')}#
#	elsif ($name=~/उल्लह$/) {$name=~s/उल्लह$//s; push(@lastnames,'उल्लाह')}
#	elsif ($name=~/\x{0941}द्दीन$/) {$name=~s/\x{0941}द्दीन$//s; push(@lastnames,'उद्दीन')}
#	elsif ($name=~/\x{0941}दीन$/) {$name=~s/\x{0941}दीन$//s; push(@lastnames,'उद्दीन')}
#	elsif ($name=~/\x{0941}ल्लह$/) {$name=~s/\x{0941}ल्लह$//s; push(@lastnames,'उल्लाह')}
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
    
#    if ($name=~/उद्दीन$/) {$name=~s/उद्दीन$//s; push(@lastnames,'उद्दीन')} # CHECK FOR MUSLIM LAST NAME CONJUNCTS -uddin and -ullah
#    elsif ($name=~/उदीन$/) {$name=~s/उदीन$//s; push(@lastnames,'उद्दीन')}
#    elsif ($name=~/उल्लह$/) {$name=~s/उल्लह$//s; push(@lastnames,'उल्लाह')}
#    elsif ($name=~/\x{0941}द्दीन$/) {$name=~s/\x{0941}द्दीन$//s; push(@lastnames,'उद्दीन')}
#    elsif ($name=~/\x{0941}दीन$/) {$name=~s/\x{0941}दीन$//s; push(@lastnames,'उद्दीन')}
#    elsif ($name=~/\x{0941}ल्लह$/) {$name=~s/\x{0941}ल्लह$//s; push(@lastnames,'उल्लाह')}
    $soundex{$name}=soundex($name);
    my @last = $dbh->selectrow_array("SELECT count(*) FROM names WHERE name_soundex = ? AND namepart = 'l'",undef,$soundex{$name});
# my $first = $dbh->selectrow_array("SELECT count(*) FROM names WHERE name_soundex = ? AND namepart = 'f'",undef,$soundex{$name});
    if (scalar(@last)<1) {
	my @first = $dbh->selectrow_array("SELECT count(*) FROM names WHERE name_soundex = ? AND namepart = 'f'",undef,$soundex{$name});
	if (scalar(@first)>0) {push(@firstnames,$name)}
    } else {push(@lastnames,$name)}
    foreach my $name (@names) { # Favour firstname if in doubt for all other names
#	next if (length($name)<2);
#	if ($name=~/उद्दीन$/) {$name=~s/उद्दीन$//s; push(@lastnames,'उद्दीन')} # CHECK FOR MUSLIM LAST NAME CONJUNCTS -uddin and -ullah
#	elsif ($name=~/उदीन$/) {$name=~s/उदीन$//s; push(@lastnames,'उद्दीन')}
#	elsif ($name=~/उल्लह$/) {$name=~s/उल्लह$//s; push(@lastnames,'उल्लाह')}
#	elsif ($name=~/\x{0941}द्दीन$/) {$name=~s/\x{0941}द्दीन$//s; push(@lastnames,'उद्दीन')}
#	elsif ($name=~/\x{0941}दीन$/) {$name=~s/\x{0941}दीन$//s; push(@lastnames,'उद्दीन')}
#	elsif ($name=~/\x{0941}ल्लह$/) {$name=~s/\x{0941}ल्लह$//s; push(@lastnames,'उल्लाह')}

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

# Connect to database
my $dbh_rolls = DBI->connect("DBI:SQLite:dbname=:memory:", "","", {sqlite_unicode=>1});

$dbh_rolls->do("CREATE TABLE names (id INTEGER, firstname CHAR,lastname CHAR,father_firstname CHAR,father_lastname CHAR,soundex CHAR)");
$dbh_rolls->do("CREATE TABLE rolls (id INTEGER PRIMARY KEY AUTOINCREMENT, constituency INTEGER, booth INTEGER, nameparts INTEGER, age INTEGER, gender CHAR, community CHAR, certainty FLOAT, gap FLOAT, name CHAR, fathername CHAR, voter_nameparts INTEGER, voter_community CHAR, voter_certainty FLOAT, voter_gap FLOAT, father_nameparts INTEGER, father_community CHAR, father_certainty FLOAT, father_gap FLOAT, voterid CHAR, rollno INTEGER, ngram INTEGER)");

# Extract table structure, with settings that allow me to filter out relevant entries (ie voter cells)
my $pagecount=`gs -q -dNODISPLAY -c "($file) (r) file runpdfbegin pdfpagecount = quit" `;
chomp($pagecount);

# $pagecount=3;

my $xml='';
for ($page=2;$page<$pagecount;$page++) {
    $xml .= `PYTHONPATH=/home/area-mnni/rsusewind/lib/python2.6/site-packages:/system/software/linux-x86_64/lib/python2.6/site-packages python2.6 /home/area-mnni/rsusewind/bin/pdf-table-extract -i $file -p $page -r 300 -l 0.5 -t cells_xml`;
}
my @xml=split(/<\/cell>/,$xml);

# Circulate through all cells
foreach my $cell (@xml) {
    $cell =~ s/<cell.*?\/>//gs;
    
    next unless $cell =~ /\d\d\d\d\d\d/;
   
    $cell =~ /p="(\d+)"/;
    my $page = $1;
    $cell =~ /x="(\d+)"/;
    my $left = $1; 
    $cell =~ /y="(\d+)"/;
    my $right = $1; 
    $cell =~ /h="(\d+)"/;
    my $bottom = $1; 
    $cell =~ /w="(\d+)"/;
    my $top = $1; 

    $cell =~ />.*?(\d+) ([^ ]+) /gs;
    my $rollno=$1; my $voterid=$2;
    $voterid=~s/^\s+//s;
    $voterid=~s/\s$//s;

next unless $voterid=~/\d\d\d\d\d\d/;

    my $secondcell=$cell; # weird perl bug?
    $secondcell =~ /(\d+)[^0-9]*?$/gs;
    my $age=$1;
    
    my $gender='';
    if ($cell =~ /নপব\s*$/gs) {$gender='m'} else {$gender='f'}

    my $width=$right-$left;
    my $height=$bottom-$top;
    my $bufferx=int($left/300*72);
    my $buffery=int(842-($top+$height)/300*72);
    
    next if $height < 200;
    
    system("gs -q -r300 -dFirstPage=$page -dLastPage=$page -sDEVICE=tiffgray -sCompression=lzw -o $const-$booth-$rollno.tif -g".$width."x".$height." -c '<</Install {-$bufferx -$buffery translate}>> setpagedevice' -f $file");
    system("tiffcrop -U px -z 92,52,770,189  $const-$booth-$rollno.tif $const-$booth-$rollno-ocr.tif");
    
    my $name='';
    my $fathername='';
    
    my $shades = `convert $const-$booth-$rollno.tif -unique-colors -depth 8 txt: | wc -l`;
    unless ($shades > 10) { # not pure black & white, i.e. "deleted" overlay or some such
 	
	my $temp= `tesseract -psm 4 -l ben --tessdata-dir /home/area-mnni/rsusewind/share/tessdata $const-$booth-$rollno-ocr.tif stdout`;

	my @temp=split(/\n/gs,$temp);

	foreach my $temp (@temp) {
	    $temp=~s/^.*?[:]\s+//gs;
	    $temp=~s/[^\p{Bengali}\s]//gs;
	    $temp=~s/\s+/ /gs;
	    $temp=~s/\s*$//gs;
	    if ($name eq '') {$name=$temp}
	    else {$fathername=$temp;last}
	}
	
        my ($community,$certainty,$percent,$voter_community,$voter_certainty,$voter_percent,$father_community,$father_certainty,$father_percent,$voterf,$voterl,$fatherf,$fatherl) = checkname($gender,$name,$fathername);
	my $voter_nameparts=scalar(@$voterf)+scalar(@$voterl);
	my $father_nameparts=scalar(@$fatherf)+scalar(@$fatherl);
	my $nameparts=$voter_nameparts+$father_nameparts;
	$dbh_rolls->do ("INSERT INTO rolls (constituency, booth, rollno, voterid, nameparts, age, gender, community, certainty, gap, name, fathername, voter_nameparts, voter_community, voter_certainty, voter_gap, father_nameparts, father_community, father_certainty, father_gap) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?,  ?, ?, ?, ?, ?, ?, ?)", undef, $constituency, $booth, $rollno, $voterid, $nameparts, $age, $gender, $community, $certainty, $percent,$name,$fathername,$voter_nameparts,$voter_community,$voter_certainty, $voter_percent,$father_nameparts,$father_community,$father_certainty,$father_percent);
	my $id=$dbh_rolls->last_insert_id("","","","");
	foreach my $name (@$voterf) {$dbh_rolls->do("INSERT INTO names (id, firstname, soundex) VALUES (?, ?, ?)",undef,$id, $name, soundex($name));}
	foreach my $name (@$voterl) {$dbh_rolls->do("INSERT INTO names (id, lastname, soundex) VALUES (?, ?, ?)",undef,$id, $name, soundex($name));}
	foreach my $name (@$fatherf) {$dbh_rolls->do("INSERT INTO names (id, father_firstname, soundex) VALUES (?, ?, ?)",undef,$id, $name, soundex($name));}
	foreach my $name (@$fatherl) {$dbh_rolls->do("INSERT INTO names (id, father_lastname, soundex) VALUES (?, ?, ?)",undef,$id, $name, soundex($name));}
	
    }
    
    system("rm $const-$booth-$rollno.tif $const-$booth-$rollno-ocr.tif");

}

$dbh_rolls->sqlite_backup_to_file("rolls.$booth.sqlite");

$dbh_rolls->disconnect;
undef($dbh_rolls);

close(FIFO);
close(PYTHON);
