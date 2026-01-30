// Renderer.m - Metal renderer implementation
#import "Renderer.h"
#import "GameConfig.h"
#import "GameTypes.h"
#import "GameState.h"
#import "GameMath.h"
#import "Collision.h"
#import "DoorSystem.h"
#import "SoundManager.h"
#import "Combat.h"
#import "Enemy.h"
#import "GeometryBuilder.h"
#import "MultiplayerController.h"
#import "PickupSystem.h"

@interface MetalRenderer ()
@property (nonatomic, strong) id<MTLRenderPipelineState> pipelineState;
@property (nonatomic, strong) id<MTLRenderPipelineState> bgPipelineState;
@property (nonatomic, strong) id<MTLRenderPipelineState> textPipelineState;
@property (nonatomic, strong) id<MTLDepthStencilState> depthState;
@property (nonatomic, strong) id<MTLDepthStencilState> bgDepthState;

@property (nonatomic, strong) id<MTLBuffer> bgVertexBuffer;
@property (nonatomic, strong) id<MTLBuffer> floorVertexBuffer;
@property (nonatomic, strong) id<MTLBuffer> houseBuffer;
@property (nonatomic) NSUInteger houseVertexCount;
@property (nonatomic, strong) id<MTLBuffer> doorBuffer;
@property (nonatomic) NSUInteger doorVertexCount;
@property (nonatomic, strong) id<MTLBuffer> wall1Buffer;
@property (nonatomic, strong) id<MTLBuffer> wall2Buffer;
@property (nonatomic, strong) id<MTLBuffer> gunVertexBuffer;
@property (nonatomic) NSUInteger gunVertexCount;
@property (nonatomic, strong) id<MTLBuffer> enemyVertexBuffer;
@property (nonatomic) NSUInteger enemyVertexCount;
@property (nonatomic, strong) id<MTLBuffer> muzzleFlashBuffer;
@property (nonatomic, strong) id<MTLBuffer> healthBarBgBuffer;
@property (nonatomic, strong) id<MTLBuffer> healthBarFgBuffer;
@property (nonatomic, strong) id<MTLBuffer> playerHpBgBuffer;
@property (nonatomic, strong) id<MTLBuffer> playerHpFgBuffer;
@property (nonatomic, strong) id<MTLBuffer> gameOverBuffer;
@property (nonatomic) NSUInteger gameOverVertexCount;
@property (nonatomic, strong) id<MTLBuffer> crosshairBuffer;
@property (nonatomic, strong) id<MTLBuffer> ePromptBuffer;
@property (nonatomic) NSUInteger ePromptVertexCount;
@property (nonatomic, strong) id<MTLBuffer> textVertexBuffer;
@property (nonatomic) NSUInteger textVertexCount;
@property (nonatomic, strong) id<MTLBuffer> boxLineBuffer;
@property (nonatomic) NSUInteger boxLineVertexCount;
@property (nonatomic, strong) id<MTLBuffer> remotePlayerBuffer;
@property (nonatomic) NSUInteger remotePlayerVertexCount;

// Pickup buffers
@property (nonatomic, strong) id<MTLBuffer> healthPackBuffer;
@property (nonatomic) NSUInteger healthPackVertexCount;
@property (nonatomic, strong) id<MTLBuffer> ammoBoxBuffer;
@property (nonatomic) NSUInteger ammoBoxVertexCount;
@property (nonatomic, strong) id<MTLBuffer> weaponPickupBuffer;
@property (nonatomic) NSUInteger weaponPickupVertexCount;
@property (nonatomic, strong) id<MTLBuffer> armorBuffer;
@property (nonatomic) NSUInteger armorVertexCount;

// Military base geometry buffers
@property (nonatomic, strong) id<MTLBuffer> commandBuildingBuffer;
@property (nonatomic) NSUInteger commandBuildingVertexCount;
@property (nonatomic, strong) id<MTLBuffer> guardTowerBuffer;
@property (nonatomic) NSUInteger guardTowerVertexCount;
@property (nonatomic, strong) id<MTLBuffer> catwalkBuffer;
@property (nonatomic) NSUInteger catwalkVertexCount;
@property (nonatomic, strong) id<MTLBuffer> bunkerBuffer;
@property (nonatomic) NSUInteger bunkerVertexCount;
@property (nonatomic, strong) id<MTLBuffer> cargoContainersBuffer;
@property (nonatomic) NSUInteger cargoContainersVertexCount;
@property (nonatomic, strong) id<MTLBuffer> sandbagBuffer;
@property (nonatomic) NSUInteger sandbagVertexCount;
@property (nonatomic, strong) id<MTLBuffer> militaryFloorBuffer;
@property (nonatomic) NSUInteger militaryFloorVertexCount;
@end

@implementation MetalRenderer

- (instancetype)initWithDevice:(id<MTLDevice>)device view:(DraggableMetalView *)view {
    self = [super init];
    if (self) {
        _device = device;
        _commandQueue = [device newCommandQueue];
        _metalView = view;

        // Initialize game state
        GameState *state = [GameState shared];

        // Initial player state
        view.posX = PLAYER_START_X;
        view.posY = FLOOR_Y + PLAYER_HEIGHT;
        view.posZ = PLAYER_START_Z;
        view.camYaw = M_PI;
        view.camPitch = 0.0;
        view.controlsActive = YES;
        view.onGround = YES;
        view.velocityY = 0;
        CGAssociateMouseAndMouseCursorPosition(false);
        [NSCursor hide];

        // Initialize sounds
        [SoundManager shared];

        // Create geometry buffers
        _bgVertexBuffer = [GeometryBuilder createBackgroundBufferWithDevice:device];
        _floorVertexBuffer = [GeometryBuilder createFloorBufferWithDevice:device];
        _houseBuffer = [GeometryBuilder createHouseBufferWithDevice:device vertexCount:&_houseVertexCount];
        _doorBuffer = [GeometryBuilder createDoorBufferWithDevice:device vertexCount:&_doorVertexCount];
        _wall1Buffer = [GeometryBuilder createWall1BufferWithDevice:device];
        _wall2Buffer = [GeometryBuilder createWall2BufferWithDevice:device];
        _gunVertexBuffer = [GeometryBuilder createGunBufferWithDevice:device vertexCount:&_gunVertexCount];
        _enemyVertexBuffer = [GeometryBuilder createEnemyBufferWithDevice:device vertexCount:&_enemyVertexCount];
        _muzzleFlashBuffer = [GeometryBuilder createMuzzleFlashBufferWithDevice:device];
        _healthBarBgBuffer = [GeometryBuilder createHealthBarBgBufferWithDevice:device];
        _healthBarFgBuffer = [GeometryBuilder createHealthBarFgBufferWithDevice:device];
        _playerHpBgBuffer = [GeometryBuilder createPlayerHpBgBufferWithDevice:device];
        _playerHpFgBuffer = [GeometryBuilder createPlayerHpFgBufferWithDevice:device];
        _gameOverBuffer = [GeometryBuilder createGameOverBufferWithDevice:device vertexCount:&_gameOverVertexCount];
        _crosshairBuffer = [GeometryBuilder createCrosshairBufferWithDevice:device];
        _ePromptBuffer = [GeometryBuilder createEPromptBufferWithDevice:device vertexCount:&_ePromptVertexCount];
        _textVertexBuffer = [GeometryBuilder createPausedTextBufferWithDevice:device vertexCount:&_textVertexCount];
        _boxLineBuffer = [GeometryBuilder createBoxGridBufferWithDevice:device vertexCount:&_boxLineVertexCount];
        _remotePlayerBuffer = [GeometryBuilder createRemotePlayerBufferWithDevice:device vertexCount:&_remotePlayerVertexCount];

        // Create pickup buffers
        _healthPackBuffer = [GeometryBuilder createHealthPackBufferWithDevice:device vertexCount:&_healthPackVertexCount];
        _ammoBoxBuffer = [GeometryBuilder createAmmoBoxBufferWithDevice:device vertexCount:&_ammoBoxVertexCount];
        _weaponPickupBuffer = [GeometryBuilder createWeaponPickupBufferWithDevice:device vertexCount:&_weaponPickupVertexCount];
        _armorBuffer = [GeometryBuilder createArmorBufferWithDevice:device vertexCount:&_armorVertexCount];

        // Create military base geometry buffers
        _commandBuildingBuffer = [GeometryBuilder createCommandBuildingBufferWithDevice:device vertexCount:&_commandBuildingVertexCount];
        _guardTowerBuffer = [GeometryBuilder createGuardTowerBufferWithDevice:device vertexCount:&_guardTowerVertexCount];
        _catwalkBuffer = [GeometryBuilder createCatwalkBufferWithDevice:device vertexCount:&_catwalkVertexCount];
        _bunkerBuffer = [GeometryBuilder createBunkerBufferWithDevice:device vertexCount:&_bunkerVertexCount];
        _cargoContainersBuffer = [GeometryBuilder createCargoContainersBufferWithDevice:device vertexCount:&_cargoContainersVertexCount];
        _sandbagBuffer = [GeometryBuilder createSandbagBufferWithDevice:device vertexCount:&_sandbagVertexCount];
        _militaryFloorBuffer = [GeometryBuilder createMilitaryFloorBufferWithDevice:device vertexCount:&_militaryFloorVertexCount];

        // Initialize pickup system
        [PickupSystem shared];

        // Create shaders and pipelines
        NSString *shaderSrc = @""
            "#include <metal_stdlib>\n"
            "using namespace metal;\n"
            "struct VertexIn { float3 position; float3 color; };\n"
            "struct VertexOut { float4 position [[position]]; float3 color; };\n"
            "vertex VertexOut vertexShader(const device VertexIn *vertices [[buffer(0)]],"
            "    constant float4x4 &mvp [[buffer(1)]], uint vid [[vertex_id]]) {\n"
            "    VertexOut out;\n"
            "    out.position = mvp * float4(vertices[vid].position, 1.0);\n"
            "    out.color = vertices[vid].color;\n"
            "    return out;\n"
            "}\n"
            "vertex VertexOut bgVertexShader(const device VertexIn *vertices [[buffer(0)]],"
            "    uint vid [[vertex_id]]) {\n"
            "    VertexOut out;\n"
            "    out.position = float4(vertices[vid].position, 1.0);\n"
            "    out.color = vertices[vid].color;\n"
            "    return out;\n"
            "}\n"
            "fragment float4 fragmentShader(VertexOut in [[stage_in]]) {\n"
            "    return float4(in.color, 1.0);\n"
            "}\n";

        NSError *error = nil;
        id<MTLLibrary> library = [device newLibraryWithSource:shaderSrc options:nil error:&error];
        if (error) NSLog(@"Shader error: %@", error);

        // Main pipeline
        MTLRenderPipelineDescriptor *desc = [[MTLRenderPipelineDescriptor alloc] init];
        desc.vertexFunction = [library newFunctionWithName:@"vertexShader"];
        desc.fragmentFunction = [library newFunctionWithName:@"fragmentShader"];
        desc.colorAttachments[0].pixelFormat = view.colorPixelFormat;
        desc.depthAttachmentPixelFormat = MTLPixelFormatDepth32Float;
        _pipelineState = [device newRenderPipelineStateWithDescriptor:desc error:&error];

        // Background pipeline
        MTLRenderPipelineDescriptor *bgDesc = [[MTLRenderPipelineDescriptor alloc] init];
        bgDesc.vertexFunction = [library newFunctionWithName:@"bgVertexShader"];
        bgDesc.fragmentFunction = [library newFunctionWithName:@"fragmentShader"];
        bgDesc.colorAttachments[0].pixelFormat = view.colorPixelFormat;
        bgDesc.depthAttachmentPixelFormat = MTLPixelFormatDepth32Float;
        _bgPipelineState = [device newRenderPipelineStateWithDescriptor:bgDesc error:&error];

        // Text pipeline with blending
        MTLRenderPipelineDescriptor *textDesc = [[MTLRenderPipelineDescriptor alloc] init];
        textDesc.vertexFunction = [library newFunctionWithName:@"bgVertexShader"];
        textDesc.fragmentFunction = [library newFunctionWithName:@"fragmentShader"];
        textDesc.colorAttachments[0].pixelFormat = view.colorPixelFormat;
        textDesc.colorAttachments[0].blendingEnabled = YES;
        textDesc.colorAttachments[0].sourceRGBBlendFactor = MTLBlendFactorSourceAlpha;
        textDesc.colorAttachments[0].destinationRGBBlendFactor = MTLBlendFactorOneMinusSourceAlpha;
        textDesc.depthAttachmentPixelFormat = MTLPixelFormatDepth32Float;
        _textPipelineState = [device newRenderPipelineStateWithDescriptor:textDesc error:&error];

        // Depth states
        MTLDepthStencilDescriptor *depthDesc = [[MTLDepthStencilDescriptor alloc] init];
        depthDesc.depthCompareFunction = MTLCompareFunctionLess;
        depthDesc.depthWriteEnabled = YES;
        _depthState = [device newDepthStencilStateWithDescriptor:depthDesc];

        MTLDepthStencilDescriptor *bgDepthDesc = [[MTLDepthStencilDescriptor alloc] init];
        bgDepthDesc.depthCompareFunction = MTLCompareFunctionAlways;
        bgDepthDesc.depthWriteEnabled = YES;
        _bgDepthState = [device newDepthStencilStateWithDescriptor:bgDepthDesc];
    }
    return self;
}

- (void)mtkView:(MTKView *)view drawableSizeWillChange:(CGSize)size {}

