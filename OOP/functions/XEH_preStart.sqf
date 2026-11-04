
#include "defines.hpp"

#ifndef ADDON
call FUNC(XEH_prep);
#else
call compileScript [FUNC_PATH(XEH_prep.sqf)];
#endif