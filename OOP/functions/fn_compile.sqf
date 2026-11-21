#include "defines.hpp"

#ifndef FINAL
#undef CFUNC
#define CFUNC(f) FUNC(f)
#endif


#define INIT "Init"
#define DEINIT "Deinit"

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
#define EXCEPTION_INSTANCE_DONT_EXISTS 8

#define OOP_GLOBAL_NAMESPACE missionNamespace
#define OOP_NP_PARAMS_CACHE_VAR OOP_SPREF(npParamsCache)

// Runtime DEV mode controlled via missionNamespace (auto-enabled if "OOP_DEV" file exists in mission root; never overwrites a pre-set value)
#define OOP_DEV_MODE_VAR OOP_SPREF(devMode)
#define OOP_DEV_MARKER_FILE "OOP_DEV"
#ifdef DEV
#define OOP_DEV_DEFAULT true
#else
#define OOP_DEV_DEFAULT false
#endif
#define IS_OOP_DEV_MODE ((missionNamespace getVariable [OOP_DEV_MODE_VAR, OOP_DEV_DEFAULT]) isEqualTo true)

// Class caching in parsingNamespace (automatically disabled whenever IS_OOP_DEV_MODE is true)
#define OOP_CACHE_ENABLED_VAR OOP_SPREF(cacheClasses)
#define OOP_CLASSES_CACHE_VAR OOP_SPREF(classesCache)
#ifdef FINAL
#define OOP_CACHE_DEFAULT true
#else
#define OOP_CACHE_DEFAULT false
#endif
#define IS_OOP_CACHE_ENABLED (!(IS_OOP_DEV_MODE) && {(parsingNamespace getVariable [OOP_CACHE_ENABLED_VAR, OOP_CACHE_DEFAULT]) isEqualTo true})

// ASCII non-identifier delimiter set for exact SQF token matching in OOP_fnc_class
#define OOP_TOKEN_DELIMS (toString [9,10,13,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,58,59,60,61,62,63,64,91,92,93,94,96,123,124,125,126])

if (isNil {missionNamespace getVariable OOP_DEV_MODE_VAR}) then {
	private _isDev = OOP_DEV_DEFAULT || {fileExists OOP_DEV_MARKER_FILE};
	#ifdef DEV
	_isDev = _isDev && (parsingNamespace getVariable [OOP_DEV_MODE_VAR, false]);
	#endif
	missionNamespace setVariable [OOP_DEV_MODE_VAR, _isDev];
};

if (isNil {parsingNamespace getVariable OOP_CACHE_ENABLED_VAR}) then {
	parsingNamespace setVariable [OOP_CACHE_ENABLED_VAR, OOP_CACHE_DEFAULT];
};


CFUNC(isDevMode) = {
	IS_OOP_DEV_MODE
};

CFUNC(restoreCachedClass) = {
	private _outerAddonPrefx = IF_NIL(_ADDON_PREFX, nil);
	params ["_className", ["_globalNamespace", OOP_GLOBAL_NAMESPACE], ["_ADDON_PREFX", _NIL(_outerAddonPrefx)]];

	if !(IS_OOP_CACHE_ENABLED) exitWith {false};

	private _classesCache = parsingNamespace getVariable OOP_CLASSES_CACHE_VAR;
	if ((isNil "_classesCache") || {!(_classesCache isEqualType createHashMap)}) exitWith {false};

	private _classRegistryName = [_className] call FUNC(classRegistryName);
	private _cachedClass = _classesCache get _classRegistryName;
	if ((isNil "_cachedClass") || {!(_cachedClass isEqualType createHashMap)} || {!("classname" in _cachedClass)}) exitWith {false};

	private _existing = _globalNamespace getVariable _classRegistryName;
	if (!(isNil "_existing") && {_existing isEqualType createHashMap} && {"classname" in _existing}) exitWith {
		_existing
	};

	private _classMap = +_cachedClass;
	private _methodsMap = _classMap getOrDefault ["methods", createHashMap];
	{
		_globalNamespace setVariable [_y select 0, _y select 1];
	} forEach _methodsMap;
	_globalNamespace setVariable [_classRegistryName, _classMap];

	_classMap
};

CFUNC(restoreAllCachedClasses) = {
	params [["_globalNamespace", OOP_GLOBAL_NAMESPACE]];

	if !(IS_OOP_CACHE_ENABLED) exitWith {false};

	private _classesCache = parsingNamespace getVariable OOP_CLASSES_CACHE_VAR;
	if ((isNil "_classesCache") || {!(_classesCache isEqualType createHashMap)}) exitWith {false};

	{
		private _classRegistryName = _x;
		private _cachedClass = _y;
		if ((_cachedClass isEqualType createHashMap) && {"classname" in _cachedClass}) then {
			private _existing = _globalNamespace getVariable _classRegistryName;
			if ((isNil "_existing") || {!(_existing isEqualType createHashMap)} || {!("classname" in _existing)}) then {
				private _classMap = +_cachedClass;
				private _methodsMap = _classMap getOrDefault ["methods", createHashMap];
				{
					_globalNamespace setVariable [_y select 0, _y select 1];
				} forEach _methodsMap;
				_globalNamespace setVariable [_classRegistryName, _classMap];
			};
		};
	} forEach _classesCache;

	true
};

