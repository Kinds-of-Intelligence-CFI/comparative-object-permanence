###############################################################################################################################
###############################################           Data Cleaning           #############################################
###############################################################################################################################


############################################################
###  Data Cleaning for comparative-object-permanence     ###
###  Author: K. Voudouris (c) 2023. All Rights Reserved. ###
###  R version: 4.3.1 (2023-06-16 ucrt) (Beagle Scouts)  ###
############################################################


###############################################################################################################################
###############################################               Preamble            #############################################
###############################################################################################################################

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

###############################################################################################################################
##############################################               Load Data              ###########################################
###############################################################################################################################

## Load Metadata

metadata <- read.csv("analysis/meta-data-full.csv") %>% mutate(minPossReward = ifelse(lavaPresence == 1 & time_limit != Inf, -2,
                                                                                      ifelse(lavaPresence == 1 & time_limit == Inf, -1,
                                                                                             ifelse(lavaPresence != 1 & time_limit == Inf, 0, -1))),
                                                               maxPossReward = ifelse(numYellowGoals > 1, numYellowGoals * mainGoalSize, pass_mark + 1)) %>%
  filter(numYellowGoals != 5) # Removing the 8 tasks that involve 5 yellow goals, as it is unclear what the pass_mark should be here, due to the role of health increasing the time span of the episode.

## Load raw performances

randomwalkers <- dbGetQuery(myDB, "SELECT instances.instancename, randomwalkers.agent_tag, randomwalkers.aai_seed, randomwalkerinstanceresults.finalreward FROM randomwalkerinstanceresults INNER JOIN randomwalkers ON randomwalkerinstanceresults.agentid = randomwalkers.agentid INNER JOIN instances ON randomwalkerinstanceresults.instanceid = instances.instanceid;")
randomactionagents <- dbGetQuery(myDB, "SELECT instances.instancename, randomactionagents.agent_tag, randomactionagents.aai_seed, randomactionagentinstanceresults.finalreward FROM randomactionagentinstanceresults INNER JOIN randomactionagents ON randomactionagentinstanceresults.agentid = randomactionagents.agentid INNER JOIN instances ON randomactionagentinstanceresults.instanceid = instances.instanceid WHERE randomactionagents.aai_seed = 356 OR randomactionagents.aai_seed = 1997 OR randomactionagents.aai_seed = 2023 OR randomactionagents.aai_seed = 1815 OR randomactionagents.aai_seed = 3761;")
vanillabraitenbergs <- dbGetQuery(myDB, "SELECT instances.instancename, vbraitenbergvehicles.agent_tag, vbraitenbergvehicles.aai_seed, vbraitenbergvehicleinstanceresults.finalreward FROM vbraitenbergvehicleinstanceresults INNER JOIN vbraitenbergvehicles ON vbraitenbergvehicles.agentid = vbraitenbergvehicleinstanceresults.agentid INNER JOIN instances ON vbraitenbergvehicleinstanceresults.instanceid = instances.instanceid;")
ppoagents <- dbGetQuery(myDB, "SELECT instances.instancename, ppoagents.agent_tag, ppoagents.aai_seed, ppoagentinstanceresults.finalreward FROM ppoagentinstanceresults INNER JOIN ppoagents ON ppoagentinstanceresults.agentid = ppoagents.agentid INNER JOIN instances ON ppoagentinstanceresults.instanceid = instances.instanceid;")
dreameragents <- dbGetQuery(myDB, "SELECT instances.instancename, dreameragents.agent_tag, dreameragentinstanceresults.finalreward FROM dreameragentinstanceresults INNER JOIN dreameragents ON dreameragentinstanceresults.agentid = dreameragents.agentid INNER JOIN instances ON dreameragentinstanceresults.instanceid = instances.instanceid;") %>%
  mutate(aai_seed = 9999)


children <- read.csv("children/results_children.csv") %>%
  pivot_longer(cols = c(tutorial_0_ready.G2.sanity_1:OP.STC.Allo.CVChick.1Occluder.Right.RND.0.OPQ.1),
               names_to = "instancename_child",
               values_to = "finalreward") %>%
  mutate(instancename = str_replace_all(instancename_child, "[.]", "-"),
         instancename_child = str_replace_all(instancename_child, "[.]", "-"),
         instancename = str_replace_all(instancename, "2-5", "2.5"),
         instancename = str_replace_all(instancename, "1-5", "1.5"),
         instancename_child = str_replace_all(instancename_child, "2-5", "2.5"),
         instancename_child = str_replace_all(instancename_child, "1-5", "1.5"),
         instancename = str_replace_all(instancename, "Break-A|Break-B|Break-C", "test_break"),
         instancename = str_replace_all(instancename, "START", "test_start"),
         instancename = paste0(instancename, ".yml"),
         instancename_child = paste0(instancename_child, ".yml"),
         instancename = str_replace_all(instancename, "_1[.]yml|_2[.]yml|_3[.]yml", ".yml"),
         instancename = str_replace_all(instancename, "-1[.]yml|-2[.]yml|-3[.]yml", ".yml"),
         instancename = str_remove_all(instancename, "tutorial_8_|tutorial_9_|tutorial_10_")) %>%
  rename(agent_tag = participant_id) %>%
  drop_na(finalreward)

children_trajectory_data <- read.csv("children/trajectory_data_children.csv") %>%
  rename(agent_tag = participant_id,
         instancename_child = instance) %>%
  mutate(instancename_child = paste0(instancename_child, ".yml"))

###############################################################################################################################
###############################################     Simple Performance Metrics    #############################################
###############################################################################################################################

## Create a dataframe with all results, tagged by the kind of agent

combined_results <- bind_rows(randomwalkers, randomactionagents, vanillabraitenbergs, children, dreameragents, ppoagents) %>%
  mutate(agent_type = ifelse(str_detect(agent_tag, "Random"), "random", 
                             ifelse(str_detect(agent_tag, "Vanilla") | str_detect(agent_tag, "vision Braitenberg"), "Braitenberg",
                                    ifelse(str_detect(agent_tag, "ppo"), "PPO", ifelse
                                           (str_detect(agent_tag, "dreamer"), "Dreamer", "child")))))

## Add metadata information
metadata_results_raw <- inner_join(metadata, combined_results, by = c("InstanceName" = "instancename"))


## Create simple performance metrics

