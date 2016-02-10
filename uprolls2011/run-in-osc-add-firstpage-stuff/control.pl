#!/usr/bin/perl

my $array=$ARGV[0];

my $stop=$array * 16;
my $start=$stop - 15;

if ($stop > 403) {$stop = 403}

use Parallel::ForkManager;
$pm = new Parallel::ForkManager(16);

for ($i=$start;$i<=$stop;$i++) {
    $pm->start and next;
    system('cp -r perl5 /data/area-mnni/rsusewind/2011/'.$i);
    system('cp *.pl /data/area-mnni/rsusewind/2011/'.$i);
    system('cp pdftotext /data/area-mnni/rsusewind/2011/'.$i);
    exec('cd /data/area-mnni/rsusewind/2011/'.$i.' && perl subcontrol.pl '.$i);
    $pm->finish;
}

$pm->wait_all_children;
