### This script goes through the BIDS directory and creates a csv of subjects
### and sessions, and the data types that they have in BIDS
###
### Ellyn Butler
### July 6, 2022 - September 26, 2022


bidsdir=/projects/b1108/studies/mwmh/data/raw/neuroimaging/bids/
subdirs=`find ${bidsdir} -maxdepth 1 -name "sub-*"`

echo "subid,sesid,t1w,dwi,rest,avoid,avoid_events,faces,faces_events" > /projects/b1108/studies/mwmh/data/raw/demographic/bids_subsesids_09-26-2022.csv

for subdir in ${subdirs}; do
  sub=`echo ${subdir} | cut -d '/' -f 10 | cut -d '-' -f 2`
  sesdirs=`find ${subdir} -maxdepth 1 -name "ses-*"`
  for sesdir in ${sesdirs}; do
    ses=`echo ${sesdir} | cut -d '/' -f 11 | cut -d '-' -f 2`
    # Check if the relevant directories exist first
    anatdir=${sesdir}/anat
    ################################### ANAT ###################################
    if [ -d ${anatdir} ] ; then
        # Does the t1w image exist?
        t1w=`find ${sesdir}/anat/ -maxdepth 1 -name "*_T1w.nii.gz"`
        if [ -f "${t1w}" ] ; then
          t1wexist=1
        else
          t1wexist=0
        fi
    else
      t1wexist=0
    fi
    #################################### DWI ###################################
    dwidir=${sesdir}/dwi
    if [ -d ${dwidir} ] ; then
      # Does the dw image exist?
      dwi=`find ${sesdir}/dwi/ -maxdepth 1 -name "*_dwi.nii.gz"`
      if [ -f "${dwi}" ] ; then
        dwiexist=1
      else
        dwiexist=0
      fi
    else
      dwiexist=0
    fi
    ################################### FUNC ###################################
    funcdir=${sesdir}/func
    if [ -d ${funcdir} ] ; then
      # Does the rest image exist?
      rest=`find ${sesdir}/func/ -maxdepth 1 -name "*rest_bold.nii.gz"`
      if [ -f "${rest}" ] ; then
        restexist=1
      else
        restexist=0
      fi
      # Does the avoid image exist?
      avoid=`find ${sesdir}/func/ -maxdepth 1 -name "*avoid_bold.nii.gz"`
      if [ -f "${avoid}" ] ; then
        avoidexist=1
      else
        avoidexist=0
      fi
      # Does the avoid events file exist?
      avoidevents=`find ${sesdir}/func/ -maxdepth 1 -name "*avoid_events.tsv"`
      if [ -f "${avoidevents}" ] ; then
        avoideventsexist=1
      else
        avoideventsexist=0
      fi
      # Does the faces image exist?
      faces=`find ${sesdir}/func/ -maxdepth 1 -name "*faces_bold.nii.gz"`
      if [ -f "${faces}" ] ; then
        facesexist=1
      else
        facesexist=0
      fi
      # Does the faces events file exist?
      facesevents=`find ${sesdir}/func/ -maxdepth 1 -name "*faces_events.tsv"`
      if [ -f "${facesevents}" ] ; then
        faceseventsexist=1
      else
        faceseventsexist=0
      fi
    else
      restexist=0
      avoidexist=0
      avoideventsexist=0
      facesexist=0
      faceseventsexist=0
    fi
    echo ${sub},${ses},${t1wexist},${dwiexist},${avoidexist},${avoideventsexist},${facesexist},${faceseventsexist} >> /projects/b1108/studies/mwmh/data/raw/demographic/bids_subsesids_09-26-2022.csv
  done
done
