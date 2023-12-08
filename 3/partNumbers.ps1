
class partnumber {
    [int]$line
    [object]$cells = @()
    [int]$value
    [bool]$isPartNumber
}

$inputfiles =  "$psscriptroot\sampledata.txt", "$psscriptroot\inputData.txt"

foreach ( $inputfile in $inputfiles ) {
    $numbers = @()
    $matrix = @()
    $content = Get-Content $inputfile
    $matrix += ".$("." * ($content[0].Length))."
    $content | ForEach-Object { $matrix += ,((".$_.").ToCharArray()) }
    $matrix += ".$("." * ($content[0].Length))."

    for ( [int]$i = 1; $i -lt $matrix.GetUpperBound(0); $i++ ){   
        for ( [int]$j = 1; $j -lt $matrix[1].Count; $j++ ){
            if ($matrix[$i][$j] -match "\d"){   
                $partnumber = [partnumber]::new()
                $partnumber.line = $i    
                $chars = ''
                while ($matrix[$i][$j] -match "\d"){
                    $partnumber.cells += $j
                    $chars += ($matrix[$i][$j].ToString())
                    $j++
                }
                $partnumber.value = [int]$chars
                $numbers += $partnumber           
            } 
        } 
    }
    $partNumber_Sum = 0 
    foreach ($p in $numbers ){
    
        $s,$e = $p.cells[0,-1]
        $s = [math]::max($s-1, 0 )
        $e = [math]::min($e+2, $matrix[0].Length -1 )
        
        #part 1
        for ($k = $p.line -1; $k -lt $p.line + 2; $k++ ){
            for ($l = $s; $l -lt $e ; $l++){
            $p.isPartNumber = $p.isPartNumber -or ($matrix[$k][$l] -match "[^\d|^\.]")
            }   
        }
    
    }
    $numbers | Where-Object { $_.isPartNumber } | ForEach-Object { $partNumber_Sum += $_.value }

   [pscustomobject]@{
      Input = ($inputfile -split "\\")[-1]
      Sum = $partNumber_Sum
   }
}