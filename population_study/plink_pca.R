# ----------------- PCA WITH COMPLETE METADATA (k = 6)----------------------
library(ggplot2)
library(plotly)
library(readODS)

# Cargar PCA
pca <- read.table("C:/Users/Valeria/Desktop/admixture/pca/pca_maf.eigenvec", header=FALSE)
colnames(pca)[1:5] <- c("FID", "IID", "PC1", "PC2", "PC3")

# Limpiar IID (formato nombre_nombre -> nombre)
pca$IID <- sub("_.*", "", pca$IID)

# Cargar eigenvalores para % varianza explicada
eigenval <- read.table("C:/Users/Valeria/Desktop/admixture/pca/pca_maf.eigenval", header=FALSE)
pve <- round(eigenval$V1 / sum(eigenval$V1) * 100, 1)

# Cargar metadatos
meta <- read_ods("C:/Users/Valeria/Desktop/Afum_metadata.ods", sheet = 4) 
mini_meta <- meta[, c("Sample_Name", "BioinfoName", "Japanese Cluster", "Our Cluster", 
                      "Emilia Cluster", "Azole_susceptibility", "Country_of_origin")]

# Merge PCA + metadata por BioinfoName
df <- merge(pca, mini_meta, by.x = "IID", by.y = "BioinfoName")

# Definir columna de cluster
df$cluster_plot <- as.character(as.integer(df$`Our Cluster`))
df$cluster_plot[is.na(df$cluster_plot)] <- "NA"

# Colores
colores <- c(
  "2" = "red",
  "1" = "#2196F3",
  "5" = "#2A9D8F",
  "4" = "purple",
  "3" = "orange",
  "6" = "navy",
  "NA" = "#CCCCCC"
)

# Plot 3D
plot_ly(data = df,
        x = ~PC1, y = ~PC2, z = ~PC3,
        color = ~cluster_plot,
        colors = colores,
        type = "scatter3d", mode = "markers",
        marker = list(size = 4, opacity = 0.85),
        text = ~paste0("Sample: ", IID,
                       "<br>Cluster: ", cluster_plot,
                       "<br>Country: ", Country_of_origin,
                       "<br>Azole: ", Azole_susceptibility),
        hovertemplate = "%{text}<extra></extra>"
) %>%
  layout(scene = list(
    xaxis = list(title = paste0("PC1 (", pve[1], "%)")),
    yaxis = list(title = paste0("PC2 (", pve[2], "%)")),
    zaxis = list(title = paste0("PC3 (", pve[3], "%)"))
  ),
  title = "PCA 3D coloreado por cluster")

# Plot PC1 and PC2
pc12 <- ggplot(df, aes(x = PC1, y = PC2, color = cluster_plot)) +
  geom_point(alpha = 0.7, size = 2) +
  scale_color_manual(values = colores) +
  labs(
    x = paste0("PC1 (", pve[1], "%)"),
    y = paste0("PC2 (", pve[2], "%)"),
    color = "Cluster"
  ) +
  theme_classic()
pc12
ggsave('multiple5_pc1_2.png', plot = pc12, width = 20, height = 12, units = "in", dpi = 600)
ggsave('multiple5_pc1_2.pdf', plot = pc12, width = 20, height = 12, units = "in", dpi = 600)

# Plot PC1 and PC3
pc13 <- ggplot(df, aes(x = PC1, y = PC3, color = cluster_plot)) +
  geom_point(alpha = 0.7, size = 2) +
  scale_color_manual(values = colores) +
  labs(
    x = paste0("PC1 (", pve[1], "%)"),
    y = paste0("PC3 (", pve[3], "%)"),
    color = "Cluster"
  ) +
  theme_classic()
pc13
ggsave('multiple5_pc1_3.png', plot = pc13, width = 20, height = 12, units = "in", dpi = 600)
ggsave('multiple5_pc1_3.pdf', plot = pc13, width = 20, height = 12, units = "in", dpi = 600)

# Plot PC2 and PC3
pc23 <- ggplot(df, aes(x = PC2, y = PC3, color = cluster_plot)) +
  geom_point(alpha = 0.7, size = 2) +
  scale_color_manual(values = colores) +
  labs(
    x = paste0("PC2 (", pve[2], "%)"),
    y = paste0("PC3 (", pve[3], "%)"),
    color = "Cluster"
  ) +
  theme_classic()
pc23
ggsave('multiple5_pc2_3.png', plot = pc23, width = 20, height = 12, units = "in", dpi = 600)
ggsave('multiple5_pc2_3.pdf', plot = pc23, width = 20, height = 12, units = "in", dpi = 600)


# ----------------- PCA WITH COMPLETE METADATA (k = 5)----------------------
library(ggplot2)
library(plotly)
library(readODS)

