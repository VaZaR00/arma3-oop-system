#include "defines.hpp"

#define LOG_CBA_EVENT 
// #define LOG_CBA_EVENT [_NIL(_eventName), time, _NIL(_this), clientOwner] RLOG

#define WRAP_FUNC(f) {LOG_CBA_EVENT; _this call f}

[OOP_SPREF(callClassInstance), WRAP_FUNC(FUNC(callClassInstance))] call CBA_fnc_addEventHandler;
