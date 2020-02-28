# powercli-kubernetes

A project to execute PowerShell Core script inside a Kubernetes cluster

## Requirements 

* Kubernetes >= 1.6.0
* PowerShell >= 6.2.3

## Configuration

### ConfigMap
CronJob uses script defined in ConfigMap

#### Snapshot
Define a ConfigMap containing the script [VMSnapshot.ps1](https://baltig.infn.it/infn-ct/powercli-kubernetes/blob/master/script/VMSnapshot.ps1) as follow:
```console
kubectl create configmap powercli-script-snap --from-file=script/VMSnapshot.ps1
```

### Secret
CronJob uses two different secrets:
1. [powercli-secret.yaml](https://baltig.infn.it/infn-ct/powercli-kubernetes/blob/master/secret/powercli-secret.yaml) contains a variable for the server hostname
2. A file contains credential used by the script for authentication on the server. Create the file with the following PowerShell commands:
```console
$User = "Username"   
$Pass = "Password" | ConvertTo-SecureString -AsPlainText -Force 
$Credentials = New-Object System.Management.Automation.PSCredential($User,$Pass)
$Credentials | Export-CliXml -Path MyCrential.xml
```
After create a secret containing the credential file
```console
kubectl create secret generic powercli-secret-credential --from-file=secret/MyCredential.xml
```
