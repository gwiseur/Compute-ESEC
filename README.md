# Compute-ESEC : une fonction pour générer la classification ESEC appliquée au contexte belge

1. INTRODUCTION

La fonction `compute_esec08()` construit le schéma de classe ESeC 08 à partir
de variables d'entrée harmonisées :
  - la profession codée en ISCO à 2 chiffres,
  - le statut d'emploi (salarié / indépendant),
  - la taille de l'unité locale (pour les indépendants),
  - la position de supervision/encadrement (pour les salariés),
  - la présence ou non de salariés pour les indépendants.

Elle retourne le data.frame original enrichi de trois nouvelles colonnes :
  empstat      — statut d'emploi combiné (4 catégories)
  ESEC08       — classe ESeC numérique (1–9 ou -99)
  ESEC08_lbl   — classe ESeC sous forme de facteur étiqueté (optionnel)

Cette fonction implémente les règles de classification ESeC 2008 sans inclure
les étapes de préparation spécifiques à certaines bases de données (ex. EU-SILC).

2. UTILISATION

  data <- compute_esec08(
    data,
    ISCO2                 = "nom_variable_isco2",
    is_employee           = "nom_variable_statut",
    nb_workers            = "nom_variable_taille",
    is_supervisor         = "nom_variable_supervision",
    selfemp_withemployee  = "nom_variable_independants",
    active_var            = NULL,    # optionnel
    add_labels            = TRUE,    # optionnel, TRUE par défaut
    suffix                = ""       # optionnel, "" par défaut
  )

3. PARAMÈTRES

  data          (data.frame, obligatoire)
                Le jeu de données contenant les variables d'entrée.

  ISCO2         (character, obligatoire)
                Nom de la colonne contenant le code ISCO-08 à 2 chiffres.
                Valeurs attendues : entiers de 1 à 96.
                Remarque : les codes à 1 chiffre (grands groupes) sont
                également acceptés.

  is_employee   (character, obligatoire)
                Nom de la colonne indiquant le statut dans l'emploi.
                Codage attendu :
                  1 = salarié (employé)
                  2 = indépendant (travailleur pour son propre compte)

  nb_workers    (character, obligatoire)
                Nom de la colonne indiquant la taille de l'unité locale.
                Codage attendu :
                  1 = moins de 10 travailleurs
                  2 = 10 travailleurs ou plus
                IMPORTANT : cette variable n'est utilisée que pour les
                indépendants (is_employee == 2). Pour les salariés, sa
                valeur peut être NA sans incidence sur le résultat.

  is_supervisor (character, obligatoire)
                Nom de la colonne indiquant si la personne encadre d'autres
                travailleurs.
                Codage attendu :
                  1 = superviseur / encadrant
                  2 = non-superviseur
                IMPORTANT : cette variable n'est utilisée que pour les
                salariés (is_employee == 1). Pour les indépendants, sa
                valeur peut être NA sans incidence sur le résultat.

  selfemp_withemployee (character, obligatoire)
                Nom de la colonne indiquant si un indépendant emploie
                du personnel.
                Codage attendu :
                  1 = avec employés
                  2 = sans employés
                Cette variable est utilisée uniquement pour les indépendants.
                Elle permet de corriger les incohérences fréquentes entre :
                  - la taille de l’unité locale (nb_workers),
                  - et le fait d’avoir effectivement des salariés.
                En cas de contradiction, cette variable est prioritaire.

  active_var    (character, optionnel, défaut = NULL)
                Nom d’une variable indiquant si l’individu appartient à la
                population active.
                Codage attendu :
                  1 = actif (occupé ou chômeur)
                  0 = inactif
                Si fourni, les individus codés 0 sont affectés à la valeur
                -97 (hors population cible).

  add_labels    (logical, optionnel, défaut = TRUE)
                Si TRUE, ajoute la colonne `ESEC08_lbl` contenant un facteur
                R avec les libellés de classe en français.

  suffix        (character, optionnel, défaut = "")
                Suffixe ajouté aux noms des colonnes créées. Utile pour
                comparer deux versions du schéma sur le même jeu de données.
                Exemple : suffix = "_v2" → colonnes empstat_v2, ESEC08_v2,
                ESEC08_lbl_v2.

4. VALEUR RETOURNÉE

  Le data.frame `data` original avec les colonnes supplémentaires suivantes
  (les noms peuvent varier selon `suffix`) :

  empstat
    Facteur à 4 niveaux résumant la situation combinée :
      se10+   indépendant avec 10 travailleurs ou plus dans l'unité locale
      se<=10  indépendant avec moins de 10 travailleurs
      sup     salarié occupant un poste de supervision / d'encadrement
      emp     salarié sans fonction d'encadrement

  ESEC08
    Entier. Classe ESeC 08 :
      1  Dirigeants, professions libérales et intellectuelles
      2  Professions intermédiaires et techniques qualifiées
      3  Employés qualifiés
      4  Petits indépendants (hors agriculture)
      5  Agriculteurs
      6  Contre-maîtres et techniciens peu qualifiés
      7  Employés peu qualifiés : commerce et service
      8  Ouvriers qualifiés
      9  Agents d'entretien, manœuvres, livreurs
     -99 Non classifiable (information manquante ou code ISCO non affecté)
     -97 Hors population cible (inactifs, si active_var est utilisé)

  ESEC08_lbl  (uniquement si add_labels = TRUE)
    Facteur R reprenant les libellés ci-dessus. Les niveaux -99 et -97
    sont étiquetés "NA".
