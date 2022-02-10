#!/usr/bin/perl

use DBI;

my $i=$ARGV[0];

exit if (-e 'integrated');

#
# Compile 2014 rolls into one database if not yet done
#

if (!-e "../../Voter-List-2014/$i/rolls.all.sqlite") {
    
  my @files = `ls ../../Voter-List-2014/$i/rolls.*.sqlite`;
    
    
   my $dbh = DBI->connect("DBI:SQLite:dbname=:memory:", "","", {sqlite_unicode=>1});

   $dbh->do("CREATE TABLE names (id INTEGER, firstname CHAR,lastname CHAR,father_firstname CHAR,father_lastname CHAR,soundex CHAR)");
   $dbh->do("CREATE TABLE rolls (id INTEGER PRIMARY KEY AUTOINCREMENT, booth INTEGER, nameparts INTEGER, age INTEGER, gender CHAR, community CHAR, certainty FLOAT, gap FLOAT, name CHAR, fathername CHAR, voter_nameparts INTEGER, voter_community CHAR, voter_certainty FLOAT, voter_gap FLOAT, father_nameparts INTEGER, father_community CHAR, father_certainty FLOAT, father_gap FLOAT, voterid CHAR, rollno INTEGER)");
   my $sth = $dbh->prepare("INSERT INTO rolls (booth, rollno, voterid, nameparts, age, gender, community, certainty, gap, name, fathername, voter_nameparts, voter_community, voter_certainty, voter_gap, father_nameparts, father_community, father_certainty, father_gap) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)");
   my $sth4 = $dbh->prepare("INSERT INTO names (id,firstname,lastname,father_firstname,father_lastname,soundex) VALUES (?,?,?,?,?,?)");
    
   foreach my $file (@files) {
       next unless $file =~ /\d/gs;#
	chomp($file);
       next if -z $file;
       $file =~ /rolls.(\d+).sqlite/gs;
	my $booth = $1;
	my $dbh2 = DBI->connect("dbi:SQLite:dbname=$file","","",{sqlite_unicode => 1});
	my $sth2 = $dbh2->prepare("SELECT * FROM rolls");
	my $sth3 = $dbh2->prepare("SELECT * FROM names WHERE id = ?");
	$sth2->execute();
	while (my $row=$sth2->fetchrow_hashref) {
	    $sth->execute($booth,$row->{rollno}, $row->{voterid}, $row->{nameparts}, $row->{age}, $row->{gender}, $row->{community}, $row->{certainty}, $row->{gap}, $row->{name}, $row->{fathername}, $row->{voter_nameparts}, $row->{voter_community}, $row->{voter_certainty}, $row->{voter_gap}, $row->{father_nameparts}, $row->{father_community}, $row->{father_certainty}, $row->{father_gap});
	    my $id=$dbh->last_insert_id("","","","");
	    $sth3->execute($row->{id});
	    while (my $row2=$sth3->fetchrow_hashref) {
		$sth4->execute($id,$row2->{firstname},$row2->{lastname},$row2->{father_firstname},$row2->{father_lastname},$row2->{soundex});
	    }
	}
	$sth2->finish();
	$sth3->finish();
	$dbh2->disconnect;
   }

 
   $sth->finish();
   $sth4->finish();

   $dbh->sqlite_backup_to_file("../../Voter-List-2014/$i/rolls.all.sqlite");
   $dbh->disconnect;
    
}

#
# Figure out which booth now was which booth then
#

system("cp ../../Voter-List-2014/$i/$i.sqlite ."); 

my $dbh_booths = DBI->connect("dbi:SQLite:dbname=$i.sqlite","","",{sqlite_unicode => 1});
$dbh_booths->do ("ALTER TABLE booths ADD COLUMN oldbooth INTEGER");
$dbh_booths->do ("ALTER TABLE booths ADD COLUMN revision21_percent_modified FLOAT");
$dbh_booths->do ("ALTER TABLE booths ADD COLUMN revision21_percent_deleted FLOAT");
$dbh_booths->do ("ALTER TABLE booths ADD COLUMN revision21_percent_new FLOAT");
$dbh_booths->do ("UPDATE booths SET oldbooth = booth");
$dbh_booths->do ("UPDATE booths SET booth = NULL");

