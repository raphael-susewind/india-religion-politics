#!/usr/bin/perl

my $i=$ARGV[0];

if (!-e 'ngram-hindu-lm') {
    system("perl -CSDA -Mlocal::lib=perl5 -Iperl5/lib/perl5 createngram.pl");
    system('rsync --update --archive ngram* $DATA/gujarat/2014/'.$i.'/');
}
    
my @files= `ls *.sqlite`;
foreach my $file (@files) {
    system("perl -e '\$s = shift; \$SIG{ALRM} = sub { kill INT => \$p }; exec(\@ARGV) unless \$p = fork; alarm \$s; waitpid \$p, 0' 43200 'perl -CSDA -Mlocal::lib=perl5 -Iperl5/lib/perl5 addngram.pl $file'");
    system('rsync --update --archive '.$file.' $DATA/gujarat/2014/'.$i.'/');
}

# system("rm $i.sqlite");

# system("perl -CSDA -Mlocal::lib=perl5 -Iperl5/lib/perl5 csv2stats.pl $i");

# system("rm -r __pycache__ perl5 *.pl *.py fifo names.sqlite pdftotext *.failure");

# system('rsync --update --archive . $DATA/gujarat/2014/'.$i.'/');
