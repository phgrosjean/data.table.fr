---
title: "Restructurer efficacement avec les data.tables"
date: "2024-09-04"
output:
  markdown::html_format
vignette: >
  %\VignetteIndexEntry{Restructurer efficacement avec les data.tables}
  %\VignetteEngine{knitr::knitr}
  \usepackage[utf8]{inputenc}
---



Cette vignette traite de l'utilisation par défaut des fonctions de transformation `melt` (du format large au long) et `dcast` (du format long à large) pour les *data.tables* ainsi que des **nouvelles fonctionnalités étendues** de transformation `melt` et `cast` sur *plusieurs colonnes* disponibles depuis la version `v1.9.6`.

***



## Données

Nous chargerons les ensembles de données directement dans chaque section.

## Introduction

Les fonctions `melt` et `dcast` pour `data.table` sont respectivement utilisées pour la restructuration de large en long et de long en large des données ; les implémentations sont spécifiquement conçues pour gérer de grandes quantités de données en mémoire (par exemple 10Go).

Dans cette vignette, nous allons

1. Examiner brievement l'utilisation par défaut des fonctions de transformation `melt` et `dcast` sur les data.tables pour les convertir du format *large* au format *long* et *vice versa*

2. Examiner des scénarios où les fonctionnalités actuelles deviennent fastidieuses et inefficaces.

3. Enfin, explorer les nouvelles améliorations apportées aux méthodes `melt` et `dcast` pour les objets de type `data.table` afin de gérer plusieurs colonnes simultanément.

Les fonctionnalités étendues sont conformes à la philosophie de `data.table` qui consiste à effectuer des opérations de manière efficace et simple.

## 1. Fonctionnalité par défaut

### a) Transformation (`melt`) des colonnes dans une `data.table` (format large vers long)

Supposons que nous ayons un `data.table` (données artificielles) comme indiqué ci-dessous :


```r
s1 <- "family_id age_mother dob_child1 dob_child2 dob_child3
1         30 1998-11-26 2000-01-29         NA
2         27 1996-06-22         NA         NA
3         26 2002-07-11 2004-04-05 2007-09-02
4         32 2004-10-10 2009-08-27 2012-07-21
5         29 2000-12-05 2005-02-28         NA"
DT <- fread(s1)
DT
#    family_id age_mother dob_child1 dob_child2 dob_child3
#        <int>      <int>     <IDat>     <IDat>     <IDat>
# 1:         1         30 1998-11-26 2000-01-29       <NA>
# 2:         2         27 1996-06-22       <NA>       <NA>
# 3:         3         26 2002-07-11 2004-04-05 2007-09-02
# 4:         4         32 2004-10-10 2009-08-27 2012-07-21
# 5:         5         29 2000-12-05 2005-02-28       <NA>

## dob signifie date de naissance.

str(DT)
# Classes 'data.table' and 'data.frame':	5 obs. of  5 variables:
#  $ family_id : int  1 2 3 4 5
#  $ age_mother: int  30 27 26 32 29
#  $ dob_child1: IDate, format: "1998-11-26" "1996-06-22" ...
#  $ dob_child2: IDate, format: "2000-01-29" NA ...
#  $ dob_child3: IDate, format: NA NA ...
#  - attr(*, ".internal.selfref")=<externalptr>
```

#### - Convertir `DT` en format *long* où chaque `dob` est une observation séparée.

Nous pouvons réaliser ceci en utilisant `melt()` en spécifiant les arguments `id.vars` et `measure.vars` comme suit :


