#ifndef INIT_ADGVM_HPP
#define INIT_ADGVM_HPP

#include <random>

/*
==========
init_plants
==========
*/
void init_plants(Plant Plants[]);


/*
==========
init_herbivore
==========
*/
void init_herbivore(Herbivore& herbivore);


/*
==========
init_conditions
==========
*/
void init_conditions(Condition Conditions[]);


/*
==========
LinearSpacedArray
==========
*/
std::vector<double> LinearSpacedArray(double a, double b, std::size_t N);


/*
==========
set_params (overloaded for double and int; added to improve readability)
==========
*/
std::uniform_real_distribution<double>::param_type set_params(double lower,
                                                              double upper);

std::uniform_int_distribution<int>::param_type set_params(int lower,
                                                          int upper);


#endif // INIT_ADGVM_HPP
