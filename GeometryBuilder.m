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

+ (id<MTLBuffer>)createHouseBufferWithDevice:(id<MTLDevice>)device vertexCount:(NSUInteger *)count {
    #define MAX_HOUSE_VERTS 2000
    Vertex houseVerts[MAX_HOUSE_VERTS];
    int hv = 0;

    simd_float3 wallExt = {0.45f, 0.30f, 0.18f};
    simd_float3 wallInt = {0.55f, 0.45f, 0.35f};
    simd_float3 wallSide = {0.40f, 0.28f, 0.15f};
    simd_float3 wallTop = {0.35f, 0.25f, 0.12f};

    float hx = HOUSE_X;
    float hz = HOUSE_Z;
    float hw = HOUSE_WIDTH / 2.0f;
    float hd = HOUSE_DEPTH / 2.0f;
    float fy = FLOOR_Y;
    float wh = HOUSE_WALL_HEIGHT;
    float wt = HOUSE_WALL_THICK;
    float dw = DOOR_WIDTH / 2.0f;
    float doorH = DOOR_HEIGHT;

    // Back wall
    float bz = hz - hd;
    QUAD(houseVerts, hv, hx-hw, fy, bz, hx+hw, fy, bz, hx+hw, fy+wh, bz, hx-hw, fy+wh, bz, wallInt);
    QUAD(houseVerts, hv, hx+hw, fy, bz-wt, hx-hw, fy, bz-wt, hx-hw, fy+wh, bz-wt, hx+hw, fy+wh, bz-wt, wallExt);

    // Left wall
    float lx = hx - hw;
    QUAD(houseVerts, hv, lx, fy, hz+hd, lx, fy, hz-hd, lx, fy+wh, hz-hd, lx, fy+wh, hz+hd, wallInt);
    QUAD(houseVerts, hv, lx-wt, fy, hz-hd, lx-wt, fy, hz+hd, lx-wt, fy+wh, hz+hd, lx-wt, fy+wh, hz-hd, wallExt);

    // Right wall
    float rx = hx + hw;
    QUAD(houseVerts, hv, rx, fy, hz-hd, rx, fy, hz+hd, rx, fy+wh, hz+hd, rx, fy+wh, hz-hd, wallInt);
    QUAD(houseVerts, hv, rx+wt, fy, hz+hd, rx+wt, fy, hz-hd, rx+wt, fy+wh, hz-hd, rx+wt, fy+wh, hz+hd, wallExt);

    // Front wall with door opening
    float fz = hz + hd;
    QUAD(houseVerts, hv, hx-hw, fy, fz+wt, hx-dw, fy, fz+wt, hx-dw, fy+wh, fz+wt, hx-hw, fy+wh, fz+wt, wallExt);
    QUAD(houseVerts, hv, hx-dw, fy, fz, hx-hw, fy, fz, hx-hw, fy+wh, fz, hx-dw, fy+wh, fz, wallInt);
    QUAD(houseVerts, hv, hx+dw, fy, fz+wt, hx+hw, fy, fz+wt, hx+hw, fy+wh, fz+wt, hx+dw, fy+wh, fz+wt, wallExt);
    QUAD(houseVerts, hv, hx+hw, fy, fz, hx+dw, fy, fz, hx+dw, fy+wh, fz, hx+hw, fy+wh, fz, wallInt);
    QUAD(houseVerts, hv, hx-dw, fy+doorH, fz+wt, hx+dw, fy+doorH, fz+wt, hx+dw, fy+wh, fz+wt, hx-dw, fy+wh, fz+wt, wallExt);
    QUAD(houseVerts, hv, hx+dw, fy+doorH, fz, hx-dw, fy+doorH, fz, hx-dw, fy+wh, fz, hx+dw, fy+wh, fz, wallInt);

    // Door frame sides
    QUAD(houseVerts, hv, hx-dw, fy, fz, hx-dw, fy, fz+wt, hx-dw, fy+doorH, fz+wt, hx-dw, fy+doorH, fz, wallSide);
    QUAD(houseVerts, hv, hx+dw, fy, fz+wt, hx+dw, fy, fz, hx+dw, fy+doorH, fz, hx+dw, fy+doorH, fz+wt, wallSide);
    QUAD(houseVerts, hv, hx-dw, fy+doorH, fz, hx+dw, fy+doorH, fz, hx+dw, fy+doorH, fz+wt, hx-dw, fy+doorH, fz+wt, wallTop);

    // Wall tops
    QUAD(houseVerts, hv, hx-hw, fy+wh, bz-wt, hx+hw, fy+wh, bz-wt, hx+hw, fy+wh, bz, hx-hw, fy+wh, bz, wallTop);
    QUAD(houseVerts, hv, lx-wt, fy+wh, hz-hd, lx-wt, fy+wh, hz+hd, lx, fy+wh, hz+hd, lx, fy+wh, hz-hd, wallTop);
    QUAD(houseVerts, hv, rx, fy+wh, hz-hd, rx, fy+wh, hz+hd, rx+wt, fy+wh, hz+hd, rx+wt, fy+wh, hz-hd, wallTop);
    QUAD(houseVerts, hv, hx-hw, fy+wh, fz, hx+hw, fy+wh, fz, hx+hw, fy+wh, fz+wt, hx-hw, fy+wh, fz+wt, wallTop);

    // Roof
    simd_float3 roofInt = {0.35f, 0.28f, 0.22f};
    simd_float3 roofExt = {0.30f, 0.20f, 0.12f};
    float roofY = fy + wh;
    float roofThick = 0.15f;
    QUAD(houseVerts, hv, hx-hw, roofY, hz-hd, hx+hw, roofY, hz-hd, hx+hw, roofY, hz+hd, hx-hw, roofY, hz+hd, roofInt);
    QUAD(houseVerts, hv, hx+hw+wt, roofY+roofThick, hz-hd-wt, hx-hw-wt, roofY+roofThick, hz-hd-wt,
         hx-hw-wt, roofY+roofThick, hz+hd+wt, hx+hw+wt, roofY+roofThick, hz+hd+wt, roofExt);

    *count = hv;
    return [device newBufferWithBytes:houseVerts length:sizeof(Vertex) * hv options:MTLResourceStorageModeShared];
}

