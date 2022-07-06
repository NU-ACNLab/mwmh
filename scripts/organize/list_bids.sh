### This script goes through the BIDS directory and creates a csv of subjects
### and sessions
###
### Ellyn Butler
### July 6, 2022


bidsdir=/projects/b1108/studies/mwmh/data/raw/neuroimaging/bids/
subdirs=`find ${bidsdir} -maxdepth 1 -name "sub-*"`

echo "subid,sesid" >> /projects/b1108/studies/mwmh/data/raw/demographic/bids_subsesids_07-06-2022.csv

for subdir in ${subdirs}; do
  sub=`echo ${subdir} | cut -d '/' -f 10 | cut -d '-' -f 2`
  sesdirs=`find ${subdir} -maxdepth 1 -name "ses-*"`
  for sesdir in ${sesdirs}; do
    ses=`echo ${sesdir} | cut -d '/' -f 11 | cut -d '-' -f 2`
    echo ${sub},${ses} >> /projects/b1108/studies/mwmh/data/raw/demographic/bids_subsesids_07-06-2022.csv
  done
done
