
#include <lauxlib.h>

//int luaopen_xxx(lua_State* L);

//int luaopen_boid(lua_State *L);

#ifdef _MSC_VER
extern "C" {
  int luaopen_rvo2(lua_State *L);
}
#else
int luaopen_rvo2(lua_State *L);
#endif

static void
_register(lua_State *L, lua_CFunction func, const char * libname) {
  luaL_requiref(L, libname, func, 0);
  lua_pop(L, 1);
}

void init_user_lua_libs(lua_State *L) {
//	_register(L, luaopen_boid, "ejoy2dx.boid.c");
	_register(L, luaopen_rvo2, "ejoy2dx.rvo2.c");
}
