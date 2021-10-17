#!/usr/bin/perl

# exit if -e 'done';

my $i=$ARGV[0];

my @files= `ls *-ocr.pdf`;

foreach my $file (@files) {
    $file =~ /(\d+)-(\d+)/gs;
    $constituency=$1/1;
    $booth=$2;
    chomp ($file);

    next if -e "rolls.$booth.sqlite";

    system("perl -e '\$s = shift; \$SIG{ALRM} = sub { kill INT => \$p }; exec(\@ARGV) unless \$p = fork; alarm \$s; waitpid \$p, 0' 3600 'perl -CSDA pdf2list.pl $file'");
    
}

unless (-e "ngram-jain-lm") {system("perl -CSDA createngram.pl");}

my @files = `ls rolls.*.sqlite`;

foreach my $file (@files) {
    $file =~ /(\d+)/gs;
    $booth=$1;
    system("perl -CSDA addngram.pl $booth");
}

system("perl -CSDA integrate.pl $i");
system("perl -CSDA csv2stats.pl $i");

system("rm -r __pycache__  *.pl *.py fifo names.sqlite *.sh");
system("touch done");
