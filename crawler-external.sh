ALL_STORAGESETS=(tern_ausplotsstorageset tern_swattstorageset usyd_dergstorageset dpipwe_platypusstorageset tern_ausplots_forestsstorageset tern_trendstorageset adelaide_koonamorestorageset uq_supersites_coverstorageset wadec_ravensthorpestorageset abares_fgcstorageset tern_swattstorageset dewnr_roadsidevegstorageset dewnr_bdbsastorageset qld_corvegstorageset oeh_visstorageset)

LOGS_DIR=logs
UNIQUE_ID=`date +%Y%m%d_%H%M`
mkdir -p $LOGS_DIR

if [ "$1" == "debug" ]
then
        DEBUG_FRAGMENT="-agentlib:jdwp=suspend=n,server=y,transport=dt_socket,address=8001"
fi

for currStorageset in "${ALL_STORAGESETS[@]}"; do
  java -Xms1G -Xmx5G -XX:MaxPermSize=384m -XX:+HeapDumpOnOutOfMemoryError $DEBUG_FRAGMENT -noverify -cp \
data-deps.compile-1.0.0-SNAPSHOT.jar au.org.aekos.gtcrawler.dao.TransformCrawlerLauncher $currStorageset 2>&1 | tee $LOGS_DIR/transform_crawler_$UNIQUE_ID-$currStorageset.log

GENETIC_RAYS_THOROUGHNESS="-Daekos.crawler.thoroughness=DO_A_GOOD_JOB"

java -Xms1G -Xmx12G -XX:MaxPermSize=384m -XX:+HeapDumpOnOutOfMemoryError $DEBUG_FRAGMENT $GENETIC_RAYS_THOROUGHNESS -cp \
data-deps.compile-1.0.0-SNAPSHOT.jar au.org.aekos.gtcrawler.dao.SubgraphContainerCrawlerLauncher $currStorageset 2>&1 | tee $LOGS_DIR/subgraph_container_crawler_$UNIQUE_ID-$currStorageset.log

java -Xms1G -Xmx12G -XX:MaxPermSize=384M -XX:+HeapDumpOnOutOfMemoryError $DEBUG_FRAGMENT -cp \
data-deps.compile-1.0.0-SNAPSHOT.jar au.org.aekos.gtcrawler.dao.MakeSubgraphInstanceTypeTreeLauncher $currStorageset 2>&1 | tee $LOGS_DIR/extraction_crawler_$UNIQUE_ID-$currStorageset.log
done
