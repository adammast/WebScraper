$import = Import-Csv "Tracker Links.csv" -header Name, Tracker

foreach ($line in $import)
{
    $name = $line.Name
    $trackerLink = $line.Tracker
    $uri = $trackerLink.substring(0, 45) + "mmr/" + $trackerLink.substring(45)
    $tracker = Invoke-WebRequest -Uri $uri
    $data = $tracker.tostring() -split "`r`n"

    $duelRatings = @()
    $doubleRatings = @()
    $soloStandardRatings = @()
    $standardRatings = @()

    for ($i=0; $i -le $data.Length; $i++)
    {
        $line = $data[$i]
        if ($line | Select-String "name:"){
            if($line | Select-String "name: 'Ranked Duel 1v1',"){
                $duelRatings = $data[$i + 2].Split('[').Split(']')[1].Split(',')
            } elseif($line | Select-String "name: 'Ranked Doubles 2v2',"){
                $doubleRatings = $data[$i + 2].Split('[').Split(']')[1].Split(',')
            } elseif($line | Select-String "name: 'Ranked Solo Standard 3v3',"){
                $soloStandardRatings = $data[$i + 2].Split('[').Split(']')[1].Split(',')
            } elseif($line | Select-String "name: 'Ranked Standard 3v3',"){
                $standardRatings = $data[$i + 2].Split('[').Split(']')[1].Split(',')
            }
        }
    }

    $max = ($duelRatings.Length, $doubleRatings.Length, $soloStandardRatings.Length, $standardRatings.Length | Measure-Object -Maximum).Maximum

    $fileName = "Scrapes/" + $name + " Initial Pull.csv"
    Add-Content -Path $fileName -Value "Name, Tracker, 1s_MMR, 2s_MMR, Solo_3s_MMR, 3s_MMR"
    for ($i=0; $i -le $max - 1; $i++){
        $duelRating = If ($duelRatings.Length -gt 1 -and $duelRatings.Length - 1 -ge $i) {$duelRatings[$i]} Else {100}
        $doubleRating = If ($doubleRatings.Length -gt 1 -and $doubleRatings.Length - 1 -ge $i) {$doubleRatings[$i]} Else {100}
        $soloStandardRating = If ($soloStandardRatings.Length -gt 1 -and $soloStandardRatings.Length - 1 -ge $i) {$soloStandardRatings[$i]} Else {100}
        $standardRating = If ($standardRatings.Length -gt 1 -and $standardRatings.Length - 1 -ge $i) {$standardRatings[$i]} Else {100}

        $string = $name + ", " + $trackerLink + ", " + $duelRating + ", " + $doubleRating + ", " + $soloStandardRating + ", " + $standardRating
        Add-Content -Path $fileName -Value $string
    }
}