```r
DT.m1 = melt(DT, id.vars = c("family_id", "age_mother"),
                measure.vars = c("dob_child1", "dob_child2", "dob_child3"))
DT.m1
#     family_id age_mother   variable      value
#         <int>      <int>     <fctr>     <IDat>
#  1:         1         30 dob_child1 1998-11-26
#  2:         2         27 dob_child1 1996-06-22
#  3:         3         26 dob_child1 2002-07-11
#  4:         4         32 dob_child1 2004-10-10
#  5:         5         29 dob_child1 2000-12-05
#  6:         1         30 dob_child2 2000-01-29
#  7:         2         27 dob_child2       <NA>
#  8:         3         26 dob_child2 2004-04-05
#  9:         4         32 dob_child2 2009-08-27
# 10:         5         29 dob_child2 2005-02-28
# 11:         1         30 dob_child3       <NA>
# 12:         2         27 dob_child3       <NA>
# 13:         3         26 dob_child3 2007-09-02
# 14:         4         32 dob_child3 2012-07-21
# 15:         5         29 dob_child3       <NA>
str(DT.m1)
# Classes 'data.table' and 'data.frame':	15 obs. of  4 variables:
#  $ family_id : int  1 2 3 4 5 1 2 3 4 5 ...
#  $ age_mother: int  30 27 26 32 29 30 27 26 32 29 ...
#  $ variable  : Factor w/ 3 levels "dob_child1","dob_child2",..: 1 1 1 1 1 2 2 2 2 2 ...
#  $ value     : IDate, format: "1998-11-26" "1996-06-22" ...
#  - attr(*, ".internal.selfref")=<externalptr>
```

* `measure.vars` spécifie l'ensemble des colonnes que nous souhaitons fusionner (ou combiner).

* Nous pouvons également spécifier les *indices* des colonnes au lieu de leurs *noms*.

* Par défaut, la colonne `variable` est de type `facteur`. Mettez l'argument `variable.factor` à `FALSE` si vous souhaitez retourner un vecteur de type *`caractère`* à la place.

* Par défaut, les colonnes fusionnées sont automatiquement nommées `variable` et `value`.

* `melt` préserve les attributs des colonnes.

#### - Nommez les colonnes `variable` et `value` respectivement `child` et `dob`


```r
DT.m1 = melt(DT, measure.vars = c("dob_child1", "dob_child2", "dob_child3"),
               variable.name = "child", value.name = "dob")
DT.m1
#     family_id age_mother      child        dob
#         <int>      <int>     <fctr>     <IDat>
#  1:         1         30 dob_child1 1998-11-26
#  2:         2         27 dob_child1 1996-06-22
#  3:         3         26 dob_child1 2002-07-11
#  4:         4         32 dob_child1 2004-10-10
#  5:         5         29 dob_child1 2000-12-05
#  6:         1         30 dob_child2 2000-01-29
#  7:         2         27 dob_child2       <NA>
#  8:         3         26 dob_child2 2004-04-05
#  9:         4         32 dob_child2 2009-08-27
# 10:         5         29 dob_child2 2005-02-28
# 11:         1         30 dob_child3       <NA>
# 12:         2         27 dob_child3       <NA>
# 13:         3         26 dob_child3 2007-09-02
# 14:         4         32 dob_child3 2012-07-21
# 15:         5         29 dob_child3       <NA>
```

* Par défaut, lorsque l'une des variables `id.vars` ou `measure.vars` est manquante, les autres colonnes sont *automatiquement affectées* à l'argument manquant.

* Lorsque ni `id.vars` ni `measure.vars` ne sont spécifiés, comme mentionné sous `?melt`, toutes les colonnes *non*-`numériques`, `intégrales`, `logiques` seront assignées à `id.vars`.

    De plus, un message d'avertissement est émis pour mettre en évidence les colonnes qui sont automatiquement considérées comme des `id.vars`.

### b) Transformation (`dcast`) des lignes (format long au large)

Dans la section précédente, nous avons vu comment passer de la forme large à la forme longue. Dans cette section, nous verrons l'opération inverse.

#### - Comment revenir à la table de données originale `DT` à partir de `DT.m1` ?

En d'autres termes, nous aimerions collecter toutes les observations *enfants* correspondant à chaque `family_id, age_mother` dans la même ligne. Nous pouvons le faire en utilisant la fonction `dcast` comme suit :


