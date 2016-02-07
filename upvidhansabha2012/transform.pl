#!/usr/bin/perl -CSDA

use DBI;

use Text::WagnerFischer 'distance';
use Text::CSV;
use List::Util 'min';
use List::MoreUtils 'indexes';

#
# First read manually compiled results and rewrite into useful format in fake memory CSV
# (originally this went into a real CSV, hence the weirdish processing chain here)
#

open (FILE, "results.csv");
my @in = <FILE>;
my $header = shift (@in);
close (FILE);

my $csv = Text::CSV->new();

my $oldconst=0; my $i=1; my %out; my %parties; my $oldboothname; my %oldparty;

while (my $line = shift(@in)) {
    $csv->parse($line);
    my @columns = $csv->fields();
    $out{$i}->{'constituency_id'}=shift(@columns);
    next if $out{$i}->{'constituency_id'} !~ /\d/;
    $out{$i}->{'constituency_name'}=shift(@columns);
    $out{$i}->{'constituency_reserved'}=shift(@columns);
    $out{$i}->{'booth_id'}=shift(@columns);
    $out{$i}->{'booth_name'}=shift(@columns);
    if ($out{$i}->{'booth_name'} =~ /^,,/) {$out{$i}->{'booth_name'}=$oldboothname}
    $oldboothname = $out{$i}->{'booth_name'};
    $out{$i}->{'electors'}=shift(@columns);
    $out{$i}->{'turnout_male'}=shift(@columns);
    $out{$i}->{'turnout_female'}=shift(@columns);
    shift (@columns);
    $out{$i}->{'turnout_total'}=shift(@columns);
    shift (@columns);
    shift (@columns);
    my $indcount=1;
    for ($p=0;$p<scalar(@columns)/3;$p++) {
	shift (@columns);
	if ($oldconst == $out{$i}->{'constituency_id'}) { 
	    shift (@columns);
	    $party = $oldparty{$p};
	    $votes = shift (@columns);
	    $votes =~ s/\D//gs;
	} else {
	    $party = shift (@columns);
	    $party =~ s/\.//gs;
	    $party =~ s/\,//gs;
	    $party =~ s/\)//gs;
	    $party =~ s/\(/-/gs;
	    $party =~ s/\s//gs;
	    $party = lc($party);
	    if ($party =~ /\d/) {print $out{$i}->{'constituency_id'};exit}
	    if ($party eq 'indep') {$party = 'ind'}
	    if ($party eq 'indipendent') {$party = 'ind'}
	    if ($party eq 'indp') {$party = 'ind'}
	    if ($party eq 'indpendent') {$party = 'ind'}
	    if ($party eq 'indpt') {$party = 'ind'}
	    if ($party eq 'indt') {$party = 'ind'}
	    if ($party eq 'independent') {$party = 'ind'}
	    if ($party eq 'nir') {$party = 'ind'}
	    if ($party eq 'ind') {$party = $party.$indcount; $indcount++}
	    if ($party eq 'a-p-') {$party = 'ap'}
	    if ($party eq 'a-p') {$party = 'ap'}
	    if ($party eq 'apnadal') {$party = 'ad'}
	    if ($party eq 'b-j-') {$party = 'bj'}
	    if ($party eq 'bahujansamajparty') {$party = 'bsp'}
	    if ($party eq 'bhartiyajantaparty') {$party = 'bjp'}
	    if ($party eq 'bhartiyasatyarthsangthan') {$party = 'bss'}
	    if ($party eq 'cpi-ml-l') {$party = 'cpi-mll'}
	    if ($party eq 'cpim') {$party = 'cpi-m'}
	    if ($party eq 'cpiml') {$party = 'cpi-ml'}
	    if ($party eq 'cpoi-ml-l') {$party = 'cpi-mll'}
	    if ($party eq 'hasiya,hatoda,sitara') {$party = 'hhs'}
	    if ($party eq 'indianjp') {$party = 'ijp'}
	    if ($party eq 'indiannationalcongres') {$party = 'inc'}
	    if ($party eq 'janmorch') {$party = 'jm'}
	    if ($party eq 'janmorcha') {$party = 'jm'}
	    if ($party eq 'janmo') {$party = 'jm'}
	    if ($party eq 'jd-secular') {$party = 'jd-s'}
	    if ($party eq 'l-d') {$party = 'ld'}
	    if ($party eq 'lokdal') {$party = 'ld'}
	    if ($party eq 'lokjanp') {$party = 'ljp'}
	    if ($party eq 'rastriyalokdal') {$party = 'rld'}
	    if ($party eq 'samajwadiparty') {$party = 'sp'}
	    if ($party eq 'samta') {$party = 's'}
	    if ($party eq 'samtap') {$party = 's'}
	    if ($party eq 's-p-') {$party = 'sp'}
	    if ($party eq 'samtaparty') {$party = 's'}
	    if ($party eq 'samtapartyp') {$party = 's'}
	    if ($party eq 'samyawadiparty') {$party = 'sap'}
	    if ($party eq 'shivsena') {$party = 'ss'}
	    if ($party eq 'shivsenap') {$party = 'ss'}
	    if ($party =~ /sjp./gs && $party ne 'sjpr' && $party ne 'sjp-r') {$party = 'sjp'}
	    if ($party eq 'hasiyahatodasitara') {$party='hhs'}
	    if ($party eq 'adarsadarshrashtriyavikasparty') {$party = 'arvp'}
	    if ($party eq 'adarshrashtriyavikasdal') {$party = 'arvd'}
	    if ($party eq 'adarshrashtriyavikashparty') {$party = 'arvp'}
	    if ($party eq 'adarshrashtriyavikasparty') {$party = 'arvp'}
	    if ($party eq 'adarshsamajparty') {$party = 'asp'}
	    if ($party eq 'addal') {$party = 'add'}
	    if ($party eq 'ait-c') {$party = 'aitc'}
	    if ($party eq 'akhilbharathindumahasabha') {$party = 'abhm'}
	    if ($party eq 'akhilbharatiyadeshbhaktmorcha') {$party = 'abdbm'}
	    if ($party eq 'akhilbhartiyaloktantrikcongress') {$party = 'abltc'}
	    if ($party eq 'al-hindparty') {$party = 'ahp'}
	    if ($party eq 'allindiaforwardblock') {$party = 'aifb'}
	    if ($party eq 'allindiaminoritiesfront') {$party = 'aimf'}
	    if ($party eq 'allindiantrinamoolcongress') {$party = 'aitc'}
	    if ($party eq 'allindiatranmoolcongress') {$party = 'aitc'}
	    if ($party eq 'allindiatrinamoolcogress') {$party = 'aitc'}
	    if ($party eq 'allindiatrinamoolcongress') {$party = 'aitc'}
	    if ($party eq 'allindiatrinmoolcongress') {$party = 'aitc'}
	    if ($party eq 'ambedakarsamajparty') {$party = 'asp'}
	    if ($party eq 'ambedkarnationalcongress') {$party = 'anc'}
	    if ($party eq 'ambedkarsamajparty') {$party = 'asp'}
	    if ($party eq 'ambedkarsamajpatry') {$party = 'asp'}
	    if ($party eq 'apanadal') {$party = 'ad'}
	    if ($party eq 'asankhyasamajparty') {$party = 'assp'}
	    if ($party eq 'bahujansagharshparty-kanshiram') {$party = 'bsp-k'}
	    if ($party eq 'bahujansamajparty-ambedkar') {$party = 'bsp-a'}
	    if ($party eq 'bahujansangharshparty-kanshiram') {$party = 'bsp-k'}
	    if ($party eq 'bahujanshakti') {$party = 'bs'}
	    if ($party eq 'bharatiyaeklavyaparty') {$party = 'bep'}
	    if ($party eq 'bharatiyajanataparty') {$party = 'bjp'}
	    if ($party eq 'bharatiyajanberojgarchhatradal') {$party = 'bjbgd'}
	    if ($party eq 'bharatiyajantaparty') {$party = 'bjp'}
	    if ($party eq 'bharatiyakrishakdal') {$party = 'bkd'}
	    if ($party eq 'bharatiyaprajatantranirmanparty') {$party = 'bptnp'}
	    if ($party eq 'bharatiyarashtriyabahujansamajvikasparty') {$party = 'bsbsvp'}
	    if ($party eq 'bharatiyarepublicanpaksh') {$party = 'brp'}
	    if ($party eq 'bharatiyarepublicanpaksha') {$party = 'brp'}
	    if ($party eq 'bharatiyasamajdal') {$party = 'bsd'}
	    if ($party eq 'bhartiyabanchitsamajparty') {$party = 'bbsp'}
	    if ($party eq 'bhartiyajanataparty') {$party = 'bjp'}
	    if ($party eq 'bhartiyakrishakdal') {$party = 'bkd'}
	    if ($party eq 'bhartiyaprajatantranirmanparty') {$party = 'bptnp'}
	    if ($party eq 'bhartiyarashtriyamorcha') {$party = 'brm'}
	    if ($party eq 'bhartiyarepublicanpaksha') {$party = 'brp'}
	    if ($party eq 'bhartiyasamajikkrantidal') {$party = 'bskd'}
	    if ($party eq 'bhartiyasarvodayakrantiparty') {$party = 'bskd'}
	    if ($party eq 'bhartiyasarvodaykrantiparty') {$party = 'bskd'}
	    if ($party eq 'bhartiyasubhashsena') {$party = 'bss'}
	    if ($party eq 'bhartiyavanchitsamajparty') {$party = 'bvsp'}
	    if ($party eq 'bhartiyavidasparty') {$party = 'bvp'}
	    if ($party eq 'bhartiyjanataparty') {$party = 'bjp'}
	    if ($party eq 'bhartiyjantaparty') {$party = 'bjp'}
	    if ($party eq 'brajvikasparty') {$party = 'bravp'}
	    if ($party eq 'bsp-kanshiram') {$party = 'bsp-k'}
	    if ($party eq 'buladelkhandcongress') {$party = 'bkc'}
	    if ($party eq 'bundelkhandcongress') {$party = 'bkc'}
	    if ($party eq 'bunndelkhandcongress') {$party = 'bkc'}
	    if ($party eq 'communistpartyofindia') {$party = 'cpi'}
	    if ($party eq 'communistpartyofindia-marxist') {$party = 'cpi-m'}
	    if ($party eq 'communistpartyofindia-marxist-leninist-liberation') {$party = 'cpi-mll'}
	    if ($party eq 'communistpartyofindia-marxistleninist-libration') {$party = 'cpi-mll'}
	    if ($party eq 'congress') {$party = 'inc'}
	    if ($party eq 'cpi-m-l') {$party = 'cpi-ml'}
	    if ($party eq 'cpi-m-l-l') {$party = 'cpi-mll'}
	    if ($party eq 'cpimll') {$party = 'cpi-mll'}
	    if ($party eq 'cpm') {$party = 'cpi-m'}
	    if ($party eq 'dalitsamajparty') {$party = 'dsp'}
	    if ($party eq 'eklavyasamajparty') {$party = 'esp'}
	    if ($party eq 'gareebsamanaparty') {$party = 'gsp'}
	    if ($party eq 'indiajusticeparty') {$party = 'ijp'}
	    if ($party eq 'indiancongressparty') {$party = 'inc'}
	    if ($party eq 'indianjusticeparty') {$party = 'ijp'}
	    if ($party eq 'indiannationalcongress') {$party = 'inc'}
	    if ($party eq 'indiannationalistcongress') {$party = 'inc'}
	    if ($party eq 'indiannationalleague') {$party = 'inl'}
	    if ($party eq 'indiannationlcongress') {$party = 'inc'}
	    if ($party eq 'indianoceanicparty') {$party = 'iop'}
	    if ($party eq 'inqalabvikasdal') {$party = 'ivs'}
	    if ($party eq 'ittehad-e-millattcouncil') {$party = 'iemc'}
	    if ($party eq 'ittehademillatcouncil') {$party = 'iemc'}
	    if ($party eq 'jagratbharatparty') {$party = 'jbp'}
	    if ($party eq 'jaimahabharatparty') {$party = 'jmbp'}
	    if ($party eq 'jammu&kashmirnationalpanthersparty') {$party = 'jknpp'}
	    if ($party eq 'jan-krantiparty-rashtrawadi') {$party = 'jkp-r'}
	    if ($party eq 'janatadal-u') {$party = 'jd-u'}
	    if ($party eq 'janatadal-united') {$party = 'jd-u'}
	    if ($party eq 'janatadalunited') {$party = 'jd-u'}
	    if ($party eq 'janatavikasmanch') {$party = 'jvm'}
	    if ($party eq 'jankarantiparty') {$party = 'jkp'}
	    if ($party eq 'jankarantiparty-rashtrawadi') {$party = 'jkp-r'}
	    if ($party eq 'jankrantiparty') {$party = 'jkp'}
	    if ($party eq 'jankrantiparty-nationalist') {$party = 'jkp-n'}
	    if ($party eq 'jankrantiparty-rashtravadi') {$party = 'jkp-r'}
	    if ($party eq 'jankrantiparty-rashtrawadi') {$party = 'jkp-r'}
	    if ($party eq 'jankrantiparty-rastravadi') {$party = 'jkp-r'}
	    if ($party eq 'jankrantiparty-rastrawadi') {$party = 'jkp-r'}
	    if ($party eq 'jankrantiparty-rastrawady') {$party = 'jkp-r'}
	    if ($party eq 'jankrantipartyrashtrawadi') {$party = 'jkp-r'}
	    if ($party eq 'jankrantipartyrastrawadi') {$party = 'jkp-r'}
	    if ($party eq 'jansanghparty') {$party = 'jsp'}
	    if ($party eq 'jantadal-secular') {$party = 'jd-s'}
	    if ($party eq 'jantadal-united') {$party = 'jd-u'}
	    if ($party eq 'jantadalsecular') {$party = 'jd-s'}
	    if ($party eq 'jantadalunited') {$party = 'jd-u'}
	    if ($party eq 'janvadiparty-socialist') {$party = 'jvp-s'}
	    if ($party eq 'janvadiparty-sociolist') {$party = 'jvp-s'}
	    if ($party eq 'janvadipartyofindia-socialist') {$party = 'jvp-s'}
	    if ($party eq 'janwadiparty-socialist') {$party = 'jvp-s'}
	    if ($party eq 'javankisanmorcha') {$party = 'jkm'}
	    if ($party eq 'jawankisanmorcha') {$party = 'jkm'}
	    if ($party eq 'jharkhandmuktimorcha') {$party = 'jkmm'}
	    if ($party eq 'jd-uni') {$party = 'jd-u'}
	    if ($party eq 'jd-united') {$party = 'jd-u'}
	    if ($party eq 'jdu') {$party = 'jd-u'}
	    if ($party eq 'jkp®') {$party = 'jkp-r'}
	    if ($party eq 'jkp¼r½') {$party = 'jkp-r'}
	    if ($party eq 'jnd') {$party = 'jd'}
	    if ($party eq 'jp[r]') {$party = 'jp-r'}
	    if ($party eq 'jpr') {$party = 'jp-r'}
	    if ($party eq 'jps') {$party = 'jp-s'}
	    if ($party eq 'jp®') {$party = 'jp-r'}
	    if ($party eq 'jwaladal') {$party = 'jwd'}
	    if ($party eq 'kisansena') {$party = 'ks'}
	    if ($party eq 'kis') {$party = 'ks'}
	    if ($party eq 'kpimll') {$party = 'cpi-mll'}
	    if ($party eq 'krantikarisamataparty') {$party = 'kksp'}
	    if ($party eq 'krantikarisamtaparty') {$party = 'kksp'}
	    if ($party eq 'labourpartyofindia-vvprasad') {$party = 'lpi-vvp'}
	    if ($party eq 'lokjansaktiparty') {$party = 'ljsp'}
	    if ($party eq 'lokjanshaktiparty') {$party = 'ljsp'}
	    if ($party eq 'lokjanshkatiparty') {$party = 'ljsp'}
	    if ($party eq 'loknirmanparty') {$party = 'lnp'}
	    if ($party eq 'lokpriyasamajparty') {$party = 'lpsp'}
	    if ($party eq 'lokpriysamajparty') {$party = 'lpsp'}
	    if ($party eq 'mahandal') {$party = 'md'}
	    if ($party eq 'manavadhikarjanshaktiparty') {$party = 'majsp'}
	    if ($party eq 'manavtawadisamajparti') {$party = 'masp'}
	    if ($party eq 'manavtawadisamajparty') {$party = 'masp'}
	    if ($party eq 'maulikadhikarparty') {$party = 'map'}
	    if ($party eq 'meydhaaparty') {$party = 'mdp'}
	    if ($party eq 'mominconference') {$party = 'mmc'}
	    if ($party eq 'mostbackwardclassesofindia') {$party = 'mbci'}
	    if ($party eq 'muslimmajlisuttarpradesh') {$party = 'mmup'}
	    if ($party eq 'naitikparty') {$party = 'naitikp'}
	    if ($party eq 'nakibharatiyaekataparty') {$party = 'nbep'}
	    if ($party eq 'nakibharatiyaektaparty') {$party = 'nbep'}
	    if ($party eq 'nakibhartiyaeaktaparty') {$party = 'nbep'}
	    if ($party eq 'nakibhartiyaektaparty') {$party = 'nbep'}
	    if ($party eq 'nationalbackwardparty') {$party = 'nbp'}
	    if ($party eq 'nationalcongressparty') {$party = 'ncp'}
	    if ($party eq 'nationalistcongressparty') {$party = 'ncp'}
	    if ($party eq 'nationalistloktantrikparty') {$party = 'nltp'}
	    if ($party eq 'nationalloktantrikparty') {$party = 'nltp'}
	    if ($party eq 'parivartandal') {$party = 'pvd'}
	    if ($party eq 'parivartansamajparty') {$party = 'pvsp'}
	    if ($party eq 'peaceparty') {$party = 'pp'}
	    if ($party eq 'pragatisheelmanavsamajparty') {$party = 'psmsp'}
	    if ($party eq 'pragitisheelmanavsamajparty') {$party = 'psmsp'}
	    if ($party eq 'prajatantrikbahujanshaktidal') {$party = 'prbd'}
	    if ($party eq 'progressivedemocraticparty') {$party = 'pdp'}
	    if ($party eq 'qaumiektadal') {$party = 'qed'}
	    if ($party eq 'quamiektadal') {$party = 'qed'}
	    if ($party eq 'rahtriyasmamantadal') {$party = 'rsd'}
	    if ($party eq 'rajlokparty') {$party = 'rlp'}
	    if ($party eq 'rashtraloknirmanparty') {$party = 'rlnp'}
	    if ($party eq 'rashtranirmanparty') {$party = 'rnp'}
	    if ($party eq 'rashtravadicommunistparty') {$party = 'rcp'}
	    if ($party eq 'rashtrawadilabourparty') {$party = 'rlp'}
	    if ($party eq 'rashtraylokmanch') {$party = 'rlm'}
	    if ($party eq 'rashtriyaambedkardal') {$party = 'rad'}
	    if ($party eq 'rashtriyaapnadal') {$party = 'rapd'}
	    if ($party eq 'rashtriyabackwardparty') {$party = 'rbp'}
	    if ($party eq 'rashtriyabahujanhitayparty') {$party = 'rbhp'}
	    if ($party eq 'rashtriyagondwanaparty') {$party = 'rgp'}
	    if ($party eq 'rashtriyainsafparty') {$party = 'rip'}
	    if ($party eq 'rashtriyajansewakparty') {$party = 'rjsp'}
	    if ($party eq 'rashtriyajanvadiparty-krantikari') {$party = 'rjvp-k'}
	    if ($party eq 'rashtriyajanwadiparty-krantikari') {$party = 'rjvp-k'}
	    if ($party eq 'rashtriyakrantikarisamajwadiparty') {$party = 'rksp'}
	    if ($party eq 'rashtriyalokdal') {$party = 'rld'}
	    if ($party eq 'rashtriyalokmanch') {$party = 'rlm'}
	    if ($party eq 'rashtriyalokmanchparty') {$party = 'rlm'}
	    if ($party eq 'rashtriyaloknirmanparty') {$party = 'rlnp'}
	    if ($party eq 'rashtriyamahandal') {$party = 'rmd'}
	    if ($party eq 'rashtriyamahangantantraparty') {$party = 'rmgtp'}
	    if ($party eq 'rashtriyamanavsammanparty') {$party = 'rmsp'}
	    if ($party eq 'rashtriyaparivartandal') {$party = 'rpd'}
	    if ($party eq 'rashtriyasamantadal') {$party = 'rsd'}
	    if ($party eq 'rashtriyaswabhimaanparty') {$party = 'rswp'}
	    if ($party eq 'rashtriyaswabhimanparty') {$party = 'rswp'}
	    if ($party eq 'rashtriyaulamaamacouncil') {$party = 'ruc'}
	    if ($party eq 'rashtriyaulamacouncil') {$party = 'ruc'}
	    if ($party eq 'rashtriyaulamadal') {$party = 'rud'}
	    if ($party eq 'rashtriyaulemacouncil') {$party = 'ruc'}
	    if ($party eq 'rashtriyaviklangparty') {$party = 'rvlp'}
	    if ($party eq 'rashtriyjanwadiparty-krantikari') {$party = 'rjp-k'}
	    if ($party eq 'rastriyagondawanaparty') {$party = 'rgp'}
	    if ($party eq 'rastriyajan-tantrapaksh') {$party = 'rjtp'}
	    if ($party eq 'rastriyakrantikarisamajwadiparty') {$party = 'rkksp'}
	    if ($party eq 'rastriyalikmanch') {$party = 'rlm'}
	    if ($party eq 'rastriyalokmanch') {$party = 'rlm'}
	    if ($party eq 'rastriyaloknirmanparty') {$party = 'rlnp'}
	    if ($party eq 'rastriyamahandal') {$party = 'rmd'}
	    if ($party eq 'rastriyamahangantantraparty') {$party = 'rmgtp'}
	    if ($party eq 'rastriyaparivartandal') {$party = 'rpd'}
	    if ($party eq 'rastriyaprivartandal') {$party = 'rpd'}
	    if ($party eq 'rastriyasamanatadal') {$party = 'rsd'}
	    if ($party eq 'rastriyasuryaprakashparty') {$party = 'rspp'}
	    if ($party eq 'rastriyaviklangparty') {$party = 'rvlp'}
	    if ($party eq 'ravidasparty') {$party = 'rp'}
	    if ($party eq 'republicanpartyofindia-a') {$party = 'rpi-a'}
	    if ($party eq 'republicanpartyofindiaa') {$party = 'rpi-a'}
	    if ($party eq 'republicnpartyofindia') {$party = 'rpi'}
	    if ($party eq 'repubnlicanpartyofindia-democratic') {$party = 'rpi-d'}
	    if ($party eq 'rlokmanch') {$party = 'rlm'}
	    if ($party eq 'samajawadiparty') {$party = 'sp'}
	    if ($party eq 'samajvadiparty') {$party = 'sp'}
	    if ($party eq 'samajwadijanataparty-rashtriya') {$party = 'sjp-r'}
	    if ($party eq 'samajwadijanataparty-rastriya') {$party = 'sjp-r'}
	    if ($party eq 'samajwadijanparishad') {$party = 'sjp'}
	    if ($party eq 'samastbharatiyaparty') {$party = 'sbp'}
	    if ($party eq 'samastbhartiyaparty') {$party = 'sbp'}
	    if ($party eq 'samtasamajwadicongressparty') {$party = 'sscp'}
	    if ($party eq 'sarwajanmahasabha') {$party = 'sms'}
	    if ($party eq 'sdpoi') {$party = 'sdpi'}
	    if ($party eq 'shoshitsamajdal') {$party = 'ssd'}
	    if ($party eq 'shositsamajdal') {$party = 'ssd'}
	    if ($party eq 'smajwadiparty') {$party = 'sp'}
	    if ($party eq 'socialdemocraticpartyofindia') {$party = 'sdpi'}
	    if ($party eq 'socialistparty-india') {$party = 'spi'}
	    if ($party eq 'socialistpartyindia') {$party = 'spi'}
	    if ($party eq 'socialistunitycenterofindia-communist') {$party = 'suci-c'}
	    if ($party eq 'socialistunitycentreofindia-communist') {$party = 'suci-c'}
	    if ($party eq 'sociolistpartyindia') {$party = 'spi'}
	    if ($party eq 'socp-i') {$party = 'spi'}
	    if ($party eq 'sp-i') {$party = 'spi'}
	    if ($party eq 'suheildevbhartiyasamajparty') {$party = 'sdbsp'}
	    if ($party eq 'suheldeobhartiyasamajparty') {$party = 'sdbsp'}
	    if ($party eq 'suheldevbharatiyasamajparty') {$party = 'sdbsp'}
	    if ($party eq 'suheldevbhartiyasamajparty') {$party = 'sdbsp'}
	    if ($party eq 'swarahtrajanparty') {$party = 'swtp'}
	    if ($party eq 'swarajdal') {$party = 'swd'}
	    if ($party eq 'swarajparty-scbosh') {$party = 'swp-scb'}
	    if ($party eq 'vanchitjamatparty') {$party = 'vjp'}
	    if ($party eq 'vanchitsamaj') {$party = 'vs'}
	    if ($party eq 'vanchitsamajinsaafparty') {$party = 'vsip'}
	    if ($party eq 'vanchitsamajinsafparty') {$party = 'vsip'}
	    if ($party eq 'yuvavikashparty') {$party = 'ysp'}
	    if ($party eq 'yuvavikasparty') {$party = 'yvp'}
	    if ($party eq '') {$party = 'unknown'}
	    $parties{$party}=1;
	    $oldparty{$p}=$party;
	    $votes = shift (@columns);
	    $votes =~ s/\D//gs;
	}
	$out{$i}->{$party}=$votes;
    }
    $oldconst = $out{$i}->{'constituency_id'};
    $i++;
}

