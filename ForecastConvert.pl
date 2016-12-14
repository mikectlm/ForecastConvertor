
use Cwd;
use File::Copy;
use File::Basename;

$dir = getdcwd();
my $config_file = getdcwd() . '\ForecastConvert.cfg';

open (CONFIG,"${config_file}") || die "Can't open $config_file";
	#first line contains scheduler
	my ($scheduler,$client) = split (/\|/, <CONFIG>);
	chomp ($scheduler);
	chomp ($client);

	#rest contains forecast files
	while ($config_line=<CONFIG>) {
	  chomp ($config_line);
	  ($odate,$file) = split (/\|/,$config_line);
	   $FileByOdate{$odate} = $file;  
	}
close (CONFIG);

#### CONTROL-M SETTINGS
my $user = "xtmab";
my $passwd = "88ZwRDu";
my $GUI = "LCBO-WLA";

## PROJECT SETTINGS
#Control-M name
my $ctm_name = "LCBO";
my $ctm_index;

#USE IF START WILL BE USED HEADERS
#TRANSLATES FROM GMT+00:00 to time specified by hours
#my $time_offset = "+3";
my $time_offset = "-5";

#Specify PARENT_TABLE or APPLICATION 
#APPLICATION | PARENT_TABLE | JOB_MEM_NAME | START
my @cols = ("PARENT_TABLE", "JOB_MEM_NAME", "START");
#########USE FOR ZEEEEEEEEEKEEEEEE################
#my @cols = ("APPLICATION", "JOB_MEM_NAME", "START");

#ext_cols refers to the one or two main values for comparison in external scheduler file
my @ext_cols = ("PARENT_TABLE", "JOB_MEM_NAME");
####ZEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEKE####
#my @ext_cols = ("APPLICATION", "JOB_MEM_NAME");

my $ext_mode = @ext_cols;

##CTM Forecast Files (These are generated - specify a work location)
&SetTime();

&SetDirectories();

## END OF VARIABLES

#MAIN LOOP
foreach $odate (keys %FileByOdate) {
	
	print "START " . $odate . "\n";	
	&CreateAndMassageCTMForecastFile();
	&MassageExtForecastFile();
	
	#$ctm_file and $ext_file
	#$CtmInput and $ExtInput
	undef %ExtInput;
	undef %CtmInput;	
	&CreateDataDictionary();
	
	&ForecastValidationExt2Ctm();
	&ForecastValidationCtm2Ext();
	print "END " . $odate . "\n";
}
#END MAIN LOOP

sub CreateAndMassageCTMForecastFile {	

	$fc_file = $ctmforecast_dir . '\FC_forecast_' . $odate . '.txt';
	#$fc_file = 'D:\Projects\ValForecastMassage\tests\FC_forecast.txt';
	$ctm_file = $ctmforecast_dir . '\FC_forecast_massaged_' . $odate . '.txt';


	# Comment this line to use an existing $fc_file instead of dynamic generation
	`forecastcli -u ${user} -p ${passwd} -s ${GUI} -odate ${odate} -job_info_file ${fc_file}`;


	open CTM_FCFILE, $fc_file or die $!;
	open CTM_MASSAGED, ">", $ctm_file or die $!;

	my $headerline = <CTM_FCFILE>;
	my @headers = split(',',$headerline);
	my @headersindex;

	$ctm_index = grep { $headers[$_] =~ /DATA_CENTER/ } 0..$#headers;

	foreach $col (@cols) 
	{
		my( $index )= grep { $headers[$_] =~ /${col}/ } 0..$#headers;	
		push @headersindex, $index;	
	}

	#print out the header record
	print CTM_MASSAGED join( ',', @cols );
	print CTM_MASSAGED "\n";

	while (my $record = <CTM_FCFILE>) 
	{
		my @records = split(',', $record);
		
		if ($records[$ctm_index] =~ $ctm_name and $record !~ /SMART Table/)
		{			
			my $outputline;
			foreach $index (@headersindex)
			{
				my $field = $records[$index];
				#print $field;
				#trim quotes
				
				$field =~ s/"//g;;
				#trim white space
				$field =~ s/^\s+|\s+$//g;
				
				
				if ($headers[$index] =~ "START")
				{
					#print $headers[$index] . " ";
					#print $field . " ";
					$field = UpdateTime($field);
					#print $field . "\n";
				}
				
				$outputline = $outputline . $field . ",";
			
			}
			print CTM_MASSAGED $outputline . "\n";		
		}
	}
	close (CTM_FCFILE);
	close (CTM_MASSAGED);
}


