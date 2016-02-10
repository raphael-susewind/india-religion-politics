#!/usr/bin/perl

use DBI;

my $i=$ARGV[0];

system("cp /data/area-mnni/rsusewind/up/2013/$i/ngram*lm . "); 
system("cp /data/area-mnni/rsusewind/up/2013/$i/$i.sqlite . "); 

my $dbh = DBI->connect("dbi:SQLite:dbname=$i.sqlite","","",{sqlite_unicode => 1});
$dbh->do ("ALTER TABLE booths ADD COLUMN oldbooth INTEGER");
$dbh->do ("UPDATE booths SET oldbooth = booth");
$dbh->do ("UPDATE booths SET booth = NULL");
$dbh->disconnect;

# system("perl -CSDA -Mlocal::lib -Iperl5/lib/perl5 downloadpdf.pl $i");

if (!-e "/data/area-mnni/rsusewind/up/2013/$i/rolls.all.sqlite") {

    my @files = `ls /data/area-mnni/rsusewind/up/2013/$i/rolls.*.sqlite`;
    
    my $dbh = DBI->connect("dbi:SQLite:dbname=/data/area-mnni/rsusewind/up/2013/$i/rolls.all.sqlite","","",{sqlite_unicode => 1});
    $dbh->do("CREATE TABLE names (id INTEGER, firstname CHAR,lastname CHAR,father_firstname CHAR,father_lastname CHAR,soundex CHAR)");
    $dbh->do("CREATE TABLE rolls (id INTEGER PRIMARY KEY AUTOINCREMENT, booth INTEGER, nameparts INTEGER, age INTEGER, gender CHAR, community CHAR, certainty FLOAT, gap FLOAT, name CHAR, fathername CHAR, voter_nameparts INTEGER, voter_community CHAR, voter_certainty FLOAT, voter_gap FLOAT, father_nameparts INTEGER, father_community CHAR, father_certainty FLOAT, father_gap FLOAT, voterid CHAR, rollno INTEGER, ngram INTEGER, revision12 CHAR, revision13 CHAR)");
    my $sth = $dbh->prepare("INSERT INTO rolls (booth, rollno, voterid, nameparts, age, gender, community, certainty, gap, name, fathername, voter_nameparts, voter_community, voter_certainty, voter_gap, father_nameparts, father_community, father_certainty, father_gap, ngram, revision12, revision13) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)");
    my $sth4 = $dbh->prepare("INSERT INTO names (id,firstname,lastname,father_firstname,father_lastname,soundex) VALUES (?,?,?,?,?,?)");
    
    foreach my $file (@files) {
	chomp($file);
	$file =~ /rolls.(\d+).sqlite/gs;
	my $booth = $1;
	my $dbh2 = DBI->connect("dbi:SQLite:dbname=$file","","",{sqlite_unicode => 1});
	my $sth2 = $dbh2->prepare("SELECT * FROM rolls WHERE revision13 IS NULL OR revision13 = 'M' OR revision13 = 'N'");
	my $sth3 = $dbh2->prepare("SELECT * FROM names WHERE id = ?");
	$sth2->execute();
	while (my $row=$sth2->fetchrow_hashref) {
	    $sth->execute($booth,$row->{rollno}, $row->{voterid}, $row->{nameparts}, $row->{age}, $row->{gender}, $row->{community}, $row->{certainty}, $row->{gap}, $row->{name}, $row->{fathername}, $row->{voter_nameparts}, $row->{voter_community}, $row->{voter_certainty}, $row->{voter_gap}, $row->{father_nameparts}, $row->{father_community}, $row->{father_certainty}, $row->{father_gap}, $row->{ngram}, $row->{revision12}, $row->{revision13});
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

    $sth->finish();
    $sth4->finish();
    $dbh->disconnect;
    
}

system("cp /data/area-mnni/rsusewind/up/2013/$i/rolls.all.sqlite rolls.old.sqlite");

my @files= `ls *-Mother.pdf`;

file: foreach my $file (@files) {
    $file =~ /(\d+)-(\d+)/gs;
    $constituency=$1/1;
    $booth=$2;
    chomp ($file);

    if (-e "rolls.$booth.sqlite-journal") {system("rm rolls.$booth.sqlite*")}
    
    my $runalready=0;
    if (-e "rolls.$booth.sqlite") {$runalready=1}   
    if ($runalready==1) {print "Skipping $file\n";next}
    else {print "Running $file\n";}    
    
    system("perl -e '\$s = shift; \$SIG{ALRM} = sub { kill INT => \$p }; exec(\@ARGV) unless \$p = fork; alarm \$s; waitpid \$p, 0' 43200 'perl -CSDA -Mlocal::lib=perl5 -Iperl5/lib/perl5 pdf2list.pl $file'");
    
}

foreach my $file (@files) {
    $file =~ /(\d+)-(\d+)/gs;
    $constituency=$1/1;
    $booth=$2;
    chomp ($file);
    system("perl -CSDA -Mlocal::lib=perl5 -Iperl5/lib/perl5 frontpage.pl $file");
}

my @files = `ls rolls*sqlite`;

# system("perl -CSDA -Mlocal::lib=perl5 -Iperl5/lib/perl5 csv2stats.pl $i");

system("rm -r __pycache__ perl5 *.pl *.py fifo names.sqlite pdftotext ngram core *.tif *.txt tesseract rolls.old.sqlite");
