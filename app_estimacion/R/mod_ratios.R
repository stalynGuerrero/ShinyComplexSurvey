mod_ratios_ui <- function(id){
  ns <- NS(id)
  tagList(
    selectInput(ns('num'),'Numerador', choices = NULL),
    selectInput(ns('den'),'Denominador', choices = NULL),
    actionButton(ns('calc'),'Calcular razón'),
    DT::DTOutput(ns('res'))
  )
}

mod_ratios_server <- function(id, data, design){
  moduleServer(id, function(input, output, session){
    observe({ req(data()); updateSelectInput(session, 'num', choices = names(data())); updateSelectInput(session, 'den', choices = names(data())) })
    res <- eventReactive(input$calc, {
      req(design()); d <- design(); num <- input$num; den <- input$den
      # cálculo por delta method y/o replicación
      mn <- survey::svymean(as.formula(paste0('~', num)), d, na.rm = TRUE)
      md <- survey::svymean(as.formula(paste0('~', den)), d, na.rm = TRUE)
      r <- as.numeric(coef(mn))/as.numeric(coef(md))
      var_r <- (1/as.numeric(coef(md))^2)*as.numeric(vcov(mn)) + (as.numeric(coef(mn))^2/as.numeric(coef(md))^4)*as.numeric(vcov(md))
      se_r <- sqrt(var_r)
      data.frame(razon = r, se = se_r, cv = se_r/r)
    })
    output$res <- DT::renderDT({ req(res()); DT::datatable(res()) })
  })
}