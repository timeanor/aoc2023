

param ([string]$inputFile = "$psscriptroot\sampledata.txt")


class coords {
    [int]$X 
    [int]$Y 
}

<#

#>

function scan_adjacent([coords]$start)
{    
    $squares  = @(
        @( @(-1,-1), @(0,-1), @(1,-1) ),
        @( @(-1, 0), @(1, 0) ), 
        @( @(-1, 1), @(0, 1), @(1, 1) )
    )  
    Foreach ($square in $squares ) 
    {
        foreach ($shift in $square)
        {
            $look_at = [coords]::new()
            $look_at.X = $start.X + $shift[0]
            $look_at.Y = $start.Y + $shift[1]

            # detect edge and skip
            if (($look_at.X -gt $ubound_X ) -or ($look_at.X -lt 0)) { continue }
            if (($look_at.Y -gt $ubound_Y ) -or ($look_at.Y -lt 0)) { continue }

            if ($matrix[$start.Y + $shift[1]])[ $look_at.X ]
          
        }
    }
}

function collect_digits([coords]$start)
{    # only looks left or write on single line

   
}

$inputContent = Get-Content $inputFile
$script:ubound_Y = $inputContent.Count - 1 
$script:ubound_X = $inputContent[0].Length - 1 

# get our matrix built 
$script:matrix = [System.Collections.ArrayList]::new()
$inputContent | ForEach-Object { $script:matrix.add($_.ToCharArray()) | out-null }

$script:current_coords = [coords]::new()

for ( $y = 0; $y -lt $script:ubound_Y ; $y++ )
{   
    for ( $x = 0; $x -lt $script:ubound_X; $x++ )
    {
        if (([regex]"[^\d|^\.]").match($($matrix[$y])[$x]).success) 
        { 
           $current_coords.X = $x 
           $current_coords.Y = $y
            scan_adjacent($current_coords)
        } 
    } 
}