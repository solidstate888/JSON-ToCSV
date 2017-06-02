<#
.SYNOPSIS
    "Flattens" a JSON file into a CSV formatted file.
 
.DESCRIPTION
    Uses the built-in function "ConvertFrom-Json" to convert the source JSON file to a PSCustomObject.
    Once the data is a PSCustomObject, calls the function "Flatten-PsCustomObject" to remove nesting.
    After nesting is removed, the data is sent to the built-in function "Export-Csv" for output.
 
.PARAMETERS
    (Function "Flatten-PsCustomObject": $parent, $sourceParam)
    $parent is required to create the CSV headers, and $sourceParam it the PSCustomObject input.  
 
.INPUTS
  $inputFile = "testA.json"
 
.OUTPUTS
  $outputFile = "testA.csv"
 
.NOTES
  Version:        1.0
  Author:         Kelly Jolly 
  Creation Date:  6/2/2017
  Purpose/Change: Initial Commit
#>
 
#----------------------------------------------------------[Declarations]----------------------------------------------------------
$output = ""
$output = New-Object -TypeName pscustomobject
$inputFile = "testA.json"
$outputFile = "testA.csv"
 
#-----------------------------------------------------------[Functions]------------------------------------------------------------
Function Flatten-PsCustomObject{
    param (
        [Parameter(Mandatory=$true)]
        $parent,
       
        [Parameter(Mandatory=$true)]
        $sourceParam
    )
 
    $parentFlat=$parent
    $parentNested=$parent
    $flat = [System.Collections.ArrayList]@()
    $nested = [System.Collections.ArrayList]@()
    $counter=$null
 
    #### Get the items in the PSCustomObject source that contain user data. ####
    if ($sourceParam){      
         $objects = Get-Member -InputObject $sourceParam -MemberType NoteProperty
    }
    else{
        $objects = $null
    }
 
    #### Separate the user data, based on whether each item has additional nested data or not. ####
    # "Nested" contains nested data. "Flat" contains flat data, ready for export.                 #
    foreach ($object in $objects) {
        if ($object.Definition -match "System.Object"){
            $nested+=$object
        }
        else{
             $flat+=$object
        }
    }
 
    #### Flat Data - Create CSV headers, and add the headers & flat data to the output variable. ####
    foreach($keyFlat in $flat){
        
        # Build the CSV headers. #
        $nameFlat = $parentFlat+"."+$keyFlat.Name
       
        # Using the object names, pull the values of those objects from the source, and save to a variable. #
        if ($keyFlat) {
            try{
                $valueFlat = $sourceParam | Select -ExpandProperty $keyFlat.Name -ErrorAction Stop
            }catch{
                write-host "Flat Data - Unable to populate the variable $keyFlat"
            }
        }else{
            $valueFlat = $null
        }
 
        # Some nested data was sneaking through - checks for that, and sends nested data recursively back to function. #
        # Otherwise, it adds the flat data to the output variable. #
        if ($valueFlat -and $valueFlat -match "@{"){
            Flatten-PsCustomObject $nameFlat $valueFlat
#
        }elseif (($valueFlat) -and $valueFlat -notmatch "@{"){
            $output | Add-Member -MemberType NoteProperty -Name $nameFlat -Value $valueFlat
        }else{
            $output | Add-Member -MemberType NoteProperty -Name $nameFlat -Value ""
        }
    }
 
    #### Nested Data - Sends the nested data recursively back through the function. ####
    foreach($keyNested in $Nested){
        # Creates CSV headers, gets the values of the nested data. #
        try{
            $nameNested = $parentNested+"."+$keyNested.Name
            $valueNested = $sourceParam | select -ExpandProperty $keyNested.Name -ErrorAction Stop
        }catch{
            write-host "Nested Data - Unable to populate the variable $keyNested"
        }
       
        # Sends non-null values recursively back through the function. Sends null values to the output variable. #
        If($valueNested) {
            foreach ($value in $valueNested){             
                Flatten-PsCustomObject "$nameNested$counter" $value
                $counter++       
            }
            $counter=$null
        }else{
            $output | Add-Member -MemberType NoteProperty -Name $nameNested -Value ""
        }
 
    }
    return $output
}
 
#-----------------------------------------------------------[Execution]------------------------------------------------------------
$input = Get-Content $inputFile | ConvertFrom-Json
Flatten-PsCustomObject 'root' $input #> $null
echo $output | Export-Csv  $outputFile -NoTypeInformation -Encoding UTF8 -Delimiter ','
