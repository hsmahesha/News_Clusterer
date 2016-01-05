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

# clean up all temp directories in order to start from scratch
rm -r ./news/hadoop/* > /dev/null 2>&1
rm -r ./news/solr/home/core1/data/* > /dev/null 2>&1
rm -r ./news/solr/logs/* > /dev/null 2>&1
rm -r ./news/solr/temp/* > /dev/null 2>&1
rm -r ./news/nutch/crawl/* > /dev/null 2>&1
rm -r ./news/nutch/urls/* > /dev/null 2>&1
rm -r ./news/mahout/* > /dev/null 2>&1

# set hadoop related environment variables.
export HADOOP_HOME=./hadoop-2.6.0                        
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

# re-format the hadoop namenode directory
echo "Message: Started reformating of hadoop namenode directory"
sleep 2
y_file=./temp/y.txt
hadoop_log=./temp/hadoop.log
hdfs=$HADOOP_HOME/bin/hdfs
echo "Y" > $y_file 2>&1
$hdfs namenode -format $hadoop_log > $hadoop_log 2>&1 < $y_file
sleep 2
grep -q "has been successfully formatted" $hadoop_log
if [ $? -eq 0 ]
then
   echo "Message: Finished reformating of hadoop namendode directory."
else
   echo "Error: Reformating of hadoop namenode directory failed. Please check it."
   exit 1
fi

sleep 2 

# set solr related variables
SOLR_HOME=./solr-undertow-1.5.0

# start undertow http server as a background job and deploy solr web application
# within it
echo "Message: Started the launching of solr undertow http server."
sleep 2
solr_log=./temp/solr.log
undertow=$SOLR_HOME/bin/solr-undertow
solr_conf=$SOLR_HOME/solr-4-6-1.conf
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
NUTCH_HOME=./nutch-1.10
nutch=$NUTCH_HOME/bin/nutch
crawldb=./news/nutch/crawl/crawldb
segments=./news/nutch/crawl/segments
linkdb=./news/nutch/crwal/linkdb
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
   $nutch generate $crawldb $segments 
   s1=`ls -d $segments/2* | tail -1`
   $nutch fetch $s1
   $nutch parse $s1
   $nutch updatedb $crawldb $s1
   $nutch solrindex http://127.0.0.1:8983/solr/core1 $crawldb $s1 
done

sleep 3 
echo "Message: Sucessfully crawled and indexed news articles."

# indexing is done. stop the solr server now.
curl -X GET http://localhost:9983?password=abcd1234
echo ""

sleep 3 
echo "Message: Indexing is done. Solr server is stopped."

# mahout related variables
MAHOUT_HOME=./mahout-0.11.1                      
MAHOUT_LOCAL=true
mahout=$MAHOUT_HOME/bin/mahout
index_dir=./news/solr/home/core1/data/index 
vec_dir=./news/mahout/lucene_vector
vec_file=$vec_dir/vec
dict_file=$vec_dir/dict
cluster_dir=./news/mahout/cluster
init_dir=./news/mahout/init
group_dir=./news/mahout/group
k=50
max_iter=20
distance_measure=org.apache.mahout.common.distance.TanimotoDistanceMeasure
group_file=./news/mahout/group.txt
result_file=./news/mahout/result.txt
final_result_file=./result/result.txt
count=1

sleep 2
echo "Message: Getting lucene vectors from solr index."
sleep 2
$mahout lucene.vector -d $index_dir -o $vec_file -t $dict_file \
--idField id  -f text -n 2 -w TFIDF
sleep 2
echo "Message: Finished getting lucene vectors."

sleep 2
echo "Message: Clustering news articles using mahout clustering algorithm."
sleep 2
$mahout kmeans -i $vec_file -o $cluster_dir -c $init_dir -k $k \
-x $max_iter -dm $distance_measure -cl -ow
sleep 2
echo "Message: Finished clustering of news articles."

sleep 2                                                                         
echo "Message: Postprocessng the clustering result."     
sleep 2
$mahout clusterpp -i $cluster_dir -o $group_dir -ow
sleep 2
ls -d1 $group_dir/* > $group_file 2>&1
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
done < $group_file 
sleep 2
echo "Message: Finished postprocessng of clustering result."

# move final result file to ./result directory
mv $result_file $final_result_file

# clean up all temp directories
rm -r ./news/hadoop/* > /dev/null 2>&1
rm -r ./news/solr/home/core1/data/* > /dev/null 2>&1
rm -r ./news/solr/logs/* > /dev/null 2>&1
rm -r ./news/solr/temp/* > /dev/null 2>&1
rm -r ./news/nutch/crawl/* > /dev/null 2>&1
rm -r ./news/nutch/urls/* > /dev/null 2>&1
rm -r ./news/mahout/* > /dev/null 2>&1
rm -r ./temp/* > /dev/null 2>&1

# print final message
echo -e ""
echo "================================================================="
echo "Done with the clustering of news articles. The final result is 
available in the file $final_result_file"
echo "================================================================="
