#!/usr/bin/perl

use Parallel::ForkManager;
$pm = new Parallel::ForkManager(16);

for ($i=1;$i<=40;$i++) {
    next if -e '/data/area-mnni/rsusewind/ceogoa.nic.in/Voter-List-2014/'.$i.'/done';
    $pm->start and next;
    system('mkfifo /data/area-mnni/rsusewind/ceogoa.nic.in/Voter-List-2014/'.$i.'/fifo');
    system('cp *.py /data/area-mnni/rsusewind/ceogoa.nic.in/Voter-List-2014/'.$i);
    system('cp *.pl /data/area-mnni/rsusewind/ceogoa.nic.in/Voter-List-2014/'.$i);
    system('cp names.sqlite /data/area-mnni/rsusewind/ceogoa.nic.in/Voter-List-2014/'.$i);
    exec('cd /data/area-mnni/rsusewind/ceogoa.nic.in/Voter-List-2014/'.$i.' && perl subcontrol.pl '.$i);
    $pm->finish;
}

$pm->wait_all_children;
