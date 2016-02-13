#!/usr/bin/perl -CSDA

#
# The logic here is not to perform the integration directly, but to create a upid.sql which would do the needful ;-)
# It does however run on an existing ../combined.sqlite upid table, which it then prepares to replace...
#

use DBI;
use Text::WagnerFischer 'distance';
use Text::CSV;
use List::Util 'min';
use List::MoreUtils 'indexes';

system("rm -f upid.sql");

#
# Integrate across years using name similarity measures
#

## FROM upid table itself
# 2007: station_name_07 in Kruti Dev
# 2009: station_name_09 in Kruti Dev
# 2012: station_name_12 in Latin Hindi, station_name_11 in Unicode Hindi
# 2014: station_name_14 in Latin Hindi, booth_name_14 in English
## FROM upgis table
# 2009: booth_name_09 in English
# 2012: booth_name_12 in Latin Hindi
# 2014: booth_name_14 in English

# Beware of pre/post delimitation ac_id differences
# Beware of changes in no of booths within station of same name
# Update ac_ids and station_ids where name is sufficiently clear
# Update booth_ids (which will lead to actual integration) only where boothcount is also the same

# $dbh = DBI->connect("DBI:SQLite:dbname=:memory:", "","", {sqlite_unicode=>1});
# $dbh->sqlite_backup_from_file('../combined.sqlite');

# TODO write new

# $dbh->disconnect;

#
# Then add code to actually run the compression
#

$dbh = DBI->connect("DBI:SQLite:dbname=:memory:", "","", {sqlite_unicode=>1});
$dbh->sqlite_backup_from_file('../combined.sqlite');

my $sql = $dbh->selectrow_array("SELECT sql FROM sqlite_master WHERE tbl_name='upid'");
$sql=~s/^CREATE TABLE upid \(//gs;
$sql=~s/\)$//gs;
my @headers=split(/,/,$sql);

my @concatsql;
foreach my $header (@headers) {
    $header =~ s/^\s+//gs;
    my ($name,$type) = split(/\s+/,$header);
    if ($type eq 'INTEGER') {push(@concatsql, "max($name) '$name'")}
    elsif ($type eq 'FLOAT') {push(@concatsql, "max($name) '$name'")}
    else {push(@concatsql, "group_concat(DISTINCT $name) '$name'")}
}

open (FILE, ">>upid.sql");
print FILE "CREATE TABLE temp AS SELECT ".join(", ",@concatsql)." FROM upid WHERE booth_id_07 IS NOT NULL GROUP BY ac_id_07,booth_id_07;\n";
print FILE "INSERT INTO temp SELECT * FROM upid WHERE booth_id_07 IS NULL;\n";
print FILE "DROP TABLE upid;\n";
print FILE "ALTER TABLE temp RENAME TO upid;\n";
print FILE "CREATE TABLE temp AS SELECT ".join(", ",@concatsql)." FROM upid WHERE booth_id_09 IS NOT NULL GROUP BY ac_id_09,booth_id_09;\n";
print FILE "INSERT INTO temp SELECT * FROM upid WHERE booth_id_09 IS NULL;\n";
print FILE "DROP TABLE upid;\n";
print FILE "ALTER TABLE temp RENAME TO upid;\n";
print FILE "CREATE TABLE temp AS SELECT ".join(", ",@concatsql)." FROM upid WHERE booth_id_12 IS NOT NULL GROUP BY ac_id_09,booth_id_12;\n";
print FILE "INSERT INTO temp SELECT * FROM upid WHERE booth_id_12 IS NULL;\n";
print FILE "DROP TABLE upid;\n";
print FILE "ALTER TABLE temp RENAME TO upid;\n";
print FILE "CREATE TABLE temp AS SELECT ".join(", ",@concatsql)." FROM upid WHERE booth_id_14 IS NOT NULL GROUP BY ac_id_09,booth_id_14;\n";
print FILE "INSERT INTO temp SELECT * FROM upid WHERE booth_id_14 IS NULL;\n";
print FILE "DROP TABLE upid;\n";
print FILE "ALTER TABLE temp RENAME TO upid;\n";
close (FILE);

