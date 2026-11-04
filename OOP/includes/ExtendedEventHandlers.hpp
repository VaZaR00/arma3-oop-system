#ifdef ADDON
class Extended_PreInit_EventHandlers {
    class PREFX {
        init = CALL_FUNC_XEH(XEH_preInit.sqf);
    };
};
class Extended_PreStart_EventHandlers {
    class PREFX {
        init = CALL_FUNC_XEH(XEH_preStart.sqf);
    };
};

class Extended_PostInit_EventHandlers {
    class PREFX {
        init = CALL_FUNC_XEH(XEH_postInit.sqf);
    };
};
#endif