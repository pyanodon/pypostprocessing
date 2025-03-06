param(
    [String]$FactorioPath = "C:\Games\Factorio\bin\x64\factorio.exe",
    [String]$FactorioDataPath = "$env:APPDATA\Factorio",
    [String]$FactorioModsPath = "$FactorioDataPath\mods.dev",
    [Boolean]$QuietMode = $false
)

# Here's how this script works and why:
function Print-PyExplanation{
    Write-Host "Pyanodon's PostProcessing is a mod that changes a lot about the tech tree. In particular, it ensures that if you get a recipe from a tech, then you must already have a way to make all the ingredients for that recipe. It also does things like automatic tech scaling. However, it had two problems: 1) it was slow to start up, and 2) it also tried to edit techs from other mods, which often resulted in problems. The cache files solve both problems: this script loads a specific subset of the Py mods, applies the tech tree correction and stores the modifications made in a cache file. This cache file can then be loaded instead of recalculating the tech tree corrections from scratch. In particular, this is much faster, and if a player loads other mods, those mods won't have their tech trees modified."
    Write-Host ""
    Write-Host "This script will load Factorio from the command line, capture the tech tree changes and save them in a file. You can pick the mod sets that you want a cache file for. This is not limited to the Py mods: you can add your own mods on top of this, such as PyBlock, and generate a cache file. These cache files can then be registered with PyPostProcessing in the data-update stage of your mod, so that players using your mod will use your cache file, and not the preconfigured ones. You can check for example data-updates.lua in the dev version of PyCoalProcessing to see how to register a cache file."
    Write-Host ""
    Write-Host "This script has two main menus. The first menu allows you to set variables, in particular the Factorio paths. If you want to save time, you can also call this script with parameters like so:"
    Write-Host ""
    Write-Host "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe -executionpolicy bypass -file ""C:\Users\<username>\AppData\Roaming\Factorio\packs\PyanodonGit\pypostprocessing\PyPP-Regen-New.ps1"" -FactorioPath ""C:\Program Files (x86)\Steam\steamapps\common\Factorio\bin\x64\factorio.exe"" -FactorioDataPath ""C:\Users\<username>\AppData\Roaming\Factorio"" -FactorioModsPath ""C:\Users\<username>\AppData\Roaming\Factorio\packs\PyanodonGit"
    Write-Host ""
    Write-Host "On the way to the second menu, this script detects existing cache files. The second menu then allows you to configure what cache file should be (re)generated. The main tool for this is that you are able to enable and disable cache files using a regex. Only enabled cache files will be (re)generated. Since this is a regex, you have to escape backslashes in Windows paths! It's also nice to know that entering an empty value will enable or disable all mods (since they all match the empty regex)."
    Write-Host ""
    Write-Host "The second menu also allows you to add your own cache file. You will have to enter the folder it will end up in, and then you can select a 'base': a starting set of mods to be used for your new cache files, taken from the existing cache files. You can then add and remove any installed mods to this set."
    Write-Host ""
}

class CacheFile{
    [string[]]$Mods
    [string]$Path
    [bool]$Enabled
    CacheFile(
        [System.IO.FileInfo]$file
    ){
        $this.Mods = $file.BaseName -split "\+"
        $this.Path = $file.ToString()
        $this.Enabled = $true
    }
    CacheFile(
        [string[]]$mods,
        [string]$mod_folder
    ){
        $this.Mods = $mods
        $this.Path = [IO.Path]::Combine($global:FactorioModsPath, $mod_folder, (($mods -join "+") + ".lua")) 
        $this.Enabled = $true
    }
}

# start with the menu definitions, the real code comes later

function Print-PySettings{
    Write-Host "These are the current settings:"
    Write-Host "Factorio binary path is $FactorioPath"
    Write-Host "Factorio data folder path is $FactorioDataPath"
    Write-Host "Factorio mods folder path is $FactorioModsPath"
    Write-Host "Quiet mode is $QuietMode"
}

function Choose-FactorioPath{
    param(
        [ref][string]$path,
        [string]$path_name
    )
    $path.Value = Read-Host "Enter a new value for the $path_name. Its current value is $($path.Value)"
}

