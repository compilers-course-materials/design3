#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

extern int our_code_starts_here() asm("our_code_starts_here");
extern void error() asm("error");
extern int print(int val) asm("print");
extern int equal(int val1, int val2) asm("equal");

const int TRUE = 0xFFFFFFFF;
const int FALSE = 0x7FFFFFFF;

int equal(int val1, int val2) {
  if(val1 == val2) { return TRUE; }
  else if(((val1 & 0x00000007) == 1) && ((val2 & 0x00000007) == 1)) {
    int* val1p = (int*) (val1 & 0xFFFFFFFE);
    int* val2p = (int*) (val2 & 0xFFFFFFFE);
    int count1 = *val1p;
    int count2 = *val2p;
    if(count1 != count2) { return FALSE; }

    for(int i = 1; i < count1 + 1; i += 1) {
      int elts_equal = equal(*(val1p + i), *(val2p + i));
      if(elts_equal == FALSE) { return FALSE; }
    }
    return TRUE;
  }
  else {
    return FALSE;
  }
}

void print_simple(int val) {
  if(val & 0x00000001 ^ 0x00000001) {
    printf("%d", val >> 1);
  }
  else if(val == 0xFFFFFFFF) {
    printf("true");
  }
  else if(val == 0x7FFFFFFF) {
    printf("false");
  }
  else if((val & 0x00000007) == 1) {
    printf("(");
    int* valp = (int*) (val & 0xFFFFFFFE);
    int count = *valp;
    for(int i = 1; i < count + 1; i += 1) {
      print_simple(*(valp + i));
      if(i < count) {
        printf(",");
      }
    }
    printf(")");
  }
  else {
    printf("Unknown value: %#010x", val);
  }
}

int print(int val) {
  print_simple(val);
  printf("\n");
  return val;
}

void error(int i) {
  if (i == 0) {
    fprintf(stderr, "Error: comparison operator got non-number");
  }
  else if (i == 1) {
    fprintf(stderr, "Error: arithmetic operator got non-number");
  }
  else if (i == 2) {
    fprintf(stderr, "Error: if condition got non-boolean");
  }
  else if (i == 3) {
    fprintf(stderr, "Error: Integer overflow");
  }
  else if (i == 4) {
    fprintf(stderr, "Error: not a tuple");
  }
  else if (i == 5) {
    fprintf(stderr, "Error: index too small");
  }
  else if (i == 6) {
    fprintf(stderr, "Error: index too large");
  }
  else {
    fprintf(stderr, "Error: Unknown error code: %d\n", i);
  }
  exit(i);
}

int main(int argc, char** argv) {
  int* HEAP = calloc(100000, sizeof (int));

  int result = our_code_starts_here(HEAP);
  print(result);
  return 0;
}

