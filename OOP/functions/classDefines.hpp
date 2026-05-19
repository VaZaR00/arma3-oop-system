#define PREFIX_VAR private _ADDON_PREFX = SPREFX;


#define OBJCLASS(name) call { \
    private _fields = []; \
    private _classname = STR(name); \
    private _methods = []; \
    private _selfVar = ""; \
    private _isSignleton = false; \
    PREFIX_VAR \


#define FIELD _fields pushBack


#define VOLATILE _fields pushBack true; FIELD


#define IS_SINGLETON _isSignleton = true;


#define SET_SELF_VAR(name) _selfVar = name;


#define METHOD(name) \
    _methods pushBack name; _methods pushBack 


#define OBJCLASS_END \
    [_classname, _fields, _methods, _selfVar, _isSignleton] call OOP_fnc_class }; \


// Singleton calls
#define CALL_OBJCLASS(name, obj) call { \
    PREFIX_VAR \
    _this params ["_method", ["_args", []], ["_def", nil]]; \
    [name, obj, _method, _args, NIL_DEF, _ADDON_PREFX] call OOP_OBJ_CLASS_fnc_callClassInstance; \
} \


#define SPAWN_OBJCLASS(name, obj) call { \
    PREFIX_VAR \
    _this params ["_method", ["_args", []], ["_def", nil]]; \
    [name, obj, _method, _args, NIL_DEF, _ADDON_PREFX] spawn OOP_OBJ_CLASS_fnc_callClassInstance; \
} \


#define REMOTE_EXEC_OBJCLASS(name, obj) call { \
    PREFIX_VAR \
    _this params ["_method", ["_args", []], ["_remoteExecParams", false], ["_def", nil]]; \
    [[name, obj, _method, _args, NIL_DEF, _ADDON_PREFX], _remoteExecParams] call OOP_OBJ_CLASS_fnc_remoteExecClassInstance; \
} \


// non singleton calls
#define CALL_OBJINSTANCE(name, index, obj) call { \
    PREFIX_VAR \
    _this params ["_method", ["_args", []], ["_def", nil]]; \
    [[name, index], obj, _method, _args, NIL_DEF, _ADDON_PREFX] call OOP_OBJ_CLASS_fnc_callClassInstance; \
} \


#define SPAWN_OBJINSTANCE(name, index, obj) call { \
    PREFIX_VAR \
    _this params ["_method", ["_args", []], ["_def", nil]]; \
    [[name, index], obj, _method, _args, NIL_DEF, _ADDON_PREFX] spawn OOP_OBJ_CLASS_fnc_callClassInstance; \
} \


#define REMOTE_EXEC_OBJINSTANCE(name, index, obj) call { \
    PREFIX_VAR \
    _this params ["_method", ["_args", []], ["_remoteExecParams", false], ["_def", nil]]; \
    [[[name, index], obj, _method, _args, NIL_DEF, _ADDON_PREFX], _remoteExecParams] call OOP_OBJ_CLASS_fnc_remoteExecClassInstance; \
} \


#define NEW_OBJINSTANCE_GLOBAL(name, global) call { \
	if (isNil "_this") exitWith {objNull}; \
    PREFIX_VAR \
	if !(_this isEqualType []) then {_this = [_this]}; \
	_this params [["_obj", objNull], ["_initArgs", []], ["_def", nil]]; \
    [name, _obj, _initArgs, global, NIL_DEF, _ADDON_PREFX] call OOP_OBJ_CLASS_fnc_newInstance; \
} \


#define SPAWN_NEW_OBJINSTANCE_GLOBAL(name, global) call { \
	if (isNil "_this") exitWith {objNull}; \
    PREFIX_VAR \
	if !(_this isEqualType []) then {_this = [_this]}; \
	_this params [["_obj", objNull], ["_initArgs", []], ["_def", nil]]; \
    [name, _obj, _initArgs, global, NIL_DEF, _ADDON_PREFX] spawn OOP_OBJ_CLASS_fnc_newInstance; \
} \


#define NEW_OBJINSTANCE(name) NEW_OBJINSTANCE_GLOBAL(name, false)
#define SPAWN_NEW_OBJINSTANCE(name) SPAWN_NEW_OBJINSTANCE_GLOBAL(name, false)

#define SVAR_NAME(name) (if (_isSingleton) then {name} else {format["%1_%2", name, _instanceIndex]})
#define VAR_NAME(name) SVAR_NAME(STR(name))

#define GLOBAL_SETTER _oopSetVarGlobal = true;
#define LOCAL_SETTER _oopSetVarGlobal = false;
#define SET_SELFVART(name, target) _self setVariable [SPREFX + VAR_NAME(name), name, target];
#define SET_SELFVAR(name) SET_SELFVART(name, _oopSetVarGlobal)
#define SET_SELFVARG(name) SET_SELFVART(name, true)
#define SET_SELFSVART(name, target) _self setVariable [SPREFX + SVAR_NAME(name), call compile name, target];
#define SET_SELFSVAR(name) SET_SELFSVART(name, _oopSetVarGlobal)
#define SET_SELFSVARG(name) SET_SELFVART(name, true)

#define GET_SELFVAR(name) (_self getVariable [_ADDON_PREFX + STR(name), name])
#define SELFVAR(name) name = GET_SELFVAR(name); name

#define IVAR(instance, name, def) private name = instance getVariable [_ADDON_PREFX + STR(name), def];


#define SAVE_VARS _oopSaveVars = true;
#define DONT_SAVE_VARS _oopSaveVars = false;
#define SAVE_VARS_DEF _oopSaveVars = 0;

#define SAVE_VAR(name) _oopToSaveVars set [STR(name), true];
#define DONT_SAVE_VAR(name) _oopToSaveVars set [STR(name), nil];
#define SAVE_VAR_TARGET(name, target) _oopToSaveVarsParams set [STR(name), target];
#define SAVE_VAR_GLOBAL(name) SAVE_VAR_TARGET(name, true)
#define SAVE_VAR_LOCAL(name) SAVE_VAR_TARGET(name, false)
#define SAVE_VAR_DEF(name) SAVE_VAR_TARGET(name, nil)


#define NP_PARAMS call {_paramsMap = _this}; private (_paramsMap apply {if (_x isEqualType []) then {_x#0} else {_x}}); _paramsMap call OOP_fnc_nonPrivateParams;