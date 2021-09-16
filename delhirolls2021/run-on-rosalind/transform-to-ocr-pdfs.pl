#!/usr/bin/perl

system('rm temp*');

my @files = `find . -name '*pdf'`;

foreach my $file (@files) {
    chomp ($file);
    $file =~ /(\d+)-(\d+)/gs; 
    my $ac=$1;
    my $booth=$2;
    my $new = $file;
    $new =~ s/.pdf$/-ocr.pdf/gs;
    next if $file=~/ocr/;
    next if -e $new;
    # Extract images and run tesseract to recreate as searcheable PDF, overwriting original PDF
    print "Processing $file into $new\n";
    system('gs -dSAFER -dQUIET -dNOPLATFONTS -dNOPAUSE -dBATCH -sOutputFile="temp%d" -sDEVICE=pngalpha -r300 -dTextAlphaBits=4 -dGraphicsAlphaBits=4  -dUseTrimBox '.$file);
    system('ls -v temp* | singularity exec /scratch/users/k1639346/tesseract-ocr_latest.sif tesseract -l hin+eng --tessdata-dir /scratch/users/k1639346/tessdata_best/ -c stream_filelist=true - - pdf > '.$new);
    system('rm temp*');
    system("rm $file");
}
