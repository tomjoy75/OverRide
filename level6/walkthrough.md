RELRO           STACK CANARY      NX            PIE             RPATH      RUNPATH      FILE
Partial RELRO   Canary found      NX enabled    No PIE          No RPATH   No RUNPATH   /home/users/level06/level06
| Protection    | Signification             | Impact pour toi                                                         |
| ------------- | ------------------------- | ----------------------------------------------------------------------- |
| Partial RELRO | GOT partiellement protégé | Tu peux peut-être encore écraser certaines entrées GOT                  |
| Canary found  | Stack canary actif        | Les buffer overflows classiques sur la stack sont détectés              |
| NX enabled    | Stack non exécutable      | Tu **ne peux pas** exécuter de shellcode en stack                       |
| No PIE        | Binaire à adresses fixes  | Les adresses du binaire sont **prévisibles** (bon point pour l’exploit) |

Le code genere un hash a partir du login et le compare au serial
On copie l'algo de hashing dans un programme en C pour generer le hash (voir hash_login.c)

``` bash
➜  OverRide git:(main) ✗ ./hash_login username         
hash : 6234463
level06@OverRide:~$ ./level06 
***********************************
*		level06		  *
***********************************
-> Enter Login: username
***********************************
***** NEW ACCOUNT DETECTED ********
***********************************
-> Enter Serial: 6234463
Authenticated!
$ whoami
level07
```
