setenv SUBJECTS_DIR *****

set echo
set subj= ($argv[1]) \

mkdir ${SUBJECTS_DIR}/CONNECTOME
cd ${SUBJECTS_DIR}/CONNECTOME/dwi
mkdir ${subj}


# Dicom to Nifti file

cd ${SUBJECTS_DIR}/CONNECTOME/dwi/${subj}/T1w/
rm -rf tmp*
cd ${SUBJECTS_DIR}/CONNECTOME/dwi/${subj}/T1w/Diffusion

# Convert preprocessed diffusion data into mrtrix3 format
mrconvert -force -nthreads 4 -fslgrad bvecs bvals data.nii.gz dwi.mif

# Create tensor images
dwi2tensor -force -mask nodif_brain_mask.nii.gz dwi.mif tensor.mif
tensor2metric -force -fa FA.nii.gz tensor.mif
tensor2metric -force -adc MD.nii.gz tensor.mif
