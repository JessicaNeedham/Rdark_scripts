#!/bin/sh
# =======================================================================================
# =======================================================================================
export CIME_MODEL=e3sm
export COMPSET=2000_DATM%QIA_ELM%BGC-FATES_SICE_SOCN_SROF_SGLC_SWAV
export RES=ELM_USRDAT
export MACH=pm-cpu                                             # Name your machine
export COMPILER=gnu                                            # Name your compiler
export PROJECT=e3sm

export TAG=bci_rdark_ensemble_2pfts_0324
export CASE_ROOT=/pscratch/sd/j/jneedham/elm_runs/bci/mar24

export SITE_NAME=bci_0.1x0.1_v4.0i
export SITE_BASE_DIR=/pscratch/sd/j/jneedham
export ELM_USRDAT_DOMAIN=domain_bci_clm5.0.dev009_c180523.nc
export ELM_USRDAT_SURDAT=surfdata_bci_elm.c211027.nc
export ELM_SURFDAT_DIR=${SITE_BASE_DIR}/${SITE_NAME}
export ELM_DOMAIN_DIR=${SITE_BASE_DIR}/${SITE_NAME}
export DIN_LOC_ROOT_FORCE=${SITE_BASE_DIR}

export DATM_START=2003
export DATM_STOP=2016

export ninst=32



# DEPENDENT PATHS AND VARIABLES (USER MIGHT CHANGE THESE..)
# =======================================================================================
export SOURCE_DIR=/global/homes/j/jneedham/E3SM_calibration/E3SM/cime/scripts
cd ${SOURCE_DIR}

export CIME_HASH=`git log -n 1 --pretty=%h`
export ELM_HASH=`(cd  ../../components/elm/src;git log -n 1 --pretty=%h)`
export FATES_HASH=`(cd ../../components/elm/src/external_models/fates;git log -n 1 --pretty=%h)`
export GIT_HASH=E${ELM_HASH}-F${FATES_HASH}
export CASE_NAME=${CASE_ROOT}/${TAG}.${GIT_HASH}.`date +"%Y-%m-%d"`


# REMOVE EXISTING CASE IF PRESENT
rm -r ${CASE_NAME}

# CREATE THE CASE
./create_newcase --case=${CASE_NAME} --res=${RES} --compset=${COMPSET} --mach=${MACH} --compiler=${COMPILER} --project=${PROJECT} --ninst=$ninst


cd ${CASE_NAME}


#./xmlchange --id ELM_FORCE_COLDSTART --val on

# SET PATHS TO SCRATCH ROOT, DOMAIN AND MET DATA (USERS WILL PROB NOT CHANGE THESE)
# =================================================================================

./xmlchange ATM_DOMAIN_FILE=${ELM_USRDAT_DOMAIN}
./xmlchange ATM_DOMAIN_PATH=${ELM_DOMAIN_DIR}
./xmlchange LND_DOMAIN_FILE=${ELM_USRDAT_DOMAIN}
./xmlchange LND_DOMAIN_PATH=${ELM_DOMAIN_DIR}
./xmlchange DATM_MODE=CLM1PT
./xmlchange ELM_USRDAT_NAME=${SITE_NAME}
./xmlchange DIN_LOC_ROOT_CLMFORC=${DIN_LOC_ROOT_FORCE}
./xmlchange CIME_OUTPUT_ROOT=${CASE_NAME}


./xmlchange PIO_VERSION=2

# For constant CO2
./xmlchange CCSM_CO2_PPMV=412
./xmlchange DATM_CO2_TSERIES=none
./xmlchange ELM_CO2_TYPE=constant


# SPECIFY PE LAYOUT FOR SINGLE SITE RUN (USERS WILL PROB NOT CHANGE THESE)
# =================================================================================

./xmlchange NTASKS_ATM=1
./xmlchange NTASKS_CPL=1
./xmlchange NTASKS_GLC=1
./xmlchange NTASKS_OCN=1
./xmlchange NTASKS_WAV=1
./xmlchange NTASKS_ICE=1
./xmlchange NTASKS_LND=1
./xmlchange NTASKS_ROF=1
./xmlchange NTASKS_ESP=1
./xmlchange ROOTPE_ATM=0
./xmlchange ROOTPE_CPL=0
./xmlchange ROOTPE_GLC=0
./xmlchange ROOTPE_OCN=0
./xmlchange ROOTPE_WAV=0
./xmlchange ROOTPE_ICE=0
./xmlchange ROOTPE_LND=0
./xmlchange ROOTPE_ROF=0
./xmlchange ROOTPE_ESP=0
./xmlchange NTHRDS_ATM=1
./xmlchange NTHRDS_CPL=1
./xmlchange NTHRDS_GLC=1
./xmlchange NTHRDS_OCN=1
./xmlchange NTHRDS_WAV=1
./xmlchange NTHRDS_ICE=1
./xmlchange NTHRDS_LND=1
./xmlchange NTHRDS_ROF=1
./xmlchange NTHRDS_ESP=1

# SPECIFY RUN TYPE PREFERENCES (USERS WILL CHANGE THESE)
# =================================================================================

