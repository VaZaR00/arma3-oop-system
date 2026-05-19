#include "defines.hpp"

#define FOLDER_PATH(path) _path = STR(path);
#define PREP(name) [STR(name), _path] call _compileFunc;

private _compileFunc = {
	params["_name", ["_folderPath", ""]];

	if (_folderPath != "") then {
		_folderPath = _folderPath + "\";
	};
	private _funcPath = format["%1\%2fn_%3.sqf", STR(ADDON_PATH), _folderPath, _name];
	private _func = compile preprocessFileLineNumbers _funcPath;
	private _funcName = SFUNC_NAME(_name);

#ifdef FINAL
	missionNamespace setVariable [_funcName, compileFinal _func];
#endif
#ifndef FINAL
	missionNamespace setVariable [_funcName, _func];
#endif
};

private _path = "";

#include "PREP.hpp"
