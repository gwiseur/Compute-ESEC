# ==============================================================================
# compute_esec08.R
# Fonction de construction du schéma de classe ESeC 2008 (ESEG)
# ==============================================================================

#' Calcule le schéma de classe ESeC 08 (European Socio-economic Classification)
#'
#' @param data        data.frame contenant les variables nécessaires.
#' @param ISCO2       Nom (chaîne) de la variable ISCO à 2 chiffres dans `data`.
#'                    Doit être numérique (entiers 1–96).
#' @param is_employee Nom (chaîne) de la variable statut d'emploi dans `data`.
#'                    Codage : 1 = salarié, 2 = indépendant. 
#'                    Attention : dans ESEC, les aidants (family workers) sont considérés comme des salariés
#' @param nb_workers  Nom (chaîne) de la variable taille de l'unité locale dans `data`.
#'                    Codage : 1 = moins de 10 travailleurs, 2 = 10 travailleurs ou plus.
#'                    Utilisée uniquement pour les indépendants.
#' @param is_supervisor Nom (chaîne) de la variable position managériale dans `data`.
#'                    Codage : 1 = superviseur/encadrant, 2 = non-superviseur.
#'                    Utilisée uniquement pour les salariés.
#' @param selfemp_withemployee Nom (chaîne) de la variable indépendant sans employé dans `data`.
#'                    Codage : 1 = avec employé, 2 = sans employé.
#'                    Cette variable est utile en cas de divergence entre le nombre de travailleurs
#'                    repris dans nb_workers et le fait d'avoir ou non des salariés.
#'                    Si la variable = 2, permet l'assignation des indépendants travaillant seul
#'                    comme indépendants avec <10 salariés (empstat).
#'                    Utilisée uniquement pour les indépendants. (ex. selfemp_withemployee dans EWCS ou PL040 == 2 dans SILC)                   
#' @param add_labels  Logique. Si TRUE (défaut), ajoute une colonne `ESEC08_lbl`
#'                    avec les libellés de classe en français.
#' @param suffix      Suffixe optionnel (chaîne) ajouté aux noms des nouvelles
#'                    colonnes (ex. "_v2"). Défaut : "".
#'
#' @return  Le data.frame `data` enrichi des colonnes suivantes :
#'   \describe{
#'     \item{empstat}{Statut d'emploi combiné (1–4) :
#'       1 = indépendant >=10, 2 = indépendant <10,
#'       3 = salarié superviseur, 4 = salarié non-superviseur.}
#'     \item{ESEC08}{Classe ESeC (1–9, ou -99 si non classifiable).}
#'     \item{ESEC08_lbl}{Facteur libellé (si add_labels = TRUE).}
#'   }
#'
#' @examples
#' df <- data.frame(
#'   isco2       = c(11, 23, 52, 62, 81),
#'   emploi      = c(1, 1, 1, 2, 1),
#'   taille      = c(NA, NA, NA, 1, NA),
#'   encadrant   = c(1, 2, 2, NA, 2),
#'   withemployee = c(NA, NA, NA, 2, NA)
#' )
#' df <- compute_esec08(df,
#'                      ISCO2        = "isco2",
#'                      is_employee  = "emploi",
#'                      nb_workers   = "taille",
#'                      is_supervisor = "encadrant",
#'                      selfemp_withemployee = "withemployee")
#' table(df$ESEC08_lbl, useNA = "always")

