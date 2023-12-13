#!/bin/bash

set -e
set -x
set -o pipefail
set -u

# Two arguments: the name of the experiment and the rest is the command to run
# Example: ./scripts/run.sh train2 ./scripts/train.sh
NAME=$1
COMMAND=${@:2}

chmod u+x $COMMAND

#SBATCH --nodelist=vrhpc2.dsic.upv.es
sbatch <<EOT
#!/bin/bash
#SBATCH --gpus=1
#SBATCH --cpus-per-task=4
#SBATCH --job-name="$NAME"
#SBATCH --output=X%j-%x.out
singularity run \
  --nv \
  --env-file .env \
  ../../../dreamerv3-animalai/dreamerv3-animalai.sif \
  $COMMAND
EOT