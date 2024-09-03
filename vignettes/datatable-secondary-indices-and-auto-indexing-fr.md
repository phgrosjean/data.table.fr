---
title: "Indices secondaires et auto-indexation"
date: "2024-09-03"
output:
  markdown::html_format
vignette: >
  %\VignetteIndexEntry{Indices secondaires et auto-indexation}
  %\VignetteEngine{knitr::knitr}
  \usepackage[utf8]{inputenc}
---



Cette vignette suppose que le lecteur est familier avec la syntaxe `[i, j, by]` de data.table, et sur la façon d’effectuer des sous-ensembles basés sur des clés rapides. Si vous n'êtes pas familier avec ces concepts, veuillez d'abord lire les vignettes *"Introduction à data.table"*, *"Sémantique de référence"* et *"Sous-ensembles basés sur les clés et la recherche binaire rapide"*.

***

## Données {#data}

Nous utiliserons les mêmes données `flights` que dans la vignette *"Introduction à data.table"*.




```r
flights <- fread("flights14.csv")
head(flights)
#     year month   day dep_delay arr_delay carrier origin   dest air_time distance  hour
#    <int> <int> <int>     <int>     <int>  <char> <char> <char>    <int>    <int> <int>
# 1:  2014     1     1        14        13      AA    JFK    LAX      359     2475     9
# 2:  2014     1     1        -3        13      AA    JFK    LAX      363     2475    11
# 3:  2014     1     1         2         9      AA    JFK    LAX      351     2475    19
# 4:  2014     1     1        -8       -26      AA    LGA    PBI      157     1035     7
# 5:  2014     1     1         2         1      AA    JFK    LAX      350     2475    13
# 6:  2014     1     1         4         0      AA    EWR    LAX      339     2454    18
dim(flights)
# [1] 253316     11
```

## Introduction

Dans cette vignette, nous allons

* discuter des *indices secondaires* et justifie leur nécessité en citant des cas où l'établissement de clés n'est pas nécessairement idéal,

* effectuer un sous-ensemble rapide, une fois de plus, mais en utilisant le nouvel argument `on`, qui calcule des indices secondaires en interne pour la tâche (temporairement), et les réutilise s'il en existe déjà un,

* et enfin, explorer l’*auto-indexation* qui va plus loin et crée des indices secondaires automatiquement, mais en utilisant la syntaxe native de R pour le sous-ensemble.

## 1. Indices secondaires

### a) Qu'est-ce qu'un indice secondaire ?

Les indices secondaires sont similaires aux `clés` dans *data.table*, à l'exception de deux différences majeures :

* Il ne réorganise pas physiquement l'ensemble de la table de données en RAM. Au lieu de cela, il calcule uniquement l'ordre pour l'ensemble des colonnes fournies et stocke ce *vecteur d'ordre* dans un attribut supplémentaire appelé `index`.

* Il peut y avoir plus d'un index secondaire pour une table de données (comme nous le verrons plus loin).

### b) Définir et obtenir des indices secondaires

#### -- Comment définir la colonne `origin` comme index secondaire dans l’objet *data.table* `flights` ?


```r
setindex(flights, origin)
head(flights)
#     year month   day dep_delay arr_delay carrier origin   dest air_time distance  hour
#    <int> <int> <int>     <int>     <int>  <char> <char> <char>    <int>    <int> <int>
# 1:  2014     1     1        14        13      AA    JFK    LAX      359     2475     9
# 2:  2014     1     1        -3        13      AA    JFK    LAX      363     2475    11
# 3:  2014     1     1         2         9      AA    JFK    LAX      351     2475    19
# 4:  2014     1     1        -8       -26      AA    LGA    PBI      157     1035     7
# 5:  2014     1     1         2         1      AA    JFK    LAX      350     2475    13
# 6:  2014     1     1         4         0      AA    EWR    LAX      339     2454    18

## nous pouvons aussi fournir des chaînes de caractères à la fonction ‘setindexv()’
# setindexv(flights, "origin") # utile en programmation

# attribut 'index' ajouté
names(attributes(flights))
# [1] "names"             "row.names"         "class"             ".internal.selfref"
# [5] "index"
```

* `setindex` et `setindexv()` permettent d'ajouter un index secondaire à data.table.

* Notez que `flights` n'est **pas** physiquement réordonné dans l'ordre croissant de `origin`, comme cela aurait été le cas avec `setkey()`.

* Notez également que l'attribut `index` a été ajouté à `flights`.

* `setindex(flights, NULL)` supprimerait tous les indices secondaires.