```r
dcast(DT.m1, family_id + age_mother ~ child, value.var = "dob")
# Key: <family_id, age_mother>
#    family_id age_mother dob_child1 dob_child2 dob_child3
#        <int>      <int>     <IDat>     <IDat>     <IDat>
# 1:         1         30 1998-11-26 2000-01-29       <NA>
# 2:         2         27 1996-06-22       <NA>       <NA>
# 3:         3         26 2002-07-11 2004-04-05 2007-09-02
# 4:         4         32 2004-10-10 2009-08-27 2012-07-21
# 5:         5         29 2000-12-05 2005-02-28       <NA>
```

* `dcast` utilise la notation *formule* ( *formula* ). Les variables du côté gauche (*LHS*) de la formule correspondent aux variables *id* et celles sur le côté droit (*RHS*) aux variables *measure*.

* `value.var` indique la colonne à remplir lors du passage au format large.

* `dcast` essaie également de préserver les attributs du résultat dans la mesure du possible.

#### - En partant de `DT.m1`, comment obtenir le nombre d'enfants dans chaque famille ?

Vous pouvez également passer une fonction d'agrégation dans `dcast` avec l'argument `fun.aggregate`. Ceci est particulièrement essentiel lorsque la formule fournie ne permet pas d'identifier une seule observation pour chaque cellule.


```r
dcast(DT.m1, family_id ~ ., fun.agg = function(x) sum(!is.na(x)), value.var = "dob")
# Key: <family_id>
#    family_id     .
#        <int> <int>
# 1:         1     2
# 2:         2     1
# 3:         3     3
# 4:         4     3
# 5:         5     2
```

Voir `?dcast` pour d'autres arguments utiles et des exemples supplémentaires.

## 2. Limitations des approches actuelles `melt/dcast`

Jusqu'à présent, nous avons vu des fonctionnalités de `melt` et `dcast` qui sont implémentées efficacement pour les objets `data.table`, en utilisant la machinerie interne de `data.table` (*tri par base rapide*, *recherche binaire* etc...).

Cependant, il existe des situations où l'opération souhaitée ne s'exprime pas de manière simple. Par exemple, considérons l'objet `data.table` présenté ci-dessous :


```r
s2 <- "family_id age_mother dob_child1 dob_child2 dob_child3 gender_child1 gender_child2 gender_child3
1         30 1998-11-26 2000-01-29         NA             1             2            NA
2         27 1996-06-22         NA         NA             2            NA            NA
3         26 2002-07-11 2004-04-05 2007-09-02             2             2             1
4         32 2004-10-10 2009-08-27 2012-07-21             1             1             1
5         29 2000-12-05 2005-02-28         NA             2             1            NA"
DT <- fread(s2)
DT
#    family_id age_mother dob_child1 dob_child2 dob_child3 gender_child1
#        <int>      <int>     <IDat>     <IDat>     <IDat>         <int>
# 1:         1         30 1998-11-26 2000-01-29       <NA>             1
# 2:         2         27 1996-06-22       <NA>       <NA>             2
# 3:         3         26 2002-07-11 2004-04-05 2007-09-02             2
# 4:         4         32 2004-10-10 2009-08-27 2012-07-21             1
# 5:         5         29 2000-12-05 2005-02-28       <NA>             2
#    gender_child2 gender_child3
#            <int>         <int>
# 1:             2            NA
# 2:            NA            NA
# 3:             2             1
# 4:             1             1
# 5:             1            NA

## 1 = femme, 2 = homme
```

Et vous aimeriez combiner (avec `melt`) toutes les colonnes `dob` ensemble, ainsi que toutes les colonnes `gender` ensemble. Avec la fonctionnalité actuelle, nous pouvons faire quelque chose comme ceci :


