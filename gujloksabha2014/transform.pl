#!/usr/bin/perl

use WWW::Mechanize;
use DBD::SQLite;
use Text::CSV;

system("cp actopc.sqlite results.sqlite");

$dbh = DBI->connect("DBI:SQLite:dbname=results.sqlite", "","", {sqlite_unicode=>1});
$dbh->do ("CREATE TABLE results (pc INTEGER, ac INTEGER, booth INTEGER, candidate CHAR, votes INTEGER)");
$dbh->do ("CREATE TABLE candidates (id INTEGER PRIMARY KEY AUTOINCREMENT, pc INTEGER, rank INTEGER, name CHAR, party CHAR, shortparty CHAR)");

# first read candidate list prepared by Dilip Damle

my $csv = Text::CSV->new();

open (CSV,"Political_parties.csv");
my @csv=<CSV>;
close (CSV);

my $header=shift(@csv);

my %party;
foreach my $line (@csv) {
    $csv->parse($line);
    my @fields=$csv->fields();
    $party{$fields[0]}=$fields[1];
}

my $csv = Text::CSV->new();

open (CSV,"Candidates.csv");
my @csv=<CSV>;
close (CSV);

my $header=shift(@csv);

foreach my $line (@csv) {
    $csv->parse($line);
    my @fields=$csv->fields();
    $fields[0] =~ /(...)PC(\d+)CA(\d+)/gs;
    my $state=$1; my $pc=$2/1; my $rank=$3/1;
    next if $state ne 'S06';
    next if $fields[1] =~ /none of the above/i;
    $dbh->do ("INSERT INTO candidates (pc,rank,name,party) VALUES (?,?,?,?)",undef,$pc,$rank,$fields[1],$party{$fields[2]});
}

# then read actual form20 results

undef(my %print); undef(my %troubleac);

$dbh->begin_work;

