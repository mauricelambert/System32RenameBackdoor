###################
#    This file implements a check on System32 executable
#    files for backdoor by renamed file
#    Copyright (C) 2023, 2025  Maurice Lambert

#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.

#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.

#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <https://www.gnu.org/licenses/>.
###################

$source = @"
using System;
using System.IO;
using System.Diagnostics;
using System.Text.RegularExpressions;

namespace BackdoorCheck
{
    public class BackdoorCheck
    {
        public static string GetCompiledFilename(string filename)
        {
            filename = FileVersionInfo.GetVersionInfo(filename).OriginalFilename;
            if (filename == null)
            {
                return "";
            }
            return filename;
        }

        private static string SanitizeFileName(string filename)
        {
            string invalidCharacters = Regex.Escape(new string(System.IO.Path.GetInvalidFileNameChars()));
            string invalidRegex = string.Format(@"([{0}]*\.+$)|([{0}]+)", invalidCharacters);
            return Regex.Replace(filename, invalidRegex, "");
        }

        private static bool CompareFilename(string filename1, string filename2)
        {
            filename2 = Path.GetFileNameWithoutExtension(SanitizeFileName(filename2)).ToUpper();
            filename1 = Path.GetFileNameWithoutExtension(SanitizeFileName(filename1)).ToUpper();
            return filename1.Contains(filename2) || filename2.Contains(filename1);
        }

        public static bool FileIsBackdoored(string filename)
        {
            return !CompareFilename(GetCompiledFilename(filename), Path.GetFileName(filename).Replace("y", "ier"));
        }

        public static bool System32IsBackdoored()
        {
            DirectoryInfo system32_folder = new DirectoryInfo(Environment.SystemDirectory);

            foreach (FileInfo file in system32_folder.GetFiles("*.exe"))
            {
                if (FileIsBackdoored(file.FullName))
                {
                    return true;
                }
            }

            return false;
        }

        public static bool CmdIsBackdoored()
        {

            if (FileIsBackdoored(Path.Combine(Environment.SystemDirectory, "cmd.exe"))) {
                return true;
            } else if (FileIsBackdoored(Path.Combine(Environment.SystemDirectory, "utilman.exe"))) {
                return true;
            } else if (FileIsBackdoored(Path.Combine(Environment.SystemDirectory, "sethc.exe"))) {
                return true;
            } else if (FileIsBackdoored(Path.Combine(Environment.SystemDirectory, "Magnify.exe"))) {
                return true;
            }

            return FileIsBackdoored(Path.Combine(Environment.SystemDirectory, "osk.exe"));
        }

        static void Main(string[] args)
        {
            if (CmdIsBackdoored()) {
                Console.WriteLine("This system is backdoored !");
            } else {
                Console.WriteLine("This system is not backdoored.");
            }
        }
    }
}
"@

Add-Type -TypeDefinition $source -Language CSharp

if ([BackdoorCheck.BackdoorCheck]::CmdIsBackdoored()) {
    Write-Host -BackgroundColor Red -ForegroundColor White "This system is backdoored !"
} else {
    Write-Host -ForegroundColor Green "This system is not backdoored."
}

# Create DLL file from powershell
# Add-Type -TypeDefinition $source -Language CSharp -OutputAssembly "PowershellBackdoorCheck.dll"

# Load DLL file from powershell

## Step 1: Get the DLL full filename
### $path = Join-Path -Path (Get-Location).path -ChildPath "PowershellBackdoorCheck.dll"

## Step 2: Load from file

### Method 1: LoadFrom
#### $_ = [Reflection.Assembly]::LoadFrom($path)

### Method 2: LoadFile
#### $_ = [Reflection.Assembly]::LoadFile($path)

# Load DLL from bytes