```r
DT.m1 = melt(DT, id = c("family_id", "age_mother"))
DT.m1[, c("variable", "child") := tstrsplit(variable, "_", fixed = TRUE)]
DT.c1 = dcast(DT.m1, family_id + age_mother + child ~ variable, value.var = "value")
DT.c1
# Key: <family_id, age_mother, child>
#     family_id age_mother  child        dob     gender
#         <int>      <int> <char>     <IDat>     <IDat>
#  1:         1         30 child1 1998-11-26 1970-01-02
#  2:         1         30 child2 2000-01-29 1970-01-03
#  3:         1         30 child3       <NA>       <NA>
#  4:         2         27 child1 1996-06-22 1970-01-03
#  5:         2         27 child2       <NA>       <NA>
#  6:         2         27 child3       <NA>       <NA>
#  7:         3         26 child1 2002-07-11 1970-01-03
#  8:         3         26 child2 2004-04-05 1970-01-03
#  9:         3         26 child3 2007-09-02 1970-01-02
# 10:         4         32 child1 2004-10-10 1970-01-02
# 11:         4         32 child2 2009-08-27 1970-01-02
# 12:         4         32 child3 2012-07-21 1970-01-02
# 13:         5         29 child1 2000-12-05 1970-01-03
# 14:         5         29 child2 2005-02-28 1970-01-02
# 15:         5         29 child3       <NA>       <NA>

str(DT.c1) ## la colonne 'gender' est un type de caractère maintenant !
# Classes 'data.table' and 'data.frame':	15 obs. of  5 variables:
#  $ family_id : int  1 1 1 2 2 2 3 3 3 4 ...
#  $ age_mother: int  30 30 30 27 27 27 26 26 26 32 ...
#  $ child     : chr  "child1" "child2" "child3" "child1" ...
#  $ dob       : IDate, format: "1998-11-26" "2000-01-29" ...
#  $ gender    : IDate, format: "1970-01-02" "1970-01-03" ...
#  - attr(*, ".internal.selfref")=<externalptr> 
#  - attr(*, "sorted")= chr [1:3] "family_id" "age_mother" "child"
```

#### Problèmes

1. Ce que nous voulions faire était de combiner toutes les colonnes de type `dob` ensemble, et toutes les colonnes de type `gender` ensemble. Au lieu de cela, nous combinons tout, puis nous les scindons à nouveau. On voit aisément que c'est une approche détournée (et inefficace).

    Comme analogie, imaginez un placard avec quatre étagères de vêtements, et vous souhaitez rassembler les vêtements des étagères 1 et 2 (dans l'étagère 1), et ceux des étagères 3 et 4 (dans l'étagère 3). Ce que nous faisons, en quelque sorte, c'est de mélanger tous les vêtements ensemble, puis de les séparer à nouveau sur les étagères 1 et 3 !

2. Les colonnes à transformer (`melt`) peuvent être de types différents, comme c'est le cas ici (types `character` et `integer`). En les transformant toutes ensemble avec `melt`, les colonnes seront forcées d'être du même type, comme l'explique le message d'avertissement ci-dessus, et on le voit dans la sortie de str(DT.c1), où la colonne `gender` a été convertie en type `character`.

3. Nous générons une colonne supplémentaire en scindant la colonne variable en deux colonnes, dont l'utilité est plutôt obscure. Nous faisons cela parce que nous en avons besoin pour la transformation (`cast`) dans l'étape suivante.

4. Enfin, nous transformons le jeu de données. Mais le problème est qu'il s'agit d'une opération beaucoup plus coûteuse en calcul que *melt*. En particulier, il faut calculer l'ordre des variables dans la formule, ce qui est coûteux.

En fait, `stats::reshape` est capable d'effectuer cette opération de manière très simple. C'est une fonction extrêmement utile et souvent sous-estimée. Vous devriez vraiment l'essayer !

## 3. (nouvelle) Fonctionnalité améliorée

### a) `melt` améliorée

Puisque nous aimerions que `data.table` effectue cette opération de façon simple et efficace en utilisant la même interface, nous avons donc implémenté une *fonctionnalité additionnelle*, où nous pouvons appliquer la fonction `melt` sur plusieurs colonnes *simultanément*.

#### - Appliquer `melt` sur plusieurs colonnes simultanément

