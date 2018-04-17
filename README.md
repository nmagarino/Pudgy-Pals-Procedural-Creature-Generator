# CIS-566 Final Project

# Midpoint Milestone

h

# Design Doc

Group Members: Josh Nadel and Nicholas Magarino

Introduction: What motivates this project?

The primary motivation for this project is the wide variety of procedural character creation interfaces that are present in so many modern (and older!) video games.  Specifically, we’re looking at the character creators that can generate completely random and still good-looking characters based on some amount of user input.

Goal: What do you intend to achieve with this project?

The goal of this project is to become familiar with a general procedure for procedurally generating characters, specifically how to make them interesting and coherent looking with as little manual tuning as possible and as much variety as possible.  We hope to learn how much user input could also appropriately affect the look of a random character.

Inspiration/reference: Attach some materials, visual or otherwise you intend as reference.

The primary inspiration will be the creature creator in Spore, which allows players to create or generate a creature of their choosing (given some premade assets).

Specification: Outline the main features of your project.

This project will allow a user to randomly generate a creature or robot (?), and also manipulate the features of said creature in some way (adjusting position of or adding body parts, changing color or shading, etc.).  The creator could allow the user to generate a random creature based on some base parameters.  For example, the user could specify the program to make something with 3 arms and 2 legs, that stands upright, and has 1 eye.

Techniques: What are the main technical/algorithmic tools you’ll be using? Give an overview, citing specific papers/articles.

Use metaballs to create organic looking forms for bodies
Use SDFs to create shapes with ray marching, use other SDF operations to smoothly blend shapes together
Need some way to automatically place the needed body parts given information about the previous body parts already in place (for example, where do we place the arms based on how many arms will be placed, and based on the dimensions of the torso).
Notes on Spore creature generation by Chris Hecker: http://chrishecker.com/My_liner_notes_for_spore#Creature_Skin_Mesh
Framework for Robot Construction Game: http://ieeexplore.ieee.org/stamp/stamp.jsp?arnumber=7332727

Design: How will your program fit together? Make a simple free-body diagram illustrating the pieces.

* User specifies inputs via GUI, generate button to start the process
* “Creature” class with array fields for different body parts
* Arms, Legs, eyes, details, etc arrays
* Body part types have their own classes containing all information needed to render that body part
* All body parts have a transformation
* Arms and legs have joint arrays
* Eyes might have a “color” field
* Raymarcher reads from body parts and generates the implicit geometry
* Textures determined by world space surface normal, position, designation of parts, etc

Timeline: Create a week-by-week set of milestones for each person in your group. Make sure you explicitly outline what each group member's duties will be.

> Week 1 - metaball spine
- Nick - spline implementation and rendering
- Josh - creature framwork & spline implementation
> Week 2 - limb class and rendering
- Nick - head class, limb rendering
- Josh - limb class construction and camera controls
> Week  3 - Placement algorithm - collision avoidance?
- Nick - user input, interaction
- Josh - randomization


