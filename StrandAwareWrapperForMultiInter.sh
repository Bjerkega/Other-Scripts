#!/bin/bash
#Script that makes Bedtools Multi Intersect strand aware
#Header will be printed and no options will work.
#Files must be sorted!
#Also read the -h help file

#Track errors
mkdir -p log
exec 2> log/$(date +"%H:%M:%S_%m_%d_%Y")MultiInter_terminal_commands.txt 2>&1
set -e
set -u
set -o pipefail

while getopts ":hf:" opt; do
    case $opt in
    h)
        echo 'This script is a wrapper to make Bedtools strand aware'
        echo 'File names will be printed as a header. No options from multiintersect will work'
        echo 'Output needs to be redirected with a >'
        echo 'Files must be sorted!'
        echo '-f Files to operate on. Must to be enclosed by ""'
        exit 0
        ;;
    f)  FILES=$OPTARG
        ;;
    esac
done

#Generate two random numbers
RN=$((RANDOM))
RN2=$((RANDOM))

#Parse the file list into a file with individual lines
echo $FILES | tr " " "\n" > MI.TempListOfFiles.$RN.$RN2

while read p; do
   awk '$6 == "+"' $p > $p.$RN.$RN2.pos
   awk '$6 == "-"' $p > $p.$RN.$RN2.neg
done < MI.TempListOfFiles.$RN.$RN2

PosFiles=$(ls *.$RN.$RN2.pos)
NegFiles=$(ls *.$RN.$RN2.neg)
#Make sure the names are sorted so they come out the same.
NamesSort=$(sort MI.TempListOfFiles.$RN.$RN2)

#There is probably a better way to do the next part
bedtools multiinter -i $PosFiles > Temp1.$RN.$RN2
paste <(cut -f 1-5 Temp1.$RN.$RN2) <(awk '{print"+"}' Temp1.$RN.$RN2) <(cut -f 6- Temp1.$RN.$RN2) > TempOut.$RN.$RN2
bedtools multiinter -i $NegFiles > Temp2.$RN.$RN2
paste <(cut -f 1-5 Temp2.$RN.$RN2) <(awk '{print"-"}' Temp2.$RN.$RN2) <(cut -f 6- Temp2.$RN.$RN2) >> TempOut.$RN.$RN2

#Output
echo -e 'chrom\tstart\tend\tnum\tlist\tstrand\t'$NamesSort
sort -k 1,1 -k 2,2n TempOut.$RN.$RN2

while read p; do
rm $p.$RN.$RN2.pos
rm $p.$RN.$RN2.neg
done < MI.TempListOfFiles.$RN.$RN2
rm MI.TempListOfFiles.$RN.$RN2
rm Temp1.$RN.$RN2
rm Temp2.$RN.$RN2
rm TempOut.$RN.$RN2