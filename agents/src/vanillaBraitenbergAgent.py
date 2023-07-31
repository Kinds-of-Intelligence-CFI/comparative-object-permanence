"""
Author: M. D. Crosby 2021-2022.
Adapted for current study by: K. Voudouris.
"""
import argparse
import numpy as np
import os
import random

from animalai.envs.actions import AAIActions, AAIAction
from animalai.envs.environment import AnimalAIEnvironment
from animalai.envs.raycastparser import RayCastParser
from animalai.envs.raycastparser import RayCastObjects

class vanillaBraitenberg():
    """Implements a simple Braitenberg vehicle agent that heads towards food
    Can change the number of rays but only responds to GOODGOALs, GOODGOALMULTI and BADGOAL"""
    def __init__(self, no_rays, max_degrees):
        self.no_rays = no_rays
        assert(self.no_rays % 2 == 1), "Only supports odd number of rays (but environment should only allow odd number"
        self.max_degrees = max_degrees
        self.listOfObjects = [RayCastObjects.GOODGOAL, RayCastObjects.GOODGOALMULTI, RayCastObjects.BADGOAL, RayCastObjects.IMMOVABLE, RayCastObjects.MOVABLE, RayCastObjects.ARENA]
        self.raycast_parser = RayCastParser(self.listOfObjects, self.no_rays)
        self.actions = AAIActions()
        self.prev_action = self.actions.FORWARDS

    def prettyPrint(self, obs) -> str:
        """Prints the parsed observation"""
        return self.raycast_parser.prettyPrint(obs)
    
    def checkStationarity(self, vel_observations):
        bool_array = (vel_observations <= np.array([1,1,1]))
        if sum(bool_array) == 3:
            return True
        else:
            return False
    
    def get_action(self, observations) -> AAIAction:
        """Returns the action to take given the current parsed raycast observation and other observations"""
        obs = observations["rays"]

        obs = self.raycast_parser.parse(obs)

        velocities = observations["velocity"]

        newAction = self.actions.FORWARDS #initialise the new action to be no action

        if self.checkStationarity(velocities) and self.prev_action != self.actions.FORWARDSLEFT and self.prev_action != self.actions.FORWARDSRIGHT:
            select_LR = random.randint(0,1)
            if select_LR == 0:
                newAction = self.actions.FORWARDSLEFT
            else:
                newAction = self.actions.FORWARDSRIGHT
        elif self.checkStationarity(velocities) and self.prev_action == self.actions.FORWARDSLEFT:
            newAction = self.actions.FORWARDSLEFT
        elif self.checkStationarity(velocities) and self.prev_action == self.actions.FORWARDSRIGHT:
            newAction = self.actions.FORWARDSRIGHT
        elif self.ahead(obs, RayCastObjects.GOODGOALMULTI) and not self.checkStationarity(velocities):
            newAction = self.actions.FORWARDS
        elif self.left(obs, RayCastObjects.GOODGOALMULTI) and not self.checkStationarity(velocities):
            newAction = self.actions.LEFT
        elif self.right(obs, RayCastObjects.GOODGOALMULTI) and not self.checkStationarity(velocities):
            newAction = self.actions.RIGHT
        elif self.ahead(obs, RayCastObjects.GOODGOAL) and not self.checkStationarity(velocities):
            newAction = self.actions.FORWARDS
        elif self.left(obs, RayCastObjects.GOODGOAL) and not self.checkStationarity(velocities):
            newAction = self.actions.LEFT
        elif self.right(obs, RayCastObjects.GOODGOAL) and not self.checkStationarity(velocities):
            newAction = self.actions.RIGHT
        elif self.ahead(obs, RayCastObjects.BADGOAL) and not self.checkStationarity(velocities):
            newAction = self.actions.BACKWARDS
        elif self.left(obs, RayCastObjects.BADGOAL) and not self.checkStationarity(velocities):
            newAction = self.actions.RIGHT
        elif self.right(obs, RayCastObjects.BADGOAL) and not self.checkStationarity(velocities):
            newAction = self.actions.LEFT
        elif self.ahead(obs, RayCastObjects.IMMOVABLE) and not self.checkStationarity(velocities):
            select_LR = random.randint(0,1)
            if select_LR == 0:
                newAction = self.actions.FORWARDSLEFT
            else:
                newAction = self.actions.FORWARDSRIGHT
        elif ((self.ahead(obs, RayCastObjects.IMMOVABLE) and self.prev_action == self.actions.FORWARDSLEFT) or (self.left(obs, RayCastObjects.IMMOVABLE) and not self.ahead(obs, RayCastObjects.IMMOVABLE))) and not self.checkStationarity(velocities):
            newAction = self.actions.FORWARDSLEFT
        elif ((self.ahead(obs, RayCastObjects.IMMOVABLE) and self.prev_action == self.actions.FORWARDSRIGHT) or (self.right(obs, RayCastObjects.IMMOVABLE) and not self.ahead(obs, RayCastObjects.IMMOVABLE))) and not self.checkStationarity(velocities):
            newAction = self.actions.FORWARDSRIGHT
        else:
            newAction = self.prev_action        
        self.prev_action = newAction
        
        return newAction

    def ahead(self, obs, object):
        """Returns true if the input object is ahead of the agent"""
        if(obs[self.listOfObjects.index(object)][int((self.no_rays-1)/2)] > 0):
            #print("found " + str(object) + " ahead")
            return True
        return False

    def left(self, obs, object):
        """Returns true if the input object is left of the agent"""
        for i in range(int((self.no_rays-1)/2)):
            if(obs[self.listOfObjects.index(object)][i] > 0):
                #print("found " + str(object) + " left")
                return True
        return False

    def right(self, obs, object):
        """Returns true if the input object is right of the agent"""
        for i in range(int((self.no_rays-1)/2)):
            if(obs[self.listOfObjects.index(object)][i+int((self.no_rays-1)/2) + 1] > 0):
                #print("found " + str(object) + " right")
                return True
        return False