+ (id<MTLBuffer>)createDoorBufferWithDevice:(id<MTLDevice>)device vertexCount:(NSUInteger *)count {
    simd_float3 doorFront = {0.5f, 0.35f, 0.25f};
    simd_float3 doorBack = {0.4f, 0.28f, 0.18f};
    simd_float3 doorSide = {0.35f, 0.22f, 0.12f};
    simd_float3 handleCol = {0.7f, 0.65f, 0.4f};

    float dw = DOOR_WIDTH;
    float dh = DOOR_HEIGHT;
    float dt = 0.08f;

    float handleX = dw - 0.15f;
    float handleY = dh * 0.45f;
    float handleW = 0.12f;
    float handleH = 0.04f;
    float handleD = 0.04f;

    Vertex doorVerts[] = {
        // Front face
        {{0, 0, dt/2}, doorFront}, {{dw, 0, dt/2}, doorFront}, {{dw, dh, dt/2}, doorFront},
        {{0, 0, dt/2}, doorFront}, {{dw, dh, dt/2}, doorFront}, {{0, dh, dt/2}, doorFront},
        // Back face
        {{dw, 0, -dt/2}, doorBack}, {{0, 0, -dt/2}, doorBack}, {{0, dh, -dt/2}, doorBack},
        {{dw, 0, -dt/2}, doorBack}, {{0, dh, -dt/2}, doorBack}, {{dw, dh, -dt/2}, doorBack},
        // Right edge
        {{dw, 0, dt/2}, doorSide}, {{dw, 0, -dt/2}, doorSide}, {{dw, dh, -dt/2}, doorSide},
        {{dw, 0, dt/2}, doorSide}, {{dw, dh, -dt/2}, doorSide}, {{dw, dh, dt/2}, doorSide},
        // Left edge
        {{0, 0, -dt/2}, doorSide}, {{0, 0, dt/2}, doorSide}, {{0, dh, dt/2}, doorSide},
        {{0, 0, -dt/2}, doorSide}, {{0, dh, dt/2}, doorSide}, {{0, dh, -dt/2}, doorSide},
        // Top
        {{0, dh, dt/2}, doorSide}, {{dw, dh, dt/2}, doorSide}, {{dw, dh, -dt/2}, doorSide},
        {{0, dh, dt/2}, doorSide}, {{dw, dh, -dt/2}, doorSide}, {{0, dh, -dt/2}, doorSide},
        // Front handle
        {{handleX, handleY, dt/2}, handleCol}, {{handleX+handleW, handleY, dt/2}, handleCol}, {{handleX+handleW, handleY+handleH, dt/2}, handleCol},
        {{handleX, handleY, dt/2}, handleCol}, {{handleX+handleW, handleY+handleH, dt/2}, handleCol}, {{handleX, handleY+handleH, dt/2}, handleCol},
        {{handleX, handleY, dt/2+handleD}, handleCol}, {{handleX+handleW, handleY, dt/2+handleD}, handleCol}, {{handleX+handleW, handleY+handleH, dt/2+handleD}, handleCol},
        {{handleX, handleY, dt/2+handleD}, handleCol}, {{handleX+handleW, handleY+handleH, dt/2+handleD}, handleCol}, {{handleX, handleY+handleH, dt/2+handleD}, handleCol},
        {{handleX, handleY, dt/2}, handleCol}, {{handleX, handleY, dt/2+handleD}, handleCol}, {{handleX, handleY+handleH, dt/2+handleD}, handleCol},
        {{handleX, handleY, dt/2}, handleCol}, {{handleX, handleY+handleH, dt/2+handleD}, handleCol}, {{handleX, handleY+handleH, dt/2}, handleCol},
        {{handleX+handleW, handleY, dt/2+handleD}, handleCol}, {{handleX+handleW, handleY, dt/2}, handleCol}, {{handleX+handleW, handleY+handleH, dt/2}, handleCol},
        {{handleX+handleW, handleY, dt/2+handleD}, handleCol}, {{handleX+handleW, handleY+handleH, dt/2}, handleCol}, {{handleX+handleW, handleY+handleH, dt/2+handleD}, handleCol},
        {{handleX, handleY+handleH, dt/2}, handleCol}, {{handleX, handleY+handleH, dt/2+handleD}, handleCol}, {{handleX+handleW, handleY+handleH, dt/2+handleD}, handleCol},
        {{handleX, handleY+handleH, dt/2}, handleCol}, {{handleX+handleW, handleY+handleH, dt/2+handleD}, handleCol}, {{handleX+handleW, handleY+handleH, dt/2}, handleCol},
        // Back handle
        {{handleX+handleW, handleY, -dt/2}, handleCol}, {{handleX, handleY, -dt/2}, handleCol}, {{handleX, handleY+handleH, -dt/2}, handleCol},
        {{handleX+handleW, handleY, -dt/2}, handleCol}, {{handleX, handleY+handleH, -dt/2}, handleCol}, {{handleX+handleW, handleY+handleH, -dt/2}, handleCol},
        {{handleX+handleW, handleY, -dt/2-handleD}, handleCol}, {{handleX, handleY, -dt/2-handleD}, handleCol}, {{handleX, handleY+handleH, -dt/2-handleD}, handleCol},
        {{handleX+handleW, handleY, -dt/2-handleD}, handleCol}, {{handleX, handleY+handleH, -dt/2-handleD}, handleCol}, {{handleX+handleW, handleY+handleH, -dt/2-handleD}, handleCol},
        {{handleX, handleY, -dt/2-handleD}, handleCol}, {{handleX, handleY, -dt/2}, handleCol}, {{handleX, handleY+handleH, -dt/2}, handleCol},
        {{handleX, handleY, -dt/2-handleD}, handleCol}, {{handleX, handleY+handleH, -dt/2}, handleCol}, {{handleX, handleY+handleH, -dt/2-handleD}, handleCol},
        {{handleX+handleW, handleY, -dt/2}, handleCol}, {{handleX+handleW, handleY, -dt/2-handleD}, handleCol}, {{handleX+handleW, handleY+handleH, -dt/2-handleD}, handleCol},
        {{handleX+handleW, handleY, -dt/2}, handleCol}, {{handleX+handleW, handleY+handleH, -dt/2-handleD}, handleCol}, {{handleX+handleW, handleY+handleH, -dt/2}, handleCol},
        {{handleX, handleY+handleH, -dt/2-handleD}, handleCol}, {{handleX, handleY+handleH, -dt/2}, handleCol}, {{handleX+handleW, handleY+handleH, -dt/2}, handleCol},
        {{handleX, handleY+handleH, -dt/2-handleD}, handleCol}, {{handleX+handleW, handleY+handleH, -dt/2}, handleCol}, {{handleX+handleW, handleY+handleH, -dt/2-handleD}, handleCol},
    };
    *count = sizeof(doorVerts) / sizeof(Vertex);
    return [device newBufferWithBytes:doorVerts length:sizeof(doorVerts) options:MTLResourceStorageModeShared];
}

