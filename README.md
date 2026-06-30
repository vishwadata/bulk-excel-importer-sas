
# 📊 Bulk Excel File Importer for SAS

[![SAS](https://img.shields.io/badge/SAS-Base%20%26%20Macro-1B4F72?style=flat-square&logo=sas)](https://www.sas.com)
[![Domain](https://img.shields.io/badge/Domain-BFSI%20%2F%20Banking-B8860B?style=flat-square)](#)
[![Status](https://img.shields.io/badge/Status-Production%20Ready-success?style=flat-square)](#)

A lightweight SAS macro utility that automatically discovers and imports **hundreds of `.xlsx` files** from a server directory into SAS datasets — no manual `PROC IMPORT` statement per file required.

---

## 📌 Problem Statement

In MIS/reporting environments (e.g., daily CASA banking reports), it's common to receive a folder containing **hundreds of Excel files** that each need to be loaded into SAS for downstream processing. Writing a `PROC IMPORT` step for every single file manually is slow and error-prone.

This script solves that by:
1. Scanning a directory for all `.xlsx` files
2. Capturing the filenames into a SAS dataset
3. Dynamically generating and executing a `PROC IMPORT` for each file using macro looping

---

## ⚙️ How It Works

### Step 1 — List Excel files in the target directory
The script uses an OS-level command (via the `x` statement) to list all `.xlsx` files in the target path and redirect that list into a text file.

```sas
%LET PATH=/path/BANKING/REPORTS/CASA;

x "ls &PATH/*.xlsx > &PATH/excel1.txt";        /* Unix/Linux */
x "find &PATH -name '*.xlsx' > &PATH/excel2.txt"; /* Unix/Linux (recursive) */
x "dir /b &PATH/*.xlsx > &PATH/excel3.txt";    /* Windows */
```

> ⚠️ Only **one** of these three commands is needed depending on the OS the SAS server runs on. They're included together here as reference/working alternatives — keep the one relevant to your environment and comment out (or delete) the other two.

### Step 2 — Read the file list into a SAS dataset
```sas
data excelfile_list;
infile "&PATH/excel1.txt" delimiter=" ";
input FILEPATH :$1000.;
files=scan(filepath,-1,'/');
run;
```
This reads the generated text file and uses `SCAN()` to strip the full path down to just the filename (e.g., `casa_report_01.xlsx`).

### Step 3 — Convert filenames into macro variables
```sas
proc sql number;
select count(files) into :cnt from excelfile_list;
select files into :files_1 -: %sysfunc(compress(files_&cnt)) from excelfile_list;
run;
```
- `&cnt` holds the total number of Excel files found
- `&files_1`, `&files_2`, ... `&files_n` each hold one filename, created via `PROC SQL`'s into `:var1-:varN` syntax

### Step 4 — Loop through and import every file
```sas
%MACRO excel_f();
%DO I =1 %TO &cnt.;
   PROC import datafile="&PATH/&&files_&i" out=data_&i
   DBMS=XLSX REPLACE;
   RUN;
%END;
%MEND excel_f();
%excel_f();
```
The macro loops from `1` to `&cnt`, building each file path dynamically (`&&files_&i` resolves to `&files_1`, `&files_2`, etc.) and importing it into a uniquely named dataset: `data_1`, `data_2`, ... `data_n`.

---

## 🚀 Usage

1. Update the `&PATH` macro variable to point to your target directory:
   ```sas
   %LET PATH=/your/server/path/here;
   ```
2. Keep only the OS-appropriate file-listing command (`ls`, `find`, or `dir`) and remove/comment the other two.
3. Run the script top to bottom.
4. Each Excel file will be loaded into its own SAS dataset (`data_1`, `data_2`, ... `data_n`) in the `WORK` library.

---

## 📂 Output

| Output | Description |
|---|---|
| `excel1.txt` / `excel2.txt` / `excel3.txt` | Text file listing all `.xlsx` filenames in the source directory |
| `excelfile_list` | SAS dataset holding the full file paths and parsed filenames |
| `data_1` ... `data_n` | One SAS dataset per imported Excel file |

---

## 📝 Notes & Limitations

- The OS-level `x` statement requires the SAS environment to have shell command access enabled (`XCMD` option) — check with your SAS admin if this is restricted in a production environment.
- All imported datasets default to the standard `PROC IMPORT` behavior (first row as column headers, auto-detected column types). Add `GETNAMES=YES` / `SHEET=` options explicitly if your files have non-standard layouts.
- Since each file lands in a separately named dataset (`data_1`, `data_2`...), consider adding a `PROC APPEND` or `SET` step afterward to consolidate them into a single master dataset if that's the end goal.
- File names are not preserved as a column in the output datasets — add a `LENGTH`/`RETAIN` statement inside the macro loop if source-file traceability is needed downstream.

---

## 🛠️ Tech Stack

`SAS Base` · `SAS Macro Language` · `PROC IMPORT` · `PROC SQL` · `DATA Step`

---

## 👤 Author

**Vishwa Bharath**
Senior SAS Developer & Data Analyst 
[LinkedIn](https://linkedin.com/in/vishwa-bharath-87b1bb104)