L'idée est assez simple. Nous passons une liste de colonnes à `measure.vars`, où chaque élément de la liste contient les colonnes qui doivent être combinées ensemble.


```r
colA = paste0("dob_child", 1:3)
colB = paste0("gender_child", 1:3)
DT.m2 = melt(DT, measure = list(colA, colB), value.name = c("dob", "gender"))
DT.m2
#     family_id age_mother variable        dob gender
#         <int>      <int>   <fctr>     <IDat>  <int>
#  1:         1         30        1 1998-11-26      1
#  2:         2         27        1 1996-06-22      2
#  3:         3         26        1 2002-07-11      2
#  4:         4         32        1 2004-10-10      1
#  5:         5         29        1 2000-12-05      2
#  6:         1         30        2 2000-01-29      2
#  7:         2         27        2       <NA>     NA
#  8:         3         26        2 2004-04-05      2
#  9:         4         32        2 2009-08-27      1
# 10:         5         29        2 2005-02-28      1
# 11:         1         30        3       <NA>     NA
# 12:         2         27        3       <NA>     NA
# 13:         3         26        3 2007-09-02      1
# 14:         4         32        3 2012-07-21      1
# 15:         5         29        3       <NA>     NA

str(DT.m2) ## le type de col est préservé
# Classes 'data.table' and 'data.frame':	15 obs. of  5 variables:
#  $ family_id : int  1 2 3 4 5 1 2 3 4 5 ...
#  $ age_mother: int  30 27 26 32 29 30 27 26 32 29 ...
#  $ variable  : Factor w/ 3 levels "1","2","3": 1 1 1 1 1 2 2 2 2 2 ...
#  $ dob       : IDate, format: "1998-11-26" "1996-06-22" ...
#  $ gender    : int  1 2 2 1 2 2 NA 2 1 1 ...
#  - attr(*, ".internal.selfref")=<externalptr>
```

* Nous pouvons supprimer la colonne `variable` si nécessaire.

* Cette fonctionnalité est entièrement implémentée en C, ce qui la rend à la fois *rapide* et *économe en mémoire* en plus d'être *simple à utiliser*.

#### - Utilisation de `patterns()`

En général, dans ce type de problème, les colonnes que l'on souhaite transformer avec `melt` peuvent être distinguées par un motif commun. Nous pouvons utiliser la fonction `patterns()`, implémentée pour faciliter cette tâche, pour fournir des expressions régulières correspondant aux colonnes à combiner ensemble. L'opération ci-dessus peut alors être réécrite comme suit :


```r
DT.m2 = melt(DT, measure = patterns("^dob", "^gender"), value.name = c("dob", "gender"))
DT.m2
#     family_id age_mother variable        dob gender
#         <int>      <int>   <fctr>     <IDat>  <int>
#  1:         1         30        1 1998-11-26      1
#  2:         2         27        1 1996-06-22      2
#  3:         3         26        1 2002-07-11      2
#  4:         4         32        1 2004-10-10      1
#  5:         5         29        1 2000-12-05      2
#  6:         1         30        2 2000-01-29      2
#  7:         2         27        2       <NA>     NA
#  8:         3         26        2 2004-04-05      2
#  9:         4         32        2 2009-08-27      1
# 10:         5         29        2 2005-02-28      1
# 11:         1         30        3       <NA>     NA
# 12:         2         27        3       <NA>     NA
# 13:         3         26        3 2007-09-02      1
# 14:         4         32        3 2012-07-21      1
# 15:         5         29        3       <NA>     NA
```

#### - Utilisation de `measure()` pour spécifier `measure.vars` via un séparateur ou un motif

Si, comme dans les données ci-dessus, les colonnes d'entrée à transformer (`melt `) ont des noms réguliers, alors nous pouvons utiliser `measure`, qui permet de spécifier les colonnes à transformer via un séparateur ou une expression régulière. Par exemple, considérons les données `iris`,


