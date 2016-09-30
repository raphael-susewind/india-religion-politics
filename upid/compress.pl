#!/usr/bin/perl -CSDA

#
# The logic here is not to perform the integration directly, but to create a upid.sql which would do the needful ;-)
# It does however run on an existing ../combined.sqlite upid table, which it then prepares to replace...
#

$|=1;

use DBI;
use Text::WagnerFischer 'distance';
use Text::CSV;
use List::Util 'min';
use List::MoreUtils 'indexes';

system("rm -f upid-b.sql upid-a.sql");

#
# Add actopc mapping
#

open (FILE, ">>upid-b.sql");

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

open (FILE, ">>upid-b.sql");

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
# Integrate across years using name similarity measures
#

## Note: Integration from 2011 onwards is best done using voter IDs in the electoral rolls - ie via uprolls* tables (2011-2013 IDs did not change, 2013-2014, this was first implemented)
## Note: So the real question is how to get from pre to post delim, and how to get from 2009 to 2011-> for this, I use this crappy old code from years back. Its a dirty hack. It works. I have not changed it since.

## Since this code is terribly inefficient and takes ours to run: run only if upid-a.sqlite does not yet exist...

if (!-e "upid-a.sqlite") {

    $dbh = DBI->connect("DBI:SQLite:dbname=:memory:", "","", {sqlite_unicode=>1});
    $dbh->do("PRAGMA journal_mode=WAL;");
    
    $dbh->sqlite_backup_from_file('../combined.sqlite');
    
    # this code was written for an earlier table structure, so we have to pretend a bit...
    
    $dbh->do("CREATE TABLE booths (id INTEGER PRIMARY KEY AUTOINCREMENT, ac_id_07 INTEGER, ac_name_07 CHAR, ac_reserved_07 CHAR, station_id_07 INTEGER, station_name_07 CHAR, booth_id_07 INTEGER, electors_07 INTEGER, ac_id_09 INTEGER, ac_name_09 CHAR, ac_reserved_09 CHAR, station_id_09 INTEGER, station_name_09 CHAR, booth_id_09 INTEGER, electors_09 INTEGER, ac_id_12 INTEGER, ac_name_12 CHAR, ac_reserved_12 CHAR, station_id_12 INTEGER, station_name_12 CHAR, booth_id_12 INTEGER, electors_12 INTEGER)");
    
    $dbh->do("INSERT INTO booths (ac_id_07, ac_name_07, ac_reserved_07, station_id_07, station_name_07, booth_id_07, electors_07, ac_id_09, ac_name_09, ac_reserved_09, station_id_09, station_name_09, booth_id_09, electors_09, ac_id_12, ac_name_12, ac_reserved_12, station_id_12, station_name_12, booth_id_12, electors_12) SELECT upid.ac_id_07, upid.ac_name_07, upid.ac_reserved_07,  upid.station_id_07, upid.station_name_07, upid.booth_id_07, upvidhansabha2007.electors_07, upid.ac_id_09, upid.ac_name_09, upid.ac_reserved_09, upid.station_id_09, upid.station_name_09, upid.booth_id_09, uploksabha2009.electors_09, upid.ac_id_09,  upid.ac_name_12, upid.ac_reserved_12, upid.station_id_12, upid.station_name_12, upid.booth_id_12, upvidhansabha2012.electors_12 FROM upid LEFT JOIN upvidhansabha2007 ON upid.ac_id_07 = upvidhansabha2007.ac_id_07 AND upid.booth_id_07 = upvidhansabha2007.booth_id_07 LEFT JOIN uploksabha2009 ON upid.ac_id_09 = uploksabha2009.ac_id_09 AND upid.booth_id_09 = uploksabha2009.booth_id_09 LEFT JOIN upvidhansabha2012 ON upid.ac_id_09 = upvidhansabha2012.ac_id_09 AND upid.booth_id_12 = upvidhansabha2012.booth_id_12");
    
    $dbh->do("DELETE FROM booths WHERE station_id_07 IS NULL AND station_id_09 IS NULL AND station_id_12 IS NULL");
    
    $dbh->do ("CREATE INDEX ac_station_id_09_12 ON booths (ac_id_09, station_id_09, station_id_12)");
    $dbh->do ("CREATE INDEX ac_station_id_09_12_b ON booths (ac_id_12, station_id_09, station_id_12)");
    $dbh->do ("CREATE INDEX ac_station_id_07_12 ON booths (ac_id_07, station_id_07, station_id_12)");
    $dbh->do ("CREATE INDEX ac_station_id_07_12_b ON booths (ac_id_12, station_id_07, station_id_12)");
    $dbh->do ("CREATE INDEX ac_station_id_07_09 ON booths (ac_id_07, station_id_07, station_id_09)");
    $dbh->do ("CREATE INDEX ac_station_id_07_09_b ON booths (ac_id_09, station_id_07, station_id_09)");
    $dbh->do ("CREATE INDEX station_id_09_12 ON booths (station_id_09, station_id_12)");
    $dbh->do ("CREATE INDEX station_id_07_12 ON booths (station_id_07, station_id_12)");
    $dbh->do ("CREATE INDEX station_id_07_09 ON booths (station_id_07, station_id_09)");
    $dbh->do ("CREATE INDEX station_id_09_ind ON booths (station_id_09)");
    $dbh->do ("CREATE INDEX station_id_07_ind ON booths (station_id_07)");
    $dbh->do ("CREATE INDEX station_id_12_ind ON booths (station_id_12)");
    
    $dbh->do("ALTER TABLE upgis ADD COLUMN ac_id_12 INTEGER");
    $dbh->do("UPDATE upgis SET ac_id_12 = ac_id_09");

    # Cleanup unnecessary tables a bit
    
    $sth = $dbh->prepare("SELECT name FROM sqlite_master WHERE name != 'booths' AND name != 'upgis' AND name != 'upid' AND type = 'table'");
    $sth->execute();
    my @names;
    while (my $row=$sth->fetchrow_hashref) {push (@names, $row->{name})}
    $sth->finish();
    foreach my $name (@names) {next if $name =~ /sqlite/; $dbh->do("DROP TABLE $name")}
    $dbh->do("VACUUM");
    
    # Next Step: Read delimitation changes from 2007 to 2009.

    print "Reading pre/post delimitation constituencies\n";
    
    open (CSV,"delimitation.csv");
    my @csv=<CSV>;
    shift (@csv);
    close (CSV);
    
    $dbh->do ("CREATE TABLE delimitation (old INTEGER, new INTEGER, aggregate INTEGER)");
    
    $dbh->begin_work;
    
    foreach my $csv (@csv) {
	chomp ($csv);
	my ($old, $new, $aggregate) = split (/,/,$csv);
	$dbh->do("INSERT INTO delimitation VALUES (?,?,?)",undef,$old,$new,$aggregate);
    }
    
    $dbh->commit;

    # First attempt to match 2012 with 2009 ones - later we try to merge further with 2007 ones...
    
    print "Merging Booths from 2012 and 2009\n";
    
    my $sql = $dbh->selectrow_array("SELECT sql FROM sqlite_master WHERE tbl_name='booths'");
    $sql=~s/^CREATE TABLE booths \(id INTEGER PRIMARY KEY AUTOINCREMENT, //gs;
    $sql=~s/\)$//gs;
    my @headers=split(/,/,$sql);
    my $updatesql=''; 
    foreach my $header (@headers) {
	$header=~s/^\s*(.*?)\s.*/$1/gs;
	$updatesql .= "$header = coalesce($header,?), ";
    }
    $updatesql =~ s/, $//gs;
      
    $dbh->do ("ALTER TABLE booths ADD COLUMN merge_score_12_09 FLOAT");
    
    my $sth = $dbh->prepare("SELECT ac_id_12 FROM booths WHERE ac_id_12 IS NOT NULL GROUP BY ac_id_12");
    $sth->execute();
    undef(my @constituencies12); undef(my @constituencies09); 
    while (my $row=$sth->fetchrow_hashref) {
	push(@constituencies12,'ac_id_12 = '.$row->{ac_id_12});
	push(@constituencies09,'ac_id_09 = '.$row->{ac_id_12});
    }
    $sth->finish();
    
    for ($p=0;$p<scalar(@constituencies12);$p++) {
	my $constituency12 = $constituencies12[$p];
	my $constituency09 = $constituencies09[$p];

        # Figure out which scripts / languages are used, and equalize using upgis table wherever necessary and possible

	my $lang12 = $dbh->selectrow_array("SELECT group_concat(station_name_12) FROM booths WHERE $constituency12 GROUP BY ac_id_12");
	my $lang09 = $dbh->selectrow_array("SELECT group_concat(station_name_09) FROM booths WHERE $constituency09 GROUP BY ac_id_09");
	if ($lang12 =~ /[\]\[<>]/gs && $lang12 =~ /\;/gs) {$lang12='krutidev'} elsif ($lang12 !~ /^\s*$/) {$lang12='latin'} else {$lang12='unknown script'}
	if ($lang09 =~ /[\]\[<>]/gs && $lang09 =~ /\;/gs) {$lang09='krutidev'} elsif ($lang09 !~ /^\s*$/) {$lang09='latin'} else {$lang09='unknown script'}
	my $lang09gis = $dbh->selectrow_array("SELECT group_concat(booth_name_09) FROM upgis WHERE $constituency09 GROUP BY ac_id_09");
	my $lang12gis = 'latin';
	if ($lang09gis =~ /\]/gs && $lang09gis =~ /\;/gs) {$lang09gis='krutidev'} elsif ($lang09gis !~ /^\s*$/) {$lang09gis='latin'} else {$lang09gis='unknown script'}

	if ($lang12 ne $lang09 && $lang12 ne $lang09gis && $lang12gis ne $lang09) {
	    $constituency12 =~ s/.*?(\d+)$/$1/gs;
	    print  '  Constituency '.$constituency12.": matching pointless, because 2012 is in $lang12 (GIS in ".$lang12gis.") and 2009 in $lang09 (GIS in ".$lang09gis.")\n";
	    next;
	}
	
	# get list of stations with booth count for 2012, should be consecutive otherwise counts as new station (i.e. based on id rather than name)
	my $sth = $dbh->prepare('SELECT station_id_12, station_name_12, count(station_id_12), sum(electors_12), min(booth_id_12) FROM booths WHERE ('.$constituency12.') AND station_id_12 IS NOT NULL AND station_id_09 IS NULL GROUP BY station_id_12');
	$sth->execute();
	undef(my @stationid12); undef(my @stationname12); undef(my @boothcount12); undef(my @electors12); undef(my $electorsavg12);
	while (my @row=$sth->fetchrow_array) {
	    push (@stationid12, $row[0]);
	    if ($lang12 ne $lang09 && $lang12gis eq $lang09 && $lang09 ne 'unknown') {$row[1] = $dbh->selectrow_array("select booth_name_14 from (select booth_name_14 from upgis where $constituency09 and booth_id_14 = (select min(booth_id_14) from upid where $constituency09 and booth_id_12 = ".$row[4].") UNION ALL select booth_name_12 from upgis where $constituency09 and booth_id_12 = ".$row[4].") where booth_name_14 is not null limit 1")} 
	    push (@stationname12, $row[1]);
	    push (@boothcount12, $row[2]);
	    push (@electors12, $row[3]);
	    $electorsavg12 = $electorsavg12 + $row[3];
	}
	$sth->finish();
	
	if (scalar(@electors12) == 0) {next}
	
	$electorsavg12 = $electorsavg12 / scalar(@electors12);
	
	# get list of stations with booth count for 2009, should be consecutive otherwise counts as new station (i.e. based on id rather than name)
	my $sth = $dbh->prepare('SELECT station_id_09, station_name_09, count(station_id_09), sum(electors_09), min(booth_id_09) FROM booths WHERE ('.$constituency09.') AND station_id_09 IS NOT NULL AND station_id_12 IS NULL GROUP BY station_id_09');
	$sth->execute();
	undef(my @stationid09); undef(my @stationname09); undef(my @boothcount09); undef(my @electors09); undef(my $electorsavg09);
	while (my @row=$sth->fetchrow_array) {
	    push (@stationid09, $row[0]);
	    if ($lang12 ne $lang09 && $lang12gis ne $lang09 && $lang09gis eq $lang12 && $lang12 ne 'unknown') {$row[1] = $dbh->selectrow_array("SELECT booth_name_09 FROM upgis WHERE $constituency09 AND booth_id_09 = ".$row[4]." AND booth_name_09 is not null LIMIT 1");} 
	    push (@stationname09, $row[1]);
	    push (@boothcount09, $row[2]);
	    push (@electors09, $row[3]);
	    $electorsavg09 = $electorsavg09 + $row[3];
	}
	$sth->finish();
	
	if (scalar(@electors09) == 0) {next}
	
	$electorsavg09 = $electorsavg09 / scalar(@electors09);
	
	if ($electorsavg12 == 0) {next}
	
	my $electorsavgdiff = ($electorsavg12-$electorsavg09) / $electorsavg12;

	# Crawl through 2012 stations and calculate scores
	undef(my %score);
	for ($i=0;$i<scalar(@stationid12);$i++) {
	    my @namesimilarity = distance([0,1,1],$stationname12[$i], @stationname09); 
	    my $ipercent = $i/scalar(@stationid12); 
	    undef(my %tempscore);
	    # THIS IS THE CRUCIAL SCORE FORMULA - TWEAK IT TIL OPTIMUM!! (weights decided by experimentation with Lucknow constituencies)
	    # THIS IS SUBOPTIMAL SO FAR - BUT I RAN OUT OF TIME. Next idea: use the listdistance > 0.95 and namesimilarity > .25 to create "sure" matches, and then try to recreate these sure matches without listdistance by automatically tweaking weighing factors and the whole formula til we get optimum results. Then use these weights to determine score for everything below that listdistance...
	    for ($u=0;$u<scalar(@stationid09);$u++) {
		my $boothequiv = 0; my $electorsdiff = 0; 
		my $namesimilarity = 0;
		if (length($stationname09[$u]) != 0) {$namesimilarity = 1-abs($namesimilarity[$u] + distance([0,1,1],$stationname09[$u],$stationname12[$i]))/2/length($stationname09[$u]);}
		my $listdistance=(1-abs($ipercent-$u/scalar(@stationid09))); 
		# All of these weights are between 1 (optimum) and 0 (minimum)
		if ($listdistance > 0.95 && $namesimilarity == 1 ) {
		    $tempscore{$i."-".$u} = 20;
		} elsif ($listdistance > 0.95 && $namesimilarity > 0.25 ) {
		    if ($boothcount12[$i] == $boothcount09[$i]) {$boothequiv=1} else {$boothequiv=0.75}
		    if (length($stationname09[$u]) == 0 || length($stationname12[$i]) == 0) {$namesimilarity=0.25}
		    if (1+abs( ($electors12[$i]-$electors09[$u])/$electors12[$i] - $electorsavgdiff ) != 0) {$electorsdiff = 0.25 + 1/(1+abs( ($electors12[$i]-$electors09[$u])/$electors12[$i] - $electorsavgdiff )) / 2;}
		    if ($boothequiv * $namesimilarity * $electorsdiff * 2 > 0.15) {$tempscore{$i."-".$u} = $boothequiv * $namesimilarity * $listdistance * $electorsdiff;}
		} elsif ($namesimilarity == 1) {
		    $tempscore{$i."-".$u} = 15; 
		}
	    }
	    # put the top three matches for this station into %score (where the second best would be used in case the very best fits even better elsewhere etc)
	    my @tempscore = sort {$tempscore{$b} <=> $tempscore{$a}} keys(%tempscore);
	    if (scalar(@tempscore) >= 1) {$score{$tempscore[0]} = $tempscore{$tempscore[0]};}
	    if (scalar(@tempscore) >= 2) {$score{$tempscore[1]} = $tempscore{$tempscore[1]};}
	    if (scalar(@tempscore) >= 3) {$score{$tempscore[2]} = $tempscore{$tempscore[2]};}
	}

	$dbh->begin_work;
	
	# Now do the actual matching

	undef(my %matched12); undef(my %matched09); my $stationmatch=0;
	foreach my $score (sort {$score{$b} <=> $score{$a}} keys(%score)) {
	    $score=~/(\d+)-(.+)/;
	    my $id12=$1; my $id09=$2;
	    next if ($matched12{$id12} == 1 || $matched09{$id09} == 1); 
	    $matched12{$id12}=1; $matched09{$id09}=1;
	    
	    # Now do the actual integration
	    if ($boothcount12[$id12] == $boothcount09[$id09]) { # We have a full match
		my $sth3 = $dbh->prepare("SELECT * FROM booths WHERE station_id_09 = ? AND station_id_12 IS NULL");
		$sth3->execute($stationid09[$id09]);
		my $sth4 = $dbh->prepare("SELECT * FROM booths WHERE station_id_12 = ? AND station_id_09 IS NULL");
		$sth4->execute($stationid12[$id12]);
		while (my @row3=$sth3->fetchrow_array) {
		    my @row4=$sth4->fetchrow_array;
		    my $oldid=shift @row4; pop @row4; # this is for ID and for the yet empty merge_score_12_09, which needs not be updated...
		    $dbh->do ("UPDATE booths SET $updatesql, merge_score_12_09 = ? WHERE id = ?",undef, @row4, $score{$score}, $row3[0]);
		    $dbh->do ("DELETE FROM booths WHERE id = ?",undef,$oldid);
		}
		$sth3->finish(); $sth4->finish();
	    } else { # We have a station match only, but booth counts differ
		my $old = $dbh->selectrow_hashref("SELECT * from booths WHERE station_id_09 = ?",undef,$stationid09[$id09]);
		my $new = $dbh->selectrow_hashref("SELECT * from booths WHERE station_id_12 = ?",undef,$stationid12[$id12]);
		$dbh->do ("UPDATE booths SET ac_id_12 = ?, ac_name_12 = ?, ac_reserved_12 = ?, station_id_12 = ?, station_name_12 = ? WHERE station_id_09 = ?", undef, $new->{ac_id_12}, $new->{ac_name_12}, $new->{ac_reserved_12}, $new->{station_id_12}, $new->{station_name_12}, $stationid09[$id09]);
		$dbh->do ("UPDATE booths SET ac_id_09 = ?, ac_name_09 = ?, ac_reserved_09 = ?, station_id_09 = ?, station_name_09 = ? WHERE station_id_12 = ?", undef, $old->{ac_id_09}, $old->{ac_name_09}, $old->{ac_reserved_09}, $old->{station_id_09}, $old->{station_name_09}, $stationid12[$id12]);
		$stationmatch++;
	    }
	}
	
	$dbh->commit;
	
	$constituency12 =~ s/.*?(\d+)$/$1/gs;
	print  '  Constituency '.$constituency12.": matched ".int(scalar(keys(%matched12))/scalar(@stationid12)*100)."% of 2012 stations (in $lang12, GIS in ".$lang12gis.") (".int($stationmatch/(scalar(keys(%matched12))+1)*100)."% of which only station-wise) to ".int(scalar(keys(%matched09))/scalar(@stationid09)*100)."% of 2009 stations (in $lang09, GIS in ".$lang09gis.")\n";
    }
    
    # Now integrate further by looking at 07 and 12 data
      
    print "Merging Booths from 2012 and 2007\n";
    
    my $sql = $dbh->selectrow_array("SELECT sql FROM sqlite_master WHERE tbl_name='booths'");
    $sql=~s/^CREATE TABLE booths \(id INTEGER PRIMARY KEY AUTOINCREMENT, //gs;
    $sql=~s/\)$//gs;
    my @headers=split(/,/,$sql);
    my $updatesql=''; 
    foreach my $header (@headers) {
	$header=~s/^\s*(.*?)\s.*/$1/gs;
	$updatesql .= "$header = coalesce($header,?), ";
    }
    $updatesql =~ s/, $//gs;
    
    $dbh->do ("ALTER TABLE booths ADD COLUMN merge_score_12_07 FLOAT");
    
    my $sth = $dbh->prepare("SELECT ac_id_12 FROM booths WHERE ac_id_12 IS NOT NULL GROUP BY ac_id_12");
    $sth->execute();
    undef(my @constituencies12); undef(my @constituencies07); 
    while (my $row=$sth->fetchrow_hashref) {
	push(@constituencies12,'ac_id_12 = '.$row->{ac_id_12});
	my @constituencyold = $dbh->selectrow_array("SELECT old from delimitation WHERE new = ?",undef,$row->{ac_id_12});
	my $oldconstituency=join (' OR ac_id_07 = ', @constituencyold);
	$oldconstituency='ac_id_07 = '.$oldconstituency;
	push(@constituencies07,$oldconstituency);
    }
    $sth->finish();
    
    for ($p=1;$p<scalar(@constituencies12);$p++) { 
	my $constituency12 = $constituencies12[$p];
	my $constituency07 = $constituencies07[$p];
	my $constituency09 = $constituency12;
	$constituency09 =~ s/12/09/gs;
	
	# Figure out which scripts / languages are used, and equalize using upgis table wherever necessary and possible
	
	my $lang12 = $dbh->selectrow_array("SELECT group_concat(station_name_12) FROM booths WHERE $constituency12 GROUP BY ac_id_12");
	my $lang12gis = 'latin';
	my $lang07 = $dbh->selectrow_array("SELECT group_concat(station_name_07) FROM booths WHERE $constituency07 GROUP BY ac_id_07");
	if ($lang12 =~ /[\]\[<>]/gs && $lang12 =~ /\;/gs) {$lang12='krutidev'} elsif ($lang12 !~ /^\s*$/) {$lang12='latin'} else {$lang12='unknown script'}
	if ($lang07 =~ /[\]\[<>]/gs && $lang07 =~ /\;/gs) {$lang07='krutidev'} elsif ($lang07 !~ /^\s*$/) {$lang07='latin'} else {$lang07='unknown script'}

	if ($lang12 ne $lang07 && $lang12gis ne $lang07) {
	    $constituency12 =~ s/.*?(\d+)$/$1/gs;
	    print  '  Constituency '.$constituency12.": matching pointless, because 2012 is in $lang12 (GIS in ".$lang12gis.") and 2007 in $lang07\n";
	    next;
	}
	
	# manual tweak for data errors
	next if $constituency07 !~ /\d$/;
	
	# get list of stations with booth count for 2012, should be consecutive otherwise counts as new station (i.e. based on id rather than name)
	my $sth = $dbh->prepare('SELECT station_id_12, station_name_12, count(station_id_12), sum(electors_12), min(booth_id_12) FROM booths WHERE ('.$constituency12.') AND station_id_12 IS NOT NULL AND station_id_07 IS NULL GROUP BY station_id_12');
	$sth->execute();
	undef(my @stationid12); undef(my @stationname12); undef(my @boothcount12); undef(my @electors12); undef(my $electorsavg12);
	while (my @row=$sth->fetchrow_array) {
	    push (@stationid12, $row[0]);
	    if ($lang12 ne $lang07 && $lang12gis eq $lang07 && $lang07 ne 'unknown') {$row[1] = $dbh->selectrow_array("select booth_name_14 from (select booth_name_14 from upgis where $constituency09 and booth_id_14 = (select min(booth_id_14) from upid where $constituency09 and booth_id_12 = ".$row[4].") UNION ALL select booth_name_12 from upgis where $constituency09 and booth_id_12 = ".$row[4].") where booth_name_14 is not null limit 1")} 
	    push (@stationname12, $row[1]);
	    push (@boothcount12, $row[2]);
	    push (@electors12, $row[3]);
	    $electorsavg12 = $electorsavg12 + $row[3];
	}
	$sth->finish();
	
	if (scalar(@electors12) == 0) {next}
	
	$electorsavg12 = $electorsavg12 / scalar(@electors12);
	
	# get list of stations with booth count for 2007, should be consecutive otherwise counts as new station (i.e. based on id rather than name)
	my $sth = $dbh->prepare('SELECT station_id_07, station_name_07, count(station_id_07), sum(electors_07) FROM booths WHERE ('.$constituency07.') AND station_id_07 IS NOT NULL AND station_id_12 IS NULL GROUP BY station_id_07');
	$sth->execute();
	undef(my @stationid07); undef(my @stationname07); undef(my @boothcount07); undef(my @electors07); undef(my $electorsavg07);
	while (my @row=$sth->fetchrow_array) {
	    push (@stationid07, $row[0]);
	    push (@stationname07, $row[1]);
	    push (@boothcount07, $row[2]);
	    push (@electors07, $row[3]);
	    $electorsavg07 = $electorsavg07 + $row[3];
	}
	$sth->finish();
	# Makes no sense to do this if this constituency has no stations in 2007...
	if (scalar(@electors07) == 0) {next}
	
	$electorsavg07 = $electorsavg07 / scalar(@electors07);
	
	if ($electorsavg12 == 0) {next}
	
	my $electorsavgdiff = ($electorsavg12-$electorsavg07) / $electorsavg12;
	
	# Crawl through 2012 stations and calculate scores
	undef(my %score);
	for ($i=0;$i<scalar(@stationid12);$i++) {
	    my @namesimilarity = distance([0,1,1],$stationname12[$i], @stationname07); 
	    my $ipercent = $i/scalar(@stationid12); 
	    undef(my %tempscore);
	    # THIS IS THE CRUCIAL SCORE FORMULA - TWEAK IT TIL OPTIMUM!! (weights decided by experimentation with Lucknow constituencies)
	    # THIS IS SUBOPTIMAL SO FAR - BUT I RAN OUT OF TIME. Next idea: use the listdistance > 0.95 and namesimilarity > .25 to create "sure" matches, and then try to recreate these sure matches without listdistance by automatically tweaking weighing factors and the whole formula til we get optimum results. Then use these weights to determine score for everything below that listdistance...
	    for ($u=0;$u<scalar(@stationid07);$u++) {
		my $boothequiv = 0; my $electorsdiff = 0; 
		my $namesimilarity = 0;
		if (length($stationname07[$u]) != 0) {$namesimilarity = 1-abs($namesimilarity[$u] + distance([0,1,1],$stationname07[$u],$stationname12[$i]))/2/length($stationname07[$u]);}
		my $listdistance=(1-abs($ipercent-$u/scalar(@stationid07))); 
		# All of these weights are between 1 (optimum) and 0 (minimum)
		if ($listdistance > 0.9 && $namesimilarity == 1 ) {
		    $tempscore{$i."-".$u} = 20;
		} elsif ($listdistance > 0.9 && $namesimilarity > 0.7 ) {
		    if ($boothcount12[$i] == $boothcount07[$i]) {$boothequiv=1} else {$boothequiv=0.9}
		    if (length($stationname07[$u]) == 0 || length($stationname12[$i]) == 0) {$namesimilarity=0.25}
		    if (1+abs( ($electors12[$i]-$electors07[$u])/$electors12[$i] - $electorsavgdiff ) != 0) {$electorsdiff = 0.9 + 1/(1+abs( ($electors12[$i]-$electors07[$u])/$electors12[$i] - $electorsavgdiff )) / 10;}
		    if ($boothequiv * $namesimilarity * $electorsdiff * 2 > 0.5) {$tempscore{$i."-".$u} = $boothequiv * $namesimilarity * $listdistance * $electorsdiff;}
		} elsif ($namesimilarity == 1) {
		    $tempscore{$i."-".$u} = 15; 
		}
	    }
	    # put the top three matches for this station into %score (where the second best would be used in case the very best fits even better elsewhere etc)
	    my @tempscore = sort {$tempscore{$b} <=> $tempscore{$a}} keys(%tempscore);
	    if (scalar(@tempscore) >= 1) {$score{$tempscore[0]} = $tempscore{$tempscore[0]};}
	    if (scalar(@tempscore) >= 2) {$score{$tempscore[1]} = $tempscore{$tempscore[1]};}
	    if (scalar(@tempscore) >= 3) {$score{$tempscore[2]} = $tempscore{$tempscore[2]};}
	}
	
	# Now do the actual matching
	
	$dbh->begin_work;
	undef(my %matched12); undef(my %matched07); my $stationmatch=0;
	foreach my $score (sort {$score{$b} <=> $score{$a}} keys(%score)) {
	    $score=~/(\d+)-(.+)/;
	    my $id12=$1; my $id07=$2; 
	    next if ($matched12{$id12} == 1 || $matched07{$id07} == 1); 
	    $matched12{$id12}=1; $matched07{$id07}=1;
	    
	    
	    # Now do the actual integration
	    if ($boothcount12[$id12] == $boothcount07[$id07]) { # We have a full match
		my $sth3 = $dbh->prepare("SELECT * FROM booths WHERE station_id_07 = ? AND station_id_12 IS NULL");
		$sth3->execute($stationid07[$id07]);
		my $sth4 = $dbh->prepare("SELECT * FROM booths WHERE station_id_12 = ? AND station_id_07 IS NULL");
		$sth4->execute($stationid12[$id12]);
		while (my @row3=$sth3->fetchrow_array) {
		    my @row4=$sth4->fetchrow_array;
		    my $oldid=shift @row4; pop @row4; # this is for ID, which needs not be updated and for yet empty merge_score...
		    $dbh->do ("UPDATE booths SET $updatesql , merge_score_12_07 = ? WHERE id = ?",undef, @row4, $score{$score}, $row3[0]);
		    $dbh->do ("DELETE FROM booths WHERE id = ?",undef,$oldid);
		}
		$sth3->finish(); $sth4->finish();
	    } else { # We have a station match only, but booth counts differ
		my $old = $dbh->selectrow_hashref("SELECT * from booths WHERE station_id_07 = ?",undef,$stationid07[$id07]);
		my $new = $dbh->selectrow_hashref("SELECT * from booths WHERE station_id_12 = ?",undef,$stationid12[$id12]);
		$dbh->do ("UPDATE booths SET ac_id_12 = ?, ac_name_12 = ?, ac_reserved_12 = ?, station_id_12 = ?, station_name_12 = ? WHERE station_id_07 = ?", undef, $new->{ac_id_12}, $new->{ac_name_12}, $new->{ac_reserved_12}, $new->{station_id_12}, $new->{station_name_12}, $stationid07[$id07]);
		$dbh->do ("UPDATE booths SET ac_id_07 = ?, ac_name_07 = ?, ac_reserved_07 = ?, station_id_07 = ?, station_name_07 = ? WHERE station_id_12 = ?", undef, $old->{ac_id_07}, $old->{ac_name_07}, $old->{ac_reserved_07}, $old->{station_id_07}, $old->{station_name_07}, $stationid12[$id12]);
		$stationmatch++;
	    }
	}
	
	$dbh->commit;
	
	$constituency12 =~ s/.*?(\d+)$/$1/gs;
	print  '  Constituency '.$constituency12.": matched ".int(scalar(keys(%matched12))/scalar(@stationid12)*100)."% of 2012 stations (in $lang12) (GIS in ".$lang12gis.") (".int($stationmatch/(scalar(keys(%matched12))+1)*100)."% of which only station-wise) to ".int(scalar(keys(%matched07))/scalar(@stationid07)*100)."% of 2007 stations (in $lang07)\n";
    }
    
    # Now integrate further by looking at 07 and 09 data
    
    print "Merging Booths from 2009 and 2007\n";
    
    my $sql = $dbh->selectrow_array("SELECT sql FROM sqlite_master WHERE tbl_name='booths'");
    $sql=~s/^CREATE TABLE booths \(id INTEGER PRIMARY KEY AUTOINCREMENT, //gs;
    $sql=~s/\)$//gs;
    my @headers=split(/,/,$sql);
    my $updatesql=''; 
    foreach my $header (@headers) {
    $header=~s/^\s*(.*?)\s.*/$1/gs;
	$updatesql .= "$header = coalesce($header,?), ";
    }
    $updatesql =~ s/, $//gs;
    
    $dbh->do ("ALTER TABLE booths ADD COLUMN merge_score_09_07 FLOAT");
    
    my $sth = $dbh->prepare("SELECT ac_id_09 FROM booths WHERE ac_id_09 IS NOT NULL GROUP BY ac_id_09");
    $sth->execute();
    undef(my @constituencies09); undef(my @constituencies07); 
    while (my $row=$sth->fetchrow_hashref) {
	push(@constituencies09,'ac_id_09 = '.$row->{ac_id_09});
	my @constituencyold = $dbh->selectrow_array("SELECT old from delimitation WHERE new = ?",undef,$row->{ac_id_09});
	my $oldconstituency=join (' OR ac_id_07 = ', @constituencyold);
	$oldconstituency='ac_id_07 = '.$oldconstituency;
	push(@constituencies07,$oldconstituency);
    }
    $sth->finish();
    
    for ($p=0;$p<scalar(@constituencies09);$p++) {
	my $constituency09 = $constituencies09[$p];
	my $constituency07 = $constituencies07[$p];

	# Figure out which scripts / languages are used, and equalize using upgis table wherever necessary and possible
	
	my $lang09 = $dbh->selectrow_array("SELECT group_concat(station_name_09) FROM booths WHERE $constituency09 GROUP BY ac_id_09");
	my $lang07 = $dbh->selectrow_array("SELECT group_concat(station_name_07) FROM booths WHERE $constituency07 GROUP BY ac_id_07");
	if ($lang09 =~ /[\]\[<>]/gs && $lang09 =~ /\;/gs) {$lang09='krutidev'} elsif ($lang09 !~ /^\s*$/) {$lang09='latin'} else {$lang09='unknown script'}
	if ($lang07 =~ /[\]\[<>]/gs && $lang07 =~ /\;/gs) {$lang07='krutidev'} elsif ($lang07 !~ /^\s*$/) {$lang07='latin'} else {$lang07='unknown script'}

	if ($lang09 ne $lang07) {
	    $constituency09 =~ s/.*?(\d+)$/$1/gs;
	    print  '  Constituency '.$constituency09.": matching pointless, because 2009 is in $lang09 and 2007 in $lang07\n";
	    next;
	}
	
	# manual tweak for data errors
	next if $constituency07 !~ /\d$/;
	
	# get list of stations with booth count for 2009, should be consecutive otherwise counts as new station (i.e. based on id rather than name)
	my $sth = $dbh->prepare('SELECT station_id_09, station_name_09, count(station_id_09), sum(electors_09) FROM booths WHERE ('.$constituency09.') AND station_id_09 IS NOT NULL AND station_id_07 IS NULL GROUP BY station_id_09');
	$sth->execute();
	undef(my @stationid09); undef(my @stationname09); undef(my @boothcount09); undef(my @electors09); undef(my $electorsavg09);
	while (my @row=$sth->fetchrow_array) {
	    push (@stationid09, $row[0]);
	    push (@stationname09, $row[1]);
	    push (@boothcount09, $row[2]);
	    push (@electors09, $row[3]);
	    $electorsavg09 = $electorsavg09 + $row[3];
	}
	$sth->finish();
	
	if (scalar(@electors09) == 0) {next}
	
	$electorsavg09 = $electorsavg09 / scalar(@electors09);
	
	# get list of stations with booth count for 2007, should be consecutive otherwise counts as new station (i.e. based on id rather than name)
	my $sth = $dbh->prepare('SELECT station_id_07, station_name_07, count(station_id_07), sum(electors_07) FROM booths WHERE ('.$constituency07.') AND station_id_07 IS NOT NULL AND station_id_09 IS NULL GROUP BY station_id_07');
	$sth->execute();
	undef(my @stationid07); undef(my @stationname07); undef(my @boothcount07); undef(my @electors07); undef(my $electorsavg07);
	while (my @row=$sth->fetchrow_array) {
	    push (@stationid07, $row[0]);
	    push (@stationname07, $row[1]);
	    push (@boothcount07, $row[2]);
	    push (@electors07, $row[3]);
	    $electorsavg07 = $electorsavg07 + $row[3];
	}
	$sth->finish();
	
	if (scalar(@electors07) == 0) {next}
	
	$electorsavg07 = $electorsavg07 / scalar(@electors07);
	
	if ($electorsavg09 == 0) {next}
	
	my $electorsavgdiff = ($electorsavg09-$electorsavg07) / $electorsavg09;
	
	# Crawl through 2009 stations and calculate scores
	undef(my %score);
	for ($i=0;$i<scalar(@stationid09);$i++) {
	    my @namesimilarity = distance([0,1,1],$stationname09[$i], @stationname07); 
	    my $ipercent = $i/scalar(@stationid09); 
	    undef(my %tempscore);
	    # THIS IS THE CRUCIAL SCORE FORMULA - TWEAK IT TIL OPTIMUM!! (weights decided by experimentation with Lucknow constituencies)
	    # THIS IS SUBOPTIMAL SO FAR - BUT I RAN OUT OF TIME. Next idea: use the listdistance > 0.95 and namesimilarity > .25 to create "sure" matches, and then try to recreate these sure matches without listdistance by automatically tweaking weighing factors and the whole formula til we get optimum results. Then use these weights to determine score for everything below that listdistance...
	    for ($u=0;$u<scalar(@stationid07);$u++) {
		my $boothequiv = 0; my $electorsdiff = 0; 
		my $namesimilarity = 0;
		if (length($stationname07[$u]) != 0) {$namesimilarity = 1-abs($namesimilarity[$u] + distance([0,1,1],$stationname07[$u],$stationname09[$i]))/2/length($stationname07[$u]);}
		my $listdistance=(1-abs($ipercent-$u/scalar(@stationid07))); 
		# All of these weights are between 1 (optimum) and 0 (minimum)
		if ($listdistance > 0.9 && $namesimilarity == 1 ) {
		    $tempscore{$i."-".$u} = 20;
		} elsif ($listdistance > 0.9 && $namesimilarity > 0.8 ) {
		    if ($boothcount09[$i] == $boothcount07[$i]) {$boothequiv=1} else {$boothequiv=0.9}
		    if (length($stationname07[$u]) == 0 || length($stationname09[$i]) == 0) {$namesimilarity=0.25}
		    if (1+abs( ($electors09[$i]-$electors07[$u])/$electors09[$i] - $electorsavgdiff ) != 0) {$electorsdiff = 0.9 + 1/(1+abs( ($electors09[$i]-$electors07[$u])/$electors09[$i] - $electorsavgdiff )) / 10;}
		    if ($boothequiv * $namesimilarity * $electorsdiff * 2 > 0.15) {$tempscore{$i."-".$u} = $boothequiv * $namesimilarity * $listdistance * $electorsdiff;}
		} elsif ($namesimilarity == 1) {
		    $tempscore{$i."-".$u} = 15; 
		}
	    }
	    # put the top three matches for this station into %score (where the second best would be used in case the very best fits even better elsewhere etc)
	    my @tempscore = sort {$tempscore{$b} <=> $tempscore{$a}} keys(%tempscore);
	    if (scalar(@tempscore) >= 1) {$score{$tempscore[0]} = $tempscore{$tempscore[0]};}
	    if (scalar(@tempscore) >= 2) {$score{$tempscore[1]} = $tempscore{$tempscore[1]};}
	    if (scalar(@tempscore) >= 3) {$score{$tempscore[2]} = $tempscore{$tempscore[2]};}
	}
	
	# Now do the actual matching
	$dbh->begin_work;
	undef(my %matched09); undef(my %matched07); my $stationmatch=0;
	foreach my $score (sort {$score{$b} <=> $score{$a}} keys(%score)) {
	    $score=~/(\d+)-(.+)/;
	    my $id09=$1; my $id07=$2; 
	    next if ($matched09{$id09} == 1 || $matched07{$id07} == 1); 
	    $matched09{$id09}=1; $matched07{$id07}=1;
	    
	    # Now do the actual integration
	    if ($boothcount09[$id09] == $boothcount07[$id07]) { # We have a full match
		my $sth3 = $dbh->prepare("SELECT * FROM booths WHERE station_id_07 = ? AND station_id_09 IS NULL");
		$sth3->execute($stationid07[$id07]);
		my $sth4 = $dbh->prepare("SELECT * FROM booths WHERE station_id_09 = ? AND station_id_07 IS NULL");
		$sth4->execute($stationid09[$id09]);
		while (my @row3=$sth3->fetchrow_array) {
		    my @row4=$sth4->fetchrow_array;
		    my $oldid=shift @row4; pop @row4; # this is for ID and for merge_score, which needs not be updated...
		    $dbh->do ("UPDATE booths SET $updatesql , merge_score_09_07 = ? WHERE id = ?",undef, @row4, $score{$score}, $row3[0]);
		    $dbh->do ("DELETE FROM booths WHERE id = ?",undef,$oldid);
		}
		$sth3->finish(); $sth4->finish();
	    } else { # We have a station match only, but booth counts differ
		my $old = $dbh->selectrow_hashref("SELECT * from booths WHERE station_id_07 = ?",undef,$stationid07[$id07]);
		my $new = $dbh->selectrow_hashref("SELECT * from booths WHERE station_id_09 = ?",undef,$stationid09[$id09]);
		$dbh->do ("UPDATE booths SET ac_id_09 = ?, ac_name_09 = ?, ac_reserved_09 = ?, station_id_09 = ?, station_name_09 = ? WHERE station_id_07 = ?", undef, $new->{ac_id_09}, $new->{ac_name_09}, $new->{ac_reserved_09}, $new->{station_id_09}, $new->{station_name_09}, $stationid07[$id07]);
		$dbh->do ("UPDATE booths SET ac_id_07 = ?, ac_name_07 = ?, ac_reserved_07 = ?, station_id_07 = ?, station_name_07 = ? WHERE station_id_09 = ?", undef, $old->{ac_id_07}, $old->{ac_name_07}, $old->{ac_reserved_07}, $old->{station_id_07}, $old->{station_name_07}, $stationid09[$id09]);
		$stationmatch++;
	    }
	}
	$dbh->commit;

	$constituency09 =~ s/.*?(\d+)$/$1/gs;
	print  '  Constituency '.$constituency09.": matched ".int(scalar(keys(%matched09))/scalar(@stationid09)*100)."% of 2009 stations (in $lang09) (".int($stationmatch/(scalar(keys(%matched09))+1)*100)."% of which only station-wise) to ".int(scalar(keys(%matched07))/scalar(@stationid07)*100)."% of 2007 stations (in $lang07)\n";
    }
    
    # Now integrate further by looking at 07 and 12 data within larger district - electors can be more fuzzy since larger time gap - here, name must match at least somewhat, pure boothcount + serial wont work

    print "Merging Booths from 2012 and 2007 within whole district\n";
    
    my $sql = $dbh->selectrow_array("SELECT sql FROM sqlite_master WHERE tbl_name='booths'");
    $sql=~s/^CREATE TABLE booths \(id INTEGER PRIMARY KEY AUTOINCREMENT, //gs;
    $sql=~s/\)$//gs;
    my @headers=split(/,/,$sql);
    my $updatesql=''; 
    foreach my $header (@headers) {
	$header=~s/^\s*(.*?)\s.*/$1/gs;
	$updatesql .= "$header = coalesce($header,?), ";
    }
    $updatesql =~ s/, $//gs;
    
    my $sth = $dbh->prepare("SELECT ac_id_12 FROM booths WHERE ac_id_12 IS NOT NULL GROUP BY ac_id_12");
    $sth->execute();
    undef(my @constituencies12); undef(my @constituencies07); 
    while (my $row=$sth->fetchrow_hashref) {
	push(@constituencies12,'ac_id_12 = '.$row->{ac_id_12});
	my $aggregate = $dbh->selectrow_array("SELECT aggregate from delimitation WHERE new = ?",undef,$row->{ac_id_12});
	my $sth = $dbh->prepare("SELECT DISTINCT old from delimitation WHERE aggregate = ?");
	$sth->execute($aggregate);
	my $oldconstituency=''; 
	while (my $constituencyold = $sth->fetchrow_array) {$oldconstituency.=' OR ac_id_07 = '.$constituencyold}
	$sth->finish();
	$oldconstituency=~s/^ OR //gs;
	push(@constituencies07,$oldconstituency);
    }
    $sth->finish();
    
    for ($p=0;$p<scalar(@constituencies12);$p++) {
	my $constituency12 = $constituencies12[$p];
	my $constituency07 = $constituencies07[$p];
	my $constituency09 = $constituency12;
	$constituency09 =~ s/12/09/gs;
	
	# Figure out which scripts / languages are used, and equalize using upgis table wherever necessary and possible
	
	my $lang12 = $dbh->selectrow_array("SELECT group_concat(station_name_12) FROM booths WHERE $constituency12 GROUP BY ac_id_12");
	my $lang07 = $dbh->selectrow_array("SELECT group_concat(station_name_07) FROM booths WHERE $constituency07 GROUP BY ac_id_07");
	if ($lang12 =~ /[\]\[<>]/gs && $lang12 =~ /\;/gs) {$lang12='krutidev'} elsif ($lang12 !~ /^\s*$/) {$lang12='latin'} else {$lang12='unknown script'}
	if ($lang07 =~ /[\]\[<>]/gs && $lang07 =~ /\;/gs) {$lang07='krutidev'} elsif ($lang07 !~ /^\s*$/) {$lang07='latin'} else {$lang07='unknown script'}
	my $lang12gis='latin';
	
	if ($lang12 ne $lang07 && $lang12gis ne $lang07) {
	    $constituency12 =~ s/.*?(\d+)$/$1/gs;
	    print  '  Constituency '.$constituency12.": matching pointless, because 2012 is in $lang12 (GIS in ".$lang12gis.") and 2007 in $lang07\n";
	    next;
	}
	
	# manual tweak for data errors
	next if $constituency07 !~ /\d$/;
        
	# get list of stations with booth count for 2012, should be consecutive otherwise counts as new station (i.e. based on id rather than name)
	my $sth = $dbh->prepare('SELECT station_id_12, station_name_12, count(station_id_12), sum(electors_12), min(booth_id_12) FROM booths WHERE ('.$constituency12.') AND station_id_12 IS NOT NULL AND station_id_07 IS NULL GROUP BY station_id_12');
	$sth->execute();
	undef(my @stationid12); undef(my @stationname12); undef(my @boothcount12); undef(my @electors12); undef(my $electorsavg12);
	while (my @row=$sth->fetchrow_array) {
	    push (@stationid12, $row[0]);
	    if ($lang12 ne $lang07 && $lang12gis eq $lang07 && $lang07 ne 'unknown' && $row[4] ne '') {$row[1] = $dbh->selectrow_array("select booth_name_14 from (select booth_name_14 from upgis where $constituency09 and booth_id_14 = (select min(booth_id_14) from upid where $constituency09 and booth_id_12 = ".$row[4].") UNION ALL select booth_name_12 from upgis where $constituency09 and booth_id_12 = ".$row[4].") where booth_name_14 is not null limit 1")} 
	    push (@stationname12, $row[1]);
	    push (@boothcount12, $row[2]);
	    push (@electors12, $row[3]);
	    $electorsavg12 = $electorsavg12 + $row[3];
	}
	$sth->finish();
	
	if (scalar(@electors12) == 0) {next}
	
	$electorsavg12 = $electorsavg12 / scalar(@electors12);
	
	# get list of stations with booth count for 2007, should be consecutive otherwise counts as new station (i.e. based on id rather than name)
	my $sth = $dbh->prepare('SELECT station_id_07, station_name_07, count(station_id_07), sum(electors_07) FROM booths WHERE ('.$constituency07.') AND station_id_07 IS NOT NULL AND station_id_12 IS NULL GROUP BY station_id_07');
	$sth->execute();
	undef(my @stationid07); undef(my @stationname07); undef(my @boothcount07); undef(my @electors07); undef(my $electorsavg07);
	while (my @row=$sth->fetchrow_array) {
	    push (@stationid07, $row[0]);
	    push (@stationname07, $row[1]);
	    push (@boothcount07, $row[2]);
	    push (@electors07, $row[3]);
	    $electorsavg07 = $electorsavg07 + $row[3];
	}
	$sth->finish();
	# Makes no sense to do this if this constituency has no stations in 2007...
	if (scalar(@electors07) == 0) {next}
	
	$electorsavg07 = $electorsavg07 / scalar(@electors07);
	
	if ($electorsavg12 == 0) {next}
	
	my $electorsavgdiff = ($electorsavg12-$electorsavg07) / $electorsavg12;
	
	# Crawl through 2012 stations and calculate scores
	undef(my %score);
	for ($i=0;$i<scalar(@stationid12);$i++) {
	    undef(my %tempscore);
	    # THIS IS THE CRUCIAL SCORE FORMULA - TWEAK IT TIL OPTIMUM!! (weights decided by experimentation with Lucknow constituencies)
	    # THIS IS SUBOPTIMAL SO FAR - BUT I RAN OUT OF TIME. Next idea: use the listdistance > 0.95 and namesimilarity > .25 to create "sure" matches, and then try to recreate these sure matches without listdistance by automatically tweaking weighing factors and the whole formula til we get optimum results. Then use these weights to determine score for everything below that listdistance...
	    for ($u=0;$u<scalar(@stationid07);$u++) {
		# All of these weights are between 1 (optimum) and 0 (minimum)
		if ($stationname07[$u] eq $stationname12[$i] ) {
		    $tempscore{$i."-".$u} = 20;
		} 
	    }
	    # put the top three matches for this station into %score (where the second best would be used in case the very best fits even better elsewhere etc)
	    my @tempscore = sort {$tempscore{$b} <=> $tempscore{$a}} keys(%tempscore);
	    if (scalar(@tempscore) >= 1) {$score{$tempscore[0]} = $tempscore{$tempscore[0]};}
	    if (scalar(@tempscore) >= 2) {$score{$tempscore[1]} = $tempscore{$tempscore[1]};}
	    if (scalar(@tempscore) >= 3) {$score{$tempscore[2]} = $tempscore{$tempscore[2]};}
	}
	
	# Now do the actual matching
	$dbh->begin_work;
	undef(my %matched12); undef(my %matched07); my $stationmatch=0;
	foreach my $score (sort {$score{$b} <=> $score{$a}} keys(%score)) {
	    $score=~/(\d+)-(.+)/;
	    my $id12=$1; my $id07=$2; 
	    next if ($matched12{$id12} == 1 || $matched07{$id07} == 1); 
	    $matched12{$id12}=1; $matched07{$id07}=1;
	    
	    
	    # Now do the actual integration
	    if ($boothcount12[$id12] == $boothcount07[$id07]) { # We have a full match
		my $sth3 = $dbh->prepare("SELECT * FROM booths WHERE station_id_07 = ? AND station_id_12 IS NULL");
		$sth3->execute($stationid07[$id07]);
		my $sth4 = $dbh->prepare("SELECT * FROM booths WHERE station_id_12 = ? AND station_id_07 IS NULL");
		$sth4->execute($stationid12[$id12]);
		while (my @row3=$sth3->fetchrow_array) {
		    my @row4=$sth4->fetchrow_array;
		    my $oldid=shift @row4; # this is for ID, which needs not be updated...
		    $dbh->do ("UPDATE booths SET $updatesql , merge_score_12_07 = ? WHERE id = ?",undef, @row4, $score{$score}, $row3[0]);
		    $dbh->do ("DELETE FROM booths WHERE id = ?",undef,$oldid);
		}
		$sth3->finish(); $sth4->finish();
	    } else { # We have a station match only, but booth counts differ
		my $old = $dbh->selectrow_hashref("SELECT * from booths WHERE station_id_07 = ?",undef,$stationid07[$id07]);
		my $new = $dbh->selectrow_hashref("SELECT * from booths WHERE station_id_12 = ?",undef,$stationid12[$id12]);
		$dbh->do ("UPDATE booths SET ac_id_12 = ?, ac_name_12 = ?, ac_reserved_12 = ?, station_id_12 = ?, station_name_12 = ? WHERE station_id_07 = ?", undef, $new->{ac_id_12}, $new->{ac_name_12}, $new->{ac_reserved_12}, $new->{station_id_12}, $new->{station_name_12}, $stationid07[$id07]);
		$dbh->do ("UPDATE booths SET ac_id_07 = ?, ac_name_07 = ?, ac_reserved_07 = ?, station_id_07 = ?, station_name_07 = ? WHERE station_id_12 = ?", undef, $old->{ac_id_07}, $old->{ac_name_07}, $old->{ac_reserved_07}, $old->{station_id_07}, $old->{station_name_07}, $stationid12[$id12]);
		$stationmatch++;
	    }
	}
	$dbh->commit;

	$constituency12 =~ s/.*?(\d+)$/$1/gs;
	print  '  Constituency '.$constituency12.": matched ".int(scalar(keys(%matched12))/scalar(@stationid12)*100)."% of 2012 (in $lang12) (GIS in ".$lang12gis.") stations (".int($stationmatch/(scalar(keys(%matched12))+1)*100)."% of which only station-wise) to ".int(scalar(keys(%matched07))/scalar(@stationid07)*100)."% of 2007 stations (in $lang07) in whole district\n";
    }
    
    # Now integrate further by looking at 07 and 09 data within larger district - here, name must match at least somewhat, pure boothcount + serial wont work

    print "Merging Booths from 2009 and 2007 within whole district\n";
    
    my $sql = $dbh->selectrow_array("SELECT sql FROM sqlite_master WHERE tbl_name='booths'");
    $sql=~s/^CREATE TABLE booths \(id INTEGER PRIMARY KEY AUTOINCREMENT, //gs;
    $sql=~s/\)$//gs;
    my @headers=split(/,/,$sql);
    my $updatesql=''; 
    foreach my $header (@headers) {
	$header=~s/^\s*(.*?)\s.*/$1/gs;
	$updatesql .= "$header = coalesce($header,?), ";
    }
    $updatesql =~ s/, $//gs;
    
    my $sth = $dbh->prepare("SELECT ac_id_09 FROM booths WHERE ac_id_09 IS NOT NULL GROUP BY ac_id_09");
    $sth->execute();
    undef(my @constituencies09); undef(my @constituencies07); 
    while (my $row=$sth->fetchrow_hashref) {
	push(@constituencies09,'ac_id_09 = '.$row->{ac_id_09});
	my $aggregate = $dbh->selectrow_array("SELECT aggregate from delimitation WHERE new = ?",undef,$row->{ac_id_09});
	my $sth = $dbh->prepare("SELECT DISTINCT old from delimitation WHERE aggregate = ?");
	$sth->execute($aggregate);
	my $oldconstituency=''; 
	while (my $constituencyold = $sth->fetchrow_array) {$oldconstituency.=' OR ac_id_07 = '.$constituencyold}
	$sth->finish();
	$oldconstituency=~s/^ OR //gs;
	push(@constituencies07,$oldconstituency);
    }
    $sth->finish();
    
    for ($p=0;$p<scalar(@constituencies09);$p++) {
	my $constituency09 = $constituencies09[$p];
	my $constituency07 = $constituencies07[$p];

	# Figure out which scripts / languages are used, and equalize using upgis table wherever necessary and possible
	
	my $lang09 = $dbh->selectrow_array("SELECT group_concat(station_name_09) FROM booths WHERE $constituency09 GROUP BY ac_id_09");
	my $lang07 = $dbh->selectrow_array("SELECT group_concat(station_name_07) FROM booths WHERE $constituency07 GROUP BY ac_id_07");
	if ($lang09 =~ /[\]\[<>]/gs && $lang09 =~ /\;/gs) {$lang09='krutidev'} elsif ($lang09 !~ /^\s*$/) {$lang09='latin'} else {$lang09='unknown script'}
	if ($lang07 =~ /[\]\[<>]/gs && $lang07 =~ /\;/gs) {$lang07='krutidev'} elsif ($lang07 !~ /^\s*$/) {$lang07='latin'} else {$lang07='unknown script'}

	if ($lang09 ne $lang07) {
	    $constituency09 =~ s/.*?(\d+)$/$1/gs;
	    print  '  Constituency '.$constituency09.": matching pointless, because 2009 is in $lang09 and 2007 in $lang07\n";
	    next;
	}

	
	# manual tweak for data errors
	next if $constituency07 !~ /\d$/;
	
	# get list of stations with booth count for 2009, should be consecutive otherwise counts as new station (i.e. based on id rather than name)
	my $sth = $dbh->prepare('SELECT station_id_09, station_name_09, count(station_id_09), sum(electors_09) FROM booths WHERE ('.$constituency09.') AND station_id_09 IS NOT NULL AND station_id_07 IS NULL GROUP BY station_id_09');
	$sth->execute();
	undef(my @stationid09); undef(my @stationname09); undef(my @boothcount09); undef(my @electors09); undef(my $electorsavg09);
	while (my @row=$sth->fetchrow_array) {
	    push (@stationid09, $row[0]);
	    push (@stationname09, $row[1]);
	    push (@boothcount09, $row[2]);
	    push (@electors09, $row[3]);
	    $electorsavg09 = $electorsavg09 + $row[3];
	}
	$sth->finish();
	
	if (scalar(@electors09) == 0) {next}
	
	$electorsavg09 = $electorsavg09 / scalar(@electors09);
	
	# get list of stations with booth count for 2007, should be consecutive otherwise counts as new station (i.e. based on id rather than name)
	my $sth = $dbh->prepare('SELECT station_id_07, station_name_07, count(station_id_07), sum(electors_07) FROM booths WHERE ('.$constituency07.') AND station_id_07 IS NOT NULL AND station_id_09 IS NULL GROUP BY station_id_07');
	$sth->execute();
	undef(my @stationid07); undef(my @stationname07); undef(my @boothcount07); undef(my @electors07); undef(my $electorsavg07);
	while (my @row=$sth->fetchrow_array) {
	    push (@stationid07, $row[0]);
	    push (@stationname07, $row[1]);
	    push (@boothcount07, $row[2]);
	    push (@electors07, $row[3]);
	    $electorsavg07 = $electorsavg07 + $row[3];
	}
	$sth->finish();
	# Makes no sense to do this if this constituency has no stations in 2007...
	if (scalar(@electors07) == 0) {next}
	
	$electorsavg07 = $electorsavg07 / scalar(@electors07);
	
	my $electorsavgdiff = ($electorsavg09-$electorsavg07) / $electorsavg09;
	
	# Crawl through 2009 stations and calculate scores
	undef(my %score);
	for ($i=0;$i<scalar(@stationid09);$i++) {
	    undef(my %tempscore);
	    # THIS IS THE CRUCIAL SCORE FORMULA - TWEAK IT TIL OPTIMUM!! (weights decided by experimentation with Lucknow constituencies)
	    # THIS IS SUBOPTIMAL SO FAR - BUT I RAN OUT OF TIME. Next idea: use the listdistance > 0.95 and namesimilarity > .25 to create "sure" matches, and then try to recreate these sure matches without listdistance by automatically tweaking weighing factors and the whole formula til we get optimum results. Then use these weights to determine score for everything below that listdistance...
	    for ($u=0;$u<scalar(@stationid07);$u++) {
		# All of these weights are between 1 (optimum) and 0 (minimum)
		if ($stationname09[$i] eq $stationname07[$i]) {
		    $tempscore{$i."-".$u} = 20;
		} 
	    }
	    # put the top three matches for this station into %score (where the second best would be used in case the very best fits even better elsewhere etc)
	    my @tempscore = sort {$tempscore{$b} <=> $tempscore{$a}} keys(%tempscore);
	    if (scalar(@tempscore) >= 1) {$score{$tempscore[0]} = $tempscore{$tempscore[0]};}
	    if (scalar(@tempscore) >= 2) {$score{$tempscore[1]} = $tempscore{$tempscore[1]};}
	    if (scalar(@tempscore) >= 3) {$score{$tempscore[2]} = $tempscore{$tempscore[2]};}
	}
	
	# Now do the actual matching
	$dbh->begin_work;
	undef(my %matched09); undef(my %matched07); my $stationmatch=0;
	foreach my $score (sort {$score{$b} <=> $score{$a}} keys(%score)) {
	    $score=~/(\d+)-(.+)/;
	    my $id09=$1; my $id07=$2; 
	    next if ($matched09{$id09} == 1 || $matched07{$id07} == 1); 
	    $matched09{$id09}=1; $matched07{$id07}=1;
	    
	    
	    # Now do the actual integration
	    if ($boothcount09[$id09] == $boothcount07[$id07]) { # We have a full match
		my $sth3 = $dbh->prepare("SELECT * FROM booths WHERE station_id_07 = ? AND station_id_09 IS NULL");
		$sth3->execute($stationid07[$id07]);
		my $sth4 = $dbh->prepare("SELECT * FROM booths WHERE station_id_09 = ? AND station_id_07 IS NULL");
		$sth4->execute($stationid09[$id09]);
		while (my @row3=$sth3->fetchrow_array) {
		    my @row4=$sth4->fetchrow_array;
		    my $oldid=shift @row4; # this is for ID, which needs not be updated...
		    $dbh->do ("UPDATE booths SET $updatesql , merge_score_09_07 = ? WHERE id = ?",undef, @row4, $score{$score}, $row3[0]);
		    $dbh->do ("DELETE FROM booths WHERE id = ?",undef,$oldid);
		}
		$sth3->finish(); $sth4->finish();
	    } else { # We have a station match only, but booth counts differ
		my $old = $dbh->selectrow_hashref("SELECT * from booths WHERE station_id_07 = ?",undef,$stationid07[$id07]);
		my $new = $dbh->selectrow_hashref("SELECT * from booths WHERE station_id_09 = ?",undef,$stationid09[$id09]);
		$dbh->do ("UPDATE booths SET ac_id_09 = ?, ac_name_09 = ?, ac_reserved_09 = ?, station_id_09 = ?, station_name_09 = ? WHERE station_id_07 = ?", undef, $new->{ac_id_09}, $new->{ac_name_09}, $new->{ac_reserved_09}, $new->{station_id_09}, $new->{station_name_09}, $stationid07[$id07]);
		$dbh->do ("UPDATE booths SET ac_id_07 = ?, ac_name_07 = ?, ac_reserved_07 = ?, station_id_07 = ?, station_name_07 = ? WHERE station_id_09 = ?", undef, $old->{ac_id_07}, $old->{ac_name_07}, $old->{ac_reserved_07}, $old->{station_id_07}, $old->{station_name_07}, $stationid09[$id09]);
		$stationmatch++;
	    }
	}
	$dbh->commit;

	$constituency09 =~ s/.*?(\d+)$/$1/gs;
	print  '  Constituency '.$constituency09.": matched ".int(scalar(keys(%matched09))/scalar(@stationid09)*100)."% of 2009 stations (in $lang09) (".int($stationmatch/(scalar(keys(%matched09))+1)*100)."% of which only station-wise) to ".int(scalar(keys(%matched07))/scalar(@stationid07)*100)."% of 2007 stations (in $lang07) in whole district\n";
    }
    
    $dbh->sqlite_backup_to_file('upid-a.sqlite');
    $dbh->disconnect;

}
 
