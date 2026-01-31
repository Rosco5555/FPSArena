// GeometryBuilder.m - All vertex buffer creation implementation
#import "GeometryBuilder.h"
#import "GameConfig.h"

// Helper macro for wall quads
#define QUAD(arr, idx, x0,y0,z0, x1,y1,z1, x2,y2,z2, x3,y3,z3, col) do { \
    arr[idx++] = (Vertex){{x0,y0,z0}, col}; \
    arr[idx++] = (Vertex){{x1,y1,z1}, col}; \
    arr[idx++] = (Vertex){{x2,y2,z2}, col}; \
    arr[idx++] = (Vertex){{x0,y0,z0}, col}; \
    arr[idx++] = (Vertex){{x2,y2,z2}, col}; \
    arr[idx++] = (Vertex){{x3,y3,z3}, col}; \
} while(0)

// Helper macro to create a 3D box
#define BOX3D(arr, idx, x0,y0,z0,x1,y1,z1,cFront,cBack,cRight,cLeft,cTop,cBot) do { \
    arr[idx++] = (Vertex){{x0,y0,z1},cFront}; \
    arr[idx++] = (Vertex){{x1,y0,z1},cFront}; \
    arr[idx++] = (Vertex){{x1,y1,z1},cFront}; \
    arr[idx++] = (Vertex){{x0,y0,z1},cFront}; \
    arr[idx++] = (Vertex){{x1,y1,z1},cFront}; \
    arr[idx++] = (Vertex){{x0,y1,z1},cFront}; \
    arr[idx++] = (Vertex){{x1,y0,z0},cBack}; \
    arr[idx++] = (Vertex){{x0,y0,z0},cBack}; \
    arr[idx++] = (Vertex){{x0,y1,z0},cBack}; \
    arr[idx++] = (Vertex){{x1,y0,z0},cBack}; \
    arr[idx++] = (Vertex){{x0,y1,z0},cBack}; \
    arr[idx++] = (Vertex){{x1,y1,z0},cBack}; \
    arr[idx++] = (Vertex){{x1,y0,z1},cRight}; \
    arr[idx++] = (Vertex){{x1,y0,z0},cRight}; \
    arr[idx++] = (Vertex){{x1,y1,z0},cRight}; \
    arr[idx++] = (Vertex){{x1,y0,z1},cRight}; \
    arr[idx++] = (Vertex){{x1,y1,z0},cRight}; \
    arr[idx++] = (Vertex){{x1,y1,z1},cRight}; \
    arr[idx++] = (Vertex){{x0,y0,z0},cLeft}; \
    arr[idx++] = (Vertex){{x0,y0,z1},cLeft}; \
    arr[idx++] = (Vertex){{x0,y1,z1},cLeft}; \
    arr[idx++] = (Vertex){{x0,y0,z0},cLeft}; \
    arr[idx++] = (Vertex){{x0,y1,z1},cLeft}; \
    arr[idx++] = (Vertex){{x0,y1,z0},cLeft}; \
    arr[idx++] = (Vertex){{x0,y1,z1},cTop}; \
    arr[idx++] = (Vertex){{x1,y1,z1},cTop}; \
    arr[idx++] = (Vertex){{x1,y1,z0},cTop}; \
    arr[idx++] = (Vertex){{x0,y1,z1},cTop}; \
    arr[idx++] = (Vertex){{x1,y1,z0},cTop}; \
    arr[idx++] = (Vertex){{x0,y1,z0},cTop}; \
    arr[idx++] = (Vertex){{x0,y0,z0},cBot}; \
    arr[idx++] = (Vertex){{x1,y0,z0},cBot}; \
    arr[idx++] = (Vertex){{x1,y0,z1},cBot}; \
    arr[idx++] = (Vertex){{x0,y0,z0},cBot}; \
    arr[idx++] = (Vertex){{x1,y0,z1},cBot}; \
    arr[idx++] = (Vertex){{x0,y0,z1},cBot}; \
} while(0)

@implementation GeometryBuilder

// ============================================
// MILITARY BASE MAP GEOMETRY
// ============================================

+ (id<MTLBuffer>)createCommandBuildingBufferWithDevice:(id<MTLDevice>)device vertexCount:(NSUInteger *)count {
    #define MAX_CMD_VERTS 5000
    Vertex verts[MAX_CMD_VERTS];
    int v = 0;

    // Colors - concrete gray theme
    simd_float3 wallExt = {0.45f, 0.45f, 0.48f};
    simd_float3 wallInt = {0.55f, 0.55f, 0.58f};
    simd_float3 wallDark = {0.35f, 0.35f, 0.38f};
    simd_float3 wallTop = {0.50f, 0.50f, 0.53f};
    simd_float3 roofTop = {0.40f, 0.42f, 0.45f};
    simd_float3 floorCol = {0.38f, 0.40f, 0.42f};
    simd_float3 windowFrame = {0.25f, 0.25f, 0.28f};
    simd_float3 stairCol = {0.42f, 0.44f, 0.46f};

    float cx = CMD_BUILDING_X;
    float cz = CMD_BUILDING_Z;
    float hw = CMD_BUILDING_WIDTH / 2.0f;
    float hd = CMD_BUILDING_DEPTH / 2.0f;
    float fy = FLOOR_Y;
    float wh = CMD_BUILDING_HEIGHT;
    float wt = CMD_WALL_THICK;
    float dw = CMD_DOOR_WIDTH / 2.0f;
    float doorH = CMD_DOOR_HEIGHT;
    float floorMid = fy + wh / 2.0f;

    // Back wall
    float bz = cz - hd;
    QUAD(verts, v, cx-hw, fy, bz, cx+hw, fy, bz, cx+hw, fy+wh, bz, cx-hw, fy+wh, bz, wallInt);
    QUAD(verts, v, cx+hw, fy, bz-wt, cx-hw, fy, bz-wt, cx-hw, fy+wh, bz-wt, cx+hw, fy+wh, bz-wt, wallExt);

    // Left wall
    float lx = cx - hw;
    QUAD(verts, v, lx, fy, cz+hd, lx, fy, cz-hd, lx, fy+wh, cz-hd, lx, fy+wh, cz+hd, wallInt);
    QUAD(verts, v, lx-wt, fy, cz-hd, lx-wt, fy, cz+hd, lx-wt, fy+wh, cz+hd, lx-wt, fy+wh, cz-hd, wallExt);

    // Right wall
    float rx = cx + hw;
    QUAD(verts, v, rx, fy, cz-hd, rx, fy, cz+hd, rx, fy+wh, cz+hd, rx, fy+wh, cz-hd, wallInt);
    QUAD(verts, v, rx+wt, fy, cz+hd, rx+wt, fy, cz-hd, rx+wt, fy+wh, cz-hd, rx+wt, fy+wh, cz+hd, wallExt);

    // Front wall with door
    float fz = cz + hd;
    QUAD(verts, v, cx-hw, fy, fz+wt, cx-dw, fy, fz+wt, cx-dw, fy+wh, fz+wt, cx-hw, fy+wh, fz+wt, wallExt);
    QUAD(verts, v, cx-dw, fy, fz, cx-hw, fy, fz, cx-hw, fy+wh, fz, cx-dw, fy+wh, fz, wallInt);
    QUAD(verts, v, cx+dw, fy, fz+wt, cx+hw, fy, fz+wt, cx+hw, fy+wh, fz+wt, cx+dw, fy+wh, fz+wt, wallExt);
    QUAD(verts, v, cx+hw, fy, fz, cx+dw, fy, fz, cx+dw, fy+wh, fz, cx+hw, fy+wh, fz, wallInt);
    QUAD(verts, v, cx-dw, fy+doorH, fz+wt, cx+dw, fy+doorH, fz+wt, cx+dw, fy+wh, fz+wt, cx-dw, fy+wh, fz+wt, wallExt);
    QUAD(verts, v, cx+dw, fy+doorH, fz, cx-dw, fy+doorH, fz, cx-dw, fy+wh, fz, cx+dw, fy+wh, fz, wallInt);

    // Door frame
    QUAD(verts, v, cx-dw, fy, fz, cx-dw, fy, fz+wt, cx-dw, fy+doorH, fz+wt, cx-dw, fy+doorH, fz, windowFrame);
    QUAD(verts, v, cx+dw, fy, fz+wt, cx+dw, fy, fz, cx+dw, fy+doorH, fz, cx+dw, fy+doorH, fz+wt, windowFrame);
    QUAD(verts, v, cx-dw, fy+doorH, fz, cx+dw, fy+doorH, fz, cx+dw, fy+doorH, fz+wt, cx-dw, fy+doorH, fz+wt, windowFrame);

    // Wall tops
    QUAD(verts, v, cx-hw-wt, fy+wh, bz-wt, cx+hw+wt, fy+wh, bz-wt, cx+hw+wt, fy+wh, bz, cx-hw-wt, fy+wh, bz, wallTop);
    QUAD(verts, v, lx-wt, fy+wh, cz-hd, lx-wt, fy+wh, cz+hd, lx, fy+wh, cz+hd, lx, fy+wh, cz-hd, wallTop);
    QUAD(verts, v, rx, fy+wh, cz-hd, rx, fy+wh, cz+hd, rx+wt, fy+wh, cz+hd, rx+wt, fy+wh, cz-hd, wallTop);
    QUAD(verts, v, cx-hw-wt, fy+wh, fz, cx+hw+wt, fy+wh, fz, cx+hw+wt, fy+wh, fz+wt, cx-hw-wt, fy+wh, fz+wt, wallTop);

    // Second floor
    float floorY = floorMid;
    float floorT = 0.2f;
    float stairHoleW = 2.0f;
    float stairHoleD = 2.0f;

    QUAD(verts, v, cx-hw+wt, floorY, cz+hd-wt, cx+hw-wt, floorY, cz+hd-wt,
         cx+hw-wt, floorY, cz+stairHoleD/2, cx-hw+wt, floorY, cz+stairHoleD/2, floorCol);
    QUAD(verts, v, cx-hw+wt, floorY, cz-stairHoleD/2, cx+hw-wt, floorY, cz-stairHoleD/2,
         cx+hw-wt, floorY, cz-hd+wt, cx-hw+wt, floorY, cz-hd+wt, floorCol);
    QUAD(verts, v, cx-hw+wt, floorY, cz+stairHoleD/2, cx-stairHoleW/2, floorY, cz+stairHoleD/2,
         cx-stairHoleW/2, floorY, cz-stairHoleD/2, cx-hw+wt, floorY, cz-stairHoleD/2, floorCol);
    QUAD(verts, v, cx+stairHoleW/2, floorY, cz+stairHoleD/2, cx+hw-wt, floorY, cz+stairHoleD/2,
         cx+hw-wt, floorY, cz-stairHoleD/2, cx+stairHoleW/2, floorY, cz-stairHoleD/2, floorCol);
    QUAD(verts, v, cx-hw+wt, floorY-floorT, cz+hd-wt, cx-hw+wt, floorY-floorT, cz-hd+wt,
         cx+hw-wt, floorY-floorT, cz-hd+wt, cx+hw-wt, floorY-floorT, cz+hd-wt, wallDark);

    // Stairs
    int numSteps = 6;
    float stepH = (floorY - fy) / numSteps;
    float stepD = stairHoleD / numSteps;
    float stairX = cx - stairHoleW/2 + 0.1f;
    float stairW = stairHoleW - 0.2f;

    for (int i = 0; i < numSteps; i++) {
        float sy = fy + i * stepH;
        float sz = cz + stairHoleD/2 - i * stepD;
        QUAD(verts, v, stairX, sy + stepH, sz, stairX + stairW, sy + stepH, sz,
             stairX + stairW, sy + stepH, sz - stepD, stairX, sy + stepH, sz - stepD, stairCol);
        QUAD(verts, v, stairX, sy, sz, stairX + stairW, sy, sz,
             stairX + stairW, sy + stepH, sz, stairX, sy + stepH, sz, wallDark);
    }

    // Roof
    float roofY = fy + wh;
    QUAD(verts, v, cx-hw-wt, roofY, cz-hd-wt, cx+hw+wt, roofY, cz-hd-wt,
         cx+hw+wt, roofY, cz+hd+wt, cx-hw-wt, roofY, cz+hd+wt, roofTop);

    float trimH = 0.3f;
    BOX3D(verts, v, cx-hw-wt-0.1f, roofY, cz-hd-wt-0.1f, cx+hw+wt+0.1f, roofY+trimH, cz-hd-wt,
          wallExt, wallDark, wallExt, wallDark, wallTop, roofTop);
    BOX3D(verts, v, cx-hw-wt-0.1f, roofY, cz+hd+wt, cx+hw+wt+0.1f, roofY+trimH, cz+hd+wt+0.1f,
          wallExt, wallDark, wallExt, wallDark, wallTop, roofTop);
    BOX3D(verts, v, cx-hw-wt-0.1f, roofY, cz-hd-wt, cx-hw-wt, roofY+trimH, cz+hd+wt,
          wallExt, wallDark, wallExt, wallDark, wallTop, roofTop);
    BOX3D(verts, v, cx+hw+wt, roofY, cz-hd-wt, cx+hw+wt+0.1f, roofY+trimH, cz+hd+wt,
          wallExt, wallDark, wallExt, wallDark, wallTop, roofTop);

    *count = v;
    return [device newBufferWithBytes:verts length:sizeof(Vertex) * v options:MTLResourceStorageModeShared];
}

+ (id<MTLBuffer>)createGuardTowerBufferWithDevice:(id<MTLDevice>)device vertexCount:(NSUInteger *)count {
    #define MAX_TOWER_VERTS 8000
    Vertex verts[MAX_TOWER_VERTS];
    int v = 0;

    simd_float3 metalRust = {0.55f, 0.35f, 0.25f};
    simd_float3 metalDark = {0.40f, 0.25f, 0.18f};
    simd_float3 metalLight = {0.65f, 0.45f, 0.35f};
    simd_float3 platformTop = {0.50f, 0.50f, 0.52f};
    simd_float3 platformBot = {0.35f, 0.35f, 0.38f};
    simd_float3 railCol = {0.45f, 0.30f, 0.22f};
    simd_float3 rampCol = {0.48f, 0.48f, 0.50f};
    simd_float3 rampDark = {0.38f, 0.38f, 0.40f};

    float fy = FLOOR_Y;
    float ts = TOWER_SIZE / 2.0f;
    float th = TOWER_HEIGHT;
    float platY = fy + th;
    float platT = 0.2f;
    float legW = 0.3f;
    float railH = CATWALK_RAIL_HEIGHT;

    float towerPos[4][2] = {
        {TOWER_OFFSET, TOWER_OFFSET},
        {-TOWER_OFFSET, TOWER_OFFSET},
        {-TOWER_OFFSET, -TOWER_OFFSET},
        {TOWER_OFFSET, -TOWER_OFFSET}
    };

    for (int t = 0; t < 4; t++) {
        float tx = towerPos[t][0];
        float tz = towerPos[t][1];

        // Support legs
        BOX3D(verts, v, tx-ts, fy, tz-ts, tx-ts+legW, platY, tz-ts+legW,
              metalRust, metalDark, metalLight, metalDark, metalLight, metalDark);
        BOX3D(verts, v, tx+ts-legW, fy, tz-ts, tx+ts, platY, tz-ts+legW,
              metalRust, metalDark, metalLight, metalDark, metalLight, metalDark);
        BOX3D(verts, v, tx-ts, fy, tz+ts-legW, tx-ts+legW, platY, tz+ts,
              metalRust, metalDark, metalLight, metalDark, metalLight, metalDark);
        BOX3D(verts, v, tx+ts-legW, fy, tz+ts-legW, tx+ts, platY, tz+ts,
              metalRust, metalDark, metalLight, metalDark, metalLight, metalDark);

        // Cross braces
        float braceY1 = fy + th * 0.3f;
        float braceY2 = fy + th * 0.7f;
        QUAD(verts, v, tx-ts+legW, braceY1, tz+ts-0.05f, tx+ts-legW, braceY1, tz+ts-0.05f,
             tx+ts-legW, braceY2, tz+ts-0.05f, tx-ts+legW, braceY2, tz+ts-0.05f, metalDark);
        QUAD(verts, v, tx+ts-legW, braceY1, tz-ts+0.05f, tx-ts+legW, braceY1, tz-ts+0.05f,
             tx-ts+legW, braceY2, tz-ts+0.05f, tx+ts-legW, braceY2, tz-ts+0.05f, metalDark);

        // Platform
        QUAD(verts, v, tx-ts, platY, tz-ts, tx+ts, platY, tz-ts,
             tx+ts, platY, tz+ts, tx-ts, platY, tz+ts, platformTop);
        QUAD(verts, v, tx-ts, platY-platT, tz+ts, tx+ts, platY-platT, tz+ts,
             tx+ts, platY-platT, tz-ts, tx-ts, platY-platT, tz-ts, platformBot);

        QUAD(verts, v, tx-ts, platY-platT, tz+ts, tx+ts, platY-platT, tz+ts,
             tx+ts, platY, tz+ts, tx-ts, platY, tz+ts, metalRust);
        QUAD(verts, v, tx+ts, platY-platT, tz-ts, tx-ts, platY-platT, tz-ts,
             tx-ts, platY, tz-ts, tx+ts, platY, tz-ts, metalDark);
        QUAD(verts, v, tx+ts, platY-platT, tz+ts, tx+ts, platY-platT, tz-ts,
             tx+ts, platY, tz-ts, tx+ts, platY, tz+ts, metalRust);
        QUAD(verts, v, tx-ts, platY-platT, tz-ts, tx-ts, platY-platT, tz+ts,
             tx-ts, platY, tz+ts, tx-ts, platY, tz-ts, metalDark);

        // Tower railings removed - catwalks have their own railings and connect to towers

        // Ramp - goes OUTWARD from arena center (away from catwalks)
        float rampW = RAMP_WIDTH / 2.0f;
        float rampL = RAMP_LENGTH;
        // Ramps go AWAY from center: positive Z for north towers, negative Z for south towers
        float rampDz = (tz > 0) ? 1.0f : -1.0f;  // Away from center on Z axis

        float rampStartX = tx;  // Centered on tower X
        float rampStartZ = tz + rampDz * ts;  // Start at outer edge of tower
        float rampEndX = tx;
        float rampEndZ = rampStartZ + rampDz * rampL;

        // Top surface
        verts[v++] = (Vertex){{rampStartX - rampW, platY, rampStartZ}, rampCol};
        verts[v++] = (Vertex){{rampStartX + rampW, platY, rampStartZ}, rampCol};
        verts[v++] = (Vertex){{rampEndX + rampW, fy, rampEndZ}, rampCol};
        verts[v++] = (Vertex){{rampStartX - rampW, platY, rampStartZ}, rampCol};
        verts[v++] = (Vertex){{rampEndX + rampW, fy, rampEndZ}, rampCol};
        verts[v++] = (Vertex){{rampEndX - rampW, fy, rampEndZ}, rampCol};

        // Bottom surface
        verts[v++] = (Vertex){{rampStartX + rampW, platY - platT, rampStartZ}, rampDark};
        verts[v++] = (Vertex){{rampStartX - rampW, platY - platT, rampStartZ}, rampDark};
        verts[v++] = (Vertex){{rampEndX - rampW, fy, rampEndZ}, rampDark};
        verts[v++] = (Vertex){{rampStartX + rampW, platY - platT, rampStartZ}, rampDark};
        verts[v++] = (Vertex){{rampEndX - rampW, fy, rampEndZ}, rampDark};
        verts[v++] = (Vertex){{rampEndX + rampW, fy, rampEndZ}, rampDark};

        // Left side wall (triangular - ramp tapers to ground)
        verts[v++] = (Vertex){{rampStartX - rampW, platY, rampStartZ}, rampDark};
        verts[v++] = (Vertex){{rampStartX - rampW, platY - platT, rampStartZ}, rampDark};
        verts[v++] = (Vertex){{rampEndX - rampW, fy, rampEndZ}, rampDark};

        // Right side wall (triangular)
        verts[v++] = (Vertex){{rampStartX + rampW, platY - platT, rampStartZ}, rampDark};
        verts[v++] = (Vertex){{rampStartX + rampW, platY, rampStartZ}, rampDark};
        verts[v++] = (Vertex){{rampEndX + rampW, fy, rampEndZ}, rampDark};
    }

    *count = v;
    return [device newBufferWithBytes:verts length:sizeof(Vertex) * v options:MTLResourceStorageModeShared];
}

