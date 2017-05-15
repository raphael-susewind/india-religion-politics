#!/usr/bin/perl -CSDA

use WWW::Mechanize;

my $array=$ARGV[0];

my $stop=$array * 16;
my $start=$stop - 15;

if ($stop > 403) {$stop = 403}

use Parallel::ForkManager;
$pm = new Parallel::ForkManager(16);

for ($i=$start;$i<=$stop;$i++) {
    next if (-e "$i.xml");
    $pm->start and next;
    my $ua = WWW::Mechanize->new(agent=>'Mozilla/5.0 (X11; U; Linux i686; de; rv:1.9.0.16)',cookie_jar=>{});                                                                   
    $ua->get('http://ceouttarpradesh.nic.in/Default.aspx');                                                                                                                          
    $ua->get('http://ceouttarpradesh.nic.in/Form20.aspx');                                                                                                                          
    $ua->get( "http://ceouttarpradesh.nic.in/Form20_17/$i.pdf", ':content_file' => "$i.pdf" );
    my $pagecount=`gs -q -dNODISPLAY -c "($i.pdf) (r) file runpdfbegin pdfpagecount = quit" `;
    chomp($pagecount); my $xml;
    for ($page=1;$page<=$pagecount;$page++) {
	$xml .= `PYTHONPATH=/home/area-mnni/rsusewind/lib/python2.6/site-packages:/system/software/linux-x86_64/lib/python2.6/site-packages python2.6 /home/area-mnni/rsusewind/bin/pdf-table-extract -i $i.pdf -p $page -r 300 -l 0.7 -t cells_xml`;
    }
    open (FILE, ">$i.xml");
    print FILE $xml;
    close (FILE);
    $pm->finish;
}

$pm->wait_all_children;
