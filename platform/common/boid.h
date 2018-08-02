#ifndef _BOID_H
#define _BOID_H
#include "vector2.h"

#define STATUS_IDLE 0
#define STATUS_MOVE 1
#define STATUS_STATIC 2

struct boid {
	struct vector2 location;
	struct vector2 velocity;
	struct vector2 acceleration;
	float r;
	float maxforce;
	float maxspeed;
	float neighbourDistance;
	float boidSeperation;
        
	float s, a, c, t, ra;

	int status;
	struct vector2 target;
	struct boid* next;
	struct boid* prev;
};

struct social {
	int size;
	struct boid* boid_pool;
	struct boid* free_list;
};

struct social* social_init();
void social_free(struct social*);
struct boid* social_add_life(struct social*);
void social_del_life(struct social*, struct boid*);
void social_update(struct social*);

void boid_flock(struct boid* b, struct boid* boids);
void boid_step(struct boid*);

#endif