+ (id<MTLBuffer>)createCatwalkBufferWithDevice:(id<MTLDevice>)device vertexCount:(NSUInteger *)count {
    #define MAX_CATWALK_VERTS 4000
    Vertex verts[MAX_CATWALK_VERTS];
    int v = 0;

    simd_float3 walkTop = {0.42f, 0.42f, 0.45f};
    simd_float3 walkBot = {0.32f, 0.32f, 0.35f};
    simd_float3 walkSide = {0.38f, 0.38f, 0.40f};
    simd_float3 railCol = {0.45f, 0.30f, 0.22f};

    float fy = FLOOR_Y;
    float th = TOWER_HEIGHT;
    float platY = fy + th;
    float cwW = CATWALK_WIDTH / 2.0f;
    float cwT = CATWALK_THICK;
    float railH = CATWALK_RAIL_HEIGHT;
    float railT = 0.06f;
    float ts = TOWER_SIZE / 2.0f;

    float cw1_x1 = TOWER_OFFSET - ts, cw1_x2 = -TOWER_OFFSET + ts;
    float cw1_z = TOWER_OFFSET;

    float cw2_x = -TOWER_OFFSET;
    float cw2_z1 = TOWER_OFFSET - ts, cw2_z2 = -TOWER_OFFSET + ts;

    float cw3_x1 = -TOWER_OFFSET + ts, cw3_x2 = TOWER_OFFSET - ts;
    float cw3_z = -TOWER_OFFSET;

    float cw4_x = TOWER_OFFSET;
    float cw4_z1 = -TOWER_OFFSET + ts, cw4_z2 = TOWER_OFFSET - ts;

    // Catwalk 1 (NE to NW)
    QUAD(verts, v, cw1_x1, platY, cw1_z-cwW, cw1_x2, platY, cw1_z-cwW,
         cw1_x2, platY, cw1_z+cwW, cw1_x1, platY, cw1_z+cwW, walkTop);
    QUAD(verts, v, cw1_x1, platY-cwT, cw1_z+cwW, cw1_x2, platY-cwT, cw1_z+cwW,
         cw1_x2, platY-cwT, cw1_z-cwW, cw1_x1, platY-cwT, cw1_z-cwW, walkBot);
    QUAD(verts, v, cw1_x1, platY-cwT, cw1_z+cwW, cw1_x2, platY-cwT, cw1_z+cwW,
         cw1_x2, platY, cw1_z+cwW, cw1_x1, platY, cw1_z+cwW, walkSide);
    QUAD(verts, v, cw1_x2, platY-cwT, cw1_z-cwW, cw1_x1, platY-cwT, cw1_z-cwW,
         cw1_x1, platY, cw1_z-cwW, cw1_x2, platY, cw1_z-cwW, walkSide);
    BOX3D(verts, v, cw1_x1, platY, cw1_z+cwW-railT, cw1_x2, platY+railH, cw1_z+cwW,
          railCol, railCol, railCol, railCol, railCol, railCol);
    BOX3D(verts, v, cw1_x1, platY, cw1_z-cwW, cw1_x2, platY+railH, cw1_z-cwW+railT,
          railCol, railCol, railCol, railCol, railCol, railCol);

    // Catwalk 2 (NW to SW)
    QUAD(verts, v, cw2_x-cwW, platY, cw2_z1, cw2_x-cwW, platY, cw2_z2,
         cw2_x+cwW, platY, cw2_z2, cw2_x+cwW, platY, cw2_z1, walkTop);
    QUAD(verts, v, cw2_x+cwW, platY-cwT, cw2_z1, cw2_x+cwW, platY-cwT, cw2_z2,
         cw2_x-cwW, platY-cwT, cw2_z2, cw2_x-cwW, platY-cwT, cw2_z1, walkBot);
    QUAD(verts, v, cw2_x+cwW, platY-cwT, cw2_z1, cw2_x+cwW, platY-cwT, cw2_z2,
         cw2_x+cwW, platY, cw2_z2, cw2_x+cwW, platY, cw2_z1, walkSide);
    QUAD(verts, v, cw2_x-cwW, platY-cwT, cw2_z2, cw2_x-cwW, platY-cwT, cw2_z1,
         cw2_x-cwW, platY, cw2_z1, cw2_x-cwW, platY, cw2_z2, walkSide);
    BOX3D(verts, v, cw2_x+cwW-railT, platY, cw2_z1, cw2_x+cwW, platY+railH, cw2_z2,
          railCol, railCol, railCol, railCol, railCol, railCol);
    BOX3D(verts, v, cw2_x-cwW, platY, cw2_z1, cw2_x-cwW+railT, platY+railH, cw2_z2,
          railCol, railCol, railCol, railCol, railCol, railCol);

    // Catwalk 3 (SW to SE)
    QUAD(verts, v, cw3_x1, platY, cw3_z+cwW, cw3_x2, platY, cw3_z+cwW,
         cw3_x2, platY, cw3_z-cwW, cw3_x1, platY, cw3_z-cwW, walkTop);
    QUAD(verts, v, cw3_x1, platY-cwT, cw3_z-cwW, cw3_x2, platY-cwT, cw3_z-cwW,
         cw3_x2, platY-cwT, cw3_z+cwW, cw3_x1, platY-cwT, cw3_z+cwW, walkBot);
    QUAD(verts, v, cw3_x1, platY-cwT, cw3_z-cwW, cw3_x2, platY-cwT, cw3_z-cwW,
         cw3_x2, platY, cw3_z-cwW, cw3_x1, platY, cw3_z-cwW, walkSide);
    QUAD(verts, v, cw3_x2, platY-cwT, cw3_z+cwW, cw3_x1, platY-cwT, cw3_z+cwW,
         cw3_x1, platY, cw3_z+cwW, cw3_x2, platY, cw3_z+cwW, walkSide);
    BOX3D(verts, v, cw3_x1, platY, cw3_z-cwW, cw3_x2, platY+railH, cw3_z-cwW+railT,
          railCol, railCol, railCol, railCol, railCol, railCol);
    BOX3D(verts, v, cw3_x1, platY, cw3_z+cwW-railT, cw3_x2, platY+railH, cw3_z+cwW,
          railCol, railCol, railCol, railCol, railCol, railCol);

    // Catwalk 4 (SE to NE)
    QUAD(verts, v, cw4_x+cwW, platY, cw4_z1, cw4_x+cwW, platY, cw4_z2,
         cw4_x-cwW, platY, cw4_z2, cw4_x-cwW, platY, cw4_z1, walkTop);
    QUAD(verts, v, cw4_x-cwW, platY-cwT, cw4_z1, cw4_x-cwW, platY-cwT, cw4_z2,
         cw4_x+cwW, platY-cwT, cw4_z2, cw4_x+cwW, platY-cwT, cw4_z1, walkBot);
    QUAD(verts, v, cw4_x-cwW, platY-cwT, cw4_z1, cw4_x-cwW, platY-cwT, cw4_z2,
         cw4_x-cwW, platY, cw4_z2, cw4_x-cwW, platY, cw4_z1, walkSide);
    QUAD(verts, v, cw4_x+cwW, platY-cwT, cw4_z2, cw4_x+cwW, platY-cwT, cw4_z1,
         cw4_x+cwW, platY, cw4_z1, cw4_x+cwW, platY, cw4_z2, walkSide);
    BOX3D(verts, v, cw4_x-cwW, platY, cw4_z1, cw4_x-cwW+railT, platY+railH, cw4_z2,
          railCol, railCol, railCol, railCol, railCol, railCol);
    BOX3D(verts, v, cw4_x+cwW-railT, platY, cw4_z1, cw4_x+cwW, platY+railH, cw4_z2,
          railCol, railCol, railCol, railCol, railCol, railCol);

    *count = v;
    return [device newBufferWithBytes:verts length:sizeof(Vertex) * v options:MTLResourceStorageModeShared];
}

+ (id<MTLBuffer>)createBunkerBufferWithDevice:(id<MTLDevice>)device vertexCount:(NSUInteger *)count {
    #define MAX_BUNKER_VERTS 3000
    Vertex verts[MAX_BUNKER_VERTS];
    int v = 0;

    simd_float3 bunkerExt = {0.30f, 0.32f, 0.35f};
    simd_float3 bunkerInt = {0.38f, 0.40f, 0.42f};
    simd_float3 bunkerDark = {0.22f, 0.24f, 0.26f};
    simd_float3 bunkerFloor = {0.35f, 0.35f, 0.38f};
    simd_float3 stairCol = {0.40f, 0.40f, 0.42f};

    float bx = BUNKER_X;
    float bz = BUNKER_Z;
    float hw = BUNKER_WIDTH / 2.0f;
    float hd = BUNKER_DEPTH / 2.0f;
    float fy = FLOOR_Y;
    float by = BASEMENT_LEVEL;
    float wt = 0.4f;
    float sw = BUNKER_STAIR_WIDTH / 2.0f;

    QUAD(verts, v, bx-hw+wt, by, bz-hd+wt, bx+hw-wt, by, bz-hd+wt,
         bx+hw-wt, by, bz+hd-wt, bx-hw+wt, by, bz+hd-wt, bunkerFloor);

    QUAD(verts, v, bx-hw+wt, by, bz-hd+wt, bx+hw-wt, by, bz-hd+wt,
         bx+hw-wt, fy, bz-hd+wt, bx-hw+wt, fy, bz-hd+wt, bunkerInt);
    QUAD(verts, v, bx-hw+wt, by, bz+hd-wt, bx-sw, by, bz+hd-wt,
         bx-sw, fy, bz+hd-wt, bx-hw+wt, fy, bz+hd-wt, bunkerInt);
    QUAD(verts, v, bx+sw, by, bz+hd-wt, bx+hw-wt, by, bz+hd-wt,
         bx+hw-wt, fy, bz+hd-wt, bx+sw, fy, bz+hd-wt, bunkerInt);
    QUAD(verts, v, bx-hw+wt, by, bz+hd-wt, bx-hw+wt, by, bz-hd+wt,
         bx-hw+wt, fy, bz-hd+wt, bx-hw+wt, fy, bz+hd-wt, bunkerInt);
    QUAD(verts, v, bx+hw-wt, by, bz-hd+wt, bx+hw-wt, by, bz+hd-wt,
         bx+hw-wt, fy, bz+hd-wt, bx+hw-wt, fy, bz-hd+wt, bunkerInt);

    float entH = 1.0f;
    QUAD(verts, v, bx-sw-wt, fy, bz+hd, bx+sw+wt, fy, bz+hd,
         bx+sw+wt, fy+entH, bz+hd, bx-sw-wt, fy+entH, bz+hd, bunkerExt);
    QUAD(verts, v, bx-sw-wt, fy, bz+hd-wt, bx-sw-wt, fy, bz+hd,
         bx-sw-wt, fy+entH, bz+hd, bx-sw-wt, fy+entH, bz+hd-wt, bunkerExt);
    QUAD(verts, v, bx+sw+wt, fy, bz+hd, bx+sw+wt, fy, bz+hd-wt,
         bx+sw+wt, fy+entH, bz+hd-wt, bx+sw+wt, fy+entH, bz+hd, bunkerExt);
    QUAD(verts, v, bx-sw-wt, fy+entH, bz+hd-wt, bx+sw+wt, fy+entH, bz+hd-wt,
         bx+sw+wt, fy+entH, bz+hd, bx-sw-wt, fy+entH, bz+hd, bunkerDark);

    int numSteps = 8;
    float stepH = (fy - by) / numSteps;
    float stepD = (hd * 2 - wt * 2) / numSteps;

    for (int i = 0; i < numSteps; i++) {
        float sy = fy - (i + 1) * stepH;
        float sz = bz + hd - wt - i * stepD;
        QUAD(verts, v, bx-sw, sy + stepH, sz, bx+sw, sy + stepH, sz,
             bx+sw, sy + stepH, sz - stepD, bx-sw, sy + stepH, sz - stepD, stairCol);
        QUAD(verts, v, bx-sw, sy, sz, bx+sw, sy, sz,
             bx+sw, sy + stepH, sz, bx-sw, sy + stepH, sz, bunkerDark);
        QUAD(verts, v, bx-sw, sy, sz - stepD, bx-sw, sy, sz,
             bx-sw, sy + stepH, sz, bx-sw, sy + stepH, sz - stepD, bunkerInt);
        QUAD(verts, v, bx+sw, sy, sz, bx+sw, sy, sz - stepD,
             bx+sw, sy + stepH, sz - stepD, bx+sw, sy + stepH, sz, bunkerInt);
    }

    // Bunker ceiling - slight offset below floor to avoid z-fighting with main floor
    QUAD(verts, v, bx-hw+wt, fy-0.01f, bz-hd+wt, bx-hw+wt, fy-0.01f, bz+hd-wt,
         bx+hw-wt, fy-0.01f, bz+hd-wt, bx+hw-wt, fy-0.01f, bz-hd+wt, bunkerDark);

    *count = v;
    return [device newBufferWithBytes:verts length:sizeof(Vertex) * v options:MTLResourceStorageModeShared];
}

+ (id<MTLBuffer>)createCargoContainersBufferWithDevice:(id<MTLDevice>)device vertexCount:(NSUInteger *)count {
    #define MAX_CARGO_VERTS 3000
    Vertex verts[MAX_CARGO_VERTS];
    int v = 0;

    simd_float3 greenFront = {0.28f, 0.38f, 0.25f};
    simd_float3 greenBack = {0.22f, 0.30f, 0.20f};
    simd_float3 greenSide = {0.25f, 0.35f, 0.22f};
    simd_float3 greenTop = {0.30f, 0.40f, 0.28f};
    simd_float3 greenBot = {0.18f, 0.25f, 0.15f};

    simd_float3 rustFront = {0.55f, 0.35f, 0.22f};
    simd_float3 rustBack = {0.45f, 0.28f, 0.18f};
    simd_float3 rustSide = {0.50f, 0.32f, 0.20f};
    simd_float3 rustTop = {0.58f, 0.38f, 0.25f};
    simd_float3 rustBot = {0.38f, 0.22f, 0.12f};

    float cl = CONTAINER_LENGTH / 2.0f;
    float cw = CONTAINER_WIDTH / 2.0f;
    float ch = CONTAINER_HEIGHT;
    float fy = FLOOR_Y;

    struct { float x, z; int rotated, colorSet; } containers[] = {
        {8.0f, 4.0f, 0, 0}, {6.0f, 7.0f, 1, 1}, {-8.0f, 4.0f, 0, 1}, {-6.0f, 7.0f, 1, 0},
        {6.0f, -8.0f, 1, 0}, {-6.0f, -8.0f, 1, 1}, {0.0f, -12.0f, 0, 0}, {18.0f, 0.0f, 1, 1},
    };
    int numContainers = 8;

    for (int i = 0; i < numContainers; i++) {
        float cx = containers[i].x;
        float cz = containers[i].z;
        float cxl = containers[i].rotated ? cw : cl;
        float czl = containers[i].rotated ? cl : cw;

        simd_float3 front, back, side, top, bot;
        if (containers[i].colorSet == 0) {
            front = greenFront; back = greenBack; side = greenSide; top = greenTop; bot = greenBot;
        } else {
            front = rustFront; back = rustBack; side = rustSide; top = rustTop; bot = rustBot;
        }
        BOX3D(verts, v, cx-cxl, fy, cz-czl, cx+cxl, fy+ch, cz+czl, front, back, side, side, top, bot);
    }

    BOX3D(verts, v, 8.0f-cl, fy+ch, 4.0f-cw, 8.0f+cl, fy+ch*2, 4.0f+cw,
          rustFront, rustBack, rustSide, rustSide, rustTop, rustBot);

    *count = v;
    return [device newBufferWithBytes:verts length:sizeof(Vertex) * v options:MTLResourceStorageModeShared];
}

+ (id<MTLBuffer>)createSandbagBufferWithDevice:(id<MTLDevice>)device vertexCount:(NSUInteger *)count {
    #define MAX_SANDBAG_VERTS 3000
    Vertex verts[MAX_SANDBAG_VERTS];
    int v = 0;

    simd_float3 bagFront = {0.45f, 0.42f, 0.32f};
    simd_float3 bagBack = {0.38f, 0.35f, 0.28f};
    simd_float3 bagSide = {0.42f, 0.38f, 0.30f};
    simd_float3 bagTop = {0.50f, 0.45f, 0.35f};
    simd_float3 bagBot = {0.32f, 0.30f, 0.22f};

    float sl = SANDBAG_LENGTH / 2.0f;
    float sh = SANDBAG_HEIGHT;
    float st = SANDBAG_THICK / 2.0f;
    float fy = FLOOR_Y;

    struct { float x, z; int rotated; } walls[] = {
        {5.0f, 4.0f, 0}, {-5.0f, 4.0f, 0}, {5.0f, -4.0f, 0}, {-5.0f, -4.0f, 0},
        {12.0f, 10.0f, 1}, {-12.0f, 10.0f, 1}, {12.0f, -10.0f, 1}, {-12.0f, -10.0f, 1},
        {3.0f, 8.0f, 1}, {-3.0f, 8.0f, 1},
    };
    int numWalls = 10;

    for (int i = 0; i < numWalls; i++) {
        float wx = walls[i].x;
        float wz = walls[i].z;
        float wl = walls[i].rotated ? st : sl;
        float wd = walls[i].rotated ? sl : st;

        // Lower tier of sandbags
        BOX3D(verts, v, wx-wl, fy, wz-wd, wx+wl, fy+sh*0.55f, wz+wd,
              bagFront, bagBack, bagSide, bagSide, bagTop, bagBot);
        // Upper tier (smaller, no overlap)
        BOX3D(verts, v, wx-wl*0.9f, fy+sh*0.55f, wz-wd*0.9f, wx+wl*0.9f, fy+sh, wz+wd*0.9f,
              bagFront, bagBack, bagSide, bagSide, bagTop, bagBot);
    }

    *count = v;
    return [device newBufferWithBytes:verts length:sizeof(Vertex) * v options:MTLResourceStorageModeShared];
}

