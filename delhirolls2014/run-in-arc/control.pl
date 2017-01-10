#!/usr/bin/perl

system('mkdir /data/area-mnni/rsusewind/delhi');

my $array=$ARGV[0];

my $stop=$array * 16;
my $start=$stop - 15;

if ($stop > 70) {$stop = 70}

use Parallel::ForkManager;
$pm = new Parallel::ForkManager(16);

for ($i=$start;$i<=$stop;$i++) {
    $pm->start and next;
    system('mkdir /data/area-mnni/rsusewind/delhi/'.$i);
    system('mkfifo /data/area-mnni/rsusewind/delhi/'.$i.'/fifo');
    system('cp *.py /data/area-mnni/rsusewind/delhi/'.$i);
    system('cp *.pl /data/area-mnni/rsusewind/delhi/'.$i);
    system('cp names.sqlite /data/area-mnni/rsusewind/delhi/'.$i);
    exec('cd /data/area-mnni/rsusewind/delhi/'.$i.' && perl subcontrol.pl '.$i);
    $pm->finish;
}

$pm->wait_all_children;