+ (id<MTLBuffer>)createFloorBufferWithDevice:(id<MTLDevice>)device {
    float s = 50.0f;
    simd_float3 c1 = {0.0, 0.15, 0.0};
    simd_float3 c2 = {0.0, 0.1, 0.0};
    Vertex floorVerts[] = {
        {{-s, -1, -s}, c2}, {{s, -1, -s}, c2}, {{s, -1, s}, c1},
        {{-s, -1, -s}, c2}, {{s, -1, s}, c1}, {{-s, -1, s}, c1},
    };
    return [device newBufferWithBytes:floorVerts length:sizeof(floorVerts) options:MTLResourceStorageModeShared];
}

+ (id<MTLBuffer>)createWall1BufferWithDevice:(id<MTLDevice>)device {
    simd_float3 wallFront = {0.45f, 0.45f, 0.42f};
    simd_float3 wallBack = {0.30f, 0.30f, 0.28f};
    simd_float3 wallRight = {0.40f, 0.40f, 0.38f};
    simd_float3 wallLeft = {0.35f, 0.35f, 0.33f};
    simd_float3 wallTop = {0.50f, 0.50f, 0.48f};
    simd_float3 wallBot = {0.25f, 0.25f, 0.23f};

    float hw = WALL_WIDTH / 2.0f;
    float hh = WALL_HEIGHT / 2.0f;
    float hd = WALL_DEPTH / 2.0f;
    float w1y = FLOOR_Y + hh;

    Vertex wall1Verts[] = {
        {{WALL1_X - hw, w1y - hh, WALL1_Z + hd}, wallFront}, {{WALL1_X + hw, w1y - hh, WALL1_Z + hd}, wallFront}, {{WALL1_X + hw, w1y + hh, WALL1_Z + hd}, wallFront},
        {{WALL1_X - hw, w1y - hh, WALL1_Z + hd}, wallFront}, {{WALL1_X + hw, w1y + hh, WALL1_Z + hd}, wallFront}, {{WALL1_X - hw, w1y + hh, WALL1_Z + hd}, wallFront},
        {{WALL1_X + hw, w1y - hh, WALL1_Z - hd}, wallBack}, {{WALL1_X - hw, w1y - hh, WALL1_Z - hd}, wallBack}, {{WALL1_X - hw, w1y + hh, WALL1_Z - hd}, wallBack},
        {{WALL1_X + hw, w1y - hh, WALL1_Z - hd}, wallBack}, {{WALL1_X - hw, w1y + hh, WALL1_Z - hd}, wallBack}, {{WALL1_X + hw, w1y + hh, WALL1_Z - hd}, wallBack},
        {{WALL1_X + hw, w1y - hh, WALL1_Z + hd}, wallRight}, {{WALL1_X + hw, w1y - hh, WALL1_Z - hd}, wallRight}, {{WALL1_X + hw, w1y + hh, WALL1_Z - hd}, wallRight},
        {{WALL1_X + hw, w1y - hh, WALL1_Z + hd}, wallRight}, {{WALL1_X + hw, w1y + hh, WALL1_Z - hd}, wallRight}, {{WALL1_X + hw, w1y + hh, WALL1_Z + hd}, wallRight},
        {{WALL1_X - hw, w1y - hh, WALL1_Z - hd}, wallLeft}, {{WALL1_X - hw, w1y - hh, WALL1_Z + hd}, wallLeft}, {{WALL1_X - hw, w1y + hh, WALL1_Z + hd}, wallLeft},
        {{WALL1_X - hw, w1y - hh, WALL1_Z - hd}, wallLeft}, {{WALL1_X - hw, w1y + hh, WALL1_Z + hd}, wallLeft}, {{WALL1_X - hw, w1y + hh, WALL1_Z - hd}, wallLeft},
        {{WALL1_X - hw, w1y + hh, WALL1_Z + hd}, wallTop}, {{WALL1_X + hw, w1y + hh, WALL1_Z + hd}, wallTop}, {{WALL1_X + hw, w1y + hh, WALL1_Z - hd}, wallTop},
        {{WALL1_X - hw, w1y + hh, WALL1_Z + hd}, wallTop}, {{WALL1_X + hw, w1y + hh, WALL1_Z - hd}, wallTop}, {{WALL1_X - hw, w1y + hh, WALL1_Z - hd}, wallTop},
        {{WALL1_X - hw, w1y - hh, WALL1_Z - hd}, wallBot}, {{WALL1_X + hw, w1y - hh, WALL1_Z - hd}, wallBot}, {{WALL1_X + hw, w1y - hh, WALL1_Z + hd}, wallBot},
        {{WALL1_X - hw, w1y - hh, WALL1_Z - hd}, wallBot}, {{WALL1_X + hw, w1y - hh, WALL1_Z + hd}, wallBot}, {{WALL1_X - hw, w1y - hh, WALL1_Z + hd}, wallBot},
    };
    return [device newBufferWithBytes:wall1Verts length:sizeof(wall1Verts) options:MTLResourceStorageModeShared];
}