+ (id<MTLBuffer>)createMilitaryFloorBufferWithDevice:(id<MTLDevice>)device vertexCount:(NSUInteger *)count {
    #define MAX_FLOOR_VERTS 500
    Vertex verts[MAX_FLOOR_VERTS];
    int v = 0;

    float s = ARENA_SIZE;  // Match collision boundary
    // Floor surface slightly below FLOOR_Y to avoid z-fighting with object bottom faces
    float fy = FLOOR_Y - 0.01f;

    simd_float3 dirtOuter = {0.25f, 0.20f, 0.12f};
    simd_float3 dirtInner = {0.30f, 0.25f, 0.15f};
    simd_float3 concreteLight = {0.45f, 0.45f, 0.48f};
    simd_float3 concreteDark = {0.38f, 0.38f, 0.40f};
    simd_float3 roadCol = {0.30f, 0.30f, 0.32f};

    verts[v++] = (Vertex){{-s, fy, -s}, dirtOuter};
    verts[v++] = (Vertex){{s, fy, -s}, dirtOuter};
    verts[v++] = (Vertex){{s, fy, s}, dirtInner};
    verts[v++] = (Vertex){{-s, fy, -s}, dirtOuter};
    verts[v++] = (Vertex){{s, fy, s}, dirtInner};
    verts[v++] = (Vertex){{-s, fy, s}, dirtInner};

    float padSize = 12.0f;
    float padY = fy + 0.02f;
    verts[v++] = (Vertex){{-padSize, padY, -padSize}, concreteDark};
    verts[v++] = (Vertex){{padSize, padY, -padSize}, concreteDark};
    verts[v++] = (Vertex){{padSize, padY, padSize}, concreteLight};
    verts[v++] = (Vertex){{-padSize, padY, -padSize}, concreteDark};
    verts[v++] = (Vertex){{padSize, padY, padSize}, concreteLight};
    verts[v++] = (Vertex){{-padSize, padY, padSize}, concreteLight};

    float roadW = 1.5f;
    verts[v++] = (Vertex){{-roadW, padY+0.01f, padSize}, roadCol};
    verts[v++] = (Vertex){{roadW, padY+0.01f, padSize}, roadCol};
    verts[v++] = (Vertex){{roadW, padY+0.01f, s}, roadCol};
    verts[v++] = (Vertex){{-roadW, padY+0.01f, padSize}, roadCol};
    verts[v++] = (Vertex){{roadW, padY+0.01f, s}, roadCol};
    verts[v++] = (Vertex){{-roadW, padY+0.01f, s}, roadCol};

    verts[v++] = (Vertex){{padSize, padY+0.01f, -roadW}, roadCol};
    verts[v++] = (Vertex){{s, padY+0.01f, -roadW}, roadCol};
    verts[v++] = (Vertex){{s, padY+0.01f, roadW}, roadCol};
    verts[v++] = (Vertex){{padSize, padY+0.01f, -roadW}, roadCol};
    verts[v++] = (Vertex){{s, padY+0.01f, roadW}, roadCol};
    verts[v++] = (Vertex){{padSize, padY+0.01f, roadW}, roadCol};

    verts[v++] = (Vertex){{-s, padY+0.01f, -roadW}, roadCol};
    verts[v++] = (Vertex){{-padSize, padY+0.01f, -roadW}, roadCol};
    verts[v++] = (Vertex){{-padSize, padY+0.01f, roadW}, roadCol};
    verts[v++] = (Vertex){{-s, padY+0.01f, -roadW}, roadCol};
    verts[v++] = (Vertex){{-padSize, padY+0.01f, roadW}, roadCol};
    verts[v++] = (Vertex){{-s, padY+0.01f, roadW}, roadCol};

    *count = v;
    return [device newBufferWithBytes:verts length:sizeof(Vertex) * v options:MTLResourceStorageModeShared];
}

// ============================================
// LEGACY GEOMETRY (compatibility)
// ============================================

+ (id<MTLBuffer>)createHouseBufferWithDevice:(id<MTLDevice>)device vertexCount:(NSUInteger *)count {
    return [self createCommandBuildingBufferWithDevice:device vertexCount:count];
}

+ (id<MTLBuffer>)createDoorBufferWithDevice:(id<MTLDevice>)device vertexCount:(NSUInteger *)count {
    simd_float3 doorFront = {0.5f, 0.35f, 0.25f};
    simd_float3 doorBack = {0.4f, 0.28f, 0.18f};
    simd_float3 doorSide = {0.35f, 0.22f, 0.12f};
    simd_float3 handleCol = {0.7f, 0.65f, 0.4f};

    float dw = DOOR_WIDTH, dh = DOOR_HEIGHT, dt = 0.08f;
    float handleX = dw - 0.15f, handleY = dh * 0.45f;
    float handleW = 0.12f, handleH = 0.04f, handleD = 0.04f;

    Vertex doorVerts[] = {
        {{0, 0, dt/2}, doorFront}, {{dw, 0, dt/2}, doorFront}, {{dw, dh, dt/2}, doorFront},
        {{0, 0, dt/2}, doorFront}, {{dw, dh, dt/2}, doorFront}, {{0, dh, dt/2}, doorFront},
        {{dw, 0, -dt/2}, doorBack}, {{0, 0, -dt/2}, doorBack}, {{0, dh, -dt/2}, doorBack},
        {{dw, 0, -dt/2}, doorBack}, {{0, dh, -dt/2}, doorBack}, {{dw, dh, -dt/2}, doorBack},
        {{dw, 0, dt/2}, doorSide}, {{dw, 0, -dt/2}, doorSide}, {{dw, dh, -dt/2}, doorSide},
        {{dw, 0, dt/2}, doorSide}, {{dw, dh, -dt/2}, doorSide}, {{dw, dh, dt/2}, doorSide},
        {{0, 0, -dt/2}, doorSide}, {{0, 0, dt/2}, doorSide}, {{0, dh, dt/2}, doorSide},
        {{0, 0, -dt/2}, doorSide}, {{0, dh, dt/2}, doorSide}, {{0, dh, -dt/2}, doorSide},
        {{0, dh, dt/2}, doorSide}, {{dw, dh, dt/2}, doorSide}, {{dw, dh, -dt/2}, doorSide},
        {{0, dh, dt/2}, doorSide}, {{dw, dh, -dt/2}, doorSide}, {{0, dh, -dt/2}, doorSide},
        {{handleX, handleY, dt/2}, handleCol}, {{handleX+handleW, handleY, dt/2}, handleCol}, {{handleX+handleW, handleY+handleH, dt/2}, handleCol},
        {{handleX, handleY, dt/2}, handleCol}, {{handleX+handleW, handleY+handleH, dt/2}, handleCol}, {{handleX, handleY+handleH, dt/2}, handleCol},
    };
    *count = sizeof(doorVerts) / sizeof(Vertex);
    return [device newBufferWithBytes:doorVerts length:sizeof(doorVerts) options:MTLResourceStorageModeShared];
}

+ (id<MTLBuffer>)createFloorBufferWithDevice:(id<MTLDevice>)device {
    NSUInteger floorCount;
    return [self createMilitaryFloorBufferWithDevice:device vertexCount:&floorCount];
}

+ (id<MTLBuffer>)createWall1BufferWithDevice:(id<MTLDevice>)device {
    simd_float3 wallFront = {0.45f, 0.45f, 0.42f};
    simd_float3 wallBack = {0.30f, 0.30f, 0.28f};
    simd_float3 wallRight = {0.40f, 0.40f, 0.38f};
    simd_float3 wallLeft = {0.35f, 0.35f, 0.33f};
    simd_float3 wallTop = {0.50f, 0.50f, 0.48f};
    simd_float3 wallBot = {0.25f, 0.25f, 0.23f};

    float hw = WALL_WIDTH / 2.0f, hh = WALL_HEIGHT / 2.0f, hd = WALL_DEPTH / 2.0f;
    float w1y = FLOOR_Y + hh;

    Vertex wall1Verts[36];
    int v = 0;
    BOX3D(wall1Verts, v, WALL1_X-hw, w1y-hh, WALL1_Z-hd, WALL1_X+hw, w1y+hh, WALL1_Z+hd,
          wallFront, wallBack, wallRight, wallLeft, wallTop, wallBot);
    return [device newBufferWithBytes:wall1Verts length:sizeof(wall1Verts) options:MTLResourceStorageModeShared];
}

+ (id<MTLBuffer>)createWall2BufferWithDevice:(id<MTLDevice>)device {
    simd_float3 wallFront = {0.45f, 0.45f, 0.42f};
    simd_float3 wallBack = {0.30f, 0.30f, 0.28f};
    simd_float3 wallRight = {0.40f, 0.40f, 0.38f};
    simd_float3 wallLeft = {0.35f, 0.35f, 0.33f};
    simd_float3 wallTop = {0.50f, 0.50f, 0.48f};
    simd_float3 wallBot = {0.25f, 0.25f, 0.23f};

    float hw = WALL_WIDTH / 2.0f, hh = WALL_HEIGHT / 2.0f, hd = WALL_DEPTH / 2.0f;
    float w2y = FLOOR_Y + hh;

    Vertex wall2Verts[36];
    int v = 0;
    BOX3D(wall2Verts, v, WALL2_X-hw, w2y-hh, WALL2_Z-hd, WALL2_X+hw, w2y+hh, WALL2_Z+hd,
          wallFront, wallBack, wallRight, wallLeft, wallTop, wallBot);
    return [device newBufferWithBytes:wall2Verts length:sizeof(wall2Verts) options:MTLResourceStorageModeShared];
}

// ============================================
// CHARACTER & WEAPON GEOMETRY
// ============================================

+ (id<MTLBuffer>)createGunBufferWithDevice:(id<MTLDevice>)device vertexCount:(NSUInteger *)count {
    #define MAX_GUN_VERTS 5000
    Vertex gunVerts[MAX_GUN_VERTS];
    int gv = 0;

    // Colors - more variety for detail
    simd_float3 gunBlack = {0.08, 0.08, 0.10};
    simd_float3 gunDark = {0.12, 0.12, 0.14};
    simd_float3 gunMid = {0.20, 0.20, 0.23};
    simd_float3 gunLight = {0.30, 0.30, 0.33};
    simd_float3 gunShine = {0.40, 0.40, 0.45};
    simd_float3 metalDark = {0.15, 0.15, 0.18};
    simd_float3 metalMid = {0.25, 0.25, 0.30};
    simd_float3 metalLight = {0.35, 0.35, 0.42};
    simd_float3 skinLight = {0.87, 0.72, 0.60};
    simd_float3 skinMid = {0.76, 0.60, 0.48};
    simd_float3 skinDark = {0.65, 0.50, 0.40};
    simd_float3 skinShadow = {0.50, 0.38, 0.30};
    simd_float3 nailCol = {0.85, 0.75, 0.70};
    simd_float3 sleeveLight = {0.22, 0.24, 0.20};
    simd_float3 sleeveMid = {0.15, 0.17, 0.14};
    simd_float3 sleeveDark = {0.10, 0.12, 0.09};
    simd_float3 cuffCol = {0.18, 0.18, 0.16};

    // === DETAILED GUN MODEL ===
    // Main receiver body - multiple sections for detail
    BOX3D(gunVerts, gv, -0.028f, 0.005f, -0.12f, 0.028f, 0.038f, 0.08f, gunMid, gunDark, gunMid, gunMid, gunLight, gunDark);
    // Top rail/sight mount
    BOX3D(gunVerts, gv, -0.018f, 0.038f, -0.08f, 0.018f, 0.048f, 0.06f, gunDark, gunDark, gunDark, gunDark, gunMid, gunDark);
    // Picatinny rail grooves (multiple small boxes)
    for (int i = 0; i < 8; i++) {
        float z = -0.06f + i * 0.015f;
        BOX3D(gunVerts, gv, -0.016f, 0.048f, z, 0.016f, 0.052f, z+0.008f, gunBlack, gunBlack, gunBlack, gunBlack, gunDark, gunBlack);
    }

    // Barrel - octagonal approximation with 8 faces
    float bx = 0.0f, by = 0.022f;
    float br = 0.012f;  // barrel radius
    for (int i = 0; i < 8; i++) {
        float a1 = i * M_PI / 4.0f;
        float a2 = (i + 1) * M_PI / 4.0f;
        float x1 = bx + br * cosf(a1), y1 = by + br * sinf(a1);
        float x2 = bx + br * cosf(a2), y2 = by + br * sinf(a2);
        simd_float3 col = (i % 2 == 0) ? gunDark : gunBlack;
        // Barrel side face
        gunVerts[gv++] = (Vertex){{x1, y1, 0.08f}, col};
        gunVerts[gv++] = (Vertex){{x2, y2, 0.08f}, col};
        gunVerts[gv++] = (Vertex){{x2, y2, 0.22f}, col};
        gunVerts[gv++] = (Vertex){{x1, y1, 0.08f}, col};
        gunVerts[gv++] = (Vertex){{x2, y2, 0.22f}, col};
        gunVerts[gv++] = (Vertex){{x1, y1, 0.22f}, col};
    }
    // Barrel muzzle ring
    BOX3D(gunVerts, gv, -0.015f, 0.007f, 0.22f, 0.015f, 0.037f, 0.25f, gunBlack, gunBlack, gunBlack, gunBlack, gunBlack, gunBlack);

    // Front sight post
    BOX3D(gunVerts, gv, -0.003f, 0.037f, 0.18f, 0.003f, 0.058f, 0.20f, gunDark, gunDark, gunDark, gunDark, metalLight, gunDark);
    // Front sight guards
    BOX3D(gunVerts, gv, -0.012f, 0.037f, 0.17f, -0.008f, 0.052f, 0.21f, gunDark, gunDark, gunDark, gunDark, gunDark, gunDark);
    BOX3D(gunVerts, gv, 0.008f, 0.037f, 0.17f, 0.012f, 0.052f, 0.21f, gunDark, gunDark, gunDark, gunDark, gunDark, gunDark);

    // Rear sight
    BOX3D(gunVerts, gv, -0.015f, 0.048f, -0.10f, -0.008f, 0.065f, -0.08f, gunDark, gunDark, gunDark, gunDark, gunMid, gunDark);
    BOX3D(gunVerts, gv, 0.008f, 0.048f, -0.10f, 0.015f, 0.065f, -0.08f, gunDark, gunDark, gunDark, gunDark, gunMid, gunDark);
    BOX3D(gunVerts, gv, -0.015f, 0.058f, -0.10f, 0.015f, 0.065f, -0.08f, gunDark, gunDark, gunDark, gunDark, gunMid, gunDark);

    // Ejection port
    BOX3D(gunVerts, gv, 0.028f, 0.015f, -0.02f, 0.032f, 0.032f, 0.03f, gunBlack, gunBlack, gunBlack, gunBlack, gunBlack, gunBlack);

    // Magazine
    BOX3D(gunVerts, gv, -0.018f, -0.08f, -0.06f, 0.018f, 0.005f, 0.0f, gunMid, gunDark, gunMid, gunMid, gunMid, gunDark);
    // Magazine base plate
    BOX3D(gunVerts, gv, -0.020f, -0.085f, -0.06f, 0.020f, -0.08f, 0.0f, gunLight, gunMid, gunLight, gunLight, gunMid, gunDark);

    // Grip - more detailed with texture
    BOX3D(gunVerts, gv, -0.022f, -0.10f, -0.12f, 0.022f, 0.005f, -0.06f, gunMid, gunDark, gunLight, gunMid, gunLight, gunDark);
    // Grip texture lines
    for (int i = 0; i < 5; i++) {
        float y = -0.09f + i * 0.018f;
        BOX3D(gunVerts, gv, -0.024f, y, -0.115f, 0.024f, y+0.006f, -0.065f, gunDark, gunBlack, gunDark, gunDark, gunDark, gunDark);
    }
    // Grip base
    BOX3D(gunVerts, gv, -0.024f, -0.11f, -0.12f, 0.024f, -0.10f, -0.06f, gunLight, gunMid, gunLight, gunLight, gunMid, gunDark);

    // Trigger guard - curved approximation
    BOX3D(gunVerts, gv, -0.018f, -0.03f, -0.04f, 0.018f, -0.02f, 0.02f, gunDark, gunDark, gunDark, gunDark, gunDark, gunDark);
    BOX3D(gunVerts, gv, -0.018f, -0.05f, -0.04f, -0.014f, -0.02f, 0.02f, gunDark, gunDark, gunDark, gunDark, gunDark, gunDark);
    BOX3D(gunVerts, gv, 0.014f, -0.05f, -0.04f, 0.018f, -0.02f, 0.02f, gunDark, gunDark, gunDark, gunDark, gunDark, gunDark);
    BOX3D(gunVerts, gv, -0.018f, -0.05f, -0.04f, 0.018f, -0.045f, -0.035f, gunDark, gunDark, gunDark, gunDark, gunDark, gunDark);

    // Trigger
    BOX3D(gunVerts, gv, -0.004f, -0.04f, -0.02f, 0.004f, -0.015f, -0.01f, metalMid, metalDark, metalMid, metalMid, metalLight, metalDark);

    // === DETAILED HAND AND ARM ===
    // Right hand holding grip - with individual fingers
    // Palm
    BOX3D(gunVerts, gv, -0.032f, -0.09f, -0.15f, 0.032f, -0.01f, -0.10f, skinMid, skinDark, skinLight, skinMid, skinLight, skinShadow);
    // Thumb
    BOX3D(gunVerts, gv, 0.032f, -0.05f, -0.14f, 0.048f, -0.02f, -0.10f, skinMid, skinDark, skinLight, skinMid, skinLight, skinDark);
    BOX3D(gunVerts, gv, 0.045f, -0.04f, -0.13f, 0.058f, -0.02f, -0.10f, skinMid, skinDark, skinLight, skinMid, skinLight, skinDark);
    // Index finger (on trigger)
    BOX3D(gunVerts, gv, -0.008f, -0.045f, -0.06f, 0.008f, -0.02f, -0.02f, skinMid, skinShadow, skinLight, skinMid, skinLight, skinDark);
    // Middle, ring, pinky fingers wrapped around grip
    for (int f = 0; f < 3; f++) {
        float fy = -0.06f - f * 0.018f;
        BOX3D(gunVerts, gv, -0.035f, fy-0.015f, -0.13f, -0.022f, fy, -0.06f, skinMid, skinDark, skinLight, skinMid, skinLight, skinDark);
        // Fingertips with nails
        BOX3D(gunVerts, gv, -0.038f, fy-0.012f, -0.06f, -0.022f, fy-0.003f, -0.05f, skinMid, skinDark, skinMid, skinMid, skinLight, skinDark);
    }

    // Wrist
    BOX3D(gunVerts, gv, -0.038f, -0.12f, -0.22f, 0.038f, -0.02f, -0.15f, skinMid, skinDark, skinLight, skinMid, skinLight, skinShadow);

    // Forearm with sleeve - multiple segments
    BOX3D(gunVerts, gv, -0.042f, -0.14f, -0.32f, 0.042f, -0.02f, -0.22f, sleeveMid, sleeveDark, sleeveLight, sleeveMid, sleeveLight, sleeveDark);
    // Sleeve cuff
    BOX3D(gunVerts, gv, -0.044f, -0.13f, -0.23f, 0.044f, -0.03f, -0.22f, cuffCol, cuffCol, cuffCol, cuffCol, cuffCol, cuffCol);
    // Sleeve wrinkles
    BOX3D(gunVerts, gv, -0.044f, -0.10f, -0.28f, 0.044f, -0.08f, -0.26f, sleeveDark, sleeveDark, sleeveDark, sleeveDark, sleeveMid, sleeveDark);
    BOX3D(gunVerts, gv, -0.044f, -0.06f, -0.30f, 0.044f, -0.04f, -0.28f, sleeveDark, sleeveDark, sleeveDark, sleeveDark, sleeveMid, sleeveDark);

    // Upper arm
    BOX3D(gunVerts, gv, -0.050f, -0.18f, -0.48f, 0.050f, -0.02f, -0.32f, sleeveMid, sleeveDark, sleeveLight, sleeveMid, sleeveLight, sleeveDark);
    // Elbow area
    BOX3D(gunVerts, gv, -0.048f, -0.16f, -0.50f, 0.048f, -0.04f, -0.48f, sleeveDark, sleeveDark, sleeveMid, sleeveMid, sleeveMid, sleeveDark);

    // Shoulder/upper arm continuing back
    BOX3D(gunVerts, gv, -0.060f, -0.25f, -0.70f, 0.060f, -0.04f, -0.48f, sleeveMid, sleeveDark, sleeveLight, sleeveMid, sleeveLight, sleeveDark);
    BOX3D(gunVerts, gv, -0.070f, -0.32f, -0.85f, 0.070f, -0.08f, -0.70f, sleeveMid, sleeveDark, sleeveLight, sleeveMid, sleeveLight, sleeveDark);

    *count = gv;
    return [device newBufferWithBytes:gunVerts length:sizeof(Vertex) * gv options:MTLResourceStorageModeShared];
}

