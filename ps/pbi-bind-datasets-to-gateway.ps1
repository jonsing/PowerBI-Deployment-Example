#------------------------------------------------------------------------------------------------------------------------------
#
# This script binds all datasets in the given group to provided gateway
#
# NOTE!!!! Requires Install-Module -Name MicrosoftPowerBIMgmt -Scope CurrentUser -Force to be run before!
#------------------------------------------------------------------------------------------------------------------------------

param (
    [Parameter(Mandatory = $true)][string]$groupId,
    [Parameter(Mandatory = $true)][string]$gatewayId
)

$securePassword = ConvertTo-SecureString $($env:saPassword) -AsPlainText -Force
$credentials = new-object -typename System.Management.Automation.PSCredential -argumentlist $($env:saUserName), $securePassword

Connect-PowerBIServiceAccount -Credential $credentials

$token = Get-PowerBIAccessToken

$getDatasetUrl = "https://api.powerbi.com/v1.0/myorg/groups/$groupId/datasets"

Write-Host("##[debug]Get all datasets in defined group")
Write-Host("##[debug]Using url: $getDatasetUrl")

$datasets = Invoke-RestMethod -Uri $getDatasetUrl -Method Get -ContentType "application/json" -Headers @{Authorization = $token.Authorization }

foreach ($dataset in $datasets.value) {
    
    $datasetId = $dataset.id

    Write-Host("##[debug]Bind dataset $dataset.item.Id to gateway")

    if ($dataset.isRefreshable -eq "True") {
        $url = "https://api.powerbi.com/v1.0/myorg/datasets/$datasetId/Default.BindToGateway"
        
        $postjson = '{"gatewayObjectId": "' + $gatewayId + '"}'

        Write-Host("##[debug]Trying to bind to gateway: $postjson")
        Write-Host("##[debug]Using url: $url")

        Invoke-RestMethod -Uri $url -Method Post -Body $postjson -ContentType "application/json" -Headers @{Authorization = $token.Authorization }
    }
}
		  
Disconnect-PowerBiServiceAccount