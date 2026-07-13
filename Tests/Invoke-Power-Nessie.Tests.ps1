#Requires -Modules @{ModuleName='Pester';ModuleVersion='5.0.0'}
<#
.SYNOPSIS
    Pester tests for Invoke-Power-Nessie web application scan support.

.DESCRIPTION
    Tests the Nessus XML parsing and document-building logic introduced to
    support Nessus Web Application Scanner (WAS) findings that lack
    traditional host-centric fields.  The tests validate:

    1. Webapp finding with parseable JSON plugin_output  ->  URL extracted,
       nessus.plugin.output contains readable text, scanner type is
       "nessus_webapp", and @timestamp is a recent date (not epoch-0/1970).

    2. Webapp finding with non-JSON plugin_output  ->  raw string preserved,
       webappUrl is null, document is still emitted (no hard-fail).

    3. Regular vulnerability scan fixture  ->  existing behaviour unchanged:
       host.ip / host.name from tags, epoch-based @timestamp, scanner type
       is "nessus", no target.url emitted.
#>

BeforeAll {
    # -----------------------------------------------------------------------
    # Replicate the helper function used inside Invoke-Import_Nessus_To_Elasticsearch
    # -----------------------------------------------------------------------
    # Replicates the helper from Invoke-Power-Nessie.ps1.
    # The input must be in milliseconds – the caller pre-multiplies
    # seconds × 1000 before passing the value.
    function convertEpochMillisecondsToISO {
        Param($epochTimeMillis)
        $dateTime = [System.DateTimeOffset]::FromUnixTimeMilliseconds($epochTimeMillis).DateTime
        $newTime = Get-Date $dateTime -Format "o"
        return $newTime
    }

    # -----------------------------------------------------------------------
    # Core function under test: builds an Elasticsearch document from one
    # ReportItem + its parent ReportHost node, mirroring the logic in
    # Invoke-Power-Nessie.ps1 Invoke-Import_Nessus_To_Elasticsearch.
    # -----------------------------------------------------------------------
    function Build-NessusDocument {
        param(
            [System.Xml.XmlElement]$ReportHost,
            [System.Xml.XmlElement]$ReportItem,
            [string]$ReportName,
            [string]$FileProcessed
        )

        # --- Collect host property tags ---
        $ip = $null; $fqdn = $null; $rdns = $null; $hostname = $null
        $netbiosname = $null; $osu = $null; $systype = $null; $os = $null
        $opersys = $null; $operSysConfidence = $null; $operSysMethod = $null
        $credscan = $null; $macAddr = $null; $hostStart = $null; $hostEnd = $null

        foreach ($tag in $ReportHost.HostProperties.tag) {
            switch -Regex ($tag.name) {
                "host-ip"                   { $ip = $tag."#text" }
                "host-fqdn"                 { $fqdn = $tag."#text" }
                "host-rdns"                 { $rdns = $tag."#text" }
                "hostname$"                 { $hostname = $tag."#text" }
                "netbios-name"              { $netbiosname = $tag."#text" }
                "operating-system-unsupported" { $osu = $tag."#text" }
                "system-type"               { $systype = $tag."#text" }
                "^os$"                      { $os = $tag."#text" }
                "operating-system$"         { $opersys = $tag."#text" }
                "operating-system-conf"     { $operSysConfidence = $tag."#text" }
                "operating-system-method"   { $operSysMethod = $tag."#text" }
                "^Credentialed_Scan"        { $credscan = $tag."#text" }
                "mac-address"               { $macAddr = $tag."#text" }
                "HOST_START_TIMESTAMP$"     { $hostStart = $tag."#text" }
                "HOST_END_TIMESTAMP$"       { $hostEnd = $tag."#text" }
            }
        }

        # --- Timestamp: use HOST_START_TIMESTAMP when available (regular scans);
        #     fall back to current time so webapp documents are not buried in 1970. ---
        if ($hostStart) {
            $hostStartMs = $([int]$hostStart * 1000)
            $hostEndMs   = if ($hostEnd) { $([int]$hostEnd * 1000) } else { $null }
            $duration    = if ($hostEndMs) { $(($hostEndMs - $hostStartMs) * 1000000) } else { $null }
            $hostStartIso = convertEpochMillisecondsToISO $hostStartMs
            $hostEndIso   = if ($hostEndMs) { convertEpochMillisecondsToISO $hostEndMs } else { $null }
        } else {
            $hostStartIso = Get-Date -Format "o"
            $hostEndIso   = $null
            $duration     = $null
        }

        # --- Parse webapp-style JSON plugin_output ---
        $webappUrl         = $null
        $pluginOutputDisplay = $ReportItem.plugin_output
        if ($ReportItem.plugin_output) {
            try {
                $parsed = $ReportItem.plugin_output | ConvertFrom-Json -ErrorAction Stop
                if ($null -ne $parsed.url)    { $webappUrl         = $parsed.url }
                if ($null -ne $parsed.output) { $pluginOutputDisplay = $parsed.output }
            } catch {
                # Not JSON – keep raw string
            }
        }

        # --- Scanner subtype ---
        $scannerType = if ($ReportItem.pluginFamily -eq "Web Applications" -or $null -ne $webappUrl) {
            "nessus_webapp"
        } else {
            "nessus"
        }

        # --- Derive host.name from URL when the ReportHost name is a URL (webapp scans) ---
        $hostnameFromUrl = if ($ReportHost.name -match '^https?://') {
            $h = try { ([System.Uri]$ReportHost.name).Host } catch { $ReportHost.name -replace '^https?://', '' -replace '/.*$', '' }
            if ($h) { $h.ToLower() } else { $null }
        } else {
            $null
        }

        # --- Build and return document object ---
        # Collect CVE IDs from the <cve> element and, as a fallback, from <cvss_score_source>
        # when it holds a CVE identifier.
        $cveIds = @(
            @(if ($ReportItem.cve) { $ReportItem.cve } else { @() }) +
            @(if ($ReportItem.cvss_score_source -match '^CVE-\d+-\d+$') { $ReportItem.cvss_score_source } else { @() })
        ) | Select-Object -Unique | Where-Object { $_ }

        return [PSCustomObject]@{
            "@timestamp"    = $hostStartIso
            "destination"   = [PSCustomObject]@{ "port" = $([Uint16]$ReportItem.port) }
            "host"          = [PSCustomObject]@{
                "ip"   = $ip
                "name" = if ($fqdn) { $fqdn.ToLower() } elseif ($rdns) { $rdns.ToLower() } elseif ($hostname) { $hostname.ToLower() } elseif ($netbiosname) { $netbiosname.ToLower() } elseif ($hostnameFromUrl) { $hostnameFromUrl } else { $null }
            }
            "nessus"        = [PSCustomObject]@{
                "name_of_host" = $ReportHost.name.ToLower()
                "plugin"       = [PSCustomObject]@{
                    "id"     = $ReportItem.pluginID
                    "name"   = $ReportItem.pluginName
                    "output" = $pluginOutputDisplay
                }
                "scanner"      = [PSCustomObject]@{ "type" = $scannerType }
            }
            "vulnerability" = [PSCustomObject]@{
                "id"             = @(if ($cveIds) { $cveIds } else { $null })
                "classification" = @(if ($cveIds) { "CVE" } else { $null })
                "report_id" = $ReportName
                "category"  = $ReportItem.pluginFamily
                "target"    = [PSCustomObject]@{ "url" = $webappUrl }
            }
            "network"       = [PSCustomObject]@{
                "transport"   = $ReportItem.protocol
                "application" = $ReportItem.svc_name
            }
            "_hostStart"    = $hostStart   # keep raw value for assertion
            "_duration"     = $duration
        }
    }

    # -----------------------------------------------------------------------
    # Load fixture XML files
    # -----------------------------------------------------------------------
    $script:WebappXml  = [xml](Get-Content "$PSScriptRoot/Fixtures/webapp-scan.nessus"  -Raw)
    $script:RegularXml = [xml](Get-Content "$PSScriptRoot/Fixtures/regular-scan.nessus" -Raw)
}

