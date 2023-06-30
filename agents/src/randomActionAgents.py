"""
Copyright © 2023 Konstantinos Voudouris (@kozzy97)

Author: Konstantinos Voudouris
Date: June 2023
Python Version: 3.10.4
Animal-AI Version: 3.0.2

"""


import numpy as np
import random
import warnings

from collections import deque
from scipy.special import softmax

### Random Action Agent + load config and watch.

"""
Random action class for the animal-ai environment
"""

class RandomActionAgent:
    """Implements a random walker with many changeable parameters"""

    def __init__(self, max_step_length = 10, step_length_distribution = 'fixed', norm_mu = 5, norm_sig = 1, beta_alpha = 2, beta_beta = 2, cauchy_mode = 5, gamma_kappa = 9, gamma_theta = 0.5, weibull_alpha = 2, poisson_lambda = 5, action_biases = [1,1,1,1,1,1,1,1,1], prev_step_bias = 0, remove_prev_step = False):
        self.max_step_length = max_step_length 
        self.step_length_distribution = step_length_distribution
        self.norm_mu = norm_mu
        self.norm_sig = norm_sig
        self.beta_alpha = beta_alpha
        self.beta_beta = beta_beta
        self.cauchy_mode = cauchy_mode
        self.gamma_kappa = gamma_kappa
        self.gamma_theta = gamma_theta
        self.weibull_alpha = weibull_alpha
        self.poisson_lambda = poisson_lambda
        self.action_biases = action_biases
        self.prev_step_bias = prev_step_bias
        self.remove_prev_step = remove_prev_step

    def get_num_steps(self, prev_step: int):
        
        if self.step_length_distribution == 'fixed':
            num_steps = self.max_step_length
        
        elif self.step_length_distribution == 'uniform': 
            num_steps = random.randint(0, self.max_step_length)

        elif self.step_length_distribution == 'normal':
            num_steps = -1
            while num_steps <= 0: # to make sure that num_steps is always a natural number
                num_steps = int(np.random.normal(self.norm_mu, self.norm_sig))

        elif self.step_length_distribution == 'beta':
            num_steps = int(np.random.beta(self.beta_alpha, self.beta_beta) * self.max_step_length) #rescale it to be bounded by 0 and max_step_length rather than by 0 and 1

        elif self.step_length_distribution == 'cauchy':
            num_steps = -1
            while num_steps < 0:
                num_steps = int(np.random.standard_cauchy() + self.cauchy_mode)
        
        elif self.step_length_distribution == 'gamma':
            num_steps = -1
            while num_steps < 0:
                num_steps = int(np.random.gamma(self.gamma_kappa, self.gamma_theta))
        
        elif self.step_length_distribution == 'weibull':
            num_steps = int(np.random.weibull(self.weibull_alpha) * self.max_step_length) #rescale it to be bounded by 0 and max_step_length rather than by 0 and 1
        
        elif self.step_length_distribution == 'poisson':
            num_steps = int(np.random.poisson(self.poisson_lambda))
        
        else:
            raise ValueError("Distribution not recognised.")

        if num_steps > 100:
            warning_string = 'The number of steps chosen is: ' + str(num_steps) + '. Try toggling distribution parameters as your agent might get stuck.'
            warnings.warn(warning_string)

        
        step_list = deque([prev_step]*num_steps)
        return step_list

    def get_new_action(self, prev_step: int):

        """
        Provide a vector of 9 real values, one for each action, which is then softmaxed to provide the probability of selecting that action. Relative differences between the values is what is important. 

        Provide an initial probability of selecting the previous step again. If that action is not selected, then the next step is picked according to the softmaxed action biases. The previous action can be removed
        from the softmaxed biases (by continually sampling until an action is picked that is not the previous action), by changing `remove_prev_step` to `True`.
        """

        assert(len(self.action_biases) == 9), "You must provide biases for all nine (9) actions. A uniform distribution is [1,1,1,1,1,1,1,1,1]"

        assert(self.prev_step_bias >= 0 and self.prev_step_bias <= 1), "The bias towards the previous action must be a scalar value between 0 and 1."

        
        action_is_prev_step = np.random.choice(a = [False,True], size = 1, p = [(1-self.prev_step_bias), self.prev_step_bias]) # should the action be the previous step?

        if action_is_prev_step:
            action = prev_step
        else:
            if self.remove_prev_step:
                action_biases_softmax = softmax(self.action_biases)
                action = prev_step
                while action == prev_step:
                    action = np.random.choice(a = [0,1,2,3,4,5,6,7,8], size = 1, p = action_biases_softmax)
            else:
                action_biases_softmax = softmax(self.action_biases)
                action = np.random.choice(a = [0,1,2,3,4,5,6,7,8], size = 1, p = action_biases_softmax)
        
        action = int(action)

        return action