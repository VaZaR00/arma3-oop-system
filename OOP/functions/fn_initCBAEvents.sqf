#include "defines.hpp"

#define DO_LOG_CBA_EVENTS

#ifdef DO_LOG_CBA_EVENTS
	#define LOG_CBA_EVENT [_NIL(_eventName), time, _NIL(_this), clientOwner] RLOG
#endif

#define WRAP_FUNC(f) {LOG_CBA_EVENT; _this call f}

["EFL_callClassInstance", WRAP_FUNC(OOP_OBJ_CLASS_fnc_callClassInstance)] call CBA_fnc_addEventHandler;
