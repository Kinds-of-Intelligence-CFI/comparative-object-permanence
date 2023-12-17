### Mixed Effects Models comparative-object-permanence
### Author: K. Voudouris, 2023 (c)
### Julia Version: 1.8.2

# Load packages
using DataFrames
using CSV
using MixedModels
using CategoricalArrays


## Working directory: comparative-object-permanence

data = CSV.read("./analysis/results_final_clean_long.csv", DataFrame)
data = data[(data[!, :problem_flag] .== "N"),:]
data = select(data, :InstanceName, :Suite, :SubSuite, :Instance, :basicTask, :opControlTask, :cvchickTask, :pctbGridTask, :pctb3CupTask, :agent_tag, :agent_tag_seed, :agent_type_mem, :agent_type_mem_noage, :agent_order_mem, :success, :correctChoice)

# Convert Predictor to a categorical variable
data.agent_type_mem_noage = categorical(data.agent_type_mem_noage)
levels!(data.agent_type_mem_noage, ["Random Walker", 
             "Random Action",
             "Braitenberg",
             "ppo-bc-all",
             "ppo-bc_opc-all",
             "ppo-bc_opc-strat",
             "ppo-bc_opc_opt-all",
             "ppo-bc_opc_opt-strat",
             "dreamer-bc-all",
             "dreamer-bc_opc-all",
             "dreamer-bc_opc-strat",
             "dreamer-bc_opc_opt-all",
             "dreamer-bc_opc_opt-strat",
             "Child"])
data = sort(data, :agent_order_mem)

basic_tasks = data[(data[!, :basicTask] .== 1),:]
op_control_cv = data[(data[!, :opControlTask] .== 1).&(data[!, :cvchickTask] .== 1),:]
op_control_cup = data[(data[!, :opControlTask] .== 1).&(data[!, :pctb3CupTask] .== 1),:]
op_control_grid = data[(data[!, :opControlTask] .== 1).&(data[!, :pctbGridTask] .== 1),:]
op_test_cv = data[(data[!, :opControlTask] .== 0).&(data[!, :cvchickTask] .== 1),:]
op_test_cup = data[(data[!, :opControlTask] .== 0).&(data[!, :pctb3CupTask] .== 1),:]
op_test_grid = data[(data[!, :opControlTask] .== 0).&(data[!, :pctbGridTask] .== 1),:]

## Mixed Models

successFormula = @formula(success ~ agent_type_mem_noage + (1 + agent_type_mem_noage | agent_tag_seed))

basic_success = fit(MixedModel, successFormula, basic_tasks, Bernoulli(), fast = false)
controlcv_success = fit(MixedModel, successFormula, op_control_cv, Bernoulli(), fast = false)
controlcup_success = fit(MixedModel, successFormula, op_control_cup, Bernoulli(), fast = false)
controlgrid_success = fit(MixedModel, successFormula, op_control_grid, Bernoulli(), fast = false)
testcv_success = fit(MixedModel, successFormula, op_test_cv, Bernoulli(), fast = false)
testcup_success = fit(MixedModel, successFormula, op_test_cup, Bernoulli(), fast = false)
testgrid_success = fit(MixedModel, successFormula, op_test_grid, Bernoulli(), fast = false)


confint95 = function(fixedeffects, stderrors)
    ci_bound = stderrors .* 1.96
    log_LL = fixedeffects - ci_bound
    log_UL = fixedeffects + ci_bound

    exp_fe = exp.(fixedeffects)
    LL = exp.(log_LL)
    UL = exp.(log_UL)

    output = hcat(exp_fe, LL, UL)

    return output
end 


