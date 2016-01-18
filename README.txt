#==============================================================================#
#                            NewsClusterer                                     #
#==============================================================================#
# 'NewsClusterer' is a machine learning project which attempt to automatically #
# cluster the online news articles into different clusters, where all news     #
# articles in a given single cluster may cover similar topic.                  #
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
5. Python and Scikit-learn: 
      Python and Scikit-learn is used for cluster evaluation.
#==============================================================================#


#==============================================================================#
Requirements:
#==============================================================================#
1. Linux Machine:
2. Java (version 7 or above) installed on 1. And, the environment variable,
   JAVA_HOME, must have been set accordingly.
3. Python and scikit-learn installed on 1.
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
The clustering result will be stored in the directory './result/' 
#==============================================================================#


#==============================================================================#
Summary:
#==============================================================================#
1. Mahout k-mean algorithm is used for clustering. Value of k is set to
   sqrt(n/2) where 'n' is the total number of document vectors.
2. SED tool is used to post-process the clustering result.
3. The sed processed result is fed to python scikit-learn to evaluate the
   clustering result. Result is evaluated by computing 'Silhouette score'.
4. Two distance measures namely - Tanimato Measure (Extened Jaccard Measure)
   and Cosine Similarity Measure, are compared. Result is slightly better for
   Tanimato Measure.
#==============================================================================#


#==============================================================================#
Future Scope of Work:
#==============================================================================#
There exists lot of scope for improving the result.
1. We may tune nutch to control the crawling, and there by to get the more
   meaningful crawl results. 
2. We may tune the solr/lucene schema file to control the terms to be indexed.
3. We may use other methods to chose the more better value for 'k' to be used 
   in k-mean algorithm, or we may explore other clustering algorithms.
4. We may explore other (complicated and may be better) techniques for cluster
   evaluation.
#==============================================================================#


#==============================================================================#
Download Note:
#==============================================================================#
The project repository size is quite big (~1GB) as it includes binaries from
four big apache open source projects, and hence, downloading may take some time.
#==============================================================================#
