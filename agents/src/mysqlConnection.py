import pandas as pd
import pymysql

def databaseConnector(databaseCredentialsCSV: str):
    databaseCredentials = pd.read_csv(databaseCredentialsCSV)
    
    connection = pymysql.connect(
        host=databaseCredentials['hostname'].iloc[0],
        user=databaseCredentials['username'].iloc[0],
        password=databaseCredentials['password'].iloc[0],
        database=databaseCredentials['database_name'].iloc[0]
        )

    mycursor = connection.cursor()

    print(f"Connected to database: `{databaseCredentials['database_name'].iloc[0]}` at `{databaseCredentials['hostname'].iloc[0]}` with user `{databaseCredentials['username'].iloc[0]}`.")

    return mycursor, connection

def agentToDB (cur, dictionary : dict, table_name : str):
    keys = ', '.join(dictionary.keys())
    values = ', '.join(
        f"'{value}'" if not isinstance(value, (int, float, bool)) else str(int(value))
        if isinstance(value, bool) else str(value)
        for value in dictionary.values()
        )

    query = f"INSERT INTO {table_name} ({keys}) VALUES ({values});"

    try:
        cur.execute(query)
    except:
        print(f"Agent `{dictionary['agent_tag']}` is already in the table: {table_name}.")
    
    return query

def removePreviouslyRunInstances(cur, yaml_files, task_names, agentid, agent_table, agent_instance_results_table):
    
    length_yaml_files = len(yaml_files)
    
    select_existing_tasks = f"SELECT instances.instancename FROM instances INNER JOIN {agent_instance_results_table} ON instances.instanceid = {agent_instance_results_table}.instanceid INNER JOIN {agent_table} ON {agent_instance_results_table}.agentid = {agent_table}.agentid WHERE {agent_table}.agentid = {agentid};"

    cur.execute(select_existing_tasks)

    results = cur.fetchall()

    already_run_tasks = pd.DataFrame(results, columns = [i[0] for i in cur.description])

    task_names_df = pd.DataFrame({'instancename' : task_names})

    outer = task_names_df.merge(already_run_tasks, how='outer', indicator=True)

    task_names = outer[(outer._merge=='left_only')].drop('_merge', axis=1)

    task_names = task_names['instancename'].to_list()

    # filter out any previously run instances from yaml_files

    yaml_files = [item for item in yaml_files if any(value in item for value in task_names)]

    length_yaml_files_new = len(yaml_files)

    print(f"Dropping {length_yaml_files - length_yaml_files_new} instances that have already been run before.")

    return task_names, yaml_files

def selectID(cur, id_name, table_name, WHERE_column, WHERE_clause, secondary_WHERE_column = None, secondary_WHERE_clause = None, distinct = True):
    if secondary_WHERE_column is None:
        if distinct:
            query = f"SELECT DISTINCT {id_name} FROM {table_name} WHERE {WHERE_column} = '{WHERE_clause}';"
        else:
            query = f"SELECT {id_name} FROM {table_name} WHERE {WHERE_column} = '{WHERE_clause}';"
    else:
        if distinct:
            query = f"SELECT DISTINCT {id_name} FROM {table_name} WHERE {WHERE_column} = '{WHERE_clause}' AND {secondary_WHERE_column} = '{secondary_WHERE_clause}';"
        else:
            query = f"SELECT {id_name} FROM {table_name} WHERE {WHERE_column} = '{WHERE_clause}' AND {secondary_WHERE_column} = '{secondary_WHERE_clause}';"


    cur.execute(query)

    id = int(cur.fetchone()[0])

    return id