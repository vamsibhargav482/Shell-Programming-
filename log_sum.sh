#!/bin/bash
#Done by Nithin Krishna

#Extracting input from user 
while getopts "L:c2rFt" opt; do
    case $opt in
        L)
            limit=$OPTARG
            ;;
        c)
            option="connection_attempts"
            ;;
        2)
            option="successful_attempts"
            ;;
        r)
            option="result_codes"
            ;;
        F)
            option="failure_result_codes"
            ;;
        t)
            option="bytes_sent"
            ;;

        \?)
            echo "Invalid option: -$OPTARG" >&2
            exit 1
            ;;
    esac
done

# Shifting to the first non-option argument (filename)
shift $((OPTIND-1))

# Reading log file below
filename="$1"
if [ "$filename" == "-" ] || [ -z "$filename" ]; then
    # Read from standard input
    log_data=$(cat)
else
    # Read from file
    log_data=$(cat "$filename")
fi

# Processing the log data based on the selected option
case $option in
    connection_attempts)
        echo "$log_data" | awk '{print $1}' | sort | uniq -c | sort -nr | head -n "${limit:-100}" | awk '{print $2, $1}'
        ;;
    successful_attempts)
        echo "$log_data" | awk '$7 ~ /^2/{print $1}' | sort | uniq -c | sort -nr | head -n "${limit:-100}"
        ;;
    result_codes)
        echo "$log_data" | awk '{print $9, $1}' | sort | uniq -c | sort -nr | head -n "${limit:-100}" | awk '{print $2, $3}'
        ;;
    failure_result_codes)
        # Filter lines with HTTP status codes starting with 4 or 5 and extract relevant fields
        echo "$log_data" | awk '$9 ~ /^(4|5)/{print $9, $1}' | sort | uniq -c | sort -nr | head -n "${limit:-100}" | awk '{print $1, $3, $2}'
        ;;
    bytes_sent)
        # Calculate sum of bytes for each IP and sort based on the sum
        # Extract relevant fields and filter by HTTP status code 200
        echo "$log_data" | awk '$9 == 200 {print $1, $10}' |
        # Group by IP address, summing up the bytes sent
        awk '{sum[$1] += $2} END {for (ip in sum) print ip, sum[ip]}' |
        # Sort by the sum of bytes in reverse numerical order
        sort -k2nr | head -n "${limit:-100}"
        ;;
esac
