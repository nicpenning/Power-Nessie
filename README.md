# ⚡Power-Nessie🦕
<img src="https://github.com/nicpenning/Power-Nessie/assets/5582679/2173ff86-7f18-4f00-b4c7-650e8ffdc35a" alt="drawing" width="600" align="right"/>

Ingest .nessus files from Tenable's Nessus scanner  into Elasticsearch.

#### ❔ Why the new repo?
This project has taken on it's own form due to the major changes from the original work: [iwikmai/Nessus-ES](https://github.com/iwikmai/Nessus-ES). A huge thanks to the original creator of Nessus-ES as it has given me the foundation to begin learning how to ingest data into the Elastic stack programmatically. Thank you! 

The old project that I had forked and made my changes to is now archived/read-only and may eventually be deleted [nicpenning/Nessus-ES](https://github.com/nicpenning/Nessus-ES). 

This new project comes with some new changes such as bug fixes, pipeline/mapping updates, and the new ability to do a patch summary from previously ingested Nessus scan data that contain the same hosts.

#### ⚡Power-Nessie🦕
A way to ingest Nessus Scan data into Elasticsearch using PowerShell. Tracking vulnerabilities can be scary and overwhelming but this tool is designed to wrangle up those vulnerabilities into a manageable way.

As always, feel free to post issues / questions in this project to make it even better. Enjoy!

```mermaid
  sequenceDiagram
    PowerShell->>Nessus: Downloads .Nessus File(s) via Nessus API
    Nessus->>PowerShell: .nessus File(s) Saved Locally
    PowerShell->>Kibana: Dashboards, Index Templates and other Setup items
    PowerShell->>Elasticsearch: Ingest Parsed XML Data via Elasticsearch API
```

With some careful setup of your Elastic stack and a little PowerShell, you can turn your *.nessus files into this:
![dashboard-simple-using-v9.1.3](./documentation/images/dashboard-simple-9.1.3.jpeg)


The Power-Nessie project is a simplified way of taking .nessus files and ingesting them into Elasticsearch using PowerShell on Windows, Mac, or Linux.

[Requirements](./documentation/Overview.md#%EF%B8%8F-requirements)
* Functioning Elastic Stack (7.0+, 8.18.3/9.2.0 Latest Tested)
* PowerShell 7.0+ (7.5.4 Latest Tested)
* .nessus File(s) Exported (Power-Nessie can do this!)

Script includes a Menu to help you use Power-Nessie for Automated or Manual Download and Ingest Capabilities - Check the [Docs](./documentation/Overview.md)!
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

Version 1.8.0
Enter your choice:
```

## Now
- [X] Index Template
- [X] Data View, Searches, Visualizations, and Dashboards
- [X] ECS coverage across as many fields as possible
- [X] Documentation ([Overview](./documentation/Overview.md#%EF%B8%8F-requirements))
- [X] Automated Nessus File Download
- [X] Automated Elasticsearch Ingest
- [X] Setup Script (Template, Objects, API, etc..)

## New
- [X] Compare Scans (New Data Stream and Dashboard)
- [X] Generate Reports (PDF/PNG) & Send via Email
- [X] Configuration File Support
- [X] 💝 Community, join here: https://teams.live.com/l/community/FBANlP3DgeNDPOagwI

✨ Patch Summary Dashboard:
![patch-summary-dashboard-using-v9.1.3](./documentation/images/patch-summary-dashboard-9.1.3.jpeg)

## Future
- [ ] Add Detection Rules

## Full dashboard preview
![full-dashboard-using-v9.1.3](./documentation/images/dashboard-9.1.3.jpeg)
