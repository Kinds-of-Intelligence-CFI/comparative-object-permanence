xvfb-run -a python train.py \
  --task ../../configs/tests_agents/training_curricula/all_suites_curriculum.yml \
  --env ../../env/env3.1.3/AAI.x86_64 \
  --logdir ./logdir/clean/a3-bc_opc_opt-strat \
  --dreamer-args "--run.steps 5000000"