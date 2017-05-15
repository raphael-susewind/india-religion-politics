#!/usr/bin/perl -CSDA

use DBI;
use XML::Simple;

#
# Create temporary sqlite table structure
#

my $dbh = DBI->connect("dbi:SQLite:dbname=temp.sqlite","","",{sqlite_unicode => 1});
$dbh->do("PRAGMA synchronous=OFF");
$dbh->do("PRAGMA cache_size = 80000");

$dbh->do ("CREATE TABLE upvidhansabha2017 (id INTEGER PRIMARY KEY, ac_id_09 INTEGER, booth_id_17 INTEGER, electors_17 INTEGER, turnout_17 INTEGER, turnout_percent_17 FLOAT, male_votes_17 INTEGER, female_votes_17 INTEGER, female_votes_percent_17 FLOAT, nota_17 INTEGER, tendered_17 INTEGER)");

#
# Parse XML and try to extract correct headers as well as content...
#

my %allparty;
for ($ac=1;$ac<=403;$ac++) { 
    my $actual; my %party; 
    print "Processing AC $ac\n";
      
    open (XML, "$ac.xml");
    my @file = <XML>;
    my $file = join("",@file);
    close (XML);
    
    $file =~ s/\<\?xml version\=\"1\.0\" \?\>\n//gs;
    $file =~ s/\<table src\=\"$ac\.pdf\"\>\n//gs;
    $file =~ s/\<\/table\>\n//gs;
    
    $file = "<table>$file</table>";
    
    my $xmlobj = new XML::Simple;
    my $xml = $xmlobj->XMLin($file, ForceArray => 1, ForceContent => 1, NormaliseSpace => 2, GroupTags => {cells => 'cell'});
    
    my $pagecount=0; my $rowindex; my $colindex;
    foreach my $cell (@{$xml->{cell}}) {
	$data->{int($cell->{p})}->{int($cell->{h})}->{int($cell->{x})} = $cell->{content}; # $data->{page}->{rowindex}->{colindex} = value CAREFUL ITS NOT x/y, its x/h [bug in pdf-table-extract on arcus!]
	$colindex->{int($cell->{p})}->{int($cell->{x})}=1;
	$rowindex->{int($cell->{p})}->{int($cell->{h})}=1;
	if ($pagecount < int($cell->{p})) {$pagecount=int($cell->{p})}
    }
    
    my $row; my $col;
    for ($p=1;$p<=$pagecount;$p++) {
	foreach my $key (keys(%{$rowindex->{$p}})) {push (@{$row->{int($p)}}, int($key))}
	@{$row->{$p}}=sort {$a <=> $b} @{$row->{$p}}; # @{$row->{page}} = sequence of rowindices
	foreach my $key (keys(%{$colindex->{$p}})) {push (@{$col->{int($p)}}, int($key))}
	@{$col->{$p}}=sort {$a <=> $b} @{$col->{$p}}; # @{$col->{page}} = sequence of colindices
    }
    
    my $header; my $indcount=1; my @discard; my %thisacparty;
    if ($data->{1}->{$row->{1}->[20]}->{$col->{1}->[2-1]} !~ /[a-zA-Z]/) {
	$header->{2} = 'booth_id_17'; 
	$header->{4} = 'electors_17';
	$header->{5} = 'male_votes_17';
	$header->{6} = 'female_votes_17';
	$header->{10} = 'tendered_17';
    } else {
	$header->{1} = 'booth_id_17'; 
	$header->{3} = 'electors_17';
	$header->{4} = 'male_votes_17';
	$header->{5} = 'female_votes_17';
	$header->{9} = 'tendered_17';
    }
    
    if ($data->{1}->{$row->{1}->[20]}->{$col->{1}->[@{$col->{1}}-1-1]} < $data->{1}->{$row->{1}->[20]}->{$col->{1}->[@{$col->{1}}-1]}) {
	$header->{@{$col->{1}}-1} = 'nota_17';
	$header->{@{$col->{1}}} = 'turnout_17';
    } else {
	$header->{@{$col->{1}}-1} = 'turnout_17';
	$header->{@{$col->{1}}} = 'nota_17';
    }

    for ($colcount=11;$colcount<@{$col->{1}}-1;$colcount++) {
        $header->{$colcount}=lc($data->{1}->{$row->{1}->[20]}->{$col->{1}->[$colcount-1-1]});
	$header->{$colcount}=~s/[^a-z\-]//gs;
	if ($header->{$colcount} eq '') {
          $header->{$colcount}=lc($data->{1}->{$row->{1}->[8]}->{$col->{1}->[$colcount-1-1]});
   	  $header->{$colcount}=~s/[^a-z\-]//gs;
	}
	if ($header->{$colcount} eq '') {
          $header->{$colcount}=lc($data->{1}->{$row->{1}->[7]}->{$col->{1}->[$colcount-1-1]});
   	  $header->{$colcount}=~s/[^a-z\-]//gs;
	}
	if ($header->{$colcount} eq '') {
          $header->{$colcount}=lc($data->{1}->{$row->{1}->[6]}->{$col->{1}->[$colcount-1-1]});
   	  $header->{$colcount}=~s/[^a-z\-]//gs;
	}
	if ($header->{$colcount} eq '' || $header->{$colcount} eq '-' || $header->{$colcount} eq '--') {
	  push(@discard,$colcount);next
	}
	if ($header->{$colcount} eq 'independent') {$header->{$colcount}='ind'}
	elsif ($header->{$colcount} eq 'peaceparty') {$header->{$colcount}='pp'}
	elsif ($header->{$colcount} eq 'shivsena') {$header->{$colcount}='ss'}
	elsif ($header->{$colcount} eq 'indep') {$header->{$colcount} = 'ind'}
	elsif ($header->{$colcount} eq 'indipendent') {$header->{$colcount} = 'ind'}
	elsif ($header->{$colcount} eq 'indp') {$header->{$colcount} = 'ind'}
	elsif ($header->{$colcount} eq 'indpendent') {$header->{$colcount} = 'ind'}
	elsif ($header->{$colcount} eq 'indpt') {$header->{$colcount} = 'ind'}
	elsif ($header->{$colcount} eq 'indt') {$header->{$colcount} = 'ind'}
	elsif ($header->{$colcount} eq 'independent') {$header->{$colcount} = 'ind'}
	elsif ($header->{$colcount} eq 'nir') {$header->{$colcount} = 'ind'}
	elsif ($header->{$colcount} eq 'a-p-') {$header->{$colcount} = 'ap'}
	elsif ($header->{$colcount} eq 'a-p') {$header->{$colcount} = 'ap'}
	elsif ($header->{$colcount} eq 'apnadal') {$header->{$colcount} = 'ad'}
	elsif ($header->{$colcount} eq 'b-j-') {$header->{$colcount} = 'bj'}
	elsif ($header->{$colcount} eq 'bahujansamajparty') {$header->{$colcount} = 'bsp'}
	elsif ($header->{$colcount} eq 'bhartiyajantaparty') {$header->{$colcount} = 'bjp'}
	elsif ($header->{$colcount} eq 'bhartiyasatyarthsangthan') {$header->{$colcount} = 'bss'}
	elsif ($header->{$colcount} eq 'cpi-ml-l') {$header->{$colcount} = 'cpi-mll'}
	elsif ($header->{$colcount} eq 'cpim') {$header->{$colcount} = 'cpi-m'}
	elsif ($header->{$colcount} eq 'cpiml') {$header->{$colcount} = 'cpi-ml'}
	elsif ($header->{$colcount} eq 'cpoi-ml-l') {$header->{$colcount} = 'cpi-mll'}
	elsif ($header->{$colcount} eq 'hasiya,hatoda,sitara') {$header->{$colcount} = 'hhs'}
	elsif ($header->{$colcount} eq 'indianjp') {$header->{$colcount} = 'ijp'}
	elsif ($header->{$colcount} eq 'indiannationalcongres') {$header->{$colcount} = 'inc'}
	elsif ($header->{$colcount} eq 'janmorch') {$header->{$colcount} = 'jm'}
	elsif ($header->{$colcount} eq 'janmorcha') {$header->{$colcount} = 'jm'}
	elsif ($header->{$colcount} eq 'janmo') {$header->{$colcount} = 'jm'}
	elsif ($header->{$colcount} eq 'jd-secular') {$header->{$colcount} = 'jd-s'}
	elsif ($header->{$colcount} eq 'l-d') {$header->{$colcount} = 'ld'}
	elsif ($header->{$colcount} eq 'lokdal') {$header->{$colcount} = 'ld'}
	elsif ($header->{$colcount} eq 'lokjanp') {$header->{$colcount} = 'ljp'}
	elsif ($header->{$colcount} eq 'rastriyalokdal') {$header->{$colcount} = 'rld'}
	elsif ($header->{$colcount} eq 'samajwadiparty') {$header->{$colcount} = 'sp'}
	elsif ($header->{$colcount} eq 'samta') {$header->{$colcount} = 's'}
	elsif ($header->{$colcount} eq 'samtap') {$header->{$colcount} = 's'}
	elsif ($header->{$colcount} eq 's-p-') {$header->{$colcount} = 'sp'}
	elsif ($header->{$colcount} eq 'samtaparty') {$header->{$colcount} = 's'}
	elsif ($header->{$colcount} eq 'samtapartyp') {$header->{$colcount} = 's'}
	elsif ($header->{$colcount} eq 'samyawadiparty') {$header->{$colcount} = 'sap'}
	elsif ($header->{$colcount} eq 'shivsena') {$header->{$colcount} = 'ss'}
	elsif ($header->{$colcount} eq 'shivsenap') {$header->{$colcount} = 'ss'}
	elsif ($header->{$colcount} =~ /sjp./gs && $party ne 'sjpr' && $party ne 'sjp-r') {$header->{$colcount} = 'sjp'}
	elsif ($header->{$colcount} eq 'hasiyahatodasitara') {$party='hhs'}
	elsif ($header->{$colcount} eq 'adarsadarshrashtriyavikasparty') {$header->{$colcount} = 'arvp'}
	elsif ($header->{$colcount} eq 'adarshrashtriyavikasdal') {$header->{$colcount} = 'arvd'}
	elsif ($header->{$colcount} eq 'adarshrashtriyavikashparty') {$header->{$colcount} = 'arvp'}
	elsif ($header->{$colcount} eq 'adarshrashtriyavikasparty') {$header->{$colcount} = 'arvp'}
	elsif ($header->{$colcount} eq 'adarshsamajparty') {$header->{$colcount} = 'asp'}
	elsif ($header->{$colcount} eq 'addal') {$header->{$colcount} = 'add'}
	elsif ($header->{$colcount} eq 'ait-c') {$header->{$colcount} = 'aitc'}
	elsif ($header->{$colcount} eq 'akhilbharathindumahasabha') {$header->{$colcount} = 'abhm'}
	elsif ($header->{$colcount} eq 'akhilbharatiyadeshbhaktmorcha') {$header->{$colcount} = 'abdbm'}
	elsif ($header->{$colcount} eq 'akhilbhartiyaloktantrikcongress') {$header->{$colcount} = 'abltc'}
	elsif ($header->{$colcount} eq 'al-hindparty') {$header->{$colcount} = 'ahp'}
	elsif ($header->{$colcount} eq 'allindiaforwardblock') {$header->{$colcount} = 'aifb'}
	elsif ($header->{$colcount} eq 'allindiaminoritiesfront') {$header->{$colcount} = 'aimf'}
	elsif ($header->{$colcount} eq 'allindiantrinamoolcongress') {$header->{$colcount} = 'aitc'}
	elsif ($header->{$colcount} eq 'allindiatranmoolcongress') {$header->{$colcount} = 'aitc'}
	elsif ($header->{$colcount} eq 'allindiatrinamoolcogress') {$header->{$colcount} = 'aitc'}
	elsif ($header->{$colcount} eq 'allindiatrinamoolcongress') {$header->{$colcount} = 'aitc'}
	elsif ($header->{$colcount} eq 'allindiatrinmoolcongress') {$header->{$colcount} = 'aitc'}
	elsif ($header->{$colcount} eq 'ambedakarsamajparty') {$header->{$colcount} = 'asp'}
	elsif ($header->{$colcount} eq 'ambedkarnationalcongress') {$header->{$colcount} = 'anc'}
	elsif ($header->{$colcount} eq 'ambedkarsamajparty') {$header->{$colcount} = 'asp'}
	elsif ($header->{$colcount} eq 'ambedkarsamajpatry') {$header->{$colcount} = 'asp'}
	elsif ($header->{$colcount} eq 'apanadal') {$header->{$colcount} = 'ad'}
	elsif ($header->{$colcount} eq 'asankhyasamajparty') {$header->{$colcount} = 'assp'}
	elsif ($header->{$colcount} eq 'bahujansagharshparty-kanshiram') {$header->{$colcount} = 'bsp-k'}
	elsif ($header->{$colcount} eq 'bahujansamajparty-ambedkar') {$header->{$colcount} = 'bsp-a'}
	elsif ($header->{$colcount} eq 'bahujansangharshparty-kanshiram') {$header->{$colcount} = 'bsp-k'}
	elsif ($header->{$colcount} eq 'bahujanshakti') {$header->{$colcount} = 'bs'}
	elsif ($header->{$colcount} eq 'bharatiyaeklavyaparty') {$header->{$colcount} = 'bep'}
	elsif ($header->{$colcount} eq 'bharatiyajanataparty') {$header->{$colcount} = 'bjp'}
	elsif ($header->{$colcount} eq 'bharatiyajanberojgarchhatradal') {$header->{$colcount} = 'bjbgd'}
	elsif ($header->{$colcount} eq 'bharatiyajantaparty') {$header->{$colcount} = 'bjp'}
	elsif ($header->{$colcount} eq 'bharatiyakrishakdal') {$header->{$colcount} = 'bkd'}
	elsif ($header->{$colcount} eq 'bharatiyaprajatantranirmanparty') {$header->{$colcount} = 'bptnp'}
	elsif ($header->{$colcount} eq 'bharatiyarashtriyabahujansamajvikasparty') {$header->{$colcount} = 'bsbsvp'}
	elsif ($header->{$colcount} eq 'bharatiyarepublicanpaksh') {$header->{$colcount} = 'brp'}
	elsif ($header->{$colcount} eq 'bharatiyarepublicanpaksha') {$header->{$colcount} = 'brp'}
	elsif ($header->{$colcount} eq 'bharatiyasamajdal') {$header->{$colcount} = 'bsd'}
	elsif ($header->{$colcount} eq 'bhartiyabanchitsamajparty') {$header->{$colcount} = 'bbsp'}
	elsif ($header->{$colcount} eq 'bhartiyajanataparty') {$header->{$colcount} = 'bjp'}
	elsif ($header->{$colcount} eq 'bhartiyakrishakdal') {$header->{$colcount} = 'bkd'}
	elsif ($header->{$colcount} eq 'bhartiyaprajatantranirmanparty') {$header->{$colcount} = 'bptnp'}
	elsif ($header->{$colcount} eq 'bhartiyarashtriyamorcha') {$header->{$colcount} = 'brm'}
	elsif ($header->{$colcount} eq 'bhartiyarepublicanpaksha') {$header->{$colcount} = 'brp'}
	elsif ($header->{$colcount} eq 'bhartiyasamajikkrantidal') {$header->{$colcount} = 'bskd'}
	elsif ($header->{$colcount} eq 'bhartiyasarvodayakrantiparty') {$header->{$colcount} = 'bskd'}
	elsif ($header->{$colcount} eq 'bhartiyasarvodaykrantiparty') {$header->{$colcount} = 'bskd'}
	elsif ($header->{$colcount} eq 'bhartiyasubhashsena') {$header->{$colcount} = 'bss'}
	elsif ($header->{$colcount} eq 'bhartiyavanchitsamajparty') {$header->{$colcount} = 'bvsp'}
	elsif ($header->{$colcount} eq 'bhartiyavidasparty') {$header->{$colcount} = 'bvp'}
	elsif ($header->{$colcount} eq 'bhartiyjanataparty') {$header->{$colcount} = 'bjp'}
	elsif ($header->{$colcount} eq 'bhartiyjantaparty') {$header->{$colcount} = 'bjp'}
	elsif ($header->{$colcount} eq 'brajvikasparty') {$header->{$colcount} = 'bravp'}
	elsif ($header->{$colcount} eq 'bsp-kanshiram') {$header->{$colcount} = 'bsp-k'}
	elsif ($header->{$colcount} eq 'buladelkhandcongress') {$header->{$colcount} = 'bkc'}
	elsif ($header->{$colcount} eq 'bundelkhandcongress') {$header->{$colcount} = 'bkc'}
	elsif ($header->{$colcount} eq 'bunndelkhandcongress') {$header->{$colcount} = 'bkc'}
	elsif ($header->{$colcount} eq 'communistpartyofindia') {$header->{$colcount} = 'cpi'}
	elsif ($header->{$colcount} eq 'communistpartyofindia-marxist') {$header->{$colcount} = 'cpi-m'}
	elsif ($header->{$colcount} eq 'communistpartyofindia-marxist-leninist-liberation') {$header->{$colcount} = 'cpi-mll'}
	elsif ($header->{$colcount} eq 'communistpartyofindia-marxistleninist-libration') {$header->{$colcount} = 'cpi-mll'}
	elsif ($header->{$colcount} eq 'congress') {$header->{$colcount} = 'inc'}
	elsif ($header->{$colcount} eq 'cpi-m-l') {$header->{$colcount} = 'cpi-ml'}
	elsif ($header->{$colcount} eq 'cpi-m-ll') {$header->{$colcount} = 'cpi-mll'}
	elsif ($header->{$colcount} eq 'cpimll') {$header->{$colcount} = 'cpi-mll'}
	elsif ($header->{$colcount} eq 'cpm') {$header->{$colcount} = 'cpi-m'}
	elsif ($header->{$colcount} eq 'dalitsamajparty') {$header->{$colcount} = 'dsp'}
	elsif ($header->{$colcount} eq 'eklavyasamajparty') {$header->{$colcount} = 'esp'}
	elsif ($header->{$colcount} eq 'gareebsamanaparty') {$header->{$colcount} = 'gsp'}
	elsif ($header->{$colcount} eq 'indiajusticeparty') {$header->{$colcount} = 'ijp'}
	elsif ($header->{$colcount} eq 'indiancongressparty') {$header->{$colcount} = 'inc'}
	elsif ($header->{$colcount} eq 'indianjusticeparty') {$header->{$colcount} = 'ijp'}
	elsif ($header->{$colcount} eq 'indiannationalcongress') {$header->{$colcount} = 'inc'}
	elsif ($header->{$colcount} eq 'indiannationalistcongress') {$header->{$colcount} = 'inc'}
	elsif ($header->{$colcount} eq 'indiannationalleague') {$header->{$colcount} = 'inl'}
	elsif ($header->{$colcount} eq 'indiannationlcongress') {$header->{$colcount} = 'inc'}
	elsif ($header->{$colcount} eq 'indianoceanicparty') {$header->{$colcount} = 'iop'}
	elsif ($header->{$colcount} eq 'inqalabvikasdal') {$header->{$colcount} = 'ivs'}
	elsif ($header->{$colcount} eq 'ittehad-e-millattcouncil') {$header->{$colcount} = 'iemc'}
	elsif ($header->{$colcount} eq 'ittehademillatcouncil') {$header->{$colcount} = 'iemc'}
	elsif ($header->{$colcount} eq 'jagratbharatparty') {$header->{$colcount} = 'jbp'}
	elsif ($header->{$colcount} eq 'jaimahabharatparty') {$header->{$colcount} = 'jmbp'}
	elsif ($header->{$colcount} eq 'jammu&kashmirnationalpanthersparty') {$header->{$colcount} = 'jknpp'}
	elsif ($header->{$colcount} eq 'jan-krantiparty-rashtrawadi') {$header->{$colcount} = 'jkp-r'}
	elsif ($header->{$colcount} eq 'janatadal-u') {$header->{$colcount} = 'jd-u'}
	elsif ($header->{$colcount} eq 'janatadal-united') {$header->{$colcount} = 'jd-u'}
	elsif ($header->{$colcount} eq 'janatadalunited') {$header->{$colcount} = 'jd-u'}
	elsif ($header->{$colcount} eq 'janatavikasmanch') {$header->{$colcount} = 'jvm'}
	elsif ($header->{$colcount} eq 'jankarantiparty') {$header->{$colcount} = 'jkp'}
	elsif ($header->{$colcount} eq 'jankarantiparty-rashtrawadi') {$header->{$colcount} = 'jkp-r'}
	elsif ($header->{$colcount} eq 'jankrantiparty') {$header->{$colcount} = 'jkp'}
	elsif ($header->{$colcount} eq 'jankrantiparty-nationalist') {$header->{$colcount} = 'jkp-n'}
	elsif ($header->{$colcount} eq 'jankrantiparty-rashtravadi') {$header->{$colcount} = 'jkp-r'}
	elsif ($header->{$colcount} eq 'jankrantiparty-rashtrawadi') {$header->{$colcount} = 'jkp-r'}
	elsif ($header->{$colcount} eq 'jankrantiparty-rastravadi') {$header->{$colcount} = 'jkp-r'}
	elsif ($header->{$colcount} eq 'jankrantiparty-rastrawadi') {$header->{$colcount} = 'jkp-r'}
	elsif ($header->{$colcount} eq 'jankrantiparty-rastrawady') {$header->{$colcount} = 'jkp-r'}
	elsif ($header->{$colcount} eq 'jankrantipartyrashtrawadi') {$header->{$colcount} = 'jkp-r'}
	elsif ($header->{$colcount} eq 'jankrantipartyrastrawadi') {$header->{$colcount} = 'jkp-r'}
	elsif ($header->{$colcount} eq 'jansanghparty') {$header->{$colcount} = 'jsp'}
	elsif ($header->{$colcount} eq 'jantadal-secular') {$header->{$colcount} = 'jd-s'}
	elsif ($header->{$colcount} eq 'jantadal-united') {$header->{$colcount} = 'jd-u'}
	elsif ($header->{$colcount} eq 'jantadalsecular') {$header->{$colcount} = 'jd-s'}
	elsif ($header->{$colcount} eq 'jantadalunited') {$header->{$colcount} = 'jd-u'}
	elsif ($header->{$colcount} eq 'janvadiparty-socialist') {$header->{$colcount} = 'jvp-s'}
	elsif ($header->{$colcount} eq 'janvadiparty-sociolist') {$header->{$colcount} = 'jvp-s'}
	elsif ($header->{$colcount} eq 'janvadipartyofindia-socialist') {$header->{$colcount} = 'jvp-s'}
	elsif ($header->{$colcount} eq 'janwadiparty-socialist') {$header->{$colcount} = 'jvp-s'}
	elsif ($header->{$colcount} eq 'javankisanmorcha') {$header->{$colcount} = 'jkm'}
	elsif ($header->{$colcount} eq 'jawankisanmorcha') {$header->{$colcount} = 'jkm'}
	elsif ($header->{$colcount} eq 'jharkhandmuktimorcha') {$header->{$colcount} = 'jkmm'}
	elsif ($header->{$colcount} eq 'jd-uni') {$header->{$colcount} = 'jd-u'}
	elsif ($header->{$colcount} eq 'jd-united') {$header->{$colcount} = 'jd-u'}
	elsif ($header->{$colcount} eq 'jdu') {$header->{$colcount} = 'jd-u'}
	elsif ($header->{$colcount} eq 'jkp®') {$header->{$colcount} = 'jkp-r'}
	elsif ($header->{$colcount} eq 'jkp¼r½') {$header->{$colcount} = 'jkp-r'}
	elsif ($header->{$colcount} eq 'jnd') {$header->{$colcount} = 'jd'}
	elsif ($header->{$colcount} eq 'jp[r]') {$header->{$colcount} = 'jp-r'}
	elsif ($header->{$colcount} eq 'jpr') {$header->{$colcount} = 'jp-r'}
	elsif ($header->{$colcount} eq 'jps') {$header->{$colcount} = 'jp-s'}
	elsif ($header->{$colcount} eq 'jp®') {$header->{$colcount} = 'jp-r'}
	elsif ($header->{$colcount} eq 'jwaladal') {$header->{$colcount} = 'jwd'}
	elsif ($header->{$colcount} eq 'kisansena') {$header->{$colcount} = 'ks'}
	elsif ($header->{$colcount} eq 'kis') {$header->{$colcount} = 'ks'}
	elsif ($header->{$colcount} eq 'kpimll') {$header->{$colcount} = 'cpi-mll'}
	elsif ($header->{$colcount} eq 'krantikarisamataparty') {$header->{$colcount} = 'kksp'}
	elsif ($header->{$colcount} eq 'krantikarisamtaparty') {$header->{$colcount} = 'kksp'}
	elsif ($header->{$colcount} eq 'labourpartyofindia-vvprasad') {$header->{$colcount} = 'lpi-vvp'}
	elsif ($header->{$colcount} eq 'lokjansaktiparty') {$header->{$colcount} = 'ljsp'}
	elsif ($header->{$colcount} eq 'lokjanshaktiparty') {$header->{$colcount} = 'ljsp'}
	elsif ($header->{$colcount} eq 'lokjanshkatiparty') {$header->{$colcount} = 'ljsp'}
	elsif ($header->{$colcount} eq 'loknirmanparty') {$header->{$colcount} = 'lnp'}
	elsif ($header->{$colcount} eq 'lokpriyasamajparty') {$header->{$colcount} = 'lpsp'}
	elsif ($header->{$colcount} eq 'lokpriysamajparty') {$header->{$colcount} = 'lpsp'}
	elsif ($header->{$colcount} eq 'mahandal') {$header->{$colcount} = 'md'}
	elsif ($header->{$colcount} eq 'manavadhikarjanshaktiparty') {$header->{$colcount} = 'majsp'}
	elsif ($header->{$colcount} eq 'manavtawadisamajparti') {$header->{$colcount} = 'masp'}
	elsif ($header->{$colcount} eq 'manavtawadisamajparty') {$header->{$colcount} = 'masp'}
	elsif ($header->{$colcount} eq 'maulikadhikarparty') {$header->{$colcount} = 'map'}
	elsif ($header->{$colcount} eq 'meydhaaparty') {$header->{$colcount} = 'mdp'}
	elsif ($header->{$colcount} eq 'mominconference') {$header->{$colcount} = 'mmc'}
	elsif ($header->{$colcount} eq 'mostbackwardclassesofindia') {$header->{$colcount} = 'mbci'}
	elsif ($header->{$colcount} eq 'muslimmajlisuttarpradesh') {$header->{$colcount} = 'mmup'}
	elsif ($header->{$colcount} eq 'naitikparty') {$header->{$colcount} = 'naitikp'}
	elsif ($header->{$colcount} eq 'nakibharatiyaekataparty') {$header->{$colcount} = 'nbep'}
	elsif ($header->{$colcount} eq 'nakibharatiyaektaparty') {$header->{$colcount} = 'nbep'}
	elsif ($header->{$colcount} eq 'nakibhartiyaeaktaparty') {$header->{$colcount} = 'nbep'}
	elsif ($header->{$colcount} eq 'nakibhartiyaektaparty') {$header->{$colcount} = 'nbep'}
	elsif ($header->{$colcount} eq 'nationalbackwardparty') {$header->{$colcount} = 'nbp'}
	elsif ($header->{$colcount} eq 'nationalcongressparty') {$header->{$colcount} = 'ncp'}
	elsif ($header->{$colcount} eq 'nationalistcongressparty') {$header->{$colcount} = 'ncp'}
	elsif ($header->{$colcount} eq 'nationalistloktantrikparty') {$header->{$colcount} = 'nltp'}
	elsif ($header->{$colcount} eq 'nationalloktantrikparty') {$header->{$colcount} = 'nltp'}
	elsif ($header->{$colcount} eq 'parivartandal') {$header->{$colcount} = 'pvd'}
	elsif ($header->{$colcount} eq 'parivartansamajparty') {$header->{$colcount} = 'pvsp'}
	elsif ($header->{$colcount} eq 'peaceparty') {$header->{$colcount} = 'pp'}
	elsif ($header->{$colcount} eq 'pragatisheelmanavsamajparty') {$header->{$colcount} = 'psmsp'}
	elsif ($header->{$colcount} eq 'pragitisheelmanavsamajparty') {$header->{$colcount} = 'psmsp'}
	elsif ($header->{$colcount} eq 'prajatantrikbahujanshaktidal') {$header->{$colcount} = 'prbd'}
	elsif ($header->{$colcount} eq 'progressivedemocraticparty') {$header->{$colcount} = 'pdp'}
	elsif ($header->{$colcount} eq 'qaumiektadal') {$header->{$colcount} = 'qed'}
	elsif ($header->{$colcount} eq 'quamiektadal') {$header->{$colcount} = 'qed'}
	elsif ($header->{$colcount} eq 'rahtriyasmamantadal') {$header->{$colcount} = 'rsd'}
	elsif ($header->{$colcount} eq 'rajlokparty') {$header->{$colcount} = 'rlp'}
	elsif ($header->{$colcount} eq 'rashtraloknirmanparty') {$header->{$colcount} = 'rlnp'}
	elsif ($header->{$colcount} eq 'rashtranirmanparty') {$header->{$colcount} = 'rnp'}
	elsif ($header->{$colcount} eq 'rashtravadicommunistparty') {$header->{$colcount} = 'rcp'}
	elsif ($header->{$colcount} eq 'rashtrawadilabourparty') {$header->{$colcount} = 'rlp'}
	elsif ($header->{$colcount} eq 'rashtraylokmanch') {$header->{$colcount} = 'rlm'}
	elsif ($header->{$colcount} eq 'rashtriyaambedkardal') {$header->{$colcount} = 'rad'}
	elsif ($header->{$colcount} eq 'rashtriyaapnadal') {$header->{$colcount} = 'rapd'}
	elsif ($header->{$colcount} eq 'rashtriyabackwardparty') {$header->{$colcount} = 'rbp'}
	elsif ($header->{$colcount} eq 'rashtriyabahujanhitayparty') {$header->{$colcount} = 'rbhp'}
	elsif ($header->{$colcount} eq 'rashtriyagondwanaparty') {$header->{$colcount} = 'rgp'}
	elsif ($header->{$colcount} eq 'rashtriyainsafparty') {$header->{$colcount} = 'rip'}
	elsif ($header->{$colcount} eq 'rashtriyajansewakparty') {$header->{$colcount} = 'rjsp'}
	elsif ($header->{$colcount} eq 'rashtriyajanvadiparty-krantikari') {$header->{$colcount} = 'rjvp-k'}
	elsif ($header->{$colcount} eq 'rashtriyajanwadiparty-krantikari') {$header->{$colcount} = 'rjvp-k'}
	elsif ($header->{$colcount} eq 'rashtriyakrantikarisamajwadiparty') {$header->{$colcount} = 'rksp'}
	elsif ($header->{$colcount} eq 'rashtriyalokdal') {$header->{$colcount} = 'rld'}
	elsif ($header->{$colcount} eq 'rashtriyalokmanch') {$header->{$colcount} = 'rlm'}
	elsif ($header->{$colcount} eq 'rashtriyalokmanchparty') {$header->{$colcount} = 'rlm'}
	elsif ($header->{$colcount} eq 'rashtriyaloknirmanparty') {$header->{$colcount} = 'rlnp'}
	elsif ($header->{$colcount} eq 'rashtriyamahandal') {$header->{$colcount} = 'rmd'}
	elsif ($header->{$colcount} eq 'rashtriyamahangantantraparty') {$header->{$colcount} = 'rmgtp'}
	elsif ($header->{$colcount} eq 'rashtriyamanavsammanparty') {$header->{$colcount} = 'rmsp'}
	elsif ($header->{$colcount} eq 'rashtriyaparivartandal') {$header->{$colcount} = 'rpd'}
	elsif ($header->{$colcount} eq 'rashtriyasamantadal') {$header->{$colcount} = 'rsd'}
	elsif ($header->{$colcount} eq 'rashtriyaswabhimaanparty') {$header->{$colcount} = 'rswp'}
	elsif ($header->{$colcount} eq 'rashtriyaswabhimanparty') {$header->{$colcount} = 'rswp'}
	elsif ($header->{$colcount} eq 'rashtriyaulamaamacouncil') {$header->{$colcount} = 'ruc'}
	elsif ($header->{$colcount} eq 'rashtriyaulamacouncil') {$header->{$colcount} = 'ruc'}
	elsif ($header->{$colcount} eq 'rashtriyaulamadal') {$header->{$colcount} = 'rud'}
	elsif ($header->{$colcount} eq 'rashtriyaulemacouncil') {$header->{$colcount} = 'ruc'}
	elsif ($header->{$colcount} eq 'rashtriyaviklangparty') {$header->{$colcount} = 'rvlp'}
	elsif ($header->{$colcount} eq 'rashtriyjanwadiparty-krantikari') {$header->{$colcount} = 'rjp-k'}
	elsif ($header->{$colcount} eq 'rastriyagondawanaparty') {$header->{$colcount} = 'rgp'}
	elsif ($header->{$colcount} eq 'rastriyajan-tantrapaksh') {$header->{$colcount} = 'rjtp'}
	elsif ($header->{$colcount} eq 'rastriyakrantikarisamajwadiparty') {$header->{$colcount} = 'rkksp'}
	elsif ($header->{$colcount} eq 'rastriyalikmanch') {$header->{$colcount} = 'rlm'}
	elsif ($header->{$colcount} eq 'rastriyalokmanch') {$header->{$colcount} = 'rlm'}
	elsif ($header->{$colcount} eq 'rastriyaloknirmanparty') {$header->{$colcount} = 'rlnp'}
	elsif ($header->{$colcount} eq 'rastriyamahandal') {$header->{$colcount} = 'rmd'}
	elsif ($header->{$colcount} eq 'rastriyamahangantantraparty') {$header->{$colcount} = 'rmgtp'}
	elsif ($header->{$colcount} eq 'rastriyaparivartandal') {$header->{$colcount} = 'rpd'}
	elsif ($header->{$colcount} eq 'rastriyaprivartandal') {$header->{$colcount} = 'rpd'}
	elsif ($header->{$colcount} eq 'rastriyasamanatadal') {$header->{$colcount} = 'rsd'}
	elsif ($header->{$colcount} eq 'rastriyasuryaprakashparty') {$header->{$colcount} = 'rspp'}
	elsif ($header->{$colcount} eq 'rastriyaviklangparty') {$header->{$colcount} = 'rvlp'}
	elsif ($header->{$colcount} eq 'ravidasparty') {$header->{$colcount} = 'rp'}
	elsif ($header->{$colcount} eq 'republicanpartyofindia-a') {$header->{$colcount} = 'rpi-a'}
	elsif ($header->{$colcount} eq 'republicanpartyofindiaa') {$header->{$colcount} = 'rpi-a'}
	elsif ($header->{$colcount} eq 'republicnpartyofindia') {$header->{$colcount} = 'rpi'}
	elsif ($header->{$colcount} eq 'repubnlicanpartyofindia-democratic') {$header->{$colcount} = 'rpi-d'}
	elsif ($header->{$colcount} eq 'rlokmanch') {$header->{$colcount} = 'rlm'}
	elsif ($header->{$colcount} eq 'samajawadiparty') {$header->{$colcount} = 'sp'}
	elsif ($header->{$colcount} eq 'samajvadiparty') {$header->{$colcount} = 'sp'}
	elsif ($header->{$colcount} eq 'samajwadijanataparty-rashtriya') {$header->{$colcount} = 'sjp-r'}
	elsif ($header->{$colcount} eq 'samajwadijanataparty-rastriya') {$header->{$colcount} = 'sjp-r'}
	elsif ($header->{$colcount} eq 'samajwadijanparishad') {$header->{$colcount} = 'sjp'}
	elsif ($header->{$colcount} eq 'samastbharatiyaparty') {$header->{$colcount} = 'sbp'}
	elsif ($header->{$colcount} eq 'samastbhartiyaparty') {$header->{$colcount} = 'sbp'}
	elsif ($header->{$colcount} eq 'samtasamajwadicongressparty') {$header->{$colcount} = 'sscp'}
	elsif ($header->{$colcount} eq 'sarwajanmahasabha') {$header->{$colcount} = 'sms'}
	elsif ($header->{$colcount} eq 'sdpoi') {$header->{$colcount} = 'sdpi'}
	elsif ($header->{$colcount} eq 'shoshitsamajdal') {$header->{$colcount} = 'ssd'}
	elsif ($header->{$colcount} eq 'shositsamajdal') {$header->{$colcount} = 'ssd'}
	elsif ($header->{$colcount} eq 'smajwadiparty') {$header->{$colcount} = 'sp'}
	elsif ($header->{$colcount} eq 'socialdemocraticpartyofindia') {$header->{$colcount} = 'sdpi'}
	elsif ($header->{$colcount} eq 'socialistparty-india') {$header->{$colcount} = 'spi'}
	elsif ($header->{$colcount} eq 'socialistpartyindia') {$header->{$colcount} = 'spi'}
	elsif ($header->{$colcount} eq 'socialistunitycenterofindia-communist') {$header->{$colcount} = 'suci-c'}
	elsif ($header->{$colcount} eq 'socialistunitycentreofindia-communist') {$header->{$colcount} = 'suci-c'}
	elsif ($header->{$colcount} eq 'sociolistpartyindia') {$header->{$colcount} = 'spi'}
	elsif ($header->{$colcount} eq 'socp-i') {$header->{$colcount} = 'spi'}
	elsif ($header->{$colcount} eq 'sp-i') {$header->{$colcount} = 'spi'}
	elsif ($header->{$colcount} eq 'suheildevbhartiyasamajparty') {$header->{$colcount} = 'sdbsp'}
	elsif ($header->{$colcount} eq 'suheldeobhartiyasamajparty') {$header->{$colcount} = 'sdbsp'}
	elsif ($header->{$colcount} eq 'suheldevbharatiyasamajparty') {$header->{$colcount} = 'sdbsp'}
	elsif ($header->{$colcount} eq 'suheldevbhartiyasamajparty') {$header->{$colcount} = 'sdbsp'}
	elsif ($header->{$colcount} eq 'swarahtrajanparty') {$header->{$colcount} = 'swtp'}
	elsif ($header->{$colcount} eq 'swarajdal') {$header->{$colcount} = 'swd'}
	elsif ($header->{$colcount} eq 'swarajparty-scbosh') {$header->{$colcount} = 'swp-scb'}
	elsif ($header->{$colcount} eq 'vanchitjamatparty') {$header->{$colcount} = 'vjp'}
	elsif ($header->{$colcount} eq 'vanchitsamaj') {$header->{$colcount} = 'vs'}
	elsif ($header->{$colcount} eq 'vanchitsamajinsaafparty') {$header->{$colcount} = 'vsip'}
	elsif ($header->{$colcount} eq 'vanchitsamajinsafparty') {$header->{$colcount} = 'vsip'}
	elsif ($header->{$colcount} eq 'yuvavikashparty') {$header->{$colcount} = 'ysp'}
	elsif ($header->{$colcount} eq 'yuvavikasparty') {$header->{$colcount} = 'yvp'}
	elsif ($header->{$colcount} eq 'ameim') {$header->{$colcount} = 'aimim'}
	elsif ($header->{$colcount} eq 'bhartiyamominfront') {$header->{$colcount} = 'bmf'}
	elsif ($header->{$colcount} eq 'akhandsamajparty') {$header->{$colcount} = 'asp'}
	elsif ($header->{$colcount} eq 'uttarpradeshrepublicanparty') {$header->{$colcount} = 'uprp'}
	elsif ($header->{$colcount} eq 'bharatiyasubhassena') {$header->{$colcount} = 'bss'}
	elsif ($header->{$colcount} eq 'aarakshanvirodhiparty') {$header->{$colcount} = 'arvp'}
	elsif ($header->{$colcount} eq 'allindiamajlis-e-ittehadulmuslimeen') {$header->{$colcount} = 'aimim'}
	elsif ($header->{$colcount} eq 'rashtriyakisanmazdoorparty') {$header->{$colcount} = 'rkmp'}
	elsif ($header->{$colcount} eq 'bhartiyataraksamajparty') {$header->{$colcount} = 'brp'}
	elsif ($header->{$colcount} eq 'bhartiyabahujanparivartanparty') {$header->{$colcount} = 'bbpp'}
	elsif ($header->{$colcount} eq 'uniteddemocraticfrontsecular') {$header->{$colcount} = 'udf-s'}
	elsif ($header->{$colcount} eq 'bhartiyataraksamajparty') {$header->{$colcount} = 'brsp'}
	elsif ($header->{$colcount} eq 'bahujanmuktiparty') {$header->{$colcount} = 'bmp'}
	elsif ($header->{$colcount} eq 'rashtriyakisanmajdoorparty') {$header->{$colcount} = 'rkmp'}
	elsif ($header->{$colcount} eq 'hindusthannirmandal') {$header->{$colcount} = 'hnm'}
	elsif ($header->{$colcount} eq 'uniteddemocraticsfrontsecular') {$header->{$colcount} = 'udf-s'}
	elsif ($header->{$colcount} eq 'rashtriyaloksamataparty') {$header->{$colcount} = 'rlsp'}
	elsif ($header->{$colcount} eq 'bharatiyataraksamajparty') {$header->{$colcount} = 'brsp'}
	elsif ($header->{$colcount} eq 'indiannastioncongress') {$header->{$colcount} = 'inc'}
	elsif ($header->{$colcount} eq 'ittehad-e-millaitcouncil') {$header->{$colcount} = 'iemc'}
	elsif ($header->{$colcount} eq 'sarvodayabharatparty') {$header->{$colcount} = 'sbp'}
	elsif ($header->{$colcount} eq 'aamjantapartyrashtriya') {$header->{$colcount} = 'ajpr'}
	elsif ($header->{$colcount} eq 'sarvjansamtaparty') {$header->{$colcount} = 'sjsp'}
	elsif ($header->{$colcount} eq 'sarvsambhavparty') {$header->{$colcount} = 'ssp'}
	elsif ($header->{$colcount} eq 'bhartiyanaujawaninklavparty') {$header->{$colcount} = 'bnip'}
	elsif ($header->{$colcount} eq 'ittehad-e-millatcouncil') {$header->{$colcount} = 'iemc'}
	elsif ($header->{$colcount} eq 'rashtriyalokdall') {$header->{$colcount} = 'rld'}
	elsif ($header->{$colcount} eq 'rashtriyakrantiparty') {$header->{$colcount} = 'rkp'}
	elsif ($header->{$colcount} eq 'republicansena') {$header->{$colcount} = 'rs'}
	elsif ($header->{$colcount} eq 'sarvasamajkalyanparty') {$header->{$colcount} = 'sskp'}
	elsif ($header->{$colcount} eq 'kisanmajdoorsurakshaparty') {$header->{$colcount} = 'kmsp'}
	elsif ($header->{$colcount} eq 'apnizindgiapnadal') {$header->{$colcount} = 'azad'}
	elsif ($header->{$colcount} eq 'samanadhikarparty') {$header->{$colcount} = 'sap'}
	elsif ($header->{$colcount} eq 'janadhikarparty') {$header->{$colcount} = 'jap'}
	elsif ($header->{$colcount} eq 'rashtravadipratapsena') {$header->{$colcount} = 'rps'}
	elsif ($header->{$colcount} eq 'aimeim') {$header->{$colcount} = 'aimim'}
	elsif ($header->{$colcount} eq 'bharatiyasubhashsena') {$header->{$colcount} = 'bss'}
	elsif ($header->{$colcount} eq 'rashtriyaloksamtaparty') {$header->{$colcount} = 'rlsp'}
	elsif ($header->{$colcount} eq 'janadhikarmanch') {$header->{$colcount} = 'jam'}
	elsif ($header->{$colcount} eq 'nirbalindianshoshithamaraaamdal') {$header->{$colcount} = 'nishad'}
	elsif ($header->{$colcount} eq 'bharatiyashaktichetnaparty') {$header->{$colcount} = 'bscp'}
	elsif ($header->{$colcount} eq 'manavhitparty') {$header->{$colcount} = 'mp'}
	elsif ($header->{$colcount} eq 'prajashaktipartysamdarshi') {$header->{$colcount} = 'psps'}
	elsif ($header->{$colcount} eq 'sanyuktsamajwadidal') {$header->{$colcount} = 'ssd'}
	elsif ($header->{$colcount} eq 'bharatiyajahataparty') {$header->{$colcount} = 'bjp'}
	elsif ($header->{$colcount} eq 'bharatiyabahujanparivartanparty') {$header->{$colcount} = 'bbjp'}
	elsif ($header->{$colcount} eq 'rashtravadipratapsena') {$header->{$colcount} = 'rps'}
	elsif ($header->{$colcount} eq 'bhartiyabhaicharaparty') {$header->{$colcount} = 'bbp'}
	elsif ($header->{$colcount} eq 'allindiamajli-e-ittehadulmuslimeen') {$header->{$colcount} = 'aimim'}
	elsif ($header->{$colcount} eq 'kalyankarijantantrikparty') {$header->{$colcount} = 'kktp'}
	elsif ($header->{$colcount} eq 'rashtriyamazdoorektaparty') {$header->{$colcount} = 'rmep'}
	elsif ($header->{$colcount} eq 'deshshaktiparty') {$header->{$colcount} = 'dsp'}
	elsif ($header->{$colcount} eq 'bharatiyashubhash') {$header->{$colcount} = 'bsp'}
	elsif ($header->{$colcount} eq 'jansevasahayak') {$header->{$colcount} = 'jss'}
	elsif ($header->{$colcount} eq 'bhartiyaimaandarparty') {$header->{$colcount} = 'bip'}
	elsif ($header->{$colcount} eq 'rashtriyajanadharparty') {$header->{$colcount} = 'rjap'}
	elsif ($header->{$colcount} eq 'sarvsambhavparty') {$header->{$colcount} = 'ssp'}
	elsif ($header->{$colcount} eq 'swarajyapartyofindia') {$header->{$colcount} = 'spi'}
	elsif ($header->{$colcount} eq 'bharatkamyunistparty') {$header->{$colcount} = 'cpi'}
	elsif ($header->{$colcount} eq 'bhagidarikrantidal') {$header->{$colcount} = 'bkd'}
	elsif ($header->{$colcount} eq 'bhartishaktichetnaparty') {$header->{$colcount} = 'bsep'}
	elsif ($header->{$colcount} eq 'aalindiamajlis-a-ettehadulmusalmin') {$header->{$colcount} = 'aimim'}
	elsif ($header->{$colcount} eq 'akhilbhartiyavikascongressparty') {$header->{$colcount} = 'abvcp'}
	elsif ($header->{$colcount} eq 'rashtriyasahrivikasparty') {$header->{$colcount} = 'rsvp'}
	elsif ($header->{$colcount} eq 'indipandent') {$header->{$colcount} = 'ind'}
	elsif ($header->{$colcount} eq 'akhilbhartiyajansangh') {$header->{$colcount} = 'akjs'}
	elsif ($header->{$colcount} eq 'rashtriyashaharivikasparty') {$header->{$colcount} = 'rsvp'}
	elsif ($header->{$colcount} eq 'nationalyouthparty') {$header->{$colcount} = 'nyp'}
	elsif ($header->{$colcount} eq 'faujijanataparty') {$header->{$colcount} = 'fjp'}
	elsif ($header->{$colcount} eq 'sarvasambhavparty') {$header->{$colcount} = 'ssp'}
	elsif ($header->{$colcount} eq 'indiansavarnparty') {$header->{$colcount} = 'isp'}
	elsif ($header->{$colcount} eq 'manviyabharatparty') {$header->{$colcount} = 'mbp'}
	elsif ($header->{$colcount} eq 'paramdigvijaydal') {$header->{$colcount} = 'pdd'}
	elsif ($header->{$colcount} eq 'mahilaswabhimanparty') {$header->{$colcount} = 'msp'}
	elsif ($header->{$colcount} eq 'jansangharshviratparty') {$header->{$colcount} = 'jsvp'}
	elsif ($header->{$colcount} eq 'allindiamajlis-e-ittehadulmouselmeen') {$header->{$colcount} = 'aimim'}
	elsif ($header->{$colcount} eq 'rashtriyashahrivikasparty') {$header->{$colcount} = 'rsvp'}
	elsif ($header->{$colcount} eq 'swaryajyapartyofindia') {$header->{$colcount} = 'spi'}
	elsif ($header->{$colcount} eq 'indiansawarnsamajparty') {$header->{$colcount} = 'issp'}
	elsif ($header->{$colcount} eq 'samajsewakparty') {$header->{$colcount} = 'ssp'}
	elsif ($header->{$colcount} eq 'swarajyapartyofindia') {$header->{$colcount} = 'spi'}
	elsif ($header->{$colcount} eq 'loktantriksamajwadiparty') {$header->{$colcount} = 'lsp'}
	elsif ($header->{$colcount} eq 'aadarshvyavasthaparty') {$header->{$colcount} = 'avp'}
	elsif ($header->{$colcount} eq 'manavtavadikranti') {$header->{$colcount} = 'mak'}
	elsif ($header->{$colcount} eq 'nagrikektaparty') {$header->{$colcount} = 'nep'}
	elsif ($header->{$colcount} eq 'kisankrantidal') {$header->{$colcount} = 'kkd'}
	elsif ($header->{$colcount} eq 'vikasparty') {$header->{$colcount} = 'vp'}
	elsif ($header->{$colcount} eq 'manavadhikarnationalparty') {$header->{$colcount} = 'manp'}
	elsif ($header->{$colcount} eq 'janvadipartysocialist') {$header->{$colcount} = 'jps'}
	elsif ($header->{$colcount} eq 'allindiamajlis-e-ittehadulmuslimeen') {$header->{$colcount} = 'aimim'}
	elsif ($header->{$colcount} eq 'allindiapichhadajansamajparty') {$header->{$colcount} = 'aipjsp'}
	elsif ($header->{$colcount} eq 'bhartiyasarvodayaparty') {$header->{$colcount} = 'bsap'}
	elsif ($header->{$colcount} eq 'apnadeshparty') {$header->{$colcount} = 'adp'}
	elsif ($header->{$colcount} eq 'gareebkrantiparty') {$header->{$colcount} = 'gkp'}
	elsif ($header->{$colcount} eq 'sampoornasamajparty') {$header->{$colcount} = 'ssp'}
	elsif ($header->{$colcount} eq 'bharatiyamominfront') {$header->{$colcount} = 'bmf'}
	elsif ($header->{$colcount} eq 'communistpartyofindiamarxist') {$header->{$colcount} = 'cpi-m'}
	elsif ($header->{$colcount} eq 'allindiamajliseittehadulmuslimeen') {$header->{$colcount} = 'aimim'}
	elsif ($header->{$colcount} eq 'arakshanvirodhiparty') {$header->{$colcount} = 'avp'}
	elsif ($header->{$colcount} eq 'rashtriyacongressbabujagjivanram') {$header->{$colcount} = 'rcbjj'}
	elsif ($header->{$colcount} eq 'rashtriyamajdoorektaparty') {$header->{$colcount} = 'rmep'}
	elsif ($header->{$colcount} eq 'socialistunitycentreofindiacommunist') {$header->{$colcount} = 'suci-c'}
	elsif ($header->{$colcount} eq 'shivsaina') {$header->{$colcount} = 'ss'}
	elsif ($header->{$colcount} eq 'hindusthannirmanparty') {$header->{$colcount} = 'hnp'}
	elsif ($header->{$colcount} eq 'bhartiyashaktichetnaparty') {$header->{$colcount} = 'bscp'}
	elsif ($header->{$colcount} eq 'bharatiyabhaichara') {$header->{$colcount} = 'bb'}
	elsif ($header->{$colcount} eq 'bharatiyaimandarparty') {$header->{$colcount} = 'bip'}
	elsif ($header->{$colcount} eq 'rashtriyashoshitsamajparty') {$header->{$colcount} = 'rssp'}
	elsif ($header->{$colcount} eq 'bharatkrantirakshakparty') {$header->{$colcount} = 'bkrp'}
	elsif ($header->{$colcount} eq 'ojaswiparty') {$header->{$colcount} = 'op'}
	elsif ($header->{$colcount} eq 'rashtravyapijantaparty') {$header->{$colcount} = 'rvjp'}
	elsif ($header->{$colcount} eq 'manuvadiparty') {$header->{$colcount} = 'mp'}
	elsif ($header->{$colcount} eq 'sabkadalunited') {$header->{$colcount} = 'sd-u'}
	elsif ($header->{$colcount} eq 'samjwadiparty') {$header->{$colcount} = 'sp'}
	elsif ($header->{$colcount} eq 'voterspartyinternational') {$header->{$colcount} = 'vpi'}
	elsif ($header->{$colcount} eq 'sanyuktvikasparty') {$header->{$colcount} = 'svp'}
	elsif ($header->{$colcount} eq 'ndependet') {$header->{$colcount} = 'ind'}
	elsif ($header->{$colcount} eq 'bhartiyashaktichetanaparty') {$header->{$colcount} = 'bscp'}
	elsif ($header->{$colcount} eq 'bhartiyashubhashsena') {$header->{$colcount} = 'bss'}
	elsif ($header->{$colcount} eq 'bhartiyashaktichetnaparty') {$header->{$colcount} = 'bscp'}
	elsif ($header->{$colcount} eq 'jaihindjaibharatparty') {$header->{$colcount} = 'jhjbp'}
	elsif ($header->{$colcount} eq 'aadhiaabadiparty') {$header->{$colcount} = 'aap'}
	elsif ($header->{$colcount} eq 'proutistblocindia') {$header->{$colcount} = 'pbi'}
	elsif ($header->{$colcount} eq 'bhartiyainsanparty') {$header->{$colcount} = 'bip'}
	elsif ($header->{$colcount} eq 'bharatiyakaryasthsena') {$header->{$colcount} = 'bks'}
	elsif ($header->{$colcount} eq 'bahujanparty') {$header->{$colcount} = 'bp'}
	elsif ($header->{$colcount} eq 'congressindiannational') {$header->{$colcount} = 'inc'}
	elsif ($header->{$colcount} eq 'nationalpeacepartysecular') {$header->{$colcount} = 'npp-s'}
	elsif ($header->{$colcount} eq 'samajwadijanatapartychandrashekhar') {$header->{$colcount} = 'sjpcc'}
	elsif ($header->{$colcount} eq 'sarvsambhaavparty') {$header->{$colcount} = 'ssp'}
	elsif ($header->{$colcount} eq 'bhartyashaktiparty') {$header->{$colcount} = 'bsap'}
	elsif ($header->{$colcount} eq 'ojasviparty') {$header->{$colcount} = 'op'}
	elsif ($header->{$colcount} eq 'kisanmajdoorberojgarsangh') {$header->{$colcount} = 'kmbs'}
	elsif ($header->{$colcount} eq 'swatantrajantarajparty') {$header->{$colcount} = 'sjp'}
	elsif ($header->{$colcount} eq 'communistpartyofindiamarxist-lenenistliberation') {$header->{$colcount} = 'cpi-m-ll'}
	elsif ($header->{$colcount} eq 'rashtriyasarvajanparty') {$header->{$colcount} = 'rsp'}
	elsif ($header->{$colcount} eq 'awamisamtaparty') {$header->{$colcount} = 'asp'}
	elsif ($header->{$colcount} eq 'rashtriyabahujancongressparty') {$header->{$colcount} = 'rbcp'}
	elsif ($header->{$colcount} eq 'socialistunitycentreofindiacommunist') {$header->{$colcount} = 'suci-c'}
	elsif ($header->{$colcount} eq 'bahujanawamparty') {$header->{$colcount} = 'bap'}
	elsif ($header->{$colcount} eq 'bharatiyasangamparty') {$header->{$colcount} = 'bsap'}
	elsif ($header->{$colcount} eq 'communistpartyofindianmarxist') {$header->{$colcount} = 'cpi-m'}
	elsif ($header->{$colcount} eq 'bharatiyarastriyajansatta') {$header->{$colcount} = 'brss'}
	elsif ($header->{$colcount} eq 'apanadals') {$header->{$colcount} = 'ad'}
	elsif ($header->{$colcount} eq 'rastriyasamajpaksha') {$header->{$colcount} = 'rsp'}
	elsif ($header->{$colcount} eq 'pragatisheelsamajparty') {$header->{$colcount} = 'pssp'}
	elsif ($header->{$colcount} eq 'bahujanawaamparty') {$header->{$colcount} = 'bap'}
	elsif ($header->{$colcount} eq 'independen') {$header->{$colcount} = 'ind'}
	elsif ($header->{$colcount} eq 'ambedkaryugparty') {$header->{$colcount} = 'ayp'}
	elsif ($header->{$colcount} eq 'pichhravargmahapanchyatparty') {$header->{$colcount} = 'pvmp'}
	elsif ($header->{$colcount} eq 'sarvashambhavparty') {$header->{$colcount} = 'ssp'}
	elsif ($header->{$colcount} eq 'naveensamajwadidal') {$header->{$colcount} = 'nsd'}
	elsif ($header->{$colcount} eq 'samaajwadiparty') {$header->{$colcount} = 'sp'}
	elsif ($header->{$colcount} eq 'rashtriyasamajpaksh') {$header->{$colcount} = 'rsp'}
	elsif ($header->{$colcount} eq 'aadimsamajparty') {$header->{$colcount} = 'asp'}
	elsif ($header->{$colcount} eq 'liberationcommunistpartyofindiamarxist-leninist') {$header->{$colcount} = 'lcpiml'}
	elsif ($header->{$colcount} eq 'moulikadhikarparty') {$header->{$colcount} = 'map'}
	elsif ($header->{$colcount} eq 'aadarshwaadicongressparty') {$header->{$colcount} = 'acp'}
	elsif ($header->{$colcount} eq 'adhikarparty') {$header->{$colcount} = 'ap'}
	elsif ($header->{$colcount} eq 'allindiamajlis-e-ittehadul') {$header->{$colcount} = 'aimim'}
	elsif ($header->{$colcount} eq 'bharatiyajanatapartyl') {$header->{$colcount} = 'bjp'}
	elsif ($header->{$colcount} eq 'peacepart') {$header->{$colcount} = 'pp'}
	elsif ($header->{$colcount} eq 'allindiamajlis-eittehadulmuslimeen') {$header->{$colcount} = 'aimim'}	
	elsif ($header->{$colcount} eq 'jayhindjaybharatparty') {$header->{$colcount} = 'jhjbp'}
	elsif ($header->{$colcount} eq 'independet') {$header->{$colcount} = 'ind'}
	elsif ($header->{$colcount} eq 'bahujansamaj') {$header->{$colcount} = 'bsp'}	
	elsif ($header->{$colcount} eq 'poorvanchalpeoplesparty') {$header->{$colcount} = 'ppp'}
	elsif ($header->{$colcount} eq 'apnadalunitedparty') {$header->{$colcount} = 'ad-u'}
	elsif ($header->{$colcount} eq 'rastriyajanadharparty') {$header->{$colcount} = 'rjap'}	
	elsif ($header->{$colcount} eq 'satyakrantiparty') {$header->{$colcount} = 'skp'}
	elsif ($header->{$colcount} eq 'bhartiyshaktichetana') {$header->{$colcount} = 'bscp'}
	elsif ($header->{$colcount} eq 'bhartiyasarvjanparty') {$header->{$colcount} = 'bsjp'}	
	elsif ($header->{$colcount} eq 'islampartyhind') {$header->{$colcount} = 'iph'}
	elsif ($header->{$colcount} eq 'samajwatiparty') {$header->{$colcount} = 'sp'}
	elsif ($header->{$colcount} eq 'ninshad') {$header->{$colcount} = 'nishad'}	
	elsif ($header->{$colcount} eq 'cpimlliberation') {$header->{$colcount} = 'cpi-m-ll'}
	elsif ($header->{$colcount} eq 'bharatkalyanparty') {$header->{$colcount} = 'bkp'}
	elsif ($header->{$colcount} eq 'lokektaparty') {$header->{$colcount} = 'lep'}	
	elsif ($header->{$colcount} eq 'shekharsamajwadijanatapartychandra') {$header->{$colcount} = 'sjp-cs'}
	elsif ($header->{$colcount} eq 'mahamuktidal') {$header->{$colcount} = 'mmd'}
	elsif ($header->{$colcount} eq 'mahakrantidal') {$header->{$colcount} = 'mkd'}	
	elsif ($header->{$colcount} eq 'rashtriyavikasmanchparty') {$header->{$colcount} = 'rvmp'}
	elsif ($header->{$colcount} eq 'gandhiektaparty') {$header->{$colcount} = 'gep'}
	elsif ($header->{$colcount} eq 'rashtriyasamajpaksha') {$header->{$colcount} = 'rsp'}	
	elsif ($header->{$colcount} eq 'communistpartyofindiamarxist-leninistliberation') {$header->{$colcount} = 'cpi-m-ll'}
	elsif ($header->{$colcount} eq 'bhartisamudayaparty') {$header->{$colcount} = 'bsap'}
	elsif ($header->{$colcount} eq 'nirmalindiaparty') {$header->{$colcount} = 'nip'}	
	elsif ($header->{$colcount} eq 'manavkalyanmanch') {$header->{$colcount} = 'mkm'}
	elsif ($header->{$colcount} eq 'navjankrantiparty') {$header->{$colcount} = 'nkp'}
	elsif ($header->{$colcount} eq 'communistpartyofindiamatrix') {$header->{$colcount} = 'cpi-m'}	
	elsif ($header->{$colcount} eq 'nationalistcondressparty') {$header->{$colcount} = 'ncp'}
	elsif ($header->{$colcount} eq 'samajwadijanataparty') {$header->{$colcount} = 'sjp'}	
	elsif ($header->{$colcount} eq 'nirbalindianshoshithamaraaam') {$header->{$colcount} = 'nishad'}
	elsif ($header->{$colcount} eq 'rashtriyasamajwadijankrantiparty') {$header->{$colcount} = 'rsjp'}
	elsif ($header->{$colcount} eq 'adarshwaadicongressparty') {$header->{$colcount} = 'acp'}	
	elsif ($header->{$colcount} eq 'bahujansamajparti') {$header->{$colcount} = 'bsp'}
	elsif ($header->{$colcount} eq 'ofindiamarxistcommunistparty') {$header->{$colcount} = 'cpi-m'}
	elsif ($header->{$colcount} eq 'samajwadiparti') {$header->{$colcount} = 'sp'}	
	elsif ($header->{$colcount} eq 'apnadalsonelal') {$header->{$colcount} = 'ad-sl'}
	elsif ($header->{$colcount} eq 'communistpartyofindiamarxistleninistliberation') {$header->{$colcount} = 'cpi-m-ll'}
	elsif ($header->{$colcount} eq 'bahujansamajpart') {$header->{$colcount} = 'bsp'}	
	elsif ($header->{$colcount} eq 'samajwadparty') {$header->{$colcount} = 'sp'}
	elsif ($header->{$colcount} eq 'bharatiyjanatapart') {$header->{$colcount} = 'bjp'}
	elsif ($header->{$colcount} eq 'shoshitsandeshparty') {$header->{$colcount} = 'ssp'}	
	elsif ($header->{$colcount} eq 'shivsen') {$header->{$colcount} = 'ss'}
	elsif ($header->{$colcount} eq 'pragatisheemanasamajpart') {$header->{$colcount} = 'pssp'}
	elsif ($header->{$colcount} eq 'nationalapnadal') {$header->{$colcount} = 'nad'}	
	elsif ($header->{$colcount} eq 'vikaspart') {$header->{$colcount} = 'vp'}
	elsif ($header->{$colcount} eq 'indiannationaljansatta') {$header->{$colcount} = 'injs'}
	elsif ($header->{$colcount} eq 'ripublicanpartyofindi') {$header->{$colcount} = 'rpi'}	
	elsif ($header->{$colcount} eq 'communistpartyofindiamarxist-leninistliberation') {$header->{$colcount} = 'cpi-m-ll'}
	elsif ($header->{$colcount} eq 'utterpradeshrepublicanparty') {$header->{$colcount} = 'urp'}
	elsif ($header->{$colcount} eq 'bharatiyarepublicanpartyinsan') {$header->{$colcount} = 'brpi'}	
	elsif ($header->{$colcount} eq 'communistpartyofindimarxist-leninist') {$header->{$colcount} = 'cpi-m-l'}	
	elsif ($header->{$colcount} eq 'allindiapeoplesfrontradical') {$header->{$colcount} = 'aipf-r'}
	
	$header->{$colcount} =~ s/\-+$//gs;
	$header->{$colcount} =~ s/^\-+//gs;		
	if (defined($thisacparty{$header->{$colcount}}) && $header->{$colcount} ne 'ind') {$header->{$colcount}='ind';} # IF A PARTY OCCURS TWICE MAKE THE SECOND CANDIDATE AN INDEPENDENT
	$thisacparty{$header->{$colcount}}=1;
	if ($header->{$colcount} eq 'ind') {$header->{$colcount}.=$indcount;$indcount++} 
	$header->{$colcount}="votes_".$header->{$colcount}."_17";
    }

    foreach my $colcount (@discard) {undef($header->{$colcount})}
    
    #
    # Manual adjustments in headers where necessary (hence all the print output...)
    #
   
    if ($ac==24) {
	$header->{13} = 'votes_bsp_17';
	$header->{16} = 'votes_sp_17';
	$header->{19} = 'votes_rld_17';
	$header->{22} = 'votes_bjp_17';	
	$header->{25} = 'votes_pp_17';
	$header->{28} = 'votes_asp_17';
	$header->{31} = 'votes_md_17';
	$header->{34} = 'votes_ind1_17';	
	$header->{37} = 'votes_ind2_17';
	$header->{40} = 'votes_ind3_17';
	$header->{43} = 'votes_ind4_17';
    } elsif ($ac==25) {
	$header->{12} = 'votes_sp_17';
	$header->{14} = 'votes_rld_17';
	$header->{16} = 'votes_bsp_17';
	$header->{18} = 'votes_inc_17';	
	$header->{20} = 'votes_bjp_17';
	$header->{22} = 'votes_nlp_17';
	$header->{24} = 'votes_aimp_17';
	$header->{26} = 'votes_pp_17';	
	$header->{28} = 'votes_ss_17';
	$header->{30} = 'votes_rcjp_17';
	$header->{32} = 'votes_ind1_17';
	$header->{34} = 'votes_ind2_17';
	$header->{36} = 'votes_ind3_17';
	$header->{38} = 'votes_ind4_17';
	$header->{39} = 'votes_turnout_17';
	$header->{40} = 'votes_nota_17';		
    } elsif ($ac==29) {
	$header->{13} = 'votes_bsp_17';
	$header->{16} = 'votes_rld_17';
	$header->{19} = 'votes_sp_17';
	$header->{22} = 'votes_bjp_17';	
	$header->{25} = 'votes_aimim_17';
	$header->{28} = 'votes_bbpp_17';
	$header->{31} = 'votes_pp_17';
	$header->{34} = 'votes_jsd_17';	
	$header->{37} = 'votes_bss_17';
	$header->{40} = 'votes_ind1_17';
	$header->{43} = 'votes_ind2_17';
	$header->{46} = 'votes_ind3_17';
	$header->{49} = 'votes_ind4_17';
	$header->{51} = 'votes_ind5_17';
     } elsif ($ac==31) {
        undef($header);
	$header->{1} = 'booth_id_17';
	$header->{12} = 'turnout_17';
	$header->{11} = 'nota_17';
	$header->{2} = 'votes_bjp_17';	
	$header->{3} = 'votes_rld_17';
	$header->{4} = 'votes_inc_17';
	$header->{5} = 'votes_bsp_17';
	$header->{6} = 'votes_md_17';	
	$header->{7} = 'votes_ind1_17';
	$header->{8} = 'votes_ind2_17';
    } elsif ($ac==32) {
        undef($header);
	$header->{1} = 'booth_id_17';
	$header->{16} = 'turnout_17';
	$header->{15} = 'nota_17';
	$header->{2} = 'votes_bsp_17';	
	$header->{3} = 'votes_rld_17';
	$header->{4} = 'votes_bjp_17';
	$header->{5} = 'votes_sp_17';
	$header->{6} = 'votes_ksjp_17';	
	$header->{7} = 'votes_ssp_17';
	$header->{8} = 'votes_ind1_17';
	$header->{9} = 'votes_ind2_17';
	$header->{10} = 'votes_ind3_17';
	$header->{11} = 'votes_ind4_17';
	$header->{12} = 'votes_ind5_17';
    } elsif ($ac==33) {
        undef($header);
	$header->{1} = 'booth_id_17';
	$header->{14} = 'turnout_17';
	$header->{13} = 'nota_17';
	$header->{2} = 'votes_bjp_17';	
	$header->{3} = 'votes_sp_17';
	$header->{4} = 'votes_rld_17';
	$header->{5} = 'votes_bsp_17';
	$header->{6} = 'votes_aimim_17';	
	$header->{7} = 'votes_jsd_17';
	$header->{8} = 'votes_ind1_17';
	$header->{9} = 'votes_ind2_17';	
	$header->{10} = 'votes_ind3_17';	
    } elsif ($ac==42) {
	$header->{11} = 'votes_sp_17';
	$header->{14} = 'votes_bsp_17';
	$header->{17} = 'votes_rld_17';
	$header->{20} = 'votes_bjp_17';
	$header->{23} = 'votes_adp_17';	
	$header->{26} = 'votes_aimim_17';
	$header->{29} = 'votes_rjsp_17';
	$header->{32} = 'votes_rpi-a_17';
	$header->{35} = 'votes_rlp_17';	
	$header->{38} = 'votes_ind1_17';
    } elsif ($ac==51) {
	$header->{13} = 'votes_bjp_17';
	$header->{16} = 'votes_bsp_17';
	$header->{19} = 'votes_sp_17';
	$header->{22} = 'votes_rld_17';	
	$header->{25} = 'votes_iemc_17';
	$header->{28} = 'votes_spi_17';
	$header->{31} = 'votes_ind1_17';
	$header->{34} = 'votes_ind2_17';	
    } elsif ($ac==57) {
	$header->{13} = 'votes_bjp_17';
	$header->{16} = 'votes_sp_17';
	$header->{19} = 'votes_bsp_17';
	$header->{22} = 'votes_rld_17';	
	$header->{25} = 'votes_rpd_17';
	$header->{28} = 'votes_rlp_17';
	$header->{31} = 'votes_ind1_17';
	$header->{34} = 'votes_ind2_17';	
	$header->{37} = 'votes_ind3_17';
    } elsif ($ac==58) {
	$header->{13} = 'votes_bsp_17';
	$header->{16} = 'votes_sp_17';
	$header->{19} = 'votes_rld_17';
	$header->{22} = 'votes_bjp_17';	
	$header->{25} = 'votes_sjp_17';
	$header->{28} = 'votes_sbp_17';
	$header->{31} = 'votes_pp_17';
	$header->{34} = 'votes_rps_17';	
	$header->{37} = 'votes_nlp_17';
	$header->{40} = 'votes_ss_17';
	$header->{43} = 'votes_ind1_17';
    } elsif ($ac==59) { 
	$header->{13} = 'votes_rld_17';
	$header->{16} = 'votes_inc_17';
	$header->{19} = 'votes_bjp_17';
	$header->{22} = 'votes_bsp_17';	
	$header->{25} = 'votes_sbp_17';
	$header->{28} = 'votes_sjrp_17';
	$header->{31} = 'votes_bmp_17';
	$header->{34} = 'votes_ind1_17';	
	$header->{37} = 'votes_ind2_17';
    } elsif ($ac==62) { 
	$header->{13} = 'votes_bjp_17';
	$header->{16} = 'votes_rld_17';
	$header->{19} = 'votes_bsp_17';
	$header->{22} = 'votes_inc_17';	
	$header->{25} = 'votes_rkvp_17';
	$header->{28} = 'votes_rps_17';
	$header->{31} = 'votes_hcp_17';
	$header->{34} = 'votes_ss_17';	
	$header->{37} = 'votes_ind1_17';
	$header->{40} = 'votes_ind2_17';
	$header->{43} = 'votes_ind3_17';	
	$header->{46} = 'votes_ind4_17';
	$header->{49} = 'votes_ind5_17';
	$header->{52} = 'votes_ind6_17';	
    } elsif ($ac==64) { 
	$header->{13} = 'votes_rld_17';
	$header->{16} = 'votes_bjp_17';
	$header->{19} = 'votes_bsp_17';
	$header->{22} = 'votes_sp_17';	
	$header->{25} = 'votes_rjs_17';
	$header->{28} = 'votes_sjp_17';
	$header->{31} = 'votes_vp_17';
    } elsif ($ac==65) { 
	$header->{13} = 'votes_bsp_17';
	$header->{16} = 'votes_bjp_17';
	$header->{19} = 'votes_sp_17';
	$header->{22} = 'votes_rld_17';	
	$header->{25} = 'votes_rkmp_17';
	$header->{28} = 'votes_rjsp_17';
	$header->{31} = 'votes_ind1_17';
    } elsif ($ac==66) { 
	$header->{13} = 'votes_inc_17';
	$header->{16} = 'votes_cpi-m_17';
	$header->{19} = 'votes_rld_17';
	$header->{22} = 'votes_bsp_17';	
	$header->{25} = 'votes_bjp_17';
	$header->{28} = 'votes_rp_17';
	$header->{31} = 'votes_sdu_17';
	$header->{34} = 'votes_rkp_17';	
	$header->{37} = 'votes_rkmp_17';
	$header->{40} = 'votes_ss_17';
	$header->{43} = 'votes_ind1_17';	
	$header->{46} = 'votes_ind2_17';	
	$header->{49} = 'votes_ind3_17';	
    } elsif ($ac==69) {
	$header->{13} = 'votes_bjp_17';
	$header->{16} = 'votes_inc_17';
	$header->{19} = 'votes_bsp_17';
	$header->{22} = 'votes_rld_17';	
	$header->{25} = 'votes_rkmp_17';
	$header->{28} = 'votes_jap_17';
	$header->{31} = 'votes_ssp_17';
	$header->{34} = 'votes_rjp_17';	
	$header->{37} = 'votes_rps_17';
	$header->{40} = 'votes_ind1_17';
	$header->{43} = 'votes_ind2_17';	
	$header->{46} = 'votes_ind3_17';
	$header->{49} = 'votes_ind4_17';	
	$header->{51} = 'votes_ind5_17';
    } elsif ($ac==70) {
	$header->{13} = 'votes_bsp_17';
	$header->{16} = 'votes_inc_17';
	$header->{19} = 'votes_rld_17';
	$header->{22} = 'votes_bjp_17';	
	$header->{25} = 'votes_rps_17';
	$header->{28} = 'votes_rjp_17';
	$header->{31} = 'votes_rkmp_17';
	$header->{34} = 'votes_ind1_17';	
    } elsif ($ac==71) {
	$header->{13} = 'votes_bjp_17';
	$header->{16} = 'votes_rld_17';
	$header->{19} = 'votes_sp_17';
	$header->{22} = 'votes_bsp_17';	
	$header->{25} = 'votes_bss_17';
	$header->{28} = 'votes_sjrp_17';
	$header->{31} = 'votes_sjp_17';
	$header->{34} = 'votes_vsip_17';	
	$header->{37} = 'votes_bmp_17';
	$header->{40} = 'votes_rmgp_17';
    } elsif ($ac==74) {
	$header->{13} = 'votes_rld_17';
	$header->{16} = 'votes_bjp_17';
	$header->{19} = 'votes_sp_17';
	$header->{22} = 'votes_bsp_17';	
	$header->{25} = 'votes_jam_17';
	$header->{28} = 'votes_mhp_17';
	$header->{31} = 'votes_srp_17';
	$header->{34} = 'votes_ld_17';	
	$header->{37} = 'votes_ind1_17';
	$header->{40} = 'votes_ind2_17';
	$header->{43} = 'votes_ind3_17';
	$header->{46} = 'votes_ind4_17';
	$header->{49} = 'votes_ind5_17';
	$header->{52} = 'votes_ind6_17';
    } elsif ($ac==75) { 
	$header->{13} = 'votes_bjp_17';
	$header->{16} = 'votes_bsp_17';
	$header->{19} = 'votes_inc_17';
	$header->{22} = 'votes_sp_17';	
	$header->{25} = 'votes_abhm_17';
	$header->{28} = 'votes_aimim_17';
	$header->{31} = 'votes_sjp-c_17';
	$header->{34} = 'votes_bss_17';	
	$header->{37} = 'votes_sskp_17';
	$header->{40} = 'votes_ind1_17';
	$header->{43} = 'votes_ind2_17';	
	$header->{46} = 'votes_ind3_17';
	$header->{49} = 'votes_ind4_17';	
    } elsif ($ac==95) { 
	$header->{13} = 'votes_rld_17';
	$header->{16} = 'votes_bsp_17';
	$header->{19} = 'votes_sp_17';
	$header->{22} = 'votes_bjp_17';	
	$header->{25} = 'votes_bmp_17';
	$header->{28} = 'votes_asp_17';
	$header->{31} = 'votes_ind1_17';
	$header->{34} = 'votes_ind2_17';	
	$header->{37} = 'votes_ind3_17';
	$header->{40} = 'votes_ind4_17';
	$header->{43} = 'votes_ind5_17';	
    } elsif ($ac==100) { 
	$header->{13} = 'votes_bsp_17';
	$header->{16} = 'votes_bjp_17';
	$header->{19} = 'votes_sp_17';
	$header->{22} = 'votes_rps_17';	
	$header->{25} = 'votes_md_17';
	$header->{28} = 'votes_ind1_17';
	$header->{31} = 'votes_ind2_17';
	$header->{34} = 'votes_ind3_17';	
	$header->{37} = 'votes_ind4_17';
	$header->{40} = 'votes_ind5_17';
    } elsif ($ac==101) { 
	$header->{13} = 'votes_bsp_17';
	$header->{16} = 'votes_bjp_17';
	$header->{19} = 'votes_sp_17';
	$header->{22} = 'votes_cpi-m_17';	
	$header->{25} = 'votes_mhp_17';
	$header->{28} = 'votes_ss_17';
	$header->{31} = 'votes_jap_17';
	$header->{34} = 'votes_md_17';	
	$header->{37} = 'votes_ind1_17';
	$header->{40} = 'votes_ind2_17';
    } elsif ($ac==102) { 
	$header->{13} = 'votes_sp_17';
	$header->{16} = 'votes_bsp_17';
	$header->{19} = 'votes_bjp_17';
	$header->{22} = 'votes_mhp_17';	
	$header->{25} = 'votes_uprp_17';
	$header->{28} = 'votes_bscp_17';
	$header->{31} = 'votes_md_17';
	$header->{34} = 'votes_ind1_17';	
	$header->{37} = 'votes_ind2_17';
	$header->{40} = 'votes_ind3_17';
    	$header->{43} = 'votes_ind4_17';
	$header->{46} = 'votes_ind5_17';    	
    } elsif ($ac==103) { 
	$header->{13} = 'votes_bsp_17';
	$header->{16} = 'votes_sp_17';
	$header->{19} = 'votes_bjp_17';
	$header->{22} = 'votes_md_17';	
	$header->{25} = 'votes_ind1_17';
	$header->{28} = 'votes_ind2_17';
	$header->{31} = 'votes_ind3_17';
	$header->{34} = 'votes_ind4_17';	
	$header->{37} = 'votes_ind5_17';
	$header->{40} = 'votes_ind6_17';
	$header->{43} = 'votes_ind7_17';	
	$header->{46} = 'votes_ind8_17';
	$header->{49} = 'votes_ind9_17';
	$header->{52} = 'votes_ind10_17';	
    } elsif ($ac==104) {
	$header->{13} = 'votes_bsp_17';
	$header->{16} = 'votes_sp_17';
	$header->{19} = 'votes_cpi-m_17';
	$header->{22} = 'votes_bjp_17';	
	$header->{25} = 'votes_ld_17';
	$header->{28} = 'votes_jap_17';
	$header->{31} = 'votes_vpi_17';
	$header->{34} = 'votes_ind1_17';	
	$header->{37} = 'votes_ind2_17';
	$header->{40} = 'votes_ind3_17';
	$header->{43} = 'votes_ind4_17';	
	$header->{46} = 'votes_ind5_17';	
	$header->{49} = 'votes_ind6_17';
    } elsif ($ac==105) { 
	$header->{13} = 'votes_sp_17';
	$header->{16} = 'votes_bjp_17';
	$header->{19} = 'votes_bsp_17';
	$header->{22} = 'votes_jam_17';	
	$header->{25} = 'votes_ld_17';
	$header->{28} = 'votes_vpi_17';
	$header->{31} = 'votes_bss_17';
	$header->{34} = 'votes_ind1_17';	
	$header->{37} = 'votes_ind2_17';
	$header->{40} = 'votes_ind3_17';
    } elsif ($ac==106) { 
	$header->{13} = 'votes_bsp_17';
	$header->{16} = 'votes_sp_17';
	$header->{19} = 'votes_bjp_17';
	$header->{22} = 'votes_rkp_17';	
	$header->{25} = 'votes_ind1_17';
	$header->{28} = 'votes_ind2_17';
	$header->{31} = 'votes_ind3_17';
	$header->{34} = 'votes_ind4_17';	
	$header->{37} = 'votes_ind5_17';
    } elsif ($ac==111) {
	undef($header);
	$header->{1} = 'booth_id_17';
	$header->{2} = 'votes_bjp_17';	
	$header->{3} = 'votes_bsp_17';
	$header->{4} = 'votes_sp_17';
	$header->{5} = 'votes_bss_17';
	$header->{6} = 'votes_ssd_17';	
	$header->{7} = 'votes_aifb_17';
	$header->{8} = 'votes_ind1_17';
	$header->{9} = 'votes_ind2_17';
	$header->{10} = 'votes_ind3_17';
	$header->{16} = 'nota_17';
	$header->{17} = 'turnout_17';	
    } elsif ($ac==118) {
	$header->{13} = 'votes_sp_17';
	$header->{16} = 'votes_bjp_17';
	$header->{19} = 'votes_bsp_17';
	$header->{22} = 'votes_rld_17';	
	$header->{25} = 'votes_jam_17';
	$header->{28} = 'votes_md_17';
	$header->{31} = 'votes_jsep_17';
	$header->{34} = 'votes_bss_17';	
	$header->{37} = 'votes_rkmp_17';
	$header->{40} = 'votes_ind1_17';
	$header->{43} = 'votes_ind2_17';	
	$header->{46} = 'votes_ind3_17';
	$header->{49} = 'votes_ind4_17';
	$header->{52} = 'votes_ind5_17';
    } elsif ($ac==120) { 
	$header->{13} = 'votes_rld_17';
	$header->{16} = 'votes_bjp_17';
	$header->{19} = 'votes_rld_17';
	$header->{22} = 'votes_bsp_17';	
	$header->{25} = 'votes_jsep_17';
	$header->{28} = 'votes_ssbp_17';
	$header->{31} = 'votes_bss_17';
	$header->{34} = 'votes_iemc_17';	
	$header->{37} = 'votes_ind1_17';
	$header->{40} = 'votes_ind2_17';
	$header->{43} = 'votes_ind3_17';	
	$header->{46} = 'votes_ind4_17';	
     } elsif ($ac==121) { 
	$header->{13} = 'votes_rld_17';
	$header->{16} = 'votes_bjp_17';
	$header->{19} = 'votes_sp_17';
	$header->{22} = 'votes_bsp_17';	
	$header->{25} = 'votes_sklp_17';
	$header->{28} = 'votes_pp_17';
	$header->{31} = 'votes_bss_17';
	$header->{34} = 'votes_iemc_17';	
	$header->{37} = 'votes_ind1_17';
	$header->{40} = 'votes_ind2_17';
	$header->{43} = 'votes_ind3_17';	
	$header->{46} = 'votes_ind4_17';	
    } elsif ($ac==122) { 
	$header->{13} = 'votes_rld_17';
	$header->{16} = 'votes_bsp_17';
	$header->{19} = 'votes_bjp_17';
	$header->{22} = 'votes_sp_17';	
	$header->{25} = 'votes_jsp_17';
	$header->{28} = 'votes_pp_17';
	$header->{31} = 'votes_ld_17';
	$header->{34} = 'votes_ind1_17';	
    } elsif ($ac==123) { 
	$header->{13} = 'votes_bjp_17';
	$header->{16} = 'votes_sp_17';
	$header->{19} = 'votes_bsp_17';
	$header->{22} = 'votes_rld_17';	
	$header->{25} = 'votes_iemc_17';
	$header->{28} = 'votes_lsp_17';
	$header->{31} = 'votes_pps_17';
	$header->{34} = 'votes_bip_17';	
	$header->{37} = 'votes_pp_17';
	$header->{40} = 'votes_ind1_17';
    } elsif ($ac==124) {
	$header->{13} = 'votes_bsp_17';
	$header->{16} = 'votes_bjp_17';
	$header->{19} = 'votes_rld_17';
	$header->{22} = 'votes_cpi_17';	
	$header->{25} = 'votes_inc_17';
	$header->{28} = 'votes_pp_17';
	$header->{31} = 'votes_jep_17';
	$header->{34} = 'votes_aifb_17';	
	$header->{37} = 'votes_ind1_17';
	$header->{40} = 'votes_ind2_17';
	$header->{43} = 'votes_ind3_17';	
	$header->{46} = 'votes_ind4_17';	
    } elsif ($ac==125) { 
	$header->{13} = 'votes_rld_17';
	$header->{16} = 'votes_inc_17';
	$header->{19} = 'votes_bsp_17';
	$header->{22} = 'votes_bjp_17';	
	$header->{25} = 'votes_plm_17';
	$header->{28} = 'votes_jsep_17';
	$header->{31} = 'votes_iemc_17';
	$header->{34} = 'votes_pp_17';	
	$header->{37} = 'votes_ss_17';
	$header->{40} = 'votes_bmp_17';
	$header->{43} = 'votes_ind1_17';	
    } elsif ($ac==145) { 
	$header->{13} = 'votes_sp_17';
	$header->{16} = 'votes_bsp_17';
	$header->{19} = 'votes_rld_17';
	$header->{22} = 'votes_bjp_17';	
	$header->{25} = 'votes_bss_17';
	$header->{28} = 'votes_uprp_17';
	$header->{31} = 'votes_ld_17';
	$header->{34} = 'votes_jhsp_17';	
	$header->{37} = 'votes_rpi-a_17';
	$header->{40} = 'votes_cpi-mll_17';
	$header->{43} = 'votes_ind1_17';	
	$header->{46} = 'votes_ind2_17';
	$header->{49} = 'votes_ind3_17';	
	$header->{52} = 'votes_ind4_17';
	$header->{55} = 'votes_ind5_17';	
    } elsif ($ac==146) { 
	$header->{13} = 'votes_bsp_17';
	$header->{16} = 'votes_bjp_17';
	$header->{19} = 'votes_sp_17';
	$header->{22} = 'votes_rld_17';	
	$header->{25} = 'votes_vsip_17';
	$header->{28} = 'votes_uprp_17';
	$header->{31} = 'votes_aipjsp_17';
	$header->{34} = 'votes_ld_17';	
	$header->{37} = 'votes_sdu_17';
	$header->{40} = 'votes_bss_17';
	$header->{43} = 'votes_ind1_17';	
	$header->{46} = 'votes_ind2_17';
	$header->{49} = 'votes_ind3_17';
	$header->{52} = 'votes_ind4_17';	
	$header->{55} = 'votes_ind5_17';
    } elsif ($ac==147) {
	$header->{13} = 'votes_sp_17';
	$header->{16} = 'votes_rld_17';
	$header->{19} = 'votes_bsp_17';
	$header->{22} = 'votes_bjp_17';	
	$header->{25} = 'votes_cpi-mll_17';
	$header->{28} = 'votes_ssp_17';
	$header->{31} = 'votes_bss_17';
	$header->{34} = 'votes_pp_17';	
	$header->{37} = 'votes_ind1_17';
    } elsif ($ac==149) { 
	$header->{13} = 'votes_sp_17';
	$header->{16} = 'votes_bsp_17';
	$header->{19} = 'votes_bjp_17';
	$header->{22} = 'votes_rlp_17';	
	$header->{25} = 'votes_aipjsp_17';
	$header->{28} = 'votes_bsrd_17';
	$header->{31} = 'votes_ind1_17';
	$header->{34} = 'votes_ind2_17';	
	$header->{37} = 'votes_ind3_17';
	$header->{40} = 'votes_ind4_17';
    } elsif ($ac==150) { 
	$header->{13} = 'votes_bsp_17';
	$header->{16} = 'votes_sp_17';
	$header->{19} = 'votes_bjp_17';
	$header->{22} = 'votes_rvp_17';	
	$header->{25} = 'votes_spi_17';
	$header->{28} = 'votes_sdu_17';
	$header->{31} = 'votes_ld_17';
	$header->{34} = 'votes_jhsp_17';	
	$header->{37} = 'votes_spi_17';
	$header->{40} = 'votes_ind1_17';
	$header->{43} = 'votes_ind2_17';	
    } elsif ($ac==151) { 
	$header->{13} = 'votes_bjp_17';
	$header->{16} = 'votes_sp_17';
	$header->{19} = 'votes_bsp_17';
	$header->{22} = 'votes_rld_17';	
	$header->{25} = 'votes_bss_17';
	$header->{28} = 'votes_ind_17';
    } elsif ($ac==153) { 
	$header->{13} = 'votes_bsp_17';
	$header->{16} = 'votes_bjp_17';
	$header->{19} = 'votes_sp_17';
	$header->{22} = 'votes_rld_17';	
	$header->{25} = 'votes_bss_17';
	$header->{28} = 'votes_ind1_17';
	$header->{31} = 'votes_ind2_17';
	$header->{34} = 'votes_ind3_17';	
    } elsif ($ac==155) { 
	$header->{13} = 'votes_bsp_17';
	$header->{16} = 'votes_bjp_17';
	$header->{19} = 'votes_rld_17';
	$header->{22} = 'votes_sp_17';	
	$header->{25} = 'votes_bss_17';
	$header->{28} = 'votes_rsvp_17';
	$header->{31} = 'votes_ld_17';
	$header->{34} = 'votes_jam_17';	
	$header->{37} = 'votes_bmp_17';
	$header->{40} = 'votes_bmap_17';
	$header->{43} = 'votes_mkp_17';	
	$header->{46} = 'votes_ind1_17';
	$header->{49} = 'votes_ind2_17';
	$header->{52} = 'votes_ind3_17';
    } elsif ($ac==159) { 
	$header->{13} = 'votes_bsp_17';
	$header->{16} = 'votes_rld_17';
	$header->{19} = 'votes_bjp_17';
	$header->{22} = 'votes_sp_17';	
	$header->{25} = 'votes_aimim_17';
	$header->{28} = 'votes_bkp_17';
	$header->{31} = 'votes_pp_17';
	$header->{34} = 'votes_bmp_17';	
	$header->{37} = 'votes_jam_17';
	$header->{40} = 'votes_bss_17';
	$header->{43} = 'votes_ind1_17';	
	$header->{46} = 'votes_ind2_17';
	$header->{49} = 'votes_ind3_17';	
	$header->{52} = 'votes_ind4_17';
	$header->{55} = 'votes_ind5_17';	
    } elsif ($ac==162) {
	undef($header);
	$header->{1} = 'booth_id_17';
	$header->{2} = 'votes_bsp_17';	
	$header->{3} = 'votes_bjp_17';
	$header->{4} = 'votes_sp_17';
	$header->{5} = 'votes_rld_17';
	$header->{6} = 'votes_bss_17';	
	$header->{7} = 'votes_pp_17';
	$header->{8} = 'votes_msp_17';
	$header->{9} = 'votes_bsep_17';
	$header->{10} = 'votes_hkd_17';
	$header->{11} = 'votes_nishad_17';
	$header->{12} = 'votes_ind1_17';
	$header->{13} = 'votes_ind2_17';
	$header->{14} = 'votes_ind3_17';
	$header->{15} = 'votes_ind4_17';
	$header->{16} = 'votes_ind5_17';	
	$header->{19} = 'nota_17';
	$header->{20} = 'turnout_17';	
    } elsif ($ac==163) { 
	undef($header);
	$header->{1} = 'booth_id_17';
	$header->{2} = 'votes_rld_17';	
	$header->{3} = 'votes_bjp_17';
	$header->{4} = 'votes_bsp_17';
	$header->{5} = 'votes_sp_17';
	$header->{6} = 'votes_jap_17';	
	$header->{7} = 'votes_ind1_17';
	$header->{8} = 'votes_ind2_17';
	$header->{9} = 'votes_ind3_17';
	$header->{12} = 'nota_17';
	$header->{13} = 'turnout_17';	
    } elsif ($ac==164) {
	undef($header);
	$header->{1} = 'booth_id_17';
	$header->{2} = 'votes_bjp_17';	
	$header->{3} = 'votes_inc_17';
	$header->{4} = 'votes_bsp_17';
	$header->{5} = 'votes_rld_17';
	$header->{6} = 'votes_jap_17';	
	$header->{7} = 'votes_bmp_17';
	$header->{8} = 'votes_ind1_17';
	$header->{9} = 'votes_ind2_17';
	$header->{12} = 'nota_17';
	$header->{13} = 'turnout_17';	
    } elsif ($ac==165) {
	undef($header);
	$header->{1} = 'booth_id_17';
	$header->{2} = 'votes_bjp_17';	
	$header->{3} = 'votes_bsp_17';
	$header->{4} = 'votes_sp_17';
	$header->{5} = 'votes_rvp_17';
	$header->{6} = 'votes_bsep_17';	
	$header->{7} = 'votes_iuml_17';
	$header->{8} = 'votes_ss_17';
	$header->{9} = 'votes_bss_17';
	$header->{10} = 'votes_ind1_17';
	$header->{11} = 'votes_ind2_17';
	$header->{12} = 'votes_ind3_17';
	$header->{13} = 'votes_ind4_17';
	$header->{14} = 'votes_ind5_17';
	$header->{17} = 'nota_17';
	$header->{18} = 'turnout_17';	
    } elsif ($ac==166) { 
	undef($header);
	$header->{1} = 'booth_id_17';
	$header->{2} = 'votes_inc_17';	
	$header->{3} = 'votes_rld_17';
	$header->{4} = 'votes_bsp_17';
	$header->{5} = 'votes_bjp_17';
	$header->{6} = 'votes_bsep_17';	
	$header->{7} = 'votes_ld_17';
	$header->{8} = 'votes_bmp_17';
	$header->{9} = 'votes_rsp_17';
	$header->{10} = 'votes_rvp_17';
	$header->{11} = 'votes_jam_17';
	$header->{12} = 'votes_spi_17';
	$header->{13} = 'votes_ind1_17';
	$header->{18} = 'nota_17';
	$header->{19} = 'turnout_17';	
    } elsif ($ac==167) { 
	undef($header);
	$header->{1} = 'booth_id_17';
	$header->{2} = 'votes_bsp_17';	
	$header->{3} = 'votes_bjp_17';
	$header->{4} = 'votes_sp_17';
	$header->{5} = 'votes_rld_17';
	$header->{6} = 'votes_ld_17';	
	$header->{7} = 'votes_jam_17';
	$header->{8} = 'votes_rsp_17';
	$header->{9} = 'votes_bmp_17';
	$header->{10} = 'votes_ind1_17';
	$header->{13} = 'nota_17';
	$header->{14} = 'turnout_17';	
    } elsif ($ac==169) { 
	$header->{13} = 'votes_bjp_17';
	$header->{16} = 'votes_sp_17';
	$header->{19} = 'votes_cpi-m_17';
	$header->{22} = 'votes_bsp_17';	
	$header->{25} = 'votes_pdd_17';
	$header->{28} = 'votes_rsvp_17';
	$header->{31} = 'votes_bscp_17';
	$header->{34} = 'votes_mp_17';	
	$header->{37} = 'votes_ld_17';
	$header->{40} = 'votes_rjp_17';
	$header->{43} = 'votes_ind1_17';	
	$header->{43} = 'votes_ind2_17';	
    } elsif ($ac==173) { 
	$header->{10} = 'votes_inc_17';
	$header->{11} = 'votes_bjp_17';
	$header->{12} = 'votes_rld_17';
	$header->{13} = 'votes_bsp_17';	
	$header->{14} = 'votes_aifb_17';
	$header->{15} = 'votes_issp_17';
	$header->{16} = 'votes_jsp_17';
	$header->{17} = 'votes_sbp_17';	
	$header->{18} = 'votes_ukd_17';
	$header->{19} = 'votes_rsvp_17';
	$header->{20} = 'votes_jam_17';	
	$header->{21} = 'votes_pdd_17';	
	$header->{22} = 'votes_ind1_17';	
	$header->{23} = 'votes_ind2_17';	
	$header->{24} = 'votes_ind3_17';	
	$header->{25} = 'turnout_17';	
	$header->{26} = 'nota_17';	
    } elsif ($ac==176) { 
	$header->{13} = 'votes_sp_17';
	$header->{16} = 'votes_bsp_17';
	$header->{19} = 'votes_rsvp_17';
	$header->{22} = 'votes_mvkd_17';	
	$header->{25} = 'votes_nep_17';
	$header->{28} = 'votes_ind1_17';
	$header->{31} = 'votes_ind2_17';
	$header->{34} = 'votes_ind3_17';	
	$header->{37} = 'votes_ind4_17';
	$header->{40} = 'votes_ind5_17';
	$header->{43} = 'votes_ind6_17';	
	$header->{46} = 'votes_ind7_17';
	$header->{49} = 'votes_ind8_17';
    } elsif ($ac==177) { 
	$header->{13} = 'votes_bjp_17';
	$header->{16} = 'votes_rld_17';
	$header->{19} = 'votes_bsp_17';
	$header->{22} = 'votes_inc_17';	
	$header->{25} = 'votes_rjap_17';
	$header->{28} = 'votes_msp_17';
	$header->{31} = 'votes_pp_17';
	$header->{34} = 'votes_jap_17';	
	$header->{37} = 'votes_ind1_17';
	$header->{40} = 'votes_ind2_17';
	$header->{43} = 'votes_ind3_17';	
	$header->{46} = 'votes_ind4_17';
	$header->{49} = 'votes_ind5_17';
	$header->{52} = 'votes_ind6_17';	
    } elsif ($ac==180) { 
	$header->{13} = 'votes_inc_17';
	$header->{16} = 'votes_bjp_17';
	$header->{19} = 'votes_rld_17';
	$header->{22} = 'votes_bsp_17';	
	$header->{25} = 'votes_abp-d_17';
	$header->{28} = 'votes_jp_17';
	$header->{31} = 'votes_bmp_17';
	$header->{34} = 'votes_rjap_17';	
	$header->{37} = 'votes_srp_17';
	$header->{40} = 'votes_msp_17';
	$header->{43} = 'votes_ind1_17';	
	$header->{46} = 'votes_ind2_17';	
	$header->{49} = 'votes_ind3_17';	
    } elsif ($ac==181) { 
	$header->{11} = 'votes_bjp_17';
	$header->{12} = 'votes_rld_17';
	$header->{13} = 'votes_bsp_17';	
	$header->{14} = 'votes_inc_17';
	$header->{15} = 'votes_msp_17';
	$header->{16} = 'votes_jam_17';
	$header->{17} = 'votes_ind1_17';	
	$header->{18} = 'votes_ind2_17';
	$header->{19} = 'votes_ind3_17';
	$header->{20} = 'votes_ind4_17';	
	$header->{21} = 'nota_17';	
	undef($header->{22});
	$header->{23} = 'turnout_17';
    } elsif ($ac==182) { 
	$header->{13} = 'votes_inc_17';
	$header->{16} = 'votes_bsp_17';
	$header->{19} = 'votes_sp_17';
	$header->{22} = 'votes_bjp_17';	
	$header->{25} = 'votes_nld_17';
	$header->{28} = 'votes_bmp_17';
	$header->{31} = 'votes_rjap_17';
	$header->{34} = 'votes_sdu_17';	
	$header->{37} = 'votes_jap_17';
	$header->{40} = 'votes_msp_17';
	$header->{43} = 'votes_ind1_17';	
	$header->{46} = 'votes_ind2_17';	
    } elsif ($ac==188) { 
	$header->{13} = 'votes_sp_17';
	$header->{16} = 'votes_cpi_17';
	$header->{19} = 'votes_rld_17';
	$header->{22} = 'votes_bsp_17';	
	$header->{25} = 'votes_bjp_17';
	$header->{28} = 'votes_rjp_17';
	$header->{31} = 'votes_rjap_17';
	$header->{34} = 'votes_adp_17';	
	$header->{37} = 'votes_ssp_17';
	$header->{40} = 'votes_bmp_17';
	$header->{43} = 'votes_mbci_17';	
	$header->{46} = 'votes_ssap_17';
	$header->{49} = 'votes_pmsp_17';	
	$header->{52} = 'votes_ind1_17';
	$header->{55} = 'votes_ind2_17';	
	$header->{58} = 'votes_ind3_17';
    } elsif ($ac==190) { 
	$header->{13} = 'votes_rld_17';
	$header->{16} = 'votes_bjp_17';
	$header->{19} = 'votes_bsp_17';
	$header->{22} = 'votes_sp_17';	
	$header->{25} = 'votes_suci-c_17';
	$header->{28} = 'votes_bmp_17';
	$header->{31} = 'votes_psa_17';
	$header->{34} = 'votes_sssp_17';	
	$header->{37} = 'votes_mbci_17';
	$header->{40} = 'votes_ind1_17';
	$header->{43} = 'votes_ind2_17';	
	$header->{46} = 'votes_ind3_17';
	$header->{49} = 'votes_ind4_17';	
    } elsif ($ac==191) { 
	$header->{13} = 'votes_inc_17';
	$header->{16} = 'votes_bsp_17';
	$header->{19} = 'votes_bjp_17';
	$header->{22} = 'votes_rld_17';	
	$header->{25} = 'votes_mbci_17';
	$header->{28} = 'votes_mp_17';
	$header->{31} = 'votes_bmp_17';
	$header->{34} = 'votes_nishad_17';	
	$header->{37} = 'votes_ind1_17';
	$header->{40} = 'votes_ind2_17';
	$header->{43} = 'votes_ind3_17';	
    } elsif ($ac==192) { 
	$header->{8} = 'turnout_17';	
	$header->{13} = 'votes_bjp_17';
	$header->{16} = 'votes_bsp_17';
	$header->{19} = 'votes_sp_17';
	$header->{22} = 'votes_cpi_17';	
	$header->{25} = 'votes_jam_17';
	$header->{28} = 'votes_bscp_17';
	$header->{31} = 'votes_ind1_17';
	$header->{34} = 'votes_ind2_17';	
    } elsif ($ac==193) { 
	$header->{8} = 'turnout_17';	
	$header->{13} = 'votes_bsp_17';
	$header->{16} = 'votes_sp_17';
	$header->{19} = 'votes_rld_17';
	$header->{22} = 'votes_bjp_17';	
	$header->{25} = 'votes_psm_17';
	$header->{28} = 'votes_bss_17';
	$header->{31} = 'votes_ld_17';
	$header->{34} = 'votes_abhm_17';	
	$header->{37} = 'votes_jam_17';
	$header->{40} = 'votes_ind1_17';
	$header->{43} = 'votes_ind2_17';	
	$header->{46} = 'votes_ind3_17';
	$header->{49} = 'votes_ind4_17';	
	$header->{52} = 'votes_ind5_17';
	$header->{55} = 'votes_ind6_17';	
	$header->{58} = 'nota_17';
    } elsif ($ac==194) { 
	$header->{8} = 'turnout_17';	
	$header->{13} = 'votes_bsp_17';
	$header->{16} = 'votes_sp_17';
	$header->{19} = 'votes_bjp_17';
	$header->{22} = 'votes_rld_17';	
	$header->{25} = 'votes_psm_17';
	$header->{28} = 'votes_rpi_17';
	$header->{31} = 'votes_bmp_17';
	$header->{34} = 'votes_bscp_17';	
	$header->{37} = 'votes_md_17';
	$header->{40} = 'votes_ind1_17';
	$header->{43} = 'votes_ind2_17';	
	$header->{46} = 'votes_ind3_17';
	$header->{49} = 'votes_ind4_17';	
	$header->{52} = 'votes_ind5_17';
	$header->{55} = 'votes_ind6_17';	
	$header->{58} = 'votes_ind7_17';
	$header->{61} = 'votes_ind8_17';	
	$header->{64} = 'votes_ind9_17';
	$header->{67} = 'votes_ind10_17';	
	$header->{70} = 'votes_ind11_17';
	$header->{73} = 'nota_17';
    } elsif ($ac==202) {
        $header->{10} = 'votes_sp_17';
	$header->{11} = 'votes_bjp_17';
	$header->{12} = 'votes_bsp_17';
	$header->{13} = 'votes_dsp_17';	
	$header->{14} = 'votes_jap_17';
	$header->{15} = 'votes_jam_17';
	$header->{16} = 'votes_ind1_17';
	$header->{17} = 'votes_ind2_17';	
	$header->{18} = 'nota_17';
	$header->{19} = 'turnout_17';
    } elsif ($ac==203) { 
	$header->{10} = 'votes_cpi_17';
	$header->{11} = 'votes_sp_17';
	$header->{12} = 'votes_bsp_17';
	$header->{13} = 'votes_bjp_17';	
	$header->{14} = 'votes_ld_17';
	$header->{15} = 'votes_bmp_17';
	$header->{16} = 'votes_ad_17';
	$header->{17} = 'votes_jam_17';	
	$header->{18} = 'votes_ind1_17';
	$header->{19} = 'votes_ind2_17';
	$header->{20} = 'votes_ind3_17';	
	$header->{21} = 'votes_ind4_17';
	$header->{22} = 'votes_ind5_17';	
	$header->{23} = 'votes_ind6_17';
	$header->{24} = 'nota_17';	
	$header->{24} = 'turnout_17';	
    } elsif ($ac==204) { 
	$header->{10} = 'votes_bsp_17';
	$header->{11} = 'votes_sp_17';
	$header->{12} = 'votes_bjp_17';
	$header->{13} = 'votes_jam_17';	
	$header->{14} = 'votes_bmp_17';
	$header->{15} = 'votes_nishad_17';
	$header->{16} = 'votes_pp_17';
	$header->{17} = 'votes_vpi_17';	
	$header->{18} = 'votes_ld_17';
	$header->{19} = 'votes_ind1_17';
	$header->{20} = 'nota_17';	
	$header->{21} = 'turnout_17';
    } elsif ($ac==208) { 
	$header->{13} = 'votes_bsp_17';
	$header->{16} = 'votes_inc_17';
	$header->{19} = 'votes_sp_17';
	$header->{22} = 'votes_bjp_17';	
	$header->{25} = 'votes_nishad_17';
	$header->{28} = 'votes_bmp_17';
	$header->{31} = 'votes_pp_17';
	$header->{34} = 'votes_bscp_17';	
	$header->{37} = 'votes_nap_17';
	$header->{40} = 'votes_birp_17';
	$header->{43} = 'votes_ind1_17';	
	$header->{46} = 'votes_ind2_17';
	$header->{49} = 'votes_ind3_17';	
	$header->{52} = 'votes_ind4_17';
	$header->{55} = 'votes_ind5_17';	
    } elsif ($ac==219) { 
	$header->{13} = 'votes_bsp_17';
	$header->{16} = 'votes_rld_17';
	$header->{19} = 'votes_bjp_17';
	$header->{22} = 'votes_inc_17';	
	$header->{25} = 'votes_kmes_17';
	$header->{28} = 'votes_md_17';
	$header->{31} = 'votes_sjp_17';
	$header->{34} = 'votes_jap_17';	
	$header->{37} = 'votes_rjp_17';
	$header->{40} = 'votes_ssp_17';
	$header->{43} = 'votes_ind1_17';	
	$header->{46} = 'votes_ind2_17';
	$header->{49} = 'votes_ind3_17';	
    } elsif ($ac==221) { 
	$header->{12} = 'votes_bjp_17';
	$header->{15} = 'votes_sp_17';
	$header->{18} = 'votes_bsp_17';
	$header->{21} = 'votes_bjp_17';	
	$header->{24} = 'votes_rv_17';
	$header->{27} = 'votes_sjp_17';
	$header->{30} = 'votes_bscp_17';
	$header->{33} = 'votes_bmp_17';	
    } elsif ($ac==226) { 
	undef($header);
	$header->{1} = 'booth_id_17'; 
	$header->{3} = 'electors_17';
	$header->{4} = 'male_votes_17';
	$header->{5} = 'female_votes_17';
	$header->{9} = 'tendered_17';
	$header->{12} = 'votes_sp_17';
	$header->{15} = 'votes_cpi_17';
	$header->{18} = 'votes_bjp_17';
	$header->{21} = 'votes_bsp_17';	
	$header->{24} = 'votes_bmp_17';
	$header->{27} = 'votes_rkmp_17';
	$header->{30} = 'votes_jap_17';
	$header->{33} = 'votes_ind1_17';	
	$header->{36} = 'votes_ind2_17';	
	$header->{39} = 'votes_ind3_17';	
	$header->{42} = 'votes_ind4_17';	
	$header->{46} = 'nota_17';	
	$header->{47} = 'turnout_17';		
	undef($header->{48});
    } elsif ($ac==227) {
        undef($header->{52});
        $header->{52} = 'nota_17';
	$header->{13} = 'votes_cpi_17';
	$header->{16} = 'votes_bsp_17';
	$header->{19} = 'votes_inc_17';
	$header->{22} = 'votes_bjp_17';	
	$header->{25} = 'votes_sp_17';
	$header->{28} = 'votes_rsp_17';
	$header->{31} = 'votes_jap_17';
	$header->{34} = 'votes_ind1_17';	
	$header->{37} = 'votes_ind2_17';
	$header->{40} = 'votes_ind3_17';
	$header->{43} = 'votes_ind4_17';	
	$header->{46} = 'votes_ind5_17';
	$header->{49} = 'votes_ind6_17';	
    } elsif ($ac==230) { 
	$header->{13} = 'votes_bsp_17';
	$header->{16} = 'votes_rld_17';
	$header->{19} = 'votes_bjp_17';
	$header->{22} = 'votes_sp_17';	
	$header->{25} = 'votes_jap_17';
	$header->{28} = 'votes_bscp_17';
	$header->{31} = 'votes_fjp_17';
	$header->{34} = 'votes_ind1_17';	
	$header->{37} = 'votes_ind2_17';
	$header->{40} = 'votes_ind3_17';
    } elsif ($ac==236) { 
	$header->{13} = 'votes_cpi_17';
	$header->{16} = 'votes_rld_17';
	$header->{19} = 'votes_bjp_17';
	$header->{22} = 'votes_bsp_17';	
	$header->{25} = 'votes_sp_17';
	$header->{28} = 'votes_nishad_17';
	$header->{31} = 'votes_sjp_17';
	$header->{34} = 'votes_abhm_17';	
	$header->{37} = 'votes_jam_17';
	$header->{40} = 'votes_bmp_17';
	$header->{43} = 'votes_ind1_17';	
	$header->{46} = 'votes_ind2_17';
    } elsif ($ac==244) { 
	$header->{13} = 'votes_rld_17';
	$header->{16} = 'votes_bsp_17';
	$header->{19} = 'votes_inc_17';
	$header->{22} = 'votes_cpi_17';	
	$header->{25} = 'votes_bjp_17';
	$header->{28} = 'votes_ncp_17';
	$header->{31} = 'votes_bmup_17';
	$header->{34} = 'votes_ark_17';	
	$header->{37} = 'votes_pupp_17';
	$header->{40} = 'votes_swp_17';
	$header->{43} = 'votes_ld_17';	
	$header->{46} = 'votes_mwsp_17';
	$header->{49} = 'votes_brabsvp_17';	
	$header->{52} = 'votes_shs_17';
	$header->{55} = 'votes_ind1_17';	
    } elsif ($ac==247) { 
	$header->{13} = 'votes_cpi_17';
	$header->{16} = 'votes_bsp_17';
	$header->{19} = 'votes_rld_17';
	$header->{22} = 'votes_ncp_17';	
	$header->{25} = 'votes_inc_17';
	$header->{28} = 'votes_vip_17';
	$header->{31} = 'votes_bmup_17';
	$header->{34} = 'votes_adal_17';	
	$header->{37} = 'votes_logap_17';
	$header->{40} = 'votes_rjp_17';
	$header->{43} = 'votes_ind1_17';	
	$header->{46} = 'votes_ind2_17';
	$header->{49} = 'votes_ind3_17';	
	$header->{52} = 'votes_ind4_17';
    } elsif ($ac==248) { 
	$header->{13} = 'votes_bsp_17';
	$header->{16} = 'votes_rld_17';
	$header->{19} = 'votes_sp_17';
	$header->{22} = 'votes_shs_17';	
	$header->{25} = 'votes_pupp_17';
	$header->{28} = 'votes_bmup_17';
	$header->{31} = 'votes_ld_17';
	$header->{34} = 'votes_adal_17';	
	$header->{37} = 'votes_rsps_17';
	$header->{40} = 'votes_ind1_17';
	$header->{43} = 'votes_ind2_17';	
	$header->{46} = 'votes_ind3_17';
	$header->{49} = 'votes_ind4_17';	
	$header->{52} = 'votes_ind5_17';
    } elsif ($ac==250) { 
	$header->{13} = 'votes_bjp_17';
	$header->{16} = 'votes_rld_17';
	$header->{19} = 'votes_bsp_17';
	$header->{22} = 'votes_sp_17';	
	$header->{25} = 'votes_cpi_17';
	$header->{28} = 'votes_sarsamp_17';
	$header->{31} = 'votes_bks_17';
	$header->{34} = 'votes_ld_17';	
	$header->{37} = 'votes_bmup_17';
	$header->{40} = 'votes_suci_17';
	$header->{43} = 'votes_pgsp_17';	
	$header->{46} = 'votes_nishad_17';
	$header->{49} = 'votes_ind1_17';	
	$header->{52} = 'votes_ind2_17';
	$header->{55} = 'votes_ind3_17';	
	$header->{58} = 'votes_ind4_17';	
	$header->{61} = 'votes_ind5_17';
	$header->{64} = 'votes_ind6_17';	
    } elsif ($ac==251) { 
	$header->{13} = 'votes_rld_17';
	$header->{16} = 'votes_sp_17';
	$header->{19} = 'votes_cpi_17';
	$header->{22} = 'votes_bjp_17';	
	$header->{25} = 'votes_bsp_17';
	$header->{28} = 'votes_bmp_17';
	$header->{31} = 'votes_bkd_17';
	$header->{34} = 'votes_bkrp_17';	
	$header->{37} = 'votes_ld_17';
	$header->{40} = 'votes_sjp_17';
	$header->{43} = 'votes_ss_17';	
	$header->{46} = 'votes_psp_17';
	$header->{49} = 'votes_ind1_17';	
	$header->{52} = 'votes_ind2_17';
	$header->{55} = 'votes_ind3_17';	
	$header->{58} = 'votes_ind4_17';	
	$header->{59} = 'nota_17';
	undef($header->{60});
    } elsif ($ac==252) { 
	$header->{13} = 'votes_bsp_17';
	$header->{16} = 'votes_bjp_17';
	$header->{19} = 'votes_sp_17';
	$header->{22} = 'votes_bmp_17';	
	$header->{25} = 'votes_bkrp_17';
	$header->{28} = 'votes_ind1_17';
	$header->{29} = 'nota_17';
	undef($header->{30});
    } elsif ($ac==253) { 
	$header->{13} = 'votes_bsp_17';
	$header->{16} = 'votes_inc_17';
	$header->{19} = 'votes_bjp_17';
	$header->{22} = 'votes_rjp_17';	
	$header->{25} = 'votes_rbcp_17';
	$header->{28} = 'votes_bsvp_17';
	$header->{31} = 'votes_bkrp_17';
	$header->{34} = 'votes_sjrp_17';	
	$header->{37} = 'votes_bscp_17';
	$header->{40} = 'votes_bmp_17';
	$header->{43} = 'votes_rjp_17';	
	$header->{46} = 'votes_rpi-a_17';
	$header->{49} = 'votes_jkp_17';	
	$header->{52} = 'votes_rkmp_17';
	$header->{55} = 'votes_ind1_17';	
	$header->{58} = 'votes_ind2_17';	
	$header->{61} = 'votes_ind3_17';	
	$header->{64} = 'votes_ind4_17';	
	$header->{67} = 'votes_ind5_17';	
	$header->{68} = 'nota_17';
	undef($header->{69});
    } elsif ($ac==259) { 
	undef($header);
	$header->{1} = 'booth_id_17';
	$header->{2} = 'votes_bjp_17';
	$header->{3} = 'votes_sp_17';
	$header->{4} = 'votes_bsp_17';	
	$header->{5} = 'votes_rld_17';
	$header->{6} = 'votes_bmp_17';
	$header->{7} = 'votes_lgp_17';
	$header->{8} = 'votes_psp_17';	
	$header->{9} = 'votes_dsp_17';
	$header->{10} = 'votes_nishad_17';
	$header->{11} = 'votes_ind1_17';	
	$header->{12} = 'votes_ind2_17';
	$header->{13} = 'votes_ind3_17';	
	$header->{14} = 'votes_ind4_17';
	$header->{15} = 'votes_ind5_17';	
	$header->{16} = 'votes_ind6_17';	
	$header->{19} = 'nota_17';	
	$header->{20} = 'turnout_17';	
	$header->{21} = 'tendered_17';	
    } elsif ($ac==261) { 
	undef($header);
	$header->{2} = 'booth_id_17'; 
	$header->{4} = 'electors_17';
	$header->{5} = 'male_votes_17';
	$header->{6} = 'female_votes_17';
	$header->{10} = 'tendered_17';
	$header->{13} = 'votes_bsp_17';
	$header->{16} = 'votes_sp_17';                                 
	$header->{19} = 'votes_bjp_17';
	$header->{22} = 'votes_rld_17';
	$header->{25} = 'votes_nishad_17';
	$header->{28} = 'votes_psp_17';
	$header->{31} = 'votes_avp_17';
	$header->{34} = 'votes_vp_17';
	$header->{37} = 'votes_ind1_17';
	$header->{40} = 'votes_ind2_17';
	$header->{43} = 'votes_ind3_17';
	$header->{46} = 'votes_ind4_17';
	$header->{49} = 'votes_ind5_17';
	$header->{52} = 'nota_17';
	$header->{53} = 'turnout_17';
    } elsif ($ac==262) {
	undef($header);
	$header->{2} = 'booth_id_17'; 
	$header->{4} = 'electors_17';
	$header->{5} = 'male_votes_17';
	$header->{6} = 'female_votes_17';
	$header->{10} = 'tendered_17';
	$header->{13} = 'votes_inc_17';
	$header->{16} = 'votes_bsp_17';                                 
	$header->{19} = 'votes_bjp_17';
	$header->{22} = 'votes_rpi-a_17';
	$header->{25} = 'votes_sklp_17';
	$header->{28} = 'votes_rbp_17';
	$header->{31} = 'votes_bap_17';
	$header->{34} = 'votes_lgp_17';
	$header->{37} = 'votes_ss_17';
	$header->{40} = 'votes_rps_17';
	$header->{43} = 'votes_bmp_17';
	$header->{46} = 'votes_bkrp_17';
	$header->{49} = 'votes_ind1_17';
	$header->{52} = 'votes_ind2_17';
	$header->{55} = 'votes_ind3_17';
	$header->{58} = 'votes_ind4_17';
	$header->{61} = 'votes_ind5_17';
	$header->{64} = 'votes_ind6_17';
	$header->{67} = 'votes_ind7_17';
	$header->{70} = 'votes_ind8_17';
	$header->{73} = 'votes_ind9_17';
	$header->{76} = 'votes_ind10_17';
	$header->{79} = 'votes_ind11_17';
	$header->{82} = 'votes_ind12_17';
	$header->{85} = 'votes_ind13_17';
	$header->{88} = 'votes_ind14_17';
	$header->{91} = 'nota_17';
	$header->{92} = 'turnout_17';
    } elsif ($ac==263) { 
	$header->{13} = 'votes_rld_17';
	$header->{16} = 'votes_cpi_17';
	$header->{19} = 'votes_bjp_17';
	$header->{22} = 'votes_sp_17';
	$header->{25} = 'votes_bsp_17';
	$header->{28} = 'votes_pp_17';
	$header->{31} = 'votes_ayp_17';
	$header->{34} = 'votes_ss_17';
	$header->{37} = 'votes_psp_17';
	$header->{40} = 'votes_sbp_17';
	$header->{43} = 'votes_bmp_17';
	$header->{46} = 'votes_nishad_17';
	$header->{49} = 'votes_rpi_17';
	$header->{52} = 'votes_rad_17';
	$header->{55} = 'votes_psp_17';
	$header->{58} = 'votes_aimim_17';
	$header->{61} = 'votes_ind1_17';
	$header->{64} = 'votes_ind2_17';
	$header->{67} = 'votes_ind3_17';
	$header->{70} = 'votes_ind4_17';
	$header->{73} = 'votes_ind5_17';
    } elsif ($ac==272) {  
	$header->{13} = 'votes_bsp_17';
	$header->{16} = 'votes_bjp_17';
	$header->{19} = 'votes_sp_17';
    } elsif ($ac==282) { 
	$header->{13} = 'votes_bjp_17';
	$header->{16} = 'votes_bsp_17';
	$header->{19} = 'votes_sp_17';
	$header->{22} = 'votes_rpi-a_17';	
	$header->{25} = 'votes_rkp_17';
	$header->{28} = 'votes_rmgp_17';
	$header->{31} = 'votes_bmp_17';
	$header->{34} = 'votes_ind1_17';	
	$header->{37} = 'votes_ind2_17';
	$header->{40} = 'votes_ind3_17';
	$header->{43} = 'votes_ind4_17';	
	$header->{46} = 'votes_ind5_17';
    } elsif ($ac==283) { 
	$header->{13} = 'votes_bsp_17';
	$header->{16} = 'votes_cpi_17';
	$header->{19} = 'votes_rld_17';
	$header->{22} = 'votes_bjp_17';	
	$header->{25} = 'votes_inc_17';
	$header->{28} = 'votes_rkp_17';
	$header->{31} = 'votes_ind1_17';
	$header->{34} = 'votes_ind2_17';	
	$header->{37} = 'votes_ind3_17';
    } elsif ($ac==284) { 
	$header->{13} = 'votes_bjp_17';
	$header->{16} = 'votes_rld_17';
	$header->{19} = 'votes_sp_17';
	$header->{22} = 'votes_bsp_17';	
	$header->{25} = 'votes_aimim_17';
	$header->{28} = 'votes_ind1_17';
	$header->{31} = 'votes_ind2_17';
	$header->{34} = 'votes_ind3_17';	
	$header->{37} = 'votes_ind4_17';
	$header->{40} = 'votes_ind5_17';
    } elsif ($ac==286) { 
	$header->{13} = 'votes_bsp_17';
	$header->{16} = 'votes_bjp_17';
	$header->{19} = 'votes_sp_17';
	$header->{22} = 'votes_ncp_17';	
	$header->{25} = 'votes_rkmp_17';
	$header->{28} = 'votes_np_17';
	$header->{31} = 'votes_ss_17';
	$header->{34} = 'votes_bdp_17';	
	$header->{37} = 'votes_pp_17';
	$header->{40} = 'votes_ind1_17';
	$header->{43} = 'votes_ind2_17';	
	$header->{46} = 'votes_ind3_17';
    } elsif ($ac==287) { 
	$header->{13} = 'votes_inc_17';
	$header->{16} = 'votes_sp_17';
	$header->{19} = 'votes_bsp_17';
	$header->{22} = 'votes_bjp_17';	
	$header->{25} = 'votes_lsp-s_17';
	$header->{28} = 'votes_spi_17';
	$header->{31} = 'votes_ind1_17';
	$header->{34} = 'votes_ind2_17';	
	$header->{37} = 'votes_ind3_17';
    } elsif ($ac==288) { 
	$header->{13} = 'votes_bsp_17';
	$header->{16} = 'votes_bjp_17';
	$header->{19} = 'votes_rld_17';
	$header->{22} = 'votes_sp_17';	
	$header->{25} = 'votes_aimim_17';
	$header->{28} = 'votes_map_17';
	$header->{31} = 'votes_ind1_17';
    } elsif ($ac==301) { 
	$header->{13} = 'votes_bsp_17';
	$header->{16} = 'votes_bcp_17';
	$header->{19} = 'votes_inc_17';
	$header->{22} = 'votes_bjp_17';	
	$header->{25} = 'votes_sp_17';
	$header->{28} = 'votes_rld_17';
	$header->{31} = 'votes_sbp_17';
	$header->{34} = 'votes_bmp_17';	
	$header->{37} = 'votes_ind1_17';
	$header->{40} = 'votes_ind2_17';
	$header->{43} = 'votes_ind3_17';	
	$header->{46} = 'votes_ind4_17';
	$header->{49} = 'votes_ind5_17';	
	$header->{52} = 'votes_ind6_17';
	$header->{55} = 'votes_ind7_17';	
    } elsif ($ac==307) { 
	$header->{13} = 'votes_bjp_17';
	$header->{16} = 'votes_rld_17';
	$header->{19} = 'votes_sp_17';
	$header->{22} = 'votes_bsp_17';	
	$header->{25} = 'votes_rps_17';
	$header->{28} = 'votes_mbci_17';
	$header->{31} = 'votes_bmp_17';
	$header->{34} = 'votes_jap_17';	
	$header->{37} = 'votes_ind1_17';
	$header->{40} = 'votes_ind2_17';
	$header->{43} = 'votes_ind3_17';	
	$header->{46} = 'votes_ind4_17';
	$header->{49} = 'votes_ind5_17';	
	$header->{52} = 'votes_ind6_17';
    } elsif ($ac==308) { 
	$header->{13} = 'votes_inc_17';
	$header->{16} = 'votes_bjp_17';
	$header->{19} = 'votes_bsp_17';
	$header->{22} = 'votes_rld_17';	
	$header->{25} = 'votes_mbci_17';
	$header->{28} = 'votes_bmp_17';
	$header->{31} = 'votes_ind1_17';
	$header->{34} = 'votes_ind2_17';	
    } elsif ($ac==314) { 
        undef($header);
	$header->{2} = 'booth_id_17'; 
	$header->{7} = 'electors_17';
	$header->{8} = 'male_votes_17';
	$header->{9} = 'female_votes_17';
	$header->{11} = 'turnout_17';
	$header->{13} = 'tendered_17';        
	$header->{16} = 'votes_sp_17';
	$header->{19} = 'votes_bsp_17';
	$header->{22} = 'votes_bjp_17';	
	$header->{25} = 'votes_bmp_17';
	$header->{28} = 'votes_bss_17';
	$header->{31} = 'votes_ssp_17';
	$header->{34} = 'votes_ind1_17';	
	$header->{37} = 'votes_ind2_17';
    } elsif ($ac==315) { 
	$header->{13} = 'votes_bjp_17';
	$header->{16} = 'votes_rld_17';
	$header->{19} = 'votes_inc_17';
	$header->{22} = 'votes_bsp_17';	
	$header->{25} = 'votes_ss_17';
	$header->{28} = 'votes_bmp_17';
	$header->{31} = 'votes_nishad_17';
	$header->{34} = 'votes_pp_17';	
	$header->{37} = 'votes_aimim_17';
	$header->{40} = 'votes_ld_17';
	$header->{43} = 'votes_jhsp_17';	
	$header->{46} = 'votes_ind1_17';
    } elsif ($ac==316) { 
	$header->{13} = 'votes_bsp_17';
	$header->{16} = 'votes_sp_17';
	$header->{19} = 'votes_ncp_17';
	$header->{22} = 'votes_rld_17';	
	$header->{25} = 'votes_bjp_17';
	$header->{28} = 'votes_nishad_17';
	$header->{31} = 'votes_jap_17';
	$header->{34} = 'votes_aimim_17';	
	$header->{37} = 'votes_bmp_17';
	$header->{40} = 'votes_ind1_17';
    } elsif ($ac==317) { 
	$header->{13} = 'votes_bjp_17';
	$header->{16} = 'votes_bsp_17';
	$header->{19} = 'votes_sp_17';
	$header->{22} = 'votes_rld_17';	
	$header->{25} = 'votes_asp_17';
	$header->{28} = 'votes_bmp_17';
	$header->{31} = 'votes_pp_17';
	$header->{34} = 'votes_cpi-m-ll_17';	
	$header->{37} = 'votes_ind1_17';
	$header->{40} = 'votes_ind2_17';
	$header->{43} = 'votes_ind3_17';	
    } elsif ($ac==318) { 
	$header->{12} = 'votes_inc_17';
	$header->{15} = 'votes_bjp_17';
	$header->{18} = 'votes_bsp_17';
	$header->{21} = 'votes_cpi_17';	
	$header->{24} = 'votes_bkp_17';
	$header->{27} = 'votes_nishad_17';
	$header->{30} = 'votes_bmp_17';
	$header->{33} = 'votes_ind1_17';	
	$header->{36} = 'votes_ind2_17';
    } elsif ($ac==319) { 
        undef($header->{2});
       	$header->{1} = 'booth_id_17'; 
	$header->{3} = 'electors_17';
	$header->{4} = 'male_votes_17';
	$header->{5} = 'female_votes_17';
	$header->{9} = 'tendered_17';
	$header->{12} = 'votes_bsp_17';
	$header->{15} = 'votes_rld_17';
	$header->{18} = 'votes_inc_17';
	$header->{21} = 'votes_bjp_17';	
	$header->{24} = 'votes_ld_17';
	$header->{27} = 'votes_md_17';
	$header->{30} = 'votes_bmp_17';
	$header->{33} = 'votes_asp_17';	
	$header->{36} = 'votes_nishad_17';
	$header->{39} = 'votes_ind1_17';
	$header->{42} = 'votes_ind2_17';
	$header->{45} = 'votes_ind3_17';
	$header->{48} = 'votes_ind4_17';
	$header->{51} = 'votes_ind5_17';
    } elsif ($ac==320) { 
	$header->{13} = 'votes_bsp_17';
	$header->{16} = 'votes_rld_17';
	$header->{19} = 'votes_inc_17';
	$header->{22} = 'votes_bjp_17';	
	$header->{25} = 'votes_ncp_17';
	$header->{28} = 'votes_rmgp_17';
	$header->{31} = 'votes_rksp_17';
	$header->{34} = 'votes_jap_17';	
	$header->{37} = 'votes_nishad_17';
	$header->{40} = 'votes_ld_17';
	$header->{43} = 'votes_bmp_17';	
	$header->{46} = 'votes_ind1_17';
	$header->{49} = 'votes_ind2_17';	
	$header->{52} = 'votes_ind3_17';
    } elsif ($ac==321) { 
	$header->{13} = 'votes_ncp_17';
	$header->{16} = 'votes_rld_17';
	$header->{19} = 'votes_sp_17';
	$header->{22} = 'votes_bsp_17';	
	$header->{25} = 'votes_bjp_17';
	$header->{28} = 'votes_jap_17';
	$header->{31} = 'votes_bmp_17';
	$header->{34} = 'votes_rjp_17';	
	$header->{37} = 'votes_ld_17';
	$header->{40} = 'votes_sjp_17';
	$header->{43} = 'votes_bscp_17';	
	$header->{46} = 'votes_ind1_17';
	$header->{49} = 'votes_ind2_17';	
	$header->{52} = 'votes_ind3_17';
	$header->{55} = 'votes_ind4_17';	
	$header->{58} = 'votes_ind5_17';	
	$header->{61} = 'votes_ind6_17';	
	$header->{64} = 'votes_ind7_17';	
	$header->{67} = 'votes_ind8_17';		
    } elsif ($ac==322) { 
	$header->{13} = 'votes_bsp_17';
	$header->{16} = 'votes_inc_17';
	$header->{19} = 'votes_bjp_17';
	$header->{22} = 'votes_rld_17';	
	$header->{25} = 'votes_sbp_17';
	$header->{28} = 'votes_ggp_17';
	$header->{31} = 'votes_pp_17';
	$header->{34} = 'votes_skp_17';	
	$header->{37} = 'votes_bscp_17';
	$header->{40} = 'votes_jap_17';
	$header->{43} = 'votes_bmp_17';	
	$header->{46} = 'votes_rjp_17';
	$header->{49} = 'votes_ind1_17';	
	$header->{52} = 'votes_ind2_17';
	$header->{55} = 'votes_ind3_17';	
	$header->{58} = 'votes_ind4_17';	
	$header->{61} = 'votes_ind5_17';
	$header->{64} = 'votes_ind6_17';	
	$header->{67} = 'votes_ind7_17';	
	$header->{70} = 'votes_ind8_17';
	$header->{73} = 'votes_ind9_17';	
	$header->{76} = 'votes_ind10_17';	
	$header->{79} = 'votes_ind11_17';
    } elsif ($ac==323) { 
	$header->{13} = 'votes_cpi_17';
	$header->{16} = 'votes_ncp_17';
	$header->{19} = 'votes_rld_17';
	$header->{22} = 'votes_bsp_17';	
	$header->{25} = 'votes_sp_17';
	$header->{28} = 'votes_bjp_17';
	$header->{31} = 'votes_ad-u_17';
	$header->{34} = 'votes_bmp_17';	
	$header->{37} = 'votes_sbp_17';
	$header->{40} = 'votes_nishad_17';
	$header->{43} = 'votes_ind1_17';	
	$header->{46} = 'votes_ind2_17';
    } elsif ($ac==324) { 
	$header->{13} = 'votes_ncp_17';
	$header->{16} = 'votes_bsp_17';
	$header->{19} = 'votes_sp_17';
	$header->{22} = 'votes_bjp_17';	
	$header->{25} = 'votes_ssd_17';
	$header->{28} = 'votes_bsp_17';
	$header->{31} = 'votes_vp_17';
	$header->{34} = 'votes_bmp_17';	
	$header->{37} = 'votes_nishad_17';
	$header->{40} = 'votes_ind1_17';
	$header->{43} = 'votes_ind2_17';	
	$header->{46} = 'votes_ind3_17';
    } elsif ($ac==325) { 
	$header->{13} = 'votes_inc_17';
	$header->{16} = 'votes_bsp_17';
	$header->{19} = 'votes_sp_17';
	$header->{22} = 'votes_bjp_17';	
	$header->{25} = 'votes_asp_17';
	$header->{28} = 'votes_jap_17';
	$header->{31} = 'votes_nishad_17';
	$header->{34} = 'votes_bmp_17';	
	$header->{37} = 'votes_ind1_17';
	$header->{40} = 'votes_ind2_17';
    } elsif ($ac==326) { 
	$header->{13} = 'votes_rld_17';
	$header->{16} = 'votes_bsp_17';
	$header->{19} = 'votes_ncp_17';
	$header->{22} = 'votes_sp_17';	
	$header->{25} = 'votes_bjp_17';
	$header->{28} = 'votes_bmp_17';
	$header->{31} = 'votes_nishad_17';
	$header->{34} = 'votes_rmhgp_17';	
	$header->{37} = 'votes_bsap_17';
	$header->{40} = 'votes_ggp_17';
	$header->{43} = 'votes_ld_17';	
	$header->{46} = 'votes_ss_17';
	$header->{49} = 'votes_mp_17';	
	$header->{52} = 'votes_ind1_17';
	$header->{55} = 'votes_ind2_17';	
	$header->{58} = 'votes_ind3_17';
	$header->{61} = 'votes_ind4_17';	
	$header->{64} = 'votes_ind5_17';
	$header->{67} = 'votes_ind6_17';	
	$header->{70} = 'votes_ind7_17';
    } elsif ($ac==328) { 
	$header->{12} = 'votes_bjp_17';
	$header->{15} = 'votes_sp_17';
	$header->{18} = 'votes_bsp_17';
	$header->{21} = 'votes_bmp_17';	
	$header->{24} = 'votes_nishad_17';
	$header->{27} = 'votes_rjap_17';
	$header->{30} = 'votes_pgn_17';
	$header->{33} = 'votes_mkd_17';	
	$header->{36} = 'votes_ind_17';
    } elsif ($ac==336) { 
	$header->{13} = 'votes_inc_17';
	$header->{16} = 'votes_bsp_17';
	$header->{19} = 'votes_bjp_17';
	$header->{22} = 'votes_mp_17';	
	$header->{25} = 'votes_bsnp_17';
	$header->{28} = 'votes_nishad_17';
	$header->{31} = 'votes_avp_17';
	$header->{34} = 'votes_bsap_17';	
	$header->{37} = 'votes_jap_17';
	$header->{40} = 'votes_ind1_17';
	$header->{43} = 'votes_ind2_17';	
	$header->{46} = 'votes_ind3_17';
    } elsif ($ac==337) { 
	$header->{13} = 'votes_bsp_17';
	$header->{16} = 'votes_rld_17';
	$header->{19} = 'votes_bjp_17';
	$header->{22} = 'votes_sp_17';	
	$header->{25} = 'votes_cpi_17';
	$header->{28} = 'votes_bsp_17';
	$header->{31} = 'votes_ld_17';
	$header->{34} = 'votes_jap_17';	
	$header->{37} = 'votes_mp_17';
	$header->{40} = 'votes_pp_17';
	$header->{43} = 'votes_mkd_17';	
	$header->{46} = 'votes_ind1_17';
	$header->{49} = 'votes_ind2_17';	
	$header->{52} = 'votes_ind3_17';
	$header->{55} = 'votes_ind4_17';		
    } elsif ($ac==338) { 
	$header->{13} = 'votes_bsp_17';
	$header->{16} = 'votes_rld_17';
	$header->{19} = 'votes_sp_17';
	$header->{22} = 'votes_bjp_17';	
	$header->{25} = 'votes_aimim_17';
	$header->{28} = 'votes_ad-u_17';
	$header->{31} = 'votes_bscp_17';
	$header->{34} = 'votes_bjd-i_17';	
	$header->{37} = 'votes_bjs_17';
	$header->{40} = 'votes_bmp_17';
	$header->{43} = 'votes_bsap_17';	
	$header->{46} = 'votes_pp_17';
	$header->{49} = 'votes_ind1_17';	
	$header->{52} = 'votes_ind2_17';
    } elsif ($ac==339) { 
	$header->{13} = 'votes_cpi_17';
	$header->{16} = 'votes_bjp_17';
	$header->{19} = 'votes_sp_17';
	$header->{22} = 'votes_bsp_17';	
	$header->{25} = 'votes_rld_17';
	$header->{28} = 'votes_ncp_17';
	$header->{31} = 'votes_ssp_17';
	$header->{34} = 'votes_bmp_17';	
	$header->{37} = 'votes_jap_17';
	$header->{40} = 'votes_rpi-a_17';
	$header->{43} = 'votes_ind1_17';	
	$header->{46} = 'votes_ind2_17';
	$header->{49} = 'votes_ind3_17';	
    } elsif ($ac==349) { 
	$header->{13} = 'votes_bsp_17';
	$header->{16} = 'votes_bjp_17';
	$header->{19} = 'votes_rld_17';
	$header->{22} = 'votes_cpi_17';	
	$header->{25} = 'votes_sp_17';
	$header->{28} = 'votes_md_17';
	$header->{31} = 'votes_bmp_17';
	$header->{34} = 'votes_nishad_17';	
	$header->{37} = 'votes_asp_17';
	$header->{40} = 'votes_ind1_17';
	$header->{43} = 'votes_ind2_17';	
	$header->{46} = 'votes_ind3_17';
	$header->{49} = 'votes_ind4_17';	
    } elsif ($ac==355) { 
	$header->{13} = 'votes_sp_17';
	$header->{16} = 'votes_bsp_17';
	$header->{19} = 'votes_bjp_17';
	$header->{22} = 'votes_pmp_17';	
	$header->{25} = 'votes_bmp_17';
	$header->{28} = 'votes_ppp_17';
	$header->{31} = 'votes_jap_17';
    } elsif ($ac==357) { 
	$header->{13} = 'votes_sp_17';
	$header->{16} = 'votes_bsp_17';
	$header->{19} = 'votes_bjp_17';
	$header->{22} = 'votes_rld_17';	
	$header->{25} = 'votes_pjd_17';
	$header->{28} = 'votes_ggp_17';
	$header->{31} = 'votes_jap_17';
	$header->{34} = 'votes_bmp_17';	
	$header->{37} = 'votes_suci_17';
	$header->{40} = 'votes_mkp_17';
	$header->{43} = 'votes_ind1_17';	
	$header->{46} = 'votes_ind2_17';
	$header->{49} = 'votes_ind3_17';	
	$header->{52} = 'votes_ind4_17';
    } elsif ($ac==358) { 
	$header->{13} = 'votes_bsp_17';
	$header->{16} = 'votes_bjp_17';
	$header->{19} = 'votes_ncp_17';
	$header->{22} = 'votes_sp_17';	
	$header->{25} = 'votes_jap_17';
	$header->{28} = 'votes_asp_17';
	$header->{31} = 'votes_bmp_17';
	$header->{34} = 'votes_rjbvp_17';	
	$header->{37} = 'votes_ind1_17';
	$header->{40} = 'votes_ind2_17';
	$header->{43} = 'votes_ind3_17';	
    } elsif ($ac==359) { 
	$header->{13} = 'votes_rld_17';
	$header->{16} = 'votes_sp_17';
	$header->{19} = 'votes_bsp_17';
	$header->{22} = 'votes_bjp_17';	
	$header->{25} = 'votes_bmp_17';
	$header->{28} = 'votes_cpi-m-ll_17';
	$header->{31} = 'votes_jap_17';
	$header->{34} = 'votes_ind1_17';	
	$header->{37} = 'votes_ind2_17';
	$header->{40} = 'votes_ind3_17';
	$header->{43} = 'votes_ind4_17';	
    } elsif ($ac==360) { 
	$header->{13} = 'votes_bsp_17';
	$header->{16} = 'votes_bjp_17';
	$header->{19} = 'votes_rld_17';
	$header->{22} = 'votes_sp_17';	
	$header->{25} = 'votes_jap_17';
	$header->{28} = 'votes_bmp_17';
	$header->{31} = 'votes_vsip_17';
	$header->{34} = 'votes_ind1_17';	
	$header->{37} = 'votes_ind2_17';
	$header->{40} = 'votes_ind3_17';
	$header->{43} = 'votes_ind4_17';	
    } elsif ($ac==361) { 
	$header->{13} = 'votes_bjp_17';
	$header->{16} = 'votes_bsp_17';
	$header->{19} = 'votes_rld_17';
	$header->{22} = 'votes_sp_17';	
	$header->{25} = 'votes_cpi-m_17';
	$header->{28} = 'votes_ggp_17';
	$header->{31} = 'votes_jap_17';
	$header->{34} = 'votes_np_17';	
	$header->{37} = 'votes_bmp_17';
	$header->{40} = 'votes_bsap_17';
	$header->{43} = 'votes_ind1_17';	
	$header->{46} = 'votes_ind2_17';
	$header->{49} = 'votes_ind3_17';	
	$header->{52} = 'votes_ind4_17';
    } elsif ($ac==362) { 
	$header->{13} = 'votes_rld_17';
	$header->{16} = 'votes_sp_17';
	$header->{19} = 'votes_bsp_17';
	$header->{22} = 'votes_sbsp_17';	
	$header->{25} = 'votes_psp_17';
	$header->{28} = 'votes_ld_17';
	$header->{31} = 'votes_jap_17';
	$header->{34} = 'votes_bjk_17';	
	$header->{37} = 'votes_ind1_17';
	$header->{40} = 'votes_ind2_17';
	$header->{43} = 'votes_ind3_17';	
	$header->{46} = 'votes_ind4_17';
	$header->{49} = 'votes_ind5_17';	
	$header->{52} = 'votes_ind6_17';
	$header->{55} = 'votes_ind7_17';		
	$header->{58} = 'votes_ind8_17';	
	$header->{61} = 'votes_ind9_17';
	$header->{64} = 'votes_ind10_17';		
    } elsif ($ac==363) { 
	$header->{13} = 'votes_sp_17';
	$header->{16} = 'votes_bsp_17';
	$header->{19} = 'votes_rld_17';
	$header->{22} = 'votes_bjp_17';	
	$header->{25} = 'votes_bmp_17';
	$header->{28} = 'votes_pjd_17';
	$header->{31} = 'votes_blp_17';
	$header->{34} = 'votes_ppp_17';	
	$header->{37} = 'votes_ind1_17';
	$header->{40} = 'votes_ind2_17';
	$header->{43} = 'votes_ind3_17';	
	$header->{46} = 'votes_ind4_17';
	$header->{49} = 'votes_ind5_17';	
	$header->{52} = 'votes_ind6_17';
	$header->{55} = 'votes_ind7_17';		
	$header->{58} = 'votes_ind8_17';
	$header->{61} = 'votes_ind9_17';		
    } elsif ($ac==380) { 
	$header->{13} = 'votes_bsp_17';
	$header->{16} = 'votes_sp_17';
	$header->{19} = 'votes_bjp_17';
	$header->{22} = 'votes_bmp_17';	
	$header->{25} = 'votes_pmsp_17';
	$header->{28} = 'votes_map_17';
	$header->{31} = 'votes_ppp_17';
	$header->{34} = 'votes_cpi-m-ll_17';	
	$header->{37} = 'votes_ind1_17';
	$header->{40} = 'votes_ind2_17';
	$header->{43} = 'votes_ind3_17';	
    } elsif ($ac==382) { 
	$header->{13} = 'votes_rld_17';
	$header->{16} = 'votes_sp_17';
	$header->{19} = 'votes_bsp_17';
	$header->{22} = 'votes_bjp_17';	
	$header->{25} = 'votes_bmp_17';
	$header->{28} = 'votes_jrp_17';
	$header->{31} = 'votes_jap_17';
	$header->{34} = 'votes_ind1_17';	
	$header->{37} = 'votes_ind2_17';
	$header->{40} = 'votes_ind3_17';
	$header->{43} = 'votes_ind4_17';	
	$header->{46} = 'votes_ind5_17';
	$header->{49} = 'votes_ind6_17';	
    } elsif ($ac==391) { 
	$header->{13} = 'votes_bsp_17';
	$header->{16} = 'votes_cpi-m_17';
	$header->{19} = 'votes_sp_17';
	$header->{22} = 'votes_rsp_17';	
	$header->{25} = 'votes_rpi-a_17';
	$header->{28} = 'votes_bss_17';
	$header->{31} = 'votes_ad_17';
	$header->{34} = 'votes_iemc_17';	
	$header->{37} = 'votes_bmp_17';
	$header->{40} = 'votes_ind1_17';
	$header->{43} = 'votes_ind2_17';	
	$header->{46} = 'votes_ind3_17';
	$header->{49} = 'votes_ind4_17';	
	$header->{52} = 'votes_ind5_17';
    } elsif ($ac==396) { 
	$header->{13} = 'votes_sp_17';
	$header->{16} = 'votes_cpi_17';
	$header->{19} = 'votes_rld_17';
	$header->{22} = 'votes_bsp_17';	
	$header->{25} = 'votes_bjp_17';
	$header->{28} = 'votes_bcsb_17';
	$header->{31} = 'votes_bmp_17';
	$header->{34} = 'votes_bnd_17';	
	$header->{37} = 'votes_pmsp_17';
	$header->{40} = 'votes_rjsp_17';
	$header->{43} = 'votes_ssp_17';	
	$header->{46} = 'votes_ind1_17';
	$header->{49} = 'votes_ind2_17';	
	$header->{52} = 'votes_ind3_17';
	$header->{55} = 'votes_ind4_17';		
	$header->{58} = 'votes_ind5_17';
	$header->{61} = 'votes_ind6_17';	
	$header->{64} = 'votes_ind7_17';
	$header->{67} = 'votes_ind8_17';		
    } elsif ($ac==401) { 
	$header->{13} = 'votes_sp_17';
	$header->{16} = 'votes_cpi_17';
	$header->{19} = 'votes_bjp_17';
	$header->{22} = 'votes_rld_17';	
	$header->{25} = 'votes_ncp_17';
	$header->{28} = 'votes_bsp_17';
	$header->{31} = 'votes_ggp_17';
	$header->{34} = 'votes_bss_17';	
	$header->{37} = 'votes_amkp_17';
	$header->{40} = 'votes_jap_17';
	$header->{43} = 'votes_ind1_17';	
	$header->{46} = 'votes_ind2_17';
	$header->{49} = 'votes_ind3_17';	
	$header->{52} = 'votes_ind4_17';
	$header->{55} = 'votes_ind5_17';		
	$header->{58} = 'votes_ind6_17';
	$header->{61} = 'votes_ind7_17';	
	$header->{64} = 'votes_ind8_17';
	$header->{67} = 'votes_ind9_17';		
    } elsif ($ac==403) { 
	$header->{13} = 'votes_inc_17';
	$header->{16} = 'votes_bsp_17';
	$header->{19} = 'votes_rld_17';
	$header->{22} = 'votes_brj_17';	
	$header->{25} = 'votes_ggp_17';
	$header->{28} = 'votes_cpi-m-ll_17';
	$header->{31} = 'votes_ad_17';
	$header->{34} = 'votes_ind1_17';	
	$header->{37} = 'votes_ind2_17';
    } 

    foreach my $datapage (keys(%{$data})) {
	foreach my $datarow (keys(%{$data->{$datapage}})) {
	    foreach my $datacol (keys(%{$data->{$datapage}->{$datarow}})) {
		my $content = $data->{$datapage}->{$datarow}->{$datacol};
		my $sqlheader;
		for ($colcount=1;$colcount<=@{$col->{$datapage}};$colcount++) {
		    if ($datacol == $col->{$datapage}->[$colcount-1]) {$sqlheader = $header->{$colcount}}
		}
		next if ($sqlheader eq '');
		if ($sqlheader=~/^votes_.*?_17$/) {$party{$sqlheader}=1}
		$actual->{$ac."-".$datapage."-".$datarow}->{$sqlheader}=$actual->{$ac."-".$datapage."-".$datarow}->{$sqlheader}+$content;
	    }
	}
    }

    #
    # Add Party headers to table
    #

    
    foreach my $party (keys(%party)) {
	$party =~ s/-/_/gs;
	next if defined($allparty{$party});
	$allparty{$party}=1;
	$dbh->do("ALTER TABLE upvidhansabha2017 ADD COLUMN ".$party." INTEGER");
	$party =~ s/_17$//gs;
	$dbh->do("ALTER TABLE upvidhansabha2017 ADD COLUMN ".$party."_percent_17 FLOAT");
    }

  
    #
    # Actually insert results into table
    #
    $dbh->begin_work;
    
    foreach my $key (keys(%{$actual})) {
	if ($actual->{$key}->{'booth_id_17'} > 0) {	
	next if $actual->{$key}->{'electors_17'} > 5000; # signals this is the total line rather than anything else
	next if $actual->{$key}->{'electors_17'} < 100; # signals again that something fishy is going on...

	my $insertheader; my $insertmarks; my @insertcontent;
	foreach my $subkey (keys(%{$actual->{$key}})) {
	    next if $actual->{$key}->{$subkey} !~ /^[0-9]+$/;
	    my $party = $subkey;
	    $party =~ s/-/_/gs;
	    $insertheader.=$party.", "; 
	    $insertmarks.="?, ";
	    push (@insertcontent, $actual->{$key}->{$subkey});
        }
        push (@insertcontent,$ac);
	$dbh->do("INSERT INTO upvidhansabha2017 (".$insertheader."ac_id_09) VALUES (".$insertmarks."?)",undef,@insertcontent);
        }
    }
    
    $dbh->commit;
}

