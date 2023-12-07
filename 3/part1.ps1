

param ([string]$inputFile = "$psscriptroot\sampledata.txt")




<#

#>

# function scan_adjacent([coords]$start)
# {    
#     $squares  = @(
#         @( @(-1,-1), @(0,-1), @(1,-1) ),
#         @( @(-1, 0), @(1, 0) ), 
#         @( @(-1, 1), @(0, 1), @(1, 1) )
#     )  
#     Foreach ($square in $squares ) 
#     {
#         foreach ($shift in $square)
#         {
#             $look_at = [coords]::new()
#             $look_at.X = $start.X + $shift[0]
#             $look_at.Y = $start.Y + $shift[1]

#             # detect edge and skip
#             if (($look_at.X -gt $ubound_X ) -or ($look_at.X -lt 0)) { continue }
#             if (($look_at.Y -gt $ubound_Y ) -or ($look_at.Y -lt 0)) { continue }

#             if ( $($matrix[ $look_at.Y ])[ $look_at.X ]) {
                
#             }
          
#         }
#     }
# }
function is_num([char]$char){
    return ([regex]"[\d]").match($char).success
}
function is_symbol([char]$char){
    return ([regex]"[^\d|^\.]").match($char).success
}

function collect_nums([coords]$start)
{    # only looks left or write on single line

   
}

function get-partNumber($row, $col){
    $global:matrix

}


function min([object]$numbers){
    return ($numbers | measure-object -minimum).minimum     
}

# function get-char($row, $col){
#     return [char]$($global:matrix[$row])[$col]
# }


$inputContent = Get-Content $inputFile
$global:ubound_Y = $inputContent.Count - 1 
$global:ubound_X = $inputContent[0].Length - 1 

# get our matrix built 
$global:matrix = [System.Collections.ArrayList]::new()
$inputContent | ForEach-Object { $global:matrix.add($_.ToCharArray()) | out-null }
# $inputContent | ForEach-Object { $global:matrix.add($_.ToCharArray()) | out-null }

$global:current_coords = [coords]::new()


$partNumberSum = 0 

for ( [int]$i = 0; $i -lt $global:ubound_Y ; $i++ ){   
    for ( [int]$j = 0; $j -lt $global:ubound_X; $j++ ){
        if (is_symbol($($global:matrix[$i])[$j])){ 

           # jump back row line and 
            ($($global:matrix[$i-1])[$($j-3)..$($j+3)]) | % {if(is_num($_))  }
            
           $($global:matrix[$i - 1])[$j - ]
            # $partNumberSum  += get-partNumber($i, $j)

        } 
    } 
}