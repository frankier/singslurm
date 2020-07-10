# singslurm

This profile configures Snakemake installed within a Singularity container to run on the [SLURM Workload Manager](https://slurm.schedmd.com/)

The project is a fork of [the SLURM Snakemake
profile](https://github.com/Snakemake-Profiles/slurm), but some changes have
been made:

  * Add a coordinator script which sets up everything to run in Singularity and passes messages through the filesystem to the host to run SLURM commands on behalf of the container
  * Remove the reliance on cookiecutter completely. Basic customisation can be done with environment variables and stored in a bash script if required. For advanced customisation, just vendorise/fork this repo.

## Running
It can be run by downloading the self bootstrapping `run_coord.sh` file.

  $ wget https://raw.githubusercontent.com/frankier/singslurm/master/run_coord.sh
  $ chmod +x run_coord.sh

Then specifying arguments as environment variables:

 * $SIF_PATH: Path to Singularity SIF file for everything -- the Snakemake
   control job and the execution jobs on the cluster
 * $SNAKEFILE: Path within container to directory containing Snakefile
 * $CLUSC_CONF: Path within container to file mapping rules to resource requirements
 * $CLUSC_CONF_ON_HOST: If set $CLUSC_CONF is checked from the host system instead
 * $TRACE: Trace this script
 * $SBATCH_DEFAULTS: Default arguments to pass to sbatch
 * $NUM_JOBS: Max jobs at the Snakemake level. Each may include many SLURM tasks. 128 by default.

Its actual arguments will be passed to Snakemake within the container.

If you want to run the control job a cluster node, rather than a login node, just do e.g.:

  $ squeue

## Parsing arguments to SLURM (sbatch)
Arguments are overridden in the following order and must be named according to
[sbatch long option names](https://slurm.schedmd.com/sbatch.html):

1) $SBATCH_DEFAULTS environment variable
2) Profile `cluster_config` file `__default__` entries
3) Snakefile threads and resources (time, mem)
4) Profile `cluster_config` file <rulename> entries
5) `--cluster-config` parsed to Snakemake (deprecated since Snakemake 5.10)
6) Any other argument conversion (experimental, currently time, ntasks and mem) if `advanced_argument_conversion` is True.

## Resources
Resources specified in Snakefiles must all be in the correct unit/format as expected by `sbatch`.
The implemented resource names are given (and may be adjusted) in the `slurm_utils.RESOURCE_MAPPING` global.
This is intended for system agnostic resources such as time and memory.

## Cluster configuration file
The profile supports setting default and per-rule options in either the `cluster_config` file and
the [`--cluster-config` file parsed to snakemake](https://snakemake.readthedocs.io/en/stable/snakefiles/configuration.html#cluster-configuration-deprecated)
(the latter is deprecated since snakemake 5.10). The `__default__` entry will apply to all jobs. Both may be YAML (see example
below) or JSON files.

```yaml
__default__:
  account: staff
  mail-user: slurm@johndoe.com
  
large_memory_requirement_job:
  constraint: mem2000MB
  ntasks: 16
```


## Tests
Tests are currently broken.
