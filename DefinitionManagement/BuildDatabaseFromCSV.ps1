param (
    [Parameter(Mandatory = $true)] [string] $DestDatabase,
    [Parameter(Mandatory = $true)] [string] $DestInstance,
    [Parameter(Mandatory = $true)] [string] $Path
)

$CsvTables = Get-ChildItem -Path $Path | Select-Object FullName, BaseName
$DestConnection = Connect-DbaInstance -SqlInstance $DestInstance -Database $DestDatabase -TrustServerCertificate 

foreach ($table in $CsvTables) { 
    $Data = Import-Csv -Path $table.FullName    
    $Cols = @()
    
    foreach ($Column in $Data[0].PSObject.Properties.Name) {
        $Values = $Data | ForEach-Object { $_.$Column }
        $integerValues = $Values | Where-Object { $_ -match '^[0-9]*$' }

        if ($integerValues.Count -eq $Values.Count) {
            $MaxValue = ($Values | ForEach-Object { [int64]$_ } | Measure-Object -Maximum).Maximum 
            $DataType = if ($MaxValue -le [int]::MaxValue) { "Int" } else { "BigInt" }

            $Cols += @{
                Name     = $Column
                Type     = $DataType
                Nullable = $True
            }   
        } else {
            $MaxLength = ($Values | ForEach-Object { $_.ToString().Length } | Measure-Object -Maximum).Maximum[0]
            $ColumnLength = if ($MaxLength -le 255) { 255 } elseif ($MaxLength -le 2000) { 2000 } else { $MaxLength + 50 }
            $DataType = "VarChar"

            $Cols += @{
                Name      = $Column
                Type      = $DataType
                MaxLength = $ColumnLength
                Nullable  = $True
            }
        }
    } 

    $TableName = $table.BaseName   
    
    Remove-DbaDbTable -SqlInstance $DestConnection -Database $DestDatabase -Table $TableName -Confirm:$false -ErrorAction ignore
    New-DbaDbTable -SqlInstance $DestConnection -Database $DestDatabase -Name $TableName -ColumnMap $Cols                       
    Write-DbaDbTableData -SqlInstance $DestConnection -Database $DestDatabase -Table $TableName -KeepNulls -InputObject $Data
}
 