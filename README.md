# Compute-ESEC : une fonction pour générer la classification ESEC appliquée au contexte belge

La fonction `compute_esec08()` construit le schéma de classe ESeC 08 à partir
de quatre variables d'entrée :
  - la profession codée en ISCO à 2 chiffres,
  - le statut d'emploi (salarié / indépendant),
  - la taille de l'unité locale (pour les indépendants),
  - la position de supervision/encadrement (pour les salariés).

Elle retourne le data.frame original enrichi de trois nouvelles colonnes :
  empstat      — statut d'emploi combiné (4 catégories)
  ESEC08       — classe ESeC numérique (1–9 ou -99)
  ESEC08_lbl   — classe ESeC sous forme de facteur étiqueté (optionnel)

