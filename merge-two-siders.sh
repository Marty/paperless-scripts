#!/bin/bash

# Lists pdfs in a directory and if it contains more than two, merges the first two into one.
# It does so by running a ghostscript docker container.
# Afterwards it moves the merged file into the paperless consume directory and deletes the original files.
#
# Run this via crontab like this:
#  */2 * * * * /path/to/script/merge-two-siders.sh 2> /path/to/paperless/consume/two-siders/merge.log

set -eu

DIR=/sharedfolders/Daten/Paperless/consume/
SUB_DIR=two-siders/

cd ${DIR}

mergePdf() {
    FILES="$(find $SUB_DIR -name '*pdf' | sort -n | head -2)"
    FILE_COUNT=$(echo "$FILES" | wc -l)

    if (( ${FILE_COUNT} < 2 )); then
        echo "Not enough pdfs. Two needed, exiting."
        exit 1
    fi

    FIRST_FILE=$(echo "$FILES" | head -1)
    SECOND_FILE=$(echo "$FILES" | tail -1)
    OUTPUT_FILE="$(basename $FIRST_FILE .pdf)-merged.pdf"

    echo "Merging PDFs ${FILES} to ${OUTPUT_FILE}"

    docker run --rm -v $DIR:/app -w /app minidocks/ghostscript -dBATCH -dNOPAUSE -q -sDEVICE=pdfwrite -sOutputFile=${OUTPUT_FILE} ${FILES}

    RC=$?

    if (( $RC != 0 )); then
        echo "PDF merge failed: $RC"
    else
        rm $FILES
        echo "PDFs merged successfully"
    fi
}

echo "Starting pdf merge"

while true; do
    mergePdf
done
