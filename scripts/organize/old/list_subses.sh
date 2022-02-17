### This script creates a csv of all the available subjects and sessions in MWMH
###
### Ellyn Butler
### November 13, 2021

bids_dir="/projects/b1108/data/MWMH/bids_directory"
sub_dirs=`find ${bids_dir} -maxdepth 1 -name "sub*"`

echo "subid,sesid" > /projects/b1108/data/MWMH/demographics/subses.csv

for sub_dir in ${sub_dirs}; do
  subid=`echo ${sub_dir} | cut -d "/" -f 7 | cut -d "-" -f 2`
  ses_dirs=`find ${sub_dir} -maxdepth 1 -name "ses*"`
  for ses_dir in ${ses_dirs}; do
    sesid=`echo ${ses_dir} | cut -d "/" -f 8 | cut -d "-" -f 2`
    echo "${subid},${sesid}" >> /projects/b1108/data/MWMH/demographics/subses.csv
  done
done
