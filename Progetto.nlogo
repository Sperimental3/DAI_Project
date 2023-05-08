globals [ problems_solved final_ticks time ]

patches-own [ chemical ]

breed [ solvers solver ]
solvers-own [ ability employed ]

breed [ problems problem ]
problems-own [ difficulty struggle ]

to setup
  ca

  ask n-of n_solvers patches                              ; this strange way to create new agents, both problems and solvers, is needed
  [ sprout-solvers 1                                      ; to avoid having two problems or solvers on the same patch at the beginning
    [ ;set shape "Arrow"
      set color blue
      ;set size 2
      set ability random max_ability + 1                  ; the ability that each solver has to solve problems
      set employed 0
    ]
  ]

  ask n-of n_problems patches
  [ sprout-problems 1
    [ set shape "Triangle"
      set color red
      set size 2
      set difficulty random max_difficulty + 1            ; the difficulty of each problem, the solvers need to have at least this number to solve the problem
      set struggle 0
    ]
  ]

  ask patches
  [ set chemical 0 ]

  reset-ticks
end

;; it can be useful for some experiments to spawn new solvers
to spawn_solvers
  ask n-of n_solvers patches
  [ sprout-solvers 1
    [ ;set shape "Arrow"
      set color blue
      ;set size 2
      set ability random max_ability + 1
      set employed 0
    ]
  ]

  set time 0                                               ; if you introduce new entities in the simulation the final score (ticks) should be unlocked
end

;; it can be useful for some experiments to spawn new problems
to spawn_problems
  ask n-of n_problems patches
  [ if not any? problems-here
    [ sprout-problems 1
      [ set shape "Triangle"
        set color red
        set size 2
        set difficulty random max_difficulty + 1
        set struggle 0
      ]
    ]
  ]

  set time 0
end

;; main method to be executed at each tick
to go
  ask solvers
  [ set employed 0
    ifelse Avoid_deadlock
    [ ifelse any? problems-here with [ color = red ]
      [ ifelse any? problems-here with [ struggle < 100 ]   ; this parameter is really important, it decides how many ticks a solver can stay on a problem
        [ solve ]
        [ ask problems-here [ set struggle 0 ]
          ask solvers-here
          [ rt 180                                          ; solvers move away from the problem, trying to avoid deadlock situations
            fd 5
          ]
        ]
      ]
      [ ifelse chemical > 0.5 and Slime_mold_aggregation    ; ignore pheromone unless there's enough here, a parameter which is possible to set
        [ turn-toward-chemical ]
        [ rt random-float 45 - random-float 45 ]            ; 45° is the wiggle angle, I've decided to set it statically to lower the number of parameters
        fd 1
      ]
    ]
    ;; if Avoid_deadlock is off
    [ ifelse any? problems-here with [ color = red ]
      [ solve ]
      [ ifelse chemical > 0.5 and Slime_mold_aggregation
        [ turn-toward-chemical ]
        [ rt random-float 45 - random-float 45 ]
        fd 1
      ]
    ]
  ]

  if Slime_mold_aggregation
  [ diffuse chemical 1                                      ; propagate the chemical to neighborhood

    ask patches
    [ ifelse Avoid_deadlock
      [ set chemical chemical * 0.5                         ; evaporate chemical
        set pcolor scale-color magenta chemical 0 3      ; update display of chemical concentration
      ]
      [ set chemical chemical * 0.9                         ; the rate of evaporation in the case of "Avoid_deadlock" is much faster
        set pcolor scale-color magenta chemical 0 30      ; beacuse we want solvers to get away from the unsolvable problem as fast as possible
      ]
    ]
  ]

  if problems_solved = (count problems) and time = 0        ; variable needed to stop the time, we want just the final score of ticks
  [ set time 1
    set final_ticks ticks
  ]

  tick
end

;; the method for solving problems, either with a contract net-like cooperation or without it
to solve
  ifelse Contract_net
  [ ifelse any? other solvers-here with [ employed = 1 ]    ; the employed attribute is useful in particular for the synchronization part,
    [ set chemical chemical + chemical_intensity ]          ; it ensures that only a solver at a time execute some crucial instructions as the setting of the struggle
    [ set employed  1
      ;show ability
      ask problems-here
      [ ;create-links-with other solvers in-radius 1        ; usefull if we want to create a mess
        set struggle struggle + 1
        ;show struggle

        let total_power sum [ ability ] of solvers-here     ; or in-radius
        ifelse ( difficulty <= total_power)
        [ set color green
          set problems_solved problems_solved + 1
          set chemical 0
          set struggle 0
        ]
        [ set chemical chemical + chemical_intensity ]
      ]
    ]
  ]
  ;; if Contract_net is off
  [ ifelse any? other solvers-here with [ employed = 1 ]
    [ set chemical chemical + chemical_intensity ]
    [ set employed 1
      ask problems-here
      [ set struggle struggle + 1
        let total_power [ ability ] of myself
        ifelse ( difficulty <= total_power)
        [ set color green
          set problems_solved problems_solved + 1
          set chemical 0
          set struggle 0
        ]
        [ set chemical chemical + chemical_intensity ]
      ]
    ]
  ]

end

;; examine the patch ahead of you and two nearby patches and turn in the direction of greatest chemical
to turn-toward-chemical

  let ahead [ chemical ] of patch-ahead 1
  let myright [ chemical ] of patch-right-and-ahead 45 1      ; here we can tune a little the angle for sensing the chemical and for turning in that direction consequently
  let myleft [ chemical ] of patch-left-and-ahead 45 1

  ifelse (myright >= ahead) and (myright >= myleft)
  [ rt 45 ]
  [ if myleft >= ahead
    [ lt 45 ]
  ]
