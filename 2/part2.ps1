
param ([string]$inputFile = "$psscriptroot\input.txt")

$count = 0 
# named capture groups 
$rgb_pattern = "(?<red>\d{1,2}).red|(?<green>\d{1,2}).green|(?<blue>\d{1,2}).blue"
$recorded_games = get-content $inputFile
$game_pow_sum = 0 
foreach ( $game in $recorded_games ) {
    $count++   
    $game_num,$pulls = $game -split ":"
    $power_tracker = [ordered]@{
        red = 1
        green = 1
        blue = 1
    }
    
    foreach ( $pull in ($pulls -split ";")){   
        $m = $pull | Select-String -pattern $rgb_pattern -AllMatches
        $s = $m.Matches.Groups | Where-Object { $_.success -and $_.name -ne 0 } 
        $s | ForEach-Object {           
            $power_tracker.($_.name) = if([int]$_.value -gt $power_tracker.($_.name)) { [int]$_.value } else { $power_tracker.($_.name) }
        }       
    }   

    $game_pow = ([int]$power_tracker.red * [int]$power_tracker.green * [int]$power_tracker.blue)
    $game_pow_sum += $game_pow
}

$game_pow_sum 