function Choose-PySettingsMenu{
    $binary_path = New-Object System.Management.Automation.Host.ChoiceDescription "Change Factorio &binary path", "Set a new path for the Factorio binary."
    $data_path = New-Object System.Management.Automation.Host.ChoiceDescription "Change Factorio &data path", "Set a new path for the Factorio data folder."
    $mods_path = New-Object System.Management.Automation.Host.ChoiceDescription "Change Factorio &mods path", "Set a new path for the Factorio mods folder."
    $quiet_mode = New-Object System.Management.Automation.Host.ChoiceDescription "Toggle &quiet mode", "Quiet mode means the output of Factorio is not shown here."
    $explain = New-Object System.Management.Automation.Host.ChoiceDescription "E&xplain", "Explain what this script is for."
    $continue = New-Object System.Management.Automation.Host.ChoiceDescription "&Continue", "Continue to cache file selection."
    $exit = New-Object System.Management.Automation.Host.ChoiceDescription "&Exit", "Exit this script early."
    $options = [System.Management.Automation.Host.ChoiceDescription[]]($binary_path, $data_path, $mods_path, $quiet_mode, $explain, $continue, $exit)

    $done = $false
    while (!$done){
        Print-PySettings

        $decision = $host.ui.PromptForChoice("Cache file generation settings", "Pick an option", $options, 5)
        switch ($decision)
        {
            0 {Choose-FactorioPath ([ref]$FactorioPath) "binary path"}
            1 {Choose-FactorioPath ([ref]$FactorioDataPath) "data path"}
            2 {Choose-FactorioPath ([ref]$FactorioModsPath) "mods path"}
            3 {
                $Global:QuietMode = !$QuietMode
                Write-Host "Toggled quiet mode, new value is $QuietMode"
            }
            4 {Print-PyExplanation}
            6 {
                Write-Host "Exiting early, bye!"
                Exit
            }
            Default {$done = $true}
        }
    }
}

function Print-PyCacheFiles{
    Write-Host -ForegroundColor White "Current list of cache files to generate:"
    foreach ($CacheFileModList in $CacheFileModLists)
    {
        if ($CacheFileModList.Enabled){
            Write-Host $CacheFileModList.Path
        }
    }
    Write-Host -ForegroundColor White "Current list of ignored cache files:"
    foreach ($CacheFileModList in $CacheFileModLists)
    {
        if (!$CacheFileModList.Enabled){
            Write-Host $CacheFileModList.Path
        }
    }
}

function Toggle-PyCacheFiles{
    param(
        [boolean]$value
    )
    $Regex = Read-Host "Give a regex to select a subset of the cache files to toggle. A partial match of the regex against the full path of the cache file will set the Enabled state to $value"
    foreach ($CacheFileModList in $CacheFileModLists)
    {
        if ($CacheFileModList.Path -match $Regex){
            if ($CacheFileModList.Enabled -ne $value){
                $CacheFileModList.Enabled = $value
                Write-Host "Matched $($CacheFileModList.Path)"
            }
        }
    }
}

