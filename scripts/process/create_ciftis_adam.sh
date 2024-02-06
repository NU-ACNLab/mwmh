### This script creates ciftis from subject fmri data
###
### https://neurostars.org/t/volume-to-surface-mapping-mri-vol2surf-using-fmriprep-outputs/4079/13
### https://www.humanconnectome.org/software/workbench-command
### https://surfer.nmr.mgh.harvard.edu/fswiki/mri_vol2vol
### https://fsl.fmrib.ox.ac.uk/fsl/fslwiki/FNIRT/UserGuide#Now_what.3F_--_applywarp.21
### Resampling-FreeSurfer-HCP.pdf
###
### Ellyn Butler & Adam Pines
### February 4, 2024


subid="MWMH212"
sesid="2"


# load needed modules (maybe not needed on your cluster)
#ml biology #what is this needed for?
#ml workbench
#ml freesurfer


##### 0) set file paths
neurodir=/projects/b1108/studies/mwmh/data/processed/neuroimaging
#neurodir=/Users/flutist4129/Documents/Northwestern/studies/mwmh/data/processed/neuroimaging

# set surf directory
surfdir=${neurodir}/fmriprep_23.1.4/sub-${subid}/ses-${sesid}/anat

# set t1 space fmri volume location
VolumefMRI=${neurodir}/fmriprep_23.1.4/sub-${subid}/ses-${sesid}/func/sub-${subid}_ses-${sesid}_task-rest_space-T1w_desc-preproc_bold.nii.gz

# this is the feesurfer surf dir: for registration (spherical)
freedir=${neurodir}/fmriprep_23.1.4/sourcedata/freesurfer/sub-${subid}
fsurfdir=${neurodir}/fmriprep_23.1.4/sourcedata/freesurfer/sub-${subid}/surf

# this one is to-be-created as an intermediate
nativesurfMRI_L=${neurodir}/surf/sub-${subid}/ses-${sesid}/sub-${subid}_ses-${sesid}_task-rest.L.native.func.gii
nativesurfMRI_R=${neurodir}/surf/sub-${subid}/ses-${sesid}/sub-${subid}_ses-${sesid}_task-rest.R.native.func.gii

# and then these are output
fslrfMRI_L=${neurodir}/surf/sub-${subid}/ses-${sesid}/sub-${subid}_ses-${sesid}_task-rest.L.fslr.func.gii
fslrfMRI_R=${neurodir}/surf/sub-${subid}/ses-${sesid}/sub-${subid}_ses-${sesid}_task-rest.R.fslr.func.gii

# hcp directory
hcptempdir=/projects/b1108/hcp/global/templates/standard_mesh_atlases/resample_fsaverage

# fslr midthickness
midthick_L=/projects/b1108/templates/HCP_S1200_GroupAvg_v1/S1200.L.midthickness_MSMAll.32k_fs_LR.surf.gii
midthick_R=/projects/b1108/templates/HCP_S1200_GroupAvg_v1/S1200.L.midthickness_MSMAll.32k_fs_LR.surf.gii
#midthick_L=/Users/flutist4129/Documents/Northwestern/templates/HCP_S1200_GroupAvg_v1/S1200.L.midthickness_MSMAll.32k_fs_LR.surf.gii
#midthick_R=/Users/flutist4129/Documents/Northwestern/templates/HCP_S1200_GroupAvg_v1/S1200.R.midthickness_MSMAll.32k_fs_LR.surf.gii


##### 1) map t1-space bold to native freesurfer (note: no -volume-roi flag, assuming this is an SNR mask)
# left
wb_command -volume-to-surface-mapping ${VolumefMRI} ${surfdir}/sub-${subid}_ses-${sesid}_hemi-L_midthickness.surf.gii \
  ${nativesurfMRI_L} -ribbon-constrained ${surfdir}/sub-${subid}_ses-${sesid}_hemi-L_white.surf.gii \
  ${surfdir}/sub-${subid}_ses-${sesid}_hemi-L_pial.surf.gii

# right
wb_command -volume-to-surface-mapping ${VolumefMRI} ${surfdir}/sub-${subid}_ses-${sesid}_hemi-R_midthickness.surf.gii \
  ${nativesurfMRI_R} -ribbon-constrained ${surfdir}/sub-${subid}_ses-${sesid}_hemi-R_white.surf.gii \
  ${surfdir}/sub-${subid}_ses-${sesid}_hemi-R_pial.surf.gii

