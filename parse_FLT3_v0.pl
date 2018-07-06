use warnings;
use File::Find;
#use PerlIO::gzip;
use File::Basename;
use File::Find::Rule;
#use String::Util qw(trim);

no warnings; 

$list = $ARGV[0];
$output= $ARGV[1];

print "\n\n\n=======================================================================================\n";
print "=======================================================================================\n";
print "=======================================================================================\n";
print "This will merge Flt3ITD SUMMARY result from all samples from the input path \n";
print "=======================================================================================\n";
print "=======================================================================================\n";
print "=======================================================================================\n";
print "\nThe format is parsexxx.pl input.txt output.txt \n";
print "\n input.txt is the output of lk get_outdirs -fi projects__pk X -fi name FLT3ITD\n";
print"\n output.txt is the summary of passed events in each sample (or none where there was no ITD event.\n";
print "=======================================================================================\n";
print "=======================================================================================\n";

my @res;
my $counter=0;

open(INFO, $list) or die("Could not open the list of FLT3 output directories. $list");

open(my $OUT, '>', $output) or die "Could not open output file to write '$output' $!";

print "SAMPLE\tType\tStart\tcDNA_change\tProtein_change\tVAF\tTotalCov\tDirecory\n";
print $OUT "SAMPLE\tType\tStart\tcDNA_change\tProtein_change\tVAF\tTotalCov\tDirectory\n";

while (my $line=<INFO>){
   
   chomp;

   chomp $line;

   my @file = File::Find::Rule->file()->name("*.annot.vcf.summary.txt")->in($line);

   push @res,@file;
}
close(INFO);


foreach(@res) {
  
    $counter++;

    my $sum_file= $_;;
   
    #print "start file $sum_file...\n";

    open(my $FH,$sum_file) or die "Error opening file:$!\n";

    my $flt3_tag=0;
   

    while (($nextline=<$FH>) && ($nextline !~ /.*Filtered.*/)){
       last if ($nextline =~ /.*Pass:.*/);
      }


      if ($nextline =~ /.*Pass:.*/){
     
      # Excecusion gets here if the line is "Pass" or it has exceeded the EOF...
      # Read the rest of the lines until to reach EOF ot Fileted or --- 
      # This means fetch out all records after the tag "Pass" at the beginning of a file
      
		$nextline=<$FH>; #skip the -- line after Pass

      while (($nextline=<$FH>) && ($nextline !~ /^\s*$/) && ($nextline !~ /.*Filtered.*/)  && ($nextline !~ /^\-.*/)){
        

           # Search for the pattern Type this will be the 1st line of the new record...
           while (($nextline !~ /.*Type.*/) && ($nextline !~ /.*Filtered.*/)  && ($nextline !~ /^\-.*/)){
                 $nextline=<$FH>;
            }
           

            my ( $mytype ) = $nextline =~ /Type=([\w\:]*)/;
            
            # the 2nd line (after Type) is for CDNA-change/Protein-change info ...           
			   $nextline = <$FH>;
			   $nextline =~ s/^\s*//g;
            
            $flt3_tag=1;

			   my ( $cdna_change ) = $nextline =~ /hgvs.c=(.*[\w\+]*),/;
			   my ( $prt_change ) = $nextline =~ /hgvs.p=(.*\w*)/;
			   
            # the 3rd line (after Type) is for POS info ...
			   $nextline = <$FH>;
            $nextline =~ s/^\s*//g;
			
			   my ($pos) = $nextline =~ /^(\d+)/;		
                        
            # the 4th line (after Type) is for SAMPLE, VAF and COV info ...
			   $nextline = <$FH>;
            $nextline =~ s/^\s*//g;

 			   my ( $sample ) = $nextline =~ /smpl=([\w\-]*)/;

			   my ($vaf) = $nextline =~ /vaf=([\d\.?]*)/;
			   my ($tc) = $nextline =~ /tc=(\d*)/;

            # the record of Pass event to STD and output\n";
			   print "Sample $counter\t$sample\t$mytype\t$pos\t$cdna_change\t$prt_change\t$vaf\t$tc\t$sum_file\n";
            print $OUT "$sample\t$mytype\t$pos\t$cdna_change\t$prt_change\t$vaf\t$tc\t$sum_file\n"; 
            
            #print "Finished phase 2...\n";
            next if $nextline =~ /^\s*$/;
            
            #print "ready to loop on phase 2: line is $nextline\n";

      }
   } elsif ($flt3_tag==0){
         $basename = basename($sum_file,".annot.vcf.summary.txt");
         $basename =~ s/PINDEL_//g;
         print "Sample $counter\t$basename\tNone\tNA\tNA\tNA\tNA\tNA\t$sum_file\n";
         print $OUT "$basename\tNone\tNA\tNA\tNA\tNA\tNA\t$sum_file\n";
      }

      close(FH);
      print "----------------------------------------------------------------------------------------------------------------------\n";
      print $OUT  "----------------------------------------------------------------------------------------------------------------------\n";
}

print "END OF FILE\n";
#close(INFO);
close(OUT);

