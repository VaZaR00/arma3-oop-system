
#include "defines.hpp"

#ifndef ADDON
call FUNC(XEH_preStart);
#endif

#ifdef ADDON
call FUNC(XEH_prep);
#endif

call FUNC(initCBAEvents);