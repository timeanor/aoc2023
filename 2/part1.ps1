
param ([string]$inputFile = "$psscriptroot\input.txt")

$game_num_sum = 0 
$count = 0 
$recorded_games = Get-Content $inputFile

$rgb_pattern = "(?<red>\d{1,2}).red|(?<green>\d{1,2}).green|(?<blue>\d{1,2}).blue"


$rbg_cubes_in_the_bag = @{ 
    red = 12
    green = 13
    blue = 14
}

foreach ( $game in $recorded_games ) {
    $count++   
    $game_num,$pulls = $game -split ":"
    
    $bPullGood = $true
    foreach ( $pull in ($pulls -split ";")){   
        $m = $pull | Select-String  -pattern $rgb_pattern -AllMatches
        $successes = $m.Matches.Groups | Where-Object { $_.success -and $_.name -ne 0 } 
        $successes | ForEach-Object {
            write-host "`th:$($rbg_cubes_in_the_bag.($_.name)) r:$($_.value ) $( $rbg_cubes_in_the_bag.($_.name) -ge $_.value )" -ForegroundColor Blue
            $bPullGood = $bPullGood -and ( $rbg_cubes_in_the_bag.($_.name) -ge $_.value )
        }
                
    }   
    $game_num_sum += $( $bPullGood ? $count : 0 ) 
    write-host " $game_num   $bPullGood  sum: $game_num_sum "
}

$game_num_sum
