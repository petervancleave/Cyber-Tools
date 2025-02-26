# website uptime checker
$websiteUrl = "https://www.example.com"

try {
    $response = Invoke-WebRequest -Uri $websiteUrl -Method Head -TimeoutSec 10
    if ($response.StatusCode -eq 200) {
        Write-Host "Website $websiteUrl is up."
    } else {
        Write-Host "Website $websiteUrl is down (HTTP Status Code: $($response.StatusCode))."
    }
} catch {
    Write-Host "Error: $_"
}
