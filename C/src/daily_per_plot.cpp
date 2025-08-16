#include "../inc/enums.hpp"
#include "../inc/daily_per_plot.hpp"
#include "../inc/structs.hpp"
#include "../inc/constants.hpp"
#include <algorithm>
#include <vector>
#include <chrono>
#include <cmath>
#include <iostream>
#include <fstream>

using namespace std;

/*
==========
==========
HERBIVORE MODEL
==========
==========
*/


/*
==========
herbivory_run
==========
*/
/*
HERBIVORE
    herbivore:
        passes the herbivore agent
//    
    Plants
        passes the plant agents    
COMMENTS
    Conducts herbivory, updates any plant agents it interacts with (removes BLeaf, BStem, BDef, Ms, and QShoot. Currently does not remove N and C from 
    substrate pools).
*/
void herbivory_run(Herbivore& herbivore,
                   Plant Plants[],
                   const int PLOT_SIZE,
                   const int PLANTS_IN_PLOT,
                   const int PLANTS_IN_X,
                   int dayofsim,
                   std::mt19937_64& rnd_num_gen,
                   std::ofstream& ofs_output)
{
    // reset herbivore's daily variables
    herbivore.intake_defence_day = 0;
    herbivore.intake_digest_carbohydrate_day = 0;
    herbivore.intake_digest_protein_day = 0;
    herbivore.intake_NPE_day = 0;
    herbivore.intake_PE_day = 0;
    herbivore.intake_total_day = 0;
    herbivore.intake_water_drinking = 0;
    herbivore.intake_water_forage = 0;
    herbivore.metabolic_water_day = 0;
    herbivore.distance_moved = 0;

    calc_gut_capacity(herbivore);
    calc_bite_size(herbivore);
    calc_handling_time(herbivore);
    calc_foraging_velocity(herbivore);
    ofs_output << "Herbivore's gut capacity is " << herbivore.gut_capacity << " kg DM \n";
    ofs_output << "Herbivore's handling time is " << herbivore.handling_time << " min/g DM \n";
    ofs_output << "Herbivore's bite size is " << herbivore.bite_size << " g DM/bite \n";
    ofs_output << "Length of digestion vectors: " << herbivore.Digestion_BDef.size() << "\n";
    double DP_to_DC_ratio = 1/NPE_to_PE_TARGET;  // digestible protein to digestible carbohydrate ratio required at the start of the day
    
    // for each time step (minute):
    int minute_continuous = 0;
    for (int minute = 0; minute < 24 * 60; minute++)
    {
        ofs_output << "MINUTE: " << minute << "\n";

        // Update the current hour (the hour the herbivore is currently in) and the last hour (the hour it was in last time step)
            
        // Set the continuous minute for this time step (spanning days) and the hour from the last time step
        if (dayofsim == SPIN_UP_LENGTH * 365) // if we are on the first day
        {
            minute_continuous = minute; // the continuous minute (across days) is equal to the current minute
            if (minute_continuous != 0) // if we are not in the first minute on the first day  
            { herbivore.last_hour = herbivore.current_hour; } // set last_hour to current_hour from the last time step
        } else { // if we are not in the first day
            if (minute == 0) // if we are in the first minute on any subsequent day
            { 
                minute_continuous = (dayofsim - (SPIN_UP_LENGTH * 365)) * (24 * 60); // set the continuous minute (across days)
            } else { // if we are not in the first minute
                minute_continuous = minute_continuous + 1; // set the new continuous minute
            }

        herbivore.last_hour = herbivore.current_hour; // set last_hour to current_hour from the last time step
        }

        // Calculate and update the current hour (the hour this minute falls in to):
        herbivore.current_hour = std::floor(minute_continuous/60);

        ofs_output << "We are in minute #" << minute << " on day #" << dayofsim << "\n";
        ofs_output << "The herbivore has foraged for " << minute_continuous << " minutes over the simulation and the current foraging hour is " << herbivore.current_hour << "\n";

        // incorporate any energy ready to be incorporated and "excrete" waste
        if (herbivore.current_hour != herbivore.last_hour) // if we have entered a new hour
        {
            incorporate_energy(herbivore, ofs_output);
            ofs_output << "Herbivore should digest and excrete " << herbivore.Digestion_BLeaf[(herbivore.MRT)-1] + herbivore.Digestion_BStem[(herbivore.MRT)-1] + herbivore.Digestion_BDef[(herbivore.MRT)-1] << "kg DM \n";
            digest_and_excrete(herbivore, ofs_output);
			calc_gut_content(herbivore);
            ofs_output << "Herbivore has incorporated some energy and excreted some food \n";
           
        } else {
            calc_gut_content(herbivore);
            ofs_output << "Herbivore has not incorporated any energy this minute \n";
        }

        ofs_output << "Current gut content: " << herbivore.gut_content << " kg DM \n";

        // for the minutes the herbivore is foraging:
        if (minute < herbivore.time_spent_foraging * 60)
        {
            ofs_output << "Herbivore is foraging \n";
            // only proceed if there is space in the herbivore's gut:
            // @TODO: or if NPE:PE target has not been met
            if ((herbivore.gut_content + 0.0001) <= herbivore.gut_capacity) // there is probably a more elegant way to do this
            {
                ofs_output << "Herbivore is hungry \n";

                // Calculate energy requirement at this moment:
                DP_to_DC_ratio = calc_required_energy_ratio(herbivore);
                ofs_output << "Herbivore currently needs a DP:DC ratio of: " << DP_to_DC_ratio << "\n";

                // If the herbivore is currently eating a plant:
                if (herbivore.behaviour == EATING)
                {
                    ofs_output << "Herbivore is currently eating \n";

                    // Should the herbivore continue to eat?
                    // the herbivore should continue to eat if the current plant:
                    // 1. has shoot biomass greater than MIN_SHOOT (should not try to eat a plant that is too small)
                    // 2. is desirable in terms of nutrition OR if the density of other available plants is low 
                    if (Plants[herbivore.selected_plant_ID].Ms > (MIN_SHOOT + 0.00000001)) // if the plant is big enough to eat, assess it relative to other plants
                    {
                        //ofs_output << "Selected plant Ms = " << Plants[herbivore.selected_plant_ID].Ms << " > MIN_SHOOT = " << MIN_SHOOT << "\n";

                        double plant_density = calc_plant_density(herbivore, Plants, PLOT_SIZE, PLANTS_IN_PLOT, PLANTS_IN_X, ofs_output); // calculate the density of plants around the herbivore [plants/km^2]
                        std::uniform_real_distribution<double> unif_real_dist(0.0, 1.0);    // Returns a real number in [0,1]
                        double rnd_num = unif_real_dist(rnd_num_gen);
                        double diff = calc_difference_between_CN_ratios(DP_to_DC_ratio, Plants[herbivore.selected_plant_ID]);

                        // if the plant has a good nutrient ratio and/or there aren't a lot of other plants around, keep eating
                        if (rnd_num > std::abs(diff) / plant_density * 10000 ) // @TODO: this may make the herbivore choose a new plant too often?
                        {
                            ofs_output << "Herbivore will continue eating plant " << herbivore.selected_plant_ID << "\n";
                            eat(herbivore, Plants[herbivore.selected_plant_ID], ofs_output);
                    
                        // if else, the herbivore should move on from the plant it was eating
                        } else {
                            ofs_output << "Herbivore needs to choose a new plant \n";

                            herbivore.behaviour = MOVING;

                            // choose a plant to move to:
                            pick_a_plant(herbivore, Plants, PLOT_SIZE, PLANTS_IN_PLOT, PLANTS_IN_X, rnd_num_gen, ofs_output);
                        
                            // move toward selected plant:
                            herbivore_move(herbivore, Plants, PLOT_SIZE, rnd_num_gen, ofs_output);

                        }
                    } else { // if the plant is not big enough to eat, choose a new plant
                        ofs_output << "Herbivore needs to choose a new plant \n";

                        herbivore.behaviour = MOVING;

                        // choose a plant to move to:
                        pick_a_plant(herbivore, Plants, PLOT_SIZE, PLANTS_IN_PLOT, PLANTS_IN_X, rnd_num_gen, ofs_output);
                        
                        // move toward selected plant:
                        herbivore_move(herbivore, Plants, PLOT_SIZE, rnd_num_gen, ofs_output);
                    }

                // if the herbivore is currently moving
                } else if (herbivore.behaviour == MOVING) {

                    ofs_output << "Herbivore is currently moving \n";
                    ofs_output << "Distance from herbivore to selected plant: " << herbivore.selected_plant_dist << " m \n";

                    // if the plant the herbivore was moving towards last time step is not within it's eating radius (or is just a random point): 
                    if (herbivore.selected_plant_dist > EAT_RADIUS || herbivore.selected_plant_ID == -1) 
                    {
                        // should the herbivore select a new plant?
                        std::uniform_real_distribution<double> unif_real_dist(0.0, 1.0);    // Returns a real number in [0,1]
                        double rnd_num = unif_real_dist(rnd_num_gen);  
                        
                        if (rnd_num > 0.9 || herbivore.selected_plant_ID == -1) 
                        {
                            // choose a plant to move to:
                            ofs_output << "Herbivore needs to choose a new plant \n";
                            pick_a_plant(herbivore, Plants, PLOT_SIZE, PLANTS_IN_PLOT, PLANTS_IN_X, rnd_num_gen, ofs_output);
                            ofs_output << "Herbivore has successfully chosen new plant \n";

                        } // otherwise keep moving toward the previously selected plant

                        // move toward selected plant
                        ofs_output << "Herbivore will move towards plant " << herbivore.selected_plant_ID << " from point (" << herbivore.xcor << ", " << herbivore.ycor << ") \n";
                        herbivore_move(herbivore, Plants, PLOT_SIZE, rnd_num_gen, ofs_output);
                        ofs_output << "Herbivore has successfully moved, has new coordinates: (" << herbivore.xcor << ", " << herbivore.ycor << ") \n";
                    
                    // else if the plant the herbivore was moving towards last time step is now within it's eating distance:
                    } else {

                        ofs_output << "Herbivore can start eating plant " << herbivore.selected_plant_ID << "\n";
                        ofs_output << "Plant " << herbivore.selected_plant_ID << " has " << Plants[herbivore.selected_plant_ID].BDef << " kg of defence biomass \n";
                        herbivore.behaviour = EATING;
                        eat(herbivore, Plants[herbivore.selected_plant_ID], ofs_output);
                        ofs_output << "Herbivore has successfully eaten plant " << herbivore.selected_plant_ID << "\n";
                    }

                } // end if herbivore is MOVING
            } // end if space in herbivore gut
        } // end foraging minutes
   
    } // end minute time step

    // has water requirement been met? If not, herbivore must move to water point to drink and incur an energy cost
    double water_required = calc_water_requirement(herbivore);
    ofs_output << "Herbivore needs " << water_required << " kg of water today \n";

    if ( (herbivore.metabolic_water_day + herbivore.intake_water_forage) - water_required < 0 )
    {
        ofs_output << "Herbivore must drink to meet water requirements today \n";
        herbivore.intake_water_drinking = water_required - (herbivore.metabolic_water_day + herbivore.intake_water_forage);
        herbivore.distance_moved += DIST_TO_WATER;
    }

    // update herbivore energy balance and water balance
    herbivore.energy_balance += (herbivore.intake_PE_day + herbivore.intake_NPE_day) - (calc_cost_maintenance(herbivore) + calc_cost_locomotion(herbivore));
    herbivore.water_balance += (herbivore.metabolic_water_day + herbivore.intake_water_forage + herbivore.intake_water_drinking) - water_required;
    // @TODO: WHEN ENERGY AND/OR WATER BALANCE DROPS BELOW A CERTAIN THRESHHOLD/FOR A CERTAIN PERIOD OF TIME, DEATH

    ofs_output << "Today the herbivore has travelled: " << herbivore.distance_moved << " m \n";
    ofs_output << "Today the herbivore has eaten: " << herbivore.intake_total_day << " kg DM (" << herbivore.intake_PE_day << " kJ PE and " << herbivore.intake_NPE_day << "kJ NPE) \n";
    ofs_output << "Today the herbivore has consumed: " << herbivore.intake_water_forage << " kg of water from forage \n";
    ofs_output << "Today the herbivore has generated: " << herbivore.metabolic_water_day << " kg of water from metabolism \n";
    ofs_output << "Herbivore's energy balance today is: " << herbivore.energy_balance << " kJ \n";
    ofs_output << "Herbivore's water balance today is: " << herbivore.water_balance << " kg \n";
}


