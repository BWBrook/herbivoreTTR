#include "../inc/constants.hpp"
#include "../inc/structs.hpp"
#include "../inc/init_aDGVM.hpp"
#include "../inc/enums.hpp"
#include "../inc/daily_per_plot.hpp"
#include <time.h>
#include <cmath>
#include <list>
#include <algorithm>
#include <iostream>
#include <fstream>
#include <random>

using namespace std;

template<typename Iter, typename RandomGenerator>
Iter select_randomly(Iter start, Iter end, RandomGenerator& g) {
    std::uniform_int_distribution<> dis(0, std::distance(start, end) - 1);
    std::advance(start, dis(g));
    return start;
}

template<typename Iter>
Iter select_randomly(Iter start, Iter end) {
    static std::random_device rd;
    static std::mt19937 gen(rd());
    return select_randomly(start, end, gen);
}

/*
==========
init_plants
==========
*/
void init_plants(Plant Plants[])
{
    // calculate the distance between plants in the x and y planes
    double inter_plant_distance_x = sqrt(PLOT_SIZE) / PLANTS_IN_X;
    double inter_plant_distance_y = sqrt(PLOT_SIZE) / PLANTS_IN_Y;

    // establish the coordinates for plant 0 (assuming plant 0 is in one corner of the grid)
    Plants[0].xcor = inter_plant_distance_x / 2;
    Plants[0].ycor = inter_plant_distance_y / 2;
    
    // calculate the coordinates for the other plants in the plot
    for (int i = 0; i < PLANTS_IN_Y; i++)
    {
        for (int j = 0; j < PLANTS_IN_X; j++)
        {
            Plants[i*PLANTS_IN_X+j].xcor = Plants[0].xcor + inter_plant_distance_x * j;
            Plants[i*PLANTS_IN_X+j].ycor = Plants[0].ycor + inter_plant_distance_y * i;
        }
    }

    double lower_bound = 0.0;
    double upper_bound = 0.0;

    std::default_random_engine re;
    
    // for each plant:
    for (int p = 0; p < PLANTS_PER_PLOT; p++)
    {
        std::cout << "INITIAL CONDITIONS FOR PLANT " << p << endl;

        // assign some plant type (0, 1, 2)
        // @TODO: make this controlled by input
        std::list<int> VegTypes = {0, 1};//, 2}; //at the moment using a grazer so for debugging make all grass
        Plants[p].VegType = *select_randomly(VegTypes.begin(), VegTypes.end());

        // assign the plant a random size between 1 and 100 [kg XDM]
        // @TODO: not sure this range is realistic for grasses, might want to adjust so that trees and grasses are assigned sizes
        //        seperately
        lower_bound = 1;
        upper_bound = 100;
        std::uniform_real_distribution<double> unif(lower_bound,upper_bound);
        Plants[p].Ms = unif(re);
        Plants[p].Mr = Plants[p].Ms;
        //Plants[p].Md = Plants[p].Ms * 0.001; // initial defence [kg XDM]
        std::cout << "Ms = " << Plants[p].Ms << endl;
        std::cout << "Mr = " << Plants[p].Mr << endl;
        //std::cout << "Md = " << Plants[p].Md << endl;

        // assign the plant a starting C concentration in root and shoot between (5 - 50%)
        lower_bound = 0.05;
        upper_bound = 0.5;
        std::uniform_real_distribution<double> unif2(lower_bound,upper_bound);
        double init_C = unif2(re);
        std::cout << "init_C = " << init_C << endl;

        // assign the plant a starting N concentration in root and shoot (1 - 2.5%)
        lower_bound = 0.01;
        upper_bound = 0.025;
        std::uniform_real_distribution<double> unif3(lower_bound,upper_bound);
        double init_N = unif3(re);
        std::cout << "init_N = " << init_N << endl;
    
        // assign C and N pools in shoot, root, and defence [kg]
        Plants[p].Cs = Plants[p].Ms * init_C;
        Plants[p].Cr = Plants[p].Mr * init_C;
        //Plants[p].Cd = Plants[p].Md * init_C; 
        Plants[p].Ns = Plants[p].Ms * init_N;
        Plants[p].Nr = Plants[p].Mr * init_N;
        //Plants[p].Nd = Plants[p].Md * init_N;
        std::cout << "Cs = " << Plants[p].Cs << endl;
        std::cout << "Cr = " << Plants[p].Cr << endl;
        //std::cout << "Cd = " << Plants[p].Cd << endl;
        std::cout << "Ns = " << Plants[p].Ns << endl;
        std::cout << "Nr = " << Plants[p].Nr << endl;
        //std::cout << "Nd = " << Plants[p].Nd << endl;
    
        // if plant is a tree (VegType == 2)
        if(Plants[p].VegType == 2)
        {
            // assign leaf, stem, root, reproductive, and defence biomass, and give plant a height
            Plants[p].BLeaf = Plants[p].Ms * 0.5;
            Plants[p].BStem = Plants[p].Ms * 0.5;
            Plants[p].BRoot = Plants[p].Mr;
            Plants[p].BRepr = Plants[p].Ms * 0.0;
		    Plants[p].BDef  = Plants[p].Ms * 0.0001;
            Plants[p].Height = 2.0; // @TODO: make this match the full model
        }

        // if plant is a grass (VegType != 2)
        else
        {
            Plants[p].BLeaf = Plants[p].Ms;
            Plants[p].BStem = 0;
            Plants[p].BRoot = Plants[p].Mr;
            Plants[p].BRepr = Plants[p].Ms * 0.0;
		    Plants[p].BDef = Plants[p].Ms * 0.0001;
            Plants[p].Height = 1.0;
        }

        // assign root and shoot water content
        // @TODO: make this a bit more sophisticated, see how it is implemented in main aDGVM
        Plants[p].QRoot = Plants[p].Mr * 8;
        Plants[p].QShoot = Plants[p].Ms * 8;

    }
}


