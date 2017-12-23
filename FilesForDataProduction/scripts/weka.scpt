
#simple
for i in `seq -w 1 2 10`;do
java -Xmx1024M -classpath /projects/nprobe2/install/weka-3-4/weka.jar weka.classifiers.bayes.NaiveBayes -c 249 -t ../entry0$i/data/filelist.weka.allclass.arff -d ../entry0$i/data/filelist.weka.allclass.simple.model > NaiveBayes.allclass.simple.0$i-0$i;
done;



#testing
for i in `seq -w 0 2 10`;do

 for j in `seq -w 1 2 10 | sed '/'$i'/ d'`;do

 java -Xmx1024M -classpath /projects/nprobe2/install/weka-3-4/weka.jar weka.classifiers.bayes.NaiveBayes -c 249 -l ../entry$i/data/filelist.weka.allclass.simple.model -i -T ../entry0$j/data/filelist.weka.allclass.arff > NaiveBayes.allclass.simple.$i-0$j;
 done;
done;
 