def watch_vanilla_braitenberg_agent_single_config(configuration_file: str, agent: vanillaBraitenberg):
    
    port = 4000 + random.randint(
        0, 1000
        )  # use a random port to avoid problems if a previous version exits slowly
    
    aai_env = AnimalAIEnvironment( 
    inference=True, #Set true when watching the agent
    seed = 123,
    worker_id=random.randint(0, 65500),
    file_name="../../env/AnimalAI",
    arenas_configurations=configuration_file,
    base_port=port,
    useCamera=False,
    useRayCasts=True,
    raysPerSide = int((agent.no_rays)/2),
    rayMaxDegrees = agent.max_degrees
    )

    behavior = list(aai_env.behavior_specs.keys())[0] # by default should be AnimalAI?team=0

    done = False
    episodeReward = 0

    aai_env.step() # take first step to get an observation

    dec, term = aai_env.get_steps(behavior)
 
    while not done:

        observations = aai_env.get_obs_dict(dec.obs)


        #raycasts = observations["rays"] # Get the raycast data

        action = agent.get_action(observations)

        #print(action)

        aai_env.set_actions(behavior, action.action_tuple)

        aai_env.step()

        dec, term = aai_env.get_steps(behavior)
        
        if len(dec.reward) > 0 and len(term) <= 0:
            episodeReward += dec.reward

        elif len(term) > 0: #Episode is over
            episodeReward += term.reward
            print(f"Episode Reward: {episodeReward}")
            done = True
        
        else:
            pass

    aai_env.close()

        
    
        




if __name__ == "__main__":

    parser = argparse.ArgumentParser()

    parser.add_argument("--config_file", 
                        type=str, 
                        help="What config file should be run? Defaults to a random file from the competition folder.")
    
    parser.add_argument("--no_rays", 
                        type=int, 
                        help="How many rays should the raycaster produce? Must be an odd number. Defaults to 11.",
                        default = 11)
    parser.add_argument("--max_degrees", 
                        type=int, 
                        help = "Over how many degrees ought the raycasts be distributed? Defaults to 60.",
                        default = 60)
    
    args = parser.parse_args()

    no_rays = args.no_rays 
    max_degrees = args.max_degrees

    if args.config_file is not None:
        configuration_file = args.config_file
    else:
        config_folder = "../../configs/tests_agents/op_tests/"
        configuration_files = os.listdir(config_folder)
        configuration_random = random.randint(0, len(configuration_files))
        configuration_file = config_folder + configuration_files[configuration_random]
        print(f"Using configuration file {configuration_file}")

    singleEpisodeVanillaBraitenberg = vanillaBraitenberg(no_rays=no_rays,
                                             max_degrees=max_degrees)
    
    watch_vanilla_braitenberg_agent_single_config(configuration_file=configuration_file, agent = singleEpisodeVanillaBraitenberg)