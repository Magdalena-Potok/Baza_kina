library("RPostgres")
library("shiny")
library("shinyalert")
library("shinythemes")

open.my.connection <- function() {
  con <- dbConnect(RPostgres::Postgres(),dbname = 'projekt10',
                   host = 'localhost',
                   port = 5432, 
                   user = 'dawid',
                   password = 'Haslo098776')
  return (con)
}

close.my.connection <- function(con) {
  dbDisconnect(con)
}

load.tytul <- function() {
  query = "SELECT tytul FROM seanse"
  con = open.my.connection()
  res = dbSendQuery(con,query)
  tytuly = dbFetch(res)
  dbClearResult(res)
  close.my.connection(con)
  return(tytuly)
}

id_seansu <- function() {
  query = "SELECT id_seansu FROM seanse"
  con = open.my.connection()
  res = dbSendQuery(con,query)
  id_seansu = dbFetch(res)
  dbClearResult(res)
  close.my.connection(con)
  return(id_seansu)
}

load.status <- function() {
  query = "SELECT id_status FROM statusy"
  con = open.my.connection()
  res = dbSendQuery(con,query)
  statusy = dbFetch(res)
  dbClearResult(res)
  close.my.connection(con)
  return(statusy)
}

load.rezerwacje <- function(status) {
  query = paste0("SELECT * FROM wszystkie_rezerwacje
                  WHERE status = ", "'",status,"'")
  con = open.my.connection()
  res = dbSendQuery(con,query)
  rezerwacje = dbFetch(res)
  dbClearResult(res)
  close.my.connection(con)
  return(rezerwacje)
}

load.r_t <- function() {
  query = paste0("SELECT * FROM ranking_tytulow")
  con = open.my.connection()
  res = dbSendQuery(con,query)
  r_t = dbFetch(res)
  dbClearResult(res)
  close.my.connection(con)
  return(r_t)
}
load.r_f <- function() {
  query = paste0("SELECT * FROM ranking_formatow")
  con = open.my.connection()
  res = dbSendQuery(con,query)
  r_f = dbFetch(res)
  dbClearResult(res)
  close.my.connection(con)
  return(r_f)
}

load.i_o_k <- function() {
  query = paste0("SELECT * FROM info_klient_sprzedaz")
  con = open.my.connection()
  res = dbSendQuery(con,query)
  i_o_k = dbFetch(res)
  dbClearResult(res)
  close.my.connection(con)
  return(i_o_k)
  
}

load.seans <- function(tytul) {
  query = paste0("SELECT tytul, format_filmu, data_seans, godzina, sala 
                  FROM seanse WHERE tytul = '", tytul,"'")
  con = open.my.connection()
  res = dbSendQuery(con,query)
  szczegoly = dbFetch(res)
  dbClearResult(res)
  close.my.connection(con)
  return(szczegoly)
}

load.seanse.func <- function(title) {
  query = paste0("SELECT tytul, data_seans, godzina, format_filmu
                  FROM seanse WHERE tytul = '",title,"'")
  con = open.my.connection()
  res = dbSendQuery(con,query)
  ratings = dbFetch(res)
  dbClearResult(res)
  close.my.connection(con)
  return(ratings)
}

load.cennik.func <- function(rodzaj.biletu) {
  query = paste0("SELECT * FROM widok_ceny_biletow 
                  WHERE nazwa_biletu = '",rodzaj.biletu,"'")
  con = open.my.connection()
  res = dbSendQuery(con,query)
  ceny = dbFetch(res)
  dbClearResult(res)
  close.my.connection(con)
  return(ceny)
}

add.or.update.seans <- function(tytul, format_filmu, godzina, data_seans, sala) {
  query = paste0("INSERT INTO seanse(tytul, format_filmu, godzina, data_seans, sala) 
                 VALUES('"
                 ,tytul,"','",format_filmu,"','",godzina,"','",data_seans,"',",
                 sala,")")
  con = open.my.connection()
  dbSendQuery(con,query)
  close.my.connection(con)
}

u.seans <- function(id_seansu) {
  query = paste0("SELECT usun_seans(",id_seansu,")")
  con = open.my.connection()
  dbSendQuery(con,query)
  close.my.connection(con)
}

zmien_cene_biletow <- function(procent) {
  query = paste0("SELECT zmien_cene(",procent,")")
  con = open.my.connection()
  dbSendQuery(con,query)
  close.my.connection(con)
}

load.sala <- function() {
  query = "SELECT id_sali FROM sala"
  con = open.my.connection()
  res = dbSendQuery(con,query)
  sale = dbFetch(res)
  dbClearResult(res)
  close.my.connection(con)
  return(sale)
}

shinyServer <- function(input, output, session) {
  
  output$seanse.func <- renderDataTable(
    load.seanse.func(input$title),
    options = list(
      pageLength = 10,
      lengthChange = FALSE,
      searching = FALSE,
      info = FALSE
    )
  )
  
  output$cennik.func <- renderDataTable(
    load.cennik.func(input$rodzaj.biletu),
    options = list(
      pageLength = 10,
      lengthChange = FALSE,
      searching = FALSE,
      info = FALSE
    )
  )
  
  output$rezerwacje.func <- renderDataTable(
    load.rezerwacje(input$status),
    options = list(
      pageLength = 10,
      lengthChange = FALSE,
      searching = FALSE,
      info = FALSE
    )
  )
  
  output$r_t.func <- renderDataTable(
    load.r_t(),
    options = list(
      pageLength = 10,
      lengthChange = FALSE,
      searching = FALSE,
      info = FALSE
    )
  )
  
  output$r_f.func <- renderDataTable(
    load.r_f(),
    options = list(
      pageLength = 10,
      lengthChange = FALSE,
      searching = FALSE,
      info = FALSE
    )
  )
  
  output$i_o_k.func <- renderDataTable(
    load.i_o_k(),
    options = list(
      pageLength = 10,
      lengthChange = FALSE,
      searching = FALSE,
      info = FALSE
    )
  )
  
  observeEvent(input$add.seans,
               add.or.update.seans(input$seanse.tytul,
                                   input$seanse.format,
                                   input$seanse.godzina,
                                   input$seanse.data,
                                   input$seanse.sala))
  

  observeEvent(input$zmien_cene_biletow,
             zmien_cene_biletow(input$procent))
  
  observeEvent(input$u.seans,
             u.seans(input$id_seansu))
  
  observeEvent(input$add.seans, {
    shinyalert(title = "Sukces", type = "success", text = "Dodales seans!")
    })
  
  observeEvent(input$u.seans, {
    shinyalert(title = "Sukces", type = "success", text = "Usunales seans!")
    })
  
  observeEvent(input$zmien_cene_biletow, {
    shinyalert(title = "Sukces", type = "success", text = "Zmieniles ceny biletow!")
    })
}



shinyUI <- fluidPage(
  theme = shinytheme("sandstone"),
  shinyalert::useShinyalert(),
  titlePanel("Kino"),
  mainPanel(
    tabsetPanel(
      tabPanel('Seanse',
               selectInput(inputId='title',
                           label='Wybierz tytul',
                           choices=load.tytul()),
               dataTableOutput('seanse.func'),
               textOutput('seanse')),
      
      
      tabPanel('Rezerwacje',
               selectInput(inputId='status',
                           label='Wybierz status',
                           choices=list("zaakceptowana","anulowana")),
               dataTableOutput('rezerwacje.func'),
               textOutput('rezerwacje')),
      

      navbarMenu("Dodaj/Usun seans",
                 tabPanel('Dodaj',
                          textInput(inputId='seanse.tytul',
                                    label='Tytul'),
                          selectInput(inputId='seanse.format',
                                      label='Format filmu',
                                      choices=list('2D', '3D', '2D VIP', '3D VIP')),
                          selectInput(inputId='seanse.godzina',
                                      label='Godzina',
                                      choices=list('8:30','10:00','11:30','13:00','14:30','16:00','17:30','19:00','20:30','22:00')),
                          dateInput(inputId='seanse.data',
                                    label='Data'),
                          selectInput(inputId='seanse.sala',
                                      label='Sala',
                                      choices=load.sala()),
                          actionButton(inputId='add.seans',
                                       label='Dodaj seans')),
                 tabPanel('Usun',
                          textInput(inputId='id_seansu',
                                    label='Podaj id seansu do usuniecia'),
                          actionButton(inputId='u.seans',
                                       label='usun'))),
      
      navbarMenu("Info o sprzedazy",
                 tabPanel('Ranking tytulow',
                          dataTableOutput('r_t.func'),
                          textOutput('r_t')),
                 tabPanel('Ranking formatow',
                          dataTableOutput('r_f.func'),
                          textOutput('r_f')),
                tabPanel('Info o klientach',
                          dataTableOutput('i_o_k.func'),
                          textOutput('i_o_k'))),
      
      navbarMenu("Ceny",
                 tabPanel("Cennik",
                          selectInput(inputId='rodzaj.biletu',
                          label='Wybierz rodzaj biletu',
                          choices=list("ulgowy", "normalny")),
                          dataTableOutput('cennik.func'),
                          textOutput('cennik')),
                 tabPanel('Zmien ceny',
                          numericInput(inputId='procent',
                          label='Podaj procent o który chcesz zwiększyć kazda cene',
                          value=1, min=1, max=100),
                          actionButton(inputId='zmien_cene_biletow',
                          label='Zmien'))
    ))))
      
shinyApp(ui = shinyUI, server = shinyServer)
