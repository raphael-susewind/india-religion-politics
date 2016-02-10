#!/usr/bin/perl -CSDA

use DBI;

use Text::WagnerFischer 'distance';
use Text::CSV;
use List::Util 'min';
use List::MoreUtils 'indexes';

system("rm -f upid.sql");

#
# Add actopc mapping
#

open (FILE, ">>upid.sql");

print FILE "ALTER TABLE upid ADD COLUMN pc_id_09 INTEGER;\n";
print FILE "ALTER TABLE upid ADD COLUMN pc_name_09 CHAR;\n";
print FILE "ALTER TABLE upid ADD COLUMN pc_reserved_09 CHAR;\n";

$dbh = DBI->connect("DBI:SQLite:dbname=:memory:", "","", {sqlite_unicode=>1});
$dbh->sqlite_backup_from_file('actopc/actopc.sqlite');

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

close (FILE);
