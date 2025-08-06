🔗 Back to [📖Overview](./Overview.md)

### 4️⃣ **Export and Ingest Nessus Files into Elasticsearch (Optional - Patch Summarization upon Completion)**

Performs a full end-to-end workflow by **exporting Nessus scan files from your Nessus scanner**, saving them locally, and then **ingesting them into Elasticsearch** for analysis and visualization. Optionally, Patch Summarization can be enabled to compare scan results and highlight remediated vulnerabilities in the ingested data.

#### What This Option Does

- **Connects to your Nessus scanner via API using provided credentials**
- **Exports scan files** from the specified Nessus folder (default: "My Scans") to a local directory
- **Optionally moves scans to an archive folder** within Nessus after export
- **Ingests all exported Nessus files** into Elasticsearch (bulk import)
- **Renames processed files** with `.processed` extension to track completed ingestion
- **Records ingestion durations** for performance tracking
- **(Optional) Performs Patch Summarization** after ingest to compare with previous scans and summarize changes

#### Variables Available for Option 4

| Variable Name                                   | Default Value                        | Description                                                                                                                  |
|-------------------------------------------------|--------------------------------------|------------------------------------------------------------------------------------------------------------------------------|
| **Nessus_URL**                                  | `"https://127.0.0.1:8834"`           | Nessus scanner API endpoint URL.                                                                                             |
| **Nessus_File_Download_Location**               | `"Nessus_Exports"`                   | Local directory for saving exported Nessus files and ingest source.                                                          |
| **Nessus_Access_Key**                           | `$null`                              | Nessus API access key.                                                                                                       |
| **Nessus_Secret_Key**                           | `$null`                              | Nessus API secret key.                                                                                                       |
| **Nessus_Source_Folder_Name**                   | `"My Scans"`                         | Nessus folder containing scans to export.                                                                                    |
| **Nessus_Archive_Folder_Name**                  | `$null`                              | Nessus folder to move scans for archival after export. If not set, scans are not moved.                                      |
| **Nessus_Export_Scans_From_Today**              | `$null`                              | Set to `"true"` to export only scans from today.                                                                             |
| **Nessus_Export_Day**                           | `$null`                              | Specify a date (`MM/DD/YYYY`) to export scans from that day.                                                                 |
| **Nessus_Export_Custom_Extended_File_Name_Attribute** | `$null`                        | String appended to exported filenames for uniqueness (e.g., `"_scanner1"`).                                                  |
| **Nessus_Export_All_Scan_History**              | `$null`                              | Set to `"true"` to export all scan history, not just the latest scan.                                                        |
| **Elasticsearch_URL**                           | `"https://127.0.0.1:9200"`           | URL for your Elasticsearch instance.                                                                                        |
| **Elasticsearch_Index_Name**                    | `"logs-nessus.vulnerability"`        | Elasticsearch index to store Nessus scan results.                                                                            |
| **Elasticsearch_Api_Key**                       | `$null`                              | Elasticsearch API key for authentication.                                                                                    |
| **Elasticsearch_Custom_Authentication_Header**   | `"ApiKey"`                           | Custom text for the Elasticsearch authentication header (e.g., `"Bearer"` for SearchGuard).                                  |
| **Execute_Patch_Summarization**                 | `"false"`                            | Set to `"true"` to enable Patch Summarization after ingest.                                                                 |
| **Nessus_Base_Comparison_Scan_Date**            | `$null`                              | Date(s) for historical scans to compare against, e.g., `@("3/5/2024","3/6/2024")`.                                          |
| **Look_Back_Time_In_Days**                      | `7`                                  | Number of days to look back for comparison.                                                                                  |
| **Look_Back_Iterations**                        | `3`                                  | Number of iterations to look back for hosts not found in first lookback.                                                     |
| **Elasticsearch_Scan_Filter**                   | `$null`                              | Array of scan names to include/exclude in Patch Summarization.                                                              |
| **Elasticsearch_Scan_Filter_Type**              | `"include"`                          | Set to `"include"` or `"exclude"` for scan filtering.                                                                       |
| **Remote_Elasticsearch_URL**                    | `$null`                              | Optional: URL for remote Elasticsearch cluster for summary results.                                                          |
| **Remote_Elasticsearch_Index_Name**             | `$null`                              | Optional: Index name for remote cluster summary results.                                                                     |
| **Remote_Elasticsearch_Api_Key**                | `$null`                              | Optional: API key for remote cluster summary ingest.                                                                         |
| **Remote_Elasticsearch_Custom_Authentication_Header** | `"ApiKey"`                    | Custom text for remote Elasticsearch authentication header.                                                                  |
| **Configuration_File_Path**                     | `$null`                              | Optional path to a JSON configuration file to load all variables.                                                            |
| **Remove_Processed_Scans_By_Days**              | `$null`                              | Optionally remove `.processed` scans by file write time. Set to `0` removes all, `1` keeps last day.                        |

#### Default Values Example

