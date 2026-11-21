// Standalone base macros for OOP System (zero external library dependency)
// Every macro is guarded with #ifndef to coexist cleanly with other addons/frameworks.

#ifndef STR
#define STR(s) #s
#endif

#ifndef DOUBLE
#define DOUBLE(a,b) a##b
#endif

#ifndef TRIPLE
#define TRIPLE(a,b,c) a##b##c
#endif

#ifndef I
#define I ,
#endif

#ifndef SPREFX
#define SPREFX STR(PREFX)
#endif

#ifndef PREF_
#define PREF_ PREFX##_
#endif

#ifndef SPREF_
#define SPREF_ STR(PREF_)
#endif

#ifndef PREF_FNC
#define PREF_FNC PREFX##_fnc_
#endif

#ifndef FUNC
#define FUNC(f) PREF_FNC##f
#endif

#ifndef SFUNC_NAME
#define SFUNC_NAME(name) (STR(PREF_FNC) + name)
#endif

#ifndef VAR_PREFIX
#define VAR_PREFIX (if (isNil "_ADDON_PREFX") then {SPREFX} else {_ADDON_PREFX})
#endif

#ifndef FUNC_PATH_JOIN
#define FUNC_PATH_JOIN(path) ADDON_PATH\##path
#endif

#ifndef FUNC_PATH
#define FUNC_PATH(path) STR(FUNC_PATH_JOIN(path))
#endif

#ifndef CALL_FUNC_XEH
#define CALL_FUNC_XEH(f) STR(call compileScript ['FUNC_PATH_JOIN(f)'])
#endif

#ifndef DO_FUNC_RECOMPILE
#define DO_FUNC_RECOMPILE recompile = 1;
#endif

#ifndef FUNC_PRE_START
#define FUNC_PRE_START preStart = 1;
#endif

#ifndef CFUNC
#define CFUNC(f) _cFuncs pushBack [STR(DOUBLE(_,f)), STR(FUNC(f))]; private DOUBLE(_,f)
#endif

#ifndef _NIL
#define _NIL(var) (if !(isNil STR(var)) then {var})
#endif

#ifndef IF_NIL
#define IF_NIL(v, d) (if (isNil STR(v)) then {d} else {v})
#endif

#ifndef NIL_DEF
#define NIL_DEF _NIL(_def)
#endif

#ifndef VARS_STR
#define VARS_STR call { \
    if !(_this isEqualType []) then {_this = ["", _this]}; \
    params ["_txt", ["_varstr", ""]]; \
    if (_varstr isEqualTo "") then {_varstr = _txt}; \
    private _ar = _varstr splitString (",;.     " + endl); \
    private _arvs = _ar apply { \
        private _val = call compile format ["if !(isNil '%1') then {%1}", _x]; \
        if (isNil "_val") then {""} else {format ["%1: %2", _x, _val]} \
    }; \
    _txt + "  :  " + (_arvs joinString "; ") \
}
#endif

#ifndef DLOG
#define DLOG call {diag_log text format ["[DLOG:%3] %2 :: %1", _this, serverTime, SPREFX]}
#endif
