# JSON-ToCSV

.SYNOPSIS
    Powershell script that "flattens" a JSON file, and converts it to a CSV file.
 
.DESCRIPTION
    Uses the built-in function "ConvertFrom-Json" to convert the source JSON file to a PSCustomObject.
    Once the data is a PSCustomObject, calls the function "Flatten-PsCustomObject" to remove nesting.
    After nesting is removed, the data is sent to the built-in function "Export-Csv" for output.
