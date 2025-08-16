#ifndef CONSTANTS_HPP
#define CONSTANTS_HPP


const int MONTHS_PER_YEAR = 12;
const int DAYS_PER_MONTH[12] = {31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31};
const int PLANTS_IN_X = 10;
const int PLANTS_IN_Y = 10;
const int PLANTS_PER_PLOT = PLANTS_IN_X * PLANTS_IN_Y;
const int NBR_RADIUS = 1;
const int COMPETING_NEIGHBOURS = 4 * (NBR_RADIUS * NBR_RADIUS + NBR_RADIUS);

const double PLOT_SIZE = 100 * 100;                                    // in m^2, required for z* calculations
const double IND_AREA_MULT = PLOT_SIZE / (double(PLANTS_PER_PLOT));    // in m^2, subgrid area available per individual based on current max. canopy_area_0 of grasses



// If there is no data available, it is substituted with double -9999, or int -9999
const double DMISSING = -9999;
const int IMISSING = -9999;

// -------------------------------------------------------------------------------
// --- PLANT TRAITS --------------------------------------------------
// -------------------------------------------------------------------------------

const int C3 = 0;
const int C4 = 1;
const double C4_THRESHOLD = 0.5;    // at which value of "C3C4" do we assume that plants are C4

const int N_PHEN = 16;
const int PHEN_MAX_POS = 15;

// TODO JL: Rename the following two constants?
const double EVERGREEN_THR = 0.5;     // at which value of "deciduous" do we assume that plant is evergreen?
const double RAIN_LIGHT_THR = 0.5;    // at which value of "phenology" do we assume that plants are summer green?

const int VTYPE_NUM = 3;            // Tree, C4-Grass, C3-Grass

const double PLANT_SIZE_MULT[VTYPE_NUM] = {1.0, 0.13*0.13/IND_AREA_MULT, 0.13*0.13/IND_AREA_MULT}; // plants per bucket multiplier. 1 tree per bucket but based on max canopy area of grasses of 0.13x0.13 m2 we can calculate how may grasses

// Trees only
const double TOPKILL_CONST = 1.48;      // updated topkill constants (Higgins et al. 2012) using more data
const double TOPKILL_H     = 3.306985;  // updated topkill constants (Higgins et al. 2012) using more data
const double TOPKILL_I     = 0.026185;  // updated topkill constants (Higgins et al. 2012) using more data
const double LEAF_HEIGHT   = 0.66;      // proportion of total height where leaves start on tree (random guess, maybe need to parameterise this better?)

// Photosynthetically active radiation
const double ANGSTRONG_A = 0.25;    // constant defining prop of extrat. radiation reaching earth on overcast days
const double ANGSTRONG_B = 0.50;    // constant defining the additional prop of extrat. radiation reaching earth on clear days
const double GSC = 0.082;           // solar constant - extraterrestrial solar radiation MJ/m2/minute

//
const double ALBEDO = 0.23;          // canopy reflection coefficient estimate for a grass reference crop (dimensionless)
const double SBC = 4.903e-09;        // stephan bolzman constant MJ.k^-4.day^-1  
const double GRAVITY_EARTH = 9.8;    // m/s^2

//
const double SP_HEAT = 1.013e-3;    // MJ/kg/degC = kJ/g/degC from FOA specific heat of moist air
const double LAMBDA = 2.45;         // MJ/kg from FOA latent heat of air at 20degC

