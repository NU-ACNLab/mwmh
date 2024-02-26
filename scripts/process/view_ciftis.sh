# View the BOLD data on the fsLR32k surface (VERY USEFUL)
wb_view ${anatoutdir}/sub-${subid}.L.midthickness.32k_fs_LR.surf.gii \
    ${fslrfMRI_L} \
    ${anatoutdir}/sub-${subid}.R.midthickness.32k_fs_LR.surf.gii \
    ${fslrfMRI_R} \
    ${anatoutdir}/fs_T1w.nii.gz

wb_view ${anatoutdir}/sub-${subid}.L.midthickness.32k_fs_LR.surf.gii \
    ${anatoutdir}/sub-${subid}.R.midthickness.32k_fs_LR.surf.gii \
    ${funcindir}/sub-${subid}_ses-${sesid}_task-${task}_space-fsLR_den-91k_bold.dtseries.nii \
    ${anatoutdir}/fs_T1w.nii.gz
