### This script identifies the sessions that did not curate successfully
### during the initial launch.
###
### Ellyn Butler
### October 25, 2022


launchdir=/projects/b1108/studies/mwmh/data/processed/neuroimaging/launch/amygconn

txtfiles=`find ${launchdir} -name "*.txt"`

echo "sub,ses,error" > ${launchdir}/errors.csv

for txtfile in ${txtfiles}; do
  amygconnerror=`grep "Error" ${txtfile}`
  if [ ! -z "${amygconneperror}" ]; then
    sub=`echo ${txtfile} | cut -d '/' -f 11 | cut -d '_' -f 1 | cut -d '-' -f 2`
    ses=`echo ${txtfile} | cut -d '/' -f 11 | cut -d '_' -f 2 | cut -d '-' -f 2 | cut -d. -f 1`
    echo ${sub},${ses},${curateerror} >> ${launchdir}/errors.csv
  fi
done
