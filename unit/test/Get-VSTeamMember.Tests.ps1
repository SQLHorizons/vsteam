Set-StrictMode -Version Latest

#region include
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.", ".")

. "$here/../../Source/Classes/VSTeamVersions.ps1"
. "$here/../../Source/Classes/VSTeamProjectCache.ps1"
. "$here/../../Source/Private/applyTypes.ps1"
. "$here/../../Source/Private/common.ps1"
. "$here/../../Source/Public/Set-VSTeamAPIVersion.ps1"
. "$here/../../Source/Public/$sut"
#endregion

Describe "VSTeamMember" {
   Mock _getInstance { return 'https://dev.azure.com/test' }
   Mock _getApiVersion { return '1.0-unitTests' } -ParameterFilter { $Service -eq 'Core' }

   . "$PSScriptRoot\mocks\mockProjectNameDynamicParam.ps1"

   Context 'Get-VSTeamMember for specific project and team' {
      Mock Invoke-RestMethod { return @{value = 'teams' } }

      It 'Should return teammembers' {
         Get-VSTeamMember -ProjectName TestProject -TeamId TestTeam
         # Make sure it was called with the correct URI
         Assert-MockCalled Invoke-RestMethod -Exactly 1 -ParameterFilter {
            $Uri -eq "https://dev.azure.com/test/_apis/projects/TestProject/teams/TestTeam/members?api-version=$(_getApiVersion Core)"
         }
      }
   }

   Context 'Get-VSTeamMember for specific project and team, with top' {
      Mock Invoke-RestMethod { return @{value = 'teams' } }

      It 'Should return teammembers' {
         Get-VSTeamMember -ProjectName TestProject -TeamId TestTeam -Top 10
         # Make sure it was called with the correct URI
         Assert-MockCalled Invoke-RestMethod -Exactly 1 -ParameterFilter {
            $Uri -like "*https://dev.azure.com/test/_apis/projects/TestProject/teams/TestTeam/members*" -and
            $Uri -like "*api-version=$(_getApiVersion Core)*" -and
            $Uri -like "*`$top=10*"
         }
      }
   }

   Context 'Get-VSTeamMember for specific project and team, with skip' {
      Mock Invoke-RestMethod { return @{value = 'teams' } }

      It 'Should return teammembers' {
         Get-VSTeamMember -ProjectName TestProject -TeamId TestTeam -Skip 5
         # Make sure it was called with the correct URI
         Assert-MockCalled Invoke-RestMethod -Exactly 1 -ParameterFilter {
            $Uri -like "*https://dev.azure.com/test/_apis/projects/TestProject/teams/TestTeam/members*" -and
            $Uri -like "*api-version=$(_getApiVersion Core)*" -and
            $Uri -like "*`$skip=5*"
         }
      }
   }

   Context 'Get-VSTeamMember for specific project and team, with top and skip' {
      Mock Invoke-RestMethod { return @{value = 'teams' } }

      It 'Should return teammembers' {
         Get-VSTeamMember -ProjectName TestProject -TeamId TestTeam -Top 10 -Skip 5
         # Make sure it was called with the correct URI
         Assert-MockCalled Invoke-RestMethod -Exactly 1 -ParameterFilter {
            $Uri -like "*https://dev.azure.com/test/_apis/projects/TestProject/teams/TestTeam/members*" -and
            $Uri -like "*api-version=$(_getApiVersion Core)*" -and
            $Uri -like "*`$top=10*" -and
            $Uri -like "*`$skip=5*"
         }
      }
   }

   Context 'Get-VSTeamMember for specific team, fed through pipeline' {
      Mock Invoke-RestMethod { return @{value = 'teammembers' } }

      It 'Should return teammembers' {
         New-Object -TypeName PSObject -Prop @{projectname = "TestProject"; name = "TestTeam" } | Get-VSTeamMember

         Assert-MockCalled Invoke-RestMethod -Exactly 1 -ParameterFilter {
            $Uri -eq "https://dev.azure.com/test/_apis/projects/TestProject/teams/TestTeam/members?api-version=$(_getApiVersion Core)"
         }
      }
   }

   # Must be last because it sets [VSTeamVersions]::Account to $null
   Context '_buildURL handles exception' {

      # Arrange
      [VSTeamVersions]::Account = $null

      It 'should return approvals' {

         # Act
         { _buildURL -ProjectName project -TeamId 1 } | Should Throw
      }
   }
}