metadata_results <- metadata_results_raw %>% mutate(roundedReward3dp = round(finalreward, 2), #rounding due to imprecision in rewards when passed from unity
                                                    proportionSuccess = (roundedReward3dp-minPossReward)/(maxPossReward - minPossReward), #what proportion of available points did they obtain?
                                                    success = ifelse(roundedReward3dp >= pass_mark, 1, 0), #did they pass or fail the instance?
                                                    # the problem with episode end is that if there are multiple yellow goals and lava, they might get a subset of the goals and then hit lava, making it difficult to read off exactly how the episode ended from the reward value
                                                    episodeEndType = ifelse(lavaPresence == 1 & roundedReward3dp < -1, "lava", # if there is lava, and the reward is less than -1, we can be sure they died by lava. Even if there are multiple goals, reward is never below -1 (as health is at 0 when reward is at -1 and so ends the episode)
                                                                            ifelse((lavaPresence != 1 | (lavaPresence == 1 & numYellowGoals <= 1)) & near(roundedReward3dp, -1), "time", # if there is no lava OR if there is lava and there are 1 or fewer yellow goals, and the reward is around -1, we can be sure that they ran out of time. 
                                                                                   #ifelse(lavaPresence != 1 & !near(roundedReward3dp, -1) & numYellowGoals <= 1 & roundedReward3dp < pass_mark, ">=1 goal obtained",
                                                                                   ifelse(lavaPresence != 1 & numYellowGoals == 2 & roundedReward3dp < pass_mark & roundedReward3dp > -1, "time, obtained 1/2 goals",
                                                                                          ifelse(roundedReward3dp >= pass_mark, "all goal(s) obtained",
                                                                                                 ifelse(decoyPresence == 1 & roundedReward3dp < pass_mark & !near(roundedReward3dp, -1), "decoyObtained", "unknown")))))) %>%
  ### now to handle the tricky cases with yellow rewards
  mutate(episodeEndType = ifelse(episodeEndType == "unknown" & numYellowGoals == 2 & mainGoalSize == 0.5 & near(roundedReward3dp, -1), "time (may have obtained 1 goal)", #we cannot know if they timed out after getting a reward in the second half of the episode (when health was lower than 50), or whether they just timed out.
                                 ifelse(episodeEndType == "unknown" & numYellowGoals == 2 & mainGoalSize == 0.5 & roundedReward3dp > -1, "time or lava, obtained 1/2 goals", #if they did not finish at -1, but they did not pass, it means they obtained a reward in the first half of the  episode (when health was above 50), and then did not obtain the second goal. They may have timed out or hit lava during that time.
                                        ifelse(episodeEndType == "unknown" & numYellowGoals == 2 & mainGoalSize != 0.5 & near(roundedReward3dp, -1), "time", #the only way to get a score of exactly -1 (within float imprecision) is to time out without getting a reward
                                               ifelse(episodeEndType == "unknown" & numYellowGoals == 2 & mainGoalSize != 0.5 & roundedReward3dp > -1, "time or lava, obtained 1/2 goals", episodeEndType)))))


### Let's make a simpler episodeEndVariable

metadata_results <- metadata_results %>% mutate(episodeEndTypeSimple = ifelse(episodeEndType == "lava", "lava",
                                                                              ifelse(episodeEndType == "all goal(s) obtained", "pass",
                                                                                     ifelse(episodeEndType == "unknown", "unknown", "incomplete"))))

### Let's add the number of instances the agent had experienced before performing the test. This is 0 for the agents, who did not learn during the test, and more than 0 for the children as they proceed with the test.

children_task_names <- read.csv("children/results_children.csv") %>%
  colnames() %>%
  str_replace_all("\\.","-") %>%
  str_replace_all("2-5", "2.5") %>%
  str_replace_all("1-5", "1.5")

tutorial_names <- children_task_names[24:46] 
task_names_A <- c(tutorial_names, children_task_names[47:88]) %>%
  paste0(., ".yml")
task_names_B <- c(tutorial_names, children_task_names[47], rev(children_task_names[48:88])) %>%
  paste0(., ".yml")

order_in_task_sequence <- c()
#V inefficient but oh well.
for (row in 1:nrow(metadata_results)){
  if (is.na(metadata_results$task_order[row])){
    order_in_task_sequence <- c(order_in_task_sequence, 0)
  } else if (metadata_results$task_order[row] == "A"){
    for (name in 1:length(task_names_A)){
      if (task_names_A[name] == metadata_results$instancename_child[row]){
        order_in_task_sequence <- c(order_in_task_sequence, (name - 1))
        break
        }
      }
    } else if (metadata_results$task_order[row] == "B"){
      for (name in 1:length(task_names_B)){
        if (task_names_B[name] == metadata_results$instancename_child[row]){
          order_in_task_sequence <- c(order_in_task_sequence, (name - 1))
          break
        }
      }
    
  }
  
}

metadata_results$numberPreviousInstances <- order_in_task_sequence


###############################################################################################################################
########################################     Reward Independent Choice Metrics    #############################################
###############################################################################################################################

# Agents might be aware of where the goal is, but unable to navigate towards it.
# For the three paradigms, we can determine what their choices were by detecting which parts of the arena they entered,
# even if they did not obtain a reward.

task_ids <- dbReadTable(myDB, "instances") # obtain task IDs, to be used for querying the database.

## Define a function for building queries for the trajectory tables