sub SetTime {

	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
	$yyyymmdd = sprintf "%.4d%.2d%.2d", $year+1900, $mon+1, $mday;
	$hhmmss = sprintf "%.2d%.2d%.2d", $hour, $min, $sec;
}

sub UpdateTime {
	my $temptime = $_[0];
	
	#no calculated time
	if ($temptime eq "---")
	{
		return "";
	}
	else
	{
		my @timevar = split(' ', $temptime);
		my $timeportion = @timevar[0];
		my ($hh,$mm,$ss) = split(':', $timeportion);
		
		my $op = substr $time_offset, 0,1;
		my $offset = substr $time_offset, 1;
		
		if ($op eq "+")
		{
			my $new_hh = $hh + $offset;
			if ($new_hh >= 24)
			{
				$new_hh = $new_hh - 24;
			}
		}
		else 
		{
			$new_hh = $hh - $offset;
			if ($new_hh < 0)
			{
				$new_hh = $new_hh + 24;
			}
		}
		if ($new_hh < 10) {
			return "0${new_hh}:${mm}:${ss}"; }
		else {
			return "${new_hh}:${mm}:${ss}"; }
	}
}

sub SetDirectories {

	$main_dir = $dir . '\\' . $scheduler . "_"	. $yyyymmdd . $hhmmss;
	mkdir $main_dir or die $!;
	
	$ctmforecast_dir = $main_dir . '\\ctm_forecasts';
	mkdir $ctmforecast_dir or die $!;

	$sch_dir = $main_dir . '\\' . $scheduler . '_forecasts';
	mkdir $sch_dir or die $!;;
	
	$results_dir = $main_dir . '\\results';
	mkdir $results_dir or die $!;
}

sub MassageExtForecastFile {

	$ext_filename = basename($FileByOdate{$odate});
	print $ext_filename . "\n";
	$ext_file = $sch_dir . '\\' . $ext_filename;
	$ext_orig = $ext_file . '.orig';
	copy $FileByOdate{$odate}, $ext_orig ;
	
	open EXT_FILE, $ext_orig or die $!;
	open EXT_MASSAGED, ">", $ext_file or die $!;

	$jobortable = 1; #used for TWS
	$ca_unicenter_currjobset = "";
	
	while (my $line = <EXT_FILE>) 
	{ 	
		$massaged = &ExtMassager($line);
		if ($massaged ne "") {
			print EXT_MASSAGED $massaged;
		}
	}
	close (EXT_FILE);
	close (EXT_MASSAGED);
}

