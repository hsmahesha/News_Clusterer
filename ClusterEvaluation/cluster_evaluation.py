import csv                                                                      
import sys
import numpy as np
from sklearn import metrics

def get_evaluation_score(labelArr, vecArr, metric):
    eVal = metrics.silhouette_score(vecArr, labelArr, metric)
    return eVal

def read_cpp_file(iFile, numTerms):
    iList = list(csv.reader(iFile, delimiter='\t'))
    numVec = len(iList)
    labelArr = np.zeros(numVec, int)
    vecArr = np.zeros((numVec, numTerms))
    curInd = 0
    for iNode in iList:
        labelArr[curInd] = int(iNode[0])
        vStr = str(iNode[1])
        vList = vStr.split(',')
        tVec = np.zeros(numTerms)
        for vNode in vList:
            vNodeList = str(vNode).split(':')
            tNo = int(vNodeList[0])
            tVal = float(vNodeList[1])
            tVec[tNo] = tVal
        vecArr[curInd] = tVec[:]
        curInd += 1
    return labelArr, vecArr

def open_in_file(fStr):
    try:
        iFile = open(fStr, "r")
    except:
        print("Failed to open the file " + fStr)
        sys.exit()
    return iFile

def open_out_file():
    fStr = './output/evaluation.txt'
    try:
        oFile = open(fStr, "w")
    except:
        print("Failed to open the file " + fStr)
        sys.exit()
    return oFile

def evaluate_clusters():
    numTermFileStr = './input/num_terms.txt'
    numTermFile = open_in_file(numTermFileStr)
    numTerms = int(numTermFile.readline())
    numTermFile.close()

    cppFileStr = './input/p_cpp.txt'
    cppFile = open_in_file(cppFileStr)
    labelArr, vecArr = read_cpp_file(cppFile, numTerms)
    cppFile.close()

    eVal = get_evaluation_score(labelArr, vecArr, 'euclidean')

    oFile = open_out_file()
    outStr = "Silhouettes Score = " + str(eVal) + "\n"
    oFile.write(outStr)
    oFile.close() 

evaluate_clusters()