+ (id<MTLBuffer>)createPistolBufferWithDevice:(id<MTLDevice>)device vertexCount:(NSUInteger *)count {
    // Same as the default gun - compact pistol
    return [self createGunBufferWithDevice:device vertexCount:count];
}

+ (id<MTLBuffer>)createShotgunBufferWithDevice:(id<MTLDevice>)device vertexCount:(NSUInteger *)count {
    // Nova/XM1014 inspired pump-action shotgun with high polygon detail
    #define MAX_SHOTGUN_VERTS 6000
    Vertex gunVerts[MAX_SHOTGUN_VERTS];
    int gv = 0;

    // Colors
    simd_float3 metalBlack = {0.06, 0.06, 0.08};
    simd_float3 metalDark = {0.12, 0.12, 0.14};
    simd_float3 metalMid = {0.22, 0.22, 0.26};
    simd_float3 metalLight = {0.32, 0.32, 0.38};
    simd_float3 metalShine = {0.42, 0.42, 0.50};
    simd_float3 woodDark = {0.30, 0.18, 0.10};
    simd_float3 woodMid = {0.45, 0.28, 0.15};
    simd_float3 woodLight = {0.58, 0.38, 0.22};
    simd_float3 woodGrain = {0.38, 0.22, 0.12};
    simd_float3 skinLight = {0.87, 0.72, 0.60};
    simd_float3 skinMid = {0.76, 0.60, 0.48};
    simd_float3 skinDark = {0.65, 0.50, 0.40};
    simd_float3 skinShadow = {0.50, 0.38, 0.30};
    simd_float3 sleeveLight = {0.22, 0.24, 0.20};
    simd_float3 sleeveMid = {0.15, 0.17, 0.14};
    simd_float3 sleeveDark = {0.10, 0.12, 0.09};
    simd_float3 cuffCol = {0.18, 0.18, 0.16};

    // === BARREL - Octagonal long barrel ===
    float bx = 0.0f, by = 0.035f;
    float br = 0.018f;  // barrel radius
    for (int i = 0; i < 8; i++) {
        float a1 = i * M_PI / 4.0f;
        float a2 = (i + 1) * M_PI / 4.0f;
        float x1 = bx + br * cosf(a1), y1 = by + br * sinf(a1);
        float x2 = bx + br * cosf(a2), y2 = by + br * sinf(a2);
        simd_float3 col = (i % 2 == 0) ? metalDark : metalBlack;
        gunVerts[gv++] = (Vertex){{x1, y1, -0.05f}, col};
        gunVerts[gv++] = (Vertex){{x2, y2, -0.05f}, col};
        gunVerts[gv++] = (Vertex){{x2, y2, 0.38f}, col};
        gunVerts[gv++] = (Vertex){{x1, y1, -0.05f}, col};
        gunVerts[gv++] = (Vertex){{x2, y2, 0.38f}, col};
        gunVerts[gv++] = (Vertex){{x1, y1, 0.38f}, col};
    }
    // Barrel muzzle
    BOX3D(gunVerts, gv, -0.022f, 0.013f, 0.38f, 0.022f, 0.057f, 0.42f, metalBlack, metalBlack, metalBlack, metalBlack, metalDark, metalBlack);
    // Barrel vent rib (top sight rail)
    BOX3D(gunVerts, gv, -0.004f, 0.053f, 0.0f, 0.004f, 0.062f, 0.36f, metalMid, metalDark, metalMid, metalMid, metalLight, metalDark);
    // Front bead sight
    BOX3D(gunVerts, gv, -0.005f, 0.062f, 0.34f, 0.005f, 0.075f, 0.37f, metalShine, metalMid, metalShine, metalShine, metalShine, metalMid);

    // === MAGAZINE TUBE (under barrel) ===
    float mx = 0.0f, my = -0.005f;
    float mr = 0.016f;
    for (int i = 0; i < 8; i++) {
        float a1 = i * M_PI / 4.0f;
        float a2 = (i + 1) * M_PI / 4.0f;
        float x1 = mx + mr * cosf(a1), y1 = my + mr * sinf(a1);
        float x2 = mx + mr * cosf(a2), y2 = my + mr * sinf(a2);
        simd_float3 col = (i % 2 == 0) ? metalMid : metalDark;
        gunVerts[gv++] = (Vertex){{x1, y1, 0.0f}, col};
        gunVerts[gv++] = (Vertex){{x2, y2, 0.0f}, col};
        gunVerts[gv++] = (Vertex){{x2, y2, 0.28f}, col};
        gunVerts[gv++] = (Vertex){{x1, y1, 0.0f}, col};
        gunVerts[gv++] = (Vertex){{x2, y2, 0.28f}, col};
        gunVerts[gv++] = (Vertex){{x1, y1, 0.28f}, col};
    }
    // Magazine tube cap
    BOX3D(gunVerts, gv, -0.018f, -0.023f, 0.28f, 0.018f, 0.013f, 0.31f, metalDark, metalDark, metalDark, metalDark, metalMid, metalDark);

    // === PUMP FOREND (wooden) ===
    BOX3D(gunVerts, gv, -0.032f, -0.035f, 0.08f, 0.032f, 0.025f, 0.22f, woodMid, woodDark, woodLight, woodMid, woodLight, woodDark);
    // Forend grooves for grip
    for (int i = 0; i < 6; i++) {
        float z = 0.10f + i * 0.018f;
        BOX3D(gunVerts, gv, -0.034f, -0.03f, z, 0.034f, -0.025f, z+0.008f, woodGrain, woodDark, woodGrain, woodGrain, woodDark, woodDark);
        BOX3D(gunVerts, gv, -0.034f, 0.015f, z, 0.034f, 0.02f, z+0.008f, woodGrain, woodDark, woodGrain, woodGrain, woodDark, woodDark);
    }
    // Forend front cap
    BOX3D(gunVerts, gv, -0.028f, -0.030f, 0.22f, 0.028f, 0.020f, 0.24f, metalDark, metalDark, metalDark, metalDark, metalMid, metalDark);

    // === RECEIVER ===
    BOX3D(gunVerts, gv, -0.038f, -0.02f, -0.14f, 0.038f, 0.055f, 0.0f, metalMid, metalDark, metalLight, metalMid, metalLight, metalDark);
    // Ejection port
    BOX3D(gunVerts, gv, 0.038f, 0.005f, -0.08f, 0.044f, 0.045f, -0.02f, metalBlack, metalBlack, metalBlack, metalBlack, metalBlack, metalBlack);
    // Loading port (bottom)
    BOX3D(gunVerts, gv, -0.025f, -0.025f, -0.10f, 0.025f, -0.02f, -0.02f, metalBlack, metalBlack, metalBlack, metalBlack, metalBlack, metalBlack);
    // Action bar
    BOX3D(gunVerts, gv, -0.012f, -0.02f, 0.0f, 0.012f, 0.015f, 0.10f, metalDark, metalBlack, metalMid, metalMid, metalMid, metalBlack);
    // Safety button
    BOX3D(gunVerts, gv, -0.008f, 0.055f, -0.12f, 0.008f, 0.068f, -0.10f, metalShine, metalMid, metalShine, metalShine, metalShine, metalMid);

    // === TRIGGER GUARD ===
    BOX3D(gunVerts, gv, -0.025f, -0.045f, -0.10f, 0.025f, -0.035f, -0.02f, metalDark, metalBlack, metalDark, metalDark, metalDark, metalBlack);
    BOX3D(gunVerts, gv, -0.025f, -0.065f, -0.10f, -0.020f, -0.035f, -0.02f, metalDark, metalBlack, metalDark, metalDark, metalDark, metalBlack);
    BOX3D(gunVerts, gv, 0.020f, -0.065f, -0.10f, 0.025f, -0.035f, -0.02f, metalDark, metalBlack, metalDark, metalDark, metalDark, metalBlack);
    BOX3D(gunVerts, gv, -0.025f, -0.065f, -0.10f, 0.025f, -0.060f, -0.095f, metalDark, metalBlack, metalDark, metalDark, metalDark, metalBlack);
    // Trigger
    BOX3D(gunVerts, gv, -0.005f, -0.055f, -0.06f, 0.005f, -0.035f, -0.05f, metalMid, metalDark, metalLight, metalMid, metalLight, metalDark);

    // === WOODEN STOCK ===
    // Grip area
    BOX3D(gunVerts, gv, -0.028f, -0.10f, -0.18f, 0.028f, -0.02f, -0.10f, woodMid, woodDark, woodLight, woodMid, woodLight, woodDark);
    // Grip texture
    for (int i = 0; i < 4; i++) {
        float y = -0.09f + i * 0.016f;
        BOX3D(gunVerts, gv, -0.030f, y, -0.175f, 0.030f, y+0.005f, -0.105f, woodGrain, woodDark, woodGrain, woodGrain, woodDark, woodDark);
    }
    // Stock body
    BOX3D(gunVerts, gv, -0.025f, -0.06f, -0.38f, 0.025f, 0.04f, -0.14f, woodMid, woodDark, woodLight, woodMid, woodLight, woodDark);
    // Stock bottom curve
    BOX3D(gunVerts, gv, -0.023f, -0.08f, -0.36f, 0.023f, -0.06f, -0.20f, woodMid, woodDark, woodLight, woodMid, woodLight, woodDark);
    // Butt pad
    BOX3D(gunVerts, gv, -0.028f, -0.08f, -0.40f, 0.028f, 0.045f, -0.38f, metalDark, metalBlack, metalDark, metalDark, metalDark, metalBlack);
    // Butt pad texture lines
    for (int i = 0; i < 4; i++) {
        float y = -0.06f + i * 0.025f;
        BOX3D(gunVerts, gv, -0.030f, y, -0.405f, 0.030f, y+0.008f, -0.398f, metalBlack, metalBlack, metalBlack, metalBlack, metalBlack, metalBlack);
    }
    // Cheek rest
    BOX3D(gunVerts, gv, -0.018f, 0.04f, -0.32f, 0.018f, 0.055f, -0.18f, woodMid, woodDark, woodLight, woodMid, woodLight, woodDark);

    // === HANDS ===
    // Front hand on forend
    BOX3D(gunVerts, gv, -0.038f, -0.06f, 0.10f, 0.038f, 0.0f, 0.20f, skinMid, skinDark, skinLight, skinMid, skinLight, skinShadow);
    // Front hand fingers
    for (int f = 0; f < 4; f++) {
        float x = -0.028f + f * 0.016f;
        BOX3D(gunVerts, gv, x, -0.065f, 0.12f, x+0.012f, -0.04f, 0.18f, skinMid, skinShadow, skinLight, skinMid, skinLight, skinDark);
    }
    // Front thumb
    BOX3D(gunVerts, gv, 0.038f, -0.02f, 0.12f, 0.055f, 0.01f, 0.18f, skinMid, skinDark, skinLight, skinMid, skinLight, skinDark);

    // Rear hand on grip
    BOX3D(gunVerts, gv, -0.035f, -0.12f, -0.20f, 0.035f, -0.04f, -0.10f, skinMid, skinDark, skinLight, skinMid, skinLight, skinShadow);
    // Index finger on trigger
    BOX3D(gunVerts, gv, -0.008f, -0.06f, -0.08f, 0.008f, -0.035f, -0.05f, skinMid, skinShadow, skinLight, skinMid, skinLight, skinDark);
    // Other fingers
    for (int f = 0; f < 3; f++) {
        float y = -0.08f - f * 0.015f;
        BOX3D(gunVerts, gv, -0.038f, y-0.012f, -0.18f, -0.025f, y, -0.11f, skinMid, skinDark, skinLight, skinMid, skinLight, skinDark);
    }
    // Rear thumb
    BOX3D(gunVerts, gv, 0.035f, -0.06f, -0.18f, 0.052f, -0.035f, -0.12f, skinMid, skinDark, skinLight, skinMid, skinLight, skinDark);

    // === ARMS ===
    // Front wrist/forearm
    BOX3D(gunVerts, gv, -0.042f, -0.10f, -0.05f, 0.042f, 0.0f, 0.10f, sleeveMid, sleeveDark, sleeveLight, sleeveMid, sleeveLight, sleeveDark);
    BOX3D(gunVerts, gv, -0.044f, -0.09f, -0.04f, 0.044f, -0.01f, -0.03f, cuffCol, cuffCol, cuffCol, cuffCol, cuffCol, cuffCol);

    // Rear wrist
    BOX3D(gunVerts, gv, -0.040f, -0.14f, -0.28f, 0.040f, -0.04f, -0.18f, skinMid, skinDark, skinLight, skinMid, skinLight, skinShadow);
    // Rear forearm
    BOX3D(gunVerts, gv, -0.045f, -0.16f, -0.40f, 0.045f, -0.04f, -0.28f, sleeveMid, sleeveDark, sleeveLight, sleeveMid, sleeveLight, sleeveDark);
    BOX3D(gunVerts, gv, -0.047f, -0.15f, -0.30f, 0.047f, -0.05f, -0.28f, cuffCol, cuffCol, cuffCol, cuffCol, cuffCol, cuffCol);
    // Upper arms
    BOX3D(gunVerts, gv, -0.055f, -0.22f, -0.60f, 0.055f, -0.04f, -0.40f, sleeveMid, sleeveDark, sleeveLight, sleeveMid, sleeveLight, sleeveDark);
    BOX3D(gunVerts, gv, -0.065f, -0.30f, -0.85f, 0.065f, -0.06f, -0.60f, sleeveMid, sleeveDark, sleeveLight, sleeveMid, sleeveLight, sleeveDark);

    *count = gv;
    return [device newBufferWithBytes:gunVerts length:sizeof(Vertex) * gv options:MTLResourceStorageModeShared];
}

