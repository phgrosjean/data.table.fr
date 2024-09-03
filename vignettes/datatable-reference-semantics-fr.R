## ----echo = FALSE, message = FALSE----------------------------------------------------------------
require(data.table)
knitr::opts_chunk$set(
  comment = "#",
    error = FALSE,
     tidy = FALSE,
    cache = FALSE,
 collapse = TRUE)
.old.th = setDTthreads(1)

## ----echo = FALSE---------------------------------------------------------------------------------
options(with = 100L)

## -------------------------------------------------------------------------------------------------
flights <- fread("flights14.csv")
flights
dim(flights)

## -------------------------------------------------------------------------------------------------
DF = data.frame(ID = c("b", "b", "b", "a", "a", "c"), a = 1:6, b = 7:12, c = 13:18)
DF

## ----eval = FALSE---------------------------------------------------------------------------------
#  DF$c <- 18:13 # (1) -- remplacer toute une colonne
#  # ou
#  DF$c[DF$ID == "b"] <- 15:13 # (2) -- sous-assignation dans la colonne 'c'

## ----eval = FALSE---------------------------------------------------------------------------------
#  DT[, c("colA", "colB", ...) := list(valA, valB, ...)]
#  
#  # lorsque vous n'avez qu'une seule colonne à assigner
#  # vous pouvez omettre les guillemets et `list(), pour plus de commodité
#  DT[, colA := valA]

## ----eval = FALSE---------------------------------------------------------------------------------
#  DT[, `:=`(colA = valA, # valA est assigné à colA
#            colB = valB, # valB est assigné à colB
#            ...
#  )]

## -------------------------------------------------------------------------------------------------
flights[, `:=`(speed = distance / (air_time/60), # vitesse en mph (mi/h)
               delay = arr_delay + dep_delay)]   # retard en minutes
head(flights)

## ou alors, en utilisant la forme 'LHS := RHS'
# flights[, c("speed", "delay") := list(distance/(air_time/60), arr_delay + dep_delay)]

## -------------------------------------------------------------------------------------------------
# récupère toutes les heures de flights
flights[, sort(unique(hour))]

## -------------------------------------------------------------------------------------------------
# sous-assignation par référence
flights[hour == 24L, hour := 0L]

## -------------------------------------------------------------------------------------------------
flights[hour == 24L, hour := 0L][]

## -------------------------------------------------------------------------------------------------
# vérifier à nouveau la présence de '24'
flights[, sort(unique(hour))]

## -------------------------------------------------------------------------------------------------
flights[, c("delay") := NULL]
head(flights)

## ou en utilisant la forme fonctionnelle
# flights[, `:=`(delay = NULL)]

## ----eval = FALSE---------------------------------------------------------------------------------
#  flights[, delay := NULL]

## -------------------------------------------------------------------------------------------------
flights[, max_speed := max(speed), by = .(origin, dest)]
head(flights)

## -------------------------------------------------------------------------------------------------
in_cols = c("dep_delay", "arr_delay")
out_cols = c("max_dep_delay", "max_arr_delay")
flights[, c(out_cols) := lapply(.SD, max), by = month, .SDcols = in_cols]
head(flights)

## -------------------------------------------------------------------------------------------------
# RHS est automatiquement recyclé à la longueur de LHS
flights[, c("speed", "max_speed", "max_dep_delay", "max_arr_delay") := NULL]
head(flights)

## -------------------------------------------------------------------------------------------------
flights[, names(.SD) := lapply(.SD, as.factor), .SDcols = is.character]

## -------------------------------------------------------------------------------------------------
factor_cols <- sapply(flights, is.factor)
flights[, names(.SD) := lapply(.SD, as.character), .SDcols = factor_cols]
str(flights[, ..factor_cols])

## -------------------------------------------------------------------------------------------------
foo <- function(DT) {
  DT[, speed := distance / (air_time/60)]
  DT[, .(max_speed = max(speed)), by = month]
}
ans = foo(flights)
head(flights)
head(ans)

## -------------------------------------------------------------------------------------------------
flights[, vitesse := NULL]

## -------------------------------------------------------------------------------------------------
foo <- function(DT) {
  DT <- copy(DT) ## copie profonde
  DT[, speed := distance / (air_time/60)] ## n'affecte pas les vols
  DT[, .(max_speed = max(speed)), by = month]
}
ans <- foo(flights)
head(flights)
head(ans)

## -------------------------------------------------------------------------------------------------
DT = data.table(x = 1L, y = 2L)
DT_n = names(DT)
DT_n

## ajouter une nouvelle colonne par référence
DT[, z := 3L]

## DT_n est également mis à jour
DT_n

## utiliser `copy()`
DT_n = copy(names(DT))
DT[, w := 4L]

## DT_n n'est pas mis à jour
DT_n

## ----echo=FALSE-----------------------------------------------------------------------------------
setDTthreads(.old.th)