$dbh->do ("CREATE INDEX ac_booth ON upvidhansabha2017 (ac_id_09,booth_id_17)");

#
# Calculate percentages
#

$dbh->begin_work;
$dbh->do("UPDATE upvidhansabha2017 SET turnout_percent_17 = cast(turnout_17 as FLOAT)/electors_17");
$dbh->do("UPDATE upvidhansabha2017 SET female_votes_percent_17 = cast(female_votes_17 as FLOAT)/turnout_17");

foreach my $party (keys(%allparty)) {
    $party =~ s/^votes_//gs;
    $party =~ s/_17$//gs;
    $dbh->do("UPDATE upvidhansabha2017 SET votes_".$party."_percent_17 = cast(votes_".$party."_17 as FLOAT)/turnout_17");
}
$dbh->commit;

#
# Finally create sqlite dump 
#



system("sqlite3 temp.sqlite '.dump upvidhansabha2017' > upvidhansabha2017-a.sql");

open (FILE, ">>upvidhansabha2017-a.sql");

print FILE ".mode csv\n";
print FILE ".headers on\n";
print FILE ".once upvidhansabha2017/upvidhansabha2017.csv\n";
print FILE "SELECT * FROM upvidhansabha2017;\n";

close (FILE);

system("split -l 24000 upvidhansabha2017-a.sql");
system("mv xaa upvidhansabha2017-a.sql");
system("echo 'COMMIT;' >> upvidhansabha2017-a.sql");
system("echo 'BEGIN TRANSACTION;' > upvidhansabha2017-b.sql");
system("cat xab >> upvidhansabha2017-b.sql");
system("echo 'COMMIT;' >> upvidhansabha2017-b.sql");
system("rm xab");
system("echo 'BEGIN TRANSACTION;' > upvidhansabha2017-c.sql");
system("cat xac >> upvidhansabha2017-c.sql");
system("echo 'COMMIT;' >> upvidhansabha2017-c.sql");
system("rm xac");
system("echo 'BEGIN TRANSACTION;' > upvidhansabha2017-d.sql");
system("cat xad >> upvidhansabha2017-d.sql");
system("rm xad");

system("rm -f temp.sqlite");
