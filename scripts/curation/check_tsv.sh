### This script identifies the sessions that did not create a tsv successfully
### during the initial launch.
###
### Ellyn Butler
### May 5, 2022


tsvlaunchdir=/projects/b1108/studies/mwmh/data/raw/neuroimaging/launch/tsv

txtfiles=`find ${tsvlaunchdir} -name "*.txt"`

echo "sub,ses,error" > ${tsvlaunchdir}/errors.csv

for txtfile in ${txtfiles}; do
  curateerror=`grep "Error" ${txtfile}`
  if [ ! -z "${curateerror}" ]; then
    sub=`echo ${txtfile} | cut -d '/' -f 11 | cut -d '_' -f 1 | cut -d '-' -f 2`
    ses=`echo ${txtfile} | cut -d '/' -f 11 | cut -d '_' -f 2 | cut -d '-' -f 2 | cut -d. -f 1`
    echo ${sub},${ses},${curateerror} >> ${tsvlaunchdir}/errors.csv
  fi
done