sub ExtMassager {
	my $line = shift;
	#print $line;
	
	if ($scheduler eq "ZEKE")	{
	##ADDING APP and JOB
		#first line matches job headers
		#2nd matches header operations
		if ($line !~ /1ZEKE/ and $line !~ /SCHEDULE/ and $line !~ /EVENT NAME/ and $line !~ /HIT DATE/ 
		and $line !~ /Z02D6I/ and $line !~ /Z02A1I/ and $line !~ /Z02B.I/ and $line != "0" and $line !~ /ZEKE UTILITY PROGRAM/)  {	
		
			# trim jobname up to 8 chars 
			my $jobname = substr $line, 75, 8;
			$jobname =~ s/^\s+|\s+$//g;
			
			my $timedate = substr $line, 21, 5;
		
			my $appl = substr $line, 39, 8;		
			$appl =~ s/^\s+|\s+$//g;
			
			return $appl . "," . $jobname . "," . $timedate . "\n";
		}		
	}
	elsif ($scheduler eq "CA7")	{
		#JOBNAME ONLY
		#empty lines
		if ($line =~ /\S/ and
		#page header parts
		$line !~ /1FJOB/ and $line !~ /CA-7/ and $line !~ /PERIOD/ and $line !~ /START DTTM/ and
		#Top of Page Filters
		$line !~ /BSTR/ and $line !~ /\/LOG/ and $line !~ /TRIG=JD/ and
		$line !~ /JOB\(S\)/ and $line !~ /SYSTEM\(S\)/ and $line !~ /HIGHEST/ and $line !~ /INCLUDED/
		#Bottom of Page Filgers
		and $line !~ /REQUEST COMPLETED/
		)  
		{	
			# trim jobname up to 8 chars 
			my $jobname = substr $line, 24, 8;
			$jobname =~ s/^\s+|\s+$//g;
			
			my $timedate = substr $line, 7, 4;
		
			#my $appl = substr $line, 39, 8;		
			#$appl =~ s/^\s+|\s+$//g;
			
			return $jobname . "," . $timedate . "\n";
		}		
	
	}
	elsif ($scheduler eq "LSAR")	{
	##ADDING TABLE and JOB
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
			
			$size = scalar @applqual;

			if ($size == 3) {
				return "$applqual[0],$jobname,$timedate,$applqual[1]\n";
			}
			else 
			{
				return "$applqual[0],$jobname,$timedate\n";
			}
		}
	}
	elsif ($scheduler eq "CAScheduler")	{
		
		
	}
	elsif ($scheduler eq "TWS")	{
		##ADDING TABLE and JOB
	
		if ($line =~ /${client}/)
		{
			ExtMassageSkipLine(2);
		}	
		#line starts with multiple spaces		
		elsif ($line !~ /^\s{2,}/ and $line !~ /^\s\-/ and $line !~ /^\-/ and $line !~ /APPL ID/ and $line !~ /OWNER ID*OP ID/)
		{
			$modcalc = $jobortable % 2;
			
			if ($modcalc == 0)
			{
				my $jobname = substr $line, 0, 18;
				$jobname =~ s/^\s+|\s+$//g;
				my $timedate = substr $line, 18, 5;
				$timedate =~ s/^\s+|\s+$//g;
				
				$jobortable+=1;
				return $jobname . "," . $timedate . "\n";
				
			}
			else 
			{
				my $table = substr $line, 0, 18;
				$table =~ s/^\s+|\s+$//g; 
				$jobortable+=1;
				return $table . ",";
			}
			
		}
	}
	elsif ($scheduler eq "CA-Unicenter")	{
		##ADDING TABLE and JOB
	
		#ExtMassageSkipLine(2);
	
		#filter line is not empty and header lines
		if ($line =~ /\S/ and $line ne "************************************************************" and $line !~ /FORECAST REPORT/)
		{
			##clean leading strings
			$line =~ s/^\s+|\s+$//g;
			
			if ($line =~ /Jobset/)
			{
				#SPLIT ON COMMA's SHOULD CREATE 3 array
				#Jobset = pabm_bat_030_p, Early Start Date = 09/24/2015, Early Start Time = 07:00:00
				
				my @linerec = split(/,/, $line);
				#SPLIT FIRST SECTION ON = returns {jobset,table}
				my @tablerec = split(/=/, $linerec[0]);				
				$ca_unicenter_currjobset = $tablerec[1];
				
				$ca_unicenter_currjobset =~ s/^\s+|\s+$//g; 
							
			}
			else 
			{
				#SPLIT ON COMMANDS SHOULD CREATEA 5 array
				 #Job = pabm010p, Jno = 0001, Qual = 2401, Early Start Date = 09/24/2015, Early Start Time = 08:00:00
				my @linerec = split(/,/, $line);
				#Split on = to return job,jobname
				my @jobrec = split(/=/, $linerec[0]);
				
				my $jobname = $jobrec[1];
				$jobname =~ s/^\s+|\s+$//g;
				
				my @timerec = split(/=/, $linerec[4]);
				my $timedate = $timerec[1];
				$timedate =~ s/^\s+|\s+$//g;
								
				return $ca_unicenter_currjobset . "," . $jobname . "," . $timedate . "\n";			
			}
		}
	}
	return "";
}

sub ExtMassageSkipLine() {
	my $skips = shift;
	for (my $i = 0; $i<$skips; $i++)
	{
		$discard = <EXT_FILE>;
	}
	#print "DISCARDED $skips LINES\n";

}

