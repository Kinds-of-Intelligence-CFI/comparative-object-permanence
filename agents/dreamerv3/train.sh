xvfb-run python train.py \
  --task ../../configs/tests_agents/basic_controls.yml \
  --aai ../../env/env3.1.3/AAI.x86_64 \

# CUDA_VISIBLE_DEVICE=1 xvfb-run -a python train.py \
#   --task ../../configs/tests_agents/op_controls_50percent_part1.yml \
#   --aai ../../env/env3.1.2.exp/AAI.x86_64 \
#   --from-checkpoint ./logdir/training-2023_09_18_14_28-basic_controls/checkpoint.ckpt