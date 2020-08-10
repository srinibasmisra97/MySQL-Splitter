#bash splitter.sh --source mysqlsampledatabase.sql

## VARIABLE DECLARATION

SOURCE_PATH=""
OUTPUT_PATH=""
MODE=""
INPUT_TABLE_NAME=""
INPUT_DB_NAME=""
LIST_MODE=""
SPLIT_MODE=""
SPLIT_TABLE_DB=""
CONFIG_PASS=0
CONFIG_FILE_PATH=""

## USAGE DESCRIPTION
usage()
{
    echo "bash splitter.sh"
    echo "OPTIONS:"
    echo "--source|-S: mysqldump file to process. has to be a .sql file. no compression allowed."
    echo "--output|-O: the output folder where all the separate sql files will be stored."
    echo "--mode | -M: Set the mode of operation."
    echo "   LIST : To list all the tables or databases."
    echo "      TABLE : To list all the tables."
    echo "      DB : To list all the databases."
    echo "   SPLIT : To split the sql file into pieces."
    echo "      ALL : Will split for all tables or databases present."
    echo "         TABLE : Will split the sql file into individual table files."
    echo "         DB : Will split the sql file into individual database files."
    echo "      SINGLE : Will search for specific table or database and generate its sql file."
    echo "         TABLE <table-name> : Will extract the table from the sql file."
    echo "         DB <database-name> : Will extract the database from the sql file."
    echo "--config|-C: Pass the path to config file. Run bash splitter.sh --config-format for more information."
    echo "--config-format: To see the format of the config file."
    echo "--help|-H: help."
    exit 1;
}

config_format()
{
        echo "File format supported: txt or conf."
        echo "SOURCE_PATH : Pass the source sql file path."
        echo "OUTPUT_PATH : Pass the output folder path."
        echo "MODE : Set the mode of operation. Two possible values -"
        echo "   LIST : To list all the tables or databases."
        echo "      LIST_MODE : Two possible values -"
        echo "         TABLE : To list all the tables."
        echo "         DB : To list all the databases."
        echo "   SPLIT : To split the sql file into pieces."
        echo "      SPLIT_MODE : Two possible values -"
        echo "         ALL : Will split for all tables or databases present."
        echo "            TABLE : Will split the sql file into individual table files."
        echo "            DB : Will split the sql file into individual database files."
        echo "         SINGLE : Will search for specific table or database and generate its sql file."
        echo "            INPUT_TABLE_NAME : Will extract the table from the sql file."
        echo "            INPUT_DB_NAME : Will extract the database from the sql file."
        exit 1;
}

missing_arg()
{
    echo "MISSING ARGUMENT: $1"
    echo "Try bash splitter.sh --help for more information."
    exit 1
}

