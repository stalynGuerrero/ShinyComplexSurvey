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

<b>Media poblacional bajo diseño complejo</b><br><br>

El estimador de la media poblacional se obtiene como:

$$
\\hat{\\bar{Y}} =
\\frac{\\sum_{i \\in s} w_i y_i}
     {\\sum_{i \\in s} w_i}
$$

donde:

<ul>
<li>\\(w_i = 1/\\pi_i\\) es el peso de expansión</li>
<li>\\(\\pi_i\\) es la probabilidad de inclusión</li>
<li>\\(y_i\\) es la variable de interés</li>
</ul>

Este estimador puede interpretarse como el estimador de Horvitz–Thompson del total dividido por el tamaño poblacional estimado.

$$
\\hat{\\bar{Y}} = \\frac{\\hat{T}_Y}{\\hat{N}}
$$

donde

$$
\\hat{T}_Y = \\sum w_i y_i
\\quad
\\hat{N} = \\sum w_i
$$

<br>

<b>Varianza aproximada</b>

$$
\\widehat{Var}(\\hat{\\bar{Y}}) =
\\frac{1}{(\\sum w_i)^2}
\\widehat{Var}\\left(\\sum w_i y_i\\right)
$$

La varianza se estima mediante linearización de Taylor o métodos de replicación.

",
        
        # =========================================================
        # TOTAL
        # =========================================================
        "total" = "

<b>Total poblacional</b><br><br>

El estimador del total poblacional corresponde al estimador de Horvitz–Thompson:

$$
\\hat{T}_{HT} =
\\sum_{i \\in s} w_i y_i
$$

donde:

<ul>
<li>\\(w_i = 1/\\pi_i\\) es el peso de expansión</li>
<li>\\(\\pi_i\\) es la probabilidad de inclusión</li>
</ul>

Bajo muestreo estratificado:

$$
\\hat{T} =
\\sum_{h=1}^{H}
\\sum_{i \\in s_h}
w_{hi} y_{hi}
$$

Este estimador es insesgado bajo el diseño de muestreo.

",
        
        # =========================================================
        # PROPORCIÓN
        # =========================================================
        "prop" = "

<b>Proporción poblacional</b><br><br>

Definiendo una variable indicadora:

$$
I_i =
\\begin{cases}
1 & \\text{si la unidad pertenece a la categoría de interés} \\\\
0 & \\text{en otro caso}
\\end{cases}
$$

La proporción poblacional se estima como:

$$
\\hat{P} =
\\frac{\\sum_{i \\in s} w_i I_i}
     {\\sum_{i \\in s} w_i}
$$

Este estimador es equivalente a la media ponderada de la variable indicadora.

La varianza se aproxima mediante linearización de Taylor.

",
        
        # =========================================================
        # RAZÓN
        # =========================================================
        "ratio" = "

<b>Estimador de razón</b><br><br>

El estimador de razón compara dos totales poblacionales estimados
a partir de una muestra con pesos de expansión.

$$
\\hat{R} =
\\frac{\\sum_{i \\in s} w_i y_i}
     {\\sum_{i \\in s} w_i x_i}
$$

donde:

<ul>
<li>\\(w_i\\) es el peso de expansión</li>
<li>\\(y_i\\) es la variable del numerador</li>
<li>\\(x_i\\) es la variable del denominador</li>
<li>\\(s\\) representa el conjunto de unidades de la muestra</li>
</ul>

<br>

<b>Relación con los estimadores de Horvitz–Thompson</b>

$$
\\hat{R} = \\frac{\\hat{Y}}{\\hat{X}}
$$

con

$$
\\hat{Y} = \\sum_{i \\in s} w_i y_i
\\qquad
\\hat{X} = \\sum_{i \\in s} w_i x_i
$$

<br>

<b>Varianza aproximada</b>

El estimador es no lineal, por lo que su varianza se aproxima mediante
linearización de Taylor:

$$
\\widehat{Var}(\\hat{R}) \\approx
\\frac{1}{\\hat{X}^2}
\\widehat{Var}(\\hat{Y} - \\hat{R}\\hat{X})
$$

<br>

<b>Casos particulares utilizados en la aplicación</b>

<br>

<b>1. Razón entre categorías</b><br>
Ejemplo: proporción de hombres respecto a mujeres.

Sea

$$
y_i = I(\\text{hombre})
\\qquad
x_i = I(\\text{mujer})
$$

