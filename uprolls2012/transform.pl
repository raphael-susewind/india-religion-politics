#!/usr/bin/perl

if (!-e "booths.sqlite") {system("tar -xzf booths.sqlite.tgz")}

use DBD::SQLite;

#
# Create and populate temporary tables with proper table and variable names
#

$dbh = DBI->connect("DBI:SQLite:dbname=:memory:", "","", {sqlite_unicode=>1});
$dbh->sqlite_backup_from_file('booths.sqlite');
$dbh->do ("CREATE TABLE uprolls2012 (id INTEGER PRIMARY KEY AUTOINCREMENT, ac_id_09 INTEGER, booth_id_12 INTEGER, electors_12 INTEGER, missing_percent_12 FLOAT, age_avg_12 FLOAT, age_stddev_12 FLOAT, age_muslim_avg_12 FLOAT, age_muslim_stddev_12 FLOAT, women_percent_12 FLOAT, women_muslim_percent_12 FLOAT, muslim_percent_12 FLOAT, buddhist_percent_12 FLOAT, age_buddhist_avg_12 FLOAT, age_buddhist_stddev_12 FLOAT, women_buddhist_percent_12 FLOAT, hindu_percent_12 FLOAT, age_hindu_avg_12 FLOAT, age_hindu_stddev_12 FLOAT, women_hindu_percent_12 FLOAT, jain_percent_12 FLOAT, age_jain_avg_12 FLOAT, age_jain_stddev_12 FLOAT, women_jain_percent_12 FLOAT, parsi_percent_12 FLOAT, age_parsi_avg_12 FLOAT, age_parsi_stddev_12 FLOAT, women_parsi_percent_12 FLOAT, sikh_percent_12 FLOAT, age_sikh_avg_12 FLOAT, age_sikh_stddev_12 FLOAT, women_sikh_percent_12 FLOAT, christian_percent_12 FLOAT, age_christian_avg_12 FLOAT, age_christian_stddev_12 FLOAT, women_christian_percent_12 FLOAT, revision_percent_new_12 FLOAT, revision_percent_deleted_12 FLOAT, revision_percent_modified_12 FLOAT)");
$dbh->do ("INSERT INTO uprolls2012 (ac_id_09, booth_id_12, electors_12, missing_percent_12, age_avg_12, age_stddev_12, age_muslim_avg_12, age_muslim_stddev_12, women_percent_12, women_muslim_percent_12, muslim_percent_12, buddhist_percent_12, age_buddhist_avg_12, age_buddhist_stddev_12, women_buddhist_percent_12, hindu_percent_12, age_hindu_avg_12, age_hindu_stddev_12, women_hindu_percent_12, jain_percent_12, age_jain_avg_12, age_jain_stddev_12, women_jain_percent_12, parsi_percent_12, age_parsi_avg_12, age_parsi_stddev_12, women_parsi_percent_12, sikh_percent_12, age_sikh_avg_12, age_sikh_stddev_12, women_sikh_percent_12, christian_percent_12, age_christian_avg_12, age_christian_stddev_12, women_christian_percent_12, revision_percent_new_12, revision_percent_deleted_12, revision_percent_modified_12) SELECT constituency, booth, voters_total, missing_percent, age_avg, age_stddev, age_muslim_avg, age_muslim_stddev, women_percent, women_muslim_percent, muslim_percent, buddhist_percent, age_buddhist_avg, age_buddhist_stddev, women_buddhist_percent, hindu_percent, age_hindu_avg, age_hindu_stddev, women_hindu_percent, jain_percent, age_jain_avg, age_jain_stddev, women_jain_percent, parsi_percent, age_parsi_avg, age_parsi_stddev, women_parsi_percent, sikh_percent, age_sikh_avg, age_sikh_stddev, women_sikh_percent, christian_percent, age_christian_avg, age_christian_stddev, women_christian_percent, revision12_percent_new, revision12_percent_deleted, revision12_percent_modified  FROM booths");

#
# Finally create sqlite dump 
#

print "Create dumps and CSV\n";

$dbh->sqlite_backup_to_file("temp.sqlite");

system("sqlite3 temp.sqlite '.dump uprolls2012' > uprolls2012.sql");

open (FILE, ">>uprolls2012.sql");

print FILE ".header on\n";
print FILE ".mode csv\n";
print FILE ".once uprolls2012/uprolls2012.csv\n";
print FILE "SELECT * FROM uprolls2012;\n";

close (FILE);


system("rm temp.sqlite booths.sqlite");
