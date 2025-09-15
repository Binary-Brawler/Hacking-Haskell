# Intent: Windows 10/11 Haskell GUI Dev setup
# Go as FAST... as you carefully can 

Add-Type -AssemblyName System.Windows.Forms

$userChoice = [System.Windows.Forms.MessageBox]::Show('Your about to Install Git, MSYS2 and the Haskell Suite?' + "`n" + "`n" + 'DISK SPACE REQUIRED:' + "`n" + '250MB Download' + "`n" + '5GB on Disk' + "`n" + "`n" + 'Continue?', 'Haskell Dev GUI Setup Confirmation', [System.Windows.Forms.MessageBoxButtons]::YesNo)

if ($userChoice -eq [System.Windows.Forms.DialogResult]::No) {
    Write-Host "Script aborted by user."
    exit
}

function Check-Program {
    param (
        [string]$program
    )

    $programPath = Get-Command $program -ErrorAction SilentlyContinue
    return $programPath -ne $null
}

# Step 1: Check if Git is installed
$gitInstalled = Check-Program "git"
if (-not $gitInstalled) {
    Write-Host "Git is not installed. Installing Git..." -ForegroundColor Green
    $gitURL = "https://github.com/git-for-windows/git/releases/download/v2.48.1.windows.1/Git-2.48.1-64-bit.exe"
    $outpath = "$PSScriptRoot\GitInstaller.exe"
    $wc = New-Object System.Net.WebClient
    $wc.DownloadFile($gitURL, $outpath)
    Write-Host "Running Git installer silently..." -ForegroundColor Green
    Start-Process -FilePath $outpath -ArgumentList "/VERYSILENT", "/NORESTART", "/NOCANCEL", "/SP-", "/CLOSEAPPLICATIONS", "/RESTARTAPPLICATIONS", "/COMPONENTS=icons,ext\reg\shellhere,assoc,assoc_sh" -Wait
} else {
    Write-Host "Git is already installed." -ForegroundColor Yellow
}

# Step 2: Check if MSYS2 is installed
$mysys2Location = "C:\msys64\mingw64.exe"
$msys2Installed = Check-Program $mysys2Location
if (-not $msys2Installed) {
    Write-Host "MSYS2 is not installed. Installing silently... Please Wait!" -ForegroundColor Green
    $url = "https://github.com/msys2/msys2-installer/releases/download/2025-02-21/msys2-x86_64-20250221.exe"
    $outpath = "$PSScriptRoot\msys2-installer.exe"
    $wc = New-Object System.Net.WebClient
    $wc.DownloadFile($url, $outpath)
    Start-Process -FilePath $outpath -ArgumentList "in", "--confirm-command", "--accept-messages", "--root", "C:\msys64" -Wait
    Start-Sleep 5
    Write-Host "Updating MSYS2" -ForegroundColor Yellow
    & "C:\msys64\usr\bin\bash.exe" -lc "pacman -Syu --noconfirm"
    Start-Sleep 5
    Write-Host "Adding pkg-config..." -ForegroundColor Green
    & "C:\msys64\usr\bin\bash.exe" -lc "pacman -S pkg-config --noconfirm"
    Start-Sleep 5
    Write-Host "Adding GTK packages..." -ForegroundColor DarkYellow
    & "C:\msys64\usr\bin\bash.exe" -lc "pacman -S -q --noconfirm git mingw64/mingw-w64-x86_64-pkg-config mingw64/mingw-w64-x86_64-gobject-introspection mingw64/mingw-w64-x86_64-gtksourceview5 mingw64/mingw-w64-x86_64-gtk4 mingw64/mingw-w64-x86_64-atk"
} else {
    Write-Host "MSYS2 is already installed." -ForegroundColor Yellow
    Write-Host "Updating MSYS2" -ForegroundColor DarkYellow
    & "C:\msys64\usr\bin\bash.exe" -lc "pacman -Syu --noconfirm"
    Start-Sleep 5
    Write-Host "Adding pkg-config..." -ForegroundColor Green
    & "C:\msys64\usr\bin\bash.exe" -lc "pacman -S pkg-config --noconfirm"
    Start-Sleep 5
    Write-Host "Adding GTK packages..." -ForegroundColor DarkYellow
    & "C:\msys64\usr\bin\bash.exe" -lc "pacman -S -q --noconfirm git mingw64/mingw-w64-x86_64-pkg-config mingw64/mingw-w64-x86_64-gobject-introspection mingw64/mingw-w64-x86_64-gtksourceview5 mingw64/mingw-w64-x86_64-gtk4 mingw64/mingw-w64-x86_64-atk"
}