```r
(two.iris = data.table(datasets::iris)[c(1,150)])
#    Sepal.Length Sepal.Width Petal.Length Petal.Width   Species
#           <num>       <num>        <num>       <num>    <fctr>
# 1:          5.1         3.5          1.4         0.2    setosa
# 2:          5.9         3.0          5.1         1.8 virginica
```

Les données iris possèdent quatre colonnes numériques avec une structure régulière : d'abord la partie de la fleur, suivie d'un point, puis le type de mesure. Pour spécifier que nous voulons transformer (`melt`) ces quatre colonnes, nous pouvons utiliser `measure` avec `sep="."` ce qui signifie utiliser `strsplit` sur tous les noms de colonnes ; les colonnes qui résultent en un nombre maximum de groupes après division seront utilisées comme `measure.vars` :


```r
melt(two.iris, measure.vars = measure(part, dim, sep="."))
#      Species   part    dim value
#       <fctr> <char> <char> <num>
# 1:    setosa  Sepal Length   5.1
# 2: virginica  Sepal Length   5.9
# 3:    setosa  Sepal  Width   3.5
# 4: virginica  Sepal  Width   3.0
# 5:    setosa  Petal Length   1.4
# 6: virginica  Petal Length   5.1
# 7:    setosa  Petal  Width   0.2
# 8: virginica  Petal  Width   1.8
```

Les deux premiers arguments de `measure` dans le code ci-dessus (`part` et `dim`) sont utilisés pour nommer les colonnes de sortie ; le nombre d'arguments doit être égal au nombre maximum de groupes après division avec `sep`.

Si nous voulons deux colonnes de valeurs, une pour chaque partie, nous pouvons utiliser le mot-clé spécial `value.name`, qui signifie produire une colonne de valeurs pour chaque nom unique trouvé dans ce groupe :


```r
melt(two.iris, measure.vars = measure(value.name, dim, sep="."))
#      Species    dim Sepal Petal
#       <fctr> <char> <num> <num>
# 1:    setosa Length   5.1   1.4
# 2: virginica Length   5.9   5.1
# 3:    setosa  Width   3.5   0.2
# 4: virginica  Width   3.0   1.8
```

En utilisant le code ci-dessus, nous obtenons une colonne de valeurs par partie de fleur. Si nous voulons une colonne de valeurs pour chaque type de mesure, nous pouvons faire


```r
melt(two.iris, measure.vars = measure(part, value.name, sep="."))
#      Species   part Length Width
#       <fctr> <char>  <num> <num>
# 1:    setosa  Sepal    5.1   3.5
# 2: virginica  Sepal    5.9   3.0
# 3:    setosa  Petal    1.4   0.2
# 4: virginica  Petal    5.1   1.8
```

En revenant à l'exemple des données sur les familles et les enfants, nous pouvons voir une utilisation plus complexe de `measure`, impliquant une fonction utilisée pour convertir les valeurs de la chaîne `child` en entiers :


```r
DT.m3 = melt(DT, measure = measure(value.name, child=as.integer, sep="_child"))
DT.m3
#     family_id age_mother child        dob gender
#         <int>      <int> <int>     <IDat>  <int>
#  1:         1         30     1 1998-11-26      1
#  2:         2         27     1 1996-06-22      2
#  3:         3         26     1 2002-07-11      2
#  4:         4         32     1 2004-10-10      1
#  5:         5         29     1 2000-12-05      2
#  6:         1         30     2 2000-01-29      2
#  7:         2         27     2       <NA>     NA
#  8:         3         26     2 2004-04-05      2
#  9:         4         32     2 2009-08-27      1
# 10:         5         29     2 2005-02-28      1
# 11:         1         30     3       <NA>     NA
# 12:         2         27     3       <NA>     NA
# 13:         3         26     3 2007-09-02      1
# 14:         4         32     3 2012-07-21      1
# 15:         5         29     3       <NA>     NA
```

Dans le code ci-dessus, nous avons utilisé `sep="_child"`, ce qui entraîne la transformation des colonnes uniquement si elle contiennent cette chaîne (six noms de colonnes séparés en deux groupes chacun). L'argument `child=as.integer` signifie que le second groupe donnera lieu à une colonne de sortie nommée `child` avec des valeurs définies en appliquant la fonction `as.integer` aux chaînes de caractères de ce groupe.

