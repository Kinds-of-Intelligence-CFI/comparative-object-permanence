xvfb-run -a python train.py \
  --task ../../configs/tests_agents/training_curricula/op_tests_curriculum.yml \
  --env ../../env/env3.1.3/AAI.x86_64 \
  --from-checkpoint ./logdir/clean/a4-bc_opc-allp3/checkpoint.ckpt \
  --logdir ./logdir/retry-a5-bc_opc_opt-all \
  --dreamer-args "--run.steps 13000000"