/*
==========
calc_gut_capacity
==========
*/
void calc_gut_capacity(Herbivore& herbivore)
{
/*
HERBIVORE
    gut_capacity:
        maximum amount of vegetation a herbivore can contain in it's gut [kg DM]
    
    mass:
        herbivore body mass [kg]
    
    GUT_CAPACITY_A:
        coeffient for gut capacity scaling relationship with mass []

    GUT_CAPACITY_B:
        exponent for gut capacity scaling relationship with mass []

COMMENTS
    Calculates the gut capacity of a herbivore. Assumes an allometric scaling relationship with mass, with 
    parameter estimates taken from Muller et al. (2013)
*/
    
    herbivore.gut_capacity =  GUT_CAPACITY_A * pow(herbivore.mass, GUT_CAPACITY_B);
}


/*
==========
calc_gut_content
==========
*/
void calc_gut_content(Herbivore& herbivore)
{
/*
HERBIVORE
    gut_content:
        amount of dry mass currently contained in herbivore's gut [kg DM]
    
    herbivore:
        herbivore
    
COMMENTS
    Calculates the amount of dry mass current contained in herbivore's gut by summing the biomass contained in the digestion
    tracking vectors, herbivore.Digestion_BLeaf, herbivore.Digestion_BStem, and herbivore.Digestion_BDef.
*/
    
    herbivore.gut_content =  std::accumulate(herbivore.Digestion_BLeaf.begin(), herbivore.Digestion_BLeaf.end(), 0.0) +
                             std::accumulate(herbivore.Digestion_BStem.begin(), herbivore.Digestion_BStem.end(), 0.0) +
                             std::accumulate(herbivore.Digestion_BDef.begin(), herbivore.Digestion_BDef.end(), 0.0);
}


/*
==========
calc_digest_time_stem
==========
*/
//void calc_digest_time_stem(Herbivore& herbivore)
//{
/*
HERBIVORE
    digest_time_stem:
        mean retention time for stem biomass [hrs]
    
    mass:
        herbivore body mass [kg]
    
    STEM_MEAN_RETENTION_TIME_A:
        coeffient for mean retention time scaling relationship with mass []

    STEM_MEAN_RETENTION_TIME_B:
        exponent for mean retention time scaling relationship with mass []

COMMENTS
    Calculates the mean retention time for stem biomass. Assumes an allometric scaling relationship with mass, with parameter 
    estimates taken from Foose (1982) (for grass hay, which is of low quality with high cellulose content). Rounds up to the 
    nearest integer.
*/
    
//    herbivore.digest_time_stem =  std::ceil(STEM_MEAN_RETENTION_TIME_A * pow(herbivore.mass, STEM_MEAN_RETENTION_TIME_B));
//}


/*
==========
calc_digest_time_leaf
==========
*/
//void calc_digest_time_leaf(Herbivore& herbivore)
//{
/*
HERBIVORE
    digest_time_leaf:
        mean retention time for leaf biomass [hrs]
    
    mass:
        herbivore body mass [kg]
    
    LEAF_MEAN_RETENTION_TIME_A:
        coeffient for mean retention time scaling relationship with mass []

    LEAF_MEAN_RETENTION_TIME_B:
        exponent for mean retention time scaling relationship with mass []

COMMENTS
    Calculates the mean retention time for leaf biomass. Assumes an allometric scaling relationship with mass, with parameter 
    estimates taken from Foose (1982) (for alfalfa hay, which is of high quality with low cellulose content). Rounds up to the
    nearest integer.
*/
    
//    herbivore.digest_time_leaf =  std::ceil(LEAF_MEAN_RETENTION_TIME_A * pow(herbivore.mass, LEAF_MEAN_RETENTION_TIME_B));
//}


/*
==========
calc_bite_size
==========
*/
void calc_bite_size(Herbivore& herbivore)
{
/*
HERBIVORE
    bite_size:
        amount of dry plant mass the herbivore can take per bite [g DM/bite]
    
    mass:
        herbivore body mass [kg]
    
    BITE_SIZE_A:
        coeffient for bite size scaling relationship with mass []

    BITE_SIZE_B:
        exponent for bite size scaling relationship with mass []

COMMENTS
    Calculates the bite size of a herbivore in dry mass. Assumes an allometric scaling relationship with mass, with 
    parameter estimates taken from Shipley et al. (1994)
*/
    
    herbivore.bite_size =  BITE_SIZE_A * pow(herbivore.mass, BITE_SIZE_B);
    
}


/*
==========
calc_handling_time
==========
*/
void calc_handling_time(Herbivore& herbivore)
{
/*
HERBIVORE
    handling time:
        time taken to crop and chew a single g DM of food [min/g DM]
    
    mass:
        herbivore body mass [kg]
    
    HANDLING_TIME_A:
        coeffient for handling time scaling relationship with mass []

    HANDLING_TIME_B:
        exponent for handling time scaling relationship with mass []

COMMENTS
    Calculates the handling time for a herbivore. Assumes an allometric scaling relationship with mass, with 
    parameter estimates taken from Jeschke & Tollrian (2005)
*/
    
    herbivore.handling_time =  HANDLING_TIME_A * pow(herbivore.mass, HANDLING_TIME_B);
}


/*
==========
calc_foraging_velocity
==========
*/
void calc_foraging_velocity(Herbivore& herbivore)
{
/*
HERBIVORE
    foraging_velocity:
        maximum velocity at which the herbivore will move around looking for plants [m/s]
    
    mass:
        herbivore body mass [kg]
    
    FORAGE_VEL_A:
        coeffient for foraging velocity scaling relationship with mass []

    FORAGE_VEL_B:
        exponent for foraging velocity scaling relationship with mass []

COMMENTS
    Calculates the foraging velocity of a herbivore. Assumes an allometric scaling relationship with mass, with 
    parameter estimates taken from Shipley et al. (1996)
*/
    
    herbivore.FV_max =  FORAGE_VEL_A * pow(herbivore.mass, FORAGE_VEL_B);
}                          


