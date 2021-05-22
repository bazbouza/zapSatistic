#!/usr/bin/perl 

use strict;
use warnings;
use DateTime;
use Getopt::Long;

#die "usage: /usr/bin/perl $0 file1 file2.\n" if(($#ARGV + 1) == 0) ; 

just for test
#  this table will stock all statistic hash of log files
our @GlobalStatisticZapResult = ();

# ARGV passed by the script
my $csvExport = "OFF"; # by default the script does't generate the csv files
my @filesNameArr = () ;



parseParams() || die "uage: /usr/bin/perl $0 [option] -csv ON/OFF -F file1*file2*file...\nExp : perl $0 -F file1.log#file2.log \n      Perl $0 -csv ON -F file1.log#file2.log";
# parse log files
parseLogFiles();
displayZapStatistic();



sub parseParams{
   my $files = "";
   GetOptions(
    "csv=s"   => \$csvExport,   
    "F=s"     => \$files,
   );
   #print "files = ".$files."\n";
   if(length($files) > 0){
     @filesNameArr = split /#/, $files;   
   }
   return @filesNameArr; 
}

sub parseLogFiles{
   
 
  foreach my $file (@filesNameArr) {
       $newZapCount = 0;	
       $parsingFileBreaked= 0;
       # new instanciation for each file parsing 
       my %currentSatisticZapResult;
       
       print $file." is currently parsing\n"; 	
       open my $fh, '<:encoding(UTF-8)', $file or die;
       while (my $line = <$fh>) {
          
          if ($line =~ /$REG1/){ 
             $zapLineLog = $line; 
           }
      		
          if(length($zapLineLog) != 0 && $line =~ /$REG2/) {
      	   # retrieve the date of live dispaly
              $currentLine = $line	;
      	      my @liveDisplayLine = split / /, $currentLine;
      	      my @startZapLine = split / /, $zapLineLog;
                             
              my $isRegularStartZapTime = (getRegularDate($startZapLine[0]))[0];
              my $isRegularLiveDispaly = (getRegularDate($liveDisplayLine[0]))[0];  
              # break file parsing if it's wrongly timestamped  
              if (($isRegularStartZapTime+$isRegularLiveDispaly) != 2){
                   $parsingFileBreaked = 1;
                   print "ERROR : File is wrongly timestamped\n" ; 
                   last;
              }
              $currentSatisticZapResult{$newZapCount}{'startZapDate'} =  (getRegularDate($startZapLine[0]))[1] ;
              $currentSatisticZapResult{$newZapCount}{'zappingDuration'} = getZapDuration($startZapLine[2] , $liveDisplayLine[2]);
              # increment the counter
              $newZapCount++;
      
              # reset the zapLineLog
      	      $zapLineLog = "";
          }
       }#end wile
       close($file);
       if($parsingFileBreaked == 0){
          # save the total zap in the parsed log file
          $currentSatisticZapResult{'info'}{'totalZap'} = $newZapCount ; 
          # save the current statistic array 
          push(@GlobalStatisticZapResult, \%currentSatisticZapResult);
       }
  }#end foreach
} 


sub displayZapStatistic{
    my $size = @GlobalStatisticZapResult ;
    for(my $cpt = 0 ; $cpt < $size ; $cpt++){
       if($csvExport eq "ON"){
  	    openCSVfiles($filesNameArr[$cpt]);
       }
       
       my $hashSize = $GlobalStatisticZapResult[$cpt]->{'info'}->{'totalZap'};
       for(my $jj = 0 ; $jj < $hashSize ; $jj++) {
           if($csvExport eq "OFF"){  
              print  $jj.'   '.$GlobalStatisticZapResult[$cpt]->{$jj}->{'startZapDate'}.'   '.$GlobalStatisticZapResult[$cpt]->{$jj}{'zappingDuration'}." sec\n";
           }else{
              print FH $GlobalStatisticZapResult[$cpt]->{$jj}->{'startZapDate'}.','.$GlobalStatisticZapResult[$cpt]->{$jj}{'zappingDuration'}."\n";
           }
       }
       
       closeCSVfiles()  if ($csvExport eq "ON");
       print "/////////   END OF PARSING the Log File : $filesNameArr[$cpt]   //////////\n";
   }
}


sub getRegularDate {
    my $stringToConvert = shift; 
    if  ($stringToConvert =~ /^([0-9]{4})([0-9]{2})([0-9]{2})T([0-9]{2})([0-9]{2})([0-9]{2})/) {	
	 return (1,$1.'/'.$2.'/'.$3.' '.$4.':'.$5.':'.$6);
    }
    else 
    {
        return (0,"ERROR");
    }
}

sub openCSVfiles{
    my $parsedLogName = shift;
    open (FH, ">$parsedLogName.csv") or die "$!";
    # add first line 
    print FH "Date, Duration\n";
}

sub closeCSVfiles{
   close(FH);
}

sub getZapDuration{
    my ($startTime , $endTime) = @_; #"05:07:53.249"
    my $diff =  to_milli($endTime) - to_milli($startTime);
    return ($diff/1000);
}

sub to_milli {
    my @components = split /[:\.]/, shift;
    return (($components[0] * 60 + $components[1]) * 60 + $components[+2]) * 1000 + $components[3];
}


