Function CreateLink($line)
{
    $split = $line.Tracker.Split('/')

    switch ($split[4]) {
        "steam" {$platformId = 1; break}
        "PS4" {$platformId = 2; break}
        "Xbox" {$platformId = 3; break}
        "Switch" {$platformId = 4; break}
        default {$platformId = 1; break}
    }

    $playerId = $split[5]
    $link = "https://api.rlstats.net/v1/profile/stats?apikey=key&platformid=platform&playerid=player"

    Return $link.Replace("=key", "=" + $key).Replace("=platform", "=" + $platformId).Replace("=player", "=" + $playerId)
}

Function GetRating($seasonData, $playlist)
{
    $playlistData = $seasonData.$playlist
    $rating = $playlistData.SkillRating

    if(-Not $rating){
        Return ""
    }

    Return $rating
}

$import = Import-Csv "TrackerLinks.csv" -header Name, Tracker, '1s_MMR', '2s_MMR', 'Solo_3s_MMR', '3s_MMR'
$key = Read-Host -Prompt 'Input your api key'
$currentSeason = 11

$index = 0
$total = $import.Count

$startTime = (Get-Date)

foreach ($line in $import)
{
    if(($line.Name -ne "") -and ($line.Tracker -ne "")){
        $link = CreateLink($line)

        $tracker = Invoke-RestMethod -Uri $link
        $seasonData = $tracker.RankedSeasons.$currentSeason

        $line.'1s_MMR' = GetRating($seasonData)(10)
        $line.'2s_MMR' = GetRating($seasonData)(11)
        $line.Solo_3s_MMR = GetRating($seasonData)(12)
        $line.'3s_MMR' = GetRating($seasonData)(13)
    }

    $index++
    $index.ToString() + "/" + $total + " completed"
}

$endTime = (Get-Date)

'Total Elapsed Time: {0:hh} hrs {0:mm} mins {0:ss} secs' -f ($endTime-$startTime)

$now = get-date -format g
$import | Export-Csv -Path "Scrapes/$((Get-Date).ToString('yyyy-MM-dd_HH-mm-ss')).csv" -NoTypeInformation