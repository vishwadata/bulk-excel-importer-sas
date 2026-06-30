

/*below commands are used to fetch xlsx files from the server path
working correct methods you can use any of these three */

%LET PATH=/path/BANKING/REPORTS/CASA;

x "ls &PATH/*.xlsx > &PATH/excel1.txt";
x "find &PATH -name '*.xlsx' > &PATH/excel2.txt";
x "dir /b &PATH/*.xlsx > &PATH/excel3.txt";

data excelfile_list;
infile "&PATH/excel1.txt" delimiter=" ";
input FILEPATH :$1000.;
files=scan(filepath,-1,'/');
run;


proc sql number;
select count(files) into :cnt from  excelfile_list;
select files into :files_1 -: %sysfunc(compress(files_&cnt)) from excelfile_list;
run;

%MACRO excel_f();
%DO I =1 %TO &cnt.;
PROC import datafile="&PATH/&&files_&i" out=data_&i
DBMS=XLSX REPLACE;
RUN;
%END;
%MEND excel_f();
%excel_f();