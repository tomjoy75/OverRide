# Walkthrough – level03 (XOR + arithmétique)

## Étape 1 : Détermination de la clé XOR

Dans la fonction `decrypt`, on observe que le buffer final doit correspondre à la chaîne :

```
"Congratulations!"
```

Or, le buffer initial est la chaîne chiffrée suivante :

```
"Q}|u`sfg~sf{}|a3"
```

Chaque caractère du buffer est transformé par l’opération :

```c
buffer[i] ^= key;
```

L’objectif est donc de déterminer la **clé XOR** qui permet de transformer la chaîne chiffrée en la chaîne attendue.

---

### 🔑 Propriété fondamentale du XOR

Le XOR possède une propriété de réversibilité :

```
A ^ B = C
C ^ B = A
A ^ C = B
```

Dans notre cas :

```
key = ciphertext ^ plaintext
```

---

### 🔍 Calcul de la clé avec GDB

Il suffit de comparer **un seul caractère** de la chaîne chiffrée avec son équivalent en clair.

Exemple avec la première lettre :

- Ciphertext : 'Q'
- Plaintext  : 'C'

Dans GDB :

```gdb
(gdb) set $key = 'Q' ^ 'C'
(gdb) p $key
$17 = 18
```

La clé vaut donc :

```
key = 18 (0x12)
```

---

### ✅ Vérification sur d’autres caractères

On vérifie que cette clé est cohérente sur le reste de la chaîne :

```gdb
(gdb) p/c '}' ^ $key
$18 = 111 'o'
(gdb) p/c '|' ^ $key
$19 = 110 'n'
(gdb) p/c 'u' ^ $key
$20 = 103 'g'
(gdb) p/c '`' ^ $key
$21 = 114 'r'
```

Les résultats sont cohérents avec la chaîne cible **"Congratulations!"**.

👉 **La clé XOR est donc bien `18 (0x12)`**.

---

## Étape 2 : Calcul de l’entrée utilisateur

Dans la fonction `test`, on trouve la logique suivante :

```c
int diff = reference - user_input;
```

La clé XOR utilisée par `decrypt()` est précisément cette valeur `diff`.

On a donc :

```
diff = 18
reference = 322424845
```

Ce qui donne :

```
user_input = reference - diff
user_input = 322424845 - 18
user_input = 322424827
```

---

## Étape 3 : Exploitation

Exécution du binaire avec la valeur calculée :

```bash
./level03
***********************************
*		level03		**
***********************************
Password: 322424827
```

Résultat :

```bash
$ whoami
level04
```

---

## 🧠 Conclusion

- Le chiffrement utilisé est un **XOR sur un octet**
- Une seule paire *(ciphertext / plaintext)* suffit pour retrouver la clé
- La valeur demandée à l’utilisateur est un **entier**, pas une chaîne
- Toute la logique repose sur une **simple soustraction**

👉 Challenge basé sur :
- compréhension du XOR
- raisonnement inverse
- lecture attentive du pseudo-code
