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
$dbh->do ("ALTER TABLE booths ADD COLUMN thana CHAR");
$dbh->do ("ALTER TABLE booths ADD COLUMN taluk CHAR");
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
    
    my $right=2364;
    my $left=167;
    my $top=1098;
    my $bottom=2132;
    my $width=$right-$left;
    my $height=$bottom-$top;
    my $bufferx=int($left/300*72);
    my $buffery=int(842-($top+$height)/300*72);
    system("gs -q -r300 -dFirstPage=1 -dLastPage=1 -sDEVICE=tiffgray -sCompression=lzw -o temp.tif -g".$width."x".$height." -c '<</Install {-$bufferx -$buffery translate}>> setpagedevice' -f $file");
    my $parts = `tesseract -psm 4 -l hin  --tessdata-dir /home/area-mnni/rsusewind/share/tessdata temp.tif stdout`;
    my $right=1596;
    my $left=167;
    my $top=2133;
    my $bottom=2599;
    my $width=$right-$left;
    my $height=$bottom-$top;
    my $bufferx=int($left/300*72);
    my $buffery=int(842-($top+$height)/300*72);
    system("gs -q -r300 -dFirstPage=1 -dLastPage=1 -sDEVICE=tiffgray -sCompression=lzw -o temp.tif -g".$width."x".$height." -c '<</Install {-$bufferx -$buffery translate}>> setpagedevice' -f $file");
    my $parts .= `tesseract -psm 4 -l hin  --tessdata-dir /home/area-mnni/rsusewind/share/tessdata temp.tif stdout`;

    my $right=1512;
    my $left=749;
    my $top=2678;
    my $bottom=2797;
    my $width=$right-$left;
    my $height=$bottom-$top;
    my $bufferx=int($left/300*72);
    my $buffery=int(842-($top+$height)/300*72);
    system("gs -q -r300 -dFirstPage=1 -dLastPage=1 -sDEVICE=tiffgray -sCompression=lzw -o temp.tif -g".$width."x".$height." -c '<</Install {-$bufferx -$buffery translate}>> setpagedevice' -f $file");
    my $name = `tesseract -psm 4 -l hin  --tessdata-dir /home/area-mnni/rsusewind/share/tessdata temp.tif stdout`;

    my $right=1512;
    my $left=504;
    my $top=2798;
    my $bottom=2930;
    my $width=$right-$left;
    my $height=$bottom-$top;
    my $bufferx=int($left/300*72);
    my $buffery=int(842-($top+$height)/300*72);
    system("gs -q -r300 -dFirstPage=1 -dLastPage=1 -sDEVICE=tiffgray -sCompression=lzw -o temp.tif -g".$width."x".$height." -c '<</Install {-$bufferx -$buffery translate}>> setpagedevice' -f $file");
    my $address = `tesseract -psm 4 -l hin  --tessdata-dir /home/area-mnni/rsusewind/share/tessdata temp.tif stdout`;

    my $right=2364;
    my $left=1920;
    my $top=2150;
    my $bottom=2506;
    my $width=$right-$left;
    my $height=$bottom-$top;
    my $bufferx=int($left/300*72);
    my $buffery=int(842-($top+$height)/300*72);
    system("gs -q -r300 -dFirstPage=1 -dLastPage=1 -sDEVICE=tiffgray -sCompression=lzw -o temp.tif -g".$width."x".$height." -c '<</Install {-$bufferx -$buffery translate}>> setpagedevice' -f $file");
    my $box = `tesseract -psm 4 -l hin  --tessdata-dir /home/area-mnni/rsusewind/share/tessdata temp.tif stdout`;
    $box =~ s/\n\s+/\n/gs;
    my @box = split(/\n/,$box);
    
    $dbh->do("UPDATE booths SET name = ?, address = ?, parts = ?, village = ?, thana = ?, taluk = ?, district = ?, pincode = ? WHERE booth = ?",undef,$name,$address,$parts,$box[0],$box[1],$box[2],$box[3],$pincode,$booth);
}

system("rm temp.tif");

$dbh->disconnect;
undef($dbh);
