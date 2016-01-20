# PsAcano
Powershell module that can access the Acano administration interfaces. It contains two Powershell modules, PsAcano-API which contains cmdlets that access the Acano API running on the server and PsAcano-MMP which contains cmdlets that connects to the MMP over SSH and SCP.

## Introduction
### PsAcano-API
The Acano Server provides management access through an API exposed through HTTPS in the WebAdmin on the server. This API is thorughly documented at https://www.acano.com/publications/2015/09/Solution-API-Reference-R1_8.pdf

Knowledge of this document is assumed before use of this module.

#### Terminology and function names
Acano uses HTTP GET, POST, PUT and DELETE methods to access functionality in the API. These are translated to the PowerShell verbs like this

- GET     -> Get-
- POST    -> New-
- PUT     -> Set-
- DELETE  -> Remove-

As far as it is possible, the PowerShell noun will be based on the API node location that is being accessed in the function prepended with Acano, for instance

```posh
Get-AcanocoSpaces
```
Which will correspond to doing a GET on the /api/v1/coSpaces node, or

```posh
New-AcanocoSpace
```
to do a POST on the /api/v1/coSpaces node. Nouns will be plural if they might return multiple results and singular if they will only return one result.

There are some exceptions - some of the API functions only trigger something to happen, for instance a POST to the node /api/v1/coSpaces/<coSpace id>/diagnostics, will trigger diagnostics logging on the coSpace. In these situations a suitable noun has been chosen. For the example the Start- noun was chosen,

```posh
Start-AcanocoSpaceCallDiagnosticsGeneration
```
### PsAcano-MMP
This module uses the posh-ssh module created by darkoperator. Posh-ssh is maintained here http://github.com/darkoperator/posh-ssh

PsAcano-MMP connects to the Acano MMP over SSH and is able to both read and write settings from MMP, eliminating the need for a separate SSH and SCP client installed on the admin system. This makes management from Windows servers easier, and together with PsAcano-API, enables full deployment scripting of an Acano server.   

#### Terminology and function names.
PsAcano-MMP tries to follow standard Powershell verbs and terminology, mainly using the Get- and Set- verbs. The Nouns are prefixed by 'Acano', and then the usual MMP command:

```posh
Get-AcanoIface a
Get-AcanoCallbridge
```

## Installation

To install PsAcano-API, run
```posh
#---NEEDS TO BE UPDATED BEFORE RELEASE--- iex (New-Object Net.WebClient).DownloadString("https://gist.githubusercontent.com/tomlarse/5f43bbe0e763cea379ca/raw/c30b59c64a309e7433531c2b33675d7ad6887f98/installmodule")
```
and PsAcano-MMP
```posh
#---NEEDS TO BE UPDATED BEFORE RELEASE--- iex (New-Object Net.WebClient).DownloadString("https://gist.githubusercontent.com/tomlarse/5f43bbe0e763cea379ca/raw/c30b59c64a309e7433531c2b33675d7ad6887f98/installmodule")
```


To install from master or dev and manually import this module, unpack or clone the PsAcano folder and run

```posh
Import-Module .\PsAcano-API.psd1
Import-Module .\PsAcano-MMP.psd1
```

in the folder in Powershell. To make it load automatically when PowerShell starts, unpack, clone or copy it in to one of the folders defined in 

```posh
$env:PsModulePath
```

## Use

To start a new session against the Acano API, use the `New-AcanoSession` cmdlet:

```posh
New-AcanoSession -APIAddress acanoserverfqdn.contoso.com -Credential (Get-Credential)
```

Default, this configure the module to connect to the API on port 443. If the webadmin is deployed on the same server as the webbridge, webadmin will often be configured to use another port than 443, in that case use the `-Port` parameter to define the port. If the server is deployed in a lab or there is another reason its certificate is not trusted, you can use the `-IgnoreSSLTrust` parameter to connect.

To start a new session against the Acano MMP, use the `New-AcanoMMPSession` cmdlet:

```posh
New-AcanoMMPSession -MMPAddress acanoserverfqdn.contoso.com -Credential (Get-Credential)
```

To display a list of possible commands use

```posh
Get-Command -Module PsAcano-API
Get-Command -Module PsAcano-MMP
```

The Acano API uses a 128-bit GUID to identify objects, use these when accessing objects with `Get-`, `Set-` and `Remove-` Cmdlets.

### Errors
If an API call fails, the server will return an HTTP 400 containing the failure reason. The module will display these as a normal Powershell error

## Caveats

There is a lot of comment-based help missing, so `Get-Help` doesn't work for all commands.

Please feel free to give feedback through [issues](https://github.com/tomlarse/PsAcano/issues).
