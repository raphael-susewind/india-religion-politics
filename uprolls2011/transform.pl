#!/usr/bin/perl

if (!-e "booths.sqlite") {system("tar -xzf booths.sqlite.tgz")}

use DBD::SQLite;

#
# Create and populate temporary tables with proper table and variable names
#

$dbh = DBI->connect("DBI:SQLite:dbname=:memory:", "","", {sqlite_unicode=>1});
$dbh->sqlite_backup_from_file('booths.sqlite');
$dbh->do ("CREATE TABLE uprolls2011 (id INTEGER PRIMARY KEY AUTOINCREMENT, ac_id_09 INTEGER, booth_id_12 INTEGER, electors_11 INTEGER, missing_percent_11 FLOAT, age_avg_11 FLOAT, age_stddev_11 FLOAT, age_muslim_avg_11 FLOAT, age_muslim_stddev_11 FLOAT, women_percent_11 FLOAT, women_muslim_percent_11 FLOAT, muslim_percent_11 FLOAT, buddhist_percent_11 FLOAT, age_buddhist_avg_11 FLOAT, age_buddhist_stddev_11 FLOAT, women_buddhist_percent_11 FLOAT, hindu_percent_11 FLOAT, age_hindu_avg_11 FLOAT, age_hindu_stddev_11 FLOAT, women_hindu_percent_11 FLOAT, jain_percent_11 FLOAT, age_jain_avg_11 FLOAT, age_jain_stddev_11 FLOAT, women_jain_percent_11 FLOAT, parsi_percent_11 FLOAT, age_parsi_avg_11 FLOAT, age_parsi_stddev_11 FLOAT, women_parsi_percent_11 FLOAT, sikh_percent_11 FLOAT, age_sikh_avg_11 FLOAT, age_sikh_stddev_11 FLOAT, women_sikh_percent_11 FLOAT, christian_percent_11 FLOAT, age_christian_avg_11 FLOAT, age_christian_stddev_11 FLOAT, women_christian_percent_11 FLOAT)");
$dbh->do ("INSERT INTO uprolls2011 (ac_id_09, booth_id_12, electors_11, missing_percent_11, age_avg_11, age_stddev_11, age_muslim_avg_11, age_muslim_stddev_11, women_percent_11, women_muslim_percent_11, muslim_percent_11, buddhist_percent_11, age_buddhist_avg_11, age_buddhist_stddev_11, women_buddhist_percent_11, hindu_percent_11, age_hindu_avg_11, age_hindu_stddev_11, women_hindu_percent_11, jain_percent_11, age_jain_avg_11, age_jain_stddev_11, women_jain_percent_11, parsi_percent_11, age_parsi_avg_11, age_parsi_stddev_11, women_parsi_percent_11, sikh_percent_11, age_sikh_avg_11, age_sikh_stddev_11, women_sikh_percent_11, christian_percent_11, age_christian_avg_11, age_christian_stddev_11, women_christian_percent_11) SELECT constituency, booth, voters_total, missing_percent, age_avg, age_stddev, age_muslim_avg, age_muslim_stddev, women_percent, women_muslim_percent, muslim_percent, buddhist_percent, age_buddhist_avg, age_buddhist_stddev, women_buddhist_percent, hindu_percent, age_hindu_avg, age_hindu_stddev, women_hindu_percent, jain_percent, age_jain_avg, age_jain_stddev, women_jain_percent, parsi_percent, age_parsi_avg, age_parsi_stddev, women_parsi_percent, sikh_percent, age_sikh_avg, age_sikh_stddev, women_sikh_percent, christian_percent, age_christian_avg, age_christian_stddev, women_christian_percent  FROM booths");
$dbh->do ("CREATE TABLE upid (ac_id_09 INTEGER, booth_id_12 INTEGER, district_11 CHAR, town_11 CHAR, ward_11 CHAR, thana_11 CHAR, tehsil_11 CHAR, village_11 CHAR, circlecourt_11 CHAR, station_name_11 CHAR, station_address_11 CHAR, areas_11 CHAR, pincode_11 INTEGER)");
$dbh->do ("INSERT INTO upid SELECT constituency, booth, district, town, ward, thana, tehsil, village, circlecourt, station_name, station_address, areas, pincode FROM booths");

#
# Finally create sqlite dump 
#

print "Create dumps and CSV\n";

$dbh->sqlite_backup_to_file("temp.sqlite");

system("sqlite3 temp.sqlite '.dump uprolls2011' > uprolls2011-a.sql");

system("sqlite3 temp.sqlite '.dump upid' > uprolls2011-b.sql");

open (FILE, "uprolls2011-b.sql");
my @file = <FILE>;
close (FILE);

open (FILE, ">uprolls2011-b.sql");

print FILE "ALTER TABLE upid ADD COLUMN district_11 CHAR;\n";
print FILE "ALTER TABLE upid ADD COLUMN tehsil_11 CHAR;\n";
print FILE "ALTER TABLE upid ADD COLUMN village_11 CHAR;\n";
print FILE "ALTER TABLE upid ADD COLUMN town_11 CHAR;\n";
print FILE "ALTER TABLE upid ADD COLUMN ward_11 CHAR;\n";
print FILE "ALTER TABLE upid ADD COLUMN thana_11 CHAR;\n";
print FILE "ALTER TABLE upid ADD COLUMN circlecourt_11 CHAR;\n";
print FILE "ALTER TABLE upid ADD COLUMN station_name_11 CHAR;\n";
print FILE "ALTER TABLE upid ADD COLUMN station_address_11 CHAR;\n";
print FILE "ALTER TABLE upid ADD COLUMN areas_11 CHAR;\n";
print FILE "ALTER TABLE upid ADD COLUMN pincode_11 INTEGER;\n";

my $insert;
foreach my $line (@file) {
    if ($line =~ /^CREATE TABLE upid (.*?);/) {$insert=$1;$insert=~s/CHAR//gs; $insert=~s/ INTEGER//gs; next}
    if ($line =~ /^INSERT INTO \"upid\"/) {$line =~ s/^INSERT INTO \"upid\"/INSERT INTO \"upid\" $insert/}
    print FILE $line;
}

close (FILE);

system("rm temp.sqlite booths.sqlite");
