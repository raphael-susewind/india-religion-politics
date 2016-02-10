#!/usr/bin/perl

use DBI;

my $i=$ARGV[0];

my @files= `ls rolls*sqlite`;

foreach my $file (@files) {
    chomp ($file);
    next if ($file =~ /old/);
    system("perl -e '\$s = shift; \$SIG{ALRM} = sub { kill INT => \$p }; exec(\@ARGV) unless \$p = fork; alarm \$s; waitpid \$p, 0' 1800 'perl -CSDA -Mlocal::lib=perl5 -Iperl5/lib/perl5 addngram.pl $file'");
    system('rsync --update --archive '.$file.' $DATA/up/2014/'.$i.'/');
}

# system("perl -CSDA -Mlocal::lib=perl5 -Iperl5/lib/perl5 csv2stats.pl $i");

# system("rm -r __pycache__ perl5 *.pl *.py fifo names.sqlite pdftotext ngram core *.tif tesseract rolls.old.sqlite");

# system('rsync --update --archive . $DATA/up/2014/'.$i.'/');
