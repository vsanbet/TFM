# --- ARBOL CON NUESTROS CLUSTERS DE ADMIXTURE ---
# Cargar librerías
library(tidyverse)
library(ggtree)
library(RColorBrewer)
library(ggnewscale)
library(viridis)
library(ape)
library(colorspace)
library(readODS)
library(Polychrome)
library(colorBlindness)

# cargar el fichero .treefile
setwd('C:/Users/Valeria/Desktop/trees/cyp51')
tree <- read.tree('C:/Users/Valeria/Desktop/resultados_tfm/Ficheros/cyp51a/arbol/Afu4g06890_aa_alineado.fasta.contree')

# Añadir el metadata:
# formato rows = muestras, cols = metadata (col1 cluster, col2 pais, col3 resistencia)
metadata <- read_ods('C:/Users/Valeria/Desktop/Afum_metadata.ods', sheet = 'final_metadata')
metadata <- data.frame(metadata)

metadata$Our.Cluster <- gsub("\\.0$", "", as.character(metadata$Our.Cluster))
metadata$Japanese.Cluster <- gsub("\\.0$", "", as.character(metadata$Japanese.Cluster))
metadata$Emilia.Cluster <- gsub("\\.0$", "", as.character(metadata$Emilia.Cluster))


metadata$Our.Cluster      <- factor(metadata$Our.Cluster,      levels = c('1','2','3','4','5'))
metadata$Japanese.Cluster <- factor(metadata$Japanese.Cluster, levels = c('1','2','3','4','5','6'))
metadata$Emilia.Cluster   <- factor(metadata$Emilia.Cluster,   levels = c('1','2','3','4'))
metadata$Mutation_group <- factor(metadata$Mutation_group, levels = c('WT', '3 SNPs', '5 SNPs', 'puntual', '-', 'TR'))

# Verificar
table(metadata$Our.Cluster)

rownames(metadata) <- metadata$BioinfoName
metadata <- metadata[, c('Sample_Name','BioinfoName', 'Country_of_origin', 'Azole_susceptibility', 'Our.Cluster', 'Japanese.Cluster', 'Emilia.Cluster', 'Mutation_group', 'Source')]
rownames(metadata) <- gsub("/", "-", rownames(metadata))
dim(metadata)
rownames(metadata)
rownames(metadata) <- gsub("/", "-", rownames(metadata))
colnames(metadata)


jap_cluster_colors <- setNames(brewer.pal(6, "Set1"),
                               levels(metadata$Japanese.Cluster))

azole_colors <- c("I" = "green",  
                  "R" = "yellow", 
                  "S" = "red")    


metadata$Country_of_origin <- factor(metadata$Country_of_origin)
n_countries <- length(levels(factor(metadata$Country_of_origin)))
country_colors <- setNames(
  colorRampPalette(brewer.pal(12, "Paired"))(n_countries),
  sort(unique(metadata$Country_of_origin))
)

emilia_colours <- setNames(brewer.pal(4, 'Set2'),
                           levels(metadata$Emilia.Cluster))

n_cyp <- length(levels(factor(metadata$cyp51A_mutations)))

# install.packages("Polychrome")
library(Polychrome)

# Crear paleta de 39 colores muy distintos
set.seed(42)  # para reproducibilidad
paleta39 <- createPalette(35, 
                          seedcolors = c("#ff0000", "#00ff00", "#0000ff"),
                          range = c(30, 80))

cyp_groups <- c(colorBlindness::paletteMartin, c("WT" = "#2F4F4F", "3 SNPs" = "#FFFF6D", "5 SNPs" = "#490092", "TR" = '#A52A2A', "-" = 'orange', 'puntual' = 'pink'))

n_source <- length(levels(factor(metadata$Source)))

source_colors <- c("CL" = "#98F5FF", "AGR" = "#76EE00", "Air" = "#FFF68F", "CNPA" = "#EEE0E5",
                   "ENV" = "#6B8E23", "PA" = "#FF4500", "VET" = "#836FFF")




# Verificar que el árbol está enraizado
print(tree)

# Mantener solo las muestras que están en el árbol
metadata2 <- metadata[rownames(metadata) %in% tree$tip.label, ]

