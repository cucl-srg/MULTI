d<-read.table("fft_b-a")
d<-data.matrix(d)
a<-atan(d)
write(t(a),file="fft_b-a.atan",ncol=10)
