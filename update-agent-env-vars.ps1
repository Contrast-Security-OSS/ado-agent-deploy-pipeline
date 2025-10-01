 param (
    [string]$ContrastAgentBaseDir
)

$envVars = @('CORECLR_PROFILER', 'CORECLR_PROFILER_PATH_32', 'CORECLR_PROFILER_PATH_64')

Invoke-Command -ScriptBlock {
    
    Write-Host "Verifying environment variables are removed:"
    foreach ($envVar in $envVars) {
        $value = [Environment]::GetEnvironmentVariable($envVar, [EnvironmentVariableTarget]::Machine)
        if ([string]::IsNullOrEmpty($value)) {
            Write-Host "✓ $envVar is not set" -ForegroundColor Green
        } else {
            Write-Host "✗ $envVar exists with value: $value" -ForegroundColor Red
        }
    }
}

# Add environment variables to the remote machine
Invoke-Command -ScriptBlock {
    # Set system environment variables 
    $n1 = $envVars.Get(0)
    [System.Environment]::SetEnvironmentVariable($n1, "{8B2CE134-0948-48CA-A4B2-80DDAD9F5791}", "Machine")
    $coreclr_profiler_value = [Environment]::GetEnvironmentVariable($n1, [EnvironmentVariableTarget]::Machine)
    Write-Host "✓ $n1 is now set: $coreclr_profiler_value" -ForegroundColor Green
    $n2 = $envVars.Get(1)
    [System.Environment]::SetEnvironmentVariable($n2, "$ContrastAgentBaseDir\Contrast.SensorsNetCore\contentFiles\any\netstandard2.0\contrast\runtimes\win-x86\native\ContrastProfiler.dll", "Machine")
    $coreclr_profiler_path_32_value = [Environment]::GetEnvironmentVariable($envVars.Get(1), [EnvironmentVariableTarget]::Machine)
    Write-Host "✓ $n2 is now set: $coreclr_profiler_path_32_value" -ForegroundColor Green
    $n3 = $envVars.Get(2)
    [System.Environment]::SetEnvironmentVariable($n3, "$ContrastAgentBaseDir\Contrast.SensorsNetCore\contentFiles\any\netstandard2.0\contrast\runtimes\win-x64\native\ContrastProfiler.dll", "Machine")
    $coreclr_profiler_path_64_value = [Environment]::GetEnvironmentVariable($n3, [EnvironmentVariableTarget]::Machine)
    Write-Host "✓ $n3 is now set: $coreclr_profiler_path_64_value" -ForegroundColor Green
    
    Write-Host "Environment variables added successfully"
} 
