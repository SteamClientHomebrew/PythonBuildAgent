# download python 3.11.8 source code
curl -o Python-3.11.8.tgz https://www.python.org/ftp/python/3.11.8/Python-3.11.8.tgz
# extract the tarball
tar -xzvf Python-3.11.8.tgz >nul 2>&1

Set-Location Python-3.11.8

$vcxprojPath = "PCbuild/pythoncore.vcxproj"
$content = Get-Content $vcxprojPath -Raw  # Read the entire content as a single string

# Replace ClCompile closing tag with runtime library entries for 64-bit (x64) builds
$pattern = '</ClCompile>'
$replacement = @"
<RuntimeLibrary Condition="'`$(Configuration)|`$(Platform)'=='Release|x64'">MultiThreaded</RuntimeLibrary>
<RuntimeLibrary Condition="'`$(Configuration)|`$(Platform)'=='Debug|x64'">MultiThreadedDebug</RuntimeLibrary>
</ClCompile>
"@

$modifiedContent = $content -replace [regex]::Escape($pattern), $replacement
$modifiedContent | Set-Content $vcxprojPath

# get python external libs before build
./PCbuild/get_externals.bat

# build python 3.11.8 for 64-bit (x64)
# ensure Platform is set to x64 so MSBuild produces 64-bit (amd64) artifacts
msbuild PCBuild/pcbuild.sln /p:Configuration=Release /p:Platform=x64 /p:RuntimeLibrary=MT
msbuild PCBuild/pcbuild.sln /p:Configuration=Debug /p:Platform=x64 /p:RuntimeLibrary=MT

# verify python is installed (64-bit)
PCbuild/amd64/python.exe --version

New-Item -ItemType Directory -Path "./python-build" -Force

# copy python 3.11.8 64-bit artifacts to python-build
Copy-Item -Path "./PCbuild/amd64/python311.dll" -Destination "./python-build/python311.dll"
Copy-Item -Path "./PCbuild/amd64/python311_d.dll" -Destination "./python-build/python311_d.dll"

# List the contents of the python-build directory
Get-ChildItem -Path "./python-build"