+ (id<MTLBuffer>)createWall2BufferWithDevice:(id<MTLDevice>)device {
    simd_float3 wallFront = {0.45f, 0.45f, 0.42f};
    simd_float3 wallBack = {0.30f, 0.30f, 0.28f};
    simd_float3 wallRight = {0.40f, 0.40f, 0.38f};
    simd_float3 wallLeft = {0.35f, 0.35f, 0.33f};
    simd_float3 wallTop = {0.50f, 0.50f, 0.48f};
    simd_float3 wallBot = {0.25f, 0.25f, 0.23f};

    float hw = WALL_WIDTH / 2.0f;
    float hh = WALL_HEIGHT / 2.0f;
    float hd = WALL_DEPTH / 2.0f;
    float w2y = FLOOR_Y + hh;

    Vertex wall2Verts[] = {
        {{WALL2_X - hw, w2y - hh, WALL2_Z + hd}, wallFront}, {{WALL2_X + hw, w2y - hh, WALL2_Z + hd}, wallFront}, {{WALL2_X + hw, w2y + hh, WALL2_Z + hd}, wallFront},
        {{WALL2_X - hw, w2y - hh, WALL2_Z + hd}, wallFront}, {{WALL2_X + hw, w2y + hh, WALL2_Z + hd}, wallFront}, {{WALL2_X - hw, w2y + hh, WALL2_Z + hd}, wallFront},
        {{WALL2_X + hw, w2y - hh, WALL2_Z - hd}, wallBack}, {{WALL2_X - hw, w2y - hh, WALL2_Z - hd}, wallBack}, {{WALL2_X - hw, w2y + hh, WALL2_Z - hd}, wallBack},
        {{WALL2_X + hw, w2y - hh, WALL2_Z - hd}, wallBack}, {{WALL2_X - hw, w2y + hh, WALL2_Z - hd}, wallBack}, {{WALL2_X + hw, w2y + hh, WALL2_Z - hd}, wallBack},
        {{WALL2_X + hw, w2y - hh, WALL2_Z + hd}, wallRight}, {{WALL2_X + hw, w2y - hh, WALL2_Z - hd}, wallRight}, {{WALL2_X + hw, w2y + hh, WALL2_Z - hd}, wallRight},
        {{WALL2_X + hw, w2y - hh, WALL2_Z + hd}, wallRight}, {{WALL2_X + hw, w2y + hh, WALL2_Z - hd}, wallRight}, {{WALL2_X + hw, w2y + hh, WALL2_Z + hd}, wallRight},
        {{WALL2_X - hw, w2y - hh, WALL2_Z - hd}, wallLeft}, {{WALL2_X - hw, w2y - hh, WALL2_Z + hd}, wallLeft}, {{WALL2_X - hw, w2y + hh, WALL2_Z + hd}, wallLeft},
        {{WALL2_X - hw, w2y - hh, WALL2_Z - hd}, wallLeft}, {{WALL2_X - hw, w2y + hh, WALL2_Z + hd}, wallLeft}, {{WALL2_X - hw, w2y + hh, WALL2_Z - hd}, wallLeft},
        {{WALL2_X - hw, w2y + hh, WALL2_Z + hd}, wallTop}, {{WALL2_X + hw, w2y + hh, WALL2_Z + hd}, wallTop}, {{WALL2_X + hw, w2y + hh, WALL2_Z - hd}, wallTop},
        {{WALL2_X - hw, w2y + hh, WALL2_Z + hd}, wallTop}, {{WALL2_X + hw, w2y + hh, WALL2_Z - hd}, wallTop}, {{WALL2_X - hw, w2y + hh, WALL2_Z - hd}, wallTop},
        {{WALL2_X - hw, w2y - hh, WALL2_Z - hd}, wallBot}, {{WALL2_X + hw, w2y - hh, WALL2_Z - hd}, wallBot}, {{WALL2_X + hw, w2y - hh, WALL2_Z + hd}, wallBot},
        {{WALL2_X - hw, w2y - hh, WALL2_Z - hd}, wallBot}, {{WALL2_X + hw, w2y - hh, WALL2_Z + hd}, wallBot}, {{WALL2_X - hw, w2y - hh, WALL2_Z + hd}, wallBot},
    };
    return [device newBufferWithBytes:wall2Verts length:sizeof(wall2Verts) options:MTLResourceStorageModeShared];
}

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

