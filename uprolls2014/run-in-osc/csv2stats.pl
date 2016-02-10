#!/usr/bin/perl

my $constituency=$ARGV[0];

#
# Create booths.sqlite with aggregated data in booths for sp and aggregated data in names for riot-names
#

use DBI;
use SQLite::More;

my $dbh_booths = DBI->connect("dbi:SQLite:dbname=$constituency.sqlite","","",{sqlite_unicode => 1});
$dbh_booths->do ("ALTER TABLE booths ADD COLUMN revision14_percent_modified FLOAT");
$dbh_booths->do ("ALTER TABLE booths ADD COLUMN revision14_percent_deleted FLOAT");
$dbh_booths->do ("ALTER TABLE booths ADD COLUMN revision14_percent_new FLOAT");

$dbh_booths->do ("ALTER TABLE booths ADD COLUMN lastupdate CHAR");
$dbh_booths->do ("ALTER TABLE booths ADD COLUMN station_name CHAR");
$dbh_booths->do ("ALTER TABLE booths ADD COLUMN oldbooth INTEGER");

$dbh_booths->do ("UPDATE booths SET oldbooth = booth WHERE oldbooth IS NULL");
$dbh_booths->do ("UPDATE booths SET booth = NULL");

$dbh_booths->begin_work;

#
# Merge old and new booths
#

my @booths=`ls rolls.*.sqlite`;

