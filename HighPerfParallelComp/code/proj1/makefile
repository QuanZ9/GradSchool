CXX:=icc


#bd_mic: bd.c
#	${CXX} -std=c99 -mkl -qopenmp -O3 harness.c bd.c interactions.c timer.c -o bd_mic -mmic
#
#bd_host: bd.c
#	${CXX} -std=c99 -mkl -qopenmp -O3 harness.c bd.c timer.c interactions.c -o bd_host

bd_mic: bd.c
	${CXX} -std=c99 -mkl -O3 harness.c bd.c interactions.c timer.c -o bd_mic -mmic

bd_host: bd.c
	${CXX} -std=c99 -mkl -O3 harness.c bd.c timer.c interactions.c -o bd_host

MIC:=mic4

runmic:
	ssh $(MIC) rm -f output.xyz
	scp lac1_novl2.xyz $(MIC):
	scp bd_mic $(MIC):
	ssh $(MIC) ./bd_mic lac1_novl2.xyz output.xyz 10
	scp $(MIC):output.xyz ./

runhost:
	rm -f output.xyz
	./bd lac1_novl2.xyz output.xyz 1000

clean:
	rm -f *.o bd bd_mic output.xyz
