#!/usr/bin/perl -CSDA

if (!-e "booths.sqlite") {system("tar -xzf booths.sqlite.tgz")}

use DBD::SQLite;

#
# Create and populate temporary tables with proper table and variable names
#

$dbh = DBI->connect("DBI:SQLite:dbname=:memory:", "","", {sqlite_unicode=>1});
$dbh->sqlite_backup_from_file('booths.sqlite');
$dbh->do ("CREATE TABLE uprolls2017 (id INTEGER PRIMARY KEY AUTOINCREMENT, ac_id_09 INTEGER, booth_id_17 INTEGER, electors_17 INTEGER, missing_percent_17 FLOAT, age_avg_17 FLOAT, age_stddev_17 FLOAT, age_muslim_avg_17 FLOAT, age_muslim_stddev_17 FLOAT, women_percent_17 FLOAT, women_muslim_percent_17 FLOAT, muslim_percent_17 FLOAT, buddhist_percent_17 FLOAT, age_buddhist_avg_17 FLOAT, age_buddhist_stddev_17 FLOAT, women_buddhist_percent_17 FLOAT, hindu_percent_17 FLOAT, age_hindu_avg_17 FLOAT, age_hindu_stddev_17 FLOAT, women_hindu_percent_17 FLOAT, jain_percent_17 FLOAT, age_jain_avg_17 FLOAT, age_jain_stddev_17 FLOAT, women_jain_percent_17 FLOAT, parsi_percent_17 FLOAT, age_parsi_avg_17 FLOAT, age_parsi_stddev_17 FLOAT, women_parsi_percent_17 FLOAT, sikh_percent_17 FLOAT, age_sikh_avg_17 FLOAT, age_sikh_stddev_17 FLOAT, women_sikh_percent_17 FLOAT, christian_percent_17 FLOAT, age_christian_avg_17 FLOAT, age_christian_stddev_17 FLOAT, women_christian_percent_17 FLOAT, revision_percent_new_17 FLOAT, revision_percent_deleted_17 FLOAT, revision_percent_modified_17 FLOAT)");
$dbh->do ("INSERT INTO uprolls2017 (ac_id_09, booth_id_17, electors_17, missing_percent_17, age_avg_17, age_stddev_17, age_muslim_avg_17, age_muslim_stddev_17, women_percent_17, women_muslim_percent_17, muslim_percent_17, buddhist_percent_17, age_buddhist_avg_17, age_buddhist_stddev_17, women_buddhist_percent_17, hindu_percent_17, age_hindu_avg_17, age_hindu_stddev_17, women_hindu_percent_17, jain_percent_17, age_jain_avg_17, age_jain_stddev_17, women_jain_percent_17, parsi_percent_17, age_parsi_avg_17, age_parsi_stddev_17, women_parsi_percent_17, sikh_percent_17, age_sikh_avg_17, age_sikh_stddev_17, women_sikh_percent_17, christian_percent_17, age_christian_avg_17, age_christian_stddev_17, women_christian_percent_17, revision_percent_new_17, revision_percent_deleted_17, revision_percent_modified_17) SELECT constituency, booth, voters_total, missing_percent, age_avg, age_stddev, age_muslim_avg, age_muslim_stddev, women_percent, women_muslim_percent, muslim_percent, buddhist_percent, age_buddhist_avg, age_buddhist_stddev, women_buddhist_percent, hindu_percent, age_hindu_avg, age_hindu_stddev, women_hindu_percent, jain_percent, age_jain_avg, age_jain_stddev, women_jain_percent, parsi_percent, age_parsi_avg, age_parsi_stddev, women_parsi_percent, sikh_percent, age_sikh_avg, age_sikh_stddev, women_sikh_percent, christian_percent, age_christian_avg, age_christian_stddev, women_christian_percent, revision17_percent_new, revision17_percent_deleted, revision17_percent_modified  FROM booths");

$dbh->do ("CREATE TABLE upid (ac_id_09 INTEGER, booth_id_17 INTEGER, booth_id_14 INTEGER, booth_name_17 CHAR, address_17 CHAR, parts_17 CHAR, village_17 CHAR, panchayat_17 CHAR, block_17 CHAR, tehsil_17 CHAR, district_17 CHAR, thana_17 CHAR, postoffice_17 CHAR, pincode_17 CHAR INTEGER)");
$dbh->do ("INSERT INTO upid SELECT constituency, booth, oldbooth, trim(trim(replace(name,char(10),'-'),'-')), trim(trim(replace(address,char(10),'-'),'-')), trim(trim(replace(parts,char(10),'-'),'-')), trim(village), trim(panchayat), trim(block), trim(tehsil), trim(district), trim(thana), trim(postoffice), pincode FROM booths");

