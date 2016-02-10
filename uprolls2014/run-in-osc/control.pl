#!/usr/bin/perl

system('mkdir $DATA/up');
system('mkdir $DATA/up/2014');

my $array=$ARGV[0];

my $stop=$array * 16;
my $start=$stop - 15;

if ($stop > 403) {$stop = 403}

use Parallel::ForkManager;
$pm = new Parallel::ForkManager(16);

for ($i=$start;$i<=$stop;$i++) {
    $pm->start and next;
    system('mkdir $DATA/up/2014/'.$i);
    
    system('mkfifo $DATA/up/2014/'.$i.'/fifo');
    system('rm -r -f $DATA/up/2014/'.$i.'/perl5');
    system('cp -r $HOME/perl5-hal $DATA/up/2014/'.$i.'/perl5');
    system('cp -r $HOME/tesseract/share $DATA/up/2014/'.$i.'/tesseract');
    system('cp *.py $DATA/up/2014/'.$i);
    system('cp *.pl $DATA/up/2014/'.$i);
    system('cp names.sqlite $DATA/up/2014/'.$i);
    system('cp pdftotext $DATA/up/2014/'.$i);
    system('cp $HOME/ghostscript/bin/gs $DATA/up/2014/'.$i);
    print "running $i\n";
    exec('cd $DATA/up/2014/'.$i.' && perl -Mlocal::lib=perl5 -Iperl5/lib/perl5 subcontrol.pl '.$i);
    
    $pm->finish;
}

$pm->wait_all_children;