- (void)drawInMTKView:(MTKView *)view {
    MTLRenderPassDescriptor *passDescriptor = view.currentRenderPassDescriptor;
    if (!passDescriptor) return;

    GameState *state = [GameState shared];

    // Update multiplayer network state
    [_metalView sendNetworkState];

    // ============================================
    // PHYSICS SYSTEM - Proper collision order
    // ============================================
    // 1. Apply input to velocity
    // 2. Apply gravity to velocity
    // 3. Move player by velocity (with collision detection)
    // 4. Resolve collisions and set onGround flag
    // ============================================

    // Skip physics when paused
    if (!state.gameOver && !state.isPaused) {

        // --- STEP 1: Apply input acceleration ---
        if (_metalView.controlsActive) {
            float fwdX = sinf(_metalView.camYaw);
            float fwdZ = -cosf(_metalView.camYaw);
            float rgtX = cosf(_metalView.camYaw);
            float rgtZ = sinf(_metalView.camYaw);

            float strafeAccel = MOVE_ACCEL * STRAFE_MULTIPLIER;
            if (_metalView.keyW) { _metalView.velocityX += fwdX * MOVE_ACCEL; _metalView.velocityZ += fwdZ * MOVE_ACCEL; }
            if (_metalView.keyS) { _metalView.velocityX -= fwdX * MOVE_ACCEL; _metalView.velocityZ -= fwdZ * MOVE_ACCEL; }
            if (_metalView.keyA) { _metalView.velocityX -= rgtX * strafeAccel; _metalView.velocityZ -= rgtZ * strafeAccel; }
            if (_metalView.keyD) { _metalView.velocityX += rgtX * strafeAccel; _metalView.velocityZ += rgtZ * strafeAccel; }
        }

        // Clamp horizontal speed
        float hSpeed = sqrtf(_metalView.velocityX * _metalView.velocityX + _metalView.velocityZ * _metalView.velocityZ);
        if (hSpeed > MAX_SPEED) {
            _metalView.velocityX *= MAX_SPEED / hSpeed;
            _metalView.velocityZ *= MAX_SPEED / hSpeed;
        }

        // Apply friction to horizontal movement
        _metalView.velocityX *= MOVE_FRICTION;
        _metalView.velocityZ *= MOVE_FRICTION;

        // --- STEP 2: Apply gravity ---
        _metalView.velocityY -= GRAVITY;

        // Clamp terminal velocity
        if (_metalView.velocityY < -0.5f) _metalView.velocityY = -0.5f;

        // Store original position for collision detection
        float origX = _metalView.posX;
        float origY = _metalView.posY;
        float origZ = _metalView.posZ;

        // --- STEP 3: Move player ---
        _metalView.posX += _metalView.velocityX;
        _metalView.posY += _metalView.velocityY;
        _metalView.posZ += _metalView.velocityZ;

        // --- STEP 4: Ground/Platform collision detection ---
        // Clear onGround - will be set true if we detect ground contact
        BOOL wasOnGround = _metalView.onGround;
        _metalView.onGround = NO;

        float px = _metalView.posX;
        float py = _metalView.posY;
        float pz = _metalView.posZ;
        float feetY = py - PLAYER_HEIGHT;
        float velY = _metalView.velocityY;

        // Ground detection tolerance - tighter than before to prevent glitching
        float groundTolerance = 0.15f;
        // Landing tolerance - how far above platform we can be to land on it
        float landingTolerance = 0.08f;

        // Track the highest valid ground surface found
        float bestGroundY = -1000.0f;
        BOOL foundGround = NO;

        // --- Check base floor level (including bunker) ---
        float bunkerMinX = BUNKER_X - BUNKER_WIDTH/2;
        float bunkerMaxX = BUNKER_X + BUNKER_WIDTH/2;
        float bunkerMinZ = BUNKER_Z - BUNKER_DEPTH/2;
        float bunkerMaxZ = BUNKER_Z + BUNKER_DEPTH/2;

        BOOL inBunkerArea = (px > bunkerMinX && px < bunkerMaxX &&
                             pz > bunkerMinZ && pz < bunkerMaxZ);
        float baseGroundY = inBunkerArea ? BASEMENT_LEVEL : FLOOR_Y;

        // Check if at or below base ground
        if (feetY <= baseGroundY + groundTolerance) {
            if (baseGroundY > bestGroundY) {
                bestGroundY = baseGroundY;
                foundGround = YES;
            }
        }

        // --- Platform collision detection ---
        // Use a helper macro to check if we can land on a platform
        // Only land when: (1) horizontally over platform, (2) feet at or just above surface,
        // (3) moving downward or stationary, (4) platform is higher than current best ground
        #define CHECK_PLATFORM_LANDING(platMinX, platMinZ, platMaxX, platMaxZ, platTopY) \
            if (px > (platMinX) - PLAYER_RADIUS && px < (platMaxX) + PLAYER_RADIUS && \
                pz > (platMinZ) - PLAYER_RADIUS && pz < (platMaxZ) + PLAYER_RADIUS) { \
                float dist = feetY - (platTopY); \
                if (dist >= -landingTolerance && dist <= groundTolerance && velY <= 0.001f) { \
                    if ((platTopY) > bestGroundY) { \
                        bestGroundY = (platTopY); \
                        foundGround = YES; \
                    } \
                } \
            }

        // Tower platforms
        float towerPositions[4][2] = {
            {TOWER_OFFSET, TOWER_OFFSET},
            {-TOWER_OFFSET, TOWER_OFFSET},
            {-TOWER_OFFSET, -TOWER_OFFSET},
            {TOWER_OFFSET, -TOWER_OFFSET}
        };

        float platHalfSize = TOWER_SIZE / 2.0f;
        for (int t = 0; t < 4; t++) {
            float tx = towerPositions[t][0];
            float tz = towerPositions[t][1];
            CHECK_PLATFORM_LANDING(tx - platHalfSize, tz - platHalfSize,
                                   tx + platHalfSize, tz + platHalfSize, PLATFORM_LEVEL);
        }

        // Catwalks
        // North catwalk
        CHECK_PLATFORM_LANDING(-TOWER_OFFSET + TOWER_SIZE/2, TOWER_OFFSET - CATWALK_WIDTH/2,
                               TOWER_OFFSET - TOWER_SIZE/2, TOWER_OFFSET + CATWALK_WIDTH/2, PLATFORM_LEVEL);
        // South catwalk
        CHECK_PLATFORM_LANDING(-TOWER_OFFSET + TOWER_SIZE/2, -TOWER_OFFSET - CATWALK_WIDTH/2,
                               TOWER_OFFSET - TOWER_SIZE/2, -TOWER_OFFSET + CATWALK_WIDTH/2, PLATFORM_LEVEL);
        // East catwalk
        CHECK_PLATFORM_LANDING(TOWER_OFFSET - CATWALK_WIDTH/2, -TOWER_OFFSET + TOWER_SIZE/2,
                               TOWER_OFFSET + CATWALK_WIDTH/2, TOWER_OFFSET - TOWER_SIZE/2, PLATFORM_LEVEL);
        // West catwalk
        CHECK_PLATFORM_LANDING(-TOWER_OFFSET - CATWALK_WIDTH/2, -TOWER_OFFSET + TOWER_SIZE/2,
                               -TOWER_OFFSET + CATWALK_WIDTH/2, TOWER_OFFSET - TOWER_SIZE/2, PLATFORM_LEVEL);

        // Cargo containers
        struct { float x, z; int rotated; float topY; } containerPlatforms[] = {
            {8.0f, 4.0f, 0, FLOOR_Y + CONTAINER_HEIGHT},
            {8.5f, 6.5f, 1, FLOOR_Y + CONTAINER_HEIGHT},
            {-8.0f, 4.0f, 0, FLOOR_Y + CONTAINER_HEIGHT},
            {-8.5f, 6.5f, 1, FLOOR_Y + CONTAINER_HEIGHT},
            {6.0f, -8.0f, 1, FLOOR_Y + CONTAINER_HEIGHT},
            {-6.0f, -8.0f, 1, FLOOR_Y + CONTAINER_HEIGHT},
            {0.0f, -12.0f, 0, FLOOR_Y + CONTAINER_HEIGHT},
            {12.0f, 0.0f, 1, FLOOR_Y + CONTAINER_HEIGHT},
            {8.0f, 4.0f, 0, FLOOR_Y + CONTAINER_HEIGHT * 2}  // Stacked container
        };

        for (int c = 0; c < 9; c++) {
            float cx = containerPlatforms[c].x;
            float cy = containerPlatforms[c].topY;
            float cz = containerPlatforms[c].z;
            float cxl = containerPlatforms[c].rotated ? CONTAINER_WIDTH/2 : CONTAINER_LENGTH/2;
            float czl = containerPlatforms[c].rotated ? CONTAINER_LENGTH/2 : CONTAINER_WIDTH/2;
            CHECK_PLATFORM_LANDING(cx - cxl, cz - czl, cx + cxl, cz + czl, cy);
        }

        // Command building second floor
        float hw = CMD_BUILDING_WIDTH / 2.0f;
        float hd = CMD_BUILDING_DEPTH / 2.0f;
        float secondFloorY = FLOOR_Y + CMD_BUILDING_HEIGHT / 2.0f;
        float stairHoleW = 1.0f;  // half-width of stair hole
        float stairHoleD = 1.0f;  // half-depth of stair hole
        float innerWall = CMD_WALL_THICK;

        // Check if inside building but not in stair hole
        if (px > CMD_BUILDING_X - hw + innerWall && px < CMD_BUILDING_X + hw - innerWall &&
            pz > CMD_BUILDING_Z - hd + innerWall && pz < CMD_BUILDING_Z + hd - innerWall) {
            BOOL inStairHole = (px > CMD_BUILDING_X - stairHoleW && px < CMD_BUILDING_X + stairHoleW &&
                               pz > CMD_BUILDING_Z - stairHoleD && pz < CMD_BUILDING_Z + stairHoleD);
            if (!inStairHole) {
                float dist = feetY - secondFloorY;
                if (dist >= -landingTolerance && dist <= groundTolerance && velY <= 0.001f) {
                    if (secondFloorY > bestGroundY) {
                        bestGroundY = secondFloorY;
                        foundGround = YES;
                    }
                }
            }
        }

        // Command building stairs (6 steps)
        int cmdNumSteps = 6;
        float cmdStepH = (secondFloorY - FLOOR_Y) / cmdNumSteps;
        float cmdStepD = stairHoleD * 2 / cmdNumSteps;
        float cmdStairX = CMD_BUILDING_X - stairHoleW + 0.1f;
        float cmdStairW = stairHoleW * 2 - 0.2f;

        for (int i = 0; i < cmdNumSteps; i++) {
            float stepTop = FLOOR_Y + (i + 1) * cmdStepH;
            float stepZStart = CMD_BUILDING_Z + stairHoleD - i * cmdStepD;
            float stepZEnd = stepZStart - cmdStepD;

            if (px > cmdStairX && px < cmdStairX + cmdStairW &&
                pz > stepZEnd && pz < stepZStart) {
                float dist = feetY - stepTop;
                if (dist >= -landingTolerance && dist <= groundTolerance + 0.1f && velY <= 0.001f) {
                    if (stepTop > bestGroundY) {
                        bestGroundY = stepTop;
                        foundGround = YES;
                    }
                }
            }
        }

        // Guard tower ramps
        float rampHalfW = RAMP_WIDTH / 2.0f;
        float rampL = RAMP_LENGTH;
        float ts = TOWER_SIZE / 2.0f;
        float platY = FLOOR_Y + TOWER_HEIGHT;

        for (int t = 0; t < 4; t++) {
            float tx = towerPositions[t][0];
            float tz = towerPositions[t][1];
            float rampDx = (tx > 0) ? -1.0f : 1.0f;
            float rampDz = (tz > 0) ? -1.0f : 1.0f;

            float rampStartX = tx + rampDx * ts;
            float rampStartZ = tz + rampDz * ts;
            float rampEndX = rampStartX + rampDx * rampL;
            float rampEndZ = rampStartZ + rampDz * rampL;

            float rampMinX = fminf(rampStartX, rampEndX) - rampHalfW * fabsf(rampDz);
            float rampMaxX = fmaxf(rampStartX, rampEndX) + rampHalfW * fabsf(rampDz);
            float rampMinZ = fminf(rampStartZ, rampEndZ) - rampHalfW * fabsf(rampDx);
            float rampMaxZ = fmaxf(rampStartZ, rampEndZ) + rampHalfW * fabsf(rampDx);

            if (px > rampMinX && px < rampMaxX && pz > rampMinZ && pz < rampMaxZ) {
                float progressX = (px - rampEndX) / (rampStartX - rampEndX);
                float progressZ = (pz - rampEndZ) / (rampStartZ - rampEndZ);
                float progress = (fabsf(rampStartX - rampEndX) > fabsf(rampStartZ - rampEndZ)) ? progressX : progressZ;
                progress = fmaxf(0.0f, fminf(1.0f, progress));
                float rampY = FLOOR_Y + progress * (platY - FLOOR_Y);

                float dist = feetY - rampY;
                if (dist >= -landingTolerance && dist <= groundTolerance + 0.2f && velY <= 0.001f) {
                    if (rampY > bestGroundY) {
                        bestGroundY = rampY;
                        foundGround = YES;
                    }
                }
            }
        }

        // Bunker floor and stairs
        float bx = BUNKER_X;
        float bz = BUNKER_Z;
        float bhw = BUNKER_WIDTH / 2.0f;
        float bhd = BUNKER_DEPTH / 2.0f;
        float bwt = 0.4f;

        // Bunker interior floor
        if (px > bx - bhw + bwt && px < bx + bhw - bwt &&
            pz > bz - bhd + bwt && pz < bz + bhd - bwt) {
            float dist = feetY - BASEMENT_LEVEL;
            if (dist >= -landingTolerance && dist <= groundTolerance && velY <= 0.001f) {
                if (BASEMENT_LEVEL > bestGroundY) {
                    bestGroundY = BASEMENT_LEVEL;
                    foundGround = YES;
                }
            }
        }

        // Bunker stairs (8 steps)
        int bunkerNumSteps = 8;
        float bunkerStepH = (FLOOR_Y - BASEMENT_LEVEL) / bunkerNumSteps;
        float bunkerStepD = (bhd * 2 - bwt * 2) / bunkerNumSteps;
        float bsw = BUNKER_STAIR_WIDTH / 2.0f;

        for (int i = 0; i < bunkerNumSteps; i++) {
            float stepTop = FLOOR_Y - i * bunkerStepH;
            float stepZStart = bz + bhd - bwt - i * bunkerStepD;
            float stepZEnd = stepZStart - bunkerStepD;

            if (px > bx - bsw && px < bx + bsw && pz > stepZEnd && pz < stepZStart) {
                float dist = feetY - stepTop;
                if (dist >= -landingTolerance && dist <= groundTolerance + 0.2f && velY <= 0.001f) {
                    if (stepTop > bestGroundY) {
                        bestGroundY = stepTop;
                        foundGround = YES;
                    }
                }
            }
        }

        // --- Apply ground collision ---
        if (foundGround && feetY <= bestGroundY + groundTolerance) {
            _metalView.posY = bestGroundY + PLAYER_HEIGHT;
            _metalView.velocityY = 0;
            _metalView.onGround = YES;

            // Auto-jump when holding space (bunny hop)
            if (_metalView.keySpace) {
                _metalView.velocityY = JUMP_VELOCITY;
                _metalView.onGround = NO;
            }
        }

        // Update position variables after ground snap
        py = _metalView.posY;
        feetY = py - PLAYER_HEIGHT;

        #undef CHECK_PLATFORM_LANDING

    // Wall collision (military base)
        // --- STEP 5: Wall/solid collision ---
        // This runs AFTER ground detection to prevent horizontal collision
        // from interfering with vertical landing

        float headY = py + 0.1f;

        float wallHw = CMD_BUILDING_WIDTH / 2.0f;
        float wallHd = CMD_BUILDING_DEPTH / 2.0f;
        float wt = CMD_WALL_THICK;
        float fy = FLOOR_Y;
        float wh = CMD_BUILDING_HEIGHT;
        float dw = CMD_DOOR_WIDTH / 2.0f;
        float cw = WALL_WIDTH / 2.0f;
        float cd = WALL_DEPTH / 2.0f;
        float towerTs = TOWER_SIZE / 2.0f;
        float legW = 0.3f;

        // Wall collision array
        float walls[][6] = {
            // Command building walls
            {CMD_BUILDING_X - wallHw - wt, CMD_BUILDING_Z - wallHd - wt, CMD_BUILDING_X + wallHw + wt, CMD_BUILDING_Z - wallHd, fy, fy + wh},
            {CMD_BUILDING_X - wallHw - wt, CMD_BUILDING_Z - wallHd, CMD_BUILDING_X - wallHw, CMD_BUILDING_Z + wallHd + wt, fy, fy + wh},
            {CMD_BUILDING_X + wallHw, CMD_BUILDING_Z - wallHd, CMD_BUILDING_X + wallHw + wt, CMD_BUILDING_Z + wallHd + wt, fy, fy + wh},
            {CMD_BUILDING_X - wallHw, CMD_BUILDING_Z + wallHd, CMD_BUILDING_X - dw, CMD_BUILDING_Z + wallHd + wt, fy, fy + wh},
            {CMD_BUILDING_X + dw, CMD_BUILDING_Z + wallHd, CMD_BUILDING_X + wallHw, CMD_BUILDING_Z + wallHd + wt, fy, fy + wh},
            {CMD_BUILDING_X - dw, CMD_BUILDING_Z + wallHd, CMD_BUILDING_X + dw, CMD_BUILDING_Z + wallHd + wt, fy + CMD_DOOR_HEIGHT, fy + wh},
            // Legacy cover walls
            {WALL1_X - cw, WALL1_Z - cd, WALL1_X + cw, WALL1_Z + cd, fy, fy + WALL_HEIGHT},
            {WALL2_X - cw, WALL2_Z - cd, WALL2_X + cw, WALL2_Z + cd, fy, fy + WALL_HEIGHT},
            // Tower legs (16 total)
            {TOWER_OFFSET - towerTs, TOWER_OFFSET - towerTs, TOWER_OFFSET - towerTs + legW, TOWER_OFFSET - towerTs + legW, fy, PLATFORM_LEVEL},
            {TOWER_OFFSET + towerTs - legW, TOWER_OFFSET - towerTs, TOWER_OFFSET + towerTs, TOWER_OFFSET - towerTs + legW, fy, PLATFORM_LEVEL},
            {TOWER_OFFSET - towerTs, TOWER_OFFSET + towerTs - legW, TOWER_OFFSET - towerTs + legW, TOWER_OFFSET + towerTs, fy, PLATFORM_LEVEL},
            {TOWER_OFFSET + towerTs - legW, TOWER_OFFSET + towerTs - legW, TOWER_OFFSET + towerTs, TOWER_OFFSET + towerTs, fy, PLATFORM_LEVEL},
            {-TOWER_OFFSET - towerTs, TOWER_OFFSET - towerTs, -TOWER_OFFSET - towerTs + legW, TOWER_OFFSET - towerTs + legW, fy, PLATFORM_LEVEL},
            {-TOWER_OFFSET + towerTs - legW, TOWER_OFFSET - towerTs, -TOWER_OFFSET + towerTs, TOWER_OFFSET - towerTs + legW, fy, PLATFORM_LEVEL},
            {-TOWER_OFFSET - towerTs, TOWER_OFFSET + towerTs - legW, -TOWER_OFFSET - towerTs + legW, TOWER_OFFSET + towerTs, fy, PLATFORM_LEVEL},
            {-TOWER_OFFSET + towerTs - legW, TOWER_OFFSET + towerTs - legW, -TOWER_OFFSET + towerTs, TOWER_OFFSET + towerTs, fy, PLATFORM_LEVEL},
            {-TOWER_OFFSET - towerTs, -TOWER_OFFSET - towerTs, -TOWER_OFFSET - towerTs + legW, -TOWER_OFFSET - towerTs + legW, fy, PLATFORM_LEVEL},
            {-TOWER_OFFSET + towerTs - legW, -TOWER_OFFSET - towerTs, -TOWER_OFFSET + towerTs, -TOWER_OFFSET - towerTs + legW, fy, PLATFORM_LEVEL},
            {-TOWER_OFFSET - towerTs, -TOWER_OFFSET + towerTs - legW, -TOWER_OFFSET - towerTs + legW, -TOWER_OFFSET + towerTs, fy, PLATFORM_LEVEL},
            {-TOWER_OFFSET + towerTs - legW, -TOWER_OFFSET + towerTs - legW, -TOWER_OFFSET + towerTs, -TOWER_OFFSET + towerTs, fy, PLATFORM_LEVEL},
            {TOWER_OFFSET - towerTs, -TOWER_OFFSET - towerTs, TOWER_OFFSET - towerTs + legW, -TOWER_OFFSET - towerTs + legW, fy, PLATFORM_LEVEL},
            {TOWER_OFFSET + towerTs - legW, -TOWER_OFFSET - towerTs, TOWER_OFFSET + towerTs, -TOWER_OFFSET - towerTs + legW, fy, PLATFORM_LEVEL},
            {TOWER_OFFSET - towerTs, -TOWER_OFFSET + towerTs - legW, TOWER_OFFSET - towerTs + legW, -TOWER_OFFSET + towerTs, fy, PLATFORM_LEVEL},
            {TOWER_OFFSET + towerTs - legW, -TOWER_OFFSET + towerTs - legW, TOWER_OFFSET + towerTs, -TOWER_OFFSET + towerTs, fy, PLATFORM_LEVEL},
            // Cargo containers
            {8.0f - CONTAINER_LENGTH/2, 4.0f - CONTAINER_WIDTH/2, 8.0f + CONTAINER_LENGTH/2, 4.0f + CONTAINER_WIDTH/2, fy, fy + CONTAINER_HEIGHT},
            {8.5f - CONTAINER_WIDTH/2, 6.5f - CONTAINER_LENGTH/2, 8.5f + CONTAINER_WIDTH/2, 6.5f + CONTAINER_LENGTH/2, fy, fy + CONTAINER_HEIGHT},
            {-8.0f - CONTAINER_LENGTH/2, 4.0f - CONTAINER_WIDTH/2, -8.0f + CONTAINER_LENGTH/2, 4.0f + CONTAINER_WIDTH/2, fy, fy + CONTAINER_HEIGHT},
            {-8.5f - CONTAINER_WIDTH/2, 6.5f - CONTAINER_LENGTH/2, -8.5f + CONTAINER_WIDTH/2, 6.5f + CONTAINER_LENGTH/2, fy, fy + CONTAINER_HEIGHT},
            {6.0f - CONTAINER_WIDTH/2, -8.0f - CONTAINER_LENGTH/2, 6.0f + CONTAINER_WIDTH/2, -8.0f + CONTAINER_LENGTH/2, fy, fy + CONTAINER_HEIGHT},
            {-6.0f - CONTAINER_WIDTH/2, -8.0f - CONTAINER_LENGTH/2, -6.0f + CONTAINER_WIDTH/2, -8.0f + CONTAINER_LENGTH/2, fy, fy + CONTAINER_HEIGHT},
            {0.0f - CONTAINER_LENGTH/2, -12.0f - CONTAINER_WIDTH/2, 0.0f + CONTAINER_LENGTH/2, -12.0f + CONTAINER_WIDTH/2, fy, fy + CONTAINER_HEIGHT},
            {12.0f - CONTAINER_WIDTH/2, 0.0f - CONTAINER_LENGTH/2, 12.0f + CONTAINER_WIDTH/2, 0.0f + CONTAINER_LENGTH/2, fy, fy + CONTAINER_HEIGHT},
            {8.0f - CONTAINER_LENGTH/2, 4.0f - CONTAINER_WIDTH/2, 8.0f + CONTAINER_LENGTH/2, 4.0f + CONTAINER_WIDTH/2, fy + CONTAINER_HEIGHT, fy + CONTAINER_HEIGHT * 2},
            // Sandbag walls
            {5.0f - SANDBAG_LENGTH/2, 4.0f - SANDBAG_THICK/2, 5.0f + SANDBAG_LENGTH/2, 4.0f + SANDBAG_THICK/2, fy, fy + SANDBAG_HEIGHT},
            {-5.0f - SANDBAG_LENGTH/2, 4.0f - SANDBAG_THICK/2, -5.0f + SANDBAG_LENGTH/2, 4.0f + SANDBAG_THICK/2, fy, fy + SANDBAG_HEIGHT},
            {5.0f - SANDBAG_LENGTH/2, -4.0f - SANDBAG_THICK/2, 5.0f + SANDBAG_LENGTH/2, -4.0f + SANDBAG_THICK/2, fy, fy + SANDBAG_HEIGHT},
            {-5.0f - SANDBAG_LENGTH/2, -4.0f - SANDBAG_THICK/2, -5.0f + SANDBAG_LENGTH/2, -4.0f + SANDBAG_THICK/2, fy, fy + SANDBAG_HEIGHT},
            {12.0f - SANDBAG_THICK/2, 10.0f - SANDBAG_LENGTH/2, 12.0f + SANDBAG_THICK/2, 10.0f + SANDBAG_LENGTH/2, fy, fy + SANDBAG_HEIGHT},
            {-12.0f - SANDBAG_THICK/2, 10.0f - SANDBAG_LENGTH/2, -12.0f + SANDBAG_THICK/2, 10.0f + SANDBAG_LENGTH/2, fy, fy + SANDBAG_HEIGHT},
            {12.0f - SANDBAG_THICK/2, -10.0f - SANDBAG_LENGTH/2, 12.0f + SANDBAG_THICK/2, -10.0f + SANDBAG_LENGTH/2, fy, fy + SANDBAG_HEIGHT},
            {-12.0f - SANDBAG_THICK/2, -10.0f - SANDBAG_LENGTH/2, -12.0f + SANDBAG_THICK/2, -10.0f + SANDBAG_LENGTH/2, fy, fy + SANDBAG_HEIGHT},
            {3.0f - SANDBAG_THICK/2, 8.0f - SANDBAG_LENGTH/2, 3.0f + SANDBAG_THICK/2, 8.0f + SANDBAG_LENGTH/2, fy, fy + SANDBAG_HEIGHT},
            {-3.0f - SANDBAG_THICK/2, 8.0f - SANDBAG_LENGTH/2, -3.0f + SANDBAG_THICK/2, 8.0f + SANDBAG_LENGTH/2, fy, fy + SANDBAG_HEIGHT},
            // Arena boundaries
            {-ARENA_SIZE - 0.5f, -ARENA_SIZE - 0.5f, -ARENA_SIZE, ARENA_SIZE + 0.5f, fy, fy + 10.0f},
            {ARENA_SIZE, -ARENA_SIZE - 0.5f, ARENA_SIZE + 0.5f, ARENA_SIZE + 0.5f, fy, fy + 10.0f},
            {-ARENA_SIZE - 0.5f, -ARENA_SIZE - 0.5f, ARENA_SIZE + 0.5f, -ARENA_SIZE, fy, fy + 10.0f},
            {-ARENA_SIZE - 0.5f, ARENA_SIZE, ARENA_SIZE + 0.5f, ARENA_SIZE + 0.5f, fy, fy + 10.0f},
            // Bunker walls
            {BUNKER_X - BUNKER_STAIR_WIDTH/2 - 0.4f, BUNKER_Z + BUNKER_DEPTH/2 - 0.4f, BUNKER_X - BUNKER_STAIR_WIDTH/2, BUNKER_Z + BUNKER_DEPTH/2, fy, fy + 1.0f},
            {BUNKER_X + BUNKER_STAIR_WIDTH/2, BUNKER_Z + BUNKER_DEPTH/2 - 0.4f, BUNKER_X + BUNKER_STAIR_WIDTH/2 + 0.4f, BUNKER_Z + BUNKER_DEPTH/2, fy, fy + 1.0f},
            {BUNKER_X - BUNKER_WIDTH/2 + 0.4f, BUNKER_Z - BUNKER_DEPTH/2 + 0.4f, BUNKER_X + BUNKER_WIDTH/2 - 0.4f, BUNKER_Z - BUNKER_DEPTH/2 + 0.5f, BASEMENT_LEVEL, fy},
            {BUNKER_X - BUNKER_WIDTH/2 + 0.4f, BUNKER_Z - BUNKER_DEPTH/2 + 0.4f, BUNKER_X - BUNKER_WIDTH/2 + 0.5f, BUNKER_Z + BUNKER_DEPTH/2 - 0.4f, BASEMENT_LEVEL, fy},
            {BUNKER_X + BUNKER_WIDTH/2 - 0.5f, BUNKER_Z - BUNKER_DEPTH/2 + 0.4f, BUNKER_X + BUNKER_WIDTH/2 - 0.4f, BUNKER_Z + BUNKER_DEPTH/2 - 0.4f, BASEMENT_LEVEL, fy},
            {BUNKER_X - BUNKER_WIDTH/2 + 0.4f, BUNKER_Z + BUNKER_DEPTH/2 - 0.5f, BUNKER_X - BUNKER_STAIR_WIDTH/2, BUNKER_Z + BUNKER_DEPTH/2 - 0.4f, BASEMENT_LEVEL, fy},
            {BUNKER_X + BUNKER_STAIR_WIDTH/2, BUNKER_Z + BUNKER_DEPTH/2 - 0.5f, BUNKER_X + BUNKER_WIDTH/2 - 0.4f, BUNKER_Z + BUNKER_DEPTH/2 - 0.4f, BASEMENT_LEVEL, fy},
        };
        int numWalls = 54;

        // Add door collision
        simd_float3 doorMin, doorMax;
        getDoorAABB(&doorMin, &doorMax);
        float doorWall[6] = {doorMin.x, doorMin.z, doorMax.x, doorMax.z, doorMin.y, doorMax.y};

        // Iterate through walls with improved collision resolution
        // Multiple iterations help resolve corner cases
        for (int iter = 0; iter < 2; iter++) {
            px = _metalView.posX;
            py = _metalView.posY;
            pz = _metalView.posZ;
            feetY = py - PLAYER_HEIGHT;
            headY = py + 0.1f;

            for (int i = 0; i < numWalls + 1; i++) {
                float *w = (i < numWalls) ? walls[i] : doorWall;
                float xMin = w[0], zMin = w[1], xMax = w[2], zMax = w[3], yMin = w[4], yMax = w[5];

                // Check AABB overlap with player cylinder approximated as box
                BOOL xOv = px > xMin - PLAYER_RADIUS && px < xMax + PLAYER_RADIUS;
                BOOL zOv = pz > zMin - PLAYER_RADIUS && pz < zMax + PLAYER_RADIUS;
                BOOL yOv = feetY < yMax && headY > yMin;

                if (xOv && zOv && yOv) {
                    // Calculate penetration on each axis
                    float penLeft = px - (xMin - PLAYER_RADIUS);
                    float penRight = (xMax + PLAYER_RADIUS) - px;
                    float penBack = pz - (zMin - PLAYER_RADIUS);
                    float penFront = (zMax + PLAYER_RADIUS) - pz;
                    float penDown = headY - yMin;  // How much head is inside from bottom
                    float penUp = yMax - feetY;    // How much feet are inside from top

                    float minPenX = fminf(penLeft, penRight);
                    float minPenZ = fminf(penBack, penFront);
                    float minPenY = fminf(penDown, penUp);

                    // Find smallest penetration axis to resolve
                    // Prioritize Y resolution to prevent getting stuck on platform edges
                    if (minPenY < minPenX && minPenY < minPenZ) {
                        // Resolve on Y axis
                        if (penDown < penUp) {
                            // Push down (hit head on ceiling/platform bottom)
                            _metalView.posY -= penDown;
                            if (_metalView.velocityY > 0) _metalView.velocityY = 0;
                        } else {
                            // Push up (shouldn't happen often since ground handles this)
                            _metalView.posY += penUp - PLAYER_HEIGHT;
                            if (_metalView.velocityY < 0) {
                                _metalView.velocityY = 0;
                                _metalView.onGround = YES;
                            }
                        }
                    } else if (minPenX < minPenZ) {
                        // Resolve on X axis
                        _metalView.posX += (penLeft < penRight) ? -penLeft : penRight;
                        _metalView.velocityX = 0;
                    } else {
                        // Resolve on Z axis
                        _metalView.posZ += (penBack < penFront) ? -penBack : penFront;
                        _metalView.velocityZ = 0;
                    }

                    // Update cached position
                    px = _metalView.posX;
                    py = _metalView.posY;
                    pz = _metalView.posZ;
                    feetY = py - PLAYER_HEIGHT;
                    headY = py + 0.1f;
                }
            }
        }

        // --- Head collision for platforms (prevent jumping through from below) ---
        // Check tower platforms from below
        for (int t = 0; t < 4; t++) {
            float tx = towerPositions[t][0];
            float tz = towerPositions[t][1];
            float platBottom = PLATFORM_LEVEL - CATWALK_THICK;

            if (px > tx - platHalfSize && px < tx + platHalfSize &&
                pz > tz - platHalfSize && pz < tz + platHalfSize) {
                if (headY > platBottom && feetY < PLATFORM_LEVEL && _metalView.velocityY > 0) {
                    _metalView.posY = platBottom - 0.1f;
                    _metalView.velocityY = 0;
                }
            }
        }

        // Check catwalks from below
        float catwalkBottom = PLATFORM_LEVEL - CATWALK_THICK;
        // North catwalk
        if (px > -TOWER_OFFSET + TOWER_SIZE/2 && px < TOWER_OFFSET - TOWER_SIZE/2 &&
            pz > TOWER_OFFSET - CATWALK_WIDTH/2 && pz < TOWER_OFFSET + CATWALK_WIDTH/2) {
            if (headY > catwalkBottom && feetY < PLATFORM_LEVEL && _metalView.velocityY > 0) {
                _metalView.posY = catwalkBottom - 0.1f;
                _metalView.velocityY = 0;
            }
        }
        // South catwalk
        if (px > -TOWER_OFFSET + TOWER_SIZE/2 && px < TOWER_OFFSET - TOWER_SIZE/2 &&
            pz > -TOWER_OFFSET - CATWALK_WIDTH/2 && pz < -TOWER_OFFSET + CATWALK_WIDTH/2) {
            if (headY > catwalkBottom && feetY < PLATFORM_LEVEL && _metalView.velocityY > 0) {
                _metalView.posY = catwalkBottom - 0.1f;
                _metalView.velocityY = 0;
            }
        }
        // East catwalk
        if (px > TOWER_OFFSET - CATWALK_WIDTH/2 && px < TOWER_OFFSET + CATWALK_WIDTH/2 &&
            pz > -TOWER_OFFSET + TOWER_SIZE/2 && pz < TOWER_OFFSET - TOWER_SIZE/2) {
            if (headY > catwalkBottom && feetY < PLATFORM_LEVEL && _metalView.velocityY > 0) {
                _metalView.posY = catwalkBottom - 0.1f;
                _metalView.velocityY = 0;
            }
        }
        // West catwalk
        if (px > -TOWER_OFFSET - CATWALK_WIDTH/2 && px < -TOWER_OFFSET + CATWALK_WIDTH/2 &&
            pz > -TOWER_OFFSET + TOWER_SIZE/2 && pz < TOWER_OFFSET - TOWER_SIZE/2) {
            if (headY > catwalkBottom && feetY < PLATFORM_LEVEL && _metalView.velocityY > 0) {
                _metalView.posY = catwalkBottom - 0.1f;
                _metalView.velocityY = 0;
            }
        }

        // --- Footstep sounds ---
        float currentSpeed = sqrtf(_metalView.velocityX * _metalView.velocityX +
                                   _metalView.velocityZ * _metalView.velocityZ);
        if (_metalView.onGround && currentSpeed > 0.03f) {
            state.footstepTimer++;
            if (state.footstepTimer >= 20) {
                state.footstepTimer = 0;
                [[SoundManager shared] playFootstepSound];
            }
        } else {
            state.footstepTimer = 12;
        }

    } // End of physics/collision block

    simd_float3 camPos = {_metalView.posX, _metalView.posY, _metalView.posZ};

    // Update door proximity
    state.playerNearDoor = checkPlayerNearDoor(camPos);

    // Skip all game logic updates when paused
    if (!state.isPaused) {
        // Animate door
        updateDoorAnimation();

        // Gun recoil decay
        if (_metalView.gunRecoil > 0) {
            _metalView.gunRecoil *= 0.85f;
            if (_metalView.gunRecoil < 0.01f) _metalView.gunRecoil = 0;
        }

        // Fire rate
        if (_metalView.fireTimer > 0) _metalView.fireTimer--;

        // Handle shooting
        BOOL shouldFire = _metalView.wantsClick || (_metalView.mouseHeld && _metalView.fireTimer == 0);
        _metalView.wantsClick = NO;

        if (shouldFire && _metalView.controlsActive && !state.gameOver) {
            _metalView.fireTimer = PLAYER_FIRE_RATE;
            _metalView.gunRecoil = 0.6f;
            CombatHitResult hitResult = processPlayerShooting(camPos, _metalView.camYaw, _metalView.camPitch);

            // In multiplayer, send hit notification if we hit the remote player
            if (state.isMultiplayer && hitResult.type == HitResultRemotePlayer) {
                [[MultiplayerController shared] sendHitOnRemotePlayer:PVP_DAMAGE];
            }
        }

        // Enemy AI
        updateEnemyAI(camPos, _metalView.controlsActive);

        // Update pickup system
        PickupSystem *pickupSystem = [PickupSystem shared];
        [pickupSystem updatePickups:1.0f];  // 1 frame delta

        // Check for pickup collection
        if (!state.gameOver) {
            [pickupSystem checkPlayerPickup:camPos];
        }

        // Update timers
        updateCombatTimers();
        updateHealthRegeneration();
    }

    // Build matrices
    CameraBasis camBasis = computeCameraBasis(_metalView.camYaw, _metalView.camPitch);
    float camX = _metalView.posX, camY = _metalView.posY, camZ = _metalView.posZ;
    float fx = camBasis.forward.x, fy = camBasis.forward.y, fz = camBasis.forward.z;
    float rx = camBasis.right.x, ry = camBasis.right.y, rz = camBasis.right.z;
    float ux = camBasis.up.x, uy = camBasis.up.y, uz = camBasis.up.z;

    simd_float4x4 viewMat = {{
        {rx, ux, -fx, 0}, {ry, uy, -fy, 0}, {rz, uz, -fz, 0},
        {-(rx*camX + ry*camY + rz*camZ), -(ux*camX + uy*camY + uz*camZ), -(-fx*camX + -fy*camY + -fz*camZ), 1}
    }};

    float f = 1.0f / tanf(FOV / 2.0f);
    simd_float4x4 proj = {{
        {f / ASPECT_RATIO, 0, 0, 0}, {0, f, 0, 0},
        {0, 0, (FAR_PLANE + NEAR_PLANE) / (NEAR_PLANE - FAR_PLANE), -1},
        {0, 0, (2 * FAR_PLANE * NEAR_PLANE) / (NEAR_PLANE - FAR_PLANE), 0}
    }};

    simd_float4x4 mvp = simd_mul(proj, viewMat);

    id<MTLCommandBuffer> commandBuffer = [_commandQueue commandBuffer];
    id<MTLRenderCommandEncoder> encoder = [commandBuffer renderCommandEncoderWithDescriptor:passDescriptor];

    // Draw background
    [encoder setRenderPipelineState:_bgPipelineState];
    [encoder setDepthStencilState:_bgDepthState];
    [encoder setVertexBuffer:_bgVertexBuffer offset:0 atIndex:0];
    [encoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:6];

    // Draw military base floor
    [encoder setRenderPipelineState:_pipelineState];
    [encoder setDepthStencilState:_depthState];
    [encoder setVertexBuffer:_militaryFloorBuffer offset:0 atIndex:0];
    [encoder setVertexBytes:&mvp length:sizeof(mvp) atIndex:1];
    [encoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:_militaryFloorVertexCount];

    // Draw command building (central structure)
    [encoder setVertexBuffer:_commandBuildingBuffer offset:0 atIndex:0];
    [encoder setVertexBytes:&mvp length:sizeof(mvp) atIndex:1];
    [encoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:_commandBuildingVertexCount];

    // Draw guard towers (4 corners)
    [encoder setVertexBuffer:_guardTowerBuffer offset:0 atIndex:0];
    [encoder setVertexBytes:&mvp length:sizeof(mvp) atIndex:1];
    [encoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:_guardTowerVertexCount];

    // Draw catwalks (connecting towers)
    [encoder setVertexBuffer:_catwalkBuffer offset:0 atIndex:0];
    [encoder setVertexBytes:&mvp length:sizeof(mvp) atIndex:1];
    [encoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:_catwalkVertexCount];

    // Draw underground bunker
    [encoder setVertexBuffer:_bunkerBuffer offset:0 atIndex:0];
    [encoder setVertexBytes:&mvp length:sizeof(mvp) atIndex:1];
    [encoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:_bunkerVertexCount];

    // Draw cargo containers
    [encoder setVertexBuffer:_cargoContainersBuffer offset:0 atIndex:0];
    [encoder setVertexBytes:&mvp length:sizeof(mvp) atIndex:1];
    [encoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:_cargoContainersVertexCount];

    // Draw sandbag walls
    [encoder setVertexBuffer:_sandbagBuffer offset:0 atIndex:0];
    [encoder setVertexBytes:&mvp length:sizeof(mvp) atIndex:1];
    [encoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:_sandbagVertexCount];

    // Draw door
    {
        float doorHingeX = HOUSE_X - DOOR_WIDTH / 2.0f;
        float doorHingeZ = HOUSE_Z + HOUSE_DEPTH / 2.0f + HOUSE_WALL_THICK / 2.0f;
        float doorY = FLOOR_Y;
        float angleRad = state.doorAngle * M_PI / 180.0f;
        float cosA = cosf(angleRad), sinA = sinf(angleRad);

        simd_float4x4 doorModel = {{
            {cosA, 0, sinA, 0}, {0, 1, 0, 0}, {-sinA, 0, cosA, 0}, {doorHingeX, doorY, doorHingeZ, 1}
        }};
        simd_float4x4 doorMvp = simd_mul(proj, simd_mul(viewMat, doorModel));

        [encoder setVertexBuffer:_doorBuffer offset:0 atIndex:0];
        [encoder setVertexBytes:&doorMvp length:sizeof(doorMvp) atIndex:1];
        [encoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:_doorVertexCount];
    }

    // Draw walls
    [encoder setVertexBuffer:_wall1Buffer offset:0 atIndex:0];
    [encoder setVertexBytes:&mvp length:sizeof(mvp) atIndex:1];
    [encoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:36];
    [encoder setVertexBuffer:_wall2Buffer offset:0 atIndex:0];
    [encoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:36];

    // Draw pickups
    {
        int pickupCount = [[PickupSystem shared] getPickupCount];
        for (int p = 0; p < pickupCount; p++) {
            Pickup *pickup = [[PickupSystem shared] getPickup:p];
            if (!pickup || !pickup->isActive) continue;

            // Calculate pickup position with bob offset
            float px = pickup->x;
            float py = pickup->y + pickup->bobOffset;
            float pz = pickup->z;
            float angle = pickup->rotationAngle;

            // Create rotation and translation matrix
            float cosA = cosf(angle);
            float sinA = sinf(angle);
            float scale = 1.0f;

            simd_float4x4 pickupRot = {{
                {cosA * scale, 0, -sinA * scale, 0},
                {0, scale, 0, 0},
                {sinA * scale, 0, cosA * scale, 0},
                {0, 0, 0, 1}
            }};
            simd_float4x4 pickupTrans = {{
                {1, 0, 0, 0}, {0, 1, 0, 0}, {0, 0, 1, 0}, {px, py, pz, 1}
            }};
            simd_float4x4 pickupModel = simd_mul(pickupTrans, pickupRot);
            simd_float4x4 pickupMvp = simd_mul(proj, simd_mul(viewMat, pickupModel));

            // Select the appropriate buffer based on pickup type
            id<MTLBuffer> pickupBuffer = nil;
            NSUInteger vertexCount = 0;

            switch (pickup->type) {
                case PickupTypeHealthPack:
                    pickupBuffer = _healthPackBuffer;
                    vertexCount = _healthPackVertexCount;
                    break;
                case PickupTypeAmmoSmall:
                case PickupTypeAmmoHeavy:
                    pickupBuffer = _ammoBoxBuffer;
                    vertexCount = _ammoBoxVertexCount;
                    break;
                case PickupTypeShotgun:
                case PickupTypeAssaultRifle:
                case PickupTypeRocketLauncher:
                    pickupBuffer = _weaponPickupBuffer;
                    vertexCount = _weaponPickupVertexCount;
                    break;
                case PickupTypeArmor:
                    pickupBuffer = _armorBuffer;
                    vertexCount = _armorVertexCount;
                    break;
            }

            if (pickupBuffer && vertexCount > 0) {
                [encoder setVertexBuffer:pickupBuffer offset:0 atIndex:0];
                [encoder setVertexBytes:&pickupMvp length:sizeof(pickupMvp) atIndex:1];
                [encoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:vertexCount];
            }
        }
    }

    // Draw enemies
    BOOL *enemyAlive = state.enemyAlive;
    int *enemyHealth = state.enemyHealth;
    float *enemyX = state.enemyX;
    float *enemyY = state.enemyY;
    float *enemyZ = state.enemyZ;

    for (int e = 0; e < NUM_ENEMIES; e++) {
        if (!enemyAlive[e]) continue;

        float edx = camPos.x - enemyX[e];
        float edz = camPos.z - enemyZ[e];
        float enemyYaw = atan2f(edx, edz);
        float cosE = cosf(enemyYaw), sinE = sinf(enemyYaw);
        float enemyScale = 1.4f;

        simd_float4x4 enemyRot = {{
            {cosE * enemyScale, 0, -sinE * enemyScale, 0}, {0, enemyScale, 0, 0},
            {sinE * enemyScale, 0, cosE * enemyScale, 0}, {0, 0, 0, 1}
        }};
        simd_float4x4 enemyTrans = {{
            {1, 0, 0, 0}, {0, 1, 0, 0}, {0, 0, 1, 0}, {enemyX[e], enemyY[e], enemyZ[e], 1}
        }};
        simd_float4x4 enemyModel = simd_mul(enemyTrans, enemyRot);
        simd_float4x4 enemyMvp = simd_mul(proj, simd_mul(viewMat, enemyModel));

        [encoder setVertexBuffer:_enemyVertexBuffer offset:0 atIndex:0];
        [encoder setVertexBytes:&enemyMvp length:sizeof(enemyMvp) atIndex:1];
        [encoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:_enemyVertexCount];

        // Check if enemy is visible (not behind walls) before drawing health bar
        simd_float3 enemyPos = {enemyX[e], enemyY[e] + 0.5f, enemyZ[e]};
        simd_float3 toEnemy = enemyPos - camPos;
        float enemyDist = simd_length(toEnemy);
        simd_float3 enemyDir = toEnemy / enemyDist;
        BOOL enemyVisible = YES;

        // Check against cover walls
        float cw = WALL_WIDTH / 2.0f;
        float ch = WALL_HEIGHT / 2.0f;
        float cd = WALL_DEPTH / 2.0f;
        simd_float3 w1Min = {WALL1_X - cw, FLOOR_Y, WALL1_Z - cd};
        simd_float3 w1Max = {WALL1_X + cw, FLOOR_Y + WALL_HEIGHT, WALL1_Z + cd};
        RayHitResult w1Hit = rayIntersectAABB(camPos, enemyDir, w1Min, w1Max);
        if (w1Hit.hit && w1Hit.t > 0 && w1Hit.t < enemyDist) enemyVisible = NO;

        simd_float3 w2Min = {WALL2_X - cw, FLOOR_Y, WALL2_Z - cd};
        simd_float3 w2Max = {WALL2_X + cw, FLOOR_Y + WALL_HEIGHT, WALL2_Z + cd};
        RayHitResult w2Hit = rayIntersectAABB(camPos, enemyDir, w2Min, w2Max);
        if (w2Hit.hit && w2Hit.t > 0 && w2Hit.t < enemyDist) enemyVisible = NO;

        // Check against house walls
        float hw = HOUSE_WIDTH / 2.0f;
        float hd = HOUSE_DEPTH / 2.0f;
        float wt = HOUSE_WALL_THICK;
        float wh = HOUSE_WALL_HEIGHT;
        float dw = DOOR_WIDTH / 2.0f;

        simd_float3 backMin = {HOUSE_X - hw - wt, FLOOR_Y, HOUSE_Z - hd - wt};
        simd_float3 backMax = {HOUSE_X + hw + wt, FLOOR_Y + wh, HOUSE_Z - hd};
        RayHitResult backHit = rayIntersectAABB(camPos, enemyDir, backMin, backMax);
        if (backHit.hit && backHit.t > 0 && backHit.t < enemyDist) enemyVisible = NO;

        simd_float3 leftMin = {HOUSE_X - hw - wt, FLOOR_Y, HOUSE_Z - hd};
        simd_float3 leftMax = {HOUSE_X - hw, FLOOR_Y + wh, HOUSE_Z + hd + wt};
        RayHitResult leftHit = rayIntersectAABB(camPos, enemyDir, leftMin, leftMax);
        if (leftHit.hit && leftHit.t > 0 && leftHit.t < enemyDist) enemyVisible = NO;

        simd_float3 rightMin = {HOUSE_X + hw, FLOOR_Y, HOUSE_Z - hd};
        simd_float3 rightMax = {HOUSE_X + hw + wt, FLOOR_Y + wh, HOUSE_Z + hd + wt};
        RayHitResult rightHit = rayIntersectAABB(camPos, enemyDir, rightMin, rightMax);
        if (rightHit.hit && rightHit.t > 0 && rightHit.t < enemyDist) enemyVisible = NO;

        simd_float3 frontLeftMin = {HOUSE_X - hw, FLOOR_Y, HOUSE_Z + hd};
        simd_float3 frontLeftMax = {HOUSE_X - dw, FLOOR_Y + wh, HOUSE_Z + hd + wt};
        RayHitResult frontLeftHit = rayIntersectAABB(camPos, enemyDir, frontLeftMin, frontLeftMax);
        if (frontLeftHit.hit && frontLeftHit.t > 0 && frontLeftHit.t < enemyDist) enemyVisible = NO;

        simd_float3 frontRightMin = {HOUSE_X + dw, FLOOR_Y, HOUSE_Z + hd};
        simd_float3 frontRightMax = {HOUSE_X + hw, FLOOR_Y + wh, HOUSE_Z + hd + wt};
        RayHitResult frontRightHit = rayIntersectAABB(camPos, enemyDir, frontRightMin, frontRightMax);
        if (frontRightHit.hit && frontRightHit.t > 0 && frontRightHit.t < enemyDist) enemyVisible = NO;

        simd_float3 aboveDoorMin = {HOUSE_X - dw, FLOOR_Y + DOOR_HEIGHT, HOUSE_Z + hd};
        simd_float3 aboveDoorMax = {HOUSE_X + dw, FLOOR_Y + wh, HOUSE_Z + hd + wt};
        RayHitResult aboveDoorHit = rayIntersectAABB(camPos, enemyDir, aboveDoorMin, aboveDoorMax);
        if (aboveDoorHit.hit && aboveDoorHit.t > 0 && aboveDoorHit.t < enemyDist) enemyVisible = NO;

        // Check against door
        simd_float3 doorMin, doorMax;
        getDoorAABB(&doorMin, &doorMax);
        RayHitResult doorHit = rayIntersectAABB(camPos, enemyDir, doorMin, doorMax);
        if (doorHit.hit && doorHit.t > 0 && doorHit.t < enemyDist) enemyVisible = NO;

        // Only draw health bar if enemy is visible
        if (enemyVisible) {
            float hbY = enemyY[e] + 1.3f;
            simd_float4x4 hbModel = {{
                {rx, ry, rz, 0}, {ux, uy, uz, 0}, {-fx, -fy, -fz, 0}, {enemyX[e], hbY, enemyZ[e], 1}
            }};
            simd_float4x4 hbMvp = simd_mul(proj, simd_mul(viewMat, hbModel));

            [encoder setVertexBuffer:_healthBarBgBuffer offset:0 atIndex:0];
            [encoder setVertexBytes:&hbMvp length:sizeof(hbMvp) atIndex:1];
            [encoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:6];

            float healthPct = (float)enemyHealth[e] / (float)ENEMY_MAX_HEALTH;
            float barHalfWidth = 0.28f;
            float offsetX = -barHalfWidth * (1.0f - healthPct);
            simd_float4x4 hbFgModel = {{
                {rx * healthPct, ry * healthPct, rz * healthPct, 0}, {ux, uy, uz, 0}, {-fx, -fy, -fz, 0},
                {enemyX[e] + rx * offsetX, hbY + ry * offsetX, enemyZ[e] + rz * offsetX, 1}
            }};
            simd_float4x4 hbFgMvp = simd_mul(proj, simd_mul(viewMat, hbFgModel));

            [encoder setDepthStencilState:_bgDepthState];
            [encoder setVertexBuffer:_healthBarFgBuffer offset:0 atIndex:0];
            [encoder setVertexBytes:&hbFgMvp length:sizeof(hbFgMvp) atIndex:1];
            [encoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:6];
            [encoder setDepthStencilState:_depthState];
        }
    }

    // Draw remote player in multiplayer mode
    if (state.isMultiplayer && state.isConnected && state.remotePlayerAlive) {
        float rpX = state.remotePlayerPosX;
        float rpY = state.remotePlayerPosY;
        float rpZ = state.remotePlayerPosZ;
        float rpYaw = state.remotePlayerCamYaw;

        float cosRP = cosf(rpYaw);
        float sinRP = sinf(rpYaw);
        float playerScale = 1.4f;

        simd_float4x4 rpRot = {{
            {cosRP * playerScale, 0, -sinRP * playerScale, 0}, {0, playerScale, 0, 0},
            {sinRP * playerScale, 0, cosRP * playerScale, 0}, {0, 0, 0, 1}
        }};
        simd_float4x4 rpTrans = {{
            {1, 0, 0, 0}, {0, 1, 0, 0}, {0, 0, 1, 0}, {rpX, rpY, rpZ, 1}
        }};
        simd_float4x4 rpModel = simd_mul(rpTrans, rpRot);
        simd_float4x4 rpMvp = simd_mul(proj, simd_mul(viewMat, rpModel));

        [encoder setVertexBuffer:_remotePlayerBuffer offset:0 atIndex:0];
        [encoder setVertexBytes:&rpMvp length:sizeof(rpMvp) atIndex:1];
        [encoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:_remotePlayerVertexCount];

        // Check if remote player is visible (not behind walls) before drawing health bar
        simd_float3 rpPos = {rpX, rpY + 0.5f, rpZ};
        simd_float3 toRP = rpPos - camPos;
        float rpDist = simd_length(toRP);
        simd_float3 rpDir = toRP / rpDist;
        BOOL rpVisible = YES;

        // Check against cover walls
        float cw = WALL_WIDTH / 2.0f;
        float cd = WALL_DEPTH / 2.0f;
        simd_float3 w1Min = {WALL1_X - cw, FLOOR_Y, WALL1_Z - cd};
        simd_float3 w1Max = {WALL1_X + cw, FLOOR_Y + WALL_HEIGHT, WALL1_Z + cd};
        RayHitResult w1Hit = rayIntersectAABB(camPos, rpDir, w1Min, w1Max);
        if (w1Hit.hit && w1Hit.t > 0 && w1Hit.t < rpDist) rpVisible = NO;

        simd_float3 w2Min = {WALL2_X - cw, FLOOR_Y, WALL2_Z - cd};
        simd_float3 w2Max = {WALL2_X + cw, FLOOR_Y + WALL_HEIGHT, WALL2_Z + cd};
        RayHitResult w2Hit = rayIntersectAABB(camPos, rpDir, w2Min, w2Max);
        if (w2Hit.hit && w2Hit.t > 0 && w2Hit.t < rpDist) rpVisible = NO;

        // Check against house walls
        float hw = HOUSE_WIDTH / 2.0f;
        float hd = HOUSE_DEPTH / 2.0f;
        float wt = HOUSE_WALL_THICK;
        float wh = HOUSE_WALL_HEIGHT;
        float dw = DOOR_WIDTH / 2.0f;

        simd_float3 backMin = {HOUSE_X - hw - wt, FLOOR_Y, HOUSE_Z - hd - wt};
        simd_float3 backMax = {HOUSE_X + hw + wt, FLOOR_Y + wh, HOUSE_Z - hd};
        RayHitResult backHit = rayIntersectAABB(camPos, rpDir, backMin, backMax);
        if (backHit.hit && backHit.t > 0 && backHit.t < rpDist) rpVisible = NO;

        simd_float3 leftMin = {HOUSE_X - hw - wt, FLOOR_Y, HOUSE_Z - hd};
        simd_float3 leftMax = {HOUSE_X - hw, FLOOR_Y + wh, HOUSE_Z + hd + wt};
        RayHitResult leftHit = rayIntersectAABB(camPos, rpDir, leftMin, leftMax);
        if (leftHit.hit && leftHit.t > 0 && leftHit.t < rpDist) rpVisible = NO;

        simd_float3 rightMin = {HOUSE_X + hw, FLOOR_Y, HOUSE_Z - hd};
        simd_float3 rightMax = {HOUSE_X + hw + wt, FLOOR_Y + wh, HOUSE_Z + hd + wt};
        RayHitResult rightHit = rayIntersectAABB(camPos, rpDir, rightMin, rightMax);
        if (rightHit.hit && rightHit.t > 0 && rightHit.t < rpDist) rpVisible = NO;

        simd_float3 frontLeftMin = {HOUSE_X - hw, FLOOR_Y, HOUSE_Z + hd};
        simd_float3 frontLeftMax = {HOUSE_X - dw, FLOOR_Y + wh, HOUSE_Z + hd + wt};
        RayHitResult frontLeftHit = rayIntersectAABB(camPos, rpDir, frontLeftMin, frontLeftMax);
        if (frontLeftHit.hit && frontLeftHit.t > 0 && frontLeftHit.t < rpDist) rpVisible = NO;

        simd_float3 frontRightMin = {HOUSE_X + dw, FLOOR_Y, HOUSE_Z + hd};
        simd_float3 frontRightMax = {HOUSE_X + hw, FLOOR_Y + wh, HOUSE_Z + hd + wt};
        RayHitResult frontRightHit = rayIntersectAABB(camPos, rpDir, frontRightMin, frontRightMax);
        if (frontRightHit.hit && frontRightHit.t > 0 && frontRightHit.t < rpDist) rpVisible = NO;

        simd_float3 aboveDoorMin = {HOUSE_X - dw, FLOOR_Y + DOOR_HEIGHT, HOUSE_Z + hd};
        simd_float3 aboveDoorMax = {HOUSE_X + dw, FLOOR_Y + wh, HOUSE_Z + hd + wt};
        RayHitResult aboveDoorHit = rayIntersectAABB(camPos, rpDir, aboveDoorMin, aboveDoorMax);
        if (aboveDoorHit.hit && aboveDoorHit.t > 0 && aboveDoorHit.t < rpDist) rpVisible = NO;

        // Check against door
        simd_float3 doorMin, doorMax;
        getDoorAABB(&doorMin, &doorMax);
        RayHitResult doorHit = rayIntersectAABB(camPos, rpDir, doorMin, doorMax);
        if (doorHit.hit && doorHit.t > 0 && doorHit.t < rpDist) rpVisible = NO;

        // Only draw health bar if remote player is visible
        if (rpVisible) {
            float hbY = rpY + 1.3f;
            simd_float4x4 hbModel = {{
                {rx, ry, rz, 0}, {ux, uy, uz, 0}, {-fx, -fy, -fz, 0}, {rpX, hbY, rpZ, 1}
            }};
            simd_float4x4 hbMvp = simd_mul(proj, simd_mul(viewMat, hbModel));

            [encoder setVertexBuffer:_healthBarBgBuffer offset:0 atIndex:0];
            [encoder setVertexBytes:&hbMvp length:sizeof(hbMvp) atIndex:1];
            [encoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:6];

            float healthPct = (float)state.remotePlayerHealth / (float)PLAYER_MAX_HEALTH;
            float barHalfWidth = 0.28f;
            float offsetX = -barHalfWidth * (1.0f - healthPct);
            simd_float4x4 hbFgModel = {{
                {rx * healthPct, ry * healthPct, rz * healthPct, 0}, {ux, uy, uz, 0}, {-fx, -fy, -fz, 0},
                {rpX + rx * offsetX, hbY + ry * offsetX, rpZ + rz * offsetX, 1}
            }};
            simd_float4x4 hbFgMvp = simd_mul(proj, simd_mul(viewMat, hbFgModel));

            [encoder setDepthStencilState:_bgDepthState];
            [encoder setVertexBuffer:_healthBarFgBuffer offset:0 atIndex:0];
            [encoder setVertexBytes:&hbFgMvp length:sizeof(hbFgMvp) atIndex:1];
            [encoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:6];
            [encoder setDepthStencilState:_depthState];
        }
    }

    // Draw wireframe box
    [encoder setVertexBuffer:_boxLineBuffer offset:0 atIndex:0];
    [encoder setVertexBytes:&mvp length:sizeof(mvp) atIndex:1];
    [encoder drawPrimitives:MTLPrimitiveTypeLine vertexStart:0 vertexCount:_boxLineVertexCount];

    // Draw PAUSED text
    if (_metalView.escapedLock && !state.gameOver) {
        [encoder setRenderPipelineState:_textPipelineState];
        [encoder setDepthStencilState:_bgDepthState];
        [encoder setVertexBuffer:_textVertexBuffer offset:0 atIndex:0];
        [encoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:_textVertexCount];
    }

    // Draw player health bar
    [encoder setRenderPipelineState:_pipelineState];
    [encoder setDepthStencilState:_bgDepthState];
    [encoder setVertexBuffer:_playerHpBgBuffer offset:0 atIndex:0];
    [encoder setVertexBytes:&IDENTITY_MATRIX length:sizeof(IDENTITY_MATRIX) atIndex:1];
    [encoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:6];

    float hpPct = (float)state.playerHealth / (float)PLAYER_MAX_HEALTH;
    float hpOffset = -0.29f * (1.0f - hpPct);
    simd_float4x4 hpScale = {{
        {hpPct,0,0,0}, {0,1,0,0}, {0,0,1,0}, {hpOffset,0,0,1}
    }};
    [encoder setVertexBuffer:_playerHpFgBuffer offset:0 atIndex:0];
    [encoder setVertexBytes:&hpScale length:sizeof(hpScale) atIndex:1];
    [encoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:6];

    // Draw armor bar (below health bar)
    if (state.playerArmor > 0) {
        // Armor bar background (blue-gray)
        simd_float3 armorBgCol = {0.1f, 0.15f, 0.3f};
        float armorY = 0.78f;  // Below health bar
        Vertex armorBg[] = {
            {{-0.3f, armorY, 0}, armorBgCol}, {{0.3f, armorY, 0}, armorBgCol}, {{0.3f, armorY + 0.05f, 0}, armorBgCol},
            {{-0.3f, armorY, 0}, armorBgCol}, {{0.3f, armorY + 0.05f, 0}, armorBgCol}, {{-0.3f, armorY + 0.05f, 0}, armorBgCol},
        };
        id<MTLBuffer> armorBgBuf = [_device newBufferWithBytes:armorBg length:sizeof(armorBg) options:MTLResourceStorageModeShared];
        [encoder setVertexBuffer:armorBgBuf offset:0 atIndex:0];
        [encoder setVertexBytes:&IDENTITY_MATRIX length:sizeof(IDENTITY_MATRIX) atIndex:1];
        [encoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:6];

        // Armor bar foreground (blue)
        simd_float3 armorFgCol = {0.2f, 0.5f, 1.0f};
        float armorPct = (float)state.playerArmor / 100.0f;  // MAX_ARMOR = 100
        Vertex armorFg[] = {
            {{-0.29f, armorY + 0.01f, 0}, armorFgCol}, {{-0.29f + 0.58f * armorPct, armorY + 0.01f, 0}, armorFgCol},
            {{-0.29f + 0.58f * armorPct, armorY + 0.04f, 0}, armorFgCol},
            {{-0.29f, armorY + 0.01f, 0}, armorFgCol}, {{-0.29f + 0.58f * armorPct, armorY + 0.04f, 0}, armorFgCol},
            {{-0.29f, armorY + 0.04f, 0}, armorFgCol},
        };
        id<MTLBuffer> armorFgBuf = [_device newBufferWithBytes:armorFg length:sizeof(armorFg) options:MTLResourceStorageModeShared];
        [encoder setVertexBuffer:armorFgBuf offset:0 atIndex:0];
        [encoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:6];
    }

    // Draw crosshair
    if (!state.gameOver && !_metalView.escapedLock) {
        [encoder setVertexBuffer:_crosshairBuffer offset:0 atIndex:0];
        [encoder setVertexBytes:&IDENTITY_MATRIX length:sizeof(IDENTITY_MATRIX) atIndex:1];
        [encoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:24];
    }

    // Draw E prompt
    if (state.playerNearDoor && !state.gameOver && !_metalView.escapedLock) {
        [encoder setVertexBuffer:_ePromptBuffer offset:0 atIndex:0];
        [encoder setVertexBytes:&IDENTITY_MATRIX length:sizeof(IDENTITY_MATRIX) atIndex:1];
        [encoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:_ePromptVertexCount];
    }

    // Draw Game Over or Multiplayer Win/Lose
    if (state.gameOver) {
        [encoder setRenderPipelineState:_textPipelineState];
        [encoder setDepthStencilState:_bgDepthState];

        if (state.isMultiplayer && state.gameWon) {
            // Draw "YOU WIN!" or "YOU LOSE!" for multiplayer
            #define MAX_WIN_VERTS 600
            Vertex winVerts[MAX_WIN_VERTS];
            int wv = 0;

            BOOL playerWon = (state.winnerId == state.localPlayerId);
            simd_float3 textCol = playerWon ? (simd_float3){0.2f, 1.0f, 0.2f} : (simd_float3){1.0f, 0.2f, 0.2f};

            #define WINRECT(x0,y0,x1,y1) do { \
                winVerts[wv++] = (Vertex){{x0,y0,0},textCol}; \
                winVerts[wv++] = (Vertex){{x1,y0,0},textCol}; \
                winVerts[wv++] = (Vertex){{x1,y1,0},textCol}; \
                winVerts[wv++] = (Vertex){{x0,y0,0},textCol}; \
                winVerts[wv++] = (Vertex){{x1,y1,0},textCol}; \
                winVerts[wv++] = (Vertex){{x0,y1,0},textCol}; \
            } while(0)

            float lw = 0.07f, lh = 0.12f, th = 0.015f, sp = 0.09f;
            float y = 0.05f;
            float x;

            if (playerWon) {
                // "YOU WIN!"
                float startX = -0.30f;
                // Y
                x = startX;
                WINRECT(x, y+lh*0.5f, x+th, y+lh);
                WINRECT(x+lw-th, y+lh*0.5f, x+lw, y+lh);
                WINRECT(x+lw*0.5f-th*0.5f, y, x+lw*0.5f+th*0.5f, y+lh*0.55f);
                WINRECT(x, y+lh*0.5f, x+lw*0.5f+th, y+lh*0.5f+th);
                WINRECT(x+lw*0.5f-th, y+lh*0.5f, x+lw, y+lh*0.5f+th);
                // O
                x += sp;
                WINRECT(x, y, x+th, y+lh); WINRECT(x+lw-th, y, x+lw, y+lh);
                WINRECT(x, y+lh-th, x+lw, y+lh); WINRECT(x, y, x+lw, y+th);
                // U
                x += sp;
                WINRECT(x, y, x+th, y+lh); WINRECT(x+lw-th, y, x+lw, y+lh);
                WINRECT(x, y, x+lw, y+th);
                // Space
                x += sp * 0.7f;
                // W
                x += sp;
                WINRECT(x, y, x+th, y+lh); WINRECT(x+lw-th, y, x+lw, y+lh);
                WINRECT(x, y, x+lw*0.5f+th, y+th);
                WINRECT(x+lw*0.5f-th, y, x+lw, y+th);
                WINRECT(x+lw*0.5f-th*0.5f, y, x+lw*0.5f+th*0.5f, y+lh*0.4f);
                // I
                x += sp;
                WINRECT(x+lw*0.5f-th*0.5f, y, x+lw*0.5f+th*0.5f, y+lh);
                WINRECT(x, y, x+lw, y+th); WINRECT(x, y+lh-th, x+lw, y+lh);
                // N
                x += sp;
                WINRECT(x, y, x+th, y+lh); WINRECT(x+lw-th, y, x+lw, y+lh);
                WINRECT(x, y+lh-th, x+lw, y+lh);
                WINRECT(x+th, y+lh*0.3f, x+lw-th, y+lh*0.7f);
                // !
                x += sp;
                WINRECT(x+lw*0.5f-th*0.5f, y+lh*0.25f, x+lw*0.5f+th*0.5f, y+lh);
                WINRECT(x+lw*0.5f-th*0.5f, y, x+lw*0.5f+th*0.5f, y+lh*0.15f);
            } else {
                // "YOU LOSE!"
                float startX = -0.35f;
                // Y
                x = startX;
                WINRECT(x, y+lh*0.5f, x+th, y+lh);
                WINRECT(x+lw-th, y+lh*0.5f, x+lw, y+lh);
                WINRECT(x+lw*0.5f-th*0.5f, y, x+lw*0.5f+th*0.5f, y+lh*0.55f);
                WINRECT(x, y+lh*0.5f, x+lw*0.5f+th, y+lh*0.5f+th);
                WINRECT(x+lw*0.5f-th, y+lh*0.5f, x+lw, y+lh*0.5f+th);
                // O
                x += sp;
                WINRECT(x, y, x+th, y+lh); WINRECT(x+lw-th, y, x+lw, y+lh);
                WINRECT(x, y+lh-th, x+lw, y+lh); WINRECT(x, y, x+lw, y+th);
                // U
                x += sp;
                WINRECT(x, y, x+th, y+lh); WINRECT(x+lw-th, y, x+lw, y+lh);
                WINRECT(x, y, x+lw, y+th);
                // Space
                x += sp * 0.7f;
                // L
                x += sp;
                WINRECT(x, y, x+th, y+lh); WINRECT(x, y, x+lw, y+th);
                // O
                x += sp;
                WINRECT(x, y, x+th, y+lh); WINRECT(x+lw-th, y, x+lw, y+lh);
                WINRECT(x, y+lh-th, x+lw, y+lh); WINRECT(x, y, x+lw, y+th);
                // S
                x += sp;
                WINRECT(x, y+lh-th, x+lw, y+lh); WINRECT(x, y+lh*0.5f, x+th, y+lh);
                WINRECT(x, y+lh*0.45f, x+lw, y+lh*0.45f+th);
                WINRECT(x+lw-th, y, x+lw, y+lh*0.5f); WINRECT(x, y, x+lw, y+th);
                // E
                x += sp;
                WINRECT(x, y, x+th, y+lh); WINRECT(x, y+lh-th, x+lw, y+lh);
                WINRECT(x, y, x+lw, y+th); WINRECT(x, y+lh*0.45f, x+lw*0.7f, y+lh*0.45f+th);
                // !
                x += sp;
                WINRECT(x+lw*0.5f-th*0.5f, y+lh*0.25f, x+lw*0.5f+th*0.5f, y+lh);
                WINRECT(x+lw*0.5f-th*0.5f, y, x+lw*0.5f+th*0.5f, y+lh*0.15f);
            }
            #undef WINRECT

            id<MTLBuffer> winBuffer = [_device newBufferWithBytes:winVerts length:sizeof(Vertex)*wv options:MTLResourceStorageModeShared];
            [encoder setVertexBuffer:winBuffer offset:0 atIndex:0];
            [encoder setVertexBytes:&IDENTITY_MATRIX length:sizeof(IDENTITY_MATRIX) atIndex:1];
            [encoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:wv];
        } else {
            // Single-player game over
            [encoder setVertexBuffer:_gameOverBuffer offset:0 atIndex:0];
            [encoder setVertexBytes:&IDENTITY_MATRIX length:sizeof(IDENTITY_MATRIX) atIndex:1];
            [encoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:_gameOverVertexCount];
        }
    }

    // Draw multiplayer score display
    if (state.isMultiplayer && state.isConnected) {
        [encoder setRenderPipelineState:_textPipelineState];
        [encoder setDepthStencilState:_bgDepthState];

        #define MAX_SCORE_VERTS 1200
        Vertex scoreVerts[MAX_SCORE_VERTS];
        int sv = 0;

        simd_float3 white = {1.0f, 1.0f, 1.0f};
        simd_float3 cyan = {0.3f, 0.9f, 1.0f};
        simd_float3 yellow = {1.0f, 1.0f, 0.3f};

        #define SCORERECT(x0,y0,x1,y1,col) do { \
            scoreVerts[sv++] = (Vertex){{x0,y0,0},col}; \
            scoreVerts[sv++] = (Vertex){{x1,y0,0},col}; \
            scoreVerts[sv++] = (Vertex){{x1,y1,0},col}; \
            scoreVerts[sv++] = (Vertex){{x0,y0,0},col}; \
            scoreVerts[sv++] = (Vertex){{x1,y1,0},col}; \
            scoreVerts[sv++] = (Vertex){{x0,y1,0},col}; \
        } while(0)

        // Helper to draw a digit
        #define DRAWDIGIT(digit, dx, dy, dw, dh, dth, col) do { \
            switch(digit) { \
                case 0: \
                    SCORERECT(dx, dy, dx+dth, dy+dh, col); SCORERECT(dx+dw-dth, dy, dx+dw, dy+dh, col); \
                    SCORERECT(dx, dy+dh-dth, dx+dw, dy+dh, col); SCORERECT(dx, dy, dx+dw, dy+dth, col); \
                    break; \
                case 1: \
                    SCORERECT(dx+dw*0.5f-dth*0.5f, dy, dx+dw*0.5f+dth*0.5f, dy+dh, col); \
                    break; \
                case 2: \
                    SCORERECT(dx, dy+dh-dth, dx+dw, dy+dh, col); \
                    SCORERECT(dx+dw-dth, dy+dh*0.5f, dx+dw, dy+dh, col); \
                    SCORERECT(dx, dy+dh*0.45f, dx+dw, dy+dh*0.45f+dth, col); \
                    SCORERECT(dx, dy, dx+dth, dy+dh*0.5f, col); \
                    SCORERECT(dx, dy, dx+dw, dy+dth, col); \
                    break; \
                case 3: \
                    SCORERECT(dx, dy+dh-dth, dx+dw, dy+dh, col); \
                    SCORERECT(dx+dw-dth, dy, dx+dw, dy+dh, col); \
                    SCORERECT(dx, dy+dh*0.45f, dx+dw, dy+dh*0.45f+dth, col); \
                    SCORERECT(dx, dy, dx+dw, dy+dth, col); \
                    break; \
                case 4: \
                    SCORERECT(dx, dy+dh*0.45f, dx+dth, dy+dh, col); \
                    SCORERECT(dx+dw-dth, dy, dx+dw, dy+dh, col); \
                    SCORERECT(dx, dy+dh*0.45f, dx+dw, dy+dh*0.45f+dth, col); \
                    break; \
                case 5: \
                    SCORERECT(dx, dy+dh-dth, dx+dw, dy+dh, col); \
                    SCORERECT(dx, dy+dh*0.5f, dx+dth, dy+dh, col); \
                    SCORERECT(dx, dy+dh*0.45f, dx+dw, dy+dh*0.45f+dth, col); \
                    SCORERECT(dx+dw-dth, dy, dx+dw, dy+dh*0.5f, col); \
                    SCORERECT(dx, dy, dx+dw, dy+dth, col); \
                    break; \
                case 6: \
                    SCORERECT(dx, dy, dx+dth, dy+dh, col); \
                    SCORERECT(dx, dy+dh-dth, dx+dw, dy+dh, col); \
                    SCORERECT(dx, dy+dh*0.45f, dx+dw, dy+dh*0.45f+dth, col); \
                    SCORERECT(dx+dw-dth, dy, dx+dw, dy+dh*0.5f, col); \
                    SCORERECT(dx, dy, dx+dw, dy+dth, col); \
                    break; \
                case 7: \
                    SCORERECT(dx, dy+dh-dth, dx+dw, dy+dh, col); \
                    SCORERECT(dx+dw-dth, dy, dx+dw, dy+dh, col); \
                    break; \
                case 8: \
                    SCORERECT(dx, dy, dx+dth, dy+dh, col); SCORERECT(dx+dw-dth, dy, dx+dw, dy+dh, col); \
                    SCORERECT(dx, dy+dh-dth, dx+dw, dy+dh, col); SCORERECT(dx, dy, dx+dw, dy+dth, col); \
                    SCORERECT(dx, dy+dh*0.45f, dx+dw, dy+dh*0.45f+dth, col); \
                    break; \
                case 9: \
                    SCORERECT(dx, dy+dh*0.45f, dx+dth, dy+dh, col); \
                    SCORERECT(dx+dw-dth, dy, dx+dw, dy+dh, col); \
                    SCORERECT(dx, dy+dh-dth, dx+dw, dy+dh, col); \
                    SCORERECT(dx, dy+dh*0.45f, dx+dw, dy+dh*0.45f+dth, col); \
                    SCORERECT(dx, dy, dx+dw, dy+dth, col); \
                    break; \
            } \
        } while(0)

        float lw = 0.035f, lh = 0.055f, th = 0.008f, sp = 0.045f;
        float scoreY = 0.72f;
        float x;

        // Draw "YOU:" text
        float youStartX = -0.35f;
        x = youStartX;
        // Y
        SCORERECT(x, scoreY+lh*0.5f, x+th, scoreY+lh, cyan);
        SCORERECT(x+lw-th, scoreY+lh*0.5f, x+lw, scoreY+lh, cyan);
        SCORERECT(x+lw*0.5f-th*0.5f, scoreY, x+lw*0.5f+th*0.5f, scoreY+lh*0.55f, cyan);
        x += sp;
        // O
        SCORERECT(x, scoreY, x+th, scoreY+lh, cyan); SCORERECT(x+lw-th, scoreY, x+lw, scoreY+lh, cyan);
        SCORERECT(x, scoreY+lh-th, x+lw, scoreY+lh, cyan); SCORERECT(x, scoreY, x+lw, scoreY+th, cyan);
        x += sp;
        // U
        SCORERECT(x, scoreY, x+th, scoreY+lh, cyan); SCORERECT(x+lw-th, scoreY, x+lw, scoreY+lh, cyan);
        SCORERECT(x, scoreY, x+lw, scoreY+th, cyan);
        x += sp;
        // :
        SCORERECT(x+lw*0.3f, scoreY+lh*0.65f, x+lw*0.5f, scoreY+lh*0.8f, cyan);
        SCORERECT(x+lw*0.3f, scoreY+lh*0.2f, x+lw*0.5f, scoreY+lh*0.35f, cyan);
        x += sp * 0.6f;

        // Draw local player score
        int localScore = state.localPlayerKills;
        if (localScore >= 10) {
            DRAWDIGIT(localScore / 10, x, scoreY, lw, lh, th, yellow);
            x += sp;
        }
        DRAWDIGIT(localScore % 10, x, scoreY, lw, lh, th, yellow);
        x += sp;

        // Draw " - " separator
        x += sp * 0.3f;
        SCORERECT(x, scoreY+lh*0.45f, x+lw*0.6f, scoreY+lh*0.55f, white);
        x += sp;

        // Draw "ENEMY:" text
        // E
        SCORERECT(x, scoreY, x+th, scoreY+lh, cyan); SCORERECT(x, scoreY+lh-th, x+lw, scoreY+lh, cyan);
        SCORERECT(x, scoreY, x+lw, scoreY+th, cyan); SCORERECT(x, scoreY+lh*0.45f, x+lw*0.7f, scoreY+lh*0.45f+th, cyan);
        x += sp;
        // N
        SCORERECT(x, scoreY, x+th, scoreY+lh, cyan); SCORERECT(x+lw-th, scoreY, x+lw, scoreY+lh, cyan);
        SCORERECT(x, scoreY+lh-th, x+lw, scoreY+lh, cyan);
        x += sp;
        // E
        SCORERECT(x, scoreY, x+th, scoreY+lh, cyan); SCORERECT(x, scoreY+lh-th, x+lw, scoreY+lh, cyan);
        SCORERECT(x, scoreY, x+lw, scoreY+th, cyan); SCORERECT(x, scoreY+lh*0.45f, x+lw*0.7f, scoreY+lh*0.45f+th, cyan);
        x += sp;
        // M
        SCORERECT(x, scoreY, x+th, scoreY+lh, cyan); SCORERECT(x+lw-th, scoreY, x+lw, scoreY+lh, cyan);
        SCORERECT(x, scoreY+lh-th, x+lw*0.5f, scoreY+lh, cyan); SCORERECT(x+lw*0.5f, scoreY+lh-th, x+lw, scoreY+lh, cyan);
        SCORERECT(x+lw*0.5f-th*0.5f, scoreY+lh*0.5f, x+lw*0.5f+th*0.5f, scoreY+lh, cyan);
        x += sp;
        // Y
        SCORERECT(x, scoreY+lh*0.5f, x+th, scoreY+lh, cyan);
        SCORERECT(x+lw-th, scoreY+lh*0.5f, x+lw, scoreY+lh, cyan);
        SCORERECT(x+lw*0.5f-th*0.5f, scoreY, x+lw*0.5f+th*0.5f, scoreY+lh*0.55f, cyan);
        x += sp;
        // :
        SCORERECT(x+lw*0.3f, scoreY+lh*0.65f, x+lw*0.5f, scoreY+lh*0.8f, cyan);
        SCORERECT(x+lw*0.3f, scoreY+lh*0.2f, x+lw*0.5f, scoreY+lh*0.35f, cyan);
        x += sp * 0.6f;

        // Draw remote player score
        int remoteScore = state.remotePlayerKills;
        if (remoteScore >= 10) {
            DRAWDIGIT(remoteScore / 10, x, scoreY, lw, lh, th, yellow);
            x += sp;
        }
        DRAWDIGIT(remoteScore % 10, x, scoreY, lw, lh, th, yellow);

        // Draw "FIRST TO 10 KILLS" subtitle
        float subY = 0.65f;
        float slw = 0.022f, slh = 0.035f, sth = 0.005f, ssp = 0.028f;
        simd_float3 gray = {0.6f, 0.6f, 0.6f};
        float subStartX = -0.22f;
        x = subStartX;

        // F
        SCORERECT(x, subY, x+sth, subY+slh, gray); SCORERECT(x, subY+slh-sth, x+slw, subY+slh, gray);
        SCORERECT(x, subY+slh*0.45f, x+slw*0.7f, subY+slh*0.45f+sth, gray);
        x += ssp;
        // I
        SCORERECT(x+slw*0.5f-sth*0.5f, subY, x+slw*0.5f+sth*0.5f, subY+slh, gray);
        x += ssp * 0.6f;
        // R
        SCORERECT(x, subY, x+sth, subY+slh, gray); SCORERECT(x, subY+slh-sth, x+slw, subY+slh, gray);
        SCORERECT(x+slw-sth, subY+slh*0.5f, x+slw, subY+slh, gray); SCORERECT(x, subY+slh*0.45f, x+slw, subY+slh*0.45f+sth, gray);
        SCORERECT(x+slw*0.4f, subY, x+slw, subY+slh*0.45f, gray);
        x += ssp;
        // S
        SCORERECT(x, subY+slh-sth, x+slw, subY+slh, gray); SCORERECT(x, subY+slh*0.5f, x+sth, subY+slh, gray);
        SCORERECT(x, subY+slh*0.45f, x+slw, subY+slh*0.45f+sth, gray);
        SCORERECT(x+slw-sth, subY, x+slw, subY+slh*0.5f, gray); SCORERECT(x, subY, x+slw, subY+sth, gray);
        x += ssp;
        // T
        SCORERECT(x, subY+slh-sth, x+slw, subY+slh, gray);
        SCORERECT(x+slw*0.5f-sth*0.5f, subY, x+slw*0.5f+sth*0.5f, subY+slh, gray);
        x += ssp;
        // Space
        x += ssp * 0.4f;
        // T
        SCORERECT(x, subY+slh-sth, x+slw, subY+slh, gray);
        SCORERECT(x+slw*0.5f-sth*0.5f, subY, x+slw*0.5f+sth*0.5f, subY+slh, gray);
        x += ssp;
        // O
        SCORERECT(x, subY, x+sth, subY+slh, gray); SCORERECT(x+slw-sth, subY, x+slw, subY+slh, gray);
        SCORERECT(x, subY+slh-sth, x+slw, subY+slh, gray); SCORERECT(x, subY, x+slw, subY+sth, gray);
        x += ssp;
        // Space
        x += ssp * 0.4f;
        // 1
        SCORERECT(x+slw*0.5f-sth*0.5f, subY, x+slw*0.5f+sth*0.5f, subY+slh, gray);
        x += ssp * 0.6f;
        // 0
        SCORERECT(x, subY, x+sth, subY+slh, gray); SCORERECT(x+slw-sth, subY, x+slw, subY+slh, gray);
        SCORERECT(x, subY+slh-sth, x+slw, subY+slh, gray); SCORERECT(x, subY, x+slw, subY+sth, gray);
        x += ssp;
        // Space
        x += ssp * 0.4f;
        // K
        SCORERECT(x, subY, x+sth, subY+slh, gray);
        SCORERECT(x, subY+slh*0.45f, x+slw*0.5f, subY+slh*0.45f+sth, gray);
        SCORERECT(x+slw*0.4f, subY+slh*0.5f, x+slw, subY+slh, gray);
        SCORERECT(x+slw*0.4f, subY, x+slw, subY+slh*0.5f, gray);
        x += ssp;
        // I
        SCORERECT(x+slw*0.5f-sth*0.5f, subY, x+slw*0.5f+sth*0.5f, subY+slh, gray);
        x += ssp * 0.6f;
        // L
        SCORERECT(x, subY, x+sth, subY+slh, gray); SCORERECT(x, subY, x+slw, subY+sth, gray);
        x += ssp;
        // L
        SCORERECT(x, subY, x+sth, subY+slh, gray); SCORERECT(x, subY, x+slw, subY+sth, gray);
        x += ssp;
        // S
        SCORERECT(x, subY+slh-sth, x+slw, subY+slh, gray); SCORERECT(x, subY+slh*0.5f, x+sth, subY+slh, gray);
        SCORERECT(x, subY+slh*0.45f, x+slw, subY+slh*0.45f+sth, gray);
        SCORERECT(x+slw-sth, subY, x+slw, subY+slh*0.5f, gray); SCORERECT(x, subY, x+slw, subY+sth, gray);

        #undef SCORERECT
        #undef DRAWDIGIT

        id<MTLBuffer> scoreBuffer = [_device newBufferWithBytes:scoreVerts length:sizeof(Vertex)*sv options:MTLResourceStorageModeShared];
        [encoder setVertexBuffer:scoreBuffer offset:0 atIndex:0];
        [encoder setVertexBytes:&IDENTITY_MATRIX length:sizeof(IDENTITY_MATRIX) atIndex:1];
        [encoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:sv];
    }

    // Draw respawn countdown in multiplayer
    if (state.isMultiplayer && state.localRespawnTimer > 0 && !state.gameWon) {
        [encoder setRenderPipelineState:_textPipelineState];
        [encoder setDepthStencilState:_bgDepthState];

        #define MAX_RESPAWN_VERTS 400
        Vertex respawnVerts[MAX_RESPAWN_VERTS];
        int rv = 0;

        simd_float3 respawnCol = {1.0f, 0.5f, 0.2f};

        #define RESPAWNRECT(x0,y0,x1,y1) do { \
            respawnVerts[rv++] = (Vertex){{x0,y0,0},respawnCol}; \
            respawnVerts[rv++] = (Vertex){{x1,y0,0},respawnCol}; \
            respawnVerts[rv++] = (Vertex){{x1,y1,0},respawnCol}; \
            respawnVerts[rv++] = (Vertex){{x0,y0,0},respawnCol}; \
            respawnVerts[rv++] = (Vertex){{x1,y1,0},respawnCol}; \
            respawnVerts[rv++] = (Vertex){{x0,y1,0},respawnCol}; \
        } while(0)

        float lw = 0.045f, lh = 0.07f, th = 0.01f, sp = 0.055f;
        float y = 0.0f;
        float startX = -0.32f;
        float x = startX;

        // R
        RESPAWNRECT(x, y, x+th, y+lh); RESPAWNRECT(x, y+lh-th, x+lw, y+lh);
        RESPAWNRECT(x+lw-th, y+lh*0.5f, x+lw, y+lh); RESPAWNRECT(x, y+lh*0.45f, x+lw, y+lh*0.45f+th);
        RESPAWNRECT(x+lw*0.4f, y, x+lw, y+lh*0.45f);
        x += sp;
        // E
        RESPAWNRECT(x, y, x+th, y+lh); RESPAWNRECT(x, y+lh-th, x+lw, y+lh);
        RESPAWNRECT(x, y, x+lw, y+th); RESPAWNRECT(x, y+lh*0.45f, x+lw*0.7f, y+lh*0.45f+th);
        x += sp;
        // S
        RESPAWNRECT(x, y+lh-th, x+lw, y+lh); RESPAWNRECT(x, y+lh*0.5f, x+th, y+lh);
        RESPAWNRECT(x, y+lh*0.45f, x+lw, y+lh*0.45f+th);
        RESPAWNRECT(x+lw-th, y, x+lw, y+lh*0.5f); RESPAWNRECT(x, y, x+lw, y+th);
        x += sp;
        // P
        RESPAWNRECT(x, y, x+th, y+lh); RESPAWNRECT(x, y+lh-th, x+lw, y+lh);
        RESPAWNRECT(x+lw-th, y+lh*0.45f, x+lw, y+lh); RESPAWNRECT(x, y+lh*0.45f, x+lw, y+lh*0.45f+th);
        x += sp;
        // A
        RESPAWNRECT(x, y, x+th, y+lh); RESPAWNRECT(x+lw-th, y, x+lw, y+lh);
        RESPAWNRECT(x, y+lh-th, x+lw, y+lh); RESPAWNRECT(x, y+lh*0.45f, x+lw, y+lh*0.45f+th);
        x += sp;
        // W
        RESPAWNRECT(x, y, x+th, y+lh); RESPAWNRECT(x+lw-th, y, x+lw, y+lh);
        RESPAWNRECT(x, y, x+lw*0.5f+th, y+th);
        RESPAWNRECT(x+lw*0.5f-th, y, x+lw, y+th);
        RESPAWNRECT(x+lw*0.5f-th*0.5f, y, x+lw*0.5f+th*0.5f, y+lh*0.4f);
        x += sp;
        // N
        RESPAWNRECT(x, y, x+th, y+lh); RESPAWNRECT(x+lw-th, y, x+lw, y+lh);
        RESPAWNRECT(x, y+lh-th, x+lw, y+lh);
        x += sp;
        // I
        RESPAWNRECT(x+lw*0.5f-th*0.5f, y, x+lw*0.5f+th*0.5f, y+lh);
        x += sp * 0.5f;
        // N
        RESPAWNRECT(x, y, x+th, y+lh); RESPAWNRECT(x+lw-th, y, x+lw, y+lh);
        RESPAWNRECT(x, y+lh-th, x+lw, y+lh);
        x += sp;
        // G
        RESPAWNRECT(x, y, x+th, y+lh); RESPAWNRECT(x, y+lh-th, x+lw, y+lh); RESPAWNRECT(x, y, x+lw, y+th);
        RESPAWNRECT(x+lw-th, y, x+lw, y+lh*0.5f); RESPAWNRECT(x+lw*0.4f, y+lh*0.45f, x+lw, y+lh*0.45f+th);
        x += sp;
        // Space
        x += sp * 0.3f;
        // I
        RESPAWNRECT(x+lw*0.5f-th*0.5f, y, x+lw*0.5f+th*0.5f, y+lh);
        x += sp * 0.5f;
        // N
        RESPAWNRECT(x, y, x+th, y+lh); RESPAWNRECT(x+lw-th, y, x+lw, y+lh);
        RESPAWNRECT(x, y+lh-th, x+lw, y+lh);
        x += sp;
        // Space
        x += sp * 0.3f;

        // Draw countdown number (convert frames to seconds)
        int secondsLeft = (state.localRespawnTimer + 59) / 60;  // Round up
        if (secondsLeft > 9) secondsLeft = 9;

        // Draw the digit
        switch(secondsLeft) {
            case 1:
                RESPAWNRECT(x+lw*0.5f-th*0.5f, y, x+lw*0.5f+th*0.5f, y+lh);
                break;
            case 2:
                RESPAWNRECT(x, y+lh-th, x+lw, y+lh);
                RESPAWNRECT(x+lw-th, y+lh*0.5f, x+lw, y+lh);
                RESPAWNRECT(x, y+lh*0.45f, x+lw, y+lh*0.45f+th);
                RESPAWNRECT(x, y, x+th, y+lh*0.5f);
                RESPAWNRECT(x, y, x+lw, y+th);
                break;
            case 3:
                RESPAWNRECT(x, y+lh-th, x+lw, y+lh);
                RESPAWNRECT(x+lw-th, y, x+lw, y+lh);
                RESPAWNRECT(x, y+lh*0.45f, x+lw, y+lh*0.45f+th);
                RESPAWNRECT(x, y, x+lw, y+th);
                break;
            case 4:
                RESPAWNRECT(x, y+lh*0.45f, x+th, y+lh);
                RESPAWNRECT(x+lw-th, y, x+lw, y+lh);
                RESPAWNRECT(x, y+lh*0.45f, x+lw, y+lh*0.45f+th);
                break;
            case 5:
                RESPAWNRECT(x, y+lh-th, x+lw, y+lh);
                RESPAWNRECT(x, y+lh*0.5f, x+th, y+lh);
                RESPAWNRECT(x, y+lh*0.45f, x+lw, y+lh*0.45f+th);
                RESPAWNRECT(x+lw-th, y, x+lw, y+lh*0.5f);
                RESPAWNRECT(x, y, x+lw, y+th);
                break;
            default:
                // Draw 0 for any other value
                RESPAWNRECT(x, y, x+th, y+lh); RESPAWNRECT(x+lw-th, y, x+lw, y+lh);
                RESPAWNRECT(x, y+lh-th, x+lw, y+lh); RESPAWNRECT(x, y, x+lw, y+th);
                break;
        }
        x += sp;

        // Draw "..."
        RESPAWNRECT(x, y+lh*0.1f, x+th*1.5f, y+lh*0.25f);
        x += sp * 0.4f;
        RESPAWNRECT(x, y+lh*0.1f, x+th*1.5f, y+lh*0.25f);
        x += sp * 0.4f;
        RESPAWNRECT(x, y+lh*0.1f, x+th*1.5f, y+lh*0.25f);

        #undef RESPAWNRECT

        id<MTLBuffer> respawnBuffer = [_device newBufferWithBytes:respawnVerts length:sizeof(Vertex)*rv options:MTLResourceStorageModeShared];
        [encoder setVertexBuffer:respawnBuffer offset:0 atIndex:0];
        [encoder setVertexBytes:&IDENTITY_MATRIX length:sizeof(IDENTITY_MATRIX) atIndex:1];
        [encoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:rv];
    }

    // Draw enemy muzzle flash
    if (state.enemyMuzzleFlashTimer > 0 && state.lastFiringEnemy >= 0 && enemyAlive[state.lastFiringEnemy]) {
        simd_float3 toFlash = state.enemyMuzzlePos - camPos;
        float flashDist = simd_length(toFlash);
        simd_float3 flashDir = toFlash / flashDist;

        BOOL flashVisible = YES;
        {
            float hw = WALL_WIDTH / 2.0f;
            float hh = WALL_HEIGHT / 2.0f;
            float hd = WALL_DEPTH / 2.0f;
            float w1y = FLOOR_Y + hh;

            simd_float3 wall1Min = {WALL1_X - hw, w1y - hh, WALL1_Z - hd};
            simd_float3 wall1Max = {WALL1_X + hw, w1y + hh, WALL1_Z + hd};
            RayHitResult wall1Hit = rayIntersectAABB(camPos, flashDir, wall1Min, wall1Max);
            if (wall1Hit.hit && wall1Hit.t < flashDist) flashVisible = NO;

            simd_float3 wall2Min = {WALL2_X - hw, w1y - hh, WALL2_Z - hd};
            simd_float3 wall2Max = {WALL2_X + hw, w1y + hh, WALL2_Z + hd};
            RayHitResult wall2Hit = rayIntersectAABB(camPos, flashDir, wall2Min, wall2Max);
            if (wall2Hit.hit && wall2Hit.t < flashDist) flashVisible = NO;
        }

        if (flashVisible) {
            simd_float4x4 eFlashModel = {{
                {rx * 0.6f, ry * 0.6f, rz * 0.6f, 0}, {ux * 0.6f, uy * 0.6f, uz * 0.6f, 0},
                {-fx, -fy, -fz, 0}, {state.enemyMuzzlePos.x, state.enemyMuzzlePos.y, state.enemyMuzzlePos.z, 1}
            }};
            simd_float4x4 eFlashMvp = simd_mul(proj, simd_mul(viewMat, eFlashModel));

            [encoder setRenderPipelineState:_pipelineState];
            [encoder setDepthStencilState:_bgDepthState];
            [encoder setVertexBuffer:_muzzleFlashBuffer offset:0 atIndex:0];
            [encoder setVertexBytes:&eFlashMvp length:sizeof(eFlashMvp) atIndex:1];
            [encoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:18];
        }
    }

    // Draw gun
    {
        float tiltX = -0.1f, tiltY = -0.45f;
        float cosTiltX = cosf(tiltX), sinTiltX = sinf(tiltX);
        float cosTiltY = cosf(tiltY), sinTiltY = sinf(tiltY);

        simd_float4x4 gunMvp = {{
            {GUN_SCALE * cosTiltY, GUN_SCALE * sinTiltX * sinTiltY, GUN_SCALE * -cosTiltX * sinTiltY, 0},
            {0, GUN_SCALE * cosTiltX, GUN_SCALE * sinTiltX, 0},
            {GUN_SCALE * sinTiltY, GUN_SCALE * -sinTiltX * cosTiltY, GUN_SCALE * cosTiltX * cosTiltY, 0},
            {GUN_SCREEN_X, GUN_SCREEN_Y, GUN_SCREEN_Z, 1}
        }};

        [encoder setRenderPipelineState:_pipelineState];
        [encoder setDepthStencilState:_bgDepthState];
        [encoder setVertexBuffer:_gunVertexBuffer offset:0 atIndex:0];
        [encoder setVertexBytes:&gunMvp length:sizeof(gunMvp) atIndex:1];
        [encoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:_gunVertexCount];

        // Player muzzle flash
        if (state.muzzleFlashTimer > 0) {
            float bx = 0.0f, by = 0.02f, bz = 0.25f;
            float tx = GUN_SCALE * (cosTiltY * bx + sinTiltY * bz);
            float ty = GUN_SCALE * (sinTiltX * sinTiltY * bx + cosTiltX * by - sinTiltX * cosTiltY * bz);
            float flashX = GUN_SCREEN_X + tx;
            float flashY = GUN_SCREEN_Y + ty;

            simd_float3 yellow = {1.0f, 1.0f, 0.3f};
            float fs = 0.04f;
            Vertex flashVerts[] = {
                {{flashX - fs*2, flashY - fs*0.3f, 0}, yellow}, {{flashX + fs*2, flashY - fs*0.3f, 0}, yellow},
                {{flashX + fs*2, flashY + fs*0.3f, 0}, yellow}, {{flashX - fs*2, flashY - fs*0.3f, 0}, yellow},
                {{flashX + fs*2, flashY + fs*0.3f, 0}, yellow}, {{flashX - fs*2, flashY + fs*0.3f, 0}, yellow},
                {{flashX - fs*0.3f, flashY - fs*2, 0}, yellow}, {{flashX + fs*0.3f, flashY - fs*2, 0}, yellow},
                {{flashX + fs*0.3f, flashY + fs*2, 0}, yellow}, {{flashX - fs*0.3f, flashY - fs*2, 0}, yellow},
                {{flashX + fs*0.3f, flashY + fs*2, 0}, yellow}, {{flashX - fs*0.3f, flashY + fs*2, 0}, yellow},
            };

            id<MTLBuffer> flashBuf = [_device newBufferWithBytes:flashVerts length:sizeof(flashVerts) options:MTLResourceStorageModeShared];
            [encoder setVertexBuffer:flashBuf offset:0 atIndex:0];
            [encoder setVertexBytes:&IDENTITY_MATRIX length:sizeof(IDENTITY_MATRIX) atIndex:1];
            [encoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:12];
        }
    }

    // Draw spawn protection shield effect (pulsing blue tint on screen edges)
    if (state.spawnProtectionTimer > 0) {
        // Pulsing effect - oscillates between 0.3 and 0.7 alpha based on timer
        float pulse = 0.3f + 0.4f * (0.5f + 0.5f * sinf((float)state.spawnProtectionTimer * 0.15f));
        // Fade out effect as timer gets low (last 60 frames = 1 second)
        if (state.spawnProtectionTimer < 60) {
            pulse *= (float)state.spawnProtectionTimer / 60.0f;
        }

        // Blue-cyan shield colors
        simd_float3 shieldDark = {0.0f, 0.2f * pulse, 0.4f * pulse};
        simd_float3 shieldMid = {0.1f * pulse, 0.4f * pulse, 0.7f * pulse};
        simd_float3 shieldLight = {0.2f * pulse, 0.6f * pulse, 1.0f * pulse};
        float s = 0.12f;  // Width of shield edge effect

        Vertex shieldVerts[] = {
            // Top edge
            {{-1.0f, 1.0f, 0}, shieldLight}, {{1.0f, 1.0f, 0}, shieldLight}, {{-1.0f, 1.0f - s, 0}, shieldDark},
            {{1.0f, 1.0f, 0}, shieldLight}, {{1.0f, 1.0f - s, 0}, shieldDark}, {{-1.0f, 1.0f - s, 0}, shieldDark},
            // Bottom edge
            {{-1.0f, -1.0f + s, 0}, shieldDark}, {{1.0f, -1.0f + s, 0}, shieldDark}, {{-1.0f, -1.0f, 0}, shieldLight},
            {{1.0f, -1.0f + s, 0}, shieldDark}, {{1.0f, -1.0f, 0}, shieldLight}, {{-1.0f, -1.0f, 0}, shieldLight},
            // Left edge
            {{-1.0f, 1.0f - s, 0}, shieldMid}, {{-1.0f + s, 1.0f - s, 0}, shieldDark}, {{-1.0f, -1.0f + s, 0}, shieldMid},
            {{-1.0f + s, 1.0f - s, 0}, shieldDark}, {{-1.0f + s, -1.0f + s, 0}, shieldDark}, {{-1.0f, -1.0f + s, 0}, shieldMid},
            // Right edge
            {{1.0f - s, 1.0f - s, 0}, shieldDark}, {{1.0f, 1.0f - s, 0}, shieldMid}, {{1.0f - s, -1.0f + s, 0}, shieldDark},
            {{1.0f, 1.0f - s, 0}, shieldMid}, {{1.0f, -1.0f + s, 0}, shieldMid}, {{1.0f - s, -1.0f + s, 0}, shieldDark},
            // Corner accents (top-left)
            {{-1.0f, 1.0f, 0}, shieldLight}, {{-1.0f + s*1.5f, 1.0f, 0}, shieldMid}, {{-1.0f, 1.0f - s*1.5f, 0}, shieldMid},
            // Corner accents (top-right)
            {{1.0f - s*1.5f, 1.0f, 0}, shieldMid}, {{1.0f, 1.0f, 0}, shieldLight}, {{1.0f, 1.0f - s*1.5f, 0}, shieldMid},
            // Corner accents (bottom-left)
            {{-1.0f, -1.0f + s*1.5f, 0}, shieldMid}, {{-1.0f + s*1.5f, -1.0f, 0}, shieldMid}, {{-1.0f, -1.0f, 0}, shieldLight},
            // Corner accents (bottom-right)
            {{1.0f, -1.0f + s*1.5f, 0}, shieldMid}, {{1.0f, -1.0f, 0}, shieldLight}, {{1.0f - s*1.5f, -1.0f, 0}, shieldMid},
        };

        id<MTLBuffer> shieldBuf = [_device newBufferWithBytes:shieldVerts length:sizeof(shieldVerts) options:MTLResourceStorageModeShared];
        [encoder setVertexBuffer:shieldBuf offset:0 atIndex:0];
        [encoder setVertexBytes:&IDENTITY_MATRIX length:sizeof(IDENTITY_MATRIX) atIndex:1];
        [encoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:36];
    }

    // Draw blood splatter
    if (state.bloodLevel > 0.0f) {
        float flash = state.bloodFlashTimer > 0 ? 0.3f : 0.0f;
        float b = state.bloodLevel;
        simd_float3 bloodDark = {0.35f + flash, 0.0f, 0.0f};
        simd_float3 bloodMid = {0.5f + flash, 0.02f, 0.02f};
        simd_float3 bloodLight = {0.65f + flash, 0.05f, 0.05f};
        float s = 0.15f + b * 0.45f;

        Vertex bloodVerts[] = {
            {{-1.0f, 1.0f, 0}, bloodDark}, {{-1.0f + s, 1.0f, 0}, bloodLight}, {{-1.0f, 1.0f - s, 0}, bloodLight},
            {{-1.0f, 1.0f - s*0.7f, 0}, bloodMid}, {{-1.0f + s*0.6f, 1.0f - s*0.3f, 0}, bloodLight}, {{-1.0f + s*0.3f, 1.0f - s*0.8f, 0}, bloodDark},
            {{1.0f, 1.0f, 0}, bloodDark}, {{1.0f - s, 1.0f, 0}, bloodLight}, {{1.0f, 1.0f - s, 0}, bloodLight},
            {{1.0f, 1.0f - s*0.7f, 0}, bloodMid}, {{1.0f - s*0.6f, 1.0f - s*0.3f, 0}, bloodLight}, {{1.0f - s*0.3f, 1.0f - s*0.8f, 0}, bloodDark},
            {{-1.0f, -1.0f, 0}, bloodDark}, {{-1.0f + s, -1.0f, 0}, bloodLight}, {{-1.0f, -1.0f + s, 0}, bloodLight},
            {{-1.0f, -1.0f + s*0.7f, 0}, bloodMid}, {{-1.0f + s*0.6f, -1.0f + s*0.3f, 0}, bloodLight}, {{-1.0f + s*0.3f, -1.0f + s*0.8f, 0}, bloodDark},
            {{1.0f, -1.0f, 0}, bloodDark}, {{1.0f - s, -1.0f, 0}, bloodLight}, {{1.0f, -1.0f + s, 0}, bloodLight},
            {{1.0f, -1.0f + s*0.7f, 0}, bloodMid}, {{1.0f - s*0.6f, -1.0f + s*0.3f, 0}, bloodLight}, {{1.0f - s*0.3f, -1.0f + s*0.8f, 0}, bloodDark},
        };

        id<MTLBuffer> bloodBuf = [_device newBufferWithBytes:bloodVerts length:sizeof(bloodVerts) options:MTLResourceStorageModeShared];
        [encoder setVertexBuffer:bloodBuf offset:0 atIndex:0];
        [encoder setVertexBytes:&IDENTITY_MATRIX length:sizeof(IDENTITY_MATRIX) atIndex:1];
        [encoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:24];
    }

    // Draw leaderboard when Tab is held
    if (_metalView.keyTab) {
        [encoder setRenderPipelineState:_textPipelineState];
        [encoder setDepthStencilState:_bgDepthState];

        #define MAX_LB_VERTS 2000
        Vertex lbVerts[MAX_LB_VERTS];
        int lbv = 0;

        simd_float3 bgColor = {0.0f, 0.0f, 0.0f};
        simd_float3 borderColor = {0.8f, 0.7f, 0.2f};
        simd_float3 headerColor = {1.0f, 0.85f, 0.0f};
        simd_float3 p1Color = {0.3f, 0.8f, 1.0f};
        simd_float3 p2Color = {1.0f, 0.4f, 0.4f};
        simd_float3 white = {1.0f, 1.0f, 1.0f};

        #define LBRECT(x0,y0,x1,y1,col) do { \
            if (lbv < MAX_LB_VERTS - 6) { \
                lbVerts[lbv++] = (Vertex){{x0,y0,0},col}; \
                lbVerts[lbv++] = (Vertex){{x1,y0,0},col}; \
                lbVerts[lbv++] = (Vertex){{x1,y1,0},col}; \
                lbVerts[lbv++] = (Vertex){{x0,y0,0},col}; \
                lbVerts[lbv++] = (Vertex){{x1,y1,0},col}; \
                lbVerts[lbv++] = (Vertex){{x0,y1,0},col}; \
            } \
        } while(0)

        // Background panel
        float panelX = -0.4f, panelY = -0.35f, panelW = 0.8f, panelH = 0.7f;
        float border = 0.008f;

        // Outer border
        LBRECT(panelX - border, panelY - border, panelX + panelW + border, panelY + panelH + border, borderColor);
        // Inner background (semi-transparent effect via darker color)
        simd_float3 panelBg = {0.05f, 0.05f, 0.1f};
        LBRECT(panelX, panelY, panelX + panelW, panelY + panelH, panelBg);

        // Title bar
        LBRECT(panelX, panelY + panelH - 0.12f, panelX + panelW, panelY + panelH, bgColor);
        LBRECT(panelX, panelY + panelH - 0.125f, panelX + panelW, panelY + panelH - 0.12f, borderColor);

        // Draw "LEADERBOARD" title
        float lw = 0.035f, lh = 0.055f, th = 0.008f, sp = 0.042f;
        float titleY = panelY + panelH - 0.095f;
        float x = panelX + 0.08f;

        // L
        LBRECT(x, titleY, x+th, titleY+lh, headerColor); LBRECT(x, titleY, x+lw, titleY+th, headerColor);
        x += sp;
        // E
        LBRECT(x, titleY, x+th, titleY+lh, headerColor); LBRECT(x, titleY+lh-th, x+lw, titleY+lh, headerColor);
        LBRECT(x, titleY, x+lw, titleY+th, headerColor); LBRECT(x, titleY+lh*0.45f, x+lw*0.7f, titleY+lh*0.45f+th, headerColor);
        x += sp;
        // A
        LBRECT(x, titleY, x+th, titleY+lh, headerColor); LBRECT(x+lw-th, titleY, x+lw, titleY+lh, headerColor);
        LBRECT(x, titleY+lh-th, x+lw, titleY+lh, headerColor); LBRECT(x, titleY+lh*0.45f, x+lw, titleY+lh*0.45f+th, headerColor);
        x += sp;
        // D
        LBRECT(x, titleY, x+th, titleY+lh, headerColor); LBRECT(x, titleY+lh-th, x+lw*0.7f, titleY+lh, headerColor);
        LBRECT(x, titleY, x+lw*0.7f, titleY+th, headerColor); LBRECT(x+lw-th, titleY+th, x+lw, titleY+lh-th, headerColor);
        x += sp;
        // E
        LBRECT(x, titleY, x+th, titleY+lh, headerColor); LBRECT(x, titleY+lh-th, x+lw, titleY+lh, headerColor);
        LBRECT(x, titleY, x+lw, titleY+th, headerColor); LBRECT(x, titleY+lh*0.45f, x+lw*0.7f, titleY+lh*0.45f+th, headerColor);
        x += sp;
        // R
        LBRECT(x, titleY, x+th, titleY+lh, headerColor); LBRECT(x, titleY+lh-th, x+lw, titleY+lh, headerColor);
        LBRECT(x+lw-th, titleY+lh*0.5f, x+lw, titleY+lh, headerColor); LBRECT(x, titleY+lh*0.45f, x+lw, titleY+lh*0.45f+th, headerColor);
        LBRECT(x+lw*0.4f, titleY, x+lw, titleY+lh*0.45f, headerColor);
        x += sp;
        // B
        LBRECT(x, titleY, x+th, titleY+lh, headerColor); LBRECT(x, titleY+lh-th, x+lw*0.8f, titleY+lh, headerColor);
        LBRECT(x, titleY, x+lw*0.8f, titleY+th, headerColor); LBRECT(x+lw-th, titleY+th, x+lw, titleY+lh*0.45f, headerColor);
        LBRECT(x+lw-th, titleY+lh*0.5f, x+lw, titleY+lh-th, headerColor); LBRECT(x, titleY+lh*0.45f, x+lw*0.8f, titleY+lh*0.45f+th, headerColor);
        x += sp;
        // O
        LBRECT(x, titleY, x+th, titleY+lh, headerColor); LBRECT(x+lw-th, titleY, x+lw, titleY+lh, headerColor);
        LBRECT(x, titleY+lh-th, x+lw, titleY+lh, headerColor); LBRECT(x, titleY, x+lw, titleY+th, headerColor);
        x += sp;
        // A
        LBRECT(x, titleY, x+th, titleY+lh, headerColor); LBRECT(x+lw-th, titleY, x+lw, titleY+lh, headerColor);
        LBRECT(x, titleY+lh-th, x+lw, titleY+lh, headerColor); LBRECT(x, titleY+lh*0.45f, x+lw, titleY+lh*0.45f+th, headerColor);
        x += sp;
        // R
        LBRECT(x, titleY, x+th, titleY+lh, headerColor); LBRECT(x, titleY+lh-th, x+lw, titleY+lh, headerColor);
        LBRECT(x+lw-th, titleY+lh*0.5f, x+lw, titleY+lh, headerColor); LBRECT(x, titleY+lh*0.45f, x+lw, titleY+lh*0.45f+th, headerColor);
        LBRECT(x+lw*0.4f, titleY, x+lw, titleY+lh*0.45f, headerColor);
        x += sp;
        // D
        LBRECT(x, titleY, x+th, titleY+lh, headerColor); LBRECT(x, titleY+lh-th, x+lw*0.7f, titleY+lh, headerColor);
        LBRECT(x, titleY, x+lw*0.7f, titleY+th, headerColor); LBRECT(x+lw-th, titleY+th, x+lw, titleY+lh-th, headerColor);

        // Column headers
        float rowY = panelY + panelH - 0.22f;
        float nameX = panelX + 0.05f;
        float killsX = panelX + 0.55f;
        float slw = 0.022f, slh = 0.035f, sth = 0.005f, ssp = 0.028f;

        // "PLAYER" header
        x = nameX;
        // P
        LBRECT(x, rowY, x+sth, rowY+slh, white); LBRECT(x, rowY+slh-sth, x+slw, rowY+slh, white);
        LBRECT(x+slw-sth, rowY+slh*0.45f, x+slw, rowY+slh, white); LBRECT(x, rowY+slh*0.45f, x+slw, rowY+slh*0.45f+sth, white);
        x += ssp;
        // L
        LBRECT(x, rowY, x+sth, rowY+slh, white); LBRECT(x, rowY, x+slw, rowY+sth, white);
        x += ssp;
        // A
        LBRECT(x, rowY, x+sth, rowY+slh, white); LBRECT(x+slw-sth, rowY, x+slw, rowY+slh, white);
        LBRECT(x, rowY+slh-sth, x+slw, rowY+slh, white); LBRECT(x, rowY+slh*0.45f, x+slw, rowY+slh*0.45f+sth, white);
        x += ssp;
        // Y
        LBRECT(x, rowY+slh*0.5f, x+sth, rowY+slh, white); LBRECT(x+slw-sth, rowY+slh*0.5f, x+slw, rowY+slh, white);
        LBRECT(x+slw*0.5f-sth*0.5f, rowY, x+slw*0.5f+sth*0.5f, rowY+slh*0.55f, white);
        x += ssp;
        // E
        LBRECT(x, rowY, x+sth, rowY+slh, white); LBRECT(x, rowY+slh-sth, x+slw, rowY+slh, white);
        LBRECT(x, rowY, x+slw, rowY+sth, white); LBRECT(x, rowY+slh*0.45f, x+slw*0.7f, rowY+slh*0.45f+sth, white);
        x += ssp;
        // R
        LBRECT(x, rowY, x+sth, rowY+slh, white); LBRECT(x, rowY+slh-sth, x+slw, rowY+slh, white);
        LBRECT(x+slw-sth, rowY+slh*0.5f, x+slw, rowY+slh, white); LBRECT(x, rowY+slh*0.45f, x+slw, rowY+slh*0.45f+sth, white);

        // "KILLS" header
        x = killsX;
        // K
        LBRECT(x, rowY, x+sth, rowY+slh, white);
        LBRECT(x, rowY+slh*0.45f, x+slw*0.5f, rowY+slh*0.45f+sth, white);
        LBRECT(x+slw*0.4f, rowY+slh*0.5f, x+slw, rowY+slh, white);
        LBRECT(x+slw*0.4f, rowY, x+slw, rowY+slh*0.5f, white);
        x += ssp;
        // I
        LBRECT(x+slw*0.5f-sth*0.5f, rowY, x+slw*0.5f+sth*0.5f, rowY+slh, white);
        x += ssp;
        // L
        LBRECT(x, rowY, x+sth, rowY+slh, white); LBRECT(x, rowY, x+slw, rowY+sth, white);
        x += ssp;
        // L
        LBRECT(x, rowY, x+sth, rowY+slh, white); LBRECT(x, rowY, x+slw, rowY+sth, white);
        x += ssp;
        // S
        LBRECT(x, rowY+slh-sth, x+slw, rowY+slh, white); LBRECT(x, rowY+slh*0.5f, x+sth, rowY+slh, white);
        LBRECT(x, rowY+slh*0.45f, x+slw, rowY+slh*0.45f+sth, white);
        LBRECT(x+slw-sth, rowY, x+slw, rowY+slh*0.5f, white); LBRECT(x, rowY, x+slw, rowY+sth, white);

        // Separator line
        LBRECT(panelX + 0.02f, rowY - 0.02f, panelX + panelW - 0.02f, rowY - 0.015f, borderColor);

        // Player rows
        float plw = 0.028f, plh = 0.045f, pth = 0.006f, psp = 0.035f;

        // Get scores
        int p1Kills, p2Kills;
        simd_float3 p1Col, p2Col;
        p1Kills = state.localPlayerKills;
        p2Kills = state.remotePlayerKills;  // In single player, this tracks bot kills on player
        p1Col = p1Color;
        p2Col = p2Color;

        // Sort by kills (higher first)
        int rank1Kills = p1Kills >= p2Kills ? p1Kills : p2Kills;
        int rank2Kills = p1Kills >= p2Kills ? p2Kills : p1Kills;
        simd_float3 rank1Col = p1Kills >= p2Kills ? p1Col : p2Col;
        simd_float3 rank2Col = p1Kills >= p2Kills ? p2Col : p1Col;
        BOOL rank1IsPlayer = p1Kills >= p2Kills;

        // Row 1 (1st place)
        rowY -= 0.08f;
        x = nameX;
        // "1."
        LBRECT(x+plw*0.5f-pth*0.5f, rowY, x+plw*0.5f+pth*0.5f, rowY+plh, rank1Col);
        x += psp * 0.6f;
        LBRECT(x, rowY+plh*0.1f, x+pth*1.5f, rowY+plh*0.25f, rank1Col);
        x += psp * 0.5f;
        // Player name - "YOU" or "ENEMY"/"BOT"
        if (rank1IsPlayer) {
            // Y
            LBRECT(x, rowY+plh*0.5f, x+pth, rowY+plh, rank1Col); LBRECT(x+plw-pth, rowY+plh*0.5f, x+plw, rowY+plh, rank1Col);
            LBRECT(x+plw*0.5f-pth*0.5f, rowY, x+plw*0.5f+pth*0.5f, rowY+plh*0.55f, rank1Col);
            x += psp;
            // O
            LBRECT(x, rowY, x+pth, rowY+plh, rank1Col); LBRECT(x+plw-pth, rowY, x+plw, rowY+plh, rank1Col);
            LBRECT(x, rowY+plh-pth, x+plw, rowY+plh, rank1Col); LBRECT(x, rowY, x+plw, rowY+pth, rank1Col);
            x += psp;
            // U
            LBRECT(x, rowY, x+pth, rowY+plh, rank1Col); LBRECT(x+plw-pth, rowY, x+plw, rowY+plh, rank1Col);
            LBRECT(x, rowY, x+plw, rowY+pth, rank1Col);
        } else {
            // B
            LBRECT(x, rowY, x+pth, rowY+plh, rank1Col); LBRECT(x, rowY+plh-pth, x+plw*0.8f, rowY+plh, rank1Col);
            LBRECT(x, rowY, x+plw*0.8f, rowY+pth, rank1Col); LBRECT(x+plw-pth, rowY+pth, x+plw, rowY+plh*0.45f, rank1Col);
            LBRECT(x+plw-pth, rowY+plh*0.5f, x+plw, rowY+plh-pth, rank1Col); LBRECT(x, rowY+plh*0.45f, x+plw*0.8f, rowY+plh*0.45f+pth, rank1Col);
            x += psp;
            // O
            LBRECT(x, rowY, x+pth, rowY+plh, rank1Col); LBRECT(x+plw-pth, rowY, x+plw, rowY+plh, rank1Col);
            LBRECT(x, rowY+plh-pth, x+plw, rowY+plh, rank1Col); LBRECT(x, rowY, x+plw, rowY+pth, rank1Col);
            x += psp;
            // T
            LBRECT(x, rowY+plh-pth, x+plw, rowY+plh, rank1Col);
            LBRECT(x+plw*0.5f-pth*0.5f, rowY, x+plw*0.5f+pth*0.5f, rowY+plh, rank1Col);
        }
        // Kill count for rank 1
        x = killsX + 0.03f;
        if (rank1Kills >= 10) {
            int tens = rank1Kills / 10;
            // Draw tens digit
            LBRECT(x+plw*0.5f-pth*0.5f, rowY, x+plw*0.5f+pth*0.5f, rowY+plh, rank1Col);
            x += psp * 0.7f;
        }
        int ones = rank1Kills % 10;
        switch(ones) {
            case 0:
                LBRECT(x, rowY, x+pth, rowY+plh, rank1Col); LBRECT(x+plw-pth, rowY, x+plw, rowY+plh, rank1Col);
                LBRECT(x, rowY+plh-pth, x+plw, rowY+plh, rank1Col); LBRECT(x, rowY, x+plw, rowY+pth, rank1Col);
                break;
            case 1:
                LBRECT(x+plw*0.5f-pth*0.5f, rowY, x+plw*0.5f+pth*0.5f, rowY+plh, rank1Col);
                break;
            case 2:
                LBRECT(x, rowY+plh-pth, x+plw, rowY+plh, rank1Col); LBRECT(x+plw-pth, rowY+plh*0.5f, x+plw, rowY+plh, rank1Col);
                LBRECT(x, rowY+plh*0.45f, x+plw, rowY+plh*0.45f+pth, rank1Col);
                LBRECT(x, rowY, x+pth, rowY+plh*0.5f, rank1Col); LBRECT(x, rowY, x+plw, rowY+pth, rank1Col);
                break;
            case 3:
                LBRECT(x, rowY+plh-pth, x+plw, rowY+plh, rank1Col); LBRECT(x+plw-pth, rowY, x+plw, rowY+plh, rank1Col);
                LBRECT(x, rowY+plh*0.45f, x+plw, rowY+plh*0.45f+pth, rank1Col); LBRECT(x, rowY, x+plw, rowY+pth, rank1Col);
                break;
            case 4:
                LBRECT(x, rowY+plh*0.45f, x+pth, rowY+plh, rank1Col); LBRECT(x+plw-pth, rowY, x+plw, rowY+plh, rank1Col);
                LBRECT(x, rowY+plh*0.45f, x+plw, rowY+plh*0.45f+pth, rank1Col);
                break;
            case 5:
                LBRECT(x, rowY+plh-pth, x+plw, rowY+plh, rank1Col); LBRECT(x, rowY+plh*0.5f, x+pth, rowY+plh, rank1Col);
                LBRECT(x, rowY+plh*0.45f, x+plw, rowY+plh*0.45f+pth, rank1Col);
                LBRECT(x+plw-pth, rowY, x+plw, rowY+plh*0.5f, rank1Col); LBRECT(x, rowY, x+plw, rowY+pth, rank1Col);
                break;
            case 6:
                LBRECT(x, rowY, x+pth, rowY+plh, rank1Col); LBRECT(x, rowY+plh-pth, x+plw, rowY+plh, rank1Col);
                LBRECT(x, rowY+plh*0.45f, x+plw, rowY+plh*0.45f+pth, rank1Col);
                LBRECT(x+plw-pth, rowY, x+plw, rowY+plh*0.5f, rank1Col); LBRECT(x, rowY, x+plw, rowY+pth, rank1Col);
                break;
            case 7:
                LBRECT(x, rowY+plh-pth, x+plw, rowY+plh, rank1Col); LBRECT(x+plw-pth, rowY, x+plw, rowY+plh, rank1Col);
                break;
            case 8:
                LBRECT(x, rowY, x+pth, rowY+plh, rank1Col); LBRECT(x+plw-pth, rowY, x+plw, rowY+plh, rank1Col);
                LBRECT(x, rowY+plh-pth, x+plw, rowY+plh, rank1Col); LBRECT(x, rowY, x+plw, rowY+pth, rank1Col);
                LBRECT(x, rowY+plh*0.45f, x+plw, rowY+plh*0.45f+pth, rank1Col);
                break;
            case 9:
                LBRECT(x, rowY+plh*0.45f, x+pth, rowY+plh, rank1Col); LBRECT(x+plw-pth, rowY, x+plw, rowY+plh, rank1Col);
                LBRECT(x, rowY+plh-pth, x+plw, rowY+plh, rank1Col); LBRECT(x, rowY+plh*0.45f, x+plw, rowY+plh*0.45f+pth, rank1Col);
                LBRECT(x, rowY, x+plw, rowY+pth, rank1Col);
                break;
        }

        // Row 2 (2nd place)
        rowY -= 0.08f;
        x = nameX;
        // "2."
        LBRECT(x, rowY+plh-pth, x+plw, rowY+plh, rank2Col); LBRECT(x+plw-pth, rowY+plh*0.5f, x+plw, rowY+plh, rank2Col);
        LBRECT(x, rowY+plh*0.45f, x+plw, rowY+plh*0.45f+pth, rank2Col);
        LBRECT(x, rowY, x+pth, rowY+plh*0.5f, rank2Col); LBRECT(x, rowY, x+plw, rowY+pth, rank2Col);
        x += psp * 0.6f;
        LBRECT(x, rowY+plh*0.1f, x+pth*1.5f, rowY+plh*0.25f, rank2Col);
        x += psp * 0.5f;
        // Player name
        if (!rank1IsPlayer) {
            // Y
            LBRECT(x, rowY+plh*0.5f, x+pth, rowY+plh, rank2Col); LBRECT(x+plw-pth, rowY+plh*0.5f, x+plw, rowY+plh, rank2Col);
            LBRECT(x+plw*0.5f-pth*0.5f, rowY, x+plw*0.5f+pth*0.5f, rowY+plh*0.55f, rank2Col);
            x += psp;
            // O
            LBRECT(x, rowY, x+pth, rowY+plh, rank2Col); LBRECT(x+plw-pth, rowY, x+plw, rowY+plh, rank2Col);
            LBRECT(x, rowY+plh-pth, x+plw, rowY+plh, rank2Col); LBRECT(x, rowY, x+plw, rowY+pth, rank2Col);
            x += psp;
            // U
            LBRECT(x, rowY, x+pth, rowY+plh, rank2Col); LBRECT(x+plw-pth, rowY, x+plw, rowY+plh, rank2Col);
            LBRECT(x, rowY, x+plw, rowY+pth, rank2Col);
        } else {
            // B
            LBRECT(x, rowY, x+pth, rowY+plh, rank2Col); LBRECT(x, rowY+plh-pth, x+plw*0.8f, rowY+plh, rank2Col);
            LBRECT(x, rowY, x+plw*0.8f, rowY+pth, rank2Col); LBRECT(x+plw-pth, rowY+pth, x+plw, rowY+plh*0.45f, rank2Col);
            LBRECT(x+plw-pth, rowY+plh*0.5f, x+plw, rowY+plh-pth, rank2Col); LBRECT(x, rowY+plh*0.45f, x+plw*0.8f, rowY+plh*0.45f+pth, rank2Col);
            x += psp;
            // O
            LBRECT(x, rowY, x+pth, rowY+plh, rank2Col); LBRECT(x+plw-pth, rowY, x+plw, rowY+plh, rank2Col);
            LBRECT(x, rowY+plh-pth, x+plw, rowY+plh, rank2Col); LBRECT(x, rowY, x+plw, rowY+pth, rank2Col);
            x += psp;
            // T
            LBRECT(x, rowY+plh-pth, x+plw, rowY+plh, rank2Col);
            LBRECT(x+plw*0.5f-pth*0.5f, rowY, x+plw*0.5f+pth*0.5f, rowY+plh, rank2Col);
        }
        // Kill count for rank 2
        x = killsX + 0.03f;
        if (rank2Kills >= 10) {
            int tens = rank2Kills / 10;
            LBRECT(x+plw*0.5f-pth*0.5f, rowY, x+plw*0.5f+pth*0.5f, rowY+plh, rank2Col);
            x += psp * 0.7f;
        }
        ones = rank2Kills % 10;
        switch(ones) {
            case 0:
                LBRECT(x, rowY, x+pth, rowY+plh, rank2Col); LBRECT(x+plw-pth, rowY, x+plw, rowY+plh, rank2Col);
                LBRECT(x, rowY+plh-pth, x+plw, rowY+plh, rank2Col); LBRECT(x, rowY, x+plw, rowY+pth, rank2Col);
                break;
            case 1:
                LBRECT(x+plw*0.5f-pth*0.5f, rowY, x+plw*0.5f+pth*0.5f, rowY+plh, rank2Col);
                break;
            case 2:
                LBRECT(x, rowY+plh-pth, x+plw, rowY+plh, rank2Col); LBRECT(x+plw-pth, rowY+plh*0.5f, x+plw, rowY+plh, rank2Col);
                LBRECT(x, rowY+plh*0.45f, x+plw, rowY+plh*0.45f+pth, rank2Col);
                LBRECT(x, rowY, x+pth, rowY+plh*0.5f, rank2Col); LBRECT(x, rowY, x+plw, rowY+pth, rank2Col);
                break;
            case 3:
                LBRECT(x, rowY+plh-pth, x+plw, rowY+plh, rank2Col); LBRECT(x+plw-pth, rowY, x+plw, rowY+plh, rank2Col);
                LBRECT(x, rowY+plh*0.45f, x+plw, rowY+plh*0.45f+pth, rank2Col); LBRECT(x, rowY, x+plw, rowY+pth, rank2Col);
                break;
            case 4:
                LBRECT(x, rowY+plh*0.45f, x+pth, rowY+plh, rank2Col); LBRECT(x+plw-pth, rowY, x+plw, rowY+plh, rank2Col);
                LBRECT(x, rowY+plh*0.45f, x+plw, rowY+plh*0.45f+pth, rank2Col);
                break;
            case 5:
                LBRECT(x, rowY+plh-pth, x+plw, rowY+plh, rank2Col); LBRECT(x, rowY+plh*0.5f, x+pth, rowY+plh, rank2Col);
                LBRECT(x, rowY+plh*0.45f, x+plw, rowY+plh*0.45f+pth, rank2Col);
                LBRECT(x+plw-pth, rowY, x+plw, rowY+plh*0.5f, rank2Col); LBRECT(x, rowY, x+plw, rowY+pth, rank2Col);
                break;
            case 6:
                LBRECT(x, rowY, x+pth, rowY+plh, rank2Col); LBRECT(x, rowY+plh-pth, x+plw, rowY+plh, rank2Col);
                LBRECT(x, rowY+plh*0.45f, x+plw, rowY+plh*0.45f+pth, rank2Col);
                LBRECT(x+plw-pth, rowY, x+plw, rowY+plh*0.5f, rank2Col); LBRECT(x, rowY, x+plw, rowY+pth, rank2Col);
                break;
            case 7:
                LBRECT(x, rowY+plh-pth, x+plw, rowY+plh, rank2Col); LBRECT(x+plw-pth, rowY, x+plw, rowY+plh, rank2Col);
                break;
            case 8:
                LBRECT(x, rowY, x+pth, rowY+plh, rank2Col); LBRECT(x+plw-pth, rowY, x+plw, rowY+plh, rank2Col);
                LBRECT(x, rowY+plh-pth, x+plw, rowY+plh, rank2Col); LBRECT(x, rowY, x+plw, rowY+pth, rank2Col);
                LBRECT(x, rowY+plh*0.45f, x+plw, rowY+plh*0.45f+pth, rank2Col);
                break;
            case 9:
                LBRECT(x, rowY+plh*0.45f, x+pth, rowY+plh, rank2Col); LBRECT(x+plw-pth, rowY, x+plw, rowY+plh, rank2Col);
                LBRECT(x, rowY+plh-pth, x+plw, rowY+plh, rank2Col); LBRECT(x, rowY+plh*0.45f, x+plw, rowY+plh*0.45f+pth, rank2Col);
                LBRECT(x, rowY, x+plw, rowY+pth, rank2Col);
                break;
        }

        // Footer hint
        float footY = panelY + 0.03f;
        float flw = 0.018f, flh = 0.028f, fth = 0.004f, fsp = 0.022f;
        simd_float3 gray = {0.5f, 0.5f, 0.5f};
        x = panelX + 0.25f;
        // "FIRST TO 10"
        // F
        LBRECT(x, footY, x+fth, footY+flh, gray); LBRECT(x, footY+flh-fth, x+flw, footY+flh, gray);
        LBRECT(x, footY+flh*0.45f, x+flw*0.7f, footY+flh*0.45f+fth, gray);
        x += fsp;
        // I
        LBRECT(x+flw*0.5f-fth*0.5f, footY, x+flw*0.5f+fth*0.5f, footY+flh, gray);
        x += fsp;
        // R
        LBRECT(x, footY, x+fth, footY+flh, gray); LBRECT(x, footY+flh-fth, x+flw, footY+flh, gray);
        LBRECT(x+flw-fth, footY+flh*0.5f, x+flw, footY+flh, gray); LBRECT(x, footY+flh*0.45f, x+flw, footY+flh*0.45f+fth, gray);
        x += fsp;
        // S
        LBRECT(x, footY+flh-fth, x+flw, footY+flh, gray); LBRECT(x, footY+flh*0.5f, x+fth, footY+flh, gray);
        LBRECT(x, footY+flh*0.45f, x+flw, footY+flh*0.45f+fth, gray);
        LBRECT(x+flw-fth, footY, x+flw, footY+flh*0.5f, gray); LBRECT(x, footY, x+flw, footY+fth, gray);
        x += fsp;
        // T
        LBRECT(x, footY+flh-fth, x+flw, footY+flh, gray);
        LBRECT(x+flw*0.5f-fth*0.5f, footY, x+flw*0.5f+fth*0.5f, footY+flh, gray);
        x += fsp * 1.3f;
        // T
        LBRECT(x, footY+flh-fth, x+flw, footY+flh, gray);
        LBRECT(x+flw*0.5f-fth*0.5f, footY, x+flw*0.5f+fth*0.5f, footY+flh, gray);
        x += fsp;
        // O
        LBRECT(x, footY, x+fth, footY+flh, gray); LBRECT(x+flw-fth, footY, x+flw, footY+flh, gray);
        LBRECT(x, footY+flh-fth, x+flw, footY+flh, gray); LBRECT(x, footY, x+flw, footY+fth, gray);
        x += fsp * 1.3f;
        // 1
        LBRECT(x+flw*0.5f-fth*0.5f, footY, x+flw*0.5f+fth*0.5f, footY+flh, gray);
        x += fsp;
        // 0
        LBRECT(x, footY, x+fth, footY+flh, gray); LBRECT(x+flw-fth, footY, x+flw, footY+flh, gray);
        LBRECT(x, footY+flh-fth, x+flw, footY+flh, gray); LBRECT(x, footY, x+flw, footY+fth, gray);

        #undef LBRECT
        #undef MAX_LB_VERTS

        id<MTLBuffer> lbBuffer = [_device newBufferWithBytes:lbVerts length:sizeof(Vertex)*lbv options:MTLResourceStorageModeShared];
        [encoder setVertexBuffer:lbBuffer offset:0 atIndex:0];
        [encoder setVertexBytes:&IDENTITY_MATRIX length:sizeof(IDENTITY_MATRIX) atIndex:1];
        [encoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:lbv];
    }

    [encoder endEncoding];
    [commandBuffer presentDrawable:view.currentDrawable];
    [commandBuffer commit];
}

@end