/*
=========================
calc_required_energy_ratio
=========================
*/
/*   
HERBIVORE
    herbivore
        the herbivore agent   
COMMENTS
    Calculates and returns the required ratio of digestible protein energy to digestible carbohydrate energy needed at the present time,
    based on the herbivore's DP:DC target and what it has already eaten today.
*/
double calc_required_energy_ratio(Herbivore& herbivore)
{
    // Calculate energy requirement at this moment:
    double energy_required =  calc_cost_maintenance(herbivore) + calc_cost_locomotion(herbivore);                 // total energy needed for maintenance and locomotion so far
    double PE_required = (energy_required/(NPE_to_PE_TARGET + 1)) - herbivore.intake_PE_day;                      // PE still needed today
    double NPE_required = (energy_required/(NPE_to_PE_TARGET + 1)) * NPE_to_PE_TARGET - herbivore.intake_NPE_day; // NPE still needed today
    double DP_to_DC_ratio = PE_required/NPE_required; // digestible carbohydrate units required per digestible protein unit to meet energy targets at the present time step

    return(DP_to_DC_ratio);
}


/*
==========
calc_cost_maintenance
==========
*/
double calc_cost_maintenance(Herbivore& herbivore)
{
/*
HERBIVORE    
    mass:
        herbivore body mass [kg]
    
    ENERGY_MAINTENANCE_A:
        coeffient for energetic requirements for maintenance scaling relationship with mass []

    GUT_CAPACITY_B:
        exponent for energetic requirements for maintenance scaling relationship with mass []

COMMENTS
    Calculates the energy required for maintenance (kJ/day). Assumes an allometric scaling relationship with metabolically active mass (M^0.75), with 
    parameter estimates taken from Kleiber (1961).
*/
    return ENERGY_MAINTENANCE_A * pow(herbivore.mass, ENERGY_MAINTENANCE_B);

}


/*
==========
calc_cost_locomotion
==========
*/
double calc_cost_locomotion(Herbivore& herbivore)
{
/*
HERBIVORE
    mass:
        herbivore body mass [kg]
    
    ICL_A:
        coeffient for incremental cost of locomotion scaling relationship with mass []

    GUT_CAPACITY_B:
        exponent for incremental cost of locomotion scaling relationship with mass []

COMMENTS
    Calculates the energy expended via locomotion (kJ/day). Assumes that the incremental cost of locomotion has an 
    allometric scaling relationship with mass, with parameter estimates taken from Taylor (1980)
*/
    return (herbivore.distance_moved/1000) * (ICL_A * pow(herbivore.mass, ICL_B))/100;
} 


/*
==========
calc_plant_density
==========
*/
/*
HERBIVORE
    herbivore:
        the herbivore agent
    Plants
        the set of all plant agents    
COMMENTS
    Calculates the density of edible plants around the herbivore [plants/km^2]. Assumes that grazing herbivores are only interested
    in grasses (C3_GRASS & C4_GRASS), while browsing herbivores are only interested in trees (TREE). Mixed feeders are interested in 
    all three types of plant. Browsers and mixed feeders ignore trees with leaves higher than their BROWSE_HEIGHT.
*/
double calc_plant_density(Herbivore& herbivore,
                          Plant Plants[],
                          const int PLOT_SIZE,
                          const int PLANTS_PER_PLOT,
                          const int PLANTS_IN_X,
                          std::ofstream& ofs_output)
{
    // Get plants in herbivore's detection distance
    std::vector<int> plants_of_interest = get_plants_of_interest(herbivore, PLOT_SIZE, PLANTS_PER_PLOT, PLANTS_IN_X, ofs_output);

    // The number of plants in the herbivore's detection distance is:
    int number_dd = plants_of_interest.size();

    // The herbivore will ignore plants it cannot eat
    for (int i = 0; i < plants_of_interest.size(); i++)
    {
        int plant_id = plants_of_interest[i];
        if (
            //@TODO: Get GRAZER, BROWSER, and MIXED to work
            ((Plants[plant_id].VegType == 0 || Plants[plant_id].VegType == 1) && herbivore.HerbType == 1)
            ||
            (Plants[plant_id].VegType == 2 && (herbivore.HerbType == 0 || (Plants[plant_id].Height * LEAF_HEIGHT > BROWSE_HEIGHT)))
        )
        {
            number_dd -= 1; // remove that plant from the total number of interest
        }
    }

    //ofs_output << "There are " << number_dd << " plants of interest around the herbivore \n";
    // calculate plant density [plants/km^2]:
    double plant_density = number_dd / (( M_PI * pow( DETECTION_DISTANCE, 2 ) ) / ( 1 * pow(10, 6) ) );

    return(plant_density);
}


/*
=========================
calc_difference_between_CN_ratios
=========================
*/
/* 
HERBIVORE  
    herbivore
        the herbivore agent
    plant
        the plant agent  
COMMENTS
    Calculates and returns the difference between the herbivore's required ratio of digestible protein energy to digestible carbohydrate energy 
    and the plant's shoot C:N ratio.
*/
double calc_difference_between_CN_ratios(double desired_DP_TO_DC,
                                         Plant& plant)
{
    // if plant.Ns or plant.Cs is negative (or nan), make the herbivore read the plant's Ns or Cs as zero; ditto if plant.Ms = 0
    double plant_Ns = plant.Ns;
    double plant_Cs = plant.Cs;
    if (plant_Ns >= 0.0) { plant_Ns = plant.Ns; } else { plant_Ns = 0.0; }
    if (plant_Cs >= 0.0) { plant_Cs = plant.Cs; } else { plant_Cs = 0.0; }

    // calculate the difference between the herbivore's required ratio of DP:DC and the plant's shoot N:C ratio:
    double difference = (desired_DP_TO_DC - (
        ( ( plant_Ns/PROP_DIGEST_TP ) / N_TO_PROTEIN )                              // DP content of plant leaves
        /
        ( plant_Cs / ( ( ( 1 - PROP_NSC_LEAF) * PROP_DIGEST_SC ) + PROP_NSC_LEAF ) ) // DC content of plant leaves
        ) );
    
    return(difference);
}


/*
==========
pick_a_plant
==========
*/
/*
HERBIVORE
    herbivore:
        the herbivore agent 
    Plants
        the set of all plant agents
    rnd_num_gen
        the random number generator    
COMMENTS
    Assigns the herbivore a plant to move towards/forage upon. Assumes that grazers and mixed feeders feed on C3_GRASS and C4_GRASS
    plants, while browsers and mixed feeders feed on TREE plants. Assumes browsers and mixed feeders ignore trees with leaves higher than
    their BROWSE_HEIGHT. The plant is chosen semi-stochastically based on a 'tastiness' ranking calculated from the plant's distance from 
    the herbivore, it's shoot C:N ratio relative to the herbivore's current digestible protein:digestible carbohydrate target, and it's 
    defensive biomass. Each plant is assigned a weighted probability of selection based on it's tastiness ranking. A random float between 1
    and 0 is generated, and the herbivore 'walks' down the list of weighted probabilities until the cumulative probability is >= the random 
    float.
*/
void pick_a_plant(Herbivore& herbivore,
                  Plant Plants[],
                  const int PLOT_SIZE,
                  const int PLANTS_PER_PLOT,
                  const int PLANTS_IN_X,
                  std::mt19937_64& rnd_num_gen,
                  std::ofstream& ofs_output)
{
    // get the plants within the herbivore's detection distance:
    std::vector<int> plants_of_interest = get_plants_of_interest(herbivore, PLOT_SIZE, PLANTS_PER_PLOT, PLANTS_IN_X, ofs_output);

    // if there are any plants within the herbivore's detection distance:
    if (plants_of_interest.size() > 1)
    {
        // calculate the weighted probability for selecting each plant:
        std::vector<double> weighted_probabilities = get_weighted_probabilities(herbivore, Plants, PLOT_SIZE, plants_of_interest, ofs_output);
        
        //for (int i = 0; i < weighted_probabilities.size(); i++)
        //{
        //    ofs_output << "Plant of interest " << i << " has a weighted probability of " << weighted_probabilities[i] << "\n";
        //}

        // if any of the weighted probabilities are over 0
        double ZeroProb = 0;
        if (std::any_of(weighted_probabilities.begin(), weighted_probabilities.end(), [ZeroProb](double i){return i > ZeroProb;})) { //@TODO very slow

            ofs_output << "There is a weighted probability over 0, i.e. at least one tasty plant \n";

            // generate a random number between 0 and 1:
            std::uniform_real_distribution<double> unif_real_dist(0.0, 1.0);    // Returns a real number in [0, 1]
            double random_N = unif_real_dist(rnd_num_gen);
            //ofs_output << "Random number = " << random_N << "\n";

            // @TODO: DO WE NEED TO SORT THIS VECTOR IN DESCENDING ORDER? THEY ONLY OCCASIONALLY PICK THE "BEST" PLANT PRESENTLY
            // walk down the weighted_probabilities vector, and select the plant with the cumulative probability >= random_N:
            int plant_tracker;
            double cumulative_prob = 0;
            for (int i = 0; i < weighted_probabilities.size(); i++)
            {
                plant_tracker = i;
                cumulative_prob = cumulative_prob + weighted_probabilities[i];

                //ofs_output << "Plant of interest " << i << " has a cumulative probability of " << cumulative_prob << "\n";
                if (cumulative_prob >= random_N)
                {
                    //ofs_output << "Loop break \n";
                    break;
                }
            }

            // use the plant_tracker value to select the appropriate plant from vect_trans and assign to the herbivore agent:
            herbivore.selected_plant_ID = plants_of_interest[plant_tracker];
            herbivore.selected_plant_dist = calc_herbivore_plant_distance(herbivore, Plants[herbivore.selected_plant_ID], sqrt(PLOT_SIZE), sqrt(PLOT_SIZE));
        
        // if none of the weighted probabilities are over zero
        } else {

            ofs_output << "There are no weighted probabilities over 0, i.e. no tasty plants \n";

            // choose a random point to head towards:
            herbivore.selected_plant_ID = -1;
            herbivore.selected_plant_dist = 0;

        }
    // however, if there is only one plant of interest, select it:
    } else if (plants_of_interest.size() == 1) {

        // there is only one choice, so the herbivore must select that plant:
        herbivore.selected_plant_ID = plants_of_interest[0];
        herbivore.selected_plant_dist = calc_herbivore_plant_distance(herbivore, Plants[plants_of_interest[0]], sqrt(PLOT_SIZE), sqrt(PLOT_SIZE));

    // or if there are no plants of interest
    } else {

        // choose a random point to head towards:
        herbivore.selected_plant_ID = -1;
        herbivore.selected_plant_dist = 0;
    }

    ofs_output << "Herbivore has selected plant " << herbivore.selected_plant_ID << " which is " << herbivore.selected_plant_dist << " m away \n";
}


