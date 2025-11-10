<#
.Synopsis
    This script is a combination of extracting, importing, and automating Nessus scan data into the Elastic stack.
    
    *Invoke-Exract_From_Nessus*
    Downloads scans from the My Scans folder (or custom folder) and move them to a different folder of your choosing for archival purposes.

    *Invoke-Import_Nessus_To_Elasticsearch*
    Parses a single Nessus XML report and imports it into Elasticsearch using the _bulk API.

    *Invoke-Automate_Nessus_File_Imports*
    Automatically checks for any unprocessed .nessus files and ingest them into Elastic.

    *Setup-Elastic-Stack*
    Use this script to configure an Elastic stack to properly ingest and visualize the Nessus scan data before ingestion.

.DESCRIPTION
    This script is useful for automating the downloads of Nessus scan files and importing them into the Elastic stack. The script will be able to allow for some customizations
    such as the Nessus scanner host, the location of the downloads, and the Nessus scan folder for which you wish to move the scans
    after they have been downloaded (if you so choose). This tool was inspired from the Posh-Nessus script. Due to lack of updates on the Posh-Nessus
    project, it seemed easier to call the raw API to perform the bare minimum functions necessary to export
    scans out automatically. I appreciate Tenable leaving these core API functions (export scan and scan status) in their product.

    Variable Options
    -Nessus_URL "https://127.0.0.1:8834"
    -Nessus_File_Download_Location "C:\Nessus"
    -Nessus_XML_File ""
    -Nessus_Access_Key "redacted"
    -Nessus_Secret_Key "redacted"
    -Nessus_Source_Folder_Name "My Scans"
    -Nessus_Archive_Folder_Name "Archive-Ingested"
    -Nessus_Scan_Name_To_Delete_Oldest_Scan ""
    -Nessus_Export_Scans_From_Today "false"
    -Nessus_Export_Day "01/11/2021"
    -Nessus_Export_Custom_Extended_File_Name_Attribute "_scanner1"
    -Nessus_Export_All_Scan_History "false"
    -Elasticsearch_URL "http://127.0.0.1:9200"
    -Elasticsearch_Index_Name "logs-nessus.vulnerability"
    -Elasticsearch_Api_Key "redacted"
    -Elasticsearch_Custom_Authentication_Header "ApiKey"
    -Nessus_Base_Comparison_Scan_Date @("3/5/2024","3/6/2024")
    -Look_Back_Time_In_Days 7,
    -Look_Back_Iterations 3,
    -Connection_Timeout 0,
    -Operation_Timeout 0,
    -Elasticsearch_Scan_Filter @("scan_1","scan2"),
    -Elasticsearch_Scan_Filter_Type "include",
    -Remote_Elasticsearch_URL "http://127.0.0.1:9200"
    -Remote_Elasticsearch_Index_Name = "logs-nessus.vulnerability-summary",
    -Remote_Elasticsearch_Api_Key "redacted"
    -Remote_Elasticsearch_Custom_Authentication_Header "ApiKey"
    -Execute_Patch_Summarization "true"
    -Kibana_URL "http://127.0.0.1:5601"
    -Kibana_Export_PDF_URL ""
    -Kibana_Export_CSV_URL ""
    -Kibana_Custom_Authentication_Header "ApiKey"
    -Email_From ""
    -Email_To ""
    -SMTP_Server ""
    -Email_CC ""
    -Configuration_File_Path ""


.EXAMPLE
   .\Invoke-Power-Nessie.ps1 -Nessus_URL "https://127.0.0.1:8834" -Nessus_File_Download_Location "C:\Nessus" -Nessus_Access_Key "redacted" -Nessus_Secret_Key "redacted" -Nessus_Source_Folder_Name "My Scans" -Nessus_Archive_Folder_Name "Archive-Ingested" -Nessus_Export_Scans_From_Today "false" -Nessus_Export_Day "01/11/2021" -Nessus_Export_Custom_Extended_File_Name_Attribute "_scanner1" -Elasticsearch_URL "http://127.0.0.1:9200" -Elasticsearch_Index_Name "logs-nessus.vulnerability" -Elasticsearch_Api_Key "redacted"
#>

Param (
    # Nessus URL. (default - https://127.0.0.1:8834)
    [Parameter(Mandatory=$false)]
    $Nessus_URL = "https://127.0.0.1:8834",
    # The location where you wish to save the extracted Nessus files from the scanner (default - Nessus_Exports)
    [Parameter(Mandatory=$false)]
    $Nessus_File_Download_Location = "Nessus_Exports",
    # The location of a specifc Nessus file for processing.
    [Parameter(Mandatory=$false)]
    $Nessus_XML_File,
    # Nessus Access Key
    [Parameter(Mandatory=$false)]
    $Nessus_Access_Key = $null,
    # Nessus Secret Key
    [Parameter(Mandatory=$false)]
    $Nessus_Secret_Key = $null,
    # The source folder for where the Nessus scans live in the UI. (default - "My Scans")
    [Parameter(Mandatory=$false)]
    $Nessus_Source_Folder_Name = "My Scans",
    # The destination folder in Nessus UI for where you wish to move your scans for archive. (default - none - scans won't move)
    [Parameter(Mandatory=$false)]
    $Nessus_Archive_Folder_Name = $null,
    # The scan name you want to delete the older scan from (default - none - scans won't get deleted)
    [Parameter(Mandatory=$false)]
    $Nessus_Scan_Name_To_Delete_Oldest_Scan = $null,
    # Use this setting if you wish to only export the scans on the day the scan occurred. (default - false)
    [Parameter(Mandatory=$false)]
    $Nessus_Export_Scans_From_Today = $null,
    # Use this setting if you want to export scans for the specific day that the scan or scans occurred. (example - 11/07/2023)
    [Parameter(Mandatory=$false)]
    $Nessus_Export_Day = $null,
    # Added atrribute for the end of the file name for uniqueness when using with multiple scanners. (example - _scanner1)
    [Parameter(Mandatory=$false)]
    $Nessus_Export_Custom_Extended_File_Name_Attribute = $null,
    # Use this setting to configure the behaviour for exporting more than just the latest scan. Options are:
    # Not configured or false, then the latest scan is exported.
    # "true" : exports all scan history.
    [Parameter(Mandatory=$false)]
    $Nessus_Export_All_Scan_History = $null,
    # Add Elasticsearch URL to automate Nessus import (default - https://127.0.0.1:9200)
    [Parameter(Mandatory=$false)]
    $Elasticsearch_URL = "https://127.0.0.1:9200",
    # Add Elasticsearch index name to automate Nessus import (default - logs-nessus.vulnerability)
    [Parameter(Mandatory=$false)]
    $Elasticsearch_Index_Name = "logs-nessus.vulnerability",
    # Add Elasticsearch API key to automate Nessus import
    [Parameter(Mandatory=$false)]
    $Elasticsearch_Api_Key = $null,
    # Optionally customize the Elasticsearch Authorization ApiKey text to support third party security such as SearchGuard (Bearer). (default ApiKey) 
    [Parameter(Mandatory=$false)]
    $Elasticsearch_Custom_Authentication_Header = "ApiKey",
    # Optionally set batch size for bulk imports (default 5000)
    [Parameter(Mandatory=$false)]
    $Elasticsearch_Bulk_Import_Batch_Size = 5000,
    # Add Kibana URL for setup. (default - https://127.0.0.1:5601)
    [Parameter(Mandatory=$false)]
    $Kibana_URL = "https://127.0.0.1:5601",
    # Add POST URL to call generation of PDF from outside Kibana (Share->PDF Reports->Advanced options->Copy POST Url)
    [Parameter(Mandatory=$false)]
    $Kibana_Export_PDF_URL = $null,
    # Add POST URL to call generation of CSV from outside Kibana (Share->CSV Reports->Advanced options->Copy POST Url)
    [Parameter(Mandatory=$false)]
    $Kibana_Export_CSV_URL = $null,
    # Optionally customize the Kibana Authorization ApiKey text to support third party security such as SearchGuard (Bearer). (default ApiKey) 
    [Parameter(Mandatory=$false)]
    $Kibana_Custom_Authentication_Header = "ApiKey",
    # Sender email address (<SOC> soc@tkretts.special.org)
    [Parameter(Mandatory=$false)]
    $Email_From = $null,
    # Recipient email addresses (can be comma seperated for multiple values using @("email1@org1.com`","email2@org2.it"))
    [Parameter(Mandatory=$false)]
    $Email_To = $null,
    # Recipient Carbon Copy (CC) email addresses (can be comma seperated for multiple values using @("email1@org1.com`","email2@org2.it"))
    [Parameter(Mandatory=$false)]
    $Email_CC = $null,
    # SMTP server used for sending email using Powershell
    [Parameter(Mandatory=$false)]
    $Email_SMTP_Server = $null,
    # Email Subject Line (default - "Vulnerability Report for $date")
    [Parameter(Mandatory=$false)]
    $Email_Subject = "Vulnerability Report for $(Get-Date -Format "M/d/yyyy")",
    # Email Body Text (default - "Attached is the vulnerability report for $date.")
    [Parameter(Mandatory=$false)]
    $Email_Body = "Attached is the vulnerability report for $(Get-Date -Format "M/d/yyyy").",
    # Selected option for automation
    [Parameter(Mandatory=$false)]
    $Option_Selected,
    ##### New For Patch Summarization Feature #####
    # Set custom scan dates for which scans you want to compare to for it's historical reference.
    # For example, setting $Nessus_Base_Comparison_Scan_Date to 3/15/2024 will use data from 3/15/2024 and then use the configured look back time in days to compare to (7 days would be 3/8/2024).
    [Parameter(Mandatory=$false)]
    $Nessus_Base_Comparison_Scan_Date,
    # Look back time for checks in days. This is how far back to compare the scan data. Typically this should be set at the frequency of scanning. Examples: Scanning weekly = 7, daily = 1 (default 7)
    [Parameter(Mandatory=$false)]
    $Look_Back_Time_In_Days = 7,
    # Iterations to look back for hosts not found in first lookback.  (default 3)
    [Parameter(Mandatory=$false)]
    $Look_Back_Iterations = 3,
    # How long to wait for a connection to start in seconds (default 0)
    [Parameter(Mandatory=$false)]
    $Connection_Timeout = 0,
    # How long to wait for connection data in seconds (default 0)
    [Parameter(Mandatory=$false)]
    $Operation_Timeout = 0,
    # Custom scan names to include or exclude based on vulnerability.report_id (example - @("scan1","scan2"))
    [Parameter(Mandatory=$false)]
    $Elasticsearch_Scan_Filter = $null,
    # Custom scan name filter to be include or exclude (default - include)
    [Parameter(Mandatory=$false)]
    $Elasticsearch_Scan_Filter_Type = "include",
    # Remote index capability - Use these options if you want to index into a different cluster your queried your scan data from. This method is typically used for testing.
    # If you don't supply these variables then the source index name, url, etc. are used.
    # Add Remote Elasticsearch URL to automate Nessus import (default - https://127.0.0.1:9200)
    [Parameter(Mandatory=$false)]
    $Remote_Elasticsearch_URL = $null,
    # Add Remote Elasticsearch Index Name. Adds -summary as a different data stream not to confuse with vulnerability scan data. Also great for index lifecycle management.
    [Parameter(Mandatory=$false)]
    $Remote_Elasticsearch_Index_Name = $null,
    # Add Remote Elasticsearch API key to ingest summary results into.
    [Parameter(Mandatory=$false)]
    $Remote_Elasticsearch_Api_Key = $null,
    # Optionally customize the Remote Elasticsearch Authorization ApiKey text to support third party security such as SearchGuard (Bearer). (default ApiKey) 
    [Parameter(Mandatory=$false)]
    $Remote_Elasticsearch_Custom_Authentication_Header = "ApiKey",
    # Optionally execute Patch summarization upon completion of automated export and ingest. (default false)
    [Parameter(Mandatory=$false)]
    $Execute_Patch_Summarization = "false",
    # Optionally use a JSON configuration file (example - configuration.json)
    [Parameter(Mandatory=$false)]
    $Configuration_File_Path = $null,
    # Optionally remove *.processed scans by number of days by file write time. Set at 0 will remove all *.processed scans. Set at 1 will remove all but the last day of scans.
    [Parameter(Mandatory=$false)]
    $Remove_Processed_Scans_By_Days = $null
)

