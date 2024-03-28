### This script copies eprime files for the passive avoidance and faces tasks
### from the external hard drives onto Ellyn's laptop
###
### Ellyn Butler
### March 3, 2022

basedir="/Volumes/MILLER/REGR/Data"

indirs=`find ${basedir} -type d -mindepth 1 -maxdepth 1 -name "*MWMH*"`

outdir="/Users/flutist4129/Documents/Northwestern/studies/mwmh/data/raw/neuroimaging/behavioral/"

for indir in ${indirs}; do
  olddirname=`echo ${indir} | cut -d '/' -f 6`
  newdirname=`echo ${olddirname} | cut -d ' ' -f 1`
  if [[ ! -d ${outdir}/${newdirname} ]] ; then mkdir ${outdir}/${newdirname}; fi
  cp ${basedir}/${olddirname}/* ${outdir}/${newdirname}
done
