function fcimage_corrmat_volume(datafile,FCdir,atlas)
% function fcimage_corrmat_volume()
% this function will make an ROI x ROI correlation matrix based on a set of
% volume ROIs and a list of files
%
% EXAMPLE: fcimage_corrmat_volume('EXAMPLESUB_DATALIST.xlsx','/projects/b1081/iNetworks/Nifti/derivatives/preproc_FCProc/','Seitzman300')
%
% CG - 03.26.2020
%%%%%%%%%%%%%%%%%

% Added August 18, 2022
addpath('/projects/b1108/studies/mwmh/scripts/process/gratton/')
addpath('/projects/b1108/software/bids-matlab')
addpath('/projects/b1081/Scripts/Scripts_general/NIfTI_20140122')

% August 18, 2022: for testing
datafile = '/projects/b1108/studies/mwmh/data/processed/neuroimaging/lists/test_list_for_motioncalc.xlsx';
FCdir = '/projects/b1108/studies/mwmh/data/processed/neuroimaging/fcon/';
atlas = 'Seitzman300'

%% Directory information
atlas_dir = '/projects/b1081/Atlases/';
outDir_top = [FCdir '/corrmats/' atlas '/'];
if ~exist(outDir_top)
    mkdir(outDir_top);
end

%% load in sub/session info
df = readtable(datafile); %reads into a table structure, with datafile top row as labels
numdatas=size(df.sub,1); %number of datasets to analyses (subs X sessions)

% organize for easier use
for i = 1:numdatas
    
    % reformat sub and run info as needed
    if isa(df.sub(i),'cell')
        subInfo(i).subjectID = df.sub{i}; % the more expected case
    elseif isa(df.sub(i),'double')  %to account for subject numbers that are all numeric
        subInfo(i).subjectID = num2str(df.sub(i)); %change to string to work with rest of code
    else
        error('can not recognize subject data type')
    end
    
    subInfo(i).session = df.sess(i); %session ID
    subInfo(i).condition = df.task{i}; %condition type (rest or name of task)
    subInfo(i).TR = df.TR(i,1); %TR (in seconds)
    subInfo(i).TRskip = df.dropFr(i); %number of frames to skip
    subInfo(i).topDir = df.topDir{i}; %initial part of directory structure
    subInfo(i).dataFolder = df.dataFolder{i}; % folder for data inputs (assume BIDS style organization otherwise)
    subInfo(i).confoundsFolder = df.confoundsFolder{i}; % folder for confound inputs (assume BIDS organization)
    subInfo(i).FDtype = df.FDtype{i,1}; %use FD or fFD for tmask, etc?
    %subInfo(i).runs = str2double(regexp(df.runs{i},',','split'))'; % get runs, converting to numerical array (other orientiation since that's what's expected
    %subInfo(i).space = space; %assuming same space for now... insert check
    %subInfo(i).res = res; %assuming same res for now.. insert check
end

%% ROI info
atlas_params = atlas_parameters_GrattonLab(atlas,atlas_dir);
roi_data = load_nii_wrapper(atlas_params.MNI_nii_file); %vox by 1


%% Loop through data, extract timecourses
for i = 1:numdatas
    
    fprintf('Subject %s, session %d\n',subInfo(i).subjectID,subInfo(i).session);
    
    sess_roi_timeseries_concat = [];
    tmask_concat = [];
    
    % outDir = outDir_top; % no real reason to keep BIDS - too spread out
    outDir = [outDir_top '/sub-' subInfo(i).subjectID];
    if ~exist(outDir) 
        mkdir(outDir);
    end
    
    %for j = 1:length(subInfo(i).runs)
        
        %fprintf('Run: %d\n',subInfo(i).runs(j));
        
        % FCprocessed file:
        procFile = sprintf('%s/sub-%s/ses-%d/func/sub-%s_ses-%d_task-%s_fmriprep_zmdt_resid_ntrpl_bpss_zmdt.nii.gz',...
            FCdir,subInfo(i).subjectID,subInfo(i).session,...
            subInfo(i).subjectID,subInfo(i).session,subInfo(i).condition);
        sess_data = load_nii_wrapper(procFile); %vox by timepoints
        
        sess_roi_timeseries = roi_average_timecourse(sess_data,roi_data);
        sess_roi_timeseries_concat = [sess_roi_timeseries_concat sess_roi_timeseries];
        
        % tmask file:
        tmaskFile = sprintf('%s/sub-%s/ses-%d/func/FD_outputs/sub-%s_ses-%d_task-%s_run-%d_desc-tmask_%s.txt',...
            FCdir,subInfo(i).subjectID,subInfo(i).session,...
            subInfo(i).subjectID,subInfo(i).session,subInfo(i).condition,subInfo(i).runs(j),subInfo(i).FDtype);
        tmask{j} = table2array(readtable(tmaskFile));
        tmask_concat = [tmask_concat; tmask{j}];
                
    %end
    
    % apply tmask to timeseries and calculate correlations
    corrmat = paircorr_mod(sess_roi_timeseries_concat(:,logical(tmask_concat))');
    
    fout_str = sprintf('%s/sub-%s_sess-%d_task-%s_corrmat_%s',outDir,subInfo(i).subjectID,subInfo(i).session,subInfo(i).condition,atlas);
    
    figure_corrmat_GrattonLab(corrmat,atlas_params,-1,1);
    saveas(gcf,[fout_str '.tiff'],'tiff');
    close(gcf);
    
    % save out files
    save([fout_str '.mat'],'sess_roi_timeseries','sess_roi_timeseries_concat','tmask','tmask_concat','corrmat');
    

end

end


