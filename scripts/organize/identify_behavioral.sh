### This script creates a csv of the available behavioral data for the tasks
###
### Ellyn Butler
### March 8, 2022

indir=/projects/b1108/studies/mwmh/data/raw/neuroimaging/behavioral
outdir=/projects/b1108/studies/mwmh/data/raw/neuroimaging/meta

subdirs=`find ${indir} -mindepth 1 -maxdepth 1 -name "MWMH*"`

echo "subid,sesid,faces,avoid" > ${outdir}/task_behav.csv

for subdir in ${subdirs}; do
  subid=`echo ${subdir} | cut -d '/' -f 10 | cut -d 'C' -f 1`
  sesid=`echo ${subdir} | cut -d '/' -f 10 | cut -d 'V' -f 2`
  faces=`find ${subdir} -name "*FACES*.edat2"`
  avoid=`find ${subdir} -name "*PA*.edat2"`
  if [ -z "${faces}" ]; then
    faces=0
  else
    faces=1
  fi
  if [ -z "${avoid}" ]; then
    avoid=0
  else
    avoid=1
  fi
  echo ${subid},${sesid},${faces},${avoid} >> ${outdir}/task_behav.csv
done
