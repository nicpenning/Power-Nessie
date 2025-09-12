💫 This is an overview of what you can do with this project along with more details and use cases for using Power-Nessie.

## 🛠️ Requirements
1. Get Nessus API Keys [Nessus Documentation](https://docs.tenable.com/nessus/Content/GenerateAnAPIKey.htm).
2. Download the latest release from [here](https://github.com/nicpenning/Power-Nessie/releases/latest) and extract to a directory of your choosing.
- Alternatively, to use the latest branch, clone this project to the directory of your choosing: 
```PowerShell
git clone https://github.com/nicpenning/Power-Nessie.git
```
3. Setup Elasticsearch : Step by step instruction 👉🏻 [Option 0](./Option-0.md)
4. Run the Invoke-Power-Nessie.ps1 script supplying required variables for your use case and using the guided options.
5. Watch the Nessus files get downloaded and then ingested into Elasticsearch - Resolve any issues along the way / Ask questions [here](https://github.com/nicpenning/Power-Nessie/discussions).

To fully automate the ingestion on a daily, weekly, or monthly schedule you could create a scheduled task to have the Invoke-Power-Nessie.ps1 script kick off as needed.

## 📃 Options
Invoking this script provides an assortment of menu options you can use for your use case!

```PowerShell
.\Invoke-Power-Nessie.ps1
```
```
PowerShell version 7 detected, great!
No configuration file supplied, using provided command line arguments.
Welcome to the PowerShell script that can export and ingest Nessus scan files into an Elastic stack!
What would you like to do?
0. Setup Elasticsearch and Kibana.
1. Export Nessus files.
2. Ingest a single Nessus file into Elasticsearch (Optional - Patch summarization upon completion).
3. Ingest all Nessus files from a specified directory into Elasticsearch (Optional - Patch summarization upon completion).
4. Export and Ingest Nessus files into Elasticsearch (Optional - Patch summarization upon completion).
5. Purge processed hashes list (Remove list of what files have already been processed).
6. Compare scan data between scans and export results into Elasticsearch (Patch summarization).
7. Export PDF or CSV Report from Kibana dashboard and optionally send via Email (Advanced Options - Copy POST URL).
8. Remove processed scans from local Nessus file download directory (May be used optionally with -Remove_Processed_Scans_By_Days).

Q. Quit

Version 1.7.0
Enter your choice:
```

⚙️This script uses inline variables or a config file. See [Configuration-Priority](https://github.com/nicpenning/Power-Nessie/blob/main/documentation/Configuration-Priority.md) for more details.

### 0️⃣ **Setup Elasticsearch and Kibana.**

Configures your Elastic stack (Elasticsearch & Kibana) to properly ingest and visualize Nessus scan data prior to importing scans. This is a critical first step to ensure your vulnerability data is ready for analysis and reporting.

👉🏻[Option 0 Full documentation and use cases here.](./Option-0.md)

### 1️⃣ **Export Nessus Files.**

Automates the extraction of Nessus scan files from your Nessus scanner and moves them to a local directory for further processing or archival. Optionally, the exported scans can be moved to an archive folder within Nessus.

👉🏻[Option 1 Full documentation and use cases here.](./Option-1.md)

### 2️⃣ **Ingest a Single Nessus File into Elasticsearch (Optional - Patch Summarization upon Completion)**

Imports a single Nessus `.nessus` XML file into your Elasticsearch cluster, making vulnerability data immediately searchable and visualizable in Kibana. Optionally, you can enable Patch Summarization to compare scan results and highlight remediated vulnerabilities.

👉🏻[Option 2 Full documentation and use cases here.](./Option-2.md)

### 3️⃣ **Ingest All Nessus Files from a Specified Directory into Elasticsearch (Optional - Patch Summarization upon Completion)**

Automates the bulk ingestion of all unprocessed Nessus `.nessus` files from a specified directory into your Elasticsearch cluster. Optionally, you can enable Patch Summarization to compare scan results and highlight remediated vulnerabilities.

👉🏻[Option 3 Full documentation and use cases here.](./Option-3.md)

### 4️⃣ **Export and Ingest Nessus Files into Elasticsearch (Optional - Patch Summarization upon Completion)**

Performs a full end-to-end workflow by exporting Nessus scan files from your Nessus scanner, saving them locally, and then ingesting them into Elasticsearch for analysis and visualization.

👉🏻[Option 4 Full documentation and use cases here.](./Option-4.md)

### 5️⃣ **Purge Processed Hashes List**

Removes the list of hashes that track which Nessus files have already been ingested by Power-Nessie. This "reset" option enables reprocessing and re-ingesting of previously imported `.nessus` files.

👉🏻[Option 5 Full documentation and use cases here.](./Option-5.md)

### 6️⃣ **Compare Scan Data Between Scans and Export Results into Elasticsearch (Patch Summarization)**

Compares vulnerability data between two or more Nessus scans and exports the results into Elasticsearch. This option is designed for Patch Summarization.

👉🏻[Option 6 Full documentation and use cases here.](./Option-6.md)

### 7️⃣ **Export PDF or CSV Report from Kibana Dashboard and Optionally Send via Email**

Automates the export of PDF or CSV reports from your Kibana dashboards, allowing you to generate and distribute visualizations of vulnerability data.

👉🏻[Option 7 Full documentation and use cases here.](./Option-7.md)

### 8️⃣ **Remove Processed Scans from Local Nessus File Download Directory**

Automates the cleanup of processed Nessus scan files from your local download directory by removing files marked as ingested.

👉🏻[Option 8 Full documentation and use cases here.](./Option-8.md)

### 🔟 **Delete Oldest Scan from Scan History (Nessus Manager License Only)**

Removes the oldest scan from the scan history for a specified scan name in your Nessus Manager environment.

👉🏻[Option 10 Full documentation and use cases here.](./Option-10.md)

### 🚫 **Quit**

Exits the Power-Nessie script interface.

## 🎉 Conclusion & Workflow Guidance

Power-Nessie provides a robust, modular toolkit for integrating Nessus vulnerability scans with the Elastic Stack using PowerShell. Each menu option is designed to support a specific part of your vulnerability management or compliance workflow — from initial environment setup, to scan export and ingest, to reporting and cleanup.

### Quick Reference: Workflow Steps

1. **Setup Elasticsearch & Kibana**  
   Prepare your analysis environment (Option 0).

2. **Export Nessus Files**  
   Download scans from your Nessus scanner (Option 1).

3. **Ingest Nessus Files**  
   Import scan data into Elasticsearch, either individually (Option 2) or in bulk (Option 3).

4. **Export & Ingest Combined**  
   Automate full-cycle workflows (Option 4).

5. **Manage Ingestion State**  
   Purge processed hashes to reset ingestion (Option 5).

6. **Patch Summarization**  
   Compare scan cycles and summarize vulnerability changes (Option 6).

7. **Report Generation & Delivery**  
   Export PDF/CSV reports from Kibana and distribute via email (Option 7).

8. **Cleanup Processed Scans**  
   Remove old processed files to keep your environment tidy (Option 8).

10. **Manage Scan Retention**  
    Delete oldest scan history entries (Nessus Manager only, Option 10).

Q. **Quit**  
   End your session.

---

Thank you for using **Power-Nessie** to bridge Nessus and the Elastic Stack for powerful, flexible vulnerability management and reporting.  
If you have questions, suggestions, or encounter issues, please visit the [Power-Nessie GitHub repository](https://github.com/nicpenning/Power-Nessie) and join the community!

Happy scanning! 🚀
