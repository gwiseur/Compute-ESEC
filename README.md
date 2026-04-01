# Compute-ESEC : une fonction pour générer la classification ESEC appliquée au contexte belge

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
  
  ## Un exemple à partir de l'enquête sur les Forces de Travail
  
      # =============================================================================
      # PRÉPARATION DES VARIABLES POUR ESeC — EFT 2024
      # =============================================================================
      
      # ── 0. Variable "en emploi" (champ ESeC) ───────────────────────────────────────
      eft_2024$EMPLOI <- ifelse(eft_2024$MAINSTAT == 1, 1, 0)
      
      # ── 1. ISCO à 2 chiffres (CRITIQUE) ────────────────────────────────────────────
      # Conversion en numérique pour assurer la compatibilité avec compute_esec08()
      
      eft_2024$ISCO2D <- as.numeric(as.character(eft_2024$ISCO2D))
      
      # ── 2. Statut d'emploi (salarié / indépendant) ────────────────────────────────
      # STAPRO :
      # 1 = indépendant avec employés
      # 2 = indépendant sans employés
      # 3 = salarié
      # 4 = aide familial (traité comme salarié en ESeC)
      
      eft_2024$is_employee <- case_when(
        eft_2024$EMPLOI == 1 & eft_2024$STAPRO %in% c(1, 2) ~ 2,  # indépendants
        eft_2024$EMPLOI == 1 & eft_2024$STAPRO %in% c(3, 4) ~ 1,  # salariés
        TRUE ~ NA_real_
      )
      
      # ── 3. Taille de l'unité locale (indépendants uniquement) ─────────────────────
      # SIZEFIRM recodé en :
      # 1 = <10 travailleurs
      # 2 = ≥10 travailleurs
      
      eft_2024$nb_workers <- case_when(
        eft_2024$EMPLOI == 1 & eft_2024$SIZEFIRM %in% 1:9   ~ 1,
        eft_2024$EMPLOI == 1 & eft_2024$SIZEFIRM %in% 10:13 ~ 2,
        eft_2024$EMPLOI == 1 & eft_2024$SIZEFIRM == 14      ~ 1,
        eft_2024$EMPLOI == 1 & eft_2024$SIZEFIRM == 15      ~ 2,
        TRUE ~ NA_real_
      )
      
      # ── 4. Position de supervision (salariés uniquement) ──────────────────────────
      # SUPVISOR : 1 = superviseur
      
      eft_2024$is_supervisor <- ifelse(
        eft_2024$EMPLOI == 1 & eft_2024$SUPVISOR == 1, 1,
        ifelse(eft_2024$EMPLOI == 1, 2, NA)
      )
      
      # ── 5. Indépendants avec/sans employés ────────────────────────────────────────
      # Correction des incohérences type EWCS / SILC
      
      eft_2024$selfemp_withemployee <- case_when(
        eft_2024$EMPLOI == 1 & eft_2024$STAPRO == 1 ~ 1,  # avec employés
        eft_2024$EMPLOI == 1 & eft_2024$STAPRO == 2 ~ 2,  # sans employés
        TRUE ~ NA_real_
      )
      
      # ── 6. Calcul ESeC ────────────────────────────────────────────────────────────
      
      eft_2024 <- compute_esec08(
        data = eft_2024,
        ISCO2 = "ISCO2D",
        is_employee = "is_employee",
        is_supervisor = "is_supervisor",
        nb_workers = "nb_workers",
        selfemp_withemployee = "selfemp_withemployee",
        add_labels = TRUE
      )
      
      # ── 7. Vérifications ──────────────────────────────────────────────────────────
      
      table(eft_2024$ESEC08_lbl, useNA = "always")