/*
========================
get_plants_of_interest
========================
*/
/*
HERBIVORE
    herbivore
        the herbivore agent
COMMENTS
    Returns a vector of the plants within the herbivore's DETECTION_DISTANCE
*/
std::vector<int> get_plants_of_interest(Herbivore& herbivore,
                                        const int PLOT_SIZE,
                                        const int PLANTS_PER_PLOT,
                                        const int PLANTS_IN_X,
                                        std::ofstream& ofs_output)
{
    // Snap herbivore to nearest bucket:
    //ofs_output << "Herbivore's (x, y) coordinates are: (" << herbivore.xcor << ", " << herbivore.ycor << ") \n";
    double herbivore_x = convert_m_to_bucket(herbivore.xcor, PLOT_SIZE, PLANTS_IN_X);
    double herbivore_y = convert_m_to_bucket(herbivore.ycor, PLOT_SIZE, PLANTS_IN_X);
    int herbivore_index = get_index(herbivore_x, herbivore_y, PLANTS_IN_X);
    //ofs_output << "Herbivore's current index is: " << herbivore_index << "\n";

    // Get the current x, y coordinates of the herbivore after being snapped to nearest bucket
    std::pair<int, int> herbivore_xy = get_xy(herbivore_index, PLANTS_IN_X);
    //ofs_output << "Herbivore's 'new' (x, y) coordinates are: (" << herbivore_xy.first << ", " << herbivore_xy.second << ") \n";

    // Convert herbivore's detection distance from [m] to [buckets]
    double detection_distance_buckets = convert_m_to_bucket(DETECTION_DISTANCE, PLOT_SIZE, PLANTS_IN_X);
    //ofs_output << "Detection distance is: " << DETECTION_DISTANCE << " m or " << detection_distance_buckets << " buckets \n";

    // Create an empty vector to put our plant IDs in (of size (2 * DETECTION_DISTANCE + 1)^2 OR the number of plants in the plot, whichever is smaller)
    int vector_length = std::min(pow(2 * detection_distance_buckets + 1, 2), double(PLANTS_PER_PLOT));
    std::vector<int> plant_vector(vector_length);
    //ofs_output << "Plants of interest vector length is: " << vector_length << "\n";

    // Get index values for all plants within herbivore's detection distance:
    for (int i = 0; i < (2 * detection_distance_buckets + 1); i++)
    {
        for (int j = 0; j < (2 * detection_distance_buckets + 1); j++)
        {
            int new_j = j;
            if (i < detection_distance_buckets && j == 0) // if bucket is to the left of the index and at the top
            {
                new_j = 2 * detection_distance_buckets + 1; // replace j
            }
            
            int p = i + (-1 * detection_distance_buckets);
            int q = new_j + (-1 * detection_distance_buckets);
            int plant_of_interest = get_index(herbivore_xy.first + p, herbivore_xy.second + q, PLANTS_IN_X);
            
            // Correct bucket #s for world wrapping:
            if (plant_of_interest < 0) // there are no negative indexed buckets
            {
                plant_of_interest = PLANTS_PER_PLOT + plant_of_interest;
            }
            
            plant_vector[i * (2 * detection_distance_buckets + 1) + j] = plant_of_interest;
        }
    }

    //for (int i = 0; i < vector_length; i++)
    //{
    //    ofs_output << "Plant of interest " << i << " is Plant: " << plant_vector[i] << "\n";
    //}

    return plant_vector;
}


/*
==========
convert_m_to_bucket
==========
*/
/*   
HERBIVORE
    distance
        some value in [m]   
COMMENTS
    Converts the passed value into [buckets] (will round up/down if not integer)
*/
int convert_m_to_bucket(double distance,
                        const int PLOT_SIZE,
                        const int PLANTS_IN_X)
{
    return (distance / (sqrt(PLOT_SIZE) / PLANTS_IN_X));
}


/*
==========
get_index
==========
*/
/*
HERBIVORE
    xcor
        x coordinate of agent  
    ycor
        y coordinate of agent    
COMMENTS
    Gets the closest index (bucket #) to a set of (x, y) coordinates
*/
int get_index(double xcor_buckets,
              double ycor_buckets,
              const int PLANTS_IN_X)
{ 
    int x = std::round(xcor_buckets);
    int x_snapped = x % PLANTS_IN_X; // column the xcor falls in
    
    int y = std::round(ycor_buckets);
    int y_snapped = y % PLANTS_IN_X; // row the ycor falls in
    
    int index = y_snapped * PLANTS_IN_X + x_snapped;
    return(index);
}


/*
==========
get_xy
==========
*/
/*
HERBIVORE
    index
        a bucket #
COMMENTS
    Gets the (x, y) coordinates of the passed index (bucket #)
*/
std::pair<int, int> get_xy(int index,
                           const int PLANTS_IN_X)
{
    int x = index % PLANTS_IN_X;
    int y = index / PLANTS_IN_X;

    return std::make_pair(x, y);
}


/*
==========
calc_herbivore_plant_distance
==========
*/
/*
HERBIVORE
    herbivore:
        the herbivore agent 
    plant
        the plant agent

    plot_width
        the width of the plot (on the x axis)
        
    plot_height
        the height of the plot (on the y axis)
        
COMMENTS
    Calculates the shortest distance between the herbivore and the plant passed to the function [m], taking into account 
    world wrapping. Has been modified slightly from the R version to only calculate one plant at a time, as C++ does
    not allow functions to pass entire arrays as output.
*/
double calc_herbivore_plant_distance(Herbivore& herbivore,
                                     Plant& plant,
                                     double plot_width,
                                     double plot_height)
{
    double x = sqrt( 
        pow( std::min( std::abs( herbivore.xcor - plant.xcor ), plot_width - std::abs( herbivore.xcor - plant.xcor ) ), 2) +
        pow( std::min( std::abs( herbivore.ycor - plant.ycor ), plot_height - std::abs( herbivore.ycor - plant.ycor ) ), 2)
        );

    return abs(x);
}


