### This script creates a csv of the subject and session labels according
### to directory names, file names, and .txt file headers for E-Prime output.
### Ideally, all of the file names NOW match the directory names (Ellyn went
### through and corrected the copies she has locally and on Quest), and that
### these file names match the actual subject and session. The latter can be
### by examining dates.
###
### https://unix.stackexchange.com/questions/637433/grep-on-windows-created-txt-file-doesnt-match-strings-on-mac-why
###
### Ellyn Butler
### July 26, 2022

indir=/projects/b1108/studies/mwmh/data/raw/neuroimaging/behavioral
indirajay=/projects/b1108/studies/mwmh/data/raw/neuroimaging/behavioral_ajay
indirkay=/projects/b1108/studies/mwmh/data/raw/neuroimaging/behavioral_kay
outdir=/projects/b1108/studies/mwmh/data/processed/demographic

echo "subid_dir,sesid_dir,subid_edat,sesid_edat,subid_txt,sesid_txt,date_txt,task" > ${outdir}/eprime_sub_ses_discrepancies.csv

mwmhdirs=`find ${indir} -maxdepth 1 -name "MWMH*"`

# Through the files from Stu
for mwmhdir in ${mwmhdirs}; do
  subid_dir=`echo ${mwmhdir} | cut -d "/" -f 10 | cut -d "C" -f 1`
  sesid_dir=`echo ${mwmhdir} | cut -d "/" -f 10 | cut -d "V" -f 2`
  edats=`find ${mwmhdir} -name "*.edat2"`
  for edat in ${edats}; do
    subid_edat=`echo ${edat} | cut -d "_" -f 3 | cut -d "-" -f 2`
    subid_edat="MWMH"${subid_edat}
    sesid_edat=`echo ${edat} | cut -d "_" -f 3 | cut -d "-" -f 3 | cut -d. -f 1`
    task=`echo ${edat} | cut -d "_" -f 2`
    txt=`find ${mwmhdir} -name "*${task}*.txt"`
    # Convert txt to be readable by bash (created on Windows)
    dos2unix ${txt}
    subid_txt=`cat ${txt} | grep -m 1 Subject | cut -d " " -f 2`
    subid_txt="MWMH"${subid_txt}
    sesid_txt=`cat ${txt} | grep -m 1 "Session: " | cut -d " " -f 2`
    date_txt=`cat ${txt} | grep -m 1 "SessionDate: " | cut -d " " -f 2`
    echo ${subid_dir},${sesid_dir},${subid_edat},${sesid_edat},${subid_txt},${sesid_txt},${date_txt},${task} >> ${outdir}/eprime_sub_ses_discrepancies.csv
  done
done

# Through the files from Ajay
mwmhdirsajay=`find ${indirajay} -maxdepth 1 -name "MWMH*"`

for mwmhdir in ${mwmhdirsajay}; do
  subid_dir=`echo ${mwmhdir} | cut -d "/" -f 10 | cut -d "C" -f 1`
  sesid_dir=`echo ${mwmhdir} | cut -d "/" -f 10 | cut -d "V" -f 2 | cut -d "_" -f 1`
  edats=`find ${mwmhdir} -name "*.edat2"`
  for edat in ${edats}; do
    subid_edat=`echo ${edat} | cut -d "_" -f 6 | cut -d "-" -f 2`
    subid_edat="MWMH"${subid_edat}
    sesid_edat=`echo ${edat} | cut -d "_" -f 6 | cut -d "-" -f 3 | cut -d. -f 1`
    task=`echo ${edat} | cut -d "_" -f 5`
    txt=`find ${mwmhdir} -name "*${task}*.txt"`
    # Convert txt to be readable by bash (created on Windows)
    dos2unix ${txt}
    subid_txt=`cat ${txt} | grep -m 1 Subject | cut -d " " -f 2`
    subid_txt="MWMH"${subid_txt}
    sesid_txt=`cat ${txt} | grep -m 1 "Session: " | cut -d " " -f 2`
    date_txt=`cat ${txt} | grep -m 1 "SessionDate: " | cut -d " " -f 2`
    echo ${subid_dir},${sesid_dir},${subid_edat},${sesid_edat},${subid_txt},${sesid_txt},${date_txt},${task} >> ${outdir}/eprime_sub_ses_discrepancies.csv
  done
done

# Through the files from Kay
mwmhdirskay=`find ${indirkay} -maxdepth 1 -name "MWMH*"`

for mwmhdir in ${mwmhdirskay}; do
  subid_dir=`echo ${mwmhdir} | cut -d "/" -f 10 | cut -d "C" -f 1`
  sesid_dir=`echo ${mwmhdir} | cut -d "/" -f 10 | cut -d "V" -f 2 | cut -d "_" -f 1`
  edats=`find ${mwmhdir} -name "*.edat2"`
  for edat in ${edats}; do
    subid_edat=`echo ${edat} | cut -d "_" -f 4 | cut -d "-" -f 2`
    subid_edat="MWMH"${subid_edat}
    sesid_edat=`echo ${edat} | cut -d "_" -f 4 | cut -d "-" -f 3 | cut -d. -f 1`
    task=`echo ${edat} | cut -d "_" -f 3`
    txt=`find ${mwmhdir} -name "*${task}*.txt"`
    # Convert txt to be readable by bash (created on Windows)
    dos2unix ${txt}
    subid_txt=`cat ${txt} | grep -m 1 Subject | cut -d " " -f 2`
    subid_txt="MWMH"${subid_txt}
    sesid_txt=`cat ${txt} | grep -m 1 "Session: " | cut -d " " -f 2`
    date_txt=`cat ${txt} | grep -m 1 "SessionDate: " | cut -d " " -f 2`
    echo ${subid_dir},${sesid_dir},${subid_edat},${sesid_edat},${subid_txt},${sesid_txt},${date_txt},${task} >> ${outdir}/eprime_sub_ses_discrepancies.csv
  done
done


##### COULD NOT FIND ACROSS THREE SOURCES
# 1) sub-MWMH278_ses-1
# 2) sub-MWMH358_ses-1_task-faces edat 
