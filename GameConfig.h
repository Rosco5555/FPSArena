// GameConfig.h - All game constants
#ifndef GAMECONFIG_H
#define GAMECONFIG_H

// Physics
static const float GRAVITY = 0.008f;
static const float MOVE_ACCEL = 0.008f;
static const float MOVE_FRICTION = 0.88f;
static const float MAX_SPEED = 0.15f;
static const float JUMP_VELOCITY = 0.20f;
static const float PLAYER_HEIGHT = 1.7f;
static const float PLAYER_RADIUS = 0.3f;

// Combat
static const int PLAYER_MAX_HEALTH = 100;
static const int ENEMY_MAX_HEALTH = 30;
static const int PLAYER_DAMAGE = 15;  // 2 shots to kill enemy
static const int ENEMY_DAMAGE = 20;   // 5 shots to kill player
static const int NUM_ENEMIES = 4;
static const int PLAYER_FIRE_RATE = 8;
static const int ENEMY_FIRE_RATE_MIN = 30;
static const int ENEMY_FIRE_RATE_VAR = 20;
static const int PLAYER_REGEN_DELAY = 120;  // frames before regen starts (~2 sec at 60fps)
static const int PLAYER_REGEN_RATE = 6;     // frames between each health point (~10 hp/sec)

// Rendering
static const float FOV = 1.0472f;  // ~60 degrees
static const float NEAR_PLANE = 0.1f;
static const float FAR_PLANE = 100.0f;
static const float MOUSE_SENSITIVITY = 0.005f;
static const float ASPECT_RATIO = 800.0f / 600.0f;

// Gun positioning
static const float GUN_SCREEN_X = 0.55f;
static const float GUN_SCREEN_Y = -0.65f;
static const float GUN_SCREEN_Z = 0.2f;
static const float GUN_SCALE = 3.5f;

// World
static const float FLOOR_Y = -1.0f;
static const float ARENA_SIZE = 10.0f;

// Cover walls
static const float WALL1_X = 2.0f;
static const float WALL1_Z = 1.0f;
static const float WALL2_X = -2.0f;
static const float WALL2_Z = 3.0f;
static const float WALL_WIDTH = 2.0f;
static const float WALL_HEIGHT = 2.0f;
static const float WALL_DEPTH = 0.3f;

// House configuration
static const float HOUSE_X = 0.0f;
static const float HOUSE_Z = -3.0f;
static const float HOUSE_WIDTH = 5.0f;
static const float HOUSE_DEPTH = 4.0f;
static const float HOUSE_WALL_HEIGHT = 3.0f;
static const float HOUSE_WALL_THICK = 0.2f;
static const float DOOR_WIDTH = 1.2f;
static const float DOOR_HEIGHT = 2.2f;
static const float DOOR_THICK = 0.1f;

// Start positions
static const float PLAYER_START_X = 0.0f;
static const float PLAYER_START_Z = 0.0f;  // Inside house center

// Enemy start positions
static const float ENEMY_START_X[NUM_ENEMIES] = {5.0f, -5.0f, 0.0f, 6.0f};
static const float ENEMY_START_Y[NUM_ENEMIES] = {-0.4f, -0.4f, -0.4f, -0.4f};
static const float ENEMY_START_Z[NUM_ENEMIES] = {5.0f, 4.0f, 7.0f, -6.0f};

#endif // GAMECONFIG_H
