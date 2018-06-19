#!/bin/bash
ALL_PROJECTS=(aekos_common abares_fgc dewnr_bdbsa oeh_vis tern_atn_bats tern_natt uq_supersites_cover adelaide_koonamore dewnr_roadsideveg qld_corveg tern_ausplots tern_swatt usyd_derg dpipwe_platypus tern_ausplots_forests tern_trend wadec_ravensthorpe)

for currProject in "${ALL_PROJECTS[@]}"; do
  tdbloader --loc=tdb-data/ --graph="<http://www.aekos.org.au/ontology/$currProject#>" `find ./$currProject -name "*.ttl" -type f`
  #echo "<http://www.aekos.org.au/ontology/$currProject#>"
done
