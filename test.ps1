
while ((Get-NetAdapter -Physical).status -eq "Up") {
    foreach ($adapter in Get-NetAdapter -Physical) {
        Write-Host $adapter.Name is up
    }
    Start-Sleep -seconds 5
}