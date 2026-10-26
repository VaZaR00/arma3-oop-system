#define OOP_FUNC(f) OOP_PREFX##_fnc_##f
#define OOP_PREF(s) OOP_PREFX##_##s
#define OOP_SPREF(s) STR(OOP_PREF(s))


#define PREFIX_VAR private _ADDON_PREFX = SPREFX;


#define CLASS(name) call { \
    params[["_isSignleton", false]]; \
    private _fields = []; \
    private _classname = STR(name); \
    private _methods = []; \
    private _selfNamespaceVar = ""; \
    private _varsPrefix = ""; \
    _isSignleton = if (_isSignleton isEqualType false) then {_isSignleton} else {false}; \
    PREFIX_VAR \


#define SINGLETON_CLASS(name) true CLASS(name)


#define FIELD _fields pushBack


#define VOLATILE _fields pushBack true; FIELD


#define IS_SINGLETON _isSignleton = true;


#define SET_SELF_VAR(name) _selfNamespaceVar = name;


#define SET_VARS_PREFIX(prefix) _varsPrefix = prefix;


#define METHOD(name) \
    _methods pushBack name; _methods pushBack 


#define CLASS_END \
    [_classname, _fields, _methods, _selfNamespaceVar, _isSignleton, _varsPrefix] call OOP_FUNC(class) }; \


// Singleton calls
#define CALL_OBJCLASS(name, obj) call { \
    PREFIX_VAR \
    _this params ["_method", ["_args", []], ["_def", nil]]; \
    [[name], obj, _method, _args, NIL_DEF, _ADDON_PREFX] call OOP_FUNC(callClassInstance); \
} \


#define SPAWN_OBJCLASS(name, obj) call { \
    PREFIX_VAR \
    _this params ["_method", ["_args", []], ["_def", nil]]; \
    [[name], obj, _method, _args, NIL_DEF, _ADDON_PREFX] spawn OOP_FUNC(callClassInstance); \
} \


#define REMOTE_EXEC_OBJCLASS(name, obj) call { \
    PREFIX_VAR \
    _this params ["_method", ["_args", []], ["_remoteExecParams", false], ["_def", nil]]; \
    [[[name], obj, _method, _args, NIL_DEF, _ADDON_PREFX], _remoteExecParams] call OOP_FUNC(remoteExecClassInstance); \
} \


// non singleton calls
#define CALL_OBJINSTANCE(name, index, obj) call { \
    PREFIX_VAR \
    _this params ["_method", ["_args", []], ["_def", nil]]; \
    [[name, index], obj, _method, _args, NIL_DEF, _ADDON_PREFX] call OOP_FUNC(callClassInstance); \
} \


#define SPAWN_OBJINSTANCE(name, index, obj) call { \
    PREFIX_VAR \
    _this params ["_method", ["_args", []], ["_def", nil]]; \
    [[name, index], obj, _method, _args, NIL_DEF, _ADDON_PREFX] spawn OOP_FUNC(callClassInstance); \
} \


#define REMOTE_EXEC_OBJINSTANCE(name, index, obj) call { \
    PREFIX_VAR \
    _this params ["_method", ["_args", []], ["_remoteExecParams", false], ["_def", nil]]; \
    [[[name, index], obj, _method, _args, NIL_DEF, _ADDON_PREFX], _remoteExecParams] call OOP_FUNC(remoteExecClassInstance); \
} \


#define NEW_OBJINSTANCE_GLOBAL(name, global) call { \
    PREFIX_VAR \
	IF_NIL(_this, []) params [["_np", missionNamespace], ["_initArgs", []], ["_def", nil], ["_globalNamespace", missionNamespace]]; \
    [name, _NIL(_np), _initArgs, global, NIL_DEF, _ADDON_PREFX, _globalNamespace] call OOP_FUNC(newInstance); \
} \

#define SPAWN_NEW_OBJINSTANCE_GLOBAL(name, global) spawn {_NIL(_this) NEW_OBJINSTANCE_GLOBAL(name, global)};

#define NEW_OBJINSTANCE(name) NEW_OBJINSTANCE_GLOBAL(name, false)
#define SPAWN_NEW_OBJINSTANCE(name) SPAWN_NEW_OBJINSTANCE_GLOBAL(name, false)


