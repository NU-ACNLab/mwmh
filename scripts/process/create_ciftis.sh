### This script adapts code from ChatGPT to create ciftis from subject fmri data
### https://netneurolab.github.io/neuromaps/user_guide/transformations.html
### Resampling-FreeSurfer-HCP.pdf
### Oct 19, 2023: This code is currently configured for a subject that has one session
###
### Ellyn Butler
### September 26, 2023 - October 19, 2023

subid="MWMH212"
sesid="2"
# Quest
ssfreedir="/projects/b1108/studies/mwmh/data/processed/neuroimaging/fmriprep_23.1.4/sourcedata/freesurfer/sub-"${subid}
ssprepdir="/projects/b1108/studies/mwmh/data/processed/neuroimaging/fmriprep_23.1.4/sub-"${subid}"/ses-"${sesid}
sssurfdir="/projects/b1108/studies/mwmh/data/processed/neuroimaging/surf/sub-"${subid}"/ses-"${sesid}
hcptempdir="/projects/b1108/hcp/global/templates/standard_mesh_atlases/resample_fsaverage"
export SUBJECTS_DIR="/projects/b1108/studies/mwmh/data/processed/neuroimaging/fmriprep_23.1.4/sourcedata/freesurfer"
tfdir="/projects/b1108/templateflow"
fslrdir=${tfdir}"/tpl-fsLR"

# Local
ssfreedir="/Users/flutist4129/Documents/Northwestern/studies/mwmh/data/processed/neuroimaging/fmriprep_23.1.4/sourcedata/freesurfer/sub-"${subid}
ssprepdir="/Users/flutist4129/Documents/Northwestern/studies/mwmh/data/processed/neuroimaging/fmriprep_23.1.4/sub-"${subid}"/ses-"${sesid}
sssurfdir="/Users/flutist4129/Documents/Northwestern/studies/mwmh/data/processed/neuroimaging/surf/sub-"${subid}"/ses-"${sesid}
hcptempdir="/Users/flutist4129/Documents/Northwestern/hcp/global/templates/standard_mesh_atlases/resample_fsaverage"
export SUBJECTS_DIR="/Users/flutist4129/Documents/Northwestern/studies/mwmh/data/processed/neuroimaging/fmriprep_23.1.4/sourcedata/freesurfer"
tfdir="/Users/flutist4129/Documents/templateflow"
fslrdir=${tfdir}"/tpl-fsLR"

##### 1) Project the subject's BOLD data to their native freesurfer surface
mri_vol2surf --src ${ssprepdir}/func/sub-${subid}_ses-${sesid}_task-rest_space-T1w_desc-preproc_bold.nii.gz \
  --out ${sssurfdir}/sub-${subid}_ses-${sesid}_task-rest_space-T1w_desc-preproc_bold_lh.mgh \
  --regheader sub-${subid} --hemi lh
mri_vol2surf --src ${ssprepdir}/func/sub-${subid}_ses-${sesid}_task-rest_space-T1w_desc-preproc_bold.nii.gz \
  --out ${sssurfdir}/sub-${subid}_ses-${sesid}_task-rest_space-T1w_desc-preproc_bold_rh.mgh \
  --regheader sub-${subid} --hemi rh

# View the BOLD data on the subject's native freesurfer surface
freeview -f ${SUBJECTS_DIR}/sub-${subid}/surf/lh.pial:overlay=${sssurfdir}/sub-${subid}_ses-${sesid}_task-rest_space-T1w_desc-preproc_bold_lh.mgh:overlay_threshold=2,5

##### 2) Convert the freesurfer spherical surface to gifti format
mris_convert ${ssfreedir}/surf/lh.sphere ${sssurfdir}/lh.sphere.gii
mris_convert ${ssfreedir}/surf/rh.sphere ${sssurfdir}/rh.sphere.gii

##### 3) Resample surfaces into fsaverage
mri_surf2surf --sval ${sssurfdir}/sub-${subid}_ses-${sesid}_task-rest_space-T1w_desc-preproc_bold_lh.mgh \
  --tval ${sssurfdir}/sub-${subid}_ses-${sesid}_task-rest_space-fsaverage_desc-preproc_bold_lh.mgh \
  --s sub-${subid} --trgsubject fsaverage --hemi lh --cortex
mri_surf2surf --sval ${sssurfdir}/sub-${subid}_ses-${sesid}_task-rest_space-T1w_desc-preproc_bold_rh.mgh \
  --tval ${sssurfdir}/sub-${subid}_ses-${sesid}_task-rest_space-fsaverage_desc-preproc_bold_rh.mgh \
  --s sub-${subid} --trgsubject fsaverage --hemi rh --cortex

##### 4) Convert the BOLD data in fsaverage space to gifti format
mri_convert ${sssurfdir}/sub-${subid}_ses-${sesid}_task-rest_space-T1w_desc-preproc_bold_lh.mgh \
  ${sssurfdir}/sub-${subid}_ses-${sesid}_task-rest_space-fsaverage_desc-preproc_bold_lh.func.gii
mri_convert ${sssurfdir}/sub-${subid}_ses-${sesid}_task-rest_space-T1w_desc-preproc_bold_rh.mgh \
  ${sssurfdir}/sub-${subid}_ses-${sesid}_task-rest_space-fsaverage_desc-preproc_bold_rh.func.gii
