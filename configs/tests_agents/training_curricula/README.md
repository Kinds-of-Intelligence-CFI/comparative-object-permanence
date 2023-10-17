# Training Curricula for PPO and Dreamer-v3

This folder contains configuration files for training `dreamer-v3` and PPO. Each algorithm is trained on the following 5 curricula to produce 10 agents:
1. `basic_controls_curriculum.yml` - contains all basic control tasks (254).
2. `basic_op_controls_curriculum.yml` - contains a stratified random sample of basic control tasks and op control tasks (303). Basic control; CVChick; PCTB Cup; and PCTB Grid are the strata.
3. `all_suits_curriculum.yml` - contains a stratified random sample of basic control tasks, op control tasks, and op test tasks (303). Basic control; CVChick Control; PCTB Cup Control; PCTB Grid Control; CVChick Test; PCTB Cup Test; PCTB Grid Test are the strata.
4. `basic_controls_curriculum.yml` + `op_controls_33percent_part1.yml` + `op_controls_33percent_part2.yml` + `op_controls_33percent_part3.yml` - the agent is trained sequentially for ~2M steps on each of these configs, ensuring full coverage of all control tasks. OP control tasks are partitioned randomly with no stratification.
5. `basic_controls_curriculum.yml` (254) + `op_controls_33percent_part1.yml` (709) + `op_controls_33percent_part2.yml` (708) + `op_controls_33percent_part3.yml` (709) + `op_tests_curriculum.yml` (301) - the agent is trained sequentially for ~2M steps on each of these configs. `op_tests_curriculum.yml` is a stratified random sample of op_tests tasks. CVChick Test; PCTB Cup Test; PCTB Grid Test are the strata.

Trained agents are available upon request.