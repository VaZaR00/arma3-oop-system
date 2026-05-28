#include "defines.hpp" 



#define INIT "Init"



// EXCEPTIONS
#define EXCEPTION(code) ([code, _NIL(_this), _NIL(_className), _NIL(_class), NIL_DEF] call OOP_fnc_raiseException)

#define EXCEPTION_CLASS_DONT_EXISTS 0
#define EXCEPTION_NON_OBJ 1
#define EXCEPTION_NO_CLASSNAME 2
#define EXCEPTION_NO_FIELDS 3
#define EXCEPTION_NO_METHODS 4
#define EXCEPTION_METHOD_DONT_EXISTS 5
#define EXCEPTION_METHOD_FUNC_DONT_EXISTS 6
#define EXCEPTION_SELF_VAR_NOT_STRING 7

#define NIL_DEF _NIL(_def)

OOP_fnc_class = {
    params ["_className", "_fields", "_methods", ["_selfVar", ""], ["_isSignleton", true], ["_varsPrefix", ""]];

    private _prefix = if (isNil "_ADDON_PREFX") then {SPREFX} else {_ADDON_PREFX};
    private _classRegistryName = [_className] call OOP_fnc_classRegistryName;

    private _fieldsCompiled = [];
    private _isVolatile = false;
    {
        if (_x isEqualTo true) then {
            // next var is volatile
            _isVolatile = true;
            continue
        };
        if !(_x isEqualType []) then {continue};
        private _fieldName = _x select 0;
        private _fieldDef = _x select 1;
        if ((_fieldDef isEqualType []) || {(_fieldDef isEqualType createHashMap)}) then {
            _fieldDef = +_fieldDef;
        };
        private _fieldType = _x select 2;
        _fieldType = if (isNil "_fieldType") then {
            if (_isVolatile) then {[]} else {
                if (_fieldDef isEqualType []) then {
                    [[]]
                } else {
                    _fieldDef
                };
            };
        } else {_fieldType};
        private _fieldNameFull = format["%1%2%3", _prefix, _varsPrefix, _fieldName];
        _fieldsCompiled pushBack [_fieldName, [_fieldNameFull, _fieldDef, _fieldType]];
        _isVolatile = false;
    } forEach _fields;

    private _fieldsMap = createHashMapFromArray _fieldsCompiled;

    private _methodsCompiled = [];
    private _skipI = [];
    for "_i" from 0 to ((count _methods) - 1) do {
        if (_i in _skipI) then {continue};
        private _methodName = _methods select _i;
        private _method = _methods select (_i + 1);
        _skipI pushBack (_i + 1);
		private _methodStr = str _method;
        private _methodSelfFields = _fieldsCompiled select {(_x#0) in _methodStr};
		private _methodNameFull = format["%1_%2", _classRegistryName, _methodName];
        missionNamespace setVariable [_methodNameFull, _method];
        _methodsCompiled pushBack [_methodName, [_methodNameFull, _method, _methodSelfFields]];
    };

    private _methodsMap = createHashMapFromArray _methodsCompiled;

    private _classMap = createHashMap;
    _classMap set ["fields", _fieldsMap];
    _classMap set ["methods", _methodsMap];
    _classMap set ["classname", _classRegistryName];

	private _selfVar = if (!(_selfVar isEqualType "") || {(_selfVar isEqualTo "")}) then {"_self"} else {_selfVar};
    _classMap set ["selfvar", _selfVar];
    _classMap set ["varsPrefix", _varsPrefix];

    _classMap set ["isSignleton", _isSignleton];

    missionNamespace setVariable [_classRegistryName, _classMap];
    _classMap
};

OOP_OBJ_CLASS_fnc_newInstance = {
    params ["_className", "_obj", ["_initArgs", []], ["_global", false], ["_def", nil], ["_ADDON_PREFX", IF_NIL(_ADDON_PREFX, nil)]];

    if !(IS_OBJ(_obj)) exitWith {
        // EXCEPTION(EXCEPTION_NON_OBJ)
    };

    private _class = [_className] call OOP_fnc_classExists;

	if (_class isEqualTo false) exitWith {EXCEPTION(EXCEPTION_CLASS_DONT_EXISTS)};

    private _classRegistryName = _class getOrDefaultCall ["classname", {EXCEPTION(EXCEPTION_NO_CLASSNAME); ""}];
    private _isSignleton = _class getOrDefault ["isSignleton", true];
    
    private _instanceName = _classRegistryName;
    private _classSet = false;
    private _instanceId = -1;
    if !(_isSignleton) then {
        private _classInstancesIdsVarName = format["OOP_OBJ_CLASS_%1_InstanceIds", _classRegistryName];
        _classIds = +(_obj getVariable [_classInstancesIdsVarName, []]);
        _classSet = _classIds isNotEqualTo [];
        _instanceId = (_classIds param [((count _classIds) -1) max 0, 0]) + 1;
        _instanceName = INSTANCE_NAME(_classRegistryName, _instanceId);
        [_obj, _classInstancesIdsVarName, _instanceId, true, _global, _global] call OOP_fnc_pushBackNet;
    };
    [_obj, "OOP_OBJ_CLASS_objClassInstancesClasses", _instanceName, true, _global, _global] call OOP_fnc_pushBackNet;

    if !(_classSet) then {
        private _methods = _class getOrDefaultCall ["methods", {EXCEPTION(EXCEPTION_NO_METHODS); createHashMap}];
        {
            // _y = [_methodVarNameFull, _methodScript, _methodSelfFields]
            // for network optimisation we set only method variable name (_y select 2) not full script
            _obj setVariable [format["%1_%2", _classRegistryName, _x], [_y select 0, _y select 2], _global];
        } forEach _methods;

        private _selfVar = _class getOrDefault ["selfvar", "_self"];
        _selfVar = if (!(_selfVar isEqualType "") || {(_selfVar isEqualTo "")}) then {"_self"} else {_selfVar};
        _obj setVariable [format["%1_selfVar", _classRegistryName], _selfVar, _global];

        private _varsPrefix = _class getOrDefault ["varsPrefix", ""];
        _obj setVariable [format["%1_varsPrefix", _classRegistryName], _varsPrefix, _global];

        _obj setVariable [format["%1_classMap", _classRegistryName], _class, _global];
    };

    private _initResult = [[_className, _instanceId], _obj, INIT, _initArgs, NIL_DEF] call OOP_OBJ_CLASS_fnc_callClassInstance;
    if (isNil "_initResult") then {[_instanceId, NIL_DEF]} else {[_instanceId, _initResult]};
};

OOP_OBJ_CLASS_fnc_callClassInstance = {
	params["_instance", "_obj", ["_methodName", INIT], ["_thisArgs", []], ["_def", nil], ["_ADDON_PREFX", IF_NIL(_ADDON_PREFX, nil)]];

    _instance params ["_className", ["_instanceIndex", -1]];

    private _isSingleton = _instanceIndex < 0;

    if !(IS_OBJ(_obj)) exitWith {
        // EXCEPTION(EXCEPTION_NON_OBJ)
    };

    private _classRegistryName = [_className] call OOP_fnc_classRegistryName;
	private _methodParams = _obj getVariable format["%1_%2", _classRegistryName, _methodName];
	if (isNil "_methodParams") exitWith {
		EXCEPTION(EXCEPTION_METHOD_DONT_EXISTS)
	};
	private _methodVarName = _methodParams param [0, "", [""]];
	private _method = missionNamespace getVariable [_methodVarName, {EXCEPTION(EXCEPTION_METHOD_FUNC_DONT_EXISTS)}];
	private _methodSelfFields = _methodParams param [1, [], [[], ""]];
	if !(_methodSelfFields isEqualType []) then {_methodSelfFields = []};
	_methodSelfFields = _methodSelfFields select {(_x#0) isEqualType ""};

    private _methodSelfFieldsVars = (_methodSelfFields apply {_x#0});
    private _methodSelfPrivateFieldsVars = _methodSelfFieldsVars select {isNil _x};
    if (_methodSelfPrivateFieldsVars isEqualTo []) then {_methodSelfPrivateFieldsVars = ["_tempp"]};
	private _methodSelfPrivateFieldsVars;
	{
		_x params [["_fieldName", ""], ["_fieldParams", []]];
		if (_fieldName isEqualTo "") then {continue};
		if !(_fieldName in _methodSelfPrivateFieldsVars) then {continue};
		_fieldParams params [["_fieldNameFull", ""], ["_fieldDef", nil], ["_fieldType", []]];
        _fieldNameFull = if (_isSingleton) then {_fieldNameFull} else {format["%1_%2", _fieldNameFull, _instanceIndex]};
		call compile (format["%1 = _obj getVariable ['%2', _fieldDef]; %1 = [if (isNil '%1') then {nil} else {%1}, _fieldType, _fieldDef] call OOP_fnc_validateFieldType", _fieldName, _fieldNameFull]);
	} forEach _methodSelfFields;

	private _varsPrefix = _obj getVariable [format["%1_varsPrefix", _classRegistryName], ""];
	private _selfVar = _obj getVariable [format["%1_selfVar", _classRegistryName], "_self"];
	if !(_selfVar isEqualType "") then {
		_selfVar = "_self";
		EXCEPTION(EXCEPTION_SELF_VAR_NOT_STRING)
	};
	private [_selfVar];
	private _self = _obj;
	call compile (format["%1 = _obj", _selfVar]);

    // class middleware variables
    private _paramsMap = [];
    private _thisMethod = _method;
    private _oopSetVarGlobal = false;
    private _oopSaveVars = false; // dont save vars by def
    private _oopToSaveVars = createHashMap;
    private _oopToSaveVarsParams = createHashMap;

    // call method
    _this = _thisArgs;
    private _result = _thisArgs call _method;

    // class middleware
    // saving vars
    if !(_oopSaveVars isEqualTo false) then {
        if !(_methodSelfFields isEqualTo []) then {
            private ["_target"];
            {
                _target = _oopToSaveVarsParams getOrDefault [_x, _oopSetVarGlobal];
                SET_SELFSVART(_x, _target);
            } forEach (if (_oopSaveVars isEqualTo true) then {_methodSelfFieldsVars} else {_oopToSaveVars});
        };
    };

    _NIL(_result)
};

OOP_OBJ_CLASS_fnc_remoteExecClassInstance = {
	params[["_callArgs", []], ["_remoteExecParams", false]];

    if (_remoteExecParams isEqualTo false) exitWith {
        _callArgs call OOP_OBJ_CLASS_fnc_callClassInstance;
    };

    private _jip = false;
    if (_remoteExecParams isEqualTo true) then {
        _jip = true;
    };
    if !(_remoteExecParams isEqualType []) then {
        _remoteExecParams = [_remoteExecParams];
    };
    _remoteExecParams params [["_targets", 0], ["_jip", _jip], ["_call", false, [false]]];
    [_callArgs, {
        _this call OOP_OBJ_CLASS_fnc_callClassInstance;
    }, _targets, _jip, _call] call OOP_fnc_remoteExec;
};

OOP_fnc_validateFieldType = {
	params["_var", ["_types", []], ["_def", nil]];
	if (isNil "_var") exitWith {nil};
	if (_types isEqualTo []) exitWith {_var};
	if !(_types isEqualType []) then {_types = [_types]};
	private _valid = false;
	{
		if (_var isEqualType _x) exitWith {_valid = true};
	} forEach _types;
	if !(_valid) exitWith {NIL_DEF};
	_var
};

OOP_fnc_classRegistryName = {
	params["_className"];
    private _prefix = VAR_PREFIX;
	_prefix = if (_prefix == "") then {_prefix} else {_prefix + "_"};
    format["OOP_OBJ_CLASS_%1%2", _prefix, _className];
};

OOP_fnc_classExists = {
	params["_classname"];
    private _classRegistryName = [_className] call OOP_fnc_classRegistryName;
	private _class = missionNamespace getVariable _classRegistryName;
	if (isNil "_class") exitWith {false};
	if !(_class isEqualType createHashMap) exitWith {false};
	private _classParam = _class get "classname";
	if (isNil "_classParam") exitWith {false};
	_class
};

OOP_fnc_raiseException = {
    params [["_id", -1], ["_this", nil], ["_className", nil], ["_class", nil], ["_def", nil]];
    private _log = switch (_id) do {
        case EXCEPTION_METHOD_DONT_EXISTS: {
            _this + [_NIL(_classRegistryName), _NIL(_methodName), _NIL(_instanceIndex)]
        };
        case EXCEPTION_METHOD_FUNC_DONT_EXISTS: { };
        case EXCEPTION_SELF_VAR_NOT_STRING: { };
        default { };
    };
    if (isNil "_log") then {
        _log = [_id, _this];
    };
	format["OOP EXCEPTION: %1", _log] DLOG;
	_id
};

OOP_fnc_remoteExec = {
    _this call EFL_fnc_remoteExec;
};

OOP_fnc_nonPrivateParams = {
    {
        _x params ["_name", ["_def", nil]];
        call compile (format["%1 = _thisArgs param [%2, if !(isNil '_def') then {_def}]", _name, _forEachIndex]);
    } forEach _this;
};

OOP_fnc_pushBackGlobal = {
    _this call EFL_fnc_pushBackGlobal;
};

OOP_fnc_pushBackNet = {
    _this call EFL_fnc_pushBackNet;
};

OOP_OBJ_CLASS_fnc_setVar = {
    params["_self", "_className", "_name", ["_val", nil], ["_target", false], ["_instanceID", IF_NIL(_instanceIndex, -1)], ["_ADDON_PREFX", IF_NIL(_ADDON_PREFX, nil)]];
    private _classRegistryName = [_className] call OOP_fnc_classRegistryName;
	private _varsPrefix = _self getVariable [format["%1_varsPrefix", _classRegistryName], ""];
    _self setVariable [VAR_NAME, _NIL(_val), _target];
};

OOP_OBJ_CLASS_fnc_getVar = {
    params["_self", "_className", "_name", ["_def", nil], ["_instanceID", IF_NIL(_instanceIndex, -1)], ["_ADDON_PREFX", IF_NIL(_ADDON_PREFX, nil)]];

    private _classRegistryName = [_className] call OOP_fnc_classRegistryName;
	private _varsPrefix = _self getVariable [format["%1_varsPrefix", _classRegistryName], ""];
    _self getVariable [VAR_NAME, _NIL(_def)];
};