// Thornley Transport Resistance parameters (as in Thornley 1998)
// (note that XDM = structural dry matter, which is produced by growth and lost to litter)
const double K_LITTER = 0.05;      // Litter production parameter, k_lit (0.05) (proportion/day)                   
const double K_M_LITTER = 2.5;     // Litter production from dry mass, K_M_lit (0.5) (kg XDM)                           
const double G_SHOOT = 200;        // Growth rate parameter for shoot, k_G (200) ([kg C/kg N/kg XDM^-2]/day)      
const double G_ROOT = 200;         // Growth rate parameter for root, k_G, (200) ([kg C/kg N/kg XDM^-2]/day)
const double G_DEFENCE = 10;       // Growth rate parameter for physical defences ([kg C/kg N/kg XDM^-2]/day)
//const double G_DEFENCE_C = 10;     // Growth rate parameter for chemical defences ([kg C/kg N/kg XDM^-2]/day)
const double K_C = 0.1;            // Typical rate of input of C, k_C (0.1 or 0.15) ([kg C/kg shoot XDM]/day)
const double K_N = 0.01;           // Typical rate of input of N, k_N (0.01 or 0.02) ([kg N/kg shoot XDM]/day)   
const double K_M = 10;             // Makes N uptake asymptotic with mass, K_M (1.0) (kg XDM)              
const double PI_C = 0.1;           // Provides product inhibition of photosynthesis (0.1 or 0.05)  (kg C/kg XDM)  
const double PI_N = 0.01;          // Provides product inhibition of N uptake (0.01 or 0.0025) (kg N/kg XDM)     
const double Q_SCP = 2/3;          // Scaling parameter, q (1) (no units)
const double TR_C = 1.0;           // Transport resistance for C, rho_C (1) (kg XDM^(Q_SCP-1)/day)                
const double TR_N = 1.0;           // Transport resistance for N, rho_N (1) (kg XDM^(Q_SCP-1)/day)                
const double FRACTION_C = 0.5;     // Fraction of C in dry matter (XDM), f_C (0.5) (kg C/kg XDM)
const double FRACTION_N = 0.025;   // Fraction of N in dry matter (XDM), f_N (0.015 or 0.025) (kg N/kg XDM)
//const double FRACTION_C_TD = 0.38; // Fraction of C in chemical terpenoid defences (kg C/kg XDM) (based on isoprene)
//const double FRACTION_N_TD = 0;    // Fraction of N in chemical terpenoid defences (kg N/kg XDM) (based on isoprene)
//const double FRACTION_C_AD = 0.33; // Fraction of C in chemical alkaloid defences (kg C/kg XDM) (based on tropane but very variable)
//const double FRACTION_N_AD = 0.04; // Fraction of N in chemical alkaloid defences (kg N/kg XDM) (based on tropane but very variable)
const double PHENO_SWITCH = 10;    // Temperature threshold below which leaf loss is accelerated (degrees)
const double ACCEL_LEAF_LOSS = 10; // Accelerated rate of leaf loss if phenology switch activated  (10 x the base rate is sufficient to draw leaf biomass down close to zero )
const double INIT_SW = 500;        // Initial standing water? (L)
const double INIT_N = 3.75;        // Initial N? Is this N availability? (kg DM)

// Temperature envelope for growth: 
const int TEMP_GROWTH_1 = 1;
const int TEMP_GROWTH_2 = 24;  
const int TEMP_GROWTH_3 = 26; 
const int TEMP_GROWTH_4 = 40;

// Temperature envelope for photosynthesis:
const int TEMP_PHOTO_1 = 1;
const int TEMP_PHOTO_2 = 15;
const int TEMP_PHOTO_3 = 25;
const int TEMP_PHOTO_4 = 35;

// -------------------------------------------------------------------------------
// --- HERBIVORE TRAITS ----------------------------------------------------------
// -------------------------------------------------------------------------------
// Main
const int SPIN_UP_LENGTH = 5;               // number of years to run vegetation model before herbivory switches on
const int HERBIVORY = 1;                    // [0 = off, 1 = on] herbivory switch value
const int HERBIVORES_PER_PLOT = 1;           // number of herbivores in a plot
const int HERBIVORE_MASS = 2180;            // average white rhino (Steuer et al. 2010) [kg]
const int HERBIVORE_TYPE = 0;               // [0 = grazer, 1 = browser, 2 = mixed feeder]
const int BROWSE_HEIGHT = 2;                // [m] maximum height at which the herbivore can browse (not utilised for grazers)

