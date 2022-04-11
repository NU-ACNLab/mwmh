### This script gets rid of the first line that eprime outputs in the txt file
### so that the txt can be turned into a csv for reading into R
###
### Ellyn Butler
### March 29, 2022


#March 30, 2022: Not working. May be best to do it just for the mega file in Excel
behavdir="/Users/flutist4129/Documents/Northwestern/studies/mwmh/data/processed/neuroimaging/behavioral"

txtfiles=`find ${behavdir} -name "*.txt"`

for txtfile in ${txtfiles}; do
  sub=`echo $txtfile | cut -d '/' -f 12 | cut -d '_' -f 1`
  ses=`echo $txtfile | cut -d '/' -f 12 | cut -d '_' -f 2`
  task=`echo $txtfile | cut -d '/' -f 12 | cut -d '_' -f 3 | cut -d '.' -f 1`
  echo `sed '1d' ${txtfile} | sed -e 's/\s\+/,/g'` >> ${behavdir}/${sub}_${ses}_${task}.csv
done
