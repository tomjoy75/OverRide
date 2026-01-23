#include <stdlib.h>
#include <stdio.h>

int	main(int argc, char **argv)
{
	(void)argc;
	printf("%p\n", getenv(argv[1]));
	return 0;
}