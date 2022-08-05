function img_out = load_nii_wrapper(fname)
% quick function for loading linearized version of nii
% note: this assumes dimensions always loaded in same order and 4th dimension is always time.
% Set up a check for this?
% CG - 3.18.20

tmp = load_nii(fname);
img = tmp.img;
d = size(img);
d_lin = d(1)*d(2)*d(3);

if length(d) == 3
    %img = img(:);
    img_out = reshape(img,[d_lin 1]);
elseif length(d) == 4
    % assume 4th dimension is time
    img_out = reshape(img,[d_lin d(4)]);    
    % checked that this is equivalent to building a new linearized version
    % via for loop with : operator on the space dimensions
else
    error('this image has a weird number of dimensions');
end



end