```powershell
.\Invoke-PowerNessie.ps1 `
  -Nessus_URL "https://127.0.0.1:8834" `
  -Nessus_File_Download_Location "Nessus_Exports" `
  -Nessus_Access_Key "<YourAccessKey>" `
  -Nessus_Secret_Key "<YourSecretKey>" `
  -Nessus_Source_Folder_Name "My Scans" `
  -Elasticsearch_URL "https://127.0.0.1:9200" `
  -Elasticsearch_Index_Name "logs-nessus.vulnerability" `
  -Elasticsearch_Api_Key "<YourApiKey>"
```

#### 📝 Use Cases

**Export all scans from Nessus and ingest them into Elasticsearch, appending a scanner ID to each filename:**

```powershell
.\Invoke-PowerNessie.ps1 `
  -Nessus_URL "https://scanner1.local:8834" `
  -Nessus_File_Download_Location "D:\NessusExports" `
  -Nessus_Access_Key "<YourAccessKey>" `
  -Nessus_Secret_Key "<YourSecretKey>" `
  -Nessus_Source_Folder_Name "My Scans" `
  -Nessus_Export_Custom_Extended_File_Name_Attribute "_scanner1" `
  -Elasticsearch_URL "https://my-elastic-instance.local:9200" `
  -Elasticsearch_Index_Name "logs-nessus.vulnerability" `
  -Elasticsearch_Api_Key "<YourApiKey>"
```

**Export only today's scans and ingest, moving them to an archive folder in Nessus after export:**

```powershell
.\Invoke-PowerNessie.ps1 `
  -Nessus_URL "https://scanner2.company.com:8834" `
  -Nessus_File_Download_Location "C:\NessusToday" `
  -Nessus_Access_Key "<YourAccessKey>" `
  -Nessus_Secret_Key "<YourSecretKey>" `
  -Nessus_Source_Folder_Name "My Scans" `
  -Nessus_Archive_Folder_Name "Archive-Ingested" `
  -Nessus_Export_Scans_From_Today "true" `
  -Elasticsearch_URL "https://my-elastic-instance.local:9200" `
  -Elasticsearch_Index_Name "logs-nessus.vulnerability" `
  -Elasticsearch_Api_Key "<YourApiKey>"
```

**Run Patch Summarization after export and ingest:**

```powershell
.\Invoke-PowerNessie.ps1 `
  -Nessus_URL "https://127.0.0.1:8834" `
  -Nessus_File_Download_Location "Nessus_Exports" `
  -Nessus_Access_Key "<YourAccessKey>" `
  -Nessus_Secret_Key "<YourSecretKey>" `
  -Elasticsearch_Api_Key "<YourApiKey>" `
  -Execute_Patch_Summarization "true" `
  -Nessus_Base_Comparison_Scan_Date "03/15/2024" `
  -Look_Back_Time_In_Days 7
```

#### Using a Configuration File

You can also use a JSON configuration file to set all the variables at once:

**configuration.json**
```json
{
    "Nessus_URL": "https://scanner1.local:8834",
    "Nessus_File_Download_Location": "D:\\NessusExports",
    "Nessus_Access_Key": "<YourAccessKey>",
    "Nessus_Secret_Key": "<YourSecretKey>",
    "Nessus_Source_Folder_Name": "My Scans",
    "Nessus_Archive_Folder_Name": "Archive-Ingested",
    "Nessus_Export_Custom_Extended_File_Name_Attribute": "_scanner1",
    "Elasticsearch_URL": "https://my-elastic-instance.local:9200",
    "Elasticsearch_Index_Name": "logs-nessus.vulnerability",
    "Elasticsearch_Api_Key": "<YourApiKey>",
    "Execute_Patch_Summarization": "true",
    "Nessus_Base_Comparison_Scan_Date": ["03/15/2024"],
    "Look_Back_Time_In_Days": 7,
    "Remove_Processed_Scans_By_Days": 0
}
```

Run the script:

```powershell
.\Invoke-PowerNessie.ps1 -Configuration_File_Path "configuration.json"
```

- Provides full-cycle Nessus scan export and ingest automation.
- Ensures only new scans are ingested by renaming processed files and tracking with hash lists.
- Patch Summarization is optional and powerful for tracking remediated vulnerabilities and scan changes.
- Supports cleanup of processed files based on age for disk management.
- Remote cluster options make it easy to send summary results to a different Elasticsearch instance.
- Supports both direct CLI argument passing and configuration via JSON file.

**Differences from Options 0, 1, 2, and 3:**

- **Combines both export and ingest** steps for a complete automation workflow.
- **Handles full batch operations:** export, ingest, track, rename, and summarize.
- **Ideal for scheduled or repeated Nessus scan workflows** where both export and ingest are required.

Use Option 4 for a seamless, automated workflow to export Nessus scans and import them into Elasticsearch, with optional Patch Summarization for vulnerability management and compliance tracking.

🔗 Back to [📖Overview](./Overview.md)
