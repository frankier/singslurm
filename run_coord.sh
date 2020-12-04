#!/usr/bin/env bash

if [[ -n "$TRACE" ]]; then
  set -o xtrace
fi

if [[ -z "$NUM_JOBS" ]]; then
  export NUM_JOBS=128
fi

[ -f $SIF_PATH ] || echo "Point $$SIF_PATH at Singularity .sif file."

# Step 1) Bootstrap slurm profile to temporary directory,
tmp_dir=$(mktemp -d -t singslurm-XXXXXXXXXX)
pushd $tmp_dir
git clone https://github.com/frankier/singslurm.git singslurm
cd singslurm
cat << CONFIGPY > singslurm/config.py
SBATCH_DEFAULTS = "$SBATCH_DEFAULTS"
CLUSTER_CONFIG = "$CLUSC_CONF"
ADVANCED_ARGUMENT_CONVERSION = False
CONFIGPY

# Step 2) Modify job starting script to use Singularity
cat << JOBSCRIPT > singslurm/slurm-jobscript.sh
#!/bin/bash
# properties = {properties}
cat << EXECJOB | singularity shell $SING_EXTRA_ARGS --nv $SIF_PATH 
{exec_job}
EXECJOB
JOBSCRIPT
chmod +x singslurm/slurm-jobscript.sh

cd ..

# Step 3) Bootstrap snakemake start script
cat << RUN_SNAKEMAKE > run_snakemake.sh
#!/usr/bin/env bash

snakemake \
  -j$NUM_JOBS \
  --profile $tmp_dir/singslurm/singslurm \
  --snakefile $SNAKEFILE \
  $@
RUN_SNAKEMAKE
chmod +x run_snakemake.sh

# Step 4)
# Execute Snakemake coordinator using Singularity
# Must map in bootstrapped tmp directory with:
#  * Snakemake SLURM profile
#  * Snakemake running script
sing_args=""
if [[ -n "$CLUSC_CONF_ON_HOST" ]]; then
    sing_args="--bind $CLUSC_CONF"
fi

popd

mkdir -p $tmp_dir/req_run
touch $tmp_dir/req_run/reqs

trap "exit" INT TERM
trap "kill 0" EXIT

tail -f $tmp_dir/req_run/reqs 2>/dev/null | $tmp_dir/singslurm/executor.sh $tmp_dir $ &

singularity exec \
    $sing_args \
    $SING_EXTRA_ARGS \
    --bind $SIF_PATH \
    --bind $tmp_dir \
    --bind $tmp_dir/req_run/:/var/run/req_run \
    $SIF_PATH $tmp_dir/run_snakemake.sh
