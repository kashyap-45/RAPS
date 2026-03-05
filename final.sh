#!/bin/ksh
#*********************************************************************
# Author : Kashyap
# Script Name : RAPS_File_Status_Check.sh
# Purpose     : Validate RAMP50 / UNBRAND / BRAND files
#               and send notification based on structure and archive
#*********************************************************************

# ---------------- CONFIGURATION ---------------- #

RAPS_HOME=/rapsa/prod
ARCH_DIR=/rapsd/prod/data/cdds
EMAIL_ID="bharanikashyap45@gmail.com"
DATE=$(date '+%d%b %Y %T')

# ------------------------------------------------ #
# Function: check_file
# Argument: File prefix (APRF.RAPS.RAMP50 etc.)
# ------------------------------------------------ #

check_file() {

    FILE_PREFIX=$1
    TYPE=$2

    FILE="$RAPS_HOME/data/$FILE_PREFIX"

    echo "---------------------------------------------"
    echo "Checking $TYPE file..."
    echo "---------------------------------------------"

    # --------- File existence check --------- #

    if [ ! -f "$FILE" ]; then
        echo "$TYPE file not found."
        echo "$TYPE file not found in data directory." | \
        mailx -s "$TYPE: File Missing - $DATE" $EMAIL_ID
        return
    fi

    # Edge Case 2: Check if file is readable
    if [ ! -r "$FILEPATH" ]; then
        echo "ERROR: File is not readable: $FILEPATH" >> $ECHO_LOG
        return 1
    fi

    # --------- Structure validation --------- #

    TOTAL_LINES=$(wc -l < "$FILE")
    echo "  Total lines in file: $TOTAL_LINES"

    # Edge Case 4: Check if file has minimum lines (HDR + TRL at minimum)
    if [ $TOTAL_LINES -lt 2 ]; then
        echo "ERROR: File has less than 2 lines (missing HDR or TRL): $FILEPATH" >> $ECHO_LOG
        echo "File is invalid - contains only $TOTAL_LINES line(s)" >> $ECHO_LOG
        return 1
    fi

    #HDR_COUNT=$(grep -c '^HDR' "$FILE")
    #TRL_COUNT=$(grep -c '^TRL' "$FILE")

    #CHECK_COUNT=$((TOTAL_LINES - HDR_COUNT - TRL_COUNT))



    # --------- Missing Header --------- #

    # Edge Case 5: Check for HDR (Header) line
    HDR_LINE=`head -1 $FILEPATH`
    if ! echo "$HDR_LINE" | grep -q '^HDR'; then
        echo "ERROR: Missing HDR (Header) line in file: $FILEPATH" >> $ECHO_LOG
        echo "First line: $HDR_LINE" >> $ECHO_LOG
        return 1
    fi
    echo "  HDR (Header) found"

    # --------- Missing Trailer --------- #

     # Edge Case 6: Check for TRL (Trailer) line
    TRL_LINE=`tail -1 $FILEPATH`
    if ! echo "$TRL_LINE" | grep -q '^TRL'; then
        echo "ERROR: Missing TRL (Trailer) line in file: $FILEPATH" >> $ECHO_LOG
        echo "Last line: $TRL_LINE" >> $ECHO_LOG
        return 1
    fi
    echo "  TRL (Trailer) found"

    # --------- Multiple HDR or TRL --------- #

    if [ "$HDR_COUNT" -gt 1 ] || [ "$TRL_COUNT" -gt 1 ]; then
        echo "$TYPE file structure invalid (multiple HDR or TRL)."
        echo "$TYPE file structure invalid. Multiple HDR or TRL found." | \
        mailx -s "$TYPE: Structure Error - $DATE" $EMAIL_ID
        return
    fi

    # --------- Empty File --------- #

    if [ "$CHECK_COUNT" -eq 0 ]; then
        echo "$TYPE file is empty (0 checks). Not transmitted."
        echo "$TYPE file is empty. Check count = 0. Not transmitted." | \
        mailx -s "$TYPE: Empty File - $DATE" $EMAIL_ID
        return
    fi

    # --------- Has Records --------- #

    BASENAME=$(basename "$FILE")

    ARCHIVED_FILE=$(ls $ARCH_DIR/$BASENAME.*.Z 2>/dev/null | head -1)

    if [ -n "$ARCHIVED_FILE" ]; then
        echo "$TYPE file has $CHECK_COUNT record(s). Successfully transmitted."
        echo "$TYPE file has $CHECK_COUNT record(s) and was successfully transmitted." | \
        mailx -s "$TYPE: Successfully Transmitted - $DATE" $EMAIL_ID
    else
        echo "$TYPE file has $CHECK_COUNT record(s) but NOT transmitted."
        echo "$TYPE file has $CHECK_COUNT record(s) but was NOT transmitted." | \
        mailx -s "$TYPE: Not Transmitted - $DATE" $EMAIL_ID
    fi
}

# ---------------- MAIN EXECUTION ---------------- #

echo "============================================="
echo "RAPS File Validation Started : $DATE"
echo "============================================="

check_file "APRF.RAPS.RAMP50" "RAMP50"
check_file "APRF.RAPS.UNBRAND" "UNBRAND"
check_file "APRF.RAPS.BRAND" "BRAND"

echo "============================================="
echo "RAPS File Validation Completed"
echo "============================================="
