

extern "C"{
#include "lua.h"
#include "lauxlib.h"
}

#ifdef _MSC_VER
#define RVO2_API __declspec(dllexport)
#else
#define RVO2_API
#endif

#include "RVOSimulator.h"
#include "Vector2.h"
#include <vector>

static RVO::RVOSimulator *sim = NULL;

#define CHECK_SIM if (!sim) {\
	return luaL_error(L, "no rvo sim");\
}\

//float timeStep, float neighborDist, size_t maxNeighbors, 
//float timeHorizon, float timeHorizonObst, float radius, float maxSpeed, const Vector2 &velocity
static int
_new_social(lua_State *L) {
	sim = new RVO::RVOSimulator();
	return 0;
}

static int
_time_step(lua_State *L) {
	CHECK_SIM

	if (lua_isnoneornil(L, 1)) {
		lua_pushnumber(L, sim->getTimeStep());
		return 1;
	}
	sim->setTimeStep(lua_tonumber(L, 1));
	return 0;
}

static int
_default_agent(lua_State *L) {
	CHECK_SIM

	float neighbor_dist = lua_tonumber(L, 1);
	int max_neighbors = lua_tointeger(L, 2);
	float time_horizon = lua_tonumber(L, 3);
	float time_horizon_obst = lua_tonumber(L, 4);
	float radius = lua_tonumber(L, 5);
	float max_speed = lua_tonumber(L, 6);
	float vx = luaL_optnumber(L, 7, 0.0);
	float vy = luaL_optnumber(L, 8, 0.0);
	sim->setAgentDefaults(neighbor_dist, max_neighbors, time_horizon, 
												time_horizon_obst, radius, max_speed, RVO::Vector2(vx, vy));  
	return 0;
}

static int
_add_agent(lua_State *L) {
	CHECK_SIM

	int n = lua_gettop(L);
	float x = lua_tonumber(L, 1);
	float y = lua_tonumber(L, 2);

	int id;
	if (n == 2) {
		id = sim->addAgent(RVO::Vector2(x, y));
	} else if (n == 8 || n == 10) {
		float neighbor_dist = lua_tonumber(L, 3);
		int max_neighbors = lua_tointeger(L, 4);
		float time_horizon = lua_tonumber(L, 5);
		float time_horizon_obst = lua_tonumber(L, 6);
		float radius = lua_tonumber(L, 7);
		float max_speed = lua_tonumber(L, 8);
		float vx = luaL_optnumber(L, 9, 0.0);
		float vy = luaL_optnumber(L, 10, 0.0);
		id = sim->addAgent(RVO::Vector2(x, y), neighbor_dist, max_neighbors, time_horizon,
				time_horizon_obst, radius, max_speed, RVO::Vector2(vx, vy));
	} else {
		return luaL_error(L, "add_agent args count error");
	}
	lua_pushinteger(L, id);
	return 1;
}

static int
_add_obstacle(lua_State *L) {
	CHECK_SIM

	int n = lua_gettop(L);
	if (n % 2 != 0)
		return luaL_error(L, "add_obstacle args count must be even");

	std::vector<RVO::Vector2> obstacle;
	for (int i = 0; i < n/2; i++)
	{
		float x = lua_tonumber(L, 2 * i + 1);
		float y = lua_tonumber(L, 2 * i + 2);
		obstacle.push_back(RVO::Vector2(x, y));
	}

	int no = sim->addObstacle(obstacle);
	if (no == RVO::RVO_ERROR)
		no = -1;
	lua_pushinteger(L, no);

	return 1;
}

static int
_process_obstacle(lua_State *L) {
	CHECK_SIM

	sim->processObstacles();
	return 0;
}

static int
_update(lua_State *L) {
	CHECK_SIM
	sim->doStep();
	return 0;
}

static int
_del_social(lua_State *L) {
	if (sim) {
		delete sim;
		sim = NULL;
	}
	return 0;
}

static int
_pre_velocity(lua_State *L) {
	CHECK_SIM

	int n = lua_gettop(L);
	int id = lua_tointeger(L, 1);
	if (n==1) {
		RVO::Vector2 v = sim->getAgentPrefVelocity(id);
		lua_pushnumber(L, v.x());
		lua_pushnumber(L, v.y());
		return 2;
	} else if (n==3) {
		float x = lua_tonumber(L, 2);
		float y = lua_tonumber(L, 3);
		sim->setAgentPrefVelocity(id, RVO::Vector2(x, y));
		return 0;
	} else {
		return luaL_error(L, "pre_velocity args count error");
	}
}

static int
_velocity(lua_State *L) {
	CHECK_SIM
		
	int n = lua_gettop(L);
	int id = lua_tointeger(L, 1);
	if (n==1) {
		RVO::Vector2 pos = sim->getAgentVelocity(id);
		lua_pushnumber(L, pos.x());
		lua_pushnumber(L, pos.y());
		return 2;
	} else if (n==3) {
		float x = lua_tonumber(L, 2);
		float y = lua_tonumber(L, 3);
		sim->setAgentVelocity(id, RVO::Vector2(x, y));
		return 0;
	} else {
		return luaL_error(L, "velocity args count error");
	}
}