my $dbh_rolls_all = DBI->connect("dbi:SQLite:dbname=../../Voter-List-2014/$i/rolls.all.sqlite","","",{sqlite_unicode => 1});
$dbh_rolls_all->do("CREATE INDEX namefathernameage ON rolls (name,fathername,age)");
$dbh_rolls_all->do("CREATE INDEX namefathernameonly ON rolls (name,fathername)");
my $sth13 = $dbh_rolls_all->prepare("SELECT * FROM rolls WHERE name LIKE ? AND fathername LIKE ?");
my $sth14 = $dbh_rolls_all->prepare("SELECT * FROM rolls WHERE name LIKE ? AND fathername LIKE ? AND age < ? AND age > ?");

my @booths=`ls rolls.*.sqlite`;

foreach my $booth (@booths) {
   next unless $booth=~/\d/gs;
   $booth=~s/.*?(\d+).*/$1/gs;
  
   print "Process AC $i / booth $booth\n";
    
   my $dbh_rolls = DBI->connect("dbi:SQLite:dbname=rolls.$booth.sqlite","","",{sqlite_unicode => 1});
   $dbh_rolls->do ("ALTER TABLE rolls ADD COLUMN booth14 INTEGER");
   $dbh_rolls->do ("ALTER TABLE rolls ADD COLUMN revision21 CHAR");
   
   my $sth12 = $dbh_rolls->prepare("SELECT * FROM rolls WHERE booth14 IS NULL");
    
   my %voteridmatch;
    
   $sth12->execute();
	while (my $row=$sth12->fetchrow_hashref) {
	    my $agemax = $row->{age}+8;
	    my $agemin = $row->{age}+5;
       $sth13->execute($row->{name}, $row->{fathername});
       my $foundit=0;
		while (my $row13=$sth13->fetchrow_hashref) {
           $voteridmatch{$row->{id}}=$row13->{booth}; $foundit++;
		}  
       if ($foundit>1) {
       
                $sth14->execute($row->{name}, $row->{fathername}, $agemax, $agemin);
                my $founditthen=0;
                while (my $row14=$sth14->fetchrow_hashref) {
                    $voteridmatch{$row->{id}}=$row14->{booth}; $foundit++;
                }  
                if ($founditthen>1) {
       
       undef($voteridmatch{$row->{id}}); print "Multiple finds\n"} # name / fathername found multiple times...
	}}
	
   foreach my $match (keys(%voteridmatch)) {
       $dbh_rolls->do("UPDATE rolls SET booth14 = ?, revision21 = 'M' WHERE id = ?",undef,$voteridmatch{$match},$match);	
   }   
   $dbh_rolls->disconnect();
}


my @booths=`ls rolls.*.sqlite`;
undef my %updates;

