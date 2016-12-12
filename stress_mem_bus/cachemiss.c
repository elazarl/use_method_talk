#include <argp.h>
#include <locale.h>
#include <pthread.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

#define L3CACHESIZE 4194000
#define _S(x) #x
#define S(x) _S(x)
int l3cachesize = L3CACHESIZE;
int L1CACHELINE = 131072;
int times = 100 * 1000;
int ncachelines = 1000;
int nthreads = 1;

#define arraysize(x) (sizeof(x) / sizeof(x[0]))
void _free(void *p);

static struct argp_option options[] = {
    {"times", 't', "ntimes", 0, "location of log file to save output to", 0},
    {"l3size", 'L', "cachesize", 0,
     "size of L3 cache on this machine, default " S(
         L3CACHESIZE) " check with lshw -C",
     0},
    {"ncaches", 'c', "ncachelines", 0, "how many cache lines should we touch",
     0},
    {"threads", 'T', "nthreads", 0,
     "How many concurrent threads should touch cache", 0},
    {.name = NULL},
};
static error_t parse_opt(int key, char *arg, struct argp_state *state);
void *touchcache(void *);
void *touchcache_infinite(void *);
static inline uint64_t atomic_xadd64(volatile uint64_t *ptr, uint64_t val);

int main(int argc, char **argv) {
  pthread_t *__attribute__((cleanup(_free))) threads;
  int i;
  setlocale(LC_ALL, "");
  struct argp argp = {.options = options,
                      .parser = parse_opt,
                      .doc = "touches ntimes times a memory byte, each time "
                             "from different L3 cache"};
  argp_parse(&argp, argc, argv, 0, 0, NULL);
  printf("Using %'d cachelines, touching memory %'d times L3 Cache size %'d, "
         "%'d threads\n",
         ncachelines, times, l3cachesize, nthreads);
  threads = calloc(sizeof(threads[0]), nthreads);
  if (times == -1) {
    for (i = 1; i < nthreads; i++)
      pthread_create(&threads[i], NULL, touchcache_infinite, NULL);
    touchcache_infinite(NULL);
  } else {
    for (i = 1; i < nthreads; i++)
      pthread_create(&threads[i], NULL, touchcache, NULL);
    touchcache(NULL);
  }
  for (i = 1; i < nthreads; i++)
    pthread_join(threads[i], NULL);
}

#define IX(x, y) (x * ncachelines + y)
void *touchcache(__attribute__((unused)) void *_) {
  int i;
  volatile char *__attribute__((cleanup(_free))) cacheline =
      malloc((uint64_t)l3cachesize * ncachelines);
  int ntimes = times;
  while (ntimes > 0)
    for (i = 0; i < ncachelines; i++)
      cacheline[IX(i, 0)] = 0, ntimes--;
  return NULL;
}

void *touchcache_infinite(__attribute__((unused)) void *_) {
  int i;
  volatile char *__attribute__((cleanup(_free))) cacheline =
      malloc((uint64_t)l3cachesize * ncachelines);
  while (1)
    for (i = 0; i < ncachelines; i++)
      atomic_xadd64((void *)(cacheline + IX(i, 0)), 1);
  return NULL;
}

bool parse_int(struct argp_state *state, int *result, char *arg);

static error_t parse_opt(int key, char *arg, struct argp_state *state) {
  switch (key) {
  case 't':
    if (!parse_int(state, &times, arg))
      return ARGP_ERR_UNKNOWN;
    break;
  case 'L':
    if (!parse_int(state, &l3cachesize, arg))
      return ARGP_ERR_UNKNOWN;
    break;
  case 'c':
    if (!parse_int(state, &ncachelines, arg))
      return ARGP_ERR_UNKNOWN;
    break;
  case 'T':
    if (!parse_int(state, &nthreads, arg))
      return ARGP_ERR_UNKNOWN;
    break;
  default:
    return ARGP_ERR_UNKNOWN;
  }
  return 0;
}

bool parse_int(struct argp_state *state, int *result, char *_arg) {
  int i;
  int j = 0;
  char *__attribute__((cleanup(_free))) arg = malloc(strlen(_arg) + 1);
  /* remove commas */
  for (i = 0; i < (int)strlen(_arg); i++)
    if (_arg[i] != ',')
      arg[j++] = _arg[i];
  arg[j] = '\0';
  char *endp;
  int rv = strtol(arg, &endp, 10);
  if (*arg == '\0' || *endp != '\0') {
    argp_failure(state, 2, errno, "a number is expected, instead '%s'", arg);
    return false;
  }
  *result = rv;
  return true;
}

void _free(void *_p) {
  void **p = _p;
  if (p)
    free(*p);
}

static inline uint64_t atomic_xadd64(volatile uint64_t *ptr, uint64_t val) {
  __asm volatile("lock ; xaddq %0, (%1)" : "+r"(val) : "r"(ptr) : "memory");
  return val;
}
