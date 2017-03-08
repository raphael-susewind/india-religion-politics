#!/usr/bin/perl -CSDA

if (!-e "booths.sqlite") {system("tar -xzf booths.sqlite.tgz")}

use utf8;
use DBD::SQLite;

#
# Create and populate temporary tables with proper table and variable names
#

$dbh = DBI->connect("DBI:SQLite:dbname=:memory:", "","", {sqlite_unicode=>1});
$dbh->sqlite_backup_from_file('booths.sqlite');
$dbh->do ("CREATE TABLE gujrolls2014 (id INTEGER PRIMARY KEY AUTOINCREMENT, ac_id_09 INTEGER, booth_id_14 INTEGER, electors_14 INTEGER, missing_percent_14 FLOAT, age_avg_14 FLOAT, age_stddev_14 FLOAT, age_muslim_avg_14 FLOAT, age_muslim_stddev_14 FLOAT, women_percent_14 FLOAT, women_muslim_percent_14 FLOAT, muslim_percent_14 FLOAT, buddhist_percent_14 FLOAT, age_buddhist_avg_14 FLOAT, age_buddhist_stddev_14 FLOAT, women_buddhist_percent_14 FLOAT, hindu_percent_14 FLOAT, age_hindu_avg_14 FLOAT, age_hindu_stddev_14 FLOAT, women_hindu_percent_14 FLOAT, jain_percent_14 FLOAT, age_jain_avg_14 FLOAT, age_jain_stddev_14 FLOAT, women_jain_percent_14 FLOAT, parsi_percent_14 FLOAT, age_parsi_avg_14 FLOAT, age_parsi_stddev_14 FLOAT, women_parsi_percent_14 FLOAT, sikh_percent_14 FLOAT, age_sikh_avg_14 FLOAT, age_sikh_stddev_14 FLOAT, women_sikh_percent_14 FLOAT, christian_percent_14 FLOAT, age_christian_avg_14 FLOAT, age_christian_stddev_14 FLOAT, women_christian_percent_14 FLOAT)");
$dbh->do ("INSERT INTO gujrolls2014 (ac_id_09, booth_id_14, electors_14, missing_percent_14, age_avg_14, age_stddev_14, age_muslim_avg_14, age_muslim_stddev_14, women_percent_14, women_muslim_percent_14, muslim_percent_14, buddhist_percent_14, age_buddhist_avg_14, age_buddhist_stddev_14, women_buddhist_percent_14, hindu_percent_14, age_hindu_avg_14, age_hindu_stddev_14, women_hindu_percent_14, jain_percent_14, age_jain_avg_14, age_jain_stddev_14, women_jain_percent_14, parsi_percent_14, age_parsi_avg_14, age_parsi_stddev_14, women_parsi_percent_14, sikh_percent_14, age_sikh_avg_14, age_sikh_stddev_14, women_sikh_percent_14, christian_percent_14, age_christian_avg_14, age_christian_stddev_14, women_christian_percent_14) SELECT constituency, booth, voters_total, missing_percent, age_avg, age_stddev, age_muslim_avg, age_muslim_stddev, women_percent, women_muslim_percent, muslim_percent, buddhist_percent, age_buddhist_avg, age_buddhist_stddev, women_buddhist_percent, hindu_percent, age_hindu_avg, age_hindu_stddev, women_hindu_percent, jain_percent, age_jain_avg, age_jain_stddev, women_jain_percent, parsi_percent, age_parsi_avg, age_parsi_stddev, women_parsi_percent, sikh_percent, age_sikh_avg, age_sikh_stddev, women_sikh_percent, christian_percent, age_christian_avg, age_christian_stddev, women_christian_percent FROM booths");

open (FILE, ">gujrolls2014-b.sql");

print FILE "ALTER TABLE gujid ADD COLUMN pincode_14 INTEGER;\n";
print FILE "ALTER TABLE gujid ADD COLUMN booth_name_14 CHAR;\n";
print FILE "ALTER TABLE gujid ADD COLUMN address_14 CHAR;\n";
print FILE "ALTER TABLE gujid ADD COLUMN parts_14 CHAR;\n";
print FILE "ALTER TABLE gujid ADD COLUMN village_14 CHAR;\n";
print FILE "ALTER TABLE gujid ADD COLUMN ward_14 CHAR;\n";
print FILE "ALTER TABLE gujid ADD COLUMN taluk_14 CHAR;\n";
print FILE "ALTER TABLE gujid ADD COLUMN district_14 CHAR;\n";
print FILE "ALTER TABLE gujid ADD COLUMN thana_14 CHAR;\n";
print FILE "ALTER TABLE gujid ADD COLUMN revenue_14 CHAR;\n";

print FILE "BEGIN TRANSACTION;\n";

my $sth = $dbh->prepare("SELECT * FROM booths");
$sth->execute();
while (my $row=$sth->fetchrow_hashref) {
    my $parts = $row->{parts};
    my $name = $row->{name};
    my $address = $row->{address};
    my $taluk = $row->{taluk};
    $parts =~ s/\n/-/gs;
    $parts =~ s/^[ \-]+//gs;
    $parts =~ s/[ \-]+$//gs;
    $name =~ s/\n/-/gs;
    $name =~ s/^[ \-]+//gs;
    $name =~ s/[ \-]+$//gs;
    $address =~ s/\n/-/gs;
    $address =~ s/^[ \-]+//gs;
    $address =~ s/[ \-]+$//gs;
    $taluk =~ s/\n/-/gs;
    $taluk =~ s/^[ \-]+//gs;
    $taluk =~ s/[ \-]+$//gs;
    print FILE "UPDATE gujid SET pincode_14 = ".$dbh->quote($row->{pincode}).", booth_name_14 = ".$dbh->quote($name).", address_14 = ".$dbh->quote($address).", parts_14 = ".$dbh->quote($parts).", village_14 = ".$dbh->quote($row->{village}).", ward_14 = ".$dbh->quote($row->{ward}).", taluk_14 = ".$dbh->quote($taluk).", thana_14 = ".$dbh->quote($row->{thana}).", revenue_14 = ".$dbh->quote($row->{revenue}).", district_14 = ".$dbh->quote($row->{district})." WHERE ac_id_09 = ".$row->{constituency}." AND booth_id_14 = ".$row->{booth}.";\n"; 
}
$sth->finish();

print FILE "COMMIT;\n";

close (FILE);

#
# Finally create sqlite dump 
#

print "Create dumps and CSV\n";

$dbh->sqlite_backup_to_file("temp.sqlite");

system("sqlite3 temp.sqlite '.dump gujrolls2014' > gujrolls2014.sql");

system("rm temp.sqlite booths.sqlite");