trajectory_query_builder <- function(reference_df, agentname, seed, instanceidstring, paradigmtype, gridtype = NULL, subsuitetype = NULL){
  ## get the table names by looking at the agent_tag
  
  if (str_detect(agentname, "Random Walker")){
    agent_table_name <- "randomwalkers"
    agent_intraresults_table_name <- "randomwalkerintrainstanceresults"
  } else if (str_detect(agentname, "Random Action Agent")) {
    agent_table_name <- "randomactionagents"
    agent_intraresults_table_name <- "randomactionagentintrainstanceresults"
  } else if (str_detect(agentname, "Vanilla Braitenberg")){
    agent_table_name <- "vbraitenbergvehicles"
    agent_intraresults_table_name <- "vbraitenbergvehicleintrainstanceresults"
  } else if (str_detect(agentname, "dreamer")){
    agent_table_name <- "dreameragents"
    agent_intraresults_table_name <- "dreameragentintrainstanceresults"
  } else if (str_detect(agentname, "ppo")){
    agent_table_name <- "ppoagents"
    agent_intraresults_table_name <- "ppoagentintrainstanceresults"
  } else {
    stop("Agent not recognised.")
  }
  
  # Build specific queries depending on the type of task
  
  if (paradigmtype == "Grid"){
    # filter the reference dataframe by the type of grid (i.e., 12Cup, 4CupClose, etc.)
    ref_df <- filter(reference_df, Task == gridtype)
    
    # Depending on whether the task is a control task or not, the y_coord is different. We can't ignore it because an agent can in principle fly across the top of a hole if they have enough momentum.
    if (subsuitetype == "OP Controls"){
      y_coords <- ref_df$max_y_coord_RP
    } else if (subsuitetype == "Allocentric OP"){
      y_coords <- ref_df$max_y_coord_OP
    }
    
    # Create a query that returns the label that the agent chose depending on coordinates
    subquery <- paste0("WHEN EXISTS (SELECT 1 FROM ", agent_intraresults_table_name, " INNER JOIN ", agent_table_name, " ON ", agent_intraresults_table_name, ".agentid = ", agent_table_name, ".agentid AND ", agent_table_name, ".agent_tag = '", agentname, "' AND ", agent_table_name, ".aai_seed = ", seed, " AND ", agent_intraresults_table_name, ".instanceid = ", instanceidstring, " AND ", agent_intraresults_table_name, ".xpos BETWEEN ", ref_df$min_x_coord, ".0 AND ", ref_df$max_x_coord, ".0 AND ", agent_intraresults_table_name, ".zpos BETWEEN ", ref_df$min_z_coord, ".0 AND ", ref_df$max_z_coord, ".0 AND ", agent_intraresults_table_name, ".ypos BETWEEN ", ref_df$min_y_coord, ".0 AND ", y_coords, ") THEN '", ref_df$label, "'", collapse = " ")
    
    query <- paste0("SELECT CASE ", subquery, " ELSE 'NoChoiceMade' END AS result;")
    
    return(query)
    
  } else if (paradigmtype == "3Cup") {
    
    query_list <- paste0("SELECT EXISTS (SELECT 1 FROM ", agent_intraresults_table_name, " LEFT JOIN ", agent_table_name, " ON ", agent_intraresults_table_name, ".agentid = ", agent_table_name, ".agentid WHERE ", agent_table_name, ".agent_tag = '", agentname, "' AND ", agent_table_name, ".aai_seed = ", seed, " AND ", agent_intraresults_table_name, ".instanceid = ", instanceidstring, " AND ", agent_intraresults_table_name, ".xpos BETWEEN ", reference_df$min_x_coord, " AND ", reference_df$max_x_coord, " AND ", agent_intraresults_table_name, ".zpos BETWEEN ", reference_df$min_z_coord, " AND ", reference_df$max_z_coord, " AND ", agent_intraresults_table_name, ".ypos <= 0.5) AS result;") #make sure y = 0 so that they have fully entered the cup.
    
    return(query_list) # returns a list of 2 queries, one for left cup, one for mid cup, and one for right cup.
    
  } else if (paradigmtype == "CVChick"){
    left_query <- paste0("SELECT EXISTS (SELECT 1 FROM ", agent_intraresults_table_name, " LEFT JOIN ", agent_table_name, " ON ", agent_intraresults_table_name, ".agentid = ", agent_table_name, ".agentid WHERE ", agent_table_name, ".agent_tag = '", agentname, "' AND ", agent_table_name, ".aai_seed = ", seed, " AND ", agent_intraresults_table_name, ".instanceid = ", instanceidstring, " AND ", agent_intraresults_table_name, ".xpos <= ", reference_df$x_coord[1], " AND ", agent_intraresults_table_name, ".ypos <= 0.5) AS result;") # ypos is set to <= 0.5 to make sure they actually stepped off the platform, rather than sticking to the wall, which some of the braitenberg vehicles did
    right_query <- paste0("SELECT EXISTS (SELECT 1 FROM ", agent_intraresults_table_name, " LEFT JOIN ", agent_table_name, " ON ", agent_intraresults_table_name, ".agentid = ", agent_table_name, ".agentid WHERE ", agent_table_name, ".agent_tag = '", agentname, "' AND ", agent_table_name, ".aai_seed = ", seed, " AND ", agent_intraresults_table_name, ".instanceid = ", instanceidstring, " AND ", agent_intraresults_table_name, ".xpos >= ", reference_df$x_coord[2], " AND ", agent_intraresults_table_name, ".ypos <= 0.5) AS result;") # ypos is set to <= 0.5 to make sure they actually stepped off the platform, rather than sticking to the wall, which some of the braitenberg vehicles did
    
    query_list <- c(left_query, right_query)
    
    return(query_list) # returns a list of 2 queries, one for left cup, one for mid cup, and one for right cup.
    
  } else {
    stop("Paradigm not recognised, it should be one of \"Grid\", \"3Cup\", or \"CVChick\"")
  }
  
}


###################
## CVChick Tasks ##
###################

## Get the CVChick task data only
cvchick_tasks <- metadata_results %>%
  filter(Paradigm == "CVChick")

## Join the task ids to those task performances
cvchick_tasks_ids <- left_join(cvchick_tasks, task_ids, by = c("InstanceName" = "instancename")) 

## Get the specific data for children's trajectories on the test tasks.
children_trajectory_data_cvchick <- filter(children_trajectory_data, str_detect(instancename_child, "CVChick"))

## Add a column that encodes the side that the goal is on
cvchick_tasks_ids <- cvchick_tasks_ids %>%
  mutate(cvchickcorrectchoice = ifelse(str_detect(InstanceName, "Left"), "L", "R"))

### the platform down the centre has a width of 2 centred on the x coordinate of 20.

cvchick_reference <- data.frame(label = c("Left", "Right"),
                                x_coord = c(18.5, 21.5))
# If the agent has a coordinate below 18.5, they definitely made a left choice
# If the agent has a coordinate above 21.5, they definitely made a right choice.

cvchick_left_vector <- c() #initialise a vector to store whether the agent went left
cvchick_right_vector <- c() #initialise a vector to store whether the agent went right

for (row in 1:nrow(cvchick_tasks_ids)){
  print(row)
  agentname <- cvchick_tasks_ids$agent_tag[row]
  seed <- cvchick_tasks$aai_seed[row]
  instanceidstring <- cvchick_tasks_ids$instanceid[row]
  instancenamestring <- cvchick_tasks_ids$instancename_child[row]
  
  if (str_count(agentname) > 7){ #must be an agent
    
    queries <- trajectory_query_builder(reference_df = cvchick_reference, agentname = agentname, seed = seed, instanceidstring = instanceidstring, paradigmtype = "CVChick")
    
    left_result <- dbGetQuery(myDB, queries[1]) #get the query for the left side
    right_result <- dbGetQuery(myDB, queries[2]) #get the query for the right side
    
    cvchick_left_vector <- c(cvchick_left_vector, as.logical(left_result$result[1])) #append to the vector with a boolean
    cvchick_right_vector <- c(cvchick_right_vector, as.logical(right_result$result[1])) #append to the vector with a boolean
    
  } else { #must be a child
    
    # filter the dataframe so that it corresponds to that child on that instance
    filtered_df <- children_trajectory_data_cvchick %>% 
      filter(instancename_child == instancenamestring & agent_tag == agentname)
    
    if (nrow(filtered_df) > 0){ # only if this is an instance for which we have a stored trajectory (tutorials are not saved, and neither are crashed instances)
      
      # filter that dataframe for coordinates above or below the limits. Using "instancename_child" because some instances were played twice
      filtered_df_left <- filter(children_trajectory_data_cvchick, instancename_child == instancenamestring & agent_tag == agentname & x <= cvchick_reference$x_coord[1] & y <= 0.5) #y is to make sure they made it off the platform
      filtered_df_right <- filter(children_trajectory_data_cvchick, instancename_child == instancenamestring & agent_tag == agentname & x >= cvchick_reference$x_coord[2] & y <= 0.5) #y is to make sure they made it off the platform
      
      
      if (nrow(filtered_df_left) > 0){ # if there were some steps recorded with qualifying coordinates, then store true
        cvchick_left_vector <- c(cvchick_left_vector, TRUE)
      } else { # else store false
        cvchick_left_vector <- c(cvchick_left_vector, FALSE)
      }
      
      if (nrow(filtered_df_right) > 0){ # if there were some steps recorded with qualifying coordinates, then store true
        cvchick_right_vector <- c(cvchick_right_vector, TRUE)
      } else { # else store false
        cvchick_right_vector <- c(cvchick_right_vector, FALSE)
      }
    } else { # no trajectories stored for an instance, so store NA.
      cvchick_left_vector <- c(cvchick_left_vector, NA)
      cvchick_right_vector <- c(cvchick_right_vector, NA)
      
    }
    
  }
}

