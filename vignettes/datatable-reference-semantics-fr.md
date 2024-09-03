---
title: "Sémantique de référence"
date: "2024-09-03"
output:
  markdown::html_format
vignette: >
  %\VignetteIndexEntry{Sémantique de référence}
  %\VignetteEngine{knitr::knitr}
  \usepackage[utf8]{inputenc}
---



Cette vignette traite de la sémantique de référence de *data.table* qui permet d'ajouter, de mettre à jour ou de supprimer des colonnes d'un *data.table par référence*, ainsi que de les combiner avec `i` et `by`. Elle s'adresse à ceux qui sont déjà familiers avec la syntaxe de *data.table*, avec sa forme générale, avec la façon de filtrer des lignes avec `i`, de sélectionner et calculer sur des colonnes, et d'effectuer des agrégations par groupe. Si vous n'êtes pas familier avec ces concepts, veuillez d'abord lire la vignette *"Introduction à data.table "*.

***

## Données {#data}

Nous utiliserons les mêmes données `flights` que dans la vignette *"Introduction à data.table"*.




```r
flights <- fread("flights14.csv")
flights
#          year month   day dep_delay arr_delay carrier origin   dest air_time distance  hour
#         <int> <int> <int>     <int>     <int>  <char> <char> <char>    <int>    <int> <int>
#      1:  2014     1     1        14        13      AA    JFK    LAX      359     2475     9
#      2:  2014     1     1        -3        13      AA    JFK    LAX      363     2475    11
#      3:  2014     1     1         2         9      AA    JFK    LAX      351     2475    19
#      4:  2014     1     1        -8       -26      AA    LGA    PBI      157     1035     7
#      5:  2014     1     1         2         1      AA    JFK    LAX      350     2475    13
#     ---                                                                                    
# 253312:  2014    10    31         1       -30      UA    LGA    IAH      201     1416    14
# 253313:  2014    10    31        -5       -14      UA    EWR    IAH      189     1400     8
# 253314:  2014    10    31        -8        16      MQ    LGA    RDU       83      431    11
# 253315:  2014    10    31        -4        15      MQ    LGA    DTW       75      502    11
# 253316:  2014    10    31        -5         1      MQ    LGA    SDF      110      659     8
dim(flights)
# [1] 253316     11
```

## Introduction

Dans cette vignette, nous allons

1. d’abord discuter brièvement les sémantiques de référence et examiner les deux formes différentes pour lesquelles l’opérateur `:=` peut être utilisé

2. ensuite, voir comment ajouter/mettre à jour/supprimer des colonnes *par référence* dans `j` en utilisant l'opérateur `:=` et comment le combiner avec `i` et `by`.

3. et enfin, nous examinerons l'utilisation de `:=` pour ses *effets secondaires* et comment nous pouvons éviter ces effets secondaires en utilisant `copy()`.

## 1. Sémantique de référence

Toutes les opérations que nous avons vues jusqu'à présent dans la vignette précédente ont abouti à un nouveau jeu de données. Nous allons voir comment *ajouter* de nouvelles colonnes, *mettre à jour* ou *supprimer* des colonnes existantes sur les données originales.

### a) Contexte

Avant d'examiner la *sémantique de référence*, considérons le *data.frame* ci-dessous :


```r
DF = data.frame(ID = c("b", "b", "b", "a", "a", "c"), a = 1:6, b = 7:12, c = 13:18)
DF
#   ID a  b  c
# 1  b 1  7 13
# 2  b 2  8 14
# 3  b 3  9 15
# 4  a 4 10 16
# 5  a 5 11 17
# 6  c 6 12 18
```

Quand nous faisions :


```r
DF$c <- 18:13 # (1) -- remplacer toute une colonne
# ou
DF$c[DF$ID == "b"] <- 15:13 # (2) -- sous-assignation dans la colonne 'c'
```

