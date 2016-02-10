#!/usr/bin/perl

my $i=$ARGV[0];

system("perl -CSDA -Mlocal::lib -Iperl5/lib/perl5 downloadpdf.pl");

my @files= `ls *pdf`;

foreach my $file (@files) {
    $file =~ /(\d+)-(\d+)/gs;
    $constituency=$1/1;
    $booth=$2;
    chomp ($file);
    system("perl -e '\$s = shift; \$SIG{ALRM} = sub { kill INT => \$p }; exec(\@ARGV) unless \$p = fork; alarm \$s; waitpid \$p, 0' 1800 'perl -CSDA -Mlocal::lib -Iperl5/lib/perl5 pdf2list.pl $file'");
}

system("perl -CSDA -Mlocal::lib -Iperl5/lib/perl5 createngram.pl");

foreach my $file (@files) {
    $file =~ /(\d+)-(\d+)/gs;
    $constituency=$1/1;
    $booth=$2;
    chomp ($file);
    if (!-e "rolls.$booth.sqlite") {system("echo 'Could not find original roll for booth $booth' >> $i.failure"); next}
    system("perl -e '\$s = shift; \$SIG{ALRM} = sub { kill INT => \$p }; exec(\@ARGV) unless \$p = fork; alarm \$s; waitpid \$p, 0' 1800 'perl -CSDA -Mlocal::lib -Iperl5/lib/perl5 addngram.pl $booth'");
}

system("rm $i.sqlite");
system("perl -CSDA -Mlocal::lib -Iperl5/lib/perl5 csv2stats.pl $i");

system("rm -r __pycache__ perl5 *.pl *.py fifo names.sqlite pdftotext ngram ngram-count");
