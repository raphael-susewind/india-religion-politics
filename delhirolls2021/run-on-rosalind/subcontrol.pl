#!/usr/bin/perl

use DBI;

exit if -e 'done';

my $i=$ARGV[0];

system("cp ../../Voter-List-2014/$i/$i.sqlite ."); 

my $dbh = DBI->connect("dbi:SQLite:dbname=$i.sqlite","","",{sqlite_unicode => 1});
$dbh->do ("ALTER TABLE booths ADD COLUMN oldbooth INTEGER");
$dbh->do ("UPDATE booths SET oldbooth = booth");
$dbh->do ("UPDATE booths SET booth = NULL");
$dbh->disconnect;

if (!-e "../../Voter-List-2014/$i/rolls.all.sqlite") {
    
  my @files = `ls ../../Voter-List-2014/$i/rolls.*.sqlite`;
    
    
   my $dbh = DBI->connect("DBI:SQLite:dbname=:memory:", "","", {sqlite_unicode=>1});

   $dbh->do("CREATE TABLE names (id INTEGER, firstname CHAR,lastname CHAR,father_firstname CHAR,father_lastname CHAR,soundex CHAR)");
   $dbh->do("CREATE TABLE rolls (id INTEGER PRIMARY KEY AUTOINCREMENT, booth INTEGER, nameparts INTEGER, age INTEGER, gender CHAR, community CHAR, certainty FLOAT, gap FLOAT, name CHAR, fathername CHAR, voter_nameparts INTEGER, voter_community CHAR, voter_certainty FLOAT, voter_gap FLOAT, father_nameparts INTEGER, father_community CHAR, father_certainty FLOAT, father_gap FLOAT, voterid CHAR, rollno INTEGER)");
   my $sth = $dbh->prepare("INSERT INTO rolls (booth, rollno, voterid, nameparts, age, gender, community, certainty, gap, name, fathername, voter_nameparts, voter_community, voter_certainty, voter_gap, father_nameparts, father_community, father_certainty, father_gap) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)");
   my $sth4 = $dbh->prepare("INSERT INTO names (id,firstname,lastname,father_firstname,father_lastname,soundex) VALUES (?,?,?,?,?,?)");
    
   foreach my $file (@files) {
       next unless $file =~ /\d/gs;#
	chomp($file);
       next if -z $file;
       $file =~ /rolls.(\d+).sqlite/gs;
	my $booth = $1;
	my $dbh2 = DBI->connect("dbi:SQLite:dbname=$file","","",{sqlite_unicode => 1});
	my $sth2 = $dbh2->prepare("SELECT * FROM rolls");
	my $sth3 = $dbh2->prepare("SELECT * FROM names WHERE id = ?");
	$sth2->execute();
	while (my $row=$sth2->fetchrow_hashref) {
	    $sth->execute($booth,$row->{rollno}, $row->{voterid}, $row->{nameparts}, $row->{age}, $row->{gender}, $row->{community}, $row->{certainty}, $row->{gap}, $row->{name}, $row->{fathername}, $row->{voter_nameparts}, $row->{voter_community}, $row->{voter_certainty}, $row->{voter_gap}, $row->{father_nameparts}, $row->{father_community}, $row->{father_certainty}, $row->{father_gap});
	    my $id=$dbh->last_insert_id("","","","");
	    $sth3->execute($row->{id});
	    while (my $row2=$sth3->fetchrow_hashref) {
		$sth4->execute($id,$row2->{firstname},$row2->{lastname},$row2->{father_firstname},$row2->{father_lastname},$row2->{soundex});
	    }
	}
	$sth2->finish();
	$sth3->finish();
	$dbh2->disconnect;
   }

   $dbh->do("CREATE INDEX voterid ON rolls (voterid)");
   $dbh->do("CREATE INDEX namefathername ON rolls (name,fathername)");

   
   $sth->finish();
   $sth4->finish();

   $dbh->sqlite_backup_to_file("../../Voter-List-2014/$i/rolls.all.sqlite");
   $dbh->disconnect;
    
}

my @files= `ls *-ocr.pdf`;

foreach my $file (@files) {
   $file =~ /(\d+)-(\d+)/gs;
   $constituency=$1/1;
   $booth=$2;
   chomp ($file);#

   next if -e "rolls.$booth.sqlite";
    
   system("rm csvtemp*");
   system("perl -e '\$s = shift; \$SIG{ALRM} = sub { kill INT => \$p }; exec(\@ARGV) unless \$p = fork; alarm \$s; waitpid \$p, 0' 3600 'perl -CSDA pdf2list.pl $file'");
}

unless (-e "ngram-jain-lm") {system("perl -CSDA createngram.pl");}

my @files = `ls rolls.*.sqlite`;

foreach my $file (@files) {
   $file =~ /(\d+)/gs;
   $booth=$1;
   system("perl -CSDA addngram.pl $booth");
}

system("perl -CSDA csv2stats.pl $i");

system("rm -r __pycache__  *.pl *.py fifo names.sqlite *.sh *~");
system("touch done");
