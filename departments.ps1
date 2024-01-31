#####################################################
# HelloID-Conn-Prov-Source-Exact-Synergy-Departments
#
# Version: 1.0.1
#####################################################

$c = $configuration | ConvertFrom-Json
$filepath = $c.filepath
$filename = $c.filename
$file = $filepath + "\" + $filename
function getDataDepartment {
    param(
        [parameter(Mandatory = $true)]$file,
        [parameter(Mandatory = $true)][ref]$departments
    )

    [xml]$xml = get-content $file

    foreach ($id in $xml.GetElementsByTagName("Medewerker")) {
        $department = [PSCustomObject]@{}
        foreach ($dept in $id.GetElementsByTagName("Afdeling").ChildNodes) {
       
            if ($dept.LocalName -eq "Loonverdeling_afdelings_code"  ) {
                $department | Add-Member -MemberType NoteProperty -Name ("ExternalId") -Value $dept.'#text' -Force
            }
            
            if ($dept.LocalName -eq "Loonverdeling_afdeling"  ) {
                $department | Add-Member -MemberType NoteProperty -Name ("DisplayName") -Value $dept.'#text' -Force 
            }
            
            [void]$departments.value.Add($department)
        }
    }
}


$departments = [System.Collections.ArrayList]::new()


try {  
    getDataDepartment -file $file -departments ([ref]$departments) 
    $departments = $departments | Where-Object { $null -ne $_.ExternalId }
    $departments = $departments | Sort-Object -Unique ExternalId


    Write-Information 'Enhancing and exporting department objects to HelloID'

    # Set counter to keep track of actual exported department objects
    $exportedDepartments = 0

    Write-verbose -verbose "Departments"
    foreach ($department in $departments) {
        $json = $department | ConvertTo-Json -Depth 5
        Write-Output $json
        $exportedDepartments++
    }

    Write-Information "Successfully enhanced and exported department objects to HelloID. Result count: $($exportedDepartments)"
    Write-Information "Department import completed"
}
catch {
    Write-Verbose "Error : $($_)" -Verbose
    throw "Could not read $($file)"
}