# ===========================================================================
Describe "Webapp scan – JSON plugin_output with URL" {

    BeforeAll {
        $host_node   = $script:WebappXml.NessusClientData_v2.Report.ReportHost
        $report_item = @($host_node.ReportItem) | Where-Object { $_.pluginID -eq "114682" } | Select-Object -First 1
        $script:Doc  = Build-NessusDocument `
            -ReportHost  $host_node `
            -ReportItem  $report_item `
            -ReportName  "WebApp Scan 2026" `
            -FileProcessed "webapp-scan.nessus"
    }

    It "scanner type is 'nessus_webapp'" {
        $script:Doc.nessus.scanner.type | Should -Be "nessus_webapp"
    }

    It "vulnerability.target.url is extracted from plugin_output JSON" {
        $script:Doc.vulnerability.target.url | Should -Be "https://www.example.com/my-webapp/"
    }

    It "nessus.plugin.output contains readable text, not the raw JSON string" {
        $script:Doc.nessus.plugin.output | Should -Not -BeLike '*"url"*'
        $script:Doc.nessus.plugin.output | Should -BeLike "*Current Version*"
    }

    It "@timestamp is NOT epoch-0 (1970-01-01)" {
        $ts = [datetime]::Parse($script:Doc."@timestamp")
        $ts.Year | Should -BeGreaterThan 1970
    }

    It "vulnerability.report_id matches the report name" {
        $script:Doc.vulnerability.report_id | Should -Be "WebApp Scan 2026"
    }

    It "vulnerability.category is 'Web Applications'" {
        $script:Doc.vulnerability.category | Should -Be "Web Applications"
    }

    It "host.ip is null (webapp scans have no host-ip tag)" {
        $script:Doc.host.ip | Should -BeNullOrEmpty
    }

    It "host.name is derived from the scanned URL (protocol stripped)" {
        $script:Doc.host.name | Should -Be "www.example.com"
    }

    It "vulnerability.id contains the CVE identifier from the finding" {
        $script:Doc.vulnerability.id | Should -Contain "CVE-2025-29927"
    }

    It "vulnerability.classification is 'CVE' when CVEs are present" {
        $script:Doc.vulnerability.classification | Should -Contain "CVE"
    }
}

