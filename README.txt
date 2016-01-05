#==============================================================================#
#                            NewsClusterer                                     #
#==============================================================================#
# 'NewsClusterer' is an inhouse developed project which attempt to cluster the # 
# online news articles into different clusters, where all news articles in a   #
# given single cluster may cover similar topic.                                #
#==============================================================================#


#==============================================================================#
Technologies Used:
#==============================================================================#
1. Apache Nutch (v1.10): 
      Apache nutch crawls different online news articles starting with few seed
      articles.
2. Apache Solr (v4.6.1):
      Apache solr index all the nutch crawled news articles. Solr Undertow is
      used as an underlying web server.
3. Apache Mahout (v0.11.1):
      Apache mahout is used as an underlying machine learning tool. It takes
      solr index (of news articles), convert it into lucene vectors, then apply 
      clustering algorithm on these lucene vectors.
4. Apache Hadoop (v2.6.0):
      Hadoop can be (optionally) used as an underlying distributed computing 
      platform. Hadoop has been set up as a single node cluster. And is turned
      off as of now. However, we can turn it on based on need.
#==============================================================================#


#==============================================================================#
Requirments:
#==============================================================================#
1. Linux Machine:
2. Java (version 7 or above) installed on 1. And, the environment variable,
   JAVA_HOME, must have been set accordingly.
#==============================================================================#


#==============================================================================#
Usage:
#==============================================================================#
All the required configuration for hadoop, mahout, nutch and solr is done. All
you need to do is just run a bash script, namely,'cluster.sh' from home 
directory of 'NewsClusterer'.
#==============================================================================#


#==============================================================================#
Result:
#==============================================================================#
The clutering result will be stored in the file './result/result.txt' 
#==============================================================================#


#==============================================================================#
Note:
#==============================================================================#
At present, we use mahout's k-mean clustering algorithm by randomly setting the
value of 'k' to 50. Also solr has been minimally tuned for term vectors. Hence,
the result may not be accurate. However, there is a lot of scope for improving 
the result including the setting up of an evaluation framework.
#==============================================================================#


#==============================================================================#
Download Note:
#==============================================================================#
The project repository size is quite big (~1GB) as it includes binaries from
four big apache open source projects. Hence, download may take some time.
#==============================================================================#