+ (id<MTLBuffer>)createRifleBufferWithDevice:(id<MTLDevice>)device vertexCount:(NSUInteger *)count {
    // M4A1-S / AK-47 inspired assault rifle with high polygon detail
    #define MAX_RIFLE_VERTS 7000
    Vertex gunVerts[MAX_RIFLE_VERTS];
    int gv = 0;

    // Colors
    simd_float3 gunBlack = {0.05, 0.05, 0.07};
    simd_float3 gunDark = {0.10, 0.10, 0.12};
    simd_float3 gunMid = {0.18, 0.18, 0.22};
    simd_float3 gunLight = {0.28, 0.28, 0.34};
    simd_float3 gunShine = {0.38, 0.38, 0.45};
    simd_float3 railDark = {0.08, 0.08, 0.10};
    simd_float3 railMid = {0.15, 0.15, 0.18};
    simd_float3 redDot = {1.0, 0.1, 0.1};
    simd_float3 lensBlue = {0.2, 0.3, 0.5};
    simd_float3 magDark = {0.12, 0.11, 0.10};
    simd_float3 magMid = {0.18, 0.16, 0.14};
    simd_float3 skinLight = {0.87, 0.72, 0.60};
    simd_float3 skinMid = {0.76, 0.60, 0.48};
    simd_float3 skinDark = {0.65, 0.50, 0.40};
    simd_float3 skinShadow = {0.50, 0.38, 0.30};
    simd_float3 sleeveLight = {0.22, 0.24, 0.20};
    simd_float3 sleeveMid = {0.15, 0.17, 0.14};
    simd_float3 sleeveDark = {0.10, 0.12, 0.09};
    simd_float3 cuffCol = {0.18, 0.18, 0.16};
    simd_float3 gloveDark = {0.08, 0.08, 0.08};
    simd_float3 gloveMid = {0.14, 0.14, 0.14};

    // === BARREL - Octagonal ===
    float bx = 0.0f, by = 0.025f;
    float br = 0.010f;
    for (int i = 0; i < 8; i++) {
        float a1 = i * M_PI / 4.0f;
        float a2 = (i + 1) * M_PI / 4.0f;
        float x1 = bx + br * cosf(a1), y1 = by + br * sinf(a1);
        float x2 = bx + br * cosf(a2), y2 = by + br * sinf(a2);
        simd_float3 col = (i % 2 == 0) ? gunDark : gunBlack;
        gunVerts[gv++] = (Vertex){{x1, y1, 0.10f}, col};
        gunVerts[gv++] = (Vertex){{x2, y2, 0.10f}, col};
        gunVerts[gv++] = (Vertex){{x2, y2, 0.40f}, col};
        gunVerts[gv++] = (Vertex){{x1, y1, 0.10f}, col};
        gunVerts[gv++] = (Vertex){{x2, y2, 0.40f}, col};
        gunVerts[gv++] = (Vertex){{x1, y1, 0.40f}, col};
    }
    // Muzzle brake/flash hider
    BOX3D(gunVerts, gv, -0.014f, 0.011f, 0.40f, 0.014f, 0.039f, 0.46f, gunDark, gunBlack, gunDark, gunDark, gunMid, gunBlack);
    // Muzzle brake slots
    for (int i = 0; i < 3; i++) {
        float z = 0.41f + i * 0.015f;
        BOX3D(gunVerts, gv, -0.016f, 0.020f, z, -0.012f, 0.030f, z+0.008f, gunBlack, gunBlack, gunBlack, gunBlack, gunBlack, gunBlack);
        BOX3D(gunVerts, gv, 0.012f, 0.020f, z, 0.016f, 0.030f, z+0.008f, gunBlack, gunBlack, gunBlack, gunBlack, gunBlack, gunBlack);
    }
    // Front sight post
    BOX3D(gunVerts, gv, -0.003f, 0.035f, 0.32f, 0.003f, 0.055f, 0.35f, gunDark, gunDark, gunDark, gunDark, gunShine, gunDark);
    // Front sight base
    BOX3D(gunVerts, gv, -0.012f, 0.015f, 0.30f, 0.012f, 0.040f, 0.36f, gunMid, gunDark, gunMid, gunMid, gunLight, gunDark);
    // Gas block
    BOX3D(gunVerts, gv, -0.015f, 0.010f, 0.26f, 0.015f, 0.045f, 0.30f, gunMid, gunDark, gunLight, gunMid, gunLight, gunDark);

    // === HANDGUARD (RIS rail system) ===
    BOX3D(gunVerts, gv, -0.028f, -0.01f, 0.06f, 0.028f, 0.045f, 0.26f, gunMid, gunDark, gunLight, gunMid, gunLight, gunDark);
    // Top rail with grooves
    for (int i = 0; i < 10; i++) {
        float z = 0.08f + i * 0.017f;
        BOX3D(gunVerts, gv, -0.020f, 0.045f, z, 0.020f, 0.052f, z+0.010f, railDark, railDark, railDark, railDark, railMid, railDark);
    }
    // Side rails
    for (int i = 0; i < 8; i++) {
        float z = 0.10f + i * 0.018f;
        BOX3D(gunVerts, gv, -0.030f, 0.008f, z, -0.028f, 0.032f, z+0.010f, railDark, railDark, railDark, railDark, railDark, railDark);
        BOX3D(gunVerts, gv, 0.028f, 0.008f, z, 0.030f, 0.032f, z+0.010f, railDark, railDark, railDark, railDark, railDark, railDark);
    }
    // Bottom rail
    for (int i = 0; i < 8; i++) {
        float z = 0.10f + i * 0.018f;
        BOX3D(gunVerts, gv, -0.018f, -0.015f, z, 0.018f, -0.010f, z+0.010f, railDark, railDark, railDark, railDark, railDark, railDark);
    }
    // Vent holes on sides
    for (int i = 0; i < 4; i++) {
        float z = 0.12f + i * 0.035f;
        BOX3D(gunVerts, gv, -0.032f, 0.012f, z, -0.028f, 0.028f, z+0.020f, gunBlack, gunBlack, gunBlack, gunBlack, gunBlack, gunBlack);
        BOX3D(gunVerts, gv, 0.028f, 0.012f, z, 0.032f, 0.028f, z+0.020f, gunBlack, gunBlack, gunBlack, gunBlack, gunBlack, gunBlack);
    }

    // === VERTICAL FOREGRIP ===
    BOX3D(gunVerts, gv, -0.012f, -0.08f, 0.14f, 0.012f, -0.01f, 0.20f, gunMid, gunDark, gunLight, gunMid, gunLight, gunDark);
    // Grip texture
    for (int i = 0; i < 3; i++) {
        float y = -0.07f + i * 0.018f;
        BOX3D(gunVerts, gv, -0.014f, y, 0.145f, 0.014f, y+0.006f, 0.195f, gunDark, gunBlack, gunDark, gunDark, gunDark, gunBlack);
    }

    // === UPPER RECEIVER ===
    BOX3D(gunVerts, gv, -0.030f, 0.005f, -0.12f, 0.030f, 0.050f, 0.08f, gunMid, gunDark, gunLight, gunMid, gunLight, gunDark);
    // Ejection port cover
    BOX3D(gunVerts, gv, 0.030f, 0.015f, -0.06f, 0.035f, 0.042f, 0.02f, gunLight, gunMid, gunLight, gunLight, gunLight, gunMid);
    // Forward assist
    BOX3D(gunVerts, gv, 0.030f, 0.025f, -0.08f, 0.042f, 0.038f, -0.06f, gunMid, gunDark, gunLight, gunMid, gunLight, gunDark);
    // Charging handle
    BOX3D(gunVerts, gv, -0.008f, 0.045f, -0.14f, 0.008f, 0.058f, -0.10f, gunMid, gunDark, gunMid, gunMid, gunLight, gunDark);
    // Top rail continuation
    for (int i = 0; i < 6; i++) {
        float z = -0.10f + i * 0.022f;
        BOX3D(gunVerts, gv, -0.018f, 0.050f, z, 0.018f, 0.058f, z+0.014f, railDark, railDark, railDark, railDark, railMid, railDark);
    }

    // === RED DOT SIGHT ===
    // Sight body
    BOX3D(gunVerts, gv, -0.020f, 0.058f, -0.06f, 0.020f, 0.095f, 0.04f, gunDark, gunBlack, gunMid, gunMid, gunMid, gunBlack);
    // Lens housing front
    BOX3D(gunVerts, gv, -0.018f, 0.062f, 0.04f, 0.018f, 0.092f, 0.05f, gunDark, gunDark, gunDark, gunDark, gunMid, gunDark);
    // Lens (blue tint)
    BOX3D(gunVerts, gv, -0.014f, 0.066f, 0.048f, 0.014f, 0.088f, 0.052f, lensBlue, lensBlue, lensBlue, lensBlue, lensBlue, lensBlue);
    // Red dot (center)
    BOX3D(gunVerts, gv, -0.002f, 0.075f, 0.051f, 0.002f, 0.079f, 0.053f, redDot, redDot, redDot, redDot, redDot, redDot);
    // Lens housing rear
    BOX3D(gunVerts, gv, -0.018f, 0.062f, -0.07f, 0.018f, 0.092f, -0.06f, gunDark, gunDark, gunDark, gunDark, gunMid, gunDark);
    // Adjustment knobs
    BOX3D(gunVerts, gv, 0.020f, 0.072f, -0.02f, 0.028f, 0.082f, 0.0f, gunMid, gunDark, gunLight, gunMid, gunLight, gunDark);
    BOX3D(gunVerts, gv, -0.008f, 0.095f, -0.02f, 0.008f, 0.105f, 0.0f, gunMid, gunDark, gunLight, gunMid, gunLight, gunDark);

    // === LOWER RECEIVER ===
    BOX3D(gunVerts, gv, -0.028f, -0.02f, -0.14f, 0.028f, 0.008f, -0.02f, gunMid, gunDark, gunLight, gunMid, gunLight, gunDark);
    // Magazine well
    BOX3D(gunVerts, gv, -0.022f, -0.025f, -0.10f, 0.022f, -0.02f, 0.0f, gunDark, gunBlack, gunDark, gunDark, gunDark, gunBlack);
    // Trigger guard
    BOX3D(gunVerts, gv, -0.022f, -0.05f, -0.10f, 0.022f, -0.04f, -0.02f, gunDark, gunBlack, gunDark, gunDark, gunDark, gunBlack);
    BOX3D(gunVerts, gv, -0.022f, -0.065f, -0.10f, -0.018f, -0.04f, -0.02f, gunDark, gunBlack, gunDark, gunDark, gunDark, gunBlack);
    BOX3D(gunVerts, gv, 0.018f, -0.065f, -0.10f, 0.022f, -0.04f, -0.02f, gunDark, gunBlack, gunDark, gunDark, gunDark, gunBlack);
    BOX3D(gunVerts, gv, -0.022f, -0.065f, -0.10f, 0.022f, -0.060f, -0.095f, gunDark, gunBlack, gunDark, gunDark, gunDark, gunBlack);
    // Trigger
    BOX3D(gunVerts, gv, -0.004f, -0.055f, -0.06f, 0.004f, -0.04f, -0.05f, gunShine, gunMid, gunShine, gunShine, gunShine, gunMid);
    // Magazine release
    BOX3D(gunVerts, gv, 0.028f, -0.01f, -0.06f, 0.035f, 0.005f, -0.04f, gunMid, gunDark, gunLight, gunMid, gunLight, gunDark);
    // Bolt release
    BOX3D(gunVerts, gv, -0.032f, 0.0f, -0.08f, -0.028f, 0.025f, -0.05f, gunMid, gunDark, gunLight, gunMid, gunLight, gunDark);
    // Selector switch
    BOX3D(gunVerts, gv, -0.032f, -0.01f, -0.12f, -0.028f, 0.015f, -0.10f, gunShine, gunMid, gunShine, gunShine, gunShine, gunMid);

    // === PISTOL GRIP ===
    BOX3D(gunVerts, gv, -0.020f, -0.12f, -0.18f, 0.020f, -0.02f, -0.10f, gunMid, gunDark, gunLight, gunMid, gunLight, gunDark);
    // Grip texture
    for (int i = 0; i < 5; i++) {
        float y = -0.11f + i * 0.016f;
        BOX3D(gunVerts, gv, -0.022f, y, -0.175f, 0.022f, y+0.005f, -0.105f, gunDark, gunBlack, gunDark, gunDark, gunDark, gunBlack);
    }
    // Grip bottom
    BOX3D(gunVerts, gv, -0.022f, -0.125f, -0.18f, 0.022f, -0.12f, -0.10f, gunLight, gunMid, gunLight, gunLight, gunMid, gunDark);

    // === CURVED MAGAZINE ===
    BOX3D(gunVerts, gv, -0.016f, -0.14f, -0.08f, 0.016f, -0.02f, 0.0f, magMid, magDark, magMid, magMid, magMid, magDark);
    BOX3D(gunVerts, gv, -0.015f, -0.16f, -0.06f, 0.015f, -0.14f, 0.02f, magMid, magDark, magMid, magMid, magMid, magDark);
    // Magazine ribs
    for (int i = 0; i < 3; i++) {
        float y = -0.12f - i * 0.025f;
        BOX3D(gunVerts, gv, -0.017f, y, -0.075f, 0.017f, y+0.008f, -0.005f, magDark, magDark, magDark, magDark, magDark, magDark);
    }
    // Magazine base plate
    BOX3D(gunVerts, gv, -0.018f, -0.165f, -0.05f, 0.018f, -0.16f, 0.025f, gunDark, gunBlack, gunDark, gunDark, gunDark, gunBlack);

    // === COLLAPSIBLE STOCK ===
    // Buffer tube
    float tx = 0.0f, ty = 0.015f;
    float tr = 0.016f;
    for (int i = 0; i < 8; i++) {
        float a1 = i * M_PI / 4.0f;
        float a2 = (i + 1) * M_PI / 4.0f;
        float x1 = tx + tr * cosf(a1), y1 = ty + tr * sinf(a1);
        float x2 = tx + tr * cosf(a2), y2 = ty + tr * sinf(a2);
        simd_float3 col = (i % 2 == 0) ? gunMid : gunDark;
        gunVerts[gv++] = (Vertex){{x1, y1, -0.14f}, col};
        gunVerts[gv++] = (Vertex){{x2, y2, -0.14f}, col};
        gunVerts[gv++] = (Vertex){{x2, y2, -0.32f}, col};
        gunVerts[gv++] = (Vertex){{x1, y1, -0.14f}, col};
        gunVerts[gv++] = (Vertex){{x2, y2, -0.32f}, col};
        gunVerts[gv++] = (Vertex){{x1, y1, -0.32f}, col};
    }
    // Stock body
    BOX3D(gunVerts, gv, -0.022f, -0.02f, -0.42f, 0.022f, 0.045f, -0.30f, gunMid, gunDark, gunLight, gunMid, gunLight, gunDark);
    // Stock cheek rest
    BOX3D(gunVerts, gv, -0.018f, 0.045f, -0.40f, 0.018f, 0.058f, -0.32f, gunMid, gunDark, gunLight, gunMid, gunLight, gunDark);
    // Stock butt pad
    BOX3D(gunVerts, gv, -0.025f, -0.025f, -0.44f, 0.025f, 0.050f, -0.42f, gunDark, gunBlack, gunDark, gunDark, gunDark, gunBlack);
    // Stock adjustment lever
    BOX3D(gunVerts, gv, -0.008f, -0.01f, -0.34f, 0.008f, 0.005f, -0.32f, gunShine, gunMid, gunShine, gunShine, gunShine, gunMid);
    // Sling mount
    BOX3D(gunVerts, gv, -0.025f, -0.015f, -0.38f, -0.020f, 0.035f, -0.36f, gunDark, gunBlack, gunDark, gunDark, gunDark, gunBlack);

    // === HANDS WITH TACTICAL GLOVES ===
    // Front hand on foregrip
    BOX3D(gunVerts, gv, -0.018f, -0.10f, 0.12f, 0.018f, -0.06f, 0.22f, gloveMid, gloveDark, gloveMid, gloveMid, gloveMid, gloveDark);
    // Front fingers wrapped around grip
    for (int f = 0; f < 4; f++) {
        float fy = -0.095f + f * 0.008f;
        BOX3D(gunVerts, gv, 0.012f, fy, 0.14f, 0.028f, fy+0.012f, 0.20f, gloveMid, gloveDark, gloveMid, gloveMid, gloveMid, gloveDark);
    }
    // Front thumb
    BOX3D(gunVerts, gv, -0.018f, -0.065f, 0.16f, -0.030f, -0.045f, 0.20f, gloveMid, gloveDark, gloveMid, gloveMid, gloveMid, gloveDark);

    // Rear hand on pistol grip
    BOX3D(gunVerts, gv, -0.028f, -0.13f, -0.20f, 0.028f, -0.06f, -0.10f, gloveMid, gloveDark, gloveMid, gloveMid, gloveMid, gloveDark);
    // Index finger on trigger
    BOX3D(gunVerts, gv, -0.006f, -0.06f, -0.08f, 0.006f, -0.04f, -0.05f, skinMid, skinShadow, skinLight, skinMid, skinLight, skinDark);
    // Other fingers
    for (int f = 0; f < 3; f++) {
        float y = -0.09f - f * 0.014f;
        BOX3D(gunVerts, gv, -0.032f, y-0.010f, -0.18f, -0.018f, y, -0.11f, gloveMid, gloveDark, gloveMid, gloveMid, gloveMid, gloveDark);
    }
    // Rear thumb
    BOX3D(gunVerts, gv, 0.028f, -0.08f, -0.18f, 0.045f, -0.055f, -0.12f, gloveMid, gloveDark, gloveMid, gloveMid, gloveMid, gloveDark);

    // === ARMS ===
    // Front wrist
    BOX3D(gunVerts, gv, -0.025f, -0.12f, 0.02f, 0.025f, -0.05f, 0.14f, sleeveMid, sleeveDark, sleeveLight, sleeveMid, sleeveLight, sleeveDark);
    BOX3D(gunVerts, gv, -0.027f, -0.11f, 0.03f, 0.027f, -0.06f, 0.05f, cuffCol, cuffCol, cuffCol, cuffCol, cuffCol, cuffCol);
    // Front forearm
    BOX3D(gunVerts, gv, -0.035f, -0.15f, -0.12f, 0.035f, -0.05f, 0.04f, sleeveMid, sleeveDark, sleeveLight, sleeveMid, sleeveLight, sleeveDark);

    // Rear wrist
    BOX3D(gunVerts, gv, -0.035f, -0.15f, -0.30f, 0.035f, -0.06f, -0.18f, skinMid, skinDark, skinLight, skinMid, skinLight, skinShadow);
    // Rear forearm
    BOX3D(gunVerts, gv, -0.042f, -0.18f, -0.45f, 0.042f, -0.06f, -0.30f, sleeveMid, sleeveDark, sleeveLight, sleeveMid, sleeveLight, sleeveDark);
    BOX3D(gunVerts, gv, -0.044f, -0.17f, -0.32f, 0.044f, -0.07f, -0.30f, cuffCol, cuffCol, cuffCol, cuffCol, cuffCol, cuffCol);

    // Upper arms
    BOX3D(gunVerts, gv, -0.050f, -0.22f, -0.65f, 0.050f, -0.06f, -0.45f, sleeveMid, sleeveDark, sleeveLight, sleeveMid, sleeveLight, sleeveDark);
    BOX3D(gunVerts, gv, -0.060f, -0.30f, -0.85f, 0.060f, -0.08f, -0.65f, sleeveMid, sleeveDark, sleeveLight, sleeveMid, sleeveLight, sleeveDark);

    *count = gv;
    return [device newBufferWithBytes:gunVerts length:sizeof(Vertex) * gv options:MTLResourceStorageModeShared];
}

