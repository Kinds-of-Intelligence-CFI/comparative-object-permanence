"""
Author: M. D. Crosby 2021-2022.
Adapted for current study by: K. Voudouris.
"""
import random

from animalai.envs.actions import AAIActions, AAIAction
from animalai.envs.raycastparser import RayCastParser
from animalai.envs.raycastparser import RayCastObjects

class vanillaBraitenberg():
    """Implements a simple Braitenberg vehicle agent that heads towards food
    Can change the number of rays but only responds to GOODGOALs, GOODGOALMULTI and BADGOAL"""
    def __init__(self, no_rays):
        self.no_rays = no_rays
        assert(self.no_rays % 2 == 1), "Only supports odd number of rays (but environment should only allow odd number"
        self.listOfObjects = [RayCastObjects.GOODGOAL, RayCastObjects.GOODGOALMULTI, RayCastObjects.BADGOAL, RayCastObjects.IMMOVABLE, RayCastObjects.MOVABLE]
        self.raycast_parser = RayCastParser(self.listOfObjects, self.no_rays)
        self.actions = AAIActions()
        self.prev_action = self.actions.NOOP

    def prettyPrint(self, obs) -> str:
        """Prints the parsed observation"""
        return self.raycast_parser.prettyPrint(obs)
    
    def get_action(self, obs) -> AAIAction:
        """Returns the action to take given the current parsed raycast observation"""
        obs = self.raycast_parser.parse(obs)

        newAction = self.actions.NOOP #initialise the new action to be no action

        if self.ahead(obs, RayCastObjects.GOODGOALMULTI):
            newAction = self.actions.FORWARDS
        elif self.left(obs, RayCastObjects.GOODGOALMULTI):
            newAction = self.actions.FORWARDSLEFT
        elif self.right(obs, RayCastObjects.GOODGOALMULTI):
            newAction = self.actions.FORWARDSRIGHT
        elif self.ahead(obs, RayCastObjects.GOODGOAL):
            newAction = self.actions.FORWARDS
        elif self.left(obs, RayCastObjects.GOODGOAL):
            newAction = self.actions.FORWARDSLEFT
        elif self.right(obs, RayCastObjects.GOODGOAL):
            newAction = self.actions.FORWARDSRIGHT
        elif self.ahead(obs, RayCastObjects.BADGOAL):
            newAction = self.actions.BACKWARDS
        elif self.left(obs, RayCastObjects.BADGOAL):
            newAction = self.actions.BACKWARDSRIGHT
        elif self.right(obs, RayCastObjects.BADGOAL):
            newAction = self.actions.BACKWARDSLEFT
        else: # if there are no objects in the agents view then:
            # if self.prev_action == self.actions.NOOP: #if the previous action was a no action, then randomly select forwardsleft or forwardsright.
            #     select_left_right = random.getrandbits(1)
            #     if select_left_right == 0:
            #         newAction = self.actions.LEFT
            #     else:
            #         newAction = self.actions.RIGHT
            # elif self.prev_action == self.actions.LEFT: # if the previous action was a forwardsleft, then with a 0.95 probability continue that action, otherwise, go forwardsright. Encourages a bit of exploration.
            #     select_change = random.randint(0,20)
            #     if select_change == 0:
            #         newAction = self.actions.RIGHT
            #     else:
            #         newAction = self.prev_action
            # elif self.prev_action == self.actions.RIGHT: # if the previous action was a forwardsright, then with a 0.95 probability continue that action, otherwise, go forwardsleft. Encourages a bit of exploration.
            #     select_change = random.randint(0,20)
            #     if select_change == 0:
            #         newAction = self.actions.LEFT
            #     else:
            #         newAction = self.prev_action
            # else:
            #    select_change = random.randint(0,20)
            #    if select_change == 0:
            select_random_action = random.randint(0,89) #pick a new random action with a probability of 0.1 (9 actions out of 90 possible integers), otherwise execute the previous action. Encourages exploration.
            if select_random_action == 0:
                newAction = self.actions.NOOP
            elif select_random_action == 1:
                newAction = self.actions.LEFT
            elif select_random_action == 2:
                newAction = self.actions.RIGHT
            elif select_random_action == 3:
                newAction = self.actions.FORWARDS
            elif select_random_action == 4:
                newAction = self.actions.FORWARDSLEFT
            elif select_random_action == 5:
                newAction = self.actions.FORWARDSRIGHT
            elif select_random_action == 6:
                newAction = self.actions.BACKWARDS
            elif select_random_action == 7:
                newAction = self.actions.BACKWARDSLEFT
            elif select_random_action == 8:
                newAction = self.actions.BACKWARDSRIGHT 
            else:
                newAction = self.prev_action
        
        self.prev_action = newAction
        
        return newAction

    def ahead(self, obs, object):
        """Returns true if the input object is ahead of the agent"""
        if(obs[self.listOfObjects.index(object)][int((self.no_rays-1)/2)] > 0):
            # print("found " + str(object) + " ahead")
            return True
        return False

    def left(self, obs, object):
        """Returns true if the input object is left of the agent"""
        for i in range(int((self.no_rays-1)/2)):
            if(obs[self.listOfObjects.index(object)][i] > 0):
                # print("found " + str(object) + " left")
                return True
        return False

    def right(self, obs, object):
        """Returns true if the input object is right of the agent"""
        for i in range(int((self.no_rays-1)/2)):
            if(obs[self.listOfObjects.index(object)][i+int((self.no_rays-1)/2) + 1] > 0):
                # print("found " + str(object) + " right")
                return True
        return False