$dbh->disconnect;

#
# Add actopc mapping
#

open (FILE, ">>upid.sql");

print FILE "ALTER TABLE upid ADD COLUMN pc_id_09 INTEGER;\n";
print FILE "ALTER TABLE upid ADD COLUMN pc_name_09 CHAR;\n";
print FILE "ALTER TABLE upid ADD COLUMN pc_reserved_09 CHAR;\n";

print FILE "BEGIN TRANSACTION;\n";

$dbh = DBI->connect("DBI:SQLite:dbname=:memory:", "","", {sqlite_unicode=>1});
$dbh->sqlite_backup_from_file('actopc.sqlite');

for ($ac=1;$ac<=403;$ac++) {
    my $ref = $dbh->selectcol_arrayref("SELECT pc FROM actopc WHERE ac = ?",undef,$ac);
    foreach my $pc (@$ref) {
	print FILE "UPDATE upid SET pc_id_09 = $pc WHERE ac_id_09 = $ac;\n";
    }
    my $ref = $dbh->selectcol_arrayref("SELECT pc_name FROM actopc WHERE ac = ?",undef,$ac);
    foreach my $pc (@$ref) {
	print FILE "UPDATE upid SET pc_name_09 = '$pc' WHERE ac_id_09 = $ac;\n";
    }
    my $ref = $dbh->selectcol_arrayref("SELECT pc_reserved FROM actopc WHERE ac = ?",undef,$ac);
    foreach my $pc (@$ref) {
	print FILE "UPDATE upid SET pc_reserved_09 = '$pc' WHERE ac_id_09 = $ac;\n";
    }
}

print FILE "COMMIT;\n";

$dbh->disconnect;

close (FILE);

#
# Add psname2partname mapping
#

open (FILE, ">>upid.sql");

print FILE "ALTER TABLE upid ADD COLUMN booth_name_14 CHAR;\n";
print FILE "ALTER TABLE upid ADD COLUMN booth_parts_14 CHAR;\n";

print FILE "CREATE INDEX upidpsname2partname ON upid (ac_id_09, booth_id_14);\n";

print FILE "BEGIN TRANSACTION;\n";

$dbh = DBI->connect("DBI:SQLite:dbname=:memory:", "","", {sqlite_unicode=>1});
$dbh->sqlite_backup_from_file('psname2partname.sqlite');

my $sth = $dbh->prepare("SELECT * FROM psname2partname");
$sth->execute();
my $oldac = 1; my $oldbooth = 1; my $concat = ''; my $name = '';
while (my $row=$sth->fetchrow_hashref) {
    if ($oldac == $row->{ac} && $oldbooth == $row->{booth}) {
	$name = $row->{booth_name};
	$concat = $concat . $row->{part} . ": " . $row->{part_name} . ", ";
    } else {
	$concat =~ s/, $//gs;
	$name =~ s/\'/\"/gs;
	$concat =~ s/\'/\"/gs;
	print FILE "UPDATE upid SET booth_name_14 = '$name' WHERE ac_id_09 = $oldac AND booth_id_14 = $oldbooth;\n";
	print FILE "UPDATE upid SET booth_parts_14 = '$concat' WHERE ac_id_09 = $oldac AND booth_id_14 = $oldbooth;\n";
	$oldac = $row->{ac};
	$oldbooth = $row->{booth};
	$name = $row->{booth_name};
	$concat = $row->{part} . ": " . $row->{part_name} . ", ";
    }
}
$sth->finish ();

print FILE "COMMIT;\n";

$dbh->disconnect;

close (FILE);

#
# Finally prepare sqlite dump 
#

open (FILE, ">>upid.sql");

print FILE ".mode csv\n";
print FILE ".headers on\n";
print FILE ".once upid/upid.csv\n";
print FILE "SELECT * FROM upid;\n";
print FILE "VACUUM;";

close (FILE);
