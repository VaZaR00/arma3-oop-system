#include "defines.hpp"

#define FOLDER_PATH(path) _path = STR(path);
#define PREP(name) [STR(name), _path] call _compileFunc;

#ifdef FINAL
#define COMPILE_C compileFinal
#else
#define COMPILE_C compile
#endif

private _cFuncs = [];
private _path = "";

private _compileFunc = {
	params ["_name", ["_folderPath", ""]];

	if (_folderPath != "") then {
		_folderPath = _folderPath + "\";
	};
	private _funcName = SFUNC_NAME(_name);

#ifdef FINAL
	private _cached = uiNamespace getVariable _funcName;
	if !(isNil "_cached") exitWith {
		missionNamespace setVariable [_funcName, _cached];
	};
#endif

	private _funcPath = format ["%1\%2fn_%3.sqf", STR(ADDON_PATH), _folderPath, _name];
	private _scriptStr = preprocessFileLineNumbers _funcPath;
	private _funcStr = format [
		"private _fnc_scriptNameParent = if (isNil '_fnc_scriptName') then {'%1'} else {_fnc_scriptName}; private _fnc_scriptName = '%1'; scriptName _fnc_scriptName; %2",
		_funcName,
		_scriptStr
	];
	private _compiled = COMPILE_C _funcStr;

	missionNamespace setVariable [_funcName, _compiled];
	uiNamespace setVariable [_funcName, _compiled];
};

#ifdef DEV
FUNC(compileFunc) = _compileFunc;
PREP(compile);
#endif

#include "PREP.hpp"
#include "fn_compile.sqf"

#ifdef FINAL
{
	_x params ["_funcVar", "_funcName"];
	private _compiled = COMPILE_C (call COMPILE_C _funcVar);
	missionNamespace setVariable [_funcName, _compiled];
	uiNamespace setVariable [_funcName, _compiled];
} forEach _cFuncs;
#endif
