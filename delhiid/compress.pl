#!/usr/bin/perl -CSDA

#
# The logic here is not to perform the integration directly, but to create a delhiid.sql which would do the needful ;-)
# It does however run on an existing ../combined.sqlite delhiid table, which it then prepares to replace...
#

$|=1;

use DBI;

system("rm -f delhiid-b.sql delhiid-a.sql");

#
# Add actopc mapping
#

open (FILE, ">>delhiid-b.sql");

print FILE "ALTER TABLE delhiid ADD COLUMN pc_id_09 INTEGER;\n";
print FILE "ALTER TABLE delhiid ADD COLUMN pc_name_09 CHAR;\n";
print FILE "ALTER TABLE delhiid ADD COLUMN pc_reserved_09 CHAR;\n";
print FILE "ALTER TABLE delhiid ADD COLUMN ac_name_14 CHAR;\n";
print FILE "ALTER TABLE delhiid ADD COLUMN ac_reserved_14 CHAR;\n";

print FILE "BEGIN TRANSACTION;\n";

$dbh = DBI->connect("DBI:SQLite:dbname=:memory:", "","", {sqlite_unicode=>1});
$dbh->sqlite_backup_from_file('actopc.sqlite');

for ($ac=1;$ac<=70;$ac++) {
    my $ref = $dbh->selectcol_arrayref("SELECT pc FROM actopc WHERE ac = ?",undef,$ac);
    foreach my $pc (@$ref) {
	print FILE "UPDATE delhiid SET pc_id_09 = $pc WHERE ac_id_09 = $ac;\n";
    }
    my $ref = $dbh->selectcol_arrayref("SELECT pc_name FROM actopc WHERE ac = ?",undef,$ac);
    foreach my $pc (@$ref) {
	print FILE "UPDATE delhiid SET pc_name_09 = '$pc' WHERE ac_id_09 = $ac;\n";
    }
    my $ref = $dbh->selectcol_arrayref("SELECT pc_reserved FROM actopc WHERE ac = ?",undef,$ac);
    foreach my $pc (@$ref) {
	print FILE "UPDATE delhiid SET pc_reserved_09 = '$pc' WHERE ac_id_09 = $ac;\n";
    }
    my $ref = $dbh->selectcol_arrayref("SELECT ac_name FROM actopc WHERE ac = ?",undef,$ac);
    foreach my $pc (@$ref) {
	print FILE "UPDATE delhiid SET ac_name_14 = '$pc' WHERE ac_id_09 = $ac;\n";
    }
    my $ref = $dbh->selectcol_arrayref("SELECT ac_reserved FROM actopc WHERE ac = ?",undef,$ac);
    foreach my $pc (@$ref) {
	print FILE "UPDATE delhiid SET ac_reserved_14 = '$pc' WHERE ac_id_09 = $ac;\n";
    }
}

print FILE "COMMIT;\n";

$dbh->disconnect;

close (FILE);

#
# Compress / integrate across years
#

$dbh = DBI->connect("DBI:SQLite:dbname=../combined.sqlite", "","", {sqlite_unicode=>1});

my $sql = $dbh->selectrow_array("SELECT sql FROM sqlite_master WHERE tbl_name='delhiid'");
$sql=~s/^CREATE TABLE delhiid \(//gs;
$sql=~s/\)$//gs;
my @headers=split(/,/,$sql);

# CAREFUL: THIS NEEDS TO BE IN THE RIGHT SEQUENCE! (ie the sequence that is used in this script)
push (@headers, 'pc_id_09 INTEGER');
push (@headers, 'pc_name_09 CHAR');
push (@headers, 'pc_reserved_09 CHAR');
push (@headers, 'ac_name_14 CHAR');
push (@headers, 'ac_reserved_14 CHAR');

my @concatsql;
foreach my $header (@headers) {
    $header =~ s/^\s+//gs;
    my ($name,$type) = split(/\s+/,$header);
    next if $name eq 'CREATE';
    if ($type eq 'INTEGER') {push(@concatsql, "cast(max($name) as integer) '$name'")}
    elsif ($type eq 'FLOAT') {push(@concatsql, "cast(max($name) as float) '$name'")}
    else {push(@concatsql, "cast(group_concat(DISTINCT $name) as char) '$name'")}
}

open (FILE, ">>delhiid-b.sql");
print FILE "CREATE TABLE temp AS SELECT ".join(", ",@concatsql)." FROM delhiid WHERE booth_id_14 IS NOT NULL GROUP BY ac_id_09,booth_id_14;\n";
print FILE "INSERT INTO temp SELECT * FROM delhiid WHERE booth_id_14 IS NULL;\n";
print FILE "DROP TABLE delhiid;\n";
print FILE "ALTER TABLE temp RENAME TO delhiid;\n";
print FILE "CREATE TABLE temp AS SELECT ".join(", ",@concatsql)." FROM delhiid WHERE booth_id_21 IS NOT NULL GROUP BY ac_id_09,booth_id_21;\n";
print FILE "INSERT INTO temp SELECT * FROM delhiid WHERE booth_id_21 IS NULL;\n";
print FILE "DROP TABLE delhiid;\n";
print FILE "ALTER TABLE temp RENAME TO delhiid;\n";
close (FILE);

$dbh->disconnect;


#
# Finally prepare sqlite dump 
#

open (FILE, ">>delhiid-b.sql");

print FILE ".mode csv\n";
print FILE ".headers on\n";
print FILE ".once delhiid/delhiid.csv\n";
print FILE "SELECT * FROM delhiid;\n";
print FILE "VACUUM;";

close (FILE);
