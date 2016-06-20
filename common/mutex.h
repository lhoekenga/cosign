#include <pthread.h>

typedef pthread_mutex_t *cosign_mutex_t;

cosign_mutex_t create_mutex();
void lock_mutex(cosign_mutex_t);
void unlock_mutex(cosign_mutex_t);
void destroy_mutex(cosign_mutex_t);

