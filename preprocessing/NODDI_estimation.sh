set echo
set subj= ($argv[1]) \

cd /data/bswift-1/dcallow/CONNECTOME/dwi/${subj}/T1w/Diffusion

# Python
python <<EOF

# Set up amico 
import amico
import spams
amico.core.setup()

# Run Amico for NODDI estimation see https://github.com/daducci/AMICO/wiki/Fitting-the-NODDI-model for specific details
ae = amico.Evaluation("CONNECTOME/dwi/", "${subj}/T1w/Diffusion")
amico.util.fsl2scheme("CONNECTOME/dwi/${subj}/T1w/Diffusion/bvals","CONNECTOME/dwi/${subj}/T1w/Diffusion/bvecs",bStep=(0,$ae.load_data(dwi_filename = "data.nii.gz", scheme_filename = "bvals.scheme", mask_filename ="nodif_brain_mask.nii.gz", b0_thr = 5)
ae.set_model("NODDI")
ae.generate_kernels(regenerate=True)
ae.load_kernels()
ae.fit()

# Save results
ae.save_results()

EOF
