param ( 
    [Parameter(Mandatory=$True)] [string] $SourceInstance,
    [Parameter(Mandatory=$True)] [string] $SourceDatabase,
    [Parameter(Mandatory=$True)] [string] $DestInstance, 
    [Parameter(Mandatory=$True)] [string] $DestDatabase ,
    [Parameter(Mandatory=$False)] [int] $MonthsBack ,
    [Parameter(Mandatory=$False)] [datetime] $CutoffDate = [datetime]::MaxValue
)  
 
$SourceConnection = Connect-DbaInstance -SqlInstance $SourceInstance -TrustServerCertificate
$DestConnection = Connect-DbaInstance -SqlInstance $SourceInstance -TrustServerCertificate

IF ($MonthsBack){
    $CutoffDate = (Get-Date).AddMonths(-($MonthsBack)).Date
}

Copy-DbaDbTableData -SqlInstance $SourceConnection -Database $SourceDatabase -Destination  $DestConnection -DestinationDatabase $DestDatabase -Table 'SourceTableName' -Query "SELECT ColA 
	,ColB
	,ColC
	,blobretainedvalie
	,ColD
  FROM SourceDBTableName d
  WHERE Whatevercondition
    " -DestinationTable 'DestTableName' -KeepNulls -KeepIdentity -BatchSize 500 -NotifyAfter 100 
   
Copy-DbaDbTableData -SqlInstance $SourceConnection -Database $SourceDatabase -Destination  $DestConnection -DestinationDatabase $DestDatabase -Table 'SourceTableName' -Query "SELECT ColA 
	,ColB
	,ColC
	,0x0
	,ColD
  FROM SourceDBTableName d
  WHERE Oppositecondition AND DateColumn >= '$CutoffDate'
  " -DestinationTable 'DestTableName' -KeepNulls -KeepIdentity -BatchSize 2000 -NotifyAfter 500 
  