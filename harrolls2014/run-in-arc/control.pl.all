#!/usr/bin/perl

system('mkdir /data/area-mnni/rsusewind/haryana');

my $array=$ARGV[0];

my $stop= $array * 16;
my $start= $stop - 15;

if ($stop > 90) {$stop = 90}

use Parallel::ForkManager;
$pm = new Parallel::ForkManager(16);

for ($i=$start;$i<=$stop;$i++) {
    $pm->start and next;
    system('mkdir /data/area-mnni/rsusewind/haryana/'.$i);
    system('mkfifo /data/area-mnni/rsusewind/haryana/'.$i.'/fifo');
    system('cp *.py /data/area-mnni/rsusewind/haryana/'.$i);
    system('cp *.pl /data/area-mnni/rsusewind/haryana/'.$i);
    system('cp names.sqlite /data/area-mnni/rsusewind/haryana/'.$i);
    exec('cd /data/area-mnni/rsusewind/haryana/'.$i.' && perl subcontrol.pl '.$i);
    $pm->finish;
}

$pm->wait_all_children;
