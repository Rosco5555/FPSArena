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

        // Railings
        float postW = 0.08f;
        for (int side = 0; side < 4; side++) {
            float px1, pz1;
            switch(side) {
                case 0: px1 = tx-ts; pz1 = tz+ts; break;
                case 1: px1 = tx+ts; pz1 = tz-ts; break;
                case 2: px1 = tx+ts; pz1 = tz+ts; break;
                default: px1 = tx-ts; pz1 = tz-ts; break;
            }
            BOX3D(verts, v, px1-postW/2, platY, pz1-postW/2, px1+postW/2, platY+railH, pz1+postW/2,
                  railCol, railCol, railCol, railCol, railCol, railCol);
        }

        // Horizontal rails
        float railT = 0.06f;
        BOX3D(verts, v, tx-ts, platY+railH-railT, tz+ts-railT, tx+ts, platY+railH, tz+ts,
              railCol, railCol, railCol, railCol, railCol, railCol);
        BOX3D(verts, v, tx-ts, platY+railH-railT, tz-ts, tx+ts, platY+railH, tz-ts+railT,
              railCol, railCol, railCol, railCol, railCol, railCol);
        BOX3D(verts, v, tx+ts-railT, platY+railH-railT, tz-ts, tx+ts, platY+railH, tz+ts,
              railCol, railCol, railCol, railCol, railCol, railCol);
        BOX3D(verts, v, tx-ts, platY+railH-railT, tz-ts, tx-ts+railT, platY+railH, tz+ts,
              railCol, railCol, railCol, railCol, railCol, railCol);

        // Ramp
        float rampW = RAMP_WIDTH / 2.0f;
        float rampL = RAMP_LENGTH;
        float rampDx = (tx > 0) ? -1.0f : 1.0f;
        float rampDz = (tz > 0) ? -1.0f : 1.0f;

        float rampStartX = tx + rampDx * ts;
        float rampStartZ = tz + rampDz * ts;
        float rampEndX = rampStartX + rampDx * rampL;
        float rampEndZ = rampStartZ + rampDz * rampL;

        verts[v++] = (Vertex){{rampStartX - rampW * fabsf(rampDz), platY, rampStartZ - rampW * fabsf(rampDx)}, rampCol};
        verts[v++] = (Vertex){{rampStartX + rampW * fabsf(rampDz), platY, rampStartZ + rampW * fabsf(rampDx)}, rampCol};
        verts[v++] = (Vertex){{rampEndX + rampW * fabsf(rampDz), fy, rampEndZ + rampW * fabsf(rampDx)}, rampCol};
        verts[v++] = (Vertex){{rampStartX - rampW * fabsf(rampDz), platY, rampStartZ - rampW * fabsf(rampDx)}, rampCol};
        verts[v++] = (Vertex){{rampEndX + rampW * fabsf(rampDz), fy, rampEndZ + rampW * fabsf(rampDx)}, rampCol};
        verts[v++] = (Vertex){{rampEndX - rampW * fabsf(rampDz), fy, rampEndZ - rampW * fabsf(rampDx)}, rampCol};

        verts[v++] = (Vertex){{rampStartX + rampW * fabsf(rampDz), platY - platT, rampStartZ + rampW * fabsf(rampDx)}, rampDark};
        verts[v++] = (Vertex){{rampStartX - rampW * fabsf(rampDz), platY - platT, rampStartZ - rampW * fabsf(rampDx)}, rampDark};
        verts[v++] = (Vertex){{rampEndX - rampW * fabsf(rampDz), fy, rampEndZ - rampW * fabsf(rampDx)}, rampDark};
        verts[v++] = (Vertex){{rampStartX + rampW * fabsf(rampDz), platY - platT, rampStartZ + rampW * fabsf(rampDx)}, rampDark};
        verts[v++] = (Vertex){{rampEndX - rampW * fabsf(rampDz), fy, rampEndZ - rampW * fabsf(rampDx)}, rampDark};
        verts[v++] = (Vertex){{rampEndX + rampW * fabsf(rampDz), fy, rampEndZ + rampW * fabsf(rampDx)}, rampDark};
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

    QUAD(verts, v, bx-hw+wt, fy, bz-hd+wt, bx-hw+wt, fy, bz+hd-wt,
         bx+hw-wt, fy, bz+hd-wt, bx+hw-wt, fy, bz-hd+wt, bunkerDark);

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
        {8.0f, 4.0f, 0, 0}, {8.5f, 6.5f, 1, 1}, {-8.0f, 4.0f, 0, 1}, {-8.5f, 6.5f, 1, 0},
        {6.0f, -8.0f, 1, 0}, {-6.0f, -8.0f, 1, 1}, {0.0f, -12.0f, 0, 0}, {12.0f, 0.0f, 1, 1},
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

        BOX3D(verts, v, wx-wl, fy, wz-wd, wx+wl, fy+sh*0.6f, wz+wd,
              bagFront, bagBack, bagSide, bagSide, bagTop, bagBot);
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

    float s = ARENA_SIZE + 5.0f;
    float fy = FLOOR_Y;

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
    #define MAX_GUN_VERTS 1500
    Vertex gunVerts[MAX_GUN_VERTS];
    int gv = 0;

    simd_float3 gunDark = {0.12, 0.12, 0.14};
    simd_float3 gunMid = {0.22, 0.22, 0.25};
    simd_float3 gunLight = {0.32, 0.32, 0.35};
    simd_float3 gunTop = {0.28, 0.28, 0.30};
    simd_float3 gunBot = {0.10, 0.10, 0.12};
    simd_float3 skinLight = {0.87, 0.72, 0.60};
    simd_float3 skinMid = {0.76, 0.60, 0.48};
    simd_float3 skinDark = {0.65, 0.50, 0.40};
    simd_float3 skinShadow = {0.55, 0.42, 0.35};
    simd_float3 sleeveLight = {0.18, 0.18, 0.20};
    simd_float3 sleeveMid = {0.12, 0.12, 0.14};
    simd_float3 sleeveDark = {0.08, 0.08, 0.10};

    BOX3D(gunVerts, gv, -0.03f, 0.0f, -0.15f, 0.03f, 0.04f, 0.12f, gunMid, gunDark, gunMid, gunMid, gunTop, gunBot);
    BOX3D(gunVerts, gv, -0.015f, 0.01f, 0.12f, 0.015f, 0.03f, 0.25f, gunDark, gunDark, gunDark, gunDark, gunDark, gunDark);
    BOX3D(gunVerts, gv, -0.025f, -0.12f, -0.12f, 0.025f, 0.0f, -0.04f, gunDark, gunMid, gunDark, gunDark, gunBot, gunBot);
    BOX3D(gunVerts, gv, -0.02f, -0.04f, -0.04f, 0.02f, -0.02f, 0.02f, gunLight, gunLight, gunLight, gunLight, gunLight, gunLight);
    BOX3D(gunVerts, gv, -0.02f, 0.04f, -0.12f, 0.02f, 0.055f, -0.08f, gunDark, gunDark, gunDark, gunDark, gunLight, gunDark);
    BOX3D(gunVerts, gv, -0.01f, 0.04f, 0.08f, 0.01f, 0.05f, 0.10f, gunDark, gunDark, gunDark, gunDark, gunLight, gunDark);
    BOX3D(gunVerts, gv, -0.04f, -0.12f, -0.18f, 0.04f, 0.0f, -0.04f, skinMid, skinDark, skinLight, skinMid, skinLight, skinShadow);
    BOX3D(gunVerts, gv, -0.05f, -0.16f, -0.35f, 0.05f, 0.0f, -0.18f, sleeveMid, sleeveDark, sleeveLight, sleeveMid, sleeveLight, sleeveDark);
    BOX3D(gunVerts, gv, -0.06f, -0.22f, -0.55f, 0.06f, -0.02f, -0.35f, sleeveMid, sleeveDark, sleeveLight, sleeveMid, sleeveLight, sleeveDark);
    BOX3D(gunVerts, gv, -0.08f, -0.35f, -0.85f, 0.08f, -0.05f, -0.55f, sleeveMid, sleeveDark, sleeveLight, sleeveMid, sleeveLight, sleeveDark);

    *count = gv;
    return [device newBufferWithBytes:gunVerts length:sizeof(Vertex) * gv options:MTLResourceStorageModeShared];
}