my @headers = ('constituency_id','constituency_name','constituency_reserved','booth_id','booth_name','electors','turnout_male','turnout_female','turnout_total',sort(keys(%parties)));

$csv->combine(@headers);
my @tempcsv = ($csv->string."\n");

foreach my $line (sort {$a <=> $b} (keys(%out))) {
    undef(my @line);
    push (@line, $out{$line}->{'constituency_id'});
    push (@line, $out{$line}->{'constituency_name'});
    push (@line, $out{$line}->{'constituency_reserved'});
    push (@line, $out{$line}->{'booth_id'});
    push (@line, $out{$line}->{'booth_name'});
    push (@line, $out{$line}->{'electors'});
    push (@line, $out{$line}->{'turnout_male'});
    push (@line, $out{$line}->{'turnout_female'});
    push (@line, $out{$line}->{'turnout_total'});
    foreach my $party (sort(keys(%parties))) { push (@line, $out{$line}->{$party}) }
    $csv->combine(@line);
    push (@tempcsv,$csv->string."\n");
}

#
# Now create temporary sqlite table structure
#

my $dbh = DBI->connect("dbi:SQLite:dbname=:memory:","","",{sqlite_unicode => 1});

$dbh->do ("CREATE TABLE upvidhansabha2012 (id INTEGER PRIMARY KEY)");

