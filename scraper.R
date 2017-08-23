# ---
# Load libraries
library(rJava)


# ---
# Settings

## User account to scrape
user_account <- "berlinphil"

## Max number of posts to retrieve
media_count <- as.integer(100)


# ---
# Initialize JVM

jvm_status <- .jinit(paste0("./libs/instagramscraper-scraper-0.0.1.jar;",
                            "./libs/okhttp-3.6.0.jar;",
                            "./libs/okio-1.11.0.jar;",
                            "./libs/gson-2.8.0.jar"))

## Print the classpath
# print(.jclassPath())

## Check the JVM init
if (jvm_status == 0) {
    message("JVM init successful.")
} else {
    stop("Error: JVM init.")
}


# ---
# Instantiate a new Instagram object with default constructor

tryCatch(
    j_instagram <- .jnew("me/postaddict/instagramscraper/Instagram"), 
    Exception = function(e) {
        e$printStackTrace() 
    })

if (is.jnull(j_instagram)) {
    stop("Error: Can't instantiate the Instagram object.")
}


# ---
# Account information

## Call method Instagram.getAccountByUsername()
## Params:
## - String username: "berlinphil" (@berlinphil, Berliner Philharmoniker)
j_account <- j_instagram$getAccountByUsername(user_account)

if (is.jnull(j_account)) {
    stop("Error: Can't retrieve account information.")
} else {
    message("Account information retrieved successfully.")
}


# ---
# Account information: Create a dataframe

df_account <- data.frame(id = j_account$id,
                         username = j_account$username,
                         followsCount = j_account$followsCount,
                         followedByCount = j_account$followedByCount,
                         profilePicUrl = j_account$profilePicUrl,
                         biography = ifelse(is.jnull(j_account$biography), 
                                            "", 
                                            j_account$biography),
                         fullName = j_account$fullName,
                         mediaCount = j_account$mediaCount,
                         isPrivate = j_account$isPrivate,
                         externalUrl = ifelse(is.jnull(j_account$externalUrl),
                                              "",
                                              j_account$externalUrl),
                         isVerified = j_account$isVerified,
                         stringsAsFactors = FALSE)


## Treat encoding
Encoding(df_account$biography) <- c("UTF-8")
Encoding(df_account$fullName) <- c("UTF-8")


# ---
# Account information: Write to CSV

account_file_path <- paste0("./dataout/", 
                            "instagram_account_", 
                            user_account,
                            ".csv")

write.csv(df_account, 
          file = account_file_path, 
          fileEncoding = "UTF-8", 
          row.names = FALSE)


# ---
# Media

## Call method Instagram.getMediasArray()
## Params:
## - String username: "berlinphil" (@berlinphil, Berliner Philharmoniker)
## - int count: 100 (to retrieve only 100 posts)
## Return:
## - Array of Media objects
tryCatch(
    j_medias_array <-
        .jcall(j_instagram,
               "[Lme/postaddict/instagramscraper/model/Media;",
               "getMediasArray", 
               user_account, 
               media_count,
               evalString = FALSE),
    Exception = function(e) {
        e$printStackTrace()
    })

if (length(j_medias_array) == 0) {
    warning("Warning: No media retrieved.")
} else {
    message("Media posts retrieved successfully.")
}


# ---
# Media: Create dataframe

posts_rows <- 
    lapply(
        j_medias_array, 
        function(media) {
            post_row <- data.frame(
                id = media$id,
                createdTime = as.POSIXct(media$createdTime, 
                                         origin = "1970-01-01"),
                type = media$type,
                link = media$link,
                imageStandardResolutionUrl = media$imageStandardResolutionUrl,
                caption = media$caption,
                code = media$code,
                commentsCount = media$commentsCount,
                likesCount = media$likesCount,
                videoViews = media$videoViews,
                stringsAsFactors = FALSE
            )
            
        }
    )

df_posts <- do.call("rbind", posts_rows)

## Treat encoding
Encoding(df_posts$caption) <- c("UTF-8")


# ---
# Media: Write to CSV

posts_file_path <- paste0("./dataout/", 
                            "instagram_posts_", 
                            user_account,
                            ".csv")

write.csv(df_posts, 
          file = posts_file_path, 
          fileEncoding = "UTF-8", 
          row.names = FALSE)


message("End of script.")