CFUNC(clearClassesCache) = {
	private _outerAddonPrefx = IF_NIL(_ADDON_PREFX, nil);
	params [["_className", ""], ["_ADDON_PREFX", _NIL(_outerAddonPrefx)]];

	if (_className isEqualTo "") exitWith {
		parsingNamespace setVariable [OOP_CLASSES_CACHE_VAR, nil];
		true
	};

	private _classesCache = parsingNamespace getVariable OOP_CLASSES_CACHE_VAR;
	if ((isNil "_classesCache") || {!(_classesCache isEqualType createHashMap)}) exitWith {false};

	if (_className in _classesCache) exitWith {
		_classesCache deleteAt _className;
		true
	};

	private _classRegistryName = [_className] call FUNC(classRegistryName);
	if !(_classRegistryName in _classesCache) exitWith {false};

	_classesCache deleteAt _classRegistryName;
	true
};

CFUNC(class) = {
	params ["_className", "_fields", "_methods", ["_selfNamespaceVar", ""], ["_isSingleton", true], ["_varsPrefix", ""], ["_globalNamespace", OOP_GLOBAL_NAMESPACE]];

	private _prefix = if (isNil "_ADDON_PREFX") then {SPREFX} else {_ADDON_PREFX};
	private _classRegistryName = [_className] call FUNC(classRegistryName);

	private _cachedClass = [_className, _globalNamespace] call FUNC(restoreCachedClass);
	if !(_cachedClass isEqualTo false) exitWith {_cachedClass};

	private _isDevMode = IS_OOP_DEV_MODE;
	private _fieldPrefix = format ["%1%2", _prefix, _varsPrefix];

	private _fieldsCompiled = [];
	private _isVolatile = false;
	{
		if (_x isEqualTo true) then {
			// next field is volatile (disables type check)
			_isVolatile = true;
			continue
		};
		if !(_x isEqualType []) then {continue};

		private _fieldName = _x select 0;
		private _fieldDef = if (count _x > 1) then {_x select 1} else {-1};
		private _isRef = false;
		if !(isNil "_fieldDef") then {
			if ((_fieldDef isEqualType []) || {_fieldDef isEqualType createHashMap}) then {
				_fieldDef = +_fieldDef;
				_isRef = true;
			};
		};

		private _fieldType = if (count _x > 2) then {_x select 2} else {nil};
		if (isNil "_fieldType") then {
			if (_isVolatile || {isNil "_fieldDef"}) then {
				_fieldType = [];
			} else {
				if (_fieldDef isEqualType []) then {
					_fieldType = [[]];
				} else {
					_fieldType = _fieldDef;
				};
			};
		};

		// 0 = volatile (no check), 1 = single type (isEqualType), 2 = type list (isEqualTypeAny)
		private _checkMode = if (_fieldType isEqualType []) then {
			if (_fieldType isEqualTo []) then {0} else {2}
		} else {
			1
		};

		private _fieldNameFull = _fieldPrefix + _fieldName;
		_fieldsCompiled pushBack [_fieldName, [_fieldNameFull, _NIL(_fieldDef), _fieldType, _isRef, _checkMode]];
		_isVolatile = false;
	} forEach _fields;

	private _fieldsMap = createHashMapFromArray _fieldsCompiled;

	private _tokenDelims = OOP_TOKEN_DELIMS;
	private _methodsCompiled = [];
	for "_i" from 0 to ((count _methods) - 2) step 2 do {
		private _methodName = _methods select _i;
		private _method = _methods select (_i + 1);
		private _methodStr = toLower (str _method);

		// Exact identifier-token lookup (avoids substring false positives like _pos matching _position)
		private _methodTokens = createHashMapFromArray ((_methodStr splitString _tokenDelims) apply {[_x, true]});
		private _methodSelfFields = _fieldsCompiled select {(toLower (_x select 0)) in _methodTokens};

		// Precompile field loader & saver code once per method (zero runtime call compile!)
		private _methodFieldNames = [];
		private _methodFieldDefs = [];
		private _loadParts = [];
		private _saveParts = [];

		{
			_x params ["_fName", "_fParams"];
			_fParams params ["_fFull", "_fDef", "_fType", "_fIsRef", "_fCheckMode"];
			private _idx = _forEachIndex;
			_methodFieldNames pushBack _fName;
			_methodFieldDefs pushBack [_NIL(_fDef), _fType, _fIsRef];

			private _defExpr = if (isNil "_fDef") then {
				"nil"
			} else {
				if (_fIsRef) then {
					format ["+((_oopMethodFieldDefs select %1) select 0)", _idx]
				} else {
					format ["((_oopMethodFieldDefs select %1) select 0)", _idx]
				}
			};

			private _valExpr = switch (_fCheckMode) do {
				case 0: {"_oo_v"};
				case 1: {format ["if (_oo_v isEqualType ((_oopMethodFieldDefs select %1) select 1)) then {_oo_v} else {%2}", _idx, _defExpr]};
				default {format ["if (_oo_v isEqualTypeAny ((_oopMethodFieldDefs select %1) select 1)) then {_oo_v} else {%2}", _idx, _defExpr]};
			};

			_loadParts pushBack format [
				"if (_oopDoPrivateVars || {!('%1' in _oopParentLoadedFields) || {isNil '%1'}}) then {private _oo_v = _namespace getVariable ('%2' + _oopFieldSuffix); %1 = if (isNil '_oo_v') then {%3} else {%4};};",
				_fName,
				_fFull,
				_defExpr,
				_valExpr
			];

			_saveParts pushBack format [
				"if (_oopToSaveVars getOrDefault ['%1', _oopSaveVars isEqualTo true]) then {_namespace setVariable ['%2' + _oopFieldSuffix, if (isNil '%1') then {nil} else {%1}, _oopToSaveVarsParams getOrDefault ['%1', _oopSetVarGlobal]];};",
				_fName,
				_fFull
			];
		} forEach _methodSelfFields;

		private _loadCode = if (_loadParts isEqualTo []) then {{}} else {compile (_loadParts joinString "")};
		private _saveCode = if (_saveParts isEqualTo []) then {{}} else {compile (_saveParts joinString "")};

		private _methodNameFull = format ["%1_%2", _classRegistryName, _methodName];
		_globalNamespace setVariable [_methodNameFull, _method];
		_methodsCompiled pushBack [
			_methodName,
			[_methodNameFull, _method, _methodSelfFields, _methodFieldNames, _methodFieldDefs, _loadCode, _saveCode]
		];
	};

	private _methodsMap = createHashMapFromArray _methodsCompiled;

	private _classMap = createHashMap;
	_classMap set ["fields", _fieldsMap];
	_classMap set ["methods", _methodsMap];
	_classMap set ["classname", _classRegistryName];
	_classMap set ["addonPrefix", _prefix];

	if !(_selfNamespaceVar isEqualType "") then {
		EXCEPTION(EXCEPTION_SELF_VAR_NOT_STRING);
	};
	private _resolvedSelfVar = if (!(_selfNamespaceVar isEqualType "") || {_selfNamespaceVar isEqualTo ""}) then {"_namespace"} else {_selfNamespaceVar};
	private _selfVarCode = if (_resolvedSelfVar isEqualTo "_namespace") then {{}} else {compile format ["%1 = _namespace", _resolvedSelfVar]};
	_classMap set ["selfvar", _resolvedSelfVar];
	_classMap set ["selfVarCode", _selfVarCode];
	_classMap set ["varsPrefix", _varsPrefix];
	_classMap set ["fieldPrefix", _fieldPrefix];
	_classMap set ["isSingleton", _isSingleton];
	_classMap set ["isSignleton", _isSingleton]; // legacy key alias
	_classMap set ["devMode", _isDevMode];

	_globalNamespace setVariable [_classRegistryName, _classMap];

	if (IS_OOP_CACHE_ENABLED) then {
		private _classesCache = parsingNamespace getVariable OOP_CLASSES_CACHE_VAR;
		if ((isNil "_classesCache") || {!(_classesCache isEqualType createHashMap)}) then {
			_classesCache = createHashMap;
		};
		_classesCache set [_classRegistryName, +_classMap];
		parsingNamespace setVariable [OOP_CLASSES_CACHE_VAR, _classesCache];
	} else {
		private _classesCache = parsingNamespace getVariable OOP_CLASSES_CACHE_VAR;
		if (!(isNil "_classesCache") && {_classesCache isEqualType createHashMap} && {_classRegistryName in _classesCache}) then {
			_classesCache deleteAt _classRegistryName;
		};
	};

	_classMap
};

