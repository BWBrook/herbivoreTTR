# herbivore-TTR-model
Large herbivore model linked with the Thornley Transport Resistance model as a simple vegetation model stand-in.

## Technical details pertaining to installing and running the model:
* Models written in C++
* I use VS Code to edit and compile, then Developer Command Prompt for VS to run

## To compile and run:
* Open the "main.cpp" file in VS Code
* Press CTRL+SHIFT+B (this will compile the current version of the code)
* Open the Developer Command Prompt for VS and navigate to the herbivore-TTR-model folder using "cd"
* Type "main.exe" and press ENTER (this will run the code)

## Notes:
* Code is commented judiciously. Units are defined in the "constants.hpp" file and elsewhere when first mentioned. References are included.
* The code is generally organised as follows:
* * main.cpp is the file that calls the rest of the code. This is the file you run the model from.
* * init_aDGVM.cpp is the file that initialises the model with starting values and gets it ready to run.
* * daily_per_plant.cpp contains all the plant related functions
* * daily_per_plot.cpp contains all the herbivore functions as well as all the rest of the non-plant related functions that need to happen in the plot daily.
* * all .cpp files have an associated .hpp file. If you make any updates to a .cpp file, check the .hpp file and make sure you don't need to update anything there because if the headings don't match the code will not run.
* * not all .hpp files have an associated .cpp file. Two important ones to work with are the "structs.hpp" file and the "constants.hpp" file which define the structures and the constants used in the model, respectively.
* If you search for @TODO in the code you will find code areas needing to be attended to (or areas of further development). 
* Output will be saved in /data/output in 3 files: herbivores.txt (herbivore information per day), plants.txt (plant information per individual per day) and screen_output.txt (this is just useful for debugging) 
