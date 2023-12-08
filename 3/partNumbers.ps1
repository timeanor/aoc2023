

class symbol {
    [string]$char
    [Coord]$coord
}
class PartNumber {
    [coord[]]$coords
    [int]$value
    [bool]$cogged
}
class Coord{
    [int]$y
    [int]$x
    Coord ([int]$Y, [int]$X){
        $this.y = $Y
        $this.x = $X
    }
}
function resolve-vector($A,$B){
    return ($B[1]-$A[1]),($B[0]-$A[0])     
}

$inputfiles =  "$psscriptroot\sampledata.txt"#, "$psscriptroot\inputData.txt"
$inputfiles = 'C:\Users\tmeanor\source\repos\aoc2023\3\sampledata.txt'
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
                $symbol.char = $matrix[$i][$j]
                $symbol.coord = [Coord]::new($i,$j)
                $symbols += $symbol
            }
            $chars = ''
            if ( $matrix[$i][$j] -match "\d" ){   
                $partnumber = [partnumber]::new()
                while ($matrix[$i][$j] -match "\d"){
                    $chars += $matrix[$i][$j]
                    $partnumber.coords += ,[Coord]::new($i,$j) 
                    $j++
                }     
                $partnumber.value = [int]$chars          
                $partNumbers += $partnumber
            } 
        } 
    }   
    $partNumber_Sum = 0 
   
    $CoggedParts = @()

    
    $gears = $symbols | Where-Object { $_.char -eq "*" } 
    $offsets = @{
        Vertical = @( @(-1,0), @(1,0))
        Left     = @(@(-1,-1), @(-1,0), @(-1,1))
        Right    = @( @(1,-1),  @(1,0), @(1,1))
    }
    foreach ( $part in $partNumbers[0] )
    {  
        foreach ($coord in $part.coords)
        {    
            $coord 
            foreach ($vert in $offsets.Vertical) {             
                $offset = [Coord]::new(($coord.y + $vert[0]), ($coord.X + $vert[1]))
                $offset 
                $matrix[$offset.y][$offset.x]
                $gears | where-object {
                    ($_.coord.y -eq $offset.y) -and ($_.coord.x -eq $offset.x)
                }
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