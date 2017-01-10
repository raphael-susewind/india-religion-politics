#!/usr/bin/perl

my @rolls = `ls rolls*sqlite`;

foreach my $roll (@rolls) {
    chomp $roll;
    system('echo -e ".mode column\n.headers off\nselect name from rolls where community = '."'Hindu'".' and name is not null;" | sqlite3 '.$roll.' | perl -CSDA -pe '."'s/(\\P{Mark})/ \$1/g; s/^ //'".' >> ngram-hindu-raw 2>/dev/null');
    system('echo -e ".mode column\n.headers off\nselect fathername from rolls where community = '."'Hindu'".' and fathername is not null;" | sqlite3 '.$roll.' | perl -CSDA -pe '."'s/(\\P{Mark})/ \$1/g; s/^ //'".' >> ngram-hindu-raw 2>/dev/null');
    system('echo -e ".mode column\n.headers off\nselect name from rolls where community = '."'Muslim'".' and name is not null;" | sqlite3 '.$roll.' | perl -CSDA -pe '."'s/(\\P{Mark})/ \$1/g; s/^ //'".' >> ngram-muslim-raw 2>/dev/null');
    system('echo -e ".mode column\n.headers off\nselect fathername from rolls where community = '."'Muslim'".' and fathername is not null;" | sqlite3 '.$roll.' | perl -CSDA -pe '."'s/(\\P{Mark})/ \$1/g; s/^ //'".' >> ngram-muslim-raw 2>/dev/null');
    system('echo -e ".mode column\n.headers off\nselect name from rolls where community = '."'Christian'".' and name is not null;" | sqlite3 '.$roll.' | perl -CSDA -pe '."'s/(\\P{Mark})/ \$1/g; s/^ //'".' >> ngram-christian-raw 2>/dev/null');
    system('echo -e ".mode column\n.headers off\nselect fathername from rolls where community = '."'Christian'".' and fathername is not null;" | sqlite3 '.$roll.' | perl -CSDA -pe '."'s/(\\P{Mark})/ \$1/g; s/^ //'".' >> ngram-christian-raw 2>/dev/null');
    system('echo -e ".mode column\n.headers off\nselect name from rolls where community = '."'Sikh'".' and name is not null;" | sqlite3 '.$roll.' | perl -CSDA -pe '."'s/(\\P{Mark})/ \$1/g; s/^ //'".' >> ngram-sikh-raw 2>/dev/null');
    system('echo -e ".mode column\n.headers off\nselect fathername from rolls where community = '."'Sikh'".' and fathername is not null;" | sqlite3 '.$roll.' | perl -CSDA -pe '."'s/(\\P{Mark})/ \$1/g; s/^ //'".' >> ngram-sikh-raw 2>/dev/null');
    system('echo -e ".mode column\n.headers off\nselect name from rolls where community = '."'Parsi'".' and name is not null;" | sqlite3 '.$roll.' | perl -CSDA -pe '."'s/(\\P{Mark})/ \$1/g; s/^ //'".' >> ngram-parsi-raw 2>/dev/null');
    system('echo -e ".mode column\n.headers off\nselect fathername from rolls where community = '."'Parsi'".' and fathername is not null;" | sqlite3 '.$roll.' | perl -CSDA -pe '."'s/(\\P{Mark})/ \$1/g; s/^ //'".' >> ngram-parsi-raw 2>/dev/null');
    system('echo -e ".mode column\n.headers off\nselect name from rolls where community = '."'Buddhist'".' and name is not null;" | sqlite3 '.$roll.' | perl -CSDA -pe '."'s/(\\P{Mark})/ \$1/g; s/^ //'".' >> ngram-buddhist-raw 2>/dev/null');
    system('echo -e ".mode column\n.headers off\nselect fathername from rolls where community = '."'Buddhist'".' and fathername is not null;" | sqlite3 '.$roll.' | perl -CSDA -pe '."'s/(\\P{Mark})/ \$1/g; s/^ //'".' >> ngram-buddhist-raw 2>/dev/null');
    system('echo -e ".mode column\n.headers off\nselect name from rolls where community = '."'Jain'".' and name is not null;" | sqlite3 '.$roll.' | perl -CSDA -pe '."'s/(\\P{Mark})/ \$1/g; s/^ //'".' >> ngram-jain-raw 2>/dev/null');
    system('echo -e ".mode column\n.headers off\nselect fathername from rolls where community = '."'Jain'".' and fathername is not null;" | sqlite3 '.$roll.' | perl -CSDA -pe '."'s/(\\P{Mark})/ \$1/g; s/^ //'".' >> ngram-jain-raw 2>/dev/null');
}

system("ngram-count -order 3 -text ngram-hindu-raw -lm ngram-hindu-lm -kndiscount -interpolate -unk");
system("ngram-count -order 3 -text ngram-muslim-raw -lm ngram-muslim-lm -kndiscount -interpolate -unk");
system("ngram-count -order 3 -text ngram-christian-raw -lm ngram-christian-lm -kndiscount -interpolate -unk");
system("ngram-count -order 3 -text ngram-sikh-raw -lm ngram-sikh-lm -kndiscount -interpolate -unk");
system("ngram-count -order 3 -text ngram-parsi-raw -lm ngram-parsi-lm -kndiscount -interpolate -unk");
system("ngram-count -order 3 -text ngram-buddhist-raw -lm ngram-buddhist-lm -kndiscount -interpolate -unk");
system("ngram-count -order 3 -text ngram-jain-raw -lm ngram-jain-lm -kndiscount -interpolate -unk");

system("rm -f ngram*raw");
