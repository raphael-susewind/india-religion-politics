#!/usr/bin/perl

system("rm -f booths.sqlite");

for ($i=1;$i<=147;$i++) {
    next if !-e $i;
    system("cd $i && echo '.dump' | sqlite3 $i.sqlite > $i.sql");
    open (FILE, "$i/$i.sql");
    my @file = <FILE>;
    close (FILE);
    open (FILE, ">$i/$i.sql");
    my $insert;
    foreach my $line (@file) {
	if ($line =~ /^CREATE TABLE booths (.*?);/) {$insert=$1;$insert=~s/ CHAR//gs; $insert=$1;$insert=~s/ FLOAT//gs; $insert=~s/ INTEGER//gs; next unless $i==1}
	if ($line =~ /^INSERT INTO \"booths\"/) {$line =~ s/^INSERT INTO \"booths\"/INSERT INTO \"booths\" $insert/}
	print FILE $line;
    }
    close (FILE);
    system("cd $i && cat $i.sql | sqlite3 ../booths.sqlite");
}

system("tar -czf booths.sqlite.tgz booths.sqlite");

system("rm -f booths.sqlite");