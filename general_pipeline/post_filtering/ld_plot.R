library(ggplot2)
ld <- read.csv("C:/Users/Valeria/Downloads/LD_decay.csv")
ld_sub <- ld[ld$Dist <= 10, ]
ggplot(ld_sub, aes(x=Dist/1000, y=Mean_r2)) +
  geom_line(color="steelblue", linewidth=1) +
  labs(x="Distance (kb)", y=expression(Mean~r^2), title="LD Decay") +
  theme_classic()
