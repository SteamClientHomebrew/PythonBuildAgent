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
# build python 3.11.8 as win32 and release
msbuild PCBuild/pcbuild.sln /p:Configuration=Release /p:Platform=Win32 /p:RuntimeLibrary=MT
msbuild PCBuild/pcbuild.sln /p:Configuration=Debug /p:Platform=Win32 /p:RuntimeLibrary=MT
# verify python is installed
PCbuild/win32/python.exe --version

New-Item -ItemType Directory -Path "./python-build" -Force

Set-Location ..

dlltool --input-def ./exports.def --output-delaylib "./python-build/python311.lib" --dllname "./PCbuild/win32/python311.dll"
dlltool --input-def ./exports.def --output-delaylib "./python-build/python311_d.lib" --dllname "./PCbuild/win32/python311_d.dll"

# copy python 3.11.8 to python-build
Copy-Item -Path "./PCbuild/win32/python311.dll" -Destination "./python-build/python311.dll"
Copy-Item -Path "./PCbuild/win32/python311_d.dll" -Destination "./python-build/python311_d.dll"

# List the contents of the python-build directory
Get-ChildItem -Path "./python-build"