cvchick_tasks_final <- cvchick_tasks_ids
cvchick_tasks_final$cvchickleftchoice <- cvchick_left_vector
cvchick_tasks_final$cvchickrightchoice <- cvchick_right_vector


#####################
## PCTB Grid Tasks ##
#####################

## Pull in a reference that describes the min/max coordinates required to have entered a hole in the grid.
grid_task_reference <- read.csv("analysis/data_cleaning/grid_task_coord_reference.csv")

## Filter out all the PCTB grid tasks from the results table
pctb_grid_tasks <- metadata_results %>%
  filter(Paradigm == "PCTB" & str_detect(Task, "Grid"))

## Build a vector that contains all the hole that the goal is in (this information is stored in the instance name)
correct_choices <- c()

for (instance in 1:nrow(pctb_grid_tasks)){ # for each of the instances in the grid task table
  for (grid_type in 1:nrow(grid_task_reference)){ #for each of the grid types in the reference table
    # see if instance is one of the types in the table
    if (str_detect(pctb_grid_tasks$Task[instance], grid_task_reference$Task[grid_type]) & str_detect(pctb_grid_tasks$Instance[instance], grid_task_reference$Instance[grid_type])){
      label <- grid_task_reference$label[grid_type]
      correct_choices <- c(correct_choices, label) #if it is, store the label as the correct choice
      break #break the inner for loop if label is found
    }
  }
}

pctb_grid_tasks$pctbgridcorrectchoice <- correct_choices #join choices to task dataframe as ground truth.

pctb_grid_tasks_ids <- left_join(pctb_grid_tasks, task_ids, by = c("InstanceName" = "instancename")) #join task ids for DB querying

children_trajectory_data_pctb_grid <- filter(children_trajectory_data, str_detect(instancename_child, "Grid")) #get trajectories for children for Grid PCTB tasks

pctb_grid_cup_choices <- c() #initialise a vector for cup choices

for (row in 1:nrow(pctb_grid_tasks_ids)){
  print(row)
  agentname <- pctb_grid_tasks_ids$agent_tag[row]
  seed <- pctb_grid_tasks_ids$aai_seed[row]
  instanceidstring <- pctb_grid_tasks_ids$instanceid[row]
  instancenamestring <- pctb_grid_tasks_ids$instancename_child[row]
  taskname <- pctb_grid_tasks_ids$Task[row]
  subsuitename <- pctb_grid_tasks_ids$SubSuite[row]
  
  if (str_count(agentname) > 7){ #must be an agent
    
    #Get the trajectory query
    row_query <- trajectory_query_builder(reference_df = grid_task_reference, agentname = agentname, seed = seed, instanceidstring = instanceidstring, paradigmtype = "Grid", gridtype = taskname, subsuitetype = subsuitename)
    
    result <- dbGetQuery(myDB, row_query) #get the result
    
    result_string <- result$result[1] #convert to a string
    
    pctb_grid_cup_choices <- c(pctb_grid_cup_choices, result_string) #append to choice vector
  } else { #must be a child
    
    # filter the trajectory dataframe to only contain this child on this instance
    filtered_df <- children_trajectory_data_pctb_grid %>% 
      filter(instancename_child == instancenamestring & agent_tag == agentname)
    
    if (nrow(filtered_df) > 0){ #if there is trajectory information recorded
      
      for (grid_type in 1:length(unique(grid_task_reference$Task))){ #for each of the grid types in the reference dataframe
        
        if (str_detect(filtered_df$instancename_child[1], unique(grid_task_reference$Task)[grid_type])){ #check whether this instance is a kind of that
          
          # filter the reference dataframe to only refer to that kind of task (i.e., 12Cup, 4CupClose, etc.)
          ref_df <- grid_task_reference %>% filter(Task == unique(grid_task_reference$Task)[grid_type])
          break
        }
      }
      
      for (row in 1:nrow(ref_df)){ #for each of the possible positions in the dataframe
        if (subsuitename == "OP Controls"){
          # filter the dataframe for the appropriate coordinates
          check_df <- filter(filtered_df, x > ref_df$min_x_coord[row] & x < ref_df$max_x_coord[row] & z > ref_df$min_z_coord[row] & z < ref_df$max_z_coord[row] & y > ref_df$min_y_coord[row] & y < ref_df$max_y_coord_RP[row]) 
        } else if (subsuitename == "Allocentric OP"){
          check_df <- filter(filtered_df, x > ref_df$min_x_coord[row] & x < ref_df$max_x_coord[row] & z > ref_df$min_z_coord[row] & z < ref_df$max_z_coord[row] & y > ref_df$min_y_coord[row] & y < ref_df$max_y_coord_OP[row])
        } else {
          stop("Control type not recognised.")
        }
        if (nrow(check_df > 0)){ #if there are recorded steps within the qualifying coordinates
          pctb_grid_cup_choices <- c(pctb_grid_cup_choices, ref_df$label[row]) #record the label of those coordinates, corresponding to the cup explored
          break #break the loop
        }
        
        if (row == nrow(ref_df)){ # if we have tried all combinations and not got an answer, they must have not entered a hole in the grid.
          pctb_grid_cup_choices <- c(pctb_grid_cup_choices, "NoChoiceMade")
        }
      }
      
    } else { #if there is no trajectory information recorded, record NA for that choice.
      pctb_grid_cup_choices <- c(pctb_grid_cup_choices, NA)
    }
  }
}

pctb_grid_tasks_final <- pctb_grid_tasks_ids
pctb_grid_tasks_final$pctbgridcupchoice <- pctb_grid_cup_choices

# for the room practice tasks, you can get the reward without entering the cup, because it fills the whole cup, so need to fix the cup chosen to be the right cup when they picked correctly.

pctb_grid_tasks_final <- pctb_grid_tasks_final %>% 
  mutate(pctbgridcupchoice = ifelse(success == 1 , pctbgridcorrectchoice, pctbgridcupchoice))


######################
## 3 Cup PCTB Tasks ##
######################

## Create a reference dataframe with the coordinates for the three choices
threeCup_task_reference <- data.frame(label = c("L", "M", "R"),
                                      min_x_coord = c(0, 13.8, 27.1),
                                      max_x_coord = c(12.8, 26.1, 40),
                                      min_z_coord = c(30.5, 30.5, 30.5), # the top edge of the ramp is at z: 30. Placing this as z: 30.5 ensures that they have gone over the ramp
                                      max_z_coord = c(40, 40, 40)) #y_coordinates aren't important here. In 2 choice tasks, we assume that if the agent has crossed the highest part of the 2-way ramp, they have entered that cup.

## Filter out the results that are PCTB 3Cup tasks, and make a new column containing correct choices.
pctb_3cup_tasks <- metadata_results %>%
  filter(Paradigm == "PCTB" & str_detect(Task, "3Cup")) %>%
  mutate(pctb3cupcorrectchoice = str_remove(Instance, "[1-2]G[0-9][.]?[0-9]?|[1-2]Y[0-9][.]?[0-9]?"),
         pctb3cupcorrectchoice = str_remove(pctb3cupcorrectchoice, "Close|Far")) 

