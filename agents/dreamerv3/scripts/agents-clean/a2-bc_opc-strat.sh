xvfb-run -a python train.py \
  --task ../../configs/tests_agents/training_curricula/basic_op_controls_curriculum.yml \
  --env ../../env/env3.1.3/AAI.x86_64 \
  --logdir ./logdir/clean/a2-bc_opc-strat \
  --dreamer-args "--run.steps 4000000"