./xmlchange DEBUG=FALSE
./xmlchange STOP_N=50
./xmlchange REST_N=25
./xmlchange STOP_OPTION=nyears
./xmlchange REST_OPTION=nyears
./xmlchange RUN_STARTDATE='1900-01-01'
./xmlchange RESUBMIT=5

./xmlchange DATM_CLMNCEP_YR_START=${DATM_START}
./xmlchange DATM_CLMNCEP_YR_END=${DATM_STOP}

./xmlchange JOB_WALLCLOCK_TIME=08:58:00
./xmlchange JOB_QUEUE=regular
#./xmlchange JOB_WALLCLOCK_TIME=00:29:00
#./xmlchange JOB_QUEUE=debug
./xmlchange SAVE_TIMING=FALSE


# MACHINE SPECIFIC, AND/OR USER PREFERENCE CHANGES (USERS WILL CHANGE THESE)
# =================================================================================

./xmlchange GMAKE=make
#./xmlchange DOUT_S_SAVE_INTERIM_RESTART_FILES=TRUE
#./xmlchange DOUT_S=TRUE
#./xmlchange DOUT_S_ROOT=${CASE_NAME}/run
./xmlchange RUNDIR=${CASE_NAME}/run
./xmlchange EXEROOT=${CASE_NAME}/bld
./xmlchange SAVE_TIMING=FALSE

#for x in `seq 1 1 $ninst`; do
ensembles=(2 34 42 85 117 145 147 160)

count=1

for ens in "${ensembles[@]}"; do
    for ((v=0; v<=3; v++)); do
	    
	 expstr=$(printf %04d $count)
	 cat >> user_nl_elm_$expstr <<EOF
hist_nhtfrq = -8760
hist_mfilt = 1
fsurdat = '${ELM_SURFDAT_DIR}/${ELM_USRDAT_SURDAT}'
fates_paramfile='/global/homes/j/jneedham/BCI_leafmr/param_dir/Rdark_vert_ensemble/fates_params_rdark_ens${ens}_vert${v}.nc'
hist_fincl1='FATES_VEGC_PF', 'FATES_VEGC_ABOVEGROUND', 'FATES_VEGC_ABOVEGROUND_SZPF',
'FATES_AUTORESP_SZPF', 'FATES_GROWAR_SZPF', 'FATES_MAINTAR_SZPF', 'FATES_RDARK_SZPF',
'FATES_AGSAPMAINTAR_SZPF', 'FATES_BGSAPMAINTAR_SZPF', 'FATES_FROOTMAINTAR_SZPF',
'FATES_NPLANT_SZPF', 'FATES_CROWNAREA_PF', 'FATES_STOREC','FATES_LAI',
'FATES_BASALAREA_SZPF', 'FATES_CA_WEIGHTED_HEIGHT', 'Z0MG',
'FATES_MORTALITY_CSTARV_CFLUX_PF', 'FATES_MORTALITY_CFLUX_PF',
'FATES_MORTALITY_HYDRO_CFLUX_PF', 'FATES_MORTALITY_BACKGROUND_SZPF',
'FATES_MORTALITY_HYDRAULIC_SZPF', 'FATES_MORTALITY_CSTARV_SZPF',
'FATES_MORTALITY_IMPACT_SZPF', 'FATES_MORTALITY_TERMINATION_SZPF',
'FATES_MORTALITY_FREEZING_SZPF', 'FATES_MORTALITY_CANOPY_SZPF',
'FATES_MORTALITY_USTORY_SZPF', 'FATES_NPLANT_CANOPY_SZPF',
'FATES_NPLANT_USTORY_SZPF','FATES_NPP_PF', 'FATES_GPP_PF', 'FATES_NEP',
'FATES_FIRE_CLOSS','FATES_ABOVEGROUND_PROD_SZPF', 'FATES_ABOVEGROUND_MORT_SZPF',
'FATES_MORTALITY_USTORY_SZPF', 
'FATES_MORTALITY_CANOPY_SZPF',
'FATES_M3_MORTALITY_USTORY_SZPF',  'FATES_M3_MORTALITY_CANOPY_SZPF',
'FATES_LEAFC_CANOPY_SZPF', 'FATES_LEAFC_USTORY_SZPF','FATES_STOREC_USTORY_SZPF',
'FATES_STOREC_CANOPY_SZPF', 'FATES_TRIMMING_CANOPY_SZ',
'FATES_TRIMMING_USTORY_SZ','FATES_TRIMMING'
use_fates_nocomp=.false.                                                                                    
use_fates_logging=.false.
fates_parteh_mode = 1
use_fates=.true.
EOF

	 ((count++))
    done
done
	 
for x in `seq 1 1 $ninst`; do
expstr=$(printf %04d $x)
cat >> user_nl_datm_${expstr} <<EOF
taxmode = "cycle", "cycle", "cycle"
EOF
done

./case.setup
./preview_namelist


for x in `seq 1 1 $ninst`; do
    expstr=$(printf %04d $x)
    echo $expstr

    cp  run/datm.streams.txt.CLM1PT.ELM_USRDAT_${expstr} user_datm.streams.txt.CLM1PT.ELM_USRDAT_${expstr}
    `sed -i '/FLDS/d' user_datm.streams.txt.CLM1PT.ELM_USRDAT_${expstr}`
    
done
		  
./case.build
./case.submit --skip-preview-namelist
