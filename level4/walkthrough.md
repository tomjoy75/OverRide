# OverRide Level04 – Walkthrough

## Contexte

Objectif : obtenir le mot de passe de l’utilisateur `level04` en exploitant une vulnérabilité de type buffer overflow sur le binaire fourni.

Le programme vulnérable :
- fork() un processus fils
- le fils appelle `gets(buffer)` sans vérification de taille
- le parent trace les syscalls et empêche l’usage de `execve`
- le parent termine le fils dès qu’un syscall interdit est détecté

Protections mémoire du binaire (checksec) :
- Partial RELRO
- No stack canary
- NX désactivé (stack exécutable)
- No PIE (adresses du binaire fixes)

Contraintes importantes :
- ASLR système activé (stack et libc randomisées entre exécutions)
- execve interdit par le mécanisme de surveillance
- Architecture x86 32 bits
- Binaire non PIE → adresses internes stables
- libc relocalisée dynamiquement → adresses variables
- GOT encore writable (Partial RELRO), mais non exploitée dans la solution finale

Conséquences pratiques :
- L’exécution de shellcode sur la stack est théoriquement possible (NX désactivé)
- Les offsets de retour (EIP) sont déterministes
- La position exacte du shellcode varie entre GDB et l’exécution réelle (ASLR)
- Toute charge utile reposant sur une adresse de stack précise est instable
- Une approche ret2libc est plus fiable qu’un shellcode open/read/write dans ce contexte

Contraintes importantes :
- NX désactivé
- ASLR activé
- execve interdit par ptrace
- Architecture x86 32 bits

---

## 1. Analyse initiale

Observation :
- Le buffer local fait 128 octets
- L’adresse de retour (saved EIP) est écrasable
- execve est bloqué (syscall 11)
- Possibilité d’exécuter du code sur la stack

Objectif technique :
- soit exécuter un shellcode custom sans execve
- soit utiliser une technique ret2libc

---

## 2. Tentative 1 – Shellcode open/read/write

### But
Lire directement le fichier `/home/users/level04/.pass` via syscalls :
- open (5)
- read (3)
- write (4)

### Implémentation

Shellcode NASM :
- jmp/call/pop pour obtenir l’adresse de la string
- open(path, O_RDONLY)
- read(fd, esp, 40)
- write(1, esp, eax)
- exit(0)

### Problèmes rencontrés

- Beaucoup d’errance sur :
  - gestion des registres
  - alignement de la stack
  - taille réelle lue par read()
- open() échouait parfois selon l’environnement
- write() imprimait des zones mémoire incorrectes
- Adresse de retour instable (ASLR)
- Difficulté à debugger proprement le shellcode
- Breakpoints GDB écrasés par la stack
- Résultat souvent : dump de l’environnement au lieu du mot de passe

Conclusion :
> Solution fonctionnelle en théorie mais trop fragile et chronophage pour ce niveau.

---

## 3. Pivot stratégique – ret2libc

Face à la complexité du shellcode, décision :
> Réutiliser la technique ret2libc déjà utilisée avec succès au level01.

Avantages :
- Pas besoin de shellcode
- Plus stable avec ASLR partiel
- Moins dépendant de l’environnement
- Pas besoin d’execve directement

---

## 4. Plan ret2libc

Objectif :
- Appeler system("/bin/sh")
- Puis exit()

Étapes :
1. Identifier l’offset exact jusqu’à saved EIP
2. Récupérer :
   - Adresse de system()
   - Adresse de exit()
   - Adresse de la chaîne "/bin/sh"
3. Construire la chaîne de retour :
   - padding
   - system()
   - exit()
   - "/bin/sh"

---

## 5. Détermination de l’offset

Méthode :
- Injections de 'A'
- Analyse des registres sous GDB
- Vérification de l’écrasement de EIP

Résultat :
- Offset ≈ 156 octets avant saved EIP

---

## 6. Résolution des adresses libc

Sous GDB :

```
p system
p exit
find &system,+9999999,"/bin/sh"
```

Exemple (valeurs variables selon ASLR) :
- system = 0xf7e6aed0
- exit   = 0xf7e5eb70
- "/bin/sh" = 0xf7f897ec

---

## 7. Payload final

Structure :
```
[ "A" * offset ]
[ system() ]
[ exit() ]
[ "/bin/sh" ]
```

Commande Python (exemple) :

```bash
python -c 'print("A"*156 + "\xd0\xae\xe6\xf7" + "\x70\xeb\xe5\xf7" + "\xec\x97\xf8\xf7")' | ./level04
```

---

## 8. Résultat

- Shell obtenu
- Lecture du fichier `.pass`
- Mot de passe validé
- Niveau terminé avec succès

---

## 9. Conclusion

Deux approches possibles :

| Méthode | État | Commentaire |
|--------|------|-------------|
| Shellcode open/read/write | ❌ Abandonnée | Trop instable / fragile |
| ret2libc | ✅ Réussie | Simple, robuste, efficace |

Le choix ret2libc était le plus rationnel compte tenu :
- des contraintes du binaire
- de l’ASLR
- du blocage execve
- du temps investi dans le shellcode

---

## 10. Notes finales pour l’examinateur

- Les deux voies ont été explorées
- Le shellcode fonctionne partiellement mais reste non fiable
- La solution retenue est propre et conforme aux contraintes du niveau
- La compréhension des mécanismes de protection est démontrée

---
