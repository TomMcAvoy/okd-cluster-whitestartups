# PowerCLI Script to Configure Fedora CoreOS Template
# This script converts a VM to template and configures it for OKD

param(
    [Parameter(Mandatory=$true)]
    [string]$VCenterServer,
    
    [Parameter(Mandatory=$true)]
    [string]$VCenterUser,
    
    [Parameter(Mandatory=$true)]
    [string]$VCenterPassword,
    
    [Parameter(Mandatory=$true)]
    [string]$TemplateName,
    
    [Parameter(Mandatory=$true)]
    [string]$Datacenter
)

# Import PowerCLI module
Import-Module VMware.PowerCLI

# Disable certificate warnings
Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -Confirm:$false

# Connect to vCenter
Write-Host "Connecting to vCenter Server: $VCenterServer"
try {
    Connect-VIServer -Server $VCenterServer -User $VCenterUser -Password $VCenterPassword
    Write-Host "Successfully connected to vCenter"
} catch {
    Write-Error "Failed to connect to vCenter: $($_.Exception.Message)"
    exit 1
}

try {
    # Get the VM
    $vm = Get-VM -Name $TemplateName -Location (Get-Datacenter -Name $Datacenter)
    
    if (-not $vm) {
        throw "VM '$TemplateName' not found"
    }
    
    Write-Host "Found VM: $($vm.Name)"
    
    # Configure VM settings for OKD
    Write-Host "Configuring VM settings..."
    
    # Set VM to not start automatically
    $vmConfigSpec = New-Object VMware.Vim.VirtualMachineConfigSpec
    $vmConfigSpec.Tools = New-Object VMware.Vim.ToolsConfigInfo
    $vmConfigSpec.Tools.SyncTimeWithHost = $true
    
    # Add extra config for ignition
    $extraConfig = New-Object VMware.Vim.OptionValue
    $extraConfig.Key = "disk.EnableUUID"
    $extraConfig.Value = "true"
    
    $extraConfig2 = New-Object VMware.Vim.OptionValue
    $extraConfig2.Key = "guestinfo.ignition.config.data.encoding"
    $extraConfig2.Value = "base64"
    
    $vmConfigSpec.ExtraConfig = @($extraConfig, $extraConfig2)
    
    # Apply configuration
    $vm.ExtensionData.ReconfigVM($vmConfigSpec)
    Write-Host "VM configuration updated"
    
    # Power off VM if running
    if ($vm.PowerState -eq "PoweredOn") {
        Write-Host "Powering off VM..."
        Stop-VM -VM $vm -Confirm:$false
        do {
            Start-Sleep -Seconds 2
            $vm = Get-VM -Name $TemplateName
        } while ($vm.PowerState -ne "PoweredOff")
    }
    
    # Convert to template
    Write-Host "Converting VM to template..."
    Set-VM -VM $vm -ToTemplate -Confirm:$false
    Write-Host "Successfully converted to template: $TemplateName"
    
} catch {
    Write-Error "Error configuring template: $($_.Exception.Message)"
    exit 1
} finally {
    # Disconnect from vCenter
    Write-Host "Disconnecting from vCenter..."
    Disconnect-VIServer -Server $VCenterServer -Confirm:$false
}

Write-Host "Template configuration completed successfully!"