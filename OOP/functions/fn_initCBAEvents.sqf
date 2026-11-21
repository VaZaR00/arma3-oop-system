#include "defines.hpp"

#define LOG_CBA_EVENT
// #define LOG_CBA_EVENT [_NIL(_eventName), time, _NIL(_this), clientOwner] DLOG

#define WRAP_FUNC(f) {LOG_CBA_EVENT; _this call f}

[OOP_SPREF(callClassInstance), WRAP_FUNC(FUNC(callClassInstance))] call CBA_fnc_addEventHandler;

[OOP_SPREF(pushBack), {
	params ["_namespace", "_varname", "_element", ["_unique", true]];
	if (isNil "_namespace" || {isNil "_varname"} || {isNil "_element"}) exitWith {};
	if !(_namespace isEqualTypeAny [objNull, missionNamespace, grpNull, locationNull, displayNull, controlNull, teamMemberNull, taskNull]) exitWith {};
	private _array = _namespace getVariable [_varname, []];
	if !(_array isEqualType []) then {_array = []};
	if (_unique) then {
		_array pushBackUnique _element;
	} else {
		_array pushBack _element;
	};
	_namespace setVariable [_varname, _array];
}] call CBA_fnc_addEventHandler;

[OOP_SPREF(removeFromArray), {
	params ["_namespace", "_varname", "_element"];
	if (isNil "_namespace" || {isNil "_varname"} || {isNil "_element"}) exitWith {};
	if !(_namespace isEqualTypeAny [objNull, missionNamespace, grpNull, locationNull, displayNull, controlNull, teamMemberNull, taskNull]) exitWith {};
	private _array = _namespace getVariable [_varname, []];
	if !(_array isEqualType []) exitWith {};
	_namespace setVariable [_varname, _array - [_element]];
}] call CBA_fnc_addEventHandler;
