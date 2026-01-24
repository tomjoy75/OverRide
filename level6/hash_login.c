#include <stdio.h>
#include <string.h>

int main(int argc, char **argv)
{
    int i;
    int hash;
    int len;
	char *s;

	if (argc < 2){
		printf("format error: ./hash_login login\n");
		return 1;
	}
	s = argv[1];

    s[strcspn(s, "\n")] = '\0';

    // Longueur max 32
    len = strnlen(s, 32);

    // Login trop court → échec
    if (len <= 5){
		printf("login too small (6 char min.)\n");
        return 1;
	}

    /* Anti-debug
    if (ptrace(PTRACE_TRACEME, 0, 1, 0) == -1)
    {
        puts("\033[32m.---------------------------.");
        puts("\033[31m| !! TAMPERING DETECTED !!  |");
        puts("\033[32m'---------------------------'");
        return 1;
    }*/

    // Initialisation du hash
    hash = (s[3] ^ 0x1337) + 6221293;

    // Boucle de hash
    for (i = 0; i < len; i++)
    {
        // Refuse caractères de contrôle
        if (s[i] <= 31){
			printf("Unauthorized caracter.\n");
            return 1;
		}

        hash += (hash ^ (unsigned int)s[i]) % 0x539;
    }

    // Compare le hash calculé avec le serial fourni
    printf("hash : %d\n", hash);
	return 0;
}

