#include "../inc/constants.hpp"
#include "../inc/structs.hpp"
#include "../inc/enums.hpp"
#include "./init_aDGVM.cpp"
#include "./daily_per_plot.cpp"
#include "./daily_per_plant.cpp"
#include <iostream>
#include <fstream>
#include <cmath>

using namespace std;

int main(int argc, char ** argvals)
{
    // set number of years to run simulation over
    int years = 10;

    // initialise conditions
    Condition* Conditions = new Condition [365];
    init_conditions(Conditions);

    // initialise plants
    Plant* Plants = new Plant [PLANTS_IN_X*PLANTS_IN_Y];
    init_plants(Plants);

    // intialise herbivores
    Herbivore* Herbivores = new Herbivore [HERBIVORES_PER_PLOT];
    for (int i = 0; i < HERBIVORES_PER_PLOT; i++)
    {
        init_herbivore(Herbivores[i]);
    }

    // create our output files
    std::ofstream ofs_plants("./data/output/plants.txt");
    ofs_plants << "Year;Day;Plant;VegType;Height;BLeaf;BStem;BDef;Ms;Ns;Cs;Mr;Cr;Nr\n";
    std::ofstream ofs_herbivores("./data/output/herbivores.txt");
    ofs_herbivores << "Year;Day;HerbType;Mass;xcor;ycor;DailyDistMoved;DailyPEI;DailyNPEI;DailyDMI;DailyForageWater;TotalDMI;WaterBalance;EnergyBalance\n";
    std::ofstream ofs_output("./data/output/screen_output.txt");

    // make our random number generator
    // @TODO: Not really sure how this works in terms of seeding.
    std::time_t init_rnd_num_gen = std::chrono::system_clock::now().time_since_epoch().count();
    std::mt19937_64 rnd_num_gen(init_rnd_num_gen);

//    std::uniform_real_distribution<double> unif_real_dist(0.0, 1.0);    // Returns a real number in [0,1]
//    double rnd_num1 = unif_real_dist(rnd_num_gen);
//   double rnd_num2 = unif_real_dist(rnd_num_gen);
//   double rnd_num3 = unif_real_dist(rnd_num_gen);

    // for every day in the year:
    for (int dayofsim = 0; dayofsim < 365 * years; dayofsim++)
    {
        for (int p = 0; p < PLANTS_PER_PLOT; p++)
        {
            //std::cout << "PLANT " << p << endl;
            transport_resistance(Plants[p], Conditions, PLANTS_PER_PLOT, dayofsim);

        }

        if (HERBIVORY == 1 && std::floor(dayofsim/365) >= SPIN_UP_LENGTH)
        {
            for (int i = 0; i < HERBIVORES_PER_PLOT; i++)
            {
                herbivory_run(Herbivores[i], Plants, PLOT_SIZE, PLANTS_PER_PLOT, PLANTS_IN_X, dayofsim, rnd_num_gen, ofs_output);

                cout << "Distance moved by herbivore today: " << Herbivores[i].distance_moved << " m" << endl;
                cout << "Herbivore energy balance: " << Herbivores[i].energy_balance << " kJ" << endl;
                cout << "Herbivore water balance: " << Herbivores[i].water_balance << " kg" << endl;
            }
        }

        // Write daily output
        //if (year > (SPIN_UP_LENGTH-1))
        //{
        for(int i = 0; i < PLANTS_PER_PLOT; i++)
        {
            ofs_plants << 
            std::floor(dayofsim / 365) << ";" << 
            dayofsim << ";" << 
            i << ";" << 
            Plants[i].VegType << ";" << 
            Plants[i].Height << ";" << 
            Plants[i].BLeaf << ";" << 
            Plants[i].BStem << ";" <<
            Plants[i].BDef << ";" << 
            Plants[i].Ms << ";" << 
            Plants[i].Ns << ";" << 
            Plants[i].Cs << ";" <<
            Plants[i].Mr << ";" <<
            Plants[i].Cr << ";" <<
            Plants[i].Nr << "\n";
        }
        //}

        if (HERBIVORY == 1 && std::floor(dayofsim/365) >= SPIN_UP_LENGTH)
        {
            for (int i = 0; i < HERBIVORES_PER_PLOT; i++)
            {
                ofs_herbivores << 
                std::floor(dayofsim / 365) << ";" << 
                dayofsim << ";" <<
                Herbivores[i].HerbType << ";" << 
                Herbivores[i].mass << ";" << 
                Herbivores[i].xcor << ";" << 
                Herbivores[i].ycor << ";" << 
                Herbivores[i].distance_moved << ";" << 
                Herbivores[i].intake_PE_day << ";" <<
                Herbivores[i].intake_NPE_day << ";" <<
                Herbivores[i].intake_total_day << ";" <<
                Herbivores[i].intake_water_forage << ";" <<
                Herbivores[i].intake_total << ";" << 
                Herbivores[i].water_balance << ";" << 
                Herbivores[i].energy_balance << "\n";
            }
        } 
    }
    
    /*
    ======
    ======
    END
    ======
    ======
    */

    delete [] Plants;
    delete [] Herbivores;
    delete [] Conditions;
 
    ofs_plants.close();
    ofs_herbivores.close();
    ofs_output.close();

    return 0;
}