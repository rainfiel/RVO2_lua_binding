
#include <string.h>
#include <stdlib.h>
#include "boid.h"

#include "lua.h"
#include "lauxlib.h"

static int
_new_social(lua_State *L) {
	size_t tsize = sizeof(struct social);
	struct social* s = (struct social*)lua_newuserdata(L, tsize);
	memset(s, 0, tsize);
	return 1;
}

static int
_del_social(lua_State *L) {
	struct social* s = (struct social*)lua_touserdata(L, 1);
	social_free(s);
	return 0;
}

static int
_update(lua_State *L) {
	struct social* s = (struct social*)lua_touserdata(L, 1);
	social_update(s);
	return 0;
}

static int
_add_life(lua_State *L) {
	struct social* s = (struct social*)lua_touserdata(L, 1);
	float x = lua_tonumber(L, 2);
	float y = lua_tonumber(L, 3);

	struct boid* b = social_add_life(s);
	vector2_setf2(&b->location, x, y);
	lua_pushlightuserdata(L, (void*)b);
	return 1;
}

static int
_del_life(lua_State *L) {
	struct social* s = (struct social*)lua_touserdata(L, 1);
	struct boid* b = (struct boid*)lua_touserdata(L, 2);
	social_del_life(s, b);
	return 0;
}

static int
_get_data(lua_State *L) {
	struct boid* b = (struct boid*)lua_touserdata(L, 1);
	if (!b)
		return luaL_error(L, "invaid boid pointer");
	lua_pushnumber(L, b->location.x);
	lua_pushnumber(L, b->location.y);
	lua_pushnumber(L, b->velocity.x);
	lua_pushnumber(L, b->velocity.y);
	return 4;
}

static int
_set_maxforce(lua_State *L) {
	struct boid* b = (struct boid*)lua_touserdata(L, 1);
	if (!b)
		return luaL_error(L, "invaid boid pointer");

	b->maxforce = lua_tonumber(L, 2);
	return 0;
}

static int
_set_maxspeed(lua_State *L) {
	struct boid* b = (struct boid*)lua_touserdata(L, 1);
	if (!b)
		return luaL_error(L, "invaid boid pointer");

	b->maxspeed = lua_tonumber(L, 2);
	return 0;
}

static int
_set_neighbour_dist(lua_State *L) {
	struct boid* b = (struct boid*)lua_touserdata(L, 1);
	if (!b)
		return luaL_error(L, "invaid boid pointer");

	b->neighbourDistance = lua_tonumber(L, 2);
	return 0;
}

static int
_set_boid_seperation(lua_State *L) {
	struct boid* b = (struct boid*)lua_touserdata(L, 1);
	if (!b)
		return luaL_error(L, "invaid boid pointer");

	b->boidSeperation = lua_tonumber(L, 2);
	return 0;
}

static int
_set_flock_ratio(lua_State *L) {
	struct boid* b = (struct boid*)lua_touserdata(L, 1);
	if (!b)
		return luaL_error(L, "invaid boid pointer");
	
	b->s = lua_tointeger(L, 2);
	b->a = lua_tointeger(L, 3);
	b->c = lua_tointeger(L, 4);
	b->t = lua_tointeger(L, 5);
	return 0;
}

static int
_set_target(lua_State *L) {
	struct boid* b = (struct boid*)lua_touserdata(L, 1);
	if (!b)
		return luaL_error(L, "invaid boid pointer");
	
	float x = lua_tonumber(L, 2);
	float y = lua_tonumber(L, 3);
	vector2_setf2(&b->target, x, y);
	b->status = STATUS_MOVE;
	return 0;
}

int
luaopen_boid(lua_State *L) {
	luaL_Reg l[] = {
		{ "new_social", _new_social},
		{ "del_social", _del_social},
		{ "update", _update },
		{ "add_life", _add_life },
		{ "del_life", _del_life },
		{ "get_data", _get_data },
		{ "set_maxforce", _set_maxforce },
		{ "set_maxspeed", _set_maxspeed },
		{ "set_neighbour_dist", _set_neighbour_dist },
		{ "set_boid_seperation", _set_boid_seperation },
		{ "set_flock_ratio", _set_flock_ratio },
		{ "set_target", _set_target },
		{ NULL, NULL },
	};
	luaL_newlib(L,l);
	
	return 1;
}