###############################################################################################
# Example script to collect and process SNOTEL date
# Example site is Hogg Pass SNOTEL
#
# Mikey Johnson
# mikeyj@nevada.unr.edu
#
# Last Eddited: 2021-01-12
#
###############################################################################################
# loading librarys
library(devtools)   # 
library(snotelr)    # downloading SNOTEL data
library(dplyr)      # data manipulation
library(ggplot2)    # plotting
library(cowplot)    # publication-ready plots
library(plotly)     # interactive plotting

###############################################################################################
# loading the Hogg Pass SNOTEL data

site_meta_data <- snotel_info() # loading all the SNOTEL station data

Hogg_Pass <- snotel_download(site_id = 526, internal = TRUE) # downloading Hogg Pass, SWE[mm] and temp[Degrees C]
#HP <- filter(Hogg_Pass, date <= "2018-09-30", date >= "2000-10-01") # seperating out the data (End Date, Start Date)
#HP <- filter(Hogg_Pass, date <= "2015-09-30", date >= "2014-10-01") # Low Snow Year
HP <- filter(Hogg_Pass, date <= "2016-09-30", date >= "2015-10-01") # Medium Snow Year
#HP <- filter(Hogg_Pass, date <= "2017-09-30", date >= "2016-10-01") # High Snow Year

# Mt. Rose
#Mt.Rose <- snotel_download(site_id = 652, internal = TRUE) # downloading Hogg Pass, SWE[mm] and temp[Degrees C]
#MR <- filter(Hogg_Pass, date <= "2019-09-30", date >= "2018-10-01") # seperating out the data (End Date, Start Date)

HP$date = as.Date(HP$date)
###############################################################################################
# plotting swe
ggplotly(ggplot()+
           geom_line(aes(as.Date(HP$date),HP$snow_water_equivalent)) +
           xlab("") + ylab("Snow Water Equivalant (mm)")+
           ggtitle("Hogg Pass SNOTEL")+
           theme_cowplot(12))



###############################################################################################
# Yearly Analysis
# Note: If you use multiple years of data it will be summed over time


###############################################################################################
# calcualting cumulative gain and loss of swe

HP <- HP %>% mutate(cumulative_gain=rep(0,nrow(HP)))
HP$cumulative_gain[1] <- HP$snow_water_equivalent[1]
for (i in 2:nrow(HP)){
HP$cumulative_gain[i] <- ifelse(HP$snow_water_equivalent[i]>HP$snow_water_equivalent[i-1],
                                HP$cumulative_gain[i-1]+(HP$snow_water_equivalent[i]-HP$snow_water_equivalent[i-1]),
                                HP$cumulative_gain[i-1])
}


HP <- HP %>% mutate(cumulative_loss=rep(0,nrow(HP)))
for (i in 2:nrow(HP)){
  HP$cumulative_loss[i] <- ifelse(HP$snow_water_equivalent[i]<HP$snow_water_equivalent[i-1],
                                  HP$cumulative_loss[i-1]-(HP$snow_water_equivalent[i-1]-HP$snow_water_equivalent[i]),
                                  HP$cumulative_loss[i-1])
}

ggplotly(ggplot(data = HP)+
           geom_line(aes(x=date,y=cumulative_gain)) +
           geom_line(aes(x=date,y=cumulative_loss)) +
           geom_hline(yintercept = 0, linetype = "dotted") +
           xlab("") + ylab("Snow Water Equivalant (mm)")+
           ggtitle("Cunulative Loss and Gain")+
           theme_cowplot(12))


###############################################################################################
# flagging days where snowfall is >3[cm] or >30[mm]

HP <- HP %>% 
  mutate(del_swe = (c(0,diff(snow_water_equivalent)))) %>%
  mutate(Storm_Flag = ifelse(del_swe >= 30,1,0))

ggplotly(ggplot(data = HP)+
           geom_point(aes(x=date,y=Storm_Flag)) +
           xlab("") + ylab("")+
           ggtitle("Storm Days")+
           theme_cowplot(12))


###############################################################################################
# flagging days where snowmelt is >1[cm] or >10[mm] Note: I might change this threshold
# Note: I need to find a way to seperate snowmelt from sublimation

# Note: Commented out for now
#
#HP <- HP %>%
#  mutate(Melt_Flag = ifelse(del_swe<=1,0,1))
#
#ggplotly(ggplot(data = HP)+
#           geom_point(aes(x=date,y=Melt_Flag)) +
#           xlab("") + ylab("")+
#           ggtitle("Melt Days")+
#           theme_cowplot(12))
#

###############################################################################################
# Counting Storms, # consider time step threshhold for gap between storms

HP <- HP %>%
  mutate(Storm_Count = ifelse(Storm_Flag == 0,NA,0))

i <- 1
j <- 1
storm_counter <- 0
while (i <= nrow(HP)){
  
  if (HP$Storm_Flag[i] == 1) {
    storm_counter <- storm_counter + 1
    HP$Storm_Count[i] <- storm_counter
    i <- i+1
    j <- i}
  else {i <- i+1}
    while (j <= nrow(HP)){
      if (HP$Storm_Flag[j] == 1){
        HP$Storm_Count[j] <- storm_counter
        j <- j+1
        i <- i+1
        }
      else { j <- nrow(HP)+1 }
    }
}
storm_counter


###############################################################################################
# Determining if the site is in the (seasonal snow zone) / (intermintent snow zone) / (rain zone)
source_url("https://raw.githubusercontent.com/MikeySnowHydro/Useful_R_Functions/master/SP_Snow_Zone.R")

SP_Snow_Zone(daily_swe = HP$snow_water_equivalent,
          min_snow = 0.02 * 1000,        # Note (Sterm, Holgrem & Liston, 1994) defines ephemeral to be bewteen 0-50 (cm)
          return_data_type = "character"   # choose "numeric" or "character"
          )





