# Compute-ESEC : une fonction pour générer la classification ESEC appliquée au contexte belge

INTRODUCTION

La fonction `compute_esec08()` construit le schéma de classe ESeC 08 à partir
de variables d'entrée harmonisées :
  - la profession codée en ISCO à 2 chiffres,
  - le statut d'emploi (salarié / indépendant) : **Attention : dans ESEC, les aidants (_family workers_) sont considérés comme des salariés**
  - la taille de l'unité locale (pour les indépendants),
  - la position de supervision/encadrement (pour les salariés),
  - la présence ou non de salariés pour les indépendants.

Elle retourne le data.frame original enrichi de trois nouvelles colonnes :
  empstat      — statut d'emploi combiné (4 catégories)
  ESEC08       — classe ESeC numérique (1–9 ou -99)
  ESEC08_lbl   — classe ESeC sous forme de facteur étiqueté (optionnel)

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

     # Un exemple à partir de l'enquête sur les Forces de Travail

     eft_2024$is_employee <- case_when(eft_2024$STAPRO == 1 | 
                                  eft_2024$STAPRO == 2  ~ 2,
                                  eft_2024$STAPRO == 3 | 
                                  eft_2024$STAPRO == 4 ~ 1)

     eft_2024$nb_workers <- ifelse(eft_2024$SIZEFIRM < 10, 1, 2)

     eft_2024$is_supervisor <- ifelse(eft_2024$SUPVISOR == 1, 1, 2)

     eft_2024$selfemp_withemployee <- ifelse(eft_2024$STAPRO == 1, 1, 2)

     eft_2024 <- compute_esec08(data = eft_2024,
                        ISCO2 = "ISCO2D",
                        is_employee = "is_employee",
                        is_supervisor = "is_supervisor",
                        nb_workers = "nb_workers",
                        selfemp_withemployee = "selfemp_withemployee",
                        add_labels = TRUE)