foreach my $booth (@booths) {
    $booth=~s/.*?(\d+).*/$1/gs;

    my $dbh_rolls = DBI->connect("dbi:SQLite:dbname=rolls.$booth.sqlite","","",{sqlite_unicode => 1});

    $booth=$booth/1;
    
    my $total = $dbh_rolls->selectrow_array("SELECT count(*) FROM rolls WHERE booth13 IS NOT NULL");
    my $max = $dbh_rolls->selectrow_array("SELECT count(*) 'count'  FROM rolls WHERE booth13 IS NOT NULL GROUP BY booth13 ORDER BY count DESC LIMIT 1");
    my $oldbooth = $dbh_rolls->selectrow_array("SELECT booth13 FROM (SELECT booth13,count(*) 'count'  FROM rolls WHERE booth13 IS NOT NULL GROUP BY booth13 ORDER BY count DESC LIMIT 1)");
    my $canupdate = $dbh_booths->selectrow_array("SELECT count(*) FROM booths WHERE oldbooth = ? AND booth IS NULL",undef,$oldbooth);
    
    undef my %updates;
    
    if ($total == 0) { # new booth, take one
    	$dbh_booths->do("INSERT INTO booths (booth) VALUES (?)",undef,$booth);
    } elsif ($max/$total > 0.8 && $canupdate == 1) { # old booth identified, update! 
	if (!defined($updates{$oldbooth})) {$updates{$oldbooth}=$booth}
	else {$updates{$oldbooth}='unclear'}

	my $filetemp=$oldbooth;
	if ($oldbooth < 10) {$filetemp="00$oldbooth"}
	elsif ($oldbooth < 100) {$filetemp="0$oldbooth"}
	
	my $dbh_rolls_old = DBI->connect("dbi:SQLite:dbname=/data/area-mnni/rsusewind/up/2013/$constituency/rolls.$filetemp.sqlite","","",{sqlite_unicode => 1});

	my $sthrolls = $dbh_rolls_old->prepare("select sql from sqlite_master where tbl_name='rolls'");
	$sthrolls->execute(); my $runalready=0;
	while (my $row=$sthrolls->fetchrow_hashref) {if ($row->{sql} =~ /rolls/) {$runalready=1;}}
	if ($runalready==0) {$dbh_rolls_old->disconnect; next}
	
	$dbh_rolls->do("UPDATE rolls SET revision14 = 'N' WHERE revision14 IS NULL AND booth13 != ?",undef,$oldbooth);
	my $sth = $dbh_rolls->prepare("INSERT INTO rolls (rollno, voterid, nameparts, age, gender, community, certainty, gap, name, fathername, voter_nameparts, voter_community, voter_certainty, voter_gap, father_nameparts, father_community, father_certainty, father_gap, ngram, revision12, revision13, revision14, booth13) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)");
	my $sth4 = $dbh_rolls->prepare("INSERT INTO names (id,firstname,lastname,father_firstname,father_lastname,soundex) VALUES (?,?,?,?,?,?)");
	my $sth2 = $dbh_rolls_old->prepare("SELECT * FROM rolls WHERE revision13 IS NULL OR revision13 = 'M' OR revision13 = 'N'");
	my $sth3 = $dbh_rolls_old->prepare("SELECT * FROM names WHERE id = ?");
	$sth2->execute();
	while (my $row=$sth2->fetchrow_hashref) {
	    my $exists = $dbh_rolls->selectrow_array("SELECT count(*) FROM rolls WHERE voterid = ?",undef,$row->{voterid});
	    next if ($exists > 0);
	    $sth->execute($row->{rollno}, $row->{voterid}, $row->{nameparts}, $row->{age}, $row->{gender}, $row->{community}, $row->{certainty}, $row->{gap}, $row->{name}, $row->{fathername}, $row->{voter_nameparts}, $row->{voter_community}, $row->{voter_certainty}, $row->{voter_gap}, $row->{father_nameparts}, $row->{father_community}, $row->{father_certainty}, $row->{father_gap}, $row->{ngram}, $row->{revision12}, $row->{revision13}, 'D', $oldbooth);
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

    foreach my $oldbooth (keys(%updates)) {
	next if $oldbooth eq 'unclear';
	$dbh_booths->do("UPDATE booths SET booth = ? WHERE oldbooth = ?",undef,$updates{$oldbooth},$oldbooth);
    }
    
    $dbh_rolls->disconnect;
}

$dbh_booths->do("DELETE FROM booths WHERE booth IS NULL");

$dbh_booths->commit;

#
# Update all booth data
#

my @booths=`ls rolls.*.sqlite`;

foreach my $booth (@booths) {
    $booth=~s/.*?(\d+).*/$1/gs;
      
    my $dbh_rolls = DBI->connect("dbi:SQLite:dbname=rolls.$booth.sqlite","","",{sqlite_unicode => 1});
    sqlite_more($dbh_rolls);
    
    $booth=$booth/1;
    
    #
    # First populate table booths
    #
    my $voters_total= $dbh_rolls->selectrow_array("SELECT count(*) FROM rolls WHERE (revision14 IS NULL OR revision14 = 'N' OR revision14 = 'M')",undef);
    
    my $missing_percent=0; my $missing=0;
    if ($voters_total>0) {
	$missing = $dbh_rolls->selectrow_array("SELECT count(*) FROM rolls WHERE (revision14 IS NULL OR revision14 = 'N' OR revision14 = 'M') AND community = 'Unknown'",undef);
	$missing_percent=int(($missing/$voters_total)*10000)/100
    }
    
    my $identified=$voters_total-$missing;
    
    my $temp = $dbh_rolls->selectrow_array("SELECT avg(age) FROM rolls WHERE (revision14 IS NULL OR revision14 = 'N' OR revision14 = 'M')",undef);
    my $age_avg=int($temp*100)/100;
    
    my $temp = $dbh_rolls->selectrow_array("SELECT stddev(age) FROM rolls WHERE (revision14 IS NULL OR revision14 = 'N' OR revision14 = 'M')",undef);
    my $age_stddev=int($temp*100)/100;

    my $temp1 = $dbh_rolls->selectrow_array("SELECT count(*) FROM rolls  WHERE (revision14 IS NULL OR revision14 = 'N' OR revision14 = 'M') AND gender = 'f'",undef);
    my $temp2 = $dbh_rolls->selectrow_array("SELECT count(*) FROM rolls  WHERE (revision14 IS NULL OR revision14 = 'N' OR revision14 = 'M') AND gender = 'm'",undef);
    my $women_percent=0;
    if (($temp1+$temp2)>0) {$women_percent=int(($temp1/($temp1+$temp2))*10000)/100;} else {$women_percent=0}
    
    my $muslim_percent=0;
    if ($identified > 0) {
	my $temp = $dbh_rolls->selectrow_array("SELECT count(*) FROM rolls  WHERE (revision14 IS NULL OR revision14 = 'N' OR revision14 = 'M') AND community = 'Muslim'",undef);
	$muslim_percent=int(($temp/$identified)*10000)/100;
    }
    
    my $women_muslim_percent=0;
    my $age_muslim_avg=0;
    my $age_muslim_stddev=0;
    if ($muslim_percent > 0) {
	my $temp = $dbh_rolls->selectrow_array("SELECT avg(age) FROM rolls  WHERE (revision14 IS NULL OR revision14 = 'N' OR revision14 = 'M') AND community = 'Muslim'",undef);
	$age_muslim_avg=int($temp*100)/100;
	
	my $temp = $dbh_rolls->selectrow_array("SELECT stddev(age) FROM rolls  WHERE (revision14 IS NULL OR revision14 = 'N' OR revision14 = 'M') AND community = 'Muslim'",undef);
	$age_muslim_stddev=int($temp*100)/100;

        my $temp1 = $dbh_rolls->selectrow_array("SELECT count(*) FROM rolls  WHERE (revision14 IS NULL OR revision14 = 'N' OR revision14 = 'M') AND gender = 'f' AND community = 'Muslim'",undef);
	my $temp2 = $dbh_rolls->selectrow_array("SELECT count(*) FROM rolls  WHERE (revision14 IS NULL OR revision14 = 'N' OR revision14 = 'M') AND gender = 'm' AND community = 'Muslim'",undef);
	if (($temp1+$temp2)>0) {$women_muslim_percent=int(($temp1/($temp1+$temp2))*10000)/100;}
    }

    my $buddhist_percent=0;
    if ($identified > 0) {
	my $temp = $dbh_rolls->selectrow_array("SELECT count(*) FROM rolls  WHERE (revision14 IS NULL OR revision14 = 'N' OR revision14 = 'M') AND community = 'Buddhist'",undef);
	$buddhist_percent=int(($temp/$identified)*10000)/100;
    }
    
    my $women_buddhist_percent=0;
    my $age_buddhist_avg=0;
    my $age_buddhist_stddev=0;
    if ($buddhist_percent > 0) {
	my $temp = $dbh_rolls->selectrow_array("SELECT avg(age) FROM rolls  WHERE (revision14 IS NULL OR revision14 = 'N' OR revision14 = 'M') AND community = 'Buddhist'",undef);
	$age_buddhist_avg=int($temp*100)/100;
	
	my $temp = $dbh_rolls->selectrow_array("SELECT stddev(age) FROM rolls  WHERE (revision14 IS NULL OR revision14 = 'N' OR revision14 = 'M') AND community = 'Buddhist'",undef);
	$age_buddhist_stddev=int($temp*100)/100;

        my $temp1 = $dbh_rolls->selectrow_array("SELECT count(*) FROM rolls  WHERE (revision14 IS NULL OR revision14 = 'N' OR revision14 = 'M') AND gender = 'f' AND community = 'Buddhist'",undef);
	my $temp2 = $dbh_rolls->selectrow_array("SELECT count(*) FROM rolls  WHERE (revision14 IS NULL OR revision14 = 'N' OR revision14 = 'M') AND gender = 'm' AND community = 'Buddhist'",undef);
	if (($temp1+$temp2)>0) {$women_buddhist_percent=int(($temp1/($temp1+$temp2))*10000)/100;}
    }

    my $hindu_percent=0;
    if ($identified > 0) {
	my $temp = $dbh_rolls->selectrow_array("SELECT count(*) FROM rolls  WHERE (revision14 IS NULL OR revision14 = 'N' OR revision14 = 'M') AND community = 'Hindu'",undef);
	$hindu_percent=int(($temp/$identified)*10000)/100;
    }
    
    my $women_hindu_percent=0;
    my $age_hindu_avg=0;
    my $age_hindu_stddev=0;
    if ($hindu_percent > 0) {
	my $temp = $dbh_rolls->selectrow_array("SELECT avg(age) FROM rolls  WHERE (revision14 IS NULL OR revision14 = 'N' OR revision14 = 'M') AND community = 'Hindu'",undef);
	$age_hindu_avg=int($temp*100)/100;
	
	my $temp = $dbh_rolls->selectrow_array("SELECT stddev(age) FROM rolls  WHERE (revision14 IS NULL OR revision14 = 'N' OR revision14 = 'M') AND community = 'Hindu'",undef);
	$age_hindu_stddev=int($temp*100)/100;

        my $temp1 = $dbh_rolls->selectrow_array("SELECT count(*) FROM rolls  WHERE (revision14 IS NULL OR revision14 = 'N' OR revision14 = 'M') AND gender = 'f' AND community = 'Hindu'",undef);
	my $temp2 = $dbh_rolls->selectrow_array("SELECT count(*) FROM rolls  WHERE (revision14 IS NULL OR revision14 = 'N' OR revision14 = 'M') AND gender = 'm' AND community = 'Hindu'",undef);
	if (($temp1+$temp2)>0) {$women_hindu_percent=int(($temp1/($temp1+$temp2))*10000)/100;}
    }

    my $jain_percent=0;
    if ($identified > 0) {
	my $temp = $dbh_rolls->selectrow_array("SELECT count(*) FROM rolls  WHERE (revision14 IS NULL OR revision14 = 'N' OR revision14 = 'M') AND community = 'Jain'",undef);
	$jain_percent=int(($temp/$identified)*10000)/100;
    }
    
    my $women_jain_percent=0;
    my $age_jain_avg=0;
    my $age_jain_stddev=0;
    if ($jain_percent > 0) {
	my $temp = $dbh_rolls->selectrow_array("SELECT avg(age) FROM rolls  WHERE (revision14 IS NULL OR revision14 = 'N' OR revision14 = 'M') AND community = 'Jain'",undef);
	$age_jain_avg=int($temp*100)/100;
	
	my $temp = $dbh_rolls->selectrow_array("SELECT stddev(age) FROM rolls  WHERE (revision14 IS NULL OR revision14 = 'N' OR revision14 = 'M') AND community = 'Jain'",undef);
	$age_jain_stddev=int($temp*100)/100;

        my $temp1 = $dbh_rolls->selectrow_array("SELECT count(*) FROM rolls  WHERE (revision14 IS NULL OR revision14 = 'N' OR revision14 = 'M') AND gender = 'f' AND community = 'Jain'",undef);
	my $temp2 = $dbh_rolls->selectrow_array("SELECT count(*) FROM rolls  WHERE (revision14 IS NULL OR revision14 = 'N' OR revision14 = 'M') AND gender = 'm' AND community = 'Jain'",undef);
	if (($temp1+$temp2)>0) {$women_jain_percent=int(($temp1/($temp1+$temp2))*10000)/100;}
    }

    my $parsi_percent=0;
    if ($identified > 0) {
	my $temp = $dbh_rolls->selectrow_array("SELECT count(*) FROM rolls  WHERE (revision14 IS NULL OR revision14 = 'N' OR revision14 = 'M') AND community = 'Parsi'",undef);
	$parsi_percent=int(($temp/$identified)*10000)/100;
    }
    
    my $women_parsi_percent=0;
    my $age_parsi_avg=0;
    my $age_parsi_stddev=0;
    if ($parsi_percent > 0) {
	my $temp = $dbh_rolls->selectrow_array("SELECT avg(age) FROM rolls  WHERE (revision14 IS NULL OR revision14 = 'N' OR revision14 = 'M') AND community = 'Parsi'",undef);
	$age_parsi_avg=int($temp*100)/100;
	
	my $temp = $dbh_rolls->selectrow_array("SELECT stddev(age) FROM rolls  WHERE (revision14 IS NULL OR revision14 = 'N' OR revision14 = 'M') AND community = 'Parsi'",undef);
	$age_parsi_stddev=int($temp*100)/100;

        my $temp1 = $dbh_rolls->selectrow_array("SELECT count(*) FROM rolls  WHERE (revision14 IS NULL OR revision14 = 'N' OR revision14 = 'M') AND gender = 'f' AND community = 'Parsi'",undef);
	my $temp2 = $dbh_rolls->selectrow_array("SELECT count(*) FROM rolls  WHERE (revision14 IS NULL OR revision14 = 'N' OR revision14 = 'M') AND gender = 'm' AND community = 'Parsi'",undef);
	if (($temp1+$temp2)>0) {$women_parsi_percent=int(($temp1/($temp1+$temp2))*10000)/100;}
    }

    my $sikh_percent=0;
    if ($identified > 0) {
	my $temp = $dbh_rolls->selectrow_array("SELECT count(*) FROM rolls  WHERE (revision14 IS NULL OR revision14 = 'N' OR revision14 = 'M') AND community = 'Sikh'",undef);
	$sikh_percent=int(($temp/$identified)*10000)/100;
    }
    
    my $women_sikh_percent=0;
    my $age_sikh_avg=0;
    my $age_sikh_stddev=0;
    if ($sikh_percent > 0) {
	my $temp = $dbh_rolls->selectrow_array("SELECT avg(age) FROM rolls  WHERE (revision14 IS NULL OR revision14 = 'N' OR revision14 = 'M') AND community = 'Sikh'",undef);
	$age_sikh_avg=int($temp*100)/100;
	
	my $temp = $dbh_rolls->selectrow_array("SELECT stddev(age) FROM rolls  WHERE (revision14 IS NULL OR revision14 = 'N' OR revision14 = 'M') AND community = 'Sikh'",undef);
	$age_sikh_stddev=int($temp*100)/100;

        my $temp1 = $dbh_rolls->selectrow_array("SELECT count(*) FROM rolls  WHERE (revision14 IS NULL OR revision14 = 'N' OR revision14 = 'M') AND gender = 'f' AND community = 'Sikh'",undef);
	my $temp2 = $dbh_rolls->selectrow_array("SELECT count(*) FROM rolls  WHERE (revision14 IS NULL OR revision14 = 'N' OR revision14 = 'M') AND gender = 'm' AND community = 'Sikh'",undef);
	if (($temp1+$temp2)>0) {$women_sikh_percent=int(($temp1/($temp1+$temp2))*10000)/100;}
    }

    my $christian_percent=0;
    if ($identified > 0) {
	my $temp = $dbh_rolls->selectrow_array("SELECT count(*) FROM rolls  WHERE (revision14 IS NULL OR revision14 = 'N' OR revision14 = 'M') AND community = 'Christian'",undef);
	$christian_percent=int(($temp/$identified)*10000)/100;
    }
    
    my $women_christian_percent=0;
    my $age_christian_avg=0;
    my $age_christian_stddev=0;
    if ($christian_percent > 0) {
	my $temp = $dbh_rolls->selectrow_array("SELECT avg(age) FROM rolls  WHERE (revision14 IS NULL OR revision14 = 'N' OR revision14 = 'M') AND community = 'Christian'",undef);
	$age_christian_avg=int($temp*100)/100;
	
	my $temp = $dbh_rolls->selectrow_array("SELECT stddev(age) FROM rolls  WHERE (revision14 IS NULL OR revision14 = 'N' OR revision14 = 'M') AND community = 'Christian'",undef);
	$age_christian_stddev=int($temp*100)/100;

        my $temp1 = $dbh_rolls->selectrow_array("SELECT count(*) FROM rolls  WHERE (revision14 IS NULL OR revision14 = 'N' OR revision14 = 'M') AND gender = 'f' AND community = 'Christian'",undef);
	my $temp2 = $dbh_rolls->selectrow_array("SELECT count(*) FROM rolls  WHERE (revision14 IS NULL OR revision14 = 'N' OR revision14 = 'M') AND gender = 'm' AND community = 'Christian'",undef);
	if (($temp1+$temp2)>0) {$women_christian_percent=int(($temp1/($temp1+$temp2))*10000)/100;}
    }
    
    my $new= $dbh_rolls->selectrow_array("SELECT count(*) FROM rolls WHERE revision14 = 'N'",undef);
    my $changed= $dbh_rolls->selectrow_array("SELECT count(*) FROM rolls WHERE revision14 = 'M'",undef);
    my $deleted= $dbh_rolls->selectrow_array("SELECT count(*) FROM rolls WHERE revision14 IS NOT NULL",undef);
    $deleted = $deleted - $new - $changed;
    
    if ($voters_total>0) {
	my $Anew = int($new/($voters_total + $deleted - $new)*10000)/100;
	my $Adeleted = int($deleted/($voters_total + $deleted - $new)*10000)/100;
	my $changed = int($changed/($voters_total + $deleted - $new)*10000)/100;
	$deleted = $Adeleted;
	$new = $Anew;
    }

    # UPDATE PROPERLY

    my $station_name = $dbh_booths->selectrow_array("SELECT station_name FROM booths WHERE booth = ?",undef,$booth);
  
    $dbh_booths->do ("UPDATE booths SET  constituency = ?, voters_total = ?, missing_percent = ?, age_avg = ?, age_stddev = ?, age_muslim_avg = ?, age_muslim_stddev = ?, women_percent = ?, women_muslim_percent = ?, muslim_percent = ?, buddhist_percent = ?, age_buddhist_avg = ?, age_buddhist_stddev = ?, women_buddhist_percent = ?, hindu_percent = ?, age_hindu_avg = ?, age_hindu_stddev = ?, women_hindu_percent = ?, jain_percent = ?, age_jain_avg = ?, age_jain_stddev = ?, women_jain_percent = ?, parsi_percent = ?, age_parsi_avg = ?, age_parsi_stddev = ?, women_parsi_percent = ?, sikh_percent = ?, age_sikh_avg = ?, age_sikh_stddev = ?, women_sikh_percent = ?, christian_percent = ?, age_christian_avg = ?, age_christian_stddev = ?, women_christian_percent = ?, lastupdate = ?, station_name = ?, revision14_percent_new = ?, revision14_percent_deleted = ?, revision14_percent_modified = ? WHERE booth = ? ", undef, $constituency, $voters_total, $missing_percent, $age_avg, $age_stddev, $age_muslim_avg, $age_muslim_stddev, $women_percent, $women_muslim_percent, $muslim_percent, $buddhist_percent, $age_buddhist_avg, $age_buddhist_stddev, $women_buddhist_percent, $hindu_percent, $age_hindu_avg, $age_hindu_stddev, $women_hindu_percent, $jain_percent, $age_jain_avg, $age_jain_stddev, $women_jain_percent, $parsi_percent, $age_parsi_avg, $age_parsi_stddev, $women_parsi_percent, $sikh_percent, $age_sikh_avg, $age_sikh_stddev, $women_sikh_percent, $christian_percent, $age_christian_avg, $age_christian_stddev, $women_christian_percent, '1/1/2014', $station_name, $new, $deleted, $changed, $booth);
    
    $dbh_rolls->disconnect;
}

$dbh_booths->commit;
$dbh_booths->disconnect;