// Physiological scaling relationships
const double BITE_SIZE_A = 0.096;           // Shipley et al. (1994)
const double BITE_SIZE_B = 0.72;            // Shipley et al. (1994)
const double FORAGE_VEL_A = 0.73;           // Shipley et al. (1996)
const double FORAGE_VEL_B = 0.04;           // Shipley et al. (1996)
const double HANDLING_TIME_A = 1.65;        // Jeschke & Tollrian (2005)
const double HANDLING_TIME_B = -0.766;      // Jeschke & Tollrian (2005)
//const double FORAGE_TIME_A = 24.2;        // Owen-Smith (1988)
//const double FORAGE_TIME_B = 0.12;        // Owen-Smith (1988)
const double GUT_CAPACITY_A = 0.030;        // Muller et al. (2013) - all herbivores >10kg, see Table 6
const double GUT_CAPACITY_B = 0.924;        // Muller et al. (2013) - all herbivores >10kg, see Table 6
//const double STEM_MEAN_RETENTION_TIME_A = 46.1;  // Foose (1982) (grass hay - low quality, high cellulose - all species)
//const double STEM_MEAN_RETENTION_TIME_B = 0.048; // Foose (1982) (grass hay - low quality, high cellulose - all species)
//const double LEAF_MEAN_RETENTION_TIME_A = 36.6;  // Foose (1982) (alfalfa hay - high quality - all species)
//const double LEAF_MEAN_RETENTION_TIME_B = 0.061; // Foose (1982) (alfalfa hay - high quality - all species)
const double ENERGY_MAINTENANCE_A = 293;    // Kleiber (1961)
const double ENERGY_MAINTENANCE_B = 0.75;   // Kleiber (1961)
const double ICL_A = 10678;                 // Taylor (1980)
const double ICL_B = 0.70;                  // Taylor (1980)

// Digestion-related
const double PROP_NSC_LEAF = 0.2;       // proportion non-structural carbohydrates in leaves (based roughly on Hoch et al. 2003)
const double PROP_NSC_STEM = 0.05;      // proportion non-structural carbohydrates in stem (based roughly on Hoch et al. 2003)
const double N_TO_PROTEIN = 6.25;       // Felton et al. (2017)      
const double PROTEIN_TO_ENERGY = 16.7;  // Felton et al. (2017) [kJ/g]
const double CARB_TO_ENERGY = 16.7;     // Felton et al. (2017) [kJ/g]
const double PROP_DIGEST_TP = 0.5;      // proportion of total protein that is digested (Navas-Camacho et al. (1993))
const double PROP_DIGEST_SC = 0.63;     // proportion of structural carbohydrates that are digested (Tilley et al. (1969) for ruminants and grasses (would be nice to get this for woody vegetation))
const double NPE_to_PE_TARGET = 4.55;   // number of non-protein energy (NPE) units needed per protein energy (PE) unit. Based on an PE:NPE target of 0.22, as for adult moose in Felton et al. (2016) 
const double PROTEIN_TO_MW = 0.42;      // [g] metabolic water produced from digesting [g] protein (from Giger-Reverdin & Gihad 1991)
const double CARB_TO_MW = 0.62;         // [g] metabolic water produced from digesting [g] carbohydrate (from Giger-Reverdin & Gihad 1991)
const double FAT_TO_MW = 1.1;           // [g] metabolic water produced from digesting [g] fat (from Giger-Reverdin & Gihad 1991)
const int HERBIVORE_MRT = 28;           // [h] mean retention time (based on MRTfluid for white rhino from Steuer et al. 2010)

// Further
const double WATER_TURNOVER = 0.061;    // water turnover [L/kg body mass/24 hrs] for camels, taken from McFarlane (1965). (cattle = 0.148, sheep = 0.110, camels = 0.061, red kangaroo = 0.088)
const double EAT_RADIUS = 1.0;          // distance at which a herbivore can commence eating a plant
const double MIN_SHOOT = 0.000001;      // minimum shoot biomass [kg] at which herbivore will cease to eat
const double DETECTION_DISTANCE = 10;   // maximum distance at which a herbivore can detect plants [m]
const double DIST_TO_WATER = 50 * 10^6; // average distance to a water point (m)


#endif // CONSTANTS_HPP
