# Scrape DI

Major issues:

*recursively get all links (some have over 1000)<br>
*make sure no external-links are followed<br>
*remove duplicates<br>
*subsites have same links<br> 
*dont get content from non-company-related sources<br>
*build a model to recognize company-related person-names and roles<br>


LOOP THROUGH EVERY LINK

 1. navigate to base_url
 2. extract all links on landingpage using get_flinks(.
 3. order the links according to depth
 4. create collectlinks-list 
 5. loop through first sublevel (eg https://www.horten.dk/Specialer.
    1. navigate to link
    2. collect all links and add to collectlinks-list
 6. extract all links from list and compare to unique(all-links.
 7. create list of new links compared to landingpage-links
 8. loop through all the new links
    1. navigate to link
    2. collect all links and add to collectlinks-list
 9. go to 6. and repeat this until there are no more duplicates
 get first level of links using selenium