pctb_3cup_tasks_ids <- left_join(pctb_3cup_tasks, task_ids, by = c("InstanceName" = "instancename")) # append instance ids

children_trajectory_data_3cup <- filter(children_trajectory_data, str_detect(instancename_child, "3Cup")) # get the data just for these tasks for children

threecup_left_vector <- c() #initialise a vector for left cup
threecup_mid_vector <- c() # initialise a vector for mid cup
threecup_right_vector <- c() # initialise a vector for right cup

for (row in 1:nrow(pctb_3cup_tasks_ids)){
  print(row)
  agentname <- pctb_3cup_tasks_ids$agent_tag[row]
  seed <- pctb_3cup_tasks_ids$aai_seed[row]
  instanceidstring <- pctb_3cup_tasks_ids$instanceid[row]
  instancenamestring <- pctb_3cup_tasks_ids$instancename_child[row]
  taskname <- pctb_3cup_tasks_ids$Task[row]
  
  if (str_count(agentname) > 7){ #must be an agent
    
    #get queries for 3 cup tasks
    row_queries <- trajectory_query_builder(reference_df = threeCup_task_reference, agentname = agentname, seed = seed, instanceidstring = instanceidstring, paradigmtype = "3Cup")
    
    left_result <- dbGetQuery(myDB, row_queries[1]) # get the query the result of the query for the left cup
    mid_result <- dbGetQuery(myDB, row_queries[2]) # for the mid cup
    right_result <- dbGetQuery(myDB, row_queries[3]) # for the right cup
    
    threecup_left_vector <- c(threecup_left_vector, as.logical(left_result$result[1])) # store the result as a bool
    threecup_mid_vector <- c(threecup_mid_vector, as.logical(mid_result$result[1])) # store the result as a bool
    threecup_right_vector <- c(threecup_right_vector, as.logical(right_result$result[1])) # store the result as a bool
    
  } else { #must be a child
    
    # filter the trajectory data for just this child/instance pair
    filtered_df <- children_trajectory_data_3cup %>% 
      filter(instancename_child == instancenamestring & agent_tag == agentname)
    
    if (nrow(filtered_df) > 0){ # if there are some rows recorded
      #filter them appropriately and store as dataframes
      left_coord_check <- filter(filtered_df, x > threeCup_task_reference$min_x_coord[1] & x < threeCup_task_reference$max_x_coord[1] & z > threeCup_task_reference$min_z_coord[1] & z < threeCup_task_reference$max_z_coord[1] & y <= 0.5) # y <= 0.5 to make sure that they completed the ramp.
      mid_coord_check <- filter(filtered_df, x > threeCup_task_reference$min_x_coord[2] & x < threeCup_task_reference$max_x_coord[2] & z > threeCup_task_reference$min_z_coord[2] & z < threeCup_task_reference$max_z_coord[2] & y <= 0.5) # y <= 0.5 to make sure that they completed the ramp.
      right_coord_check <- filter(filtered_df, x > threeCup_task_reference$min_x_coord[3] & x < threeCup_task_reference$max_x_coord[3] & z > threeCup_task_reference$min_z_coord[3] & z < threeCup_task_reference$max_z_coord[3] & y <= 0.5) # y <= 0.5 to make sure that they completed the ramp.
      
      if (nrow(left_coord_check) > 0){ # if there are rows store TRUE
        threecup_left_vector <- c(threecup_left_vector, TRUE)
      } else { # else store FALSE
        threecup_left_vector <- c(threecup_left_vector, FALSE)
      }
      
      if (nrow(mid_coord_check) > 0){ # if there are rows store TRUE
        threecup_mid_vector <- c(threecup_mid_vector, TRUE)
      } else { # else store FALSE
        threecup_mid_vector <- c(threecup_mid_vector, FALSE)
      }
      
      if (nrow(right_coord_check) > 0){ # if there are rows store TRUE
        threecup_right_vector <- c(threecup_right_vector, TRUE)
      } else { # else store FALSE
        threecup_right_vector <- c(threecup_right_vector, FALSE)
      }
      
    } else { # if there is no trajectory data, store NA.
      threecup_left_vector <- c(threecup_left_vector, NA)
      threecup_mid_vector <- c(threecup_mid_vector, NA)
      threecup_right_vector <- c(threecup_right_vector, NA)
    }
  }
}

pctb_3cup_tasks_final <- pctb_3cup_tasks_ids 
pctb_3cup_tasks_final$threecupleftchoice <- threecup_left_vector
pctb_3cup_tasks_final$threecupmidchoice <- threecup_mid_vector
pctb_3cup_tasks_final$threecuprightchoice <- threecup_right_vector

###############################################################################################################################
###############################################         Data Integration          #############################################
###############################################################################################################################

## Create one large dataframe and store as CSV containing all metadata and all results

new_metrics <- bind_rows(cvchick_tasks_final, pctb_grid_tasks_final) %>%
  bind_rows(., pctb_3cup_tasks_final)

final_results <- left_join(metadata_results, new_metrics) %>%
  select(!instanceid)


###############################################################################################################################
######################################              Clean Up Episode End Type          ########################################
###############################################################################################################################

## There is some uncertainty about whether an agent died by lava or timing out, we can use the trajectories to determine that.

lava_locations <- data.frame(lavazone = c(1, 2, 3, 4, 5, 6),
                   min_x_coord = c(0, 9.6, 13.4, 23, 26.7, 36.3),
                   max_x_coord = c(3.6, 13.2, 17, 26.6, 30.3, 40),
                   min_z_coord = c(26.5, 26.5, 26.5, 26.5, 26.5, 26.5),
                   max_z_coord = c(29.5, 29.5, 29.5, 29.5, 29.5, 29.5))

goal_locations <- data.frame(goalposition = c("L", "M", "R"),
                             min_x_coord = c(7.75, 19.75, 33.15),
                             max_x_coord = c(8.25, 20.25, 33.65),
                             min_z_coord = c(37.75, 37.75, 37.75),
                             max_z_coord = c(38.25, 38.25, 38.25))