$dbh->do ("CREATE TABLE upid (ac_id_09 INTEGER)");

print "Adding 2012 Assembly results\n";

my $csv=Text::CSV->new();

$dbh->begin_work;

my $header=shift(@tempcsv);
chomp($header);
$csv->parse($header);
my @header=$csv->fields();
my @realheader=();

# $dbh->do ("ALTER TABLE upid ADD COLUMN ac_id_09 INTEGER");
$dbh->do ("ALTER TABLE upid ADD COLUMN ac_name_12 CHAR");
$dbh->do ("ALTER TABLE upid ADD COLUMN ac_reserved_12 CHAR");
$dbh->do ("ALTER TABLE upid ADD COLUMN booth_id_12 CHAR");
$dbh->do ("ALTER TABLE upid ADD COLUMN station_name_12 CHAR");

$dbh->do ("ALTER TABLE upvidhansabha2012 ADD COLUMN ac_id_09 INTEGER");
push(@realheader,'ac_id_09');
$dbh->do ("ALTER TABLE upvidhansabha2012 ADD COLUMN booth_id_12 CHAR");
push(@realheader,'booth_id_12');
$dbh->do ("ALTER TABLE upvidhansabha2012 ADD COLUMN electors_12 INTEGER");
push(@realheader,'electors_12');
$dbh->do ("ALTER TABLE upvidhansabha2012 ADD COLUMN turnout_12 INTEGER");
push(@realheader,'turnout_12');
$dbh->do ("ALTER TABLE upvidhansabha2012 ADD COLUMN turnout_percent_12 FLOAT");
push(@realheader,'turnout_percent_12');
$dbh->do ("ALTER TABLE upvidhansabha2012 ADD COLUMN male_votes_12 INTEGER");
push(@realheader,'male_votes_12');
$dbh->do ("ALTER TABLE upvidhansabha2012 ADD COLUMN female_votes_12 INTEGER");
push(@realheader,'female_votes_12');
$dbh->do ("ALTER TABLE upvidhansabha2012 ADD COLUMN female_votes_percent_12 FLOAT");
push(@realheader,'female_votes_percent_12');

