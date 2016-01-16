#!/bin/bash

#clear screen
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
EVAL_HOME=./ClusterEvaluation

# clean up all temp directories and logs in order to start from scratch
rm -r ./news/hadoop/namenode/* > /dev/null 2>&1
rm -r ./news/hadoop/datanode/* > /dev/null 2>&1
rm -r ./news/solr/home/core1/data/* > /dev/null 2>&1
rm -r ./news/solr/logs/* > /dev/null 2>&1
rm -r ./news/solr/temp/* > /dev/null 2>&1
rm -r ./news/nutch/crawl/* > /dev/null 2>&1
rm -r ./news/nutch/urls/* > /dev/null 2>&1
rm -r ./news/mahout/* > /dev/null 2>&1
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

# we have defined temporary hadoop namenode directory as /tmp/_hdtmp_ in 
# the hadoop configuration file "core-site.xml". Hence create this directory if
# it is not already created.
hfsd="/tmp/_hdtmp_"
if [ ! -d $hfsd ]
then
   mkdir $hfsd
   chmod 777 $hfsd
fi

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
crawldb=./news/nutch/crawl/crawldb
segments=./news/nutch/crawl/segments
linkdb=./news/nutch/crawl/linkdb
urls=./news/nutch/urls

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

# final results are stored here
res_dir=./result
result_file=$res_dir/result.txt

# mahout related variables
MAHOUT_LOCAL=true
mahout=$MAHOUT_HOME/bin/mahout
index_dir=./news/solr/home/core1/data/index 
in_dir=./news/mahout/input
vec_file=$in_dir/vector-00000
dict_file=$in_dir/dictionary.txt
out_dir=./news/mahout/output
seed_dir=./news/mahout/seed
cpp_dir=./news/mahout/cpp
k=50
max_iter=20
distance_measure=org.apache.mahout.common.distance.TanimotoDistanceMeasure
cpp_list_file=./news/mahout/cpp_list.txt
count=1

sleep 2
echo "Message: Getting lucene vectors from solr index."
sleep 2
$mahout lucene.vector -d $index_dir -o $vec_file -t $dict_file \
--idField id  -f text -n 2 -w TFIDF
sleep 2
echo "Message: Finished getting lucene vectors."

# save dictionary file in result directory. Which helps to interpret the
# solr/lucene selected terms.
cp $dict_file $res_dir/

sleep 2
echo "Message: Clustering news articles using mahout clustering algorithm."
sleep 2
$mahout kmeans -i $vec_file -o $out_dir -c $seed_dir -k $k \
-x $max_iter -dm $distance_measure -cl -ow
sleep 2
echo "Message: Finished clustering of news articles."

sleep 2                                                                         
echo "Message: Postprocessng the clustering result."     
sleep 2
$mahout clusterpp -i $out_dir -o $cpp_dir -ow
sleep 2
ls -d1 $cpp_dir/* > $cpp_list_file 2>&1
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

cpp_seq_file=$out_dir/clusteredPoints/part*
cpp_txt_file=$out_dir/clusteredPoints/cpp.txt
$mahout vectordump -i $cpp_seq_file -o $cpp_txt_file -p printKey

p_cpp_txt_file=$out_dir/clusteredPoints/p_cpp.txt
sed 's/{//g' <$cpp_txt_file | sed 's/}//g' >$p_cpp_txt_file

final_seq_dir=""
for D in $out_dir/clusters-*-final
do
  final_seq_dir=$D
done
final_txt_file=$final_seq_dir/final.txt
$mahout clusterdump -i $final_seq_dir -o $final_txt_file -n 0

p_final_txt_file=$final_seq_dir/p_final.txt
sed 's/\",\"r/\"\t\"r/g' <$final_txt_file | sed -E 's/,\"n\":[0-9]+//g' | \
sed 's/\t\"r\":\[*\],\"c\":/\t/g' | sed 's/\"identifier\":\"[CV]L-//g' | \
sed 's/\"//g' | sed 's/{//g' | sed 's/}//g' | sed 's/\[//g' | sed 's/\]//g' \
>$p_final_txt_file
sleep 2
echo "Message: Finished postprocessng of clustering result."

sleep 2
echo "Message: Evaluating the clustering result."
sleep 2
eval_in_dir=$EVAL_HOME/input
eval_out_dir=$EVAL_HOME/output
eval_out_file=$eval_out_dir/evaluation.txt
final_eval_file=$res_dir/evaluation.txt

cp $p_cpp_txt_file $eval_in_dir/
cp $p_final_txt_file $eval_in_dir/
head -1 $dict_file > $eval_in_dir/num_terms.txt
cd $EVAL_HOME
python cluster_evaluation.py
cd ../ 
cp $eval_out_file $final_eval_file 
sleep 2
echo "Message: Done with evaluating the clustering result."

# clean up all temp directories and logs
rm -r ./news/hadoop/namenode/* > /dev/null 2>&1
rm -r ./news/hadoop/datanode/* > /dev/null 2>&1
rm -r ./news/solr/home/core1/data/* > /dev/null 2>&1
rm -r ./news/solr/logs/* > /dev/null 2>&1
rm -r ./news/solr/temp/* > /dev/null 2>&1
rm -r ./news/nutch/crawl/* > /dev/null 2>&1
rm -r ./news/nutch/urls/* > /dev/null 2>&1
rm -r ./news/mahout/* > /dev/null 2>&1
rm -r ./temp/* > /dev/null 2>&1
rm -r $HADOOP_HOME/logs/* > /dev/null 2>&1
rm -r $SOLR_HOME/logs/* > /dev/null 2>&1
rm -r $NUTCH_HOME/logs/* > /dev/null 2>&1
rm -r $MAHOUT_HOME/logs/* > /dev/null 2>&1
rm -r $EVAL_HOME/input/* > /dev/null 2>&1
rm -r $EVAL_HOME/output/* > /dev/null 2>&1

# print final message
echo -e ""
echo "================================================================="
echo "Done with the clustering of news articles."
echo "The final result is available in the file $final_result_file"
echo "The evalaution result is available in the file $final_eval_file"
echo "================================================================="
