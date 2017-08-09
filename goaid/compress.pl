#!/usr/bin/perl -CSDA

#
# The logic here is not to perform the integration directly, but to create a goaid.sql which would do the needful ;-)
# It does however run on an existing ../combined.sqlite goaid table, which it then prepares to replace...
#

$|=1;

use DBI;

system("rm -f goaid-b.sql");

#
# Add actopc mapping
#

open (FILE, ">>goaid-b.sql");

print FILE "ALTER TABLE goaid ADD COLUMN pc_id_09 INTEGER;\n";
print FILE "ALTER TABLE goaid ADD COLUMN pc_name_09 CHAR;\n";
print FILE "ALTER TABLE goaid ADD COLUMN pc_reserved_09 CHAR;\n";
print FILE "ALTER TABLE goaid ADD COLUMN ac_name_14 CHAR;\n";
print FILE "ALTER TABLE goaid ADD COLUMN ac_reserved_14 CHAR;\n";

print FILE "BEGIN TRANSACTION;\n";

$dbh = DBI->connect("DBI:SQLite:dbname=:memory:", "","", {sqlite_unicode=>1});
$dbh->sqlite_backup_from_file('actopc.sqlite');

for ($ac=1;$ac<=294;$ac++) {
    my $ref = $dbh->selectcol_arrayref("SELECT ac_name FROM actopc WHERE ac = ?",undef,$ac);
    print FILE "UPDATE goaid SET ac_name_14 = '".@$ref[0]."' WHERE ac_id_09 = $ac;\n";
    my $ref = $dbh->selectcol_arrayref("SELECT ac_reserved FROM actopc WHERE ac = ?",undef,$ac);
    print FILE "UPDATE goaid SET ac_reserved_14 = '".@$ref[0]."' WHERE ac_id_09 = $ac;\n";
    my $ref = $dbh->selectcol_arrayref("SELECT pc FROM actopc WHERE ac = ?",undef,$ac);
    foreach my $pc (@$ref) {
	print FILE "UPDATE goaid SET pc_id_09 = $pc WHERE ac_id_09 = $ac;\n";
    }
    my $ref = $dbh->selectcol_arrayref("SELECT pc_name FROM actopc WHERE ac = ?",undef,$ac);
    foreach my $pc (@$ref) {
	print FILE "UPDATE goaid SET pc_name_09 = '$pc' WHERE ac_id_09 = $ac;\n";
    }
    my $ref = $dbh->selectcol_arrayref("SELECT pc_reserved FROM actopc WHERE ac = ?",undef,$ac);
    foreach my $pc (@$ref) {
	print FILE "UPDATE goaid SET pc_reserved_09 = '$pc' WHERE ac_id_09 = $ac;\n";
    }
}

print FILE "COMMIT;\n";

$dbh->disconnect;

close (FILE);

#
# Finally prepare sqlite dump 
#

open (FILE, ">>goaid-b.sql");

print FILE ".mode csv\n";
print FILE ".headers on\n";
print FILE ".once goaid/goaid.csv\n";
print FILE "SELECT * FROM goaid;\n";
print FILE "VACUUM;";

close (FILE);