foreach my $booth (@booths) {
   next unless $booth=~/\d/gs;
   $booth=~s/.*?(\d+).*/$1/gs;

   my $dbh_rolls = DBI->connect("dbi:SQLite:dbname=rolls.$booth.sqlite","","",{sqlite_unicode => 1});

   $booth=$booth/1;
    
   my $total = $dbh_rolls->selectrow_array("SELECT count(*) FROM rolls WHERE booth14 IS NOT NULL");
   my $max = $dbh_rolls->selectrow_array("SELECT count(*) 'count'  FROM rolls WHERE booth14 IS NOT NULL GROUP BY booth14 ORDER BY count DESC LIMIT 1");
   my $oldbooth = $dbh_rolls->selectrow_array("SELECT booth14 FROM (SELECT booth14,count(*) 'count'  FROM rolls WHERE booth14 IS NOT NULL GROUP BY booth14 ORDER BY count DESC LIMIT 1)");
   my $canupdate = $dbh_booths->selectrow_array("SELECT count(*) FROM booths WHERE oldbooth = ? AND booth IS NULL",undef,$oldbooth);
    
   if ($total == 0) { # new booth, take one
   	$dbh_booths->do("INSERT INTO booths (booth) VALUES (?)",undef,$booth);
   } elsif ($max/$total > 0.7 && $canupdate == 1) { # old booth identified, update! #
	if (!defined($updates{$oldbooth})) {$updates{$oldbooth}=$booth}
	else {$updates{$oldbooth}='unclear'}

	my $filetemp=$oldbooth;
	if ($oldbooth < 10) {$filetemp="00$oldbooth"}
	elsif ($oldbooth < 100) {$filetemp="0$oldbooth"}
	
	my $dbh_rolls_old = DBI->connect("dbi:SQLite:dbname=../../Voter-List-2014/$i/rolls.$filetemp.sqlite","","",{sqlite_unicode => 1});

	my $sthrolls = $dbh_rolls_old->prepare("select sql from sqlite_master where tbl_name='rolls'");
	$sthrolls->execute(); my $runalready=0;
	while (my $row=$sthrolls->fetchrow_hashref) {if ($row->{sql} =~ /rolls/) {$runalready=1;}}
	if ($runalready==0) {$dbh_rolls_old->disconnect; next}
	
	$dbh_rolls->do("UPDATE rolls SET revision21 = 'N' WHERE revision21 IS NULL AND booth14 != ?",undef,$oldbooth);
	my $sth = $dbh_rolls->prepare("INSERT INTO rolls (rollno, voterid, nameparts, age, gender, community, certainty, gap, name, fathername, voter_nameparts, voter_community, voter_certainty, voter_gap, father_nameparts, father_community, father_certainty, father_gap, revision21, booth14) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)");
	my $sth4 = $dbh_rolls->prepare("INSERT INTO names (id,firstname,lastname,father_firstname,father_lastname,soundex) VALUES (?,?,?,?,?,?)");
	my $sth2 = $dbh_rolls_old->prepare("SELECT * FROM rolls");
	my $sth3 = $dbh_rolls_old->prepare("SELECT * FROM names WHERE id = ?");
	$sth2->execute();
	while (my $row=$sth2->fetchrow_hashref) {
	    my $exists = $dbh_rolls->selectrow_array("SELECT count(*) FROM rolls WHERE name LIKE ? AND fathername LIKE ?",undef,$row->{name},$row->{fathername});
	    next if ($exists == 1);
	    $sth->execute($row->{rollno}, $row->{voterid}, $row->{nameparts}, $row->{age}, $row->{gender}, $row->{community}, $row->{certainty}, $row->{gap}, $row->{name}, $row->{fathername}, $row->{voter_nameparts}, $row->{voter_community}, $row->{voter_certainty}, $row->{voter_gap}, $row->{father_nameparts}, $row->{father_community}, $row->{father_certainty}, $row->{father_gap}, 'D', $oldbooth);
	    my $id=$dbh_rolls->last_insert_id("","","","");
	    $sth3->execute($row->{id});
	    while (my $row2=$sth3->fetchrow_hashref) {
	 	$sth4->execute($id,$row2->{firstname},$row2->{lastname},$row2->{father_firstname},$row2->{father_lastname},$row2->{soundex});
	     }
	 }
	 $sth2->finish();
	 $sth3->finish();
	 $sth->finish();
	 $sth4->finish();
	 $dbh_rolls_old->disconnect;
   } else { # old booth not found, create new!
	$dbh_booths->do("INSERT INTO booths (booth) VALUES (?)",undef,$booth);
   }

   $dbh_rolls->disconnect;
}

foreach my $oldbooth (keys(%updates)) {
next  if $oldbooth eq 'unclear';
$dbh_booths->do("UPDATE booths SET booth = ? WHERE oldbooth = ?",undef,$updates{$oldbooth},$oldbooth);
}

$dbh_booths->do("DELETE FROM booths WHERE booth IS NULL");

#
# Clean up
#

$dbh_booths->disconnect();

$dbh_rolls_all->disconnect();

system("touch integrated");
