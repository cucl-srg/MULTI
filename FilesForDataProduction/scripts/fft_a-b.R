d<-read.table("fft_a-b")
d<-data.matrix(d)
a<-atan(d)
write(t(a),file="fft_a-b.atan",ncol=10)
