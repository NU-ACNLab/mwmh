function atlas_params = atlas_parameters_GrattonLab(atlas,atlasdir,varargin)
%function atlas_params = atlas_parameters(atlas,atlasdir,varargin)
% A parameter file for different atlas/parcellation options
% Inputs:
%   atlas = string with name of the atlas (e.g., 'Power','Parcels'; peruse
%      below for more options)
%   atlasdir = string path to folder where files relevant to the atlas are stored (e.g.,
%      assignments, colors, roi coordinates)
%   varargin = subject name for subject specific atlases - NOT CURRENTLY
%   SET UP
%
% Output:
%   atlas_params = structure with atlas information
%
% EXAMPLE:
% atlas_params = atlas_parameters_GrattonLab('Seitzman300','/projects/b1081/Atlases/')
%
% C Gratton
% CG - edited to work on NU system, added Seitzman 300 - 3.31.2020

if strcmp(atlas,'Power264')
    warning('need to confirm this still works at NU');
    
    atlas_params.atlas = atlas;
    
    atlas_params.networks = {'Unassigned';'SM';'SM (lat)';'CO';'Auditory';'DMN';'Memory';'Visual';'FP';'Salience';'Sub-cortex';'Ventral Attn';'Dorsal Attn';'Cerebellum'};
    atlas_params.mods = {1:28;29:58;59:63;64:77;78:90;91:148;149:153;154:184;185:209;210:227;228:240;241:249;250:260;261:264};
    atlas_params.mods_array = make_net_array(atlas_params.mods);
    
    atlas_params.atlas_file = 'BigBrain264TimOrder_roilist'; % roilist file - lists locations of ROI files and coordinates
    %atlas_params.roi_file = [homedir 'task_fc_scrubbed_' atlas '/' atlas_params.atlas_file '_RMAT_fast.roi'];
    atlas_params.roi_file = [atlasdir atlas_params.atlas_file '_RMAT_fast.roi']; % ROI file - needed for modularity commands
    %atlas_params.dmat = '/data/cn5/caterina/Atlases/Power264/BigBrain264TimOrder_dmat.mat';
    atlas_params.dmat = [atlasdir 'BigBrain264TimOrder_dmat.mat']; % distance matrix - needed for community detection
    
    %load('/data/cn5/caterina/TaskConn_Methods/all_data/Power_module_colors.mat'); %colors_new
    atlas_params.colors = [ 0.8500    0.8500    0.8500;...
         0    1.0000    1.0000;...
    1.0000    0.5000         0;...
    0.5000         0    0.5000;...
    1.0000         0    1.0000;...
    1.0000         0         0;...
    0.5000    0.5000    0.5000;...
         0         0    1.0000;...
    0.8000    0.8000         0;...
         0         0         0;...
    0.7500    0.2500         0;...
         0    0.5000    0.5000;...
         0    1.0000         0;...
    0.7500         0    0.2500];
    
    atlas_params.num_rois = 264;
    atlas_params.dist_thresh = 20;
    
    atlas_params.transitions = [29 59 64 78 91 149 154 185 210 228 241 250 261];
    atlas_params.centers = [14 44 61 70 84 119 151 168 197 218 234 244 255 262];
    atlas_params.sorti = 1:264;
    %atlas_params.allroi_file = '/data/cn5/caterina/Atlases/Power264/BigBrain264TimOrder_allROIs.4dfp.img';
    atlas_params.allroi_file = [atlasdir 'Power264/BigBrain264TimOrder_allROIs.4dfp.img']; % a single image with all of the ROIs
     
       
