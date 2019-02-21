#!/bin/bash
CURR_DIR=$(cd `dirname $0`; pwd)
source $CURR_DIR/project-list.all.sh

#Go to the rdf folder
RDF_FOLDER="data-deps.compile/rdf"
cd $CURR_DIR/../../$RDF_FOLDER

#ALL_PROJECTS=(aekos_common abares_fgc dewnr_bdbsa oeh_vis tern_atn_bats tern_natt uq_supersites_cover adelaide_koonamore dewnr_roadsideveg qld_corveg tern_ausplots tern_swatt usyd_derg dpipwe_platypus tern_ausplots_forests tern_trend wadec_ravensthorpe)

#ALL_PROJECTS=(aekos_common tern_atn_bats tern_natt)

echo "Converting ttl files to n-quads......"

#Convert all ttl to nq
find . -name "*.ttl" -type f | while read file; do turtle -out=nq $file > ${file%.*}.nq; done

echo "Appending named graph to n-quads...."

#Replace the last dot with named graph
for currProject in "${ALL_PROJECTS[@]}"; do
 echo "Processing...$currProject"
 #for Linux remove "" after -i
 sed  -i "" "s+\.$+<http://www.aekos.org.au/ontology/1.0.0/$currProject#> .+" `find ./$currProject -name "*.nq" -type f`
done

echo "Loading tdb database using tdbloader2 ...."

#Load all n quad files to a tdb data
tdbloader2 --loc=tdb-data/ `find . -name "*.nq" -type f`
#tdbloader2 --loc=/Users/aekos/java/temp/tdb `find . -name "*.nq" -type f`
echo ""
echo "Done loading tdb-database with n-quads"
