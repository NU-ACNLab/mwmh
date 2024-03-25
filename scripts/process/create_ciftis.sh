### This script creates ciftis from subject fmri data
###
### https://neurostars.org/t/volume-to-surface-mapping-mri-vol2surf-using-fmriprep-outputs/4079/13
### https://www.humanconnectome.org/software/workbench-command
### https://surfer.nmr.mgh.harvard.edu/fswiki/mri_vol2vol
### https://fsl.fmrib.ox.ac.uk/fsl/fslwiki/FNIRT/UserGuide#Now_what.3F_--_applywarp.21
### Resampling-FreeSurfer-HCP.pdf
###
### Ellyn Butler & Adam Pines
### February 4, 2024 - March 5, 2024


while getopts ":s:e:t:" option; do
    case "${option}" in
        s) 
          sub="${OPTARG}"
          ;;
        e) 
          ses="${OPTARG}"
          ;;
        t) 
          tasks="${OPTARG}"
          ;;
    esac
done

module load connectome_workbench/1.5.0

##### 0) set file paths
bidsdir=/projects/b1108/studies/mwmh/data/raw/neuroimaging/bids/${sub}/${ses}/func
neurodir=/projects/b1108/studies/mwmh/data/processed/neuroimaging

# set input directories
numses=`find ${neurodir}/fmriprep_23.2.0/${sub} -type d -name "ses-*" | wc -l`
if [ ${numses} == 1 ]; then
  anatindir=${neurodir}/fmriprep_23.2.0/${sub}/${ses}/anat
else
  anatindir=${neurodir}/fmriprep_23.2.0/${sub}/anat
fi
funcindir=${neurodir}/postproc/${sub}/${ses}/func

# set output directories
anatoutdir=${neurodir}/surf/${sub}/anat
mkdir ${neurodir}/surf/${sub}/
mkdir ${anatoutdir}
funcoutdir=${neurodir}/surf/${sub}/${ses}/func
mkdir ${neurodir}/surf/${sub}/${ses}/
mkdir ${funcoutdir}

# this is the feesurfer surf dir: for registration (spherical)
freedir=${neurodir}/fmriprep_23.2.0/sourcedata/freesurfer/${sub}

# hcp directory
hcptempdir=/projects/b1108/hcp/global/templates/standard_mesh_atlases/resampleaverage

# fslr midthickness
midthick_L=/projects/b1108/templates/HCP_S1200_GroupAvg_v1/S1200.L.midthickness_MSMAll.32k_LR.surf.gii
midthick_R=/projects/b1108/templates/HCP_S1200_GroupAvg_v1/S1200.L.midthickness_MSMAll.32k_LR.surf.gii

##### 1) Convert freesurfer T1w image to a nifti
mri_convert ${freedir}/mri/T1.mgz ${neurodir}/surf/${sub}/anat/fs_T1w.nii.gz

##### 2) convert .reg files into giftis
# left
wb_shortcuts -freesurfer-resample-prep ${freedir}/surf/lh.white ${freedir}/surf/lh.pial \
  ${freedir}/surf/lh.sphere.reg ${hcptempdir}/fs_LR-deformed_to-fsaverage.L.sphere.32k_LR.surf.gii \
  ${anatoutdir}/${sub}.L.midthickness.native.surf.gii \
  ${anatoutdir}/${sub}.L.midthickness.32k_LR.surf.gii \
  ${anatoutdir}/lh.sphere.reg.surf.gii

# right
wb_shortcuts -freesurfer-resample-prep ${freedir}/surf/rh.white ${freedir}/surf/rh.pial \
  ${freedir}/surf/rh.sphere.reg ${hcptempdir}/fs_LR-deformed_to-fsaverage.R.sphere.32k_LR.surf.gii \
  ${anatoutdir}/${sub}.R.midthickness.native.surf.gii \
  ${anatoutdir}/${sub}.R.midthickness.32k_LR.surf.gii \
  ${anatoutdir}/rh.sphere.reg.surf.gii

