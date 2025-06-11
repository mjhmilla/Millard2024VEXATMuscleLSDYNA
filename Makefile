#
# SPDX-FileCopyrightText: 2024 Matthew Millard <millard.matthew@gmail.com>
#
# SPDX-License-Identifier: MIT
#
#
#
# Makefile to compile user material on dyn21.f in current folder 
# Define whether using SMP or MPP (this is also related to dyn21.f file)
# created Fabian Kempter 7. Nov. 2019
# modified Fabian Kempter 27. Oct. 2021
# modified Matthew Millard 8 Feb. 2022 
# modified Matthew Millard 25 April 2024
# modified Matthew Millard July 2024


# get current directory
current_dir=$(shell pwd)


## PATTERNS FOR DEVELOPMENT
ALL: replace_EHTM replace_VEXAT compile_MPP931

VEXAT: replace_VEXAT compile_MPP931

EHTM: replace_MPP931 compile_MPP931

replace_EHTM:
	awk ' BEGIN       {p=1}   /^C start of umat41/   {print; system("cat WORK_R931/umat41.f");p=0} /^c END OF UMAT41/  {p=1} p' MPP_R931/dyn21.f >  dyn21.f_MPP_R931_41	
	cp dyn21.f_MPP_R931_41 MPP_R931/dyn21.f

replace_VEXAT:
	awk ' BEGIN       {p=1}   /^C start of umat43/   {print; system("cat WORK_R931/umat43.f");p=0} /^c END OF UMAT43/  {p=1} p' MPP_R931/dyn21.f >  dyn21.f_MPP_R931_43
	cp dyn21.f_MPP_R931_43 MPP_R931/dyn21.f

# COMPILATION		
compile_MPP931:
	cp ${current_dir}/MPP_R931/dyn21.f ${current_dir}/build/MPP_9.3.1/usermat/dyn21.f
	cd ${current_dir}/build/MPP_9.3.1/usermat/ && $(MAKE)		
	cp ${current_dir}/build/MPP_9.3.1/usermat/mppdyna ${current_dir}/MPP_R931/mppdyna
