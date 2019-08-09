######Importing data######

#import zip file
zipUrl <- 'https://d396qusza40orc.cloudfront.net/getdata%2Fprojectfiles%2FUCI%20HAR%20Dataset.zip'
zipFile <- "UCI HAR Dataset.zip"

if (!file.exists(zipFile)) {
                download.file(zipUrl, zipFile, mode = "wb")
}

#unzip zipfile to directory if it doesnt already exist

dataPath <- "UCI HAR Dataset"
if (!file.exists(dataPath)) {
                unzip(zipFile)        
}

dir()

#importing the data into R

#read training data
trainingSubject <- read.table(file.path(dataPath, "train", "subject_train.txt")) #the "train" folder within the ZIP file
trainingValues <- read.table(file.path(dataPath, "train", "X_train.txt"))
trainingActivity <- read.table(file.path(dataPath, "train", "y_train.txt"))                              

#read test data
testSubject <- read.table(file.path(dataPath, "test", "subject_test.txt"))
testValues <- read.table(file.path(dataPath, "test", "X_test.txt"))
testActivity <- read.table(file.path(dataPath, "test", "y_test.txt"))

#read features dataset (ie. column names)
features <- read.table(file.path(dataPath, "features.txt"), as.is = T)
head(features)
str(features)

#read activityLabel
activityLabel <- read.table(file.path(dataPath, "activity_labels.txt"))
head(activityLabel)
colnames(activityLabel) <- c("activityID", "activityLabel")        
activityLabel

######1. Merges the training and the test sets to create one data set.######

#concatenate the 6 data tables
mergedData <- rbind(
        cbind(trainingSubject, trainingValues, trainingActivity),
        cbind(testSubject, testValues, testActivity)
)
str(mergedData)
#note combining all the Data Frames seems fine. (previously combining Data tables with data frames yielded additional rows...) 

#assign column names *********************** from a 'features' data frame*****
colnames(mergedData) <- c("subject", features[, 2], "activity") ###note here subset[ , 2] ie all rows and only the 2nd column of variable names
names(mergedData)

#remove the individual datasets to save memory
rm(trainingActivity, trainingSubject, trainingValues,
   testActivity, testSubject, testValues)

######2. Extracts only the measurements on the mean and standard deviation for each measurement.######

names(mergedData)
tolower(names(mergedData)) #ensure all variable names in lower case

#Per question, we only want the selected columns of 'Subject' OR 'activity', OR the 'means' and 'standard deviation' of each unit of measurement

columnsKept <- grepl("subject|activity|mean|std", colnames(mergedData)) #finding those strings of texts (ie. OR '|') from the variables
columnsKept
mergedData <- mergedData[, columnsKept] #subsets and keeps the observation rows for those selected variables/columns
names(mergedData)

######3. Uses descriptive activity names to name the activities in the data set.######

head(mergedData)
activityLabel #note the activitylabel dataset from before

#note the activity column is labelled 1-6. Need to replace this with the actual activity labels per txt.file.

###******
mergedData$activity <- activityLabel[mergedData$activity, 2] #renaming the 'activity' variable per the labels in the activitylabel dataset
head(mergedData$activity)

######4. Appropriately labels the data set with descriptive variable names.######

names(mergedData)
renameColumns <- colnames(mergedData)
str(renameColumns) #note the Character class, essentially a list of the column names. (ie. not actual columns themselves at this point)

renameColumns
renameColumns <- gsub("[\\(\\)-]", "", renameColumns) #to remove any '(' , ')', '-' symbols in the variable names
renameColumns

renameColumns <- gsub("^f", "frequencydomain", renameColumns) #where 'f' begins in the name (ie. ^)
renameColumns <- gsub("^t", "timeDomain", renameColumns)
renameColumns <- gsub("[Aa]cc", "Accelerometer", renameColumns)
renameColumns <- gsub("[Gg]yro", "Gyroscope", renameColumns)
renameColumns <- gsub("[Mm]ag", "Magnitude", renameColumns)
renameColumns <- gsub("[Ff]req", "Frequency", renameColumns)
renameColumns <- gsub("mean", "Mean", renameColumns)
renameColumns <- gsub("[Ss]td", "StandardDeviation", renameColumns)
renameColumns

grep("[Ss]td", renameColumns, value = T) #to check for any string of odd characters left. 

#noted some instances of "BodyBody"
renameColumns <- gsub("BodyBody", "Body", renameColumns)
renameColumns

#use these list of names as the column names of our dataset
colnames(mergedData) <- renameColumns
names(mergedData)
str(mergedData)


#####5. From the data set in step 4, creates a second, independent tidy data set with the average of each 
#####variable for each activity and each subject.#####

library(dplyr)
mergedDataMeans <- mergedData %>% 
                        group_by(subject, activity) %>% 
                        summarise_each(funs = mean) #applying the pipeline operator %>% , and creating a table of variable means grouped by subject and activity

write.table(mergedDataMeans, "tidy_data.txt", row.names = F,
                        quote = F) #remove quotation marks around character strings