#### -- Comment obtenir tous les indices secondaires définis jusqu'à présent dans `flights` ?


```r
indices(flights)
# [1] "origin"

setindex(flights, origin, dest)
indices(flights)
# [1] "origin"       "origin__dest"
```

* La fonction `indices()` renvoie tous les indices secondaires actuels dans la table data.table. Si aucun n'existe, `NULL` est retourné.

* Notez qu'en créant un autre index sur les colonnes `origin, dest`, nous ne perdons pas le premier index créé sur la colonne `origin`, c'est-à-dire que nous pouvons avoir plusieurs index secondaires.

### c) Pourquoi avons-nous besoin d'indices secondaires ?

#### -- La réorganisation d'une table de données peut être coûteuse et n'est pas toujours idéale

Considérons le cas où vous voudriez effectuer un sous-ensemble basé sur une clé rapide sur la colonne `origin` pour la valeur "JFK". Nous ferions cela comme suit :


```r
## pas exécuté
setkey(flights, origin)
flights["JFK"] # or flights[.("JFK")]
```

#### `setkey()` nécessite de :

a) calculer le vecteur d'ordre pour la (les) colonne(s) fournie(s), ici, `origin`, et

b) réordonner l'ensemble du tableau de données, par référence, sur la base du vecteur d'ordre calculé.

# 

Le calcul de l'ordre n'est pas la partie qui prend le plus de temps, puisque data.table utilise un vrai tri radix sur les vecteurs d'entiers, de caractères et de nombres. Cependant, réordonner le tableau data.table peut prendre du temps (en fonction du nombre de lignes et de colonnes).

À moins que notre tâche n'implique un sous-ensemble répété sur la même colonne, le sous-ensemble basé sur une clé rapide pourrait effectivement être annulé par le temps nécessaire pour réorganiser, en fonction des dimensions de notre data.table.

#### -- Il ne peut y avoir qu'une seule `clé` au maximum

Maintenant, si nous voulons répéter la même opération mais sur la colonne `dest` à la place, pour la valeur "LAX", alors nous devons utiliser `setkey()`, *une fois de plus*.


```r
## pas exécuté
setkey(flights, dest)
flights["LAX"]
```

Et cela réordonne les `vols` par `dest`, *encore une fois*. Ce que nous aimerions vraiment, c'est pouvoir effectuer le sous-ensemble rapidement en éliminant l'étape de réorganisation.

Et c'est précisément ce que permettent les *indices secondaires* !

#### -- Les indices secondaires peuvent être réutilisés

Comme il peut y avoir plusieurs indices secondaires et que la création d'un indice est aussi simple que le stockage du vecteur d'ordre en tant qu'attribut, cela nous permet même d'éliminer le temps nécessaire pour recalculer le vecteur d'ordre si un indice existe déjà.

#### -- Le nouvel argument `on` permet une syntaxe plus propre ainsi que la création et la réutilisation automatiques d'indices secondaires

Comme nous le verrons dans la section suivante, l'argument `on` présente plusieurs avantages :

#### Argument `on`

* permet d’effectuer des sous-ensembles en calculant les indices secondaires à la volée. Cela évite d'avoir à faire `setindex()` à chaque fois.

* permet de réutiliser facilement les indices existants en vérifiant simplement les attributs.

* permet une syntaxe plus propre en intégrant dans la syntaxe les colonnes sur lesquelles le sous-ensemble est effectué. Le code est ainsi plus facile à suivre lorsqu'on le consulte ultérieurement.

    Notez que l'argument `on` peut également être utilisé pour les sous-ensembles à clés. En fait, nous encourageons à fournir l'argument `on` même lorsque le sous-ensemble utilise des clés pour une meilleure lisibilité.

# 

## 2. Sous-ensemble rapide utilisant l'argument `on` et les indices secondaires

### a) Sous-ensembles rapides dans `i`

#### -- Sous-ensemble de toutes les lignes où l'aéroport d'origine correspond à *"JFK"* en utilisant `on`


