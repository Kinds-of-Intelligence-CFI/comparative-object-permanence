from stable_baselines3 import PPO
from stable_baselines3 import DQN
import torch as th
import sys
import random
import os
from mlagents_envs.envs.unity_gym_env import UnityToGymWrapper
from animalai.envs.environment import AnimalAIEnvironment

config = {
    "curriculum": r"OP-Controls-RandBasic-SanityGreen-RND-RND-NA-RND-NA.yml",
    "policy_type": "CnnPolicy",
    "total_timesteps": 10000000,
    "learning_rate": 0.0006,
    "activation_fn": "relu",
}

def train_agent_single_config():

    aai_env = AnimalAIEnvironment(
        seed = 123,
        file_name=r"../env/AAI_v3.1.0.app",
        arenas_configurations=config["curriculum"],
        play=False,
        base_port=5006,
        inference=False,
        useCamera=True,
        resolution=72,
        useRayCasts=False,
        # raysPerSide=1,
        # rayMaxDegrees = 30,
    )

    env = UnityToGymWrapper(aai_env, uint8_visual=True, allow_multiple_obs=False, flatten_branched=True)
    if config['activation_fn'] == 'relu':
        policy_kwargs = dict(activation_fn = th.nn.ReLU)
    elif config['activation_fn'] == 'tanh':
        policy_kwargs = dict(activation_fn = th.nn.Tanh)
    
    model = PPO(config["policy_type"],
                env,
                learning_rate=config["learning_rate"],
                policy_kwargs=policy_kwargs,
                verbose=1,
                tensorboard_log=f"runs/ppo-clean")
    model.learn(total_timesteps=config["total_timesteps"])

if __name__ == "__main__":
    train_agent_single_config()