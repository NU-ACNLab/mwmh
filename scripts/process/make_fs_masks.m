function make_fs_masks(subid, sesid, task, bidsdir, fmriprepdir, outdir)

%%%%%%%%%%%%%%%%%%%%%%
% This makes several erosions of WM masks, including no erosion.
% JDP 8/14/12, modified from TOL script; modified for NU/Matlab Oct. 2020
%
% The outputs (e.g., 'sub-INET003_space-MNI152NLin6Asym_label-WM_probseg_0.9mask_res-2_ero3.nii.gz')
% are written into the subject's overall 'anat' folder.
%
% First input is subid ID (e.g., 'INET003'; assumes BIDS structure); second is fmriprep
% directory (e.g., '/projects/b1081/iNetworks/Nifti/derivatives/preproc_fmriprep-20.2.0');
% third is probabilistic threshold to start erosions
% also assumes fmriprep directory structure as our standard
%

%%%%%% change parameters if desired %%%%%%
%subid = 'MWMH352'
%sesid = 1
%task = 'rest'
%bidsdir = '/projects/b1108/studies/mwmh/data/raw/neuroimaging/bids'
%fmriprepdir = '/projects/b1108/studies/mwmh/data/processed/neuroimaging/fmriprep'
%outdir = '/projects/b1108/studies/mwmh/data/processed/neuroimaging/masks'

sesid = num2str(sesid)

space = 'MNI152NLin6Asym';
%prefix = ['sub-' subid '_ses-' sesid];
%meta = fileread([bidsdir '/sub-' subid '/ses-' sesid '/anat/' prefix '_T1w.json'])
%meta = jsonencode(meta)

voxdim = '0.8'; %voxel size... TO DO: would ideally read from json, but don't seem to be able to parse
eroiterwm = 4; %number of erosions to perform
WMprobseg_thresh = 0.9;
%------------
WMprobseg = ['sub-' subid '_space-' space '_label-WM_probseg.nii.gz'];
WMmaskname = ['sub-' subid  '_space-' space '_label-WM_probseg_' num2str(WMprobseg_thresh) 'mask.nii.gz'];
anat_dir= [fmriprepdir '/sub-' subid '/anat/']; %will need to change this if get individual session anat
 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% TO DO: make sure specifying full paths

%%% first, use ANTs to warp T1 and WMprobseg images into MNI in 111 space, if they don't yet exist %%%
antsdir = '/projects/b1081/Scripts/antsbin/ANTS-build/Examples/';
T1_templateLoc = ['/projects/b1081/Atlases/templateflow/tpl-' space '/tpl-' space '_res-01_T1w.nii.gz'];
inNames = {['sub-' subid '_desc-preproc_T1w.nii.gz'], ['sub-' subid '_label-WM_probseg.nii.gz']};
outNames = {['sub-' subid '_space-' space '_desc-preproc_T1w.nii.gz'], WMprobseg};

suboutdir = [outdir '/sub-' subid]
if ~exist([suboutdir])
    mkdir(suboutdir);
end

for tform = 1:length(inNames)
    if ~exist([outdir '/' outNames{tform}], 'file')
        system([antsdir 'antsApplyTransforms --verbose -i ' anat_dir inNames{tform} ' -o ' suboutdir '/' outNames{tform} ' -r ' T1_templateLoc [' \' '-t '] anat_dir 'sub-' subid '_from-T1w_to-' space '_mode-image_xfm.h5']);
    end
end


%%% threshold at WMprobseg_thresh and binarize %%%
system(['module load fsl; fslmaths ' anat_dir WMprobseg  ' -thr ' num2str(WMprobseg_thresh) ' -bin ' suboutdir '/' WMmaskname]);


%%% erode cerebral WM mask to avoid possible gray matter contamination %%%
%!!!!!!!!!! Line below is a problem
system(['module load singularity; singularity exec -B /projects/b1108:/projects/b1108 /projects/b1108/software/singularity_images/afni_make_build_AFNI_22.2.04.sif 3dresample -dxyz ' voxdim ' ' voxdim ' ' voxdim ' -prefix ' suboutdir '/' WMmaskname(1:end-7) '_res-' voxdim '.nii.gz -input ' suboutdir '/' WMmaskname]);
system(['module load fsl; fslmaths ' suboutdir '/' WMmaskname(1:end-7) '_res-' voxdim '.nii.gz -bin ' suboutdir '/' WMmaskname(1:end-7) '_res-' voxdim '_ero0.nii.gz']);

iter = 1;
while iter <= eroiterwm
	system(['module load fsl; fslmaths ' suboutdir '/' WMmaskname ' -kernel 3D -ero ' suboutdir '/' WMmaskname]);
    
    system(['module load AFNI; 3dresample -dxyz ' voxdim ' ' voxdim ' ' voxdim ' -prefix ' suboutdir '/' WMmaskname(1:end-7) '_res-' voxdim '.nii.gz -input ' suboutdir '/' WMmaskname ' -overwrite']);	

    system(['module load fsl; fslmaths ' suboutdir '/' WMmaskname(1:end-7) '_res-' voxdim '.nii.gz -bin ' suboutdir '/' WMmaskname(1:end-7) '_res-' voxdim '_ero' num2str(iter) '.nii.gz']);
    iter = iter + 1;
end

%%% remove unnecessary files %%%
system(['rm ' suboutdir '/' WMmaskname ' ' suboutdir '/' WMmaskname(1:end-7) '_res-' voxdim '.nii.gz']);

end