/*
========================
get_weighted_probabilities
========================
*/
/*
HERBIVORE
    herbivore
        the herbivore agent
    Plants
        the set of all plant agents
    plant_vector
        the vector containing all plants within the herbivore's DETECTION_DISTANCE from it's current location (bucket)
COMMENTS
    Calculates the tastiness scores and weighted probabilities of selection for all plants within the herbivore's DETECTION_DISTANCE. Returns a vector containing the weighted
    probabilities. Assumes that grazers and mixed feeders feed on C3_GRASS and C4_GRASS plants, while browsers and mixed feeders feed on TREE plants (non-selected plants are
    given a weighted probability of zero). 'Tastiness' is calculated based on the plant's distance from the herbivore, shoot nitrogen:carbon ratio relative to the herbivore's
    desired digestible protein:digestible carbohydrate ratio, and it's defensive biomass. Each plant is assigned a weighted probability of selection based on it's tastiness ranking.
*/
std::vector<double> get_weighted_probabilities(Herbivore& herbivore,
                                               Plant Plants[],
                                               const int PLOT_SIZE,
                                               std::vector<int> plant_vector,
                                               std::ofstream& ofs_output)
{
    // Calculate the tastiness scores for each plant within the plant_vector (note that plant_vector contains the IDs of plant's within the herbivore's detection distance)
    double sum = 0;
    std::vector<double> tastiness_scores(plant_vector.size());
    std::vector<double> weighted_probabilities(plant_vector.size());

    // for each element in the plant_vector:
    for (int i = 0; i < plant_vector.size(); i++)
    {
        int plant_id = plant_vector[i]; // assign the plant ID

        // if the plant is a grass and the herbivore is a grazer or a mixed feeder
        // OR
        // if the plant is a tree and the herbivore is a browser or a mixed feeder AND the leaf height falls within the herbivore's browse height...
        if (
            //@TODO: Get GRAZER, BROWSER, and MIXED to work
            ((Plants[plant_id].VegType == 0 || Plants[plant_id].VegType == 1) && (herbivore.HerbType == 0 || herbivore.HerbType == 2))
            ||
            (((Plants[plant_id].VegType == 2 && (herbivore.HerbType == 1 || herbivore.HerbType == 2)) && (Plants[plant_id].Height * LEAF_HEIGHT) <= BROWSE_HEIGHT))
            )
        {

            // calculate the distance from the edible plant to the herbivore and add to vectors if within the detection distance:
            double dist = calc_herbivore_plant_distance(herbivore, Plants[plant_id], sqrt(PLOT_SIZE), sqrt(PLOT_SIZE));

            // only calculate the tastiness score if the plant is large enough to eat
            if (Plants[plant_id].Ms > MIN_SHOOT + 0.00000001)
            {

                // calculate the difference between the herbivore's desired DP:DC ratio and the plant's DP:DC ratio
                double DP_to_DC = calc_required_energy_ratio(herbivore);
                //ofs_output << "Herbivore's required energy ratio right now is: " << DP_to_DC << "\n";
                double diff = calc_difference_between_CN_ratios(DP_to_DC, Plants[plant_id]); // @TODO: fixed this from passing Plants[i], correct?
                //ofs_output << "Plant ID: " << plant_id << " has " << diff << " difference in energy ratio to what the herbivore needs \n";
                //ofs_output << "Plant ID: " << plant_id << " is " << dist << " m from herbivore \n";
                //ofs_output << "Plant ID: " << plant_id << " has " << Plants[plant_id].BDef << " kg DM BDef \n";
            
                // calculate the tastiness score and add it to the vector 
                // (note: plants with smaller absolute diff values, smaller distances to the herbivore, and small BDef levels are tastier)
                tastiness_scores[i] = 1 / ( std::abs(diff) + dist + Plants[plant_id].BDef) * 100; //@TODO: this might weight dist too heavily, maybe adjust to (dist/100) or something
            
                // sanity check this, as sometimes the plants have nan or inf values that mess up the calculation:
                if (isnan(tastiness_scores[i]) || isinf(tastiness_scores[i]))
                {
                    //ofs_output << "Tastiness score is either nan or inf, correct to zero \n";
                    tastiness_scores[i] = 0; // make tastiness score actually equal zero
                }
                
                sum += tastiness_scores[i];

            // else if the plant has no shoot biomass, set the tastiness score to 0
            } else {
                tastiness_scores[i] = 0;
            }

            //ofs_output << "Plant " << plant_id << " is a distance of " << dist << " m from the herbivore and has a tastiness score of " << tastiness_scores[i] << "\n";

        // If the herbivore is not interested in the plant:
        } else {
            tastiness_scores[i] = 0;
            //ofs_output << "Plant #" << plant_id << " is not tasty and gets a tastiness score of 0 \n";
        }

    }

    //ofs_output << "Sum of all tastiness scores = " << sum << "\n";

    // calculate the weighted probabilities of each edible plant being selected based on its tastiness score:
    double total_prob = 1;
    for (int j = 0; j < tastiness_scores.size(); j++)
    {
        if (tastiness_scores[j] == 0) // if the tastiness score is 0, just set the weighted probability to zero
        {
            weighted_probabilities[j] = 0;
        } else {                     // else if the tastiness score is not 0, calculate the weighted probability
            weighted_probabilities[j] = tastiness_scores[j]/sum * total_prob;
        }
        //ofs_output << "Plant " << j << " in list has a tastiness score of " << tastiness_scores[j] << " and a weighted probability of " << weighted_probabilities[j] << "\n";
        sum -= tastiness_scores[j];
        total_prob -= weighted_probabilities[j];
        //ofs_output << "New sum = " << sum << " and new total_prob = " << total_prob << "\n";
    }

    return weighted_probabilities;
}


///*
//============
//sortcol
//============
//*/
//bool sortcol(const std::vector<double>& v1, 
//             const std::vector<double>& v2 ) 
//{ 
//    return v1[2] > v2[2]; 
//}


/*
==========
herbivore_move
==========
*/
/*
HERBIVORE
    herbivore:
        the herbivore agent  
    Plants
        the plant agent    
COMMENTS
    Makes the herbivore move toward the selected plant. Implements world-wrapping so that herbivore travels the shortest distance
    (even if it means moving out of one 'side' and through another). Updates the herbivore's xcor and ycor.
*/
void herbivore_move(Herbivore& herbivore,
                    Plant Plants[],
                    const int PLOT_SIZE,
                    std::mt19937_64& rnd_num_gen,
                    std::ofstream& ofs_output)
{
    // calculate the maximum distance the herbivore can move at maximum foraging velocity in one time step (a minute):
    double max_distance = herbivore.FV_max * 60 * 1;
    double xcor;
    double ycor;

    ofs_output << "Maximum distance the herbivore can move this minute is: " << max_distance << " m \n";

    // if the herbivore has selected a plant and if that plant is close enough to move to in one minute
    if (herbivore.selected_plant_ID != -1 && herbivore.selected_plant_dist <= max_distance)
    {   
        // set the herbivore's new coordinates to the plant's coordinates:
        herbivore.xcor = Plants[herbivore.selected_plant_ID].xcor;
        herbivore.ycor = Plants[herbivore.selected_plant_ID].ycor;

        // update the distance moved today:
        double distance_moved = herbivore.selected_plant_dist;
        herbivore.distance_moved += distance_moved;

        // update distance to selected plant after movement:
        herbivore.selected_plant_dist = calc_herbivore_plant_distance(herbivore, Plants[herbivore.selected_plant_ID], sqrt(PLOT_SIZE), sqrt(PLOT_SIZE)); // just to check, make sure this is zero
    
        ofs_output << "Herbivore moves " << distance_moved << " m to selected plant at (" << herbivore.xcor << ", " << herbivore.ycor << ") \n";
    
    // else if the herbivore has not selected a plant or cannot move all the way to the selected plant in one minute:
    } else {

        // if the herbivore has not selected a plant
        if (herbivore.selected_plant_ID == -1)
        {
            // choose a random point to head towards:
            std::uniform_real_distribution<double> unif_real_dist(0.0, sqrt(PLOT_SIZE));
            xcor = unif_real_dist(rnd_num_gen);
            ycor = unif_real_dist(rnd_num_gen);

        // if the herbivore has selected a plant
        } else {

            // set xcor and ycor to that plant's coordinates
            xcor = Plants[herbivore.selected_plant_ID].xcor;
            ycor = Plants[herbivore.selected_plant_ID].ycor;
        }

        ofs_output << "Herbivore would like to move to (" << xcor << ", " << ycor << ") but can't get all the way there \n";

        // calculate the gradient between the herbivore's coordinates and the selected point's coordinates:
        double m = (ycor - herbivore.ycor)/(xcor - herbivore.xcor);

        // calculate the xcor of a point max_distance from the herbivore's coordinates along this line:
        double xnew;
        if (xcor < herbivore.xcor)
        {
            xnew = herbivore.xcor - max_distance/sqrt(1 + pow(m, 2));
        } else {
            xnew = herbivore.xcor + max_distance/sqrt(1 + pow(m, 2));
        }

        // calculate the corresponding ycor for this xcor point:
        double ynew = m * (xnew - herbivore.xcor) + herbivore.ycor;

        // correct for world-wrapping (creates a torus-shaped world):
        if (xnew > sqrt(PLOT_SIZE)) {               // if herbivore moves off the right edge of the world...
            xnew -= sqrt(PLOT_SIZE);                // reposition as if moving back onto the left edge of the world
      
        } else if (xnew < 0) {                      // if herbivore moves off the left edge of the world...
            xnew = sqrt(PLOT_SIZE) - (0 - xnew);    // reposition as if moving back onto the right edge of the world
        }
    
        if (ynew > sqrt(PLOT_SIZE)) {               // if herbivore moves off the top edge of the world...
            ynew -= sqrt(PLOT_SIZE);                // reposition as if moving back onto the bottom edge of the world
      
        } else if (ynew < 0) {                      // if herbivore moves off the bottom edge of the world...
            ynew = sqrt(PLOT_SIZE) - (0 - ynew);    // reposition as if moving back onto the top edge of the world
        }

        ofs_output << "Instead herbivore moves to (" << xnew << ", " << ynew << ") \n";

        // set herbivore's new coordinates:
        herbivore.xcor = xnew;
        herbivore.ycor = ynew;

        herbivore.distance_moved += max_distance;

        // update herbivore's distance from selected plant (if plant chosen)
        if (herbivore.selected_plant_ID != -1)
        {
            herbivore.selected_plant_dist = calc_herbivore_plant_distance(herbivore, Plants[herbivore.selected_plant_ID], sqrt(PLOT_SIZE), sqrt(PLOT_SIZE));
        }
    }
}


