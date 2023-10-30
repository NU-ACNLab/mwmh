### This script adapts code from ChatGPT to create ciftis from subject fmri data
### https://neurostars.org/t/volume-to-surface-mapping-mri-vol2surf-using-fmriprep-outputs/4079/13
### https://www.humanconnectome.org/software/workbench-command
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

##### 3) Convert the BOLD data on the subject's native freesurfer surface to gifti format
mri_convert ${sssurfdir}/sub-${subid}_ses-${sesid}_task-rest_space-T1w_desc-preproc_bold_lh.mgh \
  ${sssurfdir}/sub-${subid}_ses-${sesid}_task-rest_space-T1w_desc-preproc_bold_lh.func.gii
mri_convert ${sssurfdir}/sub-${subid}_ses-${sesid}_task-rest_space-T1w_desc-preproc_bold_rh.mgh \
  ${sssurfdir}/sub-${subid}_ses-${sesid}_task-rest_space-T1w_desc-preproc_bold_rh.func.gii

##### 4) Get registration gifti from subject's native freesurfer surface space
#####    to fsLR32k space (?)
wb_shortcuts -freesurfer-resample-prep ${ssfreedir}/surf/lh.white \
  ${ssfreedir}/surf/lh.pial \
  ${ssfreedir}/surf/lh.sphere.reg \
  ${hcptempdir}/fs_LR-deformed_to-fsaverage.L.sphere.32k_fs_LR.surf.gii \
  ${sssurfdir}/lh.midthickness.surf.gii \
  ${sssurfdir}/sub-${subid}.L.midthickness.32k_fs_LR.surf.gii \
  ${sssurfdir}/lh.sphere.reg.surf.gii
wb_shortcuts -freesurfer-resample-prep ${ssfreedir}/surf/rh.white \
  ${ssfreedir}/surf/rh.pial \
  ${ssfreedir}/surf/rh.sphere.reg \
  ${hcptempdir}/fs_LR-deformed_to-fsaverage.R.sphere.32k_fs_LR.surf.gii \
  ${sssurfdir}/rh.midthickness.surf.gii \
  ${sssurfdir}/sub-${subid}.R.midthickness.32k_fs_LR.surf.gii \
  ${sssurfdir}/rh.sphere.reg.surf.gii

##### 5) Use the registration gifti from (4) to project the BOLD data on the
#####    subject's native freesurfer surface to fsLR32k space
wb_command -metric-resample ${sssurfdir}/sub-${subid}_ses-${sesid}_task-rest_space-T1w_desc-preproc_bold_lh.func.gii \
  ${sssurfdir}/lh.sphere.reg.surf.gii \
  ${hcptempdir}/fs_LR-deformed_to-fsaverage.L.sphere.32k_fs_LR.surf.gii \
  ADAP_BARY_AREA \
  ${sssurfdir}/sub-${subid}_ses-${sesid}.task-rest.L.32k_fs_LR.func.gii \
  -area-surfs ${sssurfdir}/lh.midthickness.surf.gii \
  ${sssurfdir}/sub-${subid}.L.midthickness.32k_fs_LR.surf.gii
wb_command -metric-resample ${sssurfdir}/sub-${subid}_ses-${sesid}_task-rest_space-T1w_desc-preproc_bold_rh.func.gii \
  ${sssurfdir}/rh.sphere.reg.surf.gii \
  ${hcptempdir}/fs_LR-deformed_to-fsaverage.R.sphere.32k_fs_LR.surf.gii \
  ADAP_BARY_AREA \
  ${sssurfdir}/sub-${subid}_ses-${sesid}.task-rest.R.32k_fs_LR.func.gii \
  -area-surfs ${sssurfdir}/rh.midthickness.surf.gii \
  ${sssurfdir}/sub-${subid}.R.midthickness.32k_fs_LR.surf.gii

##### 6) Set the structure parameter so that wb_view knows how to display the data
wb_command -set-structure ${sssurfdir}/sub-${subid}_ses-${sesid}.task-rest.L.32k_fs_LR.func.gii CORTEX_LEFT
wb_command -set-structure ${sssurfdir}/sub-${subid}_ses-${sesid}.task-rest.R.32k_fs_LR.func.gii CORTEX_RIGHT

# View the BOLD data on the fsLR32k surface
wb_view ${sssurfdir}/sub-${subid}.L.midthickness.32k_fs_LR.surf.gii \
  ${sssurfdir}/sub-${subid}_ses-${sesid}.task-rest.L.32k_fs_LR.func.gii \
  ${sssurfdir}/sub-${subid}.R.midthickness.32k_fs_LR.surf.gii \
  ${sssurfdir}/sub-${subid}_ses-${sesid}.task-rest.R.32k_fs_LR.func.gii \
  ${ssprepdir}/anat/sub-${subid}_ses-${sesid}_desc-preproc_T1w.nii.gz


wb_command -file-information ${sssurfdir}/sub-${subid}_ses-${sesid}.task-rest.L.32k_fs_LR.func.gii
# returns "Maps to Volume:           false"

##### 7) Combine surfaces in fsLR32k space and subcortical data in MNI152NLin6Asym
#####    space to create ciftis for use in templateICAr
