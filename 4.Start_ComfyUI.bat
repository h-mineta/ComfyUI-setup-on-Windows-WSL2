wsl.exe -d ComfyUI-Fedora -- bash -c "/opt/ComfyUI-running-on-Podman-WSL2/start_comfyui.sh"

REM Sleep for 5 seconds to start
timeout /t 5 /nobreak >nul

REM Open ComfyUI in the default web browser
start "" "http://localhost:8888" >nul 2>&1
