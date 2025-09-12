🔗 Back to [📖Overview](./Overview.md)

### 3️⃣ **Ingest All Nessus Files from a Specified Directory into Elasticsearch (Optional - Patch Summarization upon Completion)**

Automates the bulk ingestion of all unprocessed Nessus `.nessus` files from a specified directory into your Elasticsearch cluster. This enables efficient, repeatable import of vulnerability data for analysis in Kibana. Optionally, you can enable Patch Summarization to compare scan results and highlight remediated vulnerabilities.

#### What This Option Does

- **Looks in a specified local directory** for all Nessus files (`*.nessus`) not yet ingested
- **Checks a hash list** to avoid reprocessing files already imported
- **Bulk imports parsed vulnerability data into Elasticsearch**
- **Renames processed files** to indicate successful ingestion (adds `.processed` extension)
- **Records ingestion durations** for performance tracking
- **(Optional) Performs Patch Summarization** after ingest to compare with previous scans and summarize changes

#### Variables Available for Option 3

| Variable Name                         | Default Value                          | Description                                                                                         |
|---------------------------------------|----------------------------------------|-----------------------------------------------------------------------------------------------------|
| **Nessus_File_Download_Location**     | `"Nessus_Exports"`                     | Directory containing Nessus files to ingest.                                                        |
| **Elasticsearch_URL**                 | `"https://127.0.0.1:9200"`             | URL for your Elasticsearch instance.                                                                |
| **Elasticsearch_Index_Name**          | `"logs-nessus.vulnerability"`          | Elasticsearch index to store Nessus scan results.                                                   |
| **Elasticsearch_Api_Key**             | `$null`                                | Elasticsearch API key for authentication.                                                           |
| **Elasticsearch_Custom_Authentication_Header** | `"ApiKey"`                    | Custom text for the Elasticsearch authentication header (e.g., `"Bearer"` for SearchGuard).         |
| **Connection_Timeout**                | `0`                                    | How long to wait for a connection to start (seconds).                                               |
| **Operation_Timeout**                 | `0`                                    | How long to wait for connection data (seconds).                                                     |
| **Execute_Patch_Summarization**       | `"false"`                              | Set to `"true"` to enable Patch Summarization after ingest.                                         |
| **Nessus_Base_Comparison_Scan_Date**  | `$null`                                | Date(s) for historical scans to compare against, e.g., `@("3/5/2024","3/6/2024")`.                 |
| **Look_Back_Time_In_Days**            | `7`                                    | Number of days to look back for comparison.                                                         |
| **Look_Back_Iterations**              | `3`                                    | Number of iterations to look back for hosts not found in first lookback.                            |
| **Elasticsearch_Scan_Filter**         | `$null`                                | Array of scan names to include/exclude in Patch Summarization.                                      |
| **Elasticsearch_Scan_Filter_Type**    | `"include"`                            | Set to `"include"` or `"exclude"` for scan filtering.                                               |
| **Remote_Elasticsearch_URL**          | `$null`                                | Optional: URL for remote Elasticsearch cluster for summary results.                                 |
| **Remote_Elasticsearch_Index_Name**   | `$null`                                | Optional: Index name for remote cluster summary results.                                            |
| **Remote_Elasticsearch_Api_Key**      | `$null`                                | Optional: API key for remote cluster summary ingest.                                                |
| **Remote_Elasticsearch_Custom_Authentication_Header** | `"ApiKey"`                  | Custom text for remote Elasticsearch authentication header.                                         |
| **Configuration_File_Path**           | `$null`                                | Optional path to a JSON configuration file.                                                         |
| **Remove_Processed_Scans_By_Days**    | `$null`                                | Optionally remove `.processed` scans by file write time. Set to `0` removes all, `1` keeps last day.|

#### Default Values Example

```powershell
.\Invoke-PowerNessie.ps1 `
  -Nessus_File_Download_Location "Nessus_Exports" `
  -Elasticsearch_URL "https://127.0.0.1:9200" `
  -Elasticsearch_Index_Name "logs-nessus.vulnerability" `
  -Elasticsearch_Api_Key "<YourApiKey>"
```

#### 📝 Use Cases

**Bulk ingest all Nessus files from a custom directory:**

```powershell
.\Invoke-PowerNessie.ps1 `
  -Nessus_File_Download_Location "D:\NessusExports" `
  -Elasticsearch_URL "https://my-elastic-instance.local:9200" `
  -Elasticsearch_Index_Name "logs-nessus.vulnerability" `
  -Elasticsearch_Api_Key "<YourApiKey>"
```

**Bulk ingest and run Patch Summarization comparing to a specific week in the past:**

```powershell
.\Invoke-PowerNessie.ps1 `
  -Nessus_File_Download_Location "D:\NessusExports" `
  -Elasticsearch_Api_Key "<YourApiKey>" `
  -Execute_Patch_Summarization "true" `
  -Nessus_Base_Comparison_Scan_Date "03/15/2024" `
  -Look_Back_Time_In_Days 7
```

**Remove all `.processed` scans after ingest:**

```powershell
.\Invoke-PowerNessie.ps1 `
  -Nessus_File_Download_Location "D:\NessusExports" `
  -Elasticsearch_Api_Key "<YourApiKey>" `
  -Remove_Processed_Scans_By_Days 0
```

#### Using a Configuration File

You can also use a JSON configuration file to set all the variables at once:

**configuration.json**
```json
{
    "Nessus_File_Download_Location": "D:\\NessusExports",
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

- Only unprocessed files (`*.nessus` not listed in the hash file) are ingested.
- Ingestion is tracked and `.nessus` files are renamed to `.processed` upon completion.
- Patch Summarization is optional and powerful for tracking remediated vulnerabilities and scan changes.
- Supports cleanup of processed files based on age for disk management.
- Remote cluster options make it easy to send summary results to a different Elasticsearch instance.
- Supports both direct CLI argument passing and configuration via JSON file.

**Differences from Options 0, 1, and 2:**

- **Processes multiple files** in a directory, not just one (Option 2) or export from Nessus (Option 1).
- **Uses a hash list and file renaming** to prevent duplicate ingest and track processed files.
- **Remove_Processed_Scans_By_Days** allows for automated cleanup of old scan files.

Use Option 3 to efficiently ingest batches of Nessus files into Elasticsearch, perform Patch Summarization, and automate cleanup for continuous vulnerability management.

🔗 Back to [📖Overview](./Overview.md)
