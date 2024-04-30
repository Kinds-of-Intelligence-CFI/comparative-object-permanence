# ./scripts/slurmrun.sh evala1opc ./scripts/agents-clean-eval/op_control/a1-bc-all.sh && sleep 30s
./scripts/slurmrun.sh evala2opc ./scripts/agents-clean-eval/op_control/a2-bc_opc-strat.sh && sleep 30s
./scripts/slurmrun.sh evala3opc./scripts/agents-clean-eval/op_control/a3-bc_opc_opt-strat.sh && sleep 30s
./scripts/slurmrun.sh evala4opc ./scripts/agents-clean-eval/op_control/a4-bc_opc-all.sh && sleep 30s
./scripts/slurmrun.sh evala5opc ./scripts/agents-clean-eval/op_control/a5-bc_opc_opt-all.sh && sleep 30s

./scripts/slurmrun.sh evala1opt ./scripts/agents-clean-eval/op_test/a1-bc-all.sh && sleep 30s
# ./scripts/slurmrun.sh evala2opt ./scripts/agents-clean-eval/op_test/a2-bc_opc-strat.sh
# ./scripts/slurmrun.sh evala3opt./scripts/agents-clean-eval/op_test/a3-bc_opc_opt-strat.sh
./scripts/slurmrun.sh evala4opt ./scripts/agents-clean-eval/op_test/a4-bc_opc-all.sh && sleep 30s
# ./scripts/slurmrun.sh evala5opt ./scripts/agents-clean-eval/op_test/a5-bc_opc_opt-all.sh