+ (id<MTLBuffer>)createPistolBufferWithDevice:(id<MTLDevice>)device vertexCount:(NSUInteger *)count {
    // Same as the default gun - compact pistol
    return [self createGunBufferWithDevice:device vertexCount:count];
}

+ (id<MTLBuffer>)createShotgunBufferWithDevice:(id<MTLDevice>)device vertexCount:(NSUInteger *)count {
    #define MAX_SHOTGUN_VERTS 1500
    Vertex gunVerts[MAX_SHOTGUN_VERTS];
    int gv = 0;

    simd_float3 gunDark = {0.15, 0.10, 0.08};
    simd_float3 gunMid = {0.25, 0.18, 0.12};
    simd_float3 gunLight = {0.35, 0.25, 0.18};
    simd_float3 woodDark = {0.35, 0.22, 0.12};
    simd_float3 woodMid = {0.50, 0.32, 0.18};
    simd_float3 woodLight = {0.60, 0.40, 0.22};
    simd_float3 metalDark = {0.08, 0.08, 0.10};
    simd_float3 metalMid = {0.18, 0.18, 0.20};
    simd_float3 skinLight = {0.87, 0.72, 0.60};
    simd_float3 skinMid = {0.76, 0.60, 0.48};
    simd_float3 skinDark = {0.65, 0.50, 0.40};
    simd_float3 skinShadow = {0.55, 0.42, 0.35};
    simd_float3 sleeveLight = {0.18, 0.18, 0.20};
    simd_float3 sleeveMid = {0.12, 0.12, 0.14};
    simd_float3 sleeveDark = {0.08, 0.08, 0.10};

    // Long barrel (shotgun is longer than pistol)
    BOX3D(gunVerts, gv, -0.025f, 0.0f, -0.12f, 0.025f, 0.035f, 0.30f, metalMid, metalDark, metalMid, metalMid, metalMid, metalDark);
    // Second barrel (double barrel shotgun)
    BOX3D(gunVerts, gv, -0.025f, 0.035f, -0.12f, 0.025f, 0.07f, 0.30f, metalMid, metalDark, metalMid, metalMid, metalMid, metalDark);
    // Receiver
    BOX3D(gunVerts, gv, -0.035f, -0.02f, -0.15f, 0.035f, 0.08f, -0.02f, gunMid, gunDark, gunLight, gunMid, gunLight, gunDark);
    // Wooden stock
    BOX3D(gunVerts, gv, -0.03f, -0.12f, -0.35f, 0.03f, 0.02f, -0.12f, woodMid, woodDark, woodLight, woodMid, woodLight, woodDark);
    BOX3D(gunVerts, gv, -0.025f, -0.08f, -0.55f, 0.025f, -0.02f, -0.35f, woodMid, woodDark, woodLight, woodMid, woodLight, woodDark);
    // Trigger guard
    BOX3D(gunVerts, gv, -0.02f, -0.06f, -0.10f, 0.02f, -0.02f, -0.02f, metalDark, metalDark, metalDark, metalDark, metalDark, metalDark);
    // Hands
    BOX3D(gunVerts, gv, -0.04f, -0.10f, -0.05f, 0.04f, 0.02f, 0.08f, skinMid, skinDark, skinLight, skinMid, skinLight, skinShadow);
    BOX3D(gunVerts, gv, -0.05f, -0.16f, -0.30f, 0.05f, 0.0f, -0.13f, sleeveMid, sleeveDark, sleeveLight, sleeveMid, sleeveLight, sleeveDark);
    BOX3D(gunVerts, gv, -0.06f, -0.22f, -0.50f, 0.06f, -0.02f, -0.30f, sleeveMid, sleeveDark, sleeveLight, sleeveMid, sleeveLight, sleeveDark);
    BOX3D(gunVerts, gv, -0.08f, -0.35f, -0.80f, 0.08f, -0.05f, -0.50f, sleeveMid, sleeveDark, sleeveLight, sleeveMid, sleeveLight, sleeveDark);

    *count = gv;
    return [device newBufferWithBytes:gunVerts length:sizeof(Vertex) * gv options:MTLResourceStorageModeShared];
}

