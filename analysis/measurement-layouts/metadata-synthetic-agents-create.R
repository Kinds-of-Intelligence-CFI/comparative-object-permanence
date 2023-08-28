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
  mutate(perfectAgent = rep(1, nrow(.)),
         failedAgent = rep(0, nrow(.)),
         noOPAgent = ifelse(goalBecomesAllocentricallyOccluded == 0, 1, 0),
         lowVisualAcuityAgent = ifelse(mainGoalSize < 2, 0, 1),
         poorNavigationOPAgent = ifelse((cityBlockDistanceToGoal * minNumTurnsRequired) <= 135, 1, 0),
         poorNavigationOPAgent = ifelse((cityBlockDistanceToGoal * minNumTurnsRequired) <= 135 & goalBecomesAllocentricallyOccluded == 0, 1, 0),
         CVChickBasicSpecificAgent = ifelse(pctbTask == 1, 0, 1),
         PCTBBasicSpecificAgent = ifelse(cvchickTask == 1, 0, 1))

###############################################################################################################################
###############################################          Final Data Save          #############################################
###############################################################################################################################

write.csv(metadata_synthetic_examples, "analysis/measurement-layouts/results_synthetic_agents_wide.csv", row.names = FALSE)
