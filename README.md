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

```
Get-AcanocoSpaces
```
Which will correspond to doing a GET on the /api/v1/coSpaces node, or
```
New-AcanocoSpace
```
to do a POST on the /api/v1/coSpaces node. Nouns will be plural if they might return multiple results and singular if they will only return one result.

There are some exceptions - some of the API functions only trigger something to happen, for instance a POST to the node /api/v1/coSpaces/<coSpace id>/diagnostics, will trigger diagnostics logging on the coSpace. In these situations a suitable noun has been chosen. For the example the Start- noun was chosen,

```
Start-AcanocoSpaceCallDiagnosticsGeneration
```

## Installation

To import this module, unpack or clone the PsAcano folder and run

`Import-Module .\PsAcano.psd1`

in the folder in Powershell. To make it load automatically when PowerShell starts, unpack, clone or copy it in to one of the folders defined in 

`$env:PsModulePath`

## Use

To start a new session against an Acano server, use the `Open-AcanoSession` cmdlet. To see an example, run

`help New-AcanoSession -Examples`

To get a list of possible commands use

`Get-Command -Module PsAcano`

## Caveats

Currently this module contains the GET commands from the API, and only some of the POST, PUT and DELETE commands. The rest are being added continually. There is also no error handling in it at the moment, and there is a lot of comment-based help missing. Feel free to give feedback through issues.
