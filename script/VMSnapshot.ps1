# Copyright 2019 Istituto Nazionale di Fisica Nucleare
# salvatore.monforte@ct.infn.it
# riccardo.rotondo@ct.infn.it

param(
    [Parameter(ValueFromPipeline, Mandatory)]
    [string] $server,
    [string] $credfile,
    [string] $schedule = "daily"
)

Set-PowerCLIConfiguration -ParticipateInCEIP:$false -InvalidCertificateAction Ignore -Confirm:$false


If ( ! (Get-module VMware.VimAutomation.core )) {

    get-module -name PowerCli* -ListAvailable |  Import-Module
}

#Stop an error from occurring when a transcript is already stopped
$ErrorActionPreference = "SilentlyContinue"
Stop-Transcript | out-null

#Reset the error level before starting the transcript
$ErrorActionPreference = "Continue"

#Connect to the server using the credentials file      
$creds = Import-Clixml -Path $credfile

Connect-VIServer -Server $server -Credential $creds

    
    #Get all VMs having ScheduleSnapshot set to $schedule 
    $VMs = @(Get-VM | Get-Annotation -CustomAttribute "SnapshotSchedule" |
        Where-Object { $_.Value -eq $schedule } | Sort-Object AnnotatedEntity)

    ForEach ($VM in $VMs) {

        $name = $VM.AnnotatedEntity.Name
        $snapName = Get-Date -Format "yyyyMMdd-HHmm"

        # Creating snapshot
        Write-Host "Creating snapshot for VM $name as $snapName"
        try{
            New-Snapshot -VM $VM.AnnotatedEntity -Name $snapName -Quiesce:$true -Confirm:$false
        }
        catch [VMware.VimAutomation.Sdk.Types.V1.ErrorHandling.VimException.VimException]{
            Write-Host "VimException Caught"
            Write-Host $_
            Write-Host $_.ScriptStackTrace
        }

        # Cleaning up by removing oldest snaps
        $SNAPs = Get-Snapshot -VM $VM.AnnotatedEntity 
        $Retain = (Get-Annotation -Entity $VM.AnnotatedEntity -CustomAttribute "SnapshotRetain").Value -as [int]

        if ($SNAPs.Length -gt $Retain) {
            Write-Host "Removing oldest snapshots for VM $name"
            try{
                Remove-Snapshot -Snapshot (
                    $SNAPs | Sort-Object -Descending Created | 
                    Select-Object -Last ($SNAPs.Length - $Retain)
                ) -Confirm:$false
            }
            catch {
                Write-Host "General Exception Caught"
                Write-Host $_
                Write-Host $_.ScriptStackTrace
            }
        }
    }

#Disconnect
Disconnect-VIServer -Force -Confirm:$false
