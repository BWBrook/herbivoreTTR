#ifndef DAILY_PER_PLOT_HPP
#define DAILY_PER_PLOT_HPP


struct Herbivore;

// Functions returning a double/int/vector calculate values for variables not belonging to the herbivore struct
// Functions returning void calculate values for variables belonging to the herbivore struct

/*
==========
herbivory_run
==========
*/
void herbivory_run(Herbivore& herbivore,
                   Plant Plants[],
                   const int PLOT_SIZE,
                   const int PLANTS_IN_PLOT,
                   const int PLANTS_IN_X,
                   int dayofsim,
                   std::mt19937_64& rnd_num_gen,
                   std::ofstream& ofs_output);
               

/*
==========
calc_gut_capacity
==========
*/
void calc_gut_capacity(Herbivore& herbivore);


/*
==========
calc_gut_content
==========
*/
void calc_gut_content(Herbivore& herbivore);


/*
==========
calc_digest_time_stem
==========
*/
void calc_digest_time_stem(Herbivore& herbivore);


/*
==========
calc_digest_time_leaf
==========
*/
void calc_digest_time_leaf(Herbivore& herbivore);


/*
==========
calc_bite_size
==========
*/
void calc_bite_size(Herbivore& herbivore);


/*
==========
calc_handling_time
==========
*/
void calc_handling_time(Herbivore& herbivore);


/*
==========
calc_foraging_velocity
==========
*/
void calc_foraging_velocity(Herbivore& herbivore);


/*
=========================
calc_required_energy_ratio
=========================
*/
double calc_required_energy_ratio(Herbivore& herbivore);


/*
==========
calc_cost_maintenance
==========
*/
double calc_cost_maintenance(Herbivore& herbivore);


/*
==========
calc_cost_locomotion
==========
*/
double calc_cost_locomotion(Herbivore& herbivore);


/*
==========
calc_plant_density
==========
*/
double calc_plant_density(Herbivore& herbivore,
                          Plant Plants[],
                          const int PLOT_SIZE,
                          const int PLANTS_PER_PLOT,
                          const int PLANTS_IN_X,
                          std::ofstream& ofs_output);


/*
=========================
calc_difference_between_CN_ratios
=========================
*/
double calc_difference_between_CN_ratios(double desired_DP_TO_DC,
                                         Plant& plant);


/*
==========
pick_a_plant
==========
*/
void pick_a_plant(Herbivore& herbivore,
                  Plant Plants[],
                  const int PLOT_SIZE,
                  const int PLANTS_PER_PLOT,
                  const int PLANTS_IN_X,
                  std::mt19937_64& rnd_num_gen,
                  std::ofstream& ofs_output);


/*
========================
get_plants_of_interest
========================
*/
std::vector<int> get_plants_of_interest(Herbivore& herbivore,
                                        const int PLOT_SIZE,
                                        const int PLANTS_PER_PLOT,
                                        const int PLANTS_IN_X,
                                        std::ofstream& ofs_output);


/*
==========
convert_m_to_bucket
==========
*/
int convert_m_to_bucket(double distance,
                        const int PLOT_SIZE,
                        const int PLANTS_IN_X);


/*
==========
get_index
==========
*/
int get_index(double xcor_buckets,
              double ycor_buckets,
              const int PLANTS_IN_X);


/*
==========
get_xy
==========
*/
std::pair<int, int> get_xy(int index,
                           const int PLANTS_IN_X);


/*
==========
calc_herbivore_plant_distance
==========
*/
double calc_herbivore_plant_distance(Herbivore& herbivore,
                                     Plant& plant,
                                     double plot_width,
                                     double plot_height);


/*
========================
get_weighted_probabilities
========================
*/
std::vector<double> get_weighted_probabilities(Herbivore& herbivore,
                                               Plant Plants[],
                                               const int PLOT_SIZE,
                                               std::vector<int> plant_vector,
                                               std::ofstream& ofs_output);

///*
//============
//sortcol
//============
//*/
//bool sortcol(const vector<double>& v1, 
//             const vector<double>& v2 );


/*
==========
herbivore_move
==========
*/
void herbivore_move(Herbivore& herbivore,
                    Plant Plants[],
                    const int PLOT_SIZE,
                    std::mt19937_64& rnd_num_gen,
                    std::ofstream& ofs_output);


/*
==========
eat
==========
*/
void eat(Herbivore& herbivore,
         Plant& plant,
         std::ofstream& ofs_output);

/*
==========
incorporate_energy
==========
*/
void incorporate_energy(Herbivore& herbivore,
                        std::ofstream& ofs_output);


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
                        std::ofstream& ofs_output);


/*
==========
calc_water_requirement
==========
*/
double calc_water_requirement(Herbivore& herbivore);


#endif // DAILY_PER_PLANT_HPP