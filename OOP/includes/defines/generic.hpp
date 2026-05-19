

#define STR(s) #s
#define DOUBLE(a,b) a##b
#define TRIPLE(a,b,c) a##b##c
#define QUAD(a,b,c,d) a##b##c##d
#define SPREFX STR(PREFX)
#define DO_FUNC_RECOMPILE recompile = 1;
#define FUNC_PRE_START preStart = 1;
#define FUNC_PATH_JOIN(path) ADDON_PATH\##path
#define FUNC_PATH(path) STR(FUNC_PATH_JOIN(path))
#define PREF_ PREFX##_
#define SPREF_ STR(PREF_)
#define PREF_FNC PREFX##_fnc_
#define PREFVAR PREF_
#define SPREFVAR(var) STR(DOUBLE(PREF_, var))
#define FUNC(f) PREF_FNC##f
#define SFUNC(f) STR(FUNC(f))
#define SFUNC_NAME(name) (STR(PREF_FNC) + name)
#define QFUNC(f) (MGVAR [STR(PREF_FNC) + f, {}])
#define PREF_QVAR(s) (PREF_VAR + s)
#define RC_PREF(s) (PREF_CLAS + s)


#define FN_FUNC_CFG(name) class name {file = FUNC_PATH(TRIPLE(fn_,name,.sqf));DO_FUNC_RECOMPILE};
#define FN_FUNC_CFG_PRE(name) class name {file = FUNC_PATH(TRIPLE(fn_,name,.sqf));preInit = 1;DO_FUNC_RECOMPILE};
#define FN_FUNC_CFG_POST(name) class name {file = FUNC_PATH(TRIPLE(fn_,name,.sqf));postInit = 1;DO_FUNC_RECOMPILE};

#define FUNC_CFG(name) class name {file = FUNC_PATH(DOUBLE(name,.sqf));DO_FUNC_RECOMPILE};
#define FUNC_CFG_POST(name) class name {file = FUNC_PATH(DOUBLE(name,.sqf));postInit = 1;DO_FUNC_RECOMPILE};
#define FUNC_CFG_PRE(name) class name {file = FUNC_PATH(DOUBLE(name,.sqf));preInit = 1;DO_FUNC_RECOMPILE};


#define I ,
#define PR private
#define GV getVariable
#define SV setVariable
#define MN missionNamespace
#define IS_FPV(cls) (("fpv" in cls) || {("crocus" in cls)})
#define IS_MAVIC(cls) ("mavik_3" in cls)
#define NULL_VECTOR [0,0,0]
#define DEF_DIR [0,1,0]
#define DEF_UP [0,0,1]
#define IS_OBJ(o) (!(o isEqualTo objNull) && {o isEqualType objNull})
#define IS_STR(s) ((s isEqualType "") && {!(s isEqualTo "")})
#define IS_FUNC(f) ((f isEqualType {}) && {!(f isEqualTo {})})
#define IS_ARRAY(a) ((a isEqualType []) && {!(a isEqualTo [])})
#define IS_LOC(l) ((typeName l) isEqualTo "LOCATION")
#define IS_HASH(h) (h isEqualType createHashMap)
#define IS_INT(s) (s isEqualType 0)
#define _NIL(var) (if !(isNil STR(var)) then {var})
#define NIL_DEF _NIL(_def)
#define MGVAR missionNamespace getVariable
#define CHECK_EX(c) if (c) exitWith {false};
#define LOC localize
#define SKIP continue
#define ONUL objNull
#define EW exitWith
#define EX EW {};
#define EQTYPE isEqualType
#define EQTO isEqualTo
#define ISNIL(v) isNil STR(v)
#define MAP(v) v = v apply 
#define IF_(c, t) if (c) then {t}
#define IF_ELSE(c, t, t1) if (c) then {t} else {t1}
#define IF_EX(c) if (c) exitWith {}
#define IF_EXW(c, t) if (c) exitWith {t}
#define IF_ELSE_EX(c, t, t1) if (c) exitWith {t} else {t1}
#define IF_NIL_EX(v) if (ISNIL(v)) EX;
#define IF_NIL(v, d) IF_ELSE(ISNIL(v), d, v)
#define NIL_(v) IF_NIL(v, nil)
#define SET_IF_NIL(v, d) IF_ELSE(ISNIL(v), v = d, v)
#define IS_OBJNULL(o) (o isEqualTo objNull)
#define IS_OBJNULL_DEF(o) IF_ELSE(IS_OBJ(o), o, objNull)
#define IS_BOOL(s) (s isEqualType true)
#define IS_LOCAL(o) (IS_OBJ(o) && {local o})
#define STR_EMPTY(s) (s isEqualTo "")
#define ARR_EMPTY(a) (a isEqualTo [])
#define LWR(s) (toLower s)
#define FOR_I(n) for "_i" from 0 to (n - 1) do

