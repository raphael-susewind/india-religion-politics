#!/usr/bin/perl

if (!-e "booths.sqlite") {system("tar -xzf booths.sqlite.tgz")}

use DBD::SQLite;

#
# Create and populate temporary tables with proper table and variable names
#

$dbh = DBI->connect("DBI:SQLite:dbname=:memory:", "","", {sqlite_unicode=>1});
$dbh->sqlite_backup_from_file('booths.sqlite');
$dbh->do ("CREATE TABLE karrolls2014 (id INTEGER PRIMARY KEY AUTOINCREMENT, ac_id_09 INTEGER, booth_id_14 INTEGER, electors_14 INTEGER, missing_percent_14 FLOAT, age_avg_14 FLOAT, age_stddev_14 FLOAT, age_muslim_avg_14 FLOAT, age_muslim_stddev_14 FLOAT, women_percent_14 FLOAT, women_muslim_percent_14 FLOAT, muslim_percent_14 FLOAT, buddhist_percent_14 FLOAT, age_buddhist_avg_14 FLOAT, age_buddhist_stddev_14 FLOAT, women_buddhist_percent_14 FLOAT, hindu_percent_14 FLOAT, age_hindu_avg_14 FLOAT, age_hindu_stddev_14 FLOAT, women_hindu_percent_14 FLOAT, jain_percent_14 FLOAT, age_jain_avg_14 FLOAT, age_jain_stddev_14 FLOAT, women_jain_percent_14 FLOAT, parsi_percent_14 FLOAT, age_parsi_avg_14 FLOAT, age_parsi_stddev_14 FLOAT, women_parsi_percent_14 FLOAT, sikh_percent_14 FLOAT, age_sikh_avg_14 FLOAT, age_sikh_stddev_14 FLOAT, women_sikh_percent_14 FLOAT, christian_percent_14 FLOAT, age_christian_avg_14 FLOAT, age_christian_stddev_14 FLOAT, women_christian_percent_14 FLOAT)");
$dbh->do ("INSERT INTO karrolls2014 (ac_id_09, booth_id_14, electors_14, missing_percent_14, age_avg_14, age_stddev_14, age_muslim_avg_14, age_muslim_stddev_14, women_percent_14, women_muslim_percent_14, muslim_percent_14, buddhist_percent_14, age_buddhist_avg_14, age_buddhist_stddev_14, women_buddhist_percent_14, hindu_percent_14, age_hindu_avg_14, age_hindu_stddev_14, women_hindu_percent_14, jain_percent_14, age_jain_avg_14, age_jain_stddev_14, women_jain_percent_14, parsi_percent_14, age_parsi_avg_14, age_parsi_stddev_14, women_parsi_percent_14, sikh_percent_14, age_sikh_avg_14, age_sikh_stddev_14, women_sikh_percent_14, christian_percent_14, age_christian_avg_14, age_christian_stddev_14, women_christian_percent_14) SELECT constituency, booth, voters_total, missing_percent, age_avg, age_stddev, age_muslim_avg, age_muslim_stddev, women_percent, women_muslim_percent, muslim_percent, buddhist_percent, age_buddhist_avg, age_buddhist_stddev, women_buddhist_percent, hindu_percent, age_hindu_avg, age_hindu_stddev, women_hindu_percent, jain_percent, age_jain_avg, age_jain_stddev, women_jain_percent, parsi_percent, age_parsi_avg, age_parsi_stddev, women_parsi_percent, sikh_percent, age_sikh_avg, age_sikh_stddev, women_sikh_percent, christian_percent, age_christian_avg, age_christian_stddev, women_christian_percent FROM booths");

$dbh->do ("CREATE TABLE karid (ac_id_09 INTEGER, booth_id_14 INTEGER, booth_name_14 CHAR, address_14 CHAR, parts_14 CHAR, village_14 CHAR, thana_14 CHAR, accountant_14 CHAR, hobli_14 CHAR, taluk_14 CHAR, district_14 CHAR, pincode_14 INTEGER)");
# Rural ones
$dbh->do ("INSERT INTO karid (ac_id_09, booth_id_14, booth_name_14, address_14, parts_14, village_14, thana_14, accountant_14, hobli_14, taluk_14, district_14, pincode_14) SELECT constituency, booth, trim(trim(replace(name,char(10),'-'),'-')), trim(trim(replace(address,char(10),'-'),'-')), trim(trim(replace(parts,char(10),'-'),'-')), trim(village), trim(thana), trim(accountant), trim(hobli), trim(taluk), trim(district), pincode FROM booths WHERE district IS NOT NULL");
# Urban ones
$dbh->do ("INSERT INTO karid (ac_id_09, booth_id_14, booth_name_14, address_14, parts_14, village_14, thana_14, hobli_14, taluk_14, district_14, pincode_14) SELECT constituency, booth, trim(trim(replace(name,char(10),'-'),'-')), trim(trim(replace(address,char(10),'-'),'-')), trim(trim(replace(parts,char(10),'-'),'-')), trim(village), trim(hobli), trim(thana), trim(taluk), trim(district), pincode FROM booths WHERE district IS NULL");

#
# Finally create sqlite dump 
#

print "Create dumps and CSV\n";

$dbh->sqlite_backup_to_file("temp.sqlite");

system("sqlite3 temp.sqlite '.dump karrolls2014' > karrolls2014-a.sql");
system("sqlite3 temp.sqlite '.dump karid' > karrolls2014-b.sql");

system("rm temp.sqlite booths.sqlite");
