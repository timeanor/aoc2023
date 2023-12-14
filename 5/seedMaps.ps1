#requires -version 7.0

$inputfiles =  "$psscriptroot\sample.txt", "$psscriptroot\input.txt"

function proc_ranges($inputNum, $map){    
    foreach ($struction in $map.instructions) {
        $range = ( $struction.src )..( $struction.src + $struction.len -1 )
        if ($s -in $range) {
             return $struction.dst + $range.indexof($s)
        }     
    } 
    return $inputNum
}

foreach ( $inputfile in $inputfiles[1] ) 
{
    $content = get-content $inputfile -raw
    $seeds = ($content -split "`n" | Select-Object -First 1 ) -split ":| " | Where-Object {$_} | select-object -skip 1 | ForEach-Object {[UInt32]$_}
    $rgxPattern = [regex]"(?sm)^(?<name>[\w-]*) map:\s*(?<map>(?:\d+\s*)+)"
    $mapMatches = $rgxPattern.Matches( $content )

    $maps = @()
    
    foreach ($match in $mapMatches) {  
        $mapGroup = $match.Groups["map"].Value -split "`r`n" | Where-Object {$_}  
        $map = @{
            Name = $($match.Groups["name"].Value)
        }
        $values = @()
        foreach ($item in $mapGroup){                
            $r = @($item -split " " | Where-Object {$_})            
            $values += ,[pscustomobject]@{
                            dst = [UInt32]$r[0]
                            src = [UInt32]$r[1]
                            len = [UInt32]$r[2]
                        }
        }
        $map.instructions = $values
        $maps += ,[pscustomobject]$map
    }

    $minLocation = @()
    for ($i = 0; $i -lt $seeds.count; $i++)
    { 
        Write-Progress -Activity "Seed:  $i of $($Seeds.count)" -PercentComplete (($i / $Seeds.count) *100)  -id 1
        $s = $seeds[$i] 
        for ($j =0; $j -lt $maps.count; $j++)
        {
            $map = $maps[$j]
            Write-Progress -Activity "map:   $($map.Name)" -PercentComplete (($maps.IndexOf($map) /$map.count) *100)  -id 2 -ParentId 1
            $s = proc_ranges $s $map
        }
        $minLocation += ,$s
        # write-host "seed $seed $($map.Name) location = $s`n" -NoNewline -ForegroundColor Cyan
    }
    $minLocation | sort-object | select-object -first 1

}