```r
flights["JFK", on = "origin"]
#         year month   day dep_delay arr_delay carrier origin   dest air_time distance  hour
#        <int> <int> <int>     <int>     <int>  <char> <char> <char>    <int>    <int> <int>
#     1:  2014     1     1        14        13      AA    JFK    LAX      359     2475     9
#     2:  2014     1     1        -3        13      AA    JFK    LAX      363     2475    11
#     3:  2014     1     1         2         9      AA    JFK    LAX      351     2475    19
#     4:  2014     1     1         2         1      AA    JFK    LAX      350     2475    13
#     5:  2014     1     1        -2       -18      AA    JFK    LAX      338     2475    21
#    ---                                                                                    
# 81479:  2014    10    31        -4       -21      UA    JFK    SFO      337     2586    17
# 81480:  2014    10    31        -2       -37      UA    JFK    SFO      344     2586    18
# 81481:  2014    10    31         0       -33      UA    JFK    LAX      320     2475    17
# 81482:  2014    10    31        -6       -38      UA    JFK    SFO      343     2586     9
# 81483:  2014    10    31        -6       -38      UA    JFK    LAX      323     2475    11

## ou alors
# flights[.("JFK"), on = "origin"] (or)
# flights[list("JFK"), on = "origin"]
```

* Cette instruction effectue également une recherche binaire rapide basée sur le sous-ensemble, en calculant l'index à la volée. Cependant, notez qu'elle n'enregistre pas automatiquement l'index en tant qu'attribut. Cela pourrait changer à l'avenir.

* Si nous avions déjà créé un index secondaire en utilisant `setindex()`, alors `on` le réutiliserait au lieu de le (re)calculer. Nous pouvons le voir en utilisant `verbose = TRUE`:

    
    ```r
    setindex(flights, origin)
    flights["JFK", on = "origin", verbose = TRUE][1:5]
    # i.V1 has same type (character) as x.origin. No coercion needed.
    # on= matches existing index, using index
    # Starting bmerge ...
    # forder.c a reçu 1 lignes et 1 colonnes
    # forderReuseSorting: opt=-1, took 0.000s
    # bmerge: looping bmerge_r took 0.000s
    # bmerge: took 0.000s
    # bmerge done in 0.000s elapsed (0.000s cpu)
    # Constructing irows for '!byjoin || nqbyjoin' ... 0.000s elapsed (0.000s cpu)
    #     year month   day dep_delay arr_delay carrier origin   dest air_time distance  hour
    #    <int> <int> <int>     <int>     <int>  <char> <char> <char>    <int>    <int> <int>
    # 1:  2014     1     1        14        13      AA    JFK    LAX      359     2475     9
    # 2:  2014     1     1        -3        13      AA    JFK    LAX      363     2475    11
    # 3:  2014     1     1         2         9      AA    JFK    LAX      351     2475    19
    # 4:  2014     1     1         2         1      AA    JFK    LAX      350     2475    13
    # 5:  2014     1     1        -2       -18      AA    JFK    LAX      338     2475    21
    ```

#### -- Comment puis-je faire un sous-ensemble basé sur les colonnes `origin` *et* `dest` ?

Par exemple, si nous voulons un sous-ensemble combinant `"JFK" et "LAX"`, alors :


```r
flights[.("JFK", "LAX"), on = c("origin", "dest")][1:5]
#     year month   day dep_delay arr_delay carrier origin   dest air_time distance  hour
#    <int> <int> <int>     <int>     <int>  <char> <char> <char>    <int>    <int> <int>
# 1:  2014     1     1        14        13      AA    JFK    LAX      359     2475     9
# 2:  2014     1     1        -3        13      AA    JFK    LAX      363     2475    11
# 3:  2014     1     1         2         9      AA    JFK    LAX      351     2475    19
# 4:  2014     1     1         2         1      AA    JFK    LAX      350     2475    13
# 5:  2014     1     1        -2       -18      AA    JFK    LAX      338     2475    21
```

* l’argument `on` accepte un vecteur de caractères de noms de colonnes correspondant à l'ordre fourni à `i-argument`.

* Comme le temps de calcul de l'index secondaire est assez faible, nous n'avons pas besoin d'utiliser `setindex()`, sauf si, une fois de plus, la tâche implique un sous-ensemble répété sur la même colonne.

### b) Sélection dans `j`

Toutes les opérations que nous allons discuter ci-dessous ne sont pas différentes de celles que nous avons déjà vues dans la vignette *Clé et recherche binaire rapide basée sur un sous-ensemble*. Sauf que nous utiliserons l'argument `on` au lieu de définir des clés.

#### -- Retourner la colonne `arr_delay` seule en tant que data.table correspondant à `origin = "LGA"` et `dest = "TPA"`


```r
flights[.("LGA", "TPA"), .(arr_delay), on = c("origin", "dest")]
#       arr_delay
#           <int>
#    1:         1
#    2:        14
#    3:       -17
#    4:        -4
#    5:       -12
#   ---          
# 1848:        39
# 1849:       -24
# 1850:       -12
# 1851:        21
# 1852:       -11
```

### c) Chaînage

