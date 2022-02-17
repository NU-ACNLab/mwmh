### This script takes all of the dicoms Todd uploaded, picks the ones that should
### stay (e.g., not the failed scanning sessions), and organizes them into a
### BIDS-esque framework in the mwmh study directory
###
### Ellyn Butler
### February 16, 2022

indir=/projects/b1108/todd
outdir=/projects/b1108/studies/mwmh/data/raw/neuroimaging/dicoms

mwmhdirs=`find ${indir} -maxdepth 1 -name "MWMH*"`

for mwmhdir in ${mwmhdirs}; do
  # If "rescan" is in mwmhdir filename, break
  if [[ "${mwmhdir}" == *"rescan"* ]]; then
    break
  fi
  # Get sub and ses labels
  sub=`echo ${mwmhdir} | cut -d '/' -f 5 | cut -d '_' -f 1 | cut -d 'C' -f 1`
  ses=`echo ${mwmhdir} | cut -d '/' -f 5 | cut -d '_' -f 1 | cut -d 'V' -f 2`
  # Check if ses missing
  if [ -z "${ses}" ] || [[ "${ses}" == *"MWMH"* ]]; then
    otherdir=`find ${indir} -maxdepth 1 -name "${sub}*CV*"`
    otherses=`echo ${otherdir} | cut -d '/' -f 5 | cut -d '_' -f 1 | cut -d 'V' -f 2`
    if [[ "${otherses}" == "1" ]]; then
      ses="2"
    else
      ses="1"
    fi
  fi
  if [ ! -d "${outdir}/sub-${sub}" ]; then
    mkdir ${outdir}/sub-${sub}
  fi
  if [ ! -d "${outdir}/sub-${sub}/ses-${ses}" ]; then
    mkdir ${outdir}/sub-${sub}/ses-${ses}
  fi
  cp -r ${mwmhdir} ${outdir}/sub-${sub}/ses-${ses}
done
