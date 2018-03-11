daily_weather_noDateDeal <- function(path)
{
  test <- read_xlsx(path,sheet = "Station")
  #DT::datatable(test)
  
  colnames(test) <- c("Date","DryBulb","RelHum")
  data_daily <- test %>% as.data.frame() %>% 
    mutate(DryBulb = round(DryBulb,1),
           RelHum = round(ifelse(RelHum <= 90, RelHum, 90),0)) %>%
    select(1:3)
  
  return(data_daily)
}