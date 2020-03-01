function Update-VSTeamAgent {
   param(
      [Parameter(Mandatory = $true, ValueFromPipeline = $true, Position = 0)]
      [int] $PoolId,

      [parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, Position = 1)]
      [Alias('AgentID')]
      [int[]] $Id
   )

   process {
      foreach ($item in $Id) {
         try {
            _callAPI -Method Post -Area "distributedtask/pools/$PoolId" -Resource messages -QueryString @{agentId=$item} -Version $([VSTeamVersions]::DistributedTask) -ContentType "application/json" | Out-Null
            Write-Output "Update agent $item"
         }
         catch {
            _handleException $_
         }
      }
   }
}