function Add-PyCacheFile{
    function Print-PyModlist{
        param(
            [System.Collections.Generic.List[string]]$ModList
        )
        if ($ModList.Count -gt 0){
            $ModList -join "+"
        }else{
            "(none)"
        }
    }

    $Subpath = Read-Host "Give the subdirectory of $FactorioModsPath where this cache file will be put (for example, pypostprocessing\cached-configs)"

    Write-Host "0: (none)"
    $Counter = 1
    foreach ($CacheFileModList in $CacheFileModLists)
    {
        Write-Host ("${Counter}: " + ($CacheFileModList.Mods -Join "+"))
        $Counter++
    }
    $done = $False
    do {
        $ModListBaseIndex = Read-Host "Pick a mod set index to start from"
        $ModListBaseIndexAsInt = $ModListBaseIndex -as [int]
        if ($ModListBaseIndexAsInt -ne $null){
            $done = ($ModListBaseIndexAsInt -ge 0) -and ($ModListBaseIndexAsInt -le $CacheFileModLists.Count)
        }
    } until ($done)

    if ($ModListBaseIndexAsInt -eq 0){
        $Mods = [System.Collections.Generic.List[string]]::new()
    }else{
        $Mods = [System.Collections.Generic.List[string]]::new($CacheFileModLists[$ModListBaseIndexAsInt - 1].Mods)
    }
    Write-Host "Choosing: $(Print-PyModlist $Mods)"

    $add_mod = New-Object System.Management.Automation.Host.ChoiceDescription "&Add mod", "Add a mod to the mod set."
    $remove_mod = New-Object System.Management.Automation.Host.ChoiceDescription "&Remove mod", "Remove a mod from the mod set."
    $list_mods = New-Object System.Management.Automation.Host.ChoiceDescription "&List mods", "List the mods currently in the mod set."
    $finish = New-Object System.Management.Automation.Host.ChoiceDescription "&Finish", "Add the cache file and return to the previous menu."
    $cancel = New-Object System.Management.Automation.Host.ChoiceDescription "&Cancel", "Don't add the cache file, go back to the previous menu."
    $options = [System.Management.Automation.Host.ChoiceDescription[]]($add_mod, $remove_mod, $list_mods, $finish, $cancel)

    $done = $false
    while (!$done){
        $decision = $host.ui.PromptForChoice("Py mod set selection", "Pick an option", $options, 2)
        switch ($decision)
        {
            0 {
                $ModToAdd = Read-Host "Pick a mod to add to the mod set"
                if ($Mods -contains $ModToAdd){
                    Write-Host "Ignoring mod, already added"
                }elseif($ModListJsonNames -contains $ModToAdd){
                    $Mods.Add($ModToAdd)
                    $Mods.Sort()
                    Write-Host "Added mod, current mods are: $(Print-PyModlist $Mods)"
                }else{
                    Write-Host "Ignoring mod, not present in mod-list.json"
                }
            }
            1 {
                $ModToAdd = Read-Host "Pick a mod to remove from the mod set"
                if ($Mods -contains $ModToAdd){
                    $Mods.Remove($ModToAdd)
                    Write-Host "Removed mod, current mods are: $(Print-PyModlist $Mods)"
                }else{
                    Write-Host "Ignoring mod, not present in current mod list"
                }
            }
            2 {
                Write-Host "Current mods are: $(Print-PyModlist $Mods)"
            }
            3 {
                $CacheFileToAdd = [CacheFile]::new($Mods, $Subpath)
                $CacheFileModLists.Add($CacheFileToAdd)
                Write-Host "Added cache file $($CacheFileToAdd.Path)"
                $done = $true
            }
            Default {$done = $true}
        }
    }
}

function Choose-PyCacheFiles{
    $print_sets = New-Object System.Management.Automation.Host.ChoiceDescription "&Print cache files", "Print all cache files that will get generated"
    $ignore_sets = New-Object System.Management.Automation.Host.ChoiceDescription "&Ignore cache files", "Ignore cache files, they will not be (re)generated."
    $unignore_sets = New-Object System.Management.Automation.Host.ChoiceDescription "&Unignore cache files", "Activate cache files, they will be (re)generated."
    $add_sets = New-Object System.Management.Automation.Host.ChoiceDescription "&Add cache files", "Add a cache file to be generated."
    $return = New-Object System.Management.Automation.Host.ChoiceDescription "&Return", "Return to the previous menu."
    $options = [System.Management.Automation.Host.ChoiceDescription[]]($print_sets, $ignore_sets, $unignore_sets, $add_sets, $return)

    $done = $false
    while (!$done){
        $decision = $host.ui.PromptForChoice("Py cache file selection", "Pick an option", $options, 4)
        switch ($decision)
        {
            0 {Print-PyCacheFiles}
            1 {Toggle-PyCacheFiles $false}
            2 {Toggle-PyCacheFiles $true}
            3 {Add-PyCacheFile}
            Default {$done = $true}
        }
    }
}

function Space-Mode{
    $Regex = 'pystellarexpedition'
    foreach ($CacheFileModList in $CacheFileModLists)
    {
        if ($CacheFileModList.Path -match $Regex){
            $CacheFileModList.Enabled = $true
            Write-Host "Matched $($CacheFileModList.Path)"
        }else{
            $CacheFileModList.Enabled = $false
        }
    }
}

