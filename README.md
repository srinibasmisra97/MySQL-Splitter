MySQL Splitter

Execute using bash.

bash splitter.sh
OPTIONS:
--source|-S: mysqldump file to process. has to be a .sql file. no compression allowed.
--output|-O: the output folder where all the separate sql files will be stored.
--mode | -M: Set the mode of operation.
    LIST : To list all the tables or databases.
        TABLE : To list all the tables.
        DB : To list all the databases.
    SPLIT : To split the sql file into pieces.
        ALL : Will split for all tables or databases present.
            TABLE : Will split the sql file into individual table files.
            DB : Will split the sql file into individual database files.
        SINGLE : Will search for specific table or database and generate its sql file.
            TABLE <table-name> : Will extract the table from the sql file.
            DB <database-name> : Will extract the database from the sql file.
--config|-C: Pass the path to config file. Run bash splitter.sh --config-format for more information.
--config-format: To see the format of the config file.
--help|-H: help.

Config file format:

File format supported: txt or conf.

SOURCE_PATH : Pass the source sql file path.
OUTPUT_PATH : Pass the output folder path.
MODE : Set the mode of operation. Two possible values -
    LIST : To list all the tables or databases.
        LIST_MODE : Two possible values -
            TABLE : To list all the tables.
            DB : To list all the databases.
    SPLIT : To split the sql file into pieces.
        SPLIT_MODE : Two possible values -
            ALL : Will split for all tables or databases present.
                TABLE : Will split the sql file into individual table files.
                DB : Will split the sql file into individual database files.
            SINGLE : Will search for specific table or database and generate its sql file.
                INPUT_TABLE_NAME : Will extract the table from the sql file.
                INPUT_DB_NAME : Will extract the database from the sql file.