static int
_max_speed(lua_State *L) {
	CHECK_SIM
		
	int n = lua_gettop(L);
	int id = lua_tointeger(L, 1);
	if (n==1) {
		float ms = sim->getAgentMaxSpeed(id);
		lua_pushnumber(L, ms);
		return 1;
	} else if (n==2) {
		float ms = lua_tonumber(L, 2);
		sim->setAgentMaxSpeed(id, ms);
		return 0;
	} else {
		return luaL_error(L, "max_speed args count error");
	}
}

static int
_radius(lua_State *L) {
	CHECK_SIM
		
	int n = lua_gettop(L);
	int id = lua_tointeger(L, 1);
	if (n==1) {
		float ms = sim->getAgentRadius(id);
		lua_pushnumber(L, ms);
		return 1;
	} else if (n==2) {
		float ms = lua_tonumber(L, 2);
		sim->setAgentRadius(id, ms);
		return 0;
	} else {
		return luaL_error(L, "raduis args count error");
	}
}

static int
_time_hori(lua_State *L) {
	CHECK_SIM
		
	int n = lua_gettop(L);
	int id = lua_tointeger(L, 1);
	if (n==1) {
		float ms = sim->getAgentTimeHorizon(id);
		lua_pushnumber(L, ms);
		return 1;
	} else if (n==2) {
		float ms = lua_tonumber(L, 2);
		sim->setAgentTimeHorizon(id, ms);
		return 0;
	} else {
		return luaL_error(L, "time_hori args count error");
	}
}

static int
_time_hori_obst(lua_State *L) {
	CHECK_SIM
		
	int n = lua_gettop(L);
	int id = lua_tointeger(L, 1);
	if (n==1) {
		float ms = sim->getAgentTimeHorizonObst(id);
		lua_pushnumber(L, ms);
		return 1;
	} else if (n==2) {
		float ms = lua_tonumber(L, 2);
		sim->setAgentTimeHorizonObst(id, ms);
		return 0;
	} else {
		return luaL_error(L, "time_hori_obst args count error");
	}
}

static int
_max_neighbors(lua_State *L) {
	CHECK_SIM
		
	int n = lua_gettop(L);
	int id = lua_tointeger(L, 1);
	if (n==1) {
		float ms = sim->getAgentMaxNeighbors(id);
		lua_pushnumber(L, ms);
		return 1;
	} else if (n==2) {
		float ms = lua_tonumber(L, 2);
		sim->setAgentMaxNeighbors(id, ms);
		return 0;
	} else {
		return luaL_error(L, "max_neighbors args count error");
	}
}

static int
_position(lua_State *L) {
	CHECK_SIM
		
	int n = lua_gettop(L);
	int id = lua_tointeger(L, 1);
	if (n==1) {
		RVO::Vector2 pos = sim->getAgentPosition(id);
		lua_pushnumber(L, pos.x());
		lua_pushnumber(L, pos.y());
		return 2;
	} else if (n==3) {
		float x = lua_tonumber(L, 2);
		float y = lua_tonumber(L, 3);
		sim->setAgentPosition(id, RVO::Vector2(x, y));
		return 0;
	} else {
		return luaL_error(L, "position args count error");
	}
}

static int
_agent_neighbors_num(lua_State *L) {
	CHECK_SIM
		
	int id = lua_tointeger(L, 1);
	size_t num = sim->getAgentNumAgentNeighbors(id);
	lua_pushinteger(L, num);
	return 1;
}

static int
_get_agent_neighbor(lua_State *L) {
	CHECK_SIM

	int id = lua_tointeger(L, 1);
	int idx = lua_tointeger(L, 2)-1;
	
	int nid = sim->getAgentAgentNeighbor(id, idx);
	lua_pushinteger(L, nid);
	return 1;
}

extern "C" RVO2_API int luaopen_rvo2 (lua_State* L) {
	
	luaL_Reg l[] = {
		{ "new_social", _new_social},
		{ "del_social", _del_social},
		{ "time_step", _time_step},
		{ "default_agent", _default_agent},
		{ "add_agent", _add_agent},
		{ "add_obstacle", _add_obstacle},
		{ "process_obstacle", _process_obstacle},
		{ "update", _update},

		{ "agent_neighbors_num", _agent_neighbors_num },
		{ "get_agent_neighbor", _get_agent_neighbor },

		{ "pre_velocity", _pre_velocity},
		{ "velocity", _velocity},
		{ "max_speed", _max_speed},
		{ "position", _position},
		{ "radius", _radius},
		{ "time_hori", _time_hori},
		{ "time_hori_obst", _time_hori_obst},
		{ "max_neighbors", _max_neighbors},
		{ NULL, NULL },
	};
	luaL_newlib(L,l);
	
	return 1;
}
