# Calculates the total amount of food material (dry mass) remaining in the herbivore’s gut
update_gut_content <- function(herbivore) {
  gut_content <- sum(herbivore$digestion$bleaf) +
                 sum(herbivore$digestion$bstem) +
                 sum(herbivore$digestion$bdef)
                 
  herbivore$gut_content <- gut_content
  return(herbivore)
}