for (row in 1:nrow(final_results)){
  
  if (final_results$episodeEndType[row] == "time or lava, obtained 1/2 goals"){
    
    instancenamestring <- final_results$InstanceName[row]
    agentname <- final_results$agent_tag[row]
    seed <- final_results$aai_seed[row]
    
    
    if (final_results$agent_type[row] == "child"){
      filtered_df <- children_trajectory_data %>% 
        filter(instancename_child == instancenamestring & agent_tag == agentname)
      
      if (nrow(filtered_df) > 0){
        
        find_trajectories <- filter(filtered_df,
                                    ((between(x, lava_locations$min_x_coord[1], lava_locations$max_x_coord[1])) & (between(z, lava_locations$min_z_coord[1], lava_locations$max_z_coord[1]) & y <= 1.5) | 
                                      (between(x, lava_locations$min_x_coord[2], lava_locations$max_x_coord[2])) & (between(z, lava_locations$min_z_coord[2], lava_locations$max_z_coord[2]) & y <= 1.5) |
                                      (between(x, lava_locations$min_x_coord[3], lava_locations$max_x_coord[3])) & (between(z, lava_locations$min_z_coord[3], lava_locations$max_z_coord[3]) & y <= 1.5) |
                                      (between(x, lava_locations$min_x_coord[4], lava_locations$max_x_coord[4])) & (between(z, lava_locations$min_z_coord[4], lava_locations$max_z_coord[4]) & y <= 1.5) |
                                      (between(x, lava_locations$min_x_coord[5], lava_locations$max_x_coord[5])) & (between(z, lava_locations$min_z_coord[5], lava_locations$max_z_coord[5]) & y <= 1.5) |
                                      (between(x, lava_locations$min_x_coord[6], lava_locations$max_x_coord[6])) & (between(z, lava_locations$min_z_coord[6], lava_locations$max_z_coord[6]) & y <= 1.5)) &
                                      step == max(filtered_df$step)
                                      )
        
        if (nrow(find_trajectories) > 0){
          final_results$episodeEndType[row] <- "lava, obtained 1/2 goals"
        } else {
          final_results$episodeEndType[row] <- "time, obtained 1/2 goals"
        }
        
      } else{
        print("No trajectory data available.")
      }
      
      
      
      } else {
      if (str_detect(agentname, "Random Walker")){
        agent_table_name <- "randomwalkers"
        agent_intraresults_table_name <- "randomwalkerintrainstanceresults"
      } else if (str_detect(agentname, "Random Action Agent")) {
        agent_table_name <- "randomactionagents"
        agent_intraresults_table_name <- "randomactionagentintrainstanceresults"
      } else if (str_detect(agentname, "Vanilla Braitenberg")){
        agent_table_name <- "vbraitenbergvehicles"
        agent_intraresults_table_name <- "vbraitenbergvehicleintrainstanceresults"
      } else if (str_detect(agentname, "ppo")){
        agent_table_name <- "ppoagents"
        agent_intraresults_table_name <- "ppoagentintrainstanceresults"
      } else if (str_detect(agentname, "dreamer")){
        agent_table_name <- "dreameragents"
        agent_intraresults_table_name <- "dreameragentintrainstanceresults"
      } else {
        stop("Agent not recognised.")
      }
      
      instanceid <- paste0("SELECT instanceid FROM instances WHERE instancename = '", instancenamestring, "';") %>%
        dbGetQuery(myDB, .)
      
      if (nrow(instanceid) > 1){
        stop("Multiple instance ids found.")
      }
      
      subquery <- paste0("(", agent_intraresults_table_name, ".xpos BETWEEN ", lava_locations$min_x_coord, " AND ", lava_locations$max_x_coord, " AND ", agent_intraresults_table_name, ".zpos BETWEEN ", lava_locations$min_z_coord, " AND ", lava_locations$max_z_coord, " AND ", agent_intraresults_table_name, ".ypos <= 1.5)", collapse = " OR ")
      
      query <- paste0("SELECT EXISTS (SELECT 1 FROM ", agent_intraresults_table_name, " LEFT JOIN ", agent_table_name, " ON ", agent_intraresults_table_name, ".agentid = ", agent_table_name, ".agentid WHERE ", agent_intraresults_table_name, ".instanceid = ", instanceid$instanceid[1], " AND ", agent_table_name, ".agent_tag = '", agentname, "' AND ", agent_table_name, ".aai_seed = ", seed, " AND (", subquery, ")) AS result;")
      
      result <- dbGetQuery(myDB, query)
      
      if(as.logical(result$result[1]) == TRUE){
        final_results$episodeEndType[row] <- "lava, obtained 1/2 goals"
      } else {
        final_results$episodeEndType[row] <- "time, obtained 1/2 goals"
      }
    }
  } else if (final_results$episodeEndType[row] == "time (may have obtained 1 goal)"){
    
    instancenamestring <- final_results$InstanceName[row]
    agentname <- final_results$agent_tag[row]
    seed <- final_results$aai_seed[row]
    
    if (final_results$agent_type[row] == "child"){
      
      next # there are no children with this as they only played instances with goal size of 2. This only applies to goal size 0.5 
      
    } else {
      if (str_detect(agentname, "Random Walker")){
        agent_table_name <- "randomwalkers"
        agent_intraresults_table_name <- "randomwalkerintrainstanceresults"
      } else if (str_detect(agentname, "Random Action Agent")) {
        agent_table_name <- "randomactionagents"
        agent_intraresults_table_name <- "randomactionagentintrainstanceresults"
      } else if (str_detect(agentname, "Vanilla Braitenberg")){
        agent_table_name <- "vbraitenbergvehicles"
        agent_intraresults_table_name <- "vbraitenbergvehicleintrainstanceresults"
      } else if (str_detect(agentname, "ppo")){
        agent_table_name <- "ppoagents"
        agent_intraresults_table_name <- "ppoagentintrainstanceresults"
      } else if (str_detect(agentname, "dreamer")){
        agent_table_name <- "dreameragents"
        agent_intraresults_table_name <- "dreameragentintrainstanceresults"
      } else {
        stop("Agent not recognised.")
      }
      
      instanceid <- paste0("SELECT instanceid FROM instances WHERE instancename = '", instancenamestring, "';") %>%
        dbGetQuery(myDB, .)
      
      if (nrow(instanceid) > 1){
        stop("Multiple instance ids found.")
      }
      
      subquery <- paste0("(", agent_intraresults_table_name, ".xpos BETWEEN ", goal_locations$min_x_coord, " AND ", goal_locations$max_x_coord, " AND ", agent_intraresults_table_name, ".zpos BETWEEN ", goal_locations$min_z_coord, " AND ", goal_locations$max_z_coord, " AND ", agent_intraresults_table_name, ".ypos <= 1.5)", collapse = " OR ")
      
      query <- paste0("SELECT EXISTS (SELECT 1 FROM ", agent_intraresults_table_name, " LEFT JOIN ", agent_table_name, " ON ", agent_intraresults_table_name, ".agentid = ", agent_table_name, ".agentid WHERE ", agent_intraresults_table_name, ".instanceid = ", instanceid$instanceid[1], " AND ", agent_table_name, ".agent_tag = '", agentname, "' AND ", agent_table_name, ".aai_seed = ", seed, " AND (", subquery, ")) AS result;")
      
      result <- dbGetQuery(myDB, query)
      
      if(as.logical(result$result[1]) == TRUE){
        final_results$episodeEndType[row] <- "time, obtained 1/2 goals"
      } else {
        final_results$episodeEndType[row] <- "time"
      }
      
    }
    
  } else {
    next
  }
}



dbDisconnect(myDB)


###############################################################################################################################
###############################################      Run Data Quality Checks      #############################################
###############################################################################################################################

## Now some post hoc sanity checks to make sure that the results make sense