## Get bytes
### Method 1: from base64
#### [byte[]] $apprun  = [System.Convert]::FromBase64String('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dGVtMzJJc0JhY2tkb29yZWQAQ21kSXNCYWNrZG9vcmVkAE1haW4ALmN0b3IAZmlsZW5hbWUAZmlsZW5hbWUxAGZpbGVuYW1lMgBhcmdzAFN5c3RlbS5SdW50aW1lLkNvbXBpbGVyU2VydmljZXMAQ29tcGlsYXRpb25SZWxheGF0aW9uc0F0dHJpYnV0ZQBSdW50aW1lQ29tcGF0aWJpbGl0eUF0dHJpYnV0ZQBQb3dlcnNoZWxsQmFja2Rvb3JDaGVjawBTeXN0ZW0uRGlhZ25vc3RpY3MARmlsZVZlcnNpb25JbmZvAEdldFZlcnNpb25JbmZvAGdldF9PcmlnaW5hbEZpbGVuYW1lAFN5c3RlbS5JTwBQYXRoAEdldEludmFsaWRGaWxlTmFtZUNoYXJzAFN0cmluZwBTeXN0ZW0uVGV4dC5SZWd1bGFyRXhwcmVzc2lvbnMAUmVnZXgARXNjYXBlAEZvcm1hdABSZXBsYWNlAEdldEZpbGVOYW1lV2l0aG91dEV4dGVuc2lvbgBUb1VwcGVyAENvbnRhaW5zAEdldEZpbGVOYW1lAEVudmlyb25tZW50AGdldF9TeXN0ZW1EaXJlY3RvcnkARGlyZWN0b3J5SW5mbwBGaWxlSW5mbwBHZXRGaWxlcwBGaWxlU3lzdGVtSW5mbwBnZXRfRnVsbE5hbWUAQ29tYmluZQBDb25zb2xlAFdyaXRlTGluZQAAAQArKABbAHsAMAB9AF0AKgBcAC4AKwAkACkAfAAoAFsAewAwAH0AXQArACkAAAN5AAAHaQBlAHIAAAsqAC4AZQB4AGUAAA9jAG0AZAAuAGUAeABlAAAXdQB0AGkAbABtAGEAbgAuAGUAeABlAAATcwBlAHQAaABjAC4AZQB4AGUAABdNAGEAZwBuAGkAZgB5AC4AZQB4AGUAAA9vAHMAawAuAGUAeABlAAA3VABoAGkAcwAgAHMAeQBzAHQAZQBtACAAaQBzACAAYgBhAGMAawBkAG8AbwByAGUAZAAgACEAAD1UAGgAaQBzACAAcwB5AHMAdABlAG0AIABpAHMAIABuAG8AdAAgAGIAYQBjAGsAZABvAG8AcgBlAGQALgAAAAAA/Ny9xXEld0i1UsWYnGsIVAAIt3pcVhk04IkEAAEODgUAAgIODgQAAQIOAwAAAgUAAQEdDgMgAAEEIAEBCAUAARIRDgMgAA4EAAAdAwUgAQEdAwUAAg4OHAYAAw4ODg4EBwIODgQgAQIOBSACDg4OAwAADgQgAQEOBiABHRIpDgsHBRIlEikCHRIpCAUAAg4ODgQAAQEOCAEACAAAAAAAHgEAAQBUAhZXcmFwTm9uRXhjZXB0aW9uVGhyb3dzAQAAOCkAAAAAAAAAAAAATikAAAAgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEApAAAAAAAAAABfQ29yRGxsTWFpbgBtc2NvcmVlLmRsbAAAAAAA/yUAIAAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABABAAAAAYAACAAAAAAAAAAAAAAAAAAAABAAEAAAAwAACAAAAAAAAAAAAAAAAAAAABAAAAAABIAAAAWEAAAIQCAAAAAAAAAAAAAIQCNAAAAFYAUwBfAFYARQBSAFMASQBPAE4AXwBJAE4ARgBPAAAAAAC9BO/+AAABAAAAAAAAAAAAAAAAAAAAAAA/AAAAAAAAAAQAAAACAAAAAAAAAAAAAAAAAAAARAAAAAEAVgBhAHIARgBpAGwAZQBJAG4AZgBvAAAAAAAkAAQAAABUAHIAYQBuAHMAbABhAHQAaQBvAG4AAAAAAAAAsATkAQAAAQBTAHQAcgBpAG4AZwBGAGkAbABlAEkAbgBmAG8AAADAAQAAAQAwADAAMAAwADAANABiADAAAAAsAAIAAQBGAGkAbABlAEQAZQBzAGMAcgBpAHAAdABpAG8AbgAAAAAAIAAAADAACAABAEYAaQBsAGUAVgBlAHIAcwBpAG8AbgAAAAAAMAAuADAALgAwAC4AMAAAAFgAHAABAEkAbgB0AGUAcgBuAGEAbABOAGEAbQBlAAAAUABvAHcAZQByAHMAaABlAGwAbABCAGEAYwBrAGQAbwBvAHIAQwBoAGUAYwBrAC4AZABsAGwAAAAoAAIAAQBMAGUAZwBhAGwAQwBvAHAAeQByAGkAZwBoAHQAAAAgAAAAYAAcAAEATwByAGkAZwBpAG4AYQBsAEYAaQBsAGUAbgBhAG0AZQAAAFAAbwB3AGUAcgBzAGgAZQBsAGwAQgBhAGMAawBkAG8AbwByAEMAaABlAGMAawAuAGQAbABsAAAANAAIAAEAUAByAG8AZAB1AGMAdABWAGUAcgBzAGkAbwBuAAAAMAAuADAALgAwAC4AMAAAADgACAABAEEAcwBzAGUAbQBiAGwAeQAgAFYAZQByAHMAaQBvAG4AAAAwAC4AMAAuADAALgAwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAgAAAMAAAAYDkAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA')

### Method 2: from file
#### $apprun = [System.IO.File]::ReadAllBytes($path)

## Run method
### [<#1#>Reflection.Assembly<#1#>]::Load($apprun).GetType('BackdoorCheck.BackdoorCheck').GetMethod('CmdIsBackdoored').Invoke($null, $null)

## Import module and use types (namespace -> class -> method)
### [void]([<#1#>Reflection.Assembly<#1#>]::Load($apprun))
### [BackdoorCheck.BackdoorCheck]::CmdIsBackdoored()

<#
In BackdoorCheck.csproj:
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <OutputType>Exe</OutputType>
    <TargetFramework>net7.0</TargetFramework>
    <PublishSingleFile>true</PublishSingleFile>
    <SelfContained>true</SelfContained>
    <RuntimeIdentifier>win-x64</RuntimeIdentifier>
    <EnableCompressionInSingleFile>true</EnableCompressionInSingleFile>
  </PropertyGroup>
</Project>

dotnet publish -r win-x64  -p:PublishSingleFile=true --self-contained true -c Release
dotnet publish -c Release
#>
