#requires -version 7.0
#  7.0 for heavy use of ternary operators
#region function definitions
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

class SeedItem {
    [UInt32]$src
    [UInt32]$len
    [UInt32]$max
    [bool]$matched = $false

#region constructors
    SeedItem () { $this.Init(@{}) }
    
    SeedItem ($src, $len) { $this.Init( @{src=$src; len=$len}) }

    SeedItem ([hashtable]$Properties) { $this.Init($Properties);  }
#endregion 
#region methods
    [void] Init([hashtable]$Properties) {
        try {
            foreach ($Property in $Properties.Keys) {
                $this.$Property = $Properties.$Property
            }        
            $this.Reset()
        } catch {
            WRite-Error $_
        }
    }

    [void] Reset() { 
        $this.matched = $false
        $this.max = $this.src + $this.len -1
    }

    [string] ToString() { 
        return "{0},{1},{2},{3},{4}" -f $this.src, $this.len, $this.max, $this.matched
    }
#endregion
}


function Test-LeftShift( $A, $B ){  return ( $A.src -lt $B.src ) -and ( $A.max -le $B.max ) }
function Test-RightShift( $A, $B ){ return ( $A.src -ge $B.src ) -and ( $A.max -gt $B.max ) }
function Test-MapInclusive( $A, $B ) { return ( $A.src -lt $B.src ) -and ( $A.max -gt $B.max ) }
function Test-SeedInclusive( $A, $B ) { return ( $A.src -ge $B.src ) -and ( $A.max -le $B.max )}
function Test-RangesMutEx( $A, $B ) { ($A.src -gt $B.max) -OR ($A.max -lt $B.src) }

function Resolve-MapInclusive ([ref]$s, $m){
#  Ss----Ms--Mm----Sm  
#  $-----Ms           = $n_L
#        Ms--Mm       = $s
#             $----Sm = $n_R    
    
    $n_L = [SeedItem]::new( $s.value.src, $m.src - $s.value.src )
    $n_R = [SeedItem]::new( $s.value.src, $s.value.max - $m.max )

    $s.value.src = $m.dst
    $s.value.len = $m.len
    $s.value.matched = $true 

    return $n_L, $n_R
}

function Resolve-SeedInclusive ([ref]$s, $m){
#  M----S--S----M 
#       $--$      = $s
    $s.value.src = $s.value.src - $m.src + $m.dst   
    $s.value.matched = $true 
}
 
function Resolve-LeftShift ([ref]$s, $m){
#  Ss----Ms--Sm----Mm 
#  Ss---$            = $n
#        Ms--Sm      = $s 

    $n = [SeedItem]::new( $s.value.src, $m.src - $s.value.src )

    $s.value.src = $m.dst
    $s.value.len = $s.value.len - $n.len
    $s.value.matched = $true  

    return $n   
}

function Resolve-RightShift ([ref]$s, $m){
# Ms----Ss--Mm----Sm 
#            $----Sm = $n     
#       Ss--Mm       = $s

    $s.value.len = $m.max - $s.value.src
    $s.value.matched = $true   

    $n = [SeedItem]::new( $s.value.src,  $s.value.len - ($m.max - $s.value.src))

    return $n
}



function resolve-seedItem(){
    param(
        [Parameter()]
        [ref]$seed,
        [object]$instructions
    )
    $runList = [System.Collections.Generic.List[Object]]::new()
    $runList.add($seed.value) | out-null 
    foreach ( $mapItem in $instructions ){
        
        for ( $i = 0; $i -lt $runList.Count; $i++ ) {            
            
            #  dont process if it matched this map
            if ( $runList[$i].matched ) { continue }  
            if (Test-RangesMutEx $runList[$i] $mapItem) { continue }
            
            # resolve the updated values and capture new sets
            $subItem_l = ( Test-LeftShift    $runList[$i] $mapItem) ? ( Resolve-LeftShift    ([ref]$runList[$i]) $mapItem ) : $null
            $subItem_r = ( Test-rightShift   $runList[$i] $mapItem) ? ( Resolve-RightShift   ([ref]$runList[$i]) $mapItem ) : $null
            $subItem_x = ( Test-MapInclusive $runList[$i] $mapItem) ? ( Resolve-MapInclusive ([ref]$runList[$i]) $mapItem ) : $null

            $null = ( Test-SeedInclusive $runList[$i] $mapItem  )? ( Resolve-SeedInclusive ([ref]$runList[$i]) $mapItem ) : $null                

            #  add new sets to the run list 
            ($subItem_r, $subItem_l, $subItem_x).Where({ $_ }).foreach({ $runList.add($_) })
       }   
    }
    return $runList | Select-Object -skip 1
}
#endregion function definitions


$inputfiles =  "$psscriptroot\sample.txt", "$psscriptroot\input.txt"

foreach ( $inputfile in $inputfiles[1] ) 
{
#region load input
    $content = get-content $inputfile -raw
    $seedsInput = ($content -split "`n" | Select-Object -First 1 ) -split ":| " | Where-Object {$_} | select-object -skip 1 | ForEach-Object {[UInt32]$_}
    $rgxPattern = [regex]"(?sm)^(?<name>[\w-]*) map:\s*(?<map>(?:\d+\s*)+)"
    $mapMatches = $rgxPattern.Matches( $content )

    $maps = @()
    $seeds = [System.Collections.Generic.List[Object]]::new()
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
                            max = [UInt32]$r[1] + [UInt32]$r[2] -1
                        }
        }
        $map.instructions = $values
        $maps += ,[pscustomobject]$map
    }
    for ( $i = 0; $i -le $seedsInput.count -1; $i += 2 ){
        $seeds.Add( [SeedItem]::new( $seedsInput[$i], $seedsInput[$i+1] )) | out-null 
    }
#endregion load input

    foreach ($map in $Maps){  
        for ($i = 0; $i -lt $seeds.count; $i++ ) {  
            (resolve-seedItem ([ref]$seeds[$i]) $map.instructions) | ForEach-Object { $seeds.add($_) | out-null  }           
            $seeds | ForEach-Object { $_.reset() }
        }       
    }

#output
$verify = 51399228
    $min = $null 
    $seeds.src | ForEach-Object { $min  = [math]::min(($min ?? $_),$_) }
    $min
    [pscustomobject]@{
        Input = ($inputfile -split "\\")[-1]
        Part2 = $min 
        RightAnswer = $min -eq $verify 
    }   
}