# -------------------------Step 1-------------------------------------
set subj= ($argv[1]) \
set SUBJECTS_DIR=/Data/location

cd ${SUBJECTS_DIR}/CONNECTOME/tbss
mkdir MD
mkdir OD
mkdir ICVF
mkdir ISOVF
# Copy individual FA files for each subject into tbss folder


/bin/cp ${SUBJECTS_DIR}/CONNECTOME/dwi/${subj}/T1w/Diffusion/FA.nii.gz ${SUBJECTS_DIR}/CONNECTOME/tbss/${subj}.nii.gz

# --------------------------Step 2------------------------------------
# Run subjects through tbss pipeline; for additional details see https://fsl.fmrib.ox.ac.uk/fsl/fslwiki/TBSS/UserGuide
fslreorient2std *.nii.gz
tbss_1_preproc *.nii.gz
tbss_2_reg -T
tbss_3_postreg -S
tbss_4_prestats 0.2


# --------------------------Step 3------------------------------------
# Copy over each subjects MD, ODI, and NDI images into folders to run tbss_non_FA script to get other diffusion metrics on skeleton
mkdir MD
mkdir OD
mkdir ICVF

/bin/cp ${SUBJECTS_DIR}/CONNECTOME/dwi/${subj}/T1w/Diffusion/MD.nii.gz ${SUBJECTS_DIR}/CONNECTOME/tbss/MD/${subj}.nii.gz
/bin/cp ${SUBJECTS_DIR}/CONNECTOME/dwi/${subj}/T1w/Diffusion/FIT_OD.nii.gz ${SUBJECTS_DIR}/CONNECTOME/tbss/OD/${subj}.nii.gz
/bin/cp ${SUBJECTS_DIR}/CONNECTOME/dwi/${subj}/T1w/Diffusion/FIT_ICVF.nii.gz ${SUBJECTS_DIR}/CONNECTOME/tbss/ICVF/${subj}.nii.gz

# --------------------------Step 4------------------------------------
# Run tbss_non_FA script
tbss_non_FA MD
tbss_non_FA OD
tbss_non_FA ICV


# --------------------------Step 5------------------------------------

# Randomise Analysis for white matter
randomise -i all_ICV_skeletonised.nii.gz -o NDI_regress_age_sex_gait -d endurance_age_sex_gait.mat -t endurance_age_sex_gait.con -m mean_FA_skeleton_mask.nii.gz -n 5000 --T2 -D
randomise -i all_OD_skeletonised.nii.gz -o ODI_regress_age_sex_gait -d endurance_age_sex_gait.mat -t endurance_age_sex_gait.con -m mean_FA_skeleton_mask.nii.gz -n 5000 --T2 -D

