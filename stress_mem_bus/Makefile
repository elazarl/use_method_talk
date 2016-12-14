ifeq ($(SANITIZE),y)
SAN:=-fsanitize=address -fsanitize=undefined
endif
CFLAGS=$(SAN) -O2 -g3 -pthread -Wall -Wextra

cachemiss:

.PHONY: clean
clean:
	rm -f cachemiss