+ (id<MTLBuffer>)createEnemyBufferWithDevice:(id<MTLDevice>)device vertexCount:(NSUInteger *)count {
    #define MAX_ENEMY_VERTS 600
    Vertex enemyVerts[MAX_ENEMY_VERTS];
    int ev = 0;

    simd_float3 bodyDark = {0.5f, 0.1f, 0.1f};
    simd_float3 bodyMid = {0.7f, 0.15f, 0.15f};
    simd_float3 bodyLight = {0.8f, 0.2f, 0.2f};
    simd_float3 skinTone = {0.8f, 0.65f, 0.5f};
    simd_float3 skinDark = {0.65f, 0.5f, 0.4f};
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

    // Blue team colors instead of red
    simd_float3 bodyDark = {0.1f, 0.1f, 0.5f};
    simd_float3 bodyMid = {0.15f, 0.15f, 0.7f};
    simd_float3 bodyLight = {0.2f, 0.2f, 0.8f};
    simd_float3 skinTone = {0.8f, 0.65f, 0.5f};
    simd_float3 skinDark = {0.65f, 0.5f, 0.4f};
    simd_float3 gunC1 = {0.2f, 0.2f, 0.2f};
    simd_float3 gunC2 = {0.1f, 0.1f, 0.1f};
    simd_float3 gunC3 = {0.25f, 0.25f, 0.25f};

    // Same humanoid shape as enemy model
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

    #define GORECT(x0,y0,x1,y1,col) do { \
        goVerts[gov++] = (Vertex){{x0,y0,0},col}; \
        goVerts[gov++] = (Vertex){{x1,y0,0},col}; \
        goVerts[gov++] = (Vertex){{x1,y1,0},col}; \
        goVerts[gov++] = (Vertex){{x0,y0,0},col}; \
        goVerts[gov++] = (Vertex){{x1,y1,0},col}; \
        goVerts[gov++] = (Vertex){{x0,y1,0},col}; \
    } while(0)

    float lw = 0.07f, lh = 0.12f, th = 0.015f, sp = 0.09f;
    float startX = -0.40f;
    float y = 0.05f;
    float x;

    // G
    x = startX;
    GORECT(x, y, x+th, y+lh, red); GORECT(x, y+lh-th, x+lw, y+lh, red); GORECT(x, y, x+lw, y+th, red);
    GORECT(x+lw-th, y, x+lw, y+lh*0.5f, red); GORECT(x+lw*0.4f, y+lh*0.45f, x+lw, y+lh*0.45f+th, red);
    // A
    x += sp;
    GORECT(x, y, x+th, y+lh, red); GORECT(x+lw-th, y, x+lw, y+lh, red);
    GORECT(x, y+lh-th, x+lw, y+lh, red); GORECT(x, y+lh*0.45f, x+lw, y+lh*0.45f+th, red);
    // M
    x += sp;
    GORECT(x, y, x+th, y+lh, red); GORECT(x+lw-th, y, x+lw, y+lh, red);
    GORECT(x, y+lh-th, x+lw*0.5f, y+lh, red); GORECT(x+lw*0.5f, y+lh-th, x+lw, y+lh, red);
    GORECT(x+lw*0.5f-th*0.5f, y+lh*0.5f, x+lw*0.5f+th*0.5f, y+lh, red);
    // E
    x += sp;
    GORECT(x, y, x+th, y+lh, red); GORECT(x, y+lh-th, x+lw, y+lh, red);
    GORECT(x, y, x+lw, y+th, red); GORECT(x, y+lh*0.45f, x+lw*0.7f, y+lh*0.45f+th, red);
    // Space
    x += sp * 0.7f;
    // O
    x += sp;
    GORECT(x, y, x+th, y+lh, red); GORECT(x+lw-th, y, x+lw, y+lh, red);
    GORECT(x, y+lh-th, x+lw, y+lh, red); GORECT(x, y, x+lw, y+th, red);
    // V
    x += sp;
    GORECT(x, y+lh*0.3f, x+th, y+lh, red); GORECT(x+lw-th, y+lh*0.3f, x+lw, y+lh, red);
    GORECT(x, y+lh*0.3f, x+lw*0.5f+th, y+lh*0.3f+th, red);
    GORECT(x+lw*0.5f-th, y+lh*0.3f, x+lw, y+lh*0.3f+th, red);
    GORECT(x+lw*0.5f-th*0.5f, y, x+lw*0.5f+th*0.5f, y+lh*0.35f, red);
    // E
    x += sp;
    GORECT(x, y, x+th, y+lh, red); GORECT(x, y+lh-th, x+lw, y+lh, red);
    GORECT(x, y, x+lw, y+th, red); GORECT(x, y+lh*0.45f, x+lw*0.7f, y+lh*0.45f+th, red);
    // R
    x += sp;
    GORECT(x, y, x+th, y+lh, red); GORECT(x, y+lh-th, x+lw, y+lh, red);
    GORECT(x+lw-th, y+lh*0.5f, x+lw, y+lh, red); GORECT(x, y+lh*0.45f, x+lw, y+lh*0.45f+th, red);
    GORECT(x+lw*0.4f, y, x+lw, y+lh*0.45f, red);

    // "PRESS R" smaller
    lw = 0.045f; lh = 0.07f; th = 0.01f; sp = 0.055f;
    startX = -0.19f; y = -0.12f;
    // P
    x = startX;
    GORECT(x, y, x+th, y+lh, white); GORECT(x, y+lh-th, x+lw, y+lh, white);
    GORECT(x+lw-th, y+lh*0.45f, x+lw, y+lh, white); GORECT(x, y+lh*0.45f, x+lw, y+lh*0.45f+th, white);
    // R
    x += sp;
    GORECT(x, y, x+th, y+lh, white); GORECT(x, y+lh-th, x+lw, y+lh, white);
    GORECT(x+lw-th, y+lh*0.5f, x+lw, y+lh, white); GORECT(x, y+lh*0.45f, x+lw, y+lh*0.45f+th, white);
    GORECT(x+lw*0.4f, y, x+lw, y+lh*0.45f, white);
    // E
    x += sp;
    GORECT(x, y, x+th, y+lh, white); GORECT(x, y+lh-th, x+lw, y+lh, white);
    GORECT(x, y, x+lw, y+th, white); GORECT(x, y+lh*0.45f, x+lw*0.7f, y+lh*0.45f+th, white);
    // S
    x += sp;
    GORECT(x, y+lh-th, x+lw, y+lh, white); GORECT(x, y+lh*0.5f, x+th, y+lh, white);
    GORECT(x, y+lh*0.45f, x+lw, y+lh*0.45f+th, white);
    GORECT(x+lw-th, y, x+lw, y+lh*0.5f, white); GORECT(x, y, x+lw, y+th, white);
    // S
    x += sp;
    GORECT(x, y+lh-th, x+lw, y+lh, white); GORECT(x, y+lh*0.5f, x+th, y+lh, white);
    GORECT(x, y+lh*0.45f, x+lw, y+lh*0.45f+th, white);
    GORECT(x+lw-th, y, x+lw, y+lh*0.5f, white); GORECT(x, y, x+lw, y+th, white);
    // Space
    x += sp * 0.5f;
    // R (yellow)
    x += sp;
    simd_float3 yellow = {1.0f, 1.0f, 0.2f};
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

    // P
    RECT(0,0,1,7); RECT(1,6,4,7); RECT(4,4,5,7); RECT(1,3,4,4);
    // A
    RECT(7,0,8,7); RECT(8,6,11,7); RECT(11,0,12,7); RECT(8,3,11,4);
    // U
    RECT(14,0,15,7); RECT(15,0,18,1); RECT(18,0,19,7);
    // S
    RECT(22,0,26,1); RECT(25,1,26,3); RECT(22,3,25,4); RECT(21,4,22,6); RECT(21,6,25,7);
    // E
    RECT(28,0,29,7); RECT(29,0,33,1); RECT(29,3,32,4); RECT(29,6,33,7);
    // D
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
    float h = 10.0f;
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

@end
