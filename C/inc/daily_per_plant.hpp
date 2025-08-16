#ifndef DAILY_PER_PLANT_HPP
#define DAILY_PER_PLANT_HPP

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
                          int dayofsim);


/*
==========
calc_SWforcer
==========
*/
double calc_SWforcer(double SW,
                     double SWw,
                     double SWstar);


/*
==========
trap2
==========
*/
double trap2(double x,
             double a,
             double b, 
             double c, 
             double d);


/*
==========
trap1
==========
*/
double trap1(double x,
             double a,
             double b);


/*
==========
monod
==========
*/
double monod(double R,
             double k);


/*
==========
calc_RsC
==========
*/
double calc_RsC(double TR_C,
                double Ms,
                double Q_SCP);


/*
==========
calc_RrC
==========
*/
double calc_RrC(double TR_C,
                double Mr,
                double Q_SCP);


/*
==========
calc_RdC
==========
*/
double calc_RdC(double TR_C,
                double Md,
                double Q_SCP);


/*
==========
calc_RsN
==========
*/
double calc_RsN(double TR_N,
                double Ms,
                double Q_SCP);


/*
==========
calc_RrN
==========
*/
double calc_RrN(double TR_N,
                double Mr,
                double Q_SCP);


/*
==========
calc_RdN
==========
*/
double calc_RdN(double TR_N,
                double Md,
                double Q_SCP);


/*
==========
calc_tauC
==========
*/
double calc_tauC(Plant& plant);


/*
==========
calc_tauN
==========
*/
double calc_tauN(Plant& plant);


/*
==========
calc_tauCd
==========
*/
double calc_tauCd(Plant& plant);


/*
==========
calc_tauNd
==========
*/
double calc_tauNd(Plant& plant);


/*
==========
calc_UC
==========
*/
double calc_UC(Plant& plant,
               double CLeaf,
               double K_C,
               double K_M,
               double PI_C);


/*
==========
calc_UN
==========
*/
double calc_UN(Plant& plant,
               double N0,
               double K_M,
               double PI_N);


/*
==========
sf
==========
*/
double sf(double x,
          double k,
          double b);


/*
==========
calc_Gs
==========
*/
double calc_Gs(Plant& plant,
               double G_SHOOT);


/*
==========
calc_Gr
==========
*/
double calc_Gr(Plant& plant,
               double G_ROOT);


/*
==========
calc_Gd
==========
*/
// defence growth function
double calc_Gd(Plant& plant,
               double G_DEFENCE);


/*
==========
calc_dCs_dt
==========
*/
double calc_dCs_dt(Plant& plant,
                   double FRACTION_C);


/*
==========
calc_dCr_dt
==========
*/
double calc_dCr_dt(Plant& plant,
                   double FRACTION_C);



/*
==========
calc_dCd_dt
==========
*/
double calc_dCd_dt(Plant& plant,
                   double FRACTION_C);


/*
==========
calc_dNs_dt
==========
*/
double calc_dNs_dt(Plant& plant,
                   double FRACTION_N);


/*
==========
calc_dNr_dt
==========
*/
double calc_dNr_dt(Plant& plant,
                   double FRACTION_N);


/*
==========
calc_dNd_dt
==========
*/
double calc_dNd_dt(Plant& plant,
                   double FRACTION_N);

#endif // DAILY_PER_PLANT_HPP