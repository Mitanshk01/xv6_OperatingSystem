#include "kernel/types.h"
#include "kernel/param.h"
#include "kernel/stat.h"
#include "user/user.h"

int main(int argc, char *argv[])
{
  if (argc <= 2 || trace(atoi(argv[1])) < 0)
  {
    fprintf(2, "Invalid Command");
    exit(1);
  }

  exec(argv[2], &argv[2]);

  // myproc()->tracy = 0;

  exit(0);
}