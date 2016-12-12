#include <pthread.h>
#include <stdlib.h>

struct foo {
  int x;
#ifdef NO_FALSE_SHARING
  char padding[128];
#endif
  int y;
};

static struct foo f;

/* The two following functions are running concurrently: */

void *sum_a(void __attribute__((unused))*_) {
  volatile int r;
  int s = 0;
  int i;
  for (i = 0; i < 1000000000; ++i)
    s += f.x;
  r = s;
}

void *inc_b(void __attribute__((unused))*_) {
  int i;
  for (i = 0; i < 1000000000; ++i)
    ++f.y;
}

void _free(void *p);
int main() {
  int i;
  pthread_t threads[2];
  pthread_create(&threads[0], NULL, sum_a, NULL);
  pthread_create(&threads[1], NULL, inc_b, NULL);
  for (i = 0; i < 2; i++)
    pthread_join(threads[i], NULL);
}

void _free(void *_p) {
  void **p = _p;
  if (p)
    free(*p);
}