donde \\(I(\\cdot)\\) es una función indicadora.

El estimador es:

$$
\\hat{R} =
\\frac{\\sum w_i I(\\text{hombre})}
     {\\sum w_i I(\\text{mujer})}
$$

Este tipo de razón se utiliza para comparar tamaños relativos
entre grupos poblacionales.

<br>

<b>2. Variable continua sobre categoría</b><br>
Ejemplo: ingreso promedio de los hombres.

Sea

$$
y_i = ingreso_i
\\qquad
x_i = I(\\text{hombre})
$$

entonces

$$
\\hat{R} =
\\frac{\\sum w_i ingreso_i}
     {\\sum w_i I(\\text{hombre})}
$$

Este estimador corresponde al promedio ponderado del ingreso
en la subpoblación de hombres.

<br>

<b>3. Razón entre variables continuas</b><br>
Ejemplo: relación ingreso / gasto.

Sea

$$
y_i = ingreso_i
\\qquad
x_i = gasto_i
$$

entonces

$$
\\hat{R} =
\\frac{\\sum w_i ingreso_i}
     {\\sum w_i gasto_i}
$$

Este tipo de razón se utiliza para analizar relaciones económicas
entre variables agregadas.

<br>

<b>Interpretación</b>

El estimador de razón es especialmente eficiente cuando existe
una fuerte correlación entre \\(Y\\) y \\(X\\), ya que el denominador
actúa como variable auxiliar reduciendo la varianza del estimador.

",
        
        # =========================================================
        # CUANTILES
        # =========================================================
        "quantile" = "

<b>Cuantiles ponderados</b><br><br>

Los cuantiles poblacionales se definen a partir de la función de distribución acumulada ponderada:

$$
F_w(y) =
\\frac{\\sum w_i I(Y_i \\le y)}{\\sum w_i}
$$

El cuantil \\(q_p\\) satisface:

$$
F_w(q_p) = p
$$

Los cuantiles ponderados permiten estimar percentiles de la distribución poblacional bajo diseños complejos.

La varianza suele estimarse mediante:

<ul>
<li>linearización de Woodruff</li>
<li>métodos de replicación (Bootstrap, Jackknife, BRR)</li>
</ul>

