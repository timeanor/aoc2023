#requires -version 7.0
function test-InRange( $num, $low, $high ){
    # The sample data was too easy on Powershell......
    $geMin = $num -ge $low
    $leMax = $num -lt $high        
    return ( $geMin -and  $leMax ) ? ( $num - $low ),$true : $num,$false
}

function proc_ranges( $inputNum, $map ){ 
    $t = $inputNum     
    foreach ($instru in $map.instructions) {        
        $pos,$inRange = test-InRange $inputNum $instru.src ($instru.src + $instru.len)
        $t = ($inRange) ? $instru.dst + $pos : $t        
    }
    return $t
}


$inputfiles =  "$psscriptroot\sample.txt", "$psscriptroot\input.txt"

foreach ( $inputfile in $inputfiles ) 
{
#region load input
    $content = get-content $inputfile -raw
    $seeds = ($content -split "`n" | Select-Object -First 1 ) -split ":| " | Where-Object {$_} | select-object -skip 1 | ForEach-Object {[UInt32]$_}
    $rgxPattern = [regex]"(?sm)^(?<name>[\w-]*) map:\s*(?<map>(?:\d+\s*)+)"
    $mapMatches = $rgxPattern.Matches( $content )

    $maps = @()
    
    foreach ($match in $mapMatches) {  
        $mapGroup = $match.Groups["map"].Value -split "`r`n" | Where-Object {$_}  
        $map = @{ Name = $($match.Groups["name"].Value) }
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
#endregion load input

#region process data 
    $minLocation = @()
    foreach ( $seed in $Seeds ){       
        $s = $seed 
        foreach ( $map in $maps ){            
            $s = proc_ranges $s $map 
        }
        $minLocation += ,$s
    }
#endregion process data 
#get the smallest 

    [pscustomobject]@{
        Input = ($inputfile -split "\\")[-1]
        Part1 =  $minLocation | sort-object | select-object -first 1
        Part2 =  $null 
    }   
}