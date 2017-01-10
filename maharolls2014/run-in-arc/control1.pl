#!/usr/bin/perl

use Parallel::ForkManager;
$pm = new Parallel::ForkManager(16);

for ($i=1;$i<=288;$i++) {
    next if !-e '/data/area-mnni/rsusewind/ceo.maharashtra.gov.in/Voter-List-2014-General-Elections/'.$i;
    next if -e '/data/area-mnni/rsusewind/ceo.maharashtra.gov.in/Voter-List-2014-General-Elections/'.$i.'/done';
    $pm->start and next;
    system('mkfifo /data/area-mnni/rsusewind/ceo.maharashtra.gov.in/Voter-List-2014-General-Elections/'.$i.'/fifo');
    system('cp *.py /data/area-mnni/rsusewind/ceo.maharashtra.gov.in/Voter-List-2014-General-Elections/'.$i);
    system('cp *.pl /data/area-mnni/rsusewind/ceo.maharashtra.gov.in/Voter-List-2014-General-Elections/'.$i);
    system('cp names.sqlite /data/area-mnni/rsusewind/ceo.maharashtra.gov.in/Voter-List-2014-General-Elections/'.$i);
    exec('cd /data/area-mnni/rsusewind/ceo.maharashtra.gov.in/Voter-List-2014-General-Elections/'.$i.' && perl subcontrol.pl '.$i);
    $pm->finish;
}

$pm->wait_all_children;
