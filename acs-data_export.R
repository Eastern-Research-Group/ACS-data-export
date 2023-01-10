#Exporting American Community Survey (ACS) data provided by Julia Monsarrat on 1/5/2023 to a new Access database for further manipulation.
#Script written by Kathleen Onorevole on 1/6/2023

#Before this script can be run, must ensure that 32-bit version of R is enabled. This is necessary to properly connect to the Access database and use the ODBC.

#Install and load relevant packages. Need to make sure that Rtools is installed first.
install.packages("RODBC")
library(RODBC)
install.packages("readr")
library(readr)
install.packages("dplyr")
library(dplyr)
install.packages("Rcpp", type = "source")
library(Rcpp)
install.packages("sf", type = "source")
library(sf)

#Load ACS data provided by Julia. This is in the "simple feature" format.
load("P:/Steam Supplemental/11 EJ Coordination/from EPA/ACS/acs_data_2019_block group.Rdata")

#Remove geometry from ACS data. This changes it from simple feature to data frame format. Confirmed that leading zeros in GEOID were retained.
data2 <- st_set_geometry(data, NULL)

#Change GEOID variable from character to numeric for semi_join to work.
#data3 <- data2 %>%
 # mutate(GEOID = as.numeric(GEOID))

#Outside of R, set up DSN to connect to new blank Access database through ODBC. Created a User DSN named "ACS-data-raw".

#Connect to the blank Access database using the Access 2007 version of the ODBC connection command.
db_conn <- odbcConnectAccess2007("P:/Steam Supplemental/11 EJ Coordination/01 - Demographics analysis/acs-data-exported_01062023.accdb")

#Create dataframe in R with Census blocks without loads for 2022. These were identified by using Kristi's 'Crosswalk_092122.accdb' database in the same location, and filtering table 'Final_COMID to FIPs Crosswalk' on "Baseline_2022" = 1. I exported the resulting 188 FIPS codes to Excel and saved as a CSV.
#**Note that this is different from the list of FIPS codes used for the JTA analysis coding, because those included COMIDs without loads. Also note that there are duplicates in this list.

#FIPStext <- read.delim("P:/Steam Supplemental/11 EJ Coordination/01 - Demographics analysis/FIPS_list.txt", as.is = TRUE, stringsAsFactors = FALSE)

#Reading in a .txt version of the FIPS list (from the COMID crosswalk in the same file location). Used .txt file and set the columns to be characters to avoid losing the leading zeros.
FIPSlist <- read.table(file = "P:/Steam Supplemental/11 EJ Coordination/01 - Demographics analysis/FIPS_list.txt", header = TRUE, sep = "\t",
                    comment.char = "", colClasses = 'character')


#Create dataframe in R with unique Census blocks for 2022. Note that this is different from the original 'CBlist' above, which was based on 2020.
#uniqueFIPS <- read.csv("P:/Steam Supplemental/10 EA/04 Supplemental Analyses/Census Block GIS/unique-census-blocks-with-loads.csv", header = FALSE)

#uniqueFIPS2 <- read.csv("P:/Steam Supplemental/10 EA/04 Supplemental Analyses/Census Block GIS/Jan6FIPS.csv", colClasses=c("numeric"))

#names(uniqueFIPS) <- c('FIPS')

#nochar <- uniqueFIPS2 %>%
  #mutate_if(is.numeric, as.integer)

#select(numtest$GEOID = )

#Rename column heading to avoid formatting issues
#names(uniqueFIPS) <- c('FIPS')
#numFIPS <- uniqueFIPS %>%
  #mutate(FIPS = as.numeric(FIPS))

#Create subset with only 188 unique Census blocks of interest.Filter the ACS data to only include rows data for the 222 unique Census blocks. 
ACS_filtered <- semi_join(x= data2, y= FIPSlist, by= c("GEOID" = "FIPS"))

#Confirming that the number of unique GEOID codes in the filtered table matched the number of unique FIPS codes in the crosswalk (177 in both cases).
length(unique(ACS_filtered$GEOID))
length(unique(FIPSlist$FIPS))

#Export the extracted data to the database.
sqlSave(db_conn, ACS_filtered, rownames = FALSE, colnames = FALSE, safer = FALSE, addPK = FALSE, fast = FALSE)

#Create list of unique FIPS codes with loads for 2022 Proposal EA.
Unique_FIPS2022 <- unique(ACS_filtered$GEOID)

#Export the list of unique FIPS codes to the database.
sqlSave(db_conn,Unique_FIPS2022, rownames = FALSE, colnames = FALSE, safer = FALSE, addPK = FALSE, fast = FALSE)

#Close the ODBC connection.
odbcClose(db_conn)
