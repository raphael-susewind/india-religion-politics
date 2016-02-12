#!/usr/bin/perl -CSDA
#
# createnamedb.pl
# Copyright 2014 Raphael Susewind <mail@raphael-susewind.de>
# http://www.raphael-susewind.de
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
#

use WWW::Mechanize;
my $ua = WWW::Mechanize->new(agent=>'Mozilla/5.0 (X11; U; Linux i686; de; rv:1.9.0.16)',cookie_jar=>{});                                                                                

use DBI;
my $dbh = DBI->connect("dbi:SQLite:dbname=names.sqlite","","",{sqlite_unicode => 1});
$dbh->do ("CREATE TABLE names (name CHAR COLLATE NOCASE, name_bn CHAR, name_gu CHAR, name_hi CHAR, name_kn CHAR, name_ml CHAR, name_mr CHAR, name_ne CHAR, name_or CHAR, name_pa CHAR, name_sa CHAR, name_si CHAR, name_ta CHAR, name_te CHAR, name_ur CHAR, soundex_bn CHAR, soundex_gu CHAR, soundex_hi CHAR, soundex_kn CHAR, soundex_ml CHAR, soundex_mr CHAR, soundex_ne CHAR, soundex_or CHAR, soundex_pa CHAR, soundex_sa CHAR, soundex_si CHAR, soundex_ta CHAR, soundex_te CHAR, soundex_ur CHAR,  gender CHAR, community CHAR, namepart CHAR)");

