## Data Cleaning for comparative-object-permanence
## Author: K. Voudouris (c) 2023. All Rights Reserved.
## R version: 4.3.1 (2023-06-16 ucrt) (Beagle Scouts)

library(tidyverse)
library(haven)
library(DBI)
library(RMariaDB)

## Set working directory to comparative-object-permanence

database_connection <- read.csv("agents/scripts/databaseConnectionDetails.csv")
db_name <- database_connection$database_name[1]
db_user <- database_connection$username[1]
db_pw <- database_connection$password[1]
db_host <- database_connection$hostname
db_port <- 3306

## Database Connection

drv <- MariaDB()
myDB <- dbConnect(drv,
                  user = db_user,
                  password = db_pw,
                  dbname = db_name, 
                  host = db_host, 
                  port = db_port)

## Load Metadata

metadata <- read.csv("analysis/meta-data-full.csv") %>% mutate(minPossReward = ifelse(lavaPresence == 1 & time_limit != Inf, -2,
                                                                                      ifelse(lavaPresence == 1 & time_limit == Inf, -1,
                                                                                             ifelse(lavaPresence != 1 & time_limit == Inf, 0, -1))),
                                                               maxPossReward = pass_mark + 1)

## Load raw performances

randomwalkers <- dbGetQuery(myDB, "SELECT instances.instancename, randomwalkers.agent_tag, randomwalkers.aai_seed, randomwalkerinstanceresults.finalreward FROM randomwalkerinstanceresults INNER JOIN randomwalkers ON randomwalkerinstanceresults.agentid = randomwalkers.agentid INNER JOIN instances ON randomwalkerinstanceresults.instanceid = instances.instanceid;")
randomactionagents <- dbGetQuery(myDB, "SELECT instances.instancename, randomactionagents.agent_tag, randomactionagents.aai_seed, randomactionagentinstanceresults.finalreward FROM randomactionagentinstanceresults INNER JOIN randomactionagents ON randomactionagentinstanceresults.agentid = randomactionagents.agentid INNER JOIN instances ON randomactionagentinstanceresults.instanceid = instances.instanceid WHERE randomactionagents.aai_seed = 356 OR randomactionagents.aai_seed = 1997 OR randomactionagents.aai_seed = 2023 OR randomactionagents.aai_seed = 1815 OR randomactionagents.aai_seed = 3761;")
vanillabraitenbergs <- dbGetQuery(myDB, "SELECT instances.instancename, vbraitenbergvehicles.agent_tag, vbraitenbergvehicles.aai_seed, vbraitenbergvehicleinstanceresults.finalreward FROM vbraitenbergvehicleinstanceresults INNER JOIN vbraitenbergvehicles ON vbraitenbergvehicles.agentid = vbraitenbergvehicleinstanceresults.agentid INNER JOIN instances ON vbraitenbergvehicleinstanceresults.instanceid = instances.instanceid;")

children <- read.csv("children/results_children.csv") %>%
  pivot_longer(cols = c(tutorial_0_ready.G2.sanity_1:OP.STC.Allo.CVChick.1Occluder.Right.RND.0.OPQ.1),
               names_to = "instancename",
               values_to = "finalreward") %>%
  mutate(instancename = str_replace_all(instancename, "[.]", "-"),
         instancename = str_replace_all(instancename, "2-5", "2.5"),
         instancename = str_replace_all(instancename, "Break-A|Break-B|Break-C", "test_break"),
         instancename = str_replace_all(instancename, "START", "test_start"),
         instancename = paste0(instancename, ".yml"),
         instancename = str_replace_all(instancename, "_1[.]yml|_2[.]yml|_3[.]yml", ".yml"),
         instancename = str_replace_all(instancename, "-1[.]yml|-2[.]yml|-3[.]yml", ".yml"),
         instancename = str_remove_all(instancename, "tutorial_8_|tutorial_9_|tutorial_10_")) %>%
  rename(agent_tag = participant_id) %>%
  drop_na(finalreward)

## Generate performances data set

combined_results <- bind_rows(randomwalkers, randomactionagents, vanillabraitenbergs, children)

metadata_results_raw <- inner_join(metadata, combined_results, by = c("InstanceName" = "instancename"))

metadata_results <- metadata_results_raw %>% mutate(roundedReward3dp = round(finalreward, 2), #rounding due to imprecision in rewards when passed from unity
                                                    proportionSuccess = (roundedReward3dp-minPossReward)/(maxPossReward - minPossReward), #what proportion of available points did they obtain?
                                                    success = ifelse(roundedReward3dp >= pass_mark, 1, 0), #did they pass or fail the instance?
                                                    # the problem with episode end is that if there are multiple yellow goals and lava, they might get a subset of the goals and then hit lava, making it difficult to read off exactly how the episode ended from the reward value
                                                    episodeEndType = ifelse(lavaPresence == 1 & roundedReward3dp < -1, "lava", # if there is lava, and the reward is less than -1, we can be sure they died by lava. Even if there are multiple goals, reward is never below -1 (as health is at 0 when reward is at -1 and so ends the episode)
                                                                            ifelse((lavaPresence != 1 | (lavaPresence == 1 & numYellowGoals <= 1)) & near(roundedReward3dp, -1), "time", # if there is no lava OR if there is lava and there are 1 or fewer yellow goals, and the reward is around -1, we can be sure that they ran out of time. 
                                                                                   ifelse(lavaPresence != 1 & !near(roundedReward3dp, -1) & numYellowGoals <= 1 & roundedReward3dp < pass_mark, "unobtainedGoal(s)",
                                                                                          ifelse(lavaPresence != 1 & numYellowGoals == 2 & roundedReward3dp < pass_mark & roundedReward3dp > pass_mark - 1, "1 of 2 goals obtained not lava",
                                                                                                 ifelse(roundedReward3dp >= pass_mark, "goal(s)Obtained",
                                                                                                        ifelse(decoyPresence == 1 & roundedReward3dp < pass_mark & !near(roundedReward3dp, -1), "decoyObtained", "unknown"))))))) %>%
  ## now to handle the tricky cases with yellow rewards
  mutate(episodeEndType = ifelse(episodeEndType == "unknown" & numYellowGoals > 1 & mainGoalSize == 0.5 & !near(roundedReward3dp, -1) & roundedReward3dp < pass_mark, "1 of 2 goals obtained not lava", episodeEndType))


