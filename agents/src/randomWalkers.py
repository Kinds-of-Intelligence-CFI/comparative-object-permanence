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


"""
Random walker class for the animal-ai environment
"""

class RandomWalker:
    """Implements a random walker with many changeable parameters.
    The key idea is that a certain number of steps is selected (saccade length), the agent goes forwards for that many steps if positive and backwards if negative, and then
    picks a number of steps (angle) to turn for. 
    If the number of steps is negative, they turn left, if positive, they turn right.
    """

    def __init__(self, 
                 max_saccade_length = 10, 
                 max_angle_steps = 5,
                 saccade_distribution = 'fixed', 
                 angle_distribution = 'fixed',
                 saccade_norm_mu = 5, 
                 saccade_norm_sig = 1, 
                 saccade_beta_alpha = 2, 
                 saccade_beta_beta = 2, 
                 saccade_cauchy_mode = 5, 
                 saccade_gamma_kappa = 9, 
                 saccade_gamma_theta = 0.5, 
                 saccade_weibull_alpha = 2, 
                 saccade_poisson_lambda = 5, 
                 angle_fixed_randomise_turn = True,
                 angle_norm_mu = 5,
                 angle_norm_sig = 1,
                 angle_beta_alpha = 2,
                 angle_beta_beta = 2, 
                 angle_cauchy_mode = 5,
                 angle_gamma_kappa = 9,
                 angle_gamma_theta = 0.5,
                 angle_weibull_alpha = 2,
                 angle_poisson_lambda = 5,
                 angle_correlation = 0,
                 backwards_action = False
                 ):
        self.max_saccade_length = max_saccade_length 
        self.max_angle_steps = max_angle_steps
        self.saccade_distribution = saccade_distribution
        self.angle_distribution = angle_distribution
        self.saccade_norm_mu = saccade_norm_mu
        self.saccade_norm_sig = saccade_norm_sig
        self.saccade_beta_alpha = saccade_beta_alpha
        self.saccade_beta_beta = saccade_beta_beta
        self.saccade_cauchy_mode = saccade_cauchy_mode
        self.saccade_gamma_kappa = saccade_gamma_kappa
        self.saccade_gamma_theta = saccade_gamma_theta
        self.saccade_weibull_alpha = saccade_weibull_alpha
        self.saccade_poisson_lambda = saccade_poisson_lambda
        self.angle_fixed_randomise_turn  = angle_fixed_randomise_turn
        self.angle_norm_mu = angle_norm_mu
        self.angle_norm_sig = angle_norm_sig
        self.angle_beta_alpha = angle_beta_alpha
        self.angle_beta_beta = angle_beta_beta 
        self.angle_cauchy_mode = angle_cauchy_mode
        self.angle_gamma_kappa = angle_gamma_kappa
        self.angle_gamma_theta = angle_gamma_theta
        self.angle_weibull_alpha = angle_weibull_alpha
        self.angle_poisson_lambda = angle_poisson_lambda
        self.angle_correlation = angle_correlation
        self.backwards_action = backwards_action

    def get_num_steps_saccade(self):
        
        if self.saccade_distribution == 'fixed':
            num_steps = int(self.max_saccade_length)

        # The while statements remove the possibility of a 0, so that choices between negative and positive are not biased.
           
        elif self.saccade_distribution == 'uniform': 
            num_steps = 0

            while num_steps == 0:
                num_steps = random.randint(0, self.max_saccade_length)

        elif self.saccade_distribution == 'normal':
            num_steps = 0

            while num_steps == 0:
                num_steps = int(np.random.normal(self.saccade_norm_mu, self.saccade_norm_sig))

        elif self.saccade_distribution == 'beta':
            num_steps = 0

            while num_steps == 0:
                num_steps = int(np.random.beta(self.saccade_beta_alpha, self.saccade_beta_beta) * self.max_saccade_length) #rescale it to be bounded by 0 and max_step_length rather than by 0 and 1

        elif self.saccade_distribution == 'cauchy':
            num_steps = 0

            while num_steps == 0:
                num_steps = int(np.random.standard_cauchy() + self.saccade_cauchy_mode)
        
        elif self.saccade_distribution == 'gamma':
            num_steps = 0

            while num_steps == 0:
                num_steps = int(np.random.gamma(self.saccade_gamma_kappa, self.saccade_gamma_theta))
        
        elif self.saccade_distribution == 'weibull':
            num_steps = 0

            while num_steps == 0:
                num_steps = int(np.random.weibull(self.saccade_weibull_alpha) * self.max_saccade_length) #rescale it to be bounded by 0 and max_step_length rather than by 0 and 1
        
        elif self.saccade_distribution == 'poisson':
            num_steps = 0

            while num_steps == 0:
                num_steps = int(np.random.poisson(self.saccade_poisson_lambda))
        
        else:
            raise ValueError("Distribution not recognised.")

        if num_steps > 100:
            warning_string = 'The number of steps chosen is: ' + str(num_steps) + '. Try toggling distribution parameters as your agent might get stuck.'
            warnings.warn(warning_string)

        if self.backwards_action:
            num_steps = abs(num_steps) #make num_steps a positive number so it only goes forwards.

        if num_steps > 0: #Move forwards
            step_list = deque([3,0]*abs(num_steps)) # add in a stationary movement to reduce effect of momentum on next step.

            if (num_steps % 2) == 1:
                step_list.append(0)
        
        elif num_steps < 0: #Move backwards
            step_list = deque([6,0]*abs(num_steps))
            if (num_steps % 2) == 1:
                step_list.append(0)

        else:
            raise ValueError("Saccade length is 0. Try increasing max_saccade_length.")
        
        return step_list
    
    def get_num_steps_turn(self, prev_angle_central_moment):
        
        if self.angle_distribution == 'fixed':
            if self.angle_fixed_randomise_turn:
                right = bool(random.getrandbits(1))
                if right:
                    num_steps = int(self.max_angle_steps)
                else:
                    num_steps = int(self.max_angle_steps * -1)
            else:
                num_steps = self.max_angle_steps
        
        elif self.angle_distribution == 'uniform': 
            num_steps = 0

            while num_steps == 0:
                if self.angle_fixed_randomise_turn:
                    right = bool(random.getrandbits(1))
                    if right:
                        num_steps = random.randint(0, self.max_angle_steps)
                    else:
                        num_steps = random.randint(0, (self.max_angle_steps * -1))

        elif self.angle_distribution == 'normal':
            central_moment_difference = prev_angle_central_moment - self.angle_norm_mu 
            central_moment_shift = central_moment_difference * self.angle_correlation

            num_steps = 0

            while num_steps == 0:
                num_steps = int(np.random.normal(central_moment_shift, self.angle_norm_sig))

        elif self.angle_distribution == 'beta':
            num_steps = 0

            while num_steps == 0:
                if self.angle_fixed_randomise_turn:
                    right = bool(random.getrandbits(1))
                    if right:
                        num_steps = int(np.random.beta(self.angle_beta_alpha, self.angle_beta_beta) * self.max_angle_steps) #rescale it to be bounded by 0 and max_step_length rather than by 0 and 1
                    else:
                        num_steps = (int(np.random.beta(self.angle_beta_alpha, self.angle_beta_beta) * self.max_angle_steps) * -1) #rescale it to be bounded by 0 and max_step_length rather than by 0 and 1
                

        elif self.angle_distribution == 'cauchy':
            central_moment_difference = prev_angle_central_moment - self.angle_cauchy_mode 
            central_moment_shift = central_moment_difference * self.angle_correlation

            num_steps = 0

            while num_steps == 0:
                num_steps = int(np.random.standard_cauchy() + central_moment_shift) #affine transform of distribution
        
        elif self.angle_distribution == 'gamma':
            num_steps = 0

            while num_steps == 0:
                if self.angle_fixed_randomise_turn:
                    right = bool(random.getrandbits(1))
                    if right:
                        num_steps = int(np.random.gamma(self.angle_gamma_kappa, self.angle_gamma_theta)) 
                    else:
                        num_steps = (int(np.random.gamma(self.angle_gamma_kappa, self.angle_gamma_theta)) * -1) 
        
        elif self.angle_distribution == 'weibull':
            num_steps = 0

            while num_steps == 0:
                if self.angle_fixed_randomise_turn:
                    right = bool(random.getrandbits(1))
                    if right:
                        num_steps = int(np.random.weibull(self.angle_weibull_alpha)) 
                    else:
                        num_steps = (int(np.random.weibull(self.angle_weibull_alpha)) * -1) 
        
        elif self.angle_distribution == 'poisson':
            num_steps = 0
            
            while num_steps == 0:
                if self.angle_fixed_randomise_turn:
                    right = bool(random.getrandbits(1))
                    if right:
                        num_steps = int(np.random.poisson(self.angle_poisson_lambda)) #
                    else:
                        num_steps = (int(np.random.poisson(self.angle_poisson_lambda)) * -1) 

            while num_steps == 0:
                num_steps = int(np.random.poisson(self.angle_poisson_lambda))
        
        else:
            raise ValueError("Distribution not recognised.")

        if num_steps > 0: #Turn right
            step_list = deque([1]*abs(num_steps))
        
        elif num_steps < 0: #Turn left
            step_list = deque([2]*abs(num_steps))

        else:
            raise ValueError("Angle turn steps is 0. Try increasing max_angle_steps.")
        
        return step_list, num_steps