elseif strcmp(atlas,'Seitzman300')
    atlas_params.atlas = atlas;
    
    atlas_params.roi_file = [atlasdir '/Seitzman300/ROIs_300inVol_MNI_allInfo.txt']; % text file with ROI info
    atlas_params.anat_labels = [atlasdir '/Seitzman300/ROIs_anatomicalLabels.txt']; % text file with anatomical labels for each ROI
    atlas_params.MNI_nii_file = [atlasdir '/Seitzman300/Seitzman300_MNI_res02_allROIs.nii.gz'];
    
    % load ROI information
    [x y z rad netNum netLabel tmp] = textread(atlas_params.roi_file,'%f%f%f%f%d%s%f','headerlines',1); 
    
    atlas_params.networks = {'Unassigned';'SMd';'SMl';'CON';'Auditory';'DMN';'PMN';'Visual';'FPN';'Salience';'VAN';'DAN';'MTL';'Reward'};
    atlas_params.networks_fullnames = {'unassigned';'SomatomotorDorsal';'SomatomotorLateral';'CinguloOpercular';'Auditory';...
        'DefaultMode';'ParietoMedial';'Visual';'FrontoParietal';'Salience';'VentralAttention';'DorsalAttention';'MedialTemporalLobe';'Reward'};
    
    
    for n = 1:length(atlas_params.networks_fullnames)
        atlas_params.mods{n} = find(strcmp(netLabel,atlas_params.networks_fullnames{n}));
    end
    atlas_params.mods_array = make_net_array(atlas_params.mods);
    
    atlas_params.mods_array_workbench = netNum; %numbers in workbench
    
    atlas_params.colors = [0.8 0.8 0.8;...
        0 1 1;...
        1 0.5 0;...
        0.5 0 0.5;...
        1 0 1;...
        1 0 0;...
        0.12 0.56 1;...
        0 0 1;...
        0.9 0.9 0;...
        0 0 0;...
        0 0.5 0.5;...
        0 1 0;...
        0.6 0.98 0.6;...
        1 0.7586 0.5172;...
        0.6 0.6 1;...
        1 0.4 0.4;...
        0.5 0.5 0.5];
    
    atlas_params.num_rois = 300;
    atlas_params.dist_thresh = 20;

    atlas_params.sorted_by = 'network'; %sort by 'structure' or 'network' first

    switch atlas_params.sorted_by
        case 'structure'
            warning('sorting based on structure first, then net');
            % note that sorting by structure will do weird things with
            % transitions in subcortical
            atlas_params.transitions = find(diff(atlas_params.mods_array)) + 1;
            atlas_params.centers = compute_centers(atlas_params.mods_array);
            atlas_params.sorti = 1:atlas_params.num_rois;
        case 'network'
            warning('sorting by network first, then structure');
            [communities atlas_params.sorti] = sort(atlas_params.mods_array);
            atlas_params.transitions = find(communities(1:end-1) ~= communities(2:end));
            transitions_plusends = [1 atlas_params.transitions(:)' length(communities)];
            atlas_params.centers = transitions_plusends(1:end-1) + ((transitions_plusends(2:end) - transitions_plusends(1:end-1))/2);
    end
    
    %atlas_params.distmat = '/data/cn5/caterina/Atlases/PowerSpheres_expanded/power_expanded_distmat.mat';
    %atlas_params.allroi_file = '/data/cn5/caterina/Atlases/PowerSpheres_expanded/BigBrain298_711-2b_allROIs.4dfp.img';     

elseif strcmp(atlas,'Parcels333')

    warning('Need to confirm this all still works at NU');

    atlas_params.atlas = atlas;
    assignments = load([atlasdir 'ParcelCommunities.txt']);
    
    networklabels = {'Unassigned','Default','Visual','FrontoPar','FrontoPar 2','DorsalAttn','DorsalAttn2','VentAttn','Salience','CingOperc','MotorHand','MotorMouth','Auditory','MTL1','MTL2','PERN','RetroSpl'};
    IDs = unique(assignments);    
    for i = 1:length(IDs)
        mods{i} = find(assignments == IDs(i));
    end
    atlas_params.networks = networklabels(IDs+1);
    atlas_params.mods = mods;
    atlas_params.mods_array = assignments;
    
    atlas_params.atlas_file = 'Parcels_711-2b_withcoords_roilist';
    atlas_params.roi_file = [atlasdir 'parcel_center_7112b.roi'];
    atlas_params.dmat = [atlasdir 'Evan_parcellation/Parcels333_Euclidean_dmat.mat'];
    atlas_params.dist_thresh = 20; %Tim & Evan typically use "30" for surface distances
    atlas_params.num_rois = 333;
    
    colors_new = [.67 .67 .67;1 0 0;0 0 .6;1 1 0;1 .7 .4;0 .8 0;1 .6 1;0 .6 .6;0 0 0;.3 0 .6;.2 1 1;1 .5 0;.6 .2 1;0 .2 .4;.2 1 .2;0 0 1;.8 .8 .6];
    atlas_params.colors = colors_new(IDs+1,:);    
    
    [communities atlas_params.sorti] = sort(assignments);
    atlas_params.transitions = find(communities(1:end-1) ~= communities(2:end));
    transitions_plusends = [1 atlas_params.transitions(:)' length(communities)];
    atlas_params.centers = transitions_plusends(1:end-1) + ((transitions_plusends(2:end) - transitions_plusends(1:end-1))/2);

    
elseif strcmp(atlas,'ParcelCenters')
    
    warning('need to confirm this all still works at NU');
    
    atlas_params.atlas = atlas;
    atlas_params.atlas_file = 'ParcelCenters_roilist';
    atlas_params.roi_file = [atlasdir 'ParcelCenters_roilist_rmat_slow.roi'];
    atlas_params.dist_thresh = 20; %Tim & Evan typically use "30" for surface distances
    atlas_params.num_rois = 333;
    
    colors_new = [.67 .67 .67;1 0 0;0 0 .6;1 1 0;1 .7 .4;0 .8 0;1 .6 1;0 .6 .6;0 0 0;.3 0 .6;.2 1 1;1 .5 0;.6 .2 1;0 .2 .4;.2 1 .2;0 0 1;.8 .8 .6];
    assignments = load([atlasdir 'ParcelCommunities.txt']);
    IDs = unique(assignments);    
    atlas_params.colors = colors_new(IDs+1,:);
    
    for i = 1:length(IDs)
        mods{i} = find(assignments == IDs(i));
    end
    atlas_params.mods = mods;

    networklabels = {'Unassigned','Default','Visual','FrontoPar','FrontoPar 2','DorsalAttn','DorsalAttn2','VentAttn','Salience','CingOperc','MotorHand','MotorMouth','Auditory','MTL1','MTL2','PERN','RetroSpl'};
    atlas_params.networks = networklabels(IDs+1);
    
    [communities atlas_params.sorti] = sort(assignments);
    atlas_params.transitions = find(communities(1:end-1) ~= communities(2:end));
    transitions_plusends = [1 atlas_params.transitions(:)' length(communities)];
    atlas_params.centers = transitions_plusends(1:end-1) + ((transitions_plusends(2:end) - transitions_plusends(1:end-1))/2);

    
% elseif strcmp(atlas,'IndParcels')
%     subject = varargin{1};
%     atlas_params.atlas = [atlas '_' subject]; %varargin1 should be subs name
%     
%     load(['/data/nil-bluearc/GMT/Caterina/TaskFC/FC_Parcels_Ind/' subject '_parcel_communities_colors.mat']); %load 'recolor_consen','color_list')
%     
%     assignments = recolor_consen;    
%     %networklabels = {'Unassigned','Default','Visual','FrontoPar','FrontoPar 2','DorsalAttn','DorsalAttn2','VentAttn','Salience','CingOperc','MotorHand','MotorMouth','Auditory','MTL1','MTL2','PERN','RetroSpl'};
%     networklabels = {'Unassigned','Default','Visual','FrontoPar','DorsalAttn','VentAttn','Salience','CingOperc','MotorHand','MotorMouth','Auditory','PERN','RetroSpl'};
% 
%     IDs = unique(assignments);    
%     for i = 1:length(IDs)
%         mods{i} = find(assignments == IDs(i));
%         if IDs(i) > length(networklabels)
%             networklabels{IDs(i)} = num2str(IDs(i));
%         end
%     end
%     atlas_params.networks = networklabels(IDs);
%     atlas_params.mods = mods;
%     atlas_params.mods_array = assignments;
%     atlas_params.num_rois = length(assignments);
%         
%     atlas_params.colors = color_list(IDs,:);    
%     
%     [communities atlas_params.sorti] = sort(assignments);
%     atlas_params.transitions = find(communities(1:end-1) ~= communities(2:end));
%     transitions_plusends = [1 atlas_params.transitions(:)' length(communities)];
%     atlas_params.centers = transitions_plusends(1:end-1) + ((transitions_plusends(2:end) - transitions_plusends(1:end-1))/2);

end

end

function net_array = make_net_array(net_cells)

for nc = 1:length(net_cells)
    net_array(net_cells{nc}) = nc;
end

end

function centers = compute_centers(mod_array)

full_trans = [1 find(diff(mod_array)) length(mod_array)];
trans_short = full_trans(1:end-1);
centers = trans_short + diff(full_trans)./2;
end