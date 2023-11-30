xvfb-run -a python train.py \
  --task ../../configs/tests_agents/training_curricula/basic_controls_curriculum.yml \
  --env ../../env/env3.1.3/AAI.x86_64 \
  --logdir ./logdir/clean/a1-bc-all \
  --dreamer-args "--run.steps 4000000"

xvfb-run -a python train.py \
  --task ../../configs/tests_agents/training_curricula/op_controls_33percent_part1.yml \
  --env ../../env/env3.1.3/AAI.x86_64 \
  --from-checkpoint ./logdir/clean/a1-bc-all/checkpoint.ckpt \
  --logdir ./logdir/clean/a4-bc_opc-allp1 \
  --dreamer-args "--run.steps 6000000"

xvfb-run -a python train.py \
  --task ../../configs/tests_agents/training_curricula/op_controls_33percent_part2.yml \
  --env ../../env/env3.1.3/AAI.x86_64 \
  --from-checkpoint ./logdir/clean/a4-bc_opc-allp1/checkpoint.ckpt \
  --logdir ./logdir/clean/a4-bc_opc-allp2 \
  --dreamer-args "--run.steps 8000000"

xvfb-run -a python train.py \
  --task ../../configs/tests_agents/training_curricula/op_controls_33percent_part3.yml \
  --env ../../env/env3.1.3/AAI.x86_64 \
  --logdir ./logdir/clean/a4-bc_opc-allp3 \
  --from-checkpoint ./logdir/clean/a4-bc_opc-allp2/checkpoint.ckpt \
  --dreamer-args "--run.steps 10000000"

xvfb-run -a python train.py \
  --task ../../configs/tests_agents/training_curricula/op_tests_curriculum.yml \
  --env ../../env/env3.1.3/AAI.x86_64 \
  --from-checkpoint ./logdir/clean/a4-bc_opc-allp3/checkpoint.ckpt \
  --logdir ./logdir/clean/a5-bc_opc_opt-all \
  --dreamer-args "--run.steps 13000000"