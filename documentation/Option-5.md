🔗 Back to [📖Overview](./Overview.md)

### 5️⃣ **Purge Processed Hashes List**

Removes the list of hashes that track which Nessus files have already been ingested by Power-Nessie. This "reset" option enables reprocessing and re-ingesting of previously imported `.nessus` files during future runs, making it useful for troubleshooting, testing, or intentionally reloading scan data.

#### What This Option Does

- **Deletes the `ProcessedHashes.txt` file** in your configured Nessus file download directory.
- The next ingestion run will treat all existing `.nessus` files as "new" and process them again.
- Useful for scenarios where you need to re-ingest all scans, such as index resets, ingestion troubleshooting, or changing index mapping in Elasticsearch.

#### Variables Available for Option 5

| Variable Name                         | Default Value           | Description                                                  |
|---------------------------------------|-------------------------|--------------------------------------------------------------|
| **Nessus_File_Download_Location**     | `"Nessus_Exports"`      | Directory containing Nessus files and the `ProcessedHashes.txt` file. |
| **Configuration_File_Path**           | `$null`                 | Optional path to a JSON configuration file.                  |

*Note: Most users will not need to specify variables unless using a custom directory or config file.*

#### Default Values Example

```powershell
.\Invoke-PowerNessie.ps1 -Option_Selected 5
```

Or, specifying a custom location:

```powershell
.\Invoke-PowerNessie.ps1 -Option_Selected 5 -Nessus_File_Download_Location "D:\NessusExports"
```

#### 📝 Use Case

**Reset processed hashes to allow re-ingestion of all scans:**

```powershell
.\Invoke-PowerNessie.ps1 -Option_Selected 5
```

**Using a configuration file:**

You can also use a JSON configuration file to set all the variables at once:

**configuration.json**
```json
{
    "Nessus_File_Download_Location": "D:\\NessusExports"
}
```

Run the script:

```powershell
.\Invoke-PowerNessie.ps1 -Option_Selected 5 -Configuration_File_Path "configuration.json"
```

- After running Option 5, all `.nessus` files in the download location will be eligible for re-ingestion.
- Use with caution: re-ingesting scans may result in duplicated data in Elasticsearch if not handled appropriately.
- No effect on archived scans, index templates, or Elasticsearch — only the tracking file is removed.

**Differences from Other Options:**

- **Does not export or ingest scan files.**
- **Does not interact with Elasticsearch or Nessus directly.**
- **Simply removes tracking of processed files to enable reprocessing.**

Use Option 5 to reset your Power-Nessie ingestion state, allowing you to reprocess all scan files in your download directory.

🔗 Back to [📖Overview](./Overview.md)