#
# Now this has all been virtual - use resulting upid table to re-create, bit by bit, the necessary SQL code
#

$dbh = DBI->connect("DBI:SQLite:dbname=:memory:", "","", {sqlite_unicode=>1});
$dbh->sqlite_backup_from_file('upid-a.sqlite');

open (FILE, ">upid-a.sql");

print FILE "CREATE INDEX ac_booth_id_07 ON upid (ac_id_07, booth_id_07);\n";
print FILE "CREATE INDEX ac_booth_id_09 ON upid (ac_id_09, booth_id_09);\n";
print FILE "CREATE INDEX ac_booth_id_12 ON upid (ac_id_09, booth_id_12);\n";
print FILE "CREATE INDEX ac_station_id_07 ON upid (ac_id_07, station_id_07);\n";
print FILE "CREATE INDEX ac_station_id_09 ON upid (ac_id_09, station_id_09);\n";
print FILE "CREATE INDEX ac_station_id_12 ON upid (ac_id_09, station_id_12);\n";

print FILE "BEGIN TRANSACTION;\n";

my $sth = $dbh->prepare("SELECT * FROM booths");
$sth->execute();
while (my $row=$sth->fetchrow_hashref) {
    my $stationname09 = $row->{station_name_09};
    my $stationname12 = $row->{station_name_12};
    $stationname09 =~ s/'//gs;
    $stationname12 =~ s/'//gs;
    my $done=0;
    if ($row->{booth_id_07} ne '' && $row->{booth_id_09} ne '') {print FILE "UPDATE upid SET booth_id_09 = ".$row->{booth_id_09}.", ac_id_09 = ".$row->{ac_id_09}.", ac_name_09 = '".$row->{ac_name_09}."',  ac_reserved_09 = '".$row->{ac_reserved_09}."', station_id_09 = ".$row->{station_id_09}.",  station_name_09 = '".$stationname09."' WHERE ac_id_07 = ".$row->{ac_id_07}." AND booth_id_07 = ".$row->{booth_id_07}.";\n"; $done=1}
    if ($row->{booth_id_07} ne '' && $row->{booth_id_12} ne '') {print FILE "UPDATE upid SET booth_id_12 = ".$row->{booth_id_12}.", ac_id_09 = ".$row->{ac_id_12}.", ac_name_12 = '".$row->{ac_name_12}."',  ac_reserved_12 = '".$row->{ac_reserved_12}."', station_id_12 = ".$row->{station_id_12}.",  station_name_12 = '".$stationname12."' WHERE ac_id_07 = ".$row->{ac_id_07}." AND booth_id_07 = ".$row->{booth_id_07}.";\n"; $done=1}
    if ($row->{booth_id_09} ne '' && $row->{booth_id_12} ne '') {print FILE "UPDATE upid SET booth_id_12 = ".$row->{booth_id_12}.", ac_id_09 = ".$row->{ac_id_12}.", ac_name_12 = '".$row->{ac_name_12}."',  ac_reserved_12 = '".$row->{ac_reserved_12}."', station_id_12 = ".$row->{station_id_12}.",  station_name_12 = '".$stationname12."' WHERE ac_id_09 = ".$row->{ac_id_09}." AND booth_id_09 = ".$row->{booth_id_09}.";\n"; $done=1}
    next if $done==1;
    if ($row->{station_id_07} ne '' && $row->{station_id_09} ne '') {print FILE "UPDATE upid SET ac_id_09 = ".$row->{ac_id_09}.", ac_name_09 = '".$row->{ac_name_09}."',  ac_reserved_09 = '".$row->{ac_reserved_09}."', station_id_09 = ".$row->{station_id_09}.",  station_name_09 = '".$stationname09."' WHERE ac_id_07 = ".$row->{ac_id_07}." AND station_id_07 = ".$row->{station_id_07}.";\n"}
    if ($row->{station_id_07} ne '' && $row->{station_id_12} ne '') {print FILE "UPDATE upid SET ac_id_09 = ".$row->{ac_id_12}.", ac_name_12 = '".$row->{ac_name_12}."',  ac_reserved_12 = '".$row->{ac_reserved_12}."', station_id_12 = ".$row->{station_id_12}.",  station_name_12 = '".$stationname12."' WHERE ac_id_07 = ".$row->{ac_id_07}." AND station_id_07 = ".$row->{station_id_07}.";\n"}
    if ($row->{station_id_09} ne '' && $row->{station_id_12} ne '') {print FILE "UPDATE upid SET ac_id_09 = ".$row->{ac_id_12}.", ac_name_12 = '".$row->{ac_name_12}."',  ac_reserved_12 = '".$row->{ac_reserved_12}."', station_id_12 = ".$row->{station_id_12}.",  station_name_12 = '".$stationname12."' WHERE ac_id_09 = ".$row->{ac_id_09}." AND station_id_09 = ".$row->{station_id_09}.";\n"}
}
$sth->finish();