# Step 4: Check if Haskell/Cabal is installed
$cabalInstalled = Check-Program "cabal"
if (-not $cabalInstalled) {
    Write-Host "Cabal is not installed. Installing Haskell silently..." -ForegroundColor Green
    $maxRetries = 3
    $retryCount = 0
    $installationSuccessful = $false
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    
    while ($retryCount -lt $maxRetries -and -not $installationSuccessful) {
        try {
            # Silent installation with default options
            $env:GHCUP_INSTALL_BASE_PREFIX = "C:\"
            & ([ScriptBlock]::Create((Invoke-WebRequest https://www.haskell.org/ghcup/sh/bootstrap-haskell.ps1 -UseBasicParsing))) -DisableCurl -NoPrompt -NoModifyPath
            $installationSuccessful = $true
            Write-Host "Haskell installation completed successfully!" -ForegroundColor Green
        } catch {
            $retryCount++
            Write-Warning "Request failed on attempt $retryCount."
            if ($retryCount -ge $maxRetries) {
                Write-Error "Failed to install Haskell after $maxRetries attempts."
            }
        }
    }
}


# Step 5: Create a new Haskell project if not already created
$projectFolder = "gi-gtk-test"
if (-not (Test-Path $projectFolder)) {
    Write-Host "Creating new Haskell project 'gi-gtk-test' using the 'simple' template..." -ForegroundColor Green
    cabal init gi-gtk-test --non-interactive --quiet
} else {
    Write-Host "Project 'gi-gtk-test' already exists, skipping 'cabal init'." -ForegroundColor Yellow
}

# Navigate to the project directory
cd $projectFolder
New-Item -ItemType Directory -Name "src\UI" -Force 

$sharedFunctions = @"
module UI.Shared (createButton) where

import GI.Gtk as Gtk
import qualified Data.Text as T

createButton :: String -> IO Gtk.Button
createButton label = Gtk.buttonNewWithLabel (T.pack label)
"@

New-Item -ItemType File -Path "src\UI\" -Name "Shared.hs" -Value $sharedFunctions

$statusPageContent = @"
{-# LANGUAGE OverloadedStrings #-}

module UI.StatusPage where

import qualified GI.Gtk as Gtk

createStatusPage :: IO ()
createStatusPage = do
    win <- Gtk.windowNew Gtk.WindowTypeToplevel
    Gtk.setWindowTitle win "Testing GUI Dev on Windows"
    Gtk.setContainerBorderWidth win 10
    Gtk.setWindowDefaultWidth win 300
    Gtk.setWindowDefaultHeight win 100
    Gtk.setWindowWindowPosition win Gtk.WindowPositionCenter

    -- Set a text buffer (Testing, no real use for this yet)
    textView <- Gtk.textViewNew
    buffer   <- Gtk.textViewGetBuffer textView

    Gtk.textViewSetBuffer textView ( Just buffer )
    scrolledWindow <- Gtk.scrolledWindowNew (Nothing :: Maybe Gtk.Adjustment) (Nothing :: Maybe Gtk.Adjustment)
    Gtk.containerAdd scrolledWindow textView
    Gtk.containerAdd win scrolledWindow
    Gtk.widgetShowAll win
    
    --return win
"@

New-Item -ItemType File -Path "src\UI\" -Name "StatusPage.hs" -Value $statusPageContent

$layoutContent = @"
{-# LANGUAGE OverloadedLabels, OverloadedStrings #-}

module UI.Layout where

import qualified GI.Gtk as Gtk
import Control.Monad (zipWithM_)

setupGrid :: [(Gtk.Widget, (Int, Int))] -> IO Gtk.Grid
setupGrid widgetPositions = do 
    grid <- Gtk.gridNew
    zipWithM_ (\(widget, (col, row)) _ -> Gtk.gridAttach grid widget (fromIntegral col) (fromIntegral row) 1 1) widgetPositions [1..]
    return grid
"@

New-Item -ItemType File -Path "src\UI\" -Name "Layout.hs" -Value $layoutContent

# 
Remove-Item "gi-gtk-test.cabal" -Force

$CabalNewContent = @"
cabal-version:      3.12
name:               gi-gtk-test
version:            0.1.0.0
license:            NONE
author:             The Hacker Imperium
maintainer:         Unknown
build-type:         Simple
extra-doc-files:    CHANGELOG.md

common shared-props
  default-language: Haskell2010
  build-depends:    
    base >=4 && <5
    , gi-gtk3 ==3.0.44
    , text
  ghc-options: -Wall -Wmissing-home-modules -threaded

library
    import: shared-props
    exposed-modules:
      UI.StatusPage
      UI.Shared
      UI.MainWindow
    hs-source-dirs: src

executable gi-gtk-test
    import:           shared-props
    main-is:          Main.hs
    build-depends:
      , gi-gtk3 ==3.0.44
      , text
      , base >=4 && <5
    hs-source-dirs:   src, app
    other-modules:
      UI.Layout
      UI.MainWindow
      UI.Shared
      UI.StatusPage
    -- flags:
    extra-include-dirs: c:/msys64/mingw64/include
    extra-lib-dirs: c:/msys64/mingw64/lib
    default-language: Haskell2010

"@

New-Item -ItemType File -Name "gi-gtk-test.cabal" -Value $CabalNewContent

$mainWindowContent = @"
{-# LANGUAGE OverloadedStrings, OverloadedLabels, TupleSections #-}

module UI.MainWindow where

import qualified GI.Gtk as Gtk
import UI.Shared (createButton)
import UI.StatusPage (createStatusPage)
import UI.Layout (setupGrid)

createMainWindow :: IO Gtk.Window
createMainWindow = do
    win <- Gtk.windowNew Gtk.WindowTypeToplevel
    Gtk.setWindowTitle win "Testing GUI Dev on Windows"
    Gtk.setContainerBorderWidth win 10
    Gtk.setWindowDefaultWidth win 300
    Gtk.setWindowDefaultHeight win 100
    Gtk.setWindowWindowPosition win Gtk.WindowPositionCenter

    testButton <- createButton "Just another button"

    _ <- Gtk.on testButton #clicked createStatusPage

    widgetPositions <- sequence
        [ (, (1, 1)) <$> Gtk.toWidget testButton ]

    grid <- setupGrid widgetPositions
    Gtk.containerAdd win grid

    return win
"@

New-Item -ItemType File -Path "src\UI\"-name "MainWindow.hs" -value $mainWindowContent


# Step 6: Modify Main.hs with example code (if not already done)
$mainHsPath = ".\app\Main.hs"
$mainHsContent = @"
{-# LANGUAGE OverloadedStrings, OverloadedLabels #-}

module Main (Main.main) where

import qualified GI.Gtk as Gtk 
import UI.MainWindow (createMainWindow)


main :: IO ()
main = do 
    -- Monadic actions (Not worried about results now)
    _ <- Gtk.init Nothing
    mainWin <- createMainWindow
    _ <- Gtk.on mainWin #destroy Gtk.mainQuit
    Gtk.widgetShowAll mainWin
    Gtk.main
"@


Write-Host "Creating Main.hs file..." -ForegroundColor Green 
New-Item -Path $mainHsPath -ItemType File -Value $mainHsContent -Force


# Step 7: Build and run the Haskell project using cabal
# Using cabal run creates/builds and runs the project
Write-Host "Running the project after a short sleep to let Windows catch its breath..." -ForegroundColor Green
Start-Sleep -Seconds 20
cabal run gi-gtk-test
