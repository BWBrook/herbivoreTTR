# Simulation and model constants
CONSTANTS <- list(

  # Herbivore constants
  GUT_CAPACITY_A = 0.03,       # g : Muller et al. (2013) - all herbivores >10kg, see Table 6
  GUT_CAPACITY_B = 0.924,      # Muller et al. (2013) - all herbivores >10kg, see Table 6
  BITE_SIZE_A = 0.096,         # g : Shipley et al. (1994)
  BITE_SIZE_B = 0.72,          # Shipley et al. (1994)
  HANDLING_TIME_A = 1.65,      # Jeschke & Tollrian (2005)
  HANDLING_TIME_B = -0.766,    # Jeschke & Tollrian (2005)
  FORAGE_VEL_A = 0.73,         # Shipley et al. (1996)
  FORAGE_VEL_B = 0.04,         # Shipley et al. (1996)
  ENERGY_MAINTENANCE_A = 293,  # Kleiber (1961)
  ENERGY_MAINTENANCE_B = 0.75, # Kleiber (1961)
  ICL_A = 10678,               # Taylor (1980)
  ICL_B = 0.7,                 # Taylor (1980)
  WATER_TURNOVER = 0.061,      # water turnover [L/kg body mass/24 hrs] for camels, taken from McFarlane (1965). (cattle = 0.148, sheep = 0.110, camels = 0.061, red kangaroo = 0.088)
  DIST_TO_WATER = 5e4,         # average distance to a water point: very likely meant 50000 mm = 50 m

  # Conversion constants
  CARB_TO_ENERGY = 16.7,    # kJ/g :  Felton et al. (2017)
  PROTEIN_TO_ENERGY = 23.0, # kJ/g from Felton :  Felton et al. (2017)
  CARB_TO_MW = 0.62,        # g water/g carbohydrate : metabolic water produced from digesting [g] carbohydrate (from Giger-Reverdin & Gihad 1991)
  PROTEIN_TO_MW = 0.42,     # g water/g protein :  metabolic water produced from digesting [g] protein (from Giger-Reverdin & Gihad 1991)
  PROP_DIGEST_SC = 0.63,    # proportion of structural carbohydrates that are digested (Tilley et al. (1969) for ruminants and grasses (would be nice to get this for woody vegetation))
  PROP_DIGEST_TP = 0.5,     # proportion of total protein that is digested (Navas-Camacho et al. (1993))
  N_TO_PROTEIN = 6.25,      # Felton et al. (2017)

  # Simulation setup
  MIN_SHOOT = 1e-3,         # kg DM, minimum shoot biomass [kg] at which herbivore will cease to eat (1e3 = 1g)
  LEAF_HEIGHT = 1.0,        # height factor for browsing calculation
  BROWSE_HEIGHT = 2.0,      # [m] maximum height at which the herbivore can browse (not utilised for grazers)
  DETECTION_DISTANCE = 10,  # maximum distance at which a herbivore can detect plants [m]
  EAT_RADIUS = 1.0,         # distance at which a herbivore can commence eating a plant [m]
  NPE_TO_PE_TARGET = 4.55,  # ratio non-protein energy to protein energy
  PLANT_DENSITY = 0.25,     # local availability of plants in the area
  DP_TO_DC_TARGET = 0.2,    # digestible protein to digestible carbohydrate target
  TEMP_WATER_SCALING = 0.1, # scaling water requirements based on temperature
  
  # Plot settings
  PLANTS_IN_X = 60,
  PLANTS_IN_Y = 60,
  PLANTS_PER_PLOT = NA_integer_,               # set after list construction to avoid self-reference
  PLOT_SIZE = 10000,                           # m^2 = 1 ha
  PLANT_INITIAL_MASS_MIN = 1,                  # kg DM
  PLANT_INITIAL_MASS_MAX = 100,                # kg DM
  HERBIVORES_PER_PLOT = 1,                     # number of herbivores in a plot
  
  # Time settings
  SPIN_UP_LENGTH = 5, # number of years to run vegetation model before herbivory switches on
  HERBIVORE_MRT = 28, # mean gut retention time in hours

  # OTHER SETTINGS
  TOLERANCE = 0.0001 # calculation buffer
)

# set derived constants after list construction (avoid self-reference during list eval)
CONSTANTS$PLANTS_PER_PLOT <- CONSTANTS$PLANTS_IN_X * CONSTANTS$PLANTS_IN_Y
