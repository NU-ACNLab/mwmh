% this function puts the structural mask into the resolution of the output
% space, which is assumed to be 2x2x2
function fnames = resample_masks(anat_string,QC,space)
    type_names = {'CSF','WB','GREY'}; % AD - removed WM mask resampling; using make_fs_masks.m output {'WM','CSF','WB','GREY'}
    types = {'label-CSF_probseg','desc-brain_mask','label-GM_probseg'}; %{'label-WM_probseg','label-CSF_probseg','desc-brain_mask','label-GM_probseg'}
    
    %system('module load singularity/latest');
    currentDir = pwd;
    cd(anat_string);
    
    for t = 1:length(types)
        
        thisName = ['sub-' QC.subjectID '_space-' space '_res-2_' types{t} '.nii.gz'];
        thisName_orig = ['sub-' QC.subjectID '_space-' space '_' types{t} '.nii.gz'];
        fnames.([type_names{t} 'maskfile']) = [anat_string thisName];
        
        % only make them if they don't exist
        if ~exist(fnames.([type_names{t} 'maskfile']))
            system(['module load singularity; singularity exec --containall -B /projects/b1108:/projects/b1108 /projects/b1108/software/singularity_images/afni_make_build_AFNI_22.2.04.sif 3dresample -dxyz 2 2 2 -prefix ' anat_string thisName ' -input ' anat_string thisName_orig]);
        end
    end