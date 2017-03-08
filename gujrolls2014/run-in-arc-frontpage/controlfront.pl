#!/usr/bin/perl

use Parallel::ForkManager;
$pm = new Parallel::ForkManager(16);

for ($i=1;$i<=182;$i++) {
    next if -e "/data/area-mnni/rsusewind/ceogujarat.nic.in/Voter-List-2014/$i/donefront";
    $pm->start and next;
    system('cp *.pl /data/area-mnni/rsusewind/ceogujarat.nic.in/Voter-List-2014/'.$i);
    exec('cd /data/area-mnni/rsusewind/ceogujarat.nic.in/Voter-List-2014/'.$i.' && perl subcontrolfront.pl '.$i);
    $pm->finish;
}

$pm->wait_all_children;
