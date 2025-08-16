
#include "../inc/enums.hpp"
#include "../inc/process_input.hpp"
//#include "../inc/constants.hpp"
#include <cmath>


/*
==========
process_climate_input
==========
*/
void process_climate_input(int clim_in_size,
                           int derived_clim_vars_size,
                           size_t clim_lon_size,
                           size_t clim_lat_size,
                           double** clim_vars)
{
// Modified data
    // This variable is only needed to calculate the atmospheric pressure (atm_press)
    // Units: km -> m
    for(unsigned int i = 0; i < (clim_lat_size * clim_lon_size); i++)
    {
        clim_vars[elevation][i] = clim_vars[elevation][i] * 1000;
    }
    
        // sunp;
        // Units: % -> [0, 1]
    for(unsigned int i = 0; i < (12 * clim_lon_size * clim_lat_size); i++)
    {
        clim_vars[sunp][i] = clim_vars[sunp][i] / 100;
    }
    
// Derived data
    // Allocate memory for all variables that have data for one year
    for(int i = clim_in_size; i < clim_in_size + derived_clim_vars_size - 2; i++)    // Exclude atmospheric pressure, which has the highest int value in the enum
    {
        clim_vars[i] = new double [clim_lon_size * clim_lat_size * 12];
    }
    clim_vars[psy_const] = new double [clim_lon_size * clim_lat_size];    // One value per site
    clim_vars[atm_press] = new double [clim_lon_size * clim_lat_size];    // and the atmosperic pressure, which depends on elevation only (at least in this simulation)
    
    // Assign values
        // tmp_min
        // Units: °C
    for(unsigned int i = 0; i < (12 * clim_lon_size * clim_lat_size); i++)
    {
        clim_vars[temp_min][i] = clim_vars[temp][i] - 0.5 * clim_vars[dtr][i];
    }
    
        // tmp_max
        // Units: °C
    for(unsigned int i = 0; i < (12 * clim_lon_size * clim_lat_size); i++)
    {
        clim_vars[temp_max][i] = clim_vars[temp][i] + 0.5 * clim_vars[dtr][i];
    }
    
        // Ralpha and Rbeta (used to calculate Precipitation)
        // Units: Dimensionless
    for(unsigned int i = 0; i < (12 * clim_lon_size * clim_lat_size); i++)
    {
        if(clim_vars[precip][i] == 0)
        {
            clim_vars[ralpha][i] = 1;
            clim_vars[rbeta][i] = 0;
        }
        else
        {
            clim_vars[ralpha][i] = 1 / pow(clim_vars[precip_cv][i] / 100, 2);                        // CM 20151109 - preCV needs to be divided by 100 for New et al. equations, because it is given in %
            clim_vars[rbeta][i] = (pow(clim_vars[precip_cv][i] / 100, 2) * clim_vars[precip][i]);    // Following New et al. this should be the inverse of what is calculated, but the c++
                                                                                                     // std::gamma_distribution uses a RATE parameter which is the inverse of the SCALE
                                                                                                     // parameter (used in New et al.)
        }
    }
    
        // Mean temperature for each day (daylight)
        // Units: °C
    for(unsigned int i = 0; i < (12 * clim_lon_size * clim_lat_size); i++)
    {
        clim_vars[temp_day][i] = clim_vars[temp][i] + (clim_vars[dtr][i] / 2);    // this from InDataReaderClass l. 89. Not sure this makes sense!!! TODO
    }
    
        // pwet (probability that there is rain on a day?)
        // What happens is: wet_days_per_month / days_per_month
        // Units: [0, 1], dimensionless
    for(unsigned int month = 0; month < 12; month++)
    {
        int time_pos = month * clim_lat_size * clim_lon_size;
        for(unsigned int lat = 0; lat < clim_lat_size; lat++)
        {
            int lat_pos = lat * clim_lon_size;
            for(unsigned int lon = 0; lon < clim_lon_size; lon++)
            {
                clim_vars[pwet][time_pos + lat_pos + lon] = clim_vars[wet_days][time_pos + lat_pos + lon] / DAYS_PER_MONTH[month];
            }
        }
    }
    
        // Same for frost
        // Units: [0, 1], dimensionless
    for(unsigned int month = 0; month < 12; month++)
    {
        int time_pos = month * clim_lat_size * clim_lon_size;
        for(unsigned int lat = 0; lat < clim_lat_size; lat++)
        {
            int lat_pos = lat * clim_lon_size;
            for(unsigned int lon = 0; lon < clim_lon_size; lon++)
            {
                clim_vars[frost_days][time_pos + lat_pos + lon] = clim_vars[frost_days][time_pos + lat_pos + lon] / DAYS_PER_MONTH[month];
            }
        }
    }
    
    // atmospheric pressure
    // calculate altitude-dependent site-specific atmospheric pressure
    // Units: Pascal
    // http://www.fao.org/docrep/X0490E/x0490e07.htm#solar%20radiation equation (7)
    for(unsigned int i = 0; i < (clim_lon_size * clim_lat_size); i++)
    {
        clim_vars[atm_press][i] = 101325 * pow((293.0 - 0.0065 * clim_vars[elevation][i]) / 293.0, 5.26);
    }
    
// Derived data for transpiration?!
    // Mean saturation vapour pressure
    // Units: kPa
    // http://www.fao.org/docrep/X0490E/x0490e07.htm#calculation%20procedures equation (12)
    for(unsigned int i = 0; i < MONTHS_PER_YEAR * clim_lon_size * clim_lat_size; i++)
    {
        clim_vars[avrg_vap_press][i] = 0.6108 * ((exp(17.27 * clim_vars[temp_max][i] / (clim_vars[temp_max][i] + 237.3)) + exp(17.27 * clim_vars[temp_min][i] / (clim_vars[temp_min][i] + 237.3))) / 2);    // Average of Tetens-equation for temp min and temp max; https://en.wikipedia.org/wiki/Tetens_equation
    }
    
    // Aactual vapour pressure
    // Units: kPa
    // http://www.fao.org/docrep/X0490E/x0490e07.htm#calculation%20procedures equation (19)
    for(unsigned int i = 0; i < MONTHS_PER_YEAR * clim_lat_size * clim_lon_size; i++)
    {
        clim_vars[act_vap_press][i] = clim_vars[rel_hum][i] / 100 * clim_vars[avrg_vap_press][i];
    }
    
    // Slope of saturation vapour pressure curve
    // Units: kPa / °C
    // http://www.fao.org/docrep/X0490E/x0490e07.htm#calculation%20procedures equation (13)
    for(unsigned int i = 0; i < clim_lon_size * clim_lat_size * MONTHS_PER_YEAR; i++)
    {
        clim_vars[slope_sat_vap_press_curve][i] = 4098 * 0.6108 * exp((17.27 * clim_vars[temp][i]) / (clim_vars[temp][i] + 237.3)) / pow(clim_vars[temp][i] + 237.3, 2);    // TOOD Why is it kPa / °C and not kPa / °C² ?
    }
    
    // psychochrometric constant
    // Units: kPa / °C
    // http://www.fao.org/docrep/X0490E/x0490e07.htm#solar%20radiation equation (16)
    for(unsigned int i = 0; i < clim_lat_size * clim_lon_size; i++)
    {
        clim_vars[psy_const][i] = (clim_vars[atm_press][i] / 1000) * 0.000665;
    }
    
    // Vapour pressure deficit
    // Units: kPa
    for(unsigned int i = 0; i < MONTHS_PER_YEAR * clim_lat_size * clim_lon_size; i++)
    {
        clim_vars[vap_press_def][i] = clim_vars[avrg_vap_press][i] - clim_vars[act_vap_press][i];
    }
    
    // Air density (dry air)
    // Units: kg / m^3
    // atmosperic pressure:      kg / (m s²)
    // temperature:              °C
    // specific gas constat air: J / (kg K)
    // https://en.wikipedia.org/wiki/Density_of_air
    //      This is the density of dry air, which differs from the density of humid air. But it looks like there is not to much of a difference below 40°C.
    //      https://pdfs.semanticscholar.org/cec4/877708079f2c645c5063508403e2f17163eb.pdf page 1104 (7 in the pdf)
    const double SPECIFIC_GAS_CONSTANT_AIR = 287.058;
    for(unsigned int i = 0; i < MONTHS_PER_YEAR * clim_lat_size * clim_lon_size; i++)
    {
        clim_vars[air_dens][i] = clim_vars[atm_press][i % (clim_lat_size * clim_lon_size)] / (SPECIFIC_GAS_CONSTANT_AIR * (1.01 * (clim_vars[temp][i] + 273.15)));    // TODO Where does the 1.01 come from? fao.org?
    }
    
    // Photosynthetically active radiation
    // Units: μmol / (m² day)
        // http://www.fao.org/docrep/X0490E/x0490e07.htm#solar%20radiation              equation
    int midmonthday;
    double Ra;        // extraterrestrial radiation [MJ / (m² day)]                       (21)
    double phi;       // latitude in radians converted from latitude in degrees           (22)
    double dr;        // correction for eccentricity of Earth’s orbit around the sun      (23)
    double delta;     // declination of the sun above the celestial equator in radians    (24)
    double omega;     // sunrise hour angle in radians                                    (25)
    double hrs;       // daylight hours                                                   (34)
    double Rs;        // Solar or shortwave radiation [MJ / (m² day)]                     (35)
    double sunhrs;    // 
    double par;       // μmol / (m² day)
    
    for(int month = 0; month < MONTHS_PER_YEAR; month++)
    {
        midmonthday = (month + 1) * 30.42 - 15;
        dr = 1.0 + 0.033 * cos(midmonthday * 2 * M_PI / 365.0);
        delta = 0.409 * sin(midmonthday * 2 * M_PI / 365.0 - 1.39);
        
        for(unsigned int lat = 0; lat < clim_lat_size; lat++)
        {
            phi = clim_vars[clim_lat][lat] * M_PI / 180;
            omega = acos(-tan(phi) * tan(delta));
            Ra = (24.0 * 60.0 / M_PI) * GSC * dr * (omega * sin(phi) * sin(delta) + cos(phi) * cos(delta) * sin(omega));
            hrs = omega * 24.0 / M_PI;
            
            for(unsigned int lon = 0; lon < clim_lon_size; lon++)
            {
                sunhrs = clim_vars[sunp][month * clim_lat_size * clim_lon_size + lat * clim_lon_size + lon] * hrs;
                Rs = (ANGSTRONG_A + ANGSTRONG_B * sunhrs/ hrs) * Ra;
                par = 5 * Rs * 1e6 / (sunhrs * 3600);
                // http://www.skyeinstruments.com/wp-content/uploads/LightGuidanceNotes.pdf
                // This reference claims the conversion factor from W / m² to umol / (m² s) to be 4.6 and not 5 (for daylight). See Appendix 3.
                
                // https://academic.oup.com/jxb/article/54/384/879/631226
                // Here is a actual reference that claims the tansformation factor to be 4.6 for visible light. Just search for 4.6 to find it.
                // Actually it transforms J to micro moles.
                // W = J / s.
                // (5 umol / J) * (W / m²) = (5 umol / J) * (J / (m² s)) = 5 umol / (m² s)
                
                // https://link.springer.com/article/10.1007/s00704-010-0368-6
                // A reference for the transformation from J (solar radiation, not only visible light) to μmol.
                clim_vars[photosyn_act_rad][month * clim_lat_size * clim_lon_size + lat * clim_lon_size + lon] = par;
            }
        }
    }
}



