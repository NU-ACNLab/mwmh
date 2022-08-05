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

% cont=input('\nDo you wish to continue with these settings? (1=yes) ' );
% if cont~=1
%     error('Quitting');
% end

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


%% COMPUTE DEFINED VOXELS FOR THE BOLD RUNS

% CG edits: this previously used 4dfp compute_defined_4dfp function
% Now, using fmriprep output masks and combining the BOLD brain masks into
% a single union mask to only take voxels that are defined in every
% analyzed run of a subject
% CG2: we will save this dfndvoxels into the QC but NOT APPLY it to the
% data, since these masks tend to be a bit conservative.
for i=1:numdatas
    dfnd_name_out = [QC(i).sessdir_out QC(i).naming_str '_desc-AllRunUnionMask.nii.gz']; 
    % ^ ERROR: Brace indexing is not supported for variables of this type.
    dfndvoxels = load_nii_wrapper(boldmasknii(i))
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
            fnames = resample_masks(anat_string,QC(i),space);
            QC(i).WMmaskfile = [anat_string '/sub-' QC(i).subjectID '_space-' space '_label-WM_probseg_0.9mask_res-2_ero3.nii.gz']; %AD - replacing probseg file with output of make_fs_masks.m 
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
    for j=1:size(QC(i).runs,1)
        
        %cd(QC(i).subbolddir{j});
        fprintf('LOADING MOTION\t%d\tsub-%s\tsess-%d\trun-%d\n',i,QC(i).subjectID,QC(i).session,QC(i).runs(j));
        
        
        if QC(i).residuals ~= 0
            % load motion and alignment estimates from FD folder
            mot_fstring = sprintf('sub-%s_ses-%d_task-%s_run-%d',QC(i).subjectID,QC(i).session,QC(i).condition,QC(i).runs(j));
            mvm{i,j} = table2array(readtable([tboldmot_folder{i,j} '/' mot_fstring '_desc-mvm.txt']));        
            mvm_filt{i,j} = table2array(readtable([tboldmot_folder{i,j} '/' mot_fstring '_desc-mvm_filt.txt']));
            FD{i,j} = table2array(readtable([tboldmot_folder{i,j} '/' mot_fstring '_desc-FD.txt']));        
            fFD{i,j} = table2array(readtable([tboldmot_folder{i,j} '/' mot_fstring '_desc-fFD.txt']));
        else
            % load motion and alignment estimates from FD folder
            mvm{i,j} = table2array(readtable([tboldmot_folder{i,j} '/' QC(i).naming_str{j} '_desc-mvm.txt']));        
            mvm_filt{i,j} = table2array(readtable([tboldmot_folder{i,j} '/' QC(i).naming_str{j} '_desc-mvm_filt.txt']));
            FD{i,j} = table2array(readtable([tboldmot_folder{i,j} '/' QC(i).naming_str{j} '_desc-FD.txt']));        
            fFD{i,j} = table2array(readtable([tboldmot_folder{i,j} '/' QC(i).naming_str{j} '_desc-fFD.txt'])); 
        end
        
        % get diffed and detrended mvm params for nuisance regression
        d = size(mvm{i,j});
        ddt_mvm{i,j} = [zeros(1,d(2)); diff(mvm{i,j})]; % put 0 at the start by default
        mvm_detrend{i,j} = demean_detrend(mvm{i,j}')'; 
        ddt_mvm_detrend{i,j} = demean_detrend(ddt_mvm{i,j}')';
        
        ddt_mvm_filt{i,j} = [zeros(1,d(2)); diff(mvm_filt{i,j})]; % put 0 at the start by default
        mvm_filt_detrend{i,j} = demean_detrend(mvm_filt{i,j}')'; 
        ddt_mvm_filt_detrend{i,j} = demean_detrend(ddt_mvm_filt{i,j}')';
        %error('stopped here. check dimensionality here and in future use (tsXmot)');
        
    end
    
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
    
    for j=1:size(QC(i).runs,1)
        QC(i).MVM=[QC(i).MVM; mvm{i,j}];
        QC(i).ddtMVM=[QC(i).ddtMVM; ddt_mvm{i,j}]; 
        QC(i).DTMVM=[QC(i).DTMVM; mvm_detrend{i,j}]; 
        QC(i).ddtDTMVM=[QC(i).ddtDTMVM; ddt_mvm_detrend{i,j}]; 
        QC(i).FD=[QC(i).FD; FD{i,j}];
        
        QC(i).MVM_filt=[QC(i).MVM_filt; mvm_filt{i,j}];
        QC(i).ddtMVM_filt=[QC(i).ddtMVM_filt; ddt_mvm_filt{i,j}]; 
        QC(i).DTMVM_filt=[QC(i).DTMVM_filt; mvm_filt_detrend{i,j}]; 
        QC(i).ddtDTMVM_filt=[QC(i).ddtDTMVM_filt; ddt_mvm_filt_detrend{i,j}]; 
        QC(i).fFD=[QC(i).fFD; fFD{i,j}];
    end
    
    QC(i).switches=switches;
    
end


%% DEFINE RUN BORDERS
for i=1:numdatas
    trpos=0;
    tr(i).tot=numel(QC(i).FD);
    for j=1:size(QC(i).runs,1)
        tr(i).runtrs(j)=numel(FD{i,j});
        tr(i).start(j,1:2)=[trpos+1 trpos+tr(i).runtrs(j)];
        trpos=trpos+tr(i).runtrs(j);
        QC(i).runborders(j,:) = [j tr(i).start(j,1:2)];
    end
    % QC(i).runborders=[QC(i).restruns' tr(i).start];
    %cd(QC(i).subdir);
    dlmwrite([QC(i).sessdir_out 'runborders.txt'],QC(i).runborders,'\t');
end

%error('no idea what this next line is needed for... CG');
%[sortTR sortsubs]=sort(cell2mat({tr.tot}));





%% ASSEMBLE TEMPORAL MASKS
switch tmasktype
    case 'ones'
        for i=1:numdatas
            for j=1:size(QC(i).runs,1)
                QC(i).runtmask{j}=ones(size(FD{i,j},1),1);
                QC(i).runtmask{j}(1:QC(i).TRskip)=0;
            end
            QC(i).tmask=[];
            for j=1:size(QC(i).runs,1)
                QC(i).tmask=[QC(i).tmask; QC(i).runtmask{j}];
            end
        end
    otherwise
        for i=1:numdatas
            fprintf('GETTING TMASK FILES\t%d\tsub-%s\tsess-%d\n',i,QC(i).subjectID,QC(i).session);
            
            QC(i).tmask = [];
            for j=1:size(QC(i).runs,1)
                QC(i).runtmask{j}= table2array(readtable([boldtmask{i,j}])); 
                QC(i).tmask=[QC(i).tmask; QC(i).runtmask{j}];
            end
        end
end

%% FUNCTIONAL CONNECTIVITY PROCESSING
bigstuff=1; % this saves voxelwise timecourses over processing.
skipvox=15; % downsample grey matter voxels for visuals.
set(0, 'DefaultFigureVisible', 'off');
for i=1:numdatas %f=1:numdatas
    
    % CG: do we need this?
    % orders subjects in decreasing order to minimize memory fragmentation
    % i=sortsubs(f);
    
    %fprintf('FCPROCESSING SUBJECT %d sub-%s sess-%s\n',f,QC(i).subjectID,QC(i).session);
    fprintf('FCPROCESSING SUBJECT %d sub-%s sess-%d\n',i,QC(i).subjectID,QC(i).session);
    %pause(2);
    
    %Select voxels in glmmask
    QC(i).CSFMASK_glmmask = QC(i).CSFMASK(logical(QC(i).GLMMASK));
    QC(i).WMMASK_glmmask = QC(i).WMMASK(logical(QC(i).GLMMASK));
    QC(i).GMMASK_glmmask = QC(i).GMMASK(logical(QC(i).GLMMASK));
    QC(i).WBMASK_glmmask = QC(i).WBMASK(logical(QC(i).GLMMASK));
    QC(i).GLMMASK_glmmask = QC(i).GLMMASK(logical(QC(i).GLMMASK));
    %roimasks =roimasks_orig(logical(QC(i).GLMMASK),:);
    
    %%%
    % THE PROCESSING BEGINS
    %%%
    
    stage=1;
    ending= 'fmriprep'; %'333';
    allends = ending;
    bolds = [];
    for j=1:size(QC(i).runs,1)
        % CG - changed LASTIMG to not have i or stage counter any longer
        % LASTIMG{i,j,stage} = tboldnii{i,j}(1:end-7); %remove .nii.gz?
        LASTIMG{i,j,stage} = tboldnii{i,j}(1:end-7); %remove .nii.gz?
        bolds{j} = tboldnii{i,j}(1:end-7);
    end
    
    
    
    % obtain the raw images (and mode 1000 normalize them)
    %[tempimg]=bolds2img(bolds,tr(i).tot,tr(i).start,QC(i).GLMMASK);
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
        
    %QC = tempimgsignals(QC,i,tempimg,switches,stage); % CG - do we need this?
    QC = nuissignals(QC,i,tboldconf(i,:));
    
    
    QC(i).process{stage}=ending;
    %QC(i).tc(:,:,stage)=gettcs(roimasks,tempimg); % CG -needed?
    %dlmwrite(['total_DV_' LASTCONC{stage} '.txt'],QC(i).DV_GLM(:,stage));
    if bigstuff
        tmptcs=single(tempimg(QC(i).GMMASK_glmmask,:));
        QC(i).GMtcs(:,:,stage)=tmptcs(1:skipvox:end,:);
        QC(i).WMtcs(:,:,stage)=single(tempimg(QC(i).WMMASK_glmmask,:));
        QC(i).CSFtcs(:,:,stage)=single(tempimg(QC(i).CSFMASK_glmmask,:));
    end
    %makepictures(QC(i),stage,switches,[700:200:1300],[0:50:100],100);
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
    %LASTCONC{stage}=[LASTCONC{stage-1} '_' ending];
    
    % for each BOLD run
    for j=1:size(QC(i).runs,1)
        fprintf('\tDEMEAN DETREND\trun%d\n',QC(i).runs(j));
        tic;
        temprun=tempimg(:,QC(i).runborders(j,2):QC(i).runborders(j,3));
        temprun=demean_detrend(temprun,QC(i).runtmask{j});
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
    %makepictures(QC(i),stage,switches,[-20:20:20],[0:50:100],50);
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
    for j=1:size(QC(i).runs,1)
        LASTIMG{i,j,stage}=[ LASTIMG{i,j,stage-1} '_' ending ];
    end
    %LASTCONC{stage}=[LASTCONC{stage-1} '_' ending];
    
    
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
%             case 3
%                 frist=[QC(i).DTMVM];
%                 frist1=circshift(QC(i).DTMVM,[1 0]);
%                 frist1(1,:)=0;
%                 frist2=circshift(QC(i).DTMVM,[2 0]);
%                 frist2(1:2,:)=0;
%                 QC(i).mvmregs=[QC(i).DTMVM (QC(i).DTMVM.^2) frist1 frist1.^2 frist2 frist2.^2 ];
%                 QC(i).mvmlabels={'X','Y','Z','pitch','yaw','roll`','sqrX','sqrY','sqrZ','sqrpitch','sqryaw','sqrroll`','Xt-1','Yt-1','Zt-1','pitcht-1','yawt-1','rollt-1`','sqrXt-1','sqrYt-1','sqrZt-1','sqrpitcht-1','sqryawt-1','sqrrollt-1`','Xt-2','Yt-2','Zt-2','pitcht-2','yawt-2','rollt-2`','sqrXt-2','sqrYt-2','sqrZt-2','sqrpitcht-2','sqryawt-2','sqrrollt-2`'};
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
        
        % write the beta images % CG - implement later if we want it
        %zb_out = zeros(size(QC(i).GLMMASK,1),size(zb,2)); %Put back in volume space
        %zb_out(logical(QC(i).GLMMASK),:) = zb; %Put back in volume space
        %clear zb
        %write_4dfpimg(zb_out,'beta.4dfp.img','bigendian');
        %write_4dfpifh('beta.4dfp.img',size(zb_out,2),'bigendian');
        
        
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
    % INTERPOLATION
    %%%%%%%%%%%%%%%%%%%%%%%%
    
    if switches.dointerpolate
        
        stage=stage+1;
        ending='ntrpl';
        allends=[allends '_' ending];
        for j=1:size(QC(i).runs,1)
            LASTIMG{i,j,stage}=[ LASTIMG{i,j,stage-1} '_' ending ];
        end
        %LASTCONC{stage}=[LASTCONC{stage-1} '_' ending];
        
        
        
        %%% CG: consider shifting this to do interpolation for all runs at
        %%% once rather than each run separately
        %%%%%
        % for each BOLD run
                for j=1:numel(QC(i).runs)
                    fprintf('\tINTERPOLATE\trun%d\n',QC(i).runs(j));
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
                end
        
        
        
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
    
    %%%%%%%%%%%%%%%%%%%%%%%%
    %%% SPATIAL BLUR %%%
    %%%%%%%%%%%%%%%%%%%%%%%%
    
    % CG - commented this out for now.
    % EITHER do blurring through another tool (AFNI?) or on the surface
    
%     if switches.doblur
%         stage=stage+1;
%         ending=[ 'g' num2str(round(blursize*10)) ];
%         allends=[allends '_' ending];
%         %LASTCONC{stage}=[LASTCONC{stage-1} '_' ending];
%         for j=1:size(QC(i).restruns,1)
%             LASTIMG{i,j,stage}=[ LASTIMG{i,j,stage-1} '_' ending ];
%         end
%         
%         tic
%         fprintf('\tSPATIAL BLUR\n');
%         
%         % write BOLD files from previous stage b/c use 4dfp tool
%         for j=1:size(QC(i).restruns,1)
%             temprun=tempimg(:,QC(i).runborders(j,2):QC(i).runborders(j,3));
%             temprun_out = zeros(size(QC(i).GLMMASK,1),size(temprun,2)); %Put back in volume space
%             temprun_out(logical(QC(i).GLMMASK),:) = temprun; %Put back in volume space
%             clear temprun
%             write_4dfpimg(temprun_out,[ LASTIMG{i,j,stage-1} '.4dfp.img'],'bigendian');
%             write_4dfpifh([ LASTIMG{i,j,stage-1} '.4dfp.img'],size(temprun_out,2),'bigendian');
%         end
%         % write a new concfile
%         fid=fopen([LASTCONC{stage-1} '.conc'],'w');
%         fprintf(fid,'number_of_files: %s\n',size(QC(i).restruns,1));
%         for j=1:size(QC(i).restruns,1)
%             fprintf(fid,'\tfile:%s\n',[LASTIMG{i,j,stage-1} '.4dfp.img' ]);
%         end
%         fclose(fid);
%         
%         % run the spatial blur
%         system(['gauss_4dfp ' LASTCONC{stage-1} '.conc ' num2str(blursize) ' >/dev/null']);
%         pause(5);
%         [bolds]=conc2bolds([LASTCONC{stage} '.conc']);
%         [tempimg]=bolds2img(bolds,tr(i).tot,tr(i).start);
%         toc
%         
%         [QC]=tempimgsignals(QC,i,tempimg,switches,stage);
%         QC(i).process{stage}=ending;
%         QC(i).tc(:,:,stage)=gettcs(roimasks,tempimg);
%         dlmwrite(['total_DV_' LASTCONC{stage} '.txt'],QC(i).DV_GLM(:,stage));
%         if bigstuff
%             tmptcs=single(tempimg(QC(i).GMMASK_glmmask,:));
%             QC(i).GMtcs(:,:,stage)=tmptcs(1:skipvox:end,:);
%             QC(i).WMtcs(:,:,stage)=single(tempimg(QC(i).WMMASK_glmmask,:));
%             QC(i).CSFtcs(:,:,stage)=single(tempimg(QC(i).CSFMASK_glmmask,:));
%         end
%         makepictures(QC(i),stage,switches,[-20:20:20],[0:10:20],10);
%         saveas(gcf,[ num2str(i) '_' QC(i).vcnum '_' num2str(stage) '_' allends '.tiff'],'tiff');
%     end
    
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


%% RETURN TO THE STARTING DIRECTORY AND SAVE LABELS
% cd(outdir);
% % write a corrfile
% fid=fopen('corrfile.txt','w');
% for i=1:numdatas
%     fprintf(fid,'%s\t%s\t%s\n',[QC(i).subdir '/' QC(i).vcnum '_' allends '.4dfp.img'],[QC(i).subdir '/total_tmask.txt'],QC(i).vcnum);
% end
% fclose(fid);
% save('QC.mat','QC','-v7.3');
% cd(startdir);
% 
% toc
%exit;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [bolds]=conc2bolds(concfile)

system(['cat ' concfile ' | grep file: | awk -F: ''{print $2}'' >! tmpAB']);
[bolds]=textread('tmpAB','%s');
system('rm tmpAB');


% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function [fcimg]=bolds2img(bolds,trtot,trborders)
% vox=147456;
% fcimg=zeros(vox,trtot);
% for j=1:size(bolds,1)
%     fcimg(:,trborders(j,1):trborders(j,2))=read_4dfpimg_HCP(bolds{j,1});
% end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function [fcimg]=bolds2img(bolds,trtot,trborders,GLMmask)
% 
% vox = nnz(GLMmask);
% %vox=902629;%147456;
% fcimg=zeros(vox,trtot);
% for j=1:size(bolds,1)
%     temp = read_4dfpimg_HCP(bolds{j,1});
%     %    fcimg(:,trborders(j,1):trborders(j,2))=read_4dfpimg_HCP(bolds{j,1});
%     fcimg(:,trborders(j,1):trborders(j,2))=temp(logical(GLMmask),:);
% end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [fcimg]=bolds2mat(bolds,trtot,trborders,GLMmask,WBmask_sub)

vox = nnz(GLMmask);
%vox=902629;%147456;
fcimg=zeros(vox,trtot);
for j=1:size(bolds,2)
    temp = load_nii_wrapper([bolds{j} '.nii.gz']);
    %temp = read_4dfpimg_HCP(bolds{j,1});
    %    fcimg(:,trborders(j,1):trborders(j,2))=read_4dfpimg_HCP(bolds{j,1});
    
    %CG added, based on BK code, based on EMG code
    temp1000 = mode1000norm(temp,WBmask_sub); % use the more sub specific mask for this
   
    fcimg(:,trborders(j,1):trborders(j,2))=temp1000(logical(GLMmask),:);
    clear temp temp1000;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function bolddat1000 = mode1000norm(bolddat,bmask)

bolddat_masked = double(bolddat(bmask,:));
bolddat_masked = bolddat_masked(bolddat_masked > 0); %note: EMG code had an additional mask > 100 applied. Took out since didn't seem needed?
[counts,edges] = histcounts(bolddat_masked,1000);
[~,maxind] = max(counts);
%modeval = mean([edges(maxind) edges(maxind+1)]);
upper_75 = prctile(bolddat_masked, 75);%upper_75 = edges(maxind+250); %since 1000 bins  %
lower_25 = prctile(bolddat_masked, 25); %lower_25 = edges(maxind-250); %%

% add a range normalization step for NU to make it look more like MSC
bolddat_norm = (bolddat - lower_25)/(upper_75 - lower_25) .* 200; %MSC range seemed ~between 900 and 1200

% recalculate mode after normalization
bolddat_norm_masked = double(bolddat_norm(bmask,:));
bolddat_norm_masked = bolddat_norm_masked(bolddat_masked > 0); % use original mask for 0s
[counts,edges] = histcounts(bolddat_norm_masked,1000);
[~,maxind] = max(counts);
modeval = mean([edges(maxind) edges(maxind+1)]);

% change bold data to have mode 1000
bolddat1000 = bolddat_norm + (1000 - modeval);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [rmstotal rmstrans rmsrot rmscol mvm] = rdat_calculations(datfile,varargin)

% jdp 9/15/10
% Here, you pass in an rdat, and get back out the RMS calculations for that file
% RMS is calculated for 3 rotational and 3 translational motion parameters, combined for rotation and translation, and a total RMS is also returned.
% The rdat is also returned in mm as the mvm variable, giving motion values in mm movement.
% The number of frames of a run to skip is set to a default of 5, and the radius for movement calculations is set to 50 (mm), which is standard. Those values can be altered by apssing in additional arguments
%
% USAGE: [rmstotal rmstrans rmsrot rmscol mvm] = rdat_calculations(datfile,*skipframes,radius*)
%

% set default skipframes and radius, but replace with user-defined values values if provided
radius=50;
skipframes=5;
if ~isempty(varargin)
    skipframes=varargin{1,1};
    radius=varargin{1,2};
end

% load the rdat
% fprintf('\n%s\n',datfile);
[pth,fname,ext]=filenamefinder(datfile,'dotsout');
outputfile=[ fname '_rmscalc.txt' ];

% have to strip out a header (has #s at the beginning of each line)
command=[ 'grep -v # ' datfile ];
[trash tempmat]=system(command);
datfile=str2num(tempmat);
if datfile(1,1)~=1
    error('Reading rdatfile isn''t getting a first frame of 1');
end
d=size(datfile);

% convert the rotational mvmt to mm movement
mvm=zeros(d(1),6);
mvm(:,1)=datfile(:,2);
mvm(:,2)=datfile(:,3);
mvm(:,3)=datfile(:,4);
mvm(:,4)=convert_deg_to_mm(datfile(:,5),radius);
mvm(:,5)=convert_deg_to_mm(datfile(:,6),radius);
mvm(:,6)=convert_deg_to_mm(datfile(:,7),radius);

startframe=skipframes+1;
meancol=mean(mvm(startframe:end,:),1);
stdcol=std(mvm(startframe:end,:),1);
[rmstotal rmscol]=calc_rms(mvm(startframe:end,1),mvm(startframe:end,2),mvm(startframe:end,3),mvm(startframe:end,4),mvm(startframe:end,5),mvm(startframe:end,6));
rmstrans=sqrt(sum(rmscol(1,1:3).^2));
rmsrot=sqrt(sum(rmscol(1,4:6).^2));

function [rmstotal rmstrans rmsrot rmscol mvm] = rdat_calculations_yfiltered(datfile,TR,varargin)

% jdp 9/15/10
% Here, you pass in an rdat, and get back out the RMS calculations for that file
% RMS is calculated for 3 rotational and 3 translational motion parameters, combined for rotation and translation, and a total RMS is also returned.
% The rdat is also returned in mm as the mvm variable, giving motion values in mm movement.
% The number of frames of a run to skip is set to a default of 5, and the radius for movement calculations is set to 50 (mm), which is standard. Those values can be altered by apssing in additional arguments
%
% USAGE: [rmstotal rmstrans rmsrot rmscol mvm] = rdat_calculations(datfile,*skipframes,radius*)
%

% set default skipframes and radius, but replace with user-defined values values if provided
radius=50;
skipframes=5;
if ~isempty(varargin)
    skipframes=varargin{1,1};
    radius=varargin{1,2};
end

% load the rdat
% fprintf('\n%s\n',datfile);
[pth,fname,ext]=filenamefinder(datfile,'dotsout');
outputfile=[ fname '_rmscalc.txt' ];

% have to strip out a header (has #s at the beginning of each line)
command=[ 'grep -v # ' datfile ];
[trash tempmat]=system(command);
datfile=str2num(tempmat);
if datfile(1,1)~=1
    error('Reading rdatfile isn''t getting a first frame of 1');
end
d=size(datfile);

% filter the motion parameters to remove high freq artifact (f < 0.1 Hz)
[butta buttb]=butter(1,0.1/(0.5/TR),'low');
pad = 100;
temp_mot = cat(1, zeros(pad, d(2)), datfile, zeros(pad, d(2))); 
[temp_mot]=filtfilt(butta,buttb,double(temp_mot)); 
temp_mot = temp_mot(pad+1:end-pad, 1:d(2)); 
datfile(:,3) = temp_mot(:,3); %Only need to filter the y


% convert the rotational mvmt to mm movement
mvm=zeros(d(1),6);
mvm(:,1)=datfile(:,2);
mvm(:,2)=datfile(:,3);
mvm(:,3)=datfile(:,4);
mvm(:,4)=convert_deg_to_mm(datfile(:,5),radius);
mvm(:,5)=convert_deg_to_mm(datfile(:,6),radius);
mvm(:,6)=convert_deg_to_mm(datfile(:,7),radius);

startframe=skipframes+1;
meancol=mean(mvm(startframe:end,:),1);
stdcol=std(mvm(startframe:end,:),1);
[rmstotal rmscol]=calc_rms(mvm(startframe:end,1),mvm(startframe:end,2),mvm(startframe:end,3),mvm(startframe:end,4),mvm(startframe:end,5),mvm(startframe:end,6));
rmstrans=sqrt(sum(rmscol(1,1:3).^2));
rmsrot=sqrt(sum(rmscol(1,4:6).^2));


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [deg] = convert_deg_to_mm(deg,radius)

deg=deg*(2*radius*pi/360);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [totrms rms] = calc_rms(varargin)

% feed in arbitrary number of columns

d=size(varargin);
for i=1:d(2)
    vals(:,i)=varargin{1,i};
    rms(1,i)=sqrt(mean(vals(:,i).^2));
end

totrms=sqrt(sum(rms.^2));


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [tempbold tempbetas] = demean_detrend(img,varargin)

if ~isnumeric(img)
    %[tempbold]=read_4dfpimg_HCP(img); % read image
    tempbold = load_nii_wrapper(img);
    %tempbold = tempbold.img;
else
    [tempbold]=img;
    clear img;
end
[vox ts]=size(tempbold);

if ~isempty(varargin)
    tmask=varargin{1,1};
else
    tmask=ones(ts,1);
end

linreg=[repmat(1,[ts 1]) linspace(0,1,ts)'];
tempboldcell=num2cell(tempbold(:,logical(tmask))',1);
linregcell=repmat({linreg(logical(tmask),:)},[1 vox]);
tempbetas = cellfun(@mldivide,linregcell,tempboldcell,'uniformoutput',0);
tempbetas=cell2mat(tempbetas);
tempbetas=tempbetas';
tempintvals=tempbetas*linreg';
tempbold=tempbold-tempintvals;

if nargin==3
    outname=varargin{1,2};
    error('not changed to nii yet'); % CG added
    write_4dfpimg(tempbold,outname,'bigendian');
    write_4dfpifh(outname,size(tempbold,2),'bigendian');
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [tempimg zb newregs] = regress_nuisance(tempimg,totregs,tot_tmask)

[vox ts]=size(tempimg);
zlinreg=totregs(logical(tot_tmask),:); % only desired data
[zlinreg DMDTB]=demean_detrend(zlinreg'); % obtain fits for desired data
zlinreg=zlinreg';
zstd=std(zlinreg); % calculate std
zmean=mean(zlinreg);
zlinreg=(zlinreg-repmat(zmean,[size(zlinreg,1) 1]))./(repmat(zstd,[size(zlinreg,1) 1])); % zscore

linreg=[repmat(1,[ts 1]) linspace(0,1,ts)'];
newregs=DMDTB*linreg'; % predicted all regressors demean/detrend
newregs=totregs-newregs'; % these are the demeaned detrended regressors
newregs=(newregs-repmat(zmean,[size(newregs,1) 1]))./(repmat(zstd,[size(newregs,1) 1])); % zscore

% now we have z-scored, detrended good and all regressors.

% demean and detrend the desired data
zmdtimg=tempimg(:,logical(tot_tmask));
[zmdtimg zmdtbetas]=demean_detrend(zmdtimg);

% calculate betas on the good data
tempboldcell=num2cell(zmdtimg',1);
zlinregcell=repmat({zlinreg},[1 vox]);
zb = cellfun(@mldivide,zlinregcell,tempboldcell,'uniformoutput',0);
zb=cell2mat(zb);

% demean and detrend all data using good fits
[zmdttotimg]=zmdtbetas*linreg';
zmdttotimg=tempimg-zmdttotimg;

% calculate residuals on all the data
zb=zb';
tempintvals=zb*newregs';
tempimg=zmdttotimg-tempintvals;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [tc] = gettcs(roimasks,tempimg)

d=size(roimasks);
for i=1:d(2) % cycle all masks
    tc(:,i)=(mean(tempimg(logical(roimasks(:,i)),:)))';
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function QC = tempimgsignals(QC,i,tempimg,switches,stage)

difftempimg=diff(tempimg')';
difftempimg=[zeros(size(difftempimg,1),1) difftempimg];

QC(i).MEAN_CSF(:,stage)=mean(tempimg(QC(i).CSFMASK_glmmask,:))';
QC(i).MEAN_WM(:,stage)=mean(tempimg(QC(i).WMMASK_glmmask,:))';
QC(i).MEAN_GLM(:,stage)=mean(tempimg(QC(i).GLMMASK_glmmask,:))';

QC(i).SD_CSF(:,stage)=std(tempimg(QC(i).CSFMASK_glmmask,:))';
QC(i).SD_WM(:,stage)=std(tempimg(QC(i).WMMASK_glmmask,:))';
QC(i).SD_GLM(:,stage)=std(tempimg(QC(i).GLMMASK_glmmask,:))';

QC(i).SDbar_CSF(:,stage)=mean(QC(i).SD_CSF(:,stage));
QC(i).SDbar_WM(:,stage)=mean(QC(i).SD_WM(:,stage));
QC(i).SDbar_GLM(:,stage)=mean(QC(i).SD_GLM(:,stage));

[jnk tempDV]=array_calc_rms(difftempimg(QC(i).CSFMASK_glmmask,:));
tempDV(QC(i).runborders(:,2))=NaN;
QC(i).DV_CSF(:,stage)=tempDV';
[jnk tempDV]=array_calc_rms(difftempimg(QC(i).WMMASK_glmmask,:));
tempDV(QC(i).runborders(:,2))=NaN;
QC(i).DV_WM(:,stage)=tempDV';
[jnk tempDV]=array_calc_rms(difftempimg(QC(i).GLMMASK_glmmask,:));
tempDV(QC(i).runborders(:,2))=NaN;
QC(i).DV_GLM(:,stage)=tempDV';

QC(i).DVbar_CSF(stage)=nanmean(QC(i).DV_CSF(:,stage));
QC(i).DVbar_WM(stage)=nanmean(QC(i).DV_WM(:,stage));
QC(i).DVbar_GLM(stage)=nanmean(QC(i).DV_GLM(:,stage));

if switches.regressiontype==1 | switches.regressiontype==9
    QC(i).MEAN_GM(:,stage)=mean(tempimg(QC(i).GMMASK_glmmask,:))';
    QC(i).MEAN_WB(:,stage)=mean(tempimg(QC(i).WBMASK_glmmask,:))';
    
    QC(i).SD_GM(:,stage)=std(tempimg(QC(i).GMMASK_glmmask,:))';
    QC(i).SD_WB(:,stage)=std(tempimg(QC(i).WBMASK_glmmask,:))';
    
    QC(i).SDbar_GM(:,stage)=mean(QC(i).SD_GM(:,stage));
    QC(i).SDbar_WB(:,stage)=mean(QC(i).SD_WB(:,stage));
    
    [jnk tempDV]=array_calc_rms(difftempimg(QC(i).GMMASK_glmmask,:));
    tempDV(QC(i).runborders(:,2))=NaN;
    QC(i).DV_GM(:,stage)=tempDV';
    [jnk tempDV]=array_calc_rms(difftempimg(QC(i).WBMASK_glmmask,:));
    tempDV(QC(i).runborders(:,2))=NaN;
    QC(i).DV_WB(:,stage)=tempDV';
    
    QC(i).DVbar_GM(stage)=nanmean(QC(i).DV_GM(:,stage));
    QC(i).DVbar_WB(stage)=nanmean(QC(i).DV_WB(:,stage));
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function QC = nuissignals(QC,i,tboldconf)
% CG - added in to draw confound signals from fmriprep output

% relevant confounds to carry forward:
conf_names = {'csf','csf_derivative1','csf_power2','csf_derivative1_power2',...
    'white_matter','white_matter_derivative1','white_matter_power2','white_matter_derivative1_power2',...
    'global_signal','global_signal_derivative1','global_signal_power2','global_signal_derivative1_power2',...
    'std_dvars','dvars'};

%prep structure with empty arrays
for cn = 1:length(conf_names)
    QC(i).(conf_names{cn}) = [];
end

% load confounds signals from fmriprep
for j = 1:length(QC(i).runs)
    run_confounds = bids.util.tsvread(tboldconf{j});
    for cn = 1:length(conf_names)
        temprun_confounds=demean_detrend(run_confounds.(conf_names{cn})');
        
        QC(i).(conf_names{cn}) = [QC(i).(conf_names{cn}); temprun_confounds'];
    end
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function makepictures(QC,stage,switches,rightsignallim,leftsignallim,FDmult)

% FOR TESTING:
% set(0, 'DefaultFigureVisible', 'on');

rylimz=[min(rightsignallim) max(rightsignallim)];
lylimz=[min(leftsignallim) max(leftsignallim)];

numpts=numel(QC.FD);
clf;
subplot(8,1,1:2);
pointindex=1:numpts;
%[h a(1) a(2)]=plotyy(pointindex,QC.DV_GLM(:,stage),pointindex,QC.MEAN_GLM(:,stage));
[h a(1) a(2)]=plotyy(pointindex,QC.dvars,pointindex,QC.global_signal);
set(h(1),'xlim',[0 numpts],'ylim',lylimz,'ycolor',[0 0 0],'ytick',leftsignallim);
ylabel('B:DV G:GS');
set(a(1),'color',[0 0 1]);
set(h(2),'xlim',[0 numpts],'ycolor',[0 0 0],'xlim',[0 numel(QC.dvars)],'ylim',rylimz,'ytick',rightsignallim);
set(a(2),'color',[0 .5 0]);
axis(h(1)); hold on;
h3=plot([1:numpts],QC.FD*FDmult,'r');
h4=plot([1:numpts],QC.fFD*FDmult,'Color',[0.8 0 0]);
hold off;
axes(h(2)); hold(h(2),'on');
hline(0,'k');
hold(h(2),'off');
set(h(1),'children',[a(1) h3 h4]);
set(h(1),'YaxisLocation','left','box','off');
set(h(2),'xaxislocation','top','xticklabel','');
if switches.regressiontype==1 | switches.regressiontype==9
    subplot(8,1,3);
    imagesc(QC.MVM',[-.5 .5]);
    ylabel('XYZPYR');
    subplot(8,1,4:7);
    imagesc(QC.GMtcs(:,:,stage),rylimz); colormap(gray); ylabel('GRAY');
    subplot(8,1,8);
    imagesc([QC.WMtcs(:,:,stage);QC.CSFtcs(:,:,stage)],rylimz); ylabel('WM CSF');
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function makepictures_vCG(QC,stage,rightsignallim,leftsignallim,FDmult)

% FOR TESTING:
%set(0, 'DefaultFigureVisible', 'off');

% constants
numpts=numel(QC.FD);
%rightsignallim = [-20:20]; %GS limits (2% assuming mode 1000 normalization)
%lefsignallim = [0:20:10]; % DVARS limits
rylimz=[min(rightsignallim) max(rightsignallim)];
lylimz=[min(leftsignallim) max(leftsignallim)];
%FDmult = 10; %multiplier to get FD in range of DVARS values

figure('Position',[1 1 1700 1200],'Visible','Off');

% subplot1 = mvm
subplot(10,1,1:2);
pointindex=1:numpts;
plot(pointindex,QC.MVM);
xlim([0 numpts]);
ylim([-1 1]);
ylabel('mvm');

% subplot2 = GS
subplot(10,1,3)
%[h a(1) a(2)]=plotyy(pointindex,QC.DV_GLM(:,stage),pointindex,QC.MEAN_GLM(:,stage));
%[h a(1) a(2)]=plotyy(pointindex,QC.dvars,pointindex,QC.global_signal);
%set(h(1),'xlim',[0 numpts],'ylim',lylimz,'ycolor',[0 0 0],'ytick',leftsignallim);
%ylabel(sprintf('B:DV G:GS R:FD*%d C:fFD*%d',FDmult,FDmult));
%set(a(1),'color',[0 0 1]);
%set(h(2),'xlim',[0 numpts],'ycolor',[0 0 0],'xlim',[0 numel(QC.dvars)],'ylim',rylimz,'ytick',rightsignallim);
%set(a(2),'color',[0 .5 0]);
%axis(h(1)); hold on;
plot(pointindex,QC.global_signal,'g');
hline(0,'k');
xlim([0 numpts]);
ylim(rylimz);
ylabel('G:GS');

% subplot3 = FD
subplot(10,1,4:5)
plot([1:numpts],QC.FD,'Color',[1 0.8 0.8],'LineWidth',0.1); hold on;
plot([1:numpts],QC.fFD,'r','LineWidth',1.5);
hline(0.1,'k');
xlim([0 numpts]);
ylim([0 1])
ylabel('mm, R:fFD, M=FD');
% hold(h(2),'off');
% set(h(1),'children',[a(1) h3 h4]);
% set(h(1),'YaxisLocation','left','box','off');
% set(h(2),'xaxislocation','top','xticklabel','');

% subplots 3-4: 
subplot(10,1,6:9);
imagesc(QC.GMtcs(:,:,stage),rylimz); colormap(gray); ylabel('GRAY');
subplot(10,1,10);
imagesc([QC.WMtcs(:,:,stage);QC.CSFtcs(:,:,stage)],rylimz); ylabel('WM CSF');


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [H,f,s,c,tau,w] = getTransform(t,h,TH,Tr,ofac,hifac)

%Input t is a column vector listing the time points for which observations
%are present.  Input h is a matrix with observations in columns and the
%number of rows equals the number the time points.  For our purposes number
%of voxels = number of columns.  Ofac = oversampling frequency (generally
%>=4), hifac = highest frequency allowed.  hifac = 1 means 1*nyquist limit
%is highest frequency sampled.
%Lasted edited:  Anish Mitra, October 25 2012

N = size(h,1); %Number of time points
T = max(t) - min(t); %Total time span

%calculate sampling frequencies
f = (1/(T*ofac):1/(T*ofac):hifac*N/(2*T)).';

%angular frequencies and constant offsets
w = 2*pi*f;
tau = atan2(sum(sin(2*w*t.'),2),sum(cos(2*w*t.'),2))./(2*w);

%spectral power sin and cosine terms
cterm = cos(w*t.' - repmat(w.*tau,1,length(t)));
sterm = sin(w*t.' - repmat(w.*tau,1,length(t)));

num_tseries = size(h,2); %Number of time series

% D = bsxfun(@minus,h,mean(h));  %This line involved in normalization
D = h;
D = reshape(D,1,N,num_tseries);


%% C_final = (sum(Cmult,2).^2)./sum(Cterm.^2,2);
% This calculation is done by separately for the numerator, denominator,
% and the division

Cmult = bsxfun(@times, cterm,D);
%rewrite the above line with bsxfun to optimize further?
%bsxfun(@power,sum(Cmult,2),2) = sum(Cmult.^2,2) = numerator
% numerator = bsxfun(@power,sum(Cmult,2),2);
numerator = sum(Cmult,2); %Modify the numerator to get the cw term

%sum(bsxfun(@power,Cterm,2),2) = sum(Cterm.^2,2) = denominator
denominator = sum(bsxfun(@power,cterm,2),2); %use Cterm in place of cterm to make it exactly the denominator in the original expression
C_final_new = bsxfun(@rdivide,numerator,denominator);
c = C_final_new;
clear numerator denominator cterm Cmult C_final_new

%% Repeat the above for Sine term
Smult = bsxfun(@times, sterm,D);
% S_final = (sum(Smult,2).^2)./sum(Sterm.^2,2);
% numerator = bsxfun(@power,sum(Smult,2),2);
numerator = sum(Smult,2); %Modify the numerator to get the sw term
denominator = sum(bsxfun(@power,sterm,2),2);
S_final_new = bsxfun(@rdivide,numerator,denominator);
s = S_final_new;
clear numerator denominator sterm Smult S_final_new

% %% Power = C_final + S_final;
% Power = C_final_new + S_final_new;
% Power_reshaped = reshape(Power,size(Power,1),num_tseries);
% Power_final = bsxfun(@rdivide,Power_reshaped,2*var(h)); %Normalize the power
% clearvars -except Power_final f


% The inverse function to re-construct the original time series
Time = TH';
T_rep = repmat(Time,[size(f,1),1,size(h,2)]);
% T_rep = bsxfun(@minus,T_rep,tau);
% s(200) = s(199);
w = 2*pi*f;
prod = bsxfun(@times,T_rep,w);
sin_t = sin(prod);
cos_t = cos(prod);
sw_p = bsxfun(@times,sin_t,s);
cw_p = bsxfun(@times,cos_t,c);
S = sum(sw_p);
C = sum(cw_p);
H = C + S;
H = reshape(H,size(Time,2),size(h,2));

%Normalize the reconstructed spectrum, needed when ofac > 1
Std_H = std(H);
Std_h = std(h);
norm_fac = Std_H./Std_h;
H = bsxfun(@rdivide,H,norm_fac);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function switches = get_input_from_user()
    needcorrectinput=1;
    while needcorrectinput
        switches.doregression=input('Do you want to regress nuisance signals? (1=y; 0=no): ');
        switch switches.doregression
            case 1
                needcorrectinput=0;                
                needcorrectinput2=1;
                while needcorrectinput2
                    switches.regressiontype=input('Regression: 1 - Freesurfer seeds: ');
                    switch switches.regressiontype
                        
                        % classic or freesurfer seeds
                        case {1}
                            needcorrectinput2=0;
                            
                            needcorrectinput1=1;
                            while needcorrectinput1
                                switches.motionestimates=input('Do you want to regress motion estimates and derivatives? (0=no; 1=R,R`; 2=FRISTON; 20=R,R`,12rand; 3:volt3): ');
                                switch switches.motionestimates
                                    case {0,1,2,20,3}
                                        needcorrectinput1=0;
                                end
                            end
                            needcorrectinput1=1;
                            while needcorrectinput1
                                switches.WM=input('Do you want to regress white matter signals and derivatives? (1=y; 0=no): ');
                                switch switches.WM
                                    case {0,1}
                                        needcorrectinput1=0;
                                end
                            end
                            needcorrectinput1=1;
                            while needcorrectinput1
                                switches.V=input('Do you want to regress ventricular signals and derivatives? (1=y; 0=no): ');
                                switch switches.V
                                    case {0,1}
                                        needcorrectinput1=0;
                                end
                            end
                            needcorrectinput1=1;
                            while needcorrectinput1
                                switches.GS=input('Do you want to regress global signal and derivative? (1=y; 0=no): ');
                                switch switches.GS
                                    case {0,1}
                                        needcorrectinput1=0;
                                end
                            end
                            
                            % user seeds
                        case 2
                            needcorrectinput2=0;
                            switches.nus4dfplistfile=input('Enter the hard path to the list of nuisance regressor 4dfps ','s');
                            [switches.nus4dfpvcnum switches.nus4dfplist] = textread(switches.nus4dfplistfile,'%s%s');
                            if ~isequal(switches.nus4dfpvcnum,prepstem)
                                error('Nusiance 4dfp vcnums do not match the vc ordering of the datalist');
                            end
                            
                            needcorrectinput1=1;
                            while needcorrectinput1
                                switches.motionestimates=input('Do you want to also regress motion estimates and derivatives? (1=y; 0=no): ');
                                switch switches.motionestimates
                                    case {0,1}
                                        needcorrectinput1=0;
                                end
                            end
                            
                            % user txt file
                        case 3
                            needcorrectinput2=0;
                            switches.nustxtlistfile=input('Enter the hard path to the list of nuisance regressor files ','s');
                            [switches.nustxtvcnum switches.nustxtlist] = textread(switches.nustxtlistfile,'%s%s');
                            if ~isequal(switches.nustxtvcnum,prepstem)
                                error('Nusiance txt vcnums do not match the vc ordering of the datalist');
                            end
                            
                            needcorrectinput1=1;
                            while needcorrectinput1
                                switches.motionestimates=input('Do you want to also regress motion estimates and derivatives? (1=y; 0=no): ');
                                switch switches.motionestimates
                                    case {0,1}
                                        needcorrectinput1=0;
                                end
                            end
                            
                        case 9
                            needcorrectinput=0;
                            needcorrectinput2=0;
                            switches.motionestimates=1;
                            switches.WMV=1.
                            switches.GS=1;
                            switches.dicesize=input('What size dice to use? (# voxels): ');
                            switches.mindicevox=input('What is minimum # voxels needed in cubes?: ');
                            switches.tcchop=input('What size timeseries to use? (TRs): ');
                            switches.varexpl=input('How much variance should SVD explain?: ');
                            switches.WMero=input('How many WM erosions (4 recommended)?: ');
                            switches.CSFero=input('How many CSF erosions (1 recommended)?: ');
                            switches.sdval=input('What s.d. threshold to form nuisance mask? ');
                            
                    end
                end
            case 0
                needcorrectinput=0;
        end
    end
    
    % interpolate
    needcorrectinput=1;
    while needcorrectinput
        switches.dointerpolate=input('Do you want to interpolate over motion epochs? (1=y; 0=no): ');
        switch switches.dointerpolate
            case {0,1}
                needcorrectinput=0;
        end
    end
    
    % temporal filter lowpass
    needcorrectinput=1;
    while needcorrectinput
        switches.dobandpass=input('Do you want to temporally filter the data (1=y; 0=no): ');
        switch switches.dobandpass
            case 1
                needcorrectinput=0;
            case 0
                needcorrectinput=0;
        end
    end
    
    if switches.dobandpass
        needcorrectinput=1;
        while needcorrectinput
            switches.temporalfiltertype=input('What type of filter: (1) lowpass, (2) highpass (3) bandpass: ');
            switch switches.temporalfiltertype
                case {1,2,3}
                    needcorrectinput=0;
            end
        end
        
        if switches.temporalfiltertype
            switch switches.temporalfiltertype
                case 1
                    needcorrectinput1=1;
                    while needcorrectinput1
                        switches.lopasscutoff=input('What low-pass cutoff is desired (in Hz; .08 is standard): ');
                        if isnumeric(switches.lopasscutoff)
                            needcorrectinput1=0;
                        end
                    end
                case 2
                    needcorrectinput1=1;
                    while needcorrectinput1
                        switches.hipasscutoff=input('What high-pass cutoff is desired (in Hz; .009 is standard): ');
                        if isnumeric(switches.hipasscutoff)
                            needcorrectinput1=0;
                        end
                    end
                case 3
                    needcorrectinput1=1;
                    while needcorrectinput1
                        switches.lopasscutoff=input('What low-pass cutoff is desired (in Hz; .08 is standard): ');
                        if isnumeric(switches.lopasscutoff)
                            needcorrectinput1=0;
                        end
                    end
                    needcorrectinput1=1;
                    while needcorrectinput1
                        switches.hipasscutoff=input('What high-pass cutoff is desired (in Hz; .009 is standard): ');
                        if isnumeric(switches.hipasscutoff)
                            needcorrectinput1=0;
                        end
                    end
                    if switches.lopasscutoff <= switches.hipasscutoff
                        fprintf('Low-pass cutoff must be higher than the high-pass cutoff\n');
                    end
            end
            needcorrectinput1=1;
            while needcorrectinput1
                switches.order=input('What filter order is desired (1 is standard): ');
                if isnumeric(switches.order)
                    needcorrectinput1=0;
                end
            end
            
        end
        
    end
    
    % blurring
    needcorrectinput=1;
    while needcorrectinput
        switches.doblur=input('Do you want to spatially blur the data (1=y; 0=no): ');
        switch switches.doblur
            case 1
                needcorrectinput=0;
                needcorrectinput1=1;
                while needcorrectinput1
                    switches.blurkernel=input('What blurring kernel do you want (in mm; 4 is standard for data in 222): ');
                    if isnumeric(switches.blurkernel)
                        needcorrectinput1=0;
                        
                        fprintf('Blur kernel is %d mm\n',switches.blurkernel);
                        
                        
                    end
                end
            case 0
                needcorrectinput=0;
        end
    end
    

%save out this mask
save_out_maskfile(boldmasknii{1},dfndvoxels,outname);


function save_out_maskfile(input_template,out_data,outname)
outfile = load_nii(input_template); % for header info
img_dims = size(outfile.img);
outfile.img = reshape(out_data,img_dims);
outfile.prefix = outname;
save_nii(outfile,outname);


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
        %system(['module load singularity; singularity run /projects/b1081/singularity_images/afni_latest.sif 3dresample -dxyz 2 2 2 -prefix ' thisName ' -input ' thisName_orig]);
        system(['module load singularity; singularity exec -B /projects/b1081:/projects/b1081 /projects/b1081/singularity_images/afni_latest.sif 3dresample -dxyz 2 2 2 -prefix ' thisName ' -input ' thisName_orig]);
    end
end

cd(currentDir);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [H,f,s,c,tau,w] = LSTransform(t,h,TH,Tr,ofac,hifac)
%LSTRANSFORM  Fills up missing samples in time-series with estimates.
%   [H, F, S, C, TAU, W] = LSTRANSFORM(T, H, TH, TR, OFAC, HIFAC) takes
%   the signal in H and samples new data points given the frequecy content
%   of H at points TH. TR is the sampling resolution (this argument is
%   currently not used), OFAC is the oversampling factor, and HIFAC is the
%   highest allowed frequency.
%
%   H must be NrOfTimePoints-by-NrOfSamples matrix.
%
%   Example:
%
%   rdata = randn(512, 200);
%   allidx = (1:size(rdata, 1))';
%   badidx = ceil(numel(allidx) .* rand(10, 1));
%   goodidx = allidx;
%   goodidx(badidx) = [];
%   repdata = LSTRANSFORM(goodidx, rdata(goodidx, :), allidx, 1, 4, 1);

%Input t is a column vector listing the time points for which observations
%are present.  Input h is a matrix with observations in columns and the
%number of rows equals the number the time points.  For our purposes number
%of voxels = number of columns.  Ofac = oversampling frequency (generally
%>=4), hifac = highest frequency allowed.  hifac = 1 means 1*nyquist limit
%is highest frequency sampled.  
%Lasted edited:  Anish Mitra, October 25 2012

% double precision
D = double(h);

% number of time points
N = size(D, 1);

% total time span
t = t(:);
T = max(t) - min(t);

% calculate sampling frequencies
f = (1 / (T * ofac) : 1 / (T * ofac) : hifac * N / (2 * T))';

% angular frequencies and constant offsets
w = 2 * pi * f;
wt = w * t';
tau = atan2(sum(sin(2 .* wt), 2), sum(cos(2 * wt), 2)) ./ (2 * w);
wtau = wt - repmat(w .* tau, 1, length(t));

% spectral power sin and cosine terms
cterm = cos(wtau);
sterm = sin(wtau);

% compute numerator and denominator for cosines
numerator = cterm * D;
denominator = sum(cterm .* cterm,2);
c = diag(1 ./ denominator) * numerator;

% repeat the above for Sine term
numerator = sterm * D;
denominator = sum(sterm .* sterm,2);
s = diag(1 ./ denominator) * numerator;

% the inverse function to re-construct the original time series
prod = TH(:) * w';
H = sin(prod) * s + cos(prod) * c;

% normalize the reconstructed spectrum, needed when ofac > 1
H = H * diag(std(h) ./ std(H));
