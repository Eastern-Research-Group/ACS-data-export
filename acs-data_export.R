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

#Outside of R, set up DSN to connect to new blank Access database through ODBC. Created a User DSN named "ACS-data-raw".

#Connect to the blank Access database using the Access 2007 version of the ODBC connection command.
db_conn <- odbcConnectAccess2007("P:/Steam Supplemental/11 EJ Coordination/01 - Demographics analysis/acs-data-exported_01062023.accdb")

#Load list of Census blocks with loads for the 2022 Proposal EA. I started with the 'Census Block_COMID_crosswalk' Excel spreadsheet located in the '01 - Demographics analysis' folder. I copied the 188 FIPS codes to a new Excel spreadsheet and saved as a .txt file.
#**Note that this differs from the list of FIPS codes used for the JTA analysis coding, because those included COMIDs without loads. Also note that there are duplicate FIPS codes in this list. There are 188 entries in the FIPS to COMID crosswalk, and 177 unique FIPS codes.

#Reading in the .txt version of the FIPS list. Set the columns to be characters to avoid losing the leading zeros.
FIPSlist <- read.table(file = "P:/Steam Supplemental/11 EJ Coordination/01 - Demographics analysis/FIPS_list.txt", header = TRUE, sep = "\t",
                    comment.char = "", colClasses = 'character')

#Create subset of data from Julia with only 177 unique Census blocks of interest. Filter the ACS data to only include rows matching the FIPS codes from the crosswalk .txt file.
ACS_filtered <- semi_join(x= data2, y= FIPSlist, by= c("GEOID" = "FIPS"))

#Confirm that the number of unique GEOID codes in the filtered table matches the number of unique FIPS codes in the crosswalk (177 in both cases).
length(unique(ACS_filtered$GEOID))
length(unique(FIPSlist$FIPS))

#Export the extracted ACS data to the database.
sqlSave(db_conn, ACS_filtered, rownames = FALSE, colnames = FALSE, safer = FALSE, addPK = FALSE, fast = FALSE)

#Create list of unique FIPS codes with loads for 2022 Proposal EA. Convert to a data frame for export to Access.
Unique_FIPS2022 <- unique(ACS_filtered$GEOID)
Unique_FIPS2022_df <- data.frame(Unique_FIPS2022)

#Export the list of unique FIPS codes to the database.
sqlSave(db_conn,Unique_FIPS2022_df, rownames = FALSE, colnames = FALSE, safer = FALSE, addPK = FALSE, fast = FALSE)

#Close the ODBC connection.
odbcClose(db_conn)
