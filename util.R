get_links <- function(page) {
  result <- tryCatch({
    links <- page %>%
      html_nodes("a") %>%
      html_attr("href") %>%
      unique()
    return(links)
  },
  error = function(e) {
    # If an error occurs, return a message or a default value
    message(sprintf("Error reading %s: %s", url, e$message))
    return(character(0)) # Return an empty character vector
  })
  return(result)
}

# Create a function to scrape a page
get_body <- function(page) {
  body_text <- page %>%
    html_node("body") %>%
    html_text()
  return(body_text)
}

clean_links <- function(list_of_links, company_base) {
  filtered_urls <- unique(list_of_links)
  filtered_urls <- filtered_urls[grepl(company_base, filtered_urls)]
  filtered_urls <- filtered_urls[grepl("http", filtered_urls)]
  filtered_urls <- filtered_urls[!grepl("#", filtered_urls)]
}
