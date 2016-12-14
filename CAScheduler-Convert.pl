


$inputfile = 'C:\Users\mbobbato\Documents\Work\Motorists\CONV\OPFOREC2.JOB06221\OPFOREC1.JOB06214.txt';
$outputfile = 'D:\Projects\ValForecastMassage\CAScheduler-Massaged.txt';

open INPUTFILE, $inputfile or die $!;
open OUTPUTFILE, ">", $outputfile or die $!;

while (my $line = <INPUTFILE>) 
{ 	
	#trim whitespace
	#$line =~ s/^\s+|\s+$//g;
	
	#first line matches job headers
	#2nd matches header operations
	
	if ($line !~ /1ZEKE/ and $line !~ /SCHEDULE/ and $line !~ /EVENT NAME/ and $line !~ /HIT DATE/ 
		and $line !~ /IEF236I/ and $line !~ /IEF237I/ and $line !~ /Z02B.I/ and $line != "0" and $line !~ /ZEKE UTILITY PROGRAM/) 
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