/*
==========
eat
==========
*/
/*
HERBIVORE
    herbivore:
        the herbivore agent
    Plants
        the plant agent    
COMMENTS
    Makes the herbivore eat the selected plant. Assumes plant defences impose a penalty on the amount of vegetation the herbivore
    can consume in a given time step (where more defences = slower foraging). Updates the herbivore's daily intake parameters as well
    as it's total intake parameter. Updates the selected plant's BLeaf, BStem, BDef, and Ms parameters.
    @TODO: Empirical evidence suggests that plant defences decrease rate of feeding by reducing BITE SIZE rather than necessarily
    reducing handling time. Look into this.
*/
void eat(Herbivore& herbivore,
         Plant& plant,
         std::ofstream& ofs_output)
{
    // calculate the amount of vegetation the herbivore can consume per minute [kg dry mass]:
    // note: plant defences impose a time penalty on foraging, as the herbivore needs to forage more carefully:
    double prop_defence = plant.BDef/(plant.Ms);
    double veg_per_minute = (1/herbivore.handling_time)/1000 * (1 - prop_defence);
  
    // the structural mass (XDM) the herbivore consumes this minute [kg] is the minimum of the following:
    // 1. the maximum it can eat in a minute at it's current feeding rate
    // 2. however much is left until it's stomach is full
    // 3. the total amount of shoot available on the plant
    ofs_output << "veg_per_minute: " << veg_per_minute << " kg DM \n";
    ofs_output << "plant.Ms: " << plant.Ms << " kg DM \n";
    ofs_output << "plant.Cs: " << plant.Cs << " kg DM \n";
    ofs_output << "plant.Ns: " << plant.Ns << " kg DM \n";
    ofs_output << "plant.BDef: " << plant.BDef << " kg DM \n";
    ofs_output << "plant.QShoot: " << plant.QShoot << "L \n";
    ofs_output << "MIN_SHOOT: " << MIN_SHOOT << " kg DM \n";
    ofs_output << "Before eating this plant, the herbivore has: " << herbivore.gut_content<< " kg DM in it's gut \n";
    double intake_XDM = std::min({veg_per_minute, 
                                  std::max(0.0, plant.Ms - MIN_SHOOT), 
                                  herbivore.gut_capacity - herbivore.gut_content
                                  });
    
    // if plant.Ns or plant.Cs is negative (or nan), make the herbivore read the plant's Ns or Cs as zero
    double plant_Ns = plant.Ns;
    double plant_Cs = plant.Cs;
    if (plant_Ns >= 0.0) { plant_Ns = plant.Ns; } else { plant_Ns = 0.0; }
    if (plant_Cs >= 0.0) { plant_Cs = plant.Cs; } else { plant_Cs = 0.0; }
    
    ofs_output << "Amount of the plant herbivore can consume this minute is " << intake_XDM << " kg DM \n";
    ofs_output << "Plant shoot N content is: " << plant_Ns << " [kg] which is " << plant_Ns/plant.Ms << " fraction of " << plant.Ms << " total shoot mass \n";
    ofs_output << "Plant shoot C content is: " << plant_Cs << " [kg] which is " << plant_Cs/plant.Ms << " fraction of " << plant.Ms << " total shoot mass \n";
 
    // based on structural mass intake, calculate the amount of leaf, stem, defence, N_shoot, C_shoot, N_d, C_d, protein, digestible carbohydrates, and water consumed:
    double intake_leaf = (plant.BLeaf/(plant.BLeaf + plant.BStem + plant.BDef)) * intake_XDM;       // leaf biomass consumed this minute [kg]
    double intake_stem = (plant.BStem/(plant.BLeaf + plant.BStem + plant.BDef)) * intake_XDM;       // stem biomass consumed this minute [kg]
    double intake_def = (plant.BDef/(plant.BLeaf + plant.BStem + plant.BDef)) * intake_XDM;         // plant defence biomass consumed this minute [kg]
    double intake_C_leaf = intake_leaf * (plant_Cs/plant.Ms);                                       // structural C consumed from leaf this minute [kg]
    double intake_C_stem = intake_stem * (plant_Cs/plant.Ms);                                       // structural C consumed from stem this minute [kg]
    //double intake_C_def  = intake_def  * (plant_Cs/plant.Ms);                                       // structural C consumed from defence this minute [kg]
    double intake_N_leaf = intake_leaf * (plant_Ns/plant.Ms);                                       // structural N consumed from leaf this minute [kg]
    double intake_N_stem = intake_stem * (plant_Ns/plant.Ms);                                       // structural N consumed from stem this minute [kg]
	double intake_N_def  = intake_def  * (plant_Ns/plant.Ms);                                       // structural N consumed from defence this minute [kg]
    double intake_water  = intake_XDM  * (plant.QShoot/plant.Ms);                                   // water consumed from shoot biomass this minute [kg]
    if (intake_water < 0.0) { intake_water = 0.0; }                                                 // correct for instances where QShoot is negative
    ofs_output << "intake_leaf " << intake_leaf << " kg DM \n";
    ofs_output << "intake_stem " << intake_stem << " kg DM \n";
    ofs_output << "intake_def " << intake_def << " kg DM \n";
    //ofs_output << "intake_C_leaf " << intake_C_leaf << " kg DM \n";   
    //ofs_output << "intake_C_stem " << intake_C_stem << " kg DM \n";
	//ofs_output << "intake_C_def"   << intake_C_def << "kg DM \n";
    //ofs_output << "intake_N_leaf " << intake_N_leaf << " kg DM \n"; 
    //ofs_output << "intake_N_stem " << intake_N_stem << " kg DM \n"; 
	//ofs_output << "intake_N_def " << intake_N_def << " kg DM \n"; 
    //ofs_output << "intake_water " << intake_water << " kg DM \n";

    //********************
    // HERBIVORE-UPDATES
    //********************

    // calculate incorporatable N 
    // @TODO. Currently this does nothing interesting, but when defences are eventually split into physical/chemical, N from defence may not always be incorporated:
    //double incorp_N = intake_N_leaf + intake_N_stem + intake_N_def;
    //ofs_output << "There is " << incorp_N << " kg of incorporatable N in this amount of shoot material \n";
  
    // digestible carbohydrate intake depends on the proportion of leaf and stem consumed (assuming defence is all non-digestible, structural carbohydrate)
    double intake_NSC_leaf = PROP_NSC_LEAF * intake_C_leaf;                             // non-structural carbohydrates (leaf)
    double intake_NSC_stem = PROP_NSC_STEM * intake_C_stem;                             // non-structural carbohydrates (stem)
	//double intake NSC_def = PROP_NSC_DEF * intake_C_def;                                // non-structural carbohydrates (defence)
    double intake_DSC_leaf = (1 - PROP_NSC_LEAF) * intake_C_leaf * PROP_DIGEST_SC;      // digestible fibre (leaf)
    double intake_DSC_stem = (1 - PROP_NSC_STEM) * intake_C_stem * PROP_DIGEST_SC;      // digestible fibre (stem)
	//double intake_DSC_def = (1- PROP_NSC_DEF) * intake_C_stem * PROP_DIGEST_SC;         // digestible fibre (defence)
    double intake_DC_leaf  = intake_NSC_leaf + intake_DSC_leaf;                         // digestible carbohydrates (leaf)
    double intake_DC_stem  = intake_NSC_stem + intake_DSC_stem;                         // digestible carbohydrates (stem)
	//double intake_DC_def = intake_NSC_def + intake_DSC_def;                             // digestible carbohydrates (defence)
	ofs_output << "digestible carbohydrates (leaf): " << intake_DC_leaf << " kg DM \n";
    ofs_output << "digestible carbohydrates (stem): " << intake_DC_stem << " kg DM \n"; 
  
    // calculate total digestible protein consumed (digestible) (kg DM):
    double intake_DP_leaf  = N_TO_PROTEIN * intake_N_leaf * PROP_DIGEST_TP;                         // digestible protein (leaf)
    double intake_DP_stem  = N_TO_PROTEIN * intake_N_stem * PROP_DIGEST_TP;                         // digestible protein (stem)
    double intake_DP_def   = N_TO_PROTEIN * intake_N_def  * PROP_DIGEST_TP;                         // digestible protein (defence)
    //double intake_DP       = intake_DP_leaf + intake_DP_stem + intake_DP_def; 
    ofs_output << "digestible proteins (leaf): " << intake_DP_leaf << " kg DM \n";
    ofs_output << "digestible proteins (stem): " << intake_DP_stem << " kg DM \n";
    ofs_output << "digestible proteins (def): " << intake_DP_def << " kg DM \n";

    ofs_output << "BEFORE digestion vector update: \n";
    ofs_output << "herbivore.Digestion_BLeaf[0] = " << herbivore.Digestion_BLeaf[0] << " kg DM \n";
    ofs_output << "herbivore.Digestion_BStem[0] = " << herbivore.Digestion_BStem[0] << " kg DM \n";
    ofs_output << "herbivore.Digestion_BDef[0] = "  << herbivore.Digestion_BDef[0]  << " kg DM \n";
    ofs_output << "herbivore.Digestion_DC_leaf[0] = " << herbivore.Digestion_DC_leaf[0] << " kg DM \n";
    ofs_output << "herbivore.Digestion_DC_stem[0] = " << herbivore.Digestion_DC_stem[0] << " kg DM \n";
    ofs_output << "herbivore.Digestion_DP_leaf[0] = " << herbivore.Digestion_DP_leaf[0] << " kg DM \n";
    ofs_output << "herbivore.Digestion_DP_stem[0] = " << herbivore.Digestion_DP_stem[0] << " kg DM \n";
    ofs_output << "herbivore.Digestion_DP_def[0] = "  << herbivore.Digestion_DP_def[0]  << " kg DM \n";

    // intake is added to the first cell of each vector
    herbivore.Digestion_BLeaf[0]   += intake_leaf;
    herbivore.Digestion_BStem[0]   += intake_stem;
    herbivore.Digestion_BDef[0]    += intake_def;
    herbivore.Digestion_DC_leaf[0] += intake_DC_leaf;
    herbivore.Digestion_DC_stem[0] += intake_DC_stem;
    herbivore.Digestion_DP_leaf[0] += intake_DP_leaf;
    herbivore.Digestion_DP_stem[0] += intake_DP_stem;
    herbivore.Digestion_DP_def[0]  += intake_DP_def;
    ofs_output << "AFTER digestion vector update: \n";
    ofs_output << "herbivore.Digestion_BLeaf[0] = " << herbivore.Digestion_BLeaf[0] << " kg DM \n";
    ofs_output << "herbivore.Digestion_BStem[0] = " << herbivore.Digestion_BStem[0] << " kg DM \n";
    ofs_output << "herbivore.Digestion_BDef[0] = "  << herbivore.Digestion_BDef[0]  << " kg DM \n";
    ofs_output << "herbivore.Digestion_DC_leaf[0] = " << herbivore.Digestion_DC_leaf[0] << " kg DM \n";
    ofs_output << "herbivore.Digestion_DC_stem[0] = " << herbivore.Digestion_DC_stem[0] << " kg DM \n";
    ofs_output << "herbivore.Digestion_DP_leaf[0] = " << herbivore.Digestion_DP_leaf[0] << " kg DM \n";
    ofs_output << "herbivore.Digestion_DP_stem[0] = " << herbivore.Digestion_DP_stem[0] << " kg DM \n";
    ofs_output << "herbivore.Digestion_DP_def[0] = "  << herbivore.Digestion_DP_def[0]  << " kg DM \n";

    // update other herbivore intake parameters:
    herbivore.intake_total_day    += intake_XDM;        // update total daily dry mass intake [kg DM]
    herbivore.intake_total        += intake_XDM;        // update running total dry mass intake [kg DM]
    herbivore.intake_defence_day  += intake_def;        // update total daily defence structure intake [kg DM]
    herbivore.intake_water_forage += intake_water;      // update daily water consumed from shoot biomass [kg]

    //********************
    // PLANT-UPDATES
    //********************
    // remove appropriate biomass from plant
    plant.BLeaf  -= intake_leaf;
    plant.BStem  -= intake_stem;
    plant.BDef   -= intake_def;
    plant.Ms     -= (intake_leaf + intake_stem + intake_def);
    plant.QShoot -= intake_water;

}