+ (id<MTLBuffer>)createRocketLauncherBufferWithDevice:(id<MTLDevice>)device vertexCount:(NSUInteger *)count {
    // RPG-7 / AT4 inspired rocket launcher with high polygon detail
    #define MAX_ROCKET_VERTS 6500
    Vertex gunVerts[MAX_ROCKET_VERTS];
    int gv = 0;

    // Colors - military olive drab with metal accents
    simd_float3 tubeOlive = {0.32, 0.36, 0.26};
    simd_float3 tubeDark = {0.22, 0.26, 0.18};
    simd_float3 tubeLight = {0.42, 0.46, 0.34};
    simd_float3 tubeBand = {0.28, 0.30, 0.24};
    simd_float3 metalBlack = {0.06, 0.06, 0.08};
    simd_float3 metalDark = {0.12, 0.12, 0.14};
    simd_float3 metalMid = {0.22, 0.22, 0.26};
    simd_float3 metalLight = {0.32, 0.32, 0.38};
    simd_float3 woodDark = {0.28, 0.18, 0.10};
    simd_float3 woodMid = {0.42, 0.28, 0.16};
    simd_float3 woodLight = {0.52, 0.36, 0.22};
    simd_float3 warningYellow = {0.85, 0.75, 0.15};
    simd_float3 warningBlack = {0.08, 0.08, 0.08};
    simd_float3 rocketTip = {0.70, 0.25, 0.15};
    simd_float3 rocketBody = {0.35, 0.38, 0.28};
    simd_float3 skinLight = {0.87, 0.72, 0.60};
    simd_float3 skinMid = {0.76, 0.60, 0.48};
    simd_float3 skinDark = {0.65, 0.50, 0.40};
    simd_float3 skinShadow = {0.50, 0.38, 0.30};
    simd_float3 sleeveLight = {0.22, 0.24, 0.20};
    simd_float3 sleeveMid = {0.15, 0.17, 0.14};
    simd_float3 sleeveDark = {0.10, 0.12, 0.09};
    simd_float3 cuffCol = {0.18, 0.18, 0.16};

    // === MAIN LAUNCH TUBE (12-sided polygon) ===
    float tx = 0.0f, ty = 0.04f;
    float tr = 0.055f;  // tube radius
    for (int i = 0; i < 12; i++) {
        float a1 = i * M_PI / 6.0f;
        float a2 = (i + 1) * M_PI / 6.0f;
        float x1 = tx + tr * cosf(a1), y1 = ty + tr * sinf(a1);
        float x2 = tx + tr * cosf(a2), y2 = ty + tr * sinf(a2);
        simd_float3 col = (i % 3 == 0) ? tubeDark : ((i % 3 == 1) ? tubeOlive : tubeLight);
        gunVerts[gv++] = (Vertex){{x1, y1, -0.12f}, col};
        gunVerts[gv++] = (Vertex){{x2, y2, -0.12f}, col};
        gunVerts[gv++] = (Vertex){{x2, y2, 0.42f}, col};
        gunVerts[gv++] = (Vertex){{x1, y1, -0.12f}, col};
        gunVerts[gv++] = (Vertex){{x2, y2, 0.42f}, col};
        gunVerts[gv++] = (Vertex){{x1, y1, 0.42f}, col};
    }

    // Reinforcement bands around tube
    for (int b = 0; b < 4; b++) {
        float z = -0.08f + b * 0.13f;
        for (int i = 0; i < 12; i++) {
            float a1 = i * M_PI / 6.0f;
            float a2 = (i + 1) * M_PI / 6.0f;
            float x1 = tx + (tr+0.005f) * cosf(a1), y1 = ty + (tr+0.005f) * sinf(a1);
            float x2 = tx + (tr+0.005f) * cosf(a2), y2 = ty + (tr+0.005f) * sinf(a2);
            gunVerts[gv++] = (Vertex){{x1, y1, z}, tubeBand};
            gunVerts[gv++] = (Vertex){{x2, y2, z}, tubeBand};
            gunVerts[gv++] = (Vertex){{x2, y2, z+0.02f}, tubeBand};
            gunVerts[gv++] = (Vertex){{x1, y1, z}, tubeBand};
            gunVerts[gv++] = (Vertex){{x2, y2, z+0.02f}, tubeBand};
            gunVerts[gv++] = (Vertex){{x1, y1, z+0.02f}, tubeBand};
        }
    }

    // === FRONT MUZZLE / BLAST CONE ===
    // Flared front opening
    for (int i = 0; i < 12; i++) {
        float a1 = i * M_PI / 6.0f;
        float a2 = (i + 1) * M_PI / 6.0f;
        float r1 = tr, r2 = tr + 0.015f;
        float x1a = tx + r1 * cosf(a1), y1a = ty + r1 * sinf(a1);
        float x2a = tx + r1 * cosf(a2), y2a = ty + r1 * sinf(a2);
        float x1b = tx + r2 * cosf(a1), y1b = ty + r2 * sinf(a1);
        float x2b = tx + r2 * cosf(a2), y2b = ty + r2 * sinf(a2);
        simd_float3 col = (i % 2 == 0) ? metalDark : metalMid;
        gunVerts[gv++] = (Vertex){{x1a, y1a, 0.42f}, col};
        gunVerts[gv++] = (Vertex){{x2a, y2a, 0.42f}, col};
        gunVerts[gv++] = (Vertex){{x2b, y2b, 0.48f}, col};
        gunVerts[gv++] = (Vertex){{x1a, y1a, 0.42f}, col};
        gunVerts[gv++] = (Vertex){{x2b, y2b, 0.48f}, col};
        gunVerts[gv++] = (Vertex){{x1b, y1b, 0.48f}, col};
    }
    // Muzzle rim
    BOX3D(gunVerts, gv, -0.075f, -0.035f, 0.48f, 0.075f, 0.115f, 0.50f, metalDark, metalBlack, metalMid, metalDark, metalMid, metalBlack);

    // === REAR EXHAUST / VENTURI ===
    // Rear flare
    for (int i = 0; i < 12; i++) {
        float a1 = i * M_PI / 6.0f;
        float a2 = (i + 1) * M_PI / 6.0f;
        float r1 = tr, r2 = tr + 0.012f;
        float x1a = tx + r1 * cosf(a1), y1a = ty + r1 * sinf(a1);
        float x2a = tx + r1 * cosf(a2), y2a = ty + r1 * sinf(a2);
        float x1b = tx + r2 * cosf(a1), y1b = ty + r2 * sinf(a1);
        float x2b = tx + r2 * cosf(a2), y2b = ty + r2 * sinf(a2);
        simd_float3 col = (i % 2 == 0) ? metalDark : metalMid;
        gunVerts[gv++] = (Vertex){{x1b, y1b, -0.18f}, col};
        gunVerts[gv++] = (Vertex){{x2b, y2b, -0.18f}, col};
        gunVerts[gv++] = (Vertex){{x2a, y2a, -0.12f}, col};
        gunVerts[gv++] = (Vertex){{x1b, y1b, -0.18f}, col};
        gunVerts[gv++] = (Vertex){{x2a, y2a, -0.12f}, col};
        gunVerts[gv++] = (Vertex){{x1a, y1a, -0.12f}, col};
    }

    // Warning stripes on rear
    for (int s = 0; s < 4; s++) {
        float a = s * M_PI / 2.0f + M_PI / 4.0f;
        float x = tx + (tr+0.008f) * cosf(a);
        float y = ty + (tr+0.008f) * sinf(a);
        BOX3D(gunVerts, gv, x-0.015f, y-0.015f, -0.17f, x+0.015f, y+0.015f, -0.14f,
              (s%2==0) ? warningYellow : warningBlack, (s%2==0) ? warningYellow : warningBlack,
              (s%2==0) ? warningYellow : warningBlack, (s%2==0) ? warningYellow : warningBlack,
              (s%2==0) ? warningYellow : warningBlack, (s%2==0) ? warningYellow : warningBlack);
    }

    // === OPTICAL SIGHT ===
    // Sight mounting bracket
    BOX3D(gunVerts, gv, -0.025f, 0.095f, 0.02f, 0.025f, 0.115f, 0.18f, metalDark, metalBlack, metalMid, metalDark, metalMid, metalBlack);
    // Sight body (octagonal tube)
    float sx = 0.0f, sy = 0.14f, sr = 0.022f;
    for (int i = 0; i < 8; i++) {
        float a1 = i * M_PI / 4.0f;
        float a2 = (i + 1) * M_PI / 4.0f;
        float x1 = sx + sr * cosf(a1), y1 = sy + sr * sinf(a1);
        float x2 = sx + sr * cosf(a2), y2 = sy + sr * sinf(a2);
        simd_float3 col = (i % 2 == 0) ? metalDark : metalBlack;
        gunVerts[gv++] = (Vertex){{x1, y1, 0.04f}, col};
        gunVerts[gv++] = (Vertex){{x2, y2, 0.04f}, col};
        gunVerts[gv++] = (Vertex){{x2, y2, 0.22f}, col};
        gunVerts[gv++] = (Vertex){{x1, y1, 0.04f}, col};
        gunVerts[gv++] = (Vertex){{x2, y2, 0.22f}, col};
        gunVerts[gv++] = (Vertex){{x1, y1, 0.22f}, col};
    }
    // Sight lens
    BOX3D(gunVerts, gv, -0.018f, 0.122f, 0.22f, 0.018f, 0.158f, 0.225f, metalLight, metalMid, metalLight, metalLight, metalLight, metalMid);
    // Eyepiece
    BOX3D(gunVerts, gv, -0.020f, 0.12f, 0.02f, 0.020f, 0.16f, 0.04f, metalDark, metalBlack, metalDark, metalDark, metalMid, metalBlack);
    // Rangefinder markings
    BOX3D(gunVerts, gv, -0.012f, 0.162f, 0.10f, 0.012f, 0.168f, 0.18f, metalLight, metalMid, metalLight, metalLight, metalLight, metalMid);

    // === FRONT GRIP (wooden) ===
    BOX3D(gunVerts, gv, -0.028f, -0.08f, 0.18f, 0.028f, -0.005f, 0.32f, woodMid, woodDark, woodLight, woodMid, woodLight, woodDark);
    // Grip texture
    for (int i = 0; i < 5; i++) {
        float z = 0.20f + i * 0.022f;
        BOX3D(gunVerts, gv, -0.030f, -0.075f, z, 0.030f, -0.070f, z+0.012f, woodDark, woodDark, woodDark, woodDark, woodDark, woodDark);
    }
    // Grip end cap
    BOX3D(gunVerts, gv, -0.030f, -0.085f, 0.18f, 0.030f, -0.08f, 0.32f, metalDark, metalBlack, metalDark, metalDark, metalDark, metalBlack);

    // === REAR GRIP / TRIGGER ASSEMBLY ===
    // Pistol grip
    BOX3D(gunVerts, gv, -0.024f, -0.12f, -0.02f, 0.024f, -0.005f, 0.08f, woodMid, woodDark, woodLight, woodMid, woodLight, woodDark);
    // Grip texture
    for (int i = 0; i < 4; i++) {
        float y = -0.11f + i * 0.022f;
        BOX3D(gunVerts, gv, -0.026f, y, -0.015f, 0.026f, y+0.008f, 0.075f, woodDark, woodDark, woodDark, woodDark, woodDark, woodDark);
    }
    // Trigger guard
    BOX3D(gunVerts, gv, -0.020f, -0.06f, 0.0f, 0.020f, -0.05f, 0.06f, metalDark, metalBlack, metalDark, metalDark, metalDark, metalBlack);
    BOX3D(gunVerts, gv, -0.020f, -0.075f, 0.0f, -0.016f, -0.05f, 0.06f, metalDark, metalBlack, metalDark, metalDark, metalDark, metalBlack);
    BOX3D(gunVerts, gv, 0.016f, -0.075f, 0.0f, 0.020f, -0.05f, 0.06f, metalDark, metalBlack, metalDark, metalDark, metalDark, metalBlack);
    BOX3D(gunVerts, gv, -0.020f, -0.075f, 0.0f, 0.020f, -0.070f, 0.005f, metalDark, metalBlack, metalDark, metalDark, metalDark, metalBlack);
    // Trigger
    BOX3D(gunVerts, gv, -0.005f, -0.065f, 0.035f, 0.005f, -0.05f, 0.045f, metalMid, metalDark, metalLight, metalMid, metalLight, metalDark);
    // Trigger mechanism housing
    BOX3D(gunVerts, gv, -0.030f, -0.02f, -0.02f, 0.030f, 0.02f, 0.10f, metalMid, metalDark, metalLight, metalMid, metalLight, metalDark);

    // === SHOULDER REST ===
    BOX3D(gunVerts, gv, -0.035f, -0.04f, -0.35f, 0.035f, 0.08f, -0.12f, tubeOlive, tubeDark, tubeLight, tubeOlive, tubeLight, tubeDark);
    // Shoulder pad
    BOX3D(gunVerts, gv, -0.042f, -0.05f, -0.38f, 0.042f, 0.085f, -0.35f, metalDark, metalBlack, metalDark, metalDark, metalDark, metalBlack);
    // Cheek rest
    BOX3D(gunVerts, gv, -0.028f, 0.08f, -0.30f, 0.028f, 0.10f, -0.15f, tubeOlive, tubeDark, tubeLight, tubeOlive, tubeLight, tubeDark);

    // === LOADED ROCKET (visible in tube) ===
    // Rocket warhead tip (cone approximation)
    BOX3D(gunVerts, gv, -0.008f, 0.032f, 0.45f, 0.008f, 0.048f, 0.52f, rocketTip, rocketTip, rocketTip, rocketTip, rocketTip, rocketTip);
    BOX3D(gunVerts, gv, -0.015f, 0.025f, 0.40f, 0.015f, 0.055f, 0.45f, rocketTip, rocketTip, rocketTip, rocketTip, rocketTip, rocketTip);
    // Rocket body
    BOX3D(gunVerts, gv, -0.025f, 0.015f, 0.10f, 0.025f, 0.065f, 0.40f, rocketBody, rocketBody, rocketBody, rocketBody, rocketBody, rocketBody);
    // Rocket fins (4)
    for (int f = 0; f < 4; f++) {
        float a = f * M_PI / 2.0f;
        float fx = 0.035f * cosf(a);
        float fy = 0.04f + 0.035f * sinf(a);
        BOX3D(gunVerts, gv, fx-0.003f, fy-0.003f, 0.12f, fx+0.003f, fy+0.003f, 0.20f, metalDark, metalDark, metalMid, metalMid, metalMid, metalDark);
    }

    // === HANDS ===
    // Front hand on front grip
    BOX3D(gunVerts, gv, -0.035f, -0.10f, 0.20f, 0.035f, -0.04f, 0.30f, skinMid, skinDark, skinLight, skinMid, skinLight, skinShadow);
    // Front fingers
    for (int f = 0; f < 4; f++) {
        float x = -0.025f + f * 0.015f;
        BOX3D(gunVerts, gv, x, -0.11f, 0.22f, x+0.012f, -0.085f, 0.28f, skinMid, skinShadow, skinLight, skinMid, skinLight, skinDark);
    }
    // Front thumb
    BOX3D(gunVerts, gv, 0.035f, -0.06f, 0.22f, 0.052f, -0.035f, 0.28f, skinMid, skinDark, skinLight, skinMid, skinLight, skinDark);

    // Rear hand on pistol grip
    BOX3D(gunVerts, gv, -0.032f, -0.14f, -0.02f, 0.032f, -0.06f, 0.08f, skinMid, skinDark, skinLight, skinMid, skinLight, skinShadow);
    // Index finger on trigger
    BOX3D(gunVerts, gv, -0.006f, -0.07f, 0.03f, 0.006f, -0.05f, 0.045f, skinMid, skinShadow, skinLight, skinMid, skinLight, skinDark);
    // Other fingers
    for (int f = 0; f < 3; f++) {
        float y = -0.10f - f * 0.014f;
        BOX3D(gunVerts, gv, -0.035f, y-0.012f, -0.01f, -0.022f, y, 0.07f, skinMid, skinDark, skinLight, skinMid, skinLight, skinDark);
    }
    // Rear thumb
    BOX3D(gunVerts, gv, 0.032f, -0.08f, 0.0f, 0.050f, -0.055f, 0.06f, skinMid, skinDark, skinLight, skinMid, skinLight, skinDark);

    // === ARMS ===
    // Front wrist
    BOX3D(gunVerts, gv, -0.040f, -0.13f, 0.08f, 0.040f, -0.04f, 0.22f, skinMid, skinDark, skinLight, skinMid, skinLight, skinShadow);
    // Front forearm
    BOX3D(gunVerts, gv, -0.045f, -0.16f, -0.05f, 0.045f, -0.05f, 0.10f, sleeveMid, sleeveDark, sleeveLight, sleeveMid, sleeveLight, sleeveDark);
    BOX3D(gunVerts, gv, -0.047f, -0.15f, 0.08f, 0.047f, -0.06f, 0.10f, cuffCol, cuffCol, cuffCol, cuffCol, cuffCol, cuffCol);

    // Rear wrist
    BOX3D(gunVerts, gv, -0.038f, -0.16f, -0.15f, 0.038f, -0.06f, -0.02f, skinMid, skinDark, skinLight, skinMid, skinLight, skinShadow);
    // Rear forearm
    BOX3D(gunVerts, gv, -0.045f, -0.19f, -0.30f, 0.045f, -0.06f, -0.15f, sleeveMid, sleeveDark, sleeveLight, sleeveMid, sleeveLight, sleeveDark);
    BOX3D(gunVerts, gv, -0.047f, -0.18f, -0.17f, 0.047f, -0.07f, -0.15f, cuffCol, cuffCol, cuffCol, cuffCol, cuffCol, cuffCol);

    // Upper arms
    BOX3D(gunVerts, gv, -0.055f, -0.25f, -0.50f, 0.055f, -0.06f, -0.30f, sleeveMid, sleeveDark, sleeveLight, sleeveMid, sleeveLight, sleeveDark);
    BOX3D(gunVerts, gv, -0.065f, -0.32f, -0.75f, 0.065f, -0.08f, -0.50f, sleeveMid, sleeveDark, sleeveLight, sleeveMid, sleeveLight, sleeveDark);
    BOX3D(gunVerts, gv, -0.075f, -0.40f, -0.95f, 0.075f, -0.10f, -0.75f, sleeveMid, sleeveDark, sleeveLight, sleeveMid, sleeveLight, sleeveDark);

    *count = gv;
    return [device newBufferWithBytes:gunVerts length:sizeof(Vertex) * gv options:MTLResourceStorageModeShared];
}

