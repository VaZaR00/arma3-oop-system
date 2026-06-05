#include "defines.hpp"

// #define LOG_CBA_EVENT [_NIL(_eventName), time, _NIL(_this), clientOwner] RLOG
#define LOG_CBA_EVENT 

#define WRAP_FUNC(f) {LOG_CBA_EVENT; _this call f}

["EFL_callClassInstance", WRAP_FUNC(PREF(OBJ_CLASS_fnc_callClassInstance))] call CBA_fnc_addEventHandler;
