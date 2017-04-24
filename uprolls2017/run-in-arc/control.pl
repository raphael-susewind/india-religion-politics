#!/usr/bin/perl

use Parallel::ForkManager;
$pm = new Parallel::ForkManager(16);

for ($i=1;$i<=403;$i++) {
    next if !-e '/data/area-mnni/rsusewind/ceouttarpradesh.nic.in/Voter-List-2017/'.$i;
    next if -e '/data/area-mnni/rsusewind/ceouttarpradesh.nic.in/Voter-List-2017/'.$i.'/done';
    $pm->start and next;
    system('mkfifo /data/area-mnni/rsusewind/ceouttarpradesh.nic.in/Voter-List-2017/'.$i.'/fifo');
    system('cp *.py /data/area-mnni/rsusewind/ceouttarpradesh.nic.in/Voter-List-2017/'.$i);
    system('cp *.pl /data/area-mnni/rsusewind/ceouttarpradesh.nic.in/Voter-List-2017/'.$i);
    system('cp names.sqlite /data/area-mnni/rsusewind/ceouttarpradesh.nic.in/Voter-List-2017/'.$i);
    exec('cd /data/area-mnni/rsusewind/ceouttarpradesh.nic.in/Voter-List-2017/'.$i." && perl -CSDA -Mlocal::lib -I/home/area-mnni/rsusewind/perl5/lib/perl5  subcontrol.pl ".$i);
    $pm->finish;
}

$pm->wait_all_children;
