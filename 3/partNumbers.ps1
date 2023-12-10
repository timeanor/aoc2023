

class symbol {
    [string]$str
    $coord
}
class PartNumber {
    $coords = @()
    $cogs = @()
    [int]$value    
    [bool]$Cogged
}

$inputfiles =  "$psscriptroot\sampledata.txt"#, "$psscriptroot\inputData.txt"

foreach ( $inputfile in $inputfiles ) {
    $partNumbers = @()
    $symbols = @()
    $matrix = @()
    $content = Get-Content $inputfile
    $matrix += ,".$("." * ($content[0].Length)).".ToCharArray()
    $content | ForEach-Object { $matrix += ,((".$_.").ToCharArray()) }
    $matrix += ,".$("." * ($content[0].Length)).".ToCharArray()

    # populate lists of all symbols and contiguous numbers 
    for ( [int]$i = 1; $i -lt $matrix.Length -1; $i++ )
    {   
        for ( [int]$j = 1; $j -lt $matrix[0].Length -1; $j++ )
        {
            if ( $matrix[$i][$j] -match "[^\d|^\.]" ){ 
                $symbol = [symbol]::new()  
                $symbol.str = $matrix[$i][$j]
                $symbol.coord = @($i,$j)
                $symbols += $symbol
            }
            $chars = ''
            if ( $matrix[$i][$j] -match "\d" ){   
                $partnumber = [partnumber]::new()
                while ($matrix[$i][$j] -match "\d"){
                    $chars += $matrix[$i][$j]
                    $partnumber.coords += ,@($i, $j)
                    $j++
                }     
                $partnumber.value = [int]$chars          
                $partNumbers += $partnumber
            } 
        } 
    }   
    $partNumber_Sum = 0 

    $offsets = @{
        Vertical = @(-1,0), @(1,0)
        left = @(-1,-1), @(-1,0), @(-1,1) 
        right = @(1,-1), @(1,0), @(1,1)  
    }

    foreach ( $part in $partNumbers )
    {  
        $cogs = @()       
        $lookat = @()          
        
        $y,$x = $part.coords[0]
        $offsets.left | ForEach-Object { $lookat += ,@(( $y + @($_)[0] ),( $x + @($_)[1] ))}

        $y,$x = $part.coords[-1]
        $offsets.right | ForEach-Object { $lookat += ,@(( $y + @($_)[0] ),( $x + @($_)[1] )) } 

        $part.coords | ForEach-Object {             
            $y,$x =( $_[0],$_[1])
            $offsets.Vertical | ForEach-Object { $lookat += ,@(( $y + @($_)[0] ),( $x + @($_)[1] ))}
        }

        foreach ( $look in $lookat ){   
            foreach ( $symbol in $symbols ){
                $symbol.str
                $part.Cogged = $symbol.str -match "\*"
                $ySame = $look[0] -eq $symbol.coord[0]
                $xSame = $look[1] -eq $symbol.coord[1]
                if ($part.Cogged -and $xSame -and  $ySame ){
                    $part.Cogged
                    $part.cogs += ,($symbols.IndexOf($symbol))
                }
            }
        }
        # $lookat | % { 
        #     $c = @(($_)[0],($_)[1])
        #     $matrix[ $c[0]][$c[1]]
        # }
    }


    Foreach ($symbol in ($symbols | Where-Object { $_.str -eq "*" }) ){
         foreach  ($part in $partNumbers) { 
            foreach ($look in $part.offsets){
                if( ( test-equalCoords( $symbol.coord, $look))) { $cogs += , $symbols.IndexOf($symbol) }
            }
         }           
     }
    $partNumbers | FT
    $partNumbers | Where-Object { $_.isPartNumber } | ForEach-Object {         
        $partNumber_Sum += $_.value 
    }
    $gears =  $partNumbers | Where-Object { $_.isGear }
    #part 2
    $ratioSum = 0
    # $prevGear = $gears[0]
    $gearRatio = 1

    [pscustomobject]@{
        Input = ($inputfile -split "\\")[-1]
        NumberSum = $partNumber_Sum
        GearRatioSum = $ratioSum
    }
   
}

# [pscustomobject]$partNumbers | ft