#include "../inc/enums.hpp"
#include "../inc/daily_per_plant.hpp"
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
THORNLEY TRANSPORT RESISTANCE MODEL
==========
==========
*/

/*
==========
transport_resistance
==========
*/
void transport_resistance(Plant& plant, 
                          Condition Conditions[],
                          const int PLANTS_PER_PLOT,
                          int dayofsim)
{
    // calculate the day of the year:
    int day = dayofsim - (365 * std::floor(dayofsim / 365));
    //std::cout << "Day of the year = " << day << endl;

    // SW (water) uptake forcing:
    double SW_forced = calc_SWforcer(Conditions[day].SW, 0.15, 0.6);
    //std::cout << "SW_forced: " << SW_forced << endl;

    // Photosynthesis forcing:
    // double An_forced = 1 - trap1(CN.I, CN.A1, CN.A2); // nitrogen limited photosynthesis
    double At_forced = trap2(Conditions[day].Temp_mean_in, TEMP_PHOTO_1, TEMP_PHOTO_2, TEMP_PHOTO_3, TEMP_PHOTO_4); // temperature limited photosynthesis  

    // Temperature vs water forcing for C uptake:
    double K_C_forced = K_C * std::min(SW_forced, At_forced);

    // Growth forcing (temperature and water):
    double g_forced_shoot = G_SHOOT * std::min(trap2(Conditions[day].Temp_mean_in, TEMP_GROWTH_1, TEMP_GROWTH_2, TEMP_GROWTH_3, TEMP_GROWTH_4), SW_forced);
    double g_forced_root = G_ROOT * std::min(trap2(Conditions[day].Temp_mean_in, TEMP_GROWTH_1, TEMP_GROWTH_2, TEMP_GROWTH_3, TEMP_GROWTH_4), SW_forced);
    double g_forced_defence = G_DEFENCE * std::min(trap2(Conditions[day].Temp_mean_in, TEMP_GROWTH_1, TEMP_GROWTH_2, TEMP_GROWTH_3, TEMP_GROWTH_4), SW_forced);
    //std::cout << "g_forced_shoot: " << g_forced_shoot << endl;
    //std::cout << "g_forced_root: " << g_forced_root << endl;
    //std::cout << "g_forced_defence: " << g_forced_defence << endl;

    // Nitrogen forcing:
    double K_N_forced = monod(Conditions[day].N, 0.1) * K_N; // nitrogen uptake forcing (limited by nitrogen availability)

    // TTR parameters:
    plant.RsC = calc_RsC(TR_C, plant.Ms, Q_SCP); // differential eq. for the transport flux of substrate C in shoot
    plant.RrC = calc_RrC(TR_C, plant.Mr, Q_SCP); // differential eq. for the transport flux of substrate C in root
    //plant.RdC = calc_RdC(TR_C, plant.Md, Q_SCP); // differential eq. for the transport flux of substrate C in defence
    plant.RsN = calc_RsN(TR_N, plant.Ms, Q_SCP); // differential eq. for the transport flux of substrate N in shoot
    plant.RrN = calc_RrN(TR_N, plant.Mr, Q_SCP); // differential eq. for the transport flux of substrate N in root
    //plant.RdN = calc_RdN(TR_N, plant.Md, Q_SCP); // differential eq. for the transport flux of substrate N in defence
    plant.tauC = calc_tauC(plant); // transport rate of C from shoot to root
    plant.tauN = calc_tauN(plant); // transport rate of N from root to shoot
    //plant.tauCd = calc_tauCd(plant); // transport rate of C from shoot to defence
    //plant.tauNd = calc_tauNd(plant); // transport rate of N from root to defence
    //std::cout << "RsC: " << plant.RsC << endl;
    //std::cout << "RrC: " << plant.RrC << endl;
    //std::cout << "RdC: " << plant.RdC << endl;
    //std::cout << "RsN: " << plant.RsN << endl;
    //std::cout << "RrN: " << plant.RrN << endl;
    //std::cout << "RdN: " << plant.RdN << endl;
    //std::cout << "tauC: " << plant.tauC << endl;
    //std::cout << "tauN: " << plant.tauN << endl;
    //std::cout << "tauCd: " << plant.tauCd << endl;
    //std::cout << "tauNd: " << plant.tauNd << endl;
  
    double CLeaf = plant.Cs * plant.BLeaf/(plant.BStem + plant.BLeaf); // C content of leaf biomass
    plant.UC = calc_UC(plant, CLeaf, K_C_forced, K_M, PI_C); // input rate of C (from photosynthesis via leaves)
    //plant.UC = F_UC(plant.Ms, plant.Cs, K_C_forced, K_M, PI_C); // input rate of C (from photosynthesis via shoot)
    plant.UN = calc_UN(plant, K_N_forced, K_M, PI_N); // input rate of N (from root uptake)
    //std::cout << "UC: " << plant.UC << endl;
    //std::cout << "UN: " << plant.UN << endl;

    // Growth of shoot, root, and plant defence biomass
    plant.Gs = calc_Gs(plant, g_forced_shoot);    // growth of shoot
    plant.Gr = calc_Gr(plant, g_forced_root);     // growth of root
    //plant.Gd = calc_Gd(plant, g_forced_defence); // growth of defence
    //std::cout << "Gs: " << plant.Gs << endl;
    //std::cout << "Gr: " << plant.Gr << endl;
    //std::cout << "Gd: " << plant.Gd << endl;
    
    // Loss of root, stem, leaf, and defence biomass
    double loss_root = K_LITTER;
    //double loss_shoot = K_LITTER;
    double loss_leaf = K_LITTER * ACCEL_LEAF_LOSS;
    if (Conditions[day].Temp_mean_in > PHENO_SWITCH)
    {
        loss_leaf = K_LITTER;
    }
    double loss_stem = K_LITTER * 0.02;
    double loss_defence  = loss_leaf; // assuming defence loss is proportional to leaf loss
    double Mr_loss = (loss_root * plant.Mr) / (1 + K_M_LITTER / plant.Mr); // root loss is standard TTR loss
    //double Ms_loss = (loss_shoot * plant.Ms) / (1 + K_M_LITTER / plant.Ms); // shoot loss is standard TTR loss
    double MLeaf_loss = (loss_leaf * plant.BLeaf) / (1 + K_M_LITTER / plant.BLeaf); // leaf loss is standard TTR loss
    double MStem_loss = (loss_stem * plant.BStem) / (1 + K_M_LITTER / plant.BStem); // stem loss is standard TTR loss
    double MDef_loss = (loss_defence * plant.BDef) / (1 + K_M_LITTER / plant.BDef); // defence loss is standard TTR loss
    //std::cout << "loss_root: " << loss_root << endl;
    //std::cout << "loss_leaf: " << loss_leaf << endl;
    //std::cout << "loss_stem: " << loss_stem << endl;
    //std::cout << "loss_defence: " << loss_defence << endl;
    //std::cout << "Mr_loss: " << Mr_loss << endl;
    //std::cout << "MLeaf_loss: " << MLeaf_loss << endl;
    //std::cout << "MStem_loss: " << MStem_loss << endl;
    //std::cout << "Md_loss: " << Md_loss << endl;

    // Update state variables
    plant.Ms = plant.Ms + plant.Gs - MLeaf_loss - MStem_loss;
    plant.Mr = plant.Mr + plant.Gr - Mr_loss;
    //plant.Md = plant.Md + plant.Gd - Md_loss;
    plant.Cs = plant.Cs + calc_dCs_dt(plant, FRACTION_C);
    plant.Cr = plant.Cr + calc_dCr_dt(plant, FRACTION_C);
    //plant.Cd = plant.Cd + calc_dCd_dt(plant, FRACTION_C);
    plant.Ns = plant.Ns + calc_dNs_dt(plant, FRACTION_N);
    plant.Nr = plant.Nr + calc_dNr_dt(plant, FRACTION_N);
    //plant.Nd = plant.Nd + calc_dNd_dt(plant, FRACTION_N);
    //std::cout << "Ms: " << plant.Ms << endl;
    //std::cout << "Mr: " << plant.Mr << endl;
    //std::cout << "Md: " << plant.Md << endl;
    //std::cout << "Cs: " << plant.Cs << endl;
    //std::cout << "Cr: " << plant.Cr << endl;
    //std::cout << "Cd: " << plant.Cd << endl;
    //std::cout << "Ns: " << plant.Ns << endl;
    //std::cout << "Nr: " << plant.Nr << endl;
    //std::cout << "Nd: " << plant.Nd << endl;

    double prop_to_repr = trap1(plant.Ms, 0.5, 10) * 0.01; // plants need to be above certain size to allocate to reproduction
    //std::cout << "prop_to_repr: " << prop_to_repr << endl;

    // if the plant is a shrub, update proportion dedicated to stem
    double prop_to_stem = 0.0;
    if (plant.VegType == 2) {
        double LAI_index = plant.BLeaf/plant.BStem; // as leaf to stem ratio increases so will LAI
        prop_to_stem = 1 * trap1(LAI_index, 0.25, 5.0) * (1.0 - prop_to_repr); // the trap1 parameters would have to be tuned for LAI in aDGVM
    } // if the plant is a grass, keep proportion dedicated to stem as 0
    //std::cout << "prop_to_stem: " << prop_to_stem << endl;

    plant.BLeaf += (1.0 - prop_to_stem) * plant.Gs - MLeaf_loss;
    plant.BStem += prop_to_stem * plant.Gs - MStem_loss;
    double prop_to_def = 0.0001; // @TODO: work out what might be realistic here
    plant.BDef  += prop_to_def * plant.Gs - MDef_loss;
    plant.BRepr = 0 * plant.BRepr + prop_to_repr * plant.Gs; // 0 * means that we assume reproduction occurs continuously and does not accumulate
    plant.Ms = plant.BLeaf + plant.BStem + plant.BDef; // accounting for loss to reproduction
    plant.BRoot = plant.Mr;
    //std::cout << "BLeaf: " << plant.BLeaf << endl;
    //std::cout << "BStem: " << plant.BStem << endl;
    //std::cout << "BRepr: " << plant.BRepr << endl;
    //std::cout << "Ms (after accounting for loss to reproduction): " << plant.Ms << endl;
    //std::cout << "BDef: " << plant.BDef << endl;
    //std::cout << "BRoot: " << plant.BRoot << endl;
}


