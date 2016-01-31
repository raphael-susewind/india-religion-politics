#!/usr/bin/perl

use WWW::Mechanize;

my $ua = WWW::Mechanize->new(agent=>'Mozilla/5.0 (X11; U; Linux i686; de; rv:1.9.0.16)',cookie_jar=>{});                                                                   
$ua->get('http://ceouttarpradesh.nic.in/Default.aspx');                                                                                                                          
$ua->get('http://ceouttarpradesh.nic.in/Form20.aspx');                                                                                                                          

for ($i=1;$i<=403;$i++) {
    next if (-e "$i.xls");
    $ua->get( "http://ceouttarpradesh.nic.in/Form20_12/$i.xls", ':content_file' => "$i.xls" );
}
