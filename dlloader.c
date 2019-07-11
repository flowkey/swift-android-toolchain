#include <stdio.h>
#include <dlfcn.h>

int main(int argc, char *argv[]) {
  dlerror();
  if (!dlopen(argv[1], RTLD_NOW))
    perror(dlerror());
  return 0;
}
