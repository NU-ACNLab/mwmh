### This script identifies the sessions that did not curate successfully
### during the initial launch.
###
### Ellyn Butler
### May 4, 2022


bidslaunchdir=/projects/b1108/studies/mwmh/data/raw/neuroimaging/launch/bids

txtfiles=`find ${bidslaunchdir} -name "*.txt"`

echo "sub,ses,error" > ${bidslaunchdir}/errors.csv

for txtfile in ${txtfiles}; do
  curateerror=`grep "Error" ${txtfile}`
  if [ ! -z "${curateerror}" ]; then
    sub=`echo ${txtfile} | cut -d '/' -f 11 | cut -d '_' -f 1 | cut -d '-' -f 2`
    ses=`echo ${txtfile} | cut -d '/' -f 11 | cut -d '_' -f 2 | cut -d '-' -f 2 | cut -d. -f 1`
    echo ${sub},${ses},${curateerror} >> ${bidslaunchdir}/errors.csv
  fi
done