open("./analysis/comparative-analysis/mixedModelsOutput/MixedModelsOutputSuccess.txt", "w") do io
    # Redirect standard output and standard error to the file
    redirect_stdout(io) do
        redirect_stderr(io) do
            println("Basic Tasks:")
            println("─────────────────────────────────────────────────────────────────────────────────")
            print(basic_success)
            println()
            println("Exponentiated Coefficients (Odds) with 95% Confidence intervals")
            basic_exponentiated_coefs = confint95(fixef(basic_success), stderror(basic_success))
            for o in 1:size(basic_exponentiated_coefs)[1]
                println(basic_exponentiated_coefs[o,:])
            end
            println("─────────────────────────────────────────────────────────────────────────────────")
            println()
            println("─────────────────────────────────────────────────────────────────────────────────")
            println("CV Controls:")
            println("─────────────────────────────────────────────────────────────────────────────────")
            print(controlcv_success)
            println()
            println("Exponentiated Coefficients (Odds) with 95% Confidence intervals")
            controlcv_exponentiated_coefs = confint95(fixef(controlcv_success), stderror(controlcv_success))
            for o in 1:size(controlcv_exponentiated_coefs)[1]
                println(controlcv_exponentiated_coefs[o,:])
            end
            println("─────────────────────────────────────────────────────────────────────────────────")
            println()
            println("─────────────────────────────────────────────────────────────────────────────────")
            println("Cup Controls:")
            println("─────────────────────────────────────────────────────────────────────────────────")
            print(controlcup_success)
            println()
            println("Exponentiated Coefficients (Odds) with 95% Confidence intervals")
            controlcup_exponentiated_coefs = confint95(fixef(controlcup_success), stderror(controlcup_success))
            for o in 1:size(controlcup_exponentiated_coefs)[1]
                println(controlcup_exponentiated_coefs[o,:])
            end
            println("─────────────────────────────────────────────────────────────────────────────────")
            println()
            println("─────────────────────────────────────────────────────────────────────────────────")
            println("Grid Controls:")
            println("─────────────────────────────────────────────────────────────────────────────────")
            print(controlgrid_success)
            println()
            println("Exponentiated Coefficients (Odds) with 95% Confidence intervals")
            controlgrid_exponentiated_coefs = confint95(fixef(controlgrid_success), stderror(controlgrid_success))
            for o in 1:size(controlgrid_exponentiated_coefs)[1]
                println(controlgrid_exponentiated_coefs[o,:])
            end
            println("─────────────────────────────────────────────────────────────────────────────────")
            println()
            println("─────────────────────────────────────────────────────────────────────────────────")
            println("CV Tests:")
            println("─────────────────────────────────────────────────────────────────────────────────")
            print(testcv_success)
            println()
            println("Exponentiated Coefficients (Odds) with 95% Confidence intervals")
            testcv_exponentiated_coefs = confint95(fixef(testcv_success), stderror(testcv_success))
            for o in 1:size(testcv_exponentiated_coefs)[1]
                println(testcv_exponentiated_coefs[o,:])
            end
            println("─────────────────────────────────────────────────────────────────────────────────")
            println()
            println("─────────────────────────────────────────────────────────────────────────────────")
            println("Cup Tests:")
            println("─────────────────────────────────────────────────────────────────────────────────")
            print(testcup_success)
            println()
            println("Exponentiated Coefficients (Odds) with 95% Confidence intervals")
            testcup_exponentiated_coefs = confint95(fixef(testcup_success), stderror(testcup_success))
            for o in 1:size(testcup_exponentiated_coefs)[1]
                println(testcup_exponentiated_coefs[o,:])
            end
            println("─────────────────────────────────────────────────────────────────────────────────")
            println()
            println("─────────────────────────────────────────────────────────────────────────────────")
            println("Grid Tests:")
            println("─────────────────────────────────────────────────────────────────────────────────")
            print(testgrid_success)
            println()
            println("Exponentiated Coefficients (Odds)")
            testgrid_exponentiated_coefs = confint95(fixef(testgrid_success), stderror(testgrid_success))
            for o in 1:size(testgrid_exponentiated_coefs)[1]
                println(testgrid_exponentiated_coefs[o,:])
            end
        end
    end
end



correctChoiceFormula = @formula(correctChoice ~ agent_type_mem_noage + (1 + agent_type_mem_noage | agent_tag_seed))

basic_correctChoice = fit(MixedModel, correctChoiceFormula, basic_tasks, Bernoulli(), fast = false)
controlcv_correctChoice = fit(MixedModel, correctChoiceFormula, op_control_cv, Bernoulli(), fast = false)
controlcup_correctChoice = fit(MixedModel, correctChoiceFormula, op_control_cup, Bernoulli(), fast = false)
controlgrid_correctChoice = fit(MixedModel, correctChoiceFormula, op_control_grid, Bernoulli(), fast = false)
testcv_correctChoice = fit(MixedModel, correctChoiceFormula, op_test_cv, Bernoulli(), fast = false)
testcup_correctChoice = fit(MixedModel, correctChoiceFormula, op_test_cup, Bernoulli(), fast = false)
testgrid_correctChoice = fit(MixedModel, correctChoiceFormula, op_test_grid, Bernoulli(), fast = false)

