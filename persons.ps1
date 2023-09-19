#####################################################
# HelloID-Conn-Prov-source-Exact-Synergy-Persons
#
# Version: 1.0.0
#####################################################
$c = $configuration | ConvertFrom-Json
$filepath = $c.filepath
$filename = $c.filename
$file = $filepath + "\" + $filename
#$file = "C:\helloid\export.xml"
function getData {
    param(
        [parameter(Mandatory = $true)]$file,
        [parameter(Mandatory = $true)][ref]$persons
    )

    [xml]$xml = get-content $file

    
    $plm = $xml.jh.Medewerker
    $afdelinglist2 = [System.Collections.ArrayList]::new()
    foreach ($record in $plm) {
        $transform = [PSCustomObject]@{
            ExternalId                                             = "$($record.Strooknummer)-1"
            strooknummer                                           = $record.strooknummer 
            afdeling_Loonverdeling_afdelings_code                  = $record.afdeling.Loonverdeling_afdelings_code 
            afdeling_Loonverdeling_Afdeling                        = $record.afdeling.Loonverdeling_Afdeling
            afdeling_Beroep_Code                                   = $record.afdeling.Beroep_Code
            afdeling_Beroep                                        = $record.afdeling.Beroep
            contract_DatumUitDienst                                = $record.Contract.DatumUitDienst
            contract_Concerndatum                                  = $record.Contract.Concerndatum
            contract_Werkgevers_code                               = $record.Contract.Werkgevers_code
            contract_Werkgever                                     = $record.Contract.Werkgever
            afdeling_Datum_Functiewijziging                        = $record.afdeling.Datum_Functiewijziging
            leidinggevende_Afdelingsverantwoordelijke_1_Achternaam = $record.Leidinggevende.Afdelingsverantwoordelijke_1_Achternaam
            leidinggevende_Strooknummer                            = $record.Leidinggevende.Strooknummer
            taken_GSO                                              = $record.Taken.GSO
            taken_VVDGVA                                           = $record.Taken.VVDGVA
            rollen_R66                                             = $record.Rollen.R66
            extra_OR_Functionaris                                  = $record.Extra.OR_Functionaris
           
        }
        [void]$afdelinglist2.Add($transform)
    }
    $afdelinglist2Grouped = $afdelinglist2 | Group-Object -Property strooknummer  -AsHashTable

    foreach ($id in $xml.GetElementsByTagName("Medewerker")) {
        $person = [PSCustomObject]@{}
         
        foreach ($item in $id.ChildNodes) {
            $person | Add-Member -MemberType NoteProperty -Name ($item.LocalName) -Value $item.'#text' -Force
        }
        foreach ($id1 in $id.GetElementsByTagName("Naam").ChildNodes) {
            $person | Add-Member -MemberType NoteProperty -Name ("naam_" + $id1.LocalName) -Value $id1.'#text' -Force
        }
        foreach ($con in $id.GetElementsByTagName("Contract").ChildNodes) {
            $person | Add-Member -MemberType NoteProperty -Name ("contract_" + $con.LocalName) -Value $con.'#text' -Force
        }
        foreach ($afd in $id.GetElementsByTagName("Afdeling").ChildNodes) {
            $person | Add-Member -MemberType NoteProperty -Name ("afdeling_" + $afd.LocalName) -Value $afd.'#text' -Force
        }

        foreach ($mgr in $id.GetElementsByTagName("Leidinggevende").ChildNodes) {
            $person | Add-Member -MemberType NoteProperty -Name ("leidinggevende_" + $mgr.LocalName) -Value $mgr.'#text' -Force
        }

        foreach ($taak in $id.GetElementsByTagName("Taken").ChildNodes) {
            $person | Add-Member -MemberType NoteProperty -Name ("taken_" + $taak.LocalName) -Value $taak.'#text' -Force
        }
        foreach ($rol in $id.GetElementsByTagName("Rollen").ChildNodes) {
            $person | Add-Member -MemberType NoteProperty -Name ("rollen_" + $rol.LocalName) -Value $rol.'#text' -Force
        }
        foreach ($extra in $id.GetElementsByTagName("Extra").ChildNodes) {
            $person | Add-Member -MemberType NoteProperty -Name ("extra_" + $extra.LocalName) -Value $extra.'#text' -Force
        }

        
        $contractslist = [System.Collections.ArrayList]::new()
        $departmentlistobject = $afdelinglist2Grouped[$id.strooknummer]
        if ($null -ne $departmentlistobject) {
            [void] $contractslist.AddRange($departmentlistobject)
        }

        $person | Add-Member -MemberType NoteProperty -Name "Contracts" -Value $contractslist -Force
        [void]$persons.value.Add($person)
    }
}

$persons = [System.Collections.ArrayList]::new()
try {
    getData -file $file -persons ([ref]$persons) 
}
catch {
    Write-Verbose "Error : $($_)" -Verbose
}
try {    
    $persons | Add-Member -MemberType NoteProperty -Name "ExternalId" -Value $null -Force
    $persons | Add-Member -MemberType NoteProperty -Name "DisplayName" -Value $null -Force

    $persons | ForEach-Object {
        
        # Map required fields
        $_.ExternalId = $_.Strooknummer
        $_.DisplayName = "$($_.naam_Roepnaam)  $($_.naam_Voorvoegsels) $($_.naam_Achternaam)"  

        #$_.Contracts = $contracts

    }
    Write-verbose -verbose "Persons"
    foreach ($person in $persons) {
        $json = $person | ConvertTo-Json -Depth 5
        Write-Output $json
    }
}
catch {
    Write-Verbose "Error : $($_)" -Verbose
}