## 📦 Dataset

Due to GitHub file size limits, the dataset is hosted externally.

🔗 **Download Dataset (.bak)**  
[Google Drive Download](https://drive.google.com/file/d/143G-g-m2zhpa2_zyMAmmVE1n18wwJf0A/view?usp=drive_link)

File included:
- Database.bak

---

## How to Load the Dataset

1. Download the `.bak` file
2. Open SQL Server Management Studio
3. Run:

```sql
RESTORE DATABASE Dataset
FROM DISK = 'path_to_backup/Database.bak'
WITH REPLACE;