+ (id<MTLBuffer>)createEnemyBufferWithDevice:(id<MTLDevice>)device vertexCount:(NSUInteger *)count {
    #define MAX_ENEMY_VERTS 4000
    Vertex enemyVerts[MAX_ENEMY_VERTS];
    int ev = 0;

    // Colors - enemy in red/dark tactical gear
    simd_float3 vestDark = {0.45f, 0.08f, 0.08f};
    simd_float3 vestMid = {0.60f, 0.12f, 0.12f};
    simd_float3 vestLight = {0.72f, 0.18f, 0.18f};
    simd_float3 pantsDark = {0.18f, 0.15f, 0.14f};
    simd_float3 pantsMid = {0.28f, 0.24f, 0.22f};
    simd_float3 pantsLight = {0.35f, 0.30f, 0.28f};
    simd_float3 bootDark = {0.12f, 0.10f, 0.08f};
    simd_float3 bootMid = {0.20f, 0.16f, 0.12f};
    simd_float3 skinTone = {0.50f, 0.35f, 0.25f};
    simd_float3 skinDark = {0.40f, 0.28f, 0.20f};
    simd_float3 skinLight = {0.58f, 0.42f, 0.32f};
    simd_float3 helmetDark = {0.20f, 0.22f, 0.18f};
    simd_float3 helmetMid = {0.30f, 0.32f, 0.28f};
    simd_float3 helmetLight = {0.38f, 0.40f, 0.36f};
    simd_float3 beltCol = {0.15f, 0.12f, 0.10f};
    simd_float3 pouchCol = {0.25f, 0.20f, 0.15f};
    simd_float3 gunDark = {0.12f, 0.12f, 0.14f};
    simd_float3 gunMid = {0.22f, 0.22f, 0.25f};
    simd_float3 gunLight = {0.30f, 0.30f, 0.33f};
    simd_float3 strapCol = {0.20f, 0.18f, 0.15f};

    // === HEAD WITH HELMET ===
    // Helmet - main dome
    BOX3D(enemyVerts, ev, -0.12f, 0.62f, -0.10f, 0.12f, 0.82f, 0.10f, helmetMid, helmetDark, helmetLight, helmetMid, helmetLight, helmetDark);
    // Helmet brim
    BOX3D(enemyVerts, ev, -0.13f, 0.60f, -0.12f, 0.13f, 0.64f, 0.12f, helmetDark, helmetDark, helmetMid, helmetMid, helmetDark, helmetDark);
    // Helmet rim detail
    BOX3D(enemyVerts, ev, -0.125f, 0.78f, -0.11f, 0.125f, 0.82f, 0.11f, helmetDark, helmetDark, helmetDark, helmetDark, helmetMid, helmetDark);
    // Helmet strap
    BOX3D(enemyVerts, ev, -0.11f, 0.55f, 0.06f, -0.08f, 0.65f, 0.08f, strapCol, strapCol, strapCol, strapCol, strapCol, strapCol);
    BOX3D(enemyVerts, ev, 0.08f, 0.55f, 0.06f, 0.11f, 0.65f, 0.08f, strapCol, strapCol, strapCol, strapCol, strapCol, strapCol);
    // Face
    BOX3D(enemyVerts, ev, -0.09f, 0.52f, 0.06f, 0.09f, 0.62f, 0.11f, skinTone, skinDark, skinLight, skinTone, skinLight, skinDark);
    // Eyes area (darker)
    BOX3D(enemyVerts, ev, -0.07f, 0.56f, 0.10f, 0.07f, 0.60f, 0.115f, skinDark, skinDark, skinDark, skinDark, skinDark, skinDark);
    // Nose
    BOX3D(enemyVerts, ev, -0.015f, 0.52f, 0.10f, 0.015f, 0.58f, 0.13f, skinTone, skinTone, skinLight, skinTone, skinTone, skinTone);
    // Chin/jaw
    BOX3D(enemyVerts, ev, -0.07f, 0.48f, 0.04f, 0.07f, 0.54f, 0.10f, skinTone, skinDark, skinLight, skinTone, skinLight, skinDark);

    // Neck
    BOX3D(enemyVerts, ev, -0.06f, 0.42f, -0.04f, 0.06f, 0.52f, 0.06f, skinTone, skinDark, skinLight, skinTone, skinLight, skinDark);

    // === TORSO WITH TACTICAL VEST ===
    // Main chest
    BOX3D(enemyVerts, ev, -0.16f, 0.15f, -0.10f, 0.16f, 0.45f, 0.10f, vestMid, vestDark, vestLight, vestMid, vestLight, vestDark);
    // Vest front plate
    BOX3D(enemyVerts, ev, -0.13f, 0.18f, 0.09f, 0.13f, 0.42f, 0.12f, vestDark, vestDark, vestMid, vestMid, vestMid, vestDark);
    // Vest back plate
    BOX3D(enemyVerts, ev, -0.13f, 0.18f, -0.12f, 0.13f, 0.42f, -0.09f, vestDark, vestMid, vestDark, vestDark, vestMid, vestDark);
    // Shoulder pads
    BOX3D(enemyVerts, ev, -0.20f, 0.38f, -0.08f, -0.14f, 0.46f, 0.08f, vestMid, vestDark, vestLight, vestMid, vestLight, vestDark);
    BOX3D(enemyVerts, ev, 0.14f, 0.38f, -0.08f, 0.20f, 0.46f, 0.08f, vestMid, vestDark, vestLight, vestMid, vestLight, vestDark);
    // Collar
    BOX3D(enemyVerts, ev, -0.10f, 0.42f, -0.06f, 0.10f, 0.48f, 0.06f, vestDark, vestDark, vestMid, vestMid, vestMid, vestDark);

    // Magazine pouches on vest
    BOX3D(enemyVerts, ev, -0.14f, 0.20f, 0.10f, -0.08f, 0.32f, 0.14f, pouchCol, pouchCol, pouchCol, pouchCol, pouchCol, pouchCol);
    BOX3D(enemyVerts, ev, -0.06f, 0.20f, 0.10f, 0.0f, 0.32f, 0.14f, pouchCol, pouchCol, pouchCol, pouchCol, pouchCol, pouchCol);
    BOX3D(enemyVerts, ev, 0.02f, 0.20f, 0.10f, 0.08f, 0.32f, 0.14f, pouchCol, pouchCol, pouchCol, pouchCol, pouchCol, pouchCol);

    // Belt
    BOX3D(enemyVerts, ev, -0.17f, 0.10f, -0.11f, 0.17f, 0.16f, 0.11f, beltCol, beltCol, beltCol, beltCol, beltCol, beltCol);
    // Belt buckle
    BOX3D(enemyVerts, ev, -0.03f, 0.11f, 0.10f, 0.03f, 0.15f, 0.12f, gunMid, gunMid, gunLight, gunMid, gunLight, gunMid);
    // Holster on belt (right side)
    BOX3D(enemyVerts, ev, 0.14f, 0.02f, 0.04f, 0.20f, 0.14f, 0.10f, beltCol, beltCol, beltCol, beltCol, beltCol, beltCol);

    // === ARMS - Segmented ===
    // Left upper arm
    BOX3D(enemyVerts, ev, -0.28f, 0.22f, -0.07f, -0.16f, 0.40f, 0.07f, vestMid, vestDark, vestLight, vestMid, vestLight, vestDark);
    // Left elbow
    BOX3D(enemyVerts, ev, -0.30f, 0.18f, -0.06f, -0.18f, 0.24f, 0.06f, vestDark, vestDark, vestMid, vestMid, vestMid, vestDark);
    // Left forearm
    BOX3D(enemyVerts, ev, -0.32f, 0.08f, -0.055f, -0.20f, 0.20f, 0.055f, vestMid, vestDark, vestLight, vestMid, vestLight, vestDark);
    // Left hand
    BOX3D(enemyVerts, ev, -0.33f, 0.04f, -0.04f, -0.22f, 0.10f, 0.04f, skinTone, skinDark, skinLight, skinTone, skinLight, skinDark);

    // Right upper arm (holding gun forward)
    BOX3D(enemyVerts, ev, 0.16f, 0.22f, -0.07f, 0.28f, 0.40f, 0.07f, vestMid, vestDark, vestLight, vestMid, vestLight, vestDark);
    // Right elbow
    BOX3D(enemyVerts, ev, 0.24f, 0.18f, -0.06f, 0.34f, 0.28f, 0.06f, vestDark, vestDark, vestMid, vestMid, vestMid, vestDark);
    // Right forearm (extended forward)
    BOX3D(enemyVerts, ev, 0.28f, 0.20f, 0.02f, 0.38f, 0.30f, 0.20f, vestMid, vestDark, vestLight, vestMid, vestLight, vestDark);
    // Right hand (holding gun)
    BOX3D(enemyVerts, ev, 0.32f, 0.22f, 0.18f, 0.42f, 0.30f, 0.28f, skinTone, skinDark, skinLight, skinTone, skinLight, skinDark);

    // === LEGS - Segmented ===
    // Left thigh
    BOX3D(enemyVerts, ev, -0.14f, -0.20f, -0.08f, -0.02f, 0.12f, 0.08f, pantsMid, pantsDark, pantsLight, pantsMid, pantsLight, pantsDark);
    // Left knee
    BOX3D(enemyVerts, ev, -0.13f, -0.26f, -0.075f, -0.03f, -0.18f, 0.075f, pantsDark, pantsDark, pantsMid, pantsMid, pantsMid, pantsDark);
    // Left shin
    BOX3D(enemyVerts, ev, -0.12f, -0.48f, -0.07f, -0.04f, -0.24f, 0.07f, pantsMid, pantsDark, pantsLight, pantsMid, pantsLight, pantsDark);
    // Left boot
    BOX3D(enemyVerts, ev, -0.13f, -0.58f, -0.08f, -0.03f, -0.46f, 0.08f, bootMid, bootDark, bootMid, bootMid, bootMid, bootDark);
    BOX3D(enemyVerts, ev, -0.14f, -0.60f, -0.04f, -0.02f, -0.56f, 0.12f, bootDark, bootDark, bootMid, bootMid, bootDark, bootDark);

    // Right thigh
    BOX3D(enemyVerts, ev, 0.02f, -0.20f, -0.08f, 0.14f, 0.12f, 0.08f, pantsMid, pantsDark, pantsLight, pantsMid, pantsLight, pantsDark);
    // Right knee
    BOX3D(enemyVerts, ev, 0.03f, -0.26f, -0.075f, 0.13f, -0.18f, 0.075f, pantsDark, pantsDark, pantsMid, pantsMid, pantsMid, pantsDark);
    // Right shin
    BOX3D(enemyVerts, ev, 0.04f, -0.48f, -0.07f, 0.12f, -0.24f, 0.07f, pantsMid, pantsDark, pantsLight, pantsMid, pantsLight, pantsDark);
    // Right boot
    BOX3D(enemyVerts, ev, 0.03f, -0.58f, -0.08f, 0.13f, -0.46f, 0.08f, bootMid, bootDark, bootMid, bootMid, bootMid, bootDark);
    BOX3D(enemyVerts, ev, 0.02f, -0.60f, -0.04f, 0.14f, -0.56f, 0.12f, bootDark, bootDark, bootMid, bootMid, bootDark, bootDark);

    // === GUN (held in right hand) ===
    // Gun body
    BOX3D(enemyVerts, ev, 0.35f, 0.24f, 0.26f, 0.42f, 0.30f, 0.55f, gunMid, gunDark, gunLight, gunMid, gunLight, gunDark);
    // Gun barrel
    BOX3D(enemyVerts, ev, 0.37f, 0.25f, 0.55f, 0.40f, 0.29f, 0.70f, gunDark, gunDark, gunDark, gunDark, gunDark, gunDark);
    // Gun stock
    BOX3D(enemyVerts, ev, 0.36f, 0.22f, 0.10f, 0.41f, 0.28f, 0.28f, gunMid, gunDark, gunMid, gunMid, gunLight, gunDark);
    // Gun magazine
    BOX3D(enemyVerts, ev, 0.37f, 0.18f, 0.32f, 0.40f, 0.25f, 0.42f, gunDark, gunDark, gunMid, gunMid, gunDark, gunDark);
    // Gun sight
    BOX3D(enemyVerts, ev, 0.38f, 0.30f, 0.45f, 0.39f, 0.33f, 0.50f, gunDark, gunDark, gunDark, gunDark, gunLight, gunDark);

    // Gun strap (slung across body)
    BOX3D(enemyVerts, ev, 0.10f, 0.15f, 0.08f, 0.14f, 0.42f, 0.10f, strapCol, strapCol, strapCol, strapCol, strapCol, strapCol);
    BOX3D(enemyVerts, ev, -0.14f, 0.25f, -0.10f, -0.10f, 0.42f, -0.08f, strapCol, strapCol, strapCol, strapCol, strapCol, strapCol);

    *count = ev;
    return [device newBufferWithBytes:enemyVerts length:sizeof(Vertex) * ev options:MTLResourceStorageModeShared];
}

+ (id<MTLBuffer>)createRemotePlayerBufferWithDevice:(id<MTLDevice>)device vertexCount:(NSUInteger *)count {
    #define MAX_REMOTE_PLAYER_VERTS 600
    Vertex playerVerts[MAX_REMOTE_PLAYER_VERTS];
    int pv = 0;

    simd_float3 bodyDark = {0.1f, 0.1f, 0.5f};
    simd_float3 bodyMid = {0.15f, 0.15f, 0.7f};
    simd_float3 bodyLight = {0.2f, 0.2f, 0.8f};
    simd_float3 skinTone = {0.8f, 0.65f, 0.5f};   // Light skin
    simd_float3 skinDark = {0.65f, 0.5f, 0.4f};  // Darker light skin
    simd_float3 gunC1 = {0.2f, 0.2f, 0.2f};
    simd_float3 gunC2 = {0.1f, 0.1f, 0.1f};
    simd_float3 gunC3 = {0.25f, 0.25f, 0.25f};

    BOX3D(playerVerts, pv, -0.15f, 0.5f, -0.1f, 0.15f, 0.8f, 0.1f, skinTone, skinDark, skinTone, skinTone, skinTone, skinDark);
    BOX3D(playerVerts, pv, -0.2f, 0.0f, -0.12f, 0.2f, 0.5f, 0.12f, bodyMid, bodyDark, bodyLight, bodyMid, bodyLight, bodyDark);
    BOX3D(playerVerts, pv, -0.35f, 0.1f, -0.08f, -0.2f, 0.45f, 0.08f, bodyMid, bodyDark, bodyLight, bodyMid, bodyLight, bodyDark);
    BOX3D(playerVerts, pv, 0.2f, 0.1f, -0.08f, 0.35f, 0.45f, 0.08f, bodyMid, bodyDark, bodyLight, bodyMid, bodyLight, bodyDark);
    BOX3D(playerVerts, pv, -0.18f, -0.6f, -0.1f, -0.02f, 0.0f, 0.1f, bodyDark, bodyDark, bodyMid, bodyMid, bodyMid, bodyDark);
    BOX3D(playerVerts, pv, 0.02f, -0.6f, -0.1f, 0.18f, 0.0f, 0.1f, bodyDark, bodyDark, bodyMid, bodyMid, bodyMid, bodyDark);
    BOX3D(playerVerts, pv, 0.3f, 0.25f, -0.04f, 0.6f, 0.32f, 0.04f, gunC1, gunC2, gunC3, gunC2, gunC1, gunC2);

    *count = pv;
    return [device newBufferWithBytes:playerVerts length:sizeof(Vertex) * pv options:MTLResourceStorageModeShared];
}

+ (id<MTLBuffer>)createMuzzleFlashBufferWithDevice:(id<MTLDevice>)device {
    simd_float3 flashYellow = {1.0f, 0.95f, 0.4f};
    simd_float3 flashOrange = {1.0f, 0.7f, 0.2f};
    float s = 0.02f;
    Vertex flashVerts[] = {
        {{-s*4, -s*0.4f, 0}, flashOrange}, {{s*4, -s*0.4f, 0}, flashOrange}, {{s*4, s*0.4f, 0}, flashYellow},
        {{-s*4, -s*0.4f, 0}, flashOrange}, {{s*4, s*0.4f, 0}, flashYellow}, {{-s*4, s*0.4f, 0}, flashYellow},
        {{-s*0.4f, -s*4, 0}, flashOrange}, {{s*0.4f, -s*4, 0}, flashOrange}, {{s*0.4f, s*4, 0}, flashYellow},
        {{-s*0.4f, -s*4, 0}, flashOrange}, {{s*0.4f, s*4, 0}, flashYellow}, {{-s*0.4f, s*4, 0}, flashYellow},
        {{-s*2.5f, -s*2.5f, 0}, flashOrange}, {{-s*2.0f, -s*2.0f, 0}, flashYellow}, {{s*2.0f, s*2.0f, 0}, flashYellow},
        {{-s*2.5f, -s*2.5f, 0}, flashOrange}, {{s*2.0f, s*2.0f, 0}, flashYellow}, {{s*2.5f, s*2.5f, 0}, flashOrange},
    };
    return [device newBufferWithBytes:flashVerts length:sizeof(flashVerts) options:MTLResourceStorageModeShared];
}

// ============================================
// UI GEOMETRY
// ============================================

+ (id<MTLBuffer>)createHealthBarBgBufferWithDevice:(id<MTLDevice>)device {
    simd_float3 bgCol = {0.4f, 0.0f, 0.0f};
    Vertex hbBg[] = {
        {{-0.3f, 0.0f, 0.0f}, bgCol}, {{0.3f, 0.0f, 0.0f}, bgCol}, {{0.3f, 0.1f, 0.0f}, bgCol},
        {{-0.3f, 0.0f, 0.0f}, bgCol}, {{0.3f, 0.1f, 0.0f}, bgCol}, {{-0.3f, 0.1f, 0.0f}, bgCol},
    };
    return [device newBufferWithBytes:hbBg length:sizeof(hbBg) options:MTLResourceStorageModeShared];
}

+ (id<MTLBuffer>)createHealthBarFgBufferWithDevice:(id<MTLDevice>)device {
    simd_float3 fgCol = {0.0f, 1.0f, 0.0f};
    Vertex hbFg[] = {
        {{-0.28f, 0.01f, 0.0f}, fgCol}, {{0.28f, 0.01f, 0.0f}, fgCol}, {{0.28f, 0.09f, 0.0f}, fgCol},
        {{-0.28f, 0.01f, 0.0f}, fgCol}, {{0.28f, 0.09f, 0.0f}, fgCol}, {{-0.28f, 0.09f, 0.0f}, fgCol},
    };
    return [device newBufferWithBytes:hbFg length:sizeof(hbFg) options:MTLResourceStorageModeShared];
}

+ (id<MTLBuffer>)createPlayerHpBgBufferWithDevice:(id<MTLDevice>)device {
    simd_float3 bgCol = {0.4f, 0.0f, 0.0f};
    Vertex phBg[] = {
        {{-0.3f, 0.85f, 0}, bgCol}, {{0.3f, 0.85f, 0}, bgCol}, {{0.3f, 0.92f, 0}, bgCol},
        {{-0.3f, 0.85f, 0}, bgCol}, {{0.3f, 0.92f, 0}, bgCol}, {{-0.3f, 0.92f, 0}, bgCol},
    };
    return [device newBufferWithBytes:phBg length:sizeof(phBg) options:MTLResourceStorageModeShared];
}

+ (id<MTLBuffer>)createPlayerHpFgBufferWithDevice:(id<MTLDevice>)device {
    simd_float3 fgCol = {0.0f, 1.0f, 0.0f};
    Vertex phFg[] = {
        {{-0.29f, 0.86f, 0}, fgCol}, {{0.29f, 0.86f, 0}, fgCol}, {{0.29f, 0.91f, 0}, fgCol},
        {{-0.29f, 0.86f, 0}, fgCol}, {{0.29f, 0.91f, 0}, fgCol}, {{-0.29f, 0.91f, 0}, fgCol},
    };
    return [device newBufferWithBytes:phFg length:sizeof(phFg) options:MTLResourceStorageModeShared];
}

+ (id<MTLBuffer>)createGameOverBufferWithDevice:(id<MTLDevice>)device vertexCount:(NSUInteger *)count {
    #define MAX_GO_VERTS 1200
    Vertex goVerts[MAX_GO_VERTS];
    int gov = 0;
    simd_float3 red = {1.0f, 0.2f, 0.2f};
    simd_float3 white = {1, 1, 1};
    simd_float3 yellow = {1.0f, 1.0f, 0.2f};

    #define GORECT(x0,y0,x1,y1,col) do { \
        goVerts[gov++] = (Vertex){{x0,y0,0},col}; \
        goVerts[gov++] = (Vertex){{x1,y0,0},col}; \
        goVerts[gov++] = (Vertex){{x1,y1,0},col}; \
        goVerts[gov++] = (Vertex){{x0,y0,0},col}; \
        goVerts[gov++] = (Vertex){{x1,y1,0},col}; \
        goVerts[gov++] = (Vertex){{x0,y1,0},col}; \
    } while(0)

    float lw = 0.07f, lh = 0.12f, th = 0.015f, sp = 0.09f;
    float startX = -0.40f, y = 0.05f, x;

    x = startX;
    GORECT(x, y, x+th, y+lh, red); GORECT(x, y+lh-th, x+lw, y+lh, red); GORECT(x, y, x+lw, y+th, red);
    GORECT(x+lw-th, y, x+lw, y+lh*0.5f, red); GORECT(x+lw*0.4f, y+lh*0.45f, x+lw, y+lh*0.45f+th, red);
    x += sp;
    GORECT(x, y, x+th, y+lh, red); GORECT(x+lw-th, y, x+lw, y+lh, red);
    GORECT(x, y+lh-th, x+lw, y+lh, red); GORECT(x, y+lh*0.45f, x+lw, y+lh*0.45f+th, red);
    x += sp;
    GORECT(x, y, x+th, y+lh, red); GORECT(x+lw-th, y, x+lw, y+lh, red);
    GORECT(x, y+lh-th, x+lw*0.5f, y+lh, red); GORECT(x+lw*0.5f, y+lh-th, x+lw, y+lh, red);
    GORECT(x+lw*0.5f-th*0.5f, y+lh*0.5f, x+lw*0.5f+th*0.5f, y+lh, red);
    x += sp;
    GORECT(x, y, x+th, y+lh, red); GORECT(x, y+lh-th, x+lw, y+lh, red);
    GORECT(x, y, x+lw, y+th, red); GORECT(x, y+lh*0.45f, x+lw*0.7f, y+lh*0.45f+th, red);
    x += sp * 0.7f;
    x += sp;
    GORECT(x, y, x+th, y+lh, red); GORECT(x+lw-th, y, x+lw, y+lh, red);
    GORECT(x, y+lh-th, x+lw, y+lh, red); GORECT(x, y, x+lw, y+th, red);
    x += sp;
    GORECT(x, y+lh*0.3f, x+th, y+lh, red); GORECT(x+lw-th, y+lh*0.3f, x+lw, y+lh, red);
    GORECT(x, y+lh*0.3f, x+lw*0.5f+th, y+lh*0.3f+th, red);
    GORECT(x+lw*0.5f-th, y+lh*0.3f, x+lw, y+lh*0.3f+th, red);
    GORECT(x+lw*0.5f-th*0.5f, y, x+lw*0.5f+th*0.5f, y+lh*0.35f, red);
    x += sp;
    GORECT(x, y, x+th, y+lh, red); GORECT(x, y+lh-th, x+lw, y+lh, red);
    GORECT(x, y, x+lw, y+th, red); GORECT(x, y+lh*0.45f, x+lw*0.7f, y+lh*0.45f+th, red);
    x += sp;
    GORECT(x, y, x+th, y+lh, red); GORECT(x, y+lh-th, x+lw, y+lh, red);
    GORECT(x+lw-th, y+lh*0.5f, x+lw, y+lh, red); GORECT(x, y+lh*0.45f, x+lw, y+lh*0.45f+th, red);
    GORECT(x+lw*0.4f, y, x+lw, y+lh*0.45f, red);

    lw = 0.045f; lh = 0.07f; th = 0.01f; sp = 0.055f;
    startX = -0.19f; y = -0.12f;
    x = startX;
    GORECT(x, y, x+th, y+lh, white); GORECT(x, y+lh-th, x+lw, y+lh, white);
    GORECT(x+lw-th, y+lh*0.45f, x+lw, y+lh, white); GORECT(x, y+lh*0.45f, x+lw, y+lh*0.45f+th, white);
    x += sp;
    GORECT(x, y, x+th, y+lh, white); GORECT(x, y+lh-th, x+lw, y+lh, white);
    GORECT(x+lw-th, y+lh*0.5f, x+lw, y+lh, white); GORECT(x, y+lh*0.45f, x+lw, y+lh*0.45f+th, white);
    GORECT(x+lw*0.4f, y, x+lw, y+lh*0.45f, white);
    x += sp;
    GORECT(x, y, x+th, y+lh, white); GORECT(x, y+lh-th, x+lw, y+lh, white);
    GORECT(x, y, x+lw, y+th, white); GORECT(x, y+lh*0.45f, x+lw*0.7f, y+lh*0.45f+th, white);
    x += sp;
    GORECT(x, y+lh-th, x+lw, y+lh, white); GORECT(x, y+lh*0.5f, x+th, y+lh, white);
    GORECT(x, y+lh*0.45f, x+lw, y+lh*0.45f+th, white);
    GORECT(x+lw-th, y, x+lw, y+lh*0.5f, white); GORECT(x, y, x+lw, y+th, white);
    x += sp;
    GORECT(x, y+lh-th, x+lw, y+lh, white); GORECT(x, y+lh*0.5f, x+th, y+lh, white);
    GORECT(x, y+lh*0.45f, x+lw, y+lh*0.45f+th, white);
    GORECT(x+lw-th, y, x+lw, y+lh*0.5f, white); GORECT(x, y, x+lw, y+th, white);
    x += sp * 0.5f;
    x += sp;
    GORECT(x, y, x+th, y+lh, yellow); GORECT(x, y+lh-th, x+lw, y+lh, yellow);
    GORECT(x+lw-th, y+lh*0.5f, x+lw, y+lh, yellow); GORECT(x, y+lh*0.45f, x+lw, y+lh*0.45f+th, yellow);
    GORECT(x+lw*0.4f, y, x+lw, y+lh*0.45f, yellow);

    #undef GORECT
    *count = gov;
    return [device newBufferWithBytes:goVerts length:sizeof(Vertex)*gov options:MTLResourceStorageModeShared];
}

