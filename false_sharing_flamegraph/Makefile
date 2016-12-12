.PHONY: all
CFLAGS += -g3 -pthread

all: false_sharing no_false_sharing

false_sharing: false_sharing.c
	gcc -pthread false_sharing.c -o false_sharing

no_false_sharing: false_sharing.c
	gcc -pthread -DNO_FALSE_SHARING false_sharing.c -o no_false_sharing

clean:
	rm false_sharing no_false_sharing
