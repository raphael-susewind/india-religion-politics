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

close (FILE);
