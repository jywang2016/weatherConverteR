rm(list = ls())
# load packages
library(readxl)
library(dplyr)
library(lubridate)

# read data path
path <- "./data/"
(files_name <- list.files(path, pattern = "*xlsx$", full.names = TRUE))

# deal data format by using daily_weather.func
source("daily_weather_noDateDeal.R",encoding = "UTF-8")

raw_weather <- daily_weather_noDateDeal(files_name[1])

for (i in 2:length(files_name))
{
  temp <- daily_weather_noDateDeal(files_name[i])
  if (nrow(temp) != 288)
  {
    warnings("Data missing")
    break
  }
  raw_weather <- rbind(raw_weather,temp)
}

write.csv(raw_weather,"myweather.csv",row.names = F)

rm(list = ls())
myweather <- read.csv("myweather.csv")

# Add the Dew point Temp
# 1) call CoolProp.dll
# 2) use HAPropsSI() calculate the DewPointTemp

#1)
dyn.load(paste("CoolProp", .Platform$dynlib.ext, sep=""))
library(methods) 
source("CoolProp.R")
cacheMetaData(1)

#2)
myweather$DewPoint <- 0 
for (i in 1:nrow(myweather))
{
  myweather$DewPoint[i] <- HAPropsSI('D', 'T', myweather$DryBulb[i]+273.15, 'P', 101325, 'R', myweather$RelHum[i]/100)  
}

myweather <- myweather %>% 
  mutate(DewPoint = round(DewPoint - 273.15,1))

write.csv(myweather,"myweather_dewpTemp.csv",row.names = F)

rm(list = ls())
myweather <- read.csv("myweather_dewpTemp.csv")
# Load a stanard epw to get the colname
source("epw.R")
epw_csv <- read_epw("CHN_Henan.Zhengzhou.570830_CSWD.epw")

myweather <- myweather %>%
  mutate(
    year = unique(epw_csv$data$year),
    month = month(Date),
    day = day(Date),
    hour = hour(Date),
    minute = minute(Date)
  ) 

# ticks:the hours of epw ranges from 1:00 to 24:00
# In most of our data, the hours of one day ranges from 0:00 to 23:00
# Translation should be done to solve this problem

if(0 %in% myweather$hour)
{
  temp_d_row <- which(myweather$hour == 0)
  myweather[temp_d_row,"hour"] <- 24
  myweather[temp_d_row,"day"] <- (myweather$Date[temp_d_row] %>% as.Date() -1) %>% day()
  myweather[temp_d_row,"month"] <- (myweather$Date[temp_d_row] %>% as.Date() -1) %>% month()
}

myweather <- myweather[which(myweather$minute ==0),]

# replace the typical weather with your weather data
# 1) find the start time and end time of your weather
# 2) copy the part of typical weather, which have the same start/end time with your data
# 3) replace the responding variables in part_typical_weather with your data
# 4) replace the part of raw typical weather with your modified part_typical_weather data
nhour <- nrow(myweather) 
start<-which(epw_csv$data$month == myweather$month[1] &
               epw_csv$data$day == myweather$day[1] &
               epw_csv$data$hour == myweather$hour[1])

end<-which(epw_csv$data$month == myweather$month[nhour] &
             epw_csv$data$day == myweather$day[nhour] &
             epw_csv$data$hour == myweather$hour[nhour])

epw_my_part <- epw_csv$data[start:end,] %>%
  mutate(
    dry_bulb = myweather$DryBulb,
    dew_point = myweather$DewPoint,
    rel_hum = myweather$RelHum
  )

epw_csv$data[start:end,] <- epw_my_part

# replace the Location
epw_csv$location[,1] <- "jiaozuo" # city
epw_csv$location[,5] <- 35.210     # latitude
epw_csv$location[,6] <- 113.267    # longitute


write_epw(epw_csv,"./test/temp.epw")
#file.rename("temp","temp.epw")

#Now, the weather file named `temp.epw` can be used in simulation
# We use R package-eplusr developed by [Hongyuan Jia](https://github.com/hongyuanjia) to test the EPW file

rm(list = ls())
library(eplusr)

model <- eplus_model$new(path = "./test/5Zone_Transformer.idf")

model$run(eplus_home = "D:/EnergyPlusV8-8-0" ,period = ~"annual", weather = "./test/temp.epw" ,echo = TRUE)

sessionInfo()