for sesid in ${sesids}; do
    for task in ${tasks}; do
      # set t1 space fmri volume location
      VolumefMRI=${funcindir}/${sub}_${ses}_task-${task}_space-T1w_desc-postproc_bold.nii.gz

      # this one is to-be-created as an intermediate
      nativesurfMRI_L=${funcoutdir}/${sub}_${ses}_task-${task}.L.native.func.gii
      nativesurfMRI_R=${funcoutdir}/${sub}_${ses}_task-${task}.R.native.func.gii

      # and then these are output
      fslrfMRI_L=${funcoutdir}/${sub}_${ses}_task-${task}.L.fslr.func.gii
      fslrfMRI_R=${funcoutdir}/${sub}_${ses}_task-${task}.R.fslr.func.gii

      ##### 3) map t1-space bold to native freesurfer (note: no -volume-roi flag, assuming this is an SNR mask)
      # left
      wb_command -volume-to-surface-mapping ${VolumefMRI} ${anatindir}/${sub}_${ses}_hemi-L_midthickness.surf.gii \
        ${nativesurfMRI_L} -ribbon-constrained ${anatindir}/${sub}_${ses}_hemi-L_white.surf.gii \
        ${anatindir}/${sub}_${ses}_hemi-L_pial.surf.gii

      # right
      wb_command -volume-to-surface-mapping ${VolumefMRI} ${anatindir}/${sub}_${ses}_hemi-R_midthickness.surf.gii \
        ${nativesurfMRI_R} -ribbon-constrained ${anatindir}/${sub}_${ses}_hemi-R_white.surf.gii \
        ${anatindir}/${sub}_${ses}_hemi-R_pial.surf.gii

      ##### 4) dilate by ten, consistent b/w fmriprep and dcan hcp pipeline
      # (would love to know how they converged on this value. Note: input and output are same)
      # left
      wb_command -metric-dilate ${nativesurfMRI_L} \
        ${anatindir}/${sub}_${ses}_hemi-L_midthickness.surf.gii 10 \
        ${nativesurfMRI_L} -nearest

      # right
      wb_command -metric-dilate ${nativesurfMRI_R} \
        ${anatindir}/${sub}_${ses}_hemi-R_midthickness.surf.gii 10 \
        ${nativesurfMRI_R} -nearest

      ##### 5) resample native surface to fslr
      # (note: omission of roi use again)
      # left
      wb_command -metric-resample ${nativesurfMRI_L} ${anatoutdir}/lh.sphere.reg.surf.gii \
        ${hcptempdir}/fs_LR-deformed_to-fsaverage.L.sphere.32k_LR.surf.gii ADAP_BARY_AREA \
        ${fslrfMRI_L} -area-surfs ${anatindir}/${sub}_${ses}_hemi-L_midthickness.surf.gii \
        ${midthick_L}

      # right
      wb_command -metric-resample ${nativesurfMRI_R} ${anatoutdir}/rh.sphere.reg.surf.gii \
        ${hcptempdir}/fs_LR-deformed_to-fsaverage.R.sphere.32k_LR.surf.gii ADAP_BARY_AREA \
        ${fslrfMRI_R} -area-surfs ${anatindir}/${sub}_${ses}_hemi-R_midthickness.surf.gii \
        ${midthick_R}

      ##### 6) Set the structure parameter so that wb_view knows how to display the data
      wb_command -set-structure ${fslrfMRI_L} CORTEX_LEFT
      wb_command -set-structure ${fslrfMRI_R} CORTEX_RIGHT

      ##### 7) Convert from gifti to cifti
      # https://neurostars.org/t/any-way-to-convert-a-metric-gifti-to-a-scalar-cifti/19623
      wb_command -cifti-create-dense-scalar ${funcoutdir}/${sub}_${ses}_task-${task}_space-fsLR_desc-postproc_bold.dscalar.nii \
        -left-metric ${fslrfMRI_L} \
        -right-metric ${fslrfMRI_R}
  done
done