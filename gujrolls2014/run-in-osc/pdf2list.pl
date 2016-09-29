#!/usr/bin/perl

use DBI;
use utf8;
use HTML::TableExtract;
use WWW::Mechanize;

$dbh = DBI->connect("DBI:SQLite:dbname=:memory:", "","", {sqlite_unicode=>1});
$dbh->sqlite_backup_from_file("names.sqlite");


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
    my $temp = $_[0];
    $temp =~ s/\P{Gujarati}//gs;

    syswrite PYTHON, $temp."\n";
    sysread FIFO, $soundex, 9; 
    chomp($soundex); 
    $soundex{$_[0]}=$soundex;
    return $soundex;
}

# match against devanagari last name
sub devanagarilast {
    my %result;
    my $sth = $dbh->prepare("SELECT community, count(*) 'count' FROM names WHERE name_gu = ? AND namepart = 'l' GROUP BY community");
    $sth->execute($_[0]);
    while (my $row=$sth->fetchrow_hashref) {$result{$row->{community}}=$row->{count};}
    $sth->finish ();
    return %result;
}

# match against devanagari first name_gu gendered male
sub devanagarifirstm {
    my %result;
    my $sth = $dbh->prepare("SELECT community, count(*) 'count' FROM names WHERE name_gu = ? AND namepart = 'f' AND gender = 'm' GROUP BY community");
    $sth->execute($_[0]);
    while (my $row=$sth->fetchrow_hashref) {$result{$row->{community}}=$row->{count};}
    $sth->finish ();
    return %result;
}

# match against devanagari first name_gu gendered female
sub devanagarifirstf {
    my %result;
    my $sth = $dbh->prepare("SELECT community, count(*) 'count' FROM names WHERE name_gu = ? AND namepart = 'f' AND gender = 'f' GROUP BY community");
    $sth->execute($_[0]);
    while (my $row=$sth->fetchrow_hashref) {$result{$row->{community}}=$row->{count};}
    $sth->finish ();
    return %result;
}

# match against devanagari first name
sub devanagarifirst {
    my %result;
    my $sth = $dbh->prepare("SELECT community, count(*) 'count' FROM names WHERE name_gu = ? AND namepart = 'f' GROUP BY community");
    $sth->execute($_[0]);
    while (my $row=$sth->fetchrow_hashref) {$result{$row->{community}}=$row->{count};}
    $sth->finish ();
    return %result;
}

# match against soundex last name
sub soundexlast {
    my %result;
    my $sth = $dbh->prepare("SELECT community, count(*) 'count' FROM names WHERE soundex_gu = ? AND namepart = 'l' GROUP BY community");
    $sth->execute($_[0]);
    while (my $row=$sth->fetchrow_hashref) {$result{$row->{community}}=$row->{count};}
    $sth->finish ();
    return %result;
}

# match against soundex first name gendered male
sub soundexfirstm {
    my %result;
    my $sth = $dbh->prepare("SELECT community, count(*) 'count' FROM names WHERE soundex_gu = ? AND namepart = 'f' AND gender = 'm' GROUP BY community");
    $sth->execute($_[0]);
    while (my $row=$sth->fetchrow_hashref) {$result{$row->{community}}=$row->{count};}
    $sth->finish ();
    return %result;
}

# match against soundex first name gendered female
sub soundexfirstf {
    my %result;
    my $sth = $dbh->prepare("SELECT community, count(*) 'count' FROM names WHERE soundex_gu = ? AND namepart = 'f' AND gender = 'f' GROUP BY community");
    $sth->execute($_[0]);
    while (my $row=$sth->fetchrow_hashref) {$result{$row->{community}}=$row->{count};}
    $sth->finish ();
    return %result;
}