/*
==========
init_herbivore
==========
*/
void init_herbivore(Herbivore& herbivore)
{
    // Constant variables equal for all herbivores: see structs.hpp
    // TODO: how to read in mass and HerbType direct from input file?

// Constant variables equal for all herbivores: see structs.hpp
    // TODO: how to read in mass and HerbType direct from input file?

    herbivore.mass = HERBIVORE_MASS;
    herbivore.HerbType = HERBIVORE_TYPE;
    // @TODO: make xcor and ycor some random number within world bounds (sqrt(area))
    herbivore.xcor = 2.9;
    herbivore.ycor = 95.7;
    herbivore.current_hour = 0;                                         // hour the herbivore is currently foraging in (continuous across days)
    herbivore.last_hour = 0;                                            // hour the herbivore was foraging in last time step (continuous across days)
    herbivore.bite_size = 0;                                            // bite size [g DM/bite]
    herbivore.FV_max = 0;                                               // maximum foraging velocity [m/s]
    herbivore.handling_time = 0;                                        // time to handle (crop and chew) a bite of food [min/bite]
    herbivore.gut_capacity = 0;                                         // maximum gut capacity [kg DM]
    herbivore.gut_content = 0;
    herbivore.MRT = HERBIVORE_MRT;
    //calc_digest_time_leaf(herbivore);                                   // maximum time to digest leaf gut contents [hrs]
    //calc_digest_time_stem(herbivore);                                   // maximum time to digest stem gut contents [hrs]
    herbivore.behaviour = MOVING;                                       // MOVING, EATING, REST
    herbivore.selected_plant_ID = -1;
    herbivore.selected_plant_dist = -1;                                  // distance from herbivore to selected plant [m]
    herbivore.distance_moved = 0;                                       // distance moved in a day [m]
    herbivore.time_spent_foraging = 12;                                 // time spent foraging in a day [hrs]
    herbivore.intake_total_day = 0;                                     // total daily intake [kg DM]
    herbivore.intake_digest_carbohydrate_day = 0;                       // total daily digestible carbohydrate intake [kg DM]
    herbivore.intake_digest_protein_day = 0;                            // total daily digestible protein intake [kg DM]
    herbivore.intake_PE_day = 0;                                        // total daily protein energy intake [kJ]
    herbivore.intake_NPE_day = 0;                                       // total daily non-protein energy intake [kJ]
    herbivore.intake_defence_day = 0;                                   // total daily plant defence intake [kg DM]
    herbivore.intake_total = 0;                                         // total intake over simulation [kg DM]
    herbivore.metabolic_water_day = 0;                                  // total daily metabolic water produced [kg]
    herbivore.intake_water_forage = 0;                                  // total daily water intake from forage [kg]
    herbivore.intake_water_drinking = 0;                                // total daily water intake from drinking [kg]
    herbivore.energy_balance = 0;                                       // energy balance [kJ]
    herbivore.water_balance = 0;                                        // water balance [kg]
    
    // fill vectors with zeros 
    // @TODO: these need to be populated with realistic intake values, not zeros, so herbivore doesn't start with an empty gut!
    for (int i = 0; i < herbivore.MRT; i++)
    {
        herbivore.Digestion_BLeaf.push_back(0);
        herbivore.Digestion_DC_leaf.push_back(0);
        herbivore.Digestion_DP_leaf.push_back(0);  
    }
    for (int i = 0; i < herbivore.MRT; i++)
    {
        herbivore.Digestion_BStem.push_back(0);
        herbivore.Digestion_BDef.push_back(0);
        herbivore.Digestion_DC_stem.push_back(0);
        herbivore.Digestion_DP_stem.push_back(0);
        herbivore.Digestion_DP_def.push_back(0);  
    }

}

/*
==========
init_conditions
==========
*/
void init_conditions(Condition Conditions[])
{
    // Conditions has length = 365 and gives the standing water, mean temperature, and soil N for each day of the year
    // @TODO: presently these parameters are the same for every year, could alter this

    // create a list of input x values for Temp_mean_in
    std::vector<double> x = LinearSpacedArray(0, 2*PI_C, 365);

    for (int i = 0; i < 365; i++)
    {
        Conditions[i].Temp_mean_in = 15 + 10 * sin(x[i]);
        Conditions[i].SW = 0.5;
        Conditions[i].N = 0.5;
    }
}

/*
==========
LinearSpacedArray
==========
*/
std::vector<double> LinearSpacedArray(double a, double b, std::size_t N)
{
    double h = (b - a) / static_cast<double>(N-1);
    std::vector<double> xs(N);
    std::vector<double>::iterator x;
    double val;
    for (x = xs.begin(), val = a; x != xs.end(); ++x, val += h) {
        *x = val;
    }
    return xs;
}