open("./analysis/comparative-analysis/mixedModelsOutput/MixedModelsOutputChoice.txt", "w") do io
    # Redirect standard output and standard error to the file
    redirect_stdout(io) do
        redirect_stderr(io) do
            println("Basic Tasks:")
            println("─────────────────────────────────────────────────────────────────────────────────")
            print(basic_correctChoice)
            println()
            println("Exponentiated Coefficients (Odds) with 95% Confidence intervals")
            basic_exponentiated_coefs = confint95(fixef(basic_correctChoice), stderror(basic_correctChoice))
            for o in 1:size(basic_exponentiated_coefs)[1]
                println(basic_exponentiated_coefs[o,:])
            end
            println("─────────────────────────────────────────────────────────────────────────────────")
            println()
            println("─────────────────────────────────────────────────────────────────────────────────")
            println("CV Controls:")
            println("─────────────────────────────────────────────────────────────────────────────────")
            print(controlcv_correctChoice)
            println()
            println("Exponentiated Coefficients (Odds) with 95% Confidence intervals")
            controlcv_exponentiated_coefs = confint95(fixef(controlcv_correctChoice), stderror(controlcv_correctChoice))
            for o in 1:size(controlcv_exponentiated_coefs)[1]
                println(controlcv_exponentiated_coefs[o,:])
            end
            println("─────────────────────────────────────────────────────────────────────────────────")
            println()
            println("─────────────────────────────────────────────────────────────────────────────────")
            println("Cup Controls:")
            println("─────────────────────────────────────────────────────────────────────────────────")
            print(controlcup_correctChoice)
            println()
            println("Exponentiated Coefficients (Odds) with 95% Confidence intervals")
            controlcup_exponentiated_coefs = confint95(fixef(controlcup_correctChoice), stderror(controlcup_correctChoice))
            for o in 1:size(controlcup_exponentiated_coefs)[1]
                println(controlcup_exponentiated_coefs[o,:])
            end
            println("─────────────────────────────────────────────────────────────────────────────────")
            println()
            println("─────────────────────────────────────────────────────────────────────────────────")
            println("Grid Controls:")
            println("─────────────────────────────────────────────────────────────────────────────────")
            print(controlgrid_correctChoice)
            println()
            println("Exponentiated Coefficients (Odds) with 95% Confidence intervals")
            controlgrid_exponentiated_coefs = confint95(fixef(controlgrid_correctChoice), stderror(controlgrid_correctChoice))
            for o in 1:size(controlgrid_exponentiated_coefs)[1]
                println(controlgrid_exponentiated_coefs[o,:])
            end
            println("─────────────────────────────────────────────────────────────────────────────────")
            println()
            println("─────────────────────────────────────────────────────────────────────────────────")
            println("CV Tests:")
            println("─────────────────────────────────────────────────────────────────────────────────")
            print(testcv_correctChoice)
            println()
            println("Exponentiated Coefficients (Odds) with 95% Confidence intervals")
            testcv_exponentiated_coefs = confint95(fixef(testcv_correctChoice), stderror(testcv_correctChoice))
            for o in 1:size(testcv_exponentiated_coefs)[1]
                println(testcv_exponentiated_coefs[o,:])
            end
            println("─────────────────────────────────────────────────────────────────────────────────")
            println()
            println("─────────────────────────────────────────────────────────────────────────────────")
            println("Cup Tests:")
            println("─────────────────────────────────────────────────────────────────────────────────")
            print(testcup_correctChoice)
            println()
            println("Exponentiated Coefficients (Odds) with 95% Confidence intervals")
            testcup_exponentiated_coefs = confint95(fixef(testcup_correctChoice), stderror(testcup_correctChoice))
            for o in 1:size(testcup_exponentiated_coefs)[1]
                println(testcup_exponentiated_coefs[o,:])
            end
            println("─────────────────────────────────────────────────────────────────────────────────")
            println()
            println("─────────────────────────────────────────────────────────────────────────────────")
            println("Grid Tests:")
            println("─────────────────────────────────────────────────────────────────────────────────")
            print(testgrid_correctChoice)
            println()
            println("Exponentiated Coefficients (Odds)")
            testgrid_exponentiated_coefs = confint95(fixef(testgrid_correctChoice), stderror(testgrid_correctChoice))
            for o in 1:size(testgrid_exponentiated_coefs)[1]
                println(testgrid_exponentiated_coefs[o,:])
            end
        end
    end
end