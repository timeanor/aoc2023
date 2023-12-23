#requires -version 7.0
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
    [bool]$Finished = $false
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
        return "{0},{1},{2},{3},{4}" -f $this.src, $this.len, $this.max, $this.matched, $this.finished
    }
#endregion
}

function Test-RangesMutEx($A, $B) {
    $right_Of_B = $A.src -gt $B.max
    $left_Of_B = $A.max -lt $B.src
    return ($right_Of_B -or $left_Of_B)
}


function Resolve-MapInclusive ([ref]$s, $m){
#  Ss----Ms--Mm----Sm  
#  $-----Ms           = $newItem_L
#        Ms--Mm       = $s
#             $----Sm = $newItem_R    

    write-debug "Map inclusive  [$($s.ToString())] => "

    $newItem_L = [SeedItem]::new( $s.value.src, $m.src - $s.value.src )
    $newItem_R = [SeedItem]::new( $s.value.src, $s.value.max - $m.max )

    $s.value.src = Get-NewSrcValue 
    $s.value.len = $m.len
    $s.value.matched = $true 

    write-debug "[$($s.value.ToString())] + [$($newItem_L.ToString())], [$($newItem_R.ToString())]" 
    return $newItem_L, $newItem_R
}
function Resolve-SeedInclusive ([ref]$s, $m){
#  M----S--S----M 
#       $--$      = $s

    write-debug "Seed inclusive  [$($s.value.ToString())] => "    
   
    $s.value.src = $s.value.src - $m.src + $m.dst   
    $s.value.matched = $true 
    write-debug "[$($s.value.ToString())] "  
}
 
function Resolve-LeftShift ([ref]$s, $m){
#  Ss----Ms--Sm----Mm 
#  Ss---$            = $newitem
#        Ms--Sm      = $s 

    $t = $s.value
    write-debug "Seed Left  [$($s.value.ToString())] => "

    # new item of set that did not match
    $newItem = [SeedItem]::new( $t.src, $m.src - $t.src )

    $t.src = $m.dst
    $t.len = $t.len - $newItem.len
    $t.matched = $true  
    
    write-debug "[$($t.ToString())] + [$($newItem.ToString())]" 
    $s.value = $t  
    return $newItem   
}

function _calcNewLen($S, $M){
    return [math]::mod($s.len, [math]::Abs($m.max, $s.src))
}

function Resolve-RightShift ([ref]$s, $m){
# Ms----Ss--Mm----Sm 
#            $----Sm = $n     
#       Ss--Mm       = $s
#
#  $n.src = $s.src
#  $n.len = $s.len - ($m.max - $s.len)

    $t = $s.value
    write-debug "Seed Left [$($s.value.ToString())] => " 

#update new value of input item   
    $t.len = $m.max - $t.src
    $t.matched = $true

    
# overwrite input with new values by ref
    $s.value = $t 

    $n = [SeedItem]::new( $t.src,  $t.len - ($m.max - $t.src))
    write-debug "[$($t.ToString())] + [$($n.ToString())]" 
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
            
            if ( $runList[$i].matched ) { continue }

            if ( (-not (Test-RangesMutEx $runList[$i] $mapItem) )){

                $LeftShift  =    ( $runList[$i].src -lt $mapItem.src ) -and ( $runList[$i].max -le $mapItem.max )
                $RightShift =    ( $runList[$i].src -ge $mapItem.src ) -and ( $runList[$i].max -gt $mapItem.max )
                $SeedInclusive = ( $runList[$i].src -ge $mapItem.src ) -and ( $runList[$i].max -le $mapItem.max )
                $MapInclusive  = ( $runList[$i].src -lt $mapItem.src ) -and ( $runList[$i].max -gt $mapItem.max )
                
                $subItem_l = $LeftShift     ? ( Resolve-LeftShift    ([ref]$runList[$i]) $mapItem ) : $null
                $subItem_r = $RightShift    ? ( Resolve-RightShift   ([ref]$runList[$i]) $mapItem ) : $null
                $subItem_x = $MapInclusive  ? ( Resolve-MapInclusive ([ref]$runList[$i]) $mapItem ) : $null

                $null = $SeedInclusive ? ( Resolve-SeedInclusive ([ref]$runList[$i]) $mapItem ) : $null                

                ($subItem_r, $subItem_l, $subItem_x).Where({ $_ }).foreach({ $runList.add($_) })

            } 
       }   
    }
    return $runList | Select-Object -skip 1
}
#endregion function definitions



$inputfiles =  "$psscriptroot\sample.txt", "$psscriptroot\input.txt"

foreach ( $inputfile in $inputfiles[0] ) 
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

    # $seeds.add([seeditem]::new(82,1))
    $seeds = [System.Collections.Generic.List[Object]]::new()
    $seeds.add([seeditem]::new(74,14))
    $holding = $seeds
    for ($i = 0; $i -lt $seeds.count; $i++ ) {      
        foreach ($map in $Maps){            
            (resolve-seedItem ([ref]$holding[$i]) $map.instructions) | ForEach-Object { $holding.add($_) | out-null  }           
            $seeds | % { $_.reset() }
        }
        if ($seeds[$i].finished) { continue }
    }
    $seeds |ft 


#output
    [pscustomobject]@{
        Input = ($inputfile -split "\\")[-1]
        Part2 =  $null 
    }   
}