#### -- Sur la base du résultat obtenu ci-dessus, utilisez le chaînage pour classer la colonne par ordre décroissant.


```r
flights[.("LGA", "TPA"), .(arr_delay), on = c("origin", "dest")][order(-arr_delay)]
#       arr_delay
#           <int>
#    1:       486
#    2:       380
#    3:       351
#    4:       318
#    5:       300
#   ---          
# 1848:       -40
# 1849:       -43
# 1850:       -46
# 1851:       -48
# 1852:       -49
```

### d) Calculer ou *do* dans `j`

#### -- Trouvez le délai d'arrivée maximal correspondant à `origin = "LGA"` et `dest = "TPA"`.


```r
flights[.("LGA", "TPA"), max(arr_delay), on = c("origin", "dest")]
# [1] 486
```

### e) *sous-assignation* par référence en utilisant `:=` dans `j`

Nous avons déjà vu cet exemple dans les vignettes *Sémantique des références* et *Clé et sous-ensemble basé sur la recherche binaire rapide*. Regardons toutes les `heures` disponibles dans le *data.table* `flights` :


```r
# récupère toutes les 'hours' de flights
flights[, sort(unique(hour))]
#  [1]  0  1  2  3  4  5  6  7  8  9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24
```

Nous constatons qu'il y a au total `25` valeurs uniques dans les données. Les heures *0* et *24* semblent être présentes. Remplaçons *24* par *0*, mais cette fois-ci en utilisant `on` au lieu de définir des clés.


```r
flights[.(24L), hour := 0L, on = "hour"]
```

Maintenant, vérifions si `24` est remplacé par `0` dans la colonne `hour`.


```r
flights[, sort(unique(hour))]
#  [1]  0  1  2  3  4  5  6  7  8  9 10 11 12 13 14 15 16 17 18 19 20 21 22 23
```

* C'est notamment un énorme avantage des index secondaires. Auparavant, pour mettre à jour quelques lignes de `hour`, nous devions utiliser `setkey()` sur celui-ci, ce qui réorganisait inévitablement l'ensemble de la data.table. Avec `on`, l'ordre est préservé, et l'opération est beaucoup plus rapide ! En inspectant le code, la tâche que nous voulions effectuer est également assez claire.

### f) Agrégation à l'aide de `by`

#### -- Obtenir le retard maximum au départ pour chaque `mois` correspondant à `origine = "JFK"`. Classer les résultats par `mois`


```r
ans <- flights["JFK", max(dep_delay), keyby = month, on = "origin"]
head(ans)
# Key: <month>
#    month    V1
#    <int> <int>
# 1:     1   881
# 2:     2  1014
# 3:     3   920
# 4:     4  1241
# 5:     5   853
# 6:     6   798
```

* Nous aurions dû remettre `key` à `origin, dest`, si nous n'avions pas utilisé `on` qui construit en interne des index secondaires à la volée.

### g) L'argument *mult*

Les autres arguments, y compris `mult`, fonctionnent exactement de la même manière que nous l'avons vu dans la vignette *Keys and fast binary search based subset*. La valeur par défaut de `mult` est "all". Nous pouvons choisir de ne renvoyer que les "premières" ou "dernières" lignes correspondantes.

#### -- Sous-ensemble contenant uniquement la première ligne correspondante où `dest` correspond à *"BOS"* et *"DAY"*


```r
flights[c("BOS", "DAY"), on = "dest", mult = "first"]
#     year month   day dep_delay arr_delay carrier origin   dest air_time distance  hour
#    <int> <int> <int>     <int>     <int>  <char> <char> <char>    <int>    <int> <int>
# 1:  2014     1     1         3         1      AA    JFK    BOS       39      187    12
# 2:  2014     1     1        25        35      EV    EWR    DAY      102      533    17
```

#### -- Sous-ensemble contenant uniquement la dernière ligne correspondante où `origin` correspond à *"LGA", "JFK", "EWR"* et `dest` correspond à *"XNA"*


```r
flights[.(c("LGA", "JFK", "EWR"), "XNA"), on = c("origin", "dest"), mult = "last"]
#     year month   day dep_delay arr_delay carrier origin   dest air_time distance  hour
#    <int> <int> <int>     <int>     <int>  <char> <char> <char>    <int>    <int> <int>
# 1:  2014    10    31        -5       -11      MQ    LGA    XNA      165     1147     6
# 2:    NA    NA    NA        NA        NA    <NA>    JFK    XNA       NA       NA    NA
# 3:  2014    10    31        -2       -25      EV    EWR    XNA      160     1131     6
```

