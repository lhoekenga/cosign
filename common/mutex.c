#include "mutex.h"

    cosign_mutex_t 
create_mutex(void)
{
  pthread_mutex_t *ret = (pthread_mutex_t *) malloc(sizeof(pthread_mutex_t));
  if (!ret) {
    perror( "malloc" );
  }

  pthread_mutex_init(ret, NULL);

  return ret;
}

void lock_mutex(cosign_mutex_t m)
{
  pthread_mutex_lock(m);
}

void unlock_mutex(cosign_mutex_t m)
{
  pthread_mutex_unlock(m);
}

void destroy_mutex(cosign_mutex_t m)
{
  pthread_mutex_destroy(m);
  free(m);
}