CFUNC(newInstance) = {
	private _outerAddonPrefx = IF_NIL(_ADDON_PREFX, nil);
	private _outerGlobalNamespace = IF_NIL(_globalNamespace, OOP_GLOBAL_NAMESPACE);
	params ["_className", ["_namespace", nil], ["_initArgs", []], ["_global", false], ["_def", nil], ["_ADDON_PREFX", _NIL(_outerAddonPrefx)], ["_globalNamespace", _outerGlobalNamespace]];

	if (isNil "_namespace") then {
		_namespace = missionNamespace;
	};

	if !(IS_VALID_SELF_NAMESPACE(_namespace)) exitWith {
		EXCEPTION(EXCEPTION_NON_NAMESPACE)
	};

	private _class = [_className, _globalNamespace] call FUNC(classExists);
	if (_class isEqualTo false) exitWith {EXCEPTION(EXCEPTION_CLASS_DONT_EXISTS)};

	private _classRegistryName = _class getOrDefaultCall ["classname", {EXCEPTION(EXCEPTION_NO_CLASSNAME); ""}];
	private _isSingleton = _class getOrDefault ["isSingleton", _class getOrDefault ["isSignleton", true]];
	private _prefix = _class getOrDefault ["addonPrefix", VAR_PREFIX];
	private _isDevMode = (_class getOrDefault ["devMode", false]) || {IS_OOP_DEV_MODE};

	private _instanceName = _classRegistryName + "_instance";
	private _instanceId = -1;
	if !(_isSingleton) then {
		private _classInstancesIdsVarName = format [SPREF_ + "class_%1_InstanceIds", _classRegistryName];
		private _classIds = +(_namespace getVariable [_classInstancesIdsVarName, []]);
		_instanceId = (_classIds param [((count _classIds) - 1) max 0, 0]) + 1;
		_instanceName = INSTANCE_NAME(_classRegistryName, _instanceId);
		[_namespace, _classInstancesIdsVarName, _instanceId, true, false, _global, _global] call FUNC(pushBackNet);
	};

	if (isNil {_namespace getVariable _instanceName}) then {
		// Minimal single network write: compact metadata tuple only (never sends compiled code!)
		_namespace setVariable [_instanceName, [_className, _instanceId, _prefix], _global];

		// DEV mode: keep all local introspection metadata & instance registries for debugging (0 extra network traffic!)
		if (_isDevMode) then {
			[_namespace, SPREF_ + "namespaceClassesInstances", _instanceName, true, false, false, false] call FUNC(pushBackNet);
			private _globalId = [_instanceName, _namespace, _globalNamespace, false] call FUNC(addInstanceGlobal);
			_namespace setVariable [_instanceName + "_instanceIndex", _instanceId, false];
			_namespace setVariable [_instanceName + "_className", _className, false];
			_namespace setVariable [_instanceName + "_classRegistryName", _classRegistryName, false];
			_namespace setVariable [_instanceName + "_varsPrefix", _class getOrDefault ["varsPrefix", ""], false];
			_namespace setVariable [_instanceName + "_selfNamespaceVar", _class getOrDefault ["selfvar", "_namespace"], false];
			_namespace setVariable [_instanceName + "_methods", keys (_class getOrDefault ["methods", createHashMap]), false];
			_namespace setVariable [_instanceName + "_fields", keys (_class getOrDefault ["fields", createHashMap]), false];
			_namespace setVariable [_instanceName + "_globalId", _globalId, false];
		};
	};

	private _initResult = [[_className, _instanceId], _namespace, INIT, _initArgs, NIL_DEF, _prefix, _globalNamespace] call FUNC(callClassInstance);
	if (_isSingleton) exitWith {if (isNil "_initResult") then {NIL_DEF} else {_initResult}};
	if (isNil "_initResult") then {[_instanceId, NIL_DEF]} else {[_instanceId, _initResult]};
};

