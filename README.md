# Scrape DI

Major issues:

*recursively get all links (some have over 1000)<br>
*make sure no external-links are followed<br>
*remove duplicates<br>
*subsites have same links<br> 
*dont get content from non-company-related sources<br>
*build a model to recognize company-related person-names and roles<br>


First attempt (not using recursion because test-case followed external links)

LOOP BASED APPROACH
 1. navigate to base_url
 2. extract all links on landingpage using get_flinks().
 3. order the links according to depth
 4. create collectlinks-list 
 5. loop through first sublevel (eg https://www.horten.dk/Specialer).
    1. navigate to link
    2. collect all links and add to collectlinks-list
 6. extract and clean all links from list 
 8. loop through all the new links
    1. navigate to link
    2. collect all links and add to collectlinks-list
 9. Check list against first list and find new ones
 10. go to 6. and repeat this until there are no more duplicates
 get first level of links using selenium
