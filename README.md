# ComfyUI-setup-on-Windows-WSL2
WindowsのWSL2でComfyUIをセットアップするためのWindows Batchファイル

# これは何？
このリポジトリは、WindowsのWSL2上でComfyUIをセットアップするための手順を提供します。  
この手順に従うことで、Windows上で簡単にComfyUIを利用できるようになります。

# ATTENTION(注意事項)
- このWindows Batchファイルは信用されるサイトからダウンロードしてください。  
  例:
  https://github.com/h-mineta/ComfyUI-setup-on-Windows-WSL2/archive/refs/heads/main.zip
- WindowsのWSL2上でComfyUIをセットアップするためのものです。
- Windows 11での動作を確認しています。
- WSL2上でNVIDIA GPUを使用することを前提としています。

## インストール方法

1. WSL2を有効にする  
  `1.Enable_WSL.bat` を実行する  
  管理者権限が必要となるため、UACが表示されたら「はい」を選択してください。

2. Windowsを再起動する  
  WSL2を有効にした後、Windowsを再起動してください。

3. Linux(ComfyUI-Fedora)をインストールする  
  `2.Install_Linux.bat` を実行する

## 利用方法

1. Linux(ComfyUI-Fedora)を開く  
  `3.Open_ComfyUI_Folder.bat` を実行する  
  Explorerが開き、WSL2のLinuxフォルダが開きます。  
  data/models フォルダ配下に利用するモデルを配置してください。  

   - モデルの配置例:
     - `data/models/checkpoints` 
     - `data/models/loras` 

2. ComfyUIを起動する  
  `4.Start_ComfyUI.bat` を実行する  
  次回以降パソコンを起動した際は、`4.Start_ComfyUI.bat` を実行してください。

3. ComfyUIを終了する  
  `5.Stop_ComfyUI.bat` を実行する  
  コンテナは廃棄されますが、data フォルダ、output フォルダは残ります。