/*
==========
process_soil_input
==========
*/
void process_soil_input(size_t soil_lon_size,
                        size_t soil_lat_size,
                        double** soil_vars)
{
    // top layer or layer 0 = soil_vars[sat_hyd_cond][0 * soil_lat_size * soil_lon_size + lat * soil_lon_size + lon] = soil_vars[sat_hyd_cond][lat * soil_lon_size + lon]
    // sub layer or layer 1 = soil_vars[sat_hyd_cond][1* soil_lat_size * soil_lon_size + lat * soil_lon_size + lon] = soil_vars[sat_hyd_cond][soil_lat_size * soil_lon_size + lat * soil_lon_size + lon]

    //// Field capacity (initialises soil.water_content)
    //    // Adjust available data to be in [0, 1]
    //for(unsigned int i = 0; i < 2 * soil_lon_size * soil_lat_size; i++)
    //{
    //    if(soil_vars[field_cap][i] != DMISSING)
    //    {
    //        soil_vars[field_cap][i] = soil_vars[field_cap][i] / 100;
    //    }
    //}
    //
    //// Saturated soil water content
    //    // Adjust the available data to be in [0, 1]
    //for(unsigned int i = 0; i < 2 * soil_lon_size * soil_lat_size; i++)
    //{
    //    if(soil_vars[sat_H2O_cont][i] != DMISSING)
    //    {
    //        soil_vars[sat_H2O_cont][i] = soil_vars[sat_H2O_cont][i] / 100;
    //    }
    //}
}