# Cargar PCA
pca <- read.table("C:/Users/Valeria/Desktop/admixture/pca/pca_maf.eigenvec", header=FALSE)
colnames(pca)[1:5] <- c("FID", "IID", "PC1", "PC2", "PC3")

# Limpiar IID (formato nombre_nombre -> nombre)
pca$IID <- sub("_.*", "", pca$IID)

# Cargar eigenvalores para % varianza explicada
eigenval <- read.table("C:/Users/Valeria/Desktop/admixture/pca/pca_maf.eigenval", header=FALSE)
pve <- round(eigenval$V1 / sum(eigenval$V1) * 100, 1)

# Cargar metadatos
meta <- read_ods("C:/Users/Valeria/Desktop/Afum_metadata.ods", sheet = 4) 
mini_meta <- meta[, c("Sample_Name", "BioinfoName", "Japanese Cluster", "Our Cluster", 
                      "Emilia Cluster", "Azole_susceptibility", "Country_of_origin")]

# Merge PCA + metadata por BioinfoName
df <- merge(pca, mini_meta, by.x = "IID", by.y = "BioinfoName")

# Definir columna de cluster
df$cluster_plot <- as.character(as.integer(df$`Our Cluster`))
df$cluster_plot[is.na(df$cluster_plot)] <- "NA"

# Colores
colores <- c(
  "2" = "#2196F3",
  "1" = "red",
  "5" = "orange",
  "4" = "purple",
  "3" = "#2A9D8F",
  "6" = "navy",
  "NA" = "#CCCCCC"
)

# Plot 3D
plot_ly(data = df,
        x = ~PC1, y = ~PC2, z = ~PC3,
        color = ~cluster_plot,
        colors = colores,
        type = "scatter3d", mode = "markers",
        marker = list(size = 4, opacity = 0.85),
        text = ~paste0("Sample: ", IID,
                       "<br>Cluster: ", cluster_plot,
                       "<br>Country: ", Country_of_origin,
                       "<br>Azole: ", Azole_susceptibility),
        hovertemplate = "%{text}<extra></extra>"
) %>%
  layout(scene = list(
    xaxis = list(title = paste0("PC1 (", pve[1], "%)")),
    yaxis = list(title = paste0("PC2 (", pve[2], "%)")),
    zaxis = list(title = paste0("PC3 (", pve[3], "%)"))
  ),
  title = "PCA 3D coloreado por cluster")

# Plot PC1 and PC2
pc12 <- ggplot(df, aes(x = PC1, y = PC2, color = cluster_plot)) +
  geom_point(alpha = 0.7, size = 2) +
  scale_color_manual(values = colores) +
  labs(
    x = paste0("PC1 (", pve[1], "%)"),
    y = paste0("PC2 (", pve[2], "%)"),
    color = "Cluster"
  ) +
  theme_classic()
pc12
ggsave('C:/Users/Valeria/Desktop/admixture/pca/multiple5_pc1_2.png', plot = pc12, width = 20, height = 12, units = "in", dpi = 600)
ggsave('C:/Users/Valeria/Desktop/admixture/pca/multiple5_pc1_2.pdf', plot = pc12, width = 20, height = 12, units = "in", dpi = 600)


ggplotly(pc12 + aes(text = IID), tooltip = "text")

# Plot PC1 and PC3
pc13 <- ggplot(df, aes(x = PC1, y = PC3, color = cluster_plot)) +
  geom_point(alpha = 0.7, size = 2) +
  scale_color_manual(values = colores) +
  labs(
    x = paste0("PC1 (", pve[1], "%)"),
    y = paste0("PC3 (", pve[3], "%)"),
    color = "Cluster"
  ) +
  theme_classic()
pc13
ggsave('multiple5_pc1_3.png', plot = pc13, width = 20, height = 12, units = "in", dpi = 600)
ggsave('multiple5_pc1_3.pdf', plot = pc13, width = 20, height = 12, units = "in", dpi = 600)

# Plot PC2 and PC3
pc23 <- ggplot(df, aes(x = PC2, y = PC3, color = cluster_plot)) +
  geom_point(alpha = 0.7, size = 2) +
  scale_color_manual(values = colores) +
  labs(
    x = paste0("PC2 (", pve[2], "%)"),
    y = paste0("PC3 (", pve[3], "%)"),
    color = "Cluster"
  ) +
  theme_classic()
pc23
ggsave('multiple5_pc2_3.png', plot = pc23, width = 20, height = 12, units = "in", dpi = 600)
ggsave('multiple5_pc2_3.pdf', plot = pc23, width = 20, height = 12, units = "in", dpi = 600)