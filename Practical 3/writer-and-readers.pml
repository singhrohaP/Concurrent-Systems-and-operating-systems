// Below here is (c) 2022 Andrew Butterfield, Trinity College Dublin.

#if defined(ZERO)
  #include "pthreads0.pml"
#elif defined(ONE)
  #include "pthreads1.pml"
#elif defined(TWO)
  #include "pthreads2.pml"
#else /* no number specified */
  #include "pthreads.pml"
#endif

// Code below here is a correct model of producer-consumer behaviour.
// DO NOT MODIFY

// ====== Buffer Model ========================================================

#define BUFSIZE 4
byte buffer[BUFSIZE];
byte in,out;
bool bfull,bempty;

inline zerobuffer() {
  in = 0;
  do
  :: in < BUFSIZE -> buffer[in] = 0; in++
  :: else -> in = 0; break
  od
  out = BUFSIZE-1;
  bfull = false; bempty = true;
  printf("buffer zeroed\n")
}

byte six;

inline showbuffer(){
  atomic{
    printf("@@@ %d BUFFER in:%d, out:%d, empty:%d, full:%d [|",_pid,in,out,bempty,bfull);
    six = 0;
    do
      :: six < BUFSIZE -> printf(" %d |",buffer[six]); six++;
      :: else -> printf("]\n"); break;
    od
  }
}

#define NEXT(i) ((i+1) % BUFSIZE)

inline insert(x) {
  assert(!bfull);
  buffer[in] = x;
  printf("@@@ %d INSERT buf[%d] := %d\n",_pid,in,x);
  bempty = false;
  bfull = (in == out);
  in = NEXT(in);
  showbuffer();
}

byte cout[2];

inline extract(cno) {
  assert(!bempty);
  out = NEXT(out);
  cout[cno] = buffer[out]; buffer[out] = 0;
  printf("@@@ %d EXTRACT cout[%d] := buf[%d] is %d\n",_pid,cno,out,cout[cno]);
  bfull = false;
  bempty = (NEXT(out) == in)
  showbuffer();
}


// ====== Producer Model ======================================================

inline produce(p) {
  lock(mtx);
  assert(mtx.mid == _pid);
  do
  :: !bfull -> break;
  :: else -> wait(PRODCONDVAR,mtx);
  od
  insert(p);
  progress_prod:
  signal(CONSCONDVAR);
  unlock(mtx);
}


#define REPEAT 7
proctype producer() {
  int p=1;
  do
  :: produce(p); p = p % REPEAT + 1
  // should generate 1,...,7,1,...,7,1,...,7,....
  od
}

// ====== Consumer Model ======================================================

inline consume(cno) {
  lock(mtx);
  assert(mtx.mid == _pid);
  do
  :: !bempty -> break;
  :: else -> wait(CONSCONDVAR,mtx);
  od
  extract(cno);
  progress_cons:
  signal(PRODCONDVAR);
  unlock(mtx);
}

proctype consumer(byte cno) {
  do
  :: consume(cno)
  od
}

// ====== MAINLINE ============================================================

init {
  int z;

  printf("A Model of pthreads\n")
  printf("\n Producer-Consumer example\n")
  zerobuffer()
  showbuffer()
  initsync()
  run producer()
  run consumer(0)
  run consumer(1)
}