foreach my $header (@header) {
    if ($header eq 'constituency_id' or $header eq 'constituency_name' or $header eq 'constituency_reserved' or $header eq 'booth_id' or $header eq 'booth_name' or $header eq 'electors' or $header eq 'turnout' or $header eq 'turnout_male' or $header eq 'turnout_female' or $header eq 'turnout_total' or $header !~ /\w/) {next}
    $header=~s/-/_/gs;
    my $statement="ALTER TABLE upvidhansabha2012 ADD COLUMN votes_".$header."_12 INTEGER";
    $dbh->do ($statement);
    push(@realheader,'votes_'.$header.'_12');
    my $statement="ALTER TABLE upvidhansabha2012 ADD COLUMN votes_".$header."_percent_12 FLOAT";
    $dbh->do ($statement);
    push(@realheader,'votes_'.$header.'_percent_12');
}

$dbh->commit;

#
# Fill table with 2012 results
#

$dbh->do ("CREATE INDEX ac_booth_id_12 ON upvidhansabha2012 (ac_id_09, booth_id_12)");

$dbh->begin_work;

my $oldstationname='';
my $oldconst = 0;
foreach my $line (@tempcsv) {
    chomp($line);
    
    $csv->parse($line);
    my @fields=$csv->fields();
    
    my $constituency_id = shift(@fields);
    next if $constituency_id !~ /\d/;
    if ($constituency_id != $oldconst) {print "  $constituency_id\n"; $oldconst = $constituency_id}
    my $constituency_name = shift(@fields);
    my $constituency_reserved = uc(shift(@fields));
    my $booth_id = shift (@fields);

    my $station_name = shift (@fields);
    $station_name =~ s/[1-9]//gs; # this is to enable easier integration later on - we are interested in station_name, not booth_name
    $station_name =~ s/^\d//gs;
    # remove identical substrings of words - to fetch at least some of the cases where this happens...
    $station_name =~s/^(.+) (.*) \1 /$1 $2 /gsi;
    $station_name =~s/ (.+) (.*) \1$/ $1 $2/gsi;
    $station_name =~s/^(.+) (.*) \1$/$1 $2/gsi;
    $station_name =~s/ (.+) (.*) \1 / $1 $2 /gsi;
    $station_name =~s/ (.+) (.*) \1 / $1 $2 /gsi;
    $station_name =~s/^(.+) \1 /$1 /gsi;
    $station_name =~s/ (.+) \1$/ $1/gsi;
    $station_name =~s/^(.+) \1$/$1/gsi;
    $station_name =~s/ (.+) \1 / $1 /gsi;
    $station_name =~s/ (.+) \1 / $1 /gsi;
    
    $station_name =~ s/^izk[ \-]ik[ \-]\]*/izk ik/gs; # unify "primary school"
    $station_name =~ s/^izk[ \-]fo[ \-]\]*/izk ik/gs;
    $station_name =~ s/^izkfo\|ky\;/izk ik/gs;
    $station_name =~ s/^izkikB\'kkyk/izk ik/gs;
    $station_name =~ s/^izk\s*ikB\'kkyk/izk ik/gs;
    $station_name =~ s/^izk\s*fo\|ky\;/izk ik/gs;
  
    my $temp = distance($oldstationname,$station_name);
    if ($temp <= 1 || $temp < length($station_name)/7.5) {$station_name = $oldstationname} else {$oldstationname = $station_name}
    
    my $electors = int(shift (@fields));
    my $male_votes = int(shift (@fields));
    my $female_votes = int(shift (@fields));
    my $turnout = shift (@fields); # $male_votes + $female_votes;
    if ($turnout == 0) {$turnout = $male_votes + $female_votes}
    my $turnout_percent = 0; if ($electors > 0) {$turnout_percent=int($turnout/$electors*10000)/100;}
    my $female_votes_percent = 0; if ($turnout > 0) {$female_votes_percent=int($female_votes/$turnout*10000)/100;}
    
    my @add=();
    foreach my $party (@fields) {
	push (@add,int($party));
	if ($turnout>0) {push (@add,int($party/$turnout*10000)/100);} else  {push (@add,0);}
   }
    
    $booth_id=~s/\D//gs; # this is to integrate polling booths spread across several rolls (110 and 110v etc)
    my $sth = $dbh->prepare("SELECT * FROM upvidhansabha2012 WHERE ac_id_09 = ? AND booth_id_12 = ?");
    $sth->execute($constituency_id, $booth_id);
    my $found=undef;
    while (my $row=$sth->fetchrow_hashref) {
	$found=1; 
	my $i=0;
	my $updateline = 'UPDATE upvidhansabha2012 SET '; my @updates = ();
	foreach my $header (@realheader) {
	    if ($header eq 'ac_id_09' or $header eq 'ac_name_12' or $header eq 'ac_reserved_12' or $header eq 'booth_id_12' or $header eq 'station_name_12') {next}
	    elsif ($header eq 'electors_12') {$updateline .=  " electors_12 = ?"; push(@updates, $electors + $row->{electors_12});next}
	    elsif ($header eq 'turnout_12') {$updateline .=  " , turnout_12 = ?"; push(@updates, $turnout + $row->{turnout_12});next}
	    elsif ($header eq 'turnout_percent_12' && ($row->{electors_12} > 0 || $electors > 0)) {$updateline .=  " , turnout_percent_12 = ?"; push(@updates, int(($turnout + $row->{turnout_12})/($electors + $row->{electors_12})*10000)/100);next}
	    elsif ($header eq 'male_votes_12') {$updateline .= " , male_votes_12 = ?"; push(@updates, $male_votes + $row->{male_votes_12});next}
	    elsif ($header eq 'female_votes_12') {$updateline .= " , female_votes_12 = ?"; push(@updates, $female_votes + $row->{female_votes_12});next}
	    elsif ($header eq 'female_votes_percent_12' && ($row->{turnout_12} > 0 || $turnout > 0)) {$updateline .= ", female_votes_percent_12 = ?"; push(@updates, int(($female_votes + $row->{female_votes_12})/($turnout + $row->{turnout_12})*10000)/100);next}
	    elsif ($header !~ /percent/) {$updateline .= ", $header = ?"; push(@updates, $add[$i] + $row->{$header});}
	    elsif (($row->{turnout_12} > 0 || $turnout > 0) and ($add[$i] + $row->{$header}) > 0) {$updateline .= " , $header = ?"; push(@updates, int(($add[$i]*$turnout/100 + $row->{$header}*$row->{turnout_12}/100)/($turnout + $row->{turnout_12})*10000)/100);}
	    $i++;
	}
	$updateline .= ' WHERE ac_id_09 = ? AND booth_id_12 = ?';
	push (@updates, $row->{ac_id_09}); push(@updates, $row->{booth_id_12});
	$dbh->do ($updateline,undef,@updates);
    }

    if ($found != 1) {$dbh->do ("INSERT INTO upvidhansabha2012 (".join(',',@realheader).") VALUES (".join(',',('?') x scalar(@realheader)).")",undef, $constituency_id, $booth_id, $electors, $turnout, $turnout_percent, $male_voters, $female_voters, $female_voters_percent, @add);}
    
    if ($found != 1) {$dbh->do ("INSERT INTO upid (ac_id_09, ac_name_12, ac_reserved_12, booth_id_12, station_name_12) VALUES (?,?,?,?,?)",undef, $constituency_id, $constituency_name, $constituency_reserved, $booth_id, $station_name);}

}

