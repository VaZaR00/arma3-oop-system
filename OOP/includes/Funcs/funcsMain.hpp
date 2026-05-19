class Main
{
    class XEH_postInit {
        file = FUNC_PATH(XEH_postInit.sqf);
        DO_FUNC_RECOMPILE
        postInit = 1;
    };
    class XEH_preInit {
        file = FUNC_PATH(XEH_preInit.sqf);
        DO_FUNC_RECOMPILE
        preInit = 1;
    };
    class XEH_prep {
        file = FUNC_PATH(XEH_prep.sqf);
        DO_FUNC_RECOMPILE
        FUNC_PRE_START
    };
};