split_into_tables()
{
    if [ "$OUTPUT_PATH" == "" ]; then
        OUTPUT_PATH="./splitter_output"
        echo "Setting default output path $OUTPUT_PATH"
    fi;

    echo "Starting to parse $SOURCE_PATH."
    
    mkdir -p $OUTPUT_PATH

    if [ $? -eq 0 ]; then
            echo "Setting output path: $OUTPUT_PATH";
    else
            echo "ERROR: Error while checking output path. $OUTPUT_PATH";
    fi;

        tableNameFile_found=-1
        for filename in $OUTPUT_PATH/*; do
                if [ "$filename" == "$OUTPUT_PATH/table_names.txt" ]; then
                        echo "Table name file already exists! Not creating one."
                        tableNameFile_found=1
                        break
                fi;
        done

        if [ $tableNameFile_found -eq -1 ]; then
                cat $SOURCE_PATH | grep -n "CREATE TABLE" | awk '{print $3}' | cut -d'`' -f2 | cat > ./$OUTPUT_PATH/table_names.txt
                echo "Table Name file has been generated."
        fi;

        lineNumbersFile_found=-1
        for filename in $OUTPUT_PATH/*; do
                if [ "$filename" == "$OUTPUT_PATH/table_line_numbers.txt" ]; then
                        echo "Table line numbers file already exists! Not creating one."
                        lineNumbersFile_found=1
                fi;
        done

        if [ $lineNumbersFile_found == -1 ]; then
                cat $SOURCE_PATH | grep -n "CREATE TABLE" | awk '{print $1}' | cut -d':' -f1 | cat > ./$OUTPUT_PATH/table_line_numbers.txt
                echo "Line number file has been generated."
        fi;

    filePath="./$OUTPUT_PATH/table_names.txt"
    comm_output=`cat $filePath`
    tableName_count=0
    declare -a TABLE_NAMES
    for line in $comm_output; do
        TABLE_NAMES[$tableName_count]=$line
        tableName_count=$((tableName_count+1))
    done

    echo "Number of tables: ${#TABLE_NAMES[@]}"

    filePath="./$OUTPUT_PATH/table_line_numbers.txt"
    comm_output=`cat $filePath`
    declare -a LINE_NUMBERS
    iter=0
    for line in $comm_output; do
        LINE_NUMBERS[$iter]=$line
        iter=$((iter+1))
    done

    iter=1

    while [ $iter != $((tableName_count+1)) ]; do
        prev_lineNumber=${LINE_NUMBERS[$((iter-1))]}
        curr_lineNumber=${LINE_NUMBERS[$iter]}
        curr_lineNumber=$((curr_lineNumber-5))
        curr_tableName=${TABLE_NAMES[$((iter-1))]}

        output_fileName="./$OUTPUT_PATH/$curr_tableName.sql"

        if [ -f $output_fileName ]; then
                echo "$output_fileName already exists. Overwriting it."
                rm $output_fileName
        fi;

        if [ $iter == $((tableName_count)) ]; then
                echo "Parsing from $prev_lineNumber to end - $output_fileName"
                tail --lines="+"$prev_lineNumber $SOURCE_PATH | cat > $output_fileName
        else
                echo "Parsing from $prev_lineNumber to $curr_lineNumber - $output_fileName"
                sed -n $prev_lineNumber,$curr_lineNumber"p" $SOURCE_PATH | cat > $output_fileName
        fi

        iter=$((iter+1))
    done
    
    exit 0;
}

split_into_databases()
{
    if [ "$OUTPUT_PATH" == "" ]; then
        OUTPUT_PATH="./splitter_output"
        echo "Setting default output path $OUTPUT_PATH"
    fi;
    echo "Starting to parse $SOURCE_PATH."
    
    mkdir -p $OUTPUT_PATH

    if [ $? -eq 0 ]; then
            echo "Setting output path: $OUTPUT_PATH";
    else
            echo "ERROR: Error while checking output path. $OUTPUT_PATH";
    fi;

        dbNameFile_found=-1
        for filename in $OUTPUT_PATH/*; do
                if [ "$filename" == "$OUTPUT_PATH/database_names.txt" ]; then
                        echo "Database name file already exists! Not creating one."
                        dbNameFile_found=1
                        break
                fi;
        done

        if [ $dbNameFile_found -eq -1 ]; then
                cat $SOURCE_PATH | grep -n "USE" | awk '{print $2}' | cut -d'`' -f2 | cat > ./$OUTPUT_PATH/database_names.txt
                echo "Database name file has been generated."
        fi;

        lineNumbersFile_found=-1
        for filename in $OUTPUT_PATH/*; do
                if [ "$filename" == "$OUTPUT_PATH/database_line_numbers.txt" ]; then
                        echo "Database line numbers file already exists! Not creating one."
                        lineNumbersFile_found=1
                fi;
        done

        if [ $lineNumbersFile_found == -1 ]; then
                cat $SOURCE_PATH | grep -n "CREATE DATABASE" | awk '{print $1}' | cut -d':' -f1 | cat > ./$OUTPUT_PATH/database_line_numbers.txt
                echo "Line number file has been generated."
        fi;

    filePath="./$OUTPUT_PATH/database_names.txt"
    comm_output=`cat $filePath`
    dbName_count=0
    declare -a DB_NAMES
    for line in $comm_output; do
        DB_NAMES[$dbName_count]=$line
        dbName_count=$((dbName_count+1))
    done

    echo "Number of tables: ${#DB_NAMES[@]}"

    filePath="./$OUTPUT_PATH/database_line_numbers.txt"
    comm_output=`cat $filePath`
    declare -a LINE_NUMBERS
    iter=0
    for line in $comm_output; do
        LINE_NUMBERS[$iter]=$line
        iter=$((iter+1))
    done

    iter=1

    while [ $iter != $((dbName_count+1)) ]; do
        prev_lineNumber=${LINE_NUMBERS[$((iter-1))]}
        curr_lineNumber=${LINE_NUMBERS[$iter]}
        curr_dbName=${DB_NAMES[$((iter-1))]}

        output_fileName="./$OUTPUT_PATH/$curr_dbName.sql"

        if [ -f $output_fileName ]; then
                echo "$output_fileName already exists. Overwriting it."
                rm $output_fileName
        fi;

        if [ $iter == $((dbName_count)) ]; then
                echo "Parsing from $prev_lineNumber to end to $output_fileName."
                tail --lines="+"$prev_lineNumber $SOURCE_PATH | cat > $output_fileName
        else
                echo "Parsing from $prev_lineNumber to $curr_lineNumber to $output_fileName."
                sed -n $prev_lineNumber,$curr_lineNumber"p" $SOURCE_PATH | cat > $output_fileName
        fi

        iter=$((iter+1))
    done

    exit 0;
}

split_table()
{
        if [ "$OUTPUT_PATH" == "" ]; then
                OUTPUT_PATH="./splitter_output"
                echo "Setting default output path $OUTPUT_PATH"
        fi;

        mkdir -p $OUTPUT_PATH

        if [ "$INPUT_TABLE_NAME" == "" ]; then
                echo "ERROR: Empty table name string provided!"
                exit 1;
        fi;

        tableNameFile_found=-1
        for filename in $OUTPUT_PATH/*; do
                if [ "$filename" == "$OUTPUT_PATH/table_names.txt" ]; then
                        echo "Table name file already exists! Not creating one."
                        tableNameFile_found=1
                        break
                fi;
        done

        if [ $tableNameFile_found -eq -1 ]; then
                cat $SOURCE_PATH | grep -n "CREATE TABLE" | awk '{print $3}' | cut -d'`' -f2 | cat > ./$OUTPUT_PATH/table_names.txt
                echo "Table Name file has been generated."
        fi;

        lineNumbersFile_found=-1
        for filename in $OUTPUT_PATH/*; do
                if [ "$filename" == "$OUTPUT_PATH/table_line_numbers.txt" ]; then
                        echo "Table line numbers file already exists! Not creating one."
                        lineNumbersFile_found=1
                fi;
        done

        if [ $lineNumbersFile_found == -1 ]; then
                cat $SOURCE_PATH | grep -n "CREATE TABLE" | awk '{print $1}' | cut -d':' -f1 | cat > ./$OUTPUT_PATH/table_line_numbers.txt
                echo "Line number file has been generated."
        fi;

        echo "Checking if table exists!"

        filePath="./$OUTPUT_PATH/table_names.txt"
        comm_output=`cat $filePath`
        tableName_count=0
        declare -a TABLE_NAMES
        for line in $comm_output; do
                TABLE_NAMES[$tableName_count]=$line
                tableName_count=$((tableName_count+1))
        done

        filePath="./$OUTPUT_PATH/table_line_numbers.txt"
        comm_output=`cat $filePath`
        declare -a LINE_NUMBERS
        iter=0
        for line in $comm_output; do
                LINE_NUMBERS[$iter]=$line
                iter=$((iter+1))
        done

        index=-1
        found=-1
        iter=0
        while [ $iter != $((tableName_count)) ]; do
                if [ "${TABLE_NAMES[iter]}" == "$INPUT_TABLE_NAME" ]; then
                        index=$iter
                        found=1
                        break
                fi;
                iter=$((iter+1))
        done

        if [ $found == 1 ]; then
                echo "Table exists!"

                if [ -f $OUTPUT_PATH/$INPUT_TABLE_NAME.sql ]; then
                        loop=1
                        while [ $loop -eq 1 ]; do
                                echo "$OUTPUT_PATH/$INPUT_TABLE_NAME.sql file already present!"
                                echo "Delete existing file and create a new file? Y/N:"
                                read userChoice

                                case "$userChoice" in
                                        "Y" | "y" | "yes" | "YES" ) 
                                                echo "Removing exisiting $OUTPUT_PATH/$INPUT_TABLE_NAME.sql...."
                                                rm $OUTPUT_PATH/$INPUT_TABLE_NAME.sql
                                                loop=0
                                                ;;
                                        "N" | "n" | "no" | "NO" )
                                                echo "Keeping the existing $OUTPUT_PATH/$INPUT_TABLE_NAME.sql...."
                                                loop=0
                                                return
                                                ;;
                                        * )
                                                echo "Please enter a valid choice. Y/N."
                                                loop=1
                                                ;;
                                esac
                        done
                fi;

                if [ $index == $((tableName_count-1)) ]; then
                        start_lineNumber=${LINE_NUMBERS[$index]}
                        tail --lines="+"$start_lineNumber $SOURCE_PATH | cat > ./$OUTPUT_PATH/$INPUT_TABLE_NAME.sql
                        echo "SUCCESS: Individual file for $INPUT_TABLE_NAME generated!"
                else
                        start_lineNumber=${LINE_NUMBERS[$index]}
                        end_lineNumber=${LINE_NUMBERS[$((index+1))]}
                        end_lineNumber=$((end_lineNumber-5))
                        sed -n $start_lineNumber,$end_lineNumber"p" $SOURCE_PATH | cat > ./$OUTPUT_PATH/$INPUT_TABLE_NAME.sql
                        echo "SUCCESS: Individual file for $INPUT_TABLE_NAME generated!"
                fi;
                exit 1;
        else
                echo "ERROR: Table does not exist! Please enter a valid table name!"
                exit 0;
        fi;

        exit 0;
}

split_db()
{
        if [ "$OUTPUT_PATH" == "" ]; then
                OUTPUT_PATH="./splitter_output"
                echo "Setting default output path $OUTPUT_PATH"
        fi;

        mkdir -p $OUTPUT_PATH

        if [ "$INPUT_DB_NAME" == "" ]; then
                echo "ERROR: Empty database name string provided!"
                exit 1;
        fi;

        dbNameFile_found=-1
        for filename in $OUTPUT_PATH/*; do
                if [ "$filename" == "$OUTPUT_PATH/database_names.txt" ]; then
                        echo "Database name file already exists! Not creating one."
                        dbNameFile_found=1
                        break
                fi;
        done

        if [ $dbNameFile_found -eq -1 ]; then
                cat $SOURCE_PATH | grep -n "USE" | awk '{print $2}' | cut -d'`' -f2 | cat > ./$OUTPUT_PATH/database_names.txt
                echo "Database name file has been generated."
        fi;

        lineNumbersFile_found=-1
        for filename in $OUTPUT_PATH/*; do
                if [ "$filename" == "$OUTPUT_PATH/database_line_numbers.txt" ]; then
                        echo "Database line numbers file already exists! Not creating one."
                        lineNumbersFile_found=1
                fi;
        done

        if [ $lineNumbersFile_found == -1 ]; then
                cat $SOURCE_PATH | grep -n "CREATE DATABASE" | awk '{print $1}' | cut -d':' -f1 | cat > ./$OUTPUT_PATH/database_line_numbers.txt
                echo "Line number file has been generated."
        fi;

        echo "Checking if database exists!"

        filePath="./$OUTPUT_PATH/database_names.txt"
        comm_output=`cat $filePath`
        dbName_count=0
        declare -a DB_NAMES
        for line in $comm_output; do
                DB_NAMES[$dbName_count]=$line
                dbName_count=$((dbName_count+1))
        done

        filePath="./$OUTPUT_PATH/database_line_numbers.txt"
        comm_output=`cat $filePath`
        declare -a LINE_NUMBERS
        iter=0
        for line in $comm_output; do
                LINE_NUMBERS[$iter]=$line
                iter=$((iter+1))
        done

        index=-1
        found=-1
        iter=0
        while [ $iter != $((dbName_count)) ]; do
                if [ "${DB_NAMES[iter]}" == "$INPUT_DB_NAME" ]; then
                        index=$iter
                        found=1
                        break
                fi;
                iter=$((iter+1))
        done

        if [ $found == 1 ]; then
                echo "Database exists!"

                if [ -f $OUTPUT_PATH/$INPUT_DB_NAME.sql ]; then
                        loop=1
                        while [ $loop -eq 1 ]; do
                                echo "$OUTPUT_PATH/$INPUT_DB_NAME.sql already exists!"
                                echo "Delete existing and create a new file? Y/N:"
                                read userChoice

                                case "$userChoice" in
                                        "Y" | "y" | "yes" | "YES" )
                                                echo "Removing $OUTPUT_PATH/$INPUT_DB_NAME.sql...."
                                                rm $OUTPUT_PATH/$INPUT_DB_NAME.sql
                                                loop=0
                                                ;;
                                        "N" | "n" | "no" | "NO" )
                                                echo "Not removing $OUTPUT_PATH/$INPUT_DB_NAME.sql....."
                                                loop=0
                                                return
                                                ;;
                                        * )
                                                echo "Please enter valid choice Y/N."
                                                loop=1
                                                ;;
                                esac
                        done
                fi;

                if [ $index == $((dbName_count-1)) ]; then
                        start_lineNumber=${LINE_NUMBERS[$index]}
                        tail --lines="+"$start_lineNumber $SOURCE_PATH | cat > ./$OUTPUT_PATH/$INPUT_DB_NAME.sql
                        echo "SUCCESS: Individual file for $INPUT_DB_NAME generated!"
                else
                        start_lineNumber=${LINE_NUMBERS[$index]}
                        end_lineNumber=${LINE_NUMBERS[$((index+1))]}
                        sed -n $start_lineNumber,$end_lineNumber"p" $SOURCE_PATH | cat > ./$OUTPUT_PATH/$INPUT_DB_NAME.sql
                        echo "SUCCESS: Individual file for $INPUT_DB_NAME generated!"
                fi;
                exit 1;
        else
                echo "ERROR: Database does not exist! Please enter a valid table name!"
                exit 0;
        fi;

        exit 0;
}

list_tables()
{
        if [ "$OUTPUT_PATH" == "" ]; then
                OUTPUT_PATH="./splitter_output"
                echo "Setting default output path $OUTPUT_PATH"
        fi;

        mkdir -p $OUTPUT_PATH

        tableNameFile_found=-1
        for filename in $OUTPUT_PATH/*; do
                if [ "$filename" == "$OUTPUT_PATH/table_names.txt" ]; then
                        echo "Table name file already exists! Not creating one."
                        tableNameFile_found=1
                        break
                fi;
        done

        if [ $tableNameFile_found -eq -1 ]; then
                cat $SOURCE_PATH | grep -n "CREATE TABLE" | awk '{print $3}' | cut -d'`' -f2 | cat > ./$OUTPUT_PATH/table_names.txt
                echo "Table Name file has been generated."
        fi;

        echo "Table Names:"
        cat $OUTPUT_PATH/table_names.txt
}

list_database()
{
        if [ "$OUTPUT_PATH" == "" ]; then
                OUTPUT_PATH="./splitter_output"
                echo "Setting default output path $OUTPUT_PATH"
        fi;

        mkdir -p $OUTPUT_PATH

        dbNameFile_found=-1
        for filename in $OUTPUT_PATH/*; do
                if [ "$filename" == "$OUTPUT_PATH/database_names.txt" ]; then
                        echo "Database name file already exists! Not creating one."
                        dbNameFile_found=1
                        break
                fi;
        done

        if [ $dbNameFile_found -eq -1 ]; then
                cat $SOURCE_PATH | grep -n "USE" | awk '{print $2}' | cut -d'`' -f2 | cat > ./$OUTPUT_PATH/database_names.txt
                echo "Database name file has been generated."
        fi;

        echo "Database Names:"
        cat $OUTPUT_PATH/database_names.txt
}

parse_config()
{
        if [ -f $CONFIG_FILE_PATH ]; then
                echo "Reading from config file: $CONFIG_FILE_PATH"
        else
                echo "Please check the path of your config file."
                exit 0;
        fi;

        source $CONFIG_FILE_PATH
}

if [ "$#" -eq 0 ]; then
        usage;
        exit 1;
fi;

while [ "$1" != "" ]; do
        case $1 in
                --source | -S | -s ) shift
                        SOURCE_PATH=$1
                        ;;
                --output | -O | -o ) shift
                        OUTPUT_PATH=$1
                        ;;
                --config | -c | -C ) shift
                        CONFIG_PASS=1
                        CONFIG_FILE_PATH=$1
                        ;;
                --config-format )
                        config_format
                        ;;
                --help | -h | -H )
                        usage
                        ;;
                --mode | -m | -M ) shift
                        case "$1" in
                                "LIST" | "list" ) shift
                                        MODE="LIST"
                                        case "$1" in
                                                "TABLE" | "table" )
                                                        LIST_MODE="TABLE"
                                                        ;;
                                                "DB" | "db" )
                                                        LIST_MODE="DB"
                                                        ;;
                                                * )
                                                        echo "ERROR: Invalid list mode selected."
                                                        exit 1;
                                                        ;;
                                        esac
                                        ;;
                                "SPLIT" | "split" ) shift
                                        MODE="SPLIT"
                                        case "$1" in
                                                "ALL" | "all" ) shift
                                                        SPLIT_MODE="ALL"
                                                        case "$1" in
                                                                "TABLE" | "table" )
                                                                        SPLIT_TABLE_DB="TABLE"
                                                                        ;;
                                                                "DB" | "db" )
                                                                        SPLIT_TABLE_DB="DB"
                                                                        ;;
                                                                * )
                                                                        echo "ERROR: Invalid split all mode selected."
                                                                        exit 1;
                                                                        ;;
                                                        esac
                                                        ;;
                                                "SINGLE" | "single" ) shift
                                                        SPLIT_MODE="SINGLE"
                                                        case "$1" in
                                                                "TABLE" | "table" ) shift
                                                                        INPUT_TABLE_NAME=$1
                                                                        SPLIT_TABLE_DB="TABLE"
                                                                        ;;
                                                                "DB" | "db" ) shift
                                                                        INPUT_DB_NAME=$1
                                                                        SPLIT_TABLE_DB="DB"
                                                                        ;;
                                                                * )
                                                                        echo "ERROR: Invalid split single mode selected."
                                                                        exit 1;
                                                                        ;;
                                                        esac
                                                        ;;
                                                * )
                                                        echo "ERROR: Invalid split mode selected."
                                                        exit 1;
                                                        ;;
                                        esac
                                        ;;
                                * )
                                        echo "ERROR: Invalid mode selected."
                                        exit 1;
                                        ;;
                        esac
                        ;;
                * )
                        echo "ERROR: Unknown input parameter passed!"
                        exit 1;
                        ;;
        esac
        shift
done

if [ $CONFIG_PASS -eq 1 ]; then
        parse_config

        if [ "$SOURCE_PATH" == "" ]; then
                echo "ERROR: No SOURCE_PATH present in the config file."
                exit 1;
        fi;

        if [ "$MODE" == "" ]; then
                echo "ERROR: No MODE present in the config file."
                exit 1;
        fi;

        case "$MODE" in
                "LIST" | "list" )
                        if [ "$LIST_MODE" == "" ]; then
                                echo "ERROR: No LIST_MODE present in the config file."
                                exit 1;
                        else
                                case "$LIST_MODE" in
                                        "TABLE" | "table" | "DB" | "db" )
                                                ;;
                                        * )
                                                echo "ERROR: Unknown LIST_MODE value set - $LIST_MODE"
                                                exit 1;
                                                ;;
                                esac
                        fi;
                        ;;
                "SPLIT" | "split" )
                        if [ "$SPLIT_MODE" == "" ]; then
                                echo "ERROR: No SPLIT_MODE present in the config file."
                                exit 1;
                        else
                                case "$SPLIT_MODE" in
                                        "ALL" | "all" )
                                                if [ "$SPLIT_TABLE_DB" == "" ]; then
                                                        echo "ERROR: No SPLIT_TABLE_DB value present in the config file."
                                                        exit 1;
                                                else
                                                        case "$SPLIT_TABLE_DB" in
                                                                "TABLE" | "table" | "DB" | "db" )
                                                                        ;;
                                                                * )
                                                                        echo "ERROR: Unknown SPLIT_TABLE_DB value set - $SPLIT_TABLE_DB."
                                                                        exit 1;
                                                        esac
                                                fi;
                                                ;;
                                        "SINGLE" | "single" )
                                                if [ "$SPLIT_TABLE_DB" == "" ]; then
                                                        echo "ERROR: No SPLIT_TABLE_DB value present in the config file."
                                                        exit 1;
                                                else
                                                        case "$SPLIT_TABLE_DB" in
                                                                "TABLE" | "table" )
                                                                        if [ "$INPUT_TABLE_NAME" == "" ]; then
                                                                                echo "ERROR: No INPUT_TABLE_NAME value set in the config file."
                                                                                exit 1;
                                                                        fi;
                                                                        ;;
                                                                "DB" | "db" )
                                                                        if [ "$INPUT_DB_NAME" == "" ]; then
                                                                                echo "ERROR: No INPUT_DB_NAME value set in the config file."
                                                                                exit 1;
                                                                        fi;
                                                                        ;;
                                                                * )
                                                                        echo "ERROR: Invalid SPLIT_TABLE_DB value set - $SPLIT_TABLE_DB."
                                                                        exit 1;
                                                                        ;;
                                                        esac
                                                fi;
                                                ;;
                                        * )
                                                echo "ERROR: Invalid SPLIT_MODE value set - $SPLIT_MODE"
                                                exit 1;
                                                ;;
                                esac
                        fi;
                        ;;
                * )
                        echo "ERROR: Invalid MODE set - $MODE"
                        exit 1;
                        ;;
        esac
fi;

if [ "$MODE" != "" ]; then
        case "$MODE" in
                "LIST" | "list" )
                        case "$LIST_MODE" in
                                "TABLE" | "table" )
                                        list_tables
                                        ;;
                                "DB" | "db" )
                                        list_database
                                        ;;
                        esac
                        ;;
                "SPLIT" | "split" )
                        case "$SPLIT_MODE" in
                                "ALL" | "all" )
                                        case "$SPLIT_TABLE_DB" in
                                                "TABLE" | "table" )
                                                        split_into_tables
                                                        ;;
                                                "DB" | "db" )
                                                        split_into_databases
                                                        ;;
                                        esac
                                        ;;
                                "SINGLE" | "single" )
                                        case "$SPLIT_TABLE_DB" in
                                                "TABLE" | "table" )
                                                        split_table
                                                        ;;
                                                "DB" | "db" )
                                                        split_db
                                                        ;;
                                        esac
                                        ;;
                        esac
                        ;;
        esac
else
        missing_arg --mode
fi;

exit 0;