function Choose-PyModSetMenu{
    $change_sets = New-Object System.Management.Automation.Host.ChoiceDescription "&Change cache file sets", "Change what cache files to generate"
    $print_sets = New-Object System.Management.Automation.Host.ChoiceDescription "&Print cache files", "Print all cache files that will get generated"
    $print_settings = New-Object System.Management.Automation.Host.ChoiceDescription "P&rint settings", "Print all current settings."
    $explain = New-Object System.Management.Automation.Host.ChoiceDescription "E&xplain", "Explain what this script is for."
    $generate = New-Object System.Management.Automation.Host.ChoiceDescription "&Generate", "Begin cache file generation."
    $space = New-Object System.Management.Automation.Host.ChoiceDescription "&Space Mode", "Quickly generate cache files just for pySE and pyAliens."
    $exit = New-Object System.Management.Automation.Host.ChoiceDescription "&Exit", "Exit this script."
    $options = [System.Management.Automation.Host.ChoiceDescription[]]($change_sets, $print_sets, $print_settings, $explain, $space, $generate, $exit)

    $done = $false
    while (!$done){
        $decision = $host.ui.PromptForChoice("Py cache file generation", "Pick an option", $options, 5)
        switch ($decision)
        {
            0 {Choose-PyCacheFiles}
            1 {Print-PyCacheFiles}
            2 {Print-PySettings}
            3 {Print-PyExplanation}
            4 {
                Space-Mode
                $done = $true
            }
            6 {
                Write-Host "Exiting early, bye!"
                Exit
            }
            Default {$done = $true}
        }
    }
}

# Make the window nicely large
mode 300
Write-Host -ForegroundColor White "Starting Pyanodon's cache file generation script"

Choose-PySettingsMenu

# read mod-list.json
$ModListJson = "$FactorioModsPath\mod-list.json"
$ModListJsonContentRaw = Get-Content $ModListJson -Raw
$ModListJsonContent = $ModListJsonContentRaw | ConvertFrom-Json
Write-Host -ForegroundColor White ("Found $($ModListJsonContent.mods.Length) mods in the mods-list.json:")
$ModListJsonNames = New-Object System.Collections.Generic.List[string]
foreach ($Mod in $ModListJsonContent.mods)
{
    Write-Host "$($Mod.name) (currently $(If ($Mod.enabled) {"enabled"} Else {"disabled"}))"
    $ModListJsonNames.Add($Mod.name)
}
Write-Host "This script will attempt to restore these enabled/disabled values on exit, but it can only do so if exited through the menu or through control+C, please don't close the terminal window."

# find existing cache files
[System.IO.FileInfo[]] $ExistingCacheFiles = @(Get-ChildItem "$FactorioModsPath\*\cached-configs" -Exclude run.lua)
Write-Host -ForegroundColor White "Found $($ExistingCacheFiles.Length) existing cache files:"
$CacheFileModLists = New-Object System.Collections.Generic.List[CacheFile]
foreach ($ExistingCacheFile in $ExistingCacheFiles)
{
    $CacheFileToAdd = [CacheFile]::new($ExistingCacheFile)
    $ShouldAddCacheFile = $true
    foreach ($Mod in $CacheFileToAdd.Mods)
    {
        if (!$ModListJsonNames.Contains($Mod)){
            Write-Host "Skipping $ExistingCacheFile because $Mod does not appear in the mods-list.json"
            $ShouldAddCacheFile = $false
            break
        }
    }
    if ($ShouldAddCacheFile){
        Write-Host $ExistingCacheFile
        $CacheFileModLists.Add($CacheFileToAdd)
    }
}

Choose-PyModSetMenu

function Extract-PyCacheContent{
    param(
        [string]$LogFile
    )
    $StartToken = "<BEGINPYPP>" #\1
    $EndToken = "<ENDPYPP>" #\2

    $StartPos = $LogFile.IndexOf($StartToken)
    $EndPos = $LogFile.IndexOf($EndToken)
    if(($StartPos -gt 0) -and ($EndPos -gt 0)){
        $StartPos += $StartToken.Length
        $SubsectionLength = $EndPos - $StartPos
        $Content = $LogFile.Substring($StartPos, $SubsectionLength)
        return $Content -replace "([^`r])`n", "`$1`r`n" -replace "^`n", "`r`n" #enforce CR LF
    }else{
        return $null
    }
}

# read settings-updates so we can restore it if needed
$PyPPConfigPath = "$FactorioModsPath\pypostprocessing\settings-updates.lua"
$PyPPPrevConfig = Get-Content -Path $PyPPConfigPath -Raw

# this restores the settings even if someone control+C kills the script. Won't work if you exit the containing shell though...
Register-EngineEvent PowerShell.Exiting –Action{
    Set-Content -Path $PyPPConfigPath -Value $PyPPPrevConfig -Encoding UTF8 -NoNewline
    Set-Content -Path $ModListJson -Value $ModListJsonContentRaw -Encoding UTF8 -NoNewline
    Remove-Item -Path "$FactorioDataPath\.lock" -Force
}

