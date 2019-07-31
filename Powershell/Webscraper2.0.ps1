Function GetRank([string]$rankSearchString, $data)
{
    if($rankData = $data | Select-String $rankSearchString)
    {
        $rankSplit = $rankData[0].ToString().Split('[').Split(']')
        $rankSplitChild = $rankSplit[1].Split(',')
        if($rankSplitChild[-1] -ne "")
        {
            Return $rankSplitChild[-1]
        }
    }
    Return ''
}

$import = Import-Csv "Tracker Links - RLTN Links.csv" -header Name, Tracker, '1s_MMR', '2s_MMR', 'Solo_3s_MMR', '3s_MMR'

$index = 0
$total = $import.Count

$startTime = (Get-Date)

foreach ($line in $import)
{
    $tracker = Invoke-WebRequest -Uri $line.Tracker

    $data = $tracker.tostring() -split "`r`n" | Select-String "name:"
    
    $line.'1s_MMR' = GetRank("name: 'Ranked Duel 1v1'") ($data)
    $line.'2s_MMR' = GetRank("name: 'Ranked Doubles 2v2'") ($data)
    $line.Solo_3s_MMR = GetRank("name: 'Ranked Solo Standard 3v3'") ($data)
    $line.'3s_MMR' = GetRank("name: 'Ranked Standard 3v3'") ($data)
	
	if($line.'1s_MMR' -eq '' -and $line.'2s_MMR' -eq '' -and $line.Solo_3s_MMR -eq '' -and $line.'3s_MMR' -eq ''){
		#couldn't find stats, either bad tracker link or some error in attempting to fetch the site. Try again
		$tracker = Invoke-WebRequest -Uri $line.Tracker

		$data = $tracker.tostring() -split "`r`n" | Select-String "name:"
		
		$line.'1s_MMR' = GetRank("name: 'Ranked Duel 1v1'") ($data)
		$line.'2s_MMR' = GetRank("name: 'Ranked Doubles 2v2'") ($data)
		$line.Solo_3s_MMR = GetRank("name: 'Ranked Solo Standard 3v3'") ($data)
		$line.'3s_MMR' = GetRank("name: 'Ranked Standard 3v3'") ($data)
	}

    $index++
    $index.ToString() + "/" + $total + " completed"

    #$rnd = Get-Random -Minimum 5 -Maximum 10
    #Start-Sleep -Seconds $rnd
}

$endTime = (Get-Date)

'Total Elapsed Time: {0:hh} hrs {0:mm} mins {0:ss} secs' -f ($endTime-$startTime)

$now = get-date -format g
$import | Export-Csv -Path "Scrapes/$((Get-Date).ToString('yyyy-MM-dd_HH-mm-ss'))_RLTN.csv" -NoTypeInformation