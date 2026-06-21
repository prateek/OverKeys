param(
    [Parameter(Mandatory=$true)]
    [string]$Version
)

$outputFolderName = "overkeys_${Version}_x64"
$zipFileName = "${outputFolderName}.zip"
$tempDir = "D:\temp_zip_dir\$outputFolderName"

Remove-Item "D:\inno\LICENSE" -ErrorAction SilentlyContinue

if (Test-Path $tempDir) {
    Remove-Item -Path $tempDir -Recurse -Force
}
New-Item -Path $tempDir -ItemType Directory -Force | Out-Null

# Copy all items from inno directory to the temp directory
Copy-Item -Path "D:\inno\*" -Destination $tempDir -Recurse

# Create zip file with the properly named root folder
$zipPath = "D:\inno-result\$zipFileName"
if (Test-Path $zipPath) {
    Remove-Item -Path $zipPath -Force
}
Compress-Archive -Path "D:\temp_zip_dir\*" -DestinationPath $zipPath

# Clean up the temporary directory
Remove-Item -Path "D:\temp_zip_dir" -Recurse -Force

cd ..