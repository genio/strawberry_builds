# Make sure we only attempt to work for PowerShell v5 and greater
# this allows the use of classes.
if ($PSVersionTable.PSVersion.Major -lt 5) {
    throw "PowerShell v5.0+ is required for psperl. https://docs.microsoft.com/en-us/powershell/scripting/setup/installing-windows-powershell?view=powershell-6";
}
Write-Host("We have a sufficient version of PowerShell");
Write-Host("");

# ExtractArchive
function ExtractArchive {
    param (
        [string]$archive_path = '',
        [string]$out_dir = '',
        [bool]$no_tar = $False
    )
    # tar.exe from Cygwin or MSYS may struggle with Windows-style paths so
    # ensure we are using the one that came with Windows 10
    $tar_path = "$env:WINDIR\system32\tar.exe";
    if (-not ($no_tar) -and ([System.IO.File]::Exists($tar_path))) {
        [void](New-Item -ItemType Directory -Path $out_dir -Force);
        & $tar_path -xf $archive_path -C $out_dir;
        if (-Not $?) {
            Remove-Item -Recurse -Force $out_dir;
            throw "Unable to extract the archive.";
        }
    }
    else {
        # Expand-Archive is much slower than tar, so we only use it as a
        # fallback
        # don't show the progress bar. huge speedup
        $ProgressPreference = 'SilentlyContinue';
        Expand-Archive $archive_path -DestinationPath $out_dir;
        # put it back to normal
        $ProgressPreference = 'Continue';
    }
}

# DownloadFile
function DownloadFile {
    param (
        [string]$url = '',
        [string]$output = '',
        [string]$checksum = ''
    )
    # don't show the download progress bar. huge speedup
    $ProgressPreference = 'SilentlyContinue';
    # Invoke-WebRequest -Uri $url -OutFile $output
    (New-Object System.Net.WebClient).DownloadFile($url, $output);
    # put it back to normal
    $ProgressPreference = 'Continue';
    # we SHOULD now have the file
    if (![System.IO.File]::Exists($output)) {
        throw "We tried to download the file, but something went wrong";
    }
    # check the SHA1 checksums
    [String]$sum = (Get-FileHash -Path $output -Algorithm SHA256).hash;
    if ($sum -ne $checksum) {
        Remove-Item -Path $output -Force;
        throw "The file's SHA256 checksum hash is off. Deleting the file.";
    }
}

# Ensure we have a Z: drive
if (!(Test-Path Z:)) {
    throw "Building Strawberry requires a Z: drive setup. Please create one with several gigs of space for building Strawberry Perl.";
}
Write-Host("We have a Z: drive.");
Write-Host("");

# Ensure we have a Z:\_zips folder
if (!(Test-Path Z:\_zips)) {
    Write-Host("Creating a folder, Z:\_zips");
    New-Item -ItemType Directory -Force -Path "Z:\_zips"
}
Write-Host("We have a Z:\_zips folder.");
Write-Host("");

# Ensure we have a Z:\sw folder
if (!(Test-Path Z:\sw)) {
    Write-Host("Creating a folder, Z:\sw");
    New-Item -ItemType Directory -Force -Path Z:\sw
}
Write-Host("We have a Z:\sw folder");
Write-Host("");

# Ensure we have cmake
if (!(Test-Path Z:\sw\cmake)) {
    [String]$url = "https://github.com/Kitware/CMake/releases/download/v3.20.5/cmake-3.20.5.zip";
    [String]$file = "Z:\_zips\cmake-3.20.5.zip";
    [String]$checksum = "37FD84DB08ECC517B2274C06161978744AB6F3459A89C9AA9B68BEF7E053DD61";
    if (![System.IO.File]::Exists($file)) {
        Write-Host("Downloading $($url). This may take some time as it's 15.8MB.");
        DownloadFile -url $url -output $file -checksum $checksum;
    }
    # extract to a temporary location before moving into place
    ExtractArchive -archive_path $file -out_dir "Z:\_zips\cmake"

    Move-Item "Z:\_zips\cmake\cmake-3.20.5" "Z:\sw\cmake";
    Remove-Item Z:\_zips\cmake -Recurse -Force;
}
Write-Host("We have a Z:\sw\cmake folder");
Write-Host("");

