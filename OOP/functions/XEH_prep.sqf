#include "defines.hpp"

#ifdef DEV
#include "..\..\..\EFL_proj\EFL\functions\fnc_prepFunc.sqf"
#endif
#ifndef DEV
#include "z\efl\addons\efl\functions\fnc_prepFunc.sqf"
#endif

private _path = "";

#include "PREP.hpp"
#include "fn_compile.sqf"


#ifdef DEV
#include "..\..\..\EFL_proj\EFL\functions\COMPILE_FINAL.sqf"
#endif
#ifndef DEV
#include "z\efl\addons\efl\functions\COMPILE_FINAL.sqf"
#endif