# ---------------------------Step 1-----------------------------------
# Extract lowb image from dwi
dwiextract dwi.mif - -bzero | mrmath - mean lowb_brain.nii.gz -axis 3

# Register lowb to T1 using ANTS
antsIntermodalityIntrasubject.sh -d 3 -i lowb_brain.nii.gz -r T1.nii.gz -x T1.nii.gz -o FAtoT1 -t 2

# Register T1 to MNI using ANTS
antsRegistrationSyN.sh -d 3 -f MNI152_T1_1mm_brain.nii.gz -m T1.nii.gz -o T1toMNI


# Apply warp of FA to MNI
antsApplyTransforms -d 3 -e 3 -i FA.nii.gz -n BSpline -r T1.nii.gz -o FAtoT1.nii.gz -t FAtoT11Warp.nii.gz -t FAtoT10GenericAffine.mat --float

antsApplyTransforms -d 3 -r MNI152_T1_1mm_brain.nii.gz -i FAtoT1.nii.gz -e 3 -t T1toMNI1Warp.nii.gz -t T1toMNI0GenericAffine.mat -o FAtoMNI.nii.gz -v 1

# copy and rename FA in standard space based on subject ID
cp FAtoMNI.nii.gz ${subj}.FA.nii.gz

# --------------------------Step 2------------------------------------
# Apply above transformations to native space ISO, ODI, and NDI data
antsApplyTransforms -d 3 -e 3 -i ICV.nii.gz -n BSpline -r T1.nii.gz -o ICVtoT1.nii.gz -t FAtoT11Warp.nii.gz -t FAtoT10GenericAffine.mat --float

antsApplyTransforms -d 3 -r MNI152_T1_1mm_brain.nii.gz -i ICVtoT1.nii.gz -e 3 -t T1toMNI1Warp.nii.gz -t T1toMNI0GenericAffine.mat -o ICVtoMNI.nii.gz -v 1

antsApplyTransforms -d 3 -e 3 -i ODI.nii.gz -n BSpline -r T1.nii.gz -o ODItoT1.nii.gz -t FAtoT11Warp.nii.gz -t FAtoT10GenericAffine.mat --float

antsApplyTransforms -d 3 -r MNI152_T1_1mm_brain.nii.gz -i ODItoT1.nii.gz -e 3 -t T1toMNI1Warp.nii.gz -t T1toMNI0GenericAffine.mat -o ODItoMNI.nii.gz -v 1

# --------------------------Step 3------------------------------------
# Create mean FA image to restrict later voxel-wise analysis to gray matter
echo "merging all upsampled FA images into single 4D image"

mrcat -force -nthreads 4 *FA* all_FA.nii.gz

# Process FA images, keeping voxels in which atleast 90 percent of images are present (this approach has been shown to produce less "holes" in the mean image; see https://www.ncbi.nlm.nih.gov/pmc/articles/PMC4137565/)
$FSLDIR/bin/fslmaths all_FA -max 0 -Tperc 10 -bin mean_FA_mask_10 -odt char
$FSLDIR/bin/fslmaths all_FA -mas mean_FA_mask_10 all_FA_10
$FSLDIR/bin/fslmaths all_FA_10 -mas MNI152_T1_1mm_brain_ero.nii.gz all_FA_10
$FSLDIR/bin/fslmaths all_FA_10 -Tmean mean_FA_10

# Threshold mean FA image to exclude major white matter tracts in voxel-wise analysis
${FSLDIR}/bin/fslmaths mean_FA_10 -uthr .2 -bin mean_FA_mask_gm

# Create mean ISO image to restrict later voxel-wise analysis to gray matter

mrcat -force *ISO* all_ISO.nii.gz
echo "creating valid mask and mean ISO"


$FSLDIR/bin/fslmaths all_ISO -max 0 -Tperc 10 -bin mean_ISO_mask_10 -odt char
$FSLDIR/bin/fslmaths all_ISO -mas mean_ISO_mask_10 all_ISO_10
$FSLDIR/bin/fslmaths all_ISO_10 -mas /data/bswift-1/dcallow/CONNECTOME/MNI152_T1_1mm_brain_ero.nii.gz all_ISO_10.nii.gz
$FSLDIR/bin/fslmaths all_ISO_10 -Tmean mean_ISO_10

# Create CSF mask by thresholding average image above 50%
${FSLDIR}/bin/fslmaths mean_ISO_10 -uthr .5 -bin mean_iso_mask

# Create mask to exclude WM and CSF for later GM analysis by combining mean_iso_mask and mean_FA_mask_gm
${FSLDIR}/bin/fslmaths mean_FA_mask_gm -add mean_iso_mask GM_CSF_WM_mask

# Final Gray matter mask to use in voxel wise analysis
${FSLDIR}/bin/fslmaths mean_FA_mask_10 -sub GM_CSF_WM_mask -bin gm_csf_mask_final


# Create merged dataset of NDI and ODI images

mrcat -force *ICV* all_ICV.nii.gz
echo "creating valid mask and mean ICV"


$FSLDIR/bin/fslmaths all_ICV -max 0 -Tperc 10 -bin mean_ICV_mask_10 -odt char
$FSLDIR/bin/fslmaths all_ICV -mas mean_ICV_mask_10 all_ICV_10
$FSLDIR/bin/fslmaths all_ICV_10 -mas /data/bswift-1/dcallow/CONNECTOME/MNI152_T1_1mm_brain_ero.nii.gz all_ICV_10
$FSLDIR/bin/fslmaths all_ICV_10 -Tmean mean_ICV_10

# Smooth NDI data by smoothing with -fwhm of 8. Use results in randomise
mrfilter -fwhm 8 all_ICV_10.nii.gz smooth all_ICV_filter_10.nii.gz

mrcat -force *ODI* all_ODI.nii.gz
echo "creating valid mask and mean ODI"


$FSLDIR/bin/fslmaths all_ODI -max 0 -Tperc 10 -bin mean_ODI_mask_10 -odt char
$FSLDIR/bin/fslmaths all_ODI -mas mean_ODI_mask_10 all_ODI_10
$FSLDIR/bin/fslmaths all_ODI_10 -mas /data/bswift-1/dcallow/CONNECTOME/MNI152_T1_1mm_brain_ero.nii.gz all_ODI_10
$FSLDIR/bin/fslmaths all_ODI_10 -Tmean mean_ODI_10

# Smooth ODI data by smoothing with -fwhm of 8. Use results in randomise
mrfilter -fwhm 8 all_ODI_10.nii.gz smooth all_ODI_filter_10.nii.gz

# ---------------------------Step 4--------------------------------------
# Randomise Analysis for gray matter

randomise -i all_ISO_filter_10.nii.gz -o ISO_endurance_age_sex_gait -d endurance_age_sex_gait.mat -t endurance_age_sex_gait.con -m gm_csf_mask_final.nii.gz -n 5000 -T
randomise -i all_ODI_filter_10.nii.gz -o ODI_endurance_age_sex_gait -d endurance_age_sex_gait.mat -t endurance_age_sex_gait.con -m gm_csf_mask_final.nii.gz -n 5000 -T

