library(rvest)
library(jsonlite)
library(mongolite)
library(RSelenium)
library(dplyr)
library(stringr)
library(logr)
source("util.R")

mongo_con <- mongo(collection = "webpages", 
                   db = "scrapedi", 
                   url = "mongodb://localhost")

# Selenium-server running in Docker-container
remDr <- RSelenium::remoteDriver(remoteServerAddr = "localhost",port=4445)

# Selenium 
remDr$open()

# get links
linkl <- read.csv("links.csv",sep = ";")
linkl$Hjemmeside = gsub("https:","",linkl$Hjemmeside)
linkl$Hjemmeside = gsub("http:","",linkl$Hjemmeside)
linkl$Hjemmeside = gsub("[\\/]+","",linkl$Hjemmeside)

#main stuff1
sublink <- linkl[4:1,8]
sublink
colllist = list()
contents <- character(0)

######
visited_links <- character(0)
######
pat="(?:www\\.)?([a-z-]+)\\."
limit=5
count=0L

#remDr$navigate(paste0("https://",sublink[1]))
#remDr$navigate(paste0("https://",sublink[2]))
#remDr$navigate(paste0("https://",sublink[3]))

#HANDLE COOKIES
# fk.dk
clid = "CybotCookiebotDialogBodyLevelButtonLevelOptinAllowallSelection"
accept_cookie_button <- remDr$findElement(using = "id", value = clid)
accept_cookie_button$clickElement()

#horten.dk
bclass <- "coi-banner__accept"
accept_cookie_button <- remDr$findElement(using = "class name", value = bclass)
accept_cookie_button$clickElement()

# cbre.dk
cid <- "onetrust-accept-btn-handler"
accept_cookie_button <- remDr$findElement(using = "id", value = cid)
accept_cookie_button$clickElement()

#LOOP THROUGH EVERRY LINK
# 1) navigate to base_url
# 2) extract all links on landingpage using get_flinks()
# 3) order the links according to depth
# 4) create collectlinks-list 
# 5) loop through first sublevel (eg https://www.horten.dk/Specialer)
# 5.1) navigate to link
# 5.2) collect all links and add to collectlinks-list
# 6) extract all links from list and compare to unique(all-links)
# 7) create list of new links compared to landingpage-links
# 8) loop through all the new links
# 8.1) navigate to link
# 8.2) collect all links and add to collectlinks-list
# 
# 9) go to 6) and repeat this until there are no more duplicates
# get first level of links using selenium

# navigate to base
base_url = sublink[2]
base_url = sublink[1]
remDr$navigate(paste0("https://",base_url))
Sys.sleep(3)

# extract base-part of url
pat_for_base="(?:www\\.)?([a-z-]+)\\.([a-z]+)"
base=str_match_all(base_url,pat_for_base)
base_name=base[[1]][2]

# get the landingpage-links
links <- get_flinks()
links <- clean_links(links, base_name)
links

# now get the list grouped by levels
levels <- sapply(links, count_levels)

# Split URLs into lists based on their levels
url_lists <- split(links, levels)
url_lists

# Initialize lists for picking up links
#collist_content = list()
#collist_links = list()
# now loop through the first sublevel of landingpage-links
sublist = unique(url_lists[[2]])
sublist = unique(links)
sublist

collist_links <- visit_landingpage_links(sublist)

#clean for duplicates
all_names <- unlist(sapply(collist_links, function(x) print((x$links))))
# Check for names that appear more than once
duplicates <- duplicated(all_names)
sum(duplicates)
# Get a unique list of names

unique_names <- unique(all_names)
unique_names <- clean_links(unique_names, "fk")
 # visit these links
unique_names
collist_links_level3 <- visit_landingpage_links(unique_names)

# store in mongo
linkdocument <- list(base = base_url, links = unique_names, docdate = Sys.time())
json_document <- toJSON(tmpdocument, auto_unbox = TRUE)
mongo_con$insert(json_document)


# compare to the landingpage-links
not_in_links <- setdiff(unlist(unique_names),unlist(links))
# visit links not in landing page links
collist_links_notLP <- visit_landingpage_links(not_in_links)
collist_links_notLP2 <-  clean_links(collist_links_notLP,base_name)
all_names2 <- unlist(sapply(collist_links_notLP2, function(x) print((x$links))))
# Check for names that appear more than once
duplicates <- all_names[duplicated(all_names2)]
duplicates
# Get a unique list of names
unique_names <- unique(all_names2)
unique_names
# compare to the landingpage-links
not_in_links <- setdiff(unlist(unique_names),unlist(links))

collist_links_notLP2 
not_in_links2<- setdiff(unlist(coll),unlist(links))


visit_landingpage_links <- function(landingpage) {
  
  landingcolllist = list()
  for (i in 1:length(landingpage)) {
    print(paste("visit ..",landingpage[i]))
    if (landingpage[[i]] %in% visited_links) next
    visited_links <<- c(visited_links, landingpage[[i]])
    
    #prepare the key
    nn=floor(runif(1)*1000)
    tmpkey <- gsub("https:","",landingpage[[i]])
    tmpkey <- gsub("\\/","_",tmpkey)
    tmpkey <- gsub("[\\/\\.]","_",tmpkey)
    tmpkey <- gsub("__","_",tmpkey)
    domain <- tmpkey
    tmpkey <- paste0(tmpkey,"_",nn)
    nnl=floor(runif(1)*100)
    tmpkeylink <- paste0(tmpkey,"_links_",nnl)
    # go to link
    tryCatch(
      {
        remDr$navigate(landingpage[[i]])
        Sys.sleep(3)
        tmplinks <- get_flinks()
        tmplinks <- clean_links(tmplinks,base_name)
        # add this link
        #tmplinks[length(tmplinks)+1] <- sublist[[i]]
        tmplinkdocument <- list('_id' = tmpkeylink, level = i,base = base_url, domain = domain, links = tmplinks)
        landingcolllist[length(landingcolllist)+1] <- list(tmplinkdocument)
          },
        error = function(e) {
          message(paste("Error with URL:", url))
          message("Error message:", conditionMessage(e))
          
          # Sleep for a while before moving to the next URL, to avoid rapid retries
          Sys.sleep(1)  # Pause for 10 seconds, adjust as necessary
        }
    )
  }
  return(landingcolllist)
}



get_flinks <- function() {
  link_elem <- remDr$findElements(using="css selector","a")
  links <- sapply(link_elem, function(element) { 
    tryCatch(
      element$getElementAttribute("href")[[1]],
      error = function(e) NA
    )
  })
  return(links)
}


# Sample list of URLs
# Function to count levels of a URL
count_levels <- function(url) {
  # Split by "/"
  parts <- unlist(strsplit(url, "/"))
  
  # Remove the domain part
  length(parts) - 1
}

