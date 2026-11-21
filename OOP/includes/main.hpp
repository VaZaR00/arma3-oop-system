#define PREFX CFM_OOP
#define OOP_PREFX PREFX

#define ADDON_PATH z\cfm\addons\##PREFX##\functions
#ifdef DEV
#define ADDON_PATH mods\OOP_proj\OOP\functions
#endif
