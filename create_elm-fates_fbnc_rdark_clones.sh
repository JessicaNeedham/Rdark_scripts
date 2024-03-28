#!/bin/sh

#SBATCH -N 5
#SBATCH --account=e3sm
#SBATCH -t 01:00:00
#SBATCH --job-name=bundlecompile
#SBATCH -o sout.%j
#SBATCH -e serr.%j

ninst=5

run_elm_fates(){
# ==============================================================================
# ==============================================================================
export CIME_MODEL=e3sm
export COMPSET=2000_DATM%QIA_ELM%BGC-FATES_SICE_SOCN_SROF_SGLC_SWAV 
export RES=f45_f45
export MACH=pm-cpu
export PROJECT=e3sm
export COMPILER=gnu

export ENSEMBLE=$1

export TAG=fbnc_f45_rdark_${ENSEMBLE}
export CASEROOT=/pscratch/sd/j/jneedham/elm_runs/fbnc_cal/rdark/
export CIMEROOT=/global/homes/j/jneedham/E3SM_calibration/E3SM/cime/scripts
cd ${CIMEROOT}

export CIME_HASH=`git log -n 1 --pretty=%h`
export ELM_HASH=`(cd ../../components/elm/src;git log -n 1 --pretty=%h)`
export FATES_HASH=`(cd ../../components/elm/src/external_models/fates;git log -n 1 --pretty=%h)`
export GIT_HASH=E${ELM_HASH}-F${FATES_HASH}	
export CASE_NAME=${CASEROOT}/${TAG}.${GIT_HASH}.`date +"%Y-%m-%d"`

# REMOVE EXISTING CASE DIRECTORY IF PRESENT 
rm -r ${CASE_NAME}

# CREATE THE CASE
./create_newcase --case=${CASE_NAME} --res=${RES} --compset=${COMPSET} --mach=${MACH} --compiler=${COMPILER} --project=${PROJECT}

cd ${CASE_NAME}

./xmlchange STOP_N=10
./xmlchange STOP_OPTION=nyears
./xmlchange REST_N=5
./xmlchange REST_OPTION=nyears
./xmlchange RESUBMIT=29
./xmlchange SAVE_TIMING=FALSE
./xmlchange DEBUG=FALSE

./xmlchange DATM_MODE=CLMGSWP3v1
./xmlchange RUN_STARTDATE='1900-01-01'
./xmlchange ELM_FORCE_COLDSTART=on
./xmlchange DATM_CLMNCEP_YR_ALIGN=1965
./xmlchange DATM_CLMNCEP_YR_START=1965
./xmlchange DATM_CLMNCEP_YR_END=2014


./xmlchange JOB_WALLCLOCK_TIME=11:58:00
./xmlchange JOB_QUEUE=regular
#./xmlchange JOB_WALLCLOCK_TIME=00:28:00
#./xmlchange JOB_QUEUE=debug

./xmlchange GMAKE=make
#./xmlchange DOUT_S_SAVE_INTERIM_RESTART_FILES=TRUE
#./xmlchange DOUT_S=TRUE
#./xmlchange DOUT_S_ROOT='$CASEROOT/run'
./xmlchange RUNDIR=${CASE_NAME}/run

./xmlchange EXEROOT=/pscratch/sd/j/jneedham/elm_runs/fbnc_cal/rdark/fbnc_f45_rdark_base_debug.Ea7f4ecb9dd-F5cc6b16e.2023-12-28/bld
./xmlchange BUILD_COMPLETE=TRUE

cat >> user_nl_elm <<EOF
use_fates_sp=.false.
use_fates_nocomp=.true.
use_fates_fixed_biogeog=.true.
fates_paramfile='/global/homes/j/jneedham/RCmodes/Parameter_files/fbnc_params/vert_mr/fates_params_vert${ENSEMBLE}.nc'
hist_fincl1='FATES_VEGC', 'FATES_FRACTION', 'FATES_GPP','FATES_NEP','FATES_AUTORESP', 'FATES_HET_RESP', 'QVEGE',
 'QVEGT','QSOIL','EFLX_LH_TOT','FSH','FSR', 'FSDS','FSA','FIRE','FLDS','FATES_LAI', 'FATES_LEAFC_SZPF',
'FATES_NPP_SZPF','FATES_GPP_PF','FATES_VEGC_PF','FATES_VEGC_ABOVEGROUND_SZPF', 'FATES_DDBH_SZPF',
 'FATES_NPLANT_SZPF','FATES_ZSTAR_AP','FATES_NPLANT_CANOPY_SZPF', 'FATES_NPLANT_USTORY_SZPF',
'FATES_MORTALITY_CANOPY_SZPF','FATES_MORTALITY_USTORY_SZPF','FATES_DDBH_CANOPY_SZPF','FATES_DDBH_USTORY_SZPF',
 'FATES_LAI','FATES_AGSTRUCT_ALLOC_SZPF','FATES_ABOVEGROUND_MORT_SZPF','FATES_ABOVEGROUND_PROD_SZPF',
 'FATES_LAI_CANOPY_SZPF','FATES_LAI_USTORY_SZPF','FATES_M3_MORTALITY_CANOPY_SZPF','FATES_M3_MORTALITY_USTORY_SZPF',
 'FATES_MORTALITY_HYDRAULIC_SZPF','FATES_MORTALITY_CSTARV_SZPF','FATES_MORTALITY_IMPACT_SZPF',
 'FATES_MORTALITY_TERMINATION_SZPF','FATES_MORTALITY_BACKGROUND_SZPF','FATES_MORTALITY_FREEZING_SZPF', 
'FATES_MORTALITY_FIRE_SZPF','FATES_NOCOMP_NPATCHES_PF','FATES_NOCOMP_PATCHAREA_PF','FATES_TRIMMING_CANOPY_SZ',
'FATES_TRIMMING_USTORY_SZ','FATES_TRIMMING', 'FATES_NET_C_UPTAKE_CLLLPF','FATES_LEAFC_PF', 'FATES_STOREC_PF',
 'FATES_NPP_USTORY_SZ', 'FATES_NPLANT_USTORY_SZ', 'FATES_MAINTAR_USTORY_SZ','FATES_GROWAR_USTORY_SZ',
 'FATES_STOREC_TF_USTORY_SZPF', 'FATES_STOREC_TF_CANOPY_SZPF', 'FATES_MAINTAR_CANOPY_SZ','FATES_GROWAR_CANOPY_SZ',
 'FATES_NPLANT_CANOPY_SZ'
EOF

cat >> user_nl_datm <<EOF
taxmode = "cycle", "cycle", "cycle"
EOF

./case.setup
./case.submit

}

counter=1

while [ $counter -le $ninst ]
do
    run_elm_fates $counter --no-batch -v  >&bsubmitout.txt
    echo $counter
    ((counter++))
done

wait

echo "Done!"
