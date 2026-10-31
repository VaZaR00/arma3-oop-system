#include "defines.hpp" 



#define INIT "Init"

#define IS_VALID_SELF_NAMESPACE(np) (np isEqualTypeAny [objNull, missionNamespace, grpNull, locationNull, displayNull, controlNull, teamMemberNull, taskNull])



// EXCEPTIONS
#define EXCEPTION(code) ([code, _NIL(_this), _NIL(_className), _NIL(_class), NIL_DEF] call FUNC(raiseException))

#define EXCEPTION_CLASS_DONT_EXISTS 0
#define EXCEPTION_NON_NAMESPACE 1
#define EXCEPTION_NO_CLASSNAME 2
#define EXCEPTION_NO_FIELDS 3
#define EXCEPTION_NO_METHODS 4
#define EXCEPTION_METHOD_DONT_EXISTS 5
#define EXCEPTION_METHOD_FUNC_DONT_EXISTS 6
#define EXCEPTION_SELF_VAR_NOT_STRING 7

#define OOP_GLOBAL_NAMESPACE missionNamespace

#define NIL_DEF _NIL(_def)

FUNC(class) = {
    params ["_className", "_fields", "_methods", ["_selfNamespaceVar", ""], ["_isSignleton", true], ["_varsPrefix", ""], ["_globalNamespace", missionNamespace]];

    private _prefix = if (isNil "_ADDON_PREFX") then {SPREFX} else {_ADDON_PREFX};
    private _classRegistryName = [_className] call FUNC(classRegistryName);

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
        private _fieldDef = _x param [1, -1];
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
		private _methodStr = toLower (str _method);
        private _methodSelfFields = _fieldsCompiled select {(tolower (_x#0)) in _methodStr};
		private _methodNameFull = format["%1_%2", _classRegistryName, _methodName];
        _globalNamespace setVariable [_methodNameFull, _method];
        _methodsCompiled pushBack [_methodName, [_methodNameFull, _method, _methodSelfFields]];
    };

    private _methodsMap = createHashMapFromArray _methodsCompiled;

    private _classMap = createHashMap;
    _classMap set ["fields", _fieldsMap];
    _classMap set ["methods", _methodsMap];
    _classMap set ["classname", _classRegistryName];

	private _selfNamespaceVar = if (!(_selfNamespaceVar isEqualType "") || {(_selfNamespaceVar isEqualTo "")}) then {"_namespace"} else {_selfNamespaceVar};
    _classMap set ["selfvar", _selfNamespaceVar];
    _classMap set ["varsPrefix", _varsPrefix];

    _classMap set ["isSignleton", _isSignleton];

    _globalNamespace setVariable [_classRegistryName, _classMap];
    _classMap
};

FUNC(newInstance) = {
    private _outerAddonPrefx = IF_NIL(_ADDON_PREFX, nil);
    private _outerGlobalNamespace = IF_NIL(_globalNamespace, missionNamespace);
    params ["_className", ["_namespace", nil], ["_initArgs", []], ["_global", false], ["_def", nil], ["_ADDON_PREFX", _NIL(_outerAddonPrefx)], ["_globalNamespace", _outerGlobalNamespace]];

    ["NEW INST", _this] RLOG

    if (isNil "_namespace") then {
        _namespace = missionNamespace;
    };

    if !(IS_VALID_SELF_NAMESPACE(_namespace)) exitWith {
        EXCEPTION(EXCEPTION_NON_NAMESPACE)
    };

    private _class = [_className] call FUNC(classExists);

	if (_class isEqualTo false) exitWith {EXCEPTION(EXCEPTION_CLASS_DONT_EXISTS)};

    private _classRegistryName = _class getOrDefaultCall ["classname", {EXCEPTION(EXCEPTION_NO_CLASSNAME); ""}];
    private _isSignleton = _class getOrDefault ["isSignleton", true];
    
    private _instanceName = _classRegistryName + "_instance";
    private _instanceId = -1;
    if !(_isSignleton) then {
        private _classInstancesIdsVarName = format[SPREF_ + "class_%1_InstanceIds", _classRegistryName];
        _classIds = +(_namespace getVariable [_classInstancesIdsVarName, []]);
        _instanceId = (_classIds param [((count _classIds) -1) max 0, 0]) + 1;
        _instanceName = INSTANCE_NAME(_classRegistryName, _instanceId);
        [_namespace, _classInstancesIdsVarName, _instanceId, true, _global, _global] call FUNC(pushBackNet);
    };

    private _instance = _namespace getVariable _instanceName;

    if (isNil "_instance") then {
        [_namespace, SPREF_ + "namespaceClassesInstances", _instanceName, true, _global, _global] call FUNC(pushBackNet);

        private _methodsMaps = _class getOrDefaultCall ["methods", {EXCEPTION(EXCEPTION_NO_METHODS); createHashMap}];
        private _methods = keys _methodsMaps;
        {
            // _y = [_methodVarNameFull, _methodScript, _methodSelfFields]
            // for network optimisation we set only method variable name (_y select 2) not full script
            _namespace setVariable [format["%1_%2", _instanceName, _x], [_y select 0, _y select 2], _global];
        } forEach _methodsMaps;

        private _fieldsMap = _class getOrDefaultCall ["fields", {EXCEPTION(EXCEPTION_NO_FIELDS); createHashMap}];
        private _fields = keys _fieldsMap;

        private _selfNamespaceVar = _class getOrDefault ["selfvar", "_namespace"];
        _selfNamespaceVar = if (!(_selfNamespaceVar isEqualType "") || {(_selfNamespaceVar isEqualTo "")}) then {"_namespace"} else {_selfNamespaceVar};
        _namespace setVariable [format["%1_selfNamespaceVar", _instanceName], _selfNamespaceVar, _global];

        private _varsPrefix = _class getOrDefault ["varsPrefix", ""];
        _namespace setVariable [format["%1_varsPrefix", _instanceName], _varsPrefix, _global];

        _namespace setVariable [format["%1_classMap", _instanceName], _class, _global];
        
        // global instance name 
        private _globalId = [_instanceName, _namespace, _globalNamespace, _global] call FUNC(addInstanceGlobal);

        _namespace setVariable [_instanceName + "_namespace", _namespace, _global];
        _namespace setVariable [_instanceName + "_instanceIndex", _instanceId, _global];
        _namespace setVariable [_instanceName + "_className", _className, _global];
        _namespace setVariable [_instanceName + "_classRegistryName", _classRegistryName, _global];
        _namespace setVariable [_instanceName + "_methods", _methods, _global];
        _namespace setVariable [_instanceName + "_fields", _fields, _global];
        _namespace setVariable [_instanceName + "_globalId", _globalId, _global];

        private _globalNamespaceStr = switch (_globalNamespace) do {
            case parsingNamespace: {"parsingNamespace"};
            case uiNamespace: {"uiNamespace"};
            case profileNamespace: {"profileNamespace"};
            default {"missionNamespace"};
        };

        _instance = compile format['
            PREFIX_VAR
            private _instanceName = "%1";
            private _instanceGlobalId = "%2";
            private _instanceIndex = %3;
            private _className = "%4";
            private _ADDON_PREFX = "%5";
            private _namespace = %6 getVariable [_instanceGlobalId + "_namespace", %6];
            private _fields = _namespace getVariable [_instanceName + "_fields", []];
            _this params [["_method", ""], ["_args", nil], ["_def", nil]];
            if (_method in _fields) exitWith {
                [_namespace, _instanceName, _method, _NIL(_args), _instanceIndex, _ADDON_PREFX] call FUNC(getVar);
            };
            [_instanceName, _namespace, _method, _NIL(_args), NIL_DEF, _ADDON_PREFX] call OOP_FUNC(callClassInstance);
        ', _instanceName, _globalId, _instanceId, _className, _ADDON_PREFX, _globalNamespaceStr];

        _globalNamespace setVariable [_globalId, _instance, _global];
        _namespace setVariable [_instanceName, _instance, _global];
    };

    private _initResult = [INIT, _initArgs, NIL_DEF] call _instance;
    if (_isSignleton) exitWith {if (isNil "_initResult") then {NIL_DEF} else {_initResult}};
    if (isNil "_initResult") then {[_instanceId, NIL_DEF]} else {[_instanceId, _initResult]};
};

FUNC(callClassInstance) = {
    private _outerAddonPrefx = IF_NIL(_ADDON_PREFX, nil);
	params["_instanceParams", "_namespace", ["_methodName", INIT], ["_thisArgs", []], ["_def", nil], ["_ADDON_PREFX", _NIL(_outerAddonPrefx)]];

    // for OPTIMIZE remove
    if !(IS_VALID_SELF_NAMESPACE(_namespace)) exitWith {
        // EXCEPTION(EXCEPTION_NON_NAMESPACE)
    };

    // -------------- instance data ---------------
    private _instanceIndex = -1;
    private _isSingleton = true;
    private _className = "";
    private _classRegistryName = "";
    private _instanceName = _instanceParams;

    if (_instanceName isEqualType "") then {
        _instanceIndex = _namespace getVariable [_instanceName + "_instanceIndex", -1];
        _className = _namespace getVariable [_instanceName + "_className", ""];
        _classRegistryName = _namespace getVariable [_instanceName + "_classRegistryName", ""];
        _isSingleton = _instanceIndex < 0;
    } else {
        _instanceParams params ["__className", ["__instanceIndex", -1]];
        _className = __className;
        _instanceIndex = __instanceIndex;
        private __classRegistryName = [_className] call FUNC(classRegistryName);
        _classRegistryName = __classRegistryName;
        _isSingleton = _instanceIndex < 0;
        _instanceName = if (_isSingleton) then {
            _classRegistryName + "_instance";
        } else {
            INSTANCE_NAME(_classRegistryName, _instanceIndex)
        };
    };
    // --------------------------------------------

    // -------------- method prepare --------------
	private _methodParams = _namespace getVariable format["%1_%2", _instanceName, _methodName];
	if (isNil "_methodParams") exitWith {
		EXCEPTION(EXCEPTION_METHOD_DONT_EXISTS)
	};
	private _methodVarName = _methodParams param [0, "", [""]];
	private _method = OOP_GLOBAL_NAMESPACE getVariable [_methodVarName, {EXCEPTION(EXCEPTION_METHOD_FUNC_DONT_EXISTS)}];
	private _methodSelfFields = _methodParams param [1, [], [[], ""]];
	if !(_methodSelfFields isEqualType []) then {_methodSelfFields = []};
	_methodSelfFields = _methodSelfFields select {(_x#0) isEqualType ""};

    // prepare self vars
	private _selfNamespace = _namespace;
	private _selfObj = _namespace;

    // -------- if embedded method call -----------
    private _parentCallerClass = if (isNil "_currentCalledClassName") then {""} else {_currentCalledClassName};
    private _parentCallerMethodName = if (isNil "_currentCallerMethodName") then {""} else {_currentCallerMethodName};
    private _parentCallerMethod = if (isNil "_currentCallerMethod") then {""} else {_currentCallerMethod};
    private _parentCallerNamespace = if (isNil "_currentCallerNamespace") then {""} else {_currentCallerNamespace};
    private _parentCallerSelfObj = if (isNil "_currentCallerSelfObj") then {""} else {_currentCallerSelfObj};
    private _parentClassLoadedFields = if (isNil "_currentClassLoadedFields") then {[]} else {_currentClassLoadedFields};
    private _currentCalledClassName = _className;
    private _currentCallerMethodName = _methodName;
    private _currentCallerMethod = _method;
    private _currentCallerNamespace = _selfNamespace;
    private _currentCallerSelfObj = _selfObj;
    private _doPrivateVars = (_parentCallerClass isNotEqualTo _currentCalledClassName) || {_parentCallerNamespace isNotEqualTo _currentCallerNamespace};
    // --------------------------------------------

    private _methodSelfFieldsVars = (_methodSelfFields apply {_x#0});
    private _methodSelfPrivateFieldsVars = if (_doPrivateVars) then {
        _methodSelfFieldsVars
    } else {
        _methodSelfFieldsVars select {!(_x in _parentClassLoadedFields) || {isNil _x}}
    };
    private _currentClassLoadedFields = if (_doPrivateVars) then {
        +_methodSelfFieldsVars
    } else {
        _parentClassLoadedFields + _methodSelfPrivateFieldsVars
    };
    if (_methodSelfPrivateFieldsVars isEqualTo []) then {_methodSelfPrivateFieldsVars = ["_tempp"]};
	private _methodSelfPrivateFieldsVars;
	{
		_x params [["_fieldName", ""], ["_fieldParams", []]];
		if (_fieldName isEqualTo "") then {continue};
		if !(_fieldName in _methodSelfPrivateFieldsVars) then {continue};
		_fieldParams params [["_fieldNameFull", ""], ["_fieldDef", nil], ["_fieldType", []]];
        _fieldNameFull = if (_isSingleton) then {_fieldNameFull} else {format["%1_%2", _fieldNameFull, _instanceIndex]};
		call compile (format['%1 = _namespace getVariable ["%2", _fieldDef]; %1 = [if (isNil "%1") then {nil} else {%1}, _fieldType, _fieldDef] call FUNC(validateFieldType)', _fieldName, _fieldNameFull]);
	} forEach _methodSelfFields;
    // --------------------------------------------

    // -------------- prepare fields --------------
	private _varsPrefix = _namespace getVariable [format["%1_varsPrefix", _instanceName], ""];
    // self Namespace var
	private _selfNamespaceVar = _namespace getVariable [format["%1_selfNamespaceVar", _instanceName], "_namespace"];
	if !(_selfNamespaceVar isEqualType "") then {
		_selfNamespaceVar = "_namespace";
		EXCEPTION(EXCEPTION_SELF_VAR_NOT_STRING)
	};
	private _self = _namespace getVariable [_instanceName, {}];
    // dont re-private "_namespace" - it is already local in this scope and private would reset it to nil
    private _selfVarIsNamespace = _selfNamespaceVar isEqualTo "_namespace";
    private (if (_selfVarIsNamespace) then {["_oopTempSelfVar"]} else {[_selfNamespaceVar]});
    if !(_selfVarIsNamespace) then {
        call compile (format["%1 = _namespace", _selfNamespaceVar]);
    };
    // --------------------------------------------

    // -------- class middleware variables --------
    private _paramsMap = [];
    private _thisMethod = _method;
    private _oopSetVarGlobal = false;
    private _oopSaveVars = false; // dont save vars by def
    private _oopToSaveVars = createHashMap;
    private _oopToSaveVarsParams = createHashMap;
    // --------------------------------------------

    // --------------- METHOD CALL ----------------
    _this = _thisArgs;
    private _result = _thisArgs call _method;
    // --------------------------------------------

    // --------------- SAVE VARS ----------------
    if !(_oopSaveVars isEqualTo false) then {
        if !(_methodSelfFields isEqualTo []) then {
            private ["_target"];
            {
                _target = _oopToSaveVarsParams getOrDefault [_x, _oopSetVarGlobal];
                SET_SELFSVART(_x, _target);
            } forEach (if (_oopSaveVars isEqualTo true) then {_methodSelfFieldsVars} else {_oopToSaveVars});
        };
    };
    // --------------------------------------------

    _NIL(_result)
};

FUNC(remoteExecClassInstance) = {
	params[["_callArgs", []], ["_remoteExecParams", false]];

    if (_remoteExecParams isEqualTo false) exitWith {
        _callArgs call FUNC(callClassInstance);
    };

    private _defJip = false;
    if (_remoteExecParams isEqualTo true) then {
        _defJip = true;
    };
    if !(_remoteExecParams isEqualType []) then {
        _remoteExecParams = [_remoteExecParams];
    };
    _remoteExecParams params [["_targets", 0], ["_jip", _defJip], ["_call", false, [false]]];
    [OOP_SPREF(callClassInstance), _callArgs, _targets, _jip] call FUNC(RemoteEvent);
};

FUNC(validateFieldType) = {
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

FUNC(addInstanceGlobal) = {
	params["_instanceName", ["_instanceNamespace", missionNamespace], ["_globalNamespace", missionNamespace], ["_global", false]];
    private _lastId = _globalNamespace getVariable [_instanceName + "_lastId", 0];
    private _id = _lastId + 1;
    private _globalInstanceName = format["%1_%2", _instanceName, _id];
    _globalNamespace setVariable [_instanceName + "_lastId", _id, _global];
    _globalNamespace setVariable [_globalInstanceName + "_namespace", _instanceNamespace, _global];
    [_globalNamespace, SPREF_ + "CLASS_instances", _globalInstanceName, true, _global, _global] call FUNC(pushBackNet);
    _globalInstanceName
};

FUNC(classRegistryName) = {
	params["_className"];
    private _prefix = VAR_PREFIX;
	_prefix = if (_prefix == "") then {_prefix} else {_prefix + "_"};
    format[SPREF_ + "CLASS_%1%2", _prefix, _className];
};

FUNC(instanceName) = {
	params["_className", ["_namespace", missionNamespace], ["_instanceID", -1]];
    private _instance = _namespace getVariable _className;
    if !(isNil "_instance") exitWith {_className};
    ([_className] call FUNC(classRegistryName)) + "_instance" + (if (_instanceID > 0) then {"_" + (str _instanceID)} else {""});
};

FUNC(classExists) = {
	params["_classname"];
    private _classRegistryName = [_className] call FUNC(classRegistryName);
	private _class = missionNamespace getVariable _classRegistryName;
	if (isNil "_class") exitWith {false};
	if !(_class isEqualType createHashMap) exitWith {false};
	private _classParam = _class get "classname";
	if (isNil "_classParam") exitWith {false};
	_class
};

FUNC(raiseException) = {
    params [["_errorId", -1], ["_this", nil], ["_className", nil], ["_class", nil], ["_def", nil]];
    private _errorTypeData = switch (_errorId) do {
        case EXCEPTION_METHOD_DONT_EXISTS: {"EXCEPTION_METHOD_DONT_EXISTS"};
        case EXCEPTION_METHOD_FUNC_DONT_EXISTS: {"EXCEPTION_METHOD_FUNC_DONT_EXISTS"};
        case EXCEPTION_SELF_VAR_NOT_STRING: {"EXCEPTION_SELF_VAR_NOT_STRING"};
        default { };
    };
    private _logData = ["DATA", "_namespace, _instanceName, _methodName, _parentCallerClass, _parentCallerMethodName, _parentCallerNamespace, _parentCallerSelfObj, _thisArgs, _errorTypeData"] VARS_STR;
	private _log = format[SPREFX + " EXCEPTION: %1 | %2", _errorId, _logData];
    _log DLOG;
	_log
};

FUNC(RemoteExec) = {
    _this call EFL_FUNC(remoteExec);
};

FUNC(RemoteEvent) = {
    _this call EFL_FUNC(remoteEvent);
};

FUNC(nonPrivateParams) = {
    {
        _x params ["_name", ["_def", nil]];
        call compile (format["%1 = _thisArgs param [%2, if !(isNil '_def') then {_def}]", _name, _forEachIndex]);
    } forEach _this;
};

FUNC(pushBackGlobal) = {
    _this call EFL_FUNC(pushBackGlobal);
};

FUNC(pushBackNet) = {
    _this call EFL_FUNC(pushBackNet);
};

FUNC(setVar) = {
    private _outerInstanceID = _NIL(_instanceIndex);
    private _outerAddonPrefx = IF_NIL(_ADDON_PREFX, nil);
    params["_selfNamespace", "_className", "_name", ["_val", nil], ["_target", false], ["_instanceID", _NIL(_outerInstanceID)], ["_ADDON_PREFX", _NIL(_outerAddonPrefx)]];
    // lookup instance in its own namespace (not missionNamespace), otherwise varsPrefix is lost for object instances
    private _instanceName = [_className, _selfNamespace, _NIL(_instanceID)] call FUNC(instanceName);
	private _varsPrefix = _selfNamespace getVariable [format["%1_varsPrefix", _instanceName], ""];
    if (isNil "_instanceID") then {
        _instanceID = _selfNamespace getVariable [_instanceName + "_instanceIndex", -1];
    };
    _selfNamespace setVariable [VAR_NAME, _NIL(_val), _target];
};

FUNC(getVar) = {
    private _outerInstanceID = _NIL(_instanceIndex);
    private _outerAddonPrefx = IF_NIL(_ADDON_PREFX, nil);
    params["_selfNamespace", "_className", "_name", ["_def", nil], ["_instanceID", _NIL(_outerInstanceID)], ["_ADDON_PREFX", _NIL(_outerAddonPrefx)]];
    private _instanceName = [_className, _selfNamespace, _NIL(_instanceID)] call FUNC(instanceName);
	private _varsPrefix = _selfNamespace getVariable [format["%1_varsPrefix", _instanceName], ""];
    if (isNil "_instanceID") then {
        _instanceID = _selfNamespace getVariable [_instanceName + "_instanceIndex", -1];
    };
    _selfNamespace getVariable [VAR_NAME, _NIL(_def)];
};
