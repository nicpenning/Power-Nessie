🔗 Back to [📖Overview](./Overview.md)

### 2️⃣ **Ingest a Single Nessus File into Elasticsearch (Optional - Patch Summarization upon Completion)**

Imports a single Nessus `.nessus` XML file into your Elasticsearch cluster, making vulnerability data immediately searchable and visualizable in Kibana. Optionally, you can enable Patch Summarization to compare scan results and highlight remediated vulnerabilities.

#### What This Option Does

- **Parses a specified Nessus XML file**
- **Bulk imports parsed vulnerability data into Elasticsearch**
- **Uses your configured Elasticsearch index and API key for secure ingest**
- **(Optional) Performs Patch Summarization** to compare scan data against historical scans and summarize changes

#### Variables Available for Option 2

| Variable Name                         | Default Value                          | Description                                                                                         |
|---------------------------------------|----------------------------------------|-----------------------------------------------------------------------------------------------------|
| **Nessus_XML_File**                   | (none)                                 | Path to the Nessus XML file to ingest.                                                              |
| **Elasticsearch_URL**                 | `"https://127.0.0.1:9200"`             | URL for your Elasticsearch instance.                                                                |
| **Elasticsearch_Index_Name**          | `"logs-nessus.vulnerability"`          | Elasticsearch index to store Nessus scan results.                                                   |
| **Elasticsearch_Api_Key**             | `$null`                                | Elasticsearch API key for authentication.                                                           |
| **Elasticsearch_Custom_Authentication_Header** | `"ApiKey"`                    | Custom text for the Elasticsearch authentication header (e.g., `"Bearer"` for SearchGuard).         |
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

#### Default Values Example

```powershell
.\Invoke-PowerNessie.ps1 `
  -Nessus_XML_File "C:\NessusExports\scan1.nessus" `
  -Elasticsearch_URL "https://127.0.0.1:9200" `
  -Elasticsearch_Index_Name "logs-nessus.vulnerability" `
  -Elasticsearch_Api_Key "<YourApiKey>"
```

#### 📝 Use Cases

**Ingest a scan file with default settings:**

```powershell
.\Invoke-PowerNessie.ps1 `
  -Nessus_XML_File "C:\NessusExports\scan1.nessus" `
  -Elasticsearch_Api_Key "<YourApiKey>"
```

**Ingest a scan file and run Patch Summarization comparing to a specific week in the past:**

```powershell
.\Invoke-PowerNessie.ps1 `
  -Nessus_XML_File "C:\NessusExports\scan1.nessus" `
  -Elasticsearch_Api_Key "<YourApiKey>" `
  -Execute_Patch_Summarization "true" `
  -Nessus_Base_Comparison_Scan_Date "03/15/2024" `
  -Look_Back_Time_In_Days 7
```

**Filter Patch Summarization to only include selected scan names:**

```powershell
.\Invoke-PowerNessie.ps1 `
  -Nessus_XML_File "C:\NessusExports\scan1.nessus" `
  -Elasticsearch_Api_Key "<YourApiKey>" `
  -Execute_Patch_Summarization "true" `
  -Elasticsearch_Scan_Filter @("scan1","scan2") `
  -Elasticsearch_Scan_Filter_Type "include"
```

#### Using a Configuration File
You can also use a JSON configuration file to set all the variables at once:

**configuration.json**
```json
{
    "Nessus_XML_File": "C:\\NessusExports\\scan1.nessus",
    "Elasticsearch_URL": "https://my-elastic-instance.local:9200",
    "Elasticsearch_Index_Name": "logs-nessus.vulnerability",
    "Elasticsearch_Api_Key": "<YourApiKey>",
    "Execute_Patch_Summarization": "true",
    "Nessus_Base_Comparison_Scan_Date": ["03/15/2024"],
    "Look_Back_Time_In_Days": 7,
    "Elasticsearch_Scan_Filter": ["scan1", "scan2"],
    "Elasticsearch_Scan_Filter_Type": "include"
}
```

Run the script:

```powershell
.\Invoke-PowerNessie.ps1 -Configuration_File_Path "configuration.json"
```

- You must provide a valid Nessus XML file and Elasticsearch API key.
- Patch Summarization is optional but powerful for tracking remediated vulnerabilities and scan changes.
- Supports both direct argument passing and configuration via JSON file.
- Remote cluster options make it easy to send summary results to a different Elasticsearch instance.

Use Option 2 to quickly ingest a single Nessus scan into Elasticsearch, with optional Patch Summarization to highlight vulnerability remediation and scan changes over time.

🔗 Back to [📖Overview](./Overview.md)
