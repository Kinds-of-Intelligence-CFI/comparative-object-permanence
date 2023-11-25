import random
import logging
from pathlib import Path
from typing import Any

import gym
import dreamerv3.embodied as embodied

from mlagents_envs.envs.unity_gym_env import UnityToGymWrapper  # noqa: E402
from animalai.envs.environment import AnimalAIEnvironment  # noqa: E402

class AAItoDreamerObservationWrapper(gym.ObservationWrapper):  # type: ignore
    """
    Go from a tuple to dict observation space,
    and split the raycast and extra (health, velocity, position) observations.

    <https://www.gymlibrary.dev/api/wrappers/#observationwrapper>
    """

    def __init__(self, env: gym.Env):
        super().__init__(env)
        tuple_obs_space: gym.spaces.Tuple = self.observation_space  # type: ignore

        # RGB image (dimensions might vary)
        image = tuple_obs_space[0]

        # Raycasts in a 1D array of 20 entries.
        mixed: gym.spaces.Box = tuple_obs_space[1]  # type: ignore # Raycast + extra together
        raycast_size = mixed.shape[0] - 7
        raycast = gym.spaces.Box(float("-inf"), float("+inf"), shape=(raycast_size,), dtype=float)  # fmt: skip

        # Health, velocity (x, y, z), and global position (x, y, z) in a 1D array of 7 entries.
        extra = gym.spaces.Box(float("-inf"), float("+inf"), shape=(7,), dtype=float)

        self.observation_space = gym.spaces.Dict(
            {"image": image, "raycast": raycast, "extra": extra}
        )

    def observation(self, observation):
        image, mix = observation
        extra = mix[-7:]
        raycast = mix[:-7]
        return {"image": image, "extra": extra, "raycast": raycast}

class StepwiseCSVLogger(embodied.BatchEnv):
    """
    Logs the environment after every step to a CSV file.

    <https://stackoverflow.com/questions/1443129/completely-wrap-an-object-in-python>
    """

    def __init__(
        self, env: embodied.BatchEnv, logdir: Path
    ):
        self.__env = env
        self.__logdir = logdir / "episodes"
        self.__logdir.mkdir(parents=True, exist_ok=False)

        self.__episode = 1
        self.__stepnum = 1
        self.__cum_reward = 0

        self.__open_episode_log()

    def __getattr__(self, __name) -> Any:
        return getattr(self.__env, __name)

    def __open_episode_log(self):
        path = self.__logdir / f"episode_{self.__episode}.csv"
        path.touch()
        self.__csv_file = path.open("w")
        self.__csv_file.write(
            "episode, step, reward, cumulative reward, done, health, vx, vy, vz, px, py, pz\n"
        )

    def step(self, action):
        step_result = self.__env.step(
            action
        )  # We still need to unwrap the BatchEnv output
        extra = step_result["extra"][0]  # This is the info we care about
        reward = step_result["reward"][0]
        done = step_result["is_last"][0]
        self.__cum_reward += reward

        log_extra = ", ".join([str(x) for x in extra])
        self.__csv_file.write(
            f"{self.__episode}, {self.__stepnum}, {reward}, {self.__cum_reward}, {done}, {log_extra}\n"
        )

        self.__stepnum += 1
        if done:
            self.__cum_reward = 0
            self.__stepnum = 1
            self.__episode += 1
            self.__csv_file.close()
            self.__open_episode_log()

        return step_result

    def close(self):
        self.__csv_file.close()
        return self.__env.close()

class MultiAAIEnv(gym.Env):
    def __init__(self, tasks: list[Path], env_path: Path) -> None:
        self.env_path = env_path
        self.tasks = tasks
        self.port = 5005 + random.randint(0, 1000)
        self.current_task_idx = 0
        self.current_env = self.__initialize(self.current_task_idx)
        super().__init__()

    def step(self, action):
        step_result = self.current_env.step(action)
        done = step_result[2] # It's (observation, reward, terminated, truncated, info) after EnvCompatibility.
        if done:
            self.current_task_idx = (self.current_task_idx + 1) % len(self.tasks)
            self.current_env.close()
            self.current_env = self.__initialize(self.current_task_idx)
        return step_result

    def reset(self, *args, **kwargs):
        return self.current_env.reset(*args, **kwargs)

    def render(self, *args, **kwargs):
        return self.current_env.render(*args, **kwargs)

    def close(self):
        return self.current_env.close()

    def __initialize(self, task_idx: int) -> gym.Env:
        task_path = self.tasks[task_idx]
        assert task_path.exists(), f"Task file not found: {task_path}."
        logging.info(f"Initializing AAI environment for task {task_path}")
        logging.info(f"Using port {self.port}")
        aai_env = AnimalAIEnvironment(
            file_name=str(self.env_path),
            arenas_configurations=str(task_path),
            base_port=self.port,
            # worker_id=(task_idx % 2),
            # Set pixels to 64x64 cause it has to be power of 2 for dreamerv3
            resolution=64,  # same size as Minecraft in DreamerV3
            useCamera=True,
            useRayCasts=True,
            no_graphics=False,  # Without graphics we get gray only observations.
        )
        logging.debug("Wrapping AAI environment")
        env = UnityToGymWrapper(
            aai_env,
            uint8_visual=True,
            allow_multiple_obs=True,
            flatten_branched=True,  # Necessary. Dreamerv3 doesn't support MultiDiscrete action space.
        )
        logging.debug("EnvCompatibility")
        env = gym.wrappers.compatibility.EnvCompatibility(env, render_mode="rgb_array")  # type: ignore
        return env

    @property
    def observation_space(self):
        return self.current_env.observation_space

    @property
    def action_space(self):
        return self.current_env.action_space

    @property
    def render_mode(self):
        return self.current_env.render_mode