checking_dataframe <- final_results %>%
  filter((threecupleftchoice == threecupmidchoice & threecupmidchoice == threecuprightchoice & threecuprightchoice == TRUE & str_detect(InstanceName, "FC") & success == 1) | #should be impossible to have visited all 3 cups and still pass
           (cvchickleftchoice == cvchickrightchoice & cvchickleftchoice == TRUE) |  #should be impossible to go both left and right (unless they stick to the wall, which is possible but rare)
            (pctbgridcupchoice != pctbgridcorrectchoice & success == 1) | # this should be impossible - and there aren't any cases of it.
           (pctbgridcupchoice == pctbgridcorrectchoice & success == 0) | # all these cases are conceivably cases where the agent entered the cup but managed to avoid the goal. The RP versions, the goal is the smallest possible (2x2x2) in a hole of size 4x4x4. So there is room around the edge for the agent to walk. Looking at the coordinates, this looks feasible. # On the grid tasks, it is possible to enter the hole but not succeed (by sticking to the walls). And we have already set that if they succeeded but didn't enter the hole, then that was because it was a room practice task. These were the only tasks where that was the case.
           (episodeEndType == "time, obtained 1/2 goals" & threecupleftchoice == threecupmidchoice & threecupmidchoice == threecuprightchoice & threecuprightchoice == FALSE) | #should be impossible to have a score that suggests they entered at least 1 cup, but then coordinates disagre
           success == 1 & ((cvchickcorrectchoice == "L" & cvchickrightchoice == TRUE)|(cvchickcorrectchoice == "R" & cvchickleftchoice == TRUE))) %>% #shouldn't be able to have gone the wrong way and still passed.
dplyr::select(c(agent_type, InstanceName, success))


checking_episode_end_annotation <- final_results %>%
  select(c(InstanceName, finalreward, episodeEndType, agent_type)) %>% distinct()

## Remaining unknowns are three children, and it corresponds to the episodes before they decided to stop playing. These results are likely mid-game rewards recorded while the environment shut down.
### Adding a flag to drop them from analysis.

final_results <- final_results %>% mutate(correctChoice = ifelse((is.na(cvchickcorrectchoice) & is.na(pctbgridcorrectchoice) & is.na(pctb3cupcorrectchoice)), success,
                                                                 ifelse((is.na(pctbgridcorrectchoice) & is.na(pctb3cupcorrectchoice) & cvchickcorrectchoice == "R" & cvchickrightchoice == TRUE & cvchickleftchoice == FALSE)|
                                                                          (is.na(pctbgridcorrectchoice) & is.na(pctb3cupcorrectchoice) & cvchickcorrectchoice == "L" & cvchickleftchoice == TRUE & cvchickrightchoice == FALSE) | 
                                                                          (is.na(cvchickcorrectchoice) & is.na(pctb3cupcorrectchoice) & (pctbgridcupchoice == pctbgridcorrectchoice | success == 1)) | 
                                                                          (is.na(cvchickcorrectchoice) & is.na(pctbgridcorrectchoice) & pctb3cupcorrectchoice == "L" & threecupleftchoice == TRUE) | 
                                                                          (is.na(cvchickcorrectchoice) & is.na(pctbgridcorrectchoice) & pctb3cupcorrectchoice == "M" & threecupmidchoice == TRUE) | 
                                                                          (is.na(cvchickcorrectchoice) & is.na(pctbgridcorrectchoice) & pctb3cupcorrectchoice == "R" & threecuprightchoice == TRUE) | 
                                                                          (is.na(cvchickcorrectchoice) & is.na(pctbgridcorrectchoice) & pctb3cupcorrectchoice == "LM" & threecupleftchoice == TRUE & threecupmidchoice == TRUE) | 
                                                                          (is.na(cvchickcorrectchoice) & is.na(pctbgridcorrectchoice) & pctb3cupcorrectchoice == "LR" & threecupleftchoice == TRUE & threecuprightchoice == TRUE) | 
                                                                          (is.na(cvchickcorrectchoice) & is.na(pctbgridcorrectchoice) & pctb3cupcorrectchoice == "MR" & threecupmidchoice == TRUE & threecuprightchoice == TRUE), 1, 0)),
                                          problem_flag = ifelse(episodeEndType == "unknown", "Y", "N"))

final_results <- final_results %>% 
  mutate(agent_tag_seed = paste0(agent_tag, ifelse(is.na(aai_seed) | aai_seed == 9999, "", paste0("_", aai_seed))))

final_results <- final_results %>%
  mutate(agent_type_mem = ifelse(is.na(age) & !str_detect(agent_tag, "dreamer|ppo|Random"), agent_type,
                             ifelse(is.na(age) & str_detect(agent_tag, "dreamer|ppo"), agent_tag, 
                                    ifelse(is.na(age) & str_detect(agent_tag, "Random Action"), "Random Action", 
                                           ifelse(is.na(age) & str_detect(agent_tag, "Random Walker"), "Random Walker", age)))),
         agent_type_mem = haven::as_factor(agent_type_mem),
         agent_type = haven::as_factor(agent_type))

final_results <- final_results %>%
  mutate(agent_order_mem = ifelse(agent_type_mem == "Random Walker", 0,
                                  ifelse(agent_type_mem == "Random Action", 1,
                                         ifelse(agent_type_mem == "Braitenberg", 2, 
                                                ifelse(agent_type == "PPO", 3, 
                                                       ifelse(agent_type == "Dreamer", 4,
                                                              ifelse(agent_type_mem == "4", 5, 
                                                                     ifelse(agent_type_mem == "5", 6,
                                                                            ifelse(agent_type_mem == "6", 7, 8)))))))))
final_results <- final_results %>%
  mutate(agent_type_mem_noage = ifelse(is.na(age), agent_type_mem, "Child"))


###############################################################################################################################
###############################################       Make wide/long Versions     #############################################
###############################################################################################################################


measurement_layout_agent_data <- final_results %>%
  filter(problem_flag == "N",
         agent_type != "child") %>%
  select(c("agent_tag",
           "aai_seed",
           "InstanceName",
           "Suite", 
           "SubSuite", 
           "Paradigm", 
           "Task", 
           "Instance",
           "ColorVariant", 
           "OccluderVariant",
           "basicTask",
           "cvchickTask",
           "pctbTask",
           "pctbGridTask",
           "pctb3CupTask",
           "lavaPresence", 
           "taskCriticalRampPresence", 
           "greenGoalPresence", 
           "yellowGoalPresence",
           "stationaryGreenGoalPresence",
           "stationaryYellowGoalPresence",
           "movingGreenGoalPresence",
           "movingYellowGoalPresence",
           "numGreenGoals",
           "numYellowGoals",
           "numGoalsAll",
           "mainGoalSize",
           "multipleGoalSameSize",
           "frozenAgentPresence",
           "frozenAgentDelayLength",
           "lightsOutPresence",
           "lightsOutAlternatingPresence",
           "lightsOutPeriod",
           "goalBecomesAllocentricallyOccluded",
           "opaqueWallNotPlatformPresence",
           "transparentWallPresence",
           "bluePlatformPresence",
           "decoyPresence",
           "decoySize",
           "numDecoys",
           "numDecoys",
           "goalLeftRelToStart",
           "goalCentreRelToStart",
           "goalRightRelToStart",
           "forcedChoice",
           "opaqueWallRedValue",
           "opaqueWallGreenValue",
           "opaqueWallBlueValue",
           "opaqueWallColourRandomisationPresence",
           "cityBlockDistanceToGoal",
           "minNumTurnsRequired",
           "numChoices",
           "success",
           "correctChoice",
           "numberPreviousInstances",
           "problem_flag")) %>%
  mutate(agent_id = ifelse(is.na(aai_seed), agent_tag, paste0(agent_tag, "_", aai_seed)),
         agent_id = str_replace_all(agent_id, " |-", "_")
         ) %>%
  select(!c(agent_tag, aai_seed)) %>%
  pivot_wider(names_from = agent_id,
              values_from = c(success, correctChoice))

