
param ([string]$inputFile = "$psscriptroot\calibration.txt")
$inputcontent = Get-Content $inputFile

$sum_total_of_calibration_values = 0 

foreach ($line in $inputcontent){    
    $digits = $line -split "[a-z]|" | Where-Object {$_}
    $sum_total_of_calibration_values  += [int]($digits[0] + $digits[-1])
}

$sum_total_of_calibration_values 