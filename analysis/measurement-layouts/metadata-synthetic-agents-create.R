###############################################################################################################################
##################################           Synthetic Calibration Data Creation          #####################################
###############################################################################################################################


########################################################################
###  Creating Synthetic Data for Calibrating Measurement Layouts     ###
###  Author: K. Voudouris (c) 2023. All Rights Reserved.             ###
###  R version: 4.3.1 (2023-06-16 ucrt) (Beagle Scouts)              ###
########################################################################


###############################################################################################################################
###############################################               Preamble            #############################################
###############################################################################################################################

library(tidyverse)



###############################################################################################################################
##############################################               Load Data              ###########################################
###############################################################################################################################

## Load Metadata

metadata <- read.csv("analysis/meta-data-full.csv") %>% mutate(minPossReward = ifelse(lavaPresence == 1 & time_limit != Inf, -2,
                                                                                      ifelse(lavaPresence == 1 & time_limit == Inf, -1,
                                                                                             ifelse(lavaPresence != 1 & time_limit == Inf, 0, -1))),
                                                               maxPossReward = ifelse(numYellowGoals > 1, numYellowGoals * mainGoalSize, pass_mark + 1)) %>%
  filter(numYellowGoals != 5) # Removing the 8 tasks that involve 5 yellow goals, as it is unclear what the pass_mark should be here, due to the role of health increasing the time span of the episode.

###############################################################################################################################
##################################               Create Synthetic Examples              #######################################
###############################################################################################################################

metadata_synthetic_examples <- metadata %>%
  mutate(perfectAgent_success = rep(1, nrow(.)),
         perfectAgent_choice = rep(1, nrow(.)),
         failedAgent_success = rep(0, nrow(.)),
         failedAgent_choice = rep(0, nrow(.)),
         noOPAgent_success = ifelse(goalBecomesAllocentricallyOccluded == 0, 1, 0),
         noOPAgent_choice = ifelse(goalBecomesAllocentricallyOccluded == 0, 1, 0),
         lowVisualAcuityAgent_success = ifelse(mainGoalSize < 2, 0, 1),
         lowVisualAcuityAgent_choice = ifelse(mainGoalSize < 2, 0, 1),
         poorNavigationOPAgent_success = ifelse((minDistToGoal * minNumTurnsGoal) <= 135, 1, 0),
         poorNavigationOPAgent_choice = ifelse((minDistToCorrectChoice * minNumTurnsChoice) <= 135, 1, 0),
         poorLavaOPAgent_success = ifelse(lavaPresence == 1, 0, 1),
         poorLavaOPAgent_choice = ifelse((lavaPresence == 1 & pctb3CupTask == 1) | (lavaPresence == 1 & basicTask == 1), 0, 1)) #specifically bad at the lava tasks when the lava is present before choice is made (only case for 3cup tasks with lava and with some of the basic tasks)

###############################################################################################################################
###############################################          Final Data Save          #############################################
###############################################################################################################################

write.csv(metadata_synthetic_examples, "analysis/measurement-layouts/results_synthetic_agents_wide.csv", row.names = FALSE)
