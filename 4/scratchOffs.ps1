
$inputfiles =  "$psscriptroot\sample.txt", "$psscriptroot\input.txt"


foreach ( $inputfile in $inputfiles ) {
    $content = Get-Content $inputfile
    $gameNumbers = @()
    $toCheck = @()
    $winningNumbers = @()
    foreach($line in $content){        
        $null, $winning, $check = $line -split "\:|\|"
        $gameNumbers += ,@($winning -split " " | ? {-not [string]::isnullorempty($_)}) 
        $toCheck += ,@($check -split " " | ? {-not [string]::isnullorempty($_)}) 
    }

    for ($i = 0 ; $i -lt $gameNumbers.Count ; $i++){
        $matched = $toCheck[$i] | Where-Object { $_ -in $gameNumbers[$i] }
        $matchCount = $matched.count ?? 0 
        $winningNumbers +=,[pscustomobject]@{
            game = ($i + 1)           
            winCount = $matchCount
            winScore = ($matchCount -gt 0) ? (1 * [math]::Pow(2, $matchCount -1 )) : 0 
            matched = $matched 
        }
        
    }
}
$winningNumbers
$winSum = 0 
$winningNumbers | % {$winSum+= $_.winScore }
$winSum