# create bengali from english routine
sub bengali {
    my $ua = WWW::Mechanize->new(agent=>'Mozilla/5.0 (X11; U; Linux i686; de; rv:1.9.0.16)',cookie_jar=>{});                                                                                
    bengali: my $result = $ua->get('http://www.google.com/transliterate/indic?tlqt=1&langpair=en|bn&text='.$_[0].'&&tl_app=1');
    if ($result->is_error && $result->error_code != 404) {sleep 5; goto bengali}
    my $json=$ua->content;
    $json=~/\:\s+\[\s+\"(.*?)\"/gs;
    return $1;
}

# create gujarati from english routine
sub gujarati {
    my $ua = WWW::Mechanize->new(agent=>'Mozilla/5.0 (X11; U; Linux i686; de; rv:1.9.0.16)',cookie_jar=>{});                                                                                
    gujarati: my $result = $ua->get('http://www.google.com/transliterate/indic?tlqt=1&langpair=en|gu&text='.$_[0].'&&tl_app=1');
    if ($result->is_error && $result->error_code != 404) {sleep 5; goto gujarati}
    my $json=$ua->content;
    $json=~/\:\s+\[\s+\"(.*?)\"/gs;
    return $1;
}

# create hindi from english routine
sub hindi  {
    my $ua = WWW::Mechanize->new(agent=>'Mozilla/5.0 (X11; U; Linux i686; de; rv:1.9.0.16)',cookie_jar=>{});                                                                                
    hindi: my $result = $ua->get('http://www.google.com/transliterate/indic?tlqt=1&langpair=en|hi&text='.$_[0].'&&tl_app=1'); 
    if ($result->is_error && $result->error_code != 404) {sleep 5; goto hindi}
    my $json=$ua->content;
    $json=~/\:\s+\[\s+\"(.*?)\"/gs;
    return $1;
}

# create kannada from english routine
sub kannada {
    my $ua = WWW::Mechanize->new(agent=>'Mozilla/5.0 (X11; U; Linux i686; de; rv:1.9.0.16)',cookie_jar=>{});                                                                                
    kannada: my $result = $ua->get('http://www.google.com/transliterate/indic?tlqt=1&langpair=en|kn&text='.$_[0].'&&tl_app=1');
    if ($result->is_error && $result->error_code != 404) {sleep 5; goto kannada}
    my $json=$ua->content;
    $json=~/\:\s+\[\s+\"(.*?)\"/gs;
    return $1;
}

# create malayalam from english routine
sub malayalam {
    my $ua = WWW::Mechanize->new(agent=>'Mozilla/5.0 (X11; U; Linux i686; de; rv:1.9.0.16)',cookie_jar=>{});                                                                                
    malayalam: my $result = $ua->get('http://www.google.com/transliterate/indic?tlqt=1&langpair=en|ml&text='.$_[0].'&&tl_app=1');
    if ($result->is_error && $result->error_code != 404) {sleep 5; goto malayalam}
    my $json=$ua->content;
    $json=~/\:\s+\[\s+\"(.*?)\"/gs;
    return $1;
}

# create marathi from english routine
sub marathi {
    my $ua = WWW::Mechanize->new(agent=>'Mozilla/5.0 (X11; U; Linux i686; de; rv:1.9.0.16)',cookie_jar=>{});                                                                                
    marathi: my $result = $ua->get('http://www.google.com/transliterate/indic?tlqt=1&langpair=en|mr&text='.$_[0].'&&tl_app=1'); 
    if ($result->is_error && $result->error_code != 404) {sleep 5; goto marathi}
    my $json=$ua->content;
    $json=~/\:\s+\[\s+\"(.*?)\"/gs;
    return $1;
}

# create nepali from english routine
sub nepali {
    my $ua = WWW::Mechanize->new(agent=>'Mozilla/5.0 (X11; U; Linux i686; de; rv:1.9.0.16)',cookie_jar=>{});                                                                                
    nepali: my $result = $ua->get('http://www.google.com/transliterate/indic?tlqt=1&langpair=en|ne&text='.$_[0].'&&tl_app=1');
    if ($result->is_error && $result->error_code != 404) {sleep 5; goto nepali}
    my $json=$ua->content;
    $json=~/\:\s+\[\s+\"(.*?)\"/gs;
    return $1;
}

# create oriya from english routine
sub oriya {
    my $ua = WWW::Mechanize->new(agent=>'Mozilla/5.0 (X11; U; Linux i686; de; rv:1.9.0.16)',cookie_jar=>{});                                                                                
    oriya: my $result = $ua->get('http://www.google.com/transliterate/indic?tlqt=1&langpair=en|or&text='.$_[0].'&&tl_app=1');
    if ($result->is_error && $result->error_code != 404) {sleep 5; goto oriya}
    my $json=$ua->content;
    $json=~/\:\s+\[\s+\"(.*?)\"/gs;
    return $1;
}

# create punjabi from english routine
sub punjabi {
    my $ua = WWW::Mechanize->new(agent=>'Mozilla/5.0 (X11; U; Linux i686; de; rv:1.9.0.16)',cookie_jar=>{});                                                                                
    punjabi: my $result = $ua->get('http://www.google.com/transliterate/indic?tlqt=1&langpair=en|pa&text='.$_[0].'&&tl_app=1');
    if ($result->is_error && $result->error_code != 404) {sleep 5; goto punjabi}
    my $json=$ua->content;
    $json=~/\:\s+\[\s+\"(.*?)\"/gs;
    return $1;
}

# create sanskrit from english routine
sub sanskrit {
    my $ua = WWW::Mechanize->new(agent=>'Mozilla/5.0 (X11; U; Linux i686; de; rv:1.9.0.16)',cookie_jar=>{});                                                                                
    sanskrit: my $result = $ua->get('http://www.google.com/transliterate/indic?tlqt=1&langpair=en|sa&text='.$_[0].'&&tl_app=1');
    if ($result->is_error && $result->error_code != 404) {sleep 5; goto sanskrit}
    my $json=$ua->content;
    $json=~/\:\s+\[\s+\"(.*?)\"/gs;
    return $1;
}

# create sinhalese from english routine
sub sinhalese {
    my $ua = WWW::Mechanize->new(agent=>'Mozilla/5.0 (X11; U; Linux i686; de; rv:1.9.0.16)',cookie_jar=>{});                                                                                
    sinhalese: my $result = $ua->get('http://www.google.com/transliterate/indic?tlqt=1&langpair=en|si&text='.$_[0].'&&tl_app=1');
    if ($result->is_error && $result->error_code != 404) {sleep 5; goto sinhalese}
    my $json=$ua->content;
    $json=~/\:\s+\[\s+\"(.*?)\"/gs;
    return $1;
}

# create tamil from english routine
sub tamil {
    my $ua = WWW::Mechanize->new(agent=>'Mozilla/5.0 (X11; U; Linux i686; de; rv:1.9.0.16)',cookie_jar=>{});                                                                                
    tamil: my $result = $ua->get('http://www.google.com/transliterate/indic?tlqt=1&langpair=en|ta&text='.$_[0].'&&tl_app=1');
    if ($result->is_error && $result->error_code != 404) {sleep 5; goto tamil}
    my $json=$ua->content;
    $json=~/\:\s+\[\s+\"(.*?)\"/gs;
    return $1;
}

# create telugu from english routine
sub telugu {
    my $ua = WWW::Mechanize->new(agent=>'Mozilla/5.0 (X11; U; Linux i686; de; rv:1.9.0.16)',cookie_jar=>{});                                                                                
    telugu: my $result = $ua->get('http://www.google.com/transliterate/indic?tlqt=1&langpair=en|te&text='.$_[0].'&&tl_app=1');
    if ($result->is_error && $result->error_code != 404) {sleep 5; goto telugu}
    my $json=$ua->content;
    $json=~/\:\s+\[\s+\"(.*?)\"/gs;
    return $1;
}

# create urdu from english routine
sub urdu {
    my $ua = WWW::Mechanize->new(agent=>'Mozilla/5.0 (X11; U; Linux i686; de; rv:1.9.0.16)',cookie_jar=>{});                                                                                
    urdu: my $result = $ua->get('http://www.google.com/transliterate/indic?tlqt=1&langpair=en|ur&text='.$_[0].'&&tl_app=1');
    if ($result->is_error && $result->error_code != 404) {sleep 5; goto urdu}
    my $json=$ua->content;
    $json=~/\:\s+\[\s+\"(.*?)\"/gs;
    return $1;
}

# create indicsoundex from hindi routine
sub soundex {
    my $orig=$_[0];
    open (FILE,">soundextmp");
    print FILE $orig;
    close (FILE);
    system("python soundex.py");
    open (FILE,"soundextmp");
    $soundex=<FILE>;
    close (FILE);
    chomp($soundex); 
    system("rm -f soundextmp");
    return $soundex;
}

#
# Download the temp files in case they are not there yet
#

print "Download Hindu first names\n";
for ($i=1;$i<160;$i++) {
    next if (-e "hindunames$i.html");
    $ua->get( 'http://indiachildnames.com/indian/hindunames.aspx?type=num&pageno='.$i, ':content_file' => "hindunames$i.html" );
}
print "Download Muslim first names\n";
for ($i=1;$i<69;$i++) {
    next if (-e "muslimnames$i.html");
    $ua->get( 'http://indiachildnames.com/indian/muslimnames.aspx?type=num&pageno='.$i, ':content_file' => "muslimnames$i.html" );
}
print "Download Christian first names\n";
for ($i=1;$i<88;$i++) {
    next if (-e "christiannames$i.html");
    $ua->get( 'http://indiachildnames.com/indian/christiannames.aspx?type=num&pageno='.$i, ':content_file' => "christiannames$i.html" );
}
print "Download Sikh first names\n";
for ($i=1;$i<14;$i++) {
    next if (-e "sikhnames$i.html");
    $ua->get( 'http://indiachildnames.com/indian/sikhnames.aspx?type=num&pageno='.$i, ':content_file' => "sikhnames$i.html" );
}
print "Download Parsi first names\n";
for ($i=1;$i<18;$i++) {
    next if (-e "parsinames$i.html");
    $ua->get( 'http://indiachildnames.com/indian/parsinames.aspx?type=num&pageno='.$i, ':content_file' => "parsinames$i.html" );
}
print "Download Jain first names\n";
for ($i=1;$i<14;$i++) {
    next if (-e "jainnames$i.html");
    $ua->get( 'http://indiachildnames.com/indian/jainnames.aspx?type=num&pageno='.$i, ':content_file' => "jainnames$i.html" );
}
print "Download Buddhist first names\n";
for ($i=1;$i<3;$i++) {
    next if (-e "buddhistnames$i.html");
    $ua->get( 'http://indiachildnames.com/indian/buddhistnames.aspx?type=num&pageno='.$i, ':content_file' => "buddhistnames$i.html" );
}
print "Download surnames\n";
for ($i=1;$i<76;$i++) {
    next if (-e "surnames$i.html");
    $ua->get( 'http://indiachildnames.com/surname/familynamesbylanguage.aspx?type=num&pageno='.$i, ':content_file' => "surnames$i.html" );
}


#
# Now extract the actual data and put it into the database, adding vernaculars via google transliterate and indicsoundex via SILPA's soundex.py
#

my @hindunames=`ls hindunames*html`;
my @muslimnames=`ls muslimnames*html`;
my @christiannames=`ls christiannames*html`;
my @sikhnames=`ls sikhnames*html`;
my @parsinames=`ls parsinames*html`;
my @jainnames=`ls jainnames*html`;
my @buddhistnames=`ls buddhistnames*html`;
my @surnames=`ls surnames*html`;

print "Creating Vernacular and IndicSoundex for Hindu first names\n";
foreach my $hinduname (@hindunames) {
    chomp($hinduname);
    open(FILE,$hinduname);
    my @file=<FILE>;
    close(FILE);
    foreach my $line (@file) {
	next if $line !~ /name\.aspx\?name=(.*?)\".*?(Boy|Girl|Unisex)/gs;
	my $name=$1; my $gender=$2;
	$name=~s/\+/ /gs;
	if ($gender eq 'Boy') {$gender='m'}
	elsif ($gender eq 'Girl') {$gender='f'}
	else {$gender=''}
	$dbh->do ("INSERT INTO names VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)", undef, $name,bengali($name),gujarati($name),hindi($name),kannada($name),malayalam($name),marathi($name),nepali($name),oriya($name),punjabi($name),sanskrit($name),sinhalese($name),tamil($name),telugu($name),urdu($name),soundex(bengali($name)),soundex(gujarati($name)),soundex(hindi($name)),soundex(kannada($name)),soundex(malayalam($name)),soundex(marathi($name)),soundex(nepali($name)),soundex(oriya($name)),soundex(punjabi($name)),soundex(sanskrit($name)),soundex(sinhalese($name)),soundex(tamil($name)),soundex(telugu($name)),soundex(urdu($name)),$gender,'Hindu','f');
    }
}

print "Creating Vernacular and IndicSoundex for Muslim first names\n";
foreach my $muslimname (@muslimnames) {
    chomp($muslimname);
    open(FILE,$muslimname);
    my @file=<FILE>;
    close(FILE);
    foreach my $line (@file) {
	next if $line !~ /name\.aspx\?name=(.*?)\".*?(Boy|Girl|Unisex)/gs;
	my $name=$1; my $gender=$2;
	$name=~s/\+/ /gs;
	if ($gender eq 'Boy') {$gender='m'}
	elsif ($gender eq 'Girl') {$gender='f'}
	else {$gender=''}
	$dbh->do ("INSERT INTO names VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)", undef, $name,bengali($name),gujarati($name),hindi($name),kannada($name),malayalam($name),marathi($name),nepali($name),oriya($name),punjabi($name),sanskrit($name),sinhalese($name),tamil($name),telugu($name),urdu($name),soundex(bengali($name)),soundex(gujarati($name)),soundex(hindi($name)),soundex(kannada($name)),soundex(malayalam($name)),soundex(marathi($name)),soundex(nepali($name)),soundex(oriya($name)),soundex(punjabi($name)),soundex(sanskrit($name)),soundex(sinhalese($name)),soundex(tamil($name)),soundex(telugu($name)),soundex(urdu($name)),$gender,'Muslim','f');
    }
}

print "Creating Vernacular and IndicSoundex for Christian first names\n";
foreach my $christianname (@christiannames) {
    chomp($christianname);
    open(FILE,$christianname);
    my @file=<FILE>;
    close(FILE);
    foreach my $line (@file) {
	next if $line !~ /name\.aspx\?name=(.*?)\".*?(Boy|Girl|Unisex)/gs;
	my $name=$1; my $gender=$2;
	$name=~s/\+/ /gs;
	if ($gender eq 'Boy') {$gender='m'}
	elsif ($gender eq 'Girl') {$gender='f'}
	else {$gender=''}
	$dbh->do ("INSERT INTO names VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)", undef, $name,bengali($name),gujarati($name),hindi($name),kannada($name),malayalam($name),marathi($name),nepali($name),oriya($name),punjabi($name),sanskrit($name),sinhalese($name),tamil($name),telugu($name),urdu($name),soundex(bengali($name)),soundex(gujarati($name)),soundex(hindi($name)),soundex(kannada($name)),soundex(malayalam($name)),soundex(marathi($name)),soundex(nepali($name)),soundex(oriya($name)),soundex(punjabi($name)),soundex(sanskrit($name)),soundex(sinhalese($name)),soundex(tamil($name)),soundex(telugu($name)),soundex(urdu($name)),$gender,'Christian','f');
    }
}

print "Creating Vernacular and IndicSoundex for Sikh first names\n";
foreach my $sikhname (@sikhnames) {
    chomp($sikhname);
    open(FILE,$sikhname);
    my @file=<FILE>;
    close(FILE);
    foreach my $line (@file) {
	next if $line !~ /name\.aspx\?name=(.*?)\".*?(Boy|Girl|Unisex)/gs;
	my $name=$1; my $gender=$2;
	$name=~s/\+/ /gs;
	if ($gender eq 'Boy') {$gender='m'}
	elsif ($gender eq 'Girl') {$gender='f'}
	else {$gender=''}
	$dbh->do ("INSERT INTO names VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)", undef, $name,bengali($name),gujarati($name),hindi($name),kannada($name),malayalam($name),marathi($name),nepali($name),oriya($name),punjabi($name),sanskrit($name),sinhalese($name),tamil($name),telugu($name),urdu($name),soundex(bengali($name)),soundex(gujarati($name)),soundex(hindi($name)),soundex(kannada($name)),soundex(malayalam($name)),soundex(marathi($name)),soundex(nepali($name)),soundex(oriya($name)),soundex(punjabi($name)),soundex(sanskrit($name)),soundex(sinhalese($name)),soundex(tamil($name)),soundex(telugu($name)),soundex(urdu($name)),$gender,'Sikh','f');
    }
}

print "Creating Vernacular and IndicSoundex for Parsi first names\n";
foreach my $parsiname (@parsinames) {
    chomp($parsiname);
    open(FILE,$parsiname);
    my @file=<FILE>;
    close(FILE);
    foreach my $line (@file) {
	next if $line !~ /name\.aspx\?name=(.*?)\".*?(Boy|Girl|Unisex)/gs;
	my $name=$1; my $gender=$2;
	$name=~s/\+/ /gs;
	if ($gender eq 'Boy') {$gender='m'}
	elsif ($gender eq 'Girl') {$gender='f'}
	else {$gender=''}
	$dbh->do ("INSERT INTO names VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)", undef, $name,bengali($name),gujarati($name),hindi($name),kannada($name),malayalam($name),marathi($name),nepali($name),oriya($name),punjabi($name),sanskrit($name),sinhalese($name),tamil($name),telugu($name),urdu($name),soundex(bengali($name)),soundex(gujarati($name)),soundex(hindi($name)),soundex(kannada($name)),soundex(malayalam($name)),soundex(marathi($name)),soundex(nepali($name)),soundex(oriya($name)),soundex(punjabi($name)),soundex(sanskrit($name)),soundex(sinhalese($name)),soundex(tamil($name)),soundex(telugu($name)),soundex(urdu($name)),$gender,'Parsi','f');
    }
}

print "Creating Vernacular and IndicSoundex for Jain first names\n";
foreach my $jainname (@jainnames) {
    chomp($jainname);
    open(FILE,$jainname);
    my @file=<FILE>;
    close(FILE);
    foreach my $line (@file) {
	next if $line !~ /name\.aspx\?name=(.*?)\".*?(Boy|Girl|Unisex)/gs;
	my $name=$1; my $gender=$2;
	$name=~s/\+/ /gs;
	if ($gender eq 'Boy') {$gender='m'}
	elsif ($gender eq 'Girl') {$gender='f'}
	else {$gender=''}
	$dbh->do ("INSERT INTO names VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)", undef, $name,bengali($name),gujarati($name),hindi($name),kannada($name),malayalam($name),marathi($name),nepali($name),oriya($name),punjabi($name),sanskrit($name),sinhalese($name),tamil($name),telugu($name),urdu($name),soundex(bengali($name)),soundex(gujarati($name)),soundex(hindi($name)),soundex(kannada($name)),soundex(malayalam($name)),soundex(marathi($name)),soundex(nepali($name)),soundex(oriya($name)),soundex(punjabi($name)),soundex(sanskrit($name)),soundex(sinhalese($name)),soundex(tamil($name)),soundex(telugu($name)),soundex(urdu($name)),$gender,'Jain','f');
    }
}

print "Creating Vernacular and IndicSoundex for Buddhist first names\n";
foreach my $buddhistname (@buddhistnames) {
    chomp($buddhistname);
    open(FILE,$buddhistname);
    my @file=<FILE>;
    close(FILE);
    foreach my $line (@file) {
	next if $line !~ /name\.aspx\?name=(.*?)\".*?(Boy|Girl|Unisex)/gs;
	my $name=$1; my $gender=$2;
	$name=~s/\+/ /gs;
	if ($gender eq 'Boy') {$gender='m'}
	elsif ($gender eq 'Girl') {$gender='f'}
	else {$gender=''}
	$dbh->do ("INSERT INTO names VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)", undef, $name,bengali($name),gujarati($name),hindi($name),kannada($name),malayalam($name),marathi($name),nepali($name),oriya($name),punjabi($name),sanskrit($name),sinhalese($name),tamil($name),telugu($name),urdu($name),soundex(bengali($name)),soundex(gujarati($name)),soundex(hindi($name)),soundex(kannada($name)),soundex(malayalam($name)),soundex(marathi($name)),soundex(nepali($name)),soundex(oriya($name)),soundex(punjabi($name)),soundex(sanskrit($name)),soundex(sinhalese($name)),soundex(tamil($name)),soundex(telugu($name)),soundex(urdu($name)),$gender,'Buddhist','f');
    }
}

print "Creating Vernacular and IndicSoundex for surnames\n";
foreach my $surname (@surnames) {
    chomp($surname);
    open(FILE,$surname);
    my @file=<FILE>;
    close(FILE);
    foreach my $line (@file) {
	next if $line !~ /class=\"otherlinkclass\"/s;
	$line =~ /\?surname=(.*?)\"/s;
	my $name=$1; 
	$line =~ /^\<.*?\>\<.*?\>\<.*?\>(.*?)\</s;
	my $community=$1;
	if ($community eq $name && $community ne 'Muslim' && $community ne 'Christian') {$community=""}
 	$community=~s/[\(\)]//gs;
	$community=~s/,/ /gs;
	$community=~s/\s+/ /gs;
	my @community=split(/ /,$community);
	my $other=0;
	foreach my $com (@community) {
	    if ($com ne 'Muslim' and $com ne 'Christian' and $com ne '') { # resort to the vivaah.com portal for anything other than Muslim/Christian (since indiachildnames.com codes that by state, not by community - unfortunately and inconsistently)
		male: my $result = $ua->get( 'http://m.vivaah.com/matrimony-search/keyword-matrimony-profiles.php?gender=1&keywords='.$name.'&maritalstatus=0&age=18_100&pageno=1&search=Search', ':content_file' => "male.html.gz" );
		if ($result->is_error && $result->error_code != 404) {sleep 5; goto male}
		female: my $result = $ua->get( 'http://m.vivaah.com/matrimony-search/keyword-matrimony-profiles.php?gender=2&keywords='.$name.'&maritalstatus=0&age=18_100&pageno=1&search=Search', ':content_file' => "female.html.gz" );
		if ($result->is_error && $result->error_code != 404) {sleep 5; goto female}
		system("gunzip male.html.gz");
		system("gunzip female.html.gz");
		
		open (FILE,"male.html");
		my @male=<FILE>;
		close (FILE);
		open (FILE,"female.html");
		my @female=<FILE>;
		close (FILE);
		my @raw=(@male,@female);
		
		my %com;
		my $count=0;
		foreach my $line (@raw) {
		    next if $line !~ /Community \- /;
		    $line=~/\<\/b\>.*? - (.*?) \:/;
		    $com{$1}=$com{$1}+1;
		    $count++;
		}
		
		my @sorted = sort {$com{$b} <=> $com{$a}} (keys(%com));
		
		my $id=0;
		if ($count>0) {$id=$com{$sorted[1]}/$com{$sorted[0]}} # if one community crops up at least double as often, take it!
		if ($id<0.5) {$com=$sorted[0]}
		else {$com=''}
		
		system("rm -f male.html* female.html*");
	    } 
	    $dbh->do ("INSERT INTO names VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)", undef, $name,bengali($name),gujarati($name),hindi($name),kannada($name),malayalam($name),marathi($name),nepali($name),oriya($name),punjabi($name),sanskrit($name),sinhalese($name),tamil($name),telugu($name),urdu($name),soundex(bengali($name)),soundex(gujarati($name)),soundex(hindi($name)),soundex(kannada($name)),soundex(malayalam($name)),soundex(marathi($name)),soundex(nepali($name)),soundex(oriya($name)),soundex(punjabi($name)),soundex(sanskrit($name)),soundex(sinhalese($name)),soundex(tamil($name)),soundex(telugu($name)),soundex(urdu($name)),'',$com,'l');
	}
	
    }
}

system("rm -f soundextmp");
system("rm -f *names*.html");
