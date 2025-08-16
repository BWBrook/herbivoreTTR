#ifndef ENUMS_HPP
#define ENUMS_HPP


enum Herbivore_Type
{
    grazer = 0,
    browser = 1,
    mixed = 2
};

const enum Herbivore_Type GRAZER = grazer;
const enum Herbivore_Type BROWSER = browser;
const enum Herbivore_Type MIXED = mixed;

enum Herbivore_Behaviour
{
    moving = 0,
    eating = 1,
    resting = 2
};

const enum Herbivore_Behaviour MOVING = moving;
const enum Herbivore_Behaviour EATING = eating;
const enum Herbivore_Behaviour RESTING = resting;

#endif // ENUMS_HPP
