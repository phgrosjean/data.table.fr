# data.table.r - Translation of data.table in French

The {data.table.fr} package is a trial to provide a French translation of the {data.table} man pages (currently, only `address` is translated, as a proof-of-concept). It uses the experimental [rhelpi18n R package](https://github.com/eliocamp/rhelpi18n).

It also provides the ten vignettes of {data.table} translated in French by using the, also experimental, [rmdpo package](https://github.com/SciViews/rmdpo), see [here](https://github.com/phgrosjean/rfrench/tree/main/data.table/vignettes/fr) for tha translation intermediary files. The {R.rsp} package is used to include this static PDF file as an additional vignette in the package.

Finally, it provides the {data.table} cheatsheet, also translated in French, still in the vignettes directory.

There are currently two warnings on `R CMD CHECK` : a warning about the replacement of `.getHelpFile` by {rhelpi18n} (unavoidable), and a second warning because the `translations` object has no man page (but we should not need one).