+ (id<MTLBuffer>)createCrosshairBufferWithDevice:(id<MTLDevice>)device {
    simd_float3 white = {1.0f, 1.0f, 1.0f};
    float len = 0.025f, th = 0.003f, gap = 0.008f;
    Vertex crossVerts[] = {
        {{-th, gap, 0}, white}, {{th, gap, 0}, white}, {{th, len, 0}, white},
        {{-th, gap, 0}, white}, {{th, len, 0}, white}, {{-th, len, 0}, white},
        {{-th, -gap, 0}, white}, {{th, -gap, 0}, white}, {{th, -len, 0}, white},
        {{-th, -gap, 0}, white}, {{th, -len, 0}, white}, {{-th, -len, 0}, white},
        {{-gap, -th, 0}, white}, {{-gap, th, 0}, white}, {{-len, th, 0}, white},
        {{-gap, -th, 0}, white}, {{-len, th, 0}, white}, {{-len, -th, 0}, white},
        {{gap, -th, 0}, white}, {{gap, th, 0}, white}, {{len, th, 0}, white},
        {{gap, -th, 0}, white}, {{len, th, 0}, white}, {{len, -th, 0}, white},
    };
    return [device newBufferWithBytes:crossVerts length:sizeof(crossVerts) options:MTLResourceStorageModeShared];
}

+ (id<MTLBuffer>)createEPromptBufferWithDevice:(id<MTLDevice>)device vertexCount:(NSUInteger *)count {
    Vertex eVerts[200];
    int ev = 0;
    simd_float3 col = {0.9f, 0.9f, 0.7f};
    float sx = 0.012f, sy = 0.02f;
    float ox = -0.06f, oy = -0.25f;

    #define ERECT(x0,y0,x1,y1) do { \
        float ax=(x0)*sx+ox, ay=(y0)*sy+oy, bx=(x1)*sx+ox, by=(y1)*sy+oy; \
        eVerts[ev++] = (Vertex){{ax,ay,0},col}; \
        eVerts[ev++] = (Vertex){{bx,ay,0},col}; \
        eVerts[ev++] = (Vertex){{bx,by,0},col}; \
        eVerts[ev++] = (Vertex){{ax,ay,0},col}; \
        eVerts[ev++] = (Vertex){{bx,by,0},col}; \
        eVerts[ev++] = (Vertex){{ax,by,0},col}; \
    } while(0)

    ERECT(0, 0, 1, 7); ERECT(1, 0, 3, 1); ERECT(1, 6, 3, 7);
    ERECT(4, 0, 5, 7); ERECT(5, 0, 9, 1); ERECT(5, 3, 8, 4); ERECT(5, 6, 9, 7);
    ERECT(10, 0, 12, 1); ERECT(10, 6, 12, 7); ERECT(11, 0, 12, 7);

    #undef ERECT
    *count = ev;
    return [device newBufferWithBytes:eVerts length:sizeof(Vertex) * ev options:MTLResourceStorageModeShared];
}

+ (id<MTLBuffer>)createPausedTextBufferWithDevice:(id<MTLDevice>)device vertexCount:(NSUInteger *)count {
    #define MAX_TEXT_VERTS 600
    Vertex textVerts[MAX_TEXT_VERTS];
    int tv = 0;

    float sx = 0.03, sy = 0.05;
    float ox = -40.0 * sx * 0.5;
    float oy = -7.0 * sy * 0.5;

    #define RECT(x0,y0,x1,y1) do { \
        float ax=(x0)*sx+ox, ay=(y0)*sy+oy, bx=(x1)*sx+ox, by=(y1)*sy+oy; \
        textVerts[tv++] = (Vertex){{ax,ay,0},{1,1,1}}; \
        textVerts[tv++] = (Vertex){{bx,ay,0},{1,1,1}}; \
        textVerts[tv++] = (Vertex){{bx,by,0},{1,1,1}}; \
        textVerts[tv++] = (Vertex){{ax,ay,0},{1,1,1}}; \
        textVerts[tv++] = (Vertex){{bx,by,0},{1,1,1}}; \
        textVerts[tv++] = (Vertex){{ax,by,0},{1,1,1}}; \
    } while(0)

    RECT(0,0,1,7); RECT(1,6,4,7); RECT(4,4,5,7); RECT(1,3,4,4);
    RECT(7,0,8,7); RECT(8,6,11,7); RECT(11,0,12,7); RECT(8,3,11,4);
    RECT(14,0,15,7); RECT(15,0,18,1); RECT(18,0,19,7);
    RECT(22,0,26,1); RECT(25,1,26,3); RECT(22,3,25,4); RECT(21,4,22,6); RECT(21,6,25,7);
    RECT(28,0,29,7); RECT(29,0,33,1); RECT(29,3,32,4); RECT(29,6,33,7);
    RECT(35,0,36,7); RECT(36,0,39,1); RECT(39,1,40,6); RECT(36,6,39,7);

    #undef RECT
    *count = tv;
    return [device newBufferWithBytes:textVerts length:sizeof(Vertex) * tv options:MTLResourceStorageModeShared];
}

+ (id<MTLBuffer>)createBackgroundBufferWithDevice:(id<MTLDevice>)device {
    Vertex bgVerts[] = {
        {{-1, -1, 0.999}, {0.05, 0.0, 0.15}},
        {{ 1, -1, 0.999}, {0.05, 0.0, 0.15}},
        {{ 1,  1, 0.999}, {0.0,  0.05, 0.2}},
        {{-1, -1, 0.999}, {0.05, 0.0, 0.15}},
        {{ 1,  1, 0.999}, {0.0,  0.05, 0.2}},
        {{-1,  1, 0.999}, {0.0,  0.05, 0.2}},
    };
    return [device newBufferWithBytes:bgVerts length:sizeof(bgVerts) options:MTLResourceStorageModeShared];
}

+ (id<MTLBuffer>)createBoxGridBufferWithDevice:(id<MTLDevice>)device vertexCount:(NSUInteger *)count {
    float h = ARENA_SIZE;  // Match collision boundary
    int gridDiv = 20;
    simd_float3 col = {0.3, 0.3, 0.3};
    int maxVerts = 6 * 2 * (gridDiv + 1) * 2;
    Vertex *boxVerts = malloc(sizeof(Vertex) * maxVerts);
    int bv = 0;
    float step = 2.0f * h / gridDiv;

    for (int face = 0; face < 6; face++) {
        int fixedAxis = face / 2;
        float fixedVal = (face % 2 == 0) ? -h : h;
        int axis1 = (fixedAxis + 1) % 3;
        int axis2 = (fixedAxis + 2) % 3;

        for (int i = 0; i <= gridDiv; i++) {
            float v = -h + i * step;
            float p0[3], p1[3];
            p0[fixedAxis] = fixedVal; p1[fixedAxis] = fixedVal;
            p0[axis1] = -h; p1[axis1] = h;
            p0[axis2] = v; p1[axis2] = v;
            boxVerts[bv++] = (Vertex){{p0[0], p0[1], p0[2]}, col};
            boxVerts[bv++] = (Vertex){{p1[0], p1[1], p1[2]}, col};
        }
        for (int i = 0; i <= gridDiv; i++) {
            float v = -h + i * step;
            float p0[3], p1[3];
            p0[fixedAxis] = fixedVal; p1[fixedAxis] = fixedVal;
            p0[axis1] = v; p1[axis1] = v;
            p0[axis2] = -h; p1[axis2] = h;
            boxVerts[bv++] = (Vertex){{p0[0], p0[1], p0[2]}, col};
            boxVerts[bv++] = (Vertex){{p1[0], p1[1], p1[2]}, col};
        }
    }

    *count = bv;
    id<MTLBuffer> buffer = [device newBufferWithBytes:boxVerts length:sizeof(Vertex) * bv options:MTLResourceStorageModeShared];
    free(boxVerts);
    return buffer;
}

// ============================================
// PICKUP GEOMETRY
// ============================================

+ (id<MTLBuffer>)createHealthPackBufferWithDevice:(id<MTLDevice>)device vertexCount:(NSUInteger *)count {
    #define MAX_HEALTH_VERTS 300
    Vertex verts[MAX_HEALTH_VERTS];
    int v = 0;

    float size = 0.25f;
    float hs = size / 2.0f;

    simd_float3 white = {0.95f, 0.95f, 0.95f};
    simd_float3 whiteDark = {0.8f, 0.8f, 0.8f};
    simd_float3 red = {0.9f, 0.1f, 0.1f};

    BOX3D(verts, v, -hs, 0, -hs, hs, size*0.6f, hs, white, whiteDark, white, whiteDark, white, whiteDark);

    float crossW = size * 0.6f;
    float crossH = size * 0.2f;
    float topY = size * 0.6f + 0.001f;

    verts[v++] = (Vertex){{-crossW/2, topY, -crossH/2}, red};
    verts[v++] = (Vertex){{crossW/2, topY, -crossH/2}, red};
    verts[v++] = (Vertex){{crossW/2, topY, crossH/2}, red};
    verts[v++] = (Vertex){{-crossW/2, topY, -crossH/2}, red};
    verts[v++] = (Vertex){{crossW/2, topY, crossH/2}, red};
    verts[v++] = (Vertex){{-crossW/2, topY, crossH/2}, red};

    verts[v++] = (Vertex){{-crossH/2, topY, -crossW/2}, red};
    verts[v++] = (Vertex){{crossH/2, topY, -crossW/2}, red};
    verts[v++] = (Vertex){{crossH/2, topY, crossW/2}, red};
    verts[v++] = (Vertex){{-crossH/2, topY, -crossW/2}, red};
    verts[v++] = (Vertex){{crossH/2, topY, crossW/2}, red};
    verts[v++] = (Vertex){{-crossH/2, topY, crossW/2}, red};

    *count = v;
    return [device newBufferWithBytes:verts length:sizeof(Vertex) * v options:MTLResourceStorageModeShared];
}

+ (id<MTLBuffer>)createAmmoBoxBufferWithDevice:(id<MTLDevice>)device vertexCount:(NSUInteger *)count {
    #define MAX_AMMO_VERTS 200
    Vertex verts[MAX_AMMO_VERTS];
    int v = 0;

    float w = 0.3f, h = 0.18f, d = 0.2f;

    simd_float3 greenFront = {0.25f, 0.35f, 0.15f};
    simd_float3 greenBack = {0.18f, 0.28f, 0.1f};
    simd_float3 greenSide = {0.22f, 0.32f, 0.12f};
    simd_float3 greenTop = {0.28f, 0.38f, 0.18f};
    simd_float3 greenBot = {0.15f, 0.25f, 0.08f};
    simd_float3 yellow = {0.9f, 0.8f, 0.2f};

    BOX3D(verts, v, -w/2, 0, -d/2, w/2, h, d/2, greenFront, greenBack, greenSide, greenSide, greenTop, greenBot);

    float stripeW = w * 0.6f;
    float stripeD = 0.03f;
    float topY = h + 0.001f;
    verts[v++] = (Vertex){{-stripeW/2, topY, -stripeD/2}, yellow};
    verts[v++] = (Vertex){{stripeW/2, topY, -stripeD/2}, yellow};
    verts[v++] = (Vertex){{stripeW/2, topY, stripeD/2}, yellow};
    verts[v++] = (Vertex){{-stripeW/2, topY, -stripeD/2}, yellow};
    verts[v++] = (Vertex){{stripeW/2, topY, stripeD/2}, yellow};
    verts[v++] = (Vertex){{-stripeW/2, topY, stripeD/2}, yellow};

    *count = v;
    return [device newBufferWithBytes:verts length:sizeof(Vertex) * v options:MTLResourceStorageModeShared];
}

+ (id<MTLBuffer>)createWeaponPickupBufferWithDevice:(id<MTLDevice>)device vertexCount:(NSUInteger *)count {
    #define MAX_WEAPON_PICKUP_VERTS 200
    Vertex verts[MAX_WEAPON_PICKUP_VERTS];
    int v = 0;

    simd_float3 gunDark = {0.15f, 0.15f, 0.17f};
    simd_float3 gunMid = {0.25f, 0.25f, 0.28f};
    simd_float3 gunLight = {0.35f, 0.35f, 0.38f};

    BOX3D(verts, v, -0.03f, 0.0f, -0.2f, 0.03f, 0.05f, 0.2f, gunMid, gunDark, gunLight, gunMid, gunLight, gunDark);
    BOX3D(verts, v, -0.04f, -0.1f, -0.18f, 0.04f, 0.0f, -0.08f, gunDark, gunMid, gunLight, gunMid, gunLight, gunDark);
    BOX3D(verts, v, -0.025f, -0.08f, -0.05f, 0.025f, 0.0f, 0.05f, gunDark, gunDark, gunMid, gunMid, gunLight, gunDark);

    *count = v;
    return [device newBufferWithBytes:verts length:sizeof(Vertex) * v options:MTLResourceStorageModeShared];
}

+ (id<MTLBuffer>)createArmorBufferWithDevice:(id<MTLDevice>)device vertexCount:(NSUInteger *)count {
    #define MAX_ARMOR_VERTS 400
    Vertex verts[MAX_ARMOR_VERTS];
    int v = 0;

    float w = 0.25f, h = 0.3f, d = 0.08f;

    simd_float3 blueFront = {0.2f, 0.4f, 0.9f};
    simd_float3 blueBack = {0.1f, 0.25f, 0.6f};
    simd_float3 blueSide = {0.15f, 0.35f, 0.8f};
    simd_float3 blueTop = {0.3f, 0.5f, 1.0f};
    simd_float3 blueBot = {0.1f, 0.2f, 0.5f};

    float topW = w, botW = w * 0.6f;

    verts[v++] = (Vertex){{-botW/2, 0, d/2}, blueFront};
    verts[v++] = (Vertex){{botW/2, 0, d/2}, blueFront};
    verts[v++] = (Vertex){{topW/2, h, d/2}, blueFront};
    verts[v++] = (Vertex){{-botW/2, 0, d/2}, blueFront};
    verts[v++] = (Vertex){{topW/2, h, d/2}, blueFront};
    verts[v++] = (Vertex){{-topW/2, h, d/2}, blueFront};

    verts[v++] = (Vertex){{botW/2, 0, -d/2}, blueBack};
    verts[v++] = (Vertex){{-botW/2, 0, -d/2}, blueBack};
    verts[v++] = (Vertex){{-topW/2, h, -d/2}, blueBack};
    verts[v++] = (Vertex){{botW/2, 0, -d/2}, blueBack};
    verts[v++] = (Vertex){{-topW/2, h, -d/2}, blueBack};
    verts[v++] = (Vertex){{topW/2, h, -d/2}, blueBack};

    verts[v++] = (Vertex){{botW/2, 0, d/2}, blueSide};
    verts[v++] = (Vertex){{botW/2, 0, -d/2}, blueSide};
    verts[v++] = (Vertex){{topW/2, h, -d/2}, blueSide};
    verts[v++] = (Vertex){{botW/2, 0, d/2}, blueSide};
    verts[v++] = (Vertex){{topW/2, h, -d/2}, blueSide};
    verts[v++] = (Vertex){{topW/2, h, d/2}, blueSide};

    verts[v++] = (Vertex){{-botW/2, 0, -d/2}, blueSide};
    verts[v++] = (Vertex){{-botW/2, 0, d/2}, blueSide};
    verts[v++] = (Vertex){{-topW/2, h, d/2}, blueSide};
    verts[v++] = (Vertex){{-botW/2, 0, -d/2}, blueSide};
    verts[v++] = (Vertex){{-topW/2, h, d/2}, blueSide};
    verts[v++] = (Vertex){{-topW/2, h, -d/2}, blueSide};

    verts[v++] = (Vertex){{-topW/2, h, d/2}, blueTop};
    verts[v++] = (Vertex){{topW/2, h, d/2}, blueTop};
    verts[v++] = (Vertex){{topW/2, h, -d/2}, blueTop};
    verts[v++] = (Vertex){{-topW/2, h, d/2}, blueTop};
    verts[v++] = (Vertex){{topW/2, h, -d/2}, blueTop};
    verts[v++] = (Vertex){{-topW/2, h, -d/2}, blueTop};

    verts[v++] = (Vertex){{-botW/2, 0, -d/2}, blueBot};
    verts[v++] = (Vertex){{botW/2, 0, -d/2}, blueBot};
    verts[v++] = (Vertex){{botW/2, 0, d/2}, blueBot};
    verts[v++] = (Vertex){{-botW/2, 0, -d/2}, blueBot};
    verts[v++] = (Vertex){{botW/2, 0, d/2}, blueBot};
    verts[v++] = (Vertex){{-botW/2, 0, d/2}, blueBot};

    *count = v;
    return [device newBufferWithBytes:verts length:sizeof(Vertex) * v options:MTLResourceStorageModeShared];
}

@end
