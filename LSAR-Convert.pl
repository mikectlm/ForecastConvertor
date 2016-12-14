
$inputfile = 'C:\Users\mbobbato\Documents\Work\Wegmans\WEGMANS.MF\LSAR.txt';
$outputfile = 'C:\Users\mbobbato\Documents\Work\Wegmans\WEGMANS.MF\LSAR_Massaged.txt';

open INPUTFILE, $inputfile or die $!;
open OUTPUTFILE, ">", $outputfile or die $!;

while (my $line = <INPUTFILE>) 
{ 	
	#trim whitespace
	$line =~ s/^\s+|\s+$//g;
	if ($line !~ /AM02 BATCH INTERFACE/ and $line !~ /^0\s*/ and $line !~ /LSAR DSNAME/ and $line !~ /AVERAGE/ and $line !~ /EXEC/ and $line !~ /SPEC NON-SP/)
	{	
		# trim jobname up to 10 chars is
		my $jobname = substr $line, 0, 8;
		#trim end whitespace
		$jobname =~ s/^\s+|\s+$//g;
		my $timedate = substr $line, 11, 11;
		#application, return from 81st on, split on spaces
		my @applqual = split(/\s* /, substr $line, 81);
		
		print "$applqual[1]\n";
		$size = scalar @applqual;

		if ($size == 3) {
			$outline = "$applqual[0],$jobname,$timedate,$applqual[1]\n";
		}
		else 
		{
			$outline = "$applqual[0],$jobname,$timedate\n";
		}
		print OUTPUTFILE $outline; 
	}
	else
	{	
		#print "pass";
	}
	#<STDIN>;
	
	
	
	#print OUTPUTFILE $line; 
	
}