$dbh->commit;

#
# Add station_id and station_name
#

$dbh->do ("ALTER TABLE upid ADD COLUMN station_id_12 INTEGER");

# $dbh->do ("CREATE INDEX ac_id_09 ON upid (ac_id_09)");
$dbh->do ("CREATE INDEX booth_id_12 ON upid (booth_id_12)");

my $sth = $dbh->prepare("SELECT ac_id_09 FROM upid WHERE ac_id_09 IS NOT NULL GROUP BY ac_id_09");
$sth->execute();
my $count=0;
my %result;
while (my $row=$sth->fetchrow_hashref) {
    my $tempold='';
    my $sth2 = $dbh->prepare("SELECT station_name_12 FROM upid WHERE ac_id_09 = ?");
    $sth2->execute($row->{ac_id_09});
    while (my $row2=$sth2->fetchrow_hashref) {
	my $temp=$row2->{station_name_12};
	$temp=~s/\d//gs;
	next if ($temp eq $tempold);
	$tempold = $temp;
	$result{$row->{ac_id_09}.$temp}=$count;
	$count++;
    }
}
$sth->finish ();

$dbh->begin_work;

my $sth = $dbh->prepare("SELECT * FROM upid WHERE ac_id_09 IS NOT NULL");
$sth->execute();
while (my $row=$sth->fetchrow_hashref) {
    my $temp=$row->{station_name_12};
    $temp=~s/\d//gs;
    $dbh->do ("UPDATE upid SET station_id_12 = ? WHERE ac_id_09 = ? AND booth_id_12 = ?", undef, $result{$row->{ac_id_09}.$temp}, $row->{ac_id_09}, $row->{booth_id_12});
}
$sth->finish ();

