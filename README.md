# PsAcano
Powershell implementation of the Acano API

## Introduction
The Acano Server provides management access through an API exposed through HTTPS in the WebAdmin on the server. This API is thorughly documented at https://www.acano.com/publications/2015/09/Solution-API-Reference-R1_8.pdf

Knowledge of this document is assumed before use of this module.

### Terminology and function names
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

## Installation

To install, simply run
```posh
iex (New-Object Net.WebClient).DownloadString("https://gist.githubusercontent.com/tomlarse/5f43bbe0e763cea379ca/raw/c30b59c64a309e7433531c2b33675d7ad6887f98/installmodule")
```
to install the latest release.

To install from master or dev and manually import this module, unpack or clone the PsAcano folder and run

```posh
Import-Module .\PsAcano.psd1
```

in the folder in Powershell. To make it load automatically when PowerShell starts, unpack, clone or copy it in to one of the folders defined in 

```posh
$env:PsModulePath
```

## Use

To start a new session against an Acano server, use the `New-AcanoSession` cmdlet:

```posh
New-AcanoSession -APIAddress acanoserverfqdn.contoso.com -Credential (Get-Credential)
```

Default, this configure the module to connect to the API on port 443. If the webadmin is deployed on the same server as the webbridge, webadmin will often be configured to use another port than 443, in that case use the `-Port` parameter to define the port. If the server is deployed in a lab or there is another reason its certificate is not trusted, you can use the `-IgnoreSSLTrust` parameter to connect.

NOTE: No actual connecting is done by the `New-AcanoSession`cmdlet at the moment, it just configures parameters for the rest of the cmdlets to use. 

To display a list of possible commands use

```posh
Get-Command -Module PsAcano
```

The Acano server uses a 128-bit GUID to identify objects, use these when accessing objects with `Get-`, `Set-` and `Remove-` Cmdlets.

## Caveats

This module has feature parity with the Acano API documentation. However there is no error handling in it at the moment, so it doesn't return error messages from the server. This is planned in a future update. There is also a lot of comment-based help missing, so `Get-Help` doesn't work for all commands.

Please feel free to give feedback through [issues](https://github.com/tomlarse/PsAcano/issues).
