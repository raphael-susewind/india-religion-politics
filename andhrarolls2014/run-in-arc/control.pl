#!/usr/bin/perl

my $array=$ARGV[0];

my $stop=$array * 16;
my $start=$stop - 15;

if ($stop > 294) {$stop = 294}

use Parallel::ForkManager;
$pm = new Parallel::ForkManager(16);

for ($i=$start;$i<=$stop;$i++) {
    $pm->start and next;
    system('mkfifo /data/area-mnni/rsusewind/andhra/'.$i.'/fifo');
    system('cp *.py /data/area-mnni/rsusewind/andhra/'.$i);
    system('cp *.pl /data/area-mnni/rsusewind/andhra/'.$i);
    system('cp names.sqlite /data/area-mnni/rsusewind/andhra/'.$i);
    exec('cd /data/area-mnni/rsusewind/andhra/'.$i.' && perl subcontrol.pl '.$i);
    $pm->finish;
}

$pm->wait_all_children;
