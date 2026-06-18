BiocManager::install('trackViewer')
install.packages("g3viz")
library(trackViewer)
library(g3viz)
library(httr)
library(jsonlite)
library(dplyr)
remotes::install_github("g3viz/g3viz", force = TRUE)

url <- "https://rest.uniprot.org/uniprotkb/Q4WNT5.json"
res <- fromJSON(content(GET(url), "text", encoding = "UTF-8"))

mutation.dat <- readMAF("cyp51A_mutations.maf",
                        gene.symbol.col     = "Hugo_Symbol",
                        variant.class.col   = "Variant_Classification",
                        protein.change.col  = "Protein_Change")


## 1. Agrupar por posición: contar muestras y resolver el fenotipo --------
mut_summary <- mutation.dat %>%
  group_by(AA_Position) %>%
  summarise(
    n_samples = n_distinct(Sample_ID),
    n_phenotypes = n_distinct(Phenotype),
    Phenotype = names(sort(table(Phenotype), decreasing = TRUE))[1],
    Protein_Change = first(Protein_Change),
    .groups = "drop"
  ) %>%
  arrange(AA_Position)

if (any(mut_summary$n_phenotypes > 1)) {
  warning("Hay posiciones con más de un fenotipo entre muestras distintas: ",
          paste(mut_summary$Protein_Change[mut_summary$n_phenotypes > 1], collapse = ", "),
          ". Se usó el fenotipo más frecuente en cada caso.")
}

snp <- mut_summary$AA_Position

## 2. Construir sample.gr con score = conteo y color = fenotipo ------------
sample.gr <- GRanges("chr1",
                     IRanges(snp, width = 1, names = mut_summary$Protein_Change))

sample.gr$score <- mut_summary$n_samples

## Mapeo de color por fenotipo (valores reales confirmados en los datos)
pheno_palette <- c(
  "Resistant"     = "firebrick",
  "Intermediate"  = "darkorange",
  "Susceptible"   = "#A2CD5A",
  "Unknown"       = "grey70"
)

sample.gr$color <- pheno_palette[mut_summary$Phenotype]
sample.gr$color[is.na(sample.gr$color)] <- "grey70" 
sample.gr$label.parameter.rot <- 45
sample.gr$cex <- 1.5
sample.gr$label.parameter.cex <- 0.8

## Mostrar el conteo de muestras DENTRO de cada bolita
sample.gr$node.label <- as.character(sample.gr$score)
sample.gr$node.label.col <- "white"
sample.gr$node.label.cex <- 1.2

## 3. Features de fondo---------------------
feat <- res$features

# Filtrar SIN "HR-1"
feat_bg <- feat[feat$type %in% c("Chain", "Transmembrane"), ]

# Crear GRanges con los features reales
features.gr <- GRanges("chr1",
                       IRanges(start = feat_bg$location$start$value,
                               end   = feat_bg$location$end$value,
                               names = feat_bg$type))

# Añadir dominios manualmente
# HR1
features.gr <- c(features.gr,
                 GRanges("chr1", IRanges(110, 133, names = "HR-1")))

#HR2
features.gr <- c(features.gr,
                 GRanges("chr1", IRanges(447, 461, names = "HR-2")))


# Asignar colores (uno para cada feature)
features.gr$fill <- c("lightblue", "#FFB6C1", "#836FFF", "#FFD700")[seq_len(length(features.gr))]

## 4. Graficar ----------------------------------------------------------------
pdf("lolliplot_cyp.pdf", width = 15, height = 5)
lolliplot(sample.gr, features.gr,
          ranges = GRanges("chr1", IRanges(1, 515)),
          yaxis = FALSE,
          legend = list(labels = names(pheno_palette),
                        col = pheno_palette,
                        fill = pheno_palette))


dev.off()

cat("PDF creado: lolliplot_cyp.pdf\n")

