#' Shiny UI for ShinyComplexSurvey
#'
#' @return A Shiny UI object.
app_ui <- function() {

  shiny::withMathJax(

    shiny::navbarPage(
      title  = shiny::tagList(
        shiny::tags$span(class = "app-brand-mark", shiny::icon("chart-line")),
        shiny::tags$span("ShinyComplexSurvey")
      ),
      id     = "navbar",
      fluid  = TRUE,
      theme  = NULL,

      header = shiny::tags$head(
        shiny::tags$link(rel = "stylesheet", type = "text/css", href = "www/custom.css"),
        shiny::tags$style(shiny::HTML("
          .navbar-custom-menu {
            float: right !important;
            margin-right: 15px;
            display: flex;
            align-items: center;
            height: 54px;
          }
          .navbar-custom-menu .lang-label {
            color: #e2e8f0;
            font-size: 12px;
            letter-spacing: .08em;
            text-transform: uppercase;
            font-weight: 600;
            margin-right: 8px;
          }
          .navbar-custom-menu .form-group {
            margin-bottom: 0 !important;
          }
        "))
      ),

      # ============================================================
      # Pestaña 0: Portada
      # ============================================================
      shiny::tabPanel(
        title = shiny::tagList(
          shiny::tags$i(class = "fa fa-home"),
          shiny::textOutput("tab_portada", inline = TRUE)
        ),
        value = "portada",
        shiny::div(class = "cover-page",
          # ---- Hero ----
          shiny::div(class = "cover-hero",
            shiny::div(class = "cover-hero-content",
              shiny::div(class = "cover-logo-wrap",
                shiny::tags$img(
                  src   = "img/ShinyComplexSurvey_hex.png",
                  class = "cover-hex",
                  alt   = "ShinyComplexSurvey"
                )
              ),
              shiny::div(class = "cover-hero-text",
                shiny::tags$h1(class = "cover-title", "ShinyComplexSurvey"),
                shiny::tags$p(class = "cover-subtitle",
                  shiny::textOutput("cover_desc", inline = TRUE)
                ),
                shiny::div(class = "cover-badges",
                  shiny::tags$span(class = "cover-badge", shiny::tags$i(class = "fa fa-r-project"), " R Shiny"),
                  shiny::tags$span(class = "cover-badge", shiny::tags$i(class = "fa fa-chart-bar"), " survey"),
                  shiny::tags$span(class = "cover-badge", shiny::tags$i(class = "fa fa-globe"), " i18n")
                ),
                shiny::actionButton(
                  "go_to_datos",
                  label = shiny::tagList(
                    shiny::tags$i(class = "fa fa-play-circle"),
                    shiny::textOutput("cover_btn", inline = TRUE)
                  ),
                  class = "btn btn-primary cover-cta"
                )
              )
            )
          ),
          # ---- Feature cards ----
          shiny::div(class = "cover-features",
            shiny::div(class = "cover-feature-card",
              shiny::div(class = "cover-feature-icon", shiny::tags$i(class = "fa fa-database")),
              shiny::tags$h3(shiny::textOutput("cover_feat1_title", inline = TRUE)),
              shiny::tags$p(shiny::textOutput("cover_feat1_desc", inline = TRUE))
            ),
            shiny::div(class = "cover-feature-card",
              shiny::div(class = "cover-feature-icon", shiny::tags$i(class = "fa fa-sitemap")),
              shiny::tags$h3(shiny::textOutput("cover_feat2_title", inline = TRUE)),
              shiny::tags$p(shiny::textOutput("cover_feat2_desc", inline = TRUE))
            ),
            shiny::div(class = "cover-feature-card",
              shiny::div(class = "cover-feature-icon", shiny::tags$i(class = "fa fa-bar-chart")),
              shiny::tags$h3(shiny::textOutput("cover_feat3_title", inline = TRUE)),
              shiny::tags$p(shiny::textOutput("cover_feat3_desc", inline = TRUE))
            )
          ),
          # ---- Footer de portada ----
          shiny::div(class = "cover-footer",
            shiny::tags$span(
              shiny::tags$i(class = "fa fa-code"),
              shiny::textOutput("app_footer", inline = TRUE),
              shiny::tags$a(
                href   = "https://github.com/psirusteam/ShinyComplexSurvey",
                target = "_blank",
                shiny::tags$i(class = "fa fa-github"), " GitHub"
              )
            )
          )
        )
      ),

      # ============================================================
      # Pestaña 1: Datos
      # ============================================================
      shiny::tabPanel(
        title = shiny::tagList(
          shiny::tags$i(class = "fa fa-database"),
          shiny::textOutput("tab_datos", inline = TRUE)
        ),
        value = "datos",
        mod_datos_ui("datos")
      ),

      # ============================================================
      # Pestaña 2: Diseño muestral
      # ============================================================
      shiny::tabPanel(
        title = shiny::tagList(
          shiny::tags$i(class = "fa fa-sitemap"),
          shiny::textOutput("tab_diseno", inline = TRUE)
        ),
        value = "diseno",
        mod_diseno_ui("diseno")
      ),

      # ============================================================
      # Pestaña 3: Estimación
      # ============================================================
      shiny::tabPanel(
        title = shiny::tagList(
          shiny::tags$i(class = "fa fa-bar-chart"),
          shiny::textOutput("tab_estimacion", inline = TRUE)
        ),
        value = "estimacion",
        mod_estimacion_ui("estimacion")
      ),

      # ============================================================
      # Selector de idioma alineado a la derecha
      # ============================================================
      shiny::tags$script(shiny::HTML("
        $(document).ready(function() {
          $('.navbar-nav').after($('#lang-container'));
        });
      ")),

      footer = shiny::tags$div(
        id    = "lang-container",
        class = "navbar-custom-menu",
        shiny::tags$div(
          style = "display:flex; align-items:center; gap:8px;",
          shiny::tags$span(class = "lang-label", "Idioma"),
          shiny::tags$span(class = "fa fa-globe", style = "color:#cbd5e1;"),
          shiny::selectizeInput(
            inputId  = "lang",
            label    = NULL,
            choices  = c("ES" = "es", "EN" = "en"),
            selected = "es",
            width    = "80px",
            options  = list(maxItems = 1, searchField = FALSE)
          ),
          shiny::actionButton(
            inputId = "exit_app",
            label   = shiny::tagList(
              shiny::tags$i(class = "fa fa-power-off"),
              shiny::textOutput("btn_exit", inline = TRUE)
            ),
            class = "btn btn-danger btn-sm",
            style = "margin-left:4px;"
          )
        )
      )
    )

  )
}
