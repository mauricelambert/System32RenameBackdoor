![System32RenameBackdoor Logo](https://mauricelambert.github.io/info/CSharp/security/System32RenameBackdoor_small.png "System32RenameBackdoor logo")

# System32RenameBackdoor

## Description

This repository implements a check on System32 executable files to detect backdoor by renamed file.

## Requirements

1. To run the self-contained Windows executable:
     - No requirements
2. To compile:
     - Dotnet
3. To run the dotnet Windows executable:
     - Dotnet framework version 7
4. To run the powershell script:
     - Powershell version 5

## Compilation

### Git

```bash
git clone "https://github.com/mauricelambert/System32RenameBackdoor.git"
cd "System32RenameBackdoor"
dotnet build -c Release
```

### Wget

```bash
wget https://github.com/mauricelambert/System32RenameBackdoor/archive/refs/heads/main.zip
unzip main.zip
cd System32RenameBackdoor-main
dotnet build -c Release
```

### cURL

```bash
curl -O https://github.com/mauricelambert/System32RenameBackdoor/archive/refs/heads/main.zip
unzip main.zip
dotnet build -c Release
```

## Usages

### Command line

```bash
BackdoorCheck.exe                  # self-contained Windows executable
powershell .\BackdoorCheck.ps1     # Powershell script
BackdoorCheck\BackdoorCheck.exe    # .NET Windows executable
```

## Links

 - [Github](https://github.com/mauricelambert/System32RenameBackdoor)
 - [Windows executable](https://github.com/mauricelambert/System32RenameBackdoor/releases/latest)

## License

Licensed under the [GPL, version 3](https://www.gnu.org/licenses/).
