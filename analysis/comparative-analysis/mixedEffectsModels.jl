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
data = select(data, :InstanceName, :Suite, :SubSuite, :Instance, :basicTask, :opControlTask, :goalBecomesAllocentricallyOccluded, :cvchickTask, :pctbGridTask, :pctb3CupTask, :agent_tag, :agent_tag_seed, :agent_type, :success, :correctChoice)

# Convert Predictor to a categorical variable
data.agent_type = categorical(data.agent_type)
levels!(data.agent_type, ["Random Agent", 
             "Heuristic Agent",
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

## Mixed models by separate task type, comparing to the random agent

basic_tasks = data[(data[!, :basicTask] .== 1),:]
op_control_cv = data[(data[!, :opControlTask] .== 1).&(data[!, :cvchickTask] .== 1),:]
op_control_cup = data[(data[!, :opControlTask] .== 1).&(data[!, :pctb3CupTask] .== 1),:]
op_control_grid = data[(data[!, :opControlTask] .== 1).&(data[!, :pctbGridTask] .== 1),:]
op_test_cv = data[(data[!, :opControlTask] .== 0).&(data[!, :cvchickTask] .== 1),:]
op_test_cup = data[(data[!, :opControlTask] .== 0).&(data[!, :pctb3CupTask] .== 1),:]
op_test_grid = data[(data[!, :opControlTask] .== 0).&(data[!, :pctbGridTask] .== 1),:]

## Mixed Models

successFormula = @formula(success ~ agent_type + (1 + agent_type | agent_tag_seed))

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
            println("Exponentiated Coefficients (Odds) with 95% Confidence intervals")
            testgrid_exponentiated_coefs = confint95(fixef(testgrid_success), stderror(testgrid_success))
            for o in 1:size(testgrid_exponentiated_coefs)[1]
                println(testgrid_exponentiated_coefs[o,:])
            end
        end
    end
end



correctChoiceFormula = @formula(correctChoice ~ agent_type + (1 + agent_type | agent_tag_seed))

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
            println("Exponentiated Coefficients (Odds) with 95% Confidence intervals")
            testgrid_exponentiated_coefs = confint95(fixef(testgrid_correctChoice), stderror(testgrid_correctChoice))
            for o in 1:size(testgrid_exponentiated_coefs)[1]
                println(testgrid_exponentiated_coefs[o,:])
            end
        end
    end
end

## Mixed models comparing tests and controls

cv_tasks = data[(data[!, :cvchickTask] .== 1),:]
cup_tasks = data[(data[!, :pctb3CupTask] .== 1),:]
grid_tasks = data[(data[!, :pctbGridTask] .== 1),:]

successFormula = @formula(success ~ goalBecomesAllocentricallyOccluded + (1 + goalBecomesAllocentricallyOccluded | agent_tag_seed))

agents = ["Random Agent", 
"Heuristic Agent",
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
"Child"]

for agent in agents
    agent_data = cv_tasks[(cv_tasks[!, :agent_type] .== agent), :]
    try
        cv_fit = fit(MixedModel, successFormula, agent_data, Bernoulli(), fast = false)
        open("./analysis/comparative-analysis/mixedModelsOutput/MixedModelsOPControlComparisonOutputSuccess.txt", "a") do io
            # Redirect standard output and standard error to the file
            redirect_stdout(io) do
                redirect_stderr(io) do
                    println("CV Chick Tasks")
                    println("─────────────────────────────────────────────────────────────────────────────────")
                    println(agent, ":")
                    println("─────────────────────────────────────────────────────────────────────────────────")
                    print(cv_fit)
                    println()
                    println("Exponentiated Coefficients (Odds) with 95% Confidence intervals")
                    cv_exponentiated_coefs = confint95(fixef(cv_fit), stderror(cv_fit))
                    for o in 1:size(cv_exponentiated_coefs)[1]
                        println(cv_exponentiated_coefs[o,:])
                    end
                    println("─────────────────────────────────────────────────────────────────────────────────")
                    println()
                end
            end
        end
    catch
        println("Error with fit")
    end
end

for agent in agents
    agent_data = cup_tasks[(cup_tasks[!, :agent_type] .== agent), :]
    try
        cv_fit = fit(MixedModel, successFormula, agent_data, Bernoulli(), fast = false)
        open("./analysis/comparative-analysis/mixedModelsOutput/MixedModelsOPControlComparisonOutputSuccess.txt", "a") do io
            # Redirect standard output and standard error to the file
            redirect_stdout(io) do
                redirect_stderr(io) do
                    println("Cup Tasks")
                    println("─────────────────────────────────────────────────────────────────────────────────")
                    println(agent, ":")
                    println("─────────────────────────────────────────────────────────────────────────────────")
                    print(cv_fit)
                    println()
                    println("Exponentiated Coefficients (Odds) with 95% Confidence intervals")
                    cv_exponentiated_coefs = confint95(fixef(cv_fit), stderror(cv_fit))
                    for o in 1:size(cv_exponentiated_coefs)[1]
                        println(cv_exponentiated_coefs[o,:])
                    end
                    println("─────────────────────────────────────────────────────────────────────────────────")
                    println()
                end
            end
        end
    catch
        println("Error with fit")
    end
end

for agent in agents
    agent_data = grid_tasks[(grid_tasks[!, :agent_type] .== agent), :]
    try
        cv_fit = fit(MixedModel, successFormula, agent_data, Bernoulli(), fast = false)
        open("./analysis/comparative-analysis/mixedModelsOutput/MixedModelsOPControlComparisonOutputSuccess.txt", "a") do io
            # Redirect standard output and standard error to the file
            redirect_stdout(io) do
                redirect_stderr(io) do
                    println("Grid Tasks")
                    println("─────────────────────────────────────────────────────────────────────────────────")
                    println(agent, ":")
                    println("─────────────────────────────────────────────────────────────────────────────────")
                    print(cv_fit)
                    println()
                    println("Exponentiated Coefficients (Odds) with 95% Confidence intervals")
                    cv_exponentiated_coefs = confint95(fixef(cv_fit), stderror(cv_fit))
                    for o in 1:size(cv_exponentiated_coefs)[1]
                        println(cv_exponentiated_coefs[o,:])
                    end
                    println("─────────────────────────────────────────────────────────────────────────────────")
                    println()
                end
            end
        end
    catch
        println("Error with fit")
    end
end

choiceFormula = @formula(correctChoice ~ goalBecomesAllocentricallyOccluded + (1 + goalBecomesAllocentricallyOccluded | agent_tag_seed))

for agent in agents
    agent_data = cv_tasks[(cv_tasks[!, :agent_type] .== agent), :]
    try
        cv_fit = fit(MixedModel, choiceFormula, agent_data, Bernoulli(), fast = false)
        open("./analysis/comparative-analysis/mixedModelsOutput/MixedModelsOPControlComparisonOutputChoice.txt", "a") do io
            # Redirect standard output and standard error to the file
            redirect_stdout(io) do
                redirect_stderr(io) do
                    println("CV Chick Tasks")
                    println("─────────────────────────────────────────────────────────────────────────────────")
                    println(agent, ":")
                    println("─────────────────────────────────────────────────────────────────────────────────")
                    print(cv_fit)
                    println()
                    println("Exponentiated Coefficients (Odds) with 95% Confidence intervals")
                    cv_exponentiated_coefs = confint95(fixef(cv_fit), stderror(cv_fit))
                    for o in 1:size(cv_exponentiated_coefs)[1]
                        println(cv_exponentiated_coefs[o,:])
                    end
                    println("─────────────────────────────────────────────────────────────────────────────────")
                    println()
                end
            end
        end
    catch
        println("Error with fit")
    end
end

for agent in agents
    agent_data = cup_tasks[(cup_tasks[!, :agent_type] .== agent), :]
    try
        cv_fit = fit(MixedModel, choiceFormula, agent_data, Bernoulli(), fast = false)
        open("./analysis/comparative-analysis/mixedModelsOutput/MixedModelsOPControlComparisonOutputChoice.txt", "a") do io
            # Redirect standard output and standard error to the file
            redirect_stdout(io) do
                redirect_stderr(io) do
                    println("Cup Tasks")
                    println("─────────────────────────────────────────────────────────────────────────────────")
                    println(agent, ":")
                    println("─────────────────────────────────────────────────────────────────────────────────")
                    print(cv_fit)
                    println()
                    println("Exponentiated Coefficients (Odds) with 95% Confidence intervals")
                    cv_exponentiated_coefs = confint95(fixef(cv_fit), stderror(cv_fit))
                    for o in 1:size(cv_exponentiated_coefs)[1]
                        println(cv_exponentiated_coefs[o,:])
                    end
                    println("─────────────────────────────────────────────────────────────────────────────────")
                    println()
                end
            end
        end
    catch
        println("Error with fit")
    end
end

for agent in agents
    agent_data = grid_tasks[(grid_tasks[!, :agent_type] .== agent), :]
    try
        cv_fit = fit(MixedModel, choiceFormula, agent_data, Bernoulli(), fast = false)
        open("./analysis/comparative-analysis/mixedModelsOutput/MixedModelsOPControlComparisonOutputChoice.txt", "a") do io
            # Redirect standard output and standard error to the file
            redirect_stdout(io) do
                redirect_stderr(io) do
                    println("Grid Tasks")
                    println("─────────────────────────────────────────────────────────────────────────────────")
                    println(agent, ":")
                    println("─────────────────────────────────────────────────────────────────────────────────")
                    print(cv_fit)
                    println()
                    println("Exponentiated Coefficients (Odds) with 95% Confidence intervals")
                    cv_exponentiated_coefs = confint95(fixef(cv_fit), stderror(cv_fit))
                    for o in 1:size(cv_exponentiated_coefs)[1]
                        println(cv_exponentiated_coefs[o,:])
                    end
                    println("─────────────────────────────────────────────────────────────────────────────────")
                    println()
                end
            end
        end
    catch
        println("Error with fit")
    end
end