/*
==========
calc_SWforcer
==========
*/
double calc_SWforcer(double SW,
                     double SWw,
                     double SWstar)
{
    return(trap1(SW, SWw, SWstar));
}


/*
==========
trap2
==========
*/
double trap2(double x,
             double a,
             double b, 
             double c, 
             double d)
{
    return std::max(std::min({(x - a) / (b - a), 1.0, (d - x) / (d - c)}), 0.0);
}



/*
==========
trap1
==========
*/
double trap1(double x,
             double a,
             double b)
{
    return std::max(std::min((x - a) / (b - a), 1.0), 0.0);
}


/*
==========
monod
==========
*/
double monod(double R,
             double k)
{
    return R / (R + k);
}


/*
==========
calc_RsC
==========
*/
// The differential equation for the transport flux of substrate C in shoot:
double calc_RsC(double TR_C,
                double Ms,
                double Q_SCP)
{
    return(TR_C / pow(Ms, Q_SCP));
}


/*
==========
calc_RrC
==========
*/
// The differential equation for the transport flux of substrate C in root:
double calc_RrC(double TR_C,
                double Mr,
                double Q_SCP)
{
    return(TR_C / pow(Mr, Q_SCP));
}


/*
==========
calc_RdC
==========
*/
// The differential equation for the transport flux of substrate C in defence:
double calc_RdC(double TR_C,
                double Md,
                double Q_SCP)
{
    return(TR_C / pow(Md, Q_SCP));
}


