
#include <string.h>
#include <stdlib.h>
#include "boid.h"

struct social* social_init() {
	size_t tsize = sizeof(struct social);
	struct social* s = (struct social*)malloc(tsize);
	if (!s) return NULL;
	memset(s, 0, tsize);
	return s;
}

void social_free(struct social* s) {
	if (!s) return;
	struct boid* head = s->boid_pool;
	while (head) {
		struct boid* next = head->next;
		free(head);
		head = next;
	}

	head = s->free_list;
	while (head) {
		struct boid* next = head->next;
		free(head);
		head = next;
	}
}

struct boid* social_add_life(struct social* s) {
	struct boid* b;
	size_t tsize = sizeof(struct boid);

	if (s->free_list) {
		b = s->free_list;
		s->free_list = b->next;
		s->free_list->prev = 0;
		b->next = 0;
		b->prev = 0;
	} else {
		b = (struct boid*)malloc(tsize);
	}
	if (!b) return NULL;

	memset(b, 0, tsize);
	b->next = s->boid_pool;
	b->prev = 0;
	if (s->boid_pool)
		s->boid_pool->prev = b;
	s->boid_pool = b;
	return b;
}

void social_del_life(struct social* s, struct boid* b) {
	if (b->prev)
		b->prev->next = b->next;
	if (b->next)
		b->next->prev = b->prev;

	b->next = s->free_list;
	b->prev = 0;
	if (s->free_list)
		s->free_list->prev = b;
	s->free_list = b;
}

void social_update(struct social* s) {
	struct boid* head = s->boid_pool;
	while (head) {
		boid_flock(head, s->boid_pool);
		head = head->next;
	}

	head = s->boid_pool;
	while (head)
	{
		boid_step(head);
		head = head->next;
	}
}

//boids
//----------------------------------------------------------------------------------------------
static void apply_force(struct boid* b, struct vector2 force) {
	vector2_add(&b->acceleration, &force);
}

static void seperate(struct boid* b, struct boid* boids, struct vector2* steer) {
	vector2_zero(steer);
	int count = 0;
	struct boid* head = boids;
	struct vector2 diff;
	
	// for every boid in system, check if it is too close
	while (head) {
		if (head != b) {
			float d = vector2_distance(&b->location, &head->location);
			if (d > 0 && d < b->boidSeperation) {
				vector2_set(&diff, &b->location);
				vector2_subtract(&diff, &head->location);
				vector2_normalize(&diff);
				vector2_dividef(&diff, d);
				vector2_add(steer, &diff);
				count++;
			}
		}
		head = head->next;
	}
    
	// average
	if (count > 0)
		vector2_dividef(steer, (float)count);

	float magnitude = vector2_magnitude(steer);
	if (magnitude > 0) {
		vector2_dividef(steer, magnitude);
		vector2_multiplyf(steer, b->maxspeed);
		vector2_subtract(steer, &b->velocity);
		vector2_limit(steer, b->maxforce);
	}
}

static void align(struct boid* b, struct boid* boids, struct vector2* steer) {
	vector2_zero(steer);
	int count = 0;
	struct boid* head = boids;
	
	while (head) {
		if (head != b) {
			float d = vector2_distance(&b->location, &head->location);
			if ((d > 0) && (d < b->neighbourDistance) && d > b->boidSeperation+2) {
				vector2_add(steer, &head->velocity);
				count++;
			}
		}
		head = head->next;
	}
    
	// average
	if (count > 0)
		vector2_dividef(steer, (float)count);

	float magnitude = vector2_magnitude(steer);
	if (magnitude > 0) {
		vector2_dividef(steer, magnitude);
		vector2_multiplyf(steer, b->maxspeed);
		vector2_subtract(steer, &b->velocity);
		vector2_limit(steer, b->maxforce);
	}
}

static void seek(struct boid* b, struct vector2* steer) {
	struct vector2 target;
	vector2_set(&target, steer);
	struct vector2 desired;
	vector2_set(&desired, &target);
	vector2_subtract(&desired, &b->location);
	float d = vector2_distance(&target, &b->location);
	if (d > 0) {
		vector2_dividef(&desired, d);
		vector2_multiplyf(&desired, b->maxspeed);

		vector2_set(steer, &desired);
		vector2_subtract(steer, &b->velocity);
		vector2_limit(steer, b->maxforce);
	} else {
		vector2_zero(steer);
	}
}

static void cohesion(struct boid* b, struct boid* boids, struct vector2* steer) {
	vector2_zero(steer);
	int count = 0;
	struct boid* head = boids;
	
	while (head) {
		if (head != b) {
			float d = vector2_distance(&b->location, &head->location);
			if ((d > 0) && (d < b->neighbourDistance) && d > b->boidSeperation+2) {
				vector2_add(steer, &head->location);
				count++;
			}
		}
		head = head->next;
	}
    
	if (count > 0) {
		vector2_add(steer, &b->location);
		count++;
		vector2_dividef(steer, (float)count);
		seek(b, steer);
	}	else {
		vector2_zero(steer);
	}
}

static void tend_to_place(struct boid* b, struct vector2* target, struct vector2* steer) {
	vector2_set(steer, target);
	vector2_subtract(steer, &b->location);
	if (vector2_magnitude(steer) < 1) {
		if (b->status == STATUS_MOVE){
			b->status = STATUS_IDLE;
			vector2_zero(&b->velocity);
		}
		vector2_zero(steer);
	} else
		vector2_dividef(steer, 100.0);
}

void boid_step(struct boid* b) {
//	if (b->acceleration.x == 0 && b->acceleration.y == 0)
//		vector2_zero(&b->velocity);
	vector2_add(&b->velocity, &b->acceleration);
	vector2_limit(&b->velocity, b->maxspeed);
	vector2_add(&b->location, &b->velocity);
	vector2_zero(&b->acceleration);
}

void boid_flock(struct boid* b, struct boid* boids) {
	struct vector2 force;
	
	if (b->status != STATUS_STATIC) {
		seperate(b, boids, &force);
		vector2_multiplyf(&force, b->s);
		apply_force(b, force);
	}

	if (b->status == STATUS_MOVE) {
		align(b, boids, &force);
		vector2_multiplyf(&force, b->a);
		apply_force(b, force);

		cohesion(b, boids, &force);
		vector2_multiplyf(&force, b->c);
		apply_force(b, force);

		tend_to_place(b, &b->target, &force);
		vector2_multiplyf(&force, b->t);
		apply_force(b, force);
	}

	boid_step(b);
}
