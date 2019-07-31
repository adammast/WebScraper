$import = Import-Csv "Tracker Links.csv" -header Name, Tracker

$index = 0
$total = $import.Count

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

    $fileName = "Scrapes/DE Initial Pull.csv"
    for ($i=0; $i -le $max - 1; $i++){
        $duelRating = If ($duelRatings.Length -gt 1 -and $duelRatings.Length - 1 -ge $i) {$duelRatings[$i]} Else {''}
        $doubleRating = If ($doubleRatings.Length -gt 1 -and $doubleRatings.Length - 1 -ge $i) {$doubleRatings[$i]} Else {''}
        $soloStandardRating = If ($soloStandardRatings.Length -gt 1 -and $soloStandardRatings.Length - 1 -ge $i) {$soloStandardRatings[$i]} Else {''}
        $standardRating = If ($standardRatings.Length -gt 1 -and $standardRatings.Length - 1 -ge $i) {$standardRatings[$i]} Else {''}

        $string = $name + ", " + $trackerLink + ", " + $duelRating + ", " + $doubleRating + ", " + $soloStandardRating + ", " + $standardRating
        Add-Content -Path $fileName -Value $string
    }

    $index++
    $index.ToString() + "/" + $total + " completed"
}