$dbh->commit;

$dbh->do ("CREATE INDEX station_id_12 ON upid (station_id_12)");

#
# Finally create sqlite dump 
#

$dbh->sqlite_backup_to_file("temp.sqlite");

system("sqlite3 temp.sqlite '.dump upvidhansabha2012' > upvidhansabha2012-a.sql");


open (FILE, ">>upvidhansabha2012-a.sql");

print FILE ".mode csv\n";
print FILE ".headers on\n";
print FILE ".once upvidhansabha2012/upvidhansabha2012-a.csv\n";
print FILE "SELECT * FROM upvidhansabha2012 LIMIT 40000;\n";
print FILE ".once upvidhansabha2012/upvidhansabha2012-b.csv\n";
print FILE "SELECT * FROM upvidhansabha2012 LIMIT 40000 OFFSET 40000;\n";
print FILE ".once upvidhansabha2012/upvidhansabha2012-c.csv\n";
print FILE "SELECT * FROM upvidhansabha2012 LIMIT -1 OFFSET 80000;\n";

close (FILE);

system("split -l 40000 upvidhansabha2012-a.sql");
system("mv xaa upvidhansabha2012-a.sql");
system("echo 'COMMIT;' >> upvidhansabha2012-a.sql");
system("echo 'BEGIN TRANSACTION;' > upvidhansabha2012-b.sql");
system("cat xab >> upvidhansabha2012-b.sql");
system("echo 'COMMIT;' >> upvidhansabha2012-b.sql");
system("rm xab");
system("echo 'BEGIN TRANSACTION;' > upvidhansabha2012-c.sql");
system("cat xac >> upvidhansabha2012-c.sql");
system("echo 'COMMIT;' >> upvidhansabha2012-c.sql");
system("rm xac");
system("echo 'BEGIN TRANSACTION;' > upvidhansabha2012-d.sql");
system("cat xad >> upvidhansabha2012-d.sql");
system("rm xad");