/*
==========
calc_RsN
==========
*/
// The differential equation for the transport flux of substrate N in shoot:
double calc_RsN(double TR_N,
                double Ms,
                double Q_SCP)
{
    return(TR_N / pow(Ms, Q_SCP));
}


/*
==========
calc_RrN
==========
*/
// The differential equation for the transport flux of substrate N in root:
double calc_RrN(double TR_N,
                double Mr,
                double Q_SCP)
{
    return(TR_N / pow(Mr, Q_SCP));
}


/*
==========
calc_RdN
==========
*/
// The differential equation for the transport flux of substrate N in defence:
double calc_RdN(double TR_N,
                double Md,
                double Q_SCP)
{
    return(TR_N / pow(Md, Q_SCP));
}


/*
==========
calc_tauC
==========
*/
// transport rate of C from shoot to root
double calc_tauC(Plant& plant)
{    
    //std::cout << "Calculating tauC: Cs = " << plant.Cs << ", Ms = " << plant.Ms << ", Cr = " << plant.Cr << ", Mr = " 
    //<< plant.Mr << endl;
    return((plant.Cs/plant.Ms - plant.Cr/plant.Mr) / (plant.RsC + plant.RrC));
}


/*
==========
calc_tauN
==========
*/
// transport rate of N from root to shoot
double calc_tauN(Plant& plant)
{
    return((plant.Nr/plant.Mr - plant.Ns/plant.Ms) / (plant.RsN + plant.RrN)); 
}