# Ensure we have nasm
if (!(Test-Path Z:\sw\nasm)) {
    [String]$url = "https://www.nasm.us/pub/nasm/releasebuilds/2.15.05/win64/nasm-2.15.05-win64.zip";
    [String]$file = "Z:\_zips\nasm-2.15.05-win64.zip";
    [String]$checksum = "F5C93C146F52B4F1664FA3CE6579F961A910E869AB0DAE431BD871BDD2584EF2";
    if (![System.IO.File]::Exists($file)) {
        Write-Host("Downloading $($url).");
        DownloadFile -url $url -output $file -checksum $checksum;
    }
    # we SHOULD now have the file
    if (![System.IO.File]::Exists($file)) {
        throw "We tried to download nasm, but something went wrong";
    }
    ExtractArchive -archive_path $file -out_dir "Z:\_zips\nasm";
    # Expand-Archive $file -DestinationPath "Z:\_zips\nasm";
    Move-Item "Z:\_zips\nasm\nasm-2.15.05" "Z:\sw\nasm";
    Remove-Item Z:\_zips\nasm -Recurse -Force;
}
Write-Host("We have a Z:\sw\nasm folder");
Write-Host("");

# Ensure we have msys2
if (!(Test-Path Z:\msys64)) {
    [String]$url = "http://repo.msys2.org/distrib/x86_64/msys2-base-x86_64-20210604.sfx.exe";
    [String]$file = "Z:\_zips\msys2-x86_64-20210604.sfx.exe";
    [String]$checksum = "2D7BDB926239EC2AFACA8F9B506B34638C3CD5D18EE0F5D8CD6525BF80FCAB5D";
    if (![System.IO.File]::Exists($file)) {
        Write-Host("Downloading $($url).");
        DownloadFile -url $url -output $file -checksum $checksum;
    }
    
    # just execute the self extracting zip file
    # -y assume yes
    # -o sets the target path
    & $file -y -o"Z:\";
    if (-Not $?) {
        Remove-Item -Recurse -Force "Z:\msys64";
        throw "Unable to extract the archive.";
    }
}
Write-Host("We have a Z:\msys64 folder");
Write-Host("");

# Ensure we have WiX
if (!(Test-Path Z:\sw\wix311)) {
    [String]$url = "https://github.com/wixtoolset/wix3/releases/download/wix3112rtm/wix311-binaries.zip";
    [String]$file = "Z:\_zips\wix311-binaries.zip";
    [String]$checksum = "2C1888D5D1DBA377FC7FA14444CF556963747FF9A0A289A3599CF09DA03B9E2E";
    if (![System.IO.File]::Exists($file)) {
        Write-Host("Downloading $($url).");
        DownloadFile -url $url -output $file -checksum $checksum;
    }

    # this one's weird, so we can't use tar on it
    ExtractArchive -archive_path $file -out_dir "Z:\sw\wix311" -no_tar $True;
}
Write-Host("We have a Z:\wix311 folder");
Write-Host("");

# Ensure we have a working Perl
if (!(Test-Path "Z:\perl")) {
    [String]$url = "https://strawberryperl.com/download/5.32.1.1/strawberry-perl-5.32.1.1-64bit-portable.zip";
    [String]$file = "Z:\_zips\strawberry-perl-5.32.1.1-64bit-portable.zip";
    [String]$checksum = "692646105b0f5e058198a852dc52a48f1cebcaf676d63bbdeae12f4eaee9bf5c";
    if (![System.IO.File]::Exists($file)) {
        Write-Host("Downloading $($url).");
        DownloadFile -url $url -output $file -checksum $checksum;
    }
    Write-Host("Creating a folder, Z:\perl");
    New-Item -ItemType Directory -Force -Path "Z:\perl"
    ExtractArchive -archive_path $file -out_dir "Z:\perl" -no_tar $True;
}
Write-Host("We have Perl. Now we're setting it up");
if (Test-Path 'env:TERM') { Remove-Item env:\TERM }
if (Test-Path 'env:PERL_JSON_BACKEND') { Remove-Item env:\PERL_JSON_BACKEND }
if (Test-Path 'env:PERL_YAML_BACKEND') { Remove-Item env:\PERL_YAML_BACKEND }
if (Test-Path 'env:PERL5LIB') { Remove-Item env:\PERL5LIB }
if (Test-Path 'env:PERL5OPT') { Remove-Item env:\PERL5OPT }
if (Test-Path 'env:PERL_MM_OPT') { Remove-Item env:\PERL_MM_OPT }
if (Test-Path 'env:PERL_MB_OPT') { Remove-Item env:\PERL_MB_OPT }
if (Test-Path 'env:PERL_LOCAL_LIB_ROOT') { Remove-Item env:\PERL_LOCAL_LIB_ROOT }
# Go through the PATH and remove Perl-related items
$good_array = @();
$array = $env:Path.split(";", [System.StringSplitOptions]::RemoveEmptyEntries) | Select-Object -uniq
Foreach ($item in $array) {
    if (-not $item.StartsWith("Z:\")) {
        $good_array += ,$item;
    }
}
$env:Path = $good_array -join ';'
$env:PATH = "Z:\perl\perl\site\bin;Z:\perl\perl\bin;Z:\perl\c\bin;$($env:PATH)";
$env:PATH = "Z:\sw\wix311;$($env:PATH)";
Write-Host("");
