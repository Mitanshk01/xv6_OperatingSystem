#include "kernel/types.h"
#include "user/user.h"

int main(int argc, char *argv[])
{
  if (argc < 3 || atoi(argv[1]) < 0 || atoi(argv[2]) < 0)
  {
    fprintf(2, "Invalid System Call\n");
    exit(1);
  }

  set_priority(atoi(argv[1]), atoi(argv[2]));
  exit(0);
}