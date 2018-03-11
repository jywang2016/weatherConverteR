# weatherConverteR
using eplusr and coolprop to inset your weather data in EPW

The `main.R` call `read_epw()` function to parse the epw files provided by [EnergyPlus](https://energyplus.net/) and provide a way (call CoolProp.dll)[https://github.com/CoolProp/CoolProp] to calculate the dew point temperature. Furthermore, you can organize your weather data in R. And `write_epw()`function allows you replace the epw files (including Location and Weather) with your own organized weather data.

By the way, both of `read_epw()` and `write_epw()` are programmed by [Hongyuan Jia](https://github.com/hongyuanjia), a wise man :). You can find those amazing functions in the early version of (**eplusr**)[https://github.com/hongyuanjia/eplusr]. Unforunately, it seems that the express edition of `eplusr` remove the parts about editing epw files. Therefore, I just extract them from the (forked version)[https://github.com/jywang2016/eplusr/tree/master/R].
