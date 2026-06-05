
#include "..\includes\classDefines.hpp"

#define EFL_FUNC(f) TRIPLE(EFL_PREFX,_fnc_,f)
#define VAR_NAME (format["%1%2%3%4", VAR_PREFIX, _varsPrefix, _name, (if (_instanceID < 0) then {""} else {"_" + str _instanceID})])

_ADDON_PREFX = SPREFX;