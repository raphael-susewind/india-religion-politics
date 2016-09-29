#!/usr/bin/perl

use WWW::Mechanize;
my $ua = WWW::Mechanize->new(agent=>'Mozilla/5.0 (X11; U; Linux i686; de; rv:1.9.0.16)',cookie_jar=>{},onerror=>undef);

$ua->get("http://ceo.gujarat.gov.in/download/Form20_2014/Form20_2014.html");

my @linksraw = $ua->find_all_links(url_regex => qr/.PDF$/);

foreach my $link (@linksraw) {
    $ua->get('http://ceo.gujarat.gov.in/download/Form20_2014/'.$link->url, ':content_file' => $link->url);
}