compute_esec08 <- function(data,
                           ISCO2,
                           is_employee,
                           nb_workers,
                           is_supervisor,
                           selfemp_withemployee,
                           add_labels = TRUE,
                           suffix     = "") {
  
  # ── 0. Vérifications ────────────────────────────────────────────────────────
  stopifnot(is.data.frame(data))
  for (v in c(ISCO2, is_employee, nb_workers, is_supervisor, selfemp_withemployee)) {
    if (!v %in% names(data))
      stop(sprintf("Variable '%s' introuvable dans data.", v))
  }
  isco   <- data[[ISCO2]]
  emp    <- data[[is_employee]]    # 1 = salarié, 2 = indépendant
  taille <- data[[nb_workers]]     # 1 = <10, 2 = >=10
  spv    <- data[[is_supervisor]]  # 1 = superviseur, 2 = non-superviseur
  withemployee <- data[[selfemp_withemployee]] # 1 = indépendant avec salariée, 2 = indépendant seul
  
  n <- nrow(data)
  
  # ── 1. empstat : combinaison statut × taille × supervision ─────────────────
  empstat <- rep(NA_integer_, n)
  
  empstat[emp == 2 & taille == 2]  <- 1L  # indépendant >=10
  empstat[emp == 2 & taille == 1]  <- 2L  # indépendant <10
  empstat[emp == 1 & spv   == 1]   <- 3L  # salarié superviseur
  empstat[emp == 1 & spv   == 2]   <- 4L  # salarié non-superviseur
  empstat[withemployee == 2] <- 2L # indépendant <10
  
  # ── 2. ESEC08 : affectation de classe ───────────────────────────────────────
  esec <- isco  # on part de l'ISCO-2 comme valeur de départ
  
  ## Indépendants >=10 salariés (empstat == 1) ──────────────────────────────
  s <- empstat == 1 & !is.na(empstat)
  
  esec[s & isco %in% c(1,10,11,12,13,14,20,21,22,23,24,25,26,
                       30,31,32,33,34,35,40,41,42,43,44,
                       50,51,52,53,60,61,62,70,71,72,73,74,75,
                       80,81,82,83,90,91,92,93,94,95,96)] <- 1L
  esec[s & isco %in% c(2,3,54)]  <- 3L
  esec[s & isco == 63]           <- 5L
  
  ## Indépendants <10 salariés (empstat == 2) ───────────────────────────────
  s <- empstat == 2 & !is.na(empstat)
  
  esec[s & isco %in% c(1,11,20,21,24,26)]                              <- 1L
  esec[s & isco %in% c(10,12,13,14,30,34,35,40,41,42,43,44,
                       50,51,52,53,70,71,72,73,74,75,
                       80,81,82,83,90,91,94,95,96)]                   <- 4L
  esec[s & isco %in% c(60,61,62,63,92,93)]                             <- 5L
  esec[s & isco %in% c(2,3,54)]                                        <- 3L
  esec[s & isco %in% c(22,23,25,31,32,33)]                             <- 2L
  
  ## Salariés superviseurs (empstat == 3) ───────────────────────────────────
  s <- empstat == 3 & !is.na(empstat)
  
  esec[s & isco %in% c(1,10,11,12,13,20,21,24,26)]                    <- 1L
  esec[s & isco %in% c(2,3,14,22,23,25,30,31,32,33,34,35,40,41,43)]  <- 2L
  esec[s & isco == 63]                                                 <- 5L
  esec[s & isco %in% c(42,44,50,51,52,53,54,60,61,62,
                       70,71,72,73,74,75,80,81,82,83,
                       90,91,92,93,94,95,96)]                         <- 6L
  
  ## Salariés non-superviseurs (empstat == 4) ───────────────────────────────
  s <- empstat == 4 & !is.na(empstat)
  
  esec[s & isco %in% c(1,10,11,12,13,20,21,24,26)]                    <- 1L
  esec[s & isco %in% c(2,3,30,34,35,40,41,43,44)]                     <- 3L
  esec[s & isco %in% c(14,22,23,25,31,32,33)]                         <- 2L
  esec[s & isco == 63]                                                 <- 5L
  esec[s & isco %in% c(42,50,51,52,53,54)]                            <- 7L
  esec[s & isco %in% c(60,61,62,70,71,72,73,74,75)]                   <- 8L
  esec[s & isco %in% c(80,81,82,83,90,91,92,93,94,95,96)]             <- 9L
  
  # ── 3. Cas non classifiables → -99 ─────────────────────────────────────────
  esec[is.na(esec)]    <- -99L
  esec[esec >= 10]     <- -99L   # codes ISCO non affectés par les règles ci-dessus
  
  # ── 4. Ajout des colonnes au data.frame ─────────────────────────────────────
  col_empstat <- paste0("empstat", suffix)
  col_esec    <- paste0("ESEC08",  suffix)
  col_lbl     <- paste0("ESEC08_lbl", suffix)
  
  data[[col_empstat]] <- factor(empstat,
                                levels = 1:4,
                                labels = c("se10+", "se<=10", "sup", "emp"))
  
  data[[col_esec]] <- esec
  
  # ── 5. Étiquettes (optionnel) ───────────────────────────────────────────────
  if (add_labels) {
    data[[col_lbl]] <- factor(
      esec,
      levels = c(1, 2, 3, 4, 5, 6, 7, 8, 9, -99, -98, -97),
      labels = c(
        "Dirigeants, professions libérales et intellectuelles",   # 1
        "Professions intermédiaires et techniques qualifiées",     # 2
        "Employés qualifiés",                                      # 3
        "Petits indépendants (hors agriculture)",                  # 4
        "Agriculteurs",                                            # 5
        "Contre-maîtres et techniciens peu qualifiés",            # 6
        "Employés peu qualifiés : commerce et service",            # 7
        "Ouvriers qualifiés",                                      # 8
        "Agents d'entretien, manœuvres, livreurs",                # 9
        "NA",                                                      # -99
        "NA",                                                      # -98
        "NA"                                                       # -97
      )
    )
  }
  
  return(data)
}
