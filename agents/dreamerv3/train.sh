# # A1: Pre training run basic_controls
# xvfb-run -a python train.py \
#   --task ../../configs/tests_agents/training_curricula/basic_controls_curriculum.yml \
#   --env ../../env/env3.1.3/AAI.x86_64 \

# A2
xvfb-run -a python train.py \
  --task ../../configs/tests_agents/training_curricula/basic_op_controls_curriculum.yml \
  --env ../../env/env3.1.3/AAI.x86_64

# A3
 xvfb-run -a python train.py \
  --task ../../configs/tests_agents/training_curricula/all_suites_curriculum.yml \
  --env ../../env/env3.1.3/AAI.x86_64

# # A4p1: OP control part 1 continued from A1
# xvfb-run -a python train.py \
#   --task ../../configs/tests_agents/training_curricula/op_controls_33percent_part1.yml \
#   --env ../../env/env3.1.3/AAI.x86_64 \
#   --from-checkpoint ./logdir/A1/training-2023_10_12_15_13-basic_controls/checkpoint.ckpt

# A4p2: OP control part 2 continued from A4p1
# xvfb-run -a python train.py \
#   --task ../../configs/tests_agents/training_curricula/op_controls_33percent_part2.yml \
#   --env ../../env/env3.1.3/AAI.x86_64 \
#   --from-checkpoint ./logdir/A4/training-2023_10_16_11_45-op_controls_33percent_part1/checkpoint.ckpt

# A4 (A4p3): OP control part 3 continued from A4p2
xvfb-run -a python train.py \
  --task ../../configs/tests_agents/training_curricula/op_controls_33percent_part3.yml \
  --env ../../env/env3.1.3/AAI.x86_64 \
  --from-checkpoint ./logdir/A4/training-2023_10_18_20_41-op_controls_33percent_part2/checkpoint.ckpt
