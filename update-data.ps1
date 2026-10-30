# Crema Index data updater


# 1) data.js         : 2-year charts + latest Fear & Greed  -> used by index.html


# 2) history-data.js : max-range charts + Fear & Greed history -> used by history.html


# Fetches server-side (PowerShell) so the browser never hits CORS walls.


$ErrorActionPreference = 'Continue'


$root = Split-Path -Parent $MyInvocation.MyCommand.Path


$ua = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36"


[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12


$inv = [Globalization.CultureInfo]::InvariantCulture


$failed = @()


function Get-YahooChart([string]$symbol, [string]$range) {


    # range=max ignores interval=1d (returns monthly), so use explicit period1/period2 for full daily history


    $span = if ($range -eq "max") {


        "period1=0&period2=$([DateTimeOffset]::UtcNow.ToUnixTimeSeconds())"


    } else { "range=$range" }


    $url = "https://query1.finance.yahoo.com/v8/finance/chart/$([uri]::EscapeDataString($symbol))?$span&interval=1d&events=div%2Csplits&includeAdjustedClose=true"


    foreach ($hostName in @("query1", "query2")) {


        try {


            $resp = Invoke-WebRequest -Uri ($url -replace "query1", $hostName) -UserAgent $script:ua -UseBasicParsing -TimeoutSec 30 -ErrorAction Stop


            Write-Host "[OK]   $symbol ($range, $([math]::Round($resp.Content.Length/1KB)) KB)"


            return $resp.Content


        } catch {


            Write-Host "[WARN] $symbol ($range) via $hostName failed: $($_.Exception.Message)"


        }


    }


    $script:failed += "$symbol($range)"


    return "null"


}


$symbols = @("TQQQ", "QQQ", "VOO", "^VIX")


# --- 1) 2-year charts for index.html ---


$charts = @{}


foreach ($s in $symbols) { $charts[$s] = Get-YahooChart $s "2y" }


# --- 2) Max-range charts for history.html ---


$historyCharts = @{}


foreach ($s in $symbols) { $historyCharts[$s] = Get-YahooChart $s "max" }


# --- 3) Latest Fear & Greed (CNN first, fearandgreedgraph.com as fallback) ---


$fgJson = "null"


try {


    $h = @{


        "Accept"          = "application/json"


        "Referer"         = "https://edition.cnn.com/markets/fear-and-greed"


        "Origin"          = "https://edition.cnn.com"


        "Accept-Language" = "en-US,en;q=0.9"


    }


    $cnn = Invoke-RestMethod -Uri "https://production.dataviz.cnn.io/index/fearandgreed/graphdata" -Headers $h -UserAgent $ua -TimeoutSec 20 -ErrorAction Stop


    $score = [double]$cnn.fear_and_greed.score


    $date = ([datetime]$cnn.fear_and_greed.timestamp).ToString("yyyy-MM-dd")


    $fgJson = "{""value"":$($score.ToString($inv)),""date"":""$date""}"


    Write-Host "[OK]   Fear & Greed (CNN): $score ($date)"


} catch {


    Write-Host "[WARN] CNN Fear & Greed failed: $($_.Exception.Message)"


}


# --- 4) Fear & Greed history (fearandgreedgraph.com, from 2020-08) ---


$fgHistJson = "null"


try {


    $fgg = Invoke-RestMethod -Uri "https://fearandgreedgraph.com/api/fear-greed" -UserAgent $ua -TimeoutSec 30 -ErrorAction Stop


    $datesJson = '["' + ($fgg.dates -join '","') + '"]'


    $valsJson = '[' + (($fgg.values | ForEach-Object { ([double]$_).ToString($inv) }) -join ',') + ']'


    $fgHistJson = "{""dates"":$datesJson,""values"":$valsJson}"


    Write-Host "[OK]   Fear & Greed history: $($fgg.dates.Count) days ($($fgg.dates[0]) ~ $($fgg.dates[-1]))"


    if ($fgJson -eq "null") {


        # CNN failed -> use the last history point as the latest value too


        $fgJson = "{""value"":$(([double]$fgg.values[-1]).ToString($inv)),""date"":""$($fgg.dates[-1])""}"


        Write-Host "[OK]   Fear & Greed latest (fallback): $($fgg.values[-1]) ($($fgg.dates[-1]))"


    }


} catch {


    Write-Host "[FAIL] Fear & Greed history failed: $($_.Exception.Message)"


    if ($fgJson -eq "null") { $script:failed += "FearGreed" }


    $script:failed += "FearGreedHistory"


}


# --- 5) Write data.js / history-data.js ---


$updatedAt = (Get-Date).ToString("yyyy-MM-dd HH:mm")


$enc = New-Object Text.UTF8Encoding $false


$chartParts = foreach ($s in $symbols) { "    ""$s"": $($charts[$s])" }


$js = "window.CREMA_DATA = {`n" +


      "  ""updatedAt"": ""$updatedAt"",`n" +


      "  ""fearGreed"": $fgJson,`n" +


      "  ""charts"": {`n" + ($chartParts -join ",`n") + "`n  }`n};`n"


[IO.File]::WriteAllText((Join-Path $root "data.js"), $js, $enc)


Write-Host "data.js written ($([math]::Round($js.Length/1KB)) KB)"


$histParts = foreach ($s in $symbols) { "    ""$s"": $($historyCharts[$s])" }


$hjs = "window.CREMA_HISTORY = {`n" +


       "  ""updatedAt"": ""$updatedAt"",`n" +


       "  ""fearGreedHistory"": $fgHistJson,`n" +


       "  ""charts"": {`n" + ($histParts -join ",`n") + "`n  }`n};`n"


[IO.File]::WriteAllText((Join-Path $root "history-data.js"), $hjs, $enc)


Write-Host "history-data.js written ($([math]::Round($hjs.Length/1KB)) KB)"


if ($failed.Count -gt 0) {


    Write-Host "Some sources failed: $($failed -join ', ')" -ForegroundColor Yellow


    if (-not $env:CI) {


        # Interactive run (double-clicked bat): keep the window open so the user sees the warning


        Write-Host "Press any key to continue..."


        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")


    } else {


        exit 1


    }


}
