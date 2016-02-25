#!/bin/bash

# Arg one is a directory in which there are lists of "1w" fasta files
# named nnnnnnn.list where nnnnnnn is a patient number.  It expects
# directories within that directory to be called
# hiv_founder_id_processed_nnnnnnn unless a fourth argument is
# provided, in which case it will expect directories to be called
# hiv_founder_id_nnnnnnn. Arg two is the analogous dir for the
# estimates, arg three is the writable dir to put outputs, and the
# fourth argument if present toggles the expected dir name (as just
# described in the previous sentence).
#
mkdir ${3}
for patient in  `ls -c1 ${1}/*.fasta | cut -d_ -f5 | sort -u | egrep "^[0-9]+" | uniq`
do
    export outputDir=${3}/${patient}
    mkdir ${outputDir}
   ./evaluateFoundersV3.bash ${1} ${2} ${outputDir} ${patient} ${4} &
done
