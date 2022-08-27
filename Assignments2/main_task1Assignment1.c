#include <stdio.h>
#include <stdlib.h>

#define BITS 34 /*32bit=4bytes*/  /* maximal input size */

extern void assFunc(int x);

char c_checkValidity(int x){
 if(x>0)
  return 1;
return 0;
}
int main(int argc, char **argv) {
    char x[BITS];
    // taking user input string
    int num1 = atoi(fgets(x, BITS, stdin));     
    assFunc(num1);
    return 0;
}
