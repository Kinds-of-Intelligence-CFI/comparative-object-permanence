"""
Copyright © 2023 Konstantinos Voudouris (@kozzy97)

Author: Konstantinos Voudouris
Date: June 2023
Python Version: 3.10.4
Animal-AI Version: 3.0.2

"""

import fnmatch
import os


def find_yaml_files(directory):
    yaml_files = []
    task_names = []
    
    for root, dirnames, filenames in os.walk(directory):
        for filename in fnmatch.filter(filenames, '*.yml') + fnmatch.filter(filenames, '*.yaml'):
            yaml_files.append(os.path.join(root, filename))
            task_names.append(filename)
    
    return yaml_files, task_names

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
                        lines[0] = lines[0].replace('0: !Arena', str(i) + ": !Arena").replace('-1: !Arena', str(i) + ": !Arena") #make sure to enumerate the arena objects properly
                    else:
                        lines = input_file.readlines()
                        lines[2] = lines[2].replace('0: !Arena', str(i) + ": !Arena").replace('-1: !Arena', str(i) + ": !Arena") #make sure to enumerate the arena objects properly
                    output_file.writelines(lines)
        print(f"Yaml files combined. Saved to {temp_file_path}")
        return temp_file_path
    except IOError as e:
        print(e)
        print("An error occurred while combining files.")

if __name__ == "__main__":
    import sys
    from pathlib import Path
    # Parse arg, first one being the config dir, second one being the temp file
    dir, temp_file = sys.argv[1], Path(sys.argv[2])
    yaml_files, task_names = find_yaml_files(dir)
    yaml_combinor(yaml_files, str(temp_file.parent), temp_file.name)