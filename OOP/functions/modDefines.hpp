
#include "..\includes\classDefines.hpp"

#define VAR_NAME (VAR_PREFIX + _name + (if (_instanceID < 0) then {""} else {"_" + str _instanceID}))