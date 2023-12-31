###################
#    This file implements a check on System32 executable
#    files for backdoor by renamed file
#    Copyright (C) 2023  Maurice Lambert

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
            return !CompareFilename(GetCompiledFilename(filename), Path.GetFileName(filename));
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

## Method 1: LoadFrom
### $_ = [Reflection.Assembly]::LoadFrom("PowershellBackdoorCheck.dll")

## Method 2: LoadFile
### $path = Join-Path -Path (Get-Location).path -ChildPath "PowershellBackdoorCheck.dll"
### $_ = [Reflection.Assembly]::LoadFile($path)

# Load DLL from bytes

## Get bytes
### Method 1: from base64
#### [byte[]] $apprun  = [System.Convert]::FromBase64String('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bmFtZTIAYXJncwBTeXN0ZW0uUnVudGltZS5Db21waWxlclNlcnZpY2VzAENvbXBpbGF0aW9uUmVsYXhhdGlvbnNBdHRyaWJ1dGUAUnVudGltZUNvbXBhdGliaWxpdHlBdHRyaWJ1dGUAUG93ZXJzaGVsbEJhY2tkb29yQ2hlY2sAU3lzdGVtLkRpYWdub3N0aWNzAEZpbGVWZXJzaW9uSW5mbwBHZXRWZXJzaW9uSW5mbwBnZXRfT3JpZ2luYWxGaWxlbmFtZQBTeXN0ZW0uSU8AUGF0aABHZXRJbnZhbGlkRmlsZU5hbWVDaGFycwBTdHJpbmcAU3lzdGVtLlRleHQuUmVndWxhckV4cHJlc3Npb25zAFJlZ2V4AEVzY2FwZQBGb3JtYXQAUmVwbGFjZQBHZXRGaWxlTmFtZVdpdGhvdXRFeHRlbnNpb24AVG9VcHBlcgBDb250YWlucwBHZXRGaWxlTmFtZQBFbnZpcm9ubWVudABnZXRfU3lzdGVtRGlyZWN0b3J5AERpcmVjdG9yeUluZm8ARmlsZUluZm8AR2V0RmlsZXMARmlsZVN5c3RlbUluZm8AZ2V0X0Z1bGxOYW1lAENvbWJpbmUAQ29uc29sZQBXcml0ZUxpbmUAAAEAKygAWwB7ADAAfQBdACoAXAAuACsAJAApAHwAKABbAHsAMAB9AF0AKwApAAALKgAuAGUAeABlAAAPYwBtAGQALgBlAHgAZQAAF3UAdABpAGwAbQBhAG4ALgBlAHgAZQAAD28AcwBrAC4AZQB4AGUAADdUAGgAaQBzACAAcwB5AHMAdABlAG0AIABpAHMAIABiAGEAYwBrAGQAbwBvAHIAZQBkACAAIQAAPVQAaABpAHMAIABzAHkAcwB0AGUAbQAgAGkAcwAgAG4AbwB0ACAAYgBhAGMAawBkAG8AbwByAGUAZAAuAAAAAABFshrbYD4mRIc6k0qB9NbMAAi3elxWGTTgiQQAAQ4OBQACAg4OBAABAg4DAAACBQABAR0OAyAAAQQgAQEIBQABEhEOAyAADgQAAB0DBSABAR0DBQACDg4cBgADDg4ODgQHAg4OBCABAg4DAAAOBCABAQ4GIAEdEikOCwcFEiUSKQIdEikIBQACDg4OBAABAQ4IAQAIAAAAAAAeAQABAFQCFldyYXBOb25FeGNlcHRpb25UaHJvd3MBtCgAAAAAAAAAAAAAzigAAAAgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAMAoAAAAAAAAAAAAAAAAX0NvckRsbE1haW4AbXNjb3JlZS5kbGwAAAAAAP8lACAAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABABAAAAAYAACAAAAAAAAAAAAAAAAAAAABAAEAAAAwAACAAAAAAAAAAAAAAAAAAAABAAAAAABIAAAAWEAAAIQCAAAAAAAAAAAAAIQCNAAAAFYAUwBfAFYARQBSAFMASQBPAE4AXwBJAE4ARgBPAAAAAAC9BO/+AAABAAAAAAAAAAAAAAAAAAAAAAA/AAAAAAAAAAQAAAACAAAAAAAAAAAAAAAAAAAARAAAAAEAVgBhAHIARgBpAGwAZQBJAG4AZgBvAAAAAAAkAAQAAABUAHIAYQBuAHMAbABhAHQAaQBvAG4AAAAAAAAAsATkAQAAAQBTAHQAcgBpAG4AZwBGAGkAbABlAEkAbgBmAG8AAADAAQAAAQAwADAAMAAwADAANABiADAAAAAsAAIAAQBGAGkAbABlAEQAZQBzAGMAcgBpAHAAdABpAG8AbgAAAAAAIAAAADAACAABAEYAaQBsAGUAVgBlAHIAcwBpAG8AbgAAAAAAMAAuADAALgAwAC4AMAAAAFgAHAABAEkAbgB0AGUAcgBuAGEAbABOAGEAbQBlAAAAUABvAHcAZQByAHMAaABlAGwAbABCAGEAYwBrAGQAbwBvAHIAQwBoAGUAYwBrAC4AZABsAGwAAAAoAAIAAQBMAGUAZwBhAGwAQwBvAHAAeQByAGkAZwBoAHQAAAAgAAAAYAAcAAEATwByAGkAZwBpAG4AYQBsAEYAaQBsAGUAbgBhAG0AZQAAAFAAbwB3AGUAcgBzAGgAZQBsAGwAQgBhAGMAawBkAG8AbwByAEMAaABlAGMAawAuAGQAbABsAAAANAAIAAEAUAByAG8AZAB1AGMAdABWAGUAcgBzAGkAbwBuAAAAMAAuADAALgAwAC4AMAAAADgACAABAEEAcwBzAGUAbQBiAGwAeQAgAFYAZQByAHMAaQBvAG4AAAAwAC4AMAAuADAALgAwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAgAAAMAAAA4DgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA')

### Method 2: from file
#### $apprun = [System.IO.File]::ReadAllBytes("PowershellBackdoorCheck.dll")

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
#>
