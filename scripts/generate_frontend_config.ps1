$ErrorActionPreference = "Stop"

try {
  $apiUrl = terraform output -raw api_url
} catch {
  Write-Error "Failed to read Terraform output. Ensure you've run 'terraform apply' and that 'api_url' exists."
}

if (-not $apiUrl) {
  Write-Error "Terraform output 'api_url' is empty."
}

New-Item -ItemType Directory -Path frontend -Force | Out-Null
$content = "window.CONFIG = { API_URL: '" + $apiUrl + "' };"
Set-Content -Path frontend/config.js -Value $content -Encoding UTF8
Write-Host "Wrote frontend/config.js with API_URL = $apiUrl"

