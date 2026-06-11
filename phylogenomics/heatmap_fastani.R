# Heatmap de los resultados de FastANI
library(pheatmap)
library(readODS)
library(ggplot2)

# Leer el .ods
mat_df <- read_ods("C:/Users/Valeria/Desktop/resultados_tfm/Ficheros/spades_FastANI/allvsall.ods", sheet=1, col_names=TRUE, row_names=TRUE, as_tibble =  FALSE)

mat <- as.matrix(mat_df)
class(mat) <- "numeric"

# Clusters por muestra
annotation <- data.frame(
  Cluster = factor(c("Cluster1", "Cluster2", "Cluster3", "Cluster4", "Cluster5", "Ref"))
)
rownames(annotation) <- rownames(mat)

# Colores de los clusters
ann_colors <- list(
  Cluster = c(
    Cluster1 = "red",  
    Cluster2 = "#2196F3",  
    Cluster3 = "#2A9D8F",  
    Cluster4 = "purple",  
    Cluster5 = "orange",  
    Ref      = "#808080"   
  )
)

hm <- pheatmap(mat,
         annotation_row = annotation,
         annotation_col = annotation,
         annotation_colors = ann_colors,
         annotation_names_row = FALSE,
         annotation_names_col = FALSE,
         color = colorRampPalette(c("#fff7bc", "#d73027"))(50),
         breaks = seq(99.1, 100, length.out = 51),
         display_numbers = TRUE,
         number_format = "%.2f",
         fontsize_number = 20,
         main = "FastANI all-vs-all",
         cluster_rows = FALSE,
         cluster_cols = FALSE)

ggsave('C:/Users/Valeria/Desktop/resultados_tfm/Figuras/spades_fastani/heatmap_fastani.svg', plot = hm, width = 20, height = 12, units = "in", dpi = 600)
ggsave('C:/Users/Valeria/Desktop/resultados_tfm/Figuras/heatmap_fastani.pdf', plot = hm, width = 20, height = 12, units = "in", dpi = 600)
