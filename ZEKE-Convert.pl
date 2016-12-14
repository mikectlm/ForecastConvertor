


$inputfile = 'C:\Users\mbobbato\Documents\Work\SentryInsurance\zeke\Forecast 9-16 .txt';
$outputfile = 'C:\Users\mbobbato\Documents\Work\SentryInsurance\zeke\Zeke_Massaged.txt';

open INPUTFILE, $inputfile or die $!;
open OUTPUTFILE, ">", $outputfile or die $!;

while (my $line = <INPUTFILE>) 
{ 	
	#trim whitespace
	#$line =~ s/^\s+|\s+$//g;
	
	#first line matches job headers
	#2nd matches header operations
	
	if ($line !~ /1ZEKE/ and $line !~ /SCHEDULE/ and $line !~ /EVENT NAME/ and $line !~ /HIT DATE/ 
		and $line !~ /Z02D6I/ and $line !~ /Z02A1I/ and $line !~ /Z02B.I/ and $line != "0" and $line !~ /ZEKE UTILITY PROGRAM/) 
	{	
		# trim jobname up to 8 chars 
		my $jobname = substr $line, 75, 8;
		$jobname =~ s/^\s+|\s+$//g;
		
		my $timedate = substr $line, 21, 5;
	
		my $appl = substr $line, 39, 8;		
		$appl =~ s/^\s+|\s+$//g;
		
		$outline = "$appl,$jobname,$timedate\n";

		print OUTPUTFILE $outline; 
		#print OUTPUTFILE "$line\n";
	}
	else
	{	
		#print "pass";
	}
	#<STDIN>;
	
	
	
	#print OUTPUTFILE $line; 
	
}