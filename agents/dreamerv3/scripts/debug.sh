xvfb-run -a python train.py \
  --debug \
  --env ../../env/env3.1.3/AAI.x86_64 \
  --size small \
  --task ../../configs/tests_agents/basic_controls/ \
  --no-wandb