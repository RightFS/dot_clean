<#
.SYNOPSIS
    Windows equivalent of macOS dot_clean utility.
    
.DESCRIPTION
    Cleans macOS system files like .DS_Store from Windows drives.
    Simple usage: .\Clean-MacOS.ps1 D:\path\to\clean
    
.PARAMETER Path
    The path to clean. Required.
    
.EXAMPLE
    .\Clean-MacOS.ps1 D:\Photos
#>

param (
    [Parameter(Position = 0, Mandatory = $true)]
    [string]$Path
)

# Display current date and user information
$currentDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name

Write-Host "Current Date and Time: $currentDate" -ForegroundColor Gray
Write-Host "Current User: $currentUser" -ForegroundColor Gray
Write-Host ""

# Check if path exists
if (-not (Test-Path -Path $Path)) {
    Write-Host "Error: Path '$Path' does not exist." -ForegroundColor Red
    exit 1
}

# List of macOS garbage file patterns
$macOSFilePatterns = @(
    "*.DS_Store",             # macOS Finder metadata
    "*._*",                   # macOS resource fork files
    "*.AppleDouble",          # Apple Double resource fork
    "*.LSOverride",           # Finder item override metadata
    ".Spotlight-V100",        # Spotlight index
    ".Trashes",               # macOS Trash directory
    ".fseventsd",             # File System Events metadata
    ".TemporaryItems",        # Temporary items
    ".VolumeIcon.icns",       # Volume icon file
    ".com.apple.timemachine*" # Time Machine metadata
)

# Counters
$foundCount = 0
$deletedCount = 0
$totalSize = 0

# Show header
Write-Host "Clean-MacOS - Windows equivalent of dot_clean" -ForegroundColor Cyan
Write-Host "-------------------------------------------" -ForegroundColor Cyan
Write-Host "Cleaning macOS system files from: $Path" -ForegroundColor Yellow
Write-Host ""

# Process each pattern
foreach ($pattern in $macOSFilePatterns) {
    # Find files matching the current pattern
    try {
        $matchingFiles = Get-ChildItem -Path $Path -Filter $pattern -Recurse -Force -ErrorAction SilentlyContinue | 
                         Where-Object { -not $_.PSIsContainer }

        foreach ($file in $matchingFiles) {
            $foundCount++
            $fileSize = $file.Length
            $totalSize += $fileSize
            $fileSizeFormatted = "{0:N2} KB" -f ($fileSize / 1KB)
            
            try {
                Remove-Item -Path $file.FullName -Force -ErrorAction Stop
                $deletedCount++
                Write-Host "Removed: $($file.FullName) ($fileSizeFormatted)" -ForegroundColor Green
            }
            catch {
                Write-Host "Failed to remove: $($file.FullName) - $($_.Exception.Message)" -ForegroundColor Red
            }
        }
    }
    catch {
        Write-Host "Error searching for ${pattern}: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Also find and remove hidden .AppleDB and .AppleDesktop directories
try {
    $hiddenDirs = @(
        ".AppleDB",
        ".AppleDesktop"
    )
    
    foreach ($dirName in $hiddenDirs) {
        $matchingDirs = Get-ChildItem -Path $Path -Recurse -Force -ErrorAction SilentlyContinue | 
                        Where-Object { $_.PSIsContainer -and $_.Name -eq $dirName }
        
        foreach ($dir in $matchingDirs) {
            $foundCount++
            
            try {
                Remove-Item -Path $dir.FullName -Recurse -Force -ErrorAction Stop
                $deletedCount++
                Write-Host "Removed directory: $($dir.FullName)" -ForegroundColor Green
            }
            catch {
                Write-Host "Failed to remove directory: $($dir.FullName) - $($_.Exception.Message)" -ForegroundColor Red
            }
        }
    }
}
catch {
    Write-Host "Error searching for hidden directories: $($_.Exception.Message)" -ForegroundColor Red
}

# Display summary
Write-Host ""
Write-Host "Clean-MacOS Summary:" -ForegroundColor Cyan
Write-Host "------------------" -ForegroundColor Cyan
Write-Host "Files found: $foundCount" -ForegroundColor Yellow
Write-Host "Files removed: $deletedCount" -ForegroundColor Green
Write-Host "Total space freed: $("{0:N2} MB" -f ($totalSize / 1MB))" -ForegroundColor Green