/*
==========
incorporate_energy
==========
*/
/*
HERBIVORE
    herbivore:
        the herbivore agent   
COMMENTS
    Makes the herbivore incorporate the energy contained in the forage (leaf, stem, and defence biomass) in it's gut at the
    appropriate time. Also produces metabolic water from the digestion of protein and carbohydrate.
*/
void incorporate_energy(Herbivore& herbivore,
                        std::ofstream& ofs_output)
{
    // incorporate energy from last cell of each vector
    double intake_DC = herbivore.Digestion_DC_leaf[(herbivore.MRT)-1] +  herbivore.Digestion_DC_stem[(herbivore.MRT)-1];
    herbivore.intake_digest_carbohydrate_day += intake_DC;                                 // update daily digestible carbohydrates consumed [kg]
    herbivore.intake_NPE_day                 += CARB_TO_ENERGY * intake_DC * 1000;         // update daily non-protein energy intake [kJ]
    ofs_output << "This hour, the herbivore can incorporate " << herbivore.Digestion_DC_leaf[(herbivore.MRT)-1] << " kJ from digestable carbs from leaf biomass \n";
    ofs_output << "This hour, the herbivore can incorporate " << herbivore.Digestion_DC_stem[(herbivore.MRT)-1] << " kJ from digestable carbs from stem biomass \n";
    ofs_output << "This is a total of " << intake_DC << " kJ from digestible carbohydrates \n";

    double intake_DP = herbivore.Digestion_DP_leaf[(herbivore.MRT)-1] +  herbivore.Digestion_DP_stem[(herbivore.MRT)-1] + herbivore.Digestion_DP_def[(herbivore.MRT)-1];
    herbivore.intake_digest_protein_day += intake_DP;                                      // update daily digestible protein consumed [kg]
    herbivore.intake_PE_day += PROTEIN_TO_ENERGY * intake_DP * 1000;                       // update daily protein energy intake [kJ]
    ofs_output << "This hour, the herbivore can incorporate " << herbivore.Digestion_DP_leaf[(herbivore.MRT)-1] << " kJ from digestable proteins from leaf biomass \n";
    ofs_output << "This hour, the herbivore can incorporate " << herbivore.Digestion_DP_stem[(herbivore.MRT)-1] << " kJ from digestable proteins from stem biomass \n";
    ofs_output << "This hour, the herbivore can incorporate " << herbivore.Digestion_DP_def[(herbivore.MRT)-1] << " kJ from digestable proteins from defence biomass \n";
    ofs_output << "This is a total of " << intake_DP << " kJ from digestible proteins \n";

    // calculate total metabolic water produced from digesting the protein and carbohydrates:
    // @TODO. Currently this does not assume any fat consumed 
    herbivore.metabolic_water_day += CARB_TO_MW * intake_DC + PROTEIN_TO_MW * intake_DP;   // update daily metabolic water produced [kg]
    ofs_output << "This hour, the herbivore produces " << CARB_TO_MW * intake_DC + PROTEIN_TO_MW * intake_DP << " kg metabolic water from digestion \n";
   
}


