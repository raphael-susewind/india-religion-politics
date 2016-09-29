#!/usr/bin/perl

system('mkdir $DATA/gujarat');
system('mkdir $DATA/gujarat/2014');

system('mkdir $TMPDIR/gujarat');
system('mkdir $TMPDIR/gujarat/2014');

my $array=$ARGV[0];

my $stop=$array * 16;
my $start=$stop - 15;

if ($stop > 182) {$stop = 182}

use Parallel::ForkManager;
$pm = new Parallel::ForkManager(16);

for ($i=$start;$i<=$stop;$i++) {
    $pm->start and next;
    
    print "Fork $i: syncing TMPDIR\n";
    system('mkdir $DATA/gujarat/2014/'.$i);
    system('rsync --archive $DATA/gujarat/2014/'.$i.' $TMPDIR/gujarat/2014/');

    print "Fork $i: preparing TMPDIR\n";
    system('cp -r $HOME/perl5 $TMPDIR/gujarat/2014/'.$i);
    system('cp *.pl $TMPDIR/gujarat/2014/'.$i);
    system('cp pdftotext $TMPDIR/gujarat/2014/'.$i);

    print "Fork $i: running TMPDIR\n";
    exec('cd $TMPDIR/gujarat/2014/'.$i.' && perl subcontrol.pl '.$i);

    $pm->finish;
}

$pm->wait_all_children;
