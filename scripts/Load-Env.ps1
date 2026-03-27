<#
.SYNOPSIS
Load environment variables from .env file for VPN deployment.

.DESCRIPTION
Reads .env file, validates required values are set, and returns a hashtable
of configuration values for use in deployment scripts.

.PARAMETER EnvFilePath
Path to the .env file. Defaults to .env in the repo root.

.PARAMETER Cloud
Optional: Validate for specific cloud ('AzureCloud' or 'AzureUSGovernment')

.EXAMPLE
$config = & scripts/Load-Env.ps1
$config = & scripts/Load-Env.ps1 -EnvFilePath ".\custom.env" -Cloud "AzureCloud"

.NOTES
- .env file should contain KEY = "VALUE" format (with quotes)
- Comments starting with # are ignored
- Empty lines are ignored
- Returns $null if .env not found or validation fails
#>

param(
  [string]$EnvFilePath = ".env",
  [ValidateSet('AzureCloud', 'AzureUSGovernment')]
  [string]$Cloud
)

$ErrorActionPreference = 'Stop'

# ============================================================================
# Helper Functions
# ============================================================================

function Test-PathExists {
  param([string]$Path, [string]$Type = "File")
  
  if ($Type -eq "File" -and -not (Test-Path $Path -PathType Leaf)) {
    Write-Error ".env file not found at '$Path'. Copy .env.example to .env and fill in your values."
    return $false
  }
  return $true
}

function Parse-EnvFile {
  param([string]$FilePath)
  
  $config = @{}
  
  $lines = Get-Content $FilePath -Raw | Split-String -Delimiter "`n"
  
  foreach ($line in $lines) {
    # Trim whitespace
    $line = $line.Trim()
    
    # Skip empty lines and comments
    if (-not $line -or $line.StartsWith("#")) {
      continue
    }
    
    # Parse KEY = "VALUE" format
    if ($line -match '^([A-Z_]+)\s*=\s*"([^"]*)"$') {
      $key = $matches[1]
      $value = $matches[2]
      $config[$key] = $value
    }
  }
  
  return $config
}

function Test-RequiredValues {
  param([hashtable]$Config, [string]$Cloud)
  
  $required = @(
    'COMMERCIAL_SUBSCRIPTION_ID',
    'COMMERCIAL_TENANT_ID',
    'COMMERCIAL_RESOURCE_GROUP',
    'COMMERCIAL_ADDRESS_PREFIX',
    'COMMERCIAL_GATEWAY_SUBNET',
    'COMMERCIAL_WORKLOAD_SUBNET',
    'COMMERCIAL_REMOTE_GATEWAY_IP',
    'COMMERCIAL_REMOTE_ADDRESS_PREFIX',
    'GCC_SUBSCRIPTION_ID',
    'GCC_TENANT_ID',
    'GCC_RESOURCE_GROUP',
    'GCC_ADDRESS_PREFIX',
    'GCC_GATEWAY_SUBNET',
    'GCC_WORKLOAD_SUBNET',
    'GCC_REMOTE_GATEWAY_IP',
    'GCC_REMOTE_ADDRESS_PREFIX',
    'SHARED_KEY',
    'NAMING_PREFIX'
  )
  
  # Check for placeholder values
  $placeholder_pattern = "PASTE_YOUR|PASTE_[A-Z_]+_HERE"
  
  $missing = @()
  $invalid = @()
  
  foreach ($key in $required) {
    if (-not $Config.ContainsKey($key)) {
      $missing += $key
    } elseif ($Config[$key] -match $placeholder_pattern) {
      $invalid += "$key (still contains placeholder)"
    } elseif ([string]::IsNullOrWhiteSpace($Config[$key])) {
      $invalid += "$key (empty value)"
    }
  }
  
  if ($missing.Count -gt 0) {
    Write-Error "Missing required environment variables:`n$($missing -join "`n")"
    return $false
  }
  
  if ($invalid.Count -gt 0) {
    Write-Error "Invalid environment variable values (may contain placeholders or be empty):`n$($invalid -join "`n")"
    return $false
  }
  
  return $true
}

# ============================================================================
# Main
# ============================================================================

Write-Host "Loading environment configuration from '$EnvFilePath'..." -ForegroundColor Cyan

if (-not (Test-PathExists $EnvFilePath "File")) {
  return $null
}

$config = Parse-EnvFile $EnvFilePath

if ($config.Count -eq 0) {
  Write-Error "No configuration values found in .env file."
  return $null
}

Write-Host "Parsed $($config.Count) configuration values." -ForegroundColor Green

if (-not (Test-RequiredValues $config $Cloud)) {
  Write-Error "Validation failed. Please check your .env file."
  return $null
}

Write-Host "All required values validated successfully." -ForegroundColor Green

# Return config object
return $config
