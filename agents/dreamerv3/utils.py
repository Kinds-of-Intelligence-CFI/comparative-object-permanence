from pathlib import Path
from typing import Any

import dreamerv3.embodied as embodied


class StepwiseCSVLogger(embodied.BatchEnv):
    """
    Logs the environment after every step to a CSV file.

    <https://stackoverflow.com/questions/1443129/completely-wrap-an-object-in-python>
    """

    def __init__(
        self, env: embodied.BatchEnv, logdir: Path, episode: int = 1, step: int = 1
    ):
        self.__env = env
        self.__logdir = logdir / "episodes"
        self.__logdir.mkdir(parents=True, exist_ok=False)

        self.__episode = episode
        self.__stepnum = step

        self.__open_episode_log()

    def __getattr__(self, __name) -> Any:
        return getattr(self.__env, __name)

    def __open_episode_log(self):
        path = self.__logdir / f"episode_{self.__episode}.csv"
        path.touch()
        self.__csv_file = path.open("w")
        self.__csv_file.write(
            "episode, step, reward, done, health, vx, vy, vz, px, py, pz\n"
        )

    def step(self, action):
        step_result = self.__env.step(
            action
        )  # We still need to unwrap the BatchEnv output
        extra = step_result["extra"][0]  # This is the info we care about
        reward = step_result["reward"][0]
        done = step_result["is_last"][0]

        log_extra = ", ".join([str(x) for x in extra])
        self.__csv_file.write(
            f"{self.__episode}, {self.__stepnum}, {reward}, {done}, {log_extra}\n"
        )

        self.__stepnum += 1
        if done:
            self.__episode += 1
            self.__open_episode_log()

        return step_result

    def close(self):
        self.__csv_file.close()
        return self.__env.close()
