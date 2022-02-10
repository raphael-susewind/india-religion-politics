#!/usr/bin/perl -CSDA

if (!-e "booths.sqlite") {system("tar -xzf booths.sqlite.tgz")}

use DBD::SQLite;

#
# Create and populate temporary tables with proper table and variable names
#

$dbh = DBI->connect("DBI:SQLite:dbname=:memory:", "","", {sqlite_unicode=>1});
$dbh->sqlite_backup_from_file('booths.sqlite');
$dbh->do ("CREATE TABLE wbrolls2021 (id INTEGER PRIMARY KEY AUTOINCREMENT, ac_id_09 INTEGER, booth_id_21 INTEGER, electors_21 INTEGER, missing_percent_21 FLOAT, age_avg_21 FLOAT, age_stddev_21 FLOAT, age_muslim_avg_21 FLOAT, age_muslim_stddev_21 FLOAT, women_percent_21 FLOAT, women_muslim_percent_21 FLOAT, muslim_percent_21 FLOAT, buddhist_percent_21 FLOAT, age_buddhist_avg_21 FLOAT, age_buddhist_stddev_21 FLOAT, women_buddhist_percent_21 FLOAT, hindu_percent_21 FLOAT, age_hindu_avg_21 FLOAT, age_hindu_stddev_21 FLOAT, women_hindu_percent_21 FLOAT, jain_percent_21 FLOAT, age_jain_avg_21 FLOAT, age_jain_stddev_21 FLOAT, women_jain_percent_21 FLOAT, parsi_percent_21 FLOAT, age_parsi_avg_21 FLOAT, age_parsi_stddev_21 FLOAT, women_parsi_percent_21 FLOAT, sikh_percent_21 FLOAT, age_sikh_avg_21 FLOAT, age_sikh_stddev_21 FLOAT, women_sikh_percent_21 FLOAT, christian_percent_21 FLOAT, age_christian_avg_21 FLOAT, age_christian_stddev_21 FLOAT, women_christian_percent_21 FLOAT, revision_percent_new_21 FLOAT, revision_percent_deleted_21 FLOAT, revision_percent_modified_21 FLOAT)");
$dbh->do ("INSERT INTO wbrolls2021 (ac_id_09, booth_id_21, electors_21, missing_percent_21, age_avg_21, age_stddev_21, age_muslim_avg_21, age_muslim_stddev_21, women_percent_21, women_muslim_percent_21, muslim_percent_21, buddhist_percent_21, age_buddhist_avg_21, age_buddhist_stddev_21, women_buddhist_percent_21, hindu_percent_21, age_hindu_avg_21, age_hindu_stddev_21, women_hindu_percent_21, jain_percent_21, age_jain_avg_21, age_jain_stddev_21, women_jain_percent_21, parsi_percent_21, age_parsi_avg_21, age_parsi_stddev_21, women_parsi_percent_21, sikh_percent_21, age_sikh_avg_21, age_sikh_stddev_21, women_sikh_percent_21, christian_percent_21, age_christian_avg_21, age_christian_stddev_21, women_christian_percent_21, revision_percent_new_21, revision_percent_deleted_21, revision_percent_modified_21) SELECT constituency, booth, voters_total, missing_percent, age_avg, age_stddev, age_muslim_avg, age_muslim_stddev, women_percent, women_muslim_percent, muslim_percent, buddhist_percent, age_buddhist_avg, age_buddhist_stddev, women_buddhist_percent, hindu_percent, age_hindu_avg, age_hindu_stddev, women_hindu_percent, jain_percent, age_jain_avg, age_jain_stddev, women_jain_percent, parsi_percent, age_parsi_avg, age_parsi_stddev, women_parsi_percent, sikh_percent, age_sikh_avg, age_sikh_stddev, women_sikh_percent, christian_percent, age_christian_avg, age_christian_stddev, women_christian_percent, revision21_percent_new, revision21_percent_deleted, revision21_percent_modified  FROM booths");
$dbh->do ("CREATE TABLE wbid (ac_id_09 INTEGER, booth_id_21 INTEGER, booth_id_14 INTEGER)");
$dbh->do ("INSERT INTO wbid SELECT constituency, booth, oldbooth FROM booths");
$dbh->do ("CREATE INDEX booth_id_21 ON wbid (booth_id_21)");

#
# Finally create sqlite dump 
#

print "Create dumps and CSV\n";

$dbh->sqlite_backup_to_file("temp.sqlite");

system("sqlite3 temp.sqlite '.dump wbrolls2021' > wbrolls2021-a.sql");

open (FILE, ">>wbrolls2021-a.sql");

print FILE ".header on\n";
print FILE ".mode csv\n";
print FILE ".once wbrolls2021/wbrolls2021.csv\n";
print FILE "SELECT * FROM wbrolls2021;\n";

close (FILE);

system("sqlite3 temp.sqlite '.dump wbid' > wbrolls2021-b.sql");

open (FILE, "wbrolls2021-b.sql");
my @file = <FILE>;
close (FILE);

open (FILE, ">wbrolls2021-b.sql");

print FILE "ALTER TABLE wbid ADD COLUMN booth_id_21 INTEGER;\n";

foreach my $line (@file) {
    if ($line =~ /^INSERT INTO wbid/) {$line =~ s/^INSERT INTO wbid/INSERT INTO wbid (ac_id_09, booth_id_21, booth_id_14)/; $line =~ s/'unclear'/NULL/gs; print FILE $line;}
}

close (FILE);

system("rm temp.sqlite booths.sqlite");
