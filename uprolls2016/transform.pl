#!/usr/bin/perl

if (!-e "booths.sqlite") {system("tar -xzf booths.sqlite.tgz")}

use DBD::SQLite;

#
# Create and populate temporary tables with proper table and variable names
#

$dbh = DBI->connect("DBI:SQLite:dbname=:memory:", "","", {sqlite_unicode=>1});
$dbh->sqlite_backup_from_file('booths.sqlite');
$dbh->do ("CREATE TABLE uprolls2016 (id INTEGER PRIMARY KEY AUTOINCREMENT, ac_id_09 INTEGER, booth_id_16 INTEGER, electors_16 INTEGER, missing_percent_16 FLOAT, age_avg_16 FLOAT, age_stddev_16 FLOAT, age_muslim_avg_16 FLOAT, age_muslim_stddev_16 FLOAT, women_percent_16 FLOAT, women_muslim_percent_16 FLOAT, muslim_percent_16 FLOAT, buddhist_percent_16 FLOAT, age_buddhist_avg_16 FLOAT, age_buddhist_stddev_16 FLOAT, women_buddhist_percent_16 FLOAT, hindu_percent_16 FLOAT, age_hindu_avg_16 FLOAT, age_hindu_stddev_16 FLOAT, women_hindu_percent_16 FLOAT, jain_percent_16 FLOAT, age_jain_avg_16 FLOAT, age_jain_stddev_16 FLOAT, women_jain_percent_16 FLOAT, parsi_percent_16 FLOAT, age_parsi_avg_16 FLOAT, age_parsi_stddev_16 FLOAT, women_parsi_percent_16 FLOAT, sikh_percent_16 FLOAT, age_sikh_avg_16 FLOAT, age_sikh_stddev_16 FLOAT, women_sikh_percent_16 FLOAT, christian_percent_16 FLOAT, age_christian_avg_16 FLOAT, age_christian_stddev_16 FLOAT, women_christian_percent_16 FLOAT, revision_percent_new_16 FLOAT, revision_percent_deleted_16 FLOAT, revision_percent_modified_16 FLOAT)");
$dbh->do ("INSERT INTO uprolls2016 (ac_id_09, booth_id_16, electors_16, missing_percent_16, age_avg_16, age_stddev_16, age_muslim_avg_16, age_muslim_stddev_16, women_percent_16, women_muslim_percent_16, muslim_percent_16, buddhist_percent_16, age_buddhist_avg_16, age_buddhist_stddev_16, women_buddhist_percent_16, hindu_percent_16, age_hindu_avg_16, age_hindu_stddev_16, women_hindu_percent_16, jain_percent_16, age_jain_avg_16, age_jain_stddev_16, women_jain_percent_16, parsi_percent_16, age_parsi_avg_16, age_parsi_stddev_16, women_parsi_percent_16, sikh_percent_16, age_sikh_avg_16, age_sikh_stddev_16, women_sikh_percent_16, christian_percent_16, age_christian_avg_16, age_christian_stddev_16, women_christian_percent_16, revision_percent_new_16, revision_percent_deleted_16, revision_percent_modified_16) SELECT constituency, booth, voters_total, missing_percent, age_avg, age_stddev, age_muslim_avg, age_muslim_stddev, women_percent, women_muslim_percent, muslim_percent, buddhist_percent, age_buddhist_avg, age_buddhist_stddev, women_buddhist_percent, hindu_percent, age_hindu_avg, age_hindu_stddev, women_hindu_percent, jain_percent, age_jain_avg, age_jain_stddev, women_jain_percent, parsi_percent, age_parsi_avg, age_parsi_stddev, women_parsi_percent, sikh_percent, age_sikh_avg, age_sikh_stddev, women_sikh_percent, christian_percent, age_christian_avg, age_christian_stddev, women_christian_percent, revision16_percent_new, revision16_percent_deleted, revision16_percent_modified  FROM booths");

#
# Finally create sqlite dump 
#

print "Create dumps and CSV\n";

$dbh->sqlite_backup_to_file("temp.sqlite");

system("sqlite3 temp.sqlite '.dump uprolls2016' > uprolls2016.sql");

system("rm temp.sqlite booths.sqlite");
