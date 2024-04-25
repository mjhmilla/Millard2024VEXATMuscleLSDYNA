
## Makefile to compile user material on dyn21.f in current folder 
# Define whether using SMP or MPP (this is also related to dyn21.f file)
# created Fabian Kempter 7. Nov. 2019
# modified Fabian Kempter 27. Oct. 2021
# modified Matthew Millard 8 Feb. 2022 
# modified Matthew Millard 25 April 2024


# get current directory
current_dir=$(shell pwd)


## PATTERNS FOR DEVELOPMENT
# combined Patterns
ALL: SMP931 MPP931

SMP931: replace_SMP931 compile_SMP931

MPP931: replace_MPP931 compile_MPP931


replace_SMP931:
	awk ' BEGIN       {p=1}   /^C start of umat43/   {print; system("cat WORK_R931/umat43.f");p=0} /^c END OF UMAT43/  {p=1} p' SMP_R931/dyn21.f >  dyn21.f_SMP
	cp dyn21.f_SMP SMP_R931/dyn21.f
# replace MPP

replace_MPP931:
	awk ' BEGIN       {p=1}   /^C start of umat43/   {print; system("cat WORK_R931/umat43.f");p=0} /^c END OF UMAT43/  {p=1} p' dyn21.f >  dyn21.f_MPP_R931
	cp dyn21.f_MPP MPP_R931/dyn21.f

# COMPILATION	
# compile SMP	
compile_SMP931:
	cp ${current_dir}/SMP_R931/dyn21.f ${current_dir}/build/SMP_9.3.1/usermat/dyn21.f
	cd ${current_dir}/build/SMP_9.3.1/usermat/ && $(MAKE)	
	cd ${current_dir}
	cp ${current_dir}/build/SMP_9.3.1/usermat/lsdyna ${current_dir}/SMP_R931/lsdyna
	
compile_MPP931:
	cp ${current_dir}/MPP_R931/dyn21.f ${current_dir}/build/MPP_9.3.1/usermat/dyn21.f
	cd ${current_dir}/build/MPP_9.3.1/usermat/ && $(MAKE)		
	cp ${current_dir}/build/MPP_9.3.1/usermat/mppdyna ${current_dir}/MPP_R931/mppdyna
