"""
Copyright © 2023 Konstantinos Voudouris (@kozzy97)

Author: Konstantinos Voudouris
Date: June 2023
Python Version: 3.10.4
Animal-AI Version: 3.0.2

"""

import fnmatch
import os
import random
from pathlib import Path

def find_yaml_files(directory):
    yaml_files = []
    task_names = []
    
    for root, dirnames, filenames in os.walk(directory):
        for filename in fnmatch.filter(filenames, '*.yml') + fnmatch.filter(filenames, '*.yaml'):
            yaml_files.append(os.path.join(root, filename))
            task_names.append(filename)
    
    return yaml_files, task_names

def yaml_combinor(file_list: list, tmp_file_path: Path, shuffle = True):
    """
    Provide a list of paths to instances and the place you want to store the temporary file. You can change the name of the temporary file.
    """
    if shuffle:
        file_list = random.sample(file_list, len(file_list)) # Should be without replacement
    try:
        with open(tmp_file_path, 'w') as output_file:
            output_file.write("!ArenaConfig\narenas:\n")
            for i, file in enumerate(file_list):
                with open(file, 'r') as input_file:
                    lines = input_file.readlines()[2:] #skip the first two lines that contain `!ArenaConfig\narenas:\n`
                    lines[0] = lines[0].replace('0: !Arena', str(i) + ": !Arena").replace('-1: !Arena', str(i) + ": !Arena") #make sure to enumerate the arena objects properly
                    output_file.writelines(lines)
        print(f"Yaml files combined. Saved to {tmp_file_path}")
        return tmp_file_path
    except IOError as e:
        print(e)
        print("An error occurred while combining files.")

def yaml_combine_in_parts(file_list: list, tmp_file_path: Path, n_parts: int = 3, shuffle = True):
    if shuffle:
        file_list = random.sample(file_list, len(file_list)) # Should be without replacement
    parts = partition(file_list, n_parts)
    for i, part in enumerate(parts, 1):
        yaml_combinor(part, tmp_file_path.with_stem(f"{tmp_file_path.stem}_part{i}"), shuffle = shuffle)

# https://stackoverflow.com/questions/2659900/slicing-a-list-into-n-nearly-equal-length-partitions
def partition(lst, n):
    division = len(lst) / n
    return [lst[round(division * i):round(division * (i + 1))] for i in range(n)]


if __name__ == "__main__":
    from pathlib import Path
    import argparse

    parser = argparse.ArgumentParser()
    parser.add_argument('--dir', type=Path, required=True)
    parser.add_argument('--temp-file', type=Path, required=True)
    parser.add_argument('--shuffle', action='store_true')
    parser.add_argument('--seed', type=int, default=1234)
    parser.add_argument('--n-parts', type=int, default=None)
    args = parser.parse_args()

    random.seed(args.seed)
    yaml_files, task_names = find_yaml_files(args.dir)
    if args.n_parts is not None:
        yaml_combine_in_parts(yaml_files, args.temp_file, args.n_parts, args.shuffle)
    else:
        yaml_combinor(yaml_files, args.temp_file, args.shuffle)