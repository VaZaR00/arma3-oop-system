// Minimal self-contained fallback macros so consumer addons can include classDefines.hpp standalone
#ifndef STR
#define STR(s) #s
#endif
#ifndef I
#define I ,
#endif
#ifndef SPREFX
#define SPREFX STR(PREFX)
#endif
#ifndef VAR_PREFIX
#define VAR_PREFIX (if (isNil "_ADDON_PREFX") then {SPREFX} else {_ADDON_PREFX})
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

#define OOP_FUNC(f) OOP_PREFX##_fnc_##f
#define OOP_PREF(s) OOP_PREFX##_##s
#define OOP_SPREF(s) STR(OOP_PREF(s))


#define PREFIX_VAR private _ADDON_PREFX = SPREFX;


#define CLASS(name) call { \
    params [["_isSingleton", false]]; \
    private _classname = STR(name); \
    PREFIX_VAR \
    private _oopCachedClass = [_classname] call OOP_FUNC(restoreCachedClass); \
    if !(_oopCachedClass isEqualTo false) exitWith {_oopCachedClass}; \
    private _fields = []; \
    private _methods = []; \
    private _selfNamespaceVar = ""; \
    private _varsPrefix = ""; \
    _isSingleton = if (_isSingleton isEqualType false) then {_isSingleton} else {false};


#define SINGLETON_CLASS(name) true CLASS(name)


#define FIELD _fields pushBack


/*
    Access Level Indicators
    For semantic purposes, these are defined but do not have any effect on the code.
    They are used to indicate the intended access level and locality of fields and methods in the class definition.
*/
#define PUBLIC
/*
    Public Access

    Method: This Method is public and can be used in framework
    Field: This Field is public and can be used in framework
    Class: Fields and methods by default Public but can have own Access Level
*/

#define PRIVATE
/*
    Private Access

    Method: This Method is internal only
    Field: This Field is internal only, Read Only
    Class: This Class is internal only
*/

#define LOCAL
/*
    Method: This Method is fully local (executed only local, has only local effect)
     - if GE: this Method has Global Effect and should be executed only on one machine at a time.
    Field: This Field IS NOT Synced between clients
    Class: This Class has no methods and fields with global effect
*/

#define GLOBAL
/*
    Method: This Method should be executed Globally on all clients at a time.
    Field: This Field IS Synced between clients
    Class: Fields and methods by default Global but can have own effect scope
*/

#define SERVER
/*
    Method: This Method should be executed ONLY on Server (same as SE)
*/

#define LE
    // Local Effect

#define SE
    // Server Execution Only

#define GE
    // Global Effect

#define LA
    // Local Argument

#define GA
    // Global Argument


#define VOLATILE _fields pushBack true; FIELD


#define IS_SINGLETON _isSingleton = true;


#define SET_SELF_VAR(name) _selfNamespaceVar = name;


#define SET_VARS_PREFIX(prefix) _varsPrefix = prefix;


#define METHOD(name) \
    _methods pushBack name; _methods pushBack


#define CLASS_END \
    [_classname, _fields, _methods, _selfNamespaceVar, _isSingleton, _varsPrefix] call OOP_FUNC(class) };


// Singleton calls
#define CALL_OBJCLASS(name, obj) call { \
    PREFIX_VAR \
    _this params [["_method", ""], ["_args", nil], ["_def", nil]]; \
    [[name], obj, _method, _NIL(_args), NIL_DEF, _ADDON_PREFX] call OOP_FUNC(callClassInstance) \
}


#define SPAWN_OBJCLASS(name, obj) call { \
    PREFIX_VAR \
    _this params [["_method", ""], ["_args", nil], ["_def", nil]]; \
    [[name], obj, _method, _NIL(_args), NIL_DEF, _ADDON_PREFX] spawn OOP_FUNC(callClassInstance) \
}


#define REMOTE_EXEC_OBJCLASS(name, obj) call { \
    PREFIX_VAR \
    _this params [["_method", ""], ["_args", nil], ["_remoteExecParams", false], ["_def", nil]]; \
    [[[name], obj, _method, _NIL(_args), NIL_DEF, _ADDON_PREFX], _remoteExecParams] call OOP_FUNC(remoteExecClassInstance) \
}


