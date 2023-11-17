"""
Copyright © 2023 Konstantinos Voudouris (@kozzy97)

Author: Konstantinos Voudouris
Date: June 2023
Python Version: 3.10.4
Animal-AI Version: 3.0.2

"""

import fnmatch
import math
import os
import random
import pandas as pd
from pathlib import Path

def find_yaml_files(directory):
    yaml_files = []
    task_names = []
    
    for root, dirnames, filenames in os.walk(directory):
        for filename in fnmatch.filter(filenames, '*.yml') + fnmatch.filter(filenames, '*.yaml'):
            yaml_files.append(os.path.join(root, filename))
            task_names.append(filename)
    
    return yaml_files, task_names

def find_yaml_files_stratify(directory: Path, stratify = False, num_files: int = 300, curriculum_overview_path: Path = ""):
    yaml_files = []
    task_names = []
    
    for root, dirnames, filenames in os.walk(directory):
        for filename in fnmatch.filter(filenames, '*.yml') + fnmatch.filter(filenames, '*.yaml'):
            yaml_files.append(os.path.join(root, filename))
            task_names.append(filename)
        
    if stratify:
        total_count = len(task_names)
        if total_count < num_files:
            num_files = total_count
        basic_tasks = [file for file in task_names if ('OP-Controls-Basic' in file or 'tutorial' in file) and 'tutorial_6' not in file and 'tutorial_7' not in file] 
        control_cv_tasks = [file for file in task_names if 'OP-RP-Allo-CVChick' in file or 'tutorial_6' in file or 'tutorial_7' in file] 
        control_cup_tasks = [file for file in task_names if 'OP-RP-Allo-PCTB-3Cup' in file] 
        control_grid_tasks = [file for file in task_names if 'OP-RP-Allo-PCTB-12CupGrid' in file or 'OP-RP-Allo-PCTB-8CupGrid' in file or 'OP-RP-Allo-PCTB-4CupGrid' in file]
        op_cv_tasks = [file for file in task_names if 'OP-STC-Allo-CVChick' in file]
        op_cup_tasks = [file for file in task_names if 'OP-STC-Allo-PCTB-3Cup' in file]
        op_grid_tasks = [file for file in task_names if 'OP-STC-Allo-PCTB-12CupGrid' in file or 'OP-STC-Allo-PCTB-8CupGrid' in file or 'OP-STC-Allo-PCTB-4CupGrid' in file]

        basic_tasks_sample = random.sample(basic_tasks, k = math.ceil(num_files * (len(basic_tasks)/total_count)))
        control_cv_tasks_sample = random.sample(control_cv_tasks, k = math.ceil(num_files * (len(control_cv_tasks)/total_count)))
        control_cup_tasks_sample = random.sample(control_cup_tasks, k = math.ceil(num_files * (len(control_cup_tasks)/total_count)))
        control_grid_tasks_sample = random.sample(control_grid_tasks, k = math.ceil(num_files * (len(control_grid_tasks)/total_count)))
        op_cv_tasks_sample = random.sample(op_cv_tasks, k = math.ceil(num_files * (len(op_cv_tasks)/total_count)))
        op_cup_tasks_sample = random.sample(op_cup_tasks, k = math.ceil(num_files * (len(op_cup_tasks)/total_count)))
        op_grid_tasks_sample = random.sample(op_grid_tasks, k = math.ceil(num_files * (len(op_grid_tasks)/total_count)))
        task_names_sample = basic_tasks_sample + control_cv_tasks_sample + control_cup_tasks_sample + control_grid_tasks_sample + op_cv_tasks_sample + op_cup_tasks_sample + op_grid_tasks_sample
        task_names_sample_set = set(task_names_sample) #for faster lookup
        yaml_files_sample = [yaml for yaml in yaml_files if yaml.split("\\")[-1] in task_names_sample_set] #this might be an OS dependent separator?

        if curriculum_overview_path != "":
            task_names_in_curriculum = [1 if name in task_names_sample_set else 0 for name in task_names]
            curriculum_overview = pd.DataFrame(
                {
                    'taskName' : task_names,
                    'inCurriculum' : task_names_in_curriculum
                }
            )
            curriculum_overview.to_csv(curriculum_overview_path)
        return yaml_files_sample, task_names_sample
    else:
        if curriculum_overview_path != "":
            task_names_in_curriculum = [1 for name in task_names]
            curriculum_overview = pd.DataFrame(
                {
                    'taskName' : task_names,
                    'inCurriculum' : task_names_in_curriculum
                }
            )
            curriculum_overview.to_csv(curriculum_overview_path)
        return yaml_files, task_names

def yaml_combinor_shuffle(file_list: list, tmp_file_path: Path, shuffle = True):
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
                    lines[0] = lines[0].replace('0: !Arena', '\n' + str(i) + ": !Arena").replace('-1: !Arena', '\n' + str(i) + ": !Arena") #make sure to enumerate the arena objects properly
                    output_file.writelines(lines)
        print(f"Yaml files combined. Saved to {tmp_file_path}")
        return tmp_file_path
    except IOError as e:
        print(e)
        print("An error occurred while combining files.")

def yaml_combinor(file_list: list, temp_file_location: str, stored_file_name = "TempConfig_0.yml"):
    """
    Provide a list of paths to instances and the place you want to store the temporary file. You can change the name of the temporary file.
    """
    temp_file_path = os.path.join(temp_file_location, stored_file_name)
    
    try:
        with open(temp_file_path, 'w') as output_file:
            for i, file in enumerate(file_list):
                with open(file, 'r') as input_file:
                    if i > 0:
                        lines = input_file.readlines()[2:] #skip the first two lines that contain `!ArenaConfig\narenas:\n`
                        lines[0] = lines[0].replace('0: !Arena', "\n  " + str(i) + ": !Arena").replace('-1: !Arena', "\n  " + str(i) + ": !Arena") #make sure to enumerate the arena objects properly
                        output_file.writelines("\n# " + os.path.basename(file) + "\n")
                    else:
                        lines = input_file.readlines()
                        lines[2] = lines[2].replace('0: !Arena', "\n  " + str(i) + ": !Arena").replace('-1: !Arena', "\n  " + str(i) + ": !Arena") #make sure to enumerate the arena objects properly
                        output_file.writelines("# " + os.path.basename(file) + "\n")
                    output_file.writelines(lines)
        print(f"Yaml files combined. Saved to {temp_file_path}")
        return temp_file_path
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
    parser.add_argument('--stratify', type=bool, default=False)
    parser.add_argument('--num_files', type=int, default=300)
    parser.add_argument('--curriculum_overview_path', type=Path, default = '')
    args = parser.parse_args()
    
    random.seed(args.seed)
    if args.stratify:
        yaml_files, task_names = find_yaml_files_stratify(args.dir, 
                                                          stratify=args.stratify,
                                                          num_files=args.num_files,
                                                          curriculum_overview_path=args.curriculum_overview_path)
        yaml_combinor(yaml_files, args.temp_file, args.shuffle)
    else:
        yaml_files, task_names = find_yaml_files(args.dir)
        if args.n_parts is not None:
            yaml_combine_in_parts(yaml_files, args.temp_file, args.n_parts, args.shuffle)
        else:
            yaml_combinor(yaml_files, args.temp_file, args.shuffle)
