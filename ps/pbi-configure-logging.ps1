#------------------------------------------------------------------------------------------------------------------------------
# Configure Export of workspace logs to Log Analytics
# PBI tenant needs to be configured to allow this according to docs: https://docs.microsoft.com/en-us/power-bi/transform-model/log-analytics/desktop-log-analytics-configure
#------------------------------------------------------------------------------------------------------------------------------

param (
    [Parameter(Mandatory = $true)][string]$resourceGroup,
    [Parameter(Mandatory = $true)][string]$laWorkspaceResourceName,
    [Parameter(Mandatory = $true)][string]$subscriptionId,
    [Parameter(Mandatory = $true)][string]$tenantId,
    [Parameter(Mandatory = $true)][string]$pbiGroupId
)

$securePassword = ConvertTo-SecureString $($env:saPassword) -AsPlainText -Force
$credentials = new-object -typename System.Management.Automation.PSCredential -argumentlist $($env:saUserName), $securePassword

Connect-PowerBIServiceAccount -Credential $credentials

$token = Get-PowerBIAccessToken

try {
    $urlSetLogAnalyticsWs = "https://wabi-north-europe-redirect.analysis.windows.net/v1.0/myorg/resources?resourceType=LogAnalytics"
    $postjsonSetLogAnalyticsWs = '{"subscriptionId":"' + $subscriptionId + '","resourceGroup":"' + $resourceGroup + '","resourceName":"' + $laWorkspaceResourceName + '","region":"N/A","isCertified":false,"azureTenantObjectId":"' + $tenantId + '"}'

    $result = Invoke-RestMethod -Uri $urlSetLogAnalyticsWs -Method Post -Body $postjsonSetLogAnalyticsWs -ContentType "application/json" -Headers @{Authorization = $token.Authorization }

    Write-Host 'Log analytics connection created...'
    Write-Host $result.id

    $urlLinkLaAndPbiWs = "https://wabi-north-europe-redirect.analysis.windows.net/v1.0/myorg/resourceLinks?resourceType=LogAnalytics"
    $postjsonLinkLaAndPbiWs = '{"resourceObjectId":"' + $result.id + '","folderObjectId":"' + $pbiGroupId + '"}'

    Invoke-RestMethod -Uri $urlLinkLaAndPbiWs -Method Post -Body $postjsonLinkLaAndPbiWs -ContentType "application/json" -Headers @{Authorization = $token.Authorization }

    Write-Host 'Log analytics WS linked to workspace!'

}
catch {
    Write-Host "StatusCode:" $_.Exception.Response.StatusCode.value__ 
    Write-Host "StatusDescription:" $_.Exception.Response.StatusDescription
    Write-Host "StatusDescription:" $_.Exception
    throw
}

Disconnect-PowerBiServiceAccount