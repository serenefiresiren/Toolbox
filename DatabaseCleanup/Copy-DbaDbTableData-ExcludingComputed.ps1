Param ( 
    [Parameter(Mandatory=$True)] [string] $SourceInstance,
    [Parameter(Mandatory=$True)] [string] $SourceDatabase,
    [Parameter(Mandatory=$True)] [string] $DestInstance, 
    [Parameter(Mandatory=$True)] [string] $DestDatabase, 
    [Parameter(Mandatory=$False)] [array] $ExcludeTables = @()   
)  

$SourceConnection = Connect-DbaInstance -SqlInstance $SourceInstance -TrustServerCertificate 
$DestConnection = Connect-DbaInstance -SqlInstance $DestInstance -TrustServerCertificate 
 
$Tables = Get-DbaDbTable -SqlInstance $SourceConnection -Database $SourceDatabase | Where-Object {$_.Name -notin $ExcludeTables -and $_.RowCount -ne 0 -and $_.Name -ne 'Sysdiagrams'}
$ComputedTables = ForEach ($Table in $Tables) {
    $ComputedCount = ($Table.Columns | Where-Object Computed -eq $True | Measure-Object).Count 
    if ($ComputedCount -ne "0") {
        $Table  
    }
}

$Tables | Where-Object {$_ -notin $ComputedTables} | ForEach-Object { 
    $_ | Copy-DbaDbTableData -SqlInstance $SourceConnection -Destination $DestConnection -Database $SourceDatabase -DestinationDatabase $DestDatabase -KeepIdentity -KeepNulls  
}