Enfin, nous considérons un exemple (emprunté au package tidyr) où nous devons définir les groupes à l'aide d'une expression régulière plutôt qu'un séparateur.


```r
(who <- data.table(id=1, new_sp_m5564=2, newrel_f65=3))
#       id new_sp_m5564 newrel_f65
#    <num>        <num>      <num>
# 1:     1            2          3
melt(who, measure.vars = measure(
  diagnosis, gender, ages, pattern="new_?(.*)_(.)(.*)"))
#       id diagnosis gender   ages value
#    <num>    <char> <char> <char> <num>
# 1:     1        sp      m   5564     2
# 2:     1       rel      f     65     3
```

Lorsque vous utilisez l'argument `pattern`, il doit s'agir d'une expression régulière compatible avec Perl contenant le même nombre de groupes de capture (sous-expressions entre parenthèses) que le nombre d'autres arguments (noms de groupes). Le code ci-dessous montre comment utiliser une expression régulière plus complexe avec cinq groupes, deux colonnes de sortie numériques et une fonction de conversion de type anonyme,


```r
melt(who, measure.vars = measure(
  diagnosis, gender, age,
  ymin=as.numeric,
  ymax=function(y) ifelse(nzchar(y), as.numeric(y), Inf),
  pattern="new_?(.*)_(.)(([0-9]{2})([0-9]{0,2}))"
))
#       id diagnosis gender    age  ymin  ymax value
#    <num>    <char> <char> <char> <num> <num> <num>
# 1:     1        sp      m   5564    55    64     2
# 2:     1       rel      f     65    65   Inf     3
```

### b) `dcast` améliorée

Parfait ! Nous pouvons maintenant transformer (`melt`) plusieurs colonnes simultanément. Maintenant, étant donné le jeu de données `DT.m2`, comment pouvons-nous revenir au même format que le jeu de données avec lequel nous avons commencé ?

Si nous utilisons la fonctionnalité actuelle de `dcast`, nous devrions effectuer la transformation via `cast` deux fois et combiner les résultats. Mais c'est une fois de plus verbeux, compliqué et inefficace.

#### - Transformation (`cast`) de plusieurs `value.var`s simultanément

Nous pouvons désormais fournir **plusieurs colonnes `value.var`** à `dcast` pour les objets `data.table` directement, de sorte que les opérations soient gérées en interne de manière efficace.


```r
## nouvelle fonctionnalité 'cast' - plusieurs value.vars
DT.c2 = dcast(DT.m2, family_id + age_mother ~ variable, value.var = c("dob", "gender"))
DT.c2
# Key: <family_id, age_mother>
#    family_id age_mother      dob_1      dob_2      dob_3 gender_1 gender_2
#        <int>      <int>     <IDat>     <IDat>     <IDat>    <int>    <int>
# 1:         1         30 1998-11-26 2000-01-29       <NA>        1        2
# 2:         2         27 1996-06-22       <NA>       <NA>        2       NA
# 3:         3         26 2002-07-11 2004-04-05 2007-09-02        2        2
# 4:         4         32 2004-10-10 2009-08-27 2012-07-21        1        1
# 5:         5         29 2000-12-05 2005-02-28       <NA>        2        1
#    gender_3
#       <int>
# 1:       NA
# 2:       NA
# 3:        1
# 4:        1
# 5:       NA
```

* Les attributs sont préservés dans le résultat dans la mesure du possible.

* Tout est pris en charge de manière interne et efficace. En plus d'être rapide, il est également très économe en mémoire.

# 

#### Plusieurs fonctions pour `fun.aggregate` :

Vous pouvez également *plusieurs fonctions* à `fun.aggregate` dans `dcast` pour les *data.tables*. Consultez les exemples dans `?dcast` qui illustrent cette fonctionnalité.



# 

***
