
$inputfiles =  ("$psscriptroot\sample.txt", "$psscriptroot\input.txt")


function resolve-copies (){
    [CmdletBinding()]
    param($copy)
         
    $i = $gameCards.IndexOf($copy)

    Write-Progress -Activity "game $($i+1) instances $($copy.instances) " -id 2 -ParentId -1
    foreach ( $c in $copy.copyIndexes ){ 
        Write-Progress -Activity "recursing into game $($c+1)" -id 3 -ParentId 2  
        $gameCards[$c].instances += 1
        resolve-copies $gameCards[$c]
    }

}

foreach ( $inputfile in $inputfiles ) 
{
    $content = Get-Content $inputfile
    $gameCards = @()

    foreach ( $line in $content ) 
    {                
        $null, $winning, $check = $line -split "\:|\|"
        $game =  @($winning -split " " | Where-Object {-not [string]::isnullorempty($_)}) 
        $numbers = @($check -split " " | Where-Object {-not [string]::isnullorempty($_)})        
        $matchCount = ($numbers | Where-Object { $_ -in $game }).count ?? 0 
        $gameCards += ,[PSCustomObject]@{ 
                            game = $game
                            numbers = $numbers 
                            matchCount = $matchCount
                            score = ($matchCount -gt 0) ? ( [math]::Pow( 2, $matchCount -1 )) : 0             
                            copyIndexes = ($matchCount -gt 0) ? (($content.indexof($line) +1 )..($content.indexof($line) + $matchCount)) : $null 
                            instances = 1
                        }
    }

    $gamecards | Where-Object { $_.copyIndexes } | ForEach-Object { 
        Write-Progress -Activity ( "resolving copies for " + $gamecards.indexof($_)) -PercentComplete (( $gamecards.indexof($_)/$gamecards.Count ) * 100) -id 1 
        resolve-copies $_
    }

    $w = 0 
    $gameSum = 0 
    ($gamecards.score | ForEach-Object { $w += ($_) })
    ($gamecards.instances | ForEach-Object { $gameSum  += ($_) })
    [pscustomobject]@{
        Input = ($inputfile -split "\\")[-1]
        WinSum =  $w 
        GameSum =  $gameSum
    }   
}

