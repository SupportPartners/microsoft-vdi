$owner = "SupportPartners"
$repo_name = "microsoft-vdi"
$branch = "master"

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$wc = New-Object System.Net.WebClient

Function AzureLogin
{
    Try
    {
        $accountsNumber = (az account list | ConvertFrom-Json).Length
    }
    Catch [System.Management.Automation.CommandNotFoundException]
    {
        Invoke-WebRequest -Uri https://aka.ms/installazurecliwindows -OutFile .\AzureCLI.msi; Start-Process msiexec.exe -Wait -ArgumentList '/I AzureCLI.msi /quiet'; rm .\AzureCLI.msi
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
    }

    If ($accountsNumber -le 1) {
        az login
    }

    $accounts = az account list --query "[].{Name: name, Id: id, TenantId: tenantId}" | ConvertFrom-Json
    $accounts | Foreach-Object { $index = 1 } {Add-Member -InputObject $_ -MemberType NoteProperty  -Name "Number" -Value $index; $index++}

    Write-Host ($accounts | Format-Table | Out-String)

    $minNumber = 1
    $maxNumber = $accounts.Length
    Do {
        Try {
            $numberIsParsed = $true
            [int]$chosenAccountNumber = Read-Host "Please choose the account number from $minNumber to $maxNumber"
        }
        Catch {
            Write-Warning "Incorrect number"
            $numberIsParsed = $false
        }
    }
    Until (($chosenAccountNumber -ge $minNumber -and $chosenAccountNumber -le $maxNumber) -and $numberIsParsed)

    $chosenAccount = $accounts[$chosenAccountNumber - 1]
    $subscriptionId = $chosenAccount.id
    az account set --subscription $subscriptionId

    return $chosenAccount
}

Function DownloadProject
{
    $uri = "https://github.com/$owner/$repo_name/archive/$branch.zip"
    $zip = Join-Path $PSScriptRoot "$branch.zip"
    $wc.DownloadFile($uri, $zip)
    Expand-Archive -Path $zip -DestinationPath $PSScriptRoot -Force
    Remove-Item -Path $zip
}

Function DownloadTerraform([string] $directory)
{
    $version = "0.12.24"
    $os = "windows"
    $arch = "amd64"
    $terraform_uri = "https://releases.hashicorp.com/terraform/${version}/terraform_${version}_${os}_${arch}.zip"
    $terraform_zip = Join-Path $directory "terraform.zip"
    $wc.DownloadFile($terraform_uri, $terraform_zip)
    Expand-Archive -Path $terraform_zip -DestinationPath $directory -Force
    Remove-Item -Path $terraform_zip
}

Function CreateUsers
{
    if ((Test-Path ".\domain_users_list.csv") -eq $False) {
        $isUserAdding = $True
        $users = @()
    
        Do {
            $doContinue = Read-Host "Do you want to add user? y/N"
            If ($doContinue -eq "y") {
                $isUserAdding = $True
            } Else {
                $isUserAdding = $False
                continue
            }
    
            $username = Read-Host "Username"
            $password = Read-Host "Password"
            $firstname = Read-Host "Firstname"
            $lastname = Read-Host "Lastname"
            # $isadmin =  Read-Host "Is admin? true/false"
    
            $users += [pscustomobject]@{
                username = $username
                password = $password
                firstname = $firstname
                lastname = $lastname
                # isadmin = $isadmin
            }
        }
        Until ($isUserAdding -eq $False)

        $users | Export-Csv -NoTypeInformation -Path ".\domain_users_list.csv"
    }

    return $users.Count
}

$loggedAccount = AzureLogin

$subscriptionId = $loggedAccount.id
$tenantId = $loggedAccount.tenantId
$users_count = CreateUsers

$vars =
"subscription_id = `"$subscriptionId`"
sp_tenant_id    = `"$tenantId`"

"

DownloadProject

$repo_directory = Join-Path $PSScriptRoot "$repo_name-$branch"
pushd $repo_directory

$tfvars_file = "user-vars.tfvars"
New-Item -Path . -Name $tfvars_file -ItemType "file" -Force -Value $vars

DownloadTerraform($repo_directory)

.\terraform.exe init
.\terraform.exe apply -var-file="$tfvars_file"

popd