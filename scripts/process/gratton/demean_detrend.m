
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
