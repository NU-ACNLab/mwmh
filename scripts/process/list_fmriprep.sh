### This script goes through the fmriprep directory and creates a csv of subjects
### and sessions, and the data types that have made it through fmriprep
###
### Ellyn Butler
### July 6, 2022 - October 6, 2022


fmriprepdir=/projects/b1108/studies/mwmh/data/processed/neuroimaging/fmriprep/
outdir=/projects/b1108/studies/mwmh/data/processed/neuroimaging/meta/
subdirs=`find ${fmriprepdir} -maxdepth 1 -type d -name "sub-*"`

echo "subid,sesid,t1w,rest,avoid,faces" > ${outdir}/fmriprep_10-06-2022.csv

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
        transform=`find ${sesdir}/anat/ -maxdepth 1 -name "*T1w_mode-image_xfm.txt"`
        if [ -f "${t1w}" ] || [ -f "${transform}" ] ; then
          t1wexist=1
        else
          t1wexist=0
        fi
    else
      t1wexist=0
    fi
    ################################### FUNC ###################################
    funcdir=${sesdir}/func
    if [ -d ${funcdir} ] ; then
      # Does the rest image exist?
      rest=`find ${sesdir}/func/ -maxdepth 1 -name "*task-rest*desc-preproc_bold.nii.gz"`
      if [ -f "${rest}" ] ; then
        restexist=1
      else
        restexist=0
      fi
      # Does the avoid image exist?
      avoid=`find ${sesdir}/func/ -maxdepth 1 -name "*task-avoid*desc-preproc_bold.nii.gz"`
      if [ -f "${avoid}" ] ; then
        avoidexist=1
      else
        avoidexist=0
      fi
      # Does the faces image exist?
      faces=`find ${sesdir}/func/ -maxdepth 1 -name "*task-faces*desc-preproc_bold.nii.gz"`
      if [ -f "${faces}" ] ; then
        facesexist=1
      else
        facesexist=0
      fi
    else
      restexist=0
      avoidexist=0
      facesexist=0
    fi
    echo ${sub},${ses},${t1wexist},${restexist},${avoidexist},${facesexist} >> ${outdir}/fmriprep_10-06-2022.csv
  done
done