+ (id<MTLBuffer>)createRifleBufferWithDevice:(id<MTLDevice>)device vertexCount:(NSUInteger *)count {
    #define MAX_RIFLE_VERTS 1500
    Vertex gunVerts[MAX_RIFLE_VERTS];
    int gv = 0;

    simd_float3 gunDark = {0.10, 0.10, 0.12};
    simd_float3 gunMid = {0.20, 0.20, 0.22};
    simd_float3 gunLight = {0.30, 0.30, 0.32};
    simd_float3 gunAccent = {0.15, 0.15, 0.17};
    simd_float3 skinLight = {0.87, 0.72, 0.60};
    simd_float3 skinMid = {0.76, 0.60, 0.48};
    simd_float3 skinDark = {0.65, 0.50, 0.40};
    simd_float3 skinShadow = {0.55, 0.42, 0.35};
    simd_float3 sleeveLight = {0.18, 0.18, 0.20};
    simd_float3 sleeveMid = {0.12, 0.12, 0.14};
    simd_float3 sleeveDark = {0.08, 0.08, 0.10};

    // Long barrel
    BOX3D(gunVerts, gv, -0.018f, 0.01f, -0.10f, 0.018f, 0.04f, 0.35f, gunDark, gunDark, gunDark, gunDark, gunDark, gunDark);
    // Main body/receiver
    BOX3D(gunVerts, gv, -0.035f, 0.0f, -0.18f, 0.035f, 0.05f, 0.05f, gunMid, gunDark, gunLight, gunMid, gunLight, gunDark);
    // Magazine
    BOX3D(gunVerts, gv, -0.02f, -0.12f, -0.08f, 0.02f, 0.0f, 0.02f, gunAccent, gunDark, gunAccent, gunAccent, gunDark, gunDark);
    // Stock
    BOX3D(gunVerts, gv, -0.025f, -0.04f, -0.35f, 0.025f, 0.04f, -0.15f, gunMid, gunDark, gunLight, gunMid, gunLight, gunDark);
    // Grip
    BOX3D(gunVerts, gv, -0.02f, -0.10f, -0.18f, 0.02f, 0.0f, -0.10f, gunDark, gunDark, gunMid, gunMid, gunDark, gunDark);
    // Front grip
    BOX3D(gunVerts, gv, -0.02f, -0.06f, 0.05f, 0.02f, 0.0f, 0.15f, gunDark, gunDark, gunMid, gunMid, gunDark, gunDark);
    // Sight
    BOX3D(gunVerts, gv, -0.01f, 0.05f, -0.05f, 0.01f, 0.07f, 0.02f, gunDark, gunDark, gunDark, gunDark, gunLight, gunDark);
    // Hands
    BOX3D(gunVerts, gv, -0.04f, -0.10f, 0.0f, 0.04f, 0.02f, 0.12f, skinMid, skinDark, skinLight, skinMid, skinLight, skinShadow);
    BOX3D(gunVerts, gv, -0.04f, -0.12f, -0.20f, 0.04f, 0.0f, -0.08f, skinMid, skinDark, skinLight, skinMid, skinLight, skinShadow);
    BOX3D(gunVerts, gv, -0.05f, -0.16f, -0.38f, 0.05f, 0.0f, -0.18f, sleeveMid, sleeveDark, sleeveLight, sleeveMid, sleeveLight, sleeveDark);
    BOX3D(gunVerts, gv, -0.06f, -0.22f, -0.55f, 0.06f, -0.02f, -0.38f, sleeveMid, sleeveDark, sleeveLight, sleeveMid, sleeveLight, sleeveDark);
    BOX3D(gunVerts, gv, -0.08f, -0.35f, -0.85f, 0.08f, -0.05f, -0.55f, sleeveMid, sleeveDark, sleeveLight, sleeveMid, sleeveLight, sleeveDark);

    *count = gv;
    return [device newBufferWithBytes:gunVerts length:sizeof(Vertex) * gv options:MTLResourceStorageModeShared];
}

