mod_estimacion_server <- function(id, design) {
  
  shiny::moduleServer(id, function(input, output, session) {
    
    output$theory_box <- shiny::renderUI({
      
      shiny::req(input$estimator)
      
      theory_text <- switch(
        
        input$estimator,
        
        # =========================================================
        # MEDIA
        # =========================================================
        "mean" = "

<b>Media poblacional bajo dise\u00f1o complejo</b><br><br>

Si \\(y_k\\) denota el valor de una variable de inter\u00e9s para la unidad \\(k \\in U\\), la media poblacional se define como:

$$
\\bar{Y} = \\frac{Y}{N} = \\frac{\\sum_{U} y_k}{N}
$$

Dado que solo se observa una muestra \\(s \\subset U\\), el estimador de la media poblacional se obtiene como el cociente entre el estimador de Horvitz\u2013Thompson del total y el tama\u00f1o poblacional estimado:

$$
\\bar{y}_{HT} =
\\frac{\\hat{Y}_{HT}}{\\hat{N}_{HT}} =
\\frac{\\sum_{s} w_k \\, y_k}
     {\\sum_{s} w_k}
$$

donde:

<ul>
<li>\\(d_k = 1/\\pi_k\\) son los pesos b\u00e1sicos de dise\u00f1o</li>
<li>\\(\\pi_k = \\Pr(k \\in s)\\) es la probabilidad de inclusi\u00f3n de primer orden</li>
<li>\\(w_k\\) son los pesos ajustados (por no respuesta y/o calibraci\u00f3n)</li>
<li>\\(y_k\\) es la variable de inter\u00e9s para la unidad \\(k\\)</li>
</ul>

<br>

<b>Varianza aproximada</b>

Dado que \\(\\bar{y}_{HT}\\) es un estimador no lineal (cociente de dos estimadores), su varianza se aproxima mediante la t\u00e9cnica de <b>linealizaci\u00f3n de Taylor</b> o m\u00e9todos de replicaci\u00f3n (Bootstrap, Jackknife, BRR).

<br><br>

<b>Referencia:</b> Guti\u00e9rrez, A., Guerrero, S., T\u00e9llez, C. & Babativa, G.
<i>An\u00e1lisis de encuestas con R</i>, Cap. 2.7 y 4.3.
<a href='https://psirusteam.github.io/2021ASDA/' target='_blank'>psirusteam.github.io/2021ASDA</a>

",
        
        # =========================================================
        # TOTAL
        # =========================================================
        "total" = "

<b>Total poblacional</b><br><br>

Si \\(y_k\\) denota el valor de una variable de inter\u00e9s para la unidad \\(k \\in U\\), el total poblacional se define como:

$$
Y = \\sum_{U} y_k
$$

Dado que solo se observa una muestra \\(s \\subset U\\), el estimador de Horvitz\u2013Thompson (HT) se expresa como:

$$
\\hat{Y}_{HT} = \\sum_{s} d_k \\, y_k
$$

donde:

<ul>
<li>\\(d_k = 1/\\pi_k\\) son los pesos b\u00e1sicos de dise\u00f1o</li>
<li>\\(\\pi_k = \\Pr(k \\in s)\\) es la probabilidad de inclusi\u00f3n de primer orden</li>
</ul>

En la pr\u00e1ctica, los pesos de dise\u00f1o suelen modificarse para reflejar ajustes por no respuesta o calibraci\u00f3n, obteniendo los pesos ajustados \\(w_k\\). De esta forma:

$$
\\hat{Y} = \\sum_{s} w_k \\, y_k
$$

<b>Varianza bajo el enfoque de dise\u00f1o</b>

$$
\\hat{V}_p(\\hat{Y}_{HT}) =
\\sum_{k \\in s} \\sum_{l \\in s}
\\left( d_k \\, d_l - d_{kl} \\right)
y_k \\, y_l
$$

donde \\(d_{kl} = 1/\\pi_{kl}\\) y \\(\\pi_{kl} = \\Pr(k, l \\in s)\\) representan las probabilidades conjuntas de inclusi\u00f3n.

<br>

En la pr\u00e1ctica, esta varianza se estima mediante el <b>m\u00e9todo linealizado</b>, la <b>replicaci\u00f3n</b> o el <b>bootstrap</b>.

<br><br>

<b>Referencia:</b> Guti\u00e9rrez, A., Guerrero, S., T\u00e9llez, C. & Babativa, G.
<i>An\u00e1lisis de encuestas con R</i>, Cap. 2.7.
<a href='https://psirusteam.github.io/2021ASDA/' target='_blank'>psirusteam.github.io/2021ASDA</a>

",
        
        # =========================================================
        # PROPORCI\u00d3N
        # =========================================================
        "prop" = "

<b>Proporci\u00f3n poblacional</b><br><br>

De acuerdo con Heeringa, West y Berglund (2017), al transformar las categor\u00edas de respuesta en variables indicadoras con valores 1 y 0, la proporci\u00f3n estimada para la categor\u00eda \\(d\\) se obtiene mediante:

$$
\\hat{p}_d =
\\frac{\\hat{N}_d}{\\hat{N}} =
\\frac{\\displaystyle\\sum_{h=1}^{H} \\sum_{\\alpha \\in s_{1h}} \\sum_{k \\in s_{h\\alpha}} w_{h\\alpha k} \\, I(y_{h\\alpha k} = d)}
     {\\displaystyle\\sum_{h=1}^{H} \\sum_{\\alpha \\in s_{1h}} \\sum_{k \\in s_{h\\alpha}} w_{h\\alpha k}}
$$

donde:

<ul>
<li>\\(h = 1, \\ldots, H\\) indexa los estratos</li>
<li>\\(\\alpha\\) indexa las UPM seleccionadas en el estrato \\(h\\)</li>
<li>\\(k\\) indexa las unidades dentro de la UPM</li>
<li>\\(w_{h\\alpha k}\\) son los pesos de muestreo</li>
<li>\\(I(y_{h\\alpha k} = d)\\) es la funci\u00f3n indicadora</li>
</ul>

Dado que se trata de un estimador no lineal, su varianza se aproxima mediante la <b>t\u00e9cnica de linealizaci\u00f3n de Taylor</b>, utilizando como funci\u00f3n de estimaci\u00f3n:

$$
z_{h\\alpha k} = I(y_{h\\alpha k} = d) - \\hat{p}_d
$$

<br>

Cuando las proporciones se aproximan a 0 o 1, se recomienda aplicar la <b>transformaci\u00f3n logit</b> para asegurar que los intervalos de confianza permanezcan dentro del rango [0, 1].

<br><br>

<b>Referencia:</b> Guti\u00e9rrez, A., Guerrero, S., T\u00e9llez, C. & Babativa, G.
<i>An\u00e1lisis de encuestas con R</i>, Cap. 5.2.
<a href='https://psirusteam.github.io/2021ASDA/' target='_blank'>psirusteam.github.io/2021ASDA</a>

",
        
        # =========================================================
        # RAZ\u00d3N
        # =========================================================
        "ratio" = "

<b>Estimador de raz\u00f3n</b><br><br>

La raz\u00f3n poblacional se define como el cociente de dos totales poblacionales:

$$
R = \\frac{Y}{X}
$$

Su estimador puntual en el marco de un muestreo complejo se expresa como:

$$
\\hat{R} = \\frac{\\hat{Y}}{\\hat{X}} =
\\frac{\\displaystyle\\sum_{h=1}^{H} \\sum_{\\alpha=1}^{a_h} \\sum_{k=1}^{n_{h\\alpha}} w_{h\\alpha k} \\, y_{h\\alpha k}}
     {\\displaystyle\\sum_{h=1}^{H} \\sum_{\\alpha=1}^{a_h} \\sum_{k=1}^{n_{h\\alpha}} w_{h\\alpha k} \\, x_{h\\alpha k}}
$$

donde:

<ul>
<li>\\(h = 1, \\ldots, H\\) indexa los estratos</li>
<li>\\(\\alpha = 1, \\ldots, a_h\\) indexa las UPM seleccionadas en el estrato \\(h\\)</li>
<li>\\(k = 1, \\ldots, n_{h\\alpha}\\) indexa las unidades en la UPM</li>
<li>\\(w_{h\\alpha k}\\) son los pesos de muestreo</li>
<li>\\(y_{h\\alpha k}\\) es la variable del numerador</li>
<li>\\(x_{h\\alpha k}\\) es la variable del denominador</li>
</ul>

<br>

<b>Varianza aproximada (linealizaci\u00f3n de Taylor)</b>

Dado que \\(\\hat{R}\\) es un cociente de dos variables aleatorias, su varianza se estima empleando la linealizaci\u00f3n de Taylor con la funci\u00f3n de estimaci\u00f3n:

$$
z_{h\\alpha k} = y_{h\\alpha k} - \\hat{R} \\, x_{h\\alpha k}
$$

<br>

<b>Casos particulares utilizados en la aplicaci\u00f3n</b>

<br>

<b>1. Raz\u00f3n entre categor\u00edas</b><br>
Ejemplo: proporci\u00f3n de hombres respecto a mujeres.

$$
\\hat{R} =
\\frac{\\sum_{s} w_k \\, I(\\text{hombre})}
     {\\sum_{s} w_k \\, I(\\text{mujer})}
$$

<br>

<b>2. Variable continua sobre categor\u00eda</b><br>
Ejemplo: ingreso promedio de los hombres.

$$
\\hat{R} =
\\frac{\\sum_{s} w_k \\, ingreso_k}
     {\\sum_{s} w_k \\, I(\\text{hombre})}
$$

<br>

<b>3. Raz\u00f3n entre variables continuas</b><br>
Ejemplo: relaci\u00f3n gasto / ingreso.

$$
\\hat{R} =
\\frac{\\sum_{s} w_k \\, gasto_k}
     {\\sum_{s} w_k \\, ingreso_k}
$$

<br>

<b>Interpretaci\u00f3n</b>

El estimador de raz\u00f3n es especialmente eficiente cuando existe
una fuerte correlaci\u00f3n entre \\(Y\\) y \\(X\\), ya que el denominador
act\u00faa como variable auxiliar reduciendo la varianza del estimador.

<br><br>

<b>Referencia:</b> Guti\u00e9rrez, A., Guerrero, S., T\u00e9llez, C. & Babativa, G.
<i>An\u00e1lisis de encuestas con R</i>, Cap. 4.8.
<a href='https://psirusteam.github.io/2021ASDA/' target='_blank'>psirusteam.github.io/2021ASDA</a>

",
        
        # =========================================================
        # CUANTILES
        # =========================================================
        "quantile" = "

<b>Cuantiles ponderados</b><br><br>

Los cuantiles poblacionales se definen a partir de la funci\u00f3n de distribuci\u00f3n acumulada ponderada. Dado un conjunto de unidades en la muestra \\(s\\) con pesos \\(w_k\\):

$$
F_w(y) =
\\frac{\\sum_{s} w_k \\, I(y_k \\le y)}{\\sum_{s} w_k}
$$

El cuantil \\(q_p\\) de orden \\(p\\) satisface:

$$
F_w(q_p) = p
$$

Los cuantiles ponderados permiten estimar percentiles de la distribuci\u00f3n poblacional bajo dise\u00f1os complejos, incorporando los pesos de muestreo \\(w_k\\) para reflejar adecuadamente la estructura del dise\u00f1o.

La varianza suele estimarse mediante:

<ul>
<li>Linealizaci\u00f3n de Woodruff</li>
<li>M\u00e9todos de replicaci\u00f3n (Bootstrap, Jackknife, BRR)</li>
</ul>

<br>

<b>Referencia:</b> Guti\u00e9rrez, A., Guerrero, S., T\u00e9llez, C. & Babativa, G.
<i>An\u00e1lisis de encuestas con R</i>, Cap. 3.11 y 4.3.4.
<a href='https://psirusteam.github.io/2021ASDA/' target='_blank'>psirusteam.github.io/2021ASDA</a>

",
        
        # =========================================================
        # DEFAULT
        # =========================================================
        "Seleccione un estimador para visualizar su marco te\u00f3rico."
        
      )
      
      shiny::tagList(
        
        shiny::withMathJax(),
        
        shiny::div(
          style = "
        background-color:#f8f9fa;
        padding:20px;
        border-radius:10px;
        font-size:14px;
      ",
          shiny::HTML(theory_text)
        )
        
      )
    })
    
    observeEvent(input$estimator, {
      
      if (input$estimator == "ratio") {
        updateSelectInput(session, "y_var", selected = NULL)
      }
      
    })
    
    output$quality_theory <- shiny::renderUI({
      
      shiny::withMathJax(
        
        shiny::div(
          style="
      background:#f8f9fa;
      padding:20px;
      border-radius:10px;
      font-size:14px;
      ",
          
          shiny::HTML("
<b>Coeficiente de Variaci\u00f3n (CV)</b><br><br>

El coeficiente de variaci\u00f3n mide la precisi\u00f3n relativa del estimador y es una herramienta indispensable para evaluar la confiabilidad de las estimaciones.

$$
cv(\\hat{\\theta}) =
\\frac{se(\\hat{\\theta})}{\\hat{\\theta}}
$$

En porcentaje:

$$
cv(\\hat{\\theta}) =
\\frac{se(\\hat{\\theta})}{\\hat{\\theta}} \\times 100
$$

<br>

<b>Interpretaci\u00f3n</b>

<ul>
<li><b>&lt; 5%</b> \u2192 Muy alta precisi\u00f3n</li>
<li><b>5% \u2013 10%</b> \u2192 Alta precisi\u00f3n</li>
<li><b>10% \u2013 20%</b> \u2192 Precisi\u00f3n aceptable</li>
<li><b>20% \u2013 30%</b> \u2192 Uso con cautela</li>
<li><b>&gt; 30%</b> \u2192 Baja precisi\u00f3n</li>
</ul>

<br>

<hr>

<b>Efecto de dise\u00f1o (DEFF)</b><br><br>

El efecto de dise\u00f1o fue definido por Kish (1965) como la relaci\u00f3n entre la varianza del estimador bajo el dise\u00f1o de muestreo complejo \\(p(s)\\) y la varianza bajo un muestreo aleatorio simple (MAS) del mismo tama\u00f1o:

$$
DEFF(\\hat{\\theta}) =
\\frac{Var_p(\\hat{\\theta})}
{Var_{MAS}(\\hat{\\theta})}
$$

Su estimaci\u00f3n est\u00e1 dada por:

$$
\\widehat{DEFF} =
\\frac{\\widehat{Var}(\\hat{\\theta})}
{\\widehat{Var}_{MAS}(\\hat{\\theta})}
$$

donde \\(\\hat{\\theta}\\) puede ser un total, una media, una proporci\u00f3n, una raz\u00f3n, un percentil, etc.

<br>

<b>Tama\u00f1o de muestra efectivo</b>

$$
n_{eff} =
\\frac{n}{DEFF}
$$

<br>

<b>Nota:</b> El DEFF depende tanto del dise\u00f1o muestral \\(p(s)\\) como del par\u00e1metro \\(\\theta\\). Un mismo dise\u00f1o puede tomar diferentes valores de DEFF seg\u00fan el par\u00e1metro que se estime.

<br>
<hr><b>Referencias</b>
                 <ul>
                 <li>Guti\u00e9rrez, A., Guerrero, S., T\u00e9llez, C. & Babativa, G. <i>An\u00e1lisis de encuestas con R</i>.
                 <a href='https://psirusteam.github.io/2021ASDA/' target='_blank'>psirusteam.github.io/2021ASDA</a></li>
                 <li>Kish, L. (1965). <i>Survey Sampling</i>. John Wiley & Sons.</li>
                 <li>S\u00e4rndal, C., Swensson, B., & Wretman, J. (2003). <i>Model Assisted Survey Sampling</i>. Springer.</li>
                 <li>Heeringa, S., West, B. & Berglund, P. (2017). <i>Applied Survey Data Analysis</i>. Chapman & Hall.</li>
                 <li>Lumley, T. (2010). <i>Complex Surveys: A Guide to Analysis Using R</i>. Wiley.</li>
                 </ul>
")
        )
      )
    })
    
    
    ns <- session$ns
    
    # ==================================================
    # 1. Actualizar selectores desde el dise\u00f1o
    # ==================================================
    shiny::observeEvent(design(), {
      
      des <- design()
      shiny::req(des)
      shiny::req(!is.null(des$variables))
      
      vars <- names(des$variables)
      shiny::req(length(vars) > 0)
      
      shiny::updateSelectInput(session, "y_var",       choices = vars)
      shiny::updateSelectInput(session, "numerator",   choices = vars)
      shiny::updateSelectInput(session, "denominator", choices = vars)
      shiny::updateSelectInput(session, "domain_vars", choices = c("Ninguno" = "", vars))
    })
    
    # ==================================================
    # 1b. Filtrar variables seg\u00fan tipo de estimador
    # ==================================================
    shiny::observeEvent(list(design(), input$estimator), {
      
      des <- design()
      shiny::req(des)
      shiny::req(!is.null(des$variables))
      shiny::req(input$estimator)
      
      vars <- des$variables
      
      if (input$estimator %in% c("mean", "total", "quantile")) {
        valid_vars <- names(vars)[sapply(vars, is.numeric)]
      } else {
        valid_vars <- names(vars)
      }
      
      shiny::updateSelectInput(session, "y_var", choices = valid_vars)
      
    }, ignoreInit = TRUE)
    
    # ==================================================
    # 2. UI din\u00e1mica para ratio categ\u00f3rica
    # ==================================================
    output$ratio_levels_ui <- shiny::renderUI({
      
      shiny::req(input$estimator == "ratio")
      shiny::req(input$numerator, input$denominator)
      shiny::req(design())
      
      vars <- design()$variables
      
      num_is_cat <- is.factor(vars[[input$numerator]]) ||
        is.character(vars[[input$numerator]])
      
      den_is_cat <- is.factor(vars[[input$denominator]]) ||
        is.character(vars[[input$denominator]])
      
      ui <- list()
      
      if (num_is_cat) {
        ui <- c(ui, list(
          shiny::selectInput(
            ns("ratio_num_level"),
            "Categor\u00eda (numerador)",
            choices = sort(unique(stats::na.omit(vars[[input$numerator]])))
          )
        ))
      }
      
      if (den_is_cat) {
        ui <- c(ui, list(
          shiny::selectInput(
            ns("ratio_den_level"),
            "Categor\u00eda (denominador)",
            choices = sort(unique(stats::na.omit(vars[[input$denominator]])))
          )
        ))
      }
      
      if (length(ui) == 0) return(NULL)
      shiny::tagList(ui)
    })
    
    
    # ==================================================
    # 3. Ejecutar estimaci\u00f3n
    # ==================================================
    results_r <- shiny::eventReactive(input$run, {
      
      des <- design()
      shiny::req(des, input$estimator)
      
      domain <- input$domain_vars
      if (length(domain) == 0 || all(domain == "")) domain <- NULL
      
      # ---- Ratio ----
      if (input$estimator == "ratio") {
        
        num <- input$numerator
        den <- input$denominator
        shiny::req(num, den)
        
        vars <- design()$variables
        
        num_is_cat <- is.factor(vars[[num]]) || is.character(vars[[num]])
        den_is_cat <- is.factor(vars[[den]]) || is.character(vars[[den]])
        
        return(
          estimate_survey(
            design      = des,
            estimator   = "ratio",
            by          = domain,
            numerator   = num,
            denominator = den,
            ratio_num_level = if (num_is_cat) input$ratio_num_level else NULL,
            ratio_den_level = if (den_is_cat) input$ratio_den_level else NULL
          )
        )
      }
      
      # ---- Cuantiles ----
      if (input$estimator == "quantile") {
        
        shiny::req(input$y_var)
        probs <- trimws(unlist(strsplit(input$probs, ",")))
        probs <- sort(unique(as.numeric(probs)))
        shiny::req(length(probs) > 0, !any(is.na(probs)))
        
        return(
          estimate_survey(
            design    = des,
            estimator = "quantile",
            variable  = input$y_var,
            by        = domain,
            probs     = probs
          )
        )
      }
      
      # ---- Mean / Total / Prop ----
      shiny::req(input$y_var)
      estimate_survey(
        design    = des,
        estimator = input$estimator,
        variable  = input$y_var,
        by        = domain
      )
      
    }, ignoreInit = TRUE)
    
    
    # ==================================================
    # 4. Salidas
    # ==================================================
    output$log <- shiny::renderPrint({
      if (is.null(results_r())) return("La estimaci\u00f3n a\u00fan no ha sido ejecutada.")
      list(
        variable_interes = input$y_var,
        tipo_estimacion  = input$estimator,
        dominios = if (is.null(input$domain_vars) || all(input$domain_vars == "")) {
          "Global"
        } else {
          input$domain_vars
        }
      )
    })
    
    output$preview <- DT::renderDT({
      res <- results_r()
      shiny::req(res)
      
      res_fmt <- res %>%
        dplyr::mutate(dplyr::across(where(is.numeric), ~ round(.x, 4)))
      
      DT::datatable(
        res_fmt,
        rownames = FALSE,
        options  = list(pageLength = 10, scrollX = TRUE)
      )
    })
    
    list(results = shiny::reactive(results_r()))
  })
}
