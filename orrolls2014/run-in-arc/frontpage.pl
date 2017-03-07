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
$dbh->do ("ALTER TABLE booths ADD COLUMN panchayat CHAR");
$dbh->do ("ALTER TABLE booths ADD COLUMN block CHAR");
$dbh->do ("ALTER TABLE booths ADD COLUMN thana CHAR");
$dbh->do ("ALTER TABLE booths ADD COLUMN tehsil CHAR");
$dbh->do ("ALTER TABLE booths ADD COLUMN division CHAR");
$dbh->do ("ALTER TABLE booths ADD COLUMN district CHAR");
$dbh->do ("ALTER TABLE booths ADD COLUMN pincode INTEGER");

# Iterate through frontpages
my @files= `ls *Mother.pdf`;

foreach my $file (@files) {
    $file =~ /(\d+)-(\d+)/gs;
    $booth=$2;
    chomp ($file);

    my $frontpage = `pdftotext -f 1 -l 1 -nopgbrk $file -`;
    $frontpage =~ /(\d\d\d\d\d\d)/gs;
    my $pincode = $1;
    if ($pincode !~ /\d\d\d\d\d\d/) {undef($pincode)}
    
    my $right=2346;
    my $left=120;
    my $top=1096;
    my $bottom=1420;
    my $width=$right-$left;
    my $height=$bottom-$top;
    my $bufferx=int($left/300*72);
    my $buffery=int(842-($top+$height)/300*72);
    system("gs -q -r300 -dFirstPage=1 -dLastPage=1 -sDEVICE=tiffgray -sCompression=lzw -o temp.tif -g".$width."x".$height." -c '<</Install {-$bufferx -$buffery translate}>> setpagedevice' -f $file");
    my $parts = `tesseract -psm 4 -l ori  --tessdata-dir /home/area-mnni/rsusewind/share/tessdata temp.tif stdout`;
    my $right=1377;
    my $left=120;
    my $top=1421;
    my $bottom=2195;
    my $width=$right-$left;
    my $height=$bottom-$top;
    my $bufferx=int($left/300*72);
    my $buffery=int(842-($top+$height)/300*72);
    system("gs -q -r300 -dFirstPage=1 -dLastPage=1 -sDEVICE=tiffgray -sCompression=lzw -o temp.tif -g".$width."x".$height." -c '<</Install {-$bufferx -$buffery translate}>> setpagedevice' -f $file");
    my $parts .= `tesseract -psm 4 -l ori  --tessdata-dir /home/area-mnni/rsusewind/share/tessdata temp.tif stdout`;

    my $right=1374;
    my $left=722;
    my $top=2322;
    my $bottom=2460;
    my $width=$right-$left;
    my $height=$bottom-$top;
    my $bufferx=int($left/300*72);
    my $buffery=int(842-($top+$height)/300*72);
    system("gs -q -r300 -dFirstPage=1 -dLastPage=1 -sDEVICE=tiffgray -sCompression=lzw -o temp.tif -g".$width."x".$height." -c '<</Install {-$bufferx -$buffery translate}>> setpagedevice' -f $file");
    my $name = `tesseract -psm 4 -l ori  --tessdata-dir /home/area-mnni/rsusewind/share/tessdata temp.tif stdout`;

    my $right=1374;
    my $left=120;
    my $top=2570;
    my $bottom=2725;
    my $width=$right-$left;
    my $height=$bottom-$top;
    my $bufferx=int($left/300*72);
    my $buffery=int(842-($top+$height)/300*72);
    system("gs -q -r300 -dFirstPage=1 -dLastPage=1 -sDEVICE=tiffgray -sCompression=lzw -o temp.tif -g".$width."x".$height." -c '<</Install {-$bufferx -$buffery translate}>> setpagedevice' -f $file");
    my $address = `tesseract -psm 4 -l ori  --tessdata-dir /home/area-mnni/rsusewind/share/tessdata temp.tif stdout`;

    my $right=2346;
    my $left=1700;
    my $top=1450;
    my $bottom=2118;
    my $width=$right-$left;
    my $height=$bottom-$top;
    my $bufferx=int($left/300*72);
    my $buffery=int(842-($top+$height)/300*72);
    system("gs -q -r300 -dFirstPage=1 -dLastPage=1 -sDEVICE=tiffgray -sCompression=lzw -o temp.tif -g".$width."x".$height." -c '<</Install {-$bufferx -$buffery translate}>> setpagedevice' -f $file");
    my $box = `tesseract -psm 4 -l ori  --tessdata-dir /home/area-mnni/rsusewind/share/tessdata temp.tif stdout`;
    $box =~ s/\n\s+/\n/gs;
    my @box = split(/\n/,$box);
    
    $dbh->do("UPDATE booths SET name = ?, address = ?, parts = ?, village = ?, panchayat = ?, block = ?, thana = ?, tehsil = ?, division = ?, district = ?, pincode = ? WHERE booth = ?",undef,$name,$address,$parts,$box[0],$box[1],$box[2],$box[3],$box[4],$box[5],$box[6],$pincode,$booth);
}

system("rm temp.tif");

$dbh->disconnect;
undef($dbh);
