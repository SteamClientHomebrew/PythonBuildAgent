C:\mingw32\bin\dlltool.exe --version

# download python 3.11.8 source code
curl -o Python-3.11.8.tgz https://www.python.org/ftp/python/3.11.8/Python-3.11.8.tgz
# extract the tarball
tar -xzvf Python-3.11.8.tgz >nul 2>&1

Set-Location Python-3.11.8

$vcxprojPath = "PCbuild/pythoncore.vcxproj"
$content = Get-Content $vcxprojPath -Raw  # Read the entire content as a single string

$pattern = '</ClCompile>'
$replacement = @"
<RuntimeLibrary Condition="'`$(Configuration)|`$(Platform)'=='Release|Win32'">MultiThreaded</RuntimeLibrary>
<RuntimeLibrary Condition="'`$(Configuration)|`$(Platform)'=='Debug|Win32'">MultiThreadedDebug</RuntimeLibrary>
</ClCompile>
"@

$modifiedContent = $content -replace [regex]::Escape($pattern), $replacement
$modifiedContent | Set-Content $vcxprojPath

# get python external libs before build
./PCbuild/get_externals.bat
# build python 3.11.8
msbuild PCBuild/pcbuild.sln /p:Configuration=Release /p:RuntimeLibrary=MT
msbuild PCBuild/pcbuild.sln /p:Configuration=Debug /p:RuntimeLibrary=MT
# verify python is installed
PCbuild/win32/python.exe --version

New-Item -ItemType Directory -Path "./python-build" -Force

Write-Host "Generating delay libraries for Python 3.11.8..."

Get-Command dlltool

C:\mingw32\bin\dlltool.exe --input-def ../exports.def --output-delaylib "./python-build/python311.lib" --dllname "./PCbuild/win32/python311.dll"
C:\mingw32\bin\dlltool.exe --input-def ../exports.def --output-delaylib "./python-build/python311_d.lib" --dllname "./PCbuild/win32/python311_d.dll"

Write-Host "Done!"

# copy python 3.11.8 to python-build
Copy-Item -Path "./PCbuild/win32/python311.dll" -Destination "./python-build/python311.dll"
Copy-Item -Path "./PCbuild/win32/python311_d.dll" -Destination "./python-build/python311_d.dll"

# List the contents of the python-build directory
Get-ChildItem -Path "./python-build"

