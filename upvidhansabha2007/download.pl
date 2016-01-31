#!/usr/bin/perl

use WWW::Mechanize;

sub error {}

my $ua = WWW::Mechanize->new(agent=>'Mozilla/5.0 (X11; U; Linux i686; de; rv:1.9.0.16)',cookie_jar=>{},onerror=>\&error);                                                                   
$ua->get('http://ceouttarpradesh.nic.in/Default.aspx');                                                                                                                          
$ua->get('http://ceouttarpradesh.nic.in/Form20.aspx');                                                                                                                          

for ($i=1;$i<=403;$i++) {
    next if (-e "$i.xls");
    next if $i==20;
    next if $i==21;
    next if $i==22;
    next if $i==23;
    next if $i==25;
    next if $i==26;
    next if $i==27;
    next if $i==28;
    $ua->get( "http://ceouttarpradesh.nic.in/Form20_07/$i.xls", ':content_file' => "$i.xls" );
}

