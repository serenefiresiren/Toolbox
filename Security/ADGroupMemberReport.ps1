param ( 
    [Parameter(Mandatory=$True)] [array] $SearchList,
    [Parameter(Mandatory=$False)] [boolean] $Export, 
    [Parameter(Mandatory=$False)] [string] $ExportDirectory,
    [Parameter(Mandatory=$False)] [boolean] $Append  
)  

$Results = @([string]$PArentGroupName, [String]$ObjectClass, [String]$SamACcountName) 
$SearchList | ForEach-Object {
    $ADGroup = $_
    $NestedGroups = Get-ADGroupMember $ADGroup | Where-Object ObjectClass -eq "Group" | Select-Object @{
        Name = "ParentGroupName"
        Expression = { $ADGroup }
    }, ObjectClass, SamAccountName  

    $Row = New-Object PSObject -Property @{ SamAccountName = $null
                                            ParentGroupName = $ADGroup 
                                            ObjectClass = "Search"}
    $Results += $Row
    IF($NestedGroups -ne $Null ) {
        $NestedGroups | ForEach-Object {
         $ADGroupNested = $_.SamAccountName 
         $Results +=   $ADGroupNested | Get-ADGroupMember -Recursive | Select-Object @{
                Name = "ParentGroupName"
                Expression = { $ADGroupNested }
            }, ObjectClass, SamAccountName}}
    ELSE {
        $Results += $ADGroup | Get-ADGroupMember  -Recursive | Select-Object @{
                Name = "ParentGroupName"
                Expression = { $ADGroup }
            }, ObjectClass, SamAccountName}
 
    } 

    IF($Export -eq $True -and $ExportDirectory -ne "") {
        IF($Append -eq $true) {
            $Results |Select-Object ParentGroupName, ObjectClass, SamAccountName | Export-Csv $ExportDirectory -Append 
            }
        ELSE {
            $Results |Select-Object ParentGroupName, ObjectClass, SamAccountName | Export-Csv $ExportDirectory 
            }
        }

    ELSEIF ($Export -eq $True){
        Write-Host "No directory specified for export. Printing to Console instead."
        }
    ELSE 
    {
        IF($Append = $True){
            Write-Host "Results not exported to file, append is invalid."
            }
        $Results | Format-Table ParentGroupName, ObjectClass, SamAccountName    -AutoSize 
    }
 