sub CreateDataDictionary {

	##EXTERNAL FILE FIRST
	
	open EXT_FILE, $ext_file or die $!;
	
	while (my $record = <EXT_FILE>) 
	{
		chomp $record;
		$job = "";
		$table = "";
		$info = "";
		
		@line = split (',',$record);
		
		##JOB ONLY MODE
		if ($ext_mode == 1)	
		{
		
			$job =  @line[0];
			
			if (length($record) - length($job) > 0) {
				$info = substr $record, length($job) + 1, length($record) - length($job) -1;
			}
			
			# IF CTM job Exists in the hash, add it with count suffix (table is no matter)
			if (exists $ExtInput{$job})
			{
				$bAdded = 0;
				$iCount = 0;
				do {
					if (not exists $ExtInput{$job . "_" . $iCount})
					{
						#ExtInput[job1][job] = info
						$ExtInput{$job . "_" . $iCount} = {job=> $job, info => $info};
						$bAdded = 1;
					}
					else 
					{
						$iCount++;
					}

				} while (not $bAdded);
			}
			else
			{
				$ExtInput{$job} = {job=> $job, info => $info};
			}
		}                           
		##job and table   
		else 
		{
			$table = @line[0];
			$job =  @line[1];
			$suboninfo = $table . ',' . $job;
			$info = substr $record, length($suboninfo) + 1, length($record) - length($suboninfo) -1;
			
			if (exists $ExtInput{$job})
			{
				$bAdded = 0;
				$iCount = 0;
				do {
					if (not exists $ExtInput{$job . "_" . $iCount})
					{
						$ExtInput{$job . "_" . $iCount} = {table => $table, job => $job, info => $info};
						$bAdded = 1;
					}
					else 
					{
						$iCount++;
					}

				} while (not $bAdded);				
			}
			else {
				$ExtInput{$job} = {table => $table, job => $job, info => $info};
			}
		}
	}
	close (EXT_FILE);
	

	
	##CTM FILE NOW
	open CTM_FILE, $ctm_file or die $!;
	#open CTM_FILE, "C:\\Projects\\ValForecastMassage\\TWS_20150422114801\\ctm_forecasts\\FC_forecast_massaged_20140108.txt" or die $!;
		
	while (my $record = <CTM_FILE>) {
	
		chomp $record;
		@line = split (',',$record);
		$table = @line[0];
		$job =  @line[1];
		$suboninfo = $table . ',' . $job;
		$info = substr $record, length($suboninfo) + 1, length($record) - length($suboninfo) -1;
		
		

		if (exists $CtmInput{$table}) {
			if (exists $CtmInput{$table}{$job}) {					
				$bAdded = 0;
				$iCount = 0;
				
				do {
					$job_alias = $job . "_" . $iCount;
					if (not exists $CtmInput{$table}{$job_alias})
					{
						$CtmInput{$table}{$job . "_" . $iCount} = { "job" => $job, "info" => $info};
						$bAdded = 1;
					}
					else 
					{
						$iCount++;
					}

				} while (not $bAdded);				
			}
			else {
				$CtmInput{$table}{$job} = { "job" => $job, "info" => $info};
			}				
		}	
		else {
			$CtmInput{$table}{$job} = { "job" => $job, "info" => $info};			
		}
	} 
    close (CTM_FILE);
	
	#open TEMP_FILE, ">", $results_dir . "\\ctm_data.txt" or die $!;
	#foreach $table (keys %CtmInput) {
	#	foreach $job (keys %{$CtmInput{$table}}) {	
			#print TEMP_FILE $table . "," . $CtmInput{$table}{$job}{"job"}  . "," . $CtmInput{$table}{$job}{"info"} . "\n";	
		#}
	#}
	#close (TEMP_FILE);
	
	#open TEMP_FILE, ">", $results_dir . "\\ext_data.txt" or die $!;
	#foreach $job_alias (keys %ExtInput) {
	#		print TEMP_FILE $job_alias . "," . $ExtInput{$job_alias}{"table"} . "," . $ExtInput{$job_alias}{"job"}  . "," . $ExtInput{$job_alias}{"info"} . "\n";	
	#	}
	#close (TEMP_FILE);
}