na_func <- function(x) {
  is.na(x)
}

check <- measurement_layout_agent_data %>%
  select(c(InstanceName, success_Random_Walker_Fixed_Forwards_Saccade_15_Angle_10_356:correctChoice_ppo_bc_all_2023)) %>%
  filter(if_any(success_Random_Walker_Fixed_Forwards_Saccade_15_Angle_10_356:correctChoice_ppo_bc_all_2023, na_func))


measurement_layout_children_data <- final_results %>%
  filter(problem_flag == "N",
         agent_type == "child") %>%
  select(c("agent_tag",
           "InstanceName",
           "instancename_child",
           "Suite", 
           "SubSuite", 
           "Paradigm", 
           "Task", 
           "Instance",
           "ColorVariant", 
           "OccluderVariant",
           "basicTask",
           "cvchickTask",
           "pctbTask",
           "pctbGridTask",
           "pctb3CupTask",
           "lavaPresence", 
           "taskCriticalRampPresence", 
           "greenGoalPresence", 
           "yellowGoalPresence",
           "stationaryGreenGoalPresence",
           "stationaryYellowGoalPresence",
           "movingGreenGoalPresence",
           "movingYellowGoalPresence",
           "numGreenGoals",
           "numYellowGoals",
           "numGoalsAll",
           "mainGoalSize",
           "multipleGoalSameSize",
           "frozenAgentPresence",
           "frozenAgentDelayLength",
           "lightsOutPresence",
           "lightsOutAlternatingPresence",
           "lightsOutPeriod",
           "goalBecomesAllocentricallyOccluded",
           "opaqueWallNotPlatformPresence",
           "transparentWallPresence",
           "bluePlatformPresence",
           "decoyPresence",
           "decoySize",
           "numDecoys",
           "numDecoys",
           "goalLeftRelToStart",
           "goalCentreRelToStart",
           "goalRightRelToStart",
           "forcedChoice",
           "opaqueWallRedValue",
           "opaqueWallGreenValue",
           "opaqueWallBlueValue",
           "opaqueWallColourRandomisationPresence",
           "cityBlockDistanceToGoal",
           "minNumTurnsRequired",
           "numChoices",
           "success",
           "correctChoice",
           "numberPreviousInstances",
           "problem_flag")) %>%
  mutate(instance_id = ifelse(is.na(instancename_child), InstanceName, instancename_child)
  ) %>%
  select(!InstanceName & !instancename_child) 



###############################################################################################################################
###############################################          Final Data Save          #############################################
###############################################################################################################################


write.csv(final_results, "analysis/results_final_clean_long.csv", row.names = FALSE)

write.csv(measurement_layout_agent_data, "analysis/measurement-layouts/results_final_clean_agents_wide.csv", row.names = FALSE)

write.csv(measurement_layout_children_data, "analysis/measurement-layouts/results_final_clean_children_wide.csv", row.names = FALSE)












###############################################################################################################################
#####################################         Rerun Instances If Errors Suspected          ####################################
###############################################################################################################################


## Not Run

## For the agents in checking_dataframe that aren't children, they need to be rerun.

# database_connection <- read.csv("agents/scripts/databaseConnectionDetails.csv")
# db_name <- database_connection$database_name[1]
# db_user <- database_connection$username[1]
# db_pw <- database_connection$password[1]
# db_host <- database_connection$hostname
# db_port <- 3306
# 
# ## Database Connection
# 
# drv <- MariaDB()
# myDB <- dbConnect(drv,
#                   user = db_user,
#                   password = db_pw,
#                   dbname = db_name,
#                   host = db_host,
#                   port = db_port)
# 
# 
# checking_dataframe_agents <- checking_dataframe %>% filter(agent_type != "child")
# 
# for (row in 1:nrow(checking_dataframe_agents)){
# #for (row in 1:1){
#   print(row)
#   agentname <- checking_dataframe_agents$agent_tag[row]
#   seed <- checking_dataframe_agents$aai_seed[row]
#   instancename <- checking_dataframe_agents$InstanceName[row]
# 
#   if (str_detect(agentname, "Random Walker")){
#     agent_table_name <- "randomwalkers"
#     agent_results_table_name <- "randomwalkerinstanceresults"
#     agent_intraresults_table_name <- "randomwalkerintrainstanceresults"
#   } else if (str_detect(agentname, "Random Action Agent")) {
#     agent_table_name <- "randomactionagents"
#     agent_results_table_name <- "randomactionagentinstanceresults"
#     agent_intraresults_table_name <- "randomactionagentintrainstanceresults"
#   } else if (str_detect(agentname, "Vanilla Braitenberg")){
#     agent_table_name <- "vbraitenbergvehicles"
#     agent_results_table_name <- "vbraitenbergvehicleinstanceresults"
#     agent_intraresults_table_name <- "vbraitenbergvehicleintrainstanceresults"
#   } else {
#     stop("Agent not recognised.")
#   }
# 
#   instanceid_query <- paste0("SELECT instanceid FROM instances WHERE instancename = '", instancename, "';")
#   instanceid <- dbGetQuery(myDB, instanceid_query)
# 
#   if (nrow(instanceid) != 1){
#     stop("Multiple instanceids selected.")
#   } else {
#     instanceid <- instanceid$instanceid[1]
#   }
# 
#   agentid_query <- paste0("SELECT agentid FROM ", agent_table_name, " WHERE agent_tag = '", agentname, "' AND aai_seed = ", seed, ";")
#   agentid <- dbGetQuery(myDB, agentid_query)
# 
#   if (nrow(agentid) != 1){
#     stop("Multiple agentids selected.")
#   } else {
#     agentid <- agentid$agentid[1]
#   }
# 
#   delete_main_query <- paste0("DELETE FROM ", agent_results_table_name, " WHERE agentid = ", agentid, " AND instanceid = ", instanceid, ";")
# 
#   main_rows_affected <- dbExecute(myDB, delete_main_query)
#   cat("Deleted", main_rows_affected, "from", agent_results_table_name, ".\n")
# 
#   delete_intra_query <- paste0("DELETE FROM ", agent_intraresults_table_name, " WHERE agentid = ", agentid, " AND instanceid = ", instanceid, ";")
# 
#   intra_rows_affected <- dbExecute(myDB, delete_intra_query)
#   cat("Deleted", intra_rows_affected, "from", agent_intraresults_table_name, ".\n")
# }
# 
# #2023-08-10 - 1478 inconsistent results deleted.
# #2023-08-14 - 2 inconsistent results deleted.
# 
# dbDisconnect(myDB)