+ (id<MTLBuffer>)createRocketLauncherBufferWithDevice:(id<MTLDevice>)device vertexCount:(NSUInteger *)count {
    #define MAX_ROCKET_VERTS 1500
    Vertex gunVerts[MAX_ROCKET_VERTS];
    int gv = 0;

    simd_float3 tubeDark = {0.25, 0.30, 0.22};
    simd_float3 tubeMid = {0.35, 0.42, 0.30};
    simd_float3 tubeLight = {0.45, 0.52, 0.38};
    simd_float3 metalDark = {0.12, 0.12, 0.14};
    simd_float3 metalMid = {0.22, 0.22, 0.24};
    simd_float3 skinLight = {0.87, 0.72, 0.60};
    simd_float3 skinMid = {0.76, 0.60, 0.48};
    simd_float3 skinDark = {0.65, 0.50, 0.40};
    simd_float3 skinShadow = {0.55, 0.42, 0.35};
    simd_float3 sleeveLight = {0.18, 0.18, 0.20};
    simd_float3 sleeveMid = {0.12, 0.12, 0.14};
    simd_float3 sleeveDark = {0.08, 0.08, 0.10};

    // Main tube (large cylinder approximated with box)
    BOX3D(gunVerts, gv, -0.06f, -0.02f, -0.15f, 0.06f, 0.10f, 0.40f, tubeMid, tubeDark, tubeLight, tubeMid, tubeLight, tubeDark);
    // Front opening rim
    BOX3D(gunVerts, gv, -0.07f, -0.03f, 0.38f, 0.07f, 0.11f, 0.42f, metalDark, metalDark, metalMid, metalDark, metalMid, metalDark);
    // Back opening
    BOX3D(gunVerts, gv, -0.065f, -0.025f, -0.18f, 0.065f, 0.105f, -0.15f, metalDark, metalDark, metalMid, metalDark, metalMid, metalDark);
    // Grip section
    BOX3D(gunVerts, gv, -0.035f, -0.12f, -0.05f, 0.035f, -0.02f, 0.10f, metalMid, metalDark, metalMid, metalMid, metalMid, metalDark);
    // Trigger area
    BOX3D(gunVerts, gv, -0.02f, -0.08f, 0.0f, 0.02f, -0.02f, 0.06f, metalDark, metalDark, metalDark, metalDark, metalDark, metalDark);
    // Shoulder rest
    BOX3D(gunVerts, gv, -0.04f, -0.06f, -0.30f, 0.04f, 0.06f, -0.15f, tubeMid, tubeDark, tubeLight, tubeMid, tubeLight, tubeDark);
    // Sight
    BOX3D(gunVerts, gv, -0.015f, 0.10f, 0.05f, 0.015f, 0.15f, 0.20f, metalDark, metalDark, metalMid, metalDark, metalMid, metalDark);
    // Hands
    BOX3D(gunVerts, gv, -0.04f, -0.14f, 0.05f, 0.04f, -0.02f, 0.18f, skinMid, skinDark, skinLight, skinMid, skinLight, skinShadow);
    BOX3D(gunVerts, gv, -0.04f, -0.14f, -0.12f, 0.04f, -0.02f, 0.0f, skinMid, skinDark, skinLight, skinMid, skinLight, skinShadow);
    BOX3D(gunVerts, gv, -0.05f, -0.18f, -0.35f, 0.05f, -0.02f, -0.10f, sleeveMid, sleeveDark, sleeveLight, sleeveMid, sleeveLight, sleeveDark);
    BOX3D(gunVerts, gv, -0.06f, -0.24f, -0.55f, 0.06f, -0.04f, -0.35f, sleeveMid, sleeveDark, sleeveLight, sleeveMid, sleeveLight, sleeveDark);
    BOX3D(gunVerts, gv, -0.08f, -0.38f, -0.85f, 0.08f, -0.08f, -0.55f, sleeveMid, sleeveDark, sleeveLight, sleeveMid, sleeveLight, sleeveDark);

    *count = gv;
    return [device newBufferWithBytes:gunVerts length:sizeof(Vertex) * gv options:MTLResourceStorageModeShared];
}

