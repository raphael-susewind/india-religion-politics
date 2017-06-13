#!/usr/bin/perl

my $constituency=$ARGV[0];

#
# Create booths.sqlite with aggregated data in booths for sp and aggregated data in names for riot-names
#

use DBI;
use SQLite::More;

my $dbh_booths = DBI->connect("dbi:SQLite:dbname=$constituency.sqlite","","",{sqlite_unicode => 1});
$dbh_booths->do ("CREATE TABLE booths (constituency INTEGER, booth INTEGER, voters_total INTEGER, missing_percent FLOAT, age_avg FLOAT, age_stddev FLOAT, age_muslim_avg FLOAT, age_muslim_stddev FLOAT, women_percent FLOAT, women_muslim_percent FLOAT, muslim_percent FLOAT, buddhist_percent FLOAT, age_buddhist_avg FLOAT, age_buddhist_stddev FLOAT, women_buddhist_percent FLOAT, hindu_percent FLOAT, age_hindu_avg FLOAT, age_hindu_stddev FLOAT, women_hindu_percent FLOAT, jain_percent FLOAT, age_jain_avg FLOAT, age_jain_stddev FLOAT, women_jain_percent FLOAT, parsi_percent FLOAT, age_parsi_avg FLOAT, age_parsi_stddev FLOAT, women_parsi_percent FLOAT, sikh_percent FLOAT, age_sikh_avg FLOAT, age_sikh_stddev FLOAT, women_sikh_percent FLOAT, christian_percent FLOAT, age_christian_avg FLOAT, age_christian_stddev FLOAT, women_christian_percent FLOAT, missing_percent_pure FLOAT, age_avg_pure FLOAT, age_stddev_pure FLOAT, age_muslim_avg_pure FLOAT, age_muslim_stddev_pure FLOAT, women_percent_pure FLOAT, women_muslim_percent_pure FLOAT, muslim_percent_pure FLOAT, buddhist_percent_pure FLOAT, age_buddhist_avg_pure FLOAT, age_buddhist_stddev_pure FLOAT, women_buddhist_percent_pure FLOAT, hindu_percent_pure FLOAT, age_hindu_avg_pure FLOAT, age_hindu_stddev_pure FLOAT, women_hindu_percent_pure FLOAT, jain_percent_pure FLOAT, age_jain_avg_pure FLOAT, age_jain_stddev_pure FLOAT, women_jain_percent_pure FLOAT, parsi_percent_pure FLOAT, age_parsi_avg_pure FLOAT, age_parsi_stddev_pure FLOAT, women_parsi_percent_pure FLOAT, sikh_percent_pure FLOAT, age_sikh_avg_pure FLOAT, age_sikh_stddev_pure FLOAT, women_sikh_percent_pure FLOAT, christian_percent_pure FLOAT, age_christian_avg_pure FLOAT, age_christian_stddev_pure FLOAT, women_christian_percent_pure FLOAT)");
$dbh_booths->begin_work;

#
# Crawl through all booths
#

my @booths=`bash -c 'ls rolls.*.sqlite'`;
  
