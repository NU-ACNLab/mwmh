### This script adapts code from ChatGPT to create ciftis from subject fmri data
###
### https://neurostars.org/t/volume-to-surface-mapping-mri-vol2surf-using-fmriprep-outputs/4079/13
### https://www.humanconnectome.org/software/workbench-command
### https://surfer.nmr.mgh.harvard.edu/fswiki/mri_vol2vol
### https://fsl.fmrib.ox.ac.uk/fsl/fslwiki/FNIRT/UserGuide#Now_what.3F_--_applywarp.21
### Resampling-FreeSurfer-HCP.pdf
### Oct 19, 2023: This code is currently configured for a subject that has one session
###
### Ellyn Butler
### September 26, 2023 - January 24, 2023

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

#srun --x11 -N 1 -n 1 --account=p31521 --mem=20G --partition=short --time=4:00:00 --pty bash -l

# Local
#ssfreedir="/Users/flutist4129/Documents/Northwestern/studies/mwmh/data/processed/neuroimaging/fmriprep_23.1.4/sourcedata/freesurfer/sub-"${subid}
#ssprepdir="/Users/flutist4129/Documents/Northwestern/studies/mwmh/data/processed/neuroimaging/fmriprep_23.1.4/sub-"${subid}"/ses-"${sesid}
#sssurfdir="/Users/flutist4129/Documents/Northwestern/studies/mwmh/data/processed/neuroimaging/surf/sub-"${subid}"/ses-"${sesid}
#hcptempdir="/Users/flutist4129/Documents/Northwestern/hcp/global/templates/standard_mesh_atlases/resample_fsaverage"
#export SUBJECTS_DIR="/Users/flutist4129/Documents/Northwestern/studies/mwmh/data/processed/neuroimaging/fmriprep_23.1.4/sourcedata/freesurfer"
#tfdir="/Users/flutist4129/Documents/templateflow"
#fslrdir=${tfdir}"/tpl-fsLR"

##### 0)

# a) first calculating the transformation of a T1 image that is in sync with your
# fMRI data to the freesurfer space using `fslregister`. Make sure to write out
# the transformation file 'register.dat'
fslregister --mov ${ssprepdir}/anat/sub-MWMH212_ses-2_desc-preproc_T1w.nii.gz \
  --s sub-${subid} --reg ${sssurfdir}/register.dat
  # January 17, 2024: WARNING: possible left-right reversal... hwo do I check this?
# to check results, run the following command (looks good!)
#tkregisterfv --mov ${ssprepdir}/anat/sub-MWMH212_ses-2_desc-preproc_T1w.nii.gz \
#  --reg ${sssurfdir}/register.dat --surf orig
# January 24, 2024: This works, but mri_vol2vol is intractible memory-wise, so
# I am going to try fsl instead

#mri_convert ${ssfreedir}/mri/T1.mgz ${sssurfdir}/T1_freesurfer.nii.gz

#flirt -in ${ssprepdir}/anat/sub-MWMH212_ses-2_desc-preproc_T1w.nii.gz \
#      -ref ${sssurfdir}/T1_freesurfer.nii.gz \
#      -out ${sssurfdir}/registeredT1.nii.gz \
#      -omat ${sssurfdir}/registration_matrix.mat \
#      -dof 12

#rm ${sssurfdir}/registeredT1.nii.gz

# b) apply this registration file to the fMRI data using `mris_preproc` with
# `--target fsaverage` and --iv set to the path of your register.dat file.
# ... I think I actually want to get it into the freesurfer T1w volume space
# ... mri_vol2vol not working memory wise. either getting a bus error if request
# less than 20G of memory, or the process is getting killed. time to try ANTs

#applywarp --in=${ssprepdir}/func/sub-${subid}_ses-${sesid}_task-rest_space-T1w_desc-preproc_bold.nii.gz \
#          --ref=${sssurfdir}/T1_freesurfer.nii.gz \
#          --out=${sssurfdir}/sub-${subid}_ses-${sesid}_task-rest_space-fs_desc-preproc_bold.nii.gz \
#          --premat=${sssurfdir}/registration_matrix.mat \
#          --interp=trilinear


mri_vol2vol --reg ${sssurfdir}/register.dat \
            --mov ${ssprepdir}/func/sub-${subid}_ses-${sesid}_task-rest_space-T1w_desc-preproc_bold.nii.gz \
            --fstarg \
            --o ${sssurfdir}/sub-${subid}_ses-${sesid}_task-rest_space-fs_desc-preproc_bold.nii.gz \
            --interp nearest

##### 1) Project the subject's BOLD data to their native freesurfer surface
mri_vol2surf --src ${sssurfdir}/sub-${subid}_ses-${sesid}_task-rest_space-fs_desc-preproc_bold.nii.gz \
  --out ${sssurfdir}/sub-${subid}_ses-${sesid}_task-rest_space-fs_desc-preproc_bold_lh.mgh \
  --regheader sub-${subid} --hemi lh
mri_vol2surf --src ${sssurfdir}/sub-${subid}_ses-${sesid}_task-rest_space-fs_desc-preproc_bold.nii.gz \
  --out ${sssurfdir}/sub-${subid}_ses-${sesid}_task-rest_space-fs_desc-preproc_bold_rh.mgh \
  --regheader sub-${subid} --hemi rh

# View the BOLD data on the subject's native freesurfer surface
freeview -f ${SUBJECTS_DIR}/sub-${subid}/surf/lh.pial:overlay=${sssurfdir}/sub-${subid}_ses-${sesid}_task-rest_space-fs_desc-preproc_bold_lh.mgh:overlay_threshold=2,5

##### 2) Convert the freesurfer spherical surface to gifti format
mris_convert ${ssfreedir}/surf/lh.sphere ${sssurfdir}/lh.sphere.gii
mris_convert ${ssfreedir}/surf/rh.sphere ${sssurfdir}/rh.sphere.gii

##### 3) Convert the BOLD data on the subject's native freesurfer surface to gifti format
mri_convert ${sssurfdir}/sub-${subid}_ses-${sesid}_task-rest_space-fs_desc-preproc_bold_lh.mgh \
  ${sssurfdir}/sub-${subid}_ses-${sesid}_task-rest_space-fs_desc-preproc_bold_lh.func.gii
mri_convert ${sssurfdir}/sub-${subid}_ses-${sesid}_task-rest_space-fs_desc-preproc_bold_rh.mgh \
  ${sssurfdir}/sub-${subid}_ses-${sesid}_task-rest_space-fs_desc-preproc_bold_rh.func.gii

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
wb_command -metric-resample ${sssurfdir}/sub-${subid}_ses-${sesid}_task-rest_space-fs_desc-preproc_bold_lh.func.gii \
  ${sssurfdir}/lh.sphere.reg.surf.gii \
  ${hcptempdir}/fs_LR-deformed_to-fsaverage.L.sphere.32k_fs_LR.surf.gii \
  ADAP_BARY_AREA \
  ${sssurfdir}/sub-${subid}_ses-${sesid}.task-rest.L.32k_fs_LR.func.gii \
  -area-surfs ${sssurfdir}/lh.midthickness.surf.gii \
  ${sssurfdir}/sub-${subid}.L.midthickness.32k_fs_LR.surf.gii
wb_command -metric-resample ${sssurfdir}/sub-${subid}_ses-${sesid}_task-rest_space-fs_desc-preproc_bold_rh.func.gii \
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