+ (id<MTLBuffer>)createEnemyBufferWithDevice:(id<MTLDevice>)device vertexCount:(NSUInteger *)count {
    #define MAX_ENEMY_VERTS 600
    Vertex enemyVerts[MAX_ENEMY_VERTS];
    int ev = 0;

    simd_float3 bodyDark = {0.5f, 0.1f, 0.1f};
    simd_float3 bodyMid = {0.7f, 0.15f, 0.15f};
    simd_float3 bodyLight = {0.8f, 0.2f, 0.2f};
    simd_float3 skinTone = {0.45f, 0.3f, 0.2f};   // Brown skin
    simd_float3 skinDark = {0.35f, 0.22f, 0.15f}; // Darker brown
    simd_float3 gunC1 = {0.2f, 0.2f, 0.2f};
    simd_float3 gunC2 = {0.1f, 0.1f, 0.1f};
    simd_float3 gunC3 = {0.25f, 0.25f, 0.25f};

    BOX3D(enemyVerts, ev, -0.15f, 0.5f, -0.1f, 0.15f, 0.8f, 0.1f, skinTone, skinDark, skinTone, skinTone, skinTone, skinDark);
    BOX3D(enemyVerts, ev, -0.2f, 0.0f, -0.12f, 0.2f, 0.5f, 0.12f, bodyMid, bodyDark, bodyLight, bodyMid, bodyLight, bodyDark);
    BOX3D(enemyVerts, ev, -0.35f, 0.1f, -0.08f, -0.2f, 0.45f, 0.08f, bodyMid, bodyDark, bodyLight, bodyMid, bodyLight, bodyDark);
    BOX3D(enemyVerts, ev, 0.2f, 0.1f, -0.08f, 0.35f, 0.45f, 0.08f, bodyMid, bodyDark, bodyLight, bodyMid, bodyLight, bodyDark);
    BOX3D(enemyVerts, ev, -0.18f, -0.6f, -0.1f, -0.02f, 0.0f, 0.1f, bodyDark, bodyDark, bodyMid, bodyMid, bodyMid, bodyDark);
    BOX3D(enemyVerts, ev, 0.02f, -0.6f, -0.1f, 0.18f, 0.0f, 0.1f, bodyDark, bodyDark, bodyMid, bodyMid, bodyMid, bodyDark);
    BOX3D(enemyVerts, ev, 0.3f, 0.25f, -0.04f, 0.6f, 0.32f, 0.04f, gunC1, gunC2, gunC3, gunC2, gunC1, gunC2);

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
    float h = ARENA_SIZE + 5.0f;
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
