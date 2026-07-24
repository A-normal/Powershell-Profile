# 重新加载profile环境
function reload {
    . $PROFILE
    Write-Host ""
    Write-Host "✔ Profile Reloaded" -ForegroundColor Green
    Write-Host ""
}