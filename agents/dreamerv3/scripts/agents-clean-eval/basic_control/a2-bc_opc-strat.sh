# basic_controls = 257 tasks
# op_controls = 2129 tasks
# op_tests = 1833

xvfb-run -a python train.py \
  --eval-mode \
  --task ../../configs/tests_agents/basic_controls \
  --env ../../env/env3.1.3/AAI.x86_64 \
  --from-checkpoint ./logdir/clean/a2-bc_opc-strat/checkpoint.ckpt \
  --logdir ./logdir/clean-eval/a2-bc_opc-strat_basic_controls \
  --dreamer-args "--run.steps 300000"

# xvfb-run -a python train.py \
#   --eval-mode \
#   --task ../../configs/tests_agents/op_controls \
#   --env ../../env/env3.1.3/AAI.x86_64 \
#   --from-checkpoint ./logdir/clean/a2-bc_opc-strat/checkpoint.ckpt \
#   --logdir ./logdir/clean-eval/a2-bc_opc-strat_op_controls \
#   --dreamer-args "--run.steps 2300000"

# xvfb-run -a python train.py \
#   --eval-mode \
#   --task ../../configs/tests_agents/op_tests \
#   --env ../../env/env3.1.3/AAI.x86_64 \
#   --from-checkpoint ./logdir/clean/a2-bc_opc-strat/checkpoint.ckpt \
#   --logdir ./logdir/clean-eval/a2-bc_opc-strat_op_tests \
#   --dreamer-args "--run.steps 2000000"