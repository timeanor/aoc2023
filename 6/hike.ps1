class pos {
    
    [int]$Y
    [int]$X

    pos () { $this.Init(@{}) }
    
    pos ($y, $x ) { $this.Init( @{X=$x; Y=$y}) }

    pos ([hashtable]$Properties) { $this.Init($Properties) }
}

$inputfiles =  ("$psscriptroot\sample.txt", "$psscriptroot\input.txt")
foreach ( $inputfile in $inputfiles[0] ) 
{
    $content = Get-Content $inputfile





}