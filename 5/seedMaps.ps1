


$inputfiles =  "$psscriptroot\sample.txt"#, "$psscriptroot\input.txt"

foreach ( $inputfile in $inputfiles ) 
{
    $content = get-content $inputfile -raw
    $seeds = ($content -split "`n" | Select-Object -First 1 ) -split ":| " | Where-Object {$_} | select-object -skip 1 | ForEach-Object {[int]$_}
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
                            dst = [int]$r[0]
                            src = [int]$r[1]
                            len = [int]$r[2]
                        }
        }
        $map.instructions = $values
        $maps += ,[pscustomobject]$map
    }
    
    foreach ( $seed in $Seeds ){       
        $s = $seed 
        foreach ( $map in $maps ){
            write-host " $s -> $($map.name) "
            foreach ($struction in $map.instructions) {
                $range = ( $struction.src )..( $struction.src + $struction.len -1 )
                $s = ($s -in $range) ? $struction.dst + $range.indexof($s) : $s
            }
        }
        $s
    }


}