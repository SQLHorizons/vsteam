Set-StrictMode -Version Latest

# Loading System.Web avoids issues finding System.Web.HttpUtility
Add-Type -AssemblyName 'System.Web'

InModuleScope releaseDefinitions {
   [VSTeamVersions]::Account = 'https://test.visualstudio.com'
   [VSTeamVersions]::Release = '1.0-unittest'

   $results = [PSCustomObject]@{
      value = [PSCustomObject]@{
         queue           = [PSCustomObject]@{ name = 'Default' }
         _links          = [PSCustomObject]@{ 
            self = [PSCustomObject]@{}
            web  = [PSCustomObject]@{}
         }
         retentionPolicy = [PSCustomObject]@{}
         lastRelease     = [PSCustomObject]@{}
         artifacts       = [PSCustomObject]@{}
         modifiedBy      = [PSCustomObject]@{ name = 'project' }
         createdBy       = [PSCustomObject]@{ name = 'test'}
      }
   }

   Describe 'ReleaseDefinitions' {
      # Mock the call to Get-Projects by the dynamic parameter for ProjectName
      Mock Invoke-RestMethod { return @() } -ParameterFilter {
         $Uri -like "*_apis/projects*" 
      }
   
      . "$PSScriptRoot\mocks\mockProjectNameDynamicParamNoPSet.ps1"

      Context 'Show-VSTeamReleaseDefinition by ID' {
         Mock Show-Browser { }
         
         it 'should return Release definitions' {
            Show-VSTeamReleaseDefinition -projectName project -Id 15

            Assert-MockCalled Show-Browser -Exactly -Scope It -Times 1 -ParameterFilter {
               $url -eq 'https://test.visualstudio.com/project/_release?definitionId=15'
            }
         }
      }
    
      Context 'Get-VSTeamReleaseDefinition with no parameters' {
         Mock _useWindowsAuthenticationOnPremise { return $true }
         Mock Invoke-RestMethod {
            return $results 
         }

         It 'should return Release definitions' {
            Get-VSTeamReleaseDefinition -projectName project

            Assert-MockCalled Invoke-RestMethod -Exactly -Scope It -Times 1 -ParameterFilter { 
               $Uri -eq "https://test.vsrm.visualstudio.com/project/_apis/release/definitions/?api-version=$([VSTeamVersions]::Release)"
            }
         }
      }

      Context 'Get-VSTeamReleaseDefinition with expand environments' {
         Mock _useWindowsAuthenticationOnPremise { return $true }
         Mock Invoke-RestMethod {
            return $results 
         }

         It 'should return Release definitions' {
            Get-VSTeamReleaseDefinition -projectName project -expand environments

            Assert-MockCalled Invoke-RestMethod -Exactly -Scope It -Times 1 -ParameterFilter { 
               $Uri -eq "https://test.vsrm.visualstudio.com/project/_apis/release/definitions/?api-version=$([VSTeamVersions]::Release)&`$expand=environments"
            }
         }
      }

      Context 'Add-VSTeamReleaseDefinition' {
         Mock Invoke-RestMethod {
            return $results 
         }

         it 'Should add Release' {
            Add-VSTeamReleaseDefinition -projectName project -inFile 'Releasedef.json'

            Assert-MockCalled Invoke-RestMethod -Exactly -Scope It -Times 1 -ParameterFilter {
               $Method -eq 'Post' -and
               $InFile -eq 'Releasedef.json' -and
               $Uri -eq "https://test.vsrm.visualstudio.com/project/_apis/release/definitions/?api-version=$([VSTeamVersions]::Release)"
            }
         }
      }

      Context 'Get-VSTeamReleaseDefinition by ID' {
         Mock Invoke-RestMethod { return [PSCustomObject]@{
               queue           = [PSCustomObject]@{ name = 'Default' }
               _links          = [PSCustomObject]@{ 
                  self = [PSCustomObject]@{}
                  web  = [PSCustomObject]@{}
               }
               retentionPolicy = [PSCustomObject]@{}
               lastRelease     = [PSCustomObject]@{}
               artifacts       = [PSCustomObject]@{}
               modifiedBy      = [PSCustomObject]@{ name = 'project' }
               createdBy       = [PSCustomObject]@{ name = 'test'}
            }
         }

         It 'should return Release definition' {
            Get-VSTeamReleaseDefinition -projectName project -id 15

            Assert-MockCalled Invoke-RestMethod -Exactly -Scope It -Times 1 -ParameterFilter {
               $Uri -eq "https://test.vsrm.visualstudio.com/project/_apis/release/definitions/15?api-version=$([VSTeamVersions]::Release)"
            }
         }
      }

      Context 'Remove-VSTeamReleaseDefinition' {
         Mock Invoke-RestMethod { return $results }

         It 'should delete Release definition' {
            Remove-VSTeamReleaseDefinition -projectName project -id 2 -Force

            Assert-MockCalled Invoke-RestMethod -Exactly -Scope It -Times 1 -ParameterFilter {
               $Method -eq 'Delete' -and 
               $Uri -eq "https://test.vsrm.visualstudio.com/project/_apis/release/definitions/2?api-version=$([VSTeamVersions]::Release)"
            }
         }
      }

      # Make sure these test run last as the need differnt 
      # [VSTeamVersions]::Account values
      Context 'Get-VSTeamReleaseDefinition with no account' {
         [VSTeamVersions]::Account = $null

         It 'should return Release definitions' {
            { Get-VSTeamReleaseDefinition -projectName project } | Should Throw
         }
      }

      Context 'Add-VSTeamReleaseDefinition on TFS local Auth' {
         Mock Invoke-RestMethod { return $results }
         Mock _useWindowsAuthenticationOnPremise { return $true }
         [VSTeamVersions]::Account = 'http://localhost:8080/tfs/defaultcollection'

         it 'Should add Release' {
            Add-VSTeamReleaseDefinition -projectName project -inFile 'Releasedef.json'

            Assert-MockCalled Invoke-RestMethod -Exactly -Scope It -Times 1 -ParameterFilter {
               $Method -eq 'Post' -and
               $InFile -eq 'Releasedef.json' -and
               $Uri -eq "http://localhost:8080/tfs/defaultcollection/project/_apis/release/definitions/?api-version=$([VSTeamVersions]::Release)"
            }
         }
      }

      Context 'Remove-VSTeamReleaseDefinition on TFS local Auth' {
         Mock Invoke-RestMethod { return $results }
         Mock _useWindowsAuthenticationOnPremise { return $true }
         [VSTeamVersions]::Account = 'http://localhost:8080/tfs/defaultcollection'

         Remove-VSTeamReleaseDefinition -projectName project -id 2 -Force
         
         It 'should delete Release definition' {
            Assert-MockCalled Invoke-RestMethod -Exactly -Scope Context -Times 1 -ParameterFilter {
               $Method -eq 'Delete' -and 
               $Uri -eq "http://localhost:8080/tfs/defaultcollection/project/_apis/release/definitions/2?api-version=$([VSTeamVersions]::Release)"
            }
         }
      }
   }
}