// Multi-instance calls
#define CALL_OBJINSTANCE(name, index, obj) call { \
    PREFIX_VAR \
    _this params [["_method", ""], ["_args", nil], ["_def", nil]]; \
    [[name, index], obj, _method, _NIL(_args), NIL_DEF, _ADDON_PREFX] call OOP_FUNC(callClassInstance) \
}


#define SPAWN_OBJINSTANCE(name, index, obj) call { \
    PREFIX_VAR \
    _this params [["_method", ""], ["_args", nil], ["_def", nil]]; \
    [[name, index], obj, _method, _NIL(_args), NIL_DEF, _ADDON_PREFX] spawn OOP_FUNC(callClassInstance) \
}


#define REMOTE_EXEC_OBJINSTANCE(name, index, obj) call { \
    PREFIX_VAR \
    _this params [["_method", ""], ["_args", nil], ["_remoteExecParams", false], ["_def", nil]]; \
    [[[name, index], obj, _method, _NIL(_args), NIL_DEF, _ADDON_PREFX], _remoteExecParams] call OOP_FUNC(remoteExecClassInstance) \
}


// Instantiation
#define NEW_OBJINSTANCE_GLOBAL(name, global) call { \
    PREFIX_VAR \
    IF_NIL(_this, []) params [["_np", missionNamespace], ["_initArgs", []], ["_def", nil], ["_globalNamespace", missionNamespace]]; \
    [name, _NIL(_np), _initArgs, global, NIL_DEF, _ADDON_PREFX, _globalNamespace] call OOP_FUNC(newInstance) \
}

#define SPAWN_NEW_OBJINSTANCE_GLOBAL(name, global) spawn {_NIL(_this) NEW_OBJINSTANCE_GLOBAL(name, global)}

#define NEW_OBJINSTANCE(name) NEW_OBJINSTANCE_GLOBAL(name, false)
#define SPAWN_NEW_OBJINSTANCE(name) SPAWN_NEW_OBJINSTANCE_GLOBAL(name, false)


#define NEW_INSTANCE_GLOBAL(name, global) call { \
    IF_NIL(_this, []) params [["_initArgs", []], ["_def", nil]]; \
    _this = [nil, _initArgs, NIL_DEF]; \
    _this NEW_OBJINSTANCE_GLOBAL(name, global) \
}

#define SPAWN_NEW_INSTANCE_GLOBAL(name, global) spawn {_NIL(_this) NEW_INSTANCE_GLOBAL(name, global)}

#define NEW_INSTANCE(name) NEW_INSTANCE_GLOBAL(name, false)
#define SPAWN_NEW_INSTANCE(name) SPAWN_NEW_INSTANCE_GLOBAL(name, false)


// Destruction / Cleanup
#define DELETE_OBJCLASS_GLOBAL(name, obj, global) call { \
    PREFIX_VAR \
    IF_NIL(_this, []) params [["_callDeinit", true], ["_deinitArgs", []]]; \
    [[name], obj, global, _callDeinit, _deinitArgs, _ADDON_PREFX] call OOP_FUNC(deleteInstance) \
}
#define DELETE_OBJCLASS(name, obj) DELETE_OBJCLASS_GLOBAL(name, obj, false)

#define DELETE_OBJINSTANCE_GLOBAL(name, index, obj, global) call { \
    PREFIX_VAR \
    IF_NIL(_this, []) params [["_callDeinit", true], ["_deinitArgs", []]]; \
    [[name, index], obj, global, _callDeinit, _deinitArgs, _ADDON_PREFX] call OOP_FUNC(deleteInstance) \
}
#define DELETE_OBJINSTANCE(name, index, obj) DELETE_OBJINSTANCE_GLOBAL(name, index, obj, false)

#define DELETE_INSTANCE_GLOBAL(name, global) DELETE_OBJCLASS_GLOBAL(name, missionNamespace, global)
#define DELETE_INSTANCE(name) DELETE_OBJCLASS_GLOBAL(name, missionNamespace, false)


// Self & global singleton calls
#define CALL_SELF call { \
    _this params [["_method", ""], ["_args", nil], ["_def", nil]]; \
    [[_className, _instanceIndex], _selfNamespace, _method, _NIL(_args), NIL_DEF, _ADDON_PREFX] call OOP_FUNC(callClassInstance) \
}

#define SPAWN_SELF call { \
    _this params [["_method", ""], ["_args", nil], ["_def", nil]]; \
    [[_className, _instanceIndex], _selfNamespace, _method, _NIL(_args), NIL_DEF, _ADDON_PREFX] spawn OOP_FUNC(callClassInstance) \
}

