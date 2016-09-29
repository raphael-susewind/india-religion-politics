#!/usr/bin/perl

use DBI;
use utf8;

#
# Iterate through all PDFs
#

my $file=$ARGV[0];

chomp $file;

#
# This is a motherroll
#
$file =~ /(\d\d\d)-(\d\d\d)/gs;
$constituency=$1/1;
$booth=$2;

# Get Number of pages and take care that first and last are not used - they contain other stuff
my $pages=`pdfinfo $file`;
$pages=~s/.*?Pages:\s+(\d+).*/$1/gs;
$pages--;

next if ($pages==0 or !defined($pages));

# Extract the three data columns and re-load the respective data, putting it all into @raw, deleting temp files
system("./pdftotext -nopgbrk -f 3 -l $pages  -x 68 -y 128 -W 173 -H 965 -layout -r 100 $file out1.txt");
system("./pdftotext -nopgbrk -f 3 -l $pages  -x 241 -y 128 -W 173 -H 965 -layout -r 100 $file out2.txt");
system("./pdftotext -nopgbrk -f 3 -l $pages  -x 414 -y 128 -W 173 -H 965 -layout -r 100 $file out3.txt");
system("./pdftotext -nopgbrk -f 3 -l $pages  -x 587 -y 128 -W 173 -H 965 -layout -r 100 $file out4.txt");

open (FILE,"<:utf8","out1.txt");
my @raw1=<FILE>;
close (FILE);
open (FILE,"<:utf8","out2.txt");
my @raw2=<FILE>;
close (FILE);
open (FILE,"<:utf8","out3.txt");
my @raw3=<FILE>;
close (FILE);
open (FILE,"<:utf8","out4.txt");
my @raw4=<FILE>;
close (FILE);

my $reset;

my @raw=(@raw1,@raw2,@raw3,@raw4);

system("rm -f out1.txt out2.txt out3.txt out4.txt");

exit if (scalar(@raw)==0);

# Create rolls.X.sqlite to put in all the necessary stuff

$file =~ s/.pdf$//gs;
my $dbh_rolls = DBI->connect("dbi:SQLite:dbname=:memory:","","",{sqlite_unicode => 1});
if (-e "$file.sqlite") {$dbh_rolls->sqlite_backup_from_file("$file.sqlite");}

$dbh_rolls->begin_work;

# Build Database by extracting relevant values
my $voterid; my $entrycount=10000; 
line: while (scalar(@raw)>0) {
    $voterid=''; $rollno='';
    
    tragain2:
      if (scalar(@raw)==0) {last line}
    $first=shift(@raw);    
    if ($first !~ /\:\s*(.*?)\s*$/gs) {
	if ($first =~ /\d\d\d/) {$voterid=$first; }
	goto tragain2;
    } # filter out weird stuff
    
    next line if ($voterid eq '');
    
    $entrycount++;
    
    $voterid =~ /^\s*(\d+)/gs;
    $rollno = $1;
    if ($rollno == 0) {$rollno=$entrycount}
    
    eval $voterid =~ s/^\s*\d+//gs;
    eval $voterid =~ s/[^A-Z0-9\/]//gs; 
        
    tragain3: 
      if (scalar(@raw)==0) {last line}  
    $third=shift(@raw);
    goto tragain3 if $third !~ /\:/;
 
    tragain4:
      if (scalar(@raw)==0) {last line}  
    $fourth=shift(@raw);
    goto tragain4 if $fourth !~ /\:/;
    tragain5: 
      if (scalar(@raw)==0) {last line}  
    $fifth=shift(@raw);
    goto tragain5 if $fifth !~ /\:/;
    eval $fifth=~/.*?(\d+).*?\: (.*?)\s*\n/gs;
    $age=$1; $gender=$2; 
    eval {if ($age=~/[^0-9]/) {$age=''}};
    eval {$gender=~s/\x{093f}(.)/$1\x{093f}/gs; $gender=~s/;/,/gs};
    eval {if ($gender =~ /ી/) {$gender='f'} elsif ($gender =~ /ષ/) {$gender='m'} else {$gender=undef}};
    

    $dbh_rolls->do("UPDATE rolls SET gender = ? WHERE rollno = ? AND age = ?",undef,$gender,$rollno,$age);

}

$dbh_rolls->commit;

$dbh_rolls->sqlite_backup_to_file("$file.sqlite");

$dbh_rolls->disconnect;
$dbh->disconnect;
undef($dbh_rolls);
undef($dbh);