/*
==========
calc_tauCd
==========
*/
// transport rate of C from shoot to defence
double calc_tauCd(Plant& plant)
{    
    return((plant.Cs/plant.Ms - plant.Cd/plant.Md) / (plant.RsC + plant.RdC));
}


/*
==========
calc_tauNd
==========
*/
// transport rate of N from root to defence
double calc_tauNd(Plant& plant)
{
    return((plant.Nr/plant.Mr - plant.Nd/plant.Md) / (plant.RdN + plant.RrN)); 
}


/*
==========
calc_UC
==========
*/
// Input rate of C substrate (via photosynthesis)
double calc_UC(Plant& plant,
               double CLeaf,
               double K_C,
               double K_M,
               double PI_C)
{
    if (plant.Ms != 0) {
        return((K_C * plant.Ms) / ((1 + plant.Ms / K_M)) * sf(plant.Cs/plant.Ms, PI_C, 100));
    } else {
        return(0.0);
    }
}

/*
==========
calc_UN
==========
*/
// Input rate of N substrate (via root uptake)
double calc_UN(Plant& plant,
               double N0,
               double K_M,
               double PI_N)
{
  if (plant.Mr != 0) { 
    return((N0 * plant.Mr) / ((1 + plant.Mr / K_M)) * sf(plant.Nr/plant.Mr, PI_N, 1000)); 
  } else {
    return(0.0);  
  }
} 


/*
==========
sf
==========
*/
double sf(double x,
          double k,
          double b)
{
    return(1/(1 + exp((x - k) * b)));
}


/*
==========
calc_Gs
==========
*/
// shoot growth function
double calc_Gs(Plant& plant,
               double G_SHOOT)
{
    return(G_SHOOT * (plant.Cs * plant.Ns) / plant.Ms);
}


/*
==========
calc_Gr
==========
*/
// root growth function
double calc_Gr(Plant& plant,
               double G_ROOT)
{
    return(G_ROOT * (plant.Cr * plant.Nr) / plant.Mr);
}


/*
==========
calc_Gd
==========
*/
// defence growth function
double calc_Gd(Plant& plant,
               double G_DEFENCE)
{
    return(G_DEFENCE * (plant.Cd * plant.Nd) / plant.Md);
}


/*
==========
calc_dCs_dt
==========
*/
// C pool changes in shoot (mod. from Thornley)
double calc_dCs_dt(Plant& plant,
                   double FRACTION_C)
{
    return(plant.UC - FRACTION_C * plant.Gs - plant.tauC - plant.tauCd);
}

/*
==========
calc_dCr_dt
==========
*/
// C pool changes in root (mod. from Thornley)
double calc_dCr_dt(Plant& plant,
                   double FRACTION_C)
{
    return(plant.tauC - FRACTION_C * plant.Gr);
}


/*
==========
calc_dCd_dt
==========
*/
// C pool changes in defence
double calc_dCd_dt(Plant& plant,
                   double FRACTION_C)
{
    return(plant.tauCd - (FRACTION_C * plant.Gd));
}


/*
==========
calc_dNs_dt
==========
*/
// N pool changes in shoot (mod. from Thornley)
double calc_dNs_dt(Plant& plant,
                   double FRACTION_N)
{
    return(plant.tauN - FRACTION_N * plant.Gs);
}


/*
==========
calc_dNr_dt
==========
*/
// N pool changes in root (mod. from Thornley)
double calc_dNr_dt(Plant& plant,
                   double FRACTION_N)
{
    return(plant.UN - FRACTION_N * plant.Gr - plant.tauN - plant.tauNd);
}


/*
==========
calc_dNd_dt
==========
*/
// N pool changes in defence
double calc_dNd_dt(Plant& plant,
                   double FRACTION_N)
{
    return(plant.tauNd - (FRACTION_N * plant.Gd));
}