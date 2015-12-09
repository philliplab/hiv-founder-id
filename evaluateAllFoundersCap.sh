#!/bin/bash
mkdir ${3}
for patient in  `ls -c1 ${1}/*.fasta | cut -d_ -f5 | sort -u | egrep "^[0-9]+" | uniq`
do
    export outputDir=${3}/${patient}
    mkdir ${outputDir}
   ./evaluateFoundersV3.bash ${1} ${2} ${outputDir} ${patient} &
done
