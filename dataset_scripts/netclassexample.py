from __future__ import absolute_import
from __future__ import division
from __future__ import print_function
from copy import deepcopy
import os
import numpy as np
import tensorflow as tf
import sys 
import time

tf.logging.set_verbosity(tf.logging.INFO)
# Data sets inputted as an argument when the code is run
NET_TRAINING = sys.argv[1]
NET_TEST = sys.argv[2]

def main():
	sess = tf.Session()
  # Load datasets.
	training_set = tf.contrib.learn.datasets.base.load_csv_with_header(
      filename=NET_TRAINING,
      target_dtype=np.int,
      features_dtype=np.float32)
	test_set = tf.contrib.learn.datasets.base.load_csv_with_header(
      filename=NET_TEST,
      target_dtype=np.int,
      features_dtype=np.float32)


	# Define minimum and range from the training set data, to be used to scale the attribute values from 0 to 1 in training set, and accordingly in the test set
	# ports lists the 13 most used ports, used as a pseudo embedded layer
	min1 = np.min(training_set.data,0)
	scale1 = np.max(training_set.data,0)-np.min(training_set.data,0)
	ports = np.array([  80,   25,  443,   21, 3306,   53,  110,  135, 2234, 4662,  143, 6346, 8765], dtype=np.float32)

	# Define the training inputs, changing port
	def get_train_inputs():
		j, k =(training_set.data).shape
		train1 = deepcopy(training_set.data)
		for i in range(0,k):
			for l in range(0,j):
				train1[l,i] = train1[l,i]-min1[i]
				train1[l,i] = (train1[l,i])/(scale1[i])
		switch = np.zeros((j,13))
		for i in range(0,j):
			for l in range (0,13):
				if training_set.data[i,0] == ports[l]:
					switch[i,l]=1
					break
		train2 = np.concatenate((switch,train1[:,1:k]),1)
		x = tf.constant(train2)
		y = tf.constant(training_set.target)
		return x, y

#	train_set_data, _ = get_train_inputs()
#	train_set_data = sess.run(train_set_data)

  # Define the test inputs, using the same ports chosen above and the minimum and range defined by the training set data
	def get_test_inputs():
		j1, k1 =(test_set.data).shape
		train3 = deepcopy(test_set.data)
		for i in range(0,k1):
			for l in range(0,j1):
				train3[l,i] = train3[l,i]-min1[i]
				train3[l,i] = (train3[l,i])/(scale1[i])
		switch1 = np.zeros((j1,13))
		for i in range(0,j1):
			for l in range (0,13):
				if test_set.data[i,0] == ports[l]:
					switch1[i,l]=1
					break
		train4 = np.concatenate((switch1,train3[:,1:k1]),1)
		x = tf.constant(train4)
		y = tf.constant(test_set.target)
		return x, y

#	test_set_data, _ = get_test_inputs()
#	test_set_data = sess.run(test_set_data)

  # Set validation metrics to accuracy and a confusion matrix
	validation_metrics = {
      "accuracy":
          tf.contrib.learn.MetricSpec(
              metric_fn=tf.contrib.metrics.streaming_accuracy,
              prediction_key="classes"),
	"confusion matrix \n":
	tf.contrib.learn.MetricSpec(
		metric_fn = tf.contrib.metrics.confusion_matrix,
		prediction_key="classes")
	
}
  #validation monitor for logging purposes
	validation_monitor = tf.contrib.learn.monitors.ValidationMonitor(
		input_fn = get_test_inputs,
		every_n_steps=100,
		eval_steps=1,  
#		early_stopping_metric="accuracy",
#		   early_stopping_metric_minimize=False,
#  		  early_stopping_rounds=500,
		metrics=validation_metrics)

  # Specify that all features have real-valued data
  # Dimension = number of features + size of 'ports'(13) -1
	feature_columns = [tf.contrib.layers.real_valued_column("", dimension= (10+12))]

  # Build single hiddenlayer DNN with 12 units, tanh activation function, model directory passed in as an argument
	classifier = tf.contrib.learn.DNNClassifier(feature_columns=feature_columns,
                                              hidden_units=[12],
						activation_fn=tf.tanh,
                                              n_classes=12,
                                              model_dir=sys.argv[3],
						config=tf.contrib.learn.RunConfig(save_checkpoints_steps=100))

  #Fit model, taking time value
	t0 = time.time()	
	classifier.fit(input_fn=get_train_inputs, steps = 20000, monitors=[validation_monitor])
	t1 = time.time()
  # Evaluate accuracy and print time to conversion if it applies 
	accuracy_score = classifier.evaluate(input_fn=get_test_inputs, steps=1)["accuracy"]
	print("\nTest Accuracy: {0:f}\n".format(accuracy_score))
	time_tot = t1-t0
	print("\nTime to converge = {}\n".format(time_tot))

   # Print final confusion matrix
"""
	def train_samples():
		a,_ = get_test_inputs()
		sess = tf.Session()
		b = sess.run(a)
		return np.array(b, dtype=np.float32)
	true_samples= tf.constant(test_set.target, dtype=tf.int32)
	pred1 = list(classifier.predict(input_fn = train_samples))
	pred2 = tf.convert_to_tensor(pred1, tf.int32)
	conf_mat = tf.confusion_matrix(labels = true_samples, predictions = pred2, num_classes = 12)
	print("Training Set, Confusion Matrix:   \n {}"
	.format(sess.run(conf_mat)))  """
	
	#OTHER RESULTS Write desired neural network results into a file. 
	#Can extract global step number, all parameters and specifically weights from classifier.get_variable_variable_value
	classifier_names = classifier.get_variable_names()
	myfile = open("temp_stab_new.txt","a")
	myfile.write("Training on = {} \n".format(NET_TRAINING))
	myfile.write("Accuracy = {} \n".format(accuracy_score))
	myfile.write("Confusion Matrix = \n {} \n".format(sess.run(conf_mat)))
	myfile.write("Step number = \n {} \n".format(classifier.get_variable_value(classifier_names[9])))
	myfile.write("Time = \n {} \n \n".format(time_tot))
	myfile.close()

"""	classifier_names = classifier.get_variable_names()
	myfile1 = open("temp_stab.csv","a")
	myfile1.write("Training on = {} \n".format(NET_TRAINING))
	myfile1.write("Accuracy = {} \n".format(accuracy_score))
	myfile1.close()
	myfile1 = open("temp_stab.csv","ab")
	np.savetxt(myfile1,(sess.run(conf_mat)),delimiter = ",",footer ="\n")
	myfile1.close()
#	np.savetxt(myfile1,classifier_names[9],footer = "\n")
	myfile1 = open("temp_stab.csv","ab")
	np.savetxt(myfile1,classifier.get_variable_value(classifier_names[9]),delimiter = ",",footer = "\n \n")
	myfile1.close()

"""

if __name__ == "__main__":
	main()


