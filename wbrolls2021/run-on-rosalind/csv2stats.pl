#!/usr/bin/perl

my $constituency=$ARGV[0];

#
# Create booths.sqlite with aggregated data in booths for sp and aggregated data in names for riot-names
#

use DBI;
use SQLite::More;

my $dbh_booths = DBI->connect("dbi:SQLite:dbname=$constituency.sqlite","","",{sqlite_unicode => 1});

#
# Crawl through all booths
#


my @booths=`ls rolls.*.sqlite`;

foreach my $booth (@booths) {
    next unless $booth =~ /\d/gs;
    $booth=~s/.*?(\d+).*/$1/gs;
      
    my $dbh_rolls = DBI->connect("dbi:SQLite:dbname=rolls.$booth.sqlite","","",{sqlite_unicode => 1});
    sqlite_more($dbh_rolls);
    
    $booth=$booth/1;
    
    #
    # First populate table booths
    #
    my $voters_total= $dbh_rolls->selectrow_array("SELECT count(*) FROM rolls WHERE (revision21 IS NULL OR revision21 = 'N' OR revision21 = 'M')",undef);
    
    my $missing_percent=0; my $missing=0;
    if ($voters_total>0) {
	$missing = $dbh_rolls->selectrow_array("SELECT count(*) FROM rolls WHERE (revision21 IS NULL OR revision21 = 'N' OR revision21 = 'M') AND community = 'Unknown'",undef);
	$missing_percent=int(($missing/$voters_total)*10000)/100
    }
    
    my $identified=$voters_total-$missing;
    
    my $temp = $dbh_rolls->selectrow_array("SELECT avg(age) FROM rolls WHERE (revision21 IS NULL OR revision21 = 'N' OR revision21 = 'M')",undef);
    my $age_avg=int($temp*100)/100;
    
    my $temp = $dbh_rolls->selectrow_array("SELECT stddev(age) FROM rolls WHERE (revision21 IS NULL OR revision21 = 'N' OR revision21 = 'M')",undef);
    my $age_stddev=int($temp*100)/100;

    my $temp1 = $dbh_rolls->selectrow_array("SELECT count(*) FROM rolls  WHERE (revision21 IS NULL OR revision21 = 'N' OR revision21 = 'M') AND gender = 'f'",undef);
    my $temp2 = $dbh_rolls->selectrow_array("SELECT count(*) FROM rolls  WHERE (revision21 IS NULL OR revision21 = 'N' OR revision21 = 'M') AND gender = 'm'",undef);
    my $women_percent=0;
    if (($temp1+$temp2)>0) {$women_percent=int(($temp1/($temp1+$temp2))*10000)/100;} else {$women_percent=0}
    
    my $muslim_percent=0;
    if ($identified > 0) {
	my $temp = $dbh_rolls->selectrow_array("SELECT count(*) FROM rolls  WHERE (revision21 IS NULL OR revision21 = 'N' OR revision21 = 'M') AND community = 'Muslim'",undef);
	$muslim_percent=int(($temp/$identified)*10000)/100;
    }
    
    my $women_muslim_percent=0;
    my $age_muslim_avg=0;
    my $age_muslim_stddev=0;
    if ($muslim_percent > 0) {
	my $temp = $dbh_rolls->selectrow_array("SELECT avg(age) FROM rolls  WHERE (revision21 IS NULL OR revision21 = 'N' OR revision21 = 'M') AND community = 'Muslim'",undef);
	$age_muslim_avg=int($temp*100)/100;
	
	my $temp = $dbh_rolls->selectrow_array("SELECT stddev(age) FROM rolls  WHERE (revision21 IS NULL OR revision21 = 'N' OR revision21 = 'M') AND community = 'Muslim'",undef);
	$age_muslim_stddev=int($temp*100)/100;

        my $temp1 = $dbh_rolls->selectrow_array("SELECT count(*) FROM rolls  WHERE (revision21 IS NULL OR revision21 = 'N' OR revision21 = 'M') AND gender = 'f' AND community = 'Muslim'",undef);
	my $temp2 = $dbh_rolls->selectrow_array("SELECT count(*) FROM rolls  WHERE (revision21 IS NULL OR revision21 = 'N' OR revision21 = 'M') AND gender = 'm' AND community = 'Muslim'",undef);
	if (($temp1+$temp2)>0) {$women_muslim_percent=int(($temp1/($temp1+$temp2))*10000)/100;}
    }

    my $buddhist_percent=0;
    if ($identified > 0) {
	my $temp = $dbh_rolls->selectrow_array("SELECT count(*) FROM rolls  WHERE (revision21 IS NULL OR revision21 = 'N' OR revision21 = 'M') AND community = 'Buddhist'",undef);
	$buddhist_percent=int(($temp/$identified)*10000)/100;
    }
    
    my $women_buddhist_percent=0;
    my $age_buddhist_avg=0;
    my $age_buddhist_stddev=0;
    if ($buddhist_percent > 0) {
	my $temp = $dbh_rolls->selectrow_array("SELECT avg(age) FROM rolls  WHERE (revision21 IS NULL OR revision21 = 'N' OR revision21 = 'M') AND community = 'Buddhist'",undef);
	$age_buddhist_avg=int($temp*100)/100;
	
	my $temp = $dbh_rolls->selectrow_array("SELECT stddev(age) FROM rolls  WHERE (revision21 IS NULL OR revision21 = 'N' OR revision21 = 'M') AND community = 'Buddhist'",undef);
	$age_buddhist_stddev=int($temp*100)/100;

        my $temp1 = $dbh_rolls->selectrow_array("SELECT count(*) FROM rolls  WHERE (revision21 IS NULL OR revision21 = 'N' OR revision21 = 'M') AND gender = 'f' AND community = 'Buddhist'",undef);
	my $temp2 = $dbh_rolls->selectrow_array("SELECT count(*) FROM rolls  WHERE (revision21 IS NULL OR revision21 = 'N' OR revision21 = 'M') AND gender = 'm' AND community = 'Buddhist'",undef);
	if (($temp1+$temp2)>0) {$women_buddhist_percent=int(($temp1/($temp1+$temp2))*10000)/100;}
    }

    my $hindu_percent=0;
    if ($identified > 0) {
	my $temp = $dbh_rolls->selectrow_array("SELECT count(*) FROM rolls  WHERE (revision21 IS NULL OR revision21 = 'N' OR revision21 = 'M') AND community = 'Hindu'",undef);
	$hindu_percent=int(($temp/$identified)*10000)/100;
    }
    
    my $women_hindu_percent=0;
    my $age_hindu_avg=0;
    my $age_hindu_stddev=0;
    if ($hindu_percent > 0) {
	my $temp = $dbh_rolls->selectrow_array("SELECT avg(age) FROM rolls  WHERE (revision21 IS NULL OR revision21 = 'N' OR revision21 = 'M') AND community = 'Hindu'",undef);
	$age_hindu_avg=int($temp*100)/100;
	
	my $temp = $dbh_rolls->selectrow_array("SELECT stddev(age) FROM rolls  WHERE (revision21 IS NULL OR revision21 = 'N' OR revision21 = 'M') AND community = 'Hindu'",undef);
	$age_hindu_stddev=int($temp*100)/100;

        my $temp1 = $dbh_rolls->selectrow_array("SELECT count(*) FROM rolls  WHERE (revision21 IS NULL OR revision21 = 'N' OR revision21 = 'M') AND gender = 'f' AND community = 'Hindu'",undef);
	my $temp2 = $dbh_rolls->selectrow_array("SELECT count(*) FROM rolls  WHERE (revision21 IS NULL OR revision21 = 'N' OR revision21 = 'M') AND gender = 'm' AND community = 'Hindu'",undef);
	if (($temp1+$temp2)>0) {$women_hindu_percent=int(($temp1/($temp1+$temp2))*10000)/100;}
    }

    my $jain_percent=0;
    if ($identified > 0) {
	my $temp = $dbh_rolls->selectrow_array("SELECT count(*) FROM rolls  WHERE (revision21 IS NULL OR revision21 = 'N' OR revision21 = 'M') AND community = 'Jain'",undef);
	$jain_percent=int(($temp/$identified)*10000)/100;
    }
    
    my $women_jain_percent=0;
    my $age_jain_avg=0;
    my $age_jain_stddev=0;
    if ($jain_percent > 0) {
	my $temp = $dbh_rolls->selectrow_array("SELECT avg(age) FROM rolls  WHERE (revision21 IS NULL OR revision21 = 'N' OR revision21 = 'M') AND community = 'Jain'",undef);
	$age_jain_avg=int($temp*100)/100;
	
	my $temp = $dbh_rolls->selectrow_array("SELECT stddev(age) FROM rolls  WHERE (revision21 IS NULL OR revision21 = 'N' OR revision21 = 'M') AND community = 'Jain'",undef);
	$age_jain_stddev=int($temp*100)/100;

        my $temp1 = $dbh_rolls->selectrow_array("SELECT count(*) FROM rolls  WHERE (revision21 IS NULL OR revision21 = 'N' OR revision21 = 'M') AND gender = 'f' AND community = 'Jain'",undef);
	my $temp2 = $dbh_rolls->selectrow_array("SELECT count(*) FROM rolls  WHERE (revision21 IS NULL OR revision21 = 'N' OR revision21 = 'M') AND gender = 'm' AND community = 'Jain'",undef);
	if (($temp1+$temp2)>0) {$women_jain_percent=int(($temp1/($temp1+$temp2))*10000)/100;}
    }

    my $parsi_percent=0;
    if ($identified > 0) {
	my $temp = $dbh_rolls->selectrow_array("SELECT count(*) FROM rolls  WHERE (revision21 IS NULL OR revision21 = 'N' OR revision21 = 'M') AND community = 'Parsi'",undef);
	$parsi_percent=int(($temp/$identified)*10000)/100;
    }
    
    my $women_parsi_percent=0;
    my $age_parsi_avg=0;
    my $age_parsi_stddev=0;
    if ($parsi_percent > 0) {
	my $temp = $dbh_rolls->selectrow_array("SELECT avg(age) FROM rolls  WHERE (revision21 IS NULL OR revision21 = 'N' OR revision21 = 'M') AND community = 'Parsi'",undef);
	$age_parsi_avg=int($temp*100)/100;
	
	my $temp = $dbh_rolls->selectrow_array("SELECT stddev(age) FROM rolls  WHERE (revision21 IS NULL OR revision21 = 'N' OR revision21 = 'M') AND community = 'Parsi'",undef);
	$age_parsi_stddev=int($temp*100)/100;

        my $temp1 = $dbh_rolls->selectrow_array("SELECT count(*) FROM rolls  WHERE (revision21 IS NULL OR revision21 = 'N' OR revision21 = 'M') AND gender = 'f' AND community = 'Parsi'",undef);
	my $temp2 = $dbh_rolls->selectrow_array("SELECT count(*) FROM rolls  WHERE (revision21 IS NULL OR revision21 = 'N' OR revision21 = 'M') AND gender = 'm' AND community = 'Parsi'",undef);
	if (($temp1+$temp2)>0) {$women_parsi_percent=int(($temp1/($temp1+$temp2))*10000)/100;}
    }

    my $sikh_percent=0;
    if ($identified > 0) {
	my $temp = $dbh_rolls->selectrow_array("SELECT count(*) FROM rolls  WHERE (revision21 IS NULL OR revision21 = 'N' OR revision21 = 'M') AND community = 'Sikh'",undef);
	$sikh_percent=int(($temp/$identified)*10000)/100;
    }
    
    my $women_sikh_percent=0;
    my $age_sikh_avg=0;
    my $age_sikh_stddev=0;
    if ($sikh_percent > 0) {
	my $temp = $dbh_rolls->selectrow_array("SELECT avg(age) FROM rolls  WHERE (revision21 IS NULL OR revision21 = 'N' OR revision21 = 'M') AND community = 'Sikh'",undef);
	$age_sikh_avg=int($temp*100)/100;
	
	my $temp = $dbh_rolls->selectrow_array("SELECT stddev(age) FROM rolls  WHERE (revision21 IS NULL OR revision21 = 'N' OR revision21 = 'M') AND community = 'Sikh'",undef);
	$age_sikh_stddev=int($temp*100)/100;

        my $temp1 = $dbh_rolls->selectrow_array("SELECT count(*) FROM rolls  WHERE (revision21 IS NULL OR revision21 = 'N' OR revision21 = 'M') AND gender = 'f' AND community = 'Sikh'",undef);
	my $temp2 = $dbh_rolls->selectrow_array("SELECT count(*) FROM rolls  WHERE (revision21 IS NULL OR revision21 = 'N' OR revision21 = 'M') AND gender = 'm' AND community = 'Sikh'",undef);
	if (($temp1+$temp2)>0) {$women_sikh_percent=int(($temp1/($temp1+$temp2))*10000)/100;}
    }

    my $christian_percent=0;
    if ($identified > 0) {
	my $temp = $dbh_rolls->selectrow_array("SELECT count(*) FROM rolls  WHERE (revision21 IS NULL OR revision21 = 'N' OR revision21 = 'M') AND community = 'Christian'",undef);
	$christian_percent=int(($temp/$identified)*10000)/100;
    }
    
    my $women_christian_percent=0;
    my $age_christian_avg=0;
    my $age_christian_stddev=0;
    if ($christian_percent > 0) {
	my $temp = $dbh_rolls->selectrow_array("SELECT avg(age) FROM rolls  WHERE (revision21 IS NULL OR revision21 = 'N' OR revision21 = 'M') AND community = 'Christian'",undef);
	$age_christian_avg=int($temp*100)/100;
	
	my $temp = $dbh_rolls->selectrow_array("SELECT stddev(age) FROM rolls  WHERE (revision21 IS NULL OR revision21 = 'N' OR revision21 = 'M') AND community = 'Christian'",undef);
	$age_christian_stddev=int($temp*100)/100;

        my $temp1 = $dbh_rolls->selectrow_array("SELECT count(*) FROM rolls  WHERE (revision21 IS NULL OR revision21 = 'N' OR revision21 = 'M') AND gender = 'f' AND community = 'Christian'",undef);
	my $temp2 = $dbh_rolls->selectrow_array("SELECT count(*) FROM rolls  WHERE (revision21 IS NULL OR revision21 = 'N' OR revision21 = 'M') AND gender = 'm' AND community = 'Christian'",undef);
	if (($temp1+$temp2)>0) {$women_christian_percent=int(($temp1/($temp1+$temp2))*10000)/100;}
    }
    
    my $new= $dbh_rolls->selectrow_array("SELECT count(*) FROM rolls WHERE revision21 = 'N'",undef);
    my $changed= $dbh_rolls->selectrow_array("SELECT count(*) FROM rolls WHERE revision21 = 'M'",undef);
    my $deleted= $dbh_rolls->selectrow_array("SELECT count(*) FROM rolls WHERE revision21 IS NOT NULL",undef);
    $deleted = $deleted - $new - $changed;
    
    if (($voters_total + $deleted - $new)>0) {
	my $Anew = int($new/($voters_total + $deleted - $new)*10000)/100;
	my $Adeleted = int($deleted/($voters_total + $deleted - $new)*10000)/100;
	my $changed = int($changed/($voters_total + $deleted - $new)*10000)/100;
	$deleted = $Adeleted;
	$new = $Anew;
    }

    # UPDATE PROPERLY

    $dbh_booths->do ("UPDATE booths SET  constituency = ?, voters_total = ?, missing_percent = ?, age_avg = ?, age_stddev = ?, age_muslim_avg = ?, age_muslim_stddev = ?, women_percent = ?, women_muslim_percent = ?, muslim_percent = ?, buddhist_percent = ?, age_buddhist_avg = ?, age_buddhist_stddev = ?, women_buddhist_percent = ?, hindu_percent = ?, age_hindu_avg = ?, age_hindu_stddev = ?, women_hindu_percent = ?, jain_percent = ?, age_jain_avg = ?, age_jain_stddev = ?, women_jain_percent = ?, parsi_percent = ?, age_parsi_avg = ?, age_parsi_stddev = ?, women_parsi_percent = ?, sikh_percent = ?, age_sikh_avg = ?, age_sikh_stddev = ?, women_sikh_percent = ?, christian_percent = ?, age_christian_avg = ?, age_christian_stddev = ?, women_christian_percent = ?, revision21_percent_new = ?, revision21_percent_deleted = ?, revision21_percent_modified = ? WHERE booth = ? ", undef, $constituency, $voters_total, $missing_percent, $age_avg, $age_stddev, $age_muslim_avg, $age_muslim_stddev, $women_percent, $women_muslim_percent, $muslim_percent, $buddhist_percent, $age_buddhist_avg, $age_buddhist_stddev, $women_buddhist_percent, $hindu_percent, $age_hindu_avg, $age_hindu_stddev, $women_hindu_percent, $jain_percent, $age_jain_avg, $age_jain_stddev, $women_jain_percent, $parsi_percent, $age_parsi_avg, $age_parsi_stddev, $women_parsi_percent, $sikh_percent, $age_sikh_avg, $age_sikh_stddev, $women_sikh_percent, $christian_percent, $age_christian_avg, $age_christian_stddev, $women_christian_percent,  $new, $deleted, $changed, $booth);
    
    $dbh_rolls->disconnect;
}

$dbh_booths->disconnect;