#
# Add station_id_17
#

print "Add station_id_17\n";

$dbh->do ("ALTER TABLE upid ADD COLUMN station_id_17 INTEGER");

# $dbh->do ("CREATE INDEX ac_id_09 ON upid (ac_id_09)");
$dbh->do ("CREATE INDEX booth_id_17 ON upid (booth_id_17)");

my $sth = $dbh->prepare("SELECT ac_id_09 FROM upid WHERE ac_id_09 IS NOT NULL GROUP BY ac_id_09");
$sth->execute();
my $count=0;
my %result;
while (my $row=$sth->fetchrow_hashref) {
    my $tempold='';
    my $sth2 = $dbh->prepare("SELECT booth_name_17 FROM upid WHERE ac_id_09 = ?");
    $sth2->execute($row->{ac_id_09});
    while (my $row2=$sth2->fetchrow_hashref) {
	my $temp=$row2->{booth_name_17};
	$temp=~s/\d//gs;
	next if ($temp eq $tempold);
	$tempold = $temp;
	$result{$row->{ac_id_09}.$temp}=$count;
	$count++;
    }
}
$sth->finish ();

$dbh->begin_work;

my $sth = $dbh->prepare("SELECT * FROM upid WHERE ac_id_09 IS NOT NULL");
$sth->execute();
while (my $row=$sth->fetchrow_hashref) {
    my $temp=$row->{booth_name_17};
    $temp=~s/\d//gs;
    $dbh->do ("UPDATE upid SET station_id_17 = ? WHERE ac_id_09 = ? AND booth_id_17 = ?", undef, $result{$row->{ac_id_09}.$temp}, $row->{ac_id_09}, $row->{booth_id_17});
}
$sth->finish ();

$dbh->commit;

$dbh->do ("CREATE INDEX station_id_17 ON upid (station_id_17)");


#
# Finally create sqlite dump 
#

print "Create dumps and CSV\n";

$dbh->sqlite_backup_to_file("temp.sqlite");

system("sqlite3 temp.sqlite '.dump uprolls2017' > uprolls2017-a.sql");

open (FILE, ">>uprolls2017-a.sql");

print FILE ".header on\n";
print FILE ".mode csv\n";
print FILE ".once uprolls2017/uprolls2017.csv\n";
print FILE "SELECT * FROM uprolls2017;\n";

close (FILE);

system("sqlite3 temp.sqlite '.dump upid' > uprolls2017-b.sql");

open (FILE, "uprolls2017-b.sql");
my @file = <FILE>;
close (FILE);

open (FILE, ">uprolls2017-b.sql");

print FILE "ALTER TABLE upid ADD COLUMN booth_id_17 INTEGER;\n";
print FILE "ALTER TABLE upid ADD COLUMN booth_name_17 CHAR;\n";
print FILE "ALTER TABLE upid ADD COLUMN address_17 CHAR;\n";
print FILE "ALTER TABLE upid ADD COLUMN parts_17 CHAR;\n";
print FILE "ALTER TABLE upid ADD COLUMN village_17 CHAR;\n";
print FILE "ALTER TABLE upid ADD COLUMN panchayat_17 CHAR;\n";
print FILE "ALTER TABLE upid ADD COLUMN block_17 CHAR;\n";
print FILE "ALTER TABLE upid ADD COLUMN tehsil_17 CHAR;\n";
print FILE "ALTER TABLE upid ADD COLUMN district_17 CHAR;\n";
print FILE "ALTER TABLE upid ADD COLUMN thana_17 CHAR;\n";
print FILE "ALTER TABLE upid ADD COLUMN postoffice_17 CHAR;\n";
print FILE "ALTER TABLE upid ADD COLUMN pincode_17 INTEGER;\n";
print FILE "ALTER TABLE upid ADD COLUMN station_id_17 INTEGER;\n";

my $insert;
foreach my $line (@file) {
    if ($line =~ /^CREATE TABLE upid (.*?);/) {$insert=$1; $insert=~s/ INTEGER//gs; $insert=~s/ CHAR//gs; next}
    if ($line =~ /^INSERT INTO \"upid\"/) {$line =~ s/^INSERT INTO \"upid\"/INSERT INTO \"upid\" $insert/}
    print FILE $line;
}

close (FILE);


system("rm temp.sqlite booths.sqlite");
