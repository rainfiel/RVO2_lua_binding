#ifndef _INC_VECTOR2
#define _INC_VECTOR2

#include <math.h>

#define HYP_EPSILON 1E-5
#define HYP_FLOAT float
#define HYP_ABS(value) (((value) < 0) ? -(value) : (value))
#define HYP_SQRT(number) ((HYP_FLOAT)sqrt(number))

struct vector2
{
	union
		{
		HYP_FLOAT v[2];
		struct
			{
			HYP_FLOAT x, y;
			};
		};
};


int vector2_equals(const struct vector2 *self, const struct vector2 *vT);

struct vector2 *vector2_zero(struct vector2 *self);
struct vector2 *vector2_set(struct vector2 *self, const struct vector2 *vT);
struct vector2 *vector2_setf2(struct vector2 *self, HYP_FLOAT xT, HYP_FLOAT yT);
struct vector2 *vector2_negate(struct vector2 *self);
struct vector2 *vector2_add(struct vector2 *self, const struct vector2 *vT);
struct vector2 *vector2_addf(struct vector2 *self, HYP_FLOAT fT);
struct vector2 *vector2_subtract(struct vector2 *self, const struct vector2 *vT);
struct vector2 *vector2_subtractf(struct vector2 *self, HYP_FLOAT fT);
struct vector2 *vector2_multiply(struct vector2 *self, const struct vector2 *vT);
struct vector2 *vector2_multiplyf(struct vector2 *self, HYP_FLOAT fT);
struct vector2 *vector2_multiplym3(struct vector2 *self, const struct matrix3 *mT);
struct vector2 *vector2_divide(struct vector2 *self, const struct vector2 *vT);
struct vector2 *vector2_dividef(struct vector2 *self, HYP_FLOAT fT);
struct vector2 *vector2_limit(struct vector2 *self, HYP_FLOAT lim);

struct vector2 *vector2_normalize(struct vector2 *self);
HYP_FLOAT vector2_magnitude(const struct vector2 *self);
HYP_FLOAT vector2_distance(const struct vector2 *v1, const struct vector2 *v2);

HYP_FLOAT vector2_dot_product(const struct vector2 *self, const struct vector2 *vT);
struct vector2 *vector2_cross_product(struct vector2 *vR, const struct vector2 *vT1, const struct vector2 *vT2);

HYP_FLOAT vector2_angle_between(const struct vector2 *self, const struct vector2 *vT);
struct vector2 *vector2_find_normal_axis_between(struct vector2 *vR, const struct vector2 *vT1, const struct vector2 *vT2);

/* the length is the same as "magnitude" */
#define vector2_length(v) vector2_magnitude(v)

#ifndef DOXYGEN_SHOULD_SKIP_THIS

/* BETA aliases */
#define vec2 struct vector2

#endif /* DOXYGEN_SHOULD_SKIP_THIS */

#endif /* _INC_VECTOR2 */
