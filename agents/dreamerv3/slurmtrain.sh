#!/bin/bash
sbatch <<EOT
#!/bin/bash
#SBATCH --gpus=1
#SBATCH --job-name="COP-train"
#SBATCH --output=X%j-%x.out
singularity run \
  --nv \
  --env-file .env \
  dreamerv3-animalai.sif \
  train.sh
EOT
# This is not necessary, as singularity will be default mount the current directory.
# -v $(pwd):/dreamerv3-animalai/mnt/ \
# --workdir /dreamerv3-animalai/mnt/ \