/*
==========
digest_and_excrete
==========
*/
/*
HERBIVORE
    herbivore:
        the herbivore agent   
COMMENTS
    Moves contents of the herbivore's gut along the digestion chain (i.e. moves each entry in the digestion vectors one cell
    to the right, discarding the final cell ["excretion"]). @TODO: maybe this step could add N/C back into soil also.
*/
void digest_and_excrete(Herbivore& herbivore,
                        std::ofstream& ofs_output)
{
        ofs_output << "Before digestion step: \n";
        ofs_output << "herbivore.Digestion_BLeaf[0] = " << herbivore.Digestion_BLeaf[0] << " kg DM \n";
        ofs_output << "herbivore.Digestion_BStem[0] = " << herbivore.Digestion_BStem[0] << " kg DM \n";
        ofs_output << "herbivore.Digestion_BDef[0] = "  << herbivore.Digestion_BDef[0]  << " kg DM \n";
        ofs_output << "herbivore.Digestion_DC_leaf[0] = " << herbivore.Digestion_DC_leaf[0] << " kg DM \n";
        ofs_output << "herbivore.Digestion_DC_stem[0] = " << herbivore.Digestion_DC_stem[0] << " kg DM \n";
        ofs_output << "herbivore.Digestion_DP_leaf[0] = " << herbivore.Digestion_DP_leaf[0] << " kg DM \n";
        ofs_output << "herbivore.Digestion_DP_stem[0] = " << herbivore.Digestion_DP_stem[0] << " kg DM \n";
        ofs_output << "herbivore.Digestion_DP_def[0] = "  << herbivore.Digestion_DP_def[0]  << " kg DM \n";

        ofs_output << "herbivore.Digestion_BLeaf[1] = " << herbivore.Digestion_BLeaf[1] << " kg DM \n";
        ofs_output << "herbivore.Digestion_BStem[1] = " << herbivore.Digestion_BStem[1] << " kg DM \n";
        ofs_output << "herbivore.Digestion_BDef[1] = "  << herbivore.Digestion_BDef[1]  << " kg DM \n";
        ofs_output << "herbivore.Digestion_DC_leaf[1] = " << herbivore.Digestion_DC_leaf[1] << " kg DM \n";
        ofs_output << "herbivore.Digestion_DC_stem[1] = " << herbivore.Digestion_DC_stem[1] << " kg DM \n";
        ofs_output << "herbivore.Digestion_DP_leaf[1] = " << herbivore.Digestion_DP_leaf[1] << " kg DM \n";
        ofs_output << "herbivore.Digestion_DP_stem[1] = " << herbivore.Digestion_DP_stem[1] << " kg DM \n";
        ofs_output << "herbivore.Digestion_DP_def[1] = "  << herbivore.Digestion_DP_def[1]  << " kg DM \n";

        ofs_output << "herbivore.Digestion_BLeaf[end-1] = " << herbivore.Digestion_BLeaf[(herbivore.MRT)-2] << " kg DM \n";
        ofs_output << "herbivore.Digestion_BStem[end-1] = " << herbivore.Digestion_BStem[(herbivore.MRT)-2] << " kg DM \n";
        ofs_output << "herbivore.Digestion_BDef[end-1] = "  << herbivore.Digestion_BDef[(herbivore.MRT)-2]  << " kg DM \n";
        ofs_output << "herbivore.Digestion_DC_leaf[end-1] = " << herbivore.Digestion_DC_leaf[(herbivore.MRT)-2] << " kg DM \n";
        ofs_output << "herbivore.Digestion_DC_stem[end-1] = " << herbivore.Digestion_DC_stem[(herbivore.MRT)-2] << " kg DM \n";
        ofs_output << "herbivore.Digestion_DP_leaf[end-1] = " << herbivore.Digestion_DP_leaf[(herbivore.MRT)-2] << " kg DM \n";
        ofs_output << "herbivore.Digestion_DP_stem[end-1] = " << herbivore.Digestion_DP_stem[(herbivore.MRT)-2] << " kg DM \n";
        ofs_output << "herbivore.Digestion_DP_def[end-1] = "  << herbivore.Digestion_DP_def[(herbivore.MRT)-2]  << " kg DM \n";

        ofs_output << "herbivore.Digestion_BLeaf[end] = " << herbivore.Digestion_BLeaf[(herbivore.MRT)-1] << " kg DM \n";
        ofs_output << "herbivore.Digestion_BStem[end] = " << herbivore.Digestion_BStem[(herbivore.MRT)-1] << " kg DM \n";
        ofs_output << "herbivore.Digestion_BDef[end] = "  << herbivore.Digestion_BDef[(herbivore.MRT)-1]  << " kg DM \n";
        ofs_output << "herbivore.Digestion_DC_leaf[end] = " << herbivore.Digestion_DC_leaf[(herbivore.MRT)-1] << " kg DM \n";
        ofs_output << "herbivore.Digestion_DC_stem[end] = " << herbivore.Digestion_DC_stem[(herbivore.MRT)-1] << " kg DM \n";
        ofs_output << "herbivore.Digestion_DP_leaf[end] = " << herbivore.Digestion_DP_leaf[(herbivore.MRT)-1] << " kg DM \n";
        ofs_output << "herbivore.Digestion_DP_stem[end] = " << herbivore.Digestion_DP_stem[(herbivore.MRT)-1] << " kg DM \n";
        ofs_output << "herbivore.Digestion_DP_def[end] = "  << herbivore.Digestion_DP_def[(herbivore.MRT)-1]  << " kg DM \n";
        
        // all cells must be shifted one cell to the right
        // @TODO: when digest_time becomes different for leaf, stem, def, this will need updating
        for (int i = (herbivore.MRT-1); i > 0; i--)
        {
            herbivore.Digestion_BLeaf[i]   = herbivore.Digestion_BLeaf[i-1];
            herbivore.Digestion_DC_leaf[i] = herbivore.Digestion_DC_leaf[i-1];
            herbivore.Digestion_DP_leaf[i] = herbivore.Digestion_DP_leaf[i-1];
        }
        for (int i = (herbivore.MRT-1); i > 0; i--)
        {
            herbivore.Digestion_BStem[i]   = herbivore.Digestion_BStem[i-1];
            herbivore.Digestion_BDef[i]    = herbivore.Digestion_BDef[i-1];
            herbivore.Digestion_DC_stem[i] = herbivore.Digestion_DC_stem[i-1];
            herbivore.Digestion_DP_stem[i] = herbivore.Digestion_DP_stem[i-1];
            herbivore.Digestion_DP_def[i]  = herbivore.Digestion_DP_def[i-1];
        }

        // cells 0 must be emptied
        herbivore.Digestion_BLeaf[0]   = 0;
        herbivore.Digestion_BStem[0]   = 0;
        herbivore.Digestion_BDef[0]    = 0;
        herbivore.Digestion_DC_leaf[0] = 0;
        herbivore.Digestion_DC_stem[0] = 0;
        herbivore.Digestion_DP_leaf[0] = 0;
        herbivore.Digestion_DP_stem[0] = 0;
        herbivore.Digestion_DP_def[0]  = 0;

        ofs_output << "After digestion step: \n";
        ofs_output << "herbivore.Digestion_BLeaf[0] = " << herbivore.Digestion_BLeaf[0] << " kg DM \n";
        ofs_output << "herbivore.Digestion_BStem[0] = " << herbivore.Digestion_BStem[0] << " kg DM \n";
        ofs_output << "herbivore.Digestion_BDef[0] = "  << herbivore.Digestion_BDef[0]  << " kg DM \n";
        ofs_output << "herbivore.Digestion_DC_leaf[0] = " << herbivore.Digestion_DC_leaf[0] << " kg DM \n";
        ofs_output << "herbivore.Digestion_DC_stem[0] = " << herbivore.Digestion_DC_stem[0] << " kg DM \n";
        ofs_output << "herbivore.Digestion_DP_leaf[0] = " << herbivore.Digestion_DP_leaf[0] << " kg DM \n";
        ofs_output << "herbivore.Digestion_DP_stem[0] = " << herbivore.Digestion_DP_stem[0] << " kg DM \n";
        ofs_output << "herbivore.Digestion_DP_def[0] = "  << herbivore.Digestion_DP_def[0]  << " kg DM \n";

        ofs_output << "herbivore.Digestion_BLeaf[1] = " << herbivore.Digestion_BLeaf[1] << " kg DM \n";
        ofs_output << "herbivore.Digestion_BStem[1] = " << herbivore.Digestion_BStem[1] << " kg DM \n";
        ofs_output << "herbivore.Digestion_BDef[1] = "  << herbivore.Digestion_BDef[1]  << " kg DM \n";
        ofs_output << "herbivore.Digestion_DC_leaf[1] = " << herbivore.Digestion_DC_leaf[1] << " kg DM \n";
        ofs_output << "herbivore.Digestion_DC_stem[1] = " << herbivore.Digestion_DC_stem[1] << " kg DM \n";
        ofs_output << "herbivore.Digestion_DP_leaf[1] = " << herbivore.Digestion_DP_leaf[1] << " kg DM \n";
        ofs_output << "herbivore.Digestion_DP_stem[1] = " << herbivore.Digestion_DP_stem[1] << " kg DM \n";
        ofs_output << "herbivore.Digestion_DP_def[1] = "  << herbivore.Digestion_DP_def[1]  << " kg DM \n";

        ofs_output << "herbivore.Digestion_BLeaf[end-1] = " << herbivore.Digestion_BLeaf[(herbivore.MRT)-2] << " kg DM \n";
        ofs_output << "herbivore.Digestion_BStem[end-1] = " << herbivore.Digestion_BStem[(herbivore.MRT)-2] << " kg DM \n";
        ofs_output << "herbivore.Digestion_BDef[end-1] = "  << herbivore.Digestion_BDef[(herbivore.MRT)-2]  << " kg DM \n";
        ofs_output << "herbivore.Digestion_DC_leaf[end-1] = " << herbivore.Digestion_DC_leaf[(herbivore.MRT)-2] << " kg DM \n";
        ofs_output << "herbivore.Digestion_DC_stem[end-1] = " << herbivore.Digestion_DC_stem[(herbivore.MRT)-2] << " kg DM \n";
        ofs_output << "herbivore.Digestion_DP_leaf[end-1] = " << herbivore.Digestion_DP_leaf[(herbivore.MRT)-2] << " kg DM \n";
        ofs_output << "herbivore.Digestion_DP_stem[end-1] = " << herbivore.Digestion_DP_stem[(herbivore.MRT)-2] << " kg DM \n";
        ofs_output << "herbivore.Digestion_DP_def[end-1] = "  << herbivore.Digestion_DP_def[(herbivore.MRT)-2]  << " kg DM \n";

        ofs_output << "herbivore.Digestion_BLeaf[end] = " << herbivore.Digestion_BLeaf[(herbivore.MRT)-1] << " kg DM \n";
        ofs_output << "herbivore.Digestion_BStem[end] = " << herbivore.Digestion_BStem[(herbivore.MRT)-1] << " kg DM \n";
        ofs_output << "herbivore.Digestion_BDef[end] = "  << herbivore.Digestion_BDef[(herbivore.MRT)-1]  << " kg DM \n";
        ofs_output << "herbivore.Digestion_DC_leaf[end] = " << herbivore.Digestion_DC_leaf[(herbivore.MRT)-1] << " kg DM \n";
        ofs_output << "herbivore.Digestion_DC_stem[end] = " << herbivore.Digestion_DC_stem[(herbivore.MRT)-1] << " kg DM \n";
        ofs_output << "herbivore.Digestion_DP_leaf[end] = " << herbivore.Digestion_DP_leaf[(herbivore.MRT)-1] << " kg DM \n";
        ofs_output << "herbivore.Digestion_DP_stem[end] = " << herbivore.Digestion_DP_stem[(herbivore.MRT)-1] << " kg DM \n";
        ofs_output << "herbivore.Digestion_DP_def[end] = "  << herbivore.Digestion_DP_def[(herbivore.MRT)-1]  << " kg DM \n";

}


/*
==========
calc_water_requirement
==========
*/
/*
HERBIVORE    
    mass:
        herbivore body mass [kg]
    
    WATER_TURNOVER:
        water turnover for the herbivore [mL/kg body mass/24 hrs]

COMMENTS
    Calculates the daily water required for the herbivore (mL) based on its water turnover rate. Parameterised using water turnover data from 
    McFarlane, W.V. (1965). "Water metabolism of desert ruminants". In: "Studies in Physiology", Eds Curtis and McIntyre. 
*/
double calc_water_requirement(Herbivore& herbivore)
{
    return WATER_TURNOVER * herbivore.mass; 
}