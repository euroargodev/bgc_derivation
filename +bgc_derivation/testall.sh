#!/bin/bash

#
# /testall.sh
#

# title - s testall -vr 1.0 author - bodc/matcaz - date 24012019
#
# mods - 
#

stty -echo

declare -a versions=("2009b" "2011a" "2012a" "2013b" "2014b" "2016b")

echo "Unloading any loaded Matlab modules..."

for ii in "${versions[@]}"
do
    module unload "matlab/$ii"
done

echo "Purging output folder..."
rm -rf output/*

echo "Beginning test sequence..."

for ii in "${versions[@]}"
do
    echo "Testing $ii..."
    module load "matlab/$ii"
    matlab -nodisplay -nodesktop -nosplash -r "[~] = driverproc('input/testdriver.txt'); exit"
    mkdir -p "output/$ii"
    mv "output.mat" "output/$ii/output_$ii.mat"
    module unload "matlab/$ii"
done

echo "Generating and comparing data checksums..."

module load matlab/2016b
matlab -nodisplay -nodesktop -nosplash -r "comparetests(); exit"
module unload matlab/2016b

if grep -q "DIFF!" output/checksums.txt
then
    echo "Diffs were detected, please check the checksums file!"
else
    echo "No diffs detected!"
fi

echo "Test sequence complete!"
stty echo