system("sqlite3 temp.sqlite '.dump upid' > upvidhansabha2012-e.sql");

open (FILE, "upvidhansabha2012-e.sql");
my @file = <FILE>;
close (FILE);

open (FILE, ">upvidhansabha2012-e.sql");

# print FILE "ALTER TABLE upid ADD COLUMN ac_id_09 INTEGER;\n";
print FILE "ALTER TABLE upid ADD COLUMN ac_name_12 CHAR;\n";
print FILE "ALTER TABLE upid ADD COLUMN ac_reserved_12 CHAR;\n";
print FILE "ALTER TABLE upid ADD COLUMN booth_id_12 CHAR;\n";
print FILE "ALTER TABLE upid ADD COLUMN station_name_12 CHAR;\n";
print FILE "ALTER TABLE upid ADD COLUMN station_id_12 INTEGER;\n";

my $insert;
foreach my $line (@file) {
    if ($line =~ /^CREATE TABLE upid (.*?);/) {$insert=$1;$insert=~s/ CHAR//gs; $insert=~s/ INTEGER//gs; next}
    if ($line =~ /^INSERT INTO \"upid\"/) {$line =~ s/^INSERT INTO \"upid\"/INSERT INTO \"upid\" $insert/}
    print FILE $line;
}

close (FILE);

system("rm -f temp.sqlite");