foreach my $booth (@booths) {
    $booth=~s/.*?(\d+).*/$1/gs;

    my $dbh_rolls = DBI->connect("dbi:SQLite:dbname=:memory:","","",{sqlite_unicode => 1});
    $dbh_rolls->sqlite_backup_from_file("rolls.$booth.sqlite");
    sqlite_more($dbh_rolls);

    my $voters_total= $dbh_rolls->selectrow_array("SELECT count(*) FROM rolls",undef);
    
    my $missing_percent=0; my $missing=0;
    if ($voters_total>0) {
	$missing = $dbh_rolls->selectrow_array("SELECT count(*) FROM rolls WHERE community = 'Unknown'",undef);
	$missing_percent=int(($missing/$voters_total)*10000)/100
    }
    
    my $identified=$voters_total-$missing;
    
    my $temp = $dbh_rolls->selectrow_array("SELECT avg(age) FROM rolls",undef);
    my $age_avg=int($temp*100)/100;
    
    my $temp = $dbh_rolls->selectrow_array("SELECT stddev(age) FROM rolls",undef);
    my $age_stddev=int($temp*100)/100;

    my $temp1 = $dbh_rolls->selectrow_array("SELECT count(*) FROM rolls WHERE gender = 'f'",undef);
    my $temp2 = $dbh_rolls->selectrow_array("SELECT count(*) FROM rolls WHERE gender = 'm'",undef);
    my $women_percent=0;
    if (($temp1+$temp2)>0) {$women_percent=int(($temp1/($temp1+$temp2))*10000)/100;} else {$women_percent=0}
    
    my $muslim_percent=0;
    if ($identified > 0) {
	my $temp = $dbh_rolls->selectrow_array("SELECT count(*) FROM rolls WHERE community = 'Muslim'",undef);
	$muslim_percent=int(($temp/$identified)*10000)/100;
    }
    
    my $women_muslim_percent=0;
    my $age_muslim_avg=0;
    my $age_muslim_stddev=0;
    if ($muslim_percent > 0) {
	my $temp = $dbh_rolls->selectrow_array("SELECT avg(age) FROM rolls WHERE community = 'Muslim'",undef);
	$age_muslim_avg=int($temp*100)/100;
	
	my $temp = $dbh_rolls->selectrow_array("SELECT stddev(age) FROM rolls WHERE community = 'Muslim'",undef);
	$age_muslim_stddev=int($temp*100)/100;

        my $temp1 = $dbh_rolls->selectrow_array("SELECT count(*) FROM rolls WHERE gender = 'f' AND community = 'Muslim'",undef);
	my $temp2 = $dbh_rolls->selectrow_array("SELECT count(*) FROM rolls WHERE gender = 'm' AND community = 'Muslim'",undef);
	if (($temp1+$temp2)>0) {$women_muslim_percent=int(($temp1/($temp1+$temp2))*10000)/100;}
    }

    my $buddhist_percent=0;
    if ($identified > 0) {
	my $temp = $dbh_rolls->selectrow_array("SELECT count(*) FROM rolls WHERE community = 'Buddhist'",undef);
	$buddhist_percent=int(($temp/$identified)*10000)/100;
    }
    
    my $women_buddhist_percent=0;
    my $age_buddhist_avg=0;
    my $age_buddhist_stddev=0;
    if ($buddhist_percent > 0) {
	my $temp = $dbh_rolls->selectrow_array("SELECT avg(age) FROM rolls WHERE community = 'Buddhist'",undef);
	$age_buddhist_avg=int($temp*100)/100;
	
	my $temp = $dbh_rolls->selectrow_array("SELECT stddev(age) FROM rolls WHERE community = 'Buddhist'",undef);
	$age_buddhist_stddev=int($temp*100)/100;

        my $temp1 = $dbh_rolls->selectrow_array("SELECT count(*) FROM rolls WHERE gender = 'f' AND community = 'Buddhist'",undef);
	my $temp2 = $dbh_rolls->selectrow_array("SELECT count(*) FROM rolls WHERE gender = 'm' AND community = 'Buddhist'",undef);
	if (($temp1+$temp2)>0) {$women_buddhist_percent=int(($temp1/($temp1+$temp2))*10000)/100;}
    }

    my $hindu_percent=0;
    if ($identified > 0) {
	my $temp = $dbh_rolls->selectrow_array("SELECT count(*) FROM rolls WHERE community = 'Hindu'",undef);
	$hindu_percent=int(($temp/$identified)*10000)/100;
    }
    
    my $women_hindu_percent=0;
    my $age_hindu_avg=0;
    my $age_hindu_stddev=0;
    if ($hindu_percent > 0) {
	my $temp = $dbh_rolls->selectrow_array("SELECT avg(age) FROM rolls WHERE community = 'Hindu'",undef);
	$age_hindu_avg=int($temp*100)/100;
	
	my $temp = $dbh_rolls->selectrow_array("SELECT stddev(age) FROM rolls WHERE community = 'Hindu'",undef);
	$age_hindu_stddev=int($temp*100)/100;

        my $temp1 = $dbh_rolls->selectrow_array("SELECT count(*) FROM rolls WHERE gender = 'f' AND community = 'Hindu'",undef);
	my $temp2 = $dbh_rolls->selectrow_array("SELECT count(*) FROM rolls WHERE gender = 'm' AND community = 'Hindu'",undef);
	if (($temp1+$temp2)>0) {$women_hindu_percent=int(($temp1/($temp1+$temp2))*10000)/100;}
    }

    my $jain_percent=0;
    if ($identified > 0) {
	my $temp = $dbh_rolls->selectrow_array("SELECT count(*) FROM rolls WHERE community = 'Jain'",undef);
	$jain_percent=int(($temp/$identified)*10000)/100;
    }
    
    my $women_jain_percent=0;
    my $age_jain_avg=0;
    my $age_jain_stddev=0;
    if ($jain_percent > 0) {
	my $temp = $dbh_rolls->selectrow_array("SELECT avg(age) FROM rolls WHERE community = 'Jain'",undef);
	$age_jain_avg=int($temp*100)/100;
	
	my $temp = $dbh_rolls->selectrow_array("SELECT stddev(age) FROM rolls WHERE community = 'Jain'",undef);
	$age_jain_stddev=int($temp*100)/100;

        my $temp1 = $dbh_rolls->selectrow_array("SELECT count(*) FROM rolls WHERE gender = 'f' AND community = 'Jain'",undef);
	my $temp2 = $dbh_rolls->selectrow_array("SELECT count(*) FROM rolls WHERE gender = 'm' AND community = 'Jain'",undef);
	if (($temp1+$temp2)>0) {$women_jain_percent=int(($temp1/($temp1+$temp2))*10000)/100;}
    }

    my $parsi_percent=0;
    if ($identified > 0) {
	my $temp = $dbh_rolls->selectrow_array("SELECT count(*) FROM rolls WHERE community = 'Parsi'",undef);
	$parsi_percent=int(($temp/$identified)*10000)/100;
    }
    
    my $women_parsi_percent=0;
    my $age_parsi_avg=0;
    my $age_parsi_stddev=0;
    if ($parsi_percent > 0) {
	my $temp = $dbh_rolls->selectrow_array("SELECT avg(age) FROM rolls WHERE community = 'Parsi'",undef);
	$age_parsi_avg=int($temp*100)/100;
	
	my $temp = $dbh_rolls->selectrow_array("SELECT stddev(age) FROM rolls WHERE community = 'Parsi'",undef);
	$age_parsi_stddev=int($temp*100)/100;

        my $temp1 = $dbh_rolls->selectrow_array("SELECT count(*) FROM rolls WHERE gender = 'f' AND community = 'Parsi'",undef);
	my $temp2 = $dbh_rolls->selectrow_array("SELECT count(*) FROM rolls WHERE gender = 'm' AND community = 'Parsi'",undef);
	if (($temp1+$temp2)>0) {$women_parsi_percent=int(($temp1/($temp1+$temp2))*10000)/100;}
    }

    my $sikh_percent=0;
    if ($identified > 0) {
	my $temp = $dbh_rolls->selectrow_array("SELECT count(*) FROM rolls WHERE community = 'Sikh'",undef);
	$sikh_percent=int(($temp/$identified)*10000)/100;
    }
    
    my $women_sikh_percent=0;
    my $age_sikh_avg=0;
    my $age_sikh_stddev=0;
    if ($sikh_percent > 0) {
	my $temp = $dbh_rolls->selectrow_array("SELECT avg(age) FROM rolls WHERE community = 'Sikh'",undef);
	$age_sikh_avg=int($temp*100)/100;
	
	my $temp = $dbh_rolls->selectrow_array("SELECT stddev(age) FROM rolls WHERE community = 'Sikh'",undef);
	$age_sikh_stddev=int($temp*100)/100;

        my $temp1 = $dbh_rolls->selectrow_array("SELECT count(*) FROM rolls WHERE gender = 'f' AND community = 'Sikh'",undef);
	my $temp2 = $dbh_rolls->selectrow_array("SELECT count(*) FROM rolls WHERE gender = 'm' AND community = 'Sikh'",undef);
	if (($temp1+$temp2)>0) {$women_sikh_percent=int(($temp1/($temp1+$temp2))*10000)/100;}
    }

    my $christian_percent=0;
    if ($identified > 0) {
	my $temp = $dbh_rolls->selectrow_array("SELECT count(*) FROM rolls WHERE community = 'Christian'",undef);
	$christian_percent=int(($temp/$identified)*10000)/100;
    }
    
    my $women_christian_percent=0;
    my $age_christian_avg=0;
    my $age_christian_stddev=0;
    if ($christian_percent > 0) {
	my $temp = $dbh_rolls->selectrow_array("SELECT avg(age) FROM rolls WHERE community = 'Christian'",undef);
	$age_christian_avg=int($temp*100)/100;
	
	my $temp = $dbh_rolls->selectrow_array("SELECT stddev(age) FROM rolls WHERE community = 'Christian'",undef);
	$age_christian_stddev=int($temp*100)/100;

        my $temp1 = $dbh_rolls->selectrow_array("SELECT count(*) FROM rolls WHERE gender = 'f' AND community = 'Christian'",undef);
	my $temp2 = $dbh_rolls->selectrow_array("SELECT count(*) FROM rolls WHERE gender = 'm' AND community = 'Christian'",undef);
	if (($temp1+$temp2)>0) {$women_christian_percent=int(($temp1/($temp1+$temp2))*10000)/100;}
    }

    #
    # Now redo the same thing without ngram for accuracy reasons
    #
    
    $dbh_rolls->do("UPDATE rolls SET community = 'Unknown' WHERE ngram IS NOT NULL");

    my $missing_percent_pure=0; my $missing=0;
    if ($voters_total>0) {
	$missing = $dbh_rolls->selectrow_array("SELECT count(*) FROM rolls WHERE community = 'Unknown'",undef);
	$missing_percent_pure=int(($missing/$voters_total)*10000)/100
    }
    
    my $identified=$voters_total-$missing;
    
    my $temp = $dbh_rolls->selectrow_array("SELECT avg(age) FROM rolls",undef);
    my $age_avg_pure=int($temp*100)/100;
    
    my $temp = $dbh_rolls->selectrow_array("SELECT stddev(age) FROM rolls",undef);
    my $age_stddev_pure=int($temp*100)/100;

    my $temp1 = $dbh_rolls->selectrow_array("SELECT count(*) FROM rolls WHERE gender = 'f'",undef);
    my $temp2 = $dbh_rolls->selectrow_array("SELECT count(*) FROM rolls WHERE gender = 'm'",undef);
    my $women_percent_pure=0;
    if (($temp1+$temp2)>0) {$women_percent_pure=int(($temp1/($temp1+$temp2))*10000)/100;} else {$women_percent_pure=0}
    
    my $muslim_percent_pure=0;
    if ($identified > 0) {
	my $temp = $dbh_rolls->selectrow_array("SELECT count(*) FROM rolls WHERE community = 'Muslim'",undef);
	$muslim_percent_pure=int(($temp/$identified)*10000)/100;
    }
    
    my $women_muslim_percent_pure=0;
    my $age_muslim_avg_pure=0;
    my $age_muslim_stddev_pure=0;
    if ($muslim_percent_pure > 0) {
	my $temp = $dbh_rolls->selectrow_array("SELECT avg(age) FROM rolls WHERE community = 'Muslim'",undef);
	$age_muslim_avg_pure=int($temp*100)/100;
	
	my $temp = $dbh_rolls->selectrow_array("SELECT stddev(age) FROM rolls WHERE community = 'Muslim'",undef);
	$age_muslim_stddev_pure=int($temp*100)/100;

        my $temp1 = $dbh_rolls->selectrow_array("SELECT count(*) FROM rolls WHERE gender = 'f' AND community = 'Muslim'",undef);
	my $temp2 = $dbh_rolls->selectrow_array("SELECT count(*) FROM rolls WHERE gender = 'm' AND community = 'Muslim'",undef);
	if (($temp1+$temp2)>0) {$women_muslim_percent_pure=int(($temp1/($temp1+$temp2))*10000)/100;}
    }

    my $buddhist_percent_pure=0;
    if ($identified > 0) {
	my $temp = $dbh_rolls->selectrow_array("SELECT count(*) FROM rolls WHERE community = 'Buddhist'",undef);
	$buddhist_percent_pure=int(($temp/$identified)*10000)/100;
    }
    
    my $women_buddhist_percent_pure=0;
    my $age_buddhist_avg_pure=0;
    my $age_buddhist_stddev_pure=0;
    if ($buddhist_percent_pure > 0) {
	my $temp = $dbh_rolls->selectrow_array("SELECT avg(age) FROM rolls WHERE community = 'Buddhist'",undef);
	$age_buddhist_avg_pure=int($temp*100)/100;
	
	my $temp = $dbh_rolls->selectrow_array("SELECT stddev(age) FROM rolls WHERE community = 'Buddhist'",undef);
	$age_buddhist_stddev_pure=int($temp*100)/100;

        my $temp1 = $dbh_rolls->selectrow_array("SELECT count(*) FROM rolls WHERE gender = 'f' AND community = 'Buddhist'",undef);
	my $temp2 = $dbh_rolls->selectrow_array("SELECT count(*) FROM rolls WHERE gender = 'm' AND community = 'Buddhist'",undef);
	if (($temp1+$temp2)>0) {$women_buddhist_percent_pure=int(($temp1/($temp1+$temp2))*10000)/100;}
    }

    my $hindu_percent_pure=0;
    if ($identified > 0) {
	my $temp = $dbh_rolls->selectrow_array("SELECT count(*) FROM rolls WHERE community = 'Hindu'",undef);
	$hindu_percent_pure=int(($temp/$identified)*10000)/100;
    }
    
    my $women_hindu_percent_pure=0;
    my $age_hindu_avg_pure=0;
    my $age_hindu_stddev_pure=0;
    if ($hindu_percent_pure > 0) {
	my $temp = $dbh_rolls->selectrow_array("SELECT avg(age) FROM rolls WHERE community = 'Hindu'",undef);
	$age_hindu_avg_pure=int($temp*100)/100;
	
	my $temp = $dbh_rolls->selectrow_array("SELECT stddev(age) FROM rolls WHERE community = 'Hindu'",undef);
	$age_hindu_stddev_pure=int($temp*100)/100;

        my $temp1 = $dbh_rolls->selectrow_array("SELECT count(*) FROM rolls WHERE gender = 'f' AND community = 'Hindu'",undef);
	my $temp2 = $dbh_rolls->selectrow_array("SELECT count(*) FROM rolls WHERE gender = 'm' AND community = 'Hindu'",undef);
	if (($temp1+$temp2)>0) {$women_hindu_percent_pure=int(($temp1/($temp1+$temp2))*10000)/100;}
    }

    my $jain_percent_pure=0;
    if ($identified > 0) {
	my $temp = $dbh_rolls->selectrow_array("SELECT count(*) FROM rolls WHERE community = 'Jain'",undef);
	$jain_percent_pure=int(($temp/$identified)*10000)/100;
    }
    
    my $women_jain_percent_pure=0;
    my $age_jain_avg_pure=0;
    my $age_jain_stddev_pure=0;
    if ($jain_percent_pure > 0) {
	my $temp = $dbh_rolls->selectrow_array("SELECT avg(age) FROM rolls WHERE community = 'Jain'",undef);
	$age_jain_avg_pure=int($temp*100)/100;
	
	my $temp = $dbh_rolls->selectrow_array("SELECT stddev(age) FROM rolls WHERE community = 'Jain'",undef);
	$age_jain_stddev_pure=int($temp*100)/100;

        my $temp1 = $dbh_rolls->selectrow_array("SELECT count(*) FROM rolls WHERE gender = 'f' AND community = 'Jain'",undef);
	my $temp2 = $dbh_rolls->selectrow_array("SELECT count(*) FROM rolls WHERE gender = 'm' AND community = 'Jain'",undef);
	if (($temp1+$temp2)>0) {$women_jain_percent_pure=int(($temp1/($temp1+$temp2))*10000)/100;}
    }

    my $parsi_percent_pure=0;
    if ($identified > 0) {
	my $temp = $dbh_rolls->selectrow_array("SELECT count(*) FROM rolls WHERE community = 'Parsi'",undef);
	$parsi_percent_pure=int(($temp/$identified)*10000)/100;
    }
    
    my $women_parsi_percent_pure=0;
    my $age_parsi_avg_pure=0;
    my $age_parsi_stddev_pure=0;
    if ($parsi_percent_pure > 0) {
	my $temp = $dbh_rolls->selectrow_array("SELECT avg(age) FROM rolls WHERE community = 'Parsi'",undef);
	$age_parsi_avg_pure=int($temp*100)/100;
	
	my $temp = $dbh_rolls->selectrow_array("SELECT stddev(age) FROM rolls WHERE community = 'Parsi'",undef);
	$age_parsi_stddev_pure=int($temp*100)/100;

        my $temp1 = $dbh_rolls->selectrow_array("SELECT count(*) FROM rolls WHERE gender = 'f' AND community = 'Parsi'",undef);
	my $temp2 = $dbh_rolls->selectrow_array("SELECT count(*) FROM rolls WHERE gender = 'm' AND community = 'Parsi'",undef);
	if (($temp1+$temp2)>0) {$women_parsi_percent_pure=int(($temp1/($temp1+$temp2))*10000)/100;}
    }

    my $sikh_percent_pure=0;
    if ($identified > 0) {
	my $temp = $dbh_rolls->selectrow_array("SELECT count(*) FROM rolls WHERE community = 'Sikh'",undef);
	$sikh_percent_pure=int(($temp/$identified)*10000)/100;
    }
    
    my $women_sikh_percent_pure=0;
    my $age_sikh_avg_pure=0;
    my $age_sikh_stddev_pure=0;
    if ($sikh_percent_pure > 0) {
	my $temp = $dbh_rolls->selectrow_array("SELECT avg(age) FROM rolls WHERE community = 'Sikh'",undef);
	$age_sikh_avg_pure=int($temp*100)/100;
	
	my $temp = $dbh_rolls->selectrow_array("SELECT stddev(age) FROM rolls WHERE community = 'Sikh'",undef);
	$age_sikh_stddev_pure=int($temp*100)/100;

        my $temp1 = $dbh_rolls->selectrow_array("SELECT count(*) FROM rolls WHERE gender = 'f' AND community = 'Sikh'",undef);
	my $temp2 = $dbh_rolls->selectrow_array("SELECT count(*) FROM rolls WHERE gender = 'm' AND community = 'Sikh'",undef);
	if (($temp1+$temp2)>0) {$women_sikh_percent_pure=int(($temp1/($temp1+$temp2))*10000)/100;}
    }

    my $christian_percent_pure=0;
    if ($identified > 0) {
	my $temp = $dbh_rolls->selectrow_array("SELECT count(*) FROM rolls WHERE community = 'Christian'",undef);
	$christian_percent_pure=int(($temp/$identified)*10000)/100;
    }
    
    my $women_christian_percent_pure=0;
    my $age_christian_avg_pure=0;
    my $age_christian_stddev_pure=0;
    if ($christian_percent_pure > 0) {
	my $temp = $dbh_rolls->selectrow_array("SELECT avg(age) FROM rolls WHERE community = 'Christian'",undef);
	$age_christian_avg_pure=int($temp*100)/100;
	
	my $temp = $dbh_rolls->selectrow_array("SELECT stddev(age) FROM rolls WHERE community = 'Christian'",undef);
	$age_christian_stddev_pure=int($temp*100)/100;

        my $temp1 = $dbh_rolls->selectrow_array("SELECT count(*) FROM rolls WHERE gender = 'f' AND community = 'Christian'",undef);
	my $temp2 = $dbh_rolls->selectrow_array("SELECT count(*) FROM rolls WHERE gender = 'm' AND community = 'Christian'",undef);
	if (($temp1+$temp2)>0) {$women_christian_percent_pure=int(($temp1/($temp1+$temp2))*10000)/100;}
    }

    
    $dbh_booths->do ("INSERT INTO booths VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)", undef, $constituency, $booth, $voters_total, $missing_percent, $age_avg, $age_stddev, $age_muslim_avg, $age_muslim_stddev, $women_percent, $women_muslim_percent, $muslim_percent, $buddhist_percent, $age_buddhist_avg, $age_buddhist_stddev, $women_buddhist_percent, $hindu_percent, $age_hindu_avg, $age_hindu_stddev, $women_hindu_percent, $jain_percent, $age_jain_avg, $age_jain_stddev, $women_jain_percent, $parsi_percent, $age_parsi_avg, $age_parsi_stddev, $women_parsi_percent, $sikh_percent, $age_sikh_avg, $age_sikh_stddev, $women_sikh_percent, $christian_percent, $age_christian_avg, $age_christian_stddev, $women_christian_percent, $missing_percent_pure, $age_avg_pure, $age_stddev_pure, $age_muslim_avg_pure, $age_muslim_stddev_pure, $women_percent_pure, $women_muslim_percent_pure, $muslim_percent_pure, $buddhist_percent_pure, $age_buddhist_avg_pure, $age_buddhist_stddev_pure, $women_buddhist_percent_pure, $hindu_percent_pure, $age_hindu_avg_pure, $age_hindu_stddev_pure, $women_hindu_percent_pure, $jain_percent_pure, $age_jain_avg_pure, $age_jain_stddev_pure, $women_jain_percent_pure, $parsi_percent_pure, $age_parsi_avg_pure, $age_parsi_stddev_pure, $women_parsi_percent_pure, $sikh_percent_pure, $age_sikh_avg_pure, $age_sikh_stddev_pure, $women_sikh_percent_pure, $christian_percent_pure, $age_christian_avg_pure, $age_christian_stddev_pure, $women_christian_percent);
    
    $dbh_rolls->disconnect;
}

$dbh_booths->commit;
$dbh_booths->disconnect;
