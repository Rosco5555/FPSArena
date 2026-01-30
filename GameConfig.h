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

// Crouching
static const float CROUCH_HEIGHT = 1.0f;           // Height when crouched
static const float CROUCH_SPEED_MULTIPLIER = 0.5f; // Move at 50% speed when crouched
static const float CROUCH_TRANSITION_SPEED = 0.1f; // How fast to transition to/from crouch

// Strafing
static const float STRAFE_MULTIPLIER = 1.8f;       // Strafe speed multiplier

// Combat
static const int PLAYER_MAX_HEALTH = 100;
static const int ENEMY_MAX_HEALTH = 30;
static const int PLAYER_DAMAGE = 15;  // 2 shots to kill enemy
static const int ENEMY_DAMAGE = 20;   // 5 shots to kill player
static const int NUM_ENEMIES = 6;
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

// ============================================
// MILITARY BASE MAP CONFIGURATION
// ============================================

// World
static const float FLOOR_Y = -1.0f;
static const float ARENA_SIZE = 20.0f;  // 40x40 unit arena (half-size for calculations)

// Vertical levels
static const float GROUND_LEVEL = -1.0f;      // y=0 (FLOOR_Y)
static const float PLATFORM_LEVEL = 2.0f;     // y=3 (towers, catwalks)
static const float ROOF_LEVEL = 5.0f;         // y=6 (command building roof)
static const float BASEMENT_LEVEL = -4.0f;    // y=-3 (bunker)

// Command Building (center, 2-story)
static const float CMD_BUILDING_X = 0.0f;
static const float CMD_BUILDING_Z = 0.0f;
static const float CMD_BUILDING_WIDTH = 8.0f;
static const float CMD_BUILDING_DEPTH = 6.0f;
static const float CMD_BUILDING_HEIGHT = 6.0f;  // 2 stories
static const float CMD_WALL_THICK = 0.3f;
static const float CMD_DOOR_WIDTH = 1.5f;
static const float CMD_DOOR_HEIGHT = 2.5f;
static const float CMD_WINDOW_WIDTH = 1.2f;
static const float CMD_WINDOW_HEIGHT = 1.0f;

// Guard Towers (4 corners)
static const float TOWER_SIZE = 3.0f;
static const float TOWER_HEIGHT = 3.0f;
static const float TOWER_OFFSET = 15.0f;  // Distance from center to tower
static const float RAMP_WIDTH = 1.5f;
static const float RAMP_LENGTH = 4.0f;

// Catwalks (connecting towers)
static const float CATWALK_WIDTH = 1.2f;
static const float CATWALK_THICK = 0.15f;
static const float CATWALK_RAIL_HEIGHT = 1.0f;

// Bunker (underground)
static const float BUNKER_X = -10.0f;
static const float BUNKER_Z = 10.0f;
static const float BUNKER_WIDTH = 6.0f;
static const float BUNKER_DEPTH = 6.0f;
static const float BUNKER_HEIGHT = 3.0f;
static const float BUNKER_STAIR_WIDTH = 2.0f;

// Cargo Containers
static const float CONTAINER_LENGTH = 4.0f;
static const float CONTAINER_WIDTH = 2.0f;
static const float CONTAINER_HEIGHT = 2.5f;

// Sandbag Walls
static const float SANDBAG_LENGTH = 3.0f;
static const float SANDBAG_HEIGHT = 1.2f;
static const float SANDBAG_THICK = 0.5f;

// ============================================
// SPAWN PROTECTION CONFIGURATION
// ============================================

static const float SPAWN_PROTECTION_RADIUS = 8.0f;  // Enemies stay away from spawn points

// ============================================
// BOT AI CONFIGURATION
// ============================================

static const int NUM_WAYPOINTS = 12;
static const float BOT_DETECTION_RANGE = 25.0f;
static const float BOT_CHASE_RANGE = 20.0f;
static const float BOT_STRAFE_RANGE = 10.0f;
static const float BOT_COVER_HEALTH_THRESHOLD = 0.5f;   // 50% health (take cover earlier)
static const float BOT_RETREAT_HEALTH_THRESHOLD = 0.2f; // 20% health
static const float BOT_WAYPOINT_REACH_DIST = 1.5f;
static const float BOT_ACCELERATION = 0.015f;
static const float BOT_FRICTION = 0.92f;
static const float BOT_JUMP_COOLDOWN = 60;  // frames between jumps