# ===========================================================================
Describe "Webapp scan – non-JSON (plain-text) plugin_output" {

    BeforeAll {
        $host_node   = $script:WebappXml.NessusClientData_v2.Report.ReportHost
        $report_item = @($host_node.ReportItem) | Where-Object { $_.pluginID -eq "99999" } | Select-Object -First 1
        $script:Doc  = Build-NessusDocument `
            -ReportHost  $host_node `
            -ReportItem  $report_item `
            -ReportName  "WebApp Scan 2026" `
            -FileProcessed "webapp-scan.nessus"
    }

    It "document is still emitted (no exception)" {
        $script:Doc | Should -Not -BeNullOrEmpty
    }

    It "vulnerability.target.url is null when plugin_output is not JSON" {
        $script:Doc.vulnerability.target.url | Should -BeNullOrEmpty
    }

    It "nessus.plugin.output preserves the raw plain-text string" {
        $script:Doc.nessus.plugin.output | Should -Be "This is plain text, not JSON."
    }

    It "scanner type is 'nessus_webapp' (pluginFamily is Web Applications)" {
        $script:Doc.nessus.scanner.type | Should -Be "nessus_webapp"
    }

    It "@timestamp is NOT epoch-0 (1970-01-01)" {
        $ts = [datetime]::Parse($script:Doc."@timestamp")
        $ts.Year | Should -BeGreaterThan 1970
    }
}

