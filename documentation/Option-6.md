🔗 Back to [📖Overview](./Overview.md)

### 6️⃣ **Compare Scan Data Between Scans and Export Results into Elasticsearch (Patch Summarization)**

Compares vulnerability data between two or more Nessus scans and exports the results into Elasticsearch. This option is designed for **Patch Summarization** — providing a clear summary of what vulnerabilities have been remediated, newly discovered, or changed between scan periods.

#### What This Option Does

- **Compares Nessus scan data** using selected historical scan dates and look-back parameters.
- **Summarizes changes in vulnerabilities** (new, remediated, persistent) between scans.
- **Exports summarized results** into a dedicated summary index in Elasticsearch (e.g., `logs-nessus.vulnerability-summary`).
- **Supports custom filtering** for scan names and types (include/exclude).
- **Supports remote Elasticsearch ingest** for summary results.

#### Variables Available for Option 6

| Variable Name                                 | Default Value                                | Description                                                                                               |
|-----------------------------------------------|----------------------------------------------|-----------------------------------------------------------------------------------------------------------|
| **Elasticsearch_URL**                         | `"https://127.0.0.1:9200"`                   | URL for your Elasticsearch instance.                                                                      |
| **Elasticsearch_Index_Name**                  | `"logs-nessus.vulnerability"`                | Primary index for Nessus vulnerability data.                                                              |
| **Elasticsearch_Api_Key**                     | `$null`                                      | Elasticsearch API key for authentication.                                                                 |
| **Elasticsearch_Custom_Authentication_Header**| `"ApiKey"`                                   | Custom text for the Elasticsearch authentication header (e.g., `"Bearer"` for SearchGuard).               |
| **Remote_Elasticsearch_URL**                  | `$null`                                      | Optional: URL for remote Elasticsearch cluster to send summary results.                                   |
| **Remote_Elasticsearch_Index_Name**           | `"logs-nessus.vulnerability-summary"`         | Optional: Index name for remote cluster summary results.                                                  |
| **Remote_Elasticsearch_Api_Key**              | `$null`                                      | Optional: API key for remote cluster summary ingest.                                                      |
| **Remote_Elasticsearch_Custom_Authentication_Header** | `"ApiKey"`                          | Custom text for remote Elasticsearch authentication header.                                               |
| **Connection_Timeout**                        | `0`                                          | How long to wait for a connection to start (seconds).                                                     |
| **Operation_Timeout**                         | `0`                                          | How long to wait for connection data (seconds).                                                           |
| **Nessus_Base_Comparison_Scan_Date**          | (none)                                       | Date(s) for base scan(s) to compare against, e.g., `@("3/5/2024","3/6/2024")`.                           |
| **Look_Back_Time_In_Days**                    | `7`                                          | Number of days to look back for comparison.                                                               |
| **Look_Back_Iterations**                      | `3`                                          | Number of iterations to look back for hosts not found in first lookback.                                  |
| **Elasticsearch_Scan_Filter**                 | `$null`                                      | Array of scan names to include/exclude in Patch Summarization.                                            |
| **Elasticsearch_Scan_Filter_Type**            | `"include"`                                  | Set to `"include"` or `"exclude"` for scan filtering.                                                     |
| **Configuration_File_Path**                   | `$null`                                      | Optional path to a JSON configuration file.                                                               |

#### Default Values Example

```powershell
.\Invoke-PowerNessie.ps1 `
  -Elasticsearch_URL "https://127.0.0.1:9200" `
  -Elasticsearch_Index_Name "logs-nessus.vulnerability" `
  -Elasticsearch_Api_Key "<YourApiKey>" `
  -Nessus_Base_Comparison_Scan_Date "03/15/2024" `
  -Look_Back_Time_In_Days 7
```

#### 📝 Use Cases

**Compare two scans 7 days apart, summarizing patch activity:**

```powershell
.\Invoke-PowerNessie.ps1 `
  -Elasticsearch_URL "https://my-elastic-instance.local:9200" `
  -Elasticsearch_Index_Name "logs-nessus.vulnerability" `
  -Elasticsearch_Api_Key "<YourApiKey>" `
  -Nessus_Base_Comparison_Scan_Date "03/15/2024" `
  -Look_Back_Time_In_Days 7
```

**Compare multiple scans and filter to specific scan names:**

```powershell
.\Invoke-PowerNessie.ps1 `
  -Nessus_Base_Comparison_Scan_Date @("03/01/2024","03/15/2024") `
  -Elasticsearch_Scan_Filter @("scan1", "scan2") `
  -Elasticsearch_Scan_Filter_Type "include"
```

**Export summary results to a remote Elasticsearch cluster and index:**

```powershell
.\Invoke-PowerNessie.ps1 `
  -Nessus_Base_Comparison_Scan_Date "03/15/2024" `
  -Remote_Elasticsearch_URL "https://remote-es.company.com:9200" `
  -Remote_Elasticsearch_Index_Name "logs-nessus.vulnerability-summary" `
  -Remote_Elasticsearch_Api_Key "<RemoteApiKey>"
```

---

#### Using a Configuration File

You can also use a JSON configuration file to set all the variables at once:

**configuration.json**
```json
{
    "Elasticsearch_URL": "https://my-elastic-instance.local:9200",
    "Elasticsearch_Index_Name": "logs-nessus.vulnerability",
    "Elasticsearch_Api_Key": "<YourApiKey>",
    "Elasticsearch_Bulk_Import_Batch_Size": 5000,
    "Nessus_Base_Comparison_Scan_Date": ["03/15/2024"],
    "Look_Back_Time_In_Days": 7,
    "Elasticsearch_Scan_Filter": ["scan1", "scan2"],
    "Elasticsearch_Scan_Filter_Type": "include",
    "Remote_Elasticsearch_URL": "https://remote-es.company.com:9200",
    "Remote_Elasticsearch_Index_Name": "logs-nessus.vulnerability-summary",
    "Remote_Elasticsearch_Api_Key": "<RemoteApiKey>"
}
```

Run the script:

```powershell
.\Invoke-PowerNessie.ps1 -Configuration_File_Path "configuration.json"
```

- Patch Summarization provides actionable reporting on vulnerability status changes between scans.
- Exported summary results are stored in a separate index for easy tracking and lifecycle management.
- Supports both local and remote Elasticsearch clusters for summary ingest.
- Filtering and look-back controls help tailor comparison for your environment.

**Differences from Other Options:**

- **Does not export or ingest Nessus files directly.**
- **Operates on existing scan data already in Elasticsearch.**
- **Designed specifically for summarizing and reporting scan data changes.**

Use Option 6 to generate and export patch summary reports—tracking vulnerability remediation and changes between Nessus scan cycles.


🔗 Back to [📖Overview](./Overview.md)
