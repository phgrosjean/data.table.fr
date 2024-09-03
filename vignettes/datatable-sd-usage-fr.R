## ----echo = FALSE, message = FALSE----------------------------------------------------------------
require(data.table)
knitr::opts_chunk$set(
  comment = "#",
  error = FALSE,
  tidy = FALSE,
  cache = FALSE,
  collapse = TRUE,
  out.width = '100%',
  dpi = 144
)
.old.th = setDTthreads(1)

## ----download_lahman------------------------------------------------------------------------------
load('Teams.RData')
setDT(Teams)
Teams

load('Pitching.RData')
setDT(Pitching)
Pitching

## ----plain_sd-------------------------------------------------------------------------------------
Pitching[ , .SD]

## ----plain_sd_is_table----------------------------------------------------------------------------
identical(Pitching, Pitching[ , .SD])

## ----simple_sdcols--------------------------------------------------------------------------------
# W: Wins; L: Losses; G: Games
Pitching[ , .SD, .SDcols = c('W', 'L', 'G')]

## ----identify_factors-----------------------------------------------------------------------------
# teamIDBR: Team ID utilisé par le site de référence du baseball
# teamIDlahman45: Team ID utilisé dans la base de données Lahman v4.5
# teamIDretro: Team ID utilisé par Retrosheet
fkt = c('teamIDBR', 'teamIDlahman45', 'teamIDretro')
# confirmer que ce sont bien des `character`
str(Teams[ , ..fkt])

## ----assign_factors-------------------------------------------------------------------------------
Teams[ , names(.SD) := lapply(.SD, factor), .SDcols = patterns('teamID')]
# imprime la première colonne pour montrer que c’est correct
head(unique(Teams[[fkt[1L]]]))

## ----sd_as_logical--------------------------------------------------------------------------------
fct_idx = Teams[, which(sapply(.SD, is.factor))] # numéros de colonnes (changement de classe)
str(Teams[[fct_idx[1L]]])
Teams[ , names(.SD) := lapply(.SD, as.character), .SDcols = is.factor]
str(Teams[[fct_idx[1L]]])

## ----sd_patterns----------------------------------------------------------------------------------
Teams[ , .SD, .SDcols = patterns('team')]
Teams[ , names(.SD) := lapply(.SD, factor), .SDcols = patterns('team')]

## ----sd_for_lm, cache = FALSE, fig.cap="Ajustement OLS pour le coefficient W, diverses spécifications, représentées par des barres de couleurs distinctes."----
# ceci génère une liste des 2^k variables extra possibles
#   pour les modèles de forme ERA ~ G + (...)
extra_var = c('yearID', 'teamID', 'G', 'L')
models = unlist(
  lapply(0L:length(extra_var), combn, x = extra_var, simplify = FALSE),
  recursive = FALSE
)

# voici 16 couleurs distinctes, choisis dans une liste de 20 ici:
#   https://sashat.me/2017/01/11/list-of-20-simple-distinct-colors/
col16 = c('#e6194b', '#3cb44b', '#ffe119', '#0082c8',
          '#f58231', '#911eb4', '#46f0f0', '#f032e6',
          '#d2f53c', '#fabebe', '#008080', '#e6beff',
          '#aa6e28', '#fffac8', '#800000', '#aaffc3')

par(oma = c(2, 0, 0, 0))
lm_coef = sapply(models, function(rhs) {
  # utilisation de ERA ~ . et data = .SD, puis variation de
  #   quelles colonnes sont incluses dans .SD, ce qui nous permet
  #   de varier les iterations sur les 16 modèles facilement.
  #   coef(.)['W'] extrait le coefficient W de chaque modèle ajusté
  Pitching[ , coef(lm(ERA ~ ., data = .SD))['W'], .SDcols = c('W', rhs)]
})
barplot(lm_coef, names.arg = sapply(models, paste, collapse = '/'),
        main = 'Wins Coefficient\nWith Various Covariates',
        col = col16, las = 2L, cex.names = 0.8)

## ----conditional_join-----------------------------------------------------------------------------
# pour exclure les pichers ayant des performances exceptionnelles dans peu de jeux,
#   faire un sous-ensemble ; ensuite définir le rang des pichers dans leur équipe chaque
#   année (en général, nous nous focaliserions sur 'ties.method' de frank)
Pitching[G > 5, rank_in_team := frank(ERA), by = .(teamID, yearID)]
Pitching[rank_in_team == 1, team_performance :=
           Teams[.SD, Rank, on = c('teamID', 'yearID')]]

## ----group_sd_last--------------------------------------------------------------------------------
# les données sont déjà triées par année ; si ce n’était pas le cas
#   nous pourrions faire Teams[order(yearID), .SD[.N], by = teamID]
Teams[ , .SD[.N], by = teamID]

## ----sd_team_best_year----------------------------------------------------------------------------
Teams[ , .SD[which.max(R)], by = teamID]

## ----group_lm, results = 'hide', fig.cap="Histogramme de la distribution des coefficients ajustés. Il a plus ou moins une forme en cloche centrée autour de -.2"----
# Coefficients globaux pour comparaison
overall_coef = Pitching[ , coef(lm(ERA ~ W))['W']]
# utilisation du filtre .N > 20 pour exclure les équipes où il y a peu de données
Pitching[ , if (.N > 20L) .(w_coef = coef(lm(ERA ~ W))['W']), by = teamID
          ][ , hist(w_coef, 20L, las = 1L,
                    xlab = 'Fitted Coefficient on W',
                    ylab = 'Number of Teams', col = 'darkgreen',
                    main = 'Team-Level Distribution\nWin Coefficients on ERA')]
abline(v = overall_coef, lty = 2L, col = 'red')

## ----echo=FALSE-----------------------------------------------------------------------------------
setDTthreads(.old.th)

