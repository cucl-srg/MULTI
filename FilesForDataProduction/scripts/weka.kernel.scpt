
#kernel
#model building

for i in `seq -w 0 2 10`;do

java -Xmx1024M -classpath /projects/nprobe2/install/weka-3-4/weka.jar weka.classifiers.bayes.NaiveBayes -K -c 249 -t ../entry$i/data/filelist.weka.allclass.arff -d  ../entry$i/data/filelist.weka.allclass.kernel.model -i > NaiveBayes.allclass.kernel.$i-$i;

done;


#kernel
#testing
for i in `seq -w 0 2 10`;do

 for j in `seq -w 0 2 10 | sed '/'$i'/ d'`;do

 java -Xmx1024M -classpath /projects/nprobe2/install/weka-3-4/weka.jar weka.classifiers.bayes.NaiveBayes -K -c 249 -l ../entry$i/data/filelist.weka.allclass.kernel.model -i -T ../entry$j/data/filelist.weka.allclass.arff > NaiveBayes.allclass.kernel.$i-$j;
 done;
done;
 
