#!/bin/bash

# clear console
clear

# check if java home environment variable is set
if [ -z "$JAVA_HOME" ]
then
   echo "Error: Please set environment variable \"JAVA_HOME\""
   exit 1
fi

# create a temp directory in the current directory.
if [ ! -d ./temp ]
then
   mkdir ./temp
else
   rm -r ./temp/* > /dev/null 2>&1
fi

# set home directories of hadoop, nutch, solr and mahout
export HADOOP_HOME=./hadoop-2.6.0
export SOLR_HOME=./solr-undertow-1.5.0
export NUTCH_HOME=./nutch-1.10
export MAHOUT_HOME=./mahout-0.11.1         
export EVAL_HOME=./ClusterEvaluation
export RES_HOME=./result
export NHD=./news/hadoop
export NSD=./news/solr
export NND=./news/nutch
export NMD=./news/mahout

# clean up all temp directories and logs in order to start from scratch
rm -r $NHD/namenode/* > /dev/null 2>&1
rm -r $NHD/datanode/* > /dev/null 2>&1
rm -r $NSD/home/core1/data/* > /dev/null 2>&1
rm -r $NSD/logs/* > /dev/null 2>&1
rm -r $NSD/temp/* > /dev/null 2>&1
rm -r $NND/crawl/* > /dev/null 2>&1
rm -r $NND/urls/* > /dev/null 2>&1
rm -r $NMD/* > /dev/null 2>&1
rm -r $RES_HOME/tanimoto/* > /dev/null 2>&1
rm -r $RES_HOME/cosine/* > /dev/null 2>&1
rm -r $HADOOP_HOME/logs/* > /dev/null 2>&1
rm -r $SOLR_HOME/logs/* > /dev/null 2>&1
rm -r $NUTCH_HOME/logs/* > /dev/null 2>&1
rm -r $MAHOUT_HOME/logs/* > /dev/null 2>&1
rm -r $EVAL_HOME/input/* >/dev/null 2>&1
rm -r $EVAL_HOME/output/* >/dev/null 2>&1

# set hadoop related environment variables.
export HADOOP_PREFIX=$HADOOP_HOME
export HADOOP_INSTALL=$HADOOP_HOME                                              
export HADOOP_MAPRED_HOME=$HADOOP_HOME                                          
export HADOOP_COMMON_HOME=$HADOOP_HOME                                          
export HADOOP_HDFS_HOME=$HADOOP_HOME                                            
export YARN_HOME=$HADOOP_HOME                                                   
export HADOOP_CONF_DIR=$HADOOP_HOME/etc/hadoop                                  
export HADOOP_COMMON_LIB_NATIVE_DIR=$HADOOP_HOME/lib/native

# append hadoop bin and sbin to PATH
export PATH=$PATH:$HADOOP_HOME/sbin:$HADOOP_HOME/bin

# set solr related variables
solr_log=./temp/solr.log
undertow=$SOLR_HOME/bin/solr-undertow
solr_conf=$SOLR_HOME/solr-4-6-1.conf

# start undertow http server as a background job and deploy solr web application
# within it
echo "Message: Starting up solr undertow http server."
sleep 2
$undertow $solr_conf > $solr_log 2>&1 &
SOLR_ID=$!
sleep 10  # set sleep time appropriately. otherwise below grepping of solr log 
          # may not be correct 
grep -q "ERROR" $solr_log 
if [ $? -eq 0 ]
then
   echo "Error: Solr undertow http server is failed to start. Please check it."
   curl -X GET http://localhost:9983?password=abcd1234
   echo "" 
   exit 1
else
   echo "Message: Solr undertow http server is up and running."
fi

sleep 2

# nutch related variables
nutch=$NUTCH_HOME/bin/nutch
crawldb=$NND/crawl/crawldb
segments=$NND/crawl/segments
linkdb=$NND/crawl/linkdb
urls=$NND/urls

# create seed.txt file and add seed urls to it.
seed_file=$urls/seed.txt
touch $seed_file 
echo "http://timesofindia.indiatimes.com/" >> $seed_file 2>&1
echo "http://www.thehindu.com/" >> $seed_file 2>&1
echo "http://www.deccanherald.com/" >> $seed_file 2>&1
echo "http://indianexpress.com/" >> $seed_file 2>&1
echo "http://economictimes.indiatimes.com/" >> $seed_file 2>&1
echo "http://www.nytimes.com/" >> $seed_file 2>&1
echo "http://www.usatoday.com/" >> $seed_file 2>&1
echo "http://www.wsj.com/india" >> $seed_file 2>&1
echo "http://www.chron.com/" >> $seed_file 2>&1
echo "http://www.latimes.com/" >> $seed_file 2>&1 

# crawl and index the news sites
echo "Message: Started crawling and indexing of news articles"
sleep 2
$nutch inject $crawldb $urls
for i in `seq 1 2`;
do
   $nutch generate $crawldb $segments -topN 1000 
   s1=`ls -d $segments/2* | tail -1`
   $nutch fetch $s1
   $nutch parse $s1
   $nutch updatedb $crawldb $s1
   $nutch invertlinks $linkdb -dir $segments 
   $nutch solrindex http://127.0.0.1:8983/solr/core1 $crawldb $s1 -linkdb $linkdb 
done

sleep 3 
echo "Message: Sucessfully crawled and indexed news articles."

# indexing is done. stop the solr server now.
curl -X GET http://localhost:9983?password=abcd1234
echo ""

sleep 3 
echo "Message: Indexing is done. Solr server is stopped."

# mahout related variables
MAHOUT_LOCAL=true
mahout=$MAHOUT_HOME/bin/mahout
INDEX_DIR=$NSD/home/core1/data/index 
IN_DIR=$NMD/input
vec_seq_file=$IN_DIR/vector-00000
vec_text_file=$IN_DIR/vector.txt
dict_file=$IN_DIR/dictionary.txt
num_vec_file=$IN_DIR/num_vecs.txt

sleep 2
echo "Message: Getting lucene vectors from solr index."
sleep 2
$mahout lucene.vector -d $INDEX_DIR -o $vec_seq_file -t $dict_file \
--idField id  -f text -n 2 -w TFIDF
sleep 2
echo "Message: Finished getting lucene vectors."

# get the value of k as sqrt(n/2) where n is the number of vectors
sleep 2
echo "Message: Getting the total number of vectors."
$mahout vectordump -i $vec_seq_file -o $vec_text_file
cat $vec_text_file | wc -l > $num_vec_file
let k=$(cat $num_vec_file)
k=$(echo "sqrt($k/2)" | bc -l)
let k=${k%.*}
cp $dict_file $RES_HOME/
sleep 2
echo "Message: Finished getting the total number of vectors"

# similarity measures to be explored
DIST_ARR=(cosine tanimoto)

# processs the data set for each distance measure
for dist in ${DIST_ARR[@]}
do
  # final cluster results are stored here
  RES_DIR=$RES_HOME/$dist
  result_file=$RES_DIR/result.txt

  # create a directory to store result for current distance measure
  mkdir $NMD/$dist

  OUT_DIR=$NMD/$dist/output
  SEED_DIR=$NMD/$dist/seed
  max_iter=20

  if [ "$dist" == "tanimoto" ]
  then
     distance_measure=org.apache.mahout.common.distance.TanimotoDistanceMeasure
  elif [ "$dist" == "cosine" ]
  then
    distance_measure=org.apache.mahout.common.distance.CosineDistanceMeasure
  fi
  
  sleep 2
  echo "Message: Clustering news articles using mahout clustering algorithm."
  sleep 2
  $mahout kmeans -i $vec_seq_file -o $OUT_DIR -c $SEED_DIR -k $k \
  -x $max_iter -dm $distance_measure -cl -ow
  sleep 2
  echo "Message: Finished clustering of news articles."

  CPP_DIR=$NMD/$dist/cpp
  cpp_list_file=$NMD/$dist/cpp_list.txt
  count=1

  sleep 2                                                                         
  echo "Message: Dumping each cluster in separate directory"     
  sleep 2
  $mahout clusterpp -i $OUT_DIR -o $CPP_DIR -ow
  sleep 2
  ls -d1 $CPP_DIR/* > $cpp_list_file 2>&1
  while read line
  do 
     if [ -d $line ]
     then
        echo -e '===========================================================' >> $result_file
        echo -e "Cluster $count" >> $result_file 
        echo -e '===========================================================' >> $result_file
        seq_file=$line/part*
        $mahout vectordump -i $seq_file -o $line/dump.txt -d $dict_file -dt text -N nameOnly
        cat $line/dump.txt >> $result_file
        echo -e '===========================================================' >> $result_file
        echo -e "" >> $result_file
        count=`expr $count + 1`
     fi
  done < $cpp_list_file
  sleep 2
  echo "Message: Finished dumping of clusters"

  sleep 2
  echo "Message: Postprocessing clustering result"
  sleep 2
  cpp_seq_file=$OUT_DIR/clusteredPoints/part*
  cpp_txt_file=$OUT_DIR/clusteredPoints/cpp.txt
  p_cpp_txt_file=$OUT_DIR/clusteredPoints/p_cpp.txt
  $mahout vectordump -i $cpp_seq_file -o $cpp_txt_file -p printKey
  sed 's/{//g' <$cpp_txt_file | sed 's/}//g' >$p_cpp_txt_file

  FSD=""
  for D in $OUT_DIR/clusters-*-final
  do
    FSD=$D
  done
  final_txt_file=$FSD/final.txt
  p_final_txt_file=$FSD/p_final.txt
  $mahout clusterdump -i $FSD -o $final_txt_file -n 0
  sed 's/\",\"r/\"\t\"r/g' <$final_txt_file | sed -E 's/,\"n\":[0-9]+//g' | \
  sed 's/\t\"r\":\[*\],\"c\":/\t/g' | sed 's/\"identifier\":\"[CV]L-//g' | \
  sed 's/\"//g' | sed 's/{//g' | sed 's/}//g' | sed 's/\[//g' | sed 's/\]//g' \
  >$p_final_txt_file
  sleep 2
  echo "Message: Finished postprocessng of clustering result."

  sleep 2
  echo "Message: Evaluating the clustering result."
  sleep 2
  EID=$EVAL_HOME/input
  cp $p_cpp_txt_file $EID/
  cp $p_final_txt_file $EID/
  head -1 $dict_file > $EID/num_terms.txt
  cd $EVAL_HOME
  python cluster_evaluation.py
  cd ../ 
  EOD=$EVAL_HOME/output
  cp $EOD/evaluation.txt $RES_DIR/
  sleep 2
  echo "Message: Done with evaluating the clustering result."

done

rm -r $NHD/namenode/* > /dev/null 2>&1
rm -r $NHD/datanode/* > /dev/null 2>&1
rm -r $NSD/home/core1/data/* > /dev/null 2>&1
rm -r $NSD/logs/* > /dev/null 2>&1
rm -r $NSD/temp/* > /dev/null 2>&1
rm -r $NND/crawl/* > /dev/null 2>&1
rm -r $NND/urls/* > /dev/null 2>&1
rm -r $NMD/* > /dev/null 2>&1
rm -r $HADOOP_HOME/logs/* > /dev/null 2>&1
rm -r $SOLR_HOME/logs/* > /dev/null 2>&1
rm -r $NUTCH_HOME/logs/* > /dev/null 2>&1
rm -r $MAHOUT_HOME/logs/* > /dev/null 2>&1
rm -r $EVAL_HOME/input/* >/dev/null 2>&1
rm -r $EVAL_HOME/output/* >/dev/null 2>&1
rm -r ./temp/* > /dev/null 2>&1

# print final message
echo -e ""
echo "========================================================================"
echo "Done with the clustering of news articles. The result is available in the
directory ${RES_HOME}."
echo "========================================================================"
