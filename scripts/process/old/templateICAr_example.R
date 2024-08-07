# Build --> Install and Restart

# Setup ------------------------------------------------------------------------
# ciftiTools
library(ciftiTools)
print(packageVersion("ciftiTools"))
ciftiTools.setOption("wb_path", "~/Desktop/workbench")

# templateICAr
library(templateICAr)
print(packageVersion("templateICAr"))

library(RNifti)
library(gifti)
library(rgl)

# file paths
data_dir <- "data_notInPackage"
subjects <- c(100307, 100408, 100610)
cii_fnames <- c(
  paste0(data_dir, "/", subjects, "_rfMRI_REST1_LR_Atlas.dtseries.nii"),
  paste0(data_dir, "/", subjects, "_rfMRI_REST2_LR_Atlas.dtseries.nii")
)

GICA_fname <- c(
  cii = file.path(data_dir, "melodic_IC_100.4k.dscalar.nii")
)

xii1 <- select_xifti(read_cifti(GICA_fname["cii"]), 1) * 0

# Quick little check of the three main functions, w/ CIFTI ---------------------
tm_cii <- estimate_template(
  cii_fnames[seq(3)], 
  GICA = GICA_fname["cii"], TR=.72, FC=FALSE,
  brainstructures=c("left", "right")
)
tICA_cii <- templateICA(
  cii_fnames[4], tm_cii, brainstructures="left", 
  maxiter=5, TR="template", resamp_res=2000
)
actICA_cii <- activations(tICA_cii)