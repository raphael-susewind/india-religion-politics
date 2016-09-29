#!/usr/bin/perl

use DBD::SQLite;
use Text::CSV;

#
# Run the automatic parts
#

system("cat combined-1.sql | sqlite3");

#
# Include Raheel's corrections
#

$dbh = DBI->connect("DBI:SQLite:dbname=results.sqlite", "","", {sqlite_unicode=>1});
my $sth = $dbh->prepare("UPDATE main SET bjp_votes = ?, inc_votes = ?, aap_votes = ?, nota_votes = ?, total_votes = ?, valid_votes = ? WHERE ac = ? AND booth = ?");
my $sth2 = $dbh->prepare("INSERT INTO main (bjp_votes, inc_votes, aap_votes, nota_votes, total_votes, valid_votes, ac, booth) VALUES (?,?,?,?,?,?,?,?)");
$dbh->begin_work;

my $csv = Text::CSV->new();

open (CSV,"manual-corrections.csv");
my @csv=<CSV>;
close (CSV);

my $header=shift(@csv);
my $header2=shift(@csv);

foreach my $line (@csv) {
    $csv->parse($line);
    my @fields=$csv->fields();
    $sth->execute($fields[10],$fields[11],$fields[12],$fields[14],$fields[15],$fields[16],$fields[2],$fields[6]);
    if ($sth->rows==0) {$sth2->execute($fields[10],$fields[11],$fields[12],$fields[14],$fields[15],$fields[16],$fields[2],$fields[6]);}
}

$dbh->commit;
$sth->finish;
$sth2->finish;

$dbh->disconnect;

#
# Create CSVs
#

system("cat combined-2.sql | sqlite3");