# Enable PyPP dev mode
$PyPPConfig = $PyPPPrevConfig.Replace('data.raw["bool-setting"]["pypp-dev-mode"].forced_value  = false', 'data.raw["bool-setting"]["pypp-dev-mode"].forced_value  = true')
$PyPPConfig = $PyPPConfig.Replace('data.raw["bool-setting"]["pypp-create-cache"].forced_value  = false', 'data.raw["bool-setting"]["pypp-create-cache"].forced_value  = true')
Set-Content -Path $PyPPConfigPath -Value $PyPPConfig -Encoding UTF8 -NoNewline

$FactorioArgs = "--mod-directory $FactorioModsPath --benchmark notafile" #Stand in for "load then exit"
$BaseMods = @(
    "base",
    "pypostprocessing"
)
$GraphicModsLookup = @{
    pyalienlife = @("pyalienlifegraphics", "pyalienlifegraphics2", "pyalienlifegraphics3")
    ; pyalternativeenergy = @("pyalternativeenergygraphics")
    ; pycoalprocessing = @("pycoalprocessinggraphics")
    ; pyfusionenergy = @("pyfusionenergygraphics")
    ; pyhightech = @("pyhightechgraphics")
    ; pypetroleumhandling = @("pypetroleumhandlinggraphics")
    ; pyrawores = @("pyraworesgraphics")
    ; pyaliens = @("pyaliensgraphics")
    ; pystellarexpedition = @("pystellarexpeditiongraphics")
}

foreach ($CacheFileModList in $CacheFileModLists){
    $Path = $CacheFileModList.Path
    if (!$CacheFileModList.Enabled){
        Write-Host "Skipping disabled cache file $Path..."
        continue
    }

    Write-Host "Generating cache file $Path..."

    # enable the right mods
    $GraphicModsToAdd = [System.Collections.Generic.List[string]]::new()
    foreach ($Mod in $CacheFileModList.Mods){
        foreach ($GraphicMod in $GraphicModsLookup[$Mod]){
            $GraphicModsToAdd.Add($GraphicMod)
        }
    }
    foreach ($Mod in $ModListJsonContent.mods){
        $Mod.enabled = $BaseMods.Contains($Mod.name)
        if ($CacheFileModList.Mods.Contains($Mod.name)){
            $Mod.enabled = $true
        }
        if ($GraphicModsToAdd.Contains($Mod.name)){
            $Mod.enabled = $true
        }
    }
    Set-Content -Path $ModListJson -Value (ConvertTo-Json $ModListJsonContent) -Encoding UTF8

    $TimeBeforeStartingFactorio = [DateTime]::Now
    
    # run Factorio
    $pinfo = New-Object System.Diagnostics.ProcessStartInfo
    $pinfo.FileName = $FactorioPath
    $pinfo.RedirectStandardError = $QuietMode
    $pinfo.RedirectStandardOutput = $QuietMode
    $pinfo.UseShellExecute = $false
    $pinfo.Arguments = $FactorioArgs
    $p = New-Object System.Diagnostics.Process
    $p.StartInfo = $pinfo
    $p.Start() | Out-Null
    $p.WaitForExit()
    #Start-Process -FilePath "$FactorioPath" -ArgumentList "$FactorioArgs" -WorkingDirectory (Split-Path -Path $FactorioPath -Parent) -Wait -RedirectStandardOutput ".\NUL" -RedirectStandardError "..\NUL"

    $LogFilePath = "$FactorioDataPath\factorio-current.log"
    $lastModifiedDate = (Get-Item $LogFilePath).LastWriteTime
    
    if ($lastModifiedDate -lt $TimeBeforeStartingFactorio){
        Read-Host -Prompt "Mod Set $Path did not seem to have loaded successfully: the timestamp of the log file is from before Factorio was started. Pausing for dramatic effect and so you can read the error message."
        continue
    }

    # extract the cache
    $LogFile = Get-Content -Path $LogFilePath -Raw
    $Content = Extract-PyCacheContent($LogFile)
    if ($Content){
        Set-Content -Path $Path -Value $Content -Encoding UTF8 -NoNewline
        if ($QuietMode){
            Write-Host "Done!"
        }else{
            Write-Host "Cache file $Path loaded successfully!"
        }
    }else{
        Read-Host -Prompt "Mod Set $Path did not load successfully. Pausing for dramatic effect and so you can read the error $(If ($QuietMode) {"log"} Else {"message"})."
    }
}

Write-Host "Finished generating caches, bye!"
Pause