Begin{
    if ($PSVersionTable.PSVersion.Major -ge 7) {
        Write-Host "PowerShell version $($PSVersionTable.PSVersion.Major) detected, great!"
    } else {
        Write-Host "Old version of PowerShell detected $($PSVersionTable.PSVersion.Major). Please install PowerShell 7+. Exiting." -ForegroundColor Red
        Write-Host "No scans found." -ForegroundColor Red
        exit
    }
    # Check for configuration.json file to load configuration settings and populate them all. This will override any arguments passed in for the command line.
    if($Configuration_File_Path){
        try{
            $configurationSettings = Get-Content $Configuration_File_Path | ConvertFrom-Json
            $configurationSettingsCount = $($configurationSettings.PSObject.Properties | Where-Object {$_.MemberType -eq "NoteProperty" -and $_.Value -ne $null}).count
            if($configurationSettingsCount -gt 0){
                Write-Host "Configuration settings ($configurationSettingsCount) found in $(Get-Item $Configuration_File_Path) file." -ForegroundColor Green
            }
    
            # Store all variables from the configuration file inside of variables to be used later in the script and make sure not to null out the current variables.
            if($null -ne $configurationSettings.Nessus_URL){$Nessus_URL = $configurationSettings.Nessus_URL}
            if($null -ne $configurationSettings.Nessus_File_Download_Location){$Nessus_File_Download_Location = $configurationSettings.Nessus_File_Download_Location}
            if($null -ne $configurationSettings.Nessus_XML_File){$Nessus_XML_File = $configurationSettings.Nessus_XML_File}
            if($null -ne $configurationSettings.Nessus_Access_Key){$Nessus_Access_Key = $configurationSettings.Nessus_Access_Key}
            if($null -ne $configurationSettings.Nessus_Secret_Key){$Nessus_Secret_Key = $configurationSettings.Nessus_Secret_Key}
            if($null -ne $configurationSettings.Nessus_Source_Folder_Name){$Nessus_Source_Folder_Name = $configurationSettings.Nessus_Source_Folder_Name}
            if($null -ne $configurationSettings.Nessus_Archive_Folder_Name){$Nessus_Archive_Folder_Name = $configurationSettings.Nessus_Archive_Folder_Name}
            if($null -ne $configurationSettings.Nessus_Scan_Name_To_Delete_Oldest_Scan){$Nessus_Scan_Name_To_Delete_Oldest_Scan = $configurationSettings.Nessus_Scan_Name_To_Delete_Oldest_Scan}
            if($null -ne $configurationSettings.Nessus_Export_Scans_From_Today){$Nessus_Export_Scans_From_Today = $configurationSettings.Nessus_Export_Scans_From_Today}
            if($null -ne $configurationSettings.Nessus_Export_Day){$Nessus_Export_Day = $configurationSettings.Nessus_Export_Day}
            if($null -ne $configurationSettings.Nessus_Export_Custom_Extended_File_Name_Attribute){$Nessus_Export_Custom_Extended_File_Name_Attribute = $configurationSettings.Nessus_Export_Custom_Extended_File_Name_Attribute}
            if($null -ne $configurationSettings.Nessus_Export_All_Scan_History){$Nessus_Export_All_Scan_History = $configurationSettings.Nessus_Export_All_Scan_History}
            if($null -ne $configurationSettings.Elasticsearch_URL){$Elasticsearch_URL = $configurationSettings.Elasticsearch_URL}
            if($null -ne $configurationSettings.Elasticsearch_Index_Name){$Elasticsearch_Index_Name = $configurationSettings.Elasticsearch_Index_Name}
            if($null -ne $configurationSettings.Elasticsearch_Api_Key){$Elasticsearch_Api_Key = $configurationSettings.Elasticsearch_Api_Key}
            if($null -ne $configurationSettings.Elasticsearch_Custom_Authentication_Header){$Elasticsearch_Custom_Authentication_Header = $configurationSettings.Elasticsearch_Custom_Authentication_Header}
            if($null -ne $configurationSettings.Elasticsearch_Bulk_Import_Batch_Size){$Elasticsearch_Bulk_Import_Batch_Size = $configurationSettings.Elasticsearch_Bulk_Import_Batch_Size}
            if($null -ne $configurationSettings.Kibana_URL){$Kibana_URL = $configurationSettings.Kibana_URL}
            if($null -ne $configurationSettings.Kibana_Export_PDF_URL){$Kibana_Export_PDF_URL = $configurationSettings.Kibana_Export_PDF_URL}
            if($null -ne $configurationSettings.Kibana_Export_CSV_URL){$Kibana_Export_CSV_URL = $configurationSettings.Kibana_Export_CSV_URL}
            if($null -ne $configurationSettings.Kibana_Custom_Authentication_Header){$Kibana_Custom_Authentication_Header = $configurationSettings.Kibana_Custom_Authentication_Header}
            if($null -ne $configurationSettings.Email_From){$Email_From = $configurationSettings.Email_From}
            if($null -ne $configurationSettings.Email_To){$Email_To = $configurationSettings.Email_To}
            if($null -ne $configurationSettings.Email_CC){$Email_CC = $configurationSettings.Email_CC}
            if($null -ne $configurationSettings.Email_SMTP_Server){$Email_SMTP_Server = $configurationSettings.Email_SMTP_Server}
            if($null -ne $configurationSettings.Option_Selected){$Option_Selected = $configurationSettings.Option_Selected}
            if($null -ne $configurationSettings.Nessus_Base_Comparison_Scan_Date){$Nessus_Base_Comparison_Scan_Date = $configurationSettings.Nessus_Base_Comparison_Scan_Date}
            if($null -ne $configurationSettings.Look_Back_Time_In_Days){$Look_Back_Time_In_Days = $configurationSettings.Look_Back_Time_In_Days}
            if($null -ne $configurationSettings.Look_Back_Iterations){$Look_Back_Iterations = $configurationSettings.Look_Back_Iterations}
            if($null -ne $configurationSettings.Connection_Timeout){$Connection_Timeout = $configurationSettings.Connection_Timeout}
            if($null -ne $configurationSettings.Operation_Timeout){$Operation_Timeout = $configurationSettings.Operation_Timeout}
            if($null -ne $configurationSettings.Elasticsearch_Scan_Filter){$Elasticsearch_Scan_Filter = $configurationSettings.Elasticsearch_Scan_Filter}
            if($null -ne $configurationSettings.Elasticsearch_Scan_Filter_Type){$Elasticsearch_Scan_Filter_Type = $configurationSettings.Elasticsearch_Scan_Filter_Type}
            if($null -ne $configurationSettings.Remote_Elasticsearch_URL){$Remote_Elasticsearch_URL = $configurationSettings.Remote_Elasticsearch_URL}
            if($null -ne $configurationSettings.Remote_Elasticsearch_Index_Name){$Remote_Elasticsearch_Index_Name = $configurationSettings.Remote_Elasticsearch_Index_Name}
            if($null -ne $configurationSettings.Remote_Elasticsearch_Api_Key){$Remote_Elasticsearch_Api_Key = $configurationSettings.Remote_Elasticsearch_Api_Key}
            if($null -ne $configurationSettings.Remote_Elasticsearch_Custom_Authentication_Header){$Remote_Elasticsearch_Custom_Authentication_Header = $configurationSettings.Remote_Elasticsearch_Custom_Authentication_Header}
            if($null -ne $configurationSettings.Execute_Patch_Summarization){$Execute_Patch_Summarization = $configurationSettings.Execute_Patch_Summarization}
            if($null -ne $configurationSettings.Remove_Processed_Scans_By_Days){$Remove_Processed_Scans_By_Days = $configurationSettings.Remove_Processed_Scans_By_Days}
    
        }catch{
            $_
            Write-Host "`nInvalid JSON file: Settings in configuration file could not be processed. Please check to make sure the file contain valid JSON data. Configuration file path: $Configuration_File_Path" -ForegroundColor Red
        }
    }else{
        Write-Host "No configuration file supplied, using provided command line arguments."
    }

    $option0 = "0. Setup Elasticsearch and Kibana."
    $option1 = "1. Export Nessus files."
    $option2 = "2. Ingest a single Nessus file into Elasticsearch (Optional - Patch summarization upon completion)."
    $option3 = "3. Ingest all Nessus files from a specified directory into Elasticsearch (Optional - Patch summarization upon completion)."
    $option4 = "4. Export and Ingest Nessus files into Elasticsearch (Optional - Patch summarization upon completion)."
    $option5 = "5. Purge processed hashes list (Remove list of what files have already been processed)."
    $option6 = "6. Compare scan data between scans and export results into Elasticsearch (Patch summarization)."
    $option7 = "7. Export PDF or CSV Report from Kibana dashboard and optionally send via Email (Advanced Options - Copy POST URL)."
    $option8 = "8. Remove processed scans from local Nessus file download directory (May be used optionally with -Remove_Processed_Scans_By_Days)."
    #$option10 = "10. Delete oldest scan from scan history (Future / Only works with Nessus Manager license)"
    $quit = "Q. Quit"
    $version = "`nVersion 1.7.0"

    function Show-Menu {
        Write-Host "Welcome to the PowerShell script that can export and ingest Nessus scan files into an Elastic stack!" -ForegroundColor Blue
        Write-Host "What would you like to do?" -ForegroundColor Yellow
        Write-Host $option0
        Write-Host $option1
        Write-Host $option2
        Write-Host $option3
        Write-Host $option4
        Write-Host $option5
        Write-Host $option6
        Write-Host $option7
        Write-Host $option8

        Write-Host $option10
        Write-Host $quit
        Write-Host $version
    }
    
    # Miscellenous Functions
    # Get FolderID from Folder name
    function getFolderIdFromName {
        param ($folderNames)

        $numErrors = 0
        $maxRetries = 5
        $retryCount = 0
        do {
            $reqOk = $false
            try {
                $folders = Invoke-RestMethod -Method Get -Uri "$Nessus_URL/folders" -ContentType "application/json" -Headers $headers -SkipCertificateCheck -ConnectionTimeoutSeconds $Connection_Timeout -OperationTimeoutSeconds $Operation_Timeout
                $reqOk = $true
            } catch {
                if ($_.Exception.Message -match "timed out" -or $_.Exception.Message -match "timeout") {
                    $numErrors += 1
                    $retryCount += 1
                    Write-Host "Request timed out, retry $numErrors" -ForegroundColor Yellow
                    Start-Sleep -Seconds 1
                } else {
                    Write-Host "Non-timeout error occurred: $($_.Exception.Message)" -ForegroundColor Red
                    break
                }
            }
        } until ($reqOk -or $retryCount -ge $maxRetries)
        if (-not $reqOk) {
            Write-Host "Failed to retrieve folders after $maxRetries retries. Exiting." -ForegroundColor Red
            exit
        }
        Write-Host "Folders Found: "
        $folders.folders.Name | ForEach-Object {
            Write-Host "$_" -ForegroundColor Green
        }
        $global:sourceFolderId = $($folders.folders | Where-Object {$_.Name -eq $folderNames[0]}).id
        $global:archiveFolderId = $($folders.folders | Where-Object {$_.Name -eq $folderNames[1]}).id
    }

    # Update Scan status
    function updateStatus {
        # Store the current Nessus Scans and their completing/running status to currentNessusScanData
        $numErrors = 0
        $maxRetries = 5
        $retryCount = 0
        do {
            $reqOk = $false
            try {
                $global:currentNessusScanDataRaw = Invoke-RestMethod -Method Get -Uri "$Nessus_URL/scans?folder_id=$($global:sourceFolderId)" -ContentType "application/json" -Headers $headers -SkipCertificateCheck -ConnectionTimeoutSeconds $Connection_Timeout -OperationTimeoutSeconds $Operation_Timeout
                $reqOk = $true
            } catch {
                if ($_.Exception.Message -match "timed out" -or $_.Exception.Message -match "timeout") {
                    $numErrors += 1
                    $retryCount += 1
                    Write-Host "Request timed out, retry $numErrors" -ForegroundColor Yellow
                    Start-Sleep -Seconds 1
                } else {
                    Write-Host "Non-timeout error occurred: $($_.Exception.Message)" -ForegroundColor Red
                    break
                }
            }
        } until ($reqOk -or $retryCount -ge $maxRetries)
        if (-not $reqOk) {
            Write-Host "Failed to retrieve scan status after $maxRetries retries. Exiting." -ForegroundColor Red
            exit
        }
        $global:listOfScans = $global:currentNessusScanDataRaw.scans | Select-Object -Property Name,Status,creation_date,id
        if ($global:listOfScans) {
            Write-Host "Scans found!" -ForegroundColor Green
            $global:listOfScans
        } else {
            Write-Host "No scans found." -ForegroundColor Red
        }
    }
    
    # Simple epoch to ISO8601 Timestamp converter
    function convertToISO {
        Param($epochTime)
        [datetime]$epoch = '1970-01-01 00:00:00'
        [datetime]$result = $epoch.AddSeconds($epochTime)
        $newTime = Get-Date $result -Format "o"
        return $newTime
    }

    # Core Functions
    function Invoke-Exract_From_Nessus {
        Param (
            # Nessus URL. (default - https://127.0.0.1:8834)
            [Parameter(Mandatory=$false)]
            $Nessus_URL,
            # The location where you wish to save the extracted Nessus files from the scanner. (default - Nessus_Exports)
            [Parameter(Mandatory=$false)]
            $Nessus_File_Download_Location,
            # Nessus Access Key
            [Parameter(Mandatory=$true)]
            $Nessus_Access_Key,
            # Nessus Secret Key
            [Parameter(Mandatory=$true)]
            $Nessus_Secret_Key,
            # The source folder for where the Nessus scans live in the UI. (default - "My Scans")
            [Parameter(Mandatory=$false)]
            $Nessus_Source_Folder_Name,
            # The destination folder in Nessus UI for where you wish to move your scans for archive. (default - none - scans won't move)
            [Parameter(Mandatory=$false)]
            $Nessus_Archive_Folder_Name,
            # Use this setting if you wish to only export the scans on the day the scan occurred. (default - false)
            [Parameter(Mandatory=$false)]
            $Nessus_Export_Scans_From_Today,
            # Use this setting if you want to export scans for the specific day that the scan or scans occurred. (example - 11/07/2023)
            [Parameter(Mandatory=$false)]
            $Nessus_Export_Day,
            # Added atrribute for the end of the file name for uniqueness when using with multiple scanners. (example - _scanner1)
            [Parameter(Mandatory=$false)]
            $Nessus_Export_Custom_Extended_File_Name_Attribute,
            # Use this setting to configure the behaviour for exporting more than just the latest scan. Options are:
            # Not configured or false, then the latest scan is exported.
            # "true" : exports all scan history.
            [Parameter(Mandatory=$false)]
            $Nessus_Export_All_Scan_History = $null
        )
#>
        $headers =  @{'X-ApiKeys' = "accessKey=$Nessus_Access_Key; secretKey=$Nessus_Secret_Key"}
        # Don't parse the file downloads because we care about speed!
        $ProgressPreference = 'SilentlyContinue'

        # Check to see if export scan directory exists, if not, create it!
        if ($(Test-Path -Path $Nessus_File_Download_Location) -eq $false) {
            Write-Host "Could not find $Nessus_File_Download_Location so creating that directory now."
            New-Item $Nessus_File_Download_Location -ItemType Directory
        }

        # Get FolderID from Folder name
        function getFolderIdFromName {
            param ($folderNames)

            $numErrors = 0
            $maxRetries = 5
            $retryCount = 0
            do {
                $reqOk = $false
                try {
                    $folders = Invoke-RestMethod -Method Get -Uri "$Nessus_URL/folders" -ContentType "application/json" -Headers $headers -SkipCertificateCheck -ConnectionTimeoutSeconds $Connection_Timeout -OperationTimeoutSeconds $Operation_Timeout
                    $reqOk = $true
                } catch {
                    if ($_.Exception.Message -match "timed out" -or $_.Exception.Message -match "timeout") {
                        $numErrors += 1
                        $retryCount += 1
                        Write-Host "Request timed out, retry $numErrors" -ForegroundColor Yellow
                        Start-Sleep -Seconds 1
                    } else {
                        Write-Host "Non-timeout error occurred: $($_.Exception.Message)" -ForegroundColor Red
                        break
                    }
                }
            } until ($reqOk -or $retryCount -ge $maxRetries)
            if (-not $reqOk) {
                Write-Host "Failed to retrieve folders after $maxRetries retries. Exiting." -ForegroundColor Red
                exit
            }
            Write-Host "Folders Found: "
            $folders.folders.Name | ForEach-Object {
                Write-Host "$_" -ForegroundColor Green
            }
            $global:sourceFolderId = $($folders.folders | Where-Object {$_.Name -eq $folderNames[0]}).id
            $global:archiveFolderId = $($folders.folders | Where-Object {$_.Name -eq $folderNames[1]}).id
        }
        getFolderIdFromName $Nessus_Source_Folder_Name, $Nessus_Archive_Folder_Name

        # Simple epoch to ISO8601 Timestamp converter
        function convertToISO {
            Param($epochTime)
            [datetime]$epoch = '1970-01-01 00:00:00'
            [datetime]$result = $epoch.AddSeconds($epochTime)
            $newTime = Get-Date $result -Format "o"
            return $newTime
        }

        # Sleep if scans are not finished
        function sleep5Minutes {
            $sleeps = "Scans not finished, going to sleep for 5 minutes. " + $(Get-Date)
            Write-Host $sleeps
            Start-Sleep -s 300
        }

        # Update Scan status
        function updateStatus {
            # Store the current Nessus Scans and their completing/running status to currentNessusScanData
            $numErrors = 0
            $maxRetries = 5
            $retryCount = 0
            do {
                $reqOk = $false
                try {
                    $global:currentNessusScanDataRaw = Invoke-RestMethod -Method Get -Uri "$Nessus_URL/scans?folder_id=$($global:sourceFolderId)" -ContentType "application/json" -Headers $headers -SkipCertificateCheck -ConnectionTimeoutSeconds $Connection_Timeout -OperationTimeoutSeconds $Operation_Timeout
                    $reqOk = $true
                } catch {
                    if ($_.Exception.Message -match "timed out" -or $_.Exception.Message -match "timeout") {
                        $numErrors += 1
                        $retryCount += 1
                        Write-Host "Request timed out, retry $numErrors" -ForegroundColor Yellow
                        Start-Sleep -Seconds 1
                    } else {
                        Write-Host "Non-timeout error occurred: $($_.Exception.Message)" -ForegroundColor Red
                        break
                    }
                }
            } until ($reqOk -or $retryCount -ge $maxRetries)
            if (-not $reqOk) {
                Write-Host "Failed to retrieve scan status after $maxRetries retries. Exiting." -ForegroundColor Red
                exit
            }
            $global:listOfScans = $global:currentNessusScanDataRaw.scans | Select-Object -Property Name,Status,creation_date,id
            if ($global:listOfScans) {
                Write-Host "Scans found!`nName | Status | Creation Date | Scan ID" -ForegroundColor Green
                $global:listOfScans | ForEach-Object {
                    "{0,-25} {1,-10} {2,-15} {3}" -f $_.name, $_.status, $_.creation_date, $_.id
                }
            } else {
                Write-Host "No scans found." -ForegroundColor Red
            }
        }

        function getScanIdsAndExport{
            updateStatus
            if ($Nessus_Export_Scans_From_Today -eq "true") {
                # Gets current day
                $getDate = Get-Date -Format "dddd-d"
                $global:listOfScans | ForEach-Object {
                    if ($(convertToISO($_.creation_date) | Get-Date -format "dddd-d") -eq $getDate) {
                        Write-Host "Going to export $_"
                        export -scanId $($_.id) -scanName $($_.name)
                        Write-Host "Finished export of $_, going to update status..."
                    }
                }
            } elseif ($null -ne $Nessus_Export_Day) {
                # Gets day entered from arguments
                $getDate = $Nessus_Export_Day | Get-Date -Format "dddd-d"
                $global:listOfScans | ForEach-Object {
                    $currentId = $_.id
                    $scanName = $_.name
                    $numErrors = 0
                    $maxRetries = 5
                    $retryCount = 0
                    do {
                        $reqOk = $false
                        try {
                            $scanHistory = Invoke-RestMethod -Method Get -Uri "$Nessus_URL/scans/$($currentId)?limit=2500" -ContentType "application/json" -Headers $headers -SkipCertificateCheck -ConnectionTimeoutSeconds $Connection_Timeout -OperationTimeoutSeconds $Operation_Timeout
                            $reqOk = $true
                        } catch {
                            if ($_.Exception.Message -match "timed out" -or $_.Exception.Message -match "timeout") {
                                $numErrors += 1
                                $retryCount += 1
                                Write-Host "Request timed out, retry $numErrors" -ForegroundColor Yellow
                                Start-Sleep -Seconds 1
                            } else {
                                Write-Host "Non-timeout error occurred: $($_.Exception.Message)" -ForegroundColor Red
                                break
                            }
                        }
                    } until ($reqOk -or $retryCount -ge $maxRetries)
                    if (-not $reqOk) {
                        Write-Host "Failed to retrieve scan history after $maxRetries retries. Exiting." -ForegroundColor Red
                        exit
                    }
                    $scanHistory.history | ForEach-Object {
                        if ($(convertToISO($_.creation_date) | Get-Date -format "dddd-d") -eq $getDate) {
                            # Write-Host "Going to export $_"
                            Write-Host "Scan History ID Found $($_.history_id)"
                            $currentConvertedTime = convertToISO($_.creation_date)
                            export -scanId $currentId -historyId $_.history_id -currentConvertedTime $currentConvertedTime -scanName $scanName
                            Write-Host "Finished export of $currentId, going to update status..."
                        } else {
                            # Write-Host "Nothing found" #$_
                            #convertToISO($_.creation_date)
                        }
                    }
                }
            } else {
                $global:listOfScans | ForEach-Object {
                    # Grab latest scan from Nessus
                    if($Nessus_Export_All_Scan_History -ne "true"){
                        Write-Host "Going to export $($_.name)"
                        export -scanId $($_.id) -scanName $($_.name)
                        Write-Host "Finished export of $($_.name), going to update status..."
                    } else {
                        # Grab all scans from history
                        # Get Scan History
                        $currentId = $_.id
                        $scanName = $_.name
                        $numErrors = 0
                        $maxRetries = 5
                        $retryCount = 0
                        do {
                            $reqOk = $false
                            try {
                                $scanHistory = Invoke-RestMethod -Method Get -Uri "$Nessus_URL/scans/$($currentId)?limit=2500" -ContentType "application/json" -Headers $headers -SkipCertificateCheck -ConnectionTimeoutSeconds $Connection_Timeout -OperationTimeoutSeconds $Operation_Timeout
                                $reqOk = $true
                            } catch {
                                if ($_.Exception.Message -match "timed out" -or $_.Exception.Message -match "timeout") {
                                    $numErrors += 1
                                    $retryCount += 1
                                    Write-Host "Request timed out, retry $numErrors" -ForegroundColor Yellow
                                    Start-Sleep -Seconds 1
                                } else {
                                    Write-Host "Non-timeout error occurred: $($_.Exception.Message)" -ForegroundColor Red
                                    break
                                }
                            }
                        } until ($reqOk -or $retryCount -ge $maxRetries)
                        if (-not $reqOk) {
                            Write-Host "Failed to retrieve scan history after $maxRetries retries. Exiting." -ForegroundColor Red
                            exit
                        }
                        if ($Nessus_Export_All_Scan_History -eq "true"){
                            Write-Host "Historical scans found: $($scanHistory.history.count)"
                            $scanHistory.history | ForEach-Object {
                                Write-Host "Scan History ID Found $($_.history_id)"
                                $currentConvertedTime = convertToISO($_.creation_date)
                                export -scanId $currentId -historyId $_.history_id -currentConvertedTime $currentConvertedTime -scanName $scanName
                                Write-Host "Finished export of $scanName-$currentId with history ID of $($_.history_id), going to update status..."
                            }
                        }
                    }    
                }
            }
        }

        function Move-ScanToArchive{
            $body = [PSCustomObject]@{
                folder_id = $archiveFolderId
            } | ConvertTo-Json

            $numErrors = 0
            $maxRetries = 5
            $retryCount = 0
            do {
                $reqOk = $false
                try {
                    $ScanDetails = Invoke-RestMethod -Method Put -Uri "$Nessus_URL/scans/$($scanId)/folder" -Body $body -ContentType "application/json" -Headers $headers -SkipCertificateCheck -ConnectionTimeoutSeconds $Connection_Timeout -OperationTimeoutSeconds $Operation_Timeout
                    $reqOk = $true
                } catch {
                    if ($_.Exception.Message -match "timed out" -or $_.Exception.Message -match "timeout") {
                        $numErrors += 1
                        $retryCount += 1
                        Write-Host "Request timed out, retry $numErrors" -ForegroundColor Yellow
                        Start-Sleep -Seconds 1
                    } else {
                        Write-Host "Non-timeout error occurred: $($_.Exception.Message)" -ForegroundColor Red
                        break
                    }
                }
            } until ($reqOk -or $retryCount -ge $maxRetries)
            if (-not $reqOk) {
                Write-Host "Failed to move scan to archive after $maxRetries retries. Exiting." -ForegroundColor Red
                return
            }
            Write-Host $ScanDetails -ForegroundColor Yellow
            Write-Host "Scan Moved to Archive - Export Complete." -ForegroundColor Green
        }

        function export ($scanId, $historyId, $currentConvertedTime, $scanName){
            Write-Host "Scan: $scanName exporting...`nscan id: $scanId`nhistory id: $historyId"
            do {
                if($null -eq $currentConvertedTime){
                    $convertedTime = convertToISO($($global:currentNessusScanDataRaw.scans | Where-Object {$_.id -eq $scanId}).creation_date)
                }else{
                    $convertedTime = $currentConvertedTime
                }
                $historyIdOrCreationDate = if($historyId){$historyId}else{$_.creation_date}
                $exportFileName = Join-Path $Nessus_File_Download_Location $($($convertedTime | Get-Date -Format yyyy_MM_dd).ToString()+"-$($scanName)"+"-$scanId-$historyIdOrCreationDate$($Nessus_Export_Custom_Extended_File_Name_Attribute).nessus")
                $exportComplete = 0
                $currentScanIdStatus = $($global:currentNessusScanDataRaw.scans | Where-Object {$_.id -eq $scanId}).status
                # Check to see if scan is not running or is an empty scan, if true then lets export!
                if ($currentScanIdStatus -ne 'running' -and $currentScanIdStatus -ne 'empty' -or $historyId) {
                    $scanExportOptions = [PSCustomObject]@{
                        "format" = "nessus"
                    } | ConvertTo-Json
                    # Start the export process to Nessus has the file prepared for download
                    if($historyId){$historyIdFound = "?history_id=$historyId"}else {$historyId = $null}
                    $numErrors = 0
                    $maxRetries = 5
                    $retryCount = 0
                    do {
                        $reqOk = $false
                        try {
                            $exportInfo = Invoke-RestMethod -Method Post "$Nessus_URL/scans/$($scanId)/export$($historyIdFound)" -Body $scanExportOptions -ContentType "application/json" -Headers $headers -SkipCertificateCheck -ConnectionTimeoutSeconds $Connection_Timeout -OperationTimeoutSeconds $Operation_Timeout
                            $reqOk = $true
                        } catch {
                            if ($_.Exception.Message -match "timed out" -or $_.Exception.Message -match "timeout") {
                                $numErrors += 1
                                $retryCount += 1
                                Write-Host "Request timed out, retry $numErrors" -ForegroundColor Yellow
                                Start-Sleep -Seconds 1
                            } else {
                                Write-Host "Non-timeout error occurred: $($_.Exception.Message)" -ForegroundColor Red
                                break
                            }
                        }
                    } until ($reqOk -or $retryCount -ge $maxRetries)
                    if (-not $reqOk) {
                        Write-Host "Failed to start export after $maxRetries retries. Exiting." -ForegroundColor Red
                        return
                    }                    
                    $exportStatus = ''
                    while ($exportStatus.status -ne 'ready') {
                        try {
                            $exportStatus = Invoke-RestMethod -Method Get "$Nessus_URL/scans/$($ScanId)/export/$($exportInfo.file)/status" -ContentType "application/json" -Headers $headers -SkipCertificateCheck -ConnectionTimeoutSeconds $Connection_Timeout -OperationTimeoutSeconds $Operation_Timeout
                            Write-Host "Export status: $($exportStatus.status)"
                        }
                        catch {
                            Write-Host "An error has occurred while trying to export the scan" -ForegroundColor Red
                            break
                        }
                        Start-Sleep -Seconds 1
                    }
                    # Time to download the Nessus scan!
                    $numErrors = 0
                    $maxRetries = 5
                    $retryCount = 0
                    do {
                        $reqOk = $false
                        try {
                            Invoke-RestMethod -Method Get -Uri "$Nessus_URL/scans/$($scanId)/export/$($exportInfo.file)/download" -ContentType "application/json" -Headers $headers -OutFile $exportFileName -SkipCertificateCheck -ConnectionTimeoutSeconds $Connection_Timeout -OperationTimeoutSeconds $Operation_Timeout
                            $reqOk = $true
                        } catch {
                            if ($_.Exception.Message -match "timed out" -or $_.Exception.Message -match "timeout") {
                                $numErrors += 1
                                $retryCount += 1
                                Write-Host "Request timed out, retry $numErrors" -ForegroundColor Yellow
                                Start-Sleep -Seconds 1
                            } else {
                                Write-Host "Non-timeout error occurred: $($_.Exception.Message)" -ForegroundColor Red
                                break
                            }
                        }
                    } until ($reqOk -or $retryCount -ge $maxRetries)
                    if (-not $reqOk) {
                        Write-Host "Failed to download scan after $maxRetries retries. Exiting." -ForegroundColor Red
                        exit
                    }                    
                    $exportComplete = 1
                    Write-Host "Export succeeded!" -ForegroundColor Green
                    if ($null -ne $Nessus_Archive_Folder_Name) {
                        # Move scan to archive if folder is configured!
                        Write-Host "Archive scan folder configured so going to move the scan in the Nessus web UI to $Nessus_Archive_Folder_Name" -Foreground Yellow
                        Move-ScanToArchive
                    } else {
                        Write-Host "Archive folder not configured so not moving scan in the Nessus web UI." -Foreground Yellow
                    }

                }
                # If a scan is empty because it hasn't been started skip the export and move on.
                if ($currentScanIdStatus -eq 'empty') {
                    Write-Host "Scan has not been started, therefore skipping this scan."
                    $exportComplete = 2
                }
                if ($exportComplete -eq 0 ){
                    sleep5Minutes
                    updateStatus
                }
            } While ($exportComplete -eq 0)

        }

        $x = 3
        do {
            getScanIdsAndExport
            # Stop Nessus to get a fresh start
            if ($global:currentNessusScanData.Status -notcontains 'running') {
            } else {
                Write-Host 'Nessus has issues, investigate now!'
            }
            $x = 1
        } while ($x -gt 2)

        Write-Host "Finished Exporting!" -ForegroundColor White
    }

    function Invoke-Import_Nessus_To_Elasticsearch {
        Param (
            # Nessus XML file path
            [Parameter(Mandatory=$true)]
            $Nessus_XML_File,
            # Add Elasticsearch URL to automate Nessus import (default - https://127.0.0.1:9200)
            [Parameter(Mandatory=$true)]
            $Elasticsearch_URL,
            # Add Elasticsearch index name to automate Nessus import (default - logs-nessus.vulnerability)
            [Parameter(Mandatory=$true)]
            $Elasticsearch_Index_Name,
            # Elasticsearch API Key
            [Parameter(Mandatory=$true)]
            $Elasticsearch_API_Key,
            # Batch size for bulk imports (default - 5000)
            [Parameter(Mandatory=$false)]
            $Elasticsearch_Bulk_Import_Batch_Size = 5000
        )

        $ErrorActionPreference = 'Stop'
        $nessus = [xml]''
        Write-Host "Loading the file $Nessus_XML_File, please wait..." -ForegroundColor Green
        $nessus.Load($Nessus_XML_File)

        # Elastic Instance (Hard code values here - This is not recommended.)
        #$Elasticsearch_IP = '127.0.0.1'
        #$Elasticsearch_Port = '9200'

        if ($Elasticsearch_URL -ne "https://127.0.0.1:9200") {
            Write-Host "Using the URL you provided for Elastic: $Elasticsearch_URL" -ForegroundColor Green
        } else {
            Write-Host "Running script with default localhost Elasticsearch URL ($Elasticsearch_URL)." -ForegroundColor Yellow
        }
        # Nessus User Authenitcation Variables for Elastic
        if ($Elasticsearch_API_Key) {
            Write-Host "Using the Api Key you provided." -ForegroundColor Green
        } else {
            Write-Host "Elasticsearch API Key Required! Go here if you don't know how to obtain one - https://www.elastic.co/guide/en/elasticsearch/reference/current/security-api-create-api-key.html" -ForegroundColor "Red"
            break
        }
        $global:AuthenticationHeaders = @{Authorization = "$Elasticsearch_Custom_Authentication_Header $Elasticsearch_API_Key"}

        # Create index name
        if ($Elasticsearch_Index_Name -ne "logs-nessus.vulnerability" ) {
            Write-Host "Using the Index you provided: $Elasticsearch_Index_Name" -ForegroundColor Green
        } else {
            $Elasticsearch_Index_Name = "logs-nessus.vulnerability"; Write-Host "No Index was entered, using the default value of $Elasticsearch_Index_Name" -ForegroundColor Yellow
        }
        
        function convertEpochSecondsToISO {
            Param($epochTime)
            $dateTime = [System.DateTimeOffset]::FromUnixTimeMilliseconds($epochTime).DateTime
            $newTime = Get-Date $dateTime -Format "o"
            return $newTime
        }

        # Now let the magic happen!
        Write-Host "
        Starting ingest of $Nessus_XML_File.

        The time it takes to parse and ingest will vary on the file size. 
        
        Note: Files larger than 1GB could take over 35 minutes.

        You can check if data is getting ingested by visiting Kibana and look under Index Management for this index: $Elasticsearch_Index_Name

        For debugging uncomment:
        #`$data.items | ConvertTo-Json -Depth 5
        "
        $fileProcessed = (Get-ChildItem $Nessus_XML_File).name
        $reportName = $nessus.NessusClientData_v2.Report.name
        $totalHostsFromScan = $nessus.NessusClientData_v2.Report.ReportHost.count
        Write-Host "Processing file: $fileProcessed`nReport name: $reportName`nTotal hosts: $totalHostsFromScan`nBatch size for bulk imports: $Elasticsearch_Bulk_Import_Batch_Size" -ForegroundColor "Blue"
        $totalHostsFromScan = $nessus.NessusClientData_v2.Report.ReportHost.Count
        $hostCounter = 0
        
        # Initialize global batch tracking across all hosts
        $globalBatchBuffer = [System.Collections.Generic.List[string]]::new()
        $globalDocCount = 0
        $totalBatchesSent = 0
        
        foreach ($n in $nessus.NessusClientData_v2.Report.ReportHost) {

            # Set counter for progress bar
            $hostCounter++
            Show-ProgressBar -Current $hostCounter -Total $totalHostsFromScan -Activity "Processing Hosts" -Color "Green"

            foreach ($r in $n.ReportItem) {
                foreach ($nHPTN_Item in $n.HostProperties.tag) {
                # Get useful tag information from the report
                switch -Regex ($nHPTN_Item.name)
                    {
                    "host-ip" {$ip = $nHPTN_Item."#text"}
                    "host-fqdn" {$fqdn = $nHPTN_Item."#text"}
                    "host-rdns" {$rdns = $nHPTN_Item."#text"}
                    "hostname$" {$hostname = $nHPTN_Item."#text"}
                    "netbios-name" {$netbiosname = $nHPTN_Item."#text"}
                    "operating-system-unsupported" {$osu = $nHPTN_Item."#text"}
                    "system-type" {$systype = $nHPTN_Item."#text"}
                    "^os$" {$os = $nHPTN_Item."#text"}
                    "operating-system$" {$opersys = $nHPTN_Item."#text"}
                    "operating-system-conf" {$operSysConfidence = $nHPTN_Item."#text"}
                    "operating-system-method" {$operSysMethod = $nHPTN_Item."#text"}
                    "^Credentialed_Scan" {$credscan = $nHPTN_Item."#text"}
                    "mac-address" {$macAddr = $nHPTN_Item."#text"}
                    "HOST_START_TIMESTAMP$" {$hostStart = $nHPTN_Item."#text"}
                    "HOST_END_TIMESTAMP$" {$hostEnd = $nHPTN_Item."#text"}
                    }
                }
                # Convert seconds to milliseconds
                $hostStart = $([int]$hostStart*1000)
                $hostEnd =  if($hostEnd){$([int]$hostEnd*1000)}else{$null}
                # Create duration and convert milliseconds to nano seconds
                $duration =  $(($hostEnd - $hostStart)*1000000)

                # Convert start and end dates to ISO
                $hostStart = convertEpochSecondsToISO $hostStart
                $hostEnd = if($hostEnd){convertEpochSecondsToISO $hostEnd}else{$null}

                $obj = [PSCustomObject]@{
                    "@timestamp" = $hostStart # Remove later for at ingest enrichment
                    "destination" = [PSCustomObject]@{
                        "port" = $([Uint16]$r.port)
                    }
                    "message" = $n.name + ' - ' + $r.synopsis # Remove later for at ingest enrichment                
                    "event" = [PSCustomObject]@{
                        "category" = "host" # Remove later for at ingest enrichment
                        "kind" = "state" # Remove later for at ingest enrichment
                        "duration" = if($duration){$([long]$duration)}else{$null}
                        "start" = $hostStart
                        "end" = if($hostEnd){$hostEnd}else{$null}
                        "risk_score" = $r.severity
                        "dataset" = "vulnerability" # Remove later for at ingest enrichment
                        "provider" = "Nessus" # Remove later for at ingest enrichment
                        "module" = "Invoke-Power-Nessie"
                        "severity" = $([Uint16]$r.severity) # Remove later for at ingest enrichment
                        "url" = (@(if($r.cve){($r.cve | ForEach-Object {"https://cve.mitre.org/cgi-bin/cvename.cgi?name=$_"})}else{$null})) # Remove later for at ingest enrichment
                    }
                    "host" = [PSCustomObject]@{
                        "ip" = $ip
                        "mac" = (@(if($macAddr){($macAddr.Split([Environment]::NewLine))}else{$null}))
                        "hostname" = if($fqdn -notmatch "sources" -and ($fqbn)){($fqdn).ToLower()}elseif($rdns){($rdns).ToLower()}elseif($hostname){$hostname.ToLower()}elseif($netbiosname){$netbiosname.ToLower()}else{$null} # Remove later for at ingest enrichment # Also, added a check for an extra "sources" sub field added to the fqbn field
                        "name" = if($fqdn -notmatch "sources" -and ($fqbn)){($fqdn).ToLower()}elseif($rdns){($rdns).ToLower()}elseif($hostname){$hostname.ToLower()}elseif($netbiosname){$netbiosname.ToLower()}else{$null} # Remove later for at ingest enrichment # Also, added a check for an extra "sources" sub field added to the fqbn field
                        "os" = [PSCustomObject]@{
                            "family" = $os
                            "full" = @(if($opersys){$opersys.Split("`n`r")}else{$null})
                            "name" = @(if($opersys){$opersys.Split("`n`r")}else{$null})
                            "platform" = $os
                        }
                    }
                    "log" = [PSCustomObject]@{
                        "origin" = [PSCustomObject]@{
                            "file" = [PSCustomObject]@{
                                "name" =  $fileProcessed
                            }
                        }
                    }
                    "nessus" = [PSCustomObject]@{
                        "cve" = (@(if($r.cve){($r.cve).ToLower()}else{$null}))
                        "in_the_news" = if($r.in_the_news){$r.in_the_news}else{$null}
                        "solution" = $r.solution
                        "synopsis" = $r.synopsis
                        "unsupported_os" = if($osu){$osu}else{$null}
                        "system_type" = $systype
                        "credentialed_scan" = $credscan
                        "exploit_available" = $r.exploit_available
                        "edb-id" = $r."edb-id"
                        "unsupported_by_vendor" = $r.unsupported_by_vendor
                        "os_confidence" = $operSysConfidence
                        "os_identification_method" = $operSysMethod
                        "rdns" = $rdns
                        "name_of_host" = $n.name.ToLower()
                        "cvss" = [PSCustomObject]@{
                            "vector" = if($r.cvss_vector){$r.cvss_vector}else{$null}
                            "base_score" = if($r.cvss_base_score){$r.cvss_base_score}else{$null}
                            "impact_score" = if($r.cvss_impactScore){$r.cvss_impactScore}else{$null}
                            "temporal_score" = if($r.cvss_temporal_score){$r.cvss_temporal_score}else{$null}
                        }
                        "cvss3" = [PSCustomObject]@{
                            "vector" = if($r.cvss3_vector){$r.cvss3_vector}else{$null}
                            "base_score" = if($r.cvss3_base_score){$r.cvss3_base_score}else{$null}
                            "impact_score" = if($r.cvssV3_impactScore){$r.cvssV3_impactScore}else{$null}
                            "temporal_score" = if($r.cvss3_temporal_score){$r.cvss3_temporal_score}else{$null}
                        }
                        "cvss4" = [PSCustomObject]@{
                            "vector" = if($r.cvss4_vector){$r.cvss4_vector}else{$null}
                            "base_score" = if($r.cvss4_base_score){$r.cvss4_base_score}else{$null}
                            "threat_score" = if($r.cvss4_threat_score){$r.cvss4_threat_score}else{$null}
                            "threat_vector" = if($r.cvss4_threat_vector){$r.cvss4_threat_vector}else{$null}
                        }
                        "plugin" = [PSCustomObject]@{
                            "id" = $r.pluginID
                            "name" = $r.pluginName
                            "publication_date" = $r.plugin_publication_date
                            "type" = $r.plugin_type
                            "output" = $r.plugin_output
                            "filename" = $r.fname
                            "modification_date" = if($r.plugin_modification_date){$r.plugin_modification_date}else{$null}
                            "script_version" = if($r.script_version){$r.script_version}else{$null}
                        }
                        "vpr_score" = if($r.vpr_score){$r.vpr_score}else{$null}
                        "exploit_code_maturity" = if($r.exploit_code_maturity){$r.exploit_code_maturity}else{$null}
                        "exploitability_ease" = if($r.exploitability_ease){$r.exploitability_ease}else{$null}
                        "age_of_vuln" = if($r.age_of_vuln){$r.age_of_vuln}else{$null}
                        "patch_publication_date" = if($r.patch_publication_date){$r.patch_publication_date}else{$null}
                        "stig_severity" = if($r.stig_severity){$r.stig_severity}else{$null}
                        "threat" = [PSCustomObject]@{
                            "intensity_last_28" = if($r.threat_intensity_last_28){$r.threat_intensity_last_28}else{$null}
                            "recency" = if($r.threat_recency){$r.threat_recency}else{$null}
                            "sources_last_28" = if($r.threat_sources_last_28){$r.threat_sources_last_28}else{$null}
                        }
                        "vuln_publication_date" = if($r.vuln_publication_date){$r.vuln_publication_date}else{$null}
                        "product_coverage" = if($r.product_coverage){$r.product_coverage}else{$null}
                        "cea_id" = if($r.'cea-id'){$r.'cea-id'}else{$null}
                        "cisa_known_exploited" = if($r.'cisa-known-exploited'){$r.'cisa-known-exploited'}else{$null}
                        "cpe" = if($r.cpe){$r.cpe}else{$null}
                        "exploited_by_malware" = if($r.exploited_by_malware){$r.exploited_by_malware}else{$null}
                        "exploited_by_nessus" = if($r.exploited_by_nessus){$r.exploited_by_nessus}else{$null}
                        "risk_factor" = if($r.risk_factor){$r.risk_factor}else{$null}
                        "epss_score" = if($r.epss_score){$r.epss_score}else{$null}
                    }
                    "network" = [PSCustomObject]@{
                        "transport" = $r.protocol
                        "application" = $r.svc_name
                    }
                    "vulnerability" = [PSCustomObject]@{
                        "id" = (@(if($r.cve){($r.cve)}else{$null}))
                        "category" = $r.pluginFamily
                        "description" = $r.description
                        "severity" = $r.risk_factor
                        "reference" = (@(if($r.see_also){($r.see_also.Split("`n"))}else{$null}))
                        "report_id" = $reportName
                        "module" = $r.pluginName
                        "classification" = (@(if($r.cve){("CVE")}else{$null}))
                        "score" = [PSCustomObject]@{
                            "base" = $r.cvss_base_score
                            "temporal" = $r.cvss_temporal_score
                        }
                    }

                } | ConvertTo-Json -Compress -Depth 5
                
                $globalBatchBuffer.Add("{`"create`":{ } }`r`n$obj`r`n")
                $globalDocCount++
                
                # Check if batch size limit is reached
                if ($globalDocCount -ge $Elasticsearch_Bulk_Import_Batch_Size) {
                    # Send batch to Elasticsearch
                    $ProgressPreference = 'SilentlyContinue'
                    $hash = $globalBatchBuffer -join ""
                    $numErrors = 0
                    $maxRetries = 5
                    $retryCount = 0
                    do {
                        $reqOk = $false
                        try {
                            $data = Invoke-RestMethod -Uri "$Elasticsearch_URL/$Elasticsearch_Index_Name/_bulk" -Method POST -ContentType "application/x-ndjson; charset=utf-8" -Body $hash -Headers $global:AuthenticationHeaders -SkipCertificateCheck -ConnectionTimeoutSeconds $Connection_Timeout -OperationTimeoutSeconds $Operation_Timeout
                            $reqOk = $true
                        } catch {
                            if ($_.Exception.Message -match "timed out" -or $_.Exception.Message -match "timeout") {
                                $numErrors += 1
                                $retryCount += 1
                                Write-Host "Request timed out, retry $numErrors" -ForegroundColor Yellow
                                Start-Sleep -Seconds 1
                            } else {
                                Write-Host "Non-timeout error occurred: $($_.Exception.Message)" -ForegroundColor Red
                                break
                            }
                        }
                    } until ($reqOk -or $retryCount -ge $maxRetries)
                    if (-not $reqOk) {
                        Write-Host "Failed to ingest data after $maxRetries retries. Exiting." -ForegroundColor Red
                        exit
                    }
                    
                    # Reset batch buffer and counters
                    $globalBatchBuffer.Clear()
                    $globalDocCount = 0
                    $totalBatchesSent++
                    Write-Host "Batch $totalBatchesSent sent to Elasticsearch ($($Elasticsearch_Bulk_Import_Batch_Size) documents)" -ForegroundColor Green
                }
                
                # Clean up variables
                $ip = $null
                $fqdn = $null
                $rdns = $null
                $hostname = $null
                $netbiosname = $null
                $osu = $null
                $systype = $null
                $os = $null
                $opersys = $null
                $operSysConfidence = $null
                $operSysMethod = $null
                $credscan = $null
                $macAddr = $null
                $hostStart = $null
                $hostEnd = $null

            }
        }
        
        # Send any remaining documents in the buffer
        if ($globalDocCount -gt 0) {
            $ProgressPreference = 'SilentlyContinue'
            $hash = $globalBatchBuffer -join ""
            $numErrors = 0
            $maxRetries = 5
            $retryCount = 0
            do {
                $reqOk = $false
                try {
                    $data = Invoke-RestMethod -Uri "$Elasticsearch_URL/$Elasticsearch_Index_Name/_bulk" -Method POST -ContentType "application/x-ndjson; charset=utf-8" -Body $hash -Headers $global:AuthenticationHeaders -SkipCertificateCheck -ConnectionTimeoutSeconds $Connection_Timeout -OperationTimeoutSeconds $Operation_Timeout
                    $reqOk = $true
                } catch {
                    if ($_.Exception.Message -match "timed out" -or $_.Exception.Message -match "timeout") {
                        $numErrors += 1
                        $retryCount += 1
                        Write-Host "Request timed out, retry $numErrors" -ForegroundColor Yellow
                        Start-Sleep -Seconds 1
                    } else {
                        Write-Host "Non-timeout error occurred: $($_.Exception.Message)" -ForegroundColor Red
                        break
                    }
                }
            } until ($reqOk -or $retryCount -ge $maxRetries)
            if (-not $reqOk) {
                Write-Host "Failed to ingest data after $maxRetries retries. Exiting." -ForegroundColor Red
                exit
            }
            
            $totalBatchesSent++
            Write-Host "Final batch $totalBatchesSent sent to Elasticsearch ($globalDocCount documents)" -ForegroundColor Green
        }
        
        Write-Host "Ingestion complete! Total batches sent: $totalBatchesSent" -ForegroundColor Green
    }

    function Invoke-Automate_Nessus_File_Imports {
        Param (
            # The location where you wish to save the extracted Nessus files from the scanner (default - Nessus_Exports)
            [Parameter(Mandatory=$true)]
            $Nessus_File_Download_Location,
            # Add Elasticsearch URL to automate Nessus import (default - https://127.0.0.1:9200)
            [Parameter(Mandatory=$true)]
            $Elasticsearch_URL,
            # Add Elasticsearch index name to automate Nessus import (default - logs-nessus.vulnerability)
            [Parameter(Mandatory=$true)]
            $Elasticsearch_Index_Name,
            # Elasticsearch Api Key
            [Parameter(Mandatory=$true)]
            $Elasticsearch_API_Key,
            # Batch size for bulk imports (default - 5000)
            [Parameter(Mandatory=$false)]
            $Elasticsearch_Bulk_Import_Batch_Size = 5000
        )

        $ProcessedHashesPath = "ProcessedHashes.txt"
        # Check to see if export scan directory exists, if not, create it!
        if ($false -eq $(Test-Path -Path $Nessus_File_Download_Location)) {
            Write-Host "Could not find $Nessus_File_Download_Location so creating that directory now."
            New-Item $Nessus_File_Download_Location -ItemType Directory
        }
        # Check to see if ProcessedHashses.txt file exists, if not, create it!
        if ($false -eq $(Test-Path -Path $processedHashesPath)) {
            Write-Host "Could not find $processedHashesPath so creating that file now."
            New-Item $processedHashesPath
        }
        
        # Check to see if parsedTime.txt file exists, if not, create it!
        if ($false -eq $(Test-Path -Path "parsedTime.txt")) {
            Write-Host "Could not find parsedTime.txt so creating that file now."
            New-Item "parsedTime.txt"
        }

        # Start ingesting 1 by 1!
        $allFiles = Get-ChildItem -Path $Nessus_File_Download_Location -Recurse -Include "*.nessus"
        $allProcessedHashes = Get-Content $processedHashesPath
        $allFiles | ForEach-Object {
            # Check if already processed by name and hash
            if ($_.Name -like '*.nessus' -and ($allProcessedHashes -notcontains $($_ | Get-FileHash).Hash)) {
                $starting = Get-Date
                $Nessus_XML_File = Join-Path $Nessus_File_Download_Location -ChildPath $_.Name
                $markProcessed = "$($_.Name).processed"
                Write-Host "Going to process $_ now."
                Invoke-Import_Nessus_To_Elasticsearch -Nessus_XML_File $_ -Elasticsearch_URL $Elasticsearch_URL -Elasticsearch_Index_Name $Elasticsearch_Index_Name -Elasticsearch_API_Key $Elasticsearch_API_Key -Elasticsearch_Bulk_Import_Batch_Size $Elasticsearch_Bulk_Import_Batch_Size
                $ending = Get-Date
                $duration = $ending - $starting
                $($Nessus_XML_File+'-PSNFscript-'+$duration | Out-File $(Resolve-Path parsedTime.txt).Path -Append)
                $($_ | Get-FileHash).Hash.toString() | Add-Content $processedHashesPath
                Write-Host "$Nessus_XML_File processed in $duration"
                Rename-Item -Path $_ -NewName $markProcessed
            } else {
                Write-Host "The file $($_.Name) doesn't end in .nessus or has already been processed in the $ProcessedHashesPath file. This file is used for tracking what files have been ingested to prevent duplicate ingest of data."
                Write-Host "If it's already been processed and you want to process it again, remove the hash from the $ProcessedHashesPath file or just remove it entirely for a clean slate."
            }
        }
        
        Write-Host "End of automating script!" -ForegroundColor Green
    }

    function Invoke-Purge_Processed_Hashes_List {
        Remove-Item .\ProcessedHashes.txt -Force
    }

    function Invoke-Revert_Nessus_To_Processed_Rename {
        Param (
            # The location where you wish to save the extracted Nessus files from the scanner (default - Nessus_Exports)
            [Parameter(Mandatory=$true)]
            $Nessus_File_Download_Location
        )
        # Get all files in the directory with the .nessus.processed extension
        $allFiles = Get-ChildItem -Path $Nessus_File_Download_Location -Recurse -Include "*.processed"
        
        # Rename each file
        foreach ($file in $allFiles) {
            $newName = $file.FullName -replace '\.processed$', ''
            Rename-Item -Path $file.FullName -NewName $newName -Force
        }
    }

    function Invoke-Purge_Oldest_Scan_From_History {
        Param ( 
        [Parameter(Mandatory=$true)]
        $Nessus_Scan_Name_To_Delete_Oldest_Scan
        )

        $headers =  @{'X-ApiKeys' = "accessKey=$Nessus_Access_Key; secretKey=$Nessus_Secret_Key"}
        
        # Don't parse the file downloads because we care about speed!
        $ProgressPreference = 'SilentlyContinue'
        getFolderIdFromName $Nessus_Source_Folder_Name, $Nessus_Archive_Folder_Name
        updateStatus
        $global:listOfScans | Where-Object -Property name -eq $Nessus_Scan_Name_To_Delete_Oldest_Scan
        $scanId = $($global:listOfScans | Where-Object -Property name -eq $Nessus_Scan_Name_To_Delete_Oldest_Scan).id
        if($null -eq $scanId){
            Write-Host "Invalid scan name entered ($Nessus_Scan_Name_To_Delete_Oldest_Scan) - exiting script" -ForegroundColor Yellow
            exit
        } else {
            Write-Host "Valid scan name found ($Nessus_Scan_Name_To_Delete_Oldest_Scan)" -ForegroundColor Green
        }
        $scanHistory = Invoke-RestMethod -Method Get -Uri "$Nessus_URL/scans/$($scanId)?limit=2500" -ContentType "application/json" -Headers $headers -SkipCertificateCheck -ConnectionTimeoutSeconds $Connection_Timeout -OperationTimeoutSeconds $Operation_Timeout
        $scanHistorySorted = $scanHistory.history | Select-Object -Property history_id, @{Name='creation_date'; Expression={convertToISO($_.creation_date)|Get-Date -Format 'MM/dd/yyyy HH:mm:ss'}}, status | Sort-Object -Property creation_date
        $oldestStartDate =  $scanHistorySorted[0].creation_date
        $oldestStatus = $scanHistorySorted[0].status
        $oldestHistoryId = $scanHistorySorted[0].history_id
        $scanHistorySorted 
        Write-Host "Found $($($scanHistory.history).count) total scans for $($scanHistory.info.name)"
        Write-Host "The oldest scan will be deleted. Details below:`nScan Started: $oldestStartDate`nScan Status: $oldestStatus`nScan History Id: $oldestHistoryId"
        try{
            # Delete scan
            Write-Host "Deleting scan! $Nessus_Scan_Name_To_Delete_Oldest_Scan (Id-$scanId,History Id-$oldestHistoryId)" -ForegroundColor Magenta
            $deleteScan = Invoke-RestMethod -Method Delete -Uri "$Nessus_URL/scans/$($scanId)/history/$oldestHistoryId" -ContentType "application/json" -Headers $headers -SkipCertificateCheck -ConnectionTimeoutSeconds $Connection_Timeout -OperationTimeoutSeconds $Operation_Timeout
            Write-Host "Scan successfully deleted!"
        } catch {
            Write-Host "Scan could not be deleted. $_"
        }

        Write-Host "End of oldest scan deletion script!" -ForegroundColor Green
    }

    ### Compare Scans Feature Functions \/ \/ \/
    # Create a new date based on shift in days
    function dateShift {
        param (
            $date,
            $daysToShiftBackwards
        )
        $newDate = $((Get-Date $date).AddDays(-$daysToShiftBackwards)) | Get-Date -Format "o" -AsUTC
        return $newDate
    }

    # Get Vulnerability Scan Data
    function getVulnData {
        param (
            $dateAfter,
            $dateBefore,
            $severity
        )
        $queryResults = @()

        # Create Point In Time Query for pagination (PIT)
        $numErrors = 0
        $maxRetries = 5
        $retryCount = 0
        do {
            $reqOk = $false
            try {
                $pitSearch = Invoke-RestMethod "$Elasticsearch_URL/$Elasticsearch_Index_Name/_pit?keep_alive=1m" -Method POST -Headers $global:AuthenticationHeaders -ContentType "application/json" -SkipCertificateCheck -ConnectionTimeoutSeconds $Connection_Timeout -OperationTimeoutSeconds $Operation_Timeout
                $reqOk = $true
            } catch {
                if ($_.Exception.Message -match "timed out" -or $_.Exception.Message -match "timeout") {
                    $numErrors += 1
                    $retryCount += 1
                    Write-Host "Request timed out, retry $numErrors" -ForegroundColor Yellow
                    Start-Sleep -Seconds 1
                } else {
                    Write-Host "Non-timeout error occurred: $($_.Exception.Message)" -ForegroundColor Red
                    break
                }
            }
        } until ($reqOk -or $retryCount -ge $maxRetries)
        if (-not $reqOk) {
            Write-Host "Failed to retrieve PIT after $maxRetries retries. Exiting." -ForegroundColor Red
            exit
        }
        $pitID = $pitSearch.id

        $getAllHostsWithVulnsQueryBySeverityAllDocs = @"
        {
            "size": 5000,
            "query": {
              "bool": {
                "must": [],
                "filter": [
                  {
                    "bool": {
                      "filter": [
                        {
                          "bool": {
                            "should": [
                              {
                                "query_string": {
                                  "fields": [
                                    "_index"
                                  ],
                                  "query": "$($Elasticsearch_Index_Name)"
                                }
                              }
                            ],
                            "minimum_should_match": 1
                          }
                        },
                        {
                          "bool": {
                            "must": [],
                            "filter": [
                              {
                                "bool": {
                                  "should": [
                                    {
                                      "term": {
                                        "vulnerability.severity": {
                                          "value": "$($severity)"
                                        }
                                      }
                                    }
                                  ],
                                  "minimum_should_match": 1
                                }
                              }
                            ],
                            "should": [],
                            "must_not": []
                          }
                        }$Elasticsearch_Custom_Filter
                      ]
                    }
                  },
                  {
                    "range": {
                      "@timestamp": {
                        "format": "strict_date_optional_time",
                        "gte": "$($dateAfter)",
                        "lte": "$($dateBefore)"
                      }
                    }
                  }
                ],
                "should": [],
                "must_not": []
              }
            },
            "pit": {
              "id": "$pitID",
              "keep_alive": "1m"
            },
            "sort": [
              {
                "_shard_doc": "asc"
              }
            ]
          }
"@

        # Query Elastic for vulnerability information based on time frame
        Write-Host "Querying Elastic for $severity vulnerability data." -ForegroundColor Blue

        #$ingestResults = Invoke-RestMethod "$Elasticsearch_URL/$Elasticsearch_Index_Name/_search" -Method GET -Headers $global:AuthenticationHeaders -Body $getAllHostsWithVulnsQueryBySeverity -ContentType "application/json" -SkipCertificateCheck -ConnectionTimeoutSeconds $Connection_Timeout -OperationTimeoutSeconds $Operation_Timeout
        $numErrors = 0
        $maxRetries = 5
        $retryCount = 0
        do {
            $reqOk = $false
            try {
                $queryResults += Invoke-RestMethod "$Elasticsearch_URL/_search" -Method GET -Headers $global:AuthenticationHeaders -Body $getAllHostsWithVulnsQueryBySeverityAllDocs -ContentType "application/json" -SkipCertificateCheck -ConnectionTimeoutSeconds $Connection_Timeout -OperationTimeoutSeconds $Operation_Timeout
                $reqOk = $true
            } catch {
                if ($_.Exception.Message -match "timed out" -or $_.Exception.Message -match "timeout") {
                    $numErrors += 1
                    $retryCount += 1
                    Write-Host "Request timed out, retry $numErrors" -ForegroundColor Yellow
                    Start-Sleep -Seconds 1
                } else {
                    Write-Host "Non-timeout error occurred: $($_.Exception.Message)" -ForegroundColor Red
                    break
                }
            }
        } until ($reqOk -or $retryCount -ge $maxRetries)
        if (-not $reqOk) {
            Write-Host "Failed to retrieve data after $maxRetries retries. Exiting query loop." -ForegroundColor Red
        }

        # Write-Host "Hosts found with $($severity): $($ingestResults.aggregations."0".buckets.count)" -ForegroundColor Green
        Write-Host "Events found with $($severity): $($queryResults.hits.hits.count)" -ForegroundColor Green

        if($($queryResults.hits.hits.count) -ge 5000){
        Write-Host "Querying for more data since there are more than 5000 results."

        do {
            $sortValuesNeededToResumeSearching = $queryResults.hits.hits[-1].sort[0].ToString()
            $searchAfter = '"search_after": ['+$sortValuesNeededToResumeSearching+'],'
            $getAllHostsWithVulnsQueryBySeverityAllDocsSearchAfter = @"
            {
            "size" : 5000,
            "query": {
                "bool": {
                "must": [],
                "filter": [
                    {
                    "bool": {
                        "filter": [
                        {
                            "bool": {
                            "should": [
                                {
                                "query_string": {
                                    "fields": [
                                    "_index"
                                    ],
                                    "query": "$($Elasticsearch_Index_Name)"
                                }
                                }
                            ],
                            "minimum_should_match": 1
                            }
                        },
                        {
                            "bool": {
                            "must": [],
                            "filter": [
                                {
                                "bool": {
                                    "should": [
                                    {
                                        "term": {
                                        "vulnerability.severity": {
                                            "value": "$($severity)"
                                        }
                                        }
                                    }
                                    ],
                                    "minimum_should_match": 1
                                }
                                }
                            ],
                            "should": [],
                            "must_not": []
                            }
                        }$Elasticsearch_Custom_Filter
                        ]
                    }
                    },
                    {
                    "range": {
                        "@timestamp": {
                        "format": "strict_date_optional_time",
                        "gte": "$($dateAfter)",
                        "lte": "$($dateBefore)"
                        }
                    }
                    }
                ],
                "should": [],
                "must_not": []
                }
            },$searchAfter
            "pit": {
                "id":  "$pitID", 
                "keep_alive": "1m"
            },
            "sort" : [
                {"_shard_doc" : "asc"}
            ]
            }
"@
            $numErrors = 0
            $maxRetries = 5
            $retryCount = 0
            do {
                $reqOk = $false
                try {
                    $queryResults += Invoke-RestMethod "$Elasticsearch_URL/_search" -Method GET -Headers $global:AuthenticationHeaders -Body $getAllHostsWithVulnsQueryBySeverityAllDocsSearchAfter -ContentType "application/json" -SkipCertificateCheck -ConnectionTimeoutSeconds $Connection_Timeout -OperationTimeoutSeconds $Operation_Timeout
                    $reqOk = $true
                } catch {
                    if ($_.Exception.Message -match "timed out" -or $_.Exception.Message -match "timeout") {
                        $numErrors += 1
                        $retryCount += 1
                        Write-Host "Request timed out, retry $numErrors" -ForegroundColor Yellow
                        Start-Sleep -Seconds 1
                    } else {
                        Write-Host "Non-timeout error occurred: $($_.Exception.Message)" -ForegroundColor Red
                        break
                    }
                }
            } until ($reqOk -or $retryCount -ge $maxRetries)
            if (-not $reqOk) {
                Write-Host "Failed to retrieve data after $maxRetries retries. Exiting query loop." -ForegroundColor Red
            }
            Write-Host $queryResults.hits.hits.count

        } while ($queryResults[-1].hits.hits.count -ge 5000)
        }
        Write-Host "Finished paging through ($($queryResults.hits.hits.count)) results, moving along." -ForegroundColor Blue

        return $queryResults
    }

    # Get Host with No Vulnerabilities but still has scan data
    function getNoVulnData {
        param (
            $dateAfter,
            $dateBefore
        )
        
        # Query that Includes all hosts detected with no vulnerabilities.
        $getAllHostsWithNoVulnsQuery = @"
        {
            "aggs": {
              "0": {
                "terms": {
                  "field": "host.name",
                  "order": {
                    "1-bucket>1-metric": "desc"
                  },
                  "size": 7500
                },
                "aggs": {
                  "1-bucket": {
                    "filter": {
                      "bool": {
                        "must": [],
                        "filter": [
                          {
                            "bool": {
                              "must_not": {
                                "bool": {
                                  "should": [
                                    {
                                      "term": {
                                        "vulnerability.severity": {
                                          "value": "None"
                                        }
                                      }
                                    }
                                  ],
                                  "minimum_should_match": 1
                                }
                              }
                            }
                          }
                        ],
                        "should": [],
                        "must_not": []
                      }
                    },
                    "aggs": {
                      "1-metric": {
                        "cardinality": {
                          "field": "nessus.vulnerability.custom_hash"
                        }
                      }
                    }
                  },
                  "2-bucket": {
                    "filter": {
                      "bool": {
                        "must": [],
                        "filter": [
                          {
                            "bool": {
                              "should": [
                                {
                                  "term": {
                                    "vulnerability.severity": {
                                      "value": "None"
                                    }
                                  }
                                }
                              ],
                              "minimum_should_match": 1
                            }
                          }
                        ],
                        "should": [],
                        "must_not": []
                      }
                    },
                    "aggs": {
                      "2-metric": {
                        "cardinality": {
                          "field": "nessus.vulnerability.custom_hash"
                        }
                      }
                    }
                  },
                  "3-bucket": {
                    "filter": {
                      "bool": {
                        "must": [],
                        "filter": [
                          {
                            "bool": {
                              "should": [
                                {
                                  "exists": {
                                    "field": "vulnerability.report_id"
                                  }
                                }
                              ],
                              "minimum_should_match": 1
                            }
                          }
                        ],
                        "should": [],
                        "must_not": []
                      }
                    },
                    "aggs": {
                      "3-metric": {
                        "top_metrics": {
                          "metrics": {
                            "field": "vulnerability.report_id"
                          },
                          "size": 1,
                          "sort": {
                            "@timestamp": "desc"
                          }
                        }
                      }
                    }
                  }
                }
              }
            },
            "size": 0,
            "_source": {
              "excludes": []
            },
            "query": {
              "bool": {
                "must": [],
                "filter": [
                  {
                    "bool": {
                      "filter": [
                        {
                          "bool": {
                            "should": [
                              {
                                "query_string": {
                                  "fields": [
                                    "_index"
                                  ],
                                  "query": "$($Elasticsearch_Index_Name)"
                                }
                              }
                            ],
                            "minimum_should_match": 1
                          }
                        }$Elasticsearch_Custom_Filter
                      ]
                    }
                  },
                  {
                    "range": {
                      "@timestamp": {
                        "format": "strict_date_optional_time",
                        "gte": "$($dateAfter)",
                        "lte": "$($dateBefore)"
                      }
                    }
                  }
                ],
                "should": [],
                "must_not": []
              }
            }
          }
"@

        # Query Elastic for vulnerability information based on time frame
        Write-Host "Querying Elastic for hosts without vulnerabilities." -ForegroundColor Blue
        $ingestResults = Invoke-RestMethod $Elasticsearch_URL/$Elasticsearch_Index_Name/_search -Method GET -Headers $global:AuthenticationHeaders -Body $getAllHostsWithNoVulnsQuery -ContentType "application/json" -SkipCertificateCheck -ConnectionTimeoutSeconds $Connection_Timeout -OperationTimeoutSeconds $Operation_Timeout
        Write-Host "Results found: $($ingestResults.aggregations."0".buckets.count)" -ForegroundColor Green
        
        $hostWithNoVulnerabilities = $ingestResults.aggregations."0".buckets | Where-Object {$_."1-bucket".doc_count -eq 0}
        Write-Host "Hosts with 0 vulnerabilites found: $($hostWithNoVulnerabilities.count)" -ForegroundColor Green
        $hostWithNoVulnerabilitiesAggObject = [PSCustomObject]@{
        aggregations = [PSCustomObject]@{
            0 = [PSCustomObject]@{
            buckets = $hostWithNoVulnerabilities
            }
        }
        }
        return $hostWithNoVulnerabilitiesAggObject
    }

    # Create a clean and usable object for comparing
    function createCleanObject {
        param (
        $hostAndVulnData
        )
        # Create host / vulns object for comparison later
        $allHostAndVulnsParsed = @()
        
        Write-Host "Creating host / vulns object for comparison later" -ForegroundColor Blue
        $measure = Measure-Command {
        $vulnObjects = $($hostAndVulnData.count - 2)
        # Build cleaned object for those hosts that have vulnerabilities and other useful information
        $hostAndVulnData[0..$vulnObjects] | ForEach-Object {
            $_.hits.hits._source | ForEach-Object {
                # Host name
                $allHostAndVulnsParsed += [PSCustomObject]@{
                    host = [PSCustomObject]@{
                        ip = $_.host.ip
                        name = $_.host.name
                        os = [PSCustomObject]@{
                            family = $_.host.os.family
                            full = $_.host.os.full
                            name = $_.host.os.name
                            platform = $_.host.os.platform
                        }
                    }
                    nessus = [PSCustomObject]@{
                        cea_id = $_.nessus.'cea-id'
                        cisa_known_exploited = $_.nessus.'cisa-known-exploited'
                        cpe = $_.nessus.cpe
                        epss_score = $_.nessus.epss_score
                        exploited_by_malware = $_.nessus.exploited_by_malware
                        exploited_by_nessus = $_.nessus.exploited_by_nessus
                        exploit_available = $_.nessus.exploit_available
                        exploitability_ease = $_.nessus.exploitability_ease
                        risk_factor= $_.nessus.risk_factor
                        os_confidence = $_.nessus.os_confidence
                        plugin = [PSCustomObject]@{
                            name = $_.nessus.plugin.name
                            script_version = $_.nessus.plugin.script_version
                            type = $_.nessus.plugin.type
                        }
                        synopsis = $_.nessus.synopsis
                        system_type = $_.nessus.system_type
                        vpr_score = $_.nessus.vpr_score
                        vulnerability = [PSCustomObject]@{
                            custom_hash = $_.nessus.vulnerability.custom_hash
                        }
                    }
                    vulnerability = [PSCustomObject]@{
                        id = @($_.vulnerability.id)
                        category = $_.vulnerability.category
                        severity = $_.vulnerability.severity
                        report_id = $_.vulnerability.report_id
                    }
                }
            }
        }

        # Build object for those hosts that have have 0 vulnerabilities
        $hostAndVulnData[-1] | ForEach-Object {
            $_.aggregations."0".buckets | ForEach-Object {
                # Host name
                $allHostAndVulnsParsed += [PSCustomObject]@{
                    host = [PSCustomObject]@{
                        name = $_.key
                    }
                    vulnerability = [PSCustomObject]@{
                        report_id = $_."3-bucket"."3-metric".top.metrics.'vulnerability.report_id'
                    }
                }
            }
        }

        }

        Write-Host "Time to complete in minutes: $($measure.TotalMinutes)" -ForegroundColor Yellow
        
        return $allHostAndVulnsParsed
    }

    # Function to compare scans
    function compareObjects {
        param (
        $oldHostVulns,
        $currentHostVulns
        )
        
        # Object to be added to hosts with no vulnerabilities
        $noVulnDetected = [PSCustomObject]@{
        nessus = [PSCustomObject]@{
            state = "no_vuln_detected"
        }
        }

        if("" -eq $currentHostVulns.nessus.vulnerability.custom_hash -or $null -eq $currentHostVulns.nessus.vulnerability.custom_hash){
            #$currentHostVulns.nessus.vulnerability.custom_hash = "no_vuln_detected" # Make this enrich.nessus.state?
            $currentHostVulns | Add-Member -NotePropertyName "enrich" -NotePropertyValue  $noVulnDetected
        }

        if("" -eq $oldHostVulns.nessus.vulnerability.custom_hash -or $null -eq $oldHostVulns.nessus.vulnerability.custom_hash){
            #$oldHostVulns.nessus.vulnerability.custom_hash = "no_vuln_detected" # Make this enrich.nessus.state?
            $oldHostVulns | Add-Member -NotePropertyName "enrich" -NotePropertyValue  $noVulnDetected
        }

        # Remove any $null objects to ensure the compare works
        $currentHostVulnsOnly = @()
        $currentHostVulnsOnly = $currentHostVulns | Where-Object {$null -ne $_.nessus.vulnerability.custom_hash -or $_.enrich.nessus.state -eq "no_vuln_detected"}
        
        $oldHostVulnsOnly = @()
        $oldHostVulnsOnly = $oldHostVulns | Where-Object {$null -ne $_.nessus.vulnerability.custom_hash -or $_.enrich.nessus.state -eq "no_vuln_detected"}

        if($null -ne $currentHostVulnsOnly -and $null -ne $oldHostVulnsOnly){

            $comparedObjects = Compare-Object -ReferenceObject $currentHostVulnsOnly -DifferenceObject $oldHostVulnsOnly -IncludeEqual -Property {$_.nessus.vulnerability.custom_hash} -PassThru
            $combinedVulnsOnly = @()
            $combinedVulnsOnly += $currentHostVulnsOnly | Where-Object {$null -ne $_.SideIndicator}
            $combinedVulnsOnly += $oldHostVulnsOnly | Where-Object {$null -ne $_.SideIndicator}

            # Set enrich state, event created, tags, and other objects for adding to document for enrichment
            function setState {
                param(
                $state
                )
                $enrich = [PSCustomObject]@{
                    nessus = [PSCustomObject]@{
                        current_scan_date = $currentScanDate
                        reference_scan_date = $referenceScanDate
                        days_between_scans = $((Get-Date $currentScanDate) - (Get-Date $referenceScanDate)).TotalDays
                        state = if($state -eq "Unpatched"){
                            "Unpatched"
                        }elseif($state -eq "New"){
                            "New"
                        }elseif($state -eq "Patched"){
                            "Patched"
                        }elseif($state-eq "No Changes"){
                            "No Changes"
                        }else{$null}
                    }
                }
                return $enrich
            }

            function setEventCreated {
                    $eventCreated = [PSCustomObject]@{
                    created = $(Get-Date -Format "o" -AsUTC)
                }
                return $eventCreated
            }
            
            $combinedVulnsOnly | ForEach-Object {
                if("=>" -in $_.SideIndicator){
                    Write-Debug "Differences found! $combinedVulnsOnly"
                }
                # Check to see if te host went for 0 to 1+ vulns or the other way around so null values can properly handled.
                if("<=" -eq $_.SideIndicator){
                    if($_.enrich.nessus.state -eq "no_vuln_detected"){
                        # Host went from having no vulnerabilities to some vulnerabilities.
                        Write-Debug "Host went from no vulnerabilities to some vulnerabilities!"
                        $_ | Add-Member -NotePropertyName "message" -NotePropertyValue "New vulnerabilities detected on host when previously there were none."
                    }else{
                        # Add affliated state and message to reflect findings to object.
                        $_ | Add-Member -NotePropertyName "enrich" -NotePropertyValue $(setState "New")
                        $_ | Add-Member -NotePropertyName "message" -NotePropertyValue "Vulnerabilities detected on current and old scans."
                    }
                }elseif("=>" -eq $_.SideIndicator){
                    if($_.enrich.nessus.state -eq "no_vuln_detected"){
                        # Host went from having some vulnerabilities to no vulnerabilities.
                        Write-Debug "Host went from some vulnerabilities to no vulnerabilities!"
                        $_ | Add-Member -NotePropertyName "message" -NotePropertyValue "No vulnerabilities detected on host when previously there were some."
                    }else{
                        # Add state and message to reflect findings.
                        $_ | Add-Member -NotePropertyName "enrich" -NotePropertyValue $(setState "Patched")
                        $_ | Add-Member -NotePropertyName "message" -NotePropertyValue "Vulnerabilities detected on current and old scans."
                    }
                }elseif("==" -eq $_.SideIndicator ){
                    Write-Debug "No changes to host. Found 0 vulnerabilites on current and old scans.";
                    if($_.enrich.nessus.state -eq "no_vuln_detected"){
                        $_ | Add-Member -NotePropertyName "enrich" -NotePropertyValue $(setState "No Changes") -Force
                        $_ | Add-Member -NotePropertyName "message" -NotePropertyValue "No vulnerabilities detected on current or old scans."  
                    }else{
                        $_ | Add-Member -NotePropertyName "enrich" -NotePropertyValue $(setState "Unpatched")
                        $_ | Add-Member -NotePropertyName "message" -NotePropertyValue "Vulnerabilities detected on current and old scans."
                    }
                }
            }

            # Add metadata to all documents
            $combinedVulnsOnly | Add-Member -NotePropertyName "@timestamp" -NotePropertyValue $currentScanDate
            $combinedVulnsOnly | Add-Member -NotePropertyName "event" -NotePropertyValue $(setEventCreated)
            $combinedVulnsOnly | Add-Member -NotePropertyName "tags" -NotePropertyValue @("Vulnerability Summarization")

            #Compare-Object -ReferenceObject $oldHostVulns -DifferenceObject $currentHostVulns -IncludeEqual -Property {$_.nessus.vulnerability.custom_hash}
        }else{
            Write-Host "Failed to compare. One of the compared objects was likely null. Please investigate." -ForegroundColor Red
        }

        return $combinedVulnsOnly
    }

    # Fields to contain from today: @timestamp, host.name, host.ip, nessus.vulnerability.custom_hash, nessus.plugin.id, destination.port, network.transport, vulnerability.id, vulnerability.module
    function generateDates {
        param (
            $customDate
        )

        # Use en-US culture to ensure MM/dd/yyyy parsing always works
        $culture = [System.Globalization.CultureInfo]::GetCultureInfo('en-US')

        if ($customDate) {
            # Parse date explicitly using en-US regardless of OS locale
            $dateParsed = [datetime]::Parse($customDate, $culture)

            # Set current start date of 12 AM in UTC based on day requested
            $dateAfter = Get-Date $dateParsed -Hour 0 -Minute 0 -Second 0 -Millisecond 0 -AsUTC -Format "o"
            # Set current end date of day requested in UTC
            $dateBefore = Get-Date $dateParsed -Hour 23 -Minute 59 -Second 59 -Millisecond 0 -AsUTC -Format "o"
        }
        else {
            # Default behavior if no date is passed
            $dateAfter = Get-Date -Hour 0 -Minute 0 -Second 0 -Millisecond 0 -AsUTC -Format "o"
            $dateBefore = Get-Date -AsUTC -Format "o"
        }
        
        return $dateAfter, $dateBefore
    }

    # Compare scan time from current versus old
    function compareCurrentVsOld {
        param (
        $currentVulnsIn,
        $oldVulnsIn,
        $currentScanDate,
        $referenceScanDate
        )

        $hostVulnerabilitySummary = @()
        $missingHostVulnerabilitySummary = @()
        # Count missing and found hosts
        $missingHosts = 0
        Write-Host "Comparing current vulns to old vulns and storing them into the summary object. This could take awhile, please wait." -ForegroundColor Cyan
        $measure = Measure-Command {
        $uniqueHosts = ""
        $uniqueHosts = ($currentVulnsIn.host.name | Sort-Object -Unique)

        $uniqueHosts | ForEach-Object {
            $currentHostToCheck = $_
            Write-Debug "Building $currentHostToCheck vulnerability summary."
            $currentHostVulns = @()
            $currentHostVulns = $currentVulnsIn | Where-Object {$_.host.name -eq $currentHostToCheck}
            $oldHostVulns = @()
            $oldHostVulns = $oldVulnsIn | Where-Object {$_.host.name -eq $currentHostToCheck}
            if($null -ne $oldHostVulns -and $null -ne $currentHostVulns){
            $diff = compareObjects -currentHostVulns $currentHostVulns -oldHostVulns $oldHostVulns
            $hostVulnerabilitySummary += $diff
            }else{# TO DO - Send full object for comparison later, not just the minimal one
            Write-Debug "Host not found in past results: $currentHostToCheck"
            $missingHosts++
            
            # Build out host list to query back further.
            $missingHostVulnerabilitySummary += $currentHostVulns
            }
        }
        }

        Write-Host "Time to complete in minutes: $($measure.TotalMinutes)" -ForegroundColor Yellow
        Write-Debug "Events found for hosts that were not found in past scans to compare: $missingHosts"

        return $hostVulnerabilitySummary, $missingHostVulnerabilitySummary
    }

    # Aggregate vulnerability scan data for Critical, High, Medium, Low and None to prevent bucket overflow.
    function aggregateAllVulnerabilityScanData {
        param (
        $dateAfter,
        $dateBefore
        )
        Write-Host "Going to query and aggregate all results for comparison analysis between $(Get-Date $dateAfter) and $(Get-Date $dateBefore)." -ForegroundColor Blue
        
        $measure = Measure-Command {

        $aggregates = @()
        $aggregates += getVulnData -dateAfter $dateAfter -dateBefore $dateBefore -severity "Critical"
        $aggregates += getVulnData -dateAfter $dateAfter -dateBefore $dateBefore -severity "High"
        $aggregates += getVulnData -dateAfter $dateAfter -dateBefore $dateBefore -severity "Medium"
        $aggregates += getVulnData -dateAfter $dateAfter -dateBefore $dateBefore -severity "Low"
        $aggregates += getNoVulnData -dateAfter $dateAfter -dateBefore $dateBefore

        }

        Write-Host "Time to complete in minutes: $($measure.TotalMinutes)" -ForegroundColor Yellow
        
        return $aggregates
    }

    # Final Compare and Ingest
    function finalCompareAndIngest {
        param (
        $currentScanDate,
        $referenceScanDate
        )

        $compareResults = compareCurrentVsOld -currentVulns $global:currentVulns -oldVulns $oldVulns -currentScanDate $currentScanDate -referenceScanDate $referenceScanDate

        Write-Host "Events with vulnerabilities in past scans: $($compareResults[0].Count)" -ForegroundColor "Magenta"
        Write-Host "Events with missing hosts with vulnerabilities in past scans: $($compareResults[1].Count)" -ForegroundColor "Magenta"

        # Ingest vulnerability summary from what has been found so far
        if($compareResults[0]){
        $hashToIngest = @()
        $compareResults[0] | ForEach-Object {
            $obj = $_ | ConvertTo-Json -Depth 10 -Compress
            $hashToIngest += "{`"create`":{ } }`r`n$obj`r`n"
        }
        
        $numErrors = 0
        do {
            $reqOk=$false
            try {
                $ingestResults = Invoke-RestMethod $Remote_Elasticsearch_URL/$Remote_Elasticsearch_Index_Name/_bulk -Method POST -Headers $global:AuthenticationHeadersRemote -Body $hashToIngest -ContentType "application/x-ndjson; charset=utf-8" -SkipCertificateCheck -ConnectionTimeoutSeconds $Connection_Timeout -OperationTimeoutSeconds $Operation_Timeout
                $reqOk=$true
            } catch {
                $numErrors += 1
                Write-Host "Request timed out, retry $numErrors" -ForegroundColor Yellow
                Start-Sleep -Seconds 1
            }
        } until ($reqOk)
        
        if($ingestResults.errors -ne "True"){
            Write-Host "Results ingested: $($ingestResults.items.count)" -ForegroundColor "Green"
        }else{
            Write-Host "Errors found while ingesting. Writing error to ingest_errors.json." -ForegroundColor "Red"
            $ingestResults | ConvertTo-Json -Depth 100 | Out-File all_results.json -Append
            $errors = $($ingestResults.items.create | Where-Object {$_.status -ne 201}) 
            if($null -ne $errors){
                $($ingestResults.items.create | Where-Object {$_.status -ne 201})  | ConvertTo-Json -Depth 100 | Out-File ingest_errors.json -Append
            }
            Write-Debug $ingestResults 
        }
        }

        # Store missing results into a variable to search again later
        $global:currentVulns = $compareResults[1]
    }

    function customExcludeFilterByScan {
        param (
            $scansToFilter,
            $scanFilterType
        )

        # Take scan names and place them in a should or should not match query
        if($scanFilterType -eq "include"){
            $filterType = "must"
        } elseif($scanFilterType -eq "exclude"){
            $filterType = "must_not"
        } else {
            Write-Host "$scanFilterType not a valid option - using include instead."
            $filterType = "must"
        }
        $scansFilter = $scansToFilter | Foreach-Object {
        @"
                            {
                                "bool": {
                                    "should": [
                                        {
                                            "term": {
                                                "vulnerability.report_id": {
                                                    "value": "$_"
                                                }
                                            }
                                        }
                                    ],
                                    "minimum_should_match": 1
                                }
                            }
"@
        }
        # If there is more than one scan name, join them together with a comma to be used in the larger query.
        $excludeShouldMustNot = $scansFilter -join ",`n"

        $filterByScanQuery = @"
        ,
        {
            "bool": {
                "$filterType": {
                    "bool": {
                        "should": [
                            $excludeShouldMustNot
                        ],
                        "minimum_should_match": 1
                    }
                }
            }
        }
"@

        return $filterByScanQuery
    }
    ### Compare Scans Feature Functions /\ /\ /\

    function Invoke-Vulnerability_Summarization {
        param (
            $Elasticsearch_URL,
            $Elasticsearch_Index_Name,
            $Elasticsearch_Api_Key,
            $Elasticsearch_Scan_Filter,
            $Elasticsearch_Scan_Filter_Type,
            $Nessus_Base_Comparison_Scan_Date,
            $Remote_Elasticsearch_URL,
            $Remote_Elasticsearch_Index_Name,
            $Remote_Elasticsearch_Api_Key
        )
        if ($Elasticsearch_URL -ne "https://127.0.0.1:9200") {
            Write-Host "Using the URL you provided for Elastic: $Elasticsearch_URL" -ForegroundColor Green
        } else {
            Write-Host "Running script with default localhost Elasticsearch URL ($Elasticsearch_URL)." -ForegroundColor Yellow
        }
        # Nessus User Authenitcation Variables for Elastic
        if ($Elasticsearch_API_Key) {
            Write-Host "Using the Api Key you provided." -ForegroundColor Green
        } else {
            Write-Host "Elasticsearch API Key Required! Go here if you don't know how to obtain one - https://www.elastic.co/guide/en/elasticsearch/reference/current/security-api-create-api-key.html" -ForegroundColor "Red"
            break
        }

        $global:AuthenticationHeaders = @{Authorization = "$Elasticsearch_Custom_Authentication_Header $Elasticsearch_API_Key"}
        $global:AuthenticationHeadersRemote = @{"Authorization" = "$Remote_Elasticsearch_Custom_Authentication_Header $Remote_Elasticsearch_Api_Key"}
    
        # Force lookback time in days to be an integer for iterations use case
        $Look_Back_Time_In_Days = [int]$Look_Back_Time_In_Days
        $Look_Back_Iterations = [int]$Look_Back_Iterations
        if($null -ne $Elasticsearch_Scan_Filter){
            $Elasticsearch_Custom_Filter = customExcludeFilterByScan -scansToFilter $Elasticsearch_Scan_Filter -scanFilterType $Elasticsearch_Scan_Filter_Type
        }else{
            $Elasticsearch_Custom_Filter = $null
        }

        if($null -ne $Nessus_Base_Comparison_Scan_Date){
            $dates = generateDates -customDate $Nessus_Base_Comparison_Scan_Date
        }else{
            Write-Host "Nessus Scan Date for the latest scan you want to compare is required. Using today: $(Get-Date -Format M/dd/yyyy)"
            $Nessus_Base_Comparison_Scan_Date = $(Get-Date -Format M/dd/yyyy)
            $dates = generateDates -customDate $Nessus_Base_Comparison_Scan_Date
        }

        Write-Host "Querying $Elasticsearch_URL with $Elasticsearch_Index_Name as the source for the day $Nessus_Base_Comparison_Scan_Date and ingesting summary data into $Remote_Elasticsearch_URL with the index of $Remote_Elasticsearch_Index_Name." -ForegroundColor Yellow

        $dateAfter = $dates[0]
        $dateBefore = $dates[1]
        
        # Initial data shift
        $dateAfterShiftDays = dateShift -date $dateAfter -daysToShiftBackwards $Look_Back_Time_In_Days
        $dateBeforeShiftDays = dateShift -date $dateBefore -daysToShiftBackwards $Look_Back_Time_In_Days
        
        $todaysScanDataWithVulns = aggregateAllVulnerabilityScanData -dateAfter $dateAfter -dateBefore $dateBefore
        if($todaysScanDataWithVulns.hits.hits.count -gt 0){
            Write-Host "Results found, now checking shifted date for scan data."
            $shiftedScanDataWithVulns = aggregateAllVulnerabilityScanData -dateAfter $dateAfterShiftDays -dateBefore $dateBeforeShiftDays
        }else{
            Write-Host "No results found for initial scan comparison, moving along."
            return
        }
        
        # Create the objects that can be compared
        $global:currentVulns = @()
        Write-Host "Querying for current vulnerabilities." -ForegroundColor Green
        $global:currentVulns = createCleanObject $todaysScanDataWithVulns
        Write-Host "Querying for past vulnerabilities for comparison." -ForegroundColor Green
        $oldVulns = createCleanObject $shiftedScanDataWithVulns
        
        # Start Iterations at 1 instead of 0
        $iterations = 1

        # Set the lookback time and iterations for calculating shift.
        $Look_Back_Time_In_DaysPlusIterations = $($Look_Back_Time_In_Days*$iterations)

        do {
            # If oldVulns is greater than 0, then proceed
            if($oldVulns.Count -gt 0){
                Write-Host "$($oldVulns.Count) events found in last $Look_Back_Time_In_DaysPlusIterations day(s) data, comparing scans now." -ForegroundColor Blue
                
                # Finally compare and ingest the results
                finalCompareAndIngest -currentScanDate $dateAfter -referenceScanDate $dateAfterShiftDays
            
            }else{
                Write-Host "No events found in last $Look_Back_Time_In_DaysPlusIterations day(s). No data ingested. Moving along." -ForegroundColor Blue
            }

            # Increase iteration by 1 and decrement custom lookback iteration by 1
            $iterations++
            $Look_Back_Iterations--

            if($Look_Back_Iterations -gt 0){
            Write-Host "Shifting data for next iteration. There is potentially $Look_Back_Iterations interation(s) to go." -ForegroundColor Blue
            # Shift days based on look back time and iterations completed
            # Compute new shift iteration in days
            $Look_Back_Time_In_DaysPlusIterations = $($Look_Back_Time_In_Days*$iterations)
            $dateAfterShiftDays = dateShift -date $dateAfter -daysToShiftBackwards $Look_Back_Time_In_DaysPlusIterations
            $dateBeforeShiftDays = dateShift -date $dateBefore -daysToShiftBackwards $Look_Back_Time_In_DaysPlusIterations
            $shiftedScanDataWithVulns = aggregateAllVulnerabilityScanData -dateAfter $dateAfterShiftDays -dateBefore $dateBeforeShiftDays
            $oldVulns = createCleanObject $shiftedScanDataWithVulns
            }
        } while (
            $Look_Back_Iterations -gt 0
        )
    }

    ### Report Generation Feature
    function exportReportFromKibana {
        param (
            $Elasticsearch_Api_Key,
            $Kibana_Export_URL,
            $FileType
        )
        if ($null -eq $Elasticsearch_Api_Key -or "" -eq $Elasticsearch_Api_Key) {
            Write-Host "Elasticsearch API Key Required, exiting." -ForegroundColor Yellow
            exit
        }
        
        if ($null -eq $Kibana_Export_URL -or "" -eq $Kibana_Export_URL){
            Write-Host "No Export URL for PDF or CSV provided, exiting." -ForegroundColor Yellow
            exit
        }

        # Check to see if report export directory exists, if not, create it!
        if ($(Test-Path -Path "Kibana_Reports") -eq $false) {
            Write-Host "Could not find Kibana Reports so creating that directory now."
            New-Item "Kibana_Reports" -ItemType Directory
        }

        $kibanaHeader = @{"kbn-xsrf" = "true"; "Authorization" = "$Kibana_Custom_Authentication_Header $Elasticsearch_Api_Key"}

        Write-Host "Going to export report now, please wait." -ForegroundColor Yellow
        $result = Invoke-RestMethod -Method POST -Uri $Kibana_Export_URL -Headers $kibanaHeader -ContentType "application/json" -SkipCertificateCheck -MaximumRetryCount 10 -ConnectionTimeoutSeconds 120
        
        if($result.errors -or $null -eq $result){
                Write-Host "There was an error trying to export $Kibana_Export_URL" -ForegroundColor Red
                $result.errors
        }else{
            # Create a temporary file name for downloading the report
            $tempFile = $(Join-Path "Kibana_Reports" $(New-Guid).Guid)+".tmp" 
            # Extract Kibana URL from Export URL
            $Kibana_Export_URL -match "^.*(?=/api/reporting/generate)" | Out-Null
            # Check for Kibana URL match
            if($Matches){
                Write-Host "Kibana URL match found. Using $($Matches[0]) for the Kibana URL."
                $Kibana_URL = $Matches[0]
            }else{
                Write-Host "No Kibana URL Found, exiting." 
                exit
            }

            # Download report
            Invoke-WebRequest -Method Get -Uri "$Kibana_URL$($result.path)" -Headers $kibanaHeader -OutFile $tempFile -ConnectionTimeoutSeconds 120 -RetryIntervalSec 10 -MaximumRetryCount 60 -SkipCertificateCheck
            
            # Check if the file exists
            if (Test-Path $tempFile) {
                $decodedUrl = [System.Web.HttpUtility]::UrlDecode($Kibana_Export_URL)

                $titleRegex = "title:'([^']+)'"
                $titleMatch = [regex]::Match($decodedUrl, $titleRegex)
                if ($titleMatch.Success) {
                    $titleValue = $titleMatch.Groups[1].Value
                    # Get today's date in the desired format
                    $dateSuffix = Get-Date -Format "M_d_yyyy"
                    $tempFileName = "$($titleValue) - $($dateSuffix)$($FileType)"
                } else {
                    Write-Host "Title not found in the URL."
                }

                $tempFile = Rename-Item -Path $tempFile -NewName "$($tempFileName)" -PassThru
                $tempFile = $tempFile -Replace '\[','`[' -Replace '\]','`]'
                return $tempFile
            } else {
                Write-Host "Failed to export file."
            }       
        }
    }

    ### Remove Processed Nessus Scan Files
    function Invoke-Remove-Exported-Processed-Scans {
        param (
            $Remove_Processed_Scans_By_Days,
            $Nessus_File_Download_Location
        )
        Write-Host "Removing scans from $Nessus_File_Download_Location using the days to keep of: $Remove_Processed_Scans_By_Days." -ForegroundColor Blue
        try{
            Remove-Item $(Get-ChildItem -Path $Nessus_File_Download_Location -Filter *processed | Sort-Object -Property LastWriteTime | Where-Object {$_.LastWriteTime -lt $(get-date).AddDays(-$Remove_Processed_Scans_By_Days)})
            Write-Host "Scans have been removed!`nProcessed files that remain are: $((Get-ChildItem -Path $Nessus_File_Download_Location -Filter *processed).count)" -ForegroundColor Green
        }catch{
            Write-Host "Scans failed to get removed."
            $_
        }
    }

    ### Progress Bar
    function Show-ProgressBar {
        param(
            [int]$Current,
            [int]$Total,
            [string]$Activity = "Processing",
            [datetime]$StartTime = (Get-Date),
            [int]$BarLength = 30,
            [ConsoleColor]$Color = "Cyan"
        )

        if ($Total -eq 0) { return }

        $percent = [math]::Floor(($Current / $Total) * 100)
        $filledLength = [math]::Floor(($BarLength * $percent) / 100)
        $bar = ('█' * $filledLength) + ('░' * ($BarLength - $filledLength))

        $elapsed = (Get-Date) - $StartTime
        $eta = if ($Current -gt 0) {
            [timespan]::FromSeconds(($elapsed.TotalSeconds / $Current) * ($Total - $Current))
        } else { [timespan]::Zero }

        $progress = "$Activity`: [$bar] $percent% ($Current/$Total) | ETA: $($eta.ToString('hh\:mm\:ss'))"

        Write-Host -NoNewline "`r$progress" -ForegroundColor $Color
        if ($Current -eq $Total) { Write-Host "" }
    }

}

Process {

    while ($true -ne $finished) {
        # Show Menu if script was not provided the choice on execution using the Option_Selected variable
        if ($null -eq $Option_Selected) {
            Show-Menu
            $Option_Selected = Read-Host "Enter your choice"
        }
    
        switch ($Option_Selected) {
            '0' {
                Write-Host "You selected Option $option0"
                
                # Check for Elasticserach URL, Kibana Url, and elastic credentials
                if($null -eq $Elasticsearch_URL){
                    $Elasticsearch_URL = Read-Host "Elasticsearch URL (https://127.0.0.1:9200)"
                }
                if($null -eq $Kibana_URL){
                    $Kibana_URL = Read-Host "Kibana URL (https://127.0.0.1:5601)"
                }
                $Elasticsearch_Credentials = Get-Credential elastic
                $Elasticsearch_Credentials_Base64 = [convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($($Elasticsearch_Credentials.UserName+":"+$($Elasticsearch_Credentials.Password | ConvertFrom-SecureString -AsPlainText)).ToString()))
                $Kibana_Credentials = "Basic $Elasticsearch_Credentials_Base64"

                # Import Ingest Pipelines
                Write-Host "Setting up customized Nessus Elasticsearch ingest pipeline." -ForegroundColor Blue
                $pipelineName = "logs-nessus.vulnerability"
                $ingestPipelineJSON = Get-Content $(Join-Path .\pipelines -ChildPath "$pipelineName.json")
                $ingestPipelineURL = $Elasticsearch_URL+"/_ingest/pipeline/"+$pipelineName
                try { 
                    $createPipeline = Invoke-RestMethod -Method PUT -Uri $ingestPipelineURL -Body $ingestPipelineJSON -ContentType "application/json" -Credential $Elasticsearch_Credentials -AllowUnencryptedAuthentication -SkipCertificateCheck
                    if ($createPipeline.acknowledged -eq $true) {
                        Write-Host "The pipeline $pipelineName was successfully created!" -ForegroundColor Green
                        Write-Host "Check it out here: $Kibana_URL/app/management/ingest/ingest_pipelines/?pipeline=$pipelineName" -ForegroundColor Blue
                    } else {
                        Write-Host "Pipeline failed to get created."
                    }
                } catch {
                    Write-Host "Couldn't add ingest pipeline, likely because it already exists. Check kibana to see if the ingest pipeline $pipelineName exists." -ForegroundColor Yellow
                }

                # Import Index Template
                Write-Host "Setting up customized Elasticsearch index template." -ForegroundColor Blue
                $indexTemplateName = "logs-nessus.vulnerability"
                $indexTemplateNameJSON = Get-Content $(Join-Path .\templates -ChildPath "$indexTemplateName.json")
                $indexTemplateURL = $Elasticsearch_URL+"/_index_template/"+$indexTemplateName
                try { 
                    $createIndexTemplate = Invoke-RestMethod -Method PUT -Uri $indexTemplateURL -Body $indexTemplateNameJSON -ContentType "application/json" -Credential $Elasticsearch_Credentials -AllowUnencryptedAuthentication -SkipCertificateCheck
                    if ($createIndexTemplate.acknowledged -eq $true) {
                        Write-Host "The index template $indexTemplateName was successfully created!" -ForegroundColor Green
                        Write-Host "Check it out here: $Kibana_URL/app/management/data/index_management/templates/$indexTemplateName" -ForegroundColor Blue
                    } else {
                        Write-Host "Index template failed to get created."
                    }
                } catch {
                    Write-Host "Couldn't add index template, likely because it already exists. Check kibana to see if the ingest pipeline $indexTemplateName exists." -ForegroundColor Yellow
                }

                # Import Saved Objects
                $dashboardsPath = $(Resolve-Path .\dashboards).path
                $importSavedObjectsURL = $Kibana_URL+"/api/saved_objects/_import?overwrite=true"
                $kibanaHeader = @{"kbn-xsrf" = "true"; "Authorization" = "$Kibana_Credentials"}
                $allDashboardFiles = Get-ChildItem $dashboardsPath
                $allDashboardFiles | ForEach-Object {
                    $fileBytes = [System.IO.File]::ReadAllBytes($_.FullName);
                    $fileEnc = [System.Text.Encoding]::GetEncoding('UTF-8').GetString($fileBytes);
                    $boundary = [System.Guid]::NewGuid().ToString(); 
                    $LF = "`r`n";
    
                    $bodyLines = ( 
                        "--$boundary",
                        "Content-Disposition: form-data; name=`"file`"; filename=`"$($_.name)`"",
                        "Content-Type: application/octet-stream$LF",
                        $fileEnc,
                        "--$boundary--$LF" 
                    ) -join $LF
    
                    $result = Invoke-RestMethod -Method POST -Uri $importSavedObjectsURL -Headers $kibanaHeader -ContentType "multipart/form-data; boundary=`"$boundary`"" -Body $bodyLines -AllowUnencryptedAuthentication -SkipCertificateCheck
                    if($result.errors -or $null -eq $result){
                        Write-Host "There was an error trying to import $filename" -ForegroundColor Red
                        $result.errors
                    }
                    $fileBytes = $null
                    $fileEnc = $null
                    $boundary = $null
                    $result = $null
                }

                # Create Nessus API Key
                Write-Host "Setting up customized Nessus Elasticsearch API Key for writing to logs-nessus.vulnerability data stream." -ForegroundColor Blue
                $logsNessusAPIKey = "logs-nessus.vulnerability-api-key"
                $logsNessusAPIKeyJSON = Get-Content $(Join-Path .\templates -ChildPath "$logsNessusAPIKey.json")
                $createAPIKeyURL = $Elasticsearch_URL+"/_security/api_key"
                try { 
                    $createAPIKey = Invoke-RestMethod -Method PUT -Uri $createAPIKeyURL -Body $logsNessusAPIKeyJSON -ContentType "application/json" -Credential $Elasticsearch_Credentials -AllowUnencryptedAuthentication -SkipCertificateCheck
                    if ($createAPIKey.encoded) {
                        Write-Host "The Nessus API key was successfully created!" -ForegroundColor Green
                        Write-Host "Here is your encoded API Key that can be used to ingest your Nessus scan data into the $($createApiKey.name) data stream.`nStore in a safe place: $($createApiKey.encoded)"
                    } else {
                        Write-Host "API Key failed to get created." -ForegroundColor Yellow
                    }
                } catch {
                    Write-Host "API Key failed to get created. $_" -ForegroundColor Yellow
                }

                $finished = $true
                break
            }
            '1' {
                Write-Host "You selected Option $option1"
                
                # Check for Nessus Access and Nessus Secret Key and Prompt if not provided
                if($null -eq $Nessus_Access_Key){
                    $Nessus_Access_Key = Read-Host "Nessus Access Key"
                }
                if($null -eq $Nessus_Secret_Key){
                    $Nessus_Secret_Key = Read-Host "Nessus Secret Key"
                }

                Invoke-Exract_From_Nessus -Nessus_URL $Nessus_URL -Nessus_File_Download_Location $Nessus_File_Download_Location -Nessus_Access_Key $Nessus_Access_Key -Nessus_Secret_Key $Nessus_Secret_Key -Nessus_Source_Folder_Name $Nessus_Source_Folder_Name -Nessus_Archive_Folder_Name $Nessus_Archive_Folder_Name -Nessus_Export_Scans_From_Today $Nessus_Export_Scans_From_Today -Nessus_Export_Day $Nessus_Export_Day -Nessus_Export_Custom_Extended_File_Name_Attribute $Nessus_Export_Custom_Extended_File_Name_Attribute -Nessus_Export_All_Scan_History $Nessus_Export_All_Scan_History
                $finished = $true
                break
            }
            '2' {
                Write-Host "You selected Option $option2"

                # Check for Nessus XML File you wish to process
                if($null -eq $Nessus_XML_File){
                    $Nessus_XML_File = Read-Host "Nessus XML File (.nessus)"
                }

                # Check for Elasticsearch URL and API Keys and prompt if not provided
                if($null -eq $Elasticsearch_URL){
                    $Elasticsearch_URL = Read-Host "Elasticsearch URL (https://127.0.0.1:9200)"
                }
                if($null -eq $Elasticsearch_Api_Key){
                    $Elasticsearch_Api_Key = Read-Host "Elasticsearch API Key"
                }

                Invoke-Import_Nessus_To_Elasticsearch -Nessus_XML_File $Nessus_XML_File -Elasticsearch_URL $Elasticsearch_URL -Elasticsearch_Index_Name $Elasticsearch_Index_Name -Elasticsearch_API_Key $Elasticsearch_Api_Key
                
                if($Execute_Patch_Summarization -eq $true){
                    # Execute Patch Summarization after scans have been ingested
                    # Check for Elasticsearch URL and API Keys and prompt if not provided
                    Write-Host "Patch summarization option set to true, executing patch summary with lookback days of $Look_Back_Time_In_Days and iterations of $Look_Back_Iterations" -ForegroundColor Cyan
                    if($null -eq $Elasticsearch_URL){
                        $Elasticsearch_URL = Read-Host "Elasticsearch URL (https://127.0.0.1:9200)"
                    }
                    if($null -eq $Elasticsearch_Api_Key){
                        $Elasticsearch_Api_Key = Read-Host "Elasticsearch API Key"
                    }
                    
                    # Configure Remote Elasticsearch URL automatically to the same cluster that is provided for Elasticsearch URL / Index / API Key.
                    if($null -eq $Remote_Elasticsearch_URL){
                        $Remote_Elasticsearch_URL = $Elasticsearch_URL
                    }
                    if($null -eq $Remote_Elasticsearch_Index_Name){
                        $Remote_Elasticsearch_Index_Name = "$Elasticsearch_Index_Name-summary"
                    }
                    if($null -eq $Remote_Elasticsearch_Api_Key){
                        $Remote_Elasticsearch_Api_Key = $Elasticsearch_Api_Key
                    }

                    if($Nessus_Base_Comparison_Scan_Date.count -gt 1){
                        Write-Host "Multiple dates ($($Nessus_Base_Comparison_Scan_Date.count)) found! Running patch summary for each date."
                        $Nessus_Base_Comparison_Scan_Date | ForEach-Object {
                            $currentNessusScanDate = $_
                            Write-Host "Executing patch summary for date: $currentNessusScanDate"
                            Invoke-Vulnerability_Summarization -Elasticsearch_URL $Elasticsearch_URL -Elasticsearch_Index_Name $Elasticsearch_Index_Name -Elasticsearch_API_Key $Elasticsearch_Api_Key -Elasticsearch_Scan_Filter $Elasticsearch_Scan_Filter -Elasticsearch_Scan_Filter_Type $Elasticsearch_Scan_Filter_Type -Nessus_Base_Comparison_Scan_Date $currentNessusScanDate -Remote_Elasticsearch_URL $Remote_Elasticsearch_URL -Remote_Elasticsearch_Index_Name $Remote_Elasticsearch_Index_Name -Remote_Elasticsearch_Api_Key $Remote_Elasticsearch_Api_Key
                            Write-Host "Finished executing patch sumamry for date: $currentNessusScanDate. Moving along."
                        }
                    }else{
                        Invoke-Vulnerability_Summarization -Elasticsearch_URL $Elasticsearch_URL -Elasticsearch_Index_Name $Elasticsearch_Index_Name -Elasticsearch_API_Key $Elasticsearch_Api_Key -Elasticsearch_Scan_Filter $Elasticsearch_Scan_Filter -Elasticsearch_Scan_Filter_Type $Elasticsearch_Scan_Filter_Type -Nessus_Base_Comparison_Scan_Date $Nessus_Base_Comparison_Scan_Date -Remote_Elasticsearch_URL $Remote_Elasticsearch_URL -Remote_Elasticsearch_Index_Name $Remote_Elasticsearch_Index_Name -Remote_Elasticsearch_Api_Key $Remote_Elasticsearch_Api_Key
                    }

                    Write-Host "Vulnerability Summarization tool finished!" -ForegroundColor Green
                }

                # If Remove Processed Scans by Days is set, then execute as needed.
                if($null -ne $Remove_Processed_Scans_By_Days -and $null -ne $Nessus_File_Download_Location){
                    Invoke-Remove-Exported-Processed-Scans -Remove_Processed_Scans_By_Days $Remove_Processed_Scans_By_Days -Nessus_File_Download_Location $Nessus_File_Download_Location
                }

                $finished = $true
                break
            }
            '3' {
                Write-Host "You selected Option $option3"

                # Check for Elasticsearch URL and API Keys and prompt if not provided
                if($null -eq $Elasticsearch_URL){
                    $Elasticsearch_URL = Read-Host "Elasticsearch URL (https://127.0.0.1:9200)"
                }
                if($null -eq $Elasticsearch_Api_Key){
                    $Elasticsearch_Api_Key = Read-Host "Elasticsearch API Key"
                }
                if($null -eq $Nessus_File_Download_Location){
                    $Nessus_File_Download_Location = Read-Host "Nessus File Download Location (default - Nessus Exports)"
                }

                Invoke-Automate_Nessus_File_Imports -Nessus_File_Download_Location $Nessus_File_Download_Location -Elasticsearch_URL $Elasticsearch_URL -Elasticsearch_Index_Name $Elasticsearch_Index_Name -Elasticsearch_API_Key $Elasticsearch_Api_Key
                
                if($Execute_Patch_Summarization -eq $true){
                    # Execute Patch Summarization after scans have been ingested
                    # Check for Elasticsearch URL and API Keys and prompt if not provided
                    Write-Host "Patch summarization option set to true, executing patch summary with lookback days of $Look_Back_Time_In_Daysand iterations of $Look_Back_Iterations" -ForegroundColor Cyan
                    if($null -eq $Elasticsearch_URL){
                        $Elasticsearch_URL = Read-Host "Elasticsearch URL (https://127.0.0.1:9200)"
                    }
                    if($null -eq $Elasticsearch_Api_Key){
                        $Elasticsearch_Api_Key = Read-Host "Elasticsearch API Key"
                    }

                    # Configure Remote Elasticsearch URL automatically to the same cluster that is provided for Elasticsearch URL / Index / API Key.
                    if($null -eq $Remote_Elasticsearch_URL){
                        $Remote_Elasticsearch_URL = $Elasticsearch_URL
                    }
                    if($null -eq $Remote_Elasticsearch_Index_Name){
                        $Remote_Elasticsearch_Index_Name = "$Elasticsearch_Index_Name-summary"
                    }
                    if($null -eq $Remote_Elasticsearch_Api_Key){
                        $Remote_Elasticsearch_Api_Key = $Elasticsearch_Api_Key
                    }

                    if($Nessus_Base_Comparison_Scan_Date.count -gt 1){
                        Write-Host "Multiple dates ($($Nessus_Base_Comparison_Scan_Date.count)) found! Running patch summary for each date."
                        $Nessus_Base_Comparison_Scan_Date | ForEach-Object {
                            $currentNessusScanDate = $_
                            Write-Host "Executing patch summary for date: $currentNessusScanDate"
                            Invoke-Vulnerability_Summarization -Elasticsearch_URL $Elasticsearch_URL -Elasticsearch_Index_Name $Elasticsearch_Index_Name -Elasticsearch_API_Key $Elasticsearch_Api_Key -Elasticsearch_Scan_Filter $Elasticsearch_Scan_Filter -Elasticsearch_Scan_Filter_Type $Elasticsearch_Scan_Filter_Type -Nessus_Base_Comparison_Scan_Date $currentNessusScanDate -Remote_Elasticsearch_URL $Remote_Elasticsearch_URL -Remote_Elasticsearch_Index_Name $Remote_Elasticsearch_Index_Name -Remote_Elasticsearch_Api_Key $Remote_Elasticsearch_Api_Key
                            Write-Host "Finished executing patch sumamry for date: $currentNessusScanDate. Moving along."
                        }
                    }else{
                        Invoke-Vulnerability_Summarization -Elasticsearch_URL $Elasticsearch_URL -Elasticsearch_Index_Name $Elasticsearch_Index_Name -Elasticsearch_API_Key $Elasticsearch_Api_Key -Elasticsearch_Scan_Filter $Elasticsearch_Scan_Filter -Elasticsearch_Scan_Filter_Type $Elasticsearch_Scan_Filter_Type -Nessus_Base_Comparison_Scan_Date $Nessus_Base_Comparison_Scan_Date -Remote_Elasticsearch_URL $Remote_Elasticsearch_URL -Remote_Elasticsearch_Index_Name $Remote_Elasticsearch_Index_Name -Remote_Elasticsearch_Api_Key $Remote_Elasticsearch_Api_Key
                    }

                    Write-Host "Vulnerability Summarization tool finished!" -ForegroundColor Green
                }

                # If Remove Processed Scans by Days is set, then execute as needed.
                if($null -ne $Remove_Processed_Scans_By_Days -and $null -ne $Nessus_File_Download_Location){
                    Invoke-Remove-Exported-Processed-Scans -Remove_Processed_Scans_By_Days $Remove_Processed_Scans_By_Days -Nessus_File_Download_Location $Nessus_File_Download_Location
                }

                $finished = $true
                break
            }
            '4' {
                Write-Host "You selected Option $option4." -ForegroundColor Yellow
                
                # Check for Nessus Access and Nessus Secret Key and Prompt if not provided
                if($null -eq $Nessus_Access_Key){
                    $Nessus_Access_Key = Read-Host "Nessus Access Key"
                }
                if($null -eq $Nessus_Secret_Key){
                    $Nessus_Secret_Key = Read-Host "Nessus Secret Key"
                }

                # Check for Elasticsearch URL and API Keys and prompt if not provided
                if($null -eq $Elasticsearch_URL){
                    $Elasticsearch_URL = Read-Host "Elasticsearch URL (https://127.0.0.1:9200)"
                }
                if($null -eq $Elasticsearch_Api_Key){
                    $Elasticsearch_Api_Key = Read-Host "Elasticsearch API Key"
                }

                Invoke-Exract_From_Nessus -Nessus_URL $Nessus_URL -Nessus_File_Download_Location $Nessus_File_Download_Location -Nessus_Access_Key $Nessus_Access_Key -Nessus_Secret_Key $Nessus_Secret_Key -Nessus_Source_Folder_Name $Nessus_Source_Folder_Name -Nessus_Archive_Folder_Name $Nessus_Archive_Folder_Name -Nessus_Export_Scans_From_Today $Nessus_Export_Scans_From_Today -Nessus_Export_Day $Nessus_Export_Day -Nessus_Export_Custom_Extended_File_Name_Attribute $Nessus_Export_Custom_Extended_File_Name_Attribute

                Invoke-Automate_Nessus_File_Imports -Nessus_File_Download_Location $Nessus_File_Download_Location -Elasticsearch_URL $Elasticsearch_URL -Elasticsearch_Index_Name $Elasticsearch_Index_Name -Elasticsearch_API_Key $Elasticsearch_Api_Key

                if($Execute_Patch_Summarization -eq $true){
                    # Execute Patch Summarization after scans have been ingested
                    # Check for Elasticsearch URL and API Keys and prompt if not provided
                    Write-Host "Patch summarization option set to true, executing patch summary with lookback days of $Look_Back_Time_In_Days and iterations of $Look_Back_Iterations" -ForegroundColor Cyan
                    if($null -eq $Elasticsearch_URL){
                        $Elasticsearch_URL = Read-Host "Elasticsearch URL (https://127.0.0.1:9200)"
                    }
                    if($null -eq $Elasticsearch_Api_Key){
                        $Elasticsearch_Api_Key = Read-Host "Elasticsearch API Key"
                    }

                    # Configure Remote Elasticsearch URL automatically to the same cluster that is provided for Elasticsearch URL / Index / API Key.
                    if($null -eq $Remote_Elasticsearch_URL){
                        $Remote_Elasticsearch_URL = $Elasticsearch_URL
                    }
                    if($null -eq $Remote_Elasticsearch_Index_Name){
                        $Remote_Elasticsearch_Index_Name = "$Elasticsearch_Index_Name-summary"
                    }
                    if($null -eq $Remote_Elasticsearch_Api_Key){
                        $Remote_Elasticsearch_Api_Key = $Elasticsearch_Api_Key
                    }

                    if($Nessus_Base_Comparison_Scan_Date.count -gt 1){
                        Write-Host "Multiple dates ($($Nessus_Base_Comparison_Scan_Date.count)) found! Running patch summary for each date."
                        $Nessus_Base_Comparison_Scan_Date | ForEach-Object {
                            $currentNessusScanDate = $_
                            Write-Host "Executing patch summary for date: $currentNessusScanDate"
                            Invoke-Vulnerability_Summarization -Elasticsearch_URL $Elasticsearch_URL -Elasticsearch_Index_Name $Elasticsearch_Index_Name -Elasticsearch_API_Key $Elasticsearch_Api_Key -Elasticsearch_Scan_Filter $Elasticsearch_Scan_Filter -Elasticsearch_Scan_Filter_Type $Elasticsearch_Scan_Filter_Type -Nessus_Base_Comparison_Scan_Date $currentNessusScanDate -Remote_Elasticsearch_URL $Remote_Elasticsearch_URL -Remote_Elasticsearch_Index_Name $Remote_Elasticsearch_Index_Name -Remote_Elasticsearch_Api_Key $Remote_Elasticsearch_Api_Key
                            Write-Host "Finished executing patch sumamry for date: $currentNessusScanDate. Moving along."
                        }
                    }else{
                        Invoke-Vulnerability_Summarization -Elasticsearch_URL $Elasticsearch_URL -Elasticsearch_Index_Name $Elasticsearch_Index_Name -Elasticsearch_API_Key $Elasticsearch_Api_Key -Elasticsearch_Scan_Filter $Elasticsearch_Scan_Filter -Elasticsearch_Scan_Filter_Type $Elasticsearch_Scan_Filter_Type -Nessus_Base_Comparison_Scan_Date $Nessus_Base_Comparison_Scan_Date -Remote_Elasticsearch_URL $Remote_Elasticsearch_URL -Remote_Elasticsearch_Index_Name $Remote_Elasticsearch_Index_Name -Remote_Elasticsearch_Api_Key $Remote_Elasticsearch_Api_Key
                    }

                    Write-Host "Vulnerability Summarization tool finished!" -ForegroundColor Green
                }

                # If Remove Processed Scans by Days is set, then execute as needed.
                if($null -ne $Remove_Processed_Scans_By_Days -and $null -ne $Nessus_File_Download_Location){
                    Invoke-Remove-Exported-Processed-Scans -Remove_Processed_Scans_By_Days $Remove_Processed_Scans_By_Days -Nessus_File_Download_Location $Nessus_File_Download_Location
                }

                $finished = $true
                break
            }
            '5' {
                Write-Host "You selected Option $option5." -ForegroundColor Yellow
                Invoke-Purge_Processed_Hashes_List
                Invoke-Revert_Nessus_To_Processed_Rename $Nessus_File_Download_Location

                # If Remove Processed Scans by Days is set, then execute as needed.
                if($null -ne $Remove_Processed_Scans_By_Days -and $null -ne $Nessus_File_Download_Location){
                    Invoke-Remove-Exported-Processed-Scans -Remove_Processed_Scans_By_Days $Remove_Processed_Scans_By_Days -Nessus_File_Download_Location $Nessus_File_Download_Location
                }

                $finished = $true
                break
            }
            '6' {
                Write-Host "You selected Option $option6"

                # Check for Elasticsearch URL and API Keys and prompt if not provided
                if($null -eq $Elasticsearch_URL){
                    $Elasticsearch_URL = Read-Host "Elasticsearch URL (https://127.0.0.1:9200)"
                }
                if($null -eq $Elasticsearch_Api_Key){
                    $Elasticsearch_Api_Key = Read-Host "Elasticsearch API Key"
                }
                
                # Configure Remote Elasticsearch URL automatically to the same cluster that is provided for Elasticsearch URL / Index / API Key.
                if($null -eq $Remote_Elasticsearch_URL){
                    $Remote_Elasticsearch_URL = $Elasticsearch_URL
                }
                if($null -eq $Remote_Elasticsearch_Index_Name){
                    $Remote_Elasticsearch_Index_Name = "$Elasticsearch_Index_Name-summary"
                }
                if($null -eq $Remote_Elasticsearch_Api_Key){
                    $Remote_Elasticsearch_Api_Key = $Elasticsearch_Api_Key
                }

                if($Nessus_Base_Comparison_Scan_Date.count -gt 1){
                    Write-Host "Multiple dates ($($Nessus_Base_Comparison_Scan_Date.count)) found! Running patch summary for each date."
                    $Nessus_Base_Comparison_Scan_Date | ForEach-Object {
                        $currentNessusScanDate = $_
                        Write-Host "Executing patch summary for date: $currentNessusScanDate"
                        Invoke-Vulnerability_Summarization -Elasticsearch_URL $Elasticsearch_URL -Elasticsearch_Index_Name $Elasticsearch_Index_Name -Elasticsearch_API_Key $Elasticsearch_Api_Key -Elasticsearch_Scan_Filter $Elasticsearch_Scan_Filter -Elasticsearch_Scan_Filter_Type $Elasticsearch_Scan_Filter_Type -Nessus_Base_Comparison_Scan_Date $currentNessusScanDate -Remote_Elasticsearch_URL $Remote_Elasticsearch_URL -Remote_Elasticsearch_Index_Name $Remote_Elasticsearch_Index_Name -Remote_Elasticsearch_Api_Key $Remote_Elasticsearch_Api_Key
                        Write-Host "Finished executing patch summary for date: $currentNessusScanDate. Moving along."
                    }
                }else{
                    Invoke-Vulnerability_Summarization -Elasticsearch_URL $Elasticsearch_URL -Elasticsearch_Index_Name $Elasticsearch_Index_Name -Elasticsearch_API_Key $Elasticsearch_Api_Key -Elasticsearch_Scan_Filter $Elasticsearch_Scan_Filter -Elasticsearch_Scan_Filter_Type $Elasticsearch_Scan_Filter_Type -Nessus_Base_Comparison_Scan_Date $Nessus_Base_Comparison_Scan_Date -Remote_Elasticsearch_URL $Remote_Elasticsearch_URL -Remote_Elasticsearch_Index_Name $Remote_Elasticsearch_Index_Name -Remote_Elasticsearch_Api_Key $Remote_Elasticsearch_Api_Key
                }

                Write-Host "Vulnerability Summarization tool finished!" -ForegroundColor Green
                $finished = $true
                break
            }
            '7' {
                Write-Host "You selected Option $option7"

                if($null -eq $Elasticsearch_Api_Key){
                    $Elasticsearch_Api_Key = Read-Host "Elasticsearch API Key"
                }

                $reportedItemFiles = @()

                if($null -eq $Kibana_Export_CSV_URL){
                    Write-Host "No URL for CSV export was provide so not exporting a CSV report. Use the -Kibana_Export_URL followed by the Kibana_Export_CSV_URL when running this report option." -ForegroundColor Yellow
                }elseif ($Kibana_Export_CSV_URL){
                    # If CSV URL found for export then try to export the CSV report.
                    Write-Host "URL for CSV export found ($Kibana_Export_CSV_URL)! Attempting export of CSV report."
                    $CSVfile = exportReportFromKibana -Elasticsearch_Api_Key $Elasticsearch_Api_Key -Kibana_Export_URL $Kibana_Export_CSV_URL -FileType ".csv"
                    $reportedItemFiles += $CSVfile
                }

                if($null -eq $Kibana_Export_PDF_URL){
                    Write-Host "No URL for PDF export was provide so not exporting a PDF report. Use the -Kibana_Export_URL followed by the Kibana_Export_PDF_URL when running this report option." -ForegroundColor Yellow
                }elseif ($Kibana_Export_PDF_URL){
                    # If PDF URL found for export then try to export the PDF report.
                    Write-Host "URL for PDF export found ($Kibana_Export_PDF_URL)! Attempting export of PDF report."
                    $PDFfile = exportReportFromKibana -Elasticsearch_Api_Key $Elasticsearch_Api_Key -Kibana_Export_URL $Kibana_Export_PDF_URL -FileType ".pdf"
                    $reportedItemFiles += $PDFfile
                }

                if($null -eq $Email_To){
                    $Email_To = Read-Host "Recipient Email"
                }

                if($Email_From -and $Email_To -and $Email_SMTP_Server){
                    # Send reported items via Email
                    try{
                        # Add CC recipient if found
                        if($Email_CC){
                            Send-MailMessage -From $Email_From -To ($Email_To -split ",") -Cc ($Email_CC -split ",") -Body $Email_Body -Subject $Email_Subject -SmtpServer $Email_SMTP_Server -Attachments $reportedItemFiles
                        }else{
                            Send-MailMessage -From $Email_From -To ($Email_To -split ",") -Body $Email_Body -Subject $Email_Subject -SmtpServer $Email_SMTP_Server -Attachments $reportedItemFiles
                        }
                        # Otherwise, send it
                        Write-Host "Files sent to email:`n$($($(Get-Item $reportedItemFiles).Name) | Join-String -Separator ", `n")" -ForegroundColor Green
                    }catch{
                        $_
                        "Email was not able to be sent - Check the file size of that attachments and make sure your email gateway can send messages that large."
                    }
                }else{
                    Write-Host "Not all variables were supplied to send an email:"
                    Write-Host "Email_From : $Email_From"
                    Write-Host "Email_To : $Email_To"
                    Write-Host "Email_SMTP_Server : $Email_SMTP_Server"
                    Write-Host "Email_CC (Optional) : $Email_CC"
                }

                # Clean up files after generation
                # $reportedItemFiles | ForEach-Object {
                #    Remove-Item $_
                #}

                $finished = $true
                break
            }
            '8' {
                Write-Host "You selected Option $option8." -ForegroundColor Yellow
                # If Remove Processed Scans by Days is set, then execute as needed.
                if($null -ne $Remove_Processed_Scans_By_Days -and $null -ne $Nessus_File_Download_Location){
                    Invoke-Remove-Exported-Processed-Scans -Remove_Processed_Scans_By_Days $Remove_Processed_Scans_By_Days -Nessus_File_Download_Location $Nessus_File_Download_Location
                }
                $finished = $true
                break
            }
            '10' {
                Write-Host "You selected Option $option10." -ForegroundColor Yellow
                if($null -eq $Nessus_Scan_Name_To_Delete_Oldest_Scan){
                    $Nessus_Scan_Name_To_Delete_Oldest_Scan = Read-Host "Nessus Scan Name to Delete Oldest Scan"
                }
                Invoke-Purge_Oldest_Scan_From_History $Nessus_Scan_Name_To_Delete_Oldest_Scan
                $finished = $true
                break
            }
            'Q' {
                Write-Host "You selected quit, exiting." -ForegroundColor Yellow
                $finished = $true
                break
            }
            default {
                Write-Host "Invalid choice. Please select a valid option."
            }
        }
    }

}

End {
    Write-Host "This is the end. Thanks for using this script!" -ForegroundColor Blue
    $finished = $null
}
