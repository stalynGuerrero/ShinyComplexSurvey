# ShinyComplexSurvey <img src="inst/img/ShinyComplexSurvey_hex.png" align="right" width="120"/>

**ShinyComplexSurvey** es un paquete de R que proporciona un marco de trabajo
orientado a *tidy* para el análisis de datos de encuestas complejas. Incluye
tanto una API programática como una aplicación Shiny interactiva para análisis
punto-y-clic, sin necesidad de escribir código.

---

## Características principales

- Lectura de microdatos en múltiples formatos: CSV, XLSX, SPSS (`.sav`),
  Stata (`.dta`), RDS.
- Construcción y diagnóstico de diseños de muestreo: aleatorio simple,
  estratificado, por conglomerados y multietápico.
- Estimación de $\bar{y}_w$, $\hat{Y}_w$, $\hat{p}_k$, $\hat{R}$ y
  $\hat{q}_p$ con errores estándar, intervalos de confianza,
  $\widehat{\text{DEFF}}$ y coeficientes de variación correctos bajo
  diseño complejo.
- Estimación por dominios $U_d \subset U$ con varianza calculada sobre
  la muestra completa (sin sesgo por *subsetting*).
- Descarga de resultados en `.csv` y `.xlsx`.
- Interfaz bilingüe: español / inglés.

---

## Marco teórico

### Población, muestra y pesos

Sea $U = \{1, 2, \ldots, N\}$ la población finita de tamaño $N$ y
$s \subset U$ la muestra seleccionada bajo un diseño probabilístico $p(s)$.
Para cada unidad $k \in U$, la probabilidad de inclusión es
$\pi_k = \Pr(k \in s) > 0$.

El **peso básico de diseño** es $d_k = 1/\pi_k$. En la práctica, los
pesos se ajustan por no respuesta o calibración a totales conocidos,
obteniéndose los **pesos ajustados** $w_k$ (variable `weight` en los
microdatos).

### Estimador de Horvitz–Thompson

El estimador HT del total y del tamaño poblacional son:

$$
\hat{Y}_{HT} = \sum_{k \in s} d_k\, y_k, \qquad
\hat{N}_{HT} = \sum_{k \in s} d_k.
$$

Con pesos ajustados, el estimador del total es
$\hat{Y}_w = \sum_{k \in s} w_k\, y_k$ y la **media ponderada** es:

$$
\bar{y}_w = \frac{\hat{Y}_w}{\hat{N}_w}
= \frac{\sum_{k \in s} w_k\, y_k}{\sum_{k \in s} w_k}.
$$

La varianza de $\bar{y}_w$ se estima por linealización de Taylor:

$$
\hat{V}_p\!\left(\bar{y}_w\right) =
\frac{1}{\hat{N}_w^2}\,\hat{V}_p\!\left(\hat{Y}_w\right).
$$

### Diseño estratificado multietápico

Para un diseño con $H$ estratos, $\alpha_h$ unidades primarias de muestreo
(UPM) en el estrato $h$ y $n_{h\alpha}$ observaciones en la UPM $\alpha$:

$$
\hat{Y}_w =
\sum_{h=1}^{H}\sum_{\alpha=1}^{\alpha_h}\sum_{k=1}^{n_{h\alpha}}
\omega_{h\alpha k}\, y_{h\alpha k}, \qquad
\hat{V}_p\!\left(\hat{Y}_w\right) =
\sum_{h=1}^{H} \hat{V}_{p,h}\!\left(\hat{Y}_{w,h}\right).
$$

### Proporción poblacional

Para una variable indicadora $y_k \in \{0,1\}$:

$$
\hat{p} = \frac{\hat{N}_1}{\hat{N}_w}
= \frac{\sum_{h}\sum_{\alpha}\sum_{k} \omega_{h\alpha k}\, I(y_k = 1)}
       {\sum_{h}\sum_{\alpha}\sum_{k} \omega_{h\alpha k}}.
