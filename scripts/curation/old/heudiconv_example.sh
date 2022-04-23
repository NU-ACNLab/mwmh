### This script is a series of singularity commands that are needed in the
### curation process
### https://reproducibility.stanford.edu/bids-tutorial-series-part-2a/#heuman3
###
### Ellyn Butler
### October 24, 2021

singularity pull docker://nipy/heudiconv:0.9.0

singularity shell --writable-tmpfs --cleanenv \
  -B /projects/b1108/todd:/base \
  /home/erb9722/heudiconv_0.9.0.sif

singularity run --writable-tmpfs --cleanenv \
  -B /projects/b1108:/base \
  /home/erb9722/heudiconv_0.9.0.sif --files /base/todd/ \
  -o /base/studies/mwmh/data/raw/neuroimaging/bids/ -f convertall \
  --grouping all -c none --overwrite

singularity run --writable-tmpfs --cleanenv \
  -B /projects/b1108:/base \
  /home/erb9722/heudiconv_0.9.0.sif -d /base/Dicom/todd/{subject}*/*/*/DICOM/*.dcm \
  -o /base/studies/mwmh/data/raw/neuroimaging/bids/ \
  -f /base/Nifti/code/heuristic.py -s 991 -c dcm2niix -b --overwrite

# October 25, 2021: make sure to delete the Nifti/.heudiconv directory between
# runs of the last command

#https://stackoverflow.com/questions/31233777/python-source-code-string-cannot-contain-null-bytes
#http://www.repronim.org/coco2019-training/presentations/heudiconv/#5