# match against soundex first name
sub soundexfirst {
    my %result;
    my $sth = $dbh->prepare("SELECT community, count(*) 'count' FROM names WHERE soundex_gu = ? AND namepart = 'f' GROUP BY community");
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

#    $votername=~s/ \w / /gs;
#    $votername=~s/ \w / /gs;
#    $votername=~s/^\w //gs;
#    $votername=~s/ \w$//gs;

#    $voterfathername=~s/ \w / /gs;
#    $voterfathername=~s/ \w / /gs;
#    $voterfathername=~s/^\w //gs;
#    $voterfathername=~s/ \w$//gs;
    
    # calculate soundex codes and separate first and lastnames list
    my @names=split(/ /,$votername);

#    print "Original names: ".join(" - ", @names)."\n";

    
    my $sth = $dbh->prepare("SELECT name_gu,community FROM names WHERE name_gu IS NOT NULL AND namepart = 'f' AND COMMUNITY IS NOT NULL ORDER BY LENGTH(name_gu) DESC");
    $sth->execute();
    my %com; my @allfirstnames;
    while (my $row=$sth->fetchrow_hashref) 	    
    {
	next if $row->{name_gu} !~ /\X\X\X/;
	push(@allfirstnames,$row->{name_gu});
	$com{$row->{name_gu}}=$row->{community};
    }
    $sth->finish();
#    my @allfirstnames = sort {while ($a =~ /\X/g) { $tempa++ }; while ($b =~ /\X/g) {$tempb++}; $tempa <=> $tempb} @allfirstnamesa;
    
    my @namestemp = @names; @names = ();
    foreach my $name (@namestemp) { # check gujarati compound names!
	$soundex{$name}=soundex($name);
	if ($name !~ /\X\X/) {push (@names,$name);next}
	my @first = $dbh->selectrow_array("SELECT community FROM names WHERE soundex_gu = ? AND namepart = 'f'",undef,$soundex{$name});
	if (scalar(@first)==0) {
	    my $founditna=0;
	    foreach my $allfirstname (@allfirstnames) {
#		print "$allfirstname\n";
		if ($name =~ /^$allfirstname\X\X\X/) {
		    my $oldname = $name;
		    $name =~ s/^$allfirstname//;
		    my @first = $dbh->selectrow_array("SELECT community FROM names WHERE soundex_gu = ? AND namepart = 'f'",undef,$soundex{$name});
		    if (scalar(@first)>0 && $first[0] ne $com{$allfirstname}) {next}
		    push (@names,$allfirstname);	
		    push (@names,$name);
		    $soundex{$name}=soundex($name);	
		    $soundex{$allfirstname}=soundex($allfirstname); 
		  #  print "Split $oldname into $allfirstname - $name\n";
		    $dbh->do("INSERT INTO names (name_gu,soundex_gu,namepart,community) VALUES (?,?,?,?)",undef,$oldname,$soundex{$oldname},'f',$com{$allfirstname});
		    $founditna = 1;
		    last;
		} elsif ($name =~ /\X\X\X$allfirstname$/) {
		    my $oldname = $name;
		    $name =~ s/$allfirstname$//;
		    my @first = $dbh->selectrow_array("SELECT community FROM names WHERE soundex_gu = ? AND namepart = 'f'",undef,$soundex{$name});
		    if (scalar(@first)>0 && $first[0] ne $com{$allfirstname}) {next}
		    push (@names,$allfirstname);
		    push (@names,$name);
		    $soundex{$name}=soundex($name);	
		    $soundex{$allfirstname}=soundex($allfirstname); 
		   # print "Split $oldname into $name - $allfirstname\n";
		    $dbh->do("INSERT INTO names (name_gu,soundex_gu,namepart,community) VALUES (?,?,?,?)",undef,$oldname,$soundex{$oldname},'f',$com{$allfirstname});
		    $founditna = 1;
		    last;
		}
	    }
	    if ($founditna == 0) {push (@names,$name)}
	} else {
	    push (@names,$name)
	}
    }

#    print "Split names: ".join(" - ", @names)."\n";
    
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
    my @last = $dbh->selectrow_array("SELECT community FROM names WHERE soundex_gu = ? AND namepart = 'l'",undef,$soundex{$name});
    if (scalar(@last)<1) {
	my @first = $dbh->selectrow_array("SELECT community FROM names WHERE soundex_gu = ? AND namepart = 'f'",undef,$soundex{$name});
	if (scalar(@first)>0) {push(@firstnames,$name)}
	else {push(@lastnames,$name)}
    } else {push(@lastnames,$name)}
    
    
  foreach my $name (@names) { # Favour firstname if in doubt for all other names
#	next if (length($name) < 2);
#	if ($name=~/उद्दीन$/) {$name=~s/उद्दीन$//s; push(@lastnames,'उद्दीन')} # CHECK FOR MUSLIM LAST NAME CONJUNCTS -uddin and -ullah
#	elsif ($name=~/उदीन$/) {$name=~s/उदीन$//s; push(@lastnames,'उद्दीन')}
#	elsif ($name=~/उल्लह$/) {$name=~s/उल्लह$//s; push(@lastnames,'उल्लाह')}
#	elsif ($name=~/\x{0941}द्दीन$/) {$name=~s/\x{0941}द्दीन$//s; push(@lastnames,'उद्दीन')}
#	elsif ($name=~/\x{0941}दीन$/) {$name=~s/\x{0941}दीन$//s; push(@lastnames,'उद्दीन')}
#	elsif ($name=~/\x{0941}ल्लह$/) {$name=~s/\x{0941}ल्लह$//s; push(@lastnames,'उल्लाह')}
	
#	$soundex{$name}=soundex($name);
      my @first = $dbh->selectrow_array("SELECT community FROM names WHERE soundex_gu = ? AND namepart = 'f'",undef,$soundex{$name});
      if (scalar(@first)<1) {
	  my @last = $dbh->selectrow_array("SELECT community FROM names WHERE soundex_gu = ? AND namepart = 'l'",undef,$soundex{$name});
	  if (scalar(@last)>0) {push(@lastnames,$name)}
	  else {push(@firstnames,$name)}
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
#	if ($jaga1==0) {push(@firstnames,$lastname)}
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

#
# Iterate through all PDFs
#

my $file=$ARGV[0];

chomp $file;

# Establish WWW::Mechanize
my $ua = WWW::Mechanize->new(agent=>'Mozilla/5.0 (X11; U; Linux i686; de; rv:1.9.0.16)',cookie_jar=>{},onerror=>undef,stack_depth=>5);

#
# This is a motherroll
#
$file =~ /(\d\d\d)-(\d\d\d)/gs;
$constituency=$1/1;
$booth=$2;

# Get Number of pages and take care that first and last are not used - they contain other stuff
my $pages=`pdfinfo $file`;
$pages=~s/.*?Pages:\s+(\d+).*/$1/gs;
$pages--;

next if ($pages==0 or !defined($pages));

# Extract the three data columns and re-load the respective data, putting it all into @raw, deleting temp files
system("./pdftotext -nopgbrk -f 3 -l $pages  -x 68 -y 128 -W 173 -H 965 -layout -r 100 $file out1.txt");
system("./pdftotext -nopgbrk -f 3 -l $pages  -x 241 -y 128 -W 173 -H 965 -layout -r 100 $file out2.txt");
system("./pdftotext -nopgbrk -f 3 -l $pages  -x 414 -y 128 -W 173 -H 965 -layout -r 100 $file out3.txt");
system("./pdftotext -nopgbrk -f 3 -l $pages  -x 587 -y 128 -W 173 -H 965 -layout -r 100 $file out4.txt");

open (FILE,"<:utf8","out1.txt");
my @raw1=<FILE>;
close (FILE);
open (FILE,"<:utf8","out2.txt");
my @raw2=<FILE>;
close (FILE);
open (FILE,"<:utf8","out3.txt");
my @raw3=<FILE>;
close (FILE);
open (FILE,"<:utf8","out4.txt");
my @raw4=<FILE>;
close (FILE);

my $reset;

my @raw=(@raw1,@raw2,@raw3,@raw4);

system("rm -f out1.txt out2.txt out3.txt out4.txt");

exit if (scalar(@raw)==0);

# Create rolls.X.sqlite to put in all the necessary stuff

$file =~ s/.pdf$//gs;
my $dbh_rolls = DBI->connect("dbi:SQLite:dbname=:memory:","","",{sqlite_unicode => 1});
if (-e "$file.sqlite") {$dbh_rolls->sqlite_backup_from_file("$file.sqlite");}

$dbh_rolls->do ("CREATE TABLE rolls (id INTEGER PRIMARY KEY AUTOINCREMENT, rollno INTEGER, voterid CHAR, nameparts INTEGER, age INTEGER, gender CHAR, community CHAR, certainty FLOAT, gap FLOAT, name CHAR, fathername CHAR, voter_nameparts INTEGER, voter_community CHAR, voter_certainty FLOAT, voter_gap FLOAT, father_nameparts INTEGER, father_community CHAR, father_certainty FLOAT, father_gap FLOAT)");
$dbh_rolls->do ("CREATE TABLE names (id INTEGER, firstname CHAR,lastname CHAR,father_firstname CHAR,father_lastname CHAR,soundex CHAR)");

$dbh_rolls->do ("UPDATE rolls SET rollno = NULL");

my $sth = $dbh_rolls->prepare("SELECT id FROM rolls WHERE voterid = ? AND name IS NOT NULL AND name != ''");

$dbh_rolls->begin_work;

# Build Database by extracting relevant values
my $voterid; my $entrycount=10000; my $addednew=0; my $crashedwww=0;
line: while (scalar(@raw)>0) {
    $voterid=''; $rollno='';
    
    tragain2:
      if (scalar(@raw)==0) {last line}
    $first=shift(@raw);    
    if ($first !~ /\:\s*(.*?)\s*$/gs) {
	if ($first =~ /\d\d\d/) {$voterid=$first; }
	goto tragain2;
    } # filter out weird stuff
    
    next line if ($voterid eq '');
    
    $entrycount++;
    
    $voterid =~ /^\s*(\d+)/gs;
    $rollno = $1;
    if ($rollno == 0) {$rollno=$entrycount}
    
    eval $voterid =~ s/^\s*\d+//gs;
    eval $voterid =~ s/[^A-Z0-9\/]//gs; 
        
    tragain3: 
      if (scalar(@raw)==0) {last line}  
    $third=shift(@raw);
    goto tragain3 if $third !~ /\:/;
 
 
    tragain4:
      if (scalar(@raw)==0) {last line}  
    $fourth=shift(@raw);
    goto tragain4 if $fourth !~ /\:/;
    tragain5: 
      if (scalar(@raw)==0) {last line}  
    $fifth=shift(@raw);
    goto tragain5 if $fifth !~ /\:/;
    eval $fifth=~/.*?(\d+).*?\: (.*?)\s*\n/gs;
    $age=$1; $gender=$2; 
    eval {if ($age=~/[^0-9]/) {$age=''}};
    eval {$gender=~s/\x{093f}(.)/$1\x{093f}/gs; $gender=~s/;/,/gs};
    eval {if ($gender =~ /ી/) {$gender='f'} elsif ($gender =~ /ષ/) {$gender='m'} else {$gender=undef}};
    
    $sth->execute($voterid);
    while (my $row=$sth->fetchrow_hashref) {
	$dbh_rolls->do("UPDATE rolls SET rollno = ?, gender = ? WHERE id = ?",undef,$rollno,$gender,$row->{id});
	next line;
    }

    my $name=''; my $fathername='';
    unless ($voterid eq '') {
	
	# VERSION A: use previously stored json data
	
#	$sth2->execute($voterid);
#	while (my $row2=$sth2->fetchrow_hashref) {
#	    my $json = $row2->{json};
#	    $json=~/rln name v1\":\"(.*?)\"/gs;
#	    $fathername = $1;
#	    $json=~/name v1\":\"(.*?)\"/gs;
#	    $name = $1;
#	    $json=~/gender\":\"(.*?)\"/gs;
#	    $gender = lc($1);
#	}
	
#	if ($name eq '') {
	    
	    # VERSION B: use Gujarati website

	$ua->get("http://erms.gujarat.gov.in/ceo-gujarat/master/Elector-Search-Dist-AC-Serial.aspx");
	my $reruncount=0;
	rerun: unless ($ua->form_name('form1')) {
	    $reruncount++; 
	    if ($reruncount==10) {$crashedwww=1; goto finishcomplete} 
	    else {sleep 10; $ua->get("http://erms.gujarat.gov.in/ceo-gujarat/master/Elector-Search-Dist-AC-Serial.aspx"); goto rerun}
	}
	$ua->field('txtIDCardNo',$voterid);
	$ua->field('rblSearchType',1);
	$ua->field('drpDistrict',7);
	$ua->click('btnIDCard'); # SOMEHOW ASP.NET pages only work this way, not with $ua->form_submit !
	
	    my $te = HTML::TableExtract->new(attribs=>{id => 'gdGuj'});
	    $te->parse($ua->content);
	    
	    my $table;
	    
	    if ($table = $te->first_table_found) {
		my @temp = $table->rows;
		if (scalar(@temp) > 1) {	
		    $voteridtable = $table->cell(1,11);
		    if ($voteridtable ne $voterid && $reset <5) {$reset++; $ua->get("http://erms.gujarat.gov.in/ceo-gujarat/master/Elector-Search-Dist-AC-Serial.aspx");print "Reset crawler for mismatch\n";goto rerun}
		    elsif ($voteridtable ne $voterid) {print "Permanent mismatch between $5 and $voterid\n";next}
		    $name = $table->cell(1,7).' '.$table->cell(1,8).' '.$table->cell(1,6);
		    $fathername = $table->cell(1,6);
		    $reset=0;
		}
	    }
#	}

    }
    moveon:
    
    $addednew++;
        
    # Remove bhai/behn suffix 
    
    my $nametemp=$name;
    my $fathernametemp=$fathername;
    if ($nametemp =~ /ભાઇ$/) { 	$nametemp=~s/ભાઇ$//gs; }
    elsif ($nametemp =~ /બેન$/) {		$nametemp=~s/બેન$//gs; }
	if ($fathernametemp =~ /	ભાઇ\s/) { 	$fathernametemp=~s/ભાઇ / /gs; }
    elsif ($fathernametemp =~ /બેન\s/) { 	$fathernametemp=~s/બેન / /s; }
    
    my ($community,$certainty,$percent,$voter_community,$voter_certainty,$voter_percent,$father_community,$father_certainty,$father_percent,$voterf,$voterl,$fatherf,$fatherl) = checkname($gender,$nametemp,$fathernametemp);
    my $voter_nameparts=scalar(@$voterf)+scalar(@$voterl);
    my $father_nameparts=scalar(@$fatherf)+scalar(@$fatherl);
    my $nameparts=$voter_nameparts+$father_nameparts;
    $dbh_rolls->do ("INSERT INTO rolls (rollno, voterid, nameparts, age, gender, community, certainty, gap, name, fathername, voter_nameparts, voter_community, voter_certainty, voter_gap, father_nameparts, father_community, father_certainty, father_gap) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)", undef, $rollno, $voterid, $nameparts, $age, $gender, $community, $certainty, $percent,$name,$fathername,$voter_nameparts,$voter_community,$voter_certainty, $voter_percent,$father_nameparts,$father_community,$father_certainty,$father_percent);
    my $id=$dbh_rolls->last_insert_id("","","","");
    foreach my $name (@$voterf) {$dbh_rolls->do("INSERT INTO names (id, firstname, soundex) VALUES (?, ?, ?)",undef,$id, $name, soundex($name));}
    foreach my $name (@$voterl) {$dbh_rolls->do("INSERT INTO names (id, lastname, soundex) VALUES (?, ?, ?)",undef,$id, $name, soundex($name));}
    foreach my $name (@$fatherf) {$dbh_rolls->do("INSERT INTO names (id, father_firstname, soundex) VALUES (?, ?, ?)",undef,$id, $name, soundex($name));}
    foreach my $name (@$fatherl) {$dbh_rolls->do("INSERT INTO names (id, father_lastname, soundex) VALUES (?, ?, ?)",undef,$id, $name, soundex($name));}
    
}

finishcomplete:
  
$dbh_rolls->do("DELETE FROM rolls WHERE rollno IS NULL");
$dbh_rolls->do("DELETE FROM names WHERE id NOT IN (SELECT id FROM rolls)");

# $dbh_rolls->do("DROP TABLE raw");

$dbh_rolls->commit;

if ($crashedwww==0) {
    print "$file.sqlite: added $addednew entries\n";
    system("rm $file.sqlite.crashed");
} else {
    print "$file.sqlite: added $addednew entries but CRASHED on the way - rerun requested\n";
    system("touch $file.sqlite.crashed");
}

$dbh_rolls->sqlite_backup_to_file("$file.sqlite");

$dbh_rolls->disconnect;
$dbh->disconnect;
undef($dbh_rolls);
undef($dbh);

close(FIFO);
close(PYTHON);