",
        
        # =========================================================
        # DEFAULT
        # =========================================================
        "Seleccione un estimador para visualizar su marco teórico."
        
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
          shiny::HTML(
            
              theory_text,
            
          )
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
          
          HTML("
<b>Coeficiente de Variación (CV)</b><br><br>

El coeficiente de variación mide la precisión relativa del estimador.

$$
CV(\\hat{\\theta}) =
\\frac{SE(\\hat{\\theta})}{\\hat{\\theta}}
$$

En porcentaje:

$$
CV(\\hat{\\theta}) =
\\frac{SE(\\hat{\\theta})}{\\hat{\\theta}} \\times 100
$$

<br>

<b>Interpretación</b>

<ul>
<li><b>&lt; 5%</b> → Muy alta precisión</li>
<li><b>5% – 10%</b> → Alta precisión</li>
<li><b>10% – 20%</b> → Precisión aceptable</li>
<li><b>20% – 30%</b> → Uso con cautela</li>
<li><b>&gt; 30%</b> → Baja precisión</li>
</ul>

<br>

<hr>

<b>Efecto de diseño (Design Effect)</b><br><br>

El efecto de diseño mide cuánto aumenta la varianza debido al diseño muestral complejo comparado con un muestreo aleatorio simple.

$$
DEFF =
\\frac{Var_{diseño}(\\hat{\\theta})}
{Var_{MAS}(\\hat{\\theta})}
$$

<br>

<b>Tamaño de muestra efectivo</b>

$$
n_{eff} =
\\frac{n}{DEFF}
$$

<br>
<hr><b>Referencias</b>
                 <ul>
                 <li>Cochran, W. (1977). <i>Sampling Techniques</i>. Wiley.</li>
                 <li>Särndal, C., Swensson, B., & Wretman, J. (1992). <i>Model Assisted Survey Sampling</i>. Springer.</li>
                 <li>Lohr, S. (2021). <i>Sampling: Design and Analysis</i>. CRC Press.</li>
                 <li>Lumley, T. (2010). <i>Complex Surveys: A Guide to Analysis Using R</i>. Wiley.</li>
                 </ul>
")
        )
      )
    })
    
    
    ns <- session$ns
    
    # ==================================================
    # 1. Actualizar selectores desde el diseño (bien hecho)
    # ==================================================
    shiny::observeEvent(design(), {
      
      des <- design()
      shiny::req(des)
      shiny::req(!is.null(des$variables))
      
      vars <- names(des$variables)
      shiny::req(length(vars) > 0)
      
      shiny::updateSelectInput(session, "y_var", choices = vars)
      shiny::updateSelectInput(session, "numerator", choices = vars)
      shiny::updateSelectInput(session, "denominator", choices = vars)
      shiny::updateSelectInput(session, "domain_vars", choices = c("Ninguno" = "", vars))
    })
    
    # ==================================================
    # 1b. Filtrar variables según tipo de estimador
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
    # 2. UI dinámica para ratio categórica (usa y_var)
    # ==================================================
    output$ratio_levels_ui <- renderUI({
      
      req(input$estimator == "ratio")
      req(input$numerator, input$denominator)
      req(design())
      
      vars <- design()$variables
      
      num_is_cat <- is.factor(vars[[input$numerator]]) ||
        is.character(vars[[input$numerator]])
      
      den_is_cat <- is.factor(vars[[input$denominator]]) ||
        is.character(vars[[input$denominator]])
      
      ui <- list()
      
      if (num_is_cat) {
        ui <- c(ui, list(
          selectInput(
            ns("ratio_num_level"),
            "Categoría (numerador)",
            choices = sort(unique(stats::na.omit(vars[[input$numerator]])))
          )
        ))
      }
      
      if (den_is_cat) {
        ui <- c(ui, list(
          selectInput(
            ns("ratio_den_level"),
            "Categoría (denominador)",
            choices = sort(unique(stats::na.omit(vars[[input$denominator]])))
          )
        ))
      }
      
      if (length(ui) == 0) return(NULL)
      tagList(ui)
    })
    
    
    # ==================================================
    # 3. Ejecutar estimación
    # ==================================================
    results_r <- shiny::eventReactive(input$run, {
      
      des <- design()
      shiny::req(des, input$y_var, input$estimator)
      
      domain <- input$domain_vars
      if (length(domain) == 0 || all(domain == "")) domain <- NULL
      
      # ---- Ratio: categórica vs continua ----
      if (input$estimator == "ratio") {
        
        num <- input$numerator
        den <- input$denominator
        
        vars <- design()$variables
        
        num_is_cat <- is.factor(vars[[num]]) || is.character(vars[[num]])
        den_is_cat <- is.factor(vars[[den]]) || is.character(vars[[den]])
        
        return(
          estimate_survey(
            design = des,
            estimator = "ratio",
            by = domain,
            numerator = num,
            denominator = den,
            ratio_num_level = if (num_is_cat) input$ratio_num_level else NULL,
            ratio_den_level = if (den_is_cat) input$ratio_den_level else NULL
          )
        )
      }
      
      
      # ---- Cuantiles ----
      if (input$estimator == "quantile") {
        
        probs <- trimws(unlist(strsplit(input$probs, ",")))
        probs <- sort(unique(as.numeric(probs)))
        shiny::req(length(probs) > 0, !any(is.na(probs)))
        
        return(
          estimate_survey(
            design = des,
            estimator = "quantile",
            variable = input$y_var,
            by = domain,
            probs = probs
          )
        )
      }
      
      # ---- Mean/Total/Prop ----
      estimate_survey(
        design = des,
        estimator = input$estimator,
        variable = input$y_var,
        by = domain
      )
      
    }, ignoreInit = TRUE)
    
    
    # ==================================================
    # 4. Salidas
    # ==================================================
    output$log <- shiny::renderPrint({
      if (is.null(results_r())) return("La estimación aún no ha sido ejecutada.")
      list(
        variable_interes = input$y_var,
        tipo_estimacion = input$estimator,
        dominios = if (is.null(input$domain_vars) || all(input$domain_vars == "")) "Global" else input$domain_vars
      )
    })
    
    output$preview <- DT::renderDT({
      res <- results_r()
      shiny::req(res)
      
      res_fmt <- res  %>% 
        dplyr::mutate(dplyr::across(where(is.numeric), ~ round(.x, 3)))
      
      DT::datatable(
        res_fmt,
        rownames = FALSE,
        options = list(pageLength = 10, scrollX = TRUE)
      )
    })
    
    list(results = shiny::reactive(results_r()))
  })
}