À la fois (1) et (2) ont tous deux entraîné une copie profonde de l'ensemble du `data.frame` dans les versions de R < 3.1. [Ces version copiaient plus d’une fois](https://stackoverflow.com/q/23898969/559784). Pour améliorer les performances en évitant ces copies redondantes, *data.table* a utilisé l'opérateur [`:=` disponible mais inutilisé dans R](https://stackoverflow.com/q/7033106/559784).

D’importantes améliorations de performance ont été réalisées dans `R v3.1`, à la suite desquelles seule une copie *superficielle* est faite pour (1) et non une copie *profonde*. Cependant, pour (2), la colonne entière est encore *copiée en profondeur* même dans `R v3.1+`. Cela signifie que plus on effectue de sous-assignations de colonnes dans une *même requête*, plus R fait de *copies profondes*.

#### Copie *superficielle* vs copie *profonde*

Une copie *superficielle* consiste uniquement en une copie du vecteur de pointeurs de colonnes (correspondant aux colonnes d'un *data.frame* ou d'un *data.table*). Les données réelles ne sont pas physiquement copiées en mémoire.

Une copie *profonde*, en revanche, copie l'intégralité des données à un autre emplacement en mémoire.

Lorsque l'on utilise `i` (par exemple, `DT[1:10]`) pour sélectionner des lignes dans une *data.table*, une copie *profonde* est effectuée. Cependant, lorsque `i` n'est pas fourni ou est égal à `TRUE`, une copie *superficielle* est faite.

# 

Avec l'opérateur `:=` de *data.table*, absolument aucune copie n'est effectuée dans *les deux cas* (1) et (2), quelle que soit la version de R que vous utilisez. Cela s’explique par le fait que l’opérateur `:=` met à jour les colonnes de *data.table* en place (par référence).

### b) L'opérateur `:=`

Il peut être utilisé dans `j` de deux façons :

(a) La forme `LHS := RHS` (côté gauche := côté droit)


```r
DT[, c("colA", "colB", ...) := list(valA, valB, ...)]

# lorsque vous n'avez qu'une seule colonne à assigner
# vous pouvez omettre les guillemets et `list(), pour plus de commodité
DT[, colA := valA]
```

(b) La forme fonctionnelle


```r
DT[, `:=`(colA = valA, # valA est assigné à colA
          colB = valB, # valB est assigné à colB
          ...
)]
```

Notez que le code ci-dessus explique comment `:=` peut être utilisé. Ce ne sont pas des exemples pratiques. Nous en proposerons un premier avec le *data.table* `flights` dans la section suivante.

# 

* Dans (a), `LHS` prend un vecteur de caractères de noms de colonnes et `RHS` une *liste de valeurs*. `RHS` doit juste être un objet `list`, indépendamment de la façon dont elle est générée (par exemple, en utilisant `lapply()`, `list()`, `mget()`, `mapply()`, etc.) Cette forme est généralement facile à programmer et est particulièrement utile lorsque vous ne connaissez pas à l'avance les colonnes auxquelles attribuer des valeurs.

* En revanche, le point (b) est pratique si vous souhaitez commenter votre code (voir exemple sur `flights`).

* Le résultat est renvoyé de manière *invisible*.

* Puisque `:=` est disponible dans `j`, nous pouvons le combiner avec les opérations `i` et `by` tout comme les opérations d'agrégation que nous avons vues dans la vignette précédente.

# 

Dans les deux formes de `:=` présentées ci-dessus, notez que nous n'assignons pas le résultat à une variable, parce que nous n'en avons pas besoin. La *data.table* en entrée est modifiée par référence. Prenons des exemples pour comprendre ce que nous entendons par là.

Pour la suite de cette vignette, nous travaillerons avec la *data.table* `flights`.

## 2. Ajouter/mettre à jour/supprimer des colonnes *par référence*

### a) Ajouter des colonnes par référence {#ref-j}

#### -- Comment ajouter les colonnes vitesse *speed* et retard total *total delay* de chaque vol à la *data.table* `flights` ?


```r
flights[, `:=`(speed = distance / (air_time/60), # vitesse en mph (mi/h)
               delay = arr_delay + dep_delay)]   # retard en minutes
head(flights)
#     year month   day dep_delay arr_delay carrier origin   dest air_time distance  hour    speed
#    <int> <int> <int>     <int>     <int>  <char> <char> <char>    <int>    <int> <int>    <num>
# 1:  2014     1     1        14        13      AA    JFK    LAX      359     2475     9 413.6490
# 2:  2014     1     1        -3        13      AA    JFK    LAX      363     2475    11 409.0909
# 3:  2014     1     1         2         9      AA    JFK    LAX      351     2475    19 423.0769
# 4:  2014     1     1        -8       -26      AA    LGA    PBI      157     1035     7 395.5414
# 5:  2014     1     1         2         1      AA    JFK    LAX      350     2475    13 424.2857
# 6:  2014     1     1         4         0      AA    EWR    LAX      339     2454    18 434.3363
#    delay
#    <int>
# 1:    27
# 2:    10
# 3:    11
# 4:   -34
# 5:     3
# 6:     4

## ou alors, en utilisant la forme 'LHS := RHS'
# flights[, c("speed", "delay") := list(distance/(air_time/60), arr_delay + dep_delay)]
```

#### Notez que

* Nous n'avons pas eu à réaffecter le résultat à `flights`.

* La *data.table* `flights` contient maintenant les deux colonnes nouvellement ajoutées. C'est ce que nous entendons par *ajouté par référence*.

* Nous avons utilisé la forme fonctionnelle pour pouvoir ajouter des commentaires sur le côté afin d'expliquer ce que fait le calcul. Vous pouvez également voir la forme `LHS := RHS` (en commentaire).

### b) Mise à jour de certaines lignes de colonnes par référence - *sous-assignation* par référence {#ref-i-j}

Examinons toutes les heures (`hours`) disponibles dans la *data.table* `flights` :


```r
# récupère toutes les heures de flights
flights[, sort(unique(hour))]
#  [1]  0  1  2  3  4  5  6  7  8  9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24
```

Nous constatons qu'il y a au total `25` valeurs uniques dans les données. Les heures *0* et *24* semblent toutes les deux être présentes. Remplaçons *24* par *0*.

#### -- Remplacer les lignes où `hour == 24` par la valeur `0`


```r
# sous-assignation par référence
flights[hour == 24L, hour := 0L]
```

* Nous pouvons utiliser `i` avec `:=` dans `j` de la même manière que nous l'avons déjà vu dans la vignette *"Introduction à data.table "*.

* La colonne `hour` est remplacée par `0` uniquement sur les *indices de ligne* où la condition `hour == 24L` spécifiée dans `i` est évaluée à `TRUE`.

* `:=` renvoie le résultat de manière invisible. Parfois, il peut être nécessaire de voir le résultat après l'affectation. Nous pouvons y parvenir en ajoutant des crochets vides `[]` à la fin de la requête, comme indiqué ci-dessous :

    
    ```r
    flights[hour == 24L, hour := 0L][]
    # Indice : <hour>
    #          year month   day dep_delay arr_delay carrier origin   dest air_time distance  hour
    #         <int> <int> <int>     <int>     <int>  <char> <char> <char>    <int>    <int> <int>
    #      1:  2014     1     1        14        13      AA    JFK    LAX      359     2475     9
    #      2:  2014     1     1        -3        13      AA    JFK    LAX      363     2475    11
    #      3:  2014     1     1         2         9      AA    JFK    LAX      351     2475    19
    #      4:  2014     1     1        -8       -26      AA    LGA    PBI      157     1035     7
    #      5:  2014     1     1         2         1      AA    JFK    LAX      350     2475    13
    #     ---                                                                                    
    # 253312:  2014    10    31         1       -30      UA    LGA    IAH      201     1416    14
    # 253313:  2014    10    31        -5       -14      UA    EWR    IAH      189     1400     8
    # 253314:  2014    10    31        -8        16      MQ    LGA    RDU       83      431    11
    # 253315:  2014    10    31        -4        15      MQ    LGA    DTW       75      502    11
    # 253316:  2014    10    31        -5         1      MQ    LGA    SDF      110      659     8
    #            speed delay
    #            <num> <int>
    #      1: 413.6490    27
    #      2: 409.0909    10
    #      3: 423.0769    11
    #      4: 395.5414   -34
    #      5: 424.2857     3
    #     ---               
    # 253312: 422.6866   -29
    # 253313: 444.4444   -19
    # 253314: 311.5663     8
    # 253315: 401.6000    11
    # 253316: 359.4545    -4
    ```

# 

Regardons toutes les heures pour vérifier.


```r
# vérifier à nouveau la présence de '24'
flights[, sort(unique(hour))]
#  [1]  0  1  2  3  4  5  6  7  8  9 10 11 12 13 14 15 16 17 18 19 20 21 22 23
```

#### Exercice : {#update-by-reference-question}

Quelle est la différence entre `flights[hour == 24L, hour := 0L]` et `flights[hour == 24L][, hour := 0L]` ? Indice : le dernier a besoin d'une affectation (`<-`) si vous voulez utiliser le résultat plus tard.

Si vous ne parvenez pas à le comprendre, consultez la section `Note` de ` ?":="`.

### c) Suppression de colonne par référence

#### -- Supprimer la colonne `delay`


```r
flights[, c("delay") := NULL]
head(flights)
#     year month   day dep_delay arr_delay carrier origin   dest air_time distance  hour    speed
#    <int> <int> <int>     <int>     <int>  <char> <char> <char>    <int>    <int> <int>    <num>
# 1:  2014     1     1        14        13      AA    JFK    LAX      359     2475     9 413.6490
# 2:  2014     1     1        -3        13      AA    JFK    LAX      363     2475    11 409.0909
# 3:  2014     1     1         2         9      AA    JFK    LAX      351     2475    19 423.0769
# 4:  2014     1     1        -8       -26      AA    LGA    PBI      157     1035     7 395.5414
# 5:  2014     1     1         2         1      AA    JFK    LAX      350     2475    13 424.2857
# 6:  2014     1     1         4         0      AA    EWR    LAX      339     2454    18 434.3363

## ou en utilisant la forme fonctionnelle
# flights[, `:=`(delay = NULL)]
```

#### {#delete-convenience}

* Assigner `NULL` à une colonne *supprime* cette colonne. Et cela se produit *instantanément*.

* Nous pouvons également passer des numéros de colonnes au lieu de noms dans le membre de gauche (`LHS`), bien qu'il soit de bonne pratique de programmation d'utiliser des noms de colonnes.

* Lorsqu'il n'y a qu'une seule colonne à supprimer, nous pouvons omettre le `c()` et les guillemets doubles et simplement utiliser le nom de la colonne *sans guillemets*, pour plus de commodité. C'est-à-dire :

    
    ```r
    flights[, delay := NULL]
    ```
    
    est équivalent au code ci-dessus.

### d) `:=` avec regroupement utilisant `by` {#ref-j-by}

Nous avons déjà vu l'utilisation de `i` avec `:=` dans la [Section 2b] (#ref-i-j). Voyons maintenant comment nous pouvons utiliser `:=` avec `by`.

#### -- Comment ajouter une nouvelle colonne qui contienne pour chaque paire `orig,dest` la vitesse maximale ?


```r
flights[, max_speed := max(speed), by = .(origin, dest)]
head(flights)
#     year month   day dep_delay arr_delay carrier origin   dest air_time distance  hour    speed
#    <int> <int> <int>     <int>     <int>  <char> <char> <char>    <int>    <int> <int>    <num>
# 1:  2014     1     1        14        13      AA    JFK    LAX      359     2475     9 413.6490
# 2:  2014     1     1        -3        13      AA    JFK    LAX      363     2475    11 409.0909
# 3:  2014     1     1         2         9      AA    JFK    LAX      351     2475    19 423.0769
# 4:  2014     1     1        -8       -26      AA    LGA    PBI      157     1035     7 395.5414
# 5:  2014     1     1         2         1      AA    JFK    LAX      350     2475    13 424.2857
# 6:  2014     1     1         4         0      AA    EWR    LAX      339     2454    18 434.3363
#    max_speed
#        <num>
# 1:  526.5957
# 2:  526.5957
# 3:  526.5957
# 4:  517.5000
# 5:  526.5957
# 6:  518.4507
```

* Nous ajoutons une nouvelle colonne `max_speed` en utilisant l'opérateur `:=` par référence.

* Nous fournissons les colonnes pour le regroupement de la même manière qu’indiqué dans la vignette *Introduction à data.table*. Pour chaque groupe, `max(speed)` est calculé, ce qui renvoie une seule valeur. Cette valeur est recyclée pour s'adapter à la longueur du groupe. Encore une fois, aucune copie n'est faite. La *data.table* `flights` est modifié directement « sur place ».

* Nous aurions également pu fournir à `by` un *vecteur de caractères* comme nous l'avons vu dans la vignette *Introduction à data.table*, par exemple en utilisant `by = c("origin", "dest")`.

# 

### e) Colonnes multiples et `:=`

#### -- Comment peut-on ajouter deux colonnes supplémentaires en calculant `max()` de `dep_delay` et `arr_delay` pour chaque mois, en utilisant `.SD` ?


```r
in_cols = c("dep_delay", "arr_delay")
out_cols = c("max_dep_delay", "max_arr_delay")
flights[, c(out_cols) := lapply(.SD, max), by = month, .SDcols = in_cols]
head(flights)
#     year month   day dep_delay arr_delay carrier origin   dest air_time distance  hour    speed
#    <int> <int> <int>     <int>     <int>  <char> <char> <char>    <int>    <int> <int>    <num>
# 1:  2014     1     1        14        13      AA    JFK    LAX      359     2475     9 413.6490
# 2:  2014     1     1        -3        13      AA    JFK    LAX      363     2475    11 409.0909
# 3:  2014     1     1         2         9      AA    JFK    LAX      351     2475    19 423.0769
# 4:  2014     1     1        -8       -26      AA    LGA    PBI      157     1035     7 395.5414
# 5:  2014     1     1         2         1      AA    JFK    LAX      350     2475    13 424.2857
# 6:  2014     1     1         4         0      AA    EWR    LAX      339     2454    18 434.3363
#    max_speed max_dep_delay max_arr_delay
#        <num>         <int>         <int>
# 1:  526.5957           973           996
# 2:  526.5957           973           996
# 3:  526.5957           973           996
# 4:  517.5000           973           996
# 5:  526.5957           973           996
# 6:  518.4507           973           996
```

* Nous utilisons la forme `LHS := RHS`. Nous stockons les noms des colonnes d'entrée et les nouvelles colonnes à ajouter dans des variables séparées, puis les fournissons à `.SDcols` et à `LHS` (pour une meilleure lisibilité).

* Notez que puisque nous autorisons l'assignation par référence sans mettre les noms de colonnes entre guillemets lorsqu'il n'y a qu'une seule colonne comme expliqué dans la [Section 2c](#delete-convenience), nous ne pouvons pas faire `out_cols := lapply(.SD, max)`. Cela rajouterait une nouvelle colonne nommée `out_col`. À la place, nous devrions utiliser soit `c(out_cols)`, soit simplement `(out_cols)`. Envelopper le nom de la variable dans des parenthèses `(` est suffisant pour différencier les deux cas.

* La forme `LHS := RHS` nous permet d'opérer sur plusieurs colonnes. Dans le membre de droite (RHS), pour calculer le `max` sur les colonnes spécifiées dans `.SDcols`, nous utilisons la fonction de base `lapply()` avec `.SD` de la même manière que nous l'avons vu précédemment dans la vignette *"Introduction to data.table "*. Ceci renvoie une liste de deux éléments, contenant la valeur maximale correspondant à `dep_delay` et `arr_delay` pour chaque groupe.

# 

Avant de passer à la section suivante, nettoyons les colonnes nouvellement créées `speed`, `max_speed`, `max_dep_delay` et `max_arr_delay`.


```r
# RHS est automatiquement recyclé à la longueur de LHS
flights[, c("speed", "max_speed", "max_dep_delay", "max_arr_delay") := NULL]
head(flights)
#     year month   day dep_delay arr_delay carrier origin   dest air_time distance  hour
#    <int> <int> <int>     <int>     <int>  <char> <char> <char>    <int>    <int> <int>
# 1:  2014     1     1        14        13      AA    JFK    LAX      359     2475     9
# 2:  2014     1     1        -3        13      AA    JFK    LAX      363     2475    11
# 3:  2014     1     1         2         9      AA    JFK    LAX      351     2475    19
# 4:  2014     1     1        -8       -26      AA    LGA    PBI      157     1035     7
# 5:  2014     1     1         2         1      AA    JFK    LAX      350     2475    13
# 6:  2014     1     1         4         0      AA    EWR    LAX      339     2454    18
```

#### -- Comment peut-on mettre à jour plusieurs colonnes existantes par référence en utilisant `.SD` ?


```r
flights[, names(.SD) := lapply(.SD, as.factor), .SDcols = is.character]
```

Nettoyons à nouveau et convertissons nos colonnes de facteurs nouvellement créées en colonnes de caractères. Cette fois, nous allons utiliser `.SDcols` qui accepte une fonction pour décider quelles colonnes inclure. Dans ce cas, `is.factor()` retournera les colonnes qui sont des facteurs. Pour en savoir plus sur le **S**ous-ensemble des **D**onnées (**S**ubset of the **D**ata), il y a aussi une [vignette sur l’utilisation de SD](https://cran.r-project.org/package=data.table/vignettes/datatable-sd-usage.html).

Parfois, il est également utile de garder une trace des colonnes que nous transformons. Ainsi, même après avoir converti nos colonnes, nous pourrons toujours appeler les colonnes spécifiques que nous avons mises à jour.


```r
factor_cols <- sapply(flights, is.factor)
flights[, names(.SD) := lapply(.SD, as.character), .SDcols = factor_cols]
str(flights[, ..factor_cols])
# Classes 'data.table' and 'data.frame':	253316 obs. of  3 variables:
#  $ carrier: chr  "AA" "AA" "AA" "AA" ...
#  $ origin : chr  "JFK" "JFK" "JFK" "LGA" ...
#  $ dest   : chr  "LAX" "LAX" "LAX" "PBI" ...
#  - attr(*, ".internal.selfref")=<externalptr>
```

#### {.bs-callout .bs-callout-info}

* Nous aurions également pu utiliser `(factor_cols)` sur le membre de gauche (`LHS`) au lieu de `names(.SD)`.

## 3. `:=` et `copy()`

`:=` modifie l'objet d'entrée par référence. En dehors des fonctionnalités que nous avons déjà discutées, il arrive parfois que nous souhaitions utiliser la fonctionnalité de mise à jour par référence pour ses effets secondaires. À d’autres moments, il n'est pas souhaitable de modifier l'objet original, auquel cas nous pouvons utiliser la fonction `copy()`, comme nous le verrons dans un instant.

### a) `:=` pour ses effets secondaires

Supposons que nous voulions créer une fonction qui renvoie la vitesse maximale (*maximum speed*) pour chaque mois. Mais en même temps, nous aimerions aussi ajouter la colonne `speed` à *flights*. Nous pourrions écrire une petite fonction comme suit :


```r
foo <- function(DT) {
  DT[, speed := distance / (air_time/60)]
  DT[, .(max_speed = max(speed)), by = month]
}
ans = foo(flights)
head(flights)
#     year month   day dep_delay arr_delay carrier origin   dest air_time distance  hour    speed
#    <int> <int> <int>     <int>     <int>  <char> <char> <char>    <int>    <int> <int>    <num>
# 1:  2014     1     1        14        13      AA    JFK    LAX      359     2475     9 413.6490
# 2:  2014     1     1        -3        13      AA    JFK    LAX      363     2475    11 409.0909
# 3:  2014     1     1         2         9      AA    JFK    LAX      351     2475    19 423.0769
# 4:  2014     1     1        -8       -26      AA    LGA    PBI      157     1035     7 395.5414
# 5:  2014     1     1         2         1      AA    JFK    LAX      350     2475    13 424.2857
# 6:  2014     1     1         4         0      AA    EWR    LAX      339     2454    18 434.3363
head(ans)
#    month max_speed
#    <int>     <num>
# 1:     1  535.6425
# 2:     2  535.6425
# 3:     3  549.0756
# 4:     4  585.6000
# 5:     5  544.2857
# 6:     6  608.5714
```

* Notez que la nouvelle colonne `speed` a été ajoutée à la *data.table* `flights`. C'est parce que `:=` effectue des opérations par référence. Puisque `DT` (l'argument de la fonction) et `flights` font référence au même objet en mémoire, la modification de `DT` se répercute également sur `flights`.

* Et `ans` contient la vitesse maximale pour chaque mois.

### b) La fonction `copy()`

Dans la section précédente, nous avons utilisé `:=` pour son effet secondaire. Mais bien sûr, ce n'est pas toujours souhaitable. Parfois, nous voudrions passer un objet *data.table* à une fonction, et nous pourrions vouloir utiliser l'opérateur `:=`, mais *ne voudrions pas* mettre à jour l'objet original. Nous pouvons accomplir cela en utilisant la fonction `copy()`.

La fonction `copy()` effectue une copie *profonde* de l'objet d'entrée, et donc, toutes les opérations de mise à jour par référence effectuées sur l'objet copié n'affecteront pas l'objet d'origine.

# 

Il y a deux situations particulières où la fonction `copy()` est essentielle :

1. Contrairement à ce que nous avons vu au point précédent, nous pouvons ne pas vouloir que les données d'entrée d'une fonction soient modifiées *par référence*. A titre d'exemple, considérons la tâche de la section précédente, sauf que nous ne voulons pas modifier `flights` par référence.

    Supprimons d'abord la colonne `speed` que nous avons générée dans la section précédente.
    
    
    ```r
    flights[, vitesse := NULL]
    # Warning in `[.data.table`(flights, , `:=`(vitesse, NULL)): Tentative d’affectation de NULL à la
    # colonne ‘vitesse’, mais cette colonne n’existe pas et ne peut donc pas être éliminée
    ```
    Maintenant, nous pourrions accomplir la tâche comme suit :
    
    
    ```r
    foo <- function(DT) {
      DT <- copy(DT) ## copie profonde
      DT[, speed := distance / (air_time/60)] ## n'affecte pas les vols
      DT[, .(max_speed = max(speed)), by = month]
    }
    ans <- foo(flights)
    head(flights)
    #     year month   day dep_delay arr_delay carrier origin   dest air_time distance  hour    speed
    #    <int> <int> <int>     <int>     <int>  <char> <char> <char>    <int>    <int> <int>    <num>
    # 1:  2014     1     1        14        13      AA    JFK    LAX      359     2475     9 413.6490
    # 2:  2014     1     1        -3        13      AA    JFK    LAX      363     2475    11 409.0909
    # 3:  2014     1     1         2         9      AA    JFK    LAX      351     2475    19 423.0769
    # 4:  2014     1     1        -8       -26      AA    LGA    PBI      157     1035     7 395.5414
    # 5:  2014     1     1         2         1      AA    JFK    LAX      350     2475    13 424.2857
    # 6:  2014     1     1         4         0      AA    EWR    LAX      339     2454    18 434.3363
    head(ans)
    #    month max_speed
    #    <int>     <num>
    # 1:     1  535.6425
    # 2:     2  535.6425
    # 3:     3  549.0756
    # 4:     4  585.6000
    # 5:     5  544.2857
    # 6:     6  608.5714
    ```

* L'utilisation de la fonction `copy()` n'a pas modifié la *data.table* `flights` par référence. Elle ne contient pas la colonne `speed`.

* Et `ans` contient la vitesse maximale correspondant à chaque mois.

Cependant, nous pourrions encore améliorer cette fonctionnalité en faisant une copie *superficielle* au lieu d'une copie *profonde*. En fait, nous aimerions beaucoup [fournir cette fonctionnalité pour `v1.9.8`](https://github.com/Rdatatable/data.table/issues/617). Nous reviendrons sur ce point dans la vignette *design de data.table*.

# 

2. Lorsque nous stockons les noms de colonnes dans une variable, par exemple, `DT_n = names(DT)`, puis que nous *ajoutons/mettons à jour/supprimons* une ou plusieurs colonne(s) *par référence*, cela modifierait également `DT_n`, à moins que nous ne fassions `copy(names(DT))`.

    
    ```r
    DT = data.table(x = 1L, y = 2L)
    DT_n = names(DT)
    DT_n
    # [1] "x" "y"
    
    ## ajouter une nouvelle colonne par référence
    DT[, z := 3L]
    
    ## DT_n est également mis à jour
    DT_n
    # [1] "x" "y" "z"
    
    ## utiliser `copy()`
    DT_n = copy(names(DT))
    DT[, w := 4L]
    
    ## DT_n n'est pas mis à jour
    DT_n
    # [1] "x" "y" "z"
    ```

## Résumé

#### L'opérateur `:=`

* Il est utilisé pour *ajouter/mettre à jour/supprimer* des colonnes par référence.

* Nous avons aussi vu comment utiliser `:=` avec `i` et `by` de la même manière que nous l'avons vu dans la vignette *Introduction à data.table*. Nous pouvons de la même manière utiliser `keyby`, enchaîner des opérations, et passer des expressions à `by` de la même manière. La syntaxe est *consistante*.

* Nous pouvons utiliser `:=` pour ses effets secondaires ou utiliser `copy()` pour ne pas modifier l'objet original tout en mettant à jour par référence.



# 

Jusqu'à présent, nous avons vu beaucoup d’opérations en `j`, et comment les combiner avec `by`, mais peu de choses concernant `i`. Tournons notre attention vers `i` dans la prochaine vignette *"Clés et sous-ensembles basés sur une recherche binaire rapide"* pour réaliser des *sous-ensembles ultra-rapides* en *utilisant des clés dans data.tables*.

***