CFUNC(deleteInstance) = {
	private _outerAddonPrefx = IF_NIL(_ADDON_PREFX, nil);
	params ["_instanceParams", "_namespace", ["_global", false], ["_callDeinit", true], ["_deinitArgs", []], ["_ADDON_PREFX", _NIL(_outerAddonPrefx)], ["_globalNamespace", OOP_GLOBAL_NAMESPACE]];

	if !(IS_VALID_SELF_NAMESPACE(_namespace)) exitWith {false};

	private _className = "";
	private _instanceIndex = -1;
	private _instanceName = "";
	private _classRegistryName = "";

	if (_instanceParams isEqualType "") then {
		_instanceName = _instanceParams;
		private _meta = _namespace getVariable _instanceName;
		if (isNil "_meta" || {!(_meta isEqualType [])}) exitWith {};
		_meta params ["_mClass", ["_mIdx", -1], ["_mPrefx", _NIL(_ADDON_PREFX)]];
		_className = _mClass;
		_instanceIndex = _mIdx;
		if !(isNil "_mPrefx") then {_ADDON_PREFX = _mPrefx};
		_classRegistryName = [_className] call FUNC(classRegistryName);
	} else {
		_instanceParams params ["_pClass", ["_pIdx", -1]];
		_className = _pClass;
		_instanceIndex = _pIdx;
		_classRegistryName = [_className] call FUNC(classRegistryName);
		_instanceName = if (_instanceIndex < 0) then {
			_classRegistryName + "_instance"
		} else {
			INSTANCE_NAME(_classRegistryName, _instanceIndex)
		};
	};

	if (_className isEqualTo "" || {isNil {_namespace getVariable _instanceName}}) exitWith {false};

	private _class = [_className, _globalNamespace] call FUNC(classExists);
	private _isSingleton = _instanceIndex < 0;

	if !(_class isEqualTo false) then {
		// Optionally invoke "Deinit" if defined on class
		if (_callDeinit && {DEINIT in (_class getOrDefault ["methods", createHashMap])}) then {
			[[_className, _instanceIndex], _namespace, DEINIT, _deinitArgs, nil, _ADDON_PREFX, _globalNamespace] call FUNC(callClassInstance);
		};

		// Clear all declared field variables for this instance
		private _fieldPrefix = _class getOrDefault ["fieldPrefix", format ["%1%2", VAR_PREFIX, _class getOrDefault ["varsPrefix", ""]]];
		private _fieldSuffix = if (_isSingleton) then {""} else {"_" + str _instanceIndex};
		{
			_namespace setVariable [_fieldPrefix + _x + _fieldSuffix, nil, _global];
		} forEach (keys (_class getOrDefault ["fields", createHashMap]));
	};

	// Clear instance marker
	_namespace setVariable [_instanceName, nil, _global];

	// Remove ID from multi-instance ID list
	if !(_isSingleton) then {
		private _classInstancesIdsVarName = format [SPREF_ + "class_%1_InstanceIds", _classRegistryName];
		[_namespace, _classInstancesIdsVarName, _instanceIndex, _global, _global] call FUNC(removeFromArrayNet);
	};

	// Clean up local DEV introspection metadata if present
	private _globalId = _namespace getVariable (_instanceName + "_globalId");
	if !(isNil "_globalId") then {
		_globalNamespace setVariable [_globalId + "_namespace", nil, false];
		[_globalNamespace, SPREF_ + "CLASS_instances", _globalId, false, false] call FUNC(removeFromArrayNet);
	};
	if !(isNil {_namespace getVariable (SPREF_ + "namespaceClassesInstances")}) then {
		[_namespace, SPREF_ + "namespaceClassesInstances", _instanceName, false, false] call FUNC(removeFromArrayNet);
	};
	{
		if !(isNil {_namespace getVariable (_instanceName + _x)}) then {
			_namespace setVariable [_instanceName + _x, nil, false];
		};
	} forEach ["_instanceIndex", "_className", "_classRegistryName", "_varsPrefix", "_selfNamespaceVar", "_methods", "_fields", "_globalId"];

	true
};

