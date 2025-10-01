param(
    [Parameter(Mandatory=$true)]
    [string]$ComputerName,
    
    [Parameter(Mandatory=$false)]
    [PSCredential]$Credential
)

# Function to test if computer is online
function Test-ComputerConnection {
    param([string]$Computer)
    Test-Connection -ComputerName $Computer -Count 1 -Quiet
}

# Function to wait for computer to come back online
function Wait-ForComputer {
    param([string]$Computer, [int]$TimeoutMinutes = 10)
    
    $timeout = (Get-Date).AddMinutes($TimeoutMinutes)
    Write-Host "Waiting for $Computer to come back online..." -ForegroundColor Yellow
    
    do {
        Start-Sleep -Seconds 10
        $online = Test-ComputerConnection -Computer $Computer
        if ($online) {
            Write-Host "$Computer is back online!" -ForegroundColor Green
            return $true
        }
        Write-Host "Still waiting for $Computer..." -ForegroundColor Yellow
    } while ((Get-Date) -lt $timeout)
    
    Write-Warning "Timeout waiting for $Computer to come back online"
    return $false
}

try {
    Write-Host "Connecting to $ComputerName..." -ForegroundColor Cyan
    
    # Test initial connection
    if (-not (Test-ComputerConnection -Computer $ComputerName)) {
        throw "Cannot reach $ComputerName"
    }
    
    # Create session parameters
    $sessionParams = @{
        ComputerName = $ComputerName
        ErrorAction = 'Stop'
    }
    
    if ($Credential) {
        $sessionParams.Credential = $Credential
    }
    
    # Create PowerShell session
    $session = New-PSSession @sessionParams
    Write-Host "Connected to $ComputerName" -ForegroundColor Green
    
    # Remove environment variables
    Write-Host "Removing environment variables..." -ForegroundColor Cyan
    Invoke-Command -Session $session -ScriptBlock {
        $envVars = @('CORECLR_PROFILER', 'CORECLR_PROFILER_PATH_32', 'CORECLR_PROFILER_PATH_64')
        
        foreach ($envVar in $envVars) {
            # Remove from current session
            Remove-Item -Path "Env:\$envVar" -ErrorAction SilentlyContinue
            
            # Remove from machine-level environment variables
            [Environment]::SetEnvironmentVariable($envVar, $null, [EnvironmentVariableTarget]::Machine)
            
            Write-Host "Removed environment variable: $envVar"
        }
    }
    
    Write-Host "Environment variables removed successfully" -ForegroundColor Green
    
    # Restart the computer
    Write-Host "Restarting $ComputerName..." -ForegroundColor Cyan
    Invoke-Command -Session $session -ScriptBlock {
        Restart-Computer -Force
    }
    
    # Close the session
    Remove-PSSession -Session $session
    
    # Wait for 2 minutes
    Write-Host "Waiting 2 minutes before attempting to reconnect..." -ForegroundColor Yellow
    Start-Sleep -Seconds 120
    
    # Wait for computer to come back online
    if (Wait-ForComputer -Computer $ComputerName -TimeoutMinutes 10) {
        # Reconnect to verify
        Write-Host "Attempting to reconnect to $ComputerName..." -ForegroundColor Cyan
        $newSession = New-PSSession @sessionParams
        
        if ($newSession) {
            Write-Host "Successfully reconnected to $ComputerName" -ForegroundColor Green
            
            # Verify environment variables are removed
            Invoke-Command -Session $newSession -ScriptBlock {
                $envVars = @('CORECLR_PROFILER', 'CORECLR_PROFILER_PATH_32', 'CORECLR_PROFILER_PATH_64')
                Write-Host "Verifying environment variables are removed:"
                foreach ($envVar in $envVars) {
                    $value = [Environment]::GetEnvironmentVariable($envVar, [EnvironmentVariableTarget]::Machine)
                    if ([string]::IsNullOrEmpty($value)) {
                        Write-Host "✓ $envVar is not set" -ForegroundColor Green
                    } else {
                        Write-Host "✗ $envVar still exists: $value" -ForegroundColor Red
                    }
                }
            }
            
            Remove-PSSession -Session $newSession
        }
    }
    
    Write-Host "Script completed successfully" -ForegroundColor Green
}
catch {
    Write-Error "Error occurred: $($_.Exception.Message)"
    if ($session) {
        Remove-PSSession -Session $session -ErrorAction SilentlyContinue
    }
    exit 1
}