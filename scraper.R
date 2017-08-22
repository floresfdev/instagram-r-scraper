# ---
# Load libraries
library(rJava)


# ---
# Initialize JVM

jvm_status <- .jinit(paste0("./libs/instagramscraper-scraper-0.0.1.jar;",
                            "./libs/okhttp-3.6.0.jar;",
                            "./libs/okio-1.11.0.jar;",
                            "./libs/gson-2.8.0.jar"))

## Print the classpath
print(.jclassPath())

## Check the JVM init
if (jvm_status == 0) {
    message("JVM init succesful.")
} else {
    stop("Error: JVM init.")
}


# ---
# Instantiate a new Instagram object

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

## User @berlinphil (Berliner Philharmoniker)
user_account <- "berlinphil"
j_account <- jInstagram$getAccountByUsername(user_account)

if (is.jnull(j_account)) {
    stop("Error: Can't retrieve account information.")
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
