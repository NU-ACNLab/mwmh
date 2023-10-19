### This script adapts code from ChatGPT to create ciftis from subject fmri data
### https://neurostars.org/t/volume-to-surface-mapping-mri-vol2surf-using-fmriprep-outputs/4079/13
### https://www.humanconnectome.org/software/workbench-command
### Resampling-FreeSurfer-HCP.pdf
###
### Ellyn Butler
### September 26, 2023 - October 19, 2023

subid="MWMH212"
sesid="2"
# Quest
ssfreedir="/projects/b1108/studies/mwmh/data/processed/neuroimaging/fmriprep_23.1.4/sourcedata/freesurfer/sub-"${subid}
ssprepdir="/projects/b1108/studies/mwmh/data/processed/neuroimaging/fmriprep_23.1.4/sub-"${subid}"/ses-"${sesid}
sssurfdir="/projects/b1108/studies/mwmh/data/processed/neuroimaging/surf/sub-"${subid}"/ses-"${sesid}
hcptempdir=""
export SUBJECTS_DIR="/projects/b1108/studies/mwmh/data/processed/neuroimaging/fmriprep_23.1.4/sourcedata/freesurfer"
tfdir="/projects/b1108/templateflow"
fslrdir=${tfdir}"/tpl-fsLR"

# Local
ssfreedir="~/Documents/Northwestern/studies/mwmh/data/processed/neuroimaging/fmriprep_23.1.4/sourcedata/freesurfer/sub-"${subid}
ssprepdir="~/Documents/Northwestern/studies/mwmh/data/processed/neuroimaging/fmriprep_23.1.4/sub-"${subid}"/ses-"${sesid}
sssurfdir="~/Documents/Northwestern/studies/mwmh/data/processed/neuroimaging/surf/sub-"${subid}"/ses-"${sesid}
hcptempdir="~/Documents/Northwestern/hcp/global/templates/standard_mesh_atlases/resample_fsaverage"
export SUBJECTS_DIR="~/Documents/Northwestern/studies/mwmh/data/processed/neuroimaging/fmriprep_23.1.4/sourcedata/freesurfer"
tfdir="~/Documents/templateflow"
fslrdir=${tfdir}"/tpl-fsLR"

##### 1) Project the subject's BOLD data to their native freesurfer surface
mri_vol2surf --src ${ssprepdir}/func/sub-${subid}_ses-${sesid}_task-rest_space-T1w_desc-preproc_bold.nii.gz \
  --out ${sssurfdir}/sub-${subid}_ses-${sesid}_task-rest_space-T1w_desc-preproc_bold_lh.mgh \
  --regheader sub-${subid} --hemi lh # need this
mri_vol2surf --src ${ssprepdir}/func/sub-${subid}_ses-${sesid}_task-rest_space-T1w_desc-preproc_bold.nii.gz \
  --out ${sssurfdir}/sub-${subid}_ses-${sesid}_task-rest_space-T1w_desc-preproc_bold_rh.mgh \
  --regheader sub-${subid} --hemi rh # need this

# View the BOLD data on the subject's native freesurfer surface
freeview -f ${SUBJECTS_DIR}/sub-${subid}/surf/lh.pial:overlay=${sssurfdir}/sub-${subid}_ses-${sesid}_task-rest_space-T1w_desc-preproc_bold_lh.mgh:overlay_threshold=2,5

##### 2)
mris_convert ${ssfreedir}/surf/lh.sphere ${sssurfdir}/lh.sphere.gii # need this
mris_convert ${ssfreedir}/surf/rh.sphere ${sssurfdir}/rh.sphere.gii # need this

##### 3)
mri_convert ${sssurfdir}/sub-${subid}_ses-${sesid}_task-rest_space-T1w_desc-preproc_bold_lh.mgh \
  ${sssurfdir}/sub-${subid}_ses-${sesid}_task-rest_space-T1w_desc-preproc_bold_lh.func.gii # need this
mri_convert ${sssurfdir}/sub-${subid}_ses-${sesid}_task-rest_space-T1w_desc-preproc_bold_rh.mgh \
  ${sssurfdir}/sub-${subid}_ses-${sesid}_task-rest_space-T1w_desc-preproc_bold_rh.func.gii # need this

##### 4)
wb_shortcuts -freesurfer-resample-prep ${ssfreedir}/surf/lh.white \
  ${ssfreedir}/surf/lh.pial \
  ${ssfreedir}/surf/lh.sphere.reg \
  ${hcptempdir}/fs_LR-deformed_to-fsaverage.L.sphere.32k_fs_LR.surf.gii \
  ${sssurfdir}/lh.midthickness.surf.gii \
  ${sssurfdir}/sub-${subid}.L.midthickness.32k_fs_LR.surf.gii \
  ${sssurfdir}/lh.sphere.reg.surf.gii

##### 5)
wb_command -metric-resample ${sssurfdir}/sub-${subid}_ses-${sesid}_task-rest_space-T1w_desc-preproc_bold_lh.func.gii \
  ${sssurfdir}/lh.sphere.reg.surf.gii \
  ${hcptempdir}/fs_LR-deformed_to-fsaverage.L.sphere.32k_fs_LR.surf.gii \
  ADAP_BARY_AREA \
  ${sssurfdir}/sub-${subid}_ses-${sesid}.task-rest.L.32k_fs_LR.func.gii \
  -area-surfs ${sssurfdir}/lh.midthickness.surf.gii \
  ${sssurfdir}/sub-${subid}.L.midthickness.32k_fs_LR.surf.gii #[new-sphere-vertex-areas]

##### 6)
wb_command -set-structure ${sssurfdir}/sub-MWMH212_ses-2.task-rest.L.32k_fs_LR.func.gii CORTEX_LEFT

# View the BOLD data on the fsLR32k surface
wb_view ${sssurfdir}/sub-${subid}.L.midthickness.32k_fs_LR.surf.gii \
  ${sssurfdir}/sub-${subid}_ses-${sesid}.task-rest.L.32k_fs_LR.func.gii \
  ${ssprepdir}/anat/sub-${subid}_ses-${sesid}_desc-preproc_T1w.nii.gz
