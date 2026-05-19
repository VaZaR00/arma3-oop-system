
#include "..\includes\classDefines.hpp"

#define VAR_PREFIX (if (isNil "_ADDON_PREFX") then {SPREFX} else {_ADDON_PREFX})
#define VAR_NAME (VAR_PREFIX + _name + (if (_instanceID < 0) then {""} else {"_" + str _instanceID}))