Set-StrictMode -Version Latest

#region include
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.", ".")

. "$here/../../Source/Classes/VSTeamVersions.ps1"
. "$here/../../Source/Classes/VSTeamProjectCache.ps1"
. "$here/../../Source/Private/common.ps1"
. "$here/../../Source/Public/$sut"
#endregion

Describe 'VSTeamAgent' {
   Context 'Enable-VSTeamAgent' {
      ## Arrnage
      Mock _getApiVersion { return '1.0-unitTests' } -ParameterFilter { $Service -eq 'DistributedTask' }

      Mock _getInstance { return 'https://dev.azure.com/test' } -Verifiable
   
      # Mock the call to Get-Projects by the dynamic parameter for ProjectName
      Mock Invoke-RestMethod -ParameterFilter { $Uri -like "*950*" }
      Mock Invoke-RestMethod { throw 'boom' } -ParameterFilter { $Uri -like "*101*" }
   
      It 'by Id should enable the agent with passed in Id' {
         ## Act
         Enable-VSTeamAgent -Pool 36 -Id 950

         ## Assert
         Assert-MockCalled Invoke-RestMethod -Exactly -Times 1 -Scope It -ParameterFilter {
            $Method -eq 'Patch' -and
            $Uri -eq "https://dev.azure.com/test/_apis/distributedtask/pools/36/agents/950?api-version=$(_getApiVersion DistributedTask)"
         }
      }

      It 'should throw' {
         ## Act / ## Assert
         { Enable-VSTeamAgent -Pool 36 -Id 101 } | Should Throw
      }
   }
}