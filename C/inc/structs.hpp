#ifndef STRUCTS_HPP
#define STRUCTS_HPP
#include <iostream>
#include <vector>

using namespace std;


//#include "constants.hpp"

struct Herbivore
{
   
// Traits
    double mass;                                    // [kg]
    int HerbType;                                   // GRAZER, BROWSER, MIXED
    double xcor;                                    // x-coordinate
    double ycor;                                    // y-coordinate
    int current_hour;                               // hour the herbivore is currently foraging in (continuous across days)
    int last_hour;                                  // hour the herbivore was foraging in last time step (continuous across days)
    double bite_size;                               // bite size [g DM/bite]
    double FV_max;                                  // maximum foraging velocity [m/s]
    double handling_time;                           // time to handle (crop and chew) a unit of food [min/g DM]
    double gut_capacity;                            // maximum gut capacity [kg DM]
    double gut_content;
    int MRT;                                        // mean time to digest food in gut [hrs]
    //double digest_time_leaf;                        // mean time to digest leaves in gut [hrs]
    //double digest_time_stem;                        // mean time to digest stem in guts [hrs]
    int behaviour;                                  // MOVING, EATING, REST
    int selected_plant_ID;
    double selected_plant_dist;                     // distance from herbivore to selected plant [m]
    double distance_moved;                          // distance moved in a day [m]
    double time_spent_foraging;                     // time spent foraging in a day [hrs]
    double intake_total_day;                        // total daily intake [kg DM]
    double intake_digest_carbohydrate_day;          // total daily digestible carbohydrate intake [kg DM]
    double intake_digest_protein_day;               // total daily digestible protein intake [kg DM]
    double intake_PE_day;                           // total daily protein energy intake [kJ]
    double intake_NPE_day;                          // total daily non-protein energy intake [kJ]
    double intake_defence_day;                      // total daily plant defence intake [kg DM]
    double intake_total;                            // total intake over simulation [kg DM]
    double metabolic_water_day;                     // total daily metabolic water produced [kg]
    double intake_water_forage;                     // total daily water intake from forage [kg]
    double intake_water_drinking;                   // total daily water intake from drinking [kg]
    double energy_balance;                          // energy balance [kJ]
    double water_balance;                           // water balance [kg]
    std::vector<double> Digestion_BLeaf;            // vector to track digestion of leaf biomass
    std::vector<double> Digestion_BStem;            // vector to track digestion of stem biomass
    std::vector<double> Digestion_BDef;             // vector to track digestion of defence biomass
    std::vector<double> Digestion_DC_leaf;          // vector to track digestion of digestible carbohydrates in leaf biomass
    std::vector<double> Digestion_DC_stem;          // vector to track digestion of digestible carbohydrates in stem biomass
    std::vector<double> Digestion_DP_leaf;          // vector to track digestion of digestible proteins in leaf biomass
    std::vector<double> Digestion_DP_stem;          // vector to track digestion of digestible proteins in stem biomass
    std::vector<double> Digestion_DP_def;           // vector to track digestion of digestible proteins in defence biomass

};

struct Plant
{

    // Traits
    double xcor;           // x-coordinate
    double ycor;           // y-coordinate
    int VegType;           // type of vegetation (0, 1, 2 - C3 grass, C4 grass, tree)
    double Ms;             // shoot biomass [kg dry mass]
    double Mr;             // root biomass [kg dry mass]
    double Md;             // defence biomass [kg dry mass]
    double Ns;             // shoot N content [kg]
    double Nr;             // root N content [kg]
    double Nd;             // defence N content [kg]
    double Cs;             // shoot C content [kg]
    double Cr;             // root C content [kg]
    double Cd;             // defence C content [kg]
    double BLeaf;          // leaf biomass [kg dry mass]
    double BStem;          // stem biomass [kg dry mass]
    double BRoot;          // root biomasss [kg dry mass]
    double BRepr;          // reproductive biomass [kg dry mass]
    double BDef;           // defence biomass [kg dry mass]
    double QShoot;         // shoot water content [kg]
    double QRoot;          // root water content [kg]
    double Height;         // plant height [m]
    double Gs;             // shoot growth
    double Gr;             // root growth
    double Gd;             // defence growth
    double UC;             // input rate of C (from photosynthesis via leaves)
    double UN;             // input rate of N (from root uptake)
    double RsC;            // differential equation for the transport flux of substrate C in shoot
    double RrC;            // differential equation for the transport flux of substrate C in root
    double RdC;            // differential equation for the transport flux of substrate C in defence
    double RsN;            // differential equation for the transport flux of substrate N in shoot
    double RrN;            // differential equation for the transport flux of substrate N in root
    double RdN;            // differential equation for the transport flux of substrate N in defence
    double tauC;           // transport rate of C from shoot to root
    double tauN;           // transport rate of N from root to shoot
    double tauCd;          // transport rate of C from shoot to defence
    double tauNd;          // transport rate of N from root to defence
};

struct Condition
{
    double SW;           // standing water on this day [L]
    double Temp_mean_in; // temperature on this day [C]
    double N;            // N available in soil on this day [kg]
};

#endif // STRUCTS_HPP