#define CALL_CLASS(name) call { \
    PREFIX_VAR \
    _this params [["_method", ""], ["_args", nil], ["_def", nil]]; \
    [[name], missionNamespace, _method, _NIL(_args), NIL_DEF, _ADDON_PREFX] call OOP_FUNC(callClassInstance) \
}

#define SPAWN_CLASS(name) call { \
    PREFIX_VAR \
    _this params [["_method", ""], ["_args", nil], ["_def", nil]]; \
    [[name], missionNamespace, _method, _NIL(_args), NIL_DEF, _ADDON_PREFX] spawn OOP_FUNC(callClassInstance) \
}


#define INSTANCE_NAME(name, id) (format["%1_instance_%2", name, id])


// Direct in-method field setters & getters
#define GLOBAL_SETTER _oopSetVarGlobal = true;
#define LOCAL_SETTER _oopSetVarGlobal = false;
#define SET_SELFVART(name, target) _selfNamespace setVariable [_oopFieldPrefix + STR(name) + _oopFieldSuffix, _NIL(name), target];
#define SET_SELFVAR(name) SET_SELFVART(name, _oopSetVarGlobal)
#define SET_SELFVARG(name) SET_SELFVART(name, true)
#define SET_SELFSVART(name, target) _selfNamespace setVariable [_oopFieldPrefix + (name) + _oopFieldSuffix, (if (isNil (name)) then {nil} else {call compile (name)}), target];
#define SET_SELFSVAR(name) SET_SELFSVART(name, _oopSetVarGlobal)
#define SET_SELFSVARG(name) SET_SELFSVART(name, true)

#define GET_SELFVAR(name) (_selfNamespace getVariable [_oopFieldPrefix + (name) + _oopFieldSuffix, nil])
#define SELFVAR(name) name = GET_SELFVAR(STR(name)); name


// External field readers — SINGLETONS
#define SOIVAR(obj,className,name,def) ([obj,className,STR(name),def,-1,VAR_PREFIX] call OOP_FUNC(getVar))
#define PR_SOIVAR_S(obj,className,name,def) private name = SOIVAR(obj,className,name,def);
#define SOIVAR_S(obj,className,name,def) name = SOIVAR(obj,className,name,def);


// External field readers — MULTI-INSTANCE
#define OIVAR(obj,className,name,instanceId,def) ([obj,className,STR(name),def,instanceId,VAR_PREFIX] call OOP_FUNC(getVar))
#define PR_OIVAR_S(obj,className,name,instanceId,def) private name = OIVAR(obj,className,name,instanceId,def);
#define OIVAR_S(obj,className,name,instanceId,def) name = OIVAR(obj,className,name,instanceId,def);


// Batch persistence on method exit
#define SAVE_VARS _oopSaveVars = true;
#define DONT_SAVE_VARS _oopSaveVars = false;
#define SAVE_VARS_DEF _oopSaveVars = 0;

#define SAVE_VAR(name) if (_oopSaveVars isEqualTo false) then {_oopSaveVars = 0}; _oopToSaveVars set [STR(name), true];
#define DONT_SAVE_VAR(name) _oopToSaveVars set [STR(name), false];
#define SAVE_VAR_TARGET(name, target) _oopToSaveVarsParams set [STR(name), target];
#define SAVE_VAR_GLOBAL(name) SAVE_VAR_TARGET(name, true)
#define SAVE_VAR_LOCAL(name) SAVE_VAR_TARGET(name, false)
#define SAVE_VAR_DEF(name) _oopToSaveVarsParams deleteAt STR(name);


// Non-private params (preserves auto-loaded class fields, privatizes temporary params)
#define NP_PARAMS call {_paramsMap = _this}; \
    private _oo_privateVarnames = (_paramsMap apply {if (_x isEqualType []) then {_x select 0} else {_x}}); \
    private _oo_varsToPrivate = _oo_privateVarnames select {isNil _x}; \
    _oo_varsToPrivate = if (_oo_varsToPrivate isEqualTo []) then {["_TEMPPPPP"]} else {_oo_varsToPrivate}; \
    private _oo_varsToPrivate; \
    [_paramsMap, _oo_privateVarnames] call OOP_FUNC(nonPrivateParams);


#define UNUSED_METHOD(name)