# Ahora reordenar correctamente
metadata2 <- metadata2[tree$tip.label, ]

# Verificar
all(rownames(metadata2) == tree$tip.label)


# Árbol circular
# Crear dataframe auxiliar para etiquetas
label_df <- data.frame(
  BioinfoName = tree$tip.label,
  Sample_Name = metadata2$Sample_Name
)

shared_colors <- c(
  "1" = "#E41A1C",
  "2" = "#377EB8",
  "3" = "#4DAF4A",
  "4" = "#984EA3",
  "5" = "#FF7F00",
  "6" = "#A65628"
)


our_cluster_colours <-  c(
  "2" = "#E41A1C",
  "1" = "#377EB8",
  "5" = "#4DAF4A",
  "4" = "#984EA3",
  "3" = "#FF7F00",
  "6" = "#A65628"
)


# ---- VISUALIZACIÓN CON ÁRBOL CIRCULAR ----
label_df <- data.frame(
  BioinfoName = tree$tip.label,
  Sample_Name = metadata2$Sample_Name
)

circ <- ggtree(tree, layout = 'circular', size = 0.1) %<+% label_df +
  geom_tiplab(aes(label = Sample_Name),
              size = 1.5,
              offset = 0.003,
              align = TRUE,
              linesize = 0,
              branch.length = "none") +
  theme(legend.position = "right") +   geom_text2(aes(subset = !isTip, label = label), 
                                                  size = 2, 
                                                  hjust = 1.3,  
                                                  vjust = -0.5)   


# Azole susceptibility
p2 <- gheatmap(circ,
               metadata2['Azole_susceptibility'],
               offset = 0.0001,
               width = 0.045,
               color = NA,
               colnames_angle = 90,
               colnames = TRUE,
               font.size = 2) +
  scale_fill_manual(values = azole_colors,
                    name = "Azole susceptibility",
                    na.value = "grey") +
  new_scale_fill()

# MUTATION GROUP
p8 <- gheatmap(p2,
               metadata2['Mutation_group'],
               offset = 0.001,
               width = 0.045,
               color = NA,
               colnames_angle = 90,
               colnames = TRUE,
               font.size = 2) +
  scale_fill_manual(values = cyp_groups,
                    name = "Cyp groups",
                    na.value = "grey") +
  new_scale_fill()

# # Emilia's clusters
# p7 <- gheatmap(p8,
#                metadata2['Emilia.Cluster'],
#                offset = 0.0009,
#                width = 0.05,
#                color = NA,
#                colnames_angle = 90,
#                colnames = TRUE,
#                font.size = 2) +
#   scale_fill_manual(values = emilia_colours,
#                     name = "Emilia Cluster",
#                     na.value = "grey")
# 

# Our Cluster
p7 <- gheatmap(p8,
               metadata2['Our.Cluster'],
               offset = 0.0017,
               width = 0.045,
               color = NA,
               colnames_angle = 90,
               colnames = TRUE,
               font.size = 2) +
  scale_fill_manual(values = shared_colors,
                    name = "Our Cluster",
                    na.value = "grey") +
  new_scale_fill()

p7
ggsave("C:/Users/Valeria/Desktop/resultados_tfm/Figuras/cyp51a/cyp_tree.svg", plot = p7, width = 14, height = 14, units = "in", dpi = 600)
ggsave("C:/Users/Valeria/Desktop/resultados_tfm/Figuras/cyp51a/cyp_tree.pdf", plot = p7, width = 14, height = 14, units = "in", dpi = 600)

# mutations cyp
p9 <- gheatmap(p7,
               metadata2['Mutation_group'],
               offset = 0.0012,
               width = 0.05,
               color = NA,
               colnames_angle = 90,
               colnames = TRUE,
               font.size = 2) +
  scale_fill_manual(values = cyp_cluster,
                    name = "Mutation",
                    na.value = "grey")

p9

ggsave("cyp_tree.png", plot = p9, width = 14, height = 14, units = "in", dpi = 600)
ggsave("cyp_tree.pdf", plot = p9, width = 14, height = 14, units = "in", dpi = 600)