print FILE "COMMIT;\n";
close (FILE);

$dbh->disconnect;
    
#
# Then add code to actually run the compression
#

$dbh = DBI->connect("DBI:SQLite:dbname=:memory:", "","", {sqlite_unicode=>1});
$dbh->sqlite_backup_from_file('../combined.sqlite');

my $sql = $dbh->selectrow_array("SELECT sql FROM sqlite_master WHERE tbl_name='upid'");
$sql=~s/^CREATE TABLE upid \(//gs;
$sql=~s/\)$//gs;
my @headers=split(/,/,$sql);

push (@headers, 'booth_parts_14 CHAR');
push (@headers, 'booth_name_14 CHAR');
push (@headers, 'pc_id_09 INTEGER');
push (@headers, 'pc_name_09 CHAR');
push (@headers, 'pc_reserved_09 CHAR');

my @concatsql;
foreach my $header (@headers) {
    $header =~ s/^\s+//gs;
    my ($name,$type) = split(/\s+/,$header);
    next if $name eq 'CREATE';
    if ($type eq 'INTEGER') {push(@concatsql, "cast(max($name) as integer) '$name'")}
    elsif ($type eq 'FLOAT') {push(@concatsql, "cast(max($name) as float) '$name'")}
    else {push(@concatsql, "cast(group_concat(DISTINCT $name) as char) '$name'")}
}

open (FILE, ">>upid-b.sql");
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
# Finally prepare sqlite dump 
#

open (FILE, ">>upid-b.sql");

print FILE ".mode csv\n";
print FILE ".headers on\n";
print FILE ".once upid/upid.csv\n";
print FILE "SELECT * FROM upid;\n";
print FILE "VACUUM;";

close (FILE);