CFUNC(callClassInstance) = {
	private _outerAddonPrefx = IF_NIL(_ADDON_PREFX, nil);
	params ["_instanceParams", "_namespace", ["_methodName", INIT], ["_rawArgs", nil], ["_def", nil], ["_ADDON_PREFX", _NIL(_outerAddonPrefx)], ["_globalNamespace", OOP_GLOBAL_NAMESPACE]];

	if !(IS_VALID_SELF_NAMESPACE(_namespace)) exitWith {
		if (IS_OOP_DEV_MODE) then {EXCEPTION(EXCEPTION_NON_NAMESPACE)};
		NIL_DEF
	};

	// -------------- instance resolution ---------------
	private _instanceIndex = -1;
	private _className = "";
	private _classRegistryName = "";
	private _instanceName = "";
	private _oopInstMeta = nil;

	if (_instanceParams isEqualType "") then {
		_instanceName = _instanceParams;
		_oopInstMeta = _namespace getVariable _instanceName;
		if (isNil "_oopInstMeta" || {!(_oopInstMeta isEqualType [])}) exitWith {
			EXCEPTION(EXCEPTION_INSTANCE_DONT_EXISTS)
		};
		_oopInstMeta params ["_mClassName", ["_mInstIdx", -1], ["_mPrefx", _NIL(_ADDON_PREFX)]];
		_className = _mClassName;
		_instanceIndex = _mInstIdx;
		if !(isNil "_mPrefx") then {_ADDON_PREFX = _mPrefx};
		_classRegistryName = [_className] call FUNC(classRegistryName);
	} else {
		_instanceParams params ["_pClassName", ["_pInstIdx", -1]];
		_className = _pClassName;
		_instanceIndex = _pInstIdx;
		_classRegistryName = [_className] call FUNC(classRegistryName);
		_instanceName = if (_instanceIndex < 0) then {
			_classRegistryName + "_instance"
		} else {
			INSTANCE_NAME(_classRegistryName, _instanceIndex)
		};
		_oopInstMeta = _namespace getVariable _instanceName;
		if (isNil "_oopInstMeta") exitWith {
			EXCEPTION(EXCEPTION_INSTANCE_DONT_EXISTS)
		};
	};

	// -------------- class & method lookup --------------
	private _class = _globalNamespace getVariable _classRegistryName;
	if (isNil "_class") then {
		_class = [_className, _globalNamespace] call FUNC(restoreCachedClass);
	};
	if (isNil "_class" || {_class isEqualTo false} || {!(_class isEqualType createHashMap)}) exitWith {
		EXCEPTION(EXCEPTION_CLASS_DONT_EXISTS)
	};

	private _oopFieldPrefix = _class getOrDefault ["fieldPrefix", format ["%1%2", VAR_PREFIX, _class getOrDefault ["varsPrefix", ""]]];
	private _oopFieldSuffix = if (_instanceIndex < 0) then {""} else {"_" + str _instanceIndex};

	private _oopMethodsMap = _class getOrDefault ["methods", createHashMap];
	private _oopMethodEntry = _oopMethodsMap get _methodName;
	if (isNil "_oopMethodEntry") exitWith {
		// Direct field-read shortcut: ["_fieldName", _default] CALL_SELF / CALL_CLASS / CALL_OBJCLASS
		private _oopFieldsMap = _class getOrDefault ["fields", createHashMap];
		if (_methodName in _oopFieldsMap) exitWith {
			_namespace getVariable [_oopFieldPrefix + _methodName + _oopFieldSuffix, _NIL(_rawArgs)]
		};
		EXCEPTION(EXCEPTION_METHOD_DONT_EXISTS)
	};

	_oopMethodEntry params ["_oopMethodVarName", "_oopMethodFallback", "_oopMethodSelfFields", "_oopMethodFieldNames", "_oopMethodFieldDefs", "_oopLoadCode", "_oopSaveCode"];
	private _method = _globalNamespace getVariable [_oopMethodVarName, _oopMethodFallback];
	if (isNil "_method" || {!(_method isEqualType {})}) exitWith {
		EXCEPTION(EXCEPTION_METHOD_FUNC_DONT_EXISTS)
	};

	// -------------- prepare self & nested call context --------------
	private _thisArgs = if (isNil "_rawArgs") then {[]} else {_rawArgs};
	private _selfNamespace = _namespace;
	private _selfObj = _namespace;
	private _varsPrefix = _class getOrDefault ["varsPrefix", ""];

	private _parentCallerClass = if (isNil "_currentCalledClassName") then {""} else {_currentCalledClassName};
	private _parentCallerMethodName = if (isNil "_currentCallerMethodName") then {""} else {_currentCallerMethodName};
	private _parentCallerMethod = if (isNil "_currentCallerMethod") then {""} else {_currentCallerMethod};
	private _parentCallerNamespace = if (isNil "_currentCallerNamespace") then {""} else {_currentCallerNamespace};
	private _parentCallerSelfObj = if (isNil "_currentCallerSelfObj") then {""} else {_currentCallerSelfObj};
	private _parentCallerInstanceName = if (isNil "_currentCallerInstanceName") then {""} else {_currentCallerInstanceName};
	private _oopParentLoadedFields = if (isNil "_currentClassLoadedFields") then {[]} else {_currentClassLoadedFields};

	private _currentCalledClassName = _className;
	private _currentCallerMethodName = _methodName;
	private _currentCallerMethod = _method;
	private _currentCallerNamespace = _selfNamespace;
	private _currentCallerSelfObj = _selfObj;
	private _currentCallerInstanceName = _instanceName;

	// Compares BOTH instanceName (class + instanceIndex) AND namespace to prevent cross-instance collisions on the same object
	private _oopDoPrivateVars = (_parentCallerInstanceName isNotEqualTo _instanceName) || {_parentCallerNamespace isNotEqualTo _currentCallerNamespace};

	private _oopPrivateFieldsVars = if (_oopDoPrivateVars) then {
		_oopMethodFieldNames
	} else {
		_oopMethodFieldNames select {!(_x in _oopParentLoadedFields) || {isNil _x}}
	};
	private _currentClassLoadedFields = if (_oopDoPrivateVars) then {
		+_oopMethodFieldNames
	} else {
		_oopParentLoadedFields + _oopPrivateFieldsVars
	};

	// Must be at top level of callClassInstance so privatized field vars remain in scope for _loadCode, _method, and _saveCode
	if (_oopPrivateFieldsVars isEqualTo []) then {_oopPrivateFieldsVars = ["_oop_noop_tmp"]};
	private _oopPrivateFieldsVars;
	if !(_oopMethodFieldNames isEqualTo []) then {
		call _oopLoadCode;
	};

	// Self alias (precompiled assignment — zero runtime call compile)
	private _selfNamespaceVar = _class getOrDefault ["selfvar", "_namespace"];
	if !(_selfNamespaceVar isEqualType "") then {
		_selfNamespaceVar = "_namespace";
		EXCEPTION(EXCEPTION_SELF_VAR_NOT_STRING);
	};
	private _oopSelfVarIsNamespace = _selfNamespaceVar isEqualTo "_namespace";
	private (if (_oopSelfVarIsNamespace) then {["_oop_noop_selfvar"]} else {[_selfNamespaceVar]});
	if !(_oopSelfVarIsNamespace) then {
		call (_class getOrDefault ["selfVarCode", {}]);
	};

	// -------------- class middleware variables --------------
	private _self = {_this CALL_SELF};
	private _paramsMap = [];
	private _thisMethod = _method;
	private _oopSetVarGlobal = false;
	private _oopSaveVars = false;
	private _oopToSaveVars = createHashMap;
	private _oopToSaveVarsParams = createHashMap;

	// -------------- METHOD CALL --------------
	_this = _thisArgs;
	private _result = _thisArgs call _method;

	// -------------- BATCH SAVE VARS (precompiled — zero runtime call compile) --------------
	if (!(_oopSaveVars isEqualTo false) && {!(_oopMethodFieldNames isEqualTo [])}) then {
		call _oopSaveCode;
	};

	_NIL(_result)
};

