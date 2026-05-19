#include "includes\defines.hpp"

class CfgPatches {
	class PREFX {
		name = "OOP System";
		author = "Vazar";
		requiredAddons[] = {
			// "cba_common",
			"A3_Functions_F"
		};
		units[] = {};
		weapons[] = {};
        skipWhenMissingDependencies = 1;
	};
};

#include "includes\CfgFunctions.hpp"
#include "includes\cfgRemoteExec.hpp"
#include "includes\configIncludes.hpp"