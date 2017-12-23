d<-read.table("fft.all")
d<-data.matrix(d)
a<-atan(d)
write(t(a),file="fft.all.atan",ncol=10)