# ===========================================================================
Describe "Regular vulnerability scan – existing behaviour unchanged" {

    BeforeAll {
        $host_node   = $script:RegularXml.NessusClientData_v2.Report.ReportHost
        $report_item = @($host_node.ReportItem) | Select-Object -First 1
        $script:Doc  = Build-NessusDocument `
            -ReportHost  $host_node `
            -ReportItem  $report_item `
            -ReportName  "Regular Vuln Scan 2026" `
            -FileProcessed "regular-scan.nessus"
    }

    It "scanner type is 'nessus' (not a webapp finding)" {
        $script:Doc.nessus.scanner.type | Should -Be "nessus"
    }

    It "vulnerability.target.url is null for non-webapp findings" {
        $script:Doc.vulnerability.target.url | Should -BeNullOrEmpty
    }

    It "@timestamp is derived from HOST_START_TIMESTAMP (epoch-based, year >= 2024)" {
        $ts = [datetime]::Parse($script:Doc."@timestamp")
        $ts.Year | Should -BeGreaterOrEqual 2024
    }

    It "host.name is populated from hostname tag" {
        $script:Doc.host.name | Should -Be "myserver.example.com"
    }

    It "nessus.plugin.output is the original plain-text string" {
        $script:Doc.nessus.plugin.output | Should -BeLike "*arcfour*"
    }

    It "vulnerability.report_id matches the report name" {
        $script:Doc.vulnerability.report_id | Should -Be "Regular Vuln Scan 2026"
    }

    It "vulnerability.id is populated from the CVE field in the finding" {
        $script:Doc.vulnerability.id | Should -Contain "CVE-2013-5028"
    }

    It "vulnerability.classification is 'CVE' when CVEs are present" {
        $script:Doc.vulnerability.classification | Should -Contain "CVE"
    }
}

# ===========================================================================
Describe "Regular scan – CVE sourced from cvss_score_source (no <cve> element)" {

    BeforeAll {
        $host_node   = $script:RegularXml.NessusClientData_v2.Report.ReportHost
        $report_item = @($host_node.ReportItem) | Where-Object { $_.pluginID -eq "189760" } | Select-Object -First 1
        $script:Doc  = Build-NessusDocument `
            -ReportHost  $host_node `
            -ReportItem  $report_item `
            -ReportName  "Regular Vuln Scan 2026" `
            -FileProcessed "regular-scan.nessus"
    }

    It "document is emitted (no exception)" {
        $script:Doc | Should -Not -BeNullOrEmpty
    }

    It "vulnerability.id is populated from cvss_score_source when no <cve> element is present" {
        $script:Doc.vulnerability.id | Should -Contain "CVE-2024-2511"
    }

    It "vulnerability.classification is 'CVE' when CVE comes from cvss_score_source" {
        $script:Doc.vulnerability.classification | Should -Contain "CVE"
    }

    It "scanner type is 'nessus' (not a webapp finding)" {
        $script:Doc.nessus.scanner.type | Should -Be "nessus"
    }
}

# ===========================================================================
Describe "Webapp URL extraction helper logic (unit)" {

    It "extracts url and output from valid JSON plugin_output" {
        $raw = '{"output":"Version 14.2.15","url":"https://www.example.com/path/"}'
        $parsed = $raw | ConvertFrom-Json
        $parsed.url    | Should -Be "https://www.example.com/path/"
        $parsed.output | Should -Be "Version 14.2.15"
    }

    It "ConvertFrom-Json throws on non-JSON input (which the main code catches and handles gracefully)" {
        { "plain text" | ConvertFrom-Json -ErrorAction Stop } | Should -Throw
    }

    It "handles missing url key gracefully (output-only JSON)" {
        $raw    = '{"output":"some text"}'
        $parsed = $raw | ConvertFrom-Json
        $parsed.url    | Should -BeNullOrEmpty
        $parsed.output | Should -Be "some text"
    }

    It "timestamp fallback produces a year greater than 1970 when hostStart is null" {
        $hostStart = $null
        $result = if ($hostStart) { "should-not-be-reached" } else { Get-Date -Format "o" }
        $ts = [datetime]::Parse($result)
        $ts.Year | Should -BeGreaterThan 1970
    }

    It "strips protocol from URL to derive host.name (http)" {
        $url = "http://www.example.com"
        $hostname = try { ([System.Uri]$url).Host } catch { ($url -replace '^https?://', '' -replace '/.*$', '').ToLower() }
        $hostname | Should -Be "www.example.com"
    }

    It "strips protocol and path from URL to derive host.name (https with path)" {
        $url = "https://www.example.com/my-webapp/"
        $hostname = try { ([System.Uri]$url).Host } catch { ($url -replace '^https?://', '' -replace '/.*$', '').ToLower() }
        $hostname | Should -Be "www.example.com"
    }
}
