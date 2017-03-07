#!/usr/bin/perl

use DBI;
use utf8;

my $constituency=$ARGV[0];
chomp $constituency;

# Connect to database and alter structure
my $dbh = DBI->connect("dbi:SQLite:dbname=$constituency.sqlite","","",{sqlite_unicode => 1});

$dbh->do ("ALTER TABLE booths ADD COLUMN name CHAR");
$dbh->do ("ALTER TABLE booths ADD COLUMN address CHAR");
$dbh->do ("ALTER TABLE booths ADD COLUMN parts CHAR");
$dbh->do ("ALTER TABLE booths ADD COLUMN village CHAR");
$dbh->do ("ALTER TABLE booths ADD COLUMN postoffice CHAR");
$dbh->do ("ALTER TABLE booths ADD COLUMN block CHAR");
$dbh->do ("ALTER TABLE booths ADD COLUMN thana CHAR");
$dbh->do ("ALTER TABLE booths ADD COLUMN tehsil CHAR");
$dbh->do ("ALTER TABLE booths ADD COLUMN district CHAR");
$dbh->do ("ALTER TABLE booths ADD COLUMN pincode INTEGER");

# Iterate through frontpages
my @files= `ls *pdf`;

foreach my $file (@files) {
    $file =~ /(\d+)-(\d+)/gs;
    $booth=$2;
    chomp ($file);

    my $frontpage = `pdftotext -f 1 -l 1 -nopgbrk $file -`;
    $frontpage =~ /(\d\d\d\d\d\d)/gs;
    my $pincode = $1;
    if ($pincode !~ /\d\d\d\d\d\d/) {undef($pincode)}
    
    my $right=2382;
    my $left=110;
    my $top=1180;
    my $bottom=1794;
    my $width=$right-$left;
    my $height=$bottom-$top;
    my $bufferx=int($left/300*72);
    my $buffery=int(842-($top+$height)/300*72);
    system("gs -q -r300 -dFirstPage=1 -dLastPage=1 -sDEVICE=tiffgray -sCompression=lzw -o temp.tif -g".$width."x".$height." -c '<</Install {-$bufferx -$buffery translate}>> setpagedevice' -f $file");
    my $parts = `tesseract -psm 4 -l hin  --tessdata-dir /home/area-mnni/rsusewind/share/tessdata temp.tif stdout`;
    my $right=1377;
    my $left=110;
    my $top=1795;
    my $bottom=1374;
    my $width=$right-$left;
    my $height=$bottom-$top;
    my $bufferx=int($left/300*72);
    my $buffery=int(842-($top+$height)/300*72);
    system("gs -q -r300 -dFirstPage=1 -dLastPage=1 -sDEVICE=tiffgray -sCompression=lzw -o temp.tif -g".$width."x".$height." -c '<</Install {-$bufferx -$buffery translate}>> setpagedevice' -f $file");
    my $parts .= `tesseract -psm 4 -l hin  --tessdata-dir /home/area-mnni/rsusewind/share/tessdata temp.tif stdout`;

    my $right=1504;
    my $left=110;
    my $top=2530;
    my $bottom=2650;
    my $width=$right-$left;
    my $height=$bottom-$top;
    my $bufferx=int($left/300*72);
    my $buffery=int(842-($top+$height)/300*72);
    system("gs -q -r300 -dFirstPage=1 -dLastPage=1 -sDEVICE=tiffgray -sCompression=lzw -o temp.tif -g".$width."x".$height." -c '<</Install {-$bufferx -$buffery translate}>> setpagedevice' -f $file");
    my $name = `tesseract -psm 4 -l hin  --tessdata-dir /home/area-mnni/rsusewind/share/tessdata temp.tif stdout`;

    my $right=1504;
    my $left=110;
    my $top=2720;
    my $bottom=2830;
    my $width=$right-$left;
    my $height=$bottom-$top;
    my $bufferx=int($left/300*72);
    my $buffery=int(842-($top+$height)/300*72);
    system("gs -q -r300 -dFirstPage=1 -dLastPage=1 -sDEVICE=tiffgray -sCompression=lzw -o temp.tif -g".$width."x".$height." -c '<</Install {-$bufferx -$buffery translate}>> setpagedevice' -f $file");
    my $address = `tesseract -psm 4 -l hin  --tessdata-dir /home/area-mnni/rsusewind/share/tessdata temp.tif stdout`;

    my $right=2382;
    my $left=1760;
    my $top=1818;
    my $bottom=2284;
    my $width=$right-$left;
    my $height=$bottom-$top;
    my $bufferx=int($left/300*72);
    my $buffery=int(842-($top+$height)/300*72);
    system("gs -q -r300 -dFirstPage=1 -dLastPage=1 -sDEVICE=tiffgray -sCompression=lzw -o temp.tif -g".$width."x".$height." -c '<</Install {-$bufferx -$buffery translate}>> setpagedevice' -f $file");
    my $box = `tesseract -psm 4 -l hin  --tessdata-dir /home/area-mnni/rsusewind/share/tessdata temp.tif stdout`;
    $box =~ s/\n\s+/\n/gs;
    my @box = split(/\n/,$box);
    
    $dbh->do("UPDATE booths SET name = ?, address = ?, parts = ?, village = ?, postoffice = ?, block = ?, thana = ?, tehsil = ?, district = ?, pincode = ? WHERE booth = ?",undef,$name,$address,$parts,$box[0],$box[1],$box[2],$box[3],$box[4],$box[5],$pincode,$booth);
}

system("rm temp.tif");

$dbh->disconnect;
undef($dbh);
