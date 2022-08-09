function FCPROCESS_GrattonLab(datafile,outdir,varargin)
% This script is the fcprocessing script, originally from the Petersen
% lab, now for the Gratton lab.
% FCPROCESS(datalist,outdir,varargin)
% Example:
% FCPROCESS_GrattonLab('EXAMPLESUB_DATALIST.xlsx','/projects/b1081/iNetworks/Nifti/derivatives/preproc_FCProc/','defaults2');
%
% The datalist specifies the data to process, and is a 10-column tab-delimited xlsx file:
% subid sessid taskid TR skipframes topDir dataFolder confoundsFolder FDtype runs
% e.g.:
% INET003	1	rest	 1.1	5	/projects/b1081/iNetworks/Nifti/derivatives	preproc_fmriprep-1.5.8_MOD5	preproc_fmriprep-1.5.8_MOD5 fFD 1,2,3,4,5,6,7
%
% We presume the BIDS file structure for fMRI data
%
% outdir: where to write files to (e.g., '/projects/iNetworks/Nifti/derivatives/FCProcess_initial/INET001/ses-1_task-rest/')
% IMPORTANT: fcp_process removes the /newtargetdir/sub/sess folder when it
% begins processing a new session, so DO NOT set the outdir to the directory
% where your 333 BOLD data exist - use a new directory, specific to FC
% data. 
%
% for now, force to always use tmask for processing, but should be able to
% change code to use 'ones' = just skip frames at the start of each run,
% but don't do scrubbing
%
% nuisance regressor toggle: 'fmriprep' or 'recalc'
% fmriprep: nuisance regressors are taken from fmriprep output
% recalc: recalculate nuisance regressors in the script (default since
% we've had intermittent issues with fmriprep global signal regressor)
%
% The processing order is:
%    demean/detrend (mask)
%    extract nuisance signals
%    multiple regression (mask)
%    *interpolate* (mask) %% this step takes a while, but faster now
%    temporal filter (butter1 filtfilt low-pass)
%    demean/detrend (mask)
%    [spatial blur (gauss_4dfp)] - NO LONGER DONE
%
% Not yet set up for computing task residuals
%
% originally written by: jdp 2/22/2012
% CG 2017: working off of T. Laumann's FCPROCESS_MSC.m version Editing to work with task residuals data
% CG 2019: editing to work at NU and with iNetworks data (rest)
%       example call: FCPROCESS_GrattonLab('EXAMPLESUB_DATALIST.xlsx','/projects/b1081/iNetworks/Nifti/derivatives/preproc_FCProc/','defaults2')

% Added on 08/03/2022 
addpath('/projects/b1108/studies/mwmh/scripts/process/gratton/')
addpath('/projects/b1108/software/bids-matlab')
addpath('/projects/b1081/Scripts/Scripts_general/NIfTI_20140122')

datafile = '/projects/b1108/studies/mwmh/data/processed/neuroimaging/lists/test_list_for_motioncalc.xlsx'
outdir = '/projects/b1108/studies/mwmh/data/processed/neuroimaging/fcon'

%% IMPORTANT VARIABLES
tmasktype = 'regular'; %'ones' or something else (ones = take everything except short periods at the start of each scan
space = 'MNI152NLin6Asym';
res = 'res-2'; %'','res-2' or 'res-3' (voxel resolutions for output)
GMthresh = 0.5; %used for nuis regressors. Check that these (esp WM/CSF look ok; GM mostly used for grayplot)
WMthresh = 0.9; %thresholded prior to FCprocess (make_fs_masks script), but keeping for QC variable
CSFthresh = 0.95;
set(0, 'DefaultFigureVisible', 'off'); % puts figures in the background while running



%% READ IN DATALIST

% read in the subject data including location, vcnum, and boldruns
df = readtable(datafile); %reads into a table structure, with datafile top row as labels
numdatas = size(df.sub,1); %number of datasets to analyses (subs X sessions)

for i=1:numdatas
    %experiment subject IDv
    if isa(df.sub(i),'cell')
        QC(i).subjectID = df.sub{i}; % the more expected case
    elseif isa(df.sub(i),'double')  %to account for subject numbers that are all numeric
        QC(i).subjectID = num2str(df.sub(i)); %change to string to work with rest of code
    else
        error('can not recognize subject data type')
    end

    subid = char(df.sub(i))
    sesid = num2str(df.sess(i))

    sesoutdir = [outdir '/sub-' subid '/ses-' sesid]
    % TO DO ^ strcat not behaving the same way
    
    QC(i).session = df.sess(i); %session ID
    QC(i).condition = df.task{i}; %condition type (rest or name of task)
    QC(i).TR = df.TR(i,1); %TR (in seconds)
    QC(i).TRskip = df.dropFr(i); %number of frames to skip
    QC(i).topDir = df.topDir{i}; %initial part of directory structure
    QC(i).dataFolder = df.dataFolder{i}; % folder for data inputs (assume BIDS style organization otherwise)
    QC(i).confoundsFolder = df.confoundsFolder{i}; % folder for confound inputs (assume BIDS organization)
    QC(i).FDtype = df.FDtype{i,1}; %use FD or fFD for tmask, etc?
    %QC(i).runs = str2double(regexp(df.runs{i},',','split'))'; % get runs, converting to numerical array (other orientiation since that's what's expected    
    QC(i).space = space;
    QC(i).res = res;
    QC(i).GMthresh = GMthresh;
    QC(i).WMthresh = WMthresh;
    QC(i).CSFthresh = CSFthresh;
    
    % to address potential residuals feild (to indicate residuals for task FC)
    if ismember('residuals',df.Properties.VariableNames)
        QC(i).residuals = df.residuals(i);
    else
        QC(i).residuals = 0; % assume these are not residuals if the field doesn't exist
    end
end

%% CHECK TEMPORAL MASKS
fprintf('CHECKING DATA, CONFOUNDS, AND TEMPORAL MASKS EXIST\n');

% check that data, confounds, and tmask files with right names all exist
for i = 1:numdatas
    %subid = char(df.sub(i));
    %sesid = df.sess(i);
    %fprintf(sesid)
    subid = df.sub(i);
    subid2 = char(df.sub(i));
    sesid = num2str(df.sess(i));
    sesoutdir = [outdir '/sub-' subid2 '/ses-' sesid];
    data_fstring1 = sprintf('%s/%s/fmriprep/sub-%s/ses-%d/func/',QC(i).topDir,QC(i).dataFolder,subid{1},df.sess(i));
    conf_fstring1 = sprintf('%s/%s/fmriprep/sub-%s/ses-%d/func/',QC(i).topDir,QC(i).confoundsFolder,subid{1},df.sess(i));
    all_fstring2 = sprintf('sub-%s_ses-%d_task-%s',subid{1},df.sess(i),QC(i).condition);

    if QC(i).residuals == 0 % the typical case
        bolddata_fname = [data_fstring1 all_fstring2 '_space-' space '_desc-preproc_bold.nii.gz'];
    else %if these are task FC that have been residualized
        bolddata_fname = [data_fstring1 all_fstring2 '_space-' space '_desc-preproc_bold_residuals.nii.gz'];
    end
    boldavg_fname = [conf_fstring1 all_fstring2 '_space-' space '_boldref.nii.gz']; %referent for alignment
    boldmask_fname = [conf_fstring1 all_fstring2 '_space-' space '_desc-brain_mask.nii.gz']; %fmriprep mask
    confounds_fname = [conf_fstring1 all_fstring2 '_desc-confounds_timeseries.tsv']; %if using the fmriprep regressor
    tmask_fname = [sesoutdir '/' all_fstring2 '_desc-tmask_' QC(i).FDtype '.txt']; %assume this is in confounds folder
        % TO DO ^ strcat not behaving the same way
    boldnii{i} = bolddata_fname;
    boldavgnii{i} = boldavg_fname;
    boldmasknii{i} = boldmask_fname;
    boldconf{i} = confounds_fname;
    boldtmask{i} = tmask_fname;
    boldmot_folder{i} = sesoutdir; % in this case, just give path/start so I can load different versions
        
    if ~exist(bolddata_fname)
        error(['Data does not exist. Check paths and FMRIPREP output for: ' bolddata_fname]);
    end
        
    if ~exist(boldavg_fname)
        error(['Bold ref does not exist. Check paths and FMRIPREP output for: ' boldref_fname]);
    end
        
    if ~exist(boldmask_fname)
        error(['Bold mask does not exist. Check paths and FMRIPREP output for: ' boldmask_fname]);
    end
        
    if ~exist(confounds_fname)
        error(['Confounds file does not exist. Check paths and FMRIPREP output for: ' confounds_fname]);
    end
        
    if ~exist(boldmot_folder{i})
        error(['FD folder does not exist for: ' boldmot_folder{i}]);
    end
        
    switch tmasktype
        case 'ones'
        otherwise
            if ~exist(tmask_fname)
                error(['Tmasks do not exist. Run FDcalc script for: ' tmask_fname]);
            end
    end
    
    % there is only one anatomy target across all runs and sessions
    mpr_fname = sprintf('%s/%s/fmriprep/sub-%s/anat/sub-%s_space-%s_desc-preproc_T1w.nii.gz',QC(i).topDir,QC(i).dataFolder,QC(i).subjectID,QC(i).subjectID,space);
    mprnii{i,1} = mpr_fname;
    
    if ~exist(mpr_fname)
        error(['MPRAGE does not exist. Check paths and FMRIPREP output for: ' mpr_fname]);
    end
end
 
varargin = {'defaults2'} %ADDED FOR TESTING

%% SET SWITCHES
if length(varargin) > 0
    switch varargin{1}
        case 'defaults2'
            switches.doregression=1;
            switches.regressiontype=1;
            switches.regress_source='calc'; %'calc' (recalc here) or 'fmriprep' (take from fmriprep output
            switches.motionestimates=2;
            switches.WM=1;
            switches.V=1;
            switches.GS=1;
            switches.dointerpolate=1;
            switches.dobandpass=1;
            switches.temporalfiltertype=3;
            switches.lopasscutoff=.08;
            switches.hipasscutoff=.009;
            switches.order=1;
            switches.doblur=0; %smooth on the surface
            switches.blurkernel=0;
        case 'special'
            switches = varargin{3};
    end
    plot_silent = 1;
else
    % get input from user
    switches = get_input_from_user();    
end

if switches.doblur
    blursize=2*log(2)/pi*10/switches.blurkernel;
    fprintf('gauss_4dfp set to blur at %d; default is 1.1032 for data in 222\n',blursize);
end

fprintf('\n\n\n\n*** HERE ARE YOUR SETTINGS ***:\n')
fprintf('switches.doregression (1=yes;0=no): %d\n',switches.doregression);
fprintf('switches.regressiontype (1=freesurfer): %d\n',switches.regressiontype);
fprintf('switches.regress_source : %s\n',switches.regress_source);
fprintf('switches.motionestimates (0=no; 1=R,R`; 2=FRISTON; 20=R,R`,12rand): %d\n',switches.motionestimates);
fprintf('switches.WM (1=regress;0=no): %d\n',switches.WM);
fprintf('switches.V (1=regress;0=no): %d\n',switches.V);
fprintf('switches.GS (1=regress;0=no): %d\n',switches.GS);
fprintf('switches.dointerpolate (1=yes;0=no): %d\n',switches.dointerpolate);
fprintf('switches.dobandpass (1=yes;0=no): %d\n',switches.dobandpass);
fprintf('switches.temporalfiltertype (1=lowpass;2=hipass;3=bandpass): %d\n',switches.temporalfiltertype);
fprintf('switches.lopasscutoff (in Hz; 0.08 is typical): %g\n',switches.lopasscutoff);
fprintf('switches.hipasscutoff (in Hz; 0.009 is typical): %g\n',switches.hipasscutoff);
fprintf('switches.order (1 is typical): %g\n',switches.order);
fprintf('switches.doblur (1=yes;0=no): %d\n',switches.doblur);
fprintf('switches.blurkernel (in mm; 4 is typical for data in 222): %d\n',switches.blurkernel);

tic


%% LINKING TO BOLD DATA

% prepare output directory
if ~exist(outdir)
    mkdir(outdir)
end
fprintf('PREPARING OUTPUT DIRECTORIES\n');
fprintf('LINKING BOLD DATA\n');
%pause(2);
for i=1:numdatas
    % prepare target subject directory
    QC(i).subdir_out = sprintf('%s/sub-%s/',outdir,QC(i).subjectID);
    if ~exist(QC(i).subdir_out)
        mkdir(QC(i).subdir_out); %make the directory, but don't remove previous if it exists as you may be running sessions separately
    end
    
    % prepare target session directory
    QC(i).sessdir_out=sprintf('%s/ses-%d/func/',QC(i).subdir_out,QC(i).session);
    if ~exist(QC(i).sessdir_out) %only make it if it doesn't exist to account for running different task types
        mkdir(QC(i).sessdir_out);
    else
        warning('Sess output folder already existed; new results will be added to this folder and mixed');
    end
    
    % make links to atlas and seed data
    QC(i).subatlasdir_out=[QC(i).subdir_out '/anat/']; %directory with anatomical info CG = changed to BIDS-like
    if ~exist(QC(i).subatlasdir_out)
        mkdir(QC(i).subatlasdir_out);
    end
    
    % set symbolic link to MPRAGE data
    tmprnii{i,1} = [QC(i).subatlasdir_out '/sub-' QC(i).subjectID '_space-' space '_desc-preproc_T1w.nii.gz'];
    % only 1 anatomy target per subject, so only link if not yet linked
    if ~exist(tmprnii{i,1}, 'file')
        system([ 'ln -s ' mprnii{i,1} ' ' tmprnii{i,1}]);
    end

    % cycle through each BOLD run
        
    % CG: keep structure more akin to BIDS
    % prepare and enter targetsubbolddir
    if QC(i).residuals ~= 0
        all_fstring = sprintf('sub-%s_ses-%d_task-%s_residuals',QC(i).subjectID,QC(i).session,QC(i).condition);
        QC(i).naming_str = all_fstring; % keep a record of this string
        QC(i).naming_str_allruns = sprintf('sub-%s_ses-%d_task-%s_residuals',QC(i).subjectID,QC(i).session,QC(i).condition);
    else
        all_fstring = sprintf('sub-%s_ses-%d_task-%s',QC(i).subjectID,QC(i).session,QC(i).condition);
        QC(i).naming_str = all_fstring; % keep a record of this string
        QC(i).naming_str_allruns = sprintf('sub-%s_ses-%d_task-%s',QC(i).subjectID,QC(i).session,QC(i).condition);
    end
         
    tboldnii{i} = [QC(i).sessdir_out all_fstring '_space-' space '_' res '_desc-preproc_bold.nii.gz'];
    tboldavgnii{i} = [QC(i).sessdir_out all_fstring '_space-' space '_' res '_boldref.nii.gz'];
    tboldmasknii{i} = [QC(i).sessdir_out all_fstring '_space-' space '_' res '_desc-brain_mask.nii.gz'];
    tboldconf{i} = [QC(i).sessdir_out all_fstring '_desc-confounds_timeseries.tsv'];
    tboldmot_folder{i} = [QC(i).sessdir_out 'FD_outputs'];

    system(['ln -s ' boldnii{i} ' ' tboldnii{i}]);
    system(['ln -s ' boldmasknii{i} ' ' tboldmasknii{i}]);
    system(['ln -s ' boldavgnii{i} ' ' tboldavgnii{i}]); %this used to be created once per subject, now once per run with fmriprep
    system(['ln -s ' boldconf{i} ' ' tboldconf{i}]);
        
    % only 1 FD_outputs folder per session (not per run), so only link this if it is not yet linked. Somehow this was previously 
    % creating infinite FD_outputs folders linked within each other
    if ~exist(tboldmot_folder{i}, 'dir')
        system(['ln -s ' boldmot_folder{i} ' ' tboldmot_folder{i}]);
    end
end


%% COMPUTE DEFINED VOXELS FOR THE BOLD RUNS.............

% CG edits: this previously used 4dfp compute_defined_4dfp function
% Now, using fmriprep output masks and combining the BOLD brain masks into
% a single union mask to only take voxels that are defined in every
% analyzed run of a subject
% CG2: we will save this dfndvoxels into the QC but NOT APPLY it to the
% data, since these masks tend to be a bit conservative.
for i=1:numdatas
    dfnd_name_out = [QC(i).sessdir_out QC(i).naming_str '_desc-AllRunUnionMask.nii.gz']; 
    tmp_boldmasknii = boldmasknii(i);
    dfndvoxels = load_nii_wrapper(tmp_boldmasknii{1});
end


%% CHECK FOR NUISANCE SEEDS
% CG - changing to point to ouputs to fmriprep
% May need to edit if we aren't happy with those timeseries
% CG2 - this could be where we choose to potentially load a design matrix
% as well for task data

needtostop=0;
switch switches.regressiontype 
    case {0,1,9} % freesurfer masks of WM and V
        
        display('assuming res02 for all masks now given issues with res saving in fmriprep');
        %these masks are not perfect. Check them if you require high accuracy.
        
        % set basic names
        for i=1:numdatas
            
            anat_string = [QC(i).topDir '/' QC(i).confoundsFolder '/fmriprep/sub-' QC(i).subjectID '/anat/'];
            
            % CG - usually would be a general mask across subjects, but
            % this mask below seems overly conservative. I made a less
            % conservative one by dilating this one 3x using AFNI:
            % singularity run /projects/b1081/singularity_images/afni_latest.sif 3dmask_tool -input tpl-MNI152NLin6Asym_res-02_desc-brain_mask.nii.gz -prefix tpl-MNI152NLin6Asym_res-02_desc-brain_mask_dilate3.nii.gz -dilate_input 3
            % QC(i).GLMmaskfile = ['/projects/b1081/Atlases/templateflow/tpl-' space '/tpl-' space '_res-02_desc-brain_mask.nii.gz'];
            QC(i).GLMmaskfile = ['/projects/b1081/Atlases/templateflow/tpl-' space '/tpl-' space '_res-02_desc-brain_mask_dilate3.nii.gz']; %CG = primary mask we will use
            
            % need to resample the maskfiles to res02 space 
            masks_string = [QC(i).topDir '/' QC(i).confoundsFolder '/masks/sub-' QC(i).subjectID '/' ]

            fnames = resample_masks(anat_string,masks_string,QC(i),space,inres); 
            QC(i).WMmaskfile = [masks_string '/sub-' QC(i).subjectID '_space-' space '_label-WM_probseg_0.9mask_res-2_ero3.nii.gz']; %AD - replacing probseg file with output of make_fs_masks.m 
            QC(i).CSFmaskfile = fnames.CSFmaskfile;
            QC(i).WBmaskfile = fnames.WBmaskfile;
            QC(i).GREYmaskfile = fnames.GREYmaskfile;
            
        end
        
        % check for existence of mask files
        for i=1:numdatas
            fprintf('CHECKING NUISANCE SEEDS\t%d\t%s\n',i,QC(i).subjectID);
            disp('remember to visually check if nuisance masks at set thresholds look OK.');
            needtostop=0;
            
            if ~exist([QC(i).GLMmaskfile])
                fprintf('No GLMmask found: %s\n',QC(i).GLMmaskfile);
                needtostop=1;
            end            
            if ~exist(QC(i).WBmaskfile)
                fprintf('WBmaskfile: %s missing!\n',QC(i).WBmaskfile);
                needtostop=1;
            end
            if ~exist(QC(i).GREYmaskfile)
                fprintf('GREYmaskfile: %s missing!\n',QC(i).GREYmaskfile);
                needtostop=1;
            end
            if ~exist(QC(i).WMmaskfile)
                fprintf('WMmaskfile: %s missing! Check make_fs_masks output.\n',QC(i).WMmaskfile);
                needtostop=1;
            end
            if ~exist(QC(i).CSFmaskfile)
                fprintf('CSFmaskfile: %s missing!\n',QC(i).CSFmaskfile);
                needtostop=1;
            end
            if needtostop
                error('Fix the BRAIN masks.\n');
            end
        end
        
        % ensure masks contain something, relax erosions if not
        for i=1:numdatas
            %needtostop=0;
            
            tmpmask=load_nii_wrapper(QC(i).GLMmaskfile);
            %tmpmask=tmpmask & QC(i).DFNDVOXELS; %CG - too conservative - don't mask at this stage
            QC(i).GLMMASK=~~tmpmask;
            
            tmpmask = load_nii_wrapper(QC(i).WBmaskfile);
            %tmpmask=tmpmask & QC(i).DFNDVOXELS;
            QC(i).WBMASK=~~tmpmask;
            
            tmpmask = load_nii_wrapper(QC(i).GREYmaskfile);
            %tmpmask = (tmpmask > GMthresh) & QC(i).DFNDVOXELS;
            tmpmask = (tmpmask > GMthresh);
            QC(i).GMMASK=~~tmpmask;
            QC(i).GMthresh = GMthresh;
            %save this file out for later inspection (add warnings based on
            %percent voxels too?)
            outname = [QC(i).sessdir_out QC(i).naming_str_allruns '_desc-GMMASK.nii.gz'];
            save_out_maskfile(QC(i).GREYmaskfile,QC(i).GMMASK,outname);
            
            tmpmask = load_nii_wrapper(QC(i).WMmaskfile);
            %tmpmask = (tmpmask > WMthresh) & QC(i).DFNDVOXELS;
            % tmpmask = (tmpmask > WMthresh); % AD - commenting out; we now input an already-thresholded/binarized version
            QC(i).WMMASK=~~tmpmask;
            QC(i).WMthresh = WMthresh;
            %save this file out for later inspection (add warnings based on
            %percent voxels too?)
            outname = [QC(i).sessdir_out QC(i).naming_str_allruns '_desc-WMMASK.nii.gz'];
            save_out_maskfile(QC(i).WMmaskfile,QC(i).WMMASK,outname);
            
            tmpmask = load_nii_wrapper(QC(i).CSFmaskfile);
            %tmpmask = (tmpmask > CSFthresh) & QC(i).DFNDVOXELS;
            tmpmask = (tmpmask > CSFthresh);
            QC(i).CSFMASK=~~tmpmask;
            QC(i).CSFthresh = CSFthresh;
            %save this file out for later inspection (add warnings based on
            %percent voxels too?)
            outname = [QC(i).sessdir_out QC(i).naming_str_allruns '_desc-CSFMASK.nii.gz'];
            save_out_maskfile(QC(i).CSFmaskfile,QC(i).CSFMASK,outname);
        end
        
 
        
    case 2 % external 4dfp of regressor ROIs
        
        
    case 3 % external txt file
        
    otherwise
end


%% CALCULATE SUBJECT MOVEMENT
for i=1:numdatas
    %for j=1:size(QC(i).runs,1)
        
        %cd(QC(i).subbolddir{j});
        fprintf('LOADING MOTION\t%d\tsub-%s\tsess-%d\n',i,QC(i).subjectID,QC(i).session);
        
        
        if QC(i).residuals ~= 0
            % load motion and alignment estimates from FD folder
            mot_fstring = sprintf('sub-%s_ses-%d_task-%s',QC(i).subjectID,QC(i).session,QC(i).condition);
            mvm{i} = table2array(readtable([tboldmot_folder{i} '/' mot_fstring '_desc-mvm.txt']));        
            mvm_filt{i} = table2array(readtable([tboldmot_folder{i} '/' mot_fstring '_desc-mvm_filt.txt']));
            FD{i} = table2array(readtable([tboldmot_folder{i} '/' mot_fstring '_desc-FD.txt']));        
            fFD{i} = table2array(readtable([tboldmot_folder{i} '/' mot_fstring '_desc-fFD.txt']));
        else
            % load motion and alignment estimates from FD folder
            mvm{i} = table2array(readtable([tboldmot_folder{i} '/' QC(i).naming_str '_desc-mvm.txt']));        
            mvm_filt{i} = table2array(readtable([tboldmot_folder{i} '/' QC(i).naming_str '_desc-mvm_filt.txt']));
            FD{i} = table2array(readtable([tboldmot_folder{i} '/' QC(i).naming_str '_desc-FD.txt']));        
            fFD{i} = table2array(readtable([tboldmot_folder{i} '/' QC(i).naming_str '_desc-fFD.txt'])); 
        end
        
        % get diffed and detrended mvm params for nuisance regression
        d = size(mvm{i});
        ddt_mvm{i} = [zeros(1,d(2)); diff(mvm{i})]; % put 0 at the start by default
        mvm_detrend{i} = demean_detrend(mvm{i}')'; 
        ddt_mvm_detrend{i} = demean_detrend(ddt_mvm{i}')';
        
        ddt_mvm_filt{i} = [zeros(1,d(2)); diff(mvm_filt{i})]; % put 0 at the start by default
        mvm_filt_detrend{i} = demean_detrend(mvm_filt{i}')'; 
        ddt_mvm_filt_detrend{i} = demean_detrend(ddt_mvm_filt{i}')';
        %error('stopped here. check dimensionality here and in future use (tsXmot)');
        
    %end
    
    % STORE TOTAL DATA FOR EACH SUBJECT
    
    % store the total movement data
    QC(i).MVM=[];
    QC(i).ddtMVM=[];
    QC(i).DTMVM=[];
    QC(i).ddtDTMVM=[];
    QC(i).FD=[];
    
    QC(i).MVM_filt=[];
    QC(i).ddtMVM_filt=[];
    QC(i).DTMVM_filt=[];
    QC(i).ddtDTMVM_filt=[];
    QC(i).fFD=[];
    
    QC(i).MVM=[QC(i).MVM; mvm{i}];
    QC(i).ddtMVM=[QC(i).ddtMVM; ddt_mvm{i}]; 
    QC(i).DTMVM=[QC(i).DTMVM; mvm_detrend{i}]; 
    QC(i).ddtDTMVM=[QC(i).ddtDTMVM; ddt_mvm_detrend{i}]; 
    QC(i).FD=[QC(i).FD; FD{i}];
        
    QC(i).MVM_filt=[QC(i).MVM_filt; mvm_filt{i}];
    QC(i).ddtMVM_filt=[QC(i).ddtMVM_filt; ddt_mvm_filt{i}]; 
    QC(i).DTMVM_filt=[QC(i).DTMVM_filt; mvm_filt_detrend{i}]; 
    QC(i).ddtDTMVM_filt=[QC(i).ddtDTMVM_filt; ddt_mvm_filt_detrend{i}]; 
    QC(i).fFD=[QC(i).fFD; fFD{i}];
    
    QC(i).switches=switches;
end


%% ASSEMBLE TEMPORAL MASKS
switch tmasktype
    case 'ones'
        for i=1:numdatas
            QC(i).runtmask=ones(size(FD{i},1),1);
            QC(i).runtmask(1:QC(i).TRskip)=0;
            QC(i).tmask=[];
            QC(i).tmask=[QC(i).tmask];
        end
    otherwise
        for i=1:numdatas
            fprintf('GETTING TMASK FILES\t%d\tsub-%s\tses-%d\n',i,QC(i).subjectID,QC(i).session);
            
            QC(i).tmask = [];
            QC(i).runtmask = table2array(readtable([boldtmask{i}])); 
                QC(i).tmask=[QC(i).tmask];
        end
end

%% FUNCTIONAL CONNECTIVITY PROCESSING
bigstuff=1; % this saves voxelwise timecourses over processing.
skipvox=15; % downsample grey matter voxels for visuals.
set(0, 'DefaultFigureVisible', 'off');
for i=1:numdatas 
    fprintf('FCPROCESSING SUBJECT %d sub-%s sess-%d\n',i,QC(i).subjectID,QC(i).session);
    
    %Select voxels in glmmask
    QC(i).CSFMASK_glmmask = QC(i).CSFMASK(logical(QC(i).GLMMASK));
    QC(i).WMMASK_glmmask = QC(i).WMMASK(logical(QC(i).GLMMASK));
    QC(i).GMMASK_glmmask = QC(i).GMMASK(logical(QC(i).GLMMASK));
    QC(i).WBMASK_glmmask = QC(i).WBMASK(logical(QC(i).GLMMASK));
    QC(i).GLMMASK_glmmask = QC(i).GLMMASK(logical(QC(i).GLMMASK));
    
    %%%
    % THE PROCESSING BEGINS
    %%%
    
    stage=1;
    ending= 'fmriprep'; %'333';
    allends = ending;
    bolds = [];
    LASTIMG{i,stage} = tboldnii{i}(1:end-7); %remove .nii.gz?
    bolds = tboldnii{i}(1:end-7);
    
    % obtain the raw images (and mode 1000 normalize them)
    tempimg = bolds2mat(bolds,tr(i).tot,tr(i).start,QC(i).GLMMASK,QC(i).WBMASK);
    
    % save out average raw image for SNR mask later
    tempimg_avg = zeros(size(QC(i).GLMMASK));
    tempimg_avg(logical(QC(i).GLMMASK)) = squeeze(mean(tempimg,2));
    outSNR = [QC(i).sessdir_out QC(i).naming_str_allruns '_desc-mode1000_mean.nii.gz'];
    outfile = load_nii([bolds{1} '.nii.gz']); % for header info
    img_dims = size(outfile.img);
    img_dims(4) = 1; % this is only a mask, no temporal data
    outfile.img = reshape(tempimg_avg,img_dims);
    outfile.prefix = outSNR;   
    outfile.hdr.dime.dim(2:5) = img_dims;
    save_nii(outfile,outSNR);
        
    QC = nuissignals(QC,i,tboldconf(i,:));
    
    QC(i).process{stage}=ending;
    if bigstuff
        tmptcs=single(tempimg(QC(i).GMMASK_glmmask,:));
        QC(i).GMtcs(:,:,stage)=tmptcs(1:skipvox:end,:);
        QC(i).WMtcs(:,:,stage)=single(tempimg(QC(i).WMMASK_glmmask,:));
        QC(i).CSFtcs(:,:,stage)=single(tempimg(QC(i).CSFMASK_glmmask,:));
    end
    makepictures_vCG(QC(i),stage,[700:200:1300],[0:50:100],200);    
    saveas(gcf,[QC(i).sessdir_out QC(i).naming_str{1}(1:end-6) '_stage-' num2str(stage) '-' allends '.tiff'],'tiff');
    close(gcf);
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%
    %%% 0-mean, detrend %%%
    %%%%%%%%%%%%%%%%%%%%%%%%
    
    stage=stage+1;
    ending='zmdt';
    allends=[allends '_' ending];
    for j=1:size(QC(i).runs,1)
        LASTIMG{i,j,stage}=[ LASTIMG{i,j,stage-1} '_' ending ];
    end

    tic;
    temprun=tempimg(:,QC(i).runborders(2):QC(i).runborders(3));
    temprun=demean_detrend(temprun,QC(i).runtmask);
    tempimg(:,QC(i).runborders(2):QC(i).runborders(3))=temprun;
    toc;
    
    QC(i).process{stage}=ending;
    if bigstuff
        tmptcs=single(tempimg(QC(i).GMMASK_glmmask,:));
        QC(i).GMtcs(:,:,stage)=tmptcs(1:skipvox:end,:);
        QC(i).WMtcs(:,:,stage)=single(tempimg(QC(i).WMMASK_glmmask,:));
        QC(i).CSFtcs(:,:,stage)=single(tempimg(QC(i).CSFMASK_glmmask,:));
    end
    makepictures_vCG(QC(i),stage,[-20:20:20],[0:50:100],200);    
    saveas(gcf,[QC(i).sessdir_out QC(i).naming_str{1}(1:end-6) '_stage-' num2str(stage) '-' allends '.tiff'],'tiff');
    close(gcf);
    
    %%%%%%%%%%%%%%%%%%%%%%%%
    %%% MULTIPLE REGRESSION %%%
    %%%%%%%%%%%%%%%%%%%%%%%%
    
    % load the image in question, including all BOLD runs
    fprintf('\tNUISANCE REGRESSION\n');
    stage=stage+1;
    ending='resid';
    allends=[allends '_' ending];
    LASTIMG{i,stage}=[ LASTIMG{i,stage-1} '_' ending ];
   
    if switches.doregression
        % get the movement-based regressors
        switch switches.motionestimates
            case 0 %
                QC(i).mvmregs=[];
                QC(i).mvmlabels={''};
            case 1 % R,R`                   LAB CLASSIC
                QC(i).mvmregs=[QC(i).DTMVM QC(i).ddtDTMVM];
                QC(i).mvmlabels={'trans_x','trans_y','trans_z','rot_x','rot_y','rot_z',...
                    'trans_x_ddt','trans_y_ddt','trans_z_ddt','rot_x_ddt','rot_y_ddt','rot_z_ddt'};
            case 2 % R,R^2,R-1,R-1^2       FRISTON
                frist1=circshift(QC(i).DTMVM,[1 0]);
                frist1(1,:)=0;
                QC(i).mvmregs=[QC(i).DTMVM (QC(i).DTMVM.^2) frist1 frist1.^2 ];
                QC(i).mvmlabels={'X','Y','Z','rot_x','rot_y','rot_z',...
                    'sqrX','sqrY','sqrZ','sqrrot_x','sqrrot_y','sqrrot_z',...
                    'Xt-1','Yt-1','Zt-1','rot_xz-1','rot_yz-1','rot_zz-1',...
                    'sqrXt-1','sqrYt-1','sqrZt-1','sqrrot_xt-1','sqrrot_yt-1','sqrrot_zt-1'};
        end
        
        % get the signal regressors
        QC(i).sigregs=[];
        QC(i).siglabels=[];
        switch switches.regressiontype
            case {0,1}
                if switches.GS
                    if strcmp(switches.regress_source,'fmriprep')
                        sig = QC(i).global_signal;
                    elseif strcmp(switches.regress_source,'calc')
                        sig = mean(tempimg(QC(i).GLMMASK_glmmask,:))';
                    else
                        error('do no recognize regress_source switch');
                    end
                    QC(i).sigregs=[QC(i).sigregs sig];
                    QC(i).siglabels=[QC(i).siglabels {'WB'}];
                end
                if switches.WM
                    if strcmp(switches.regress_source,'fmriprep')
                        sig = QC(i).white_matter;
                    elseif strcmp(switches.regress_source,'calc')
                        sig=mean(tempimg(QC(i).WMMASK_glmmask,:))';
                    else
                        error('do no recognize regress_source switch');
                    end
                        QC(i).sigregs=[QC(i).sigregs sig];
                        QC(i).siglabels=[QC(i).siglabels {'WM'}];
                    
                end
                if switches.V
                    if strcmp(switches.regress_source,'fmriprep')
                        sig = QC(i).csf;
                    elseif strcmp(switches.regress_source,'calc')
                        sig=mean(tempimg(QC(i).CSFMASK_glmmask,:))';
                    else
                        error('do no recognize regress_source switch');
                    end
                        QC(i).sigregs=[QC(i).sigregs sig];
                        QC(i).siglabels=[QC(i).siglabels {'V'}];
                end
                if ~isempty(QC(i).sigregs)
                    QC(i).sigregs=[QC(i).sigregs [repmat(0,[1 size(QC(i).sigregs,2)]); diff(QC(i).sigregs)]];
                    kk=numel(QC(i).siglabels);
                    for k=1:kk
                        QC(i).siglabels{k+kk}=[ QC(i).siglabels{k} '`'];
                    end
                end
        end
        
        QC(i).nuisanceregressors=[QC(i).mvmregs QC(i).sigregs];
        QC(i).nuisanceregressorlabels=[QC(i).mvmlabels QC(i).siglabels];
        dlmwrite([QC(i).sessdir_out 'total_nuisance_regressors.txt'],QC(i).nuisanceregressors,'\t');
        
        figure('Visible','Off');
        subplot(8,1,8);
        imagesc(zscore(QC(i).nuisanceregressors)',[-2 2]); ylabel('REGS');
        saveas(gcf,[QC(i).sessdir_out 'total_nuisance_regressors.tiff'],'tiff');
        
        % write the correlations of the nuisance regressors
        clf;
        h=imagesc(triu(corrcoef(QC(i).nuisanceregressors),1),[-.5 1]);
        colorbar;
        saveas(gcf,[QC(i).sessdir_out 'total_nuisance_regressors_correlations.tiff'],'tiff');
        close;
        dlmwrite([QC(i).sessdir_out 'total_nuisance_regressors_correlations.txt'],corrcoef(QC(i).nuisanceregressors),'\t');
        close;
        
        tic
        [tempimg zb regsz]=regress_nuisance(tempimg,QC(i).nuisanceregressors,QC(i).tmask);
        toc
        
        QC(i).nuisanceregressors_ZSCORE=regsz;
        
        QC(i).process{stage}=ending;
        if bigstuff
            tmptcs=single(tempimg(QC(i).GMMASK_glmmask,:));
            QC(i).GMtcs(:,:,stage)=tmptcs(1:skipvox:end,:);
            QC(i).WMtcs(:,:,stage)=single(tempimg(QC(i).WMMASK_glmmask,:));
            QC(i).CSFtcs(:,:,stage)=single(tempimg(QC(i).CSFMASK_glmmask,:));
        end
        makepictures_vCG(QC(i),stage,[-20:20:20],[0:50:100],200);    
        saveas(gcf,[QC(i).sessdir_out QC(i).naming_str{1}(1:end-6) '_stage-' num2str(stage) '-' allends '.tiff'],'tiff');
        close(gcf);
        
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%
    % INTERPOLATION
    %%%%%%%%%%%%%%%%%%%%%%%%
    
    if switches.dointerpolate
        
        stage=stage+1;
        ending='ntrpl';
        allends=[allends '_' ending];
        LASTIMG{i,stage}=[ LASTIMG{i,stage-1} '_' ending ];

        %%% CG: consider shifting this to do interpolation for all runs at
        %%% once rather than each run separately
        %%%%%
        % for each BOLD run
                %for j=1:numel(QC(i).runs)
                    %fprintf('\tINTERPOLATE\trun%d\n',QC(i).runs(j));
                    tic;
                    temprun=tempimg(:,QC(i).runborders(j,2):QC(i).runborders(j,3));
                    ofac=8;
                    hifac=1;
                    TRtimes=([1:size(temprun,2)]')*QC(i).TR;

                    if numel(TRtimes)<150
                        voxbinsize=5000;
                    elseif (numel(TRtimes)>=150 && numel(TRtimes)<500)
                        voxbinsize=500;
                    elseif numel(TRtimes)>=500
                        voxbinsize=50;
                    end
                    fprintf('INTERPOLATION VOXBINSIZE: %d\n',voxbinsize);
                    voxbin=1:voxbinsize:size(temprun,1);
                    voxbin=[voxbin size(temprun,1)];

                    temprun=temprun';
                    tempanish=zeros(size(temprun,1),size(temprun,2));

                    % gotta bin by voxels: 5K is ~15GB, 15K is ~40GB at standard
                    % run lengths. 5K is ~15% slower but saves 2/3 RAM, so that's
                    % the call.
                    % CG: could consider adding parfor loops here
                    for v=1:numel(voxbin)-1 % this takes huge RAM if all voxels
%                         tempanish(:,voxbin(v):voxbin(v+1))=getTransform(TRtimes(~~QC(i).runtmask{j}),temprun(~~QC(i).runtmask{j},voxbin(v):voxbin(v+1)),TRtimes,QC(i).TR,ofac,hifac);
%
%
%<BAS> Added code from Gaurav Patel's coding wiz: speeds up interpolation
%      25x. Answer is the same as the original (getTransform) within
%      rounding error.
                        tempanish(:,voxbin(v):voxbin(v+1))=LSTransform(TRtimes(~~QC(i).runtmask{j}),temprun(~~QC(i).runtmask{j},voxbin(v):voxbin(v+1)),TRtimes,QC(i).TR,ofac,hifac);
%</BAS>
                    end

                    tempanish=tempanish';
                    temprun=temprun';

                    temprun(:,~QC(i).runtmask{j})=tempanish(:,~QC(i).runtmask{j});
                    tempimg(:,QC(i).runborders(j,2):QC(i).runborders(j,3))=temprun;
                    toc;
                %end
        
        
        
%         %%%%% PREVIOUS VERSION, CG implemented edits to do all runs at once
%                 fprintf('\tINTERPOLATE full set\n');
%                   tic;
%             temprun=tempimg;
%             ofac=8;
%             hifac=1;
%             TRtimes=([1:size(temprun,2)]')*QC(i).TR;
%             TRtimes=([1:size(temprun,2)]')*QC(i).TR;
%             
%             if numel(TRtimes)<150
%                 voxbinsize=5000;
%             elseif (numel(TRtimes)>=150 && numel(TRtimes)<500)
%                 voxbinsize=500;
%             elseif numel(TRtimes)>=500
%                 voxbinsize=50;
%             end
%             fprintf('INTERPOLATION VOXBINSIZE: %d\n',voxbinsize);
%             voxbin=1:voxbinsize:size(temprun,1);
%             voxbin=[voxbin size(temprun,1)];
% 
%             temprun=temprun';
%             tempanish=zeros(size(temprun,1),size(temprun,2));
%             
%             % gotta bin by voxels: 5K is ~15GB, 15K is ~40GB at standard
%             % run lengths. 5K is ~15% slower but saves 2/3 RAM, so that's
%             % the call.
%             disp(['size ' num2str(size(voxbin))])
%             matlabpool open 4
%             %for v = 1:numel(voxbin)-1 % this takes huge RAM if all voxels
%             parfor v = 1:numel(voxbin)-1 % this takes huge RAM if all voxels
%                 %temp = temprun(~~QC(i).runtmask{j},voxbin(v):voxbin(v+1));
%                 temp = temprun(~~QC(i).tmask,voxbin(v):voxbin(v+1));
%                 %tempanish_piece{v}=getTransform(TRtimes(~~QC(i).runtmask{j}),temp,TRtimes,QC(i).TR,ofac,hifac);
%                 tempanish_piece{v}=getTransform(TRtimes(~~QC(i).tmask),temp,TRtimes,QC(i).TR,ofac,hifac);
%                 tempanish(:,voxbin(v):voxbin(v+1))=LSTransform(TRtimes(~~QC(i).runtmask{j}),temprun(~~QC(i).runtmask{j},voxbin(v):voxbin(v+1)),TRtimes,QC(i).TR,ofac,hifac);
% 
%             end
%             matlabpool close
%             
%             for v = 1:numel(voxbin)-1
%                 tempanish(:,voxbin(v):voxbin(v+1)) = tempanish_piece{v};
%             end
%             clear tempanish_piece;
%             
%             tempanish=tempanish';
%             temprun=temprun';
%             
%             %temprun(:,~QC(i).runtmask{j})=tempanish(:,~QC(i).runtmask{j});
%             temprun(:,~QC(i).tmask)=tempanish(:,~QC(i).tmask);
%             %tempimg(:,QC(i).runborders(j,2):QC(i).runborders(j,3))=temprun;
%             tempimg=temprun;
%             toc;
%         %%% CG added piece - END
        

        
        %[QC]=tempimgsignals(QC,i,tempimg,switches,stage);
        QC(i).process{stage}=ending;
        %QC(i).tc(:,:,stage)=gettcs(roimasks,tempimg);
        %dlmwrite(['total_DV_' LASTCONC{stage} '.txt'],QC(i).DV_GLM(:,stage));
        if bigstuff
            tmptcs=single(tempimg(QC(i).GMMASK_glmmask,:));
            QC(i).GMtcs(:,:,stage)=tmptcs(1:skipvox:end,:);
            QC(i).WMtcs(:,:,stage)=single(tempimg(QC(i).WMMASK_glmmask,:));
            QC(i).CSFtcs(:,:,stage)=single(tempimg(QC(i).CSFMASK_glmmask,:));
        end
        %makepictures(QC(i),stage,switches,[-20:20:20],[0:50:100],50);
        makepictures_vCG(QC(i),stage,[-20:20:20],[0:50:100],200);    
        saveas(gcf,[QC(i).sessdir_out QC(i).naming_str{1}(1:end-6) '_stage-' num2str(stage) '-' allends '.tiff'],'tiff');
        close(gcf);
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%
    %%% TEMPORAL FILTER %%%
    %%%%%%%%%%%%%%%%%%%%%%%%
    
    if switches.dobandpass
        
        stage=stage+1;
        ending='bpss';
        allends=[allends '_' ending];
        for j=1:size(QC(i).runs,1)
            LASTIMG{i,j,stage}=[ LASTIMG{i,j,stage-1} '_' ending ];
        end
        %LASTCONC{stage}=[LASTCONC{stage-1} '_' ending];
        
        filtorder=switches.order;
        switch switches.temporalfiltertype
            case 1
                lopasscutoff=switches.lopasscutoff/(0.5/QC(i).TR); % since TRs vary have to recalc each time
                [butta buttb]=butter(filtorder,lopasscutoff,'low');
            case 2
                hipasscutoff=switches.hipasscutoff/(0.5/QC(i).TR); % since TRs vary have to recalc each time
                [butta buttb]=butter(filtorder,hipasscutoff,'high');
            case 3
                lopasscutoff=switches.lopasscutoff/(0.5/QC(i).TR); % since TRs vary have to recalc each time
                hipasscutoff=switches.hipasscutoff/(0.5/QC(i).TR); % since TRs vary have to recalc each time
                [butta buttb]=butter(filtorder,[hipasscutoff lopasscutoff]);
        end
        
        aa = tempimg;
        for j=1:size(QC(i).runs,1)
            fprintf('\tTEMPORAL FILTER\trun%d\n',QC(i).runs(j,:));
            tic;
            temprun=tempimg(:,QC(i).runborders(j,2):QC(i).runborders(j,3));
            temprun=temprun';
            size_temprun = size(temprun);
            pad = 1000;
            temprun = cat(1, zeros(pad, size_temprun(2)), temprun, zeros(pad, size_temprun(2)));
            [temprun]=filtfilt(butta,buttb,double(temprun));
            temprun = temprun(pad+1:end-pad, 1:size_temprun(2));
            temprun=temprun';
            tempimg(:,QC(i).runborders(j,2):QC(i).runborders(j,3))=temprun;
            toc;
        end
        
        %[QC]=tempimgsignals(QC,i,tempimg,switches,stage);
        QC(i).process{stage}=ending;
        %QC(i).tc(:,:,stage)=gettcs(roimasks,tempimg);
        %dlmwrite(['total_DV_' LASTCONC{stage} '.txt'],QC(i).DV_GLM(:,stage));
        if bigstuff
            tmptcs=single(tempimg(QC(i).GMMASK_glmmask,:));
            QC(i).GMtcs(:,:,stage)=tmptcs(1:skipvox:end,:);
            QC(i).WMtcs(:,:,stage)=single(tempimg(QC(i).WMMASK_glmmask,:));
            QC(i).CSFtcs(:,:,stage)=single(tempimg(QC(i).CSFMASK_glmmask,:));
        end
        %makepictures(QC(i),stage,switches,[-20:20:20],[0:10:20],10);
        makepictures_vCG(QC(i),stage,[-20:20:20],[0:50:100],200);    
        saveas(gcf,[QC(i).sessdir_out QC(i).naming_str{1}(1:end-6) '_stage-' num2str(stage) '-' allends '.tiff'],'tiff');
        close(gcf);
        
        % create temporal mask based on filter properties
        filtertrim=15; % TRs at beginning and end of run to ignore due to IIR zero-phase filter
        QC(i).filtertmask=[];
        
        for j=1:size(QC(i).runs,1)
            QC(i).runfiltertmask{j}=QC(i).runtmask{j};
            QC(i).runfiltertmask{j}(1:filtertrim)=0;
            QC(i).runfiltertmask{j}(end-filtertrim+1:end)=0;
            QC(i).runfiltertmask{j}=QC(i).runfiltertmask{j} & QC(i).runtmask{j};
            QC(i).filtertmask=[QC(i).filtertmask; QC(i).runfiltertmask{j}];
        end
        
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%
    %%% 0-mean, detrend %%%
    %%%%%%%%%%%%%%%%%%%%%%%%
    
    stage=stage+1;
    ending='zmdt';
    allends=[allends '_' ending];
    for j=1:size(QC(i).runs,1)
        LASTIMG{i,j,stage}=[ LASTIMG{i,j,stage-1} '_' ending ];
    end
    %LASTCONC{stage}=[LASTCONC{stage-1} '_' ending];
    
    % for each BOLD run
    for j=1:size(QC(i).runs,1)
        fprintf('\tDEMEAN DETREND\trun%d\n',QC(i).runs(j,:));
        tic;
        temprun=tempimg(:,QC(i).runborders(j,2):QC(i).runborders(j,3));
        if switches.dobandpass
            temprun=demean_detrend(temprun,QC(i).runfiltertmask{j});
        else
            temprun=demean_detrend(temprun,QC(i).runtmask{j});
        end
        tempimg(:,QC(i).runborders(j,2):QC(i).runborders(j,3))=temprun;
        toc;
    end
    
    %[QC]=tempimgsignals(QC,i,tempimg,switches,stage);
    QC(i).process{stage}=ending;
    %QC(i).tc(:,:,stage)=gettcs(roimasks,tempimg);
    %dlmwrite(['total_DV_' LASTCONC{stage} '.txt'],QC(i).DV_GLM(:,stage));
    if bigstuff
        tmptcs=single(tempimg(QC(i).GMMASK_glmmask,:));
        QC(i).GMtcs(:,:,stage)=tmptcs(1:skipvox:end,:);
        QC(i).WMtcs(:,:,stage)=single(tempimg(QC(i).WMMASK_glmmask,:));
        QC(i).CSFtcs(:,:,stage)=single(tempimg(QC(i).CSFMASK_glmmask,:));
    end
    %makepictures(QC(i),stage,switches,[-20:20:20],[0:10:20],10);
    makepictures_vCG(QC(i),stage,[-20:20:20],[0:50:100],200);    
    saveas(gcf,[QC(i).sessdir_out QC(i).naming_str{1}(1:end-6) '_stage-' num2str(stage) '-' allends '.tiff'],'tiff');
    close(gcf);
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%% CONCATENATE INTO SINGLE IMAGE %%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    
    fprintf('\tCONCATENATE AND CLEANUP\n');
    %cd(QC(i).subdir);
    tempimg_out = zeros(size(QC(i).GLMMASK,1),size(tempimg,2)); %Put back in volume space
    tempimg_out(logical(QC(i).GLMMASK),:) = tempimg;
    tmpavg = load_nii(tboldavgnii{i,1}); 
    d = size(tmpavg.img);
    dims_bold = [d(1) d(2) d(3) size(tempimg,2)];
    tempimg_out = reshape(tempimg_out,dims_bold);
    clear tempimg tmpavg d;
    
    %write_4dfpimg(tempimg_out,[ QC(i).vcnum '_' allends '.4dfp.img'],'bigendian');
    %write_4dfpifh([ QC(i).vcnum '_' allends '.4dfp.img'],size(tempimg_out,2),'bigendian');
    % save a separate file for each run so not too huge
    for j = 1:length(QC(i).runs)
        outdat = load_nii(tboldnii{i,j});
        outdat.img = tempimg_out(:,:,:,tr(i).start(j,1):tr(i).start(j,2));
        out_fname = [QC(i).sessdir_out QC(i).naming_str{j} '_' allends '.nii.gz'];
        outdat.fileprefix = out_fname;
        save_nii(outdat,out_fname);
        clear outdat;
    end
    
    % save QC file per session
    QC_outname = [QC(i).sessdir_out QC(i).naming_str{1}(1:end-6) 'QC.mat'];
    QCsub = QC(i);
    save(QC_outname,'QCsub','-v7.3');
    clear QCsub;
    
end