CFUNC(remoteExecClassInstance) = {
	params [["_callArgs", []], ["_remoteExecParams", false]];

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

CFUNC(validateFieldType) = {
	params ["_var", ["_types", []], ["_def", nil]];
	if (isNil "_var") exitWith {nil};
	if (_types isEqualTo []) exitWith {_var};
	private _valid = if (_types isEqualType []) then {
		_var isEqualTypeAny _types
	} else {
		_var isEqualType _types
	};
	if !(_valid) exitWith {
		if (isNil "_def") then {nil} else {
			if ((_def isEqualType []) || {_def isEqualType createHashMap}) then {+_def} else {_def}
		}
	};
	_var
};

CFUNC(addInstanceGlobal) = {
	params ["_instanceName", ["_instanceNamespace", missionNamespace], ["_globalNamespace", OOP_GLOBAL_NAMESPACE], ["_global", false]];
	private _lastId = _globalNamespace getVariable [_instanceName + "_lastId", 0];
	private _id = _lastId + 1;
	private _globalInstanceName = format ["%1_%2", _instanceName, _id];
	_globalNamespace setVariable [_instanceName + "_lastId", _id, _global];
	_globalNamespace setVariable [_globalInstanceName + "_namespace", _instanceNamespace, _global];
	[_globalNamespace, SPREF_ + "CLASS_instances", _globalInstanceName, true, false, _global, _global] call FUNC(pushBackNet);
	_globalInstanceName
};

CFUNC(classRegistryName) = {
	params ["_className"];
	private _prefix = VAR_PREFIX;
	_prefix = if (_prefix == "") then {_prefix} else {_prefix + "_"};
	format [SPREF_ + "CLASS_%1%2", _prefix, _className];
};

CFUNC(instanceName) = {
	params ["_className", ["_namespace", missionNamespace], ["_instanceID", -1]];
	private _instance = _namespace getVariable _className;
	if !(isNil "_instance") exitWith {_className};
	([_className] call FUNC(classRegistryName)) + "_instance" + (if (_instanceID > 0) then {"_" + (str _instanceID)} else {""});
};

CFUNC(classExists) = {
	params ["_className", ["_globalNamespace", OOP_GLOBAL_NAMESPACE]];
	private _classRegistryName = [_className] call FUNC(classRegistryName);
	private _class = _globalNamespace getVariable _classRegistryName;
	if (isNil "_class") then {
		_class = [_className, _globalNamespace] call FUNC(restoreCachedClass);
	};
	if ((isNil "_class") || {_class isEqualTo false}) exitWith {false};
	if !(_class isEqualType createHashMap) exitWith {false};
	private _classParam = _class get "classname";
	if (isNil "_classParam") exitWith {false};
	_class
};

CFUNC(raiseException) = {
	params [["_errorId", -1], ["_this", nil], ["_className", nil], ["_class", nil], ["_def", nil]];
	private _errorTypeData = switch (_errorId) do {
		case EXCEPTION_CLASS_DONT_EXISTS: {"EXCEPTION_CLASS_DONT_EXISTS"};
		case EXCEPTION_NON_NAMESPACE: {"EXCEPTION_NON_NAMESPACE"};
		case EXCEPTION_NO_CLASSNAME: {"EXCEPTION_NO_CLASSNAME"};
		case EXCEPTION_NO_FIELDS: {"EXCEPTION_NO_FIELDS"};
		case EXCEPTION_NO_METHODS: {"EXCEPTION_NO_METHODS"};
		case EXCEPTION_METHOD_DONT_EXISTS: {"EXCEPTION_METHOD_DONT_EXISTS"};
		case EXCEPTION_METHOD_FUNC_DONT_EXISTS: {"EXCEPTION_METHOD_FUNC_DONT_EXISTS"};
		case EXCEPTION_SELF_VAR_NOT_STRING: {"EXCEPTION_SELF_VAR_NOT_STRING"};
		case EXCEPTION_INSTANCE_DONT_EXISTS: {"EXCEPTION_INSTANCE_DONT_EXISTS"};
		default {"EXCEPTION_UNKNOWN"};
	};
	private _logData = ["DATA", "_namespace, _instanceName, _methodName, _parentCallerClass, _parentCallerMethodName, _parentCallerNamespace, _parentCallerSelfObj, _thisArgs, _errorTypeData"] VARS_STR;
	private _log = format [SPREFX + " EXCEPTION: %1 | %2", _errorId, _logData];
	_log DLOG;
	NIL_DEF
};

// Standalone CBA-based remote event dispatcher (zero EFL dependency)
CFUNC(RemoteEvent) = {
	params ["_eventName", ["_args", []], ["_target", false], ["_jip", false]];

	if (_target in [false, clientOwner]) exitWith {
		[_eventName, _args] call CBA_fnc_localEvent;
	};
	if (_target isEqualTo 2) exitWith {
		[_eventName, _args] call CBA_fnc_serverEvent;
	};
	if (_target isEqualTo true) exitWith {
		if !(_jip isEqualTypeAny ["", objNull]) then {
			_jip = "";
		};
		[_eventName, _args, _NIL(_jip)] call CBA_fnc_globalEventJIP;
	};
	if (_target isEqualTo 0) exitWith {
		[_eventName, _args] call CBA_fnc_globalEvent;
	};
	if (_target isEqualType 1) exitWith {
		[_eventName, _args, _target] call CBA_fnc_ownerEvent;
	};
	if (_target isEqualType objNull) exitWith {
		[_eventName, _args, _target] call CBA_fnc_targetEvent;
	};
	if (_target isEqualType []) exitWith {
		{
			[_eventName, _args, _x] call FUNC(RemoteEvent);
		} forEach _target;
	};
	[_eventName, _args] call CBA_fnc_localEvent;
};

// Cached non-private params (compiles once per unique parameter signature, zero compile thereafter)
CFUNC(nonPrivateParams) = {
	params ["_oo_paramsMap", ["_oo_varNames", []]];
	if (_oo_varNames isEqualTo []) then {
		_oo_varNames = _oo_paramsMap apply {if (_x isEqualType []) then {_x select 0} else {_x}};
	};
	if (_oo_varNames isEqualTo []) exitWith {};

	private _oo_defs = _oo_paramsMap apply {
		if (_x isEqualType [] && {count _x > 1}) then {_x select 1} else {nil}
	};

	private _oo_cacheKey = _oo_varNames joinString ",";
	private _oo_cache = missionNamespace getVariable OOP_NP_PARAMS_CACHE_VAR;
	if (isNil "_oo_cache") then {
		_oo_cache = createHashMap;
		missionNamespace setVariable [OOP_NP_PARAMS_CACHE_VAR, _oo_cache];
	};

	private _oo_code = _oo_cache get _oo_cacheKey;
	if (isNil "_oo_code") then {
		private _oo_parts = [];
		{
			_oo_parts pushBack format [
				"private _oo_d = _oo_defs select %2; %1 = if (isNil '_oo_d') then {_thisArgs param [%2]} else {_thisArgs param [%2, _oo_d]};",
				_x,
				_forEachIndex
			];
		} forEach _oo_varNames;
		_oo_code = compile (_oo_parts joinString "");
		_oo_cache set [_oo_cacheKey, _oo_code];
	};

	call _oo_code;
};

// Standalone delta-sync array helpers (zero EFL dependency)
CFUNC(pushBackNet) = {
	params ["_namespace", "_varname", "_element", ["_unique", true], ["_callEH", false], ["_target", false], ["_jip", true]];
	if (isNil "_namespace" || {isNil "_varname"} || {isNil "_element"}) exitWith {};
	if (_target in [false, clientOwner]) exitWith {
		private _array = _namespace getVariable [_varname, []];
		if !(_array isEqualType []) then {_array = []};
		if (_unique) then {
			_array pushBackUnique _element;
		} else {
			_array pushBack _element;
		};
		_namespace setVariable [_varname, _array];
	};
	[OOP_SPREF(pushBack), [_namespace, _varname, _element, _unique], _target, _jip] call FUNC(RemoteEvent);
};

CFUNC(pushBackGlobal) = {
	params ["_namespace", "_varname", "_element", ["_unique", true], ["_callEH", false]];
	[_NIL(_namespace), _NIL(_varname), _NIL(_element), _unique, _callEH, true, true] call FUNC(pushBackNet);
};

CFUNC(removeFromArrayNet) = {
	params ["_namespace", "_varname", "_element", ["_target", false], ["_jip", true]];
	if (isNil "_namespace" || {isNil "_varname"} || {isNil "_element"}) exitWith {};
	if (_target in [false, clientOwner]) exitWith {
		private _array = _namespace getVariable [_varname, []];
		if !(_array isEqualType []) exitWith {};
		_namespace setVariable [_varname, _array - [_element]];
	};
	[OOP_SPREF(removeFromArray), [_namespace, _varname, _element], _target, _jip] call FUNC(RemoteEvent);
};

CFUNC(setVar) = {
	private _outerInstanceID = _NIL(_instanceIndex);
	private _outerAddonPrefx = IF_NIL(_ADDON_PREFX, nil);
	params ["_selfNamespace", "_className", "_name", ["_val", nil], ["_target", false], ["_instanceID", _NIL(_outerInstanceID)], ["_ADDON_PREFX", _NIL(_outerAddonPrefx)]];

	private _class = [_className] call FUNC(classExists);
	if (_class isEqualTo false) then {
		private _meta = _selfNamespace getVariable _className;
		if (!(isNil "_meta") && {_meta isEqualType []}) then {
			_className = _meta param [0, _className];
			if (isNil "_instanceID") then {_instanceID = _meta param [1, -1]};
			if (isNil "_ADDON_PREFX") then {_ADDON_PREFX = _meta param [2, SPREFX]};
			_class = [_className] call FUNC(classExists);
		};
	};
	if (isNil "_instanceID") then {_instanceID = -1};

	private _fieldPrefix = if !(_class isEqualTo false) then {
		_class getOrDefault ["fieldPrefix", format ["%1%2", VAR_PREFIX, _class getOrDefault ["varsPrefix", ""]]]
	} else {
		VAR_PREFIX
	};
	private _fieldSuffix = if (_instanceID < 0) then {""} else {"_" + str _instanceID};
	_selfNamespace setVariable [_fieldPrefix + _name + _fieldSuffix, _NIL(_val), _target];
};

CFUNC(getVar) = {
	private _outerInstanceID = _NIL(_instanceIndex);
	private _outerAddonPrefx = IF_NIL(_ADDON_PREFX, nil);
	params ["_selfNamespace", "_className", "_name", ["_def", nil], ["_instanceID", _NIL(_outerInstanceID)], ["_ADDON_PREFX", _NIL(_outerAddonPrefx)]];

	private _class = [_className] call FUNC(classExists);
	if (_class isEqualTo false) then {
		private _meta = _selfNamespace getVariable _className;
		if (!(isNil "_meta") && {_meta isEqualType []}) then {
			_className = _meta param [0, _className];
			if (isNil "_instanceID") then {_instanceID = _meta param [1, -1]};
			if (isNil "_ADDON_PREFX") then {_ADDON_PREFX = _meta param [2, SPREFX]};
			_class = [_className] call FUNC(classExists);
		};
	};
	if (isNil "_instanceID") then {_instanceID = -1};

	private _fieldPrefix = if !(_class isEqualTo false) then {
		_class getOrDefault ["fieldPrefix", format ["%1%2", VAR_PREFIX, _class getOrDefault ["varsPrefix", ""]]]
	} else {
		VAR_PREFIX
	};
	private _fieldSuffix = if (_instanceID < 0) then {""} else {"_" + str _instanceID};
	_selfNamespace getVariable [_fieldPrefix + _name + _fieldSuffix, _NIL(_def)]
};