##### 2) dilate by ten, consistent b/w fmriprep and dcan hcp pipeline
# (would love to know how they converged on this value. Note: input and output are same)
# left
wb_command -metric-dilate ${nativesurfMRI_L} \
  ${surfdir}/sub-${subid}_ses-${sesid}_hemi-L_midthickness.surf.gii 10 \
  ${nativesurfMRI_L} -nearest

# right
wb_command -metric-dilate ${nativesurfMRI_R} \
  ${surfdir}/sub-${subid}_ses-${sesid}_hemi-R_midthickness.surf.gii 10 \
  ${nativesurfMRI_R} -nearest

##### 3) convert .reg files into giftis
# left
wb_shortcuts -freesurfer-resample-prep ${fsurfdir}/lh.white ${fsurfdir}/lh.pial \
  ${fsurfdir}/lh.sphere.reg ${hcptempdir}/fs_LR-deformed_to-fsaverage.L.sphere.32k_fs_LR.surf.gii \
  ${surfdir}/sub-${subid}.L.midthickness.native.surf.gii \
  ${fsurfdir}/sub-${subid}.L.midthickness.32k_fs_LR.surf.gii ${fsurfdir}/lh.sphere.reg.surf.gii

# right
wb_shortcuts -freesurfer-resample-prep ${fsurfdir}/rh.white $fsurfdir/rh.pial \
  ${fsurfdir}/rh.sphere.reg ${hcptempdir}/fs_LR-deformed_to-fsaverage.R.sphere.32k_fs_LR.surf.gii \
  ${surfdir}/sub-${subj}.R.midthickness.native.surf.gii \
  ${fsurfdir}/sub-${subid}.R.midthickness.32k_fs_LR.surf.gii ${fsurfdir}/rh.sphere.reg.surf.gii

##### 4) resample native surface to fslr
# (note: omission of roi use again)
# left
wb_command -metric-resample $nativesurfMRI_L ${fsurfdir}/lh.sphere.reg.surf.gii \
  ${hcptempdir}/fs_LR-deformed_to-fsaverage.L.sphere.32k_fs_LR.surf.gii ADAP_BARY_AREA \
  ${fslrfMRI_L} -area-surfs ${surfdir}/sub-${subid}_ses-${sesid}_hemi-L_midthickness.surf.gii \
  ${midthick_L}

# right
wb_command -metric-resample $nativesurfMRI_R ${fsurfdir}/rh.sphere.reg.surf.gii \
  ${hcptempdir}/fs_LR-deformed_to-fsaverage.R.sphere.32k_fs_LR.surf.gii ADAP_BARY_AREA \
  ${fslrfMRI_R} -area-surfs ${surfdir}/sub-${subid}_ses-${sesid}_hemi-R_midthickness.surf.gii \
  ${midthick_R}

##### 5) Set the structure parameter so that wb_view knows how to display the data
wb_command -set-structure ${sssurfdir}/sub-${subid}_ses-${sesid}.task-rest.L.32k_fs_LR.func.gii CORTEX_LEFT
wb_command -set-structure ${sssurfdir}/sub-${subid}_ses-${sesid}.task-rest.R.32k_fs_LR.func.gii CORTEX_RIGHT

##### 6) Convert freesurfer T1w image to a nifti
mri_convert ${freedir}/mri/T1.mgz ${neurodir}/surf/sub-${subid}/ses-${sesid}/fs_T1w.nii.gz

# View the BOLD data on the fsLR32k surface (VERY USEFUL)... doesn't look good
wb_view ${neurodir}/surf/sub-${subid}/ses-${sesid}/sub-${subid}.L.midthickness.32k_fs_LR.surf.gii \
  ${neurodir}/surf/sub-${subid}/ses-${sesid}/sub-${subid}_ses-${sesid}_task-rest.L.fslr.func.gii \
  ${neurodir}/surf/sub-${subid}/ses-${sesid}/sub-${subid}.R.midthickness.32k_fs_LR.surf.gii \
  ${neurodir}/surf/sub-${subid}/ses-${sesid}/sub-${subid}_ses-${sesid}_task-rest.R.fslr.func.gii \
  ${neurodir}/surf/sub-${subid}/ses-${sesid}/fs_T1w.nii.gz

##### 6) https://neurostars.org/t/any-way-to-convert-a-metric-gifti-to-a-scalar-cifti/19623
