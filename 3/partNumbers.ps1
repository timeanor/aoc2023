


class partnumber {
    [object]$cells = @()
    [int]$value
    [bool]$isPartNumber
    [bool]$isGear

}
class cog {
    [object]$cells = @()
}

function resolve-vector($x1,$y1,$x2,$y2){
    
     
}

$inputfiles =  "$psscriptroot\sampledata.txt"#, "$psscriptroot\inputData.txt"

foreach ( $inputfile in $inputfiles ) {
    $partNumbers = @()
    $cogs = @()
    $matrix = @()
    $content = Get-Content $inputfile
    $matrix += ".$("." * ($content[0].Length))."
    $content | ForEach-Object { $matrix += ,((".$_.").ToCharArray()) }
    $matrix += ".$("." * ($content[0].Length))."

    for ( [int]$i = 1; $i -lt $matrix.GetUpperBound(0); $i++ ){   
        for ( [int]$j = 1; $j -lt $matrix[1].Count; $j++ ){
            if ($matrix[$i][$j] -match "\*"){ $cogs += @($i,$j) }
            if ($matrix[$i][$j] -match "\d"){   
                $partnumber = [partnumber]::new()              
                while ($matrix[$i][$j] -match "\d"){
                    $partnumber.cells += @($i, $j)  # transposed as y,x
                    $j++
                }                
                $partNumbers += $partnumber
            } 
        } 
    }
return 
    $partNumber_Sum = 0 
    foreach ( $part in $partNumbers ){
        
        foreach ($cell in $part.cells){
            $y,$x = $cell[0,1]
            $part.value += [int]($matrix[$y][$x])
        }           
        foreach ($blah in $cogs){
            $s = [math]::max($s - 1, 0 )
            $e = [math]::min($e + 2, $matrix[0].Length -1 )
                
            for ($k = $p.line -1; $k -lt $part.line + 2; $k++ ){
                for ($l = $s; $l -lt $e; $l++){
                    $part.isPartNumber = $part.isPartNumber -or ($matrix[$k][$l] -match "[^\d|^\.]")
                    $part.isGear = $part.isGear -or ($matrix[$k][$l] -match "\*") 
                    if ( $part.isGear ){ $part.gear = ($k, $l) }
                }
            }
        }           
    }

    $partNumbers | Where-Object { $_.isPartNumber } | ForEach-Object { $partNumber_Sum += $_.value }
    $gears =  $partNumbers | Where-Object { $_.isGear }
    #part 2
    $ratioSum = 0
    # $prevGear = $gears[0]
    $gearRatio = 1
    # foreach ( $gear in ( $gears[1..-1] ) ){
    #     $X1eqY2 = $gear.gear[0] -eq $prevGear.gear[0]
    #     $X1eqX2 = $gear.gear[0] -eq $prevGear.gear[1]
    #     $Y1eqY2 = $gear.gear[1] -eq $prevGear.gear[0]
    #     $Y1eqx2 = $gear.gear[1] -eq $prevGear.gear[1]
       
    #     if ($X1eqY2 -or $X1eqX2 -or $Y1eqY2 -or $Y1eqx2) {
    #         $gearRatio *= $gear.value * $prevGear.value
    #         if ( ){
    #             $ratioSum += $gearRatio 
    #             $gearRatio = 1;
    #         }
    #     }   
    #     $prevGear = $gear
    # }

    [pscustomobject]@{
        Input = ($inputfile -split "\\")[-1]
        NumberSum = $partNumber_Sum
        GearRatioSum = $ratioSum
    }
   
}

# [pscustomobject]$partNumbers | ft