### h) L'argument *nomatch*

Nous pouvons choisir si les requêtes qui ne correspondent pas doivent retourner `NA` ou être ignorées en utilisant l'argument `nomatch`.

#### -- D'après l'exemple précédent, le sous-ensemble de toutes les lignes n'est pris en compte que s'il y a une correspondance


```r
flights[.(c("LGA", "JFK", "EWR"), "XNA"), mult = "last", on = c("origin", "dest"), nomatch = NULL]
#     year month   day dep_delay arr_delay carrier origin   dest air_time distance  hour
#    <int> <int> <int>     <int>     <int>  <char> <char> <char>    <int>    <int> <int>
# 1:  2014    10    31        -5       -11      MQ    LGA    XNA      165     1147     6
# 2:  2014    10    31        -2       -25      EV    EWR    XNA      160     1131     6
```

* Aucun vol ne relie "JFK" à "XNA". Par conséquent, cette ligne est ignorée dans le résultat.

## 3. Indexation automatique

Dans un premier temps, nous avons étudié comment effectuer un sous-ensemble rapide à l'aide d'une recherche binaire en utilisant des *clés*. Ensuite, nous avons découvert que nous pouvions améliorer encore les performances et avoir une syntaxe plus propre en utilisant des indices secondaires.

C'est ce que fait l'indexation automatique. Pour l'instant, il n'est implémenté que pour les opérateurs binaires `==` et `%in%`. Un indice est automatiquement créé *et* sauvegardé en tant qu'attribut. C'est-à-dire que contrairement à l'argument `on` qui calcule l'indice à la volée à chaque fois (à moins qu'il n'en existe déjà un), un indice secondaire est créé ici.

Commençons par créer un tableau data.table suffisamment grand pour mettre en évidence l'avantage.


```r
set.seed(1L)
dt = data.table(x = sample(1e5L, 1e7L, TRUE), y = runif(100L))
print(object.size(dt), units = "Mb")
# 114.4 Mb
```

Lorsque nous utilisons `==` ou `%in%` sur une seule colonne pour la première fois, un indice secondaire est créé automatiquement, et il est utilisé pour effectuer le sous-ensemble.


```r
## inspection de tous les noms d’attributs
names(attributes(dt))
# [1] "names"             "row.names"         "class"             ".internal.selfref"

## première exécution
(t1 <- system.time(ans <- dt[x == 989L]))
# utilisateur     système      écoulé 
#       0.214       0.005       0.219
head(ans)
#        x         y
#    <int>     <num>
# 1:   989 0.7757157
# 2:   989 0.6813302
# 3:   989 0.2815894
# 4:   989 0.4954259
# 5:   989 0.7885886
# 6:   989 0.5547504

## indice secondaire créé
names(attributes(dt))
# [1] "names"             "row.names"         "class"             ".internal.selfref"
# [5] "index"

indices(dt)
# [1] "x"
```

Le temps nécessaire pour créer un sous-ensemble la première fois est égal au temps nécessaire pour créer l'indice + le temps nécessaire pour créer un sous-ensemble. Étant donné que la création d'un indice secondaire n'implique que la création du vecteur d'ordre, cette opération combinée est plus rapide que les balayages vectoriels dans de nombreux cas. Mais le véritable avantage réside dans les sous-ensembles successifs. Ils sont extrêmement rapides.


```r
## sous-ensembles successifs
(t2 <- system.time(dt[x == 989L]))
# utilisateur     système      écoulé 
#       0.009       0.000       0.009
system.time(dt[x %in% 1989:2012])
# utilisateur     système      écoulé 
#       0.008       0.000       0.008
```

* L'exécution la première fois a pris 0.219 secondes tandis que la deuxième fois, elle a pris 0.009 secondes.

* L'indexation automatique peut être désactivée en définissant l'argument global `options(datatable.auto.index = FALSE)`.

* Désactiver l'indexation automatique permet toujours d'utiliser les index créés explicitement avec `setindex` ou `setindexv`. Vous pouvez désactiver complètement les index en définissant l'argument global `options(datatable.use.index = FALSE)`.

# 

Dans la version récente, nous avons étendu l'indexation automatique aux expressions impliquant plus d'une colonne (combinées avec l'opérateur `&`). Dans le futur, nous prévoyons d'étendre la recherche binaire à d'autres opérateurs binaires comme `<`, `<=`, `>` et `>=`.

Nous aborderons les *sous-ensembles* rapides utilisant des clés et des indices secondaires pour les *joints* dans la prochaine vignette, *"Joints et jointures roulantes"*.

***