sub ForecastValidationExt2Ctm {
	
	$ext2ctm = $results_dir . '\\OrigToControlM_' . $odate . '.csv';
	
	open EXT2CTM, ">", $ext2ctm or die $!;
	
	print EXT2CTM "OrigTable,OrigJob,CTMTable,CTMJob,STATUS,OrigInfo,CTMInfo\n";
	
	foreach $sOrig (keys %ExtInput) {
		$iFindCount = 0;
		
		$sOrigTable = "";
		$sOrigJob = "";
		$sOrigInfo = "";

		if ($ext_mode == 1) {
			$sOrigJob = $ExtInput{$sOrig}{"job"};
			$sOrigInfo = $ExtInput{$sOrig}{"info"};
		}
		else {
			$sOrigTable = $ExtInput{$sOrig}{"table"};
			$sOrigJob = $ExtInput{$sOrig}{"job"};
			$sOrigInfo = $ExtInput{$sOrig}{"info"};
		}

		foreach $sCtmTable (keys %CtmInput) {
			foreach $sCompare (keys %{$CtmInput{$sCtmTable}}) {
				#sCompare is the job ALIAS (in most cases same as the job)
				
				$sCtmJob = $CtmInput{$sCtmTable}{$sCompare}{"job"};
				$sCtmInfo = $CtmInput{$sCtmTable}{$sCompare}{"info"};
	
				#reset
				$bCompare = 0;

				if ($ext_mode == 1)	{
					$bCompare = ($sCtmJob cmp $sOrigJob);
				}
				else {
					$bCompare = ($sCtmJob cmp $sOrigJob) and ($sCtmTable cmp $sOrigTable);
				}
				#print $bCompare . "\n";
				if ($bCompare == 0)	{
				
					$iFindCount++;
					if ($iFindCount > 1) {
						print EXT2CTM $sOrigTable . "," . $sOrigJob . "," . $sCtmTable . "," . $sCtmJob . "," . "DUPLICATE" . "," . $sOrigInfo . "," . $sCtmInfo . "\n";
					}
					else {
						print EXT2CTM $sOrigTable . "," . $sOrigJob . "," . $sCtmTable . "," . $sCtmJob . "," . "MATCH" . "," . $sOrigInfo . "," . $sCtmInfo . "\n";
					}
				}
			}
		}
		if ($iFindCount == 0)
		{
			print EXT2CTM $sOrigTable . "," . $sOrigJob . ",,," . "MISSING IN CTM," . $sOrigInfo . "\n";
		}
	}
	close (EXT2CTM);
}

sub ForecastValidationCtm2Ext {

	$ctm2ext = $results_dir . '\\ControlMToOrig_' . $odate . '.csv';

	open CTM2EXT, ">", $ctm2ext or die $!;
	
	print CTM2EXT "CTMTable,CTMJob,OrigTable,OrigJob,STATUS,OrigInfo,CTMInfo\n";
	
	foreach $sCtmTable (keys %CtmInput) {
	
		foreach $sCompare  (keys %{$CtmInput{$sCtmTable}}) {
		
			$iFindCount = 0;
						
			$sCtmJob = $CtmInput{$sCtmTable}{$sCompare}{"job"};
			$sCtmInfo = $CtmInput{$sCtmTable}{$sCompare}{"info"};
			
			$sOrigTable = "";
			$sOrigJob = "";
			$sOrigInfo = "";
			
			foreach $sOrig (keys %ExtInput) {
			
				if ($ext_mode == 1)	{					
					$sOrigJob = $ExtInput{$sOrig}{"job"};
					$sOrigInfo = $ExtInput{$sOrig}{"info"};
				}
				else
				{
					$sOrigTable = $ExtInput{$sOrig}{"table"};
					$sOrigJob = $ExtInput{$sOrig}{"job"};
					$sOrigInfo = $ExtInput{$sOrig}{"info"};
				}
				#reset
				$bCompare = 0;

				if ($ext_mode == 1)
				{
					$bCompare = ($sCtmJob cmp $sOrigJob);
				}
				else 
				{
					$bCompare = ($sCtmJob cmp $sOrigJob) and ($sCtmTable cmp $sOrigTable);
				}
				
				if ($bCompare == 0)
				{
					$iFindCount++;
					if ($iFindCount > 1) {
						print CTM2EXT $sCtmTable . "," . $sCtmJob . "," . $sOrigTable . "," . $sOrigJob . "," . "DUPLICATE" . "," . $sOrigInfo . "," . $sCtmInfo . "\n";
					}
					else {
						print CTM2EXT $sCtmTable . "," . $sCtmJob . "," . $sOrigTable . "," . $sOrigJob . "," . "MATCH" . "," . $sOrigInfo . "," . $sCtmInfo . "\n";
					}
				}
			}
			if ($iFindCount == 0)	{
				print CTM2EXT $sCtmTable . "," . $sCtmJob . ",,," . "MISSING IN ORIGINAL DATA,," . $sCtmInfo . "\n";
			}
	}
	close (EXT2CTM);        
	}

}