#define ARGS PR _args = 

#define ABSOLUTE_RANDOM_NUM (round (((random 2) * 100000) + (systemTimeUTC select -1)))

#define CLEAR_SYMBOLS(s) ((s) call {PR _s = toArray _this; PR _n = count _s; PR _r = []; PR _f = true; for "_i" from 0 to (_n - 1) do {PR _c = _s select _i; if (((_c >= 48) && (_c <= 57)) || ((_c >= 65) && (_c <= 90)) || ((_c >= 97) && (_c <= 122))) then {if (_f && (_c >= 48) && (_c <= 57)) then {} else {_r pushBack _c}; _f = false;}}; toString _r})
#define HASHVAL_(v) CLEAR_SYMBOLS(hashValue v)
#define UNQ_HASHVAL(v1, v2) (HASHVAL_(v1) + HASHVAL_(v2))
#define OBJ_HASHVAL(o) UNQ_HASHVAL(o, typeOf o)


// for handling scripts
#define THIS_FUNC_NAME ((__FILE_SHORT__ splitString "_") select -1)
#define SCR_HNDLR(s) DOUBLE(s,_scriptHandler)
#define SCR_HNDLR_UNQ(s) (format["%1_%2_%3", s, "scriptHandler", HASHVAL_(_this)])
#define SCR_HNDLR_VAR(s) (MGVAR [STR(SCR_HNDLR(s)), scriptNull])
#define SCR_HNDLR_VAR_UNQ(s) (MGVAR [SCR_HNDLR_UNQ(s), scriptNull])
#define SPAWN_F_ONCE(f) call (if (scriptDone SCR_HNDLR_VAR(f)) then {{SCR_HNDLR(f) = _this spawn f;}} else {{}});

#define ENSURE_SPAWN_ONCE_UNQ  \
    if !(scriptDone SCR_HNDLR_VAR_UNQ(THIS_FUNC_NAME)) EW {};  \
    MSVAR [SCR_HNDLR_UNQ(THIS_FUNC_NAME), _thisScript]; \

#define ENSURE_SPAWN_ONCE_UNQ_GLOBAL  \
    if !(scriptDone SCR_HNDLR_VAR_UNQ(THIS_FUNC_NAME)) EW {};  \
    MSVAR [SCR_HNDLR_UNQ(THIS_FUNC_NAME), _thisScript, true]; \

#define ENSURE_SPAWN_ONCE_START PR _codeForSpawnOnce = {
#define ENSURE_SPAWN_ONCE_END }; \
    PR _spawnOnceArgs = [_this, _codeForSpawnOnce]; \
    PR _codeHash = HASHVAL_(_spawnOnceArgs); \
    _spawnOnceArgs call ( \
        if (scriptDone (MGVAR [_codeHash, scriptNull])) then { \
            {PR _hndl = (_this select 0) spawn (_this select 1); MSVAR [_codeHash, _hndl]} \
        } else {{}} \
    ); \

#define SPAWN_NWAIT(c) PR _thndl = [] spawn c; waitUntil {scriptDone _thndl}; _thndl = nil;
#define SPAWNF_NWAIT(a, f) PR _thndl = a spawn f; waitUntil {scriptDone _thndl}; _thndl = nil;
#define WAIT_THIS_SCRIPT \
    waitUntil { scriptDone (missionNamespace getVariable ["TEMP_TEMP_HNDL_" + THIS_FUNC_NAME, scriptNull]) }; \
	missionNamespace setVariable ["TEMP_TEMP_HNDL_" + THIS_FUNC_NAME, _thisScript];

