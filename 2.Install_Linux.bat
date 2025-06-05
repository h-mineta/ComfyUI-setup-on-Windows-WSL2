@echo off

set "SRC_BAT=%~f0"
set "TMP_PS=%TEMP%\temp_install_linux.ps1"

REM "REM --- BEGIN POWERSHELL ---"以降を.ps1に書き出し
powershell -NoProfile -Command ^
  "$lines = Get-Content -Raw -Encoding UTF8 '%SRC_BAT%';" ^
  "$split = $lines -split 'REM --- BEGIN POWERSHELL ---\r?\n', 2;" ^
  "if ($split.Count -eq 2) { $split[1] | Set-Content -Encoding UTF8 '%TMP_PS%' } else { Write-Error 'Marker not found.'; exit 1 }"

REM PowerShellスクリプトを実行
powershell -NoProfile -ExecutionPolicy Unrestricted -File "%TMP_PS%"
del "%TMP_PS%"
exit

REM -----------------------------------------------------------------------------------------------

REM --- BEGIN POWERSHELL ---
# Install WSL2 and Fedora on Windows using PowerShell

$env:WSL_UTF8 = 1
$DistroName = "ComfyUI-Fedora"
$DistroPath = "C:\WSL\$DistroName"
$DistroUrl = "https://ftp.riken.jp/Linux/fedora/releases/42/Container/x86_64/images/Fedora-WSL-Base-42-1.1.x86_64.tar.xz"
$DistroSHA256 = "99fb3d05d78ca17c6815bb03cf528da8ef82ebc6260407f2b09461e0da8a1b8d"

# Install : WSL
#winget.exe install --id Microsoft.WSL --source winget

$wslList = wsl.exe --list | Select-String "$DistroName"
if ($wslList) {
    Write-Warning "WSL2($DistroName) is already installed. Unregister and re-import? (y/n)"
    $answer = Read-Host "Type y to continue"
    if ($answer -eq "y") {
        wsl.exe -t "$DistroName"
        wsl.exe --unregister "$DistroName"
        Write-Host "$DistroName has been unregistered."
    }
    else {
        Write-Host "Operation cancelled."
    }
}

# Download Fedora WSL
curl.exe -o "$env:TEMP\fedora-wsl.tar.xz" $DistroUrl
if (-not (Test-Path "$env:TEMP\fedora-wsl.tar.xz")) {
    Write-Error "Failed to download Fedora WSL."
    exit
}

# Verify SHA256
$downloadedHash = (Get-FileHash -Path "$env:TEMP\fedora-wsl.tar.xz" -Algorithm SHA256).Hash.ToLower()
if ($downloadedHash -ne $DistroSHA256.ToLower()) {
    Write-Error "SHA256 hash mismatch! Downloaded: $downloadedHash, Expected: $DistroSHA256"
    exit
}
else {
    Write-Host "SHA256 hash verified."
}

# Install Fedora Linux
if (Test-Path "$DistroPath") {
    Write-Warning "$DistroPath already exists. Remove and re-import? (y/n)"
    $answer = Read-Host "Type y to continue"
    if ($answer -eq "y") {
        Remove-Item -Path $DistroPath -Recurse -Force
    }
    else {
        Write-Host "Operation cancelled."
    }
}
New-Item -ItemType Directory -Path "$DistroPath" | Out-Null

# Import Fedora Linux into WSL
wsl.exe --import "$DistroName" "$DistroPath" "$env:TEMP\fedora-wsl.tar.xz"

$bashScript = @'
#!/bin/bash
dnf -y upgrade
curl -s -L https://nvidia.github.io/libnvidia-container/stable/rpm/nvidia-container-toolkit.repo > /etc/yum.repos.d/nvidia-container-toolkit.repo
dnf install -y nvidia-container-toolkit
nvidia-smi || echo "NVIDIA driver not found. Please install the NVIDIA driver for WSL2."

dnf install -y git podman
nvidia-ctk cdi generate --output=/etc/cdi/nvidia.yaml
nvidia-ctk config --set nvidia-container-cli.no-cgroups --in-place
sed -i 's/^#no-cgroups = false/no-cgroups = true/;' /etc/nvidia-container-runtime/config.toml

mkdir -p /usr/share/containers/oci/hooks.d/
cat << '_EOL_' | sudo tee /usr/share/containers/oci/hooks.d/oci-nvidia-hook.json > /dev/null
{
    "version": "1.0.0",
    "hook": {
        "path": "/usr/bin/nvidia-container-runtime-hook",
        "args": ["nvidia-container-runtime-hook", "prestart"],
        "env": [
            "PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
        ]
    },
    "when": {
        "always": true,
        "commands": [".*"]
    },
    "stages": ["prestart"]
}
_EOL_

chown root:wheel /opt
chmod 775 /opt

useradd -G wheel comfyui-user

cat << '_EOL_' > /etc/wsl.conf
[boot]
systemd=true

[interop]
enabled = true
appendWindowsPath = false

[automount]
enabled = true
mountFsTab = true

[network]
generateHosts = true
generateResolvConf = true

[user]
default = comfyui-user
_EOL_

exit

'@

($bashScript -replace "`r`n", "`n") | Set-Content ".\setup_root.sh"
wsl.exe --user root -d $DistroName -- bash -c "bash ./setup_root.sh"

wsl.exe -t $DistroName

$bashScript = @'
#!/bin/bash
cd /opt
if [ ! -d "ComfyUI-running-on-Podman-WSL2" ]; then
    echo "Cloning ComfyUI-running-on-Podman-WSL2 repository..."
    git clone https://github.com/h-mineta/ComfyUI-running-on-Podman-WSL2.git
else;
    echo "ComfyUI-running-on-Podman-WSL2 already exists."
fi
cd ComfyUI-running-on-Podman-WSL2

git config --global --add safe.directory /opt/ComfyUI-running-on-Podman-WSL2
git pull

chmod +x build.sh start_comfyui.sh

# Remove old ComfyUI images
podman images --format "{{.Repository}}:{{.Tag}} {{.ID}}" \
  | grep '^localhost/comfyui' \
  | awk '{print $2}' \
  | xargs -r podman rmi -f

# Build ComfyUI Container
./build.sh

podman image ls

exit

'@

($bashScript -replace "`r`n", "`n") | Set-Content ".\setup_comfyui-user.sh"
wsl.exe -d $DistroName -- bash -c "bash ./setup_comfyui-user.sh"

Remove-Item -Path ".\setup_root.sh"
Remove-Item -Path ".\setup_comfyui-user.sh"
