

$inputfiles =  "$psscriptroot\sampledata.txt", "$psscriptroot\inputData.txt"


foreach ( $inputfile in $inputfiles ) {
    $parts = @()
    $symbols = @()
    $matrix = @()
    $content = Get-Content $inputfile
    $matrix += ,".$("." * ($content[0].Length)).".ToCharArray()
    $content | ForEach-Object { $matrix += ,((".$_.").ToCharArray()) }
    $matrix += ,".$("." * ($content[0].Length)).".ToCharArray()

    # populate lists of all symbols and contiguous numbers 
    for ( [int]$i = 0; $i -lt $matrix.Length -1; $i++ )
    {   
        for ( [int]$j = 0; $j -lt $matrix[0].Length -1; $j++ )
        {
            if ( $matrix[$i][$j] -match "[^\d^\.]" ){ 
                $symbol = [PSCustomObject]@{
                    str = $matrix[$i][$j];
                    coord = @($i,$j);
                    ratio = 1
                }
                $symbols += ,$symbol
            }
           
            if ( $matrix[$i][$j] -match "\d" ){   
                $part = [PSCustomObject]@{
                    isPartnumber = $false
                    value = ''
                    coords = @()                    
                    cogIndex = $null 
                }
                while ($matrix[$i][$j] -match "\d"){
                    $part.value += $matrix[$i][$j]
                    $part.coords += ,@($i, $j)
                    $j++
                }     
                $part.value = $part.value         
                $parts +=  ,$part
                $j--
            } 
        } 
    }   

    $offsets = @{
        vertical = @(-1,0), @(1,0)
        left = @(-1,-1), @(0,-1), @(1,-1) 
        right = @(-1,1), @(0,1), @(1,1)  
    }

    foreach ( $part in $parts )
    {     
        $adjacentCells = @()          
        
        $y,$x = $part.coords[0]
        $offsets.left | ForEach-Object { $adjacentCells += ,@(( $y + $_[0] ),( $x + $_[1] ))}

        $y,$x = $part.coords[-1]
        $offsets.right | ForEach-Object { $adjacentCells += ,@(( $y + $_[0] ),( $x + $_[1] ))} 

        $part.coords | ForEach-Object {             
             $y,$x =( $_[0], $_[1] )
             $offsets.vertical | ForEach-Object { $adjacentCells += ,@(( $y + $_[0] ),( $x + $_[1] ))}
         }
 
        foreach ( $cell in $adjacentCells){          
            $part.isPartnumber = $part.isPartnumber -or $matrix[$cell[0]][$cell[1]] -match "[^\d^\.]"
            
            if ( $matrix[$cell[0]][$cell[1]] -match  "\*" ) { 
                $symbol = $symbols | where-object { ($_.coord[0] -eq $cell[0]) -and ($_.coord[1] -eq $cell[1]) }  
                $part.cogIndex = [int]($symbols.IndexOf($symbol))
            }
        }
    }

    $partNumber_Sum = 0 
    $parts | Where-Object { $_.isPartNumber } | ForEach-Object {                 
        $partNumber_Sum += [int]($_.value) 
    }

    $meshedGears = $parts | where-object { $_.cogIndex -ne $null } | Group-Object -Property cogIndex  | where-object count -gt 1
    $meshedGears.group | ForEach-Object {              
        $symbols[$_.cogIndex].ratio *= $_.value

    }
    $ratioSum = 0 
    $symbols | where-object {$_.ratio -gt 1} | ForEach-Object { $ratioSum += $_.ratio}

    [pscustomobject]@{
        Input = ($inputfile -split "\\")[-1]
        NumberSum = $partNumber_Sum
        GearRatioSum = $ratioSum
    }   
}