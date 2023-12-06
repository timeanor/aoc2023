
param ([string]$inputFile = "$psscriptroot\sampledata.txt")
$inputcontent = Get-Content $inputFile

$sum_total_of_calibration_values = 0 

$wordNumbers = @('zero', 'one', 'two', 'three', 'four', 'five', 'six', 'seven', 'eight', 'nine')

$pattern = "(\d+|$($wordNumbers -join "|"))"

foreach ($line in $inputcontent){
    $digits = @()
    $selectMatches = $line  | Select-String -pattern $pattern -AllMatches

    $selectMatches.matches.value | ForEach-Object { 
        $digits += if ($_ -match "\d+") { $_ } else { $wordNumbers.IndexOf($_) }
    }

    $sum_total_of_calibration_values  += [int]("{0}{1}" -f $digits[0,-1])

    write-host "$($inputcontent.indexof($line)) $line $( $selectMatches.matches.value  -join ",") $( $digits -join ",") $([int]("{0}{1}" -f $digits[0,-1]))"
}

# the sample data calcs correctly but somehow the larger input does not
$sum_total_of_calibration_values 

