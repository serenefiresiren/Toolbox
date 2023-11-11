param ( 
    [Parameter(Mandatory=$True)] [string] $SourceInstance,
    [Parameter(Mandatory=$True)] [string] $SourceDatabase,
    [Parameter(Mandatory=$True)] [string] $DestInstance, 
    [Parameter(Mandatory=$True)] [string] $DestDatabase,
    [Parameter(Mandatory=$True)] [string] $Path ,
    [Parameter(Mandatory=$False)] [boolean] $IgnorePermissions = $True,
    [Parameter(Mandatory=$False)] [boolean] $IgnoreUserLoginMappings = $True,
    [Parameter(Mandatory=$False)] [array] $ExcludeObjectTypes = ("Certificates")
)  


$SourceConnection = Connect-DbaInstance -SqlInstance $SourceInstance  -TrustServerCertificate
$DestConnection = Connect-DbaInstance -SqlInstance $DestInstance -TrustServerCertificate
 
$ExportOptions = New-DbaDacOption -Type Dacpac -Action Export
$ExportOptions.IgnorePermissions = $IgnorePermissions
$ExportOptions.IgnoreUserLoginMappings = $IgnoreUserLoginMappings 
$ExportOptions.CommandTimeout = 0

$PublishOptions =  New-dbadacoption -Type dacpac -Action Publish
$PublishOptions.DeployOptions.ExcludeObjectTypes = $ExcludeObjectTypes 

Export-DbaDacPackage -SqlInstance $SourceConnection -Database $SourceDatabase -DacOption $ExportProperties -Path $Path |
    Publish-DbaDacPackage -SqlInstance $DestConnection -Database $DestDatabase -Verbose 