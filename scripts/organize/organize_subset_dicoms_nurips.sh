### This script takes all of the dicoms Ellyn downloaded from NURIPS (because
### they were missing from Todd's upload), and organizes them into a
### BIDS-esque framework in the mwmh study directory
###
### Ellyn Butler
### April 19, 2022 - April 20, 2022

indir=/projects/b1108/ellyn/mwmh_zips
outdir=/projects/b1108/studies/mwmh/data/raw/neuroimaging/dicoms

cd ${indir}
unzip '*.zip'

# (Manually edited off file names)

mwmhdirs=`find ${indir} -maxdepth 1 -name "MWMH*"`

for mwmhdir in ${mwmhdirs}; do
  # Get sub and ses labels
  sub=`echo ${mwmhdir} | cut -d '/' -f 6 | cut -d '_' -f 1 | cut -d 'C' -f 1`
  ses=`echo ${mwmhdir} | cut -d '/' -f 6 | cut -d '_' -f 1 | cut -d 'V' -f 2`
  if [ ! -d "${outdir}/sub-${sub}" ]; then
    mkdir ${outdir}/sub-${sub}
  fi
  if [ ! -d "${outdir}/sub-${sub}/ses-${ses}" ]; then
    mkdir ${outdir}/sub-${sub}/ses-${ses}
    mkdir ${outdir}/sub-${sub}/ses-${ses}/SCANS
  fi
  if [ "$(ls -A ${outdir}/sub-${sub}/ses-${ses}/SCANS)" ]; then
    cp -r ${mwmhdir} ${outdir}/sub-${sub}/ses-${ses}/SCANS
  fi
done
