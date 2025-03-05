*------------------------------------------------------------------------   
* Define the sets of streams and components in the process
* Streams according to proposed flowsheet      
*------------------------------------------------------------------------
sets
    component Components in the process /methanol, water, dimethyl/
    stream Streams in the system /feed, mix, effluent,
                                     product, bottom, recycle, waste/
;

*------------------------------------------------------------------------   
* Each stream is described by the individual flows of all the components      
*------------------------------------------------------------------------
positive variable
    f(stream,component) Flows of components in streams [kmol per hour]
;

*------------------------------------------------------------------------   
* Specification of the feed composition with given data
* Calculation of feed stream in kmol per hour with given equation
* feed composition is fixed 
*------------------------------------------------------------------------
parameter
    ffm feed fraction methanol /0.99/
    sn last digit student number for feed stream calculation /7/
    fstream feed stream in kmol per hour
;

*Calculate feed stream with given equation
fstream = 450 + 10*sn;

f.fx('feed','dimethyl') = 0;
f.fx('feed','methanol') = ffm*fstream;
f.fx('feed','water') = (1-ffm)*fstream;

*------------------------------------------------------------------------   
* Purity of the product in the product stream is given       
*------------------------------------------------------------------------
parameter
    purity /0.99/
;

*------------------------------------------------------------------------   
* Constraint on feasible solutions that they must have a product
* stream with the desired purity of product P.
*------------------------------------------------------------------------
equation
    fraction Purity of product
;

fraction .. f('product','dimethyl')
            =g= purity*sum(component,f('product',component));
            
*------------------------------------------------------------------------   
* Given a semi-sharp separation (see later) it is assumed that there is no
* water in the product stream and no product in the waste 
*------------------------------------------------------------------------   
f.fx('product','water') = 0.0;
f.fx('waste','dimethyl') = 0.0;

*------------------------------------------------------------------------   
* Definition of mass balance for the mixer for every component 
* In the mixer feed and recycling streams are combined to one stream
* flowing to the reactor: input = output
*------------------------------------------------------------------------
equations
    mixermb(component)
;

mixermb(component) .. f('feed',component) + f('recycle',component)
                      =e= f('mix',component);

*------------------------------------------------------------------------   
* The reactions that take place at a defined residence time t with a
* conversion x for methanol to products. X is dependent on t and will be
* calculated later for different values of t in the for-loop at the end
*------------------------------------------------------------------------
parameters
    x Conversion 
    t residence time /2/
;

* Given conversion relation with values from regression task
x = 0.3416 + log(t)*0.6119;

*------------------------------------------------------------------------   
* Definition of extent of the reaction for mass balances. There is only
* one reaction taking place, resulting in one extent variable
*------------------------------------------------------------------------
positive variables
    xi Extents of reactions
;

*------------------------------------------------------------------------   
* The model for the reactor consists of the definition of single pass conversion
* and a mass balance for each molecular species.
*------------------------------------------------------------------------
equations
    conversion Definition of conversion
    rmb_methanol Reactor mass balance for methanol 
    rmb_water Reactor mass balance for Water  
    rmb_dimethyl Reactor mass balance for Dimethyl ether 
;

* Definition of conversion: How much of the stream of methanol is converted 
conversion .. xi =e= x * f('mix','methanol');

*------------------------------------------------------------------------   
* the mass balances of the reactor are based on extents (XI) of reaction:
* output = input + amount*XI 
* Given the stoichiometry of the reaction 2*Me = 1*H2O + 1*Dimethyl ether
* the reacted methanol is equally converted into water and dimethyl,
* so 0,5*xi respectively 
*------------------------------------------------------------------------
rmb_methanol .. f('effluent','methanol') =e= f('mix','methanol') - xi;
rmb_water .. f('effluent','water') =e= f('mix','water') + 0.5*xi;
rmb_dimethyl .. f('effluent','dimethyl') =e= f('mix','dimethyl') + 0.5*xi;

