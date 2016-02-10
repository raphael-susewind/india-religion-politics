#!/usr/bin/perl

my $booth=$ARGV[0];

use DBI;

my $dbh = DBI->connect("dbi:SQLite:dbname=rolls.$booth.sqlite","","",{sqlite_unicode => 1});
# $dbh->do ("ALTER TABLE rolls ADD COLUMN ngram INTEGER");

my $sth = $dbh->prepare("SELECT * FROM rolls WHERE community = 'Unknown' AND revision12 IS NOT NULL");
my $sth2 = $dbh->prepare("UPDATE rolls SET community = ?, ngram = ? WHERE id = ?");

$sth->execute();
while (my $row=$sth->fetchrow_hashref) {
    open (FILE, ">temp");
    my $name = $row->{name};
    my $fathername = $row->{fathername};
    next if (length($name.$fathername) < 10);
    $name =~ s/(\P{Mark})/ $1/g; 
    $name =~ s/^ //;
    $fathername =~ s/(\P{Mark})/ $1/g; 
    $fathername =~ s/^ //;
    print FILE $name."\n".$name."\n".$fathername."\n";
    close (FILE);
    undef (my %list);
    $return = `./ngram -order 3 -lm ngram-hindu-lm -ppl temp 2>/dev/null`;
    $return =~ /logprob= (-*\d*\.*\d+)/gs;
    $list{'Hindu'} = $1;
    $return = `./ngram -order 3 -lm ngram-muslim-lm -ppl temp 2>/dev/null`;
    $return =~ /logprob= (-*\d*\.*\d+)/gs;
    $list{'Muslim'} = $1;
    $return = `./ngram -order 3 -lm ngram-christian-lm -ppl temp 2>/dev/null`;
    $return =~ /logprob= (-*\d*\.*\d+)/gs;
    $list{'Christian'} = $1;
    $return = `./ngram -order 3 -lm ngram-sikh-lm -ppl temp 2>/dev/null`;
    $return =~ /logprob= (-*\d*\.*\d+)/gs;
    $list{'Sikh'} = $1;
    $return = `./ngram -order 3 -lm ngram-buddhist-lm -ppl temp 2>/dev/null`;
    $return =~ /logprob= (-*\d*\.*\d+)/gs;
    $list{'Buddhist'} = $1;
    $return = `./ngram -order 3 -lm ngram-jain-lm -ppl temp 2>/dev/null`;
    $return =~ /logprob= (-*\d*\.*\d+)/gs;
    $list{'Jain'} = $1;
    $return = `./ngram -order 3 -lm ngram-parsi-lm -ppl temp 2>/dev/null`;
    $return =~ /logprob= (-*\d*\.*\d+)/gs;
    $list{'Parsi'} = $1;
    my @sorted = sort {$list{$b} <=> $list{$a}} (keys(%list));
    if ($list{$sorted[0]}-$list{$sorted[1]} > 0.75) {$sth2->execute($sorted[0],$list{$sorted[0]}-$list{$sorted[1]},$row->{id});} 
}

system("rm -f temp");
