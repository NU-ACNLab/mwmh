### This script adapts code from ChatGPT to create ciftis from subject fmri data
### https://neurostars.org/t/volume-to-surface-mapping-mri-vol2surf-using-fmriprep-outputs/4079/13
### https://www.humanconnectome.org/software/workbench-command
###
### Ellyn Butler
### September 26, 2023

subid="MWMH212"
sesid="2"
# Quest
ssfreedir="/projects/b1108/studies/mwmh/data/processed/neuroimaging/fmriprep_23.1.4/sourcedata/freesurfer/sub-"${subid}
ssprepdir="/projects/b1108/studies/mwmh/data/processed/neuroimaging/fmriprep_23.1.4/sub-"${subid}"/ses-"${sesid}
sssurfdir="/projects/b1108/studies/mwmh/data/processed/neuroimaging/surf/sub-"${subid}"/ses-"${sesid}
export SUBJECTS_DIR="/projects/b1108/studies/mwmh/data/processed/neuroimaging/fmriprep_23.1.4/sourcedata/freesurfer"
tfdir="/projects/b1108/templateflow"
fslrdir=${tfdir}"/tpl-fsLR"

# Local
ssfreedir="/Users/flutist4129/Documents/Northwestern/studies/mwmh/data/processed/neuroimaging/fmriprep_23.1.4/sourcedata/freesurfer/sub-"${subid}
ssprepdir="/Users/flutist4129/Documents/Northwestern/studies/mwmh/data/processed/neuroimaging/fmriprep_23.1.4/sub-"${subid}"/ses-"${sesid}
sssurfdir="/Users/flutist4129/Documents/Northwestern/studies/mwmh/data/processed/neuroimaging/surf/sub-"${subid}"/ses-"${sesid}
export SUBJECTS_DIR="/Users/flutist4129/Documents/Northwestern/studies/mwmh/data/processed/neuroimaging/fmriprep_23.1.4/sourcedata/freesurfer"
tfdir="/Users/flutist4129/Documents/templateflow"
fslrdir=${tfdir}"/tpl-fsLR"

# 1. OLD: Surface reconstruction from T1w
#    Use FreeSurfer to obtain the cortical surface from your T1w image.
#    DONE WITH FMRIPREP

#recon-all -s subjectID -i path/to/T1w.nii.gz -all

# 1. Create new version of transform file from T1w to fsnative that is compatible
#    with freesurfer

#lta_convert --initk ${ssprepdir}/sub-${subid}_ses-${sesid}_from-T1w_to-fsnative_mode-image_xfm.txt \ # Sept 28: can't handle this file... maybe only affines work
#  --outlta ${sssurfdir}/sub-${subid}_ses-${sesid}_T1w_target-fsnative_affine.lta \
#  --outreg ${sssurfdir}/sub-${subid}_ses-${sesid}_T1w_target-fsnative_affine.dat \
#  --src ${ssprepdir}/sub-${subid}_ses-${sesid}_desc-preproc_T1w.nii.gz \
#  --trg ${ssfreedir}/mri/T1.mgz --subject sub-${subid}_ses-${sesid}

# 2. Mapping fMRI data to subject surface:
#    Convert the FreeSurfer surface and volumetric data to the gifti/cifti
#    format that can be read by the Connectome Workbench.
#NOTE (Sept 28): I don't have these regular outputs from freesurfer with fmriprep
#mri_convert subjectID/mri/brain.mgz brain.nii.gz
#mri_convert subjectID/mri/orig.mgz orig.nii.gz

#    Map the fMRI data to the subject's surface using FreeSurfer:
#mri_vol2surf --mov path/to/fmri_data.nii.gz --hemi lh --src orig.nii.gz --out lh.fmri_on_surface.mgh --regheader subjectID
#mri_vol2surf --mov path/to/fmri_data.nii.gz --hemi rh --src orig.nii.gz --out rh.fmri_on_surface.mgh --regheader subjectID

# Sept 28: What is the --regheader flag doing? Defining the output space,
# but I'd like it to be the subject's own surface, and it won't let me give the full path
# If I am going straight to fsaverage5, shouldn't I start in a standard space?
# gives output with --regheader as fsaverage5
mri_vol2surf --src ${ssprepdir}/func/sub-${subid}_ses-${sesid}_task-rest_space-T1w_desc-preproc_bold.nii.gz \
  --out ${sssurfdir}/sub-${subid}_ses-${sesid}_task-rest_space-T1w_desc-preproc_bold_lh.mgh \
  --regheader sub-${subid} --hemi lh
mri_vol2surf --src ${ssprepdir}/func/sub-${subid}_ses-${sesid}_task-rest_space-T1w_desc-preproc_bold.nii.gz \
  --out ${sssurfdir}/sub-${subid}_ses-${sesid}_task-rest_space-T1w_desc-preproc_bold_rh.mgh \
  --regheader sub-${subid} --hemi rh

freeview -f ${SUBJECTS_DIR}/sub-${subid}/surf/lh.pial:overlay=${sssurfdir}/sub-${subid}_ses-${sesid}_task-rest_space-T1w_desc-preproc_bold_lh.mgh:overlay_threshold=2,5

# 3. Register subject surface to fsLR32k:
#    You'll need to register your subject's cortical surface to the fsLR32k
#    template. This involves a spherical registration (which doesn' depend on
#    T2w data).
mris_convert ${ssfreedir}/surf/lh.sphere ${sssurfdir}/lh.sphere.gii
wb_command -surface-sphere-project-unproject ${fslrdir}/tpl-fsLR_hemi-L_den-32k_sphere.surf.gii ${sssurfdir}/lh.sphere.gii ${sssurfdir}/sub-${subid}_ses-${sesid}_lh.sphere.reg
wb_command -surface-sphere-project-unproject subjectID/surf/rh.sphere fsLR.R.sphere.reg.surf.gii subjectID/surf/rh.sphere.reg

# 4. Map fMRI data to fsLR32k:
#    Use the Connectome Workbench to map the fMRI data on the individual's
#    surface to the fsLR32k space.
wb_command -metric-resample lh.fmri_on_surface.mgh subjectID/surf/lh.sphere.reg fsLR.L.sphere.reg.surf.gii ADAP_BARY_AREA lh.fmri_on_fsLR32k.func.gii -area-metrics subjectID/surf/lh.midthickness.area.surf.gii fsLR.L.midthickness.32k_fs_LR.area.surf.gii
wb_command -metric-resample rh.fmri_on_surface.mgh subjectID/surf/rh.sphere.reg fsLR.R.sphere.reg.surf.gii ADAP_BARY_AREA rh.fmri_on_fsLR32k.func.gii -area-metrics subjectID/surf/rh.midthickness.area.surf.gii fsLR.R.midthickness.32k_fs_LR.area.surf.gii

# 5. Combine hemispheres:
#    If you want to create a combined cifti file with data from both hemispheres:
wb_command -cifti-create-dense-timeseries combined_fsLR32k.dtseries.nii -left-metric lh.fmri_on_fsLR32k.func.gii -right-metric rh.fmri_on_fsLR32k.func.gii