end
@#$#@#$#@
GRAPHICS-WINDOW
309
10
968
451
-1
-1
6.45
1
10
1
1
1
0
1
1
1
-50
50
-33
33
0
0
1
ticks
30.0

SLIDER
41
176
253
209
n_solvers
n_solvers
0
100
50.0
1
1
NIL
HORIZONTAL

BUTTON
23
10
117
72
setup
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
167
10
264
73
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
42
225
254
258
n_problems
n_problems
1
100
30.0
1
1
NIL
HORIZONTAL

MONITOR
982
10
1092
55
Problems solved
problems_solved
17
1
11

PLOT
983
74
1243
293
Plot
ticks
problems_solved
0.0
100.0
0.0
100.0
true
false
"" ""
PENS
"ciao" 1.0 0 -16777216 true "" "plot problems_solved"

SLIDER
62
332
234
365
max_difficulty
max_difficulty
1
100
10.0
1
1
NIL
HORIZONTAL

SLIDER
62
394
236
427
chemical_intensity
chemical_intensity
0
10
10.0
1
1
NIL
HORIZONTAL

SLIDER
62
285
234
318
max_ability
max_ability
1
100
10.0
1
1
NIL
HORIZONTAL

SWITCH
1009
317
1210
350
Slime_mold_aggregation
Slime_mold_aggregation
1
1
-1000

SWITCH
1010
366
1211
399
Contract_net
Contract_net
1
1
-1000

SWITCH
1010
414
1212
447
Avoid_deadlock
Avoid_deadlock
0
1
-1000

MONITOR
1104
10
1277
55
Number of ticks to complete
final_ticks
17
1
11

BUTTON
23
97
118
139
Add solvers
spawn_solvers
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
166
98
265
141
Add problems
spawn_problems
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

@#$#@#$#@
## WHAT IS IT?

A model about the interaction of multiple generic entities (the solvers) trying to solve generical problems which are already, and can appear, in the environment.
It tries to show the importance of swarm intelligence (in particular the behavior of slime mold behavior in aggregation) and cooperative behaviors (a sort of contract net-like protocol) that combined together can greatly improved the solution of possibly inherently distributed problems.

## HOW IT WORKS

This is a "modular" model, in the sense that I've provided 3 switches to able/disable the key features of the model, I will describe the general functioning, with all the features "On".
Once created the agents simply start moving randomically in the environment, but at the same time they also sense the environment around them, searching for chemical, if the chemical on a particular patch is the biggest around (and greater than a certain threshold) they will turn toward that patch until they will end up eventually (together with other agents) on a problem. At the beginning there is no chemical on the patches, in fact, unlike what happens with the slime mold, agents do not spread continuously chemical, but only when they arrive on a problem unsolved. So at the start the first agent that arrives on a problem, starts spreading the chemical that will help other agents to arrive there and to group with him, we can see this initial spreading of the first agent as a call for proposal in the contract net.
The problems have different difficulties, and the solvers different abilities to solve them; Once on the same problem, this will be solved only when there is enough ability (the sum of agents abilities there, they can be seen as the bidders of a contract net protocol).
In some condition there is the need of introducing a maximum time agents can stay on a problem without solving it to avoid deadlock, I've wanted also to introduce a switch that "allows deadlocks" to underline that if this condition happens the system could be under dimensioned (i.e. the number of problems or their difficulties is too large for the number of solvers or their abilities).

## HOW TO USE IT

Other the setup and go buttons, it is also possible to add solvers and problems on the fly (it can be useful for example to see how a new group of agents can impact on the world, maybe in a deadlock situation).
There are sliders to control the number of solvers and problems, together with two for maximum ability and maximum difficulty, the actual number of these properties for each agent is actually pick at random from 1 to the maximum specified by the user with the slider. There is at the end a slider to control the intensity of the chemical that each agent will drop and the environment will spread once arrived on a problem. 
As mentioned before there are 3 switches granting the possibility for various combinations for the simulation.
There are monitor and plot to visualized the number of solved problems in real time; Finally a monitor to see in how many ticks (that can be considered time for netlogo) all the problems on the environment have been solved.

## THINGS TO NOTICE

An important thing that a user should notice is that if the maximum difficulty of a problem is greater than the maximum ability of any agents, and if the cooperation between agents (the contract net-like behavior) is disable, it can happen that some problems can not be solved because they cannot be solved by a single agent. If one wants to compare the behavior of the model with or without contract net (and slime mold aggregation together with the avoiding of the deadlocks) this aspect should be take into consideration (one can set the maximum ability and difficulty slider equals).

## THINGS TO TRY

I suggest to fix the parameters of the sliders, tuning them on values that suit your experiment, and then trying all the different combinations (or those that for you are the most relevant) of the switches, trying to see how the time of completion varies, if deadlock conditions happen, etc.

## EXTENDING THE MODEL

There are many parameters not explicitly changeable with sliders (for a more clear interface), in particular values about sniff angle, sniff threshold, angle of rotation and others, one of the most important is probably the value that regulate how many ticks a solver can stay on a problem without solving it (setted to 100 in the code), you can look at the code tab for them and change them there.
A possible extension of the model, in order to make it more complicated, would be introducing new classes of problems (differentiated by color) with the solvers that instead of having a single ability to solve, will have multiple different abilities to solve different classes of problems.

## NETLOGO FEATURES

One peculiar thing of NetLogo used here is the keyword "diffuse", it is really useful in contexts related to field or chemical based interaction.
The keyword "sprout" has been used to avoid new created problems and solvers to be on the same patch.

## RELATED MODELS

Slime, under the section Sample Models/Biology in the NetLogo models library.

## CREDITS AND REFERENCES

Wilensky, U. (1997). NetLogo Slime model. http://ccl.northwestern.edu/netlogo/models/Slime. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.2.2
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