*------------------------------------------------------------------------   
* The two distillation columns both have a design variable: the key recovery.
* Those are given lower and upper values allowed and we let GAMS choose the
* best value. This assumes that we will be solving an optimization problem 
*------------------------------------------------------------------------
positive variable
    r_1 Recovery of key components for first distillation
    r_2 Recovery of key components for second distillation
;

r_1.lo = 0.9;
r_1.up = 0.998;

r_2.lo = 0.9;
r_2.up = 0.998;

*------------------------------------------------------------------------   
* The process consists of two distillations. The first rectification column
* is seperating the product and the second methanol as the recycling component 
* The mass balances for the distillation columns are input = output with one
* input stream and two output streams.  We also include two equations based on
* the definition of a semi-sharp separation: the recovery of the light and
* heavy keys.
*------------------------------------------------------------------------
equations
    distillationmb1(component) Mass balance around distillation column
    distillationtoplightkey1 Distribution of light key in top stream
    distillationtopheavykey1 Distribution of heavy key to top stream
;

* Mass balance first distillation: distillation stream is called 'product'
distillationmb1(component) .. f('effluent',component)
                              =e= f('product',component)
                              + f('bottom', component);
                             
* In this distillation all the water is at the bottom 
distillationtoplightkey1 .. f('product','dimethyl')
                            =e= r_1*f('effluent','dimethyl');
distillationtopheavykey1 .. f('product','methanol')
                            =e= (1-r_1)*f('effluent','methanol');

*------------------------------------------------------------------------   
* Same for second distillation
*------------------------------------------------------------
equations
    distillationmb2(component) Mass balance around distillation column
    distillationtoplightkey2 Distribution of light key in top stream
    distillationtopheavykey2 Distribution of heavy key to top stream
;

distillationmb2(component) .. f('bottom',component)
                              =e= f('recycle',component)
                              + f('waste', component);

* In this distillation rest of the dimethyl is only in the distillate                  
distillationtoplightkey2 .. f('recycle','methanol')
                            =e= r_2*f('bottom','methanol');
distillationtopheavykey2 .. f('recycle','water')
                            =e= (1-r_2)*f('bottom','water');

*------------------------------------------------------------------------   
* Here we define all the parameters for estimating the economic potential.
* To convert the units of the streams, we also need molar mass of the components
* The numbers for each component are from the NIST page 
*------------------------------------------------------------------------
parameters
    hpy Operating hours per year /8150/
    value Value product in € per kg /1.15/
    cost Cost of feed stream in € per kg /0.4/
    M_dimethyl molar mass dimethyl in kg per kmol /46/
    M_methanol same /32/
    M_water same /18/
;

*------------------------------------------------------------------------   
* To calculate the cost of the distillation columns we need the relative
* volatilies of light to heavy keys. Those are calculated from the vapour
* pressures. The vapour presures are calculated with the 
* Antoine coefficients from http://webbook.nist.gov/chemistry/
* for log_10 (P [bar]) = A - B / (T [K] + C)
*
* As the vapour pressure is dependet on the temperature we assume a fixed
* temperature as a new design variables. We assign the lowest possible value of
* 35°C = 308K. This is because according to the physical properties the
* relative volatility is the highest for low temperatures. The higher
* this alpha is the lower is the cost for distillation (see equation)
* and this is what we want (see report). Therefore no need for GAMS to find an optimal value for T
*------------------------------------------------------------------------
sets  
    coeff Antoine coefficients /A, B, C/
;

Table antoine(component, coeff) Antoine coefficients
                      A            B           C
    methanol       5.20409     1581.341     -33.5
    water          5.20389     1733.926     -39.485
    dimethyl       4.11475     894.669      -30.604
;
  
parameters
    T_1 teperature for first distillation /308/
    T_2 temperature for second distillation /308/
    pstar1(component) saturation or vapour pressure for first temperature
    pstar2(component) saturation or vapour pressure for second temperature    
    alpha_1 Volatility light to heavy key first distillation 
    alpha_2 Volatility light to heavy key second distillation
