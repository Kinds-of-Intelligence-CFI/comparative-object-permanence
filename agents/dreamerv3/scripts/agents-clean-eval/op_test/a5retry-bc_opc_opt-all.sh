# basic_controls = 257 tasks
# op_controls = 2129 tasks
# op_tests = 1833

# xvfb-run -a python train.py \
#   --eval-mode \
#   --task ../../configs/tests_agents/basic_controls \
#   --env ../../env/env3.1.3/AAI.x86_64 \
#   --from-checkpoint ./logdir/retry-a5-bc_opc_opt-all/checkpoint.ckpt \
#   --logdir ./logdir/a5retry-bc_opc_opt-all_basic_controls \
#   --dreamer-args "--run.steps 0.3e6"

# xvfb-run -a python train.py \
#   --eval-mode \
#   --task ../../configs/tests_agents/op_controls \
#   --env ../../env/env3.1.3/AAI.x86_64 \
#   --from-checkpoint ./logdir/retry-a5-bc_opc_opt-all/checkpoint.ckpt \
#   --logdir ./logdir/a5retry-bc_opc_opt-all_op_controls \
#   --dreamer-args "--run.steps 2.3e6"

xvfb-run -a python train.py \
  --eval-mode \
  --task ../../configs/tests_agents/op_tests \
  --env ../../env/env3.1.3/AAI.x86_64 \
  --from-checkpoint ./logdir/retry-a5-bc_opc_opt-all/checkpoint.ckpt \
  --logdir ./logdir/a5retry-bc_opc_opt-all_op_testsp2 \
  --start-from 980 \
  --dreamer-args "--run.steps 1.1e6"
