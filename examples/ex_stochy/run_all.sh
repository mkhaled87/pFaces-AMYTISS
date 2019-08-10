OPTIONS="-CGH -d 3 -p"
echo $OPTIONS
pfaces -k amytiss.cpu@../../kernel-pack -cfg stochy2.cfg $OPTIONS | tee stochy2_run.txt
pfaces -k amytiss.cpu@../../kernel-pack -cfg stochy3.cfg $OPTIONS | tee stochy3_run.txt
pfaces -k amytiss.cpu@../../kernel-pack -cfg stochy4.cfg $OPTIONS | tee stochy4_run.txt
pfaces -k amytiss.cpu@../../kernel-pack -cfg stochy5.cfg $OPTIONS | tee stochy5_run.txt
pfaces -k amytiss.cpu@../../kernel-pack -cfg stochy6.cfg $OPTIONS | tee stochy6_run.txt
pfaces -k amytiss.cpu@../../kernel-pack -cfg stochy7.cfg $OPTIONS | tee stochy7_run.txt
pfaces -k amytiss.cpu@../../kernel-pack -cfg stochy8.cfg $OPTIONS | tee stochy8_run.txt
pfaces -k amytiss.cpu@../../kernel-pack -cfg stochy9.cfg $OPTIONS | tee stochy9_run.txt
pfaces -k amytiss.cpu@../../kernel-pack -cfg stochy10.cfg $OPTIONS | tee stochy10_run.txt
pfaces -k amytiss.cpu@../../kernel-pack -cfg stochy11.cfg $OPTIONS | tee stochy11_run.txt
pfaces -k amytiss.cpu@../../kernel-pack -cfg stochy12.cfg $OPTIONS | tee stochy12_run.txt