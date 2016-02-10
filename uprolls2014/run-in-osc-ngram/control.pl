#!/usr/bin/perl

system('mkdir $TMPDIR/up');
system('mkdir $TMPDIR/up/2014');

my $array=$ARGV[0];

my $stop=$array * 16;
my $start=$stop - 15;

if ($stop > 403) {$stop = 403}

use Parallel::ForkManager;
$pm = new Parallel::ForkManager(16);

for ($i=$start;$i<=$stop;$i++) {
    $pm->start and next;
    
    system('mkdir $TMPDIR/up/2014/'.$i);
    system('rsync --archive $DATA/up/2014/'.$i.'/*sqlite $TMPDIR/up/2014/'.$i.'/');

    system('cp -r $HOME/perl5 $TMPDIR/up/2014/'.$i.'/perl5');
    system('cp *ngram* $TMPDIR/up/2014/'.$i);
    system('cp *.pl $TMPDIR/up/2014/'.$i);
    
    exec('cd $TMPDIR/up/2014/'.$i.' && perl -Mlocal::lib=perl5 -Iperl5/lib/perl5 subcontrol.pl '.$i);
    
    $pm->finish;
}

$pm->wait_all_children;
