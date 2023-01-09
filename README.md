
# HelloID-Conn-Prov-Target-Planon-Order

| :warning: Warning |
|:---------------------------|
| Note that this connector is "a work in progress" and therefore not ready to use in your production environment. |

| :warning: Warning |
|:---------------------------|
| This connector has not been tested on a Planon environment. Therefore, changes might have to be made according to your environment. |

| :warning: Warning |
|:---------------------------|
|Before using this connector, make sure the necessary Planon WSDL's are available. See: [WSDL specifications](#wsdl-specifications) |

| :information_source: Information |
|:---------------------------|
| This repository contains the connector and configuration code only. The implementer is responsible to acquire the connection details such as username, password, certificate, etc. You might even need to sign a contract or agreement with the supplier before implementing this connector. Please contact the client's application manager to coordinate the connector requirements. |

<p align="center">
  <img src="https://webhelp.planoncloud.com/en/connect/planonlogo.png">
</p>

## Table of contents

- [HelloID-Conn-Prov-Target-Planon-Order](#helloid-conn-prov-target-planon-order)
  - [Table of contents](#table-of-contents)
  - [Introduction](#introduction)
  - [Getting started](#getting-started)
    - [Connection settings](#connection-settings)
    - [LifeCycle events](#lifecycle-events)
    - [Prerequisites](#prerequisites)
    - [Remarks](#remarks)
      - [No user provisioning](#no-user-provisioning)
      - [`GetPerson` not yet available](#getperson-not-yet-available)
      - [Pre-Emptive authentication](#pre-emptive-authentication)
      - [WSDL specifications](#wsdl-specifications)
  - [Getting help](#getting-help)
  - [HelloID docs](#helloid-docs)

## Introduction

_HelloID-Conn-Prov-Target-Planon_ is a _target_ connector. Planon offers web services APIs that allow developers to access and integrate the functionality of with other applications and systems.

The Planon API uses a WSDL / SOAP architecture. A WSDL (Web Services Description Language) is an XML-based language that is used for describing the functionality of a web service. A WSDL file defines the methods that are exposed by the web service, along with the data types that are used by those methods and the messages that are exchanged between the web service and its clients.

## Getting started

### Connection settings

The following settings are required to connect to the API.

| Setting| Description| Mandatory |
| --- | --- | --- |
| UserName| The UserName to connect to the Planon webservice| Yes|
| Password| The Password to connect to the Planon webservice| Yes|
| BaseUrl| The URL to the Planon webservice <br> Example: *https://{environment}/nyx/services*| Yes       |
| OrderCodesJSONFile | The path to a file with StandardOrderCode the required permissions<br> And example can be found in the asset folder| Yes|

### LifeCycle events

The following lifecycle events are available:

| Event  | Description| Notes |
|---|---|---|
| create.ps1| Correlates an account| *ws:GetPerson* |
| grant.ps1| Creates an order| *umr:MaakOrder* |
| permissions.ps1 | Retrieves a list of order codes | Requires a file in JSON format containing standard user codes |

### Prerequisites

> :exclamation: Note that, this connector has not been tested on a Planon environment. Changes might have to be made according to your environment.

> :exclamation: **Contact your Planon consultant to verify that the necessary WSDL's are available.**

- [ ] A JSON file containing the standard order Codes.
- [ ] URL to the Planon webservice
- [ ] The `UmraOrders` and `SDWWebServices` [WSDL's](#multiple-wsdl-specifications) available.

### Remarks

#### No user provisioning

The sole purpose of this connector is to automatically create Planon orders. It cannot be used for user provisioning.

#### `GetPerson` not yet available

Both the `create.ps1` and `grant.ps1` will need to retrieve the user account from Planon. The `create.ps1` for account correlation, the `grant.ps1` because the order send to Planon must contain the `EmployeeId` or `PersonnelNumber`.

Because the connector is based on documentation, the XML response for a `GetPerson` call to Planon is unclear. Therefore, this part is currently not developed and not available in the connector.

The PowerShell code below can be used to retrieve a person from Planon.

```powershell
$UserName   = ''
$Password   = ''
$BaseUrl    = ''
$ExternalId = ''

$pair = "$($UserName):$($Password)"
$b64Encoded = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($pair))
$headers = [system.collections.generic.dictionary[string, string]]::new()
$headers.add('Authorization', "Basic $b64Encoded")

$body = @"
<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:ws="http://www.tempsdw.org/SDWWebServices/v1/ws">
    <soapenv:Body>
        <ws:GetPerson>
            <code>$ExternalId</code>
        </ws:GetPerson>
    </soapenv:Body>
</soapenv:Envelope>
"@

$splatParams = @{
    Uri         = "$($BaseUrl)/SDWWebServices.SDWWebServicesSOAP"
    Method      = 'POST'
    Headers     = $headers
    Body        = $body
    ContentType = 'application/text+xml; charset=utf-8'
}
Invoke-RestMethod @splatParams
```

#### Pre-Emptive authentication

Planon requires _Pre-Emptive_ authentication. Which means that, the outgoing request must contain the `authorization` header with the username:password in a base64 encoded string.

#### WSDL specifications

The connector uses the following WSDL specifications:

| WSDL  | Description |
|---|---|
| UmraOrders | To create, update and retrieves order(s) |
| SDWWebServices | To retrieve and correlate a user account |

Before using this connector, contact your Planon consultant to verify the WSDL's listed above are available.

## Getting help

> _For more information on how to configure a HelloID PowerShell connector, please refer to our [documentation](https://docs.helloid.com/hc/en-us/articles/360012558020-Configure-a-custom-PowerShell-target-system) pages_

> _If you need help, feel free to ask questions on our [forum](https://forum.helloid.com)_

## HelloID docs

The official HelloID documentation can be found at: https://docs.helloid.com/
