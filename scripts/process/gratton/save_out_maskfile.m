
function save_out_maskfile(input_template,out_data,outname)
outfile = load_nii(input_template); % for header info
img_dims = size(outfile.img);
outfile.img = reshape(out_data,img_dims);
outfile.prefix = outname;
save_nii(outfile,outname);