;

* Calculation of vapour pressure for assigned temperatures
pstar1(component) = 10**(antoine(component,'A') - antoine(component,'B')/(T_1 + antoine(component,'C')));
pstar2(component) = 10**(antoine(component,'A') - antoine(component,'B')/(T_2 + antoine(component,'C')));

* Relative volatilities for distilations with alpha = pstar(LK)/pstar(HK)
alpha_1 = pstar1('dimethyl')/pstar1('methanol');
alpha_2 = pstar2('methanol')/pstar2('water');

*------------------------------------------------------------------------   
* The economic potential will be the difference between the product values and
* raw material cost minus the costs of the processing units.
*------------------------------------------------------------------------
variable
    netvalue Difference in value of products and cost of feed € per hour
    unitcosts Cost of the various units in € per hour
    EP Economic potential in € per hour
;

*Calculation of netvalue and convert stream from kmol per hour in kg per hour with molar mass of components
equation
    materialscosts Cost of material and direct calculation of netvalue 
;

materialscosts .. netvalue
                  =e= value*f('product','dimethyl')*M_dimethyl
                  - cost*(f('feed','methanol')*M_methanol
                  + f('feed','water')*M_water);

*Calculate the unit cost and convert from M€ per year in € per hour with 8150 operating hours
equation
    costunits Cost of units 
;

costunits .. unitcosts =e=
                 1000000*(0.001*t*sum(component, f('mix',component))
                + sqrt(sum(component, f('mix',component)))/(100*(1-r_1)*(alpha_1-1))
                + sqrt(sum(component, f('mix',component)))/(100*(1-r_2)*(alpha_2-1)))/hpy;

*Calculation of economic potential
equation
    economicpotential
;

economicpotential .. EP =e= netvalue - unitcosts;



*------------------------------------------------------------------------   
* we will use the optimization capabilities of GAMS to find the best solution
* for different values of the recovery design variable, letting the
* optimization method find the best values for the key recoveries in the
* distillation column. We also iterate through different values of t 
*
* the objective function for the optimization will be the economic potential
* which should be maximized.
*------------------------------------------------------------------------
variable
    z
;

equation
    objective
;

objective .. z =e= EP;

model process /all/;



*------------------------------------------------------------------------   
* specify a file to which we will send results      
*------------------------------------------------------------------------
file results /Project.txt/;
put results;
put '#        t          x           r_1         r_2         z' /;

*------------------------------------------------------------------------   
* iterate over different values of the residence time t, the upper and lower
* value refer to the allowed domain suggested in the regression task 
*------------------------------------------------------------------------
for(t = 0.6 to 2.5 by 0.01,

*------------------------------------------------------------------------   
* the conversion is a function of the residence time and 
* therefore need to be calculated for each different value of t.
*------------------------------------------------------------------------
        x = 0.3416 + log(t)*0.6119;

*------------------------------------------------------------------------   
* we initialize all stream flows to reasonable values to help GAMS get started
* in the search for the solution. In this case 0 as for example there is
* no water in the product stream 
*------------------------------------------------------------------------
        f.l(stream,component) = 0;

*------------------------------------------------------------------------   
* solve the model as an optimization problem as there are two degrees of
* freedom (the recoveries)
*------------------------------------------------------------------------
        solve process using nlp maximizing z;

*------------------------------------------------------------------------   
* all relevant values are displayed into the LST file that GAMS generates       
*------------------------------------------------------------------------
        display netvalue.l, unitcosts.l, EP.l;
        display t, x, r_1.l, r_2.l, f.l;
        
*------------------------------------------------------------------------   
* output the solutions in the data file which can be used to plot the economic potential,
*------------------------------------------------------------------------
        put t, x, r_1.l, r_2.l, z.l/;
        
    put /;
);