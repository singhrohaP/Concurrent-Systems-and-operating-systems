// pthreads.pml

// Task: modify lock, unlock, wait and signal to do the correct thing.

mtype = { unlocked, locked } ;

typedef mutexData {
  mtype mstate;
  int mid;
}


typedef condvarData {
  bool dummy;
}

mutexData mtx;

condvarData cvars[2];
#define PRODCONDVAR 0
#define CONSCONDVAR 1

inline initsync() {
  mtx.mstate = unlocked;
  cvars[0].dummy = true;
  cvars[1].dummy = true;
}

// pthread_mutex_lock(&m);
inline lock(m) {
  printf("@@@ %d LOCKING : state is %e\n",_pid,m.mstate)
  atomic{(m.mstate==unlocked) -> m.mstate=locked; m.mid= _pid}
  printf("@@@ %d LOCKED : state is %e\n",_pid,m.mstate)
}

// pthread_mutex_unlock(&m);
inline unlock(m) {
  printf("@@@ %d UNLOCKING : state is %e\n",_pid,m.mstate)
  // will need code here
  atomic{(m.mid==_pid); m.mstate = unlocked; m.mid = 0}
  printf("@@@ %d UNLOCKED : state is %e\n",_pid,m.mstate)
}

// pthread_cond_wait(&c,&m);
inline wait(c,m) {
  printf("@@@ %d WAIT for cond[%d]=%d with mutex=%e\n",_pid,
         c,cvars[c].dummy,m.mstate)
  // will need code here
  unlock(m);
  do
  ::cvars[c].dummy == true -> break;
  od
  lock(m);
  printf("@@@ %d DONE with cond[%d]=%d with mutex=%e\n",_pid,
         c,cvars[c].dummy,m.mstate)
}

// pthread_cond_signal(&c);
inline signal(c) {
  printf("@@@ %d SIGNAL cond[%d]=%d\n",_pid,c,cvars[c].dummy)
  // will need code here
  if 
  :: (!bfull && !bempty) ->  cvars[c].dummy = true; cvars[1-c].dummy = true;
  :: (bfull) -> cvars[PRODCONDVAR].dummy = false; cvars[CONSCONDVAR].dummy = true;
  :: (bempty) -> cvars[PRODCONDVAR].dummy = true; cvars[CONSCONDVAR].dummy = false;
  fi
  printf("@@@ %d SIGNALLED cond[%d]=%d\n",_pid,c,cvars[c].dummy)
}
