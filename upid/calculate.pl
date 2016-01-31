#!/usr/bin/perl -CSDA

use DBI;

use Text::WagnerFischer 'distance';
use Text::CSV;
use List::Util 'min';
use List::MoreUtils 'indexes';

#
# Finally create sqlite dump 
#

open (FILE, ">upid.sql");

print FILE ".mode csv\n";
print FILE ".headers on\n";
print FILE ".once upid.csv\n";
print FILE "SELECT * FROM upid;\n";

close (FILE);
