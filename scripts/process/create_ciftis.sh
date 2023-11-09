### This script adapts code from ChatGPT to create ciftis from subject fmri data
### https://netneurolab.github.io/neuromaps/user_guide/transformations.html
### Resampling-FreeSurfer-HCP.pdf
### Oct 19, 2023: This code is currently configured for a subject that has one session
###
### Ellyn Butler
### September 26, 2023 - November 9, 2023

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
surfdir="/Users/flutist4129/Documents/Northwestern/studies/mwmh/data/processed/neuroimaging/surf"
scriptsdir="/Users/flutist4129/Documents/Northwestern/studies/mwmh/scripts/process/"
ssfreedir="/Users/flutist4129/Documents/Northwestern/studies/mwmh/data/processed/neuroimaging/fmriprep_23.1.4/sourcedata/freesurfer/sub-"${subid}
ssprepdir="/Users/flutist4129/Documents/Northwestern/studies/mwmh/data/processed/neuroimaging/fmriprep_23.1.4/sub-"${subid}"/ses-"${sesid}
sssurfdir="/Users/flutist4129/Documents/Northwestern/studies/mwmh/data/processed/neuroimaging/surf/sub-"${subid}"/ses-"${sesid}
hcptempdir="/Users/flutist4129/Documents/Northwestern/hcp/global/templates/standard_mesh_atlases/resample_fsaverage"
export SUBJECTS_DIR="/"
mysubs="/Users/flutist4129/Documents/Northwestern/studies/mwmh/data/processed/neuroimaging/fmriprep_23.1.4/sourcedata/freesurfer"
fssubs="/Applications/freesurfer/7.4.1/subjects"
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
freeview -f ${mysubs}/sub-${subid}/surf/lh.pial:overlay=${sssurfdir}/sub-${subid}_ses-${sesid}_task-rest_space-T1w_desc-preproc_bold_lh.mgh:overlay_threshold=2,5

##### 2) Resample surfaces into fsaverage
mri_surf2surf --sval ${sssurfdir}/sub-${subid}_ses-${sesid}_task-rest_space-T1w_desc-preproc_bold_lh.mgh \
  --tval ${sssurfdir}/sub-${subid}_ses-${sesid}_task-rest_space-fsaverage5_desc-preproc_bold_lh.mgh \
  --s ${mysubs}/sub-${subid} --trgsubject ${fssubs}/fsaverage5 --hemi lh --cortex
mri_surf2surf --sval ${sssurfdir}/sub-${subid}_ses-${sesid}_task-rest_space-T1w_desc-preproc_bold_rh.mgh \
  --tval ${sssurfdir}/sub-${subid}_ses-${sesid}_task-rest_space-fsaverage5_desc-preproc_bold_rh.mgh \
  --s ${mysubs}/sub-${subid} --trgsubject ${fssubs}/fsaverage5 --hemi rh --cortex

# View the BOLD data on fsaverage5 surface (Nov 9: looks good)
freeview -f ${fssubs}/fsaverage5/surf/lh.pial:overlay=${sssurfdir}/sub-${subid}_ses-${sesid}_task-rest_space-fsaverage5_desc-preproc_bold_lh.mgh:overlay_threshold=2,5

##### 3) Convert the BOLD data in fsaverage space to gifti format
mri_convert ${sssurfdir}/sub-${subid}_ses-${sesid}_task-rest_space-fsaverage5_desc-preproc_bold_lh.mgh \
  ${sssurfdir}/sub-${subid}_ses-${sesid}_task-rest_space-fsaverage5_desc-preproc_bold_lh.func.gii
mri_convert ${sssurfdir}/sub-${subid}_ses-${sesid}_task-rest_space-fsaverage5_desc-preproc_bold_rh.mgh \
  ${sssurfdir}/sub-${subid}_ses-${sesid}_task-rest_space-fsaverage5_desc-preproc_bold_rh.func.gii

wb_command -set-structure ${sssurfdir}/sub-${subid}_ses-${sesid}_task-rest_space-fsaverage5_desc-preproc_bold_lh.func.gii CORTEX_LEFT
wb_command -set-structure ${sssurfdir}/sub-${subid}_ses-${sesid}_task-rest_space-fsaverage5_desc-preproc_bold_rh.func.gii CORTEX_RIGHT

# Generate midthickness surfaces for lh and rh (if they don't already exist)
#mris_expand -thickness ${fssubs}/fsaverage5/surf/lh.white 0.5 ${surfdir}/lh.midthickness
#mris_expand -thickness ${fssubs}/fsaverage5/surf/rh.white 0.5 ${surfdir}/rh.midthickness

# Convert the midthickness surfaces to GIFTI format
mris_convert ${fssubs}/fsaverage5/surf/lh.pial ${surfdir}/lh.pial.surf.gii
mris_convert ${fssubs}/fsaverage5/surf/rh.pial ${surfdir}/rh.pial.surf.gii

wb_command -set-structure ${surfdir}/lh.pial.surf.gii CORTEX_LEFT
wb_command -set-structure ${surfdir}/rh.pial.surf.gii CORTEX_RIGHT

wb_view ${surfdir}/lh.pial.surf.gii \
  ${sssurfdir}/sub-${subid}_ses-${sesid}_task-rest_space-fsaverage5_desc-preproc_bold_lh.func.gii \
  ${surfdir}/rh.pial.surf.gii \
  ${sssurfdir}/sub-${subid}_ses-${sesid}_task-rest_space-fsaverage5_desc-preproc_bold_rh.func.gii # Nov 9: why isn't this working? Not seeing any data on the surface

wb_view ${hcptempdir}/fsaverage5_std_sphere.L.10k_fsavg_L.surf.gii \
  ${sssurfdir}/sub-${subid}_ses-${sesid}_task-rest_space-fsaverage5_desc-preproc_bold_lh.func.gii \
  ${hcptempdir}/fsaverage5_std_sphere.R.10k_fsavg_R.surf.gii \
  ${sssurfdir}/sub-${subid}_ses-${sesid}_task-rest_space-fsaverage5_desc-preproc_bold_rh.func.gii # Nov 9: why isn't this working? Not seeing any data on the surface... maybe functional data is all 0s because of earlier problem?

##### 4) (python script to get from fsaverage to fslr32k)

# (steps to get the midthickness? try just finding paths to midthickness in fslr32k directly)
python3 ${scriptsdir}/create_ciftis.py # ${subid} ${sesid}

# View the BOLD data on the fsLR32k surface
wb_command -set-structure ${sssurfdir}/sub-${subid}_ses-${sesid}_task-rest_space-fslr32k_desc-preproc_bold_lh.func.gii CORTEX_LEFT
wb_command -set-structure ${sssurfdir}/sub-${subid}_ses-${sesid}_task-rest_space-fslr32k_desc-preproc_bold_rh.func.gii CORTEX_RIGHT

# Nov 9: Not working. Seems like somehow vertices and TRs are getting confused
wb_view ${sssurfdir}/sub-${subid}.L.midthickness.32k_fs_LR.surf.gii \
  ${sssurfdir}/sub-${subid}_ses-${sesid}_space-fslr32k_task-rest_lh.func.gii \
  ${sssurfdir}/sub-${subid}.R.midthickness.32k_fs_LR.surf.gii \
  ${sssurfdir}/sub-${subid}_ses-${sesid}_space-fslr32k_task-rest_rh.func.gii \
  ${ssprepdir}/anat/sub-${subid}_ses-${sesid}_desc-preproc_T1w.nii.gz
