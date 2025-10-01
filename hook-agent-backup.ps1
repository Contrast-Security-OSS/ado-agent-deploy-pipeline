# Connect to remote computer (replace 'ComputerName' with actual computer name/IP)
$ComputerName = "ComputerName"
$Session = New-PSSession -ComputerName $ComputerName

# Add environment variables to the remote machine
Invoke-Command -Session $Session -ScriptBlock {
    # Set system environment variables
    [System.Environment]::SetEnvironmentVariable("CORECLR_PROFILER", "{8B2CE134-0948-48CA-A4B2-80DDAD9F5791}", "Machine")
    [System.Environment]::SetEnvironmentVariable("CORECLR_PROFILER_PATH_32", "C:\ContrastSecurity\Contrast.SensorsNetCore\contentFiles\any\netstandard2.0\contrast\runtimes\win-x86\native\ContrastProfiler.dll", "Machine")
    [System.Environment]::SetEnvironmentVariable("CORECLR_PROFILER_PATH_64", "C:\ContrastSecurity\Contrast.SensorsNetCore\contentFiles\any\netstandard2.0\contrast\runtimes\win-x64\native\ContrastProfiler.dll", "Machine")
    
    Write-Host "Environment variables added successfully"
}

# Close the session before restart
Remove-PSSession $Session

# Restart the remote computer
Restart-Computer -ComputerName $ComputerName -Force -Wait

Write-Host "Computer is restarting... waiting 2 minutes"
Start-Sleep -Seconds 120

# Reconnect to the machine
do {
    try {
        $Session = New-PSSession -ComputerName $ComputerName -ErrorAction Stop
        Write-Host "Successfully reconnected to $ComputerName"
        break
    }
    catch {
        Write-Host "Waiting for $ComputerName to come back online..."
        Start-Sleep -Seconds 30
    }
} while ($true)

# Verify environment variables are set
Invoke-Command -Session $Session -ScriptBlock {
    Write-Host "Verifying environment variables:"
    Write-Host "CORECLR_PROFILER: $([System.Environment]::GetEnvironmentVariable('CORECLR_PROFILER', 'Machine'))"
    Write-Host "CORECLR_PROFILER_PATH_32: $([System.Environment]::GetEnvironmentVariable('CORECLR_PROFILER_PATH_32', 'Machine'))"
    Write-Host "CORECLR_PROFILER_PATH_64: $([System.Environment]::GetEnvironmentVariable('CORECLR_PROFILER_PATH_64', 'Machine'))"
}

# Clean up session
Remove-PSSession $Session