#define NEW_INSTANCE_GLOBAL(name, global) call { \
	IF_NIL(_this, []) params [["_initArgs", []], ["_def", nil]]; \
    _this = [nil, _initArgs, NIL_DEF]; \
	_this NEW_OBJINSTANCE_GLOBAL(name, global) \
} \

#define SPAWN_NEW_INSTANCE_GLOBAL(name, global) spawn {_NIL(_this) NEW_INSTANCE_GLOBAL(name, global)};

#define NEW_INSTANCE(name) NEW_INSTANCE_GLOBAL(name, false)
#define SPAWN_NEW_INSTANCE(name) SPAWN_NEW_INSTANCE_GLOBAL(name, false)


#define CALL_SELF call _self;

#define SPAWN_SELF spawn _self;

#define CALL_CLASS(name) call { \
    PREFIX_VAR \
    private _instanceName = [name] call OOP_FUNC(instanceName); \
    _NIL(_this) call (missionNamespace getVariable [_instanceName, {}]); \
} \

#define SPAWN_CLASS(name) spawn {_this CALL_CLASS(name)};


#define INSTANCE_NAME(name, id) (format["%1_instance_%2", name, id])


#define GLOBAL_SETTER _oopSetVarGlobal = true;
#define LOCAL_SETTER _oopSetVarGlobal = false;
#define SET_SELFVART(name, target) [_selfNamespace, _instanceName, STR(name), _NIL(name), target] call OOP_FUNC(setVar);
#define SET_SELFVAR(name) SET_SELFVART(name, _oopSetVarGlobal)
#define SET_SELFVARG(name) SET_SELFVART(name, true)
#define SET_SELFSVART(name, target) [_selfNamespace, _instanceName, name, (call compile name), target] call OOP_FUNC(setVar);
#define SET_SELFSVAR(name) SET_SELFSVART(name, _oopSetVarGlobal)
#define SET_SELFSVARG(name) SET_SELFVART(name, true)

#define GET_SELFVAR(name) ([_selfNamespace, _instanceName, name, nil] call OOP_FUNC(getVar))
#define SELFVAR(name) name = GET_SELFVAR(name); name

// SIGNLETONS
#define SOIVAR(obj,className,name,def) ([obj,className,STR(name),def,-1,VAR_PREFIX] call OOP_FUNC(getVar))
#define PR_SOIVAR_S(obj,className,name,def) private name = SOIVAR(obj,className,name,def);
#define SOIVAR_S(obj,className,name,def) name = SOIVAR(obj,className,name,def);


// NON SIGNLETONS
#define OIVAR(obj,className,name,instanceId,def) ([obj,className,STR(name),def,instanceId,VAR_PREFIX] call OOP_FUNC(getVar))
#define PR_OIVAR_S(obj,className,name,instanceId,def) private name = OIVAR(obj,className,name,instanceId,def);
#define OIVAR_S(obj,className,name,instanceId,def) name = OIVAR(obj,className,name,instanceId,def);


#define SAVE_VARS _oopSaveVars = true;
#define DONT_SAVE_VARS _oopSaveVars = false;
#define SAVE_VARS_DEF _oopSaveVars = 0;

#define SAVE_VAR(name) _oopToSaveVars set [STR(name), true];
#define DONT_SAVE_VAR(name) _oopToSaveVars set [STR(name), nil];
#define SAVE_VAR_TARGET(name, target) _oopToSaveVarsParams set [STR(name), target];
#define SAVE_VAR_GLOBAL(name) SAVE_VAR_TARGET(name, true)
#define SAVE_VAR_LOCAL(name) SAVE_VAR_TARGET(name, false)
#define SAVE_VAR_DEF(name) SAVE_VAR_TARGET(name, nil)


#define NP_PARAMS call {_paramsMap = _this}; \
    private _oo_privateVarnames = (_paramsMap apply {if (_x isEqualType []) then {_x select 0} else {_x}}); \
    private _oo_varsToPrivate = _oo_privateVarnames select {isNil _x}; \
    _oo_varsToPrivate = if (_oo_varsToPrivate isEqualTo []) then {["_TEMPPPPP"]} else {_oo_varsToPrivate}; \
    private _oo_varsToPrivate; \
    _paramsMap call OOP_FUNC(nonPrivateParams);


#define UNUSED_METHOD(name) 