$$

Para variables categóricas multinomiales, la proporción de la categoría $c$ es
$\hat{p}_c = \hat{N}_c / \hat{N}_w$.

### Estimador de razón

$$
\hat{R} = \frac{\hat{Y}_w}{\hat{X}_w}, \qquad
\hat{V}_p(\hat{R}) \approx
\frac{1}{\hat{X}_w^2}\,
\hat{V}_p\!\left(\hat{Y}_w - \hat{R}\,\hat{X}_w\right).
$$

### Efecto de diseño

El **efecto de diseño** (Kish, 1965) mide el incremento de varianza relativo
al muestreo aleatorio simple de igual tamaño:

$$
\widehat{\text{DEFF}} =
\frac{\hat{V}_p(\hat{\theta})}{\hat{V}_{\text{SRS}}(\hat{\theta})}.
$$

Para dominios $U_d$, el efecto de diseño de dominio es:

$$
\widehat{\text{DEFF}}_d =
\frac{\hat{V}_p(\hat{\theta}_d)}{\hat{V}_{\text{SRS}}(\hat{\theta}_d)}.
$$

---

## Instalación

`ShinyComplexSurvey` requiere R ≥ 4.1.0. La forma recomendada de instalar
el paquete y todas sus dependencias es:

```r
install.packages("pak")
pak::pak("stalynGuerrero/ShinyComplexSurvey")
```

O desde una copia local del repositorio:

```r
pak::pak(".")
```

---

## Uso programático

```r
library(ShinyComplexSurvey)

# 1. Generar datos de ejemplo (estructura jerárquica 3 niveles)
data <- generate_example_data(n_upm = 100, seed = 2024)

# 2. Construir el objeto de diseño (estratificado multietápico)
#    weight = w_k,  strata = h,  cluster = alpha
design <- as_survey_design_tbl(
  data    = data,
  weight  = "weight",
  strata  = "strata",
  cluster = "upm",
  nest    = TRUE
)

# 3. Estimar la media por dominio con DEFF e intervalo de confianza
res <- estimate_survey(
  design    = design,
  variable  = "ingreso_pc",
  estimator = "mean",
  by        = "region"
)

# 4. Formatear y visualizar
format_results_table(res, digits = 2)
plot_results_bar(res)
```

---

## Ejecutar la aplicación Shiny

```r
ShinyComplexSurvey::ComplexSurvey_app()
```

La aplicación guía al usuario a través de tres pestañas:

1. **Datos** — carga de archivos o uso de datos de ejemplo integrados.
2. **Diseño muestral** — especificación de $w_k$, estrato $h$ y UPM $\alpha$;
   descripción del diseño con diagnósticos de pesos.
3. **Estimación** — selección de estimador ($\bar{y}_w$, $\hat{Y}_w$,
   $\hat{p}_k$, $\hat{R}$, $\hat{q}_p$), variable objetivo y dominios;
   tabla interactiva y gráfico con indicadores de precisión basados en el $CV$.

---

## Referencias

- Horvitz, D. G. & Thompson, D. J. (1952). *JASA*, 47(260), 663–685.
- Kish, L. (1965). *Survey Sampling*. Wiley.
- Cochran, W. G. (1977). *Sampling Techniques* (3.ª ed.). Wiley.
- Särndal, C.-E., Swensson, B. & Wretman, J. (1992). *Model Assisted Survey Sampling*. Springer.
- Lumley, T. (2010). *Complex Surveys: A Guide to Analysis Using R*. Wiley.
- Heeringa, S. G., West, B. T. & Berglund, P. A. (2017). *Applied Survey Data Analysis* (2.ª ed.). CRC Press.
- Gutiérrez, A., Guerrero, S., Téllez, C. & Babativa, G. (2025). *Análisis de encuestas con R*. <https://psirusteam.github.io/2021ASDA/>
