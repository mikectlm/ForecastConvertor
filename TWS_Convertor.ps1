     
    
#BEFORE RUNNING DELETE INITIAL LINES INCLUDING HEADER

$sFile = "C:\Users\mbobbato\Documents\Work\SWGAS\swg.tws.ltp.rpt.orig.txt";

$date = Get-Date -format "yyyyMMddHHmm"
$sOutputFile = "C:\Users\mbobbato\Documents\Work\SWGAS\swg.tws.ltp.rpt." + $date + ".txt";

$sCompanyFilter = "1SOUTHWEST GAS CORPORATION";
    
Function Table($iLine)
{
    if (($iLine % 2) -eq 0) 
    {
        return $false;
    }
    else
    {
        return $true;
    }
}

Function Skippable($sLine)
{
    #If it starts with multiple spaces, can be skipped
    if ($sLine.StartsWith("   "))
    {
        return $true;
    }
    #If it starts with a dash or space dash can be  skiped
    elseif ($sLine.StartsWith(" -") -OR $sLine.StartsWith("-"))
    {
        return $true;
    }    
    #Headers Catch
    elseif ($sLine.StartsWith(" APPL ID") -OR $sLine.StartsWith(" OWNER ID/OP ID"))
    {
        return $true;
    }
    return $false;
}


$l = new-Object System.Collections.Generic.List[string]
$sb = new-Object System.Text.StringBuilder;

$sr = new-Object System.IO.StreamReader("$sFile");

while( ($sLine = $sr.ReadLine()) -ne $null)  
{

    if ($sLine.StartsWith($sCompanyFilter))
    {
        #skip 2 lines
        for ($i = 1; $i -le 3; $i++)
        {
            $dump = $sr.ReadLine();
        }

    }
    elseif (!(Skippable($sLine)))
    {
        $l.Add($sLine);
    }
    
}
$sr.Close();

$iLine = 1;
foreach ($s in $l)
{
    #write-host $s >> "C:\Users\mbobbato\Documents\Work\SWGAS\file.txt"
    
    if ((Table($iLine)) -eq "true")
    {
        #Sets the table to a line by itself with , appended
        [void]$sb.Append($s.Substring(0, 18).Trim() + ",");
    }
    else #job, add a line
    {
        [void]$sb.AppendLine($s.Substring(0,18).Trim() + "," + $s.Substring(18,5).Trim());                    
    }
    $iLine++;
}

$sw = new-Object System.IO.StreamWriter($sOutputFile);
$sw.WriteLine($sb.ToString());
$sw.Close();

        

