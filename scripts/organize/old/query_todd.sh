### This script goes through all of the directories Todd created with the dicoms
### from MWMH to create a csv of available data.
###
### Ellyn Butler
### February 1, 2022

basedir=/projects/b1108/todd

mwmhdirs=`find ${basedir} -maxdepth 1 -name "MWMH*"`

for mwmhdir in ${mwmhdirs}; do
  subid=``
  sesid=``
  dicomdirs=`ls ${mwmhdir}/SCANS/`
  for dicomdir in ${dicomdirs};
    dicom=`find ${mwmhdir}/SCANS/${dicomdir}/ -name "*.dcm" -print -quit`
    hdr=`dicom_hdr ${dicom}` #stopped here
