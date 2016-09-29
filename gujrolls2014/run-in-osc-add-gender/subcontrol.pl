#!/usr/bin/perl

my $i=$ARGV[0];

my @files= `ls *.pdf`;

foreach my $file (@files) {
    chomp ($file);
    print "Fork $i: running file $file\n";
    $file =~ /(\d+)-(\d+)/gs;
    $constituency=$1/1;
    $booth=$2;
    system("perl -e '\$s = shift; \$SIG{ALRM} = sub { kill INT => \$p }; exec(\@ARGV) unless \$p = fork; alarm \$s; waitpid \$p, 0' 43200 'perl -CSDA -Mlocal::lib=perl5 -Iperl5/lib/perl5 pdf2list.pl $file'");
    system('rsync --update --archive '.$rollfile.'* $DATA/gujarat/2014/'.$i.'/');
}

# print "Fork $i: assemble\n";

# system("rm $i.sqlite");
# system("perl -CSDA -Mlocal::lib=perl5 -Iperl5/lib/perl5 csv2stats.pl $i");

# print "Fork $i: cleanup and sync back\n";

# system("rm -r __pycache__ perl5 *.pl *.py fifo names.sqlite pdftotext *.failure");

# system('rsync --update --archive . $DATA/gujarat/2014/'.$i.'/');

print "Fork $i: exit\n";