# iterate through PCs
for ($pc=1;$pc<=26;$pc++) {

    $dbh->do ("INSERT INTO candidates (pc,party) VALUES (?,?)",undef,$pc,'valid');
    $dbh->do ("INSERT INTO candidates (pc,party) VALUES (?,?)",undef,$pc,'rejected');
    $dbh->do ("INSERT INTO candidates (pc,party) VALUES (?,?)",undef,$pc,'nota');
    $dbh->do ("INSERT INTO candidates (pc,party) VALUES (?,?)",undef,$pc,'total');
    $dbh->do ("INSERT INTO candidates (pc,party) VALUES (?,?)",undef,$pc,'tendered');
    
    my $ref = $dbh->selectcol_arrayref("SELECT ac FROM actopc WHERE state_name = 'Gujarat' AND pc = ?",undef,$pc);

    # iterate through relevant ACs
    foreach my $ac (@$ref) {
		
	my $code=$ac;
	if ($code<10) {$code="00$code"}
	elsif ($code<100) {$code="0$code"}
	
	# generate CSV file if not yet there
	if (!-e "AC$code.csv") {
	    
	    my $pagecount=`gs -q -dNODISPLAY -c "(AC$code.PDF) (r) file runpdfbegin pdfpagecount = quit" `;
	    chomp($pagecount);
	    
	    undef(my @csv);
	    for ($page=1;$page<=$pagecount;$page++) {
		if (!-e "AC$code.$page.csv") {system("pdf-table-extract -r 300 -p $page -i AC$code.PDF -o AC$code.$page.csv -t table_csv");}
		
		open (CSV,"AC$code.$page.csv");
		my @temp = <CSV>;
		push (@csv,@temp);
		close (CSV);
		
		system("rm -f AC$code.$page.csv");
	    }
	    
	    $toggle=0; my $checkit=0;
	    open (CSV,">AC$code.csv");
	    undef(my %line);
	    foreach my $line (@csv) {
		next if $line =~ /^\,+\n$/;
		next if $line =~ /annexure/i;
		next if $line =~ /^[, ]*page/i;
		next if $line =~ /^[, ]*form.20/i;
		next if defined($line{$line});
		$line{$line}=1;
		print CSV $line;
	    }
	    close (CSV);
	
	}

	my $csv = Text::CSV->new({binary=>1});
	
	# read in CSV file, prepare stuff
	open (CSV,"AC$code.csv");
	my @csv = <CSV>;
	close (CSV);

	undef(my %cand);
	undef(my $pscol);
	my $toggle=0;
	
	# iterate through CSV file
	foreach my $line (@csv) {
	    
	    if ($toggle == 0) { # filter garbage and register general names
		if ($line =~ /Polling St/gsi) {
		    $toggle=1; 
		    $csv->parse($line);
		    my @fields=$csv->fields();
		    for ($i=0;$i<scalar(@fields);$i++) {if ($fields[$i] ne '') {if (!defined($cand{$i})) {$cand{$i}=$fields[$i]}}}
		}
	    } elsif ($toggle == 1) { # read in candidate names
		$toggle=2; 
		$csv->parse($line);
		my @fields=$csv->fields();
		if ($fields[0] =~ /\d/ and $fields[0] !~ /\D/ and $fields[0] ne '') {push (@csv,$line)}
		else {for ($i=0;$i<scalar(@fields);$i++) {if ($fields[$i] ne '') {$cand{$i}=$fields[$i]}}}		
		
		if ($ac==10) {
		    $cand{1}='Chaudhary Haribhai Parthibhai';
		    $cand{2}='Patel Joitabhai Kasnabhai';
		    $cand{3}='Mahant Parsotamgiri Turantgiri';
		    $cand{4}='Choudhary Adambhai Nasirbhai';
		    $cand{5}='Sanjaykumar Somnathbhai Raval';
		    $cand{6}='Gamar Vadhabhai Radhabhai';
		    $cand{7}='Thakor Bhupataji Ravaji';
		    $cand{8}='Dabhi Navajibhai Madhabhai';
		    $cand{9}='Babaji Thakor';
		    $cand{10}='Mahendrabhai Kesarabhai Bumbadia';
		    $cand{11}='Madhu Nirupaben Natvarlal';
		    $cand{12}='Shrimali Ashokbhai Balchndbhai';
		    $cand{13}='Solanki Dineshkumar Aljibhai';
		    $cand{14}='Solanki Saybabhai Nanabhai';
		} elsif ($ac==58) {
		    $cand{1}='CHAUHAN DEVUSINH JESINGBHAI';
		    $cand{2}='DINSHA PATEL';
		    $cand{3}='PANDAV BHAILALBHAI KALUBHAI';
		    $cand{4}='ABDUL RAZAKKHAN PATHAN';
		    $cand{5}='BADHIWALA LABHUBHAI JIVRAJBHAI';
		    $cand{6}='RANVEER PRANAYRAJ GOVINDBHAI';
		    $cand{7}='KHRISTI ADWARD KHUSHALBHAI';
		    $cand{8}='CHAUHAN DEVUSING MOTISHING';
		    $cand{9}='PATHAN AMANULLAKHA SITABKHA';
		    $cand{10}='PARIKH VIRAL HASMUKHBHAI';
		    $cand{11}='MALEK YAKUBMIYA NABIMIYA';
		    $cand{12}='MALEK SADIK HUSHEN MAHAMMD HUSHEN';
		    $cand{13}='MALEK SABIRHUSEN ISMAELBHAI';
		    $cand{14}='RATANSINH UDESINH CHAUHAN';
		    $cand{15}='ROSHAN PRIYAVADAN SHAH';
		} elsif ($ac==81) {
		    $cand{1}='AHIR VIKRAMBHAI ARJANBHAI MADAM';
		    $cand{2}='POONAMBEN HEMATBHAI MAADAM';
		    $cand{3}='SAMA YUSUF';
		    $cand{4}='KASAMBHAI';
		    $cand{5}='JHALA RAJENDRASINH';
		    $cand{6}='SAIYAD ABUBAKAR IBRAHIM';
		    $cand{7}='CHANDRAVIJAYSINH TAKHUBHA RANA';
		    $cand{8}='DALIT ASHOK NATHABHAI CHAVDA';
		    $cand{9}='DALIT JITESH BABUBHAI RATHORE';
		    $cand{10}='DHANJIBHAI LALJIBHAI RANEVADIA';
		    $cand{11}='DHARAVIYA VALLABHBHAI';
		    $cand{12}='NARIYA PRAVINBHAI VALLABHBHAI';
		    $cand{13}='PADHIYAR LALJIBHAI KARABHAI';
		    $cand{14}='PANDYA CHIRAGBHAI HARIOMBHAI';
		    $cand{15}='BATHWAR NANJIBHAI';
		    $cand{16}='MAMAD HAJI BOLIM';
		    $cand{17}='MEMAN RAFIK ABUBAKAR POPATPUTRA';
		    $cand{18}='VAGHER ALI ISHAK PALANI';
		    $cand{19}='VAGHER JAVIDBHAI OSMANBHAI NOLE';
		    $cand{20}='VANIYA GANGAJIBHAI';
		    $cand{21}='SACHADA HABIB ISHABHAI';
		    $cand{22}='SUTHAR HANSABEN HARSUKHBHAI GORECHA';
		    $cand{23}='SUMARA AMANDBHAI NOORMAMADBHAI SUMARA';
		    $cand{24}='SODHA SALIMBHAI NURMAMADBHAI';
		    $cand{25}='SANDHI MAMADBHAI HAJIBHAI SAFIA';
		} elsif ($ac==106) {
		    $cand{1}='GITA CHETAN PAUNDA (ADVOCATE GITABA JADEJA)';
		    $cand{2}='DR. BHARATIBEN DHIRUBHAI SHIYAL';
		    $cand{3}='RATHOD PRAVINBHAI JINABHAI';
		    $cand{4}='DR. KANUBHAI V. KALSARIA';
		    $cand{5}='KAGADA RAMESHBHAI PUNABHAI';
		    $cand{6}='KHADRANI ASIMBHAI PIRBHAI';
		    $cand{7}='GOHIL PRAVINSINH DHIRUBHA';
		    $cand{8}='GOHEL BHARATBHAI BHIMABHAI';
		    $cand{9}='JAGADISHBHAI AMARABHAI VEGAD';
		    $cand{10}='BHAVES GHANSHYAMBHAI RAJYAGURU';
		    $cand{11}='MEHTA YASHVANTRAY ODHAVJIBHAI';
		    $cand{12}='MARU MANHAR VALAJIBHAI';
		    $cand{13}='RASIDKHAN HASANKHAN PATHAN';
		    $cand{14}='RATHOD PRAVINSINH CHANDRASINH';
		    $cand{15}='VAGHELA NARENDRABHAI SHAVJIBHAI';
		    $cand{16}='VEGAD NATHABHAI';
		} elsif ($ac==144) {
		    $cand{1}='NARENDRA MODI';
		    $cand{2}='MISTRI MADHUSUDAN DEVRAM';
		    $cand{3}='ROHIT MADHUSUDAN MOHANBHAI';
		    $cand{4}='JADAV AMBALAL KANABHAI';
		    $cand{5}='TAPAN DASGUPTA';
		    $cand{6}='PATHAN MAHEMUDKHAN RAZAKKHAN';
		    $cand{7}='PATHAN SAHEBKHAN ASIFKHAN';
		    $cand{8}='SUNIL DIGAMBAR KULKARNI';
		}
		
		key: foreach my $key (sort(keys(%cand))) {
		    $cand{$key} =~ s/\s*\(.*//gs;
		    $cand{$key} =~ s/[^A-Za-z\.\(\) ]/ /gs;
		    $cand{$key} =~ s/\s+/ /gs;
		    $cand{$key} =~ s/\s+$//gs;
		    $cand{$key} =~ s/^\s+//gs;
		    
		    if ($cand{$key} eq 'Valid' or $cand{$key} =~ /valied votes/i or $cand{$key} =~ /valid\s* votes/i or $cand{$key} eq 'valid' or $cand{$key} =~ /total\s* of\s* valid/i) {$cand{$key}='valid'}
		    elsif ($cand{$key} =~ /rejected/i or $cand{$key} =~ /rejecte d vote/i or $cand{$key} eq 'No. of Reject votes' or $cand{$key} eq 'No. of reje cted votes' or $cand{$key} eq 'reje cted votes' or $cand{$key} eq 'Total of Reject - ed Votes' or $cand{$key} =~ /rejec\s*t\s*e\s*d vote/i or $cand{$key} =~ /rejected\/ missing/ or $cand{$key} eq 'rejected' ) {$cand{$key}='rejected'}
		    elsif ($cand{$key} =~ /[\'\" ]N\s*O\s*T\s*A[\'\" ]/i or $cand{$key} eq 'N O T A' or $cand{$key} eq 'O T A' or $cand{$key} eq 'NOTA 5' or $cand{$key} eq 'NOTA' or $cand{$key} eq 'Nota' or $cand{$key} =~ /none\s* of\s* the\s* above/i  or $cand{$key} eq 'nota' or $cand{$key} eq 'NOTA') {$cand{$key}='nota'}
		    elsif ($cand{$key} =~ /^Total$/i or $cand{$key} =~ /Total\s* vote/i or $cand{$key} eq 'total' ) {$cand{$key}='total'}
		    elsif ($cand{$key} =~ /tender votes/i or $cand{$key} =~ /tendered\s* vo/i or $cand{$key} =~ /tende red vote/i or $cand{$key} =~ /tendere d vote/i or $cand{$key} eq 'No. of tende red votes' or $cand{$key} eq 'No.of tender votes' or $cand{$key} eq 'No of Tender- ed Votes' or $cand{$key} =~ /tenderd vote/i or $cand{$key} eq 'tende red votes' or $cand{$key} =~ /tende\s*r ed vote/i or $cand{$key} =~ /Tendere d vote/i or $cand{$key} eq 'tendered' or $cand{$key} =~ /tendred votes/i) {$cand{$key}='tendered'}
		    elsif (!defined($pscol) and ($cand{$key} eq 'No. of P.S.' or $cand{$key} =~ /polling st/i or $cand{$key} eq 'Station')) {$pscol=$key;undef($cand{$key})}
		    elsif ($cand{$key} eq '' or $cand{$key} !~ /\D/ or $cand{$key} eq 'Name' or $cand{$key} eq 'NAME' or $cand{$key} eq 'o.' or $cand{$key} eq '03-BHUJ' or ($ac==40 and $key==27) or $cand{$key} =~ /Sr\s*No\./i or $cand{$key} =~ /Sr\.\s*No/i or $cand{$key} eq 'Table No.' or $cand{$key} =~ /1E\+\d+/ or $cand{$key} =~ /returning officer/i or $cand{$key} !~ /\D/ or $cand{$key} =~ /test votes/i) {undef($cand{$key})}
		    else {
			if ($pc==4 && $cand{$key} eq 'Thakor Samaratji Balavantsinh') {$cand{$key}='THAKOR SAMARATJI BALVANTSINH'}
			elsif ($pc==4 && $cand{$key} eq 'Smt. Vandanaben Dineshkumar Patel') {$cand{$key}='SMT VANDANABEN DINESHKUMAR PATEL'}
			elsif ($pc==6 && $cand{$key} eq 'M. K.Shah') {$cand{$key}='M. K. SHAH'}
			elsif ($pc==7 && $cand{$key} eq 'Khalifa Samsuddin Nasirudding') {$cand{$key}='KHALIFA SAMSUDDIN NASIRUDDIN (JUGNU)'}
			elsif ($pc==7 && $cand{$key} eq 'Dutt Aakash - Advocate') {$cand{$key}='DUTT AAKASH -. ADVOCATE'}
			elsif ($pc==9 && $cand{$key} eq 'PARMARVASHARAMBHAI BAVALBHAI') {$cand{$key}='PARMAR VASHARAMBHAI BAVALBHAI'}
			elsif ($pc==9 && $cand{$key} eq 'MAKWANA UKABHAI AMRATBHAI') {$cand{$key}='MAKWANA UKABHAI AMRABHAI'}
			elsif ($pc==9 && $cand{$key} eq 'ZALA MANSINH SHIVUBHA') {$cand{$key}='MANSINH SHIVUBHA ZALA'}
			elsif ($pc==9 && $cand{$key} eq 'VAGEHLA PRAKASHBHAI BACHUBHAI') {$cand{$key}='VAGHELA PRAKASHBHAI BACHUBHAI'}
			elsif ($pc==9 && $cand{$key} eq 'VORA BHAVABHAI DEVABHAI') {$cand{$key}='VORA BHAVANBHAI DEVAJIBHAI'}
			elsif ($pc==9 && $cand{$key} eq 'FATEPARA DEVJIBHAI GOVINDBHAI') {$cand{$key}='FATEPARA DEVAJIBHAI GOVINDBHAI'}
			elsif ($pc==9 && $cand{$key} eq 'PATEL JETHABHAI MANJIBHAI') {$cand{$key}='JETHABHAI MANJIBHAI PATEL'}
			elsif ($pc==9 && $cand{$key} eq 'CHAVADA PALABHAI NANJIBHAI') {$cand{$key}='CHAVDA PALABHAI NANJIBHAI'}
			elsif ($pc==9 && $cand{$key} eq 'PARMAR PARBHUBHAI GOKABHAI') {$cand{$key}='PARMAR PRABHUBHAI GOKALBHAI'}
			elsif ($pc==7 && $cand{$key} eq 'Naranbhai T. Sengal') {$cand{$key}='NARANBHAI T. SENGAL (DR. N. T. SENGAL)'}
			elsif ($pc==14 && $cand{$key} eq 'THUMMAR VIRJIBHAI KESHAVBHAI') {$cand{$key}='THUMMAR VIRJIBHAI KESHAVBHAI (VIRJIBHAI THUMMAR)'}
			elsif ($pc==16 && $cand{$key} eq 'Patel Naineshkuma r Umedbhai') {$cand{$key}='PATEL NAINESHKUMAR UMEDBHAI'}
			elsif ($pc==16 && $cand{$key} eq 'Vahora Firojbhai Walimahamad bhai') {$cand{$key}='VAHORA FIROJBHAI WALIMAHAMADBHAI (KASORWALA)'}
			elsif ($pc==16 && $cand{$key} eq 'Vaghela Bharat P') {$cand{$key}='VAGHELA BHARAT P.'}
			elsif ($pc==16 && $cand{$key} eq 'Purshottambhai Alias Kanubhai Mathurbhai Chauhan') {$cand{$key}='PURSOTTAMBHAI ALIAS KANUBHAI MATHURBHAI CHAUHAN'}
			elsif ($pc==16 && $cand{$key} eq 'Girishbhai Das') {$cand{$key}='GIRISHBHAI DAS (ADVOCATE)'}
			elsif ($pc==16 && $cand{$key} eq 'Padhiyar Vikramsinh') {$cand{$key}='PADHIYAR VIKRAMSINH (VAKIL)'}
			elsif ($pc==16 && $cand{$key} eq 'Ravjibhai S Parmar') {$cand{$key}='RAVJIBHAI S. PARMAR'}
			elsif ($pc==17 && $cand{$key} eq 'Parikh Viral Hasmukhbh ai') {$cand{$key}='PARIKH VIRAL HASMUKHBHAI'}
			elsif ($pc==17 && $cand{$key} eq 'Roshan Priyavada n Shah') {$cand{$key}='ROSHAN PRIYAVADAN SHAH'}
			elsif ($pc==17 && $cand{$key} eq 'Abdul Razakkha n Pathan') {$cand{$key}='ABDUL RAZAKKHAN PATHAN'}
			elsif ($pc==17 && $cand{$key} eq 'Khristi Adward Khushalbh ai') {$cand{$key}='KHRISTI ADWARD KHUSHALBHAI'}
			elsif ($pc==3 && $cand{$key} eq 'Rathod Bhavsinhbhai Dahyabha') {$cand{$key}='RATHOD BHAVSINHBHAI DAHYABHAI'}
			elsif ($pc==4 && $cand{$key} eq 'Patel Vandanaben Dineshbhai') {$cand{$key}='SMT VANDANABEN DINESHKUMAR PATEL'}
			elsif ($pc==4 && $cand{$key} eq 'Pathan Mahmad Azam Haidarkhan') {$cand{$key}='MAHMAD AZAM HAIDERKHAN PATHAN'}
			elsif ($pc==4 && $cand{$key} eq 'Dabhi Girishji Jenaji') {$cand{$key}='GIRISHJI JENAJI DABHI'}
			elsif ($pc==7 && $cand{$key} eq 'VIJAYKUMAR M VADHER') {$cand{$key}='VIJAYKUMAR M. VADHEL'}
			elsif ($pc==7 && $cand{$key} eq 'Khalifa Samsuddin Nasiruddin') {$cand{$key}='KHALIFA SAMSUDDIN NASIRUDDIN (JUGNU)'}
			elsif ($pc==8 && $cand{$key} eq 'Solanki Vithalbhai Maganbhai') {$cand{$key}='SOLANKI VITTHALBHAI MAGANBHAI'}
			elsif ($pc==7 && $cand{$key} eq 'ANIL KUMAR SHARMA') {$cand{$key}='ANILKUMAR SHARMA'}
			elsif ($pc==8 && $cand{$key} eq 'Dr. J G Parmar') {$cand{$key}='DR J. G. PARMAR'}
			elsif ($pc==9 && $cand{$key} eq 'Parmar Vashrambhai Bavalbhai') {$cand{$key}='PARMAR VASHARAMBHAI BAVALBHAI'}
			elsif ($pc==9 && $cand{$key} eq 'Makvana Ukabhai Amrabhai') {$cand{$key}='MAKWANA UKABHAI AMRABHAI'}
			elsif ($pc==7 && $cand{$key} eq 'DASHRATHBHAI M DEVDA') {$cand{$key}='DASHRATHBHAI M. DEVDA'}
			elsif ($pc==8 && $cand{$key} eq 'J J Mevada') {$cand{$key}='J. J. MEVADA'}
			elsif ($pc==9 && $cand{$key} eq 'Vora Bhavanbhai Devjibhai') {$cand{$key}='VORA BHAVANBHAI DEVAJIBHAI'}
			elsif ($pc==9 && $cand{$key} eq 'Makvana Vashrambhai Karshanbhai') {$cand{$key}='MAKWANA VASHARAMBHAI KARSHANBHAI'}
			elsif ($pc==9 && $cand{$key} eq 'CHAVDA PALABHAI NANAJIBHAI') {$cand{$key}='CHAVDA PALABHAI NANJIBHAI'}
			elsif ($pc==11 && $cand{$key} eq 'Tukadiya G.R.') {$cand{$key}='TUKADIA G. R.'}
			elsif ($pc==11 && $cand{$key} eq 'Rathod Chandulal Mohanbhai') {$cand{$key}='RATHOD CHANDULAL MOHANLAL'}
			elsif ($pc==7 && $cand{$key} eq 'ROSHAN PRIYVADAN SHAH') {$cand{$key}='ROSHAN PRIYAVADAN SHAH'}
			elsif ($pc==7 && $cand{$key} eq 'NARANBHAI T SENGAL') {$cand{$key}='NARANBHAI T. SENGAL (DR. N. T. SENGAL)'}
			elsif ($pc==7 && $cand{$key} eq 'BUDDHPRIYA JASHVANT SOMABHAI') {$cand{$key}='BUDDHPRIYA JASVANT SOMABHAI'}
			elsif ($pc==7 && $cand{$key} eq 'PARESH RAVAL') {$cand{$key}='PARESH RAWAL'}
			elsif ($pc==7 && $cand{$key} eq 'KHALIFA SAMSUDDIN NASIRUDDIN') {$cand{$key}='KHALIFA SAMSUDDIN NASIRUDDIN (JUGNU)'}
			elsif ($pc==7 && $cand{$key} eq 'ROHIT RAJUBHAI VIRJIBHAI URF MANOJ SONTARIYA') {$cand{$key}='ROHIT RAJUBHAI VIRJIBHAI ALIAS MANOJBHAI SONTARIYA'}
			elsif ($pc==7 && $cand{$key} eq 'DATT AKASH ADVOCATE') {$cand{$key}='DUTT AAKASH -. ADVOCATE'}
			elsif ($pc==9 && $cand{$key} eq 'Bar Ajmalbhai Karmanbhai') {$cand{$key}='BAR AJAMALBHAI KARMANBHAI'}
			elsif ($pc==9 && $cand{$key} eq 'Vadliya Kalubhai Malubhai') {$cand{$key}='VADALIYA KALUBHAI MALUBHAI'}
			elsif ($pc==9 && $cand{$key} eq 'Majethiya Samratbhai Jerambhai') {$cand{$key}='MAJETHIYA SAMARATBHAI JERAMBHAI'}
			elsif ($pc==9 && $cand{$key} eq 'Chavda Palabhai Nanajibhai') {$cand{$key}='CHAVDA PALABHAI NANJIBHAI'}
			elsif ($pc==9 && $cand{$key} eq 'Fatepara Devjibhai Govindbhai') {$cand{$key}='FATEPARA DEVAJIBHAI GOVINDBHAI'}
			elsif ($pc==9 && $cand{$key} eq 'Makvana Vasharambhai Karshanbhai') {$cand{$key}='MAKWANA VASHARAMBHAI KARSHANBHAI'}
			elsif ($pc==9 && $cand{$key} eq 'Sapra Vipulbhai Rameshbhai') {$cand{$key}='SAPARA VIPULBHAI RAMESHBHAI'}
			elsif ($pc==9 && $cand{$key} eq 'Parmar Prabhubhai Gokalbha') {$cand{$key}='PARMAR PRABHUBHAI GOKALBHAI'}
			elsif ($pc==11 && $cand{$key} eq 'Sadiya Vrajlal Pababhai') {$cand{$key}='SADIYA VRAJALAL PABABHAI'}
			elsif ($pc==11 && $cand{$key} eq 'Vakil Vinzuda Ranjit Naranbh ai') {$cand{$key}='VAKIL VINZUDA RANJITBHAI NARANBHAI'}
			elsif ($pc==11 && $cand{$key} eq 'Irfanshah Habibshah Suhravardi') {$cand{$key}='IRFANSHAH HABIBSHAH SUHARAVARDI'}
			elsif ($pc==11 && $cand{$key} eq 'Vakil Vinzuda Ranjit Naranbhai') {$cand{$key}='VAKIL VINZUDA RANJITBHAI NARANBHAI'}
			elsif ($pc==11 && $cand{$key} eq 'Mansukh Sundarji Dhokai') {$cand{$key}='MANSUKH SUNDARAJI DHOKAI'}
			elsif ($pc==11 && $cand{$key} eq 'Irafanshah Habibshah Suhravardi') {$cand{$key}='IRFANSHAH HABIBSHAH SUHARAVARDI'}
			elsif ($pc==11 && $cand{$key} eq 'Unadakat Prakash Vallabhada s') {$cand{$key}='UNADAKAT PRAKASH VALLABHADAS'}
			elsif ($pc==11 && $cand{$key} eq 'Tukadia G.R.') {$cand{$key}='TUKADIA G. R.'}
			elsif ($pc==11 && $cand{$key} eq 'Vakil Vinzuda Ranjit Narambhai') {$cand{$key}='VAKIL VINZUDA RANJITBHAI NARANBHAI'}
			elsif ($pc==11 && $cand{$key} eq 'Radadiya Vitthalbhai Hansarajbhai') {$cand{$key}='RADADIYA VITHALBHAI HANSRAJBHAI'}
			elsif ($pc==13 && $cand{$key} eq 'Atul Govindbhai Shekhda') {$cand{$key}='ATUL GOVINDBHAI SHEKHADA'}
			elsif ($pc==13 && $cand{$key} eq 'Harilal Ranchhodb hai Chauhan') {$cand{$key}='HARILAL RANCHHODBHAI CHAUHAN'}
			elsif ($pc==13 && $cand{$key} eq 'Saiyad Altafhusen Abdulahmiya') {$cand{$key}='SAIYED ALTAF HUSAIN ABDULLAH MIYAN'}
			elsif ($pc==13 && $cand{$key} eq 'Kadri Ibrahim saiyad Husen') {$cand{$key}='KADRI IBRAHIM SAIYED HUSEN'}
			elsif ($pc==13 && $cand{$key} eq 'Gadhiya Soyeb Hushenbha i') {$cand{$key}='GADHIYA SOYEB HUSHENBHAI'}
			elsif ($pc==13 && $cand{$key} eq 'Gadhiya Soyeb Husenbhai') {$cand{$key}='GADHIYA SOYEB HUSHENBHAI'}
			elsif ($pc==13 && $cand{$key} eq 'Punjabhai Bhimabhai Vainsh') {$cand{$key}='PUNJABHAI BHIMABHAI VANSH'}
			elsif ($pc==15 && $cand{$key} eq 'MEHTA YASHVA NT RAY ODHAVJI BHAI') {$cand{$key}='MEHTA YASHVANTRAY ODHAVJIBHAI'}
			elsif ($pc==15 && $cand{$key} eq 'Vegad Nathabhai') {$cand{$key}='VEGAD NATHABHAI (VEGADBHAI PRAGNACHAKSHU CANDIDATE)'}
			elsif ($pc==15 && $cand{$key} eq 'Rathod Pravin sinh Chandra sinh') {$cand{$key}='RATHOD PRAVINSINH CHANDRASINH'}
			elsif ($pc==15 && $cand{$key} eq 'RATHOD PRAVIN BHAI JINABHAI') {$cand{$key}='RATHOD PRAVINBHAI JINABHAI'}
			elsif ($pc==15 && $cand{$key} eq 'MARU MANHAR VALJI BHAI') {$cand{$key}='MARU MANHAR VALAJIBHAI'}
			elsif ($pc==15 && $cand{$key} eq 'JAGDISH BHAI AMARA BHAI VEGAD') {$cand{$key}='JAGADISHBHAI AMARABHAI VEGAD'}
			elsif ($pc==15 && $cand{$key} eq 'DR. BHARATI BEN DHIRU BAHI SHIYAL') {$cand{$key}='DR. BHARATIBEN DHIRUBHAI SHIYAL'}
			elsif ($pc==15 && $cand{$key} eq 'VEGAD NATHA BHAI') {$cand{$key}='VEGAD NATHABHAI (VEGADBHAI PRAGNACHAKSHU CANDIDATE)'}
			elsif ($pc==15 && $cand{$key} eq 'Maru Manhar Valjibhai') {$cand{$key}='MARU MANHAR VALAJIBHAI'}
			elsif ($pc==15 && $cand{$key} eq 'BHAVES GHANSHYAM BHAI RAJYAGURU') {$cand{$key}='BHAVES GHANSHYAMBHAI RAJYAGURU'}
			elsif ($pc==15 && $cand{$key} eq 'MEHTA YASHVANT RAY ODHAVJI BHAI') {$cand{$key}='MEHTA YASHVANTRAY ODHAVJIBHAI'}
			elsif ($pc==15 && $cand{$key} eq 'DR. KANU BHAI V. KALSARIA') {$cand{$key}='DR. KANUBHAI V. KALSARIA'}
			elsif ($pc==15 && $cand{$key} eq 'Dr.Bharatiben Dhirubhai Shiyal') {$cand{$key}='DR. BHARATIBEN DHIRUBHAI SHIYAL'}
			elsif ($pc==15 && $cand{$key} eq 'RASID KHAN HASAN KHAN PATHAN') {$cand{$key}='RASIDKHAN HASANKHAN PATHAN'}
			elsif ($pc==15 && $cand{$key} eq 'GOHEL BHARAT BHAI BHIMA BHAI') {$cand{$key}='GOHEL BHARATBHAI BHIMABHAI'}
			elsif ($pc==15 && $cand{$key} eq 'BHAVES GHAN SHYAM BHAI RAJYA GURU') {$cand{$key}='BHAVES GHANSHYAMBHAI RAJYAGURU'}
			elsif ($pc==15 && $cand{$key} eq 'VAGHELA NARENDRA BHAI SHAVJI BHAI') {$cand{$key}='VAGHELA NARENDRABHAI SHAVJIBHAI'}
			elsif ($pc==15 && $cand{$key} eq 'VAGHELA NARE NDRA BHAI SHAVJI BHAI') {$cand{$key}='VAGHELA NARENDRABHAI SHAVJIBHAI'}
			elsif ($pc==15 && $cand{$key} eq 'KHAD RANI ASIM BHAI PIRBHAI') {$cand{$key}='KHADRANI ASIMBHAI PIRBHAI'}
			elsif ($pc==15 && $cand{$key} eq 'RATHOD PRAVIN BHAI JINA BHAI') {$cand{$key}='RATHOD PRAVINBHAI JINABHAI'}
			elsif ($pc==15 && $cand{$key} eq 'Vaghela Narendra bhai Shavji bhai') {$cand{$key}='VAGHELA NARENDRABHAI SHAVJIBHAI'}
			elsif ($pc==15 && $cand{$key} eq 'RATHOD PRAVIN SINH CHANDRA SINH') {$cand{$key}='RATHOD PRAVINSINH CHANDRASINH'}
			elsif ($pc==15 && $cand{$key} eq 'DR. KANUBHAI V. KALSARIYA') {$cand{$key}='DR. KANUBHAI V. KALSARIA'}
			elsif ($pc==15 && $cand{$key} eq 'Mehta Yashvan tray Odhavji bhai') {$cand{$key}='MEHTA YASHVANTRAY ODHAVJIBHAI'}
			elsif ($pc==15 && $cand{$key} eq 'GOHIL PRAVI NSINH DHIRU BHA') {$cand{$key}='GOHIL PRAVINSINH DHIRUBHA'}
			elsif ($pc==15 && $cand{$key} eq 'Dr.Kanubhai V. Kalsaria') {$cand{$key}='DR. KANUBHAI V. KALSARIA'}
			elsif ($pc==15 && $cand{$key} eq 'Jagdishbhai Amarabhai Vegad') {$cand{$key}='JAGADISHBHAI AMARABHAI VEGAD'}
			elsif ($pc==15 && $cand{$key} eq 'GITA CHETAN PAUNDA') {$cand{$key}='GITA CHETAN PAUNDA (ADVOCATE GITABA JADEJA)'}
			elsif ($pc==15 && $cand{$key} eq 'Rathod Pravinhai Jinabhai') {$cand{$key}='RATHOD PRAVINBHAI JINABHAI'}
			elsif ($pc==15 && $cand{$key} eq 'Kagada Ramesh bhai Punabhai') {$cand{$key}='KAGADA RAMESHBHAI PUNABHAI'}
			elsif ($pc==15 && $cand{$key} eq 'GOHIL PRAVIN SINH DHIRU BHAI') {$cand{$key}='GOHIL PRAVINSINH DHIRUBHA'}
			elsif ($pc==15 && $cand{$key} eq 'KAGADA RAMESH BHAI PUNA BHAI') {$cand{$key}='KAGADA RAMESHBHAI PUNABHAI'}
			elsif ($pc==15 && $cand{$key} eq 'Bhaves Ghanshyam bhai Rajyaguru') {$cand{$key}='BHAVES GHANSHYAMBHAI RAJYAGURU'}
			elsif ($pc==15 && $cand{$key} eq 'DR. BHARATI BEN DHIRU BHAI SHIYAL') {$cand{$key}='DR. BHARATIBEN DHIRUBHAI SHIYAL'}
			elsif ($pc==17 && $cand{$key} eq 'ADWARD KHUSHALBHA I') {$cand{$key}='KHRISTI ADWARD KHUSHALBHAI'}
			elsif ($pc==17 && $cand{$key} eq 'MALEK SADIK HUSHEN MAH. HUSHEN') {$cand{$key}='MALEK SADIK HUSHEN MAHAMMD HUSHEN'}
			elsif ($pc==20 && $cand{$key} eq 'MISTRI MADHUSUD AN DEVRAM') {$cand{$key}='MISTRI MADHUSUDAN DEVRAM'}
			elsif ($pc==20 && $cand{$key} eq 'PATHAN MAHEMUDK HAN RAZAKKHAN') {$cand{$key}='PATHAN MAHEMUDKHAN RAZAKKHAN'}
			elsif ($pc==20 && $cand{$key} eq 'Pathan Mahemudk han Razakkhan') {$cand{$key}='PATHAN MAHEMUDKHAN RAZAKKHAN'}
			elsif ($pc==20 && $cand{$key} eq 'ROHIT MADHUSUD AN MOHANBHAI') {$cand{$key}='ROHIT MADHUSUDAN MOHANBHAI'}
			elsif ($pc==20 && $cand{$key} eq 'Sunil Digamba r Kulkarn i') {$cand{$key}='SUNIL DIGAMBAR KULKARNI'}
			elsif ($pc==21 && $cand{$key} eq 'NARANBHAI JEMALABHAI RATHAVA') {$cand{$key}='NARANBHAI JEMALABHAI RATHVA'}
			elsif ($pc==21 && $cand{$key} eq 'Naranbhai Jemlabhai Rathva') {$cand{$key}='NARANBHAI JEMALABHAI RATHVA'}
			elsif ($pc==21 && $cand{$key} eq 'PRO. ARJUNBHAI VERSINGBHA I RATHAVA') {$cand{$key}='Prof. ARJUNBHAI VERSINGBHAI RATHVA'}
			elsif ($pc==21 && $cand{$key} eq 'Prof. Arjunbhai Versingbhai Rathva 3') {$cand{$key}='Prof. ARJUNBHAI VERSINGBHAI RATHVA'}
			elsif ($pc==21 && $cand{$key} eq 'Prof. Arjunbhai Versingbhai Rathva Aam Aadmi Party') {$cand{$key}='Prof. ARJUNBHAI VERSINGBHAI RATHVA'}
			elsif ($pc==21 && $cand{$key} eq 'RAMSINH RATHAVA') {$cand{$key}='RAMSINH RATHWA'}
			elsif ($pc==21 && $cand{$key} eq 'Ramsinh Rathva') {$cand{$key}='RAMSINH RATHWA'}
			elsif ($pc==21 && $cand{$key} eq 'Ramsinh Rathwa 2') {$cand{$key}='RAMSINH RATHWA'}
			elsif ($pc==21 && $cand{$key} eq 'Vasava Prafulbhai Devajibhai Jantadal') {$cand{$key}='VASAVA PRAFULBHAI DEVJIBHAI'}
			elsif ($pc==21 && $cand{$key} eq 'Vasava Prafulbhai Devjibhai 4') {$cand{$key}='VASAVA PRAFULBHAI DEVJIBHAI'}
			elsif ($pc==22 && $cand{$key} eq 'Anandkumar Sarvarsinh Vasava - IND') {$cand{$key}='ANANDKUMAR SARVARSINH VASAVA'}
			elsif ($pc==22 && $cand{$key} eq 'Anilkumar Chhitubhai Bhagat - JD') {$cand{$key}='ANILKUMAR CHHITUBHAI BHAGAT'}
			elsif ($pc==22 && $cand{$key} eq 'Bhura Shabbirbhai Valibhai - IND') {$cand{$key}='BHURA SHABBIRBHAI VALIBHAI'}
			elsif ($pc==22 && $cand{$key} eq 'Jayendrasinh Rana - AAP') {$cand{$key}='JAYENDRASINH RANA'}
			elsif ($pc==22 && $cand{$key} eq 'Nitin Ishwarlal Vakil') {$cand{$key}='NITIN ISHWARLAL VAKIL (ADVOCATE)'}
			elsif ($pc==22 && $cand{$key} eq 'Patel Jayeshbhai Ambalalbhai') {$cand{$key}='PATEL JAYESHBHAI AMBALALBHAI (JAYESH KAKA)'}
			elsif ($pc==22 && $cand{$key} eq 'Rafikbhai Suleman Sapa - IND') {$cand{$key}='RAFIKBHAI SULEMAN SAPA'}
			elsif ($pc==22 && $cand{$key} eq 'Saiyad Mohsin Bapu Nanumiyawala - BMP') {$cand{$key}='SAIYAD MOHSIN BAPU NANUMIYAWALA'}
			elsif ($pc==22 && $cand{$key} eq 'Sayyed Asif Zafar Al - ADP') {$cand{$key}='SAYYED ASIF ZAFAR ALI'}
			elsif ($pc==22 && $cand{$key} eq 'Sayyed Asif Zafar Ali - ADP') {$cand{$key}='SAYYED ASIF ZAFAR ALI'}
			elsif ($pc==22 && $cand{$key} eq 'Sayyed Asif Zafar Ali ADP') {$cand{$key}='SAYYED ASIF ZAFAR ALI'}
			elsif ($pc==22 && $cand{$key} eq 'Shaileshkumar Maganbhai Parmar - IND') {$cand{$key}='SHAILESHKUMAR MAGANBHAI PARMAR'}
			elsif ($pc==22 && $cand{$key} eq 'Sindhi Mayyudeen Umarbhai - IND') {$cand{$key}='SINDHI MAYYUDEEN UMARBHAI'}
			elsif ($pc==22 && $cand{$key} eq 'Sukhramsingh - BSP') {$cand{$key}='SUKHRAMSINGH'}
			elsif ($pc==22 && $cand{$key} eq 'Vasava Mansukhbhai Dhanjibhai - BJP') {$cand{$key}='VASAVA MANSUKHBHAI DHANJIBHAI'}
			elsif ($pc==22 && $cand{$key} eq 'Virsangbhai Parbatbhai Gohil - IND') {$cand{$key}='VIRSANGBHAI PARBATBHAI GOHIL'}
			elsif ($pc==23 && $cand{$key} eq 'Chaudhari Chandubhai Machalabhai.') {$cand{$key}='CHAUDHARI CHANDUBHAI MACHALABHAI'}
			elsif ($pc==23 && $cand{$key} eq 'Chaudhari Reniyabhai Shankarbhai.') {$cand{$key}='CHAUDHARI RENIYABHAI SHANKARBHAI'}
			elsif ($pc==23 && $cand{$key} eq 'Chaudhari Revaben Shankarbhai.') {$cand{$key}='CHAUDHARI REVABEN SHANKARBHAI'}
			elsif ($pc==23 && $cand{$key} eq 'Chaudhari Tusharbhai Amarsinhbha i.') {$cand{$key}='CHAUDHARI TUSHARBHAI AMARSINHBHAI'}
			elsif ($pc==23 && $cand{$key} eq 'Chaudhari Tusharbhai Amarsinhbhai.') {$cand{$key}='CHAUDHARI TUSHARBHAI AMARSINHBHAI'}
			elsif ($pc==23 && $cand{$key} eq 'Gamit Surendrabhai Simabhai.') {$cand{$key}='GAMIT surendrabhai simabhai'}
			elsif ($pc==23 && $cand{$key} eq 'Rathod Rameshbhai Bhikhabhai.') {$cand{$key}='RATHOD RAMESHBHAI BHIKHABHAI'}
			elsif ($pc==23 && $cand{$key} eq 'Vasava Parbhubhai Nagarbhai.') {$cand{$key}='VASAVA PARBHUBHAI NAGARBHAI'}
			elsif ($pc==24 && $cand{$key} eq '-16') {undef($cand{$key});next}
			elsif ($pc==24 && $cand{$key} eq 'DARSHA NA VIKRAM JARDOSH') {$cand{$key}='DARSHANA VIKRAM JARDOSH'}
			elsif ($pc==24 && $cand{$key} eq 'DARSHA NA VIKRAM') {$cand{$key}='DARSHANA VIKRAM JARDOSH'}
			elsif ($pc==24 && $cand{$key} eq 'DARSHA NA') {$cand{$key}='DARSHANA VIKRAM JARDOSH'}
			elsif ($pc==24 && $cand{$key} eq 'DESAI NAISHAD HBHAI BHUPATB') {$cand{$key}='DESAI NAISHADHBHAI BHUPATBHAI'}
			elsif ($pc==24 && $cand{$key} eq 'DESAI NAISHAD HBHAI') {$cand{$key}='DESAI NAISHADHBHAI BHUPATBHAI'}
			elsif ($pc==24 && $cand{$key} eq 'DESAI NAISHAD') {$cand{$key}='DESAI NAISHADHBHAI BHUPATBHAI'}
			elsif ($pc==24 && $cand{$key} eq 'KIRITBHA I HARJIBH AI') {$cand{$key}='KIRITBHAI HARJIBHAI VASANI'}
			elsif ($pc==24 && $cand{$key} eq 'KIRITBHA I HARJIBH') {$cand{$key}='KIRITBHAI HARJIBHAI VASANI'}
			elsif ($pc==24 && $cand{$key} eq 'KIRITBHA I') {$cand{$key}='KIRITBHAI HARJIBHAI VASANI'}
			elsif ($pc==24 && $cand{$key} eq 'MAVJIBH AI LAXMAN BHAI') {$cand{$key}='MAVJIBHAI LAXMANBHAI SANDIS'}
			elsif ($pc==24 && $cand{$key} eq 'MAVJIBH AI LAXMAN') {$cand{$key}='MAVJIBHAI LAXMANBHAI SANDIS'}
			elsif ($pc==24 && $cand{$key} eq 'MAVJIBH AI') {$cand{$key}='MAVJIBHAI LAXMANBHAI SANDIS'}
			elsif ($pc==24 && $cand{$key} eq 'MOHANB HAI B. PATEL') {$cand{$key}='MOHANBHAI B. PATEL'}
			elsif ($pc==24 && $cand{$key} eq 'MOHANB HAI B.') {$cand{$key}='MOHANBHAI B. PATEL'}
			elsif ($pc==24 && $cand{$key} eq 'MUKESH BHAI LAVJIBH AI') {$cand{$key}='MUKESHBHAI LAVJIBHAI AMBALIYA'}
			elsif ($pc==24 && $cand{$key} eq 'MUKESH BHAI LAVJIBH') {$cand{$key}='MUKESHBHAI LAVJIBHAI AMBALIYA'}
			elsif ($pc==24 && $cand{$key} eq 'MUKESH BHAI') {$cand{$key}='MUKESHBHAI LAVJIBHAI AMBALIYA'}
			elsif ($pc==24 && $cand{$key} eq 'VASAVA KISHORB HAI CHHOTU') {$cand{$key}='VASAVA KISHORBHAI CHHOTUBHAI'}
			elsif ($pc==24 && $cand{$key} eq 'VASAVA KISHORB HAI') {$cand{$key}='VASAVA KISHORBHAI CHHOTUBHAI'}
			elsif ($pc==24 && $cand{$key} eq 'VASAVA KISHORB') {$cand{$key}='VASAVA KISHORBHAI CHHOTUBHAI'}
			elsif ($pc==25 && $cand{$key} eq '#N/A') {undef($cand{$key});next}
			elsif ($pc==25 && $cand{$key} =~ /^\d.\d+$/) {undef($cand{$key});next}
			elsif ($pc==25 && $cand{$key} eq 'Arun S. Pathak') {$cand{$key}='ARUN S. PATHAK(JOURNALIST)'}
			elsif ($pc==25 && $cand{$key} eq 'Asla m Mistr y') {$cand{$key}='ASLAM MISTRY'}
			elsif ($pc==25 && $cand{$key} eq 'C.R.Patil') {$cand{$key}='C. R. PATIL'}
			elsif ($pc==25 && $cand{$key} eq 'Chauhan Keshavbhai Malabhai') {$cand{$key}='CHAUHAN KESAVBHAI MALABHAI (MASTER)'}
			elsif ($pc==25 && $cand{$key} eq 'D:\\') {undef($cand{$key});next}
			elsif ($pc==25 && $cand{$key} eq 'Hasan Sheikh') {$cand{$key}='HASAN SHAIKH'}
			elsif ($pc==25 && $cand{$key} eq 'Kesha vji L. Sarad va') {$cand{$key}='KESHAVJI L. SARADVA'}
			elsif ($pc==25 && $cand{$key} eq 'Keshavji L. Sardva') {$cand{$key}='KESHAVJI L. SARADVA'}
			elsif ($pc==25 && $cand{$key} eq 'Lataben Ashokku mar Dwivedi') {$cand{$key}='LATABEN ASHOKKUMAR DWIVEDI'}
			elsif ($pc==25 && $cand{$key} eq 'Lataben Ashokkumar Dwiv') {$cand{$key}='LATABEN ASHOKKUMAR DWIVEDI'}
			elsif ($pc==25 && $cand{$key} eq 'Maksu d Mirza') {$cand{$key}='MAKSUD MIRZA'}
			elsif ($pc==25 && $cand{$key} eq 'Parsi Munsi') {$cand{$key}='PERCY MUNSHI'}
			elsif ($pc==25 && $cand{$key} eq 'Patel Bhupen drakum ar Dhirubh ai') {$cand{$key}='PATEL BHUPENDRAKUMAR DHIRUBHAI'}
			elsif ($pc==25 && $cand{$key} eq 'Patel Bhupendrakuma r Dhirubhai') {$cand{$key}='PATEL BHUPENDRAKUMAR DHIRUBHAI'}
			elsif ($pc==25 && $cand{$key} eq 'Pyarel al Bharti') {$cand{$key}='PYARELAL BHARTI'}
			elsif ($pc==25 && $cand{$key} eq 'Ramjan Mansuri') {$cand{$key}='RAMJAN MANSURI(JOURNALIST)'}
			elsif ($pc==25 && $cand{$key} eq 'Ramzan Mansuri') {$cand{$key}='RAMJAN MANSURI(JOURNALIST)'}
			elsif ($pc==25 && $cand{$key} eq 'Ravsaheb Bhimrav Patil') {$cand{$key}='RAVSHAHEB BHIMRAV PATIL (BANDHU)'}
			elsif ($pc==25 && $cand{$key} eq 'Ravsha heb Bhimra v Patil') {$cand{$key}='RAVSHAHEB BHIMRAV PATIL (BANDHU)'}
			elsif ($pc==25 && $cand{$key} eq 'Ravshaheb Bhimrav Patil') {$cand{$key}='RAVSHAHEB BHIMRAV PATIL (BANDHU)'}
			elsif ($pc==25 && $cand{$key} eq 'Saiyad Mehmud Aehmad') {$cand{$key}='SAIYED MEHMUD AHMED'}
			elsif ($pc==25 && $cand{$key} eq 'Saiyed Mehmu d Ahmed') {$cand{$key}='SAIYED MEHMUD AHMED'}
			elsif ($pc==25 && $cand{$key} eq 'Sonal Kellog g') {$cand{$key}='SONAL KELLOGG'}
			elsif ($pc==25 && $cand{$key} eq 'Sonal Kelog') {$cand{$key}='SONAL KELLOGG'}
			elsif ($pc==25 && $cand{$key} eq 'Varde Rajubhai Bhimrav') {$cand{$key}='WARDE RAJUBHAI BHIMRAO'}
			elsif ($pc==25 && $cand{$key} eq 'Vimal Patel') {$cand{$key}='VIMAL PATEL (ENDHAL)'}
			elsif ($pc==25 && $cand{$key} eq 'Warde Rajub hai Bhimr ao') {$cand{$key}='WARDE RAJUBHAI BHIMRAO'}
			elsif ($pc==26 && $cand{$key} eq 'DR. K.C.PATEL') {$cand{$key}='DR. K. C. PATEL'}
			elsif ($pc==26 && $cand{$key} eq 'Dr. K.C. Patel') {$cand{$key}='DR. K. C. PATEL'}
			elsif ($pc==26 && $cand{$key} eq 'Dr. K.C.Patel') {$cand{$key}='DR. K. C. PATEL'}
			elsif ($pc==26 && $cand{$key} eq 'Dr. Pankajbhai Parbhubhai Patel') {$cand{$key}='DR. PANKAJKUMAR PARBHUBHAI PATEL'}
			elsif ($pc==26 && $cand{$key} eq 'Dr. Pankajkumar P. Patel') {$cand{$key}='DR. PANKAJKUMAR PARBHUBHAI PATEL'}
			elsif ($pc==26 && $cand{$key} eq 'Dr. Pankajkumar Parbhubhai') {$cand{$key}='DR. PANKAJKUMAR PARBHUBHAI PATEL'}
			elsif ($pc==26 && $cand{$key} eq 'Dr.K.C. Patel') {$cand{$key}='DR. K. C. PATEL'}
			elsif ($pc==26 && $cand{$key} eq 'Dr.K.C.Patel') {$cand{$key}='DR. K. C. PATEL'}
			elsif ($pc==26 && $cand{$key} eq 'Dr.Pankaj kumar Parabhubhai Patel') {$cand{$key}='DR. PANKAJKUMAR PARBHUBHAI PATEL'}
			elsif ($pc==26 && $cand{$key} eq 'Dr.Pankajku mar Parabhubhai Patel') {$cand{$key}='DR. PANKAJKUMAR PARBHUBHAI PATEL'}
			elsif ($pc==26 && $cand{$key} eq 'Gaurangbhai R. Patel') {$cand{$key}='GAURANGBHAI RAMESHBHAI PATEL'}
			elsif ($pc==26 && $cand{$key} eq 'Patel Budhabhai R.') {$cand{$key}='PATEL BUDHABHAI RANCHHODBHAI'}
			elsif ($pc==26 && $cand{$key} eq 'Patel Budhabhai Ranchhodb hai') {$cand{$key}='PATEL BUDHABHAI RANCHHODBHAI'}
			elsif ($pc==26 && $cand{$key} eq 'Patel Govindbhai R.') {$cand{$key}='PATEL GOVINDBHAI RANCHHODBHAI'}
			elsif ($pc==26 && $cand{$key} eq 'Patel Govindbhai Ranchhod bhai') {$cand{$key}='PATEL GOVINDBHAI RANCHHODBHAI'}
			elsif ($pc==26 && $cand{$key} eq 'Patel Shaileshbhai G.') {$cand{$key}='PATEL SHAILESHBHAI GANDABHAI'}
			elsif ($pc==26 && $cand{$key} eq 'Serial No.') {undef($cand{$key}); next}
			elsif ($pc==26 && $cand{$key} eq 'Talaviya Babubhai C.') {$cand{$key}='TALAVIYA BABUBHAI CHHAGANBHAI'}
			elsif ($pc==26 && $cand{$key} eq 'Thakarya Ratilal Vajirbhai') {$cand{$key}='THAKRIYA RATILAL VAJIRBHAI'}
			elsif ($pc==26 && $cand{$key} eq 'Thakriya Ratilal V.') {$cand{$key}='THAKRIYA RATILAL VAJIRBHAI'}
			elsif ($pc==26 && $cand{$key} eq 'Vadiya Laxmanbhai C.') {$cand{$key}='VADIA LAXMANBHAI CHHAGANBHAI'}
			elsif ($pc==26 && $cand{$key} eq 'Vadiya Laxmanbhai Chhaganbhai') {$cand{$key}='VADIA LAXMANBHAI CHHAGANBHAI'}
			elsif ($pc==26 && $cand{$key} eq 's. no') {undef($cand{$key}); next}
			elsif ($pc==15 && $cand{$key} eq '* *') {undef($cand{$key}); next}
			elsif ($pc==15 && $cand{$key} eq '*') {undef($cand{$key}); next}
			elsif ($pc==12 && $cand{$key} eq 'PADHIYAR LALJIBHAI KARABHA') {$cand{$key}='PADHIYAR LALJIBHAI KARABHAI'} # AC 78
			elsif ($pc==12 && $cand{$key} eq 'SUMARA AMANDBHAI NOORMAMADBHA SUMARA') {$cand{$key}='SUMARA AMANDBHAI NOORMAMADBHAI SUMARA'} # AC 79
			elsif ($pc==15 && $cand{$key} eq 'VEGAD NATHABHAI') {$cand{$key}='VEGAD NATHABHAI (VEGADBHAI PRAGNACHAKSHU CANDIDATE)'} # AC 106
			elsif ($pc==3 && $cand{$key} eq 'RATHOD BHAVSINH DAHYABHAI') {$cand{$key}='RATHOD BHAVSINHBHAI DAHYABHAI'} # AC 19
			elsif ($pc==11 && $cand{$key} eq 'Jadeja Kandhalbhai Saramanbhai') {$cand{$key}='JADEJA KANDHALBHAI SARMANBHAI'} # AC 88, column 1
			elsif ($pc==11 && $cand{$key} eq 'Unadakat Prakash Vallabhdas') {$cand{$key}='UNADAKAT PRAKASH VALLABHADAS'} # AC 73, column 7
			elsif ($pc==18 && $cand{$key} eq 'AAAP') {$cand{$key}='PIYUSHKUMAR DILIPBHAI PARMAR'} # AC 127, column 4
			elsif ($pc==18 && $cand{$key} eq 'BJP') {$cand{$key}='CHAUHAN PRABHATSINH PRATAPSINH'} # AC 127, column 2
			elsif ($pc==18 && $cand{$key} eq 'BSP') {$cand{$key}='GIRI RAMCHANDRA VAIJNATH'} # AC 127, column 1
			elsif ($pc==18 && $cand{$key} eq 'INC') {$cand{$key}='RAMSINH PARMAR'} # AC 127, column 3
			elsif ($pc==18 && $key==10) {$cand{$key}='PATEL PANKAJBHAI RAVJIBHAI'} # AC 127, column 10
			elsif ($pc==18 && $key==11) {$cand{$key}='MANSURI MUKHATYAR MOHAMMAD (PANTER M. LALA)'} # AC 127, column 11
			elsif ($pc==18 && $key==12) {$cand{$key}='VANKAR MANILAL BHANABHAI'} # AC 127, column 12
			elsif ($pc==18 && $key==7) {$cand{$key}='GORA SHOEB MOHMADHANIF'} # AC 127, column 7
			elsif ($pc==18 && $key==8) {$cand{$key}='S. N. CHAVADA (CHAVADA VAKIL)'} # AC 127, column 8
			elsif ($pc==18 && $key==9) {$cand{$key}='CHAVADA HARISHCHANDRASINH PRABHATSINH'} # AC 127, column 9
			elsif ($pc==18 && $cand{$key} eq 'JD') {$cand{$key}='SHAIKH MAJITMIYA JIVAMIYA'} # AC 127, column 6
			elsif ($pc==18 && $cand{$key} eq 'SP') {$cand{$key}='SHAIKH KALIM ABDULLATIF'} # AC 127, column 5
			elsif ($pc==20 && $cand{$key} eq 'Pathan Sahebkhan Aasifkhan') {$cand{$key}='PATHAN SAHEBKHAN ASIFKHAN'} # AC 143, column 7
			elsif ($pc==20 && $cand{$key} eq 'Rohit Madhusu dan Mohanb hai') {$cand{$key}='ROHIT MADHUSUDAN MOHANBHAI'} # AC 143, column 3
			elsif ($pc==20 && $cand{$key} eq 'Tapan Dasgup ta') {$cand{$key}='TAPAN DASGUPTA'} # AC 143, column 5
			elsif ($pc==24 && $cand{$key} eq 'DARSHA NA VIKRAM 3') {$cand{$key}='DARSHANA VIKRAM JARDOSH'} # AC 155, column 2
			elsif ($pc==24 && $cand{$key} eq 'DESAI NAISHAD HBHAI 4') {$cand{$key}='DESAI NAISHADHBHAI BHUPATBHAI'} # AC 159, column 3
			elsif ($pc==24 && $cand{$key} eq 'KIRITBHA I HARJIBH 5') {$cand{$key}='KIRITBHAI HARJIBHAI VASANI'} # AC 155, column 4
			elsif ($pc==24 && $cand{$key} eq 'MAVJIBH AI LAXMAN 8') {$cand{$key}='MAVJIBHAI LAXMANBHAI SANDIS'} # AC 159, column 7
			elsif ($pc==24 && $cand{$key} eq 'MOHANB HAI B. PATEL 6') {$cand{$key}='MOHANBHAI B. PATEL'} # AC 155, column 5
			elsif ($pc==24 && $cand{$key} eq 'MUKESH BHAI LAVJIBH 9') {$cand{$key}='MUKESHBHAI LAVJIBHAI AMBALIYA'} # AC 159, column 8
			elsif ($pc==24 && $cand{$key} eq 'VASAVA KISHORB HAI 7') {$cand{$key}='VASAVA KISHORBHAI CHHOTUBHAI'} # AC 159, column 6
			elsif ($pc==25 && $cand{$key} eq 'Chuhan Kesavbhai Malabhai') {$cand{$key}='CHAUHAN KESAVBHAI MALABHAI (MASTER)'} # AC 165, column 1
			elsif ($pc==6 && $cand{$key} eq 'of 11') {undef($cand{$key}); next} # AC 40, column 25
			elsif ($pc==8 && $cand{$key} eq 'Chavda Mansukhbh ai Nagarbhai') {$cand{$key}='CHAVDA MANSUKHBHAI NAGARBHAI'} # AC 54, column 3
			elsif ($pc==8 && $cand{$key} eq 'Dr. J.G. Parmar') {$cand{$key}='DR J. G. PARMAR'} # AC 56, column 6
			elsif ($pc==8 && $cand{$key} eq 'Ishvarbhai Dhanabhai Makwana') {$cand{$key}='ISHWARBAHI DHANABHAI MAKWANA'} # AC 54, column 1
			elsif ($pc==8 && $cand{$key} eq 'Solanki Rameshbha i Danabhai') {$cand{$key}='SOLANKI RAMESHBHAI DANABHAI'} # AC 56, column 10
			elsif ($pc==11 && $cand{$key} eq 'Jadeja Kandhalbh ai Saramanb hai') {$cand{$key}='JADEJA KANDHALBHAI SARMANBHAI'} # AC 85, column 1
			elsif ($pc==13 && $cand{$key} eq 'ChudasamaRaje shbhai Naranbhai') {$cand{$key}='CHUDASAMA RAJESHBHAI NARANBHAI'} # AC 92, column 1
			elsif ($pc==15 && $cand{$key} eq 'Gita Chetan Paunda') {$cand{$key}='GITA CHETAN PAUNDA (ADVOCATE GITABA JADEJA)'} # AC 104, column 1
			elsif ($pc==17 && $cand{$key} eq 'CHAUHAN 1 DEVUSINH JESINGBHAI') {$cand{$key}='CHAUHAN DEVUSING MOTISHING'} # AC 115, column 1
			elsif ($pc==21 && $cand{$key} eq 'Naranbhai Jemalabhai Rathva 1') {$cand{$key}='NARANBHAI JEMALABHAI RATHVA'} # AC 139, column 1
			elsif ($pc==23 && $cand{$key} eq 'Gamit Movaliyabhai Nopariyabhai .') {$cand{$key}='GAMIT MOVALIYABHAI NOPARIYABHAI'} # AC 157, column 1
			elsif ($pc==23 && $cand{$key} eq 'Gamit Movaliyabhai Nopariyabhai.') {$cand{$key}='GAMIT MOVALIYABHAI NOPARIYABHAI'} # AC 172, column 1
			elsif ($pc==24 && $cand{$key} eq 'OMPRAK ASH SHRIVAS 2') {$cand{$key}='OMPRAKASH SHRIVASTAV'} # AC 155, column 1
			elsif ($pc==24 && $cand{$key} eq 'OMPRAK ASH SHRIVAS TAV') {$cand{$key}='OMPRAKASH SHRIVASTAV'} # AC 166, column 1
			elsif ($pc==24 && $cand{$key} eq 'OMPRAK ASH SHRIVAS') {$cand{$key}='OMPRAKASH SHRIVASTAV'} # AC 167, column 1
			elsif ($pc==26 && $cand{$key} eq 'Kishanbhai V. Patel') {$cand{$key}='KISHANBHAI VESTABHAI PATEL'} # AC 177, column 1
			elsif ($pc==3 && $cand{$key} eq 'Parmar Maganbhai Amrabhai') {$cand{$key}='PARMAR MAGANBHAI AMARABHAI'} # AC 18, column 1
			elsif ($pc==9 && $cand{$key} eq 'KOLIPATEL SOMABHAI GANDABHAI') {$cand{$key}='KOLI PATEL SOMABHAI GANDALAL'} # AC 39, column 1
			elsif ($pc==1 && $cand{$key} eq 'BHUJ') {undef($cand{$key}); next} # AC 3, column 11
			elsif ($pc==15 && $cand{$key} eq 'BHAVES GHANSHY AMBHAI RAJYAGU RU') {$cand{$key}='BHAVES GHANSHYAMBHAI RAJYAGURU'} # AC 100, column 10
			elsif ($pc==15 && $cand{$key} eq 'DR.BHARA TIBEN DHIRUBH AI SHIYAL') {$cand{$key}='DR. BHARATIBEN DHIRUBHAI SHIYAL'} # AC 100, column 2
			elsif ($pc==15 && $cand{$key} eq 'DR.BHARTI BEN DHIRUBHA I SHIYAL') {$cand{$key}='DR. BHARATIBEN DHIRUBHAI SHIYAL'} # AC 102, column 2
			elsif ($pc==15 && $cand{$key} eq 'DR.KANU BHAI.V.KA LSARIYA') {$cand{$key}='DR. KANUBHAI V. KALSARIA'} # AC 100, column 4
			elsif ($pc==15 && $cand{$key} eq 'DR.KANUB HAI V. KALSARIA') {$cand{$key}='DR. KANUBHAI V. KALSARIA'} # AC 102, column 4
			elsif ($pc==15 && $cand{$key} eq 'GOHEL BHARATB HAI BHIMABH AI') {$cand{$key}='GOHEL BHARATBHAI BHIMABHAI'} # AC 100, column 8
			elsif ($pc==15 && $cand{$key} eq 'GOHEL BHARATBH AI BHIMABHA I') {$cand{$key}='GOHEL BHARATBHAI BHIMABHAI'} # AC 102, column 8
			elsif ($pc==15 && $cand{$key} eq 'GOHIL PRAVIN SINH DHIRU BHA') {$cand{$key}='GOHIL PRAVINSINH DHIRUBHA'} # AC 107, column 7
			elsif ($pc==15 && $cand{$key} eq 'GOHIL PRAVINSI NH DHIRUBH A') {$cand{$key}='GOHIL PRAVINSINH DHIRUBHA'} # AC 100, column 7
			elsif ($pc==15 && $cand{$key} eq 'GOHIL PRAVINSIN H DHIRUBHA') {$cand{$key}='GOHIL PRAVINSINH DHIRUBHA'} # AC 102, column 7
			elsif ($pc==15 && $cand{$key} eq 'JAGADISHB HAI AMARABH AI VEGAD') {$cand{$key}='JAGADISHBHAI AMARABHAI VEGAD'} # AC 102, column 9
			elsif ($pc==15 && $cand{$key} eq 'JAGDISHB HAI AMARAB HAI VEGAD') {$cand{$key}='JAGADISHBHAI AMARABHAI VEGAD'} # AC 100, column 9
			elsif ($pc==15 && $cand{$key} eq 'KAGADA RAMESHB HAI PUNABHA I') {$cand{$key}='KAGADA RAMESHBHAI PUNABHAI'} # AC 100, column 5
			elsif ($pc==15 && $cand{$key} eq 'KAGDA RAMESHB HAI PUNABHAI') {$cand{$key}='KAGADA RAMESHBHAI PUNABHAI'} # AC 102, column 5
			elsif ($pc==15 && $cand{$key} eq 'KHADRAN I ASIMBHAI PIRBHAI') {$cand{$key}='KHADRANI ASIMBHAI PIRBHAI'} # AC 100, column 6
			elsif ($pc==15 && $cand{$key} eq 'MARU MANHAR BHAI VALJIBHAI') {$cand{$key}='MARU MANHAR VALAJIBHAI'} # AC 100, column 12
			elsif ($pc==15 && $cand{$key} eq 'MARU MANHAR VALAJI BHAI') {$cand{$key}='MARU MANHAR VALAJIBHAI'} # AC 107, column 12
			elsif ($pc==15 && $cand{$key} eq 'MARU MANHARB HAI VALJIBHAI') {$cand{$key}='MARU MANHAR VALAJIBHAI'} # AC 102, column 12
			elsif ($pc==15 && $cand{$key} eq 'MEHTA YASHVAN TRAY ODHAVJIB HAI') {$cand{$key}='MEHTA YASHVANTRAY ODHAVJIBHAI'} # AC 100, column 11
			elsif ($pc==15 && $cand{$key} eq 'MEHTA YASHVANT RAI ODHAVJIB HAI') {$cand{$key}='MEHTA YASHVANTRAY ODHAVJIBHAI'} # AC 102, column 11
			elsif ($pc==15 && $cand{$key} eq 'RASIDKHA N HASANKH AN PATHAN') {$cand{$key}='RASIDKHAN HASANKHAN PATHAN'} # AC 100, column 13
			elsif ($pc==15 && $cand{$key} eq 'RASIDKHA N HASANKH AN PATHAN') {$cand{$key}='RASIDKHAN HASANKHAN PATHAN'} # AC 102, column 13
			elsif ($pc==15 && $cand{$key} eq 'RATHOD PRAVINBH AI JINABHAI') {$cand{$key}='RATHOD PRAVINBHAI JINABHAI'} # AC 100, column 3
			elsif ($pc==15 && $cand{$key} eq 'RATHOD PRAVINBH AI JINABHAI') {$cand{$key}='RATHOD PRAVINBHAI JINABHAI'} # AC 102, column 3
			elsif ($pc==15 && $cand{$key} eq 'RATHOD PRAVINSI NH CHANDRA SINH') {$cand{$key}='RATHOD PRAVINSINH CHANDRASINH'} # AC 100, column 14
			elsif ($pc==15 && $cand{$key} eq 'RATHOD PRAVINSIN H CHANDRAS INH') {$cand{$key}='RATHOD PRAVINSINH CHANDRASINH'} # AC 102, column 14
			elsif ($pc==15 && $cand{$key} eq 'VAGHELA NARENDR ABHAI SAVAJIBH AI') {$cand{$key}='VAGHELA NARENDRABHAI SHAVJIBHAI'} # AC 100, column 15
			elsif ($pc==15 && $cand{$key} eq 'VAGHELA NARENDR ABHAI SHAVJIBHA I') {$cand{$key}='VAGHELA NARENDRABHAI SHAVJIBHAI'} # AC 102, column 15
			elsif ($pc==15 && $cand{$key} eq 'VEGAD NATHABH AI') {$cand{$key}='VEGAD NATHABHAI (VEGADBHAI PRAGNACHAKSHU CANDIDATE)'} # AC 100, column 16
			elsif ($pc==17 && $cand{$key} eq 'Abdul Rajjakkhan Pathan') {$cand{$key}='ABDUL RAZAKKHAN PATHAN'} # AC 117, column 4
			elsif ($pc==17 && $cand{$key} eq 'Badhivala Labhubhai Jivrajbhai') {$cand{$key}='BADHIWALA LABHUBHAI JIVRAJBHAI'} # AC 117, column 5
			elsif ($pc==17 && $cand{$key} eq 'Chauhan Devusinh Motisinh') {$cand{$key}='CHAUHAN DEVUSING MOTISHING'} # AC 117, column 8
			elsif ($pc==17 && $cand{$key} eq 'Khristi Advord Khushalbha i') {$cand{$key}='KHRISTI ADWARD KHUSHALBHAI'} # AC 117, column 7
			elsif ($pc==17 && $cand{$key} eq 'Malek Sabirhusen Ismailbhai') {$cand{$key}='MALEK SABIRHUSEN ISMAELBHAI'} # AC 117, column 13
			elsif ($pc==17 && $cand{$key} eq 'Malek Sadik Husen Mahammd Hushen') {$cand{$key}='MALEK SADIK HUSHEN MAHAMMD HUSHEN'} # AC 120, column 12
			elsif ($pc==17 && $cand{$key} eq 'Malek Shadikhusen Mahmadhuse n') {$cand{$key}='MALEK SADIK HUSHEN MAHAMMD HUSHEN'} # AC 117, column 12
			elsif ($pc==17 && $cand{$key} eq 'Malek Yakubmiya Nabhimiya') {$cand{$key}='MALEK YAKUBMIYA NABIMIYA'} # AC 118, column 11
			elsif ($pc==17 && $cand{$key} eq 'Malek Yakubmiya Nabi miya') {$cand{$key}='MALEK YAKUBMIYA NABIMIYA'} # AC 117, column 11
			elsif ($pc==17 && $cand{$key} eq 'Pathan Amanullakha Sitabka') {$cand{$key}='PATHAN AMANULLAKHA SITABKHA'} # AC 117, column 9
			elsif ($pc==17 && $cand{$key} eq 'Ranvir Pranavraj Govindbhai') {$cand{$key}='RANVEER PRANAYRAJ GOVINDBHAI'} # AC 117, column 6
			elsif ($pc==17 && $cand{$key} eq 'Roshan Priyvadan Shan') {$cand{$key}='ROSHAN PRIYAVADAN SHAH'} # AC 117, column 15
			elsif ($pc==18 && $cand{$key} eq 'Chavada Harishchandr asinh Prabhatsinh') {$cand{$key}='CHAVADA HARISHCHANDRASINH PRABHATSINH'} # AC 126, column 9
			elsif ($pc==18 && $cand{$key} eq 'Gora Shoeb Mohmadh anif') {$cand{$key}='GORA SHOEB MOHMADHANIF'} # AC 126, column 7
			elsif ($pc==18 && $cand{$key} eq 'Mansuri Mukhatyar Mohammad') {$cand{$key}='MANSURI MUKHATYAR MOHAMMAD (PANTER M. LALA)'} # AC 126, column 11
			elsif ($pc==18 && $cand{$key} eq 'S.N. Chavada') {$cand{$key}='S. N. CHAVADA (CHAVADA VAKIL)'} # AC 126, column 8
			elsif ($pc==18 && $cand{$key} eq 'Shaikh Kalim Abdul Latif') {$cand{$key}='SHAIKH KALIM ABDULLATIF'} # AC 126, column 5
			elsif ($pc==19 && $cand{$key} eq 'Bhura Navalbhai Manabhai') {$cand{$key}='BHURA NAVALABHAI MANABHAI'} # AC 134, column 10
			elsif ($pc==19 && $cand{$key} eq 'K. C. Muniya Advocate') {$cand{$key}='K. C. MUNIA ADVOCATE'} # AC 130, column 6
			elsif ($pc==19 && $cand{$key} eq 'Katara Singjibhai Jaljibhai') {$cand{$key}='KATARA SINGAJIBHAI JALJIBHAI'} # AC 134, column 1
			elsif ($pc==19 && $cand{$key} eq 'Meda Jagdishbha i Manilal') {$cand{$key}='MEDA JAGDISHBHAI MANILAL'} # AC 130, column 7
			elsif ($pc==19 && $cand{$key} eq 'Taviyad Dr.Prabhaben Kishorsinh') {$cand{$key}='TAVIYAD DR. PRABHABEN KISHORSINH'} # AC 134, column 3
			elsif ($pc==20 && $cand{$key} eq 'Pathan Mahemudkhan Rajakkhan') {$cand{$key}='PATHAN MAHEMUDKHAN RAZAKKHAN'} # AC 145, column 6
			elsif ($pc==21 && $cand{$key} eq 'Prof.Arjunbhai Versingbhai Rathva') {$cand{$key}='Prof. ARJUNBHAI VERSINGBHAI RATHVA'} # AC 138, column 3
			elsif ($pc==22 && $cand{$key} eq 'Anandkumar Sarvarsinh Vasava IND') {$cand{$key}='ANANDKUMAR SARVARSINH VASAVA'} # AC 154, column 8
			elsif ($pc==22 && $cand{$key} eq 'Anilkumar Chhitubhai Bhagat JD') {$cand{$key}='ANILKUMAR CHHITUBHAI BHAGAT'} # AC 154, column 4
			elsif ($pc==22 && $cand{$key} eq 'Bhura Shabbirbhai Valibhai IND') {$cand{$key}='BHURA SHABBIRBHAI VALIBHAI'} # AC 154, column 10
			elsif ($pc==22 && $cand{$key} eq 'Jayendrasinh Rana AAP') {$cand{$key}='JAYENDRASINH RANA'} # AC 154, column 5
			elsif ($pc==22 && $cand{$key} eq 'Rafikbhai Suleman Sapa IND') {$cand{$key}='RAFIKBHAI SULEMAN SAPA'} # AC 154, column 11
			elsif ($pc==22 && $cand{$key} eq 'Saiyad Mohsin Bapu Nanumiyawala BMP') {$cand{$key}='SAIYAD MOHSIN BAPU NANUMIYAWALA'} # AC 147, column 7
			elsif ($pc==22 && $cand{$key} eq 'Sayyed Asif Zafar Al ADP') {$cand{$key}='SAYYED ASIF ZAFAR ALI'} # AC 147, column 6
			elsif ($pc==22 && $cand{$key} eq 'Shaileshkumar Maganbhai Parmar IND') {$cand{$key}='SHAILESHKUMAR MAGANBHAI PARMAR'} # AC 154, column 13
			elsif ($pc==22 && $cand{$key} eq 'Sindhi Mayyudeen Umarbhai IND') {$cand{$key}='SINDHI MAYYUDEEN UMARBHAI'} # AC 154, column 14
			elsif ($pc==22 && $cand{$key} eq 'Sukhramsingh BSP') {$cand{$key}='SUKHRAMSINGH'} # AC 154, column 3
			elsif ($pc==22 && $cand{$key} eq 'Vasava Mansukhbhai Dhanjibhai BJP') {$cand{$key}='VASAVA MANSUKHBHAI DHANJIBHAI'} # AC 147, column 2
			elsif ($pc==22 && $cand{$key} eq 'Virsangbhai Parbatbhai Gohil IND') {$cand{$key}='VIRSANGBHAI PARBATBHAI GOHIL'} # AC 154, column 12
			elsif ($pc==25 && $cand{$key} eq 'N A') {undef($cand{$key});next} # AC 168, column 20
			elsif ($pc==6 && $cand{$key} eq 'Amarkumar Raj Prajapati') {$cand{$key}='RAJ PRAJAPATI'} # AC 55, column 15
			elsif ($pc==6 && $cand{$key} eq 'Brahmbhatt Sanjaybhai') {$cand{$key}='BRAHMBHATT SANJAYBHAI AMARKUMAR'} # AC 55, column 14
			elsif ($pc==6 && $cand{$key} eq 'L K Advani') {$cand{$key}='L. K. ADVANI'} # AC 55, column 1
			elsif ($pc==6 && $cand{$key} eq 'of') {undef($cand{$key});next} # AC 40, column 25
			elsif ($pc==7 && $cand{$key} eq 'Dutt Aakash Advocate') {$cand{$key}='DUTT AAKASH -. ADVOCATE'} # AC 49, column 6
			elsif ($pc==7 && $cand{$key} eq 'PATEL HIMMATSINGH PRAHLADSIGH') {$cand{$key}='PATEL HIMMATSINGH PRAHLADSINGH'} # AC 48, column 1
			elsif ($pc==3 && $cand{$key} eq 'PARMAR MAGANBHAI AMRABHAI') {$cand{$key}='PARMAR MAGANBHAI AMARABHAI'} # AC 19, column 1
			elsif ($pc==7 && $cand{$key} eq 'Aditya Rawal') {$cand{$key}='ADITYA RAVAL'} # AC 46, column 4
			elsif ($pc==7 && $cand{$key} eq 'Buddhipriya Jaswant Somabhai') {$cand{$key}='BUDDHPRIYA JASVANT SOMABHAI'} # AC 46, column 9
			elsif ($pc==7 && $cand{$key} eq 'Dashrathbhai M. Devada') {$cand{$key}='DASHRATHBHAI M. DEVDA'} # AC 46, column 13
			elsif ($pc==7 && $cand{$key} eq 'Datt Akash Advocate') {$cand{$key}='DUTT AAKASH -. ADVOCATE'} # AC 46, column 6
			elsif ($pc==7 && $cand{$key} eq 'Patel Himmatsinh Prahladsinh') {$cand{$key}='PATEL HIMMATSINGH PRAHLADSINGH'} # AC 46, column 1
			elsif ($pc==7 && $cand{$key} eq 'Rohit Rajubhai Virjibhai') {$cand{$key}='ROHIT RAJUBHAI VIRJIBHAI ALIAS MANOJBHAI SONTARIYA'} # AC 46, column 3
			elsif ($pc==18 && $cand{$key} eq 'MANSURI MUKHATYAR MOHAMMAD') {$cand{$key}='MANSURI MUKHATYAR MOHAMMAD (PANTER M. LALA)'} # AC 127, column 11
			elsif ($pc==18 && $cand{$key} eq 'S. N. CHAVADA') {$cand{$key}='S. N. CHAVADA (CHAVADA VAKIL)'} # AC 127, column 8
			elsif ($pc==17 && $cand{$key} eq 'Parikh Viral Hasmukbhai') {$cand{$key}='PARIKH VIRAL HASMUKHBHAI'} # AC 116, column 10
			elsif ($pc==17 && $cand{$key} eq 'Pathan Amanullakhan Sitabkhan') {$cand{$key}='PATHAN AMANULLAKHA SITABKHA'} # AC 116, column 9
			
			
			# check if candidate remains unknown
			my $re2f = $dbh->selectcol_arrayref("SELECT id FROM candidates WHERE pc = ? AND name LIKE ?",undef,$pc,$cand{$key});
			if (scalar(@$re2f) != 1) {$print{'elsif ($pc=='.$pc.' && $cand{$key} eq \''.$cand{$key}.'\') {$cand{$key}=\''."'} # AC $ac, column $key\n"}++;  $troubleac{$ac}=1; undef($cand{$key}); next key;}
			$cand{$key}=$$re2f[0];
		    }
		}
	    } else { # read in results
		if ($line =~ /VIPUL\\FORM-20 LS/) {$toggle=0; next}
		$csv->parse($line);
		my @fields=$csv->fields();
		
		next unless $fields[$pscol] =~ /\d/;
		next if ($fields[$pscol+1] == $fields[$pscol]+1 && $fields[$pscol+2] == $fields[$pscol]+2 && $fields[$pscol+3] == $fields[$pscol]+3 && $fields[$pscol+4] == $fields[$pscol]+4 && $fields[$pscol+5] == $fields[$pscol]+5);
		
		$fields[$pscol]=~s/^(\d+)*/$1/gs;
		
		my $booth = $fields[$pscol]/1;
		undef(my $total); undef(my $control);
		for ($i=0;$i<scalar(@fields);$i++) {
		    if ($fields[$i] =~ /\d/) {
			next if !defined($cand{$i});
#			$fields[$i] =~ s/\D//gs;
			if ($cand{$i} eq 'total') {$total=$fields[$i]} 
			elsif ($cand{$i} eq 'valid' or $cand{$i} eq 'tendered') {}
			else {$control=$control+$fields[$i]}
			$dbh->do("INSERT INTO results VALUES (?,?,?,?,?)",undef,$pc,$ac,$booth,$cand{$i},$fields[$i]);
		    }
		}
#		# check if vote counts add up
		if ($total != $control) {$print{"Vote count mismatch in AC $ac, booth ".$fields[$pscol].": votes add up to $control, but total column says $total!\n"}++;  $troubleac{$ac}=1; }
	    }
	    
	}
	
	# check if AC has all relevant candidates!
	if (defined($pscol)) {
	    my $re2f = $dbh->selectcol_arrayref("select name from candidates where id not in (select candidate from results where ac=? group by candidate) and pc=? and name is not null",undef,$ac,$pc);
	    foreach my $candidate (@$re2f) {$print{"Missing candidate $candidate from AC $ac!\n"}++; $troubleac{$ac}=1;}
	# TODO implement boothcount check, using GIS data as reference
	} else {
	    $print{"Empty file for AC $ac!\n"}=1; $troubleac{$ac}=1;
	}
	    
    }
    
}

# print diagnostics
foreach my $key (sort(keys(%print))) {print $key}
# foreach my $key (sort {$a <=> $b} (keys(%troubleac))) {print "Troubling AC: ".$key."\n"}

# Finally calculate the actual gujloksabha2014 table


$dbh->do ("CREATE TABLE gujloksabha2014 (id INTEGER PRIMARY KEY)");

print "Calculate gujloksabha2014 table\n";

my @realheader;
my @realselect;

$dbh->do ("ALTER TABLE gujloksabha2014 ADD COLUMN ac_id_09 INTEGER");
push(@realheader,'ac_id_09');
push(@realselect,'results.ac');
$dbh->do ("ALTER TABLE gujloksabha2014 ADD COLUMN booth_id_14 INTEGER");
push(@realheader,'booth_id_14');
push(@realselect,'results.booth');
$dbh->do ("ALTER TABLE gujloksabha2014 ADD COLUMN electors_14 INTEGER");
push(@realheader,'electors_14');
push(@realselect,'sum(case when results.candidate = "total" then results.votes end)');
$dbh->do ("ALTER TABLE gujloksabha2014 ADD COLUMN turnout_14 INTEGER");
push(@realheader,'turnout_14');
push(@realselect,'sum(case when results.candidate = "valid" then results.votes end)');
$dbh->do ("ALTER TABLE gujloksabha2014 ADD COLUMN nota_14 INTEGER");
push(@realheader,'nota_14');
push(@realselect,'sum(case when results.candidate = "nota" then results.votes end)');
$dbh->do ("ALTER TABLE gujloksabha2014 ADD COLUMN tendered_14 INTEGER");
push(@realheader,'tendered_14');
push(@realselect,'sum(case when results.candidate = "tendered" then results.votes end)');
$dbh->do ("ALTER TABLE gujloksabha2014 ADD COLUMN male_votes_14 INTEGER");
push(@realheader,'male_votes_14');
push(@realselect,'sum(case when results.candidate = "male" then results.votes end)');
$dbh->do ("ALTER TABLE gujloksabha2014 ADD COLUMN female_votes_14 INTEGER");
push(@realheader,'female_votes_14');
push(@realselect,'sum(case when results.candidate = "female" then results.votes end)');

my $ref = $dbh->selectcol_arrayref("SELECT party FROM candidates WHERE name IS NOT NULL GROUP BY party");

foreach my $party (@$ref) {
    my $oldparty = $party;
    $party =~ s/\.//gs;
    $party =~ s/\,//gs;
    $party =~ s/\)//gs;
    $party =~ s/\(/-/gs;
    $party =~ s/\s//gs;
    $party = lc($party);
    if ($party eq 'indep') {$party = 'ind'}
    if ($party eq 'indipendent') {$party = 'ind'}
    if ($party eq 'indp') {$party = 'ind'}
    if ($party eq 'indpendent') {$party = 'ind'}
    if ($party eq 'indpt') {$party = 'ind'}
    if ($party eq 'indt') {$party = 'ind'}
    if ($party eq 'independent') {$party = 'ind'}
    if ($party eq 'nir') {$party = 'ind'}
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
    if ($party eq '') {print "$party\n"}
    
    $party=~s/-/_/gs;
    my $statement="ALTER TABLE gujloksabha2014 ADD COLUMN votes_".$party."_14 INTEGER";
    $dbh->do ($statement);
    push(@realheader,'votes_'.$party.'_14');
    push(@realselect,'sum(case when candidates.shortparty = "'.$party.'" then results.votes end)');
    my $statement="ALTER TABLE gujloksabha2014 ADD COLUMN votes_".$party."_percent_14 FLOAT";
    $dbh->do ($statement);
    push(@realheader,'votes_'.$party.'_percent_14');
    push(@realselect,'sum(case when candidates.shortparty = "'.$party.'" then cast(results.votes as float) end) / sum(case when results.candidate = "valid" then cast(results.votes as float) end)');
    
    $dbh->do("UPDATE candidates SET shortparty = ? WHERE party = ?",undef,$party,$oldparty);
}

my $realsql = 'INSERT INTO gujloksabha2014 ('.join(",",@realheader).') SELECT '.join(",",@realselect).' FROM results left join candidates on results.candidate=candidates.id GROUP BY results.ac,results.booth';

$dbh->commit;
$dbh->begin_work;
$dbh->do($realsql);
$dbh->commit;

#
# Prepare the gujid table
#

$dbh->do ("CREATE TABLE gujid (ac_id_09 INTEGER, ac_name_14 CHAR, ac_reserved_14 CHAR, booth_id_14 INTEGER, station_id_14 INTEGER, station_name_14 CHAR)");
$dbh->do ("CREATE INDEX booth_id_14 ON gujid (booth_id_14)");

#
# Include Raheel's corrections
#

my $sth = $dbh->prepare("UPDATE gujloksabha2014 SET votes_bjp_14 = ?, votes_inc_14 = ?, votes_aamaadmiparty_14 = ?, nota_14 = ?, electors_14 = ?, turnout_14 = ? WHERE ac_id_09 = ? AND booth_id_14 = ?");
my $sth2 = $dbh->prepare("INSERT INTO gujloksabha2014 (votes_bjp_14, votes_inc_14, votes_aamaadmiparty_14, nota_14, electors_14, turnout_14, ac_id_09, booth_id_14) VALUES (?,?,?,?,?,?,?,?)");
my $sth3 = $dbh->prepare("INSERT INTO gujid (ac_id_09, booth_id_14, station_id_14, station_name_14) VALUES (?,?,?,?)");
$dbh->begin_work;

my $csv = Text::CSV->new();

open (CSV,"manual-corrections.csv");
my @csv=<CSV>;
close (CSV);

my $header=shift(@csv);
my $header2=shift(@csv);

foreach my $line (@csv) {
    $csv->parse($line);
    my @fields=$csv->fields();
    $sth->execute($fields[5],$fields[6],$fields[7],$fields[8],$fields[9],$fields[10],$fields[0],$fields[3]);
    if ($sth->rows==0) {$sth2->execute($fields[5],$fields[6],$fields[7],$fields[8],$fields[9],$fields[10],$fields[0],$fields[3]);}
    $sth3->execute($fields[0],$fields[3],$fields[1],$fields[2]);
}

$dbh->commit;
$sth->finish;
$sth2->finish;
$sth3->finish;

$dbh->do ("UPDATE gujloksabha2014 SET votes_bjp_percent_14 = votes_bjp_14 / turnout_14");
$dbh->do ("UPDATE gujloksabha2014 SET votes_inc_percent_14 = votes_inc_14 / turnout_14");
$dbh->do ("UPDATE gujloksabha2014 SET votes_aamaadmiparty_percent_14 = votes_aamaadmiparty_14 / turnout_14");

$dbh->do ("ALTER TABLE gujloksabha2014 ADD COLUMN turnout_percent_14 FLOAT");
$dbh->do ("UPDATE gujloksabha2014 SET turnout_percent_14 = turnout_14 / electors_14");
$dbh->do ("ALTER TABLE gujloksabha2014 ADD COLUMN female_votes_percent_14 FLOAT");
$dbh->do ("UPDATE gujloksabha2014 SET female_votes_percent_14 = female_votes_14 / turnout_14");

#
# Finally create sqlite dump 
#

print "Create dumps and CSV\n";

$dbh->sqlite_backup_to_file("temp.sqlite");

system("sqlite3 temp.sqlite '.dump gujloksabha2014' > gujloksabha2014-a.sql");
system("sqlite3 temp.sqlite '.dump gujid' > gujloksabha2014-b.sql");

open (FILE, ">>gujloksabha2014-a.sql");

print FILE ".mode csv\n";
print FILE ".headers on\n";
print FILE ".once gujloksabha2014/gujloksabha2014.csv\n";
print FILE "SELECT * FROM gujloksabha2014;\n";

close (FILE);

system("rm temp.sqlite results.sqlite");