#define WAIT_SCRIPT_END(script) \
    waitUntil { scriptDone (missionNamespace getVariable ["TEMP_TEMP_HNDL_" + #script, scriptNull]) }; \
	missionNamespace setVariable ["TEMP_TEMP_HNDL_" + #script, _thisScript];

#define WAITVAR(v) waitUntil { !ISNIL(v) };
#define WAITSVAR(v) waitUntil { !isNil v };
#define WAITVAR_OR_EX_T(v, t) _thisScript spawn {sleep t; terminate _this}; WAITVAR(v)
#define WAITVAR_OR_EX(v) WAITVAR_OR_EX_T(v, 0.5)
#define ONLY_SPAWN(fnc) \
if (!canSuspend) EW { \
    _this spawn fnc; \
}; \

#define WAIT_A_BIT_T(code, t) private _tempWaitABitStartTime = time; \
waitUntil { (code) || ((time - _tempWaitABitStartTime) > t) }; \

#define WAIT_A_BIT(code) WAIT_A_BIT_T(code, 1)

#define FILE_ONLY_SPAWN ONLY_SPAWN(QFUNC(THIS_FUNC_NAME))

// for server execuiton
#define REMOTE_CALL_FUNC "call"
#define EXEC_ON_SERVER_START PR _codeForServer = {
#define EXEC_ON_SERVER_END }; if (isServer) then {_this call _codeForServer} else {[[_this], _codeForServer] remoteExec [REMOTE_CALL_FUNC, 2]};
#define EXEC_ON_SERVER_END_RESULT }; \
PR _serverExecResult = if (isServer) then { \
	_this call _codeForServer \
} else { \
    private _tempVarName = format ["TEMP_remoteExec_result_%1", ABSOLUTE_RANDOM_NUM]; \
    [[_this, clientOwner, _tempVarName], _codeForServer] remoteExec [REMOTE_CALL_FUNC, 2]; \
    WAITSVAR(_tempVarName); \
    MGVAR _tempVarName; \
}; \
_serverExecResult; \

#define EXEC_ON_SERVER_END_RESULT_VAR(var) EXEC_ON_SERVER_END_RESULT; var = _serverExecResult;

#define GET_SERVER_VAL \
    EXEC_ON_SERVER_START \

#define GSRES(var) \
    EXEC_ON_SERVER_END_RESULT_VAR(var) \

#define OBJ_OWNER(o) IF_ELSE(owner o == 0, 2, owner o)


#define BOOL(i) (IF_ELSE(IS_INT(i), i == 1, nil))
#define BOOL_TO_INT(b) (if (b) then {1} else {0})
#define SET_BOOL(b) (if (IS_BOOL(b)) then {b} else {0})


#define PLAYER_ (MGVAR ['bis_fnc_moduleremotecontrol_unit', player])
// #define PLAYER_ player
#define PLAYER_STR STR(PLAYER_)

#define RLOG call {_txt = text format["[RLOG]  %3%4 :: %2 :: %1", _this, serverTime, __FILE_SHORT__, if !(isNil "_ooMember") then {format[".%1", _ooMember]} else {""}]; hint _txt; diag_log _txt};
#define DLOG call {_txt = text format["[DLOG]  %3%4 :: %2 :: %1", _this, serverTime, __FILE_SHORT__, if !(isNil "_ooMember") then {format[".%1", _ooMember]} else {""}]; diag_log _txt};
#define VARS_STR call {if !(_this isEqualType []) then {_this = ["", _this]}; params["_txt", ["_varstr", ""]]; if (_varstr isEqualTo "") then {_varstr = _txt}; private _ar = _varstr splitString ",;. "; private _arvs = _ar apply {private _val = call compile format["if !(isNil '%1') then {%1}", _x]; if (isNil "_val") then {""} else {format["%1: %2", _x, _val]}}; _txt + "  :  " + (_arvs joinString "; ")}
#define LOG_VARS ;
#define RLOG_VARS VARS_STR RLOG
#define LOGH hintSilent str
#define HINT hint
#define CLEAR_HINT hint "";
#define _HINT call {hint _this};
#define WARN DLOG
#define LOG_VARS(txt, vars) LOGH ([txt, vars] VARS_STR);
#define ALOG_V T_LOG
#define ALOG call {private _arr = (if (isNil STR(ALOG_V)) then {ALOG_V = []; ALOG_V} else {ALOG_V}); _arr pushback [diag_tickTime, count _arr, _this]};
#define ARLOG call {ALOG; _this RLOG};
