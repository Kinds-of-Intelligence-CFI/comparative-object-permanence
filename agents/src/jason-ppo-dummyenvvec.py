from stable_baselines3 import PPO
from stable_baselines3 import DQN
from stable_baselines3.common.monitor import Monitor
from stable_baselines3.common.vec_env import DummyVecEnv
import torch as th
import wandb
from wandb.integration.sb3 import WandbCallback
from mlagents_envs.envs.unity_gym_env import UnityToGymWrapper
from animalai.envs.environment import AnimalAIEnvironment
import random
import datetime

config = {
    'batch_size': 128,
    'activation_fn': 'relu',
    'gamma': 0.9754,
    'policy_type': 'CnnPolicy',
    'total_timesteps': 4000000,
    'vf_coef': 0.3771,
    'clip_range': 0.2047,
    'learning_rate': 0.0001067,
    'ent_coef': 0.01
}

run = wandb.init(project="animalai-remote-experiments", name="parallelised", config=config, sync_tensorboard=True, save_code=True)

def make_env(worker_id):

    def _init():

        aai_env = AnimalAIEnvironment(
        seed = random.randint(1,300),
        file_name=r"../env/AAI_v3.0.2.app",
        arenas_configurations=r"OP-Controls-RandBasic-SanityGreen-RND-RND-NA-RND-NA.yml",
        play=False,
        base_port=5000+worker_id,
        worker_id=worker_id,
        inference=False,
        useCamera=True,
        resolution=72,
        useRayCasts=False,
        # raysPerSide=1,
        # rayMaxDegrees = 30,
    )
        env = UnityToGymWrapper(aai_env, uint8_visual=True, allow_multiple_obs=False, flatten_branched=True)
        env = Monitor(env)
        return env

    return _init

env = DummyVecEnv([make_env(worker_id) for worker_id in range(1,6)])

if config['activation_fn'] == 'relu':
    policy_kwargs = dict(activation_fn = th.nn.ReLU)
elif config['activation_fn'] == 'tanh':
    policy_kwargs = dict(activation_fn = th.nn.Tanh)

model = PPO(policy=config["policy_type"],
            env=env,
            vf_coef=config["vf_coef"],
            clip_range=config["clip_range"],
            learning_rate=config["learning_rate"],
            ent_coef=config["ent_coef"],
            batch_size=config["batch_size"],
            gamma=config["gamma"],
            policy_kwargs=policy_kwargs,
            verbose=1,
            tensorboard_log=f"runs/{run.id}")
            
model.learn(total_timesteps=config["total_timesteps"], callback=WandbCallback(gradient_save_freq=100000, model_save_path=f"models/{run.id}/{datetime.datetime.now().strftime('%Y-%m-%d-%H-%M-%S')}", model_save_freq=100000, verbose=2))

run.finish()