// Waypoints around the military base for bot patrol
static const float WAYPOINT_X[NUM_WAYPOINTS] = {
    15.0f, 15.0f, 0.0f, -15.0f, -15.0f, -15.0f, 0.0f, 15.0f, 8.0f, -8.0f, 5.0f, -5.0f
};
static const float WAYPOINT_Z[NUM_WAYPOINTS] = {
    0.0f, 15.0f, 15.0f, 15.0f, 0.0f, -15.0f, -15.0f, -15.0f, 8.0f, -8.0f, 0.0f, 0.0f
};

// Cover positions (near structures)
static const int NUM_COVER_POINTS = 8;
static const float COVER_X[NUM_COVER_POINTS] = {6.0f, -6.0f, 10.0f, -10.0f, 5.0f, -5.0f, 12.0f, -12.0f};
static const float COVER_Z[NUM_COVER_POINTS] = {4.0f, 4.0f, 8.0f, 8.0f, -4.0f, -4.0f, -10.0f, -10.0f};

// Bot stats by difficulty [Easy, Medium, Hard]
static const float BOT_MOVE_SPEED[3] = {0.03f, 0.05f, 0.07f};
static const float BOT_ACCURACY[3] = {0.35f, 0.50f, 0.70f};
static const int BOT_REACTION_TIME[3] = {90, 60, 30};  // frames
static const float BOT_AGGRESSION[3] = {0.2f, 0.4f, 0.7f};

// Engagement limits (rebalanced for fairer gameplay)
static const float BOT_ENGAGEMENT_DISTANCE = 20.0f;    // Max distance to engage player
static const int BOT_SPOTTING_DELAY = 30;              // Frames bot must see player before shooting
static const int BOT_LOSE_SIGHT_TIMEOUT = 180;         // Frames (3 sec at 60fps) before breaking pursuit
static const int BOT_ACTIVATION_INTERVAL = 1800;       // Frames (30 sec) between activating new enemies
static const int BOT_INITIAL_ACTIVE_COUNT = 3;         // Number of enemies active at game start

// ============================================
// LEGACY CONSTANTS (kept for compatibility)
// ============================================

// Cover walls (replaced by new structures but kept for collision compatibility)
static const float WALL1_X = 6.0f;
static const float WALL1_Z = 8.0f;
static const float WALL2_X = -6.0f;
static const float WALL2_Z = 8.0f;
static const float WALL_WIDTH = 2.0f;
static const float WALL_HEIGHT = 2.0f;
static const float WALL_DEPTH = 0.3f;

// House configuration (replaced by command building, kept for door system compatibility)
static const float HOUSE_X = 0.0f;
static const float HOUSE_Z = 0.0f;
static const float HOUSE_WIDTH = 8.0f;
static const float HOUSE_DEPTH = 6.0f;
static const float HOUSE_WALL_HEIGHT = 6.0f;
static const float HOUSE_WALL_THICK = 0.3f;
static const float DOOR_WIDTH = 1.5f;
static const float DOOR_HEIGHT = 2.5f;
static const float DOOR_THICK = 0.15f;

// Start positions
static const float PLAYER_START_X = 0.0f;
static const float PLAYER_START_Z = 12.0f;  // Outside command building

// Enemy start positions (spread across the military base at various elevations)
static const float ENEMY_START_X[NUM_ENEMIES] = {14.0f, -14.0f, 8.0f, -8.0f, 14.0f, -14.0f};
static const float ENEMY_START_Y[NUM_ENEMIES] = {-0.4f, -0.4f, -0.4f, -0.4f, 2.6f, 2.6f};  // Last two on platforms
static const float ENEMY_START_Z[NUM_ENEMIES] = {14.0f, 14.0f, -10.0f, -10.0f, -14.0f, -14.0f};

// Enemy difficulty levels (0=Easy, 1=Medium, 2=Hard)
// Rebalanced: 3 Easy, 2 Medium, 1 Hard for fairer gameplay
static const int ENEMY_DIFFICULTY[NUM_ENEMIES] = {0, 0, 0, 1, 1, 2};

#endif // GAMECONFIG_H
