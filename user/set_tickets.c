#include "kernel/types.h"
#include "user/user.h"

int main(int argc, char *argv[])
{
  if (argc < 2)
  {
    fprintf(2, "Invalid System call!");
    exit(1);
  }

  set_tickets(atoi(argv[1]));
  exit(0);
}