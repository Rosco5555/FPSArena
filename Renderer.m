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
#import "WeaponSystem.h"
#import "CollisionWorld.h"

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
@property (nonatomic, strong) id<MTLBuffer> pistolBuffer;
@property (nonatomic) NSUInteger pistolVertexCount;
@property (nonatomic, strong) id<MTLBuffer> shotgunBuffer;
@property (nonatomic) NSUInteger shotgunVertexCount;
@property (nonatomic, strong) id<MTLBuffer> rifleBuffer;
@property (nonatomic) NSUInteger rifleVertexCount;
@property (nonatomic, strong) id<MTLBuffer> rocketLauncherBuffer;
@property (nonatomic) NSUInteger rocketLauncherVertexCount;
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
        _pistolBuffer = [GeometryBuilder createPistolBufferWithDevice:device vertexCount:&_pistolVertexCount];
        _shotgunBuffer = [GeometryBuilder createShotgunBufferWithDevice:device vertexCount:&_shotgunVertexCount];
        _rifleBuffer = [GeometryBuilder createRifleBufferWithDevice:device vertexCount:&_rifleVertexCount];
        _rocketLauncherBuffer = [GeometryBuilder createRocketLauncherBufferWithDevice:device vertexCount:&_rocketLauncherVertexCount];
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
        // Bunker removed
        // _bunkerBuffer = [GeometryBuilder createBunkerBufferWithDevice:device vertexCount:&_bunkerVertexCount];
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

    // Handle respawn teleport
    if (state.needsRespawnTeleport) {
        state.needsRespawnTeleport = NO;
        _metalView.posX = state.respawnX;
        _metalView.posY = state.respawnY;
        _metalView.posZ = state.respawnZ;
        _metalView.camYaw = state.respawnYaw;
        _metalView.camPitch = 0;
        _metalView.velocityX = 0;
        _metalView.velocityY = 0;
        _metalView.velocityZ = 0;
        _metalView.onGround = YES;
        NSLog(@"[RENDERER] Teleported to respawn point");
    }

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

        // --- STEP 4: Collision detection using CollisionWorld ---
        CollisionWorld *collisionWorld = [CollisionWorld shared];
        BOOL wasOnGround = _metalView.onGround;
        _metalView.onGround = NO;

        float px = _metalView.posX;
        float py = _metalView.posY;
        float pz = _metalView.posZ;
        // --- GROUND DETECTION using CollisionWorld ---
        GroundResult groundResult = [collisionWorld checkGroundAt:px y:py z:pz
                                                     playerRadius:PLAYER_RADIUS
                                                     playerHeight:PLAYER_HEIGHT];

        // Apply ground collision
        if (groundResult.onGround) {
            _metalView.posY = groundResult.groundY + PLAYER_HEIGHT;
            _metalView.velocityY = 0;
            _metalView.onGround = YES;

            // Auto-jump when holding space (bunny hop)
            if (_metalView.keySpace) {
                _metalView.velocityY = JUMP_VELOCITY;
                _metalView.onGround = NO;

                // Bhop acceleration - boost horizontal speed each hop
                float hSpeed = sqrtf(_metalView.velocityX * _metalView.velocityX + _metalView.velocityZ * _metalView.velocityZ);
                if (hSpeed > 0.01f && hSpeed < BHOP_MAX_SPEED) {
                    float boost = fminf(BHOP_SPEED_BOOST, BHOP_MAX_SPEED / hSpeed);
                    _metalView.velocityX *= boost;
                    _metalView.velocityZ *= boost;
                }
            }
        }

        // Update position after ground snap
        px = _metalView.posX;
        py = _metalView.posY;
        pz = _metalView.posZ;

        // --- WALL COLLISION using CollisionWorld ---
        simd_float3 playerPos = {px, py, pz};
        simd_float3 playerVel = {_metalView.velocityX, _metalView.velocityY, _metalView.velocityZ};
        MoveResult moveResult = [collisionWorld movePlayerFrom:playerPos
                                                      velocity:playerVel
                                                        radius:PLAYER_RADIUS
                                                        height:PLAYER_HEIGHT];

        if (moveResult.collided) {
            _metalView.posX += moveResult.pushOut.x;
            _metalView.posY += moveResult.pushOut.y;
            _metalView.posZ += moveResult.pushOut.z;
            _metalView.velocityX = moveResult.newVelocity.x;
            _metalView.velocityY = moveResult.newVelocity.y;
            _metalView.velocityZ = moveResult.newVelocity.z;

            // Check if we landed on something
            if (moveResult.pushOut.y > 0 && _metalView.velocityY == 0) {
                _metalView.onGround = YES;
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

        // Handle shooting (automatic fire when holding mouse)
        BOOL shouldFire = _metalView.wantsClick || (_metalView.mouseHeld && _metalView.fireTimer == 0);
        _metalView.wantsClick = NO;

        if (shouldFire && _metalView.controlsActive && !state.gameOver) {
            _metalView.fireTimer = PLAYER_FIRE_RATE;
            _metalView.gunRecoil = 0.6f;
            CombatHitResult hitResult = processPlayerShooting(camPos, _metalView.camYaw, _metalView.camPitch);

            // In multiplayer, send hit notification if we hit the remote player
            if (state.isMultiplayer && hitResult.type == HitResultRemotePlayer) {
                NSLog(@"HIT DETECTED on remote player! Sending damage: %d", PVP_DAMAGE);
                [[MultiplayerController shared] sendHitOnRemotePlayer:PVP_DAMAGE];
            } else if (state.isMultiplayer) {
                NSLog(@"Shot fired - hitType: %d, isMP: %d, remoteAlive: %d", hitResult.type, state.isMultiplayer, state.remotePlayerAlive);
            }
        }

        // Enemy AI
        updateEnemyAI(camPos, _metalView.controlsActive);

        // Update pickup system
        PickupSystem *pickupSystem = [PickupSystem shared];
        [pickupSystem updatePickups:1.0f];  // 1 frame delta

        // Check for pickup collection
        if (!state.gameOver) {
            PickupResult result = [pickupSystem checkPlayerPickup:camPos];
            if (result.collected) {
                // Set notification based on pickup type
                state.pickupNotificationTimer = 180;  // 3 seconds at 60fps
                switch (result.type) {
                    case PickupTypeHealthPack:
                        state.pickupNotificationText = @"+50 HEALTH";
                        break;
                    case PickupTypeAmmoSmall:
                        state.pickupNotificationText = @"+30 AMMO";
                        break;
                    case PickupTypeAmmoHeavy:
                        state.pickupNotificationText = @"+10 HEAVY AMMO";
                        break;
                    case PickupTypeShotgun:
                        state.pickupNotificationText = @"SHOTGUN ACQUIRED";
                        break;
                    case PickupTypeAssaultRifle:
                        state.pickupNotificationText = @"ASSAULT RIFLE ACQUIRED";
                        break;
                    case PickupTypeRocketLauncher:
                        state.pickupNotificationText = @"ROCKET LAUNCHER ACQUIRED";
                        break;
                    case PickupTypeArmor:
                        state.pickupNotificationText = @"+50 ARMOR";
                        break;
                }
            }
        }

        // Update pickup notification timer
        if (state.pickupNotificationTimer > 0) {
            state.pickupNotificationTimer--;
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

    // Bunker removed
    // [encoder setVertexBuffer:_bunkerBuffer offset:0 atIndex:0];
    // [encoder setVertexBytes:&mvp length:sizeof(mvp) atIndex:1];
    // [encoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:_bunkerVertexCount];

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

        // Remote player Y is eye position - convert to model position
        // Model has feet at -0.6 (scaled: -0.84), so we place model origin at:
        // footY + 0.84 = (eyeY - PLAYER_HEIGHT) + 0.84
        float modelY = rpY - PLAYER_HEIGHT + (0.6f * playerScale);

        simd_float4x4 rpRot = {{
            {cosRP * playerScale, 0, -sinRP * playerScale, 0}, {0, playerScale, 0, 0},
            {sinRP * playerScale, 0, cosRP * playerScale, 0}, {0, 0, 0, 1}
        }};
        simd_float4x4 rpTrans = {{
            {1, 0, 0, 0}, {0, 1, 0, 0}, {0, 0, 1, 0}, {rpX, modelY, rpZ, 1}
        }};
        simd_float4x4 rpModel = simd_mul(rpTrans, rpRot);
        simd_float4x4 rpMvp = simd_mul(proj, simd_mul(viewMat, rpModel));

        [encoder setVertexBuffer:_remotePlayerBuffer offset:0 atIndex:0];
        [encoder setVertexBytes:&rpMvp length:sizeof(rpMvp) atIndex:1];
        [encoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:_remotePlayerVertexCount];

        // Check if remote player is visible (not behind walls) before drawing health bar
        // Use chest height of the model for visibility check
        simd_float3 rpPos = {rpX, modelY + 0.3f, rpZ};
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
            // Position health bar above head (model head top is at modelY + 1.12)
            float hbY = modelY + 1.3f;
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

    // Draw pause menu when paused
    if (state.showPauseMenu && !state.gameOver) {
        [encoder setRenderPipelineState:_bgPipelineState];
        [encoder setDepthStencilState:_bgDepthState];

        #define MAX_PAUSE_MENU_VERTS 3000
        Vertex pauseMenuVerts[MAX_PAUSE_MENU_VERTS];
        int pmv = 0;

        // Helper macro for menu quads
        #define PAUSE_QUAD(x0,y0,x1,y1,col) do { \
            pauseMenuVerts[pmv++] = (Vertex){{x0,y0,0},col}; \
            pauseMenuVerts[pmv++] = (Vertex){{x1,y0,0},col}; \
            pauseMenuVerts[pmv++] = (Vertex){{x1,y1,0},col}; \
            pauseMenuVerts[pmv++] = (Vertex){{x0,y0,0},col}; \
            pauseMenuVerts[pmv++] = (Vertex){{x1,y1,0},col}; \
            pauseMenuVerts[pmv++] = (Vertex){{x0,y1,0},col}; \
        } while(0)

        // Colors
        simd_float3 overlayColor = {0.0f, 0.0f, 0.0f};
        simd_float3 panelColor = {0.12f, 0.12f, 0.18f};
        simd_float3 borderColor = {0.4f, 0.35f, 0.2f};
        simd_float3 buttonColor = {0.22f, 0.22f, 0.28f};
        simd_float3 hoverColor = {0.32f, 0.32f, 0.42f};
        simd_float3 accentColor = {1.0f, 0.85f, 0.0f};  // Gold
        simd_float3 textColor = {0.95f, 0.95f, 0.95f};
        simd_float3 dimTextColor = {0.7f, 0.7f, 0.75f};
        simd_float3 sliderBgColor = {0.08f, 0.08f, 0.12f};
        simd_float3 sliderFgColor = {0.25f, 0.65f, 0.35f};
        simd_float3 knobColor = {0.9f, 0.9f, 0.95f};

        // Semi-transparent background overlay
        PAUSE_QUAD(-1.0f, -1.0f, 1.0f, 1.0f, overlayColor);

        // Menu panel with border
        float panelLeft = -0.52f;
        float panelRight = 0.52f;
        float panelTop = 0.52f;
        float panelBottom = -0.38f;
        float borderW = 0.008f;

        // Panel border (gold accent)
        PAUSE_QUAD(panelLeft - borderW, panelBottom - borderW, panelRight + borderW, panelTop + borderW, borderColor);
        // Panel background
        PAUSE_QUAD(panelLeft, panelBottom, panelRight, panelTop, panelColor);

        // Menu title "PAUSED" text
        float titleY = 0.38f;
        float lw = 0.038f;
        float lh = 0.07f;
        float th = 0.009f;
        float sp = 0.048f;
        float startX = -0.13f;

        // P
        float x = startX;
        PAUSE_QUAD(x, titleY, x+th, titleY+lh, accentColor);
        PAUSE_QUAD(x, titleY+lh-th, x+lw, titleY+lh, accentColor);
        PAUSE_QUAD(x+lw-th, titleY+lh*0.5f, x+lw, titleY+lh, accentColor);
        PAUSE_QUAD(x, titleY+lh*0.5f-th*0.5f, x+lw, titleY+lh*0.5f+th*0.5f, accentColor);
        // A
        x += sp;
        PAUSE_QUAD(x, titleY, x+th, titleY+lh, accentColor);
        PAUSE_QUAD(x+lw-th, titleY, x+lw, titleY+lh, accentColor);
        PAUSE_QUAD(x, titleY+lh-th, x+lw, titleY+lh, accentColor);
        PAUSE_QUAD(x, titleY+lh*0.5f-th*0.5f, x+lw, titleY+lh*0.5f+th*0.5f, accentColor);
        // U
        x += sp;
        PAUSE_QUAD(x, titleY, x+th, titleY+lh, accentColor);
        PAUSE_QUAD(x+lw-th, titleY, x+lw, titleY+lh, accentColor);
        PAUSE_QUAD(x, titleY, x+lw, titleY+th, accentColor);
        // S
        x += sp;
        PAUSE_QUAD(x, titleY+lh-th, x+lw, titleY+lh, accentColor);
        PAUSE_QUAD(x, titleY+lh*0.5f, x+th, titleY+lh, accentColor);
        PAUSE_QUAD(x, titleY+lh*0.5f-th*0.5f, x+lw, titleY+lh*0.5f+th*0.5f, accentColor);
        PAUSE_QUAD(x+lw-th, titleY, x+lw, titleY+lh*0.5f, accentColor);
        PAUSE_QUAD(x, titleY, x+lw, titleY+th, accentColor);
        // E
        x += sp;
        PAUSE_QUAD(x, titleY, x+th, titleY+lh, accentColor);
        PAUSE_QUAD(x, titleY+lh-th, x+lw, titleY+lh, accentColor);
        PAUSE_QUAD(x, titleY, x+lw, titleY+th, accentColor);
        PAUSE_QUAD(x, titleY+lh*0.5f-th*0.5f, x+lw*0.7f, titleY+lh*0.5f+th*0.5f, accentColor);
        // D
        x += sp;
        PAUSE_QUAD(x, titleY, x+th, titleY+lh, accentColor);
        PAUSE_QUAD(x, titleY+lh-th, x+lw*0.7f, titleY+lh, accentColor);
        PAUSE_QUAD(x, titleY, x+lw*0.7f, titleY+th, accentColor);
        PAUSE_QUAD(x+lw-th, titleY+th, x+lw, titleY+lh-th, accentColor);

        // Menu items layout
        float itemHeight = 0.09f;
        float menuTop = 0.28f;
        float itemSpacing = 0.115f;
        float itemLeft = -0.46f;
        float itemRight = 0.46f;

        // Slider layout
        float sliderLeft = -0.38f;
        float sliderRight = 0.38f;
        float sliderHeight = 0.018f;

        // Helper for drawing letters (compact inline)
        #define LETTER_S(lx, ly, lh, lt, lw, c) do { \
            PAUSE_QUAD(lx, ly+lh-lt, lx+lw, ly+lh, c); \
            PAUSE_QUAD(lx, ly+lh*0.5f, lx+lt, ly+lh, c); \
            PAUSE_QUAD(lx, ly+lh*0.45f, lx+lw, ly+lh*0.55f, c); \
            PAUSE_QUAD(lx+lw-lt, ly, lx+lw, ly+lh*0.5f, c); \
            PAUSE_QUAD(lx, ly, lx+lw, ly+lt, c); \
        } while(0)

        #define LETTER_E(lx, ly, lh, lt, lw, c) do { \
            PAUSE_QUAD(lx, ly, lx+lt, ly+lh, c); \
            PAUSE_QUAD(lx, ly+lh-lt, lx+lw, ly+lh, c); \
            PAUSE_QUAD(lx, ly, lx+lw, ly+lt, c); \
            PAUSE_QUAD(lx, ly+lh*0.45f, lx+lw*0.75f, ly+lh*0.55f, c); \
        } while(0)

        #define LETTER_N(lx, ly, lh, lt, lw, c) do { \
            PAUSE_QUAD(lx, ly, lx+lt, ly+lh, c); \
            PAUSE_QUAD(lx+lw-lt, ly, lx+lw, ly+lh, c); \
            PAUSE_QUAD(lx, ly+lh-lt, lx+lw, ly+lh, c); \
        } while(0)

        #define LETTER_I(lx, ly, lh, lt, lw, c) do { \
            PAUSE_QUAD(lx+lw*0.5f-lt*0.5f, ly, lx+lw*0.5f+lt*0.5f, ly+lh, c); \
            PAUSE_QUAD(lx, ly, lx+lw, ly+lt, c); \
            PAUSE_QUAD(lx, ly+lh-lt, lx+lw, ly+lh, c); \
        } while(0)

        #define LETTER_T(lx, ly, lh, lt, lw, c) do { \
            PAUSE_QUAD(lx+lw*0.5f-lt*0.5f, ly, lx+lw*0.5f+lt*0.5f, ly+lh, c); \
            PAUSE_QUAD(lx, ly+lh-lt, lx+lw, ly+lh, c); \
        } while(0)

        #define LETTER_V(lx, ly, lh, lt, lw, c) do { \
            PAUSE_QUAD(lx, ly+lh*0.4f, lx+lt, ly+lh, c); \
            PAUSE_QUAD(lx+lw-lt, ly+lh*0.4f, lx+lw, ly+lh, c); \
            PAUSE_QUAD(lx+lw*0.5f-lt*0.6f, ly, lx+lw*0.5f+lt*0.6f, ly+lh*0.5f, c); \
        } while(0)

        #define LETTER_O(lx, ly, lh, lt, lw, c) do { \
            PAUSE_QUAD(lx, ly, lx+lt, ly+lh, c); \
            PAUSE_QUAD(lx+lw-lt, ly, lx+lw, ly+lh, c); \
            PAUSE_QUAD(lx, ly+lh-lt, lx+lw, ly+lh, c); \
            PAUSE_QUAD(lx, ly, lx+lw, ly+lt, c); \
        } while(0)

        #define LETTER_L(lx, ly, lh, lt, lw, c) do { \
            PAUSE_QUAD(lx, ly, lx+lt, ly+lh, c); \
            PAUSE_QUAD(lx, ly, lx+lw, ly+lt, c); \
        } while(0)

        #define LETTER_U(lx, ly, lh, lt, lw, c) do { \
            PAUSE_QUAD(lx, ly, lx+lt, ly+lh, c); \
            PAUSE_QUAD(lx+lw-lt, ly, lx+lw, ly+lh, c); \
            PAUSE_QUAD(lx, ly, lx+lw, ly+lt, c); \
        } while(0)

        #define LETTER_M(lx, ly, lh, lt, lw, c) do { \
            PAUSE_QUAD(lx, ly, lx+lt, ly+lh, c); \
            PAUSE_QUAD(lx+lw-lt, ly, lx+lw, ly+lh, c); \
            PAUSE_QUAD(lx, ly+lh-lt, lx+lw, ly+lh, c); \
            PAUSE_QUAD(lx+lw*0.5f-lt*0.5f, ly+lh*0.4f, lx+lw*0.5f+lt*0.5f, ly+lh, c); \
        } while(0)

        #define LETTER_R(lx, ly, lh, lt, lw, c) do { \
            PAUSE_QUAD(lx, ly, lx+lt, ly+lh, c); \
            PAUSE_QUAD(lx, ly+lh-lt, lx+lw, ly+lh, c); \
            PAUSE_QUAD(lx+lw-lt, ly+lh*0.5f, lx+lw, ly+lh, c); \
            PAUSE_QUAD(lx, ly+lh*0.45f, lx+lw, ly+lh*0.55f, c); \
            PAUSE_QUAD(lx+lw*0.4f, ly, lx+lw, ly+lh*0.45f, c); \
        } while(0)

        #define LETTER_A(lx, ly, lh, lt, lw, c) do { \
            PAUSE_QUAD(lx, ly, lx+lt, ly+lh, c); \
            PAUSE_QUAD(lx+lw-lt, ly, lx+lw, ly+lh, c); \
            PAUSE_QUAD(lx, ly+lh-lt, lx+lw, ly+lh, c); \
            PAUSE_QUAD(lx, ly+lh*0.45f, lx+lw, ly+lh*0.55f, c); \
        } while(0)

        #define LETTER_Y(lx, ly, lh, lt, lw, c) do { \
            PAUSE_QUAD(lx, ly+lh*0.5f, lx+lt, ly+lh, c); \
            PAUSE_QUAD(lx+lw-lt, ly+lh*0.5f, lx+lw, ly+lh, c); \
            PAUSE_QUAD(lx+lw*0.5f-lt*0.5f, ly, lx+lw*0.5f+lt*0.5f, ly+lh*0.55f, c); \
            PAUSE_QUAD(lx, ly+lh*0.45f, lx+lw*0.55f, ly+lh*0.55f, c); \
            PAUSE_QUAD(lx+lw*0.45f, ly+lh*0.45f, lx+lw, ly+lh*0.55f, c); \
        } while(0)

        // Menu item 0: Resume
        {
            simd_float3 col = (state.pauseMenuSelection == 0) ? hoverColor : buttonColor;
            float itemTop = menuTop;
            float itemBottom = itemTop - itemHeight;
            PAUSE_QUAD(itemLeft, itemBottom, itemRight, itemTop, col);

            // "RESUME" text centered
            float txtH = 0.032f;
            float txtTh = 0.006f;
            float txtLw = 0.022f;
            float txtSp = 0.028f;
            float txtY = itemBottom + (itemHeight - txtH) * 0.5f;
            float txtX = -0.08f;

            LETTER_R(txtX, txtY, txtH, txtTh, txtLw, textColor); txtX += txtSp;
            LETTER_E(txtX, txtY, txtH, txtTh, txtLw, textColor); txtX += txtSp;
            LETTER_S(txtX, txtY, txtH, txtTh, txtLw, textColor); txtX += txtSp;
            LETTER_U(txtX, txtY, txtH, txtTh, txtLw, textColor); txtX += txtSp;
            LETTER_M(txtX, txtY, txtH, txtTh, txtLw, textColor); txtX += txtSp;
            LETTER_E(txtX, txtY, txtH, txtTh, txtLw, textColor);
        }

        // Menu item 1: Sensitivity with slider
        {
            simd_float3 col = (state.pauseMenuSelection == 1) ? hoverColor : buttonColor;
            float itemTop = menuTop - 1 * itemSpacing;
            float itemBottom = itemTop - itemHeight;
            PAUSE_QUAD(itemLeft, itemBottom, itemRight, itemTop, col);

            // "SENSITIVITY" label
            float lblH = 0.022f;
            float lblTh = 0.004f;
            float lblLw = 0.014f;
            float lblSp = 0.018f;
            float lblY = itemTop - 0.032f;
            float lblX = -0.13f;  // Start position for "SENSITIVITY"

            LETTER_S(lblX, lblY, lblH, lblTh, lblLw, dimTextColor); lblX += lblSp;
            LETTER_E(lblX, lblY, lblH, lblTh, lblLw, dimTextColor); lblX += lblSp;
            LETTER_N(lblX, lblY, lblH, lblTh, lblLw, dimTextColor); lblX += lblSp;
            LETTER_S(lblX, lblY, lblH, lblTh, lblLw, dimTextColor); lblX += lblSp;
            LETTER_I(lblX, lblY, lblH, lblTh, lblLw, dimTextColor); lblX += lblSp;
            LETTER_T(lblX, lblY, lblH, lblTh, lblLw, dimTextColor); lblX += lblSp;
            LETTER_I(lblX, lblY, lblH, lblTh, lblLw, dimTextColor); lblX += lblSp;
            LETTER_V(lblX, lblY, lblH, lblTh, lblLw, dimTextColor); lblX += lblSp;
            LETTER_I(lblX, lblY, lblH, lblTh, lblLw, dimTextColor); lblX += lblSp;
            LETTER_T(lblX, lblY, lblH, lblTh, lblLw, dimTextColor); lblX += lblSp;
            LETTER_Y(lblX, lblY, lblH, lblTh, lblLw, dimTextColor);

            // Slider track background
            float sliderY = itemBottom + itemHeight * 0.22f;
            PAUSE_QUAD(sliderLeft, sliderY, sliderRight, sliderY + sliderHeight, sliderBgColor);

            // Slider fill
            float sensNorm = (state.mouseSensitivity - 0.001f) / (0.02f - 0.001f);
            if (sensNorm < 0) sensNorm = 0;
            if (sensNorm > 1) sensNorm = 1;
            float fillRight = sliderLeft + (sliderRight - sliderLeft) * sensNorm;
            PAUSE_QUAD(sliderLeft, sliderY, fillRight, sliderY + sliderHeight, sliderFgColor);

            // Slider knob (larger, rounded appearance with multiple quads)
            float knobW = 0.025f;
            float knobH = 0.035f;
            float knobX = fillRight;
            float knobY = sliderY + sliderHeight * 0.5f;
            PAUSE_QUAD(knobX - knobW*0.5f, knobY - knobH*0.5f, knobX + knobW*0.5f, knobY + knobH*0.5f, knobColor);
            // Knob highlight
            simd_float3 knobHighlight = {1.0f, 1.0f, 1.0f};
            PAUSE_QUAD(knobX - knobW*0.35f, knobY, knobX + knobW*0.35f, knobY + knobH*0.35f, knobHighlight);
        }

        // Menu item 2: Volume with slider
        {
            simd_float3 col = (state.pauseMenuSelection == 2) ? hoverColor : buttonColor;
            float itemTop = menuTop - 2 * itemSpacing;
            float itemBottom = itemTop - itemHeight;
            PAUSE_QUAD(itemLeft, itemBottom, itemRight, itemTop, col);

            // "VOLUME" label
            float lblH = 0.022f;
            float lblTh = 0.004f;
            float lblLw = 0.014f;
            float lblSp = 0.018f;
            float lblY = itemTop - 0.032f;
            float lblX = -0.06f;  // Centered for "VOLUME"

            LETTER_V(lblX, lblY, lblH, lblTh, lblLw, dimTextColor); lblX += lblSp;
            LETTER_O(lblX, lblY, lblH, lblTh, lblLw, dimTextColor); lblX += lblSp;
            LETTER_L(lblX, lblY, lblH, lblTh, lblLw, dimTextColor); lblX += lblSp;
            LETTER_U(lblX, lblY, lblH, lblTh, lblLw, dimTextColor); lblX += lblSp;
            LETTER_M(lblX, lblY, lblH, lblTh, lblLw, dimTextColor); lblX += lblSp;
            LETTER_E(lblX, lblY, lblH, lblTh, lblLw, dimTextColor);

            // Slider track background
            float sliderY = itemBottom + itemHeight * 0.22f;
            PAUSE_QUAD(sliderLeft, sliderY, sliderRight, sliderY + sliderHeight, sliderBgColor);

            // Slider fill
            float volNorm = state.masterVolume;
            if (volNorm < 0) volNorm = 0;
            if (volNorm > 1) volNorm = 1;
            float fillRight = sliderLeft + (sliderRight - sliderLeft) * volNorm;
            PAUSE_QUAD(sliderLeft, sliderY, fillRight, sliderY + sliderHeight, sliderFgColor);

            // Slider knob
            float knobW = 0.025f;
            float knobH = 0.035f;
            float knobX = fillRight;
            float knobY = sliderY + sliderHeight * 0.5f;
            PAUSE_QUAD(knobX - knobW*0.5f, knobY - knobH*0.5f, knobX + knobW*0.5f, knobY + knobH*0.5f, knobColor);
            simd_float3 knobHighlight = {1.0f, 1.0f, 1.0f};
            PAUSE_QUAD(knobX - knobW*0.35f, knobY, knobX + knobW*0.35f, knobY + knobH*0.35f, knobHighlight);
        }

        // Menu item 3: Main Menu
        {
            simd_float3 col = (state.pauseMenuSelection == 3) ? hoverColor : buttonColor;
            float itemTop = menuTop - 3 * itemSpacing;
            float itemBottom = itemTop - itemHeight;
            PAUSE_QUAD(itemLeft, itemBottom, itemRight, itemTop, col);

            // "MAIN MENU" text centered
            float txtH = 0.032f;
            float txtTh = 0.006f;
            float txtLw = 0.022f;
            float txtSp = 0.028f;
            float txtY = itemBottom + (itemHeight - txtH) * 0.5f;
            float txtX = -0.14f;

            LETTER_M(txtX, txtY, txtH, txtTh, txtLw, textColor); txtX += txtSp;
            LETTER_A(txtX, txtY, txtH, txtTh, txtLw, textColor); txtX += txtSp;
            LETTER_I(txtX, txtY, txtH, txtTh, txtLw, textColor); txtX += txtSp;
            LETTER_N(txtX, txtY, txtH, txtTh, txtLw, textColor); txtX += txtSp * 1.3f;
            LETTER_M(txtX, txtY, txtH, txtTh, txtLw, textColor); txtX += txtSp;
            LETTER_E(txtX, txtY, txtH, txtTh, txtLw, textColor); txtX += txtSp;
            LETTER_N(txtX, txtY, txtH, txtTh, txtLw, textColor); txtX += txtSp;
            LETTER_U(txtX, txtY, txtH, txtTh, txtLw, textColor);
        }

        // Cleanup macros
        #undef PAUSE_QUAD
        #undef LETTER_S
        #undef LETTER_E
        #undef LETTER_N
        #undef LETTER_I
        #undef LETTER_T
        #undef LETTER_V
        #undef LETTER_O
        #undef LETTER_L
        #undef LETTER_U
        #undef LETTER_M
        #undef LETTER_R
        #undef LETTER_A
        #undef LETTER_Y

        // Render pause menu
        id<MTLBuffer> pauseMenuBuffer = [_device newBufferWithBytes:pauseMenuVerts length:sizeof(Vertex)*pmv options:MTLResourceStorageModeShared];
        [encoder setVertexBuffer:pauseMenuBuffer offset:0 atIndex:0];
        [encoder setVertexBytes:&IDENTITY_MATRIX length:sizeof(IDENTITY_MATRIX) atIndex:1];
        [encoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:pmv];

        #undef MAX_PAUSE_MENU_VERTS
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

    // ============================================
    // WEAPON & AMMO HUD
    // ============================================
    if (!state.gameOver && !_metalView.escapedLock) {
        #define MAX_AMMO_HUD_VERTS 2000
        Vertex ammoHudVerts[MAX_AMMO_HUD_VERTS];
        int ahv = 0;

        #define HUD_QUAD(x0,y0,x1,y1,col) do { \
            ammoHudVerts[ahv++] = (Vertex){{x0,y0,0},col}; \
            ammoHudVerts[ahv++] = (Vertex){{x1,y0,0},col}; \
            ammoHudVerts[ahv++] = (Vertex){{x1,y1,0},col}; \
            ammoHudVerts[ahv++] = (Vertex){{x0,y0,0},col}; \
            ammoHudVerts[ahv++] = (Vertex){{x1,y1,0},col}; \
            ammoHudVerts[ahv++] = (Vertex){{x0,y1,0},col}; \
        } while(0)

        // Colors
        simd_float3 white = {1.0f, 1.0f, 1.0f};
        simd_float3 gold = {1.0f, 0.85f, 0.0f};
        simd_float3 dimWhite = {0.7f, 0.7f, 0.7f};
        simd_float3 darkBg = {0.1f, 0.1f, 0.15f};
        simd_float3 slotBg = {0.2f, 0.2f, 0.25f};
        simd_float3 red = {1.0f, 0.3f, 0.3f};
        simd_float3 green = {0.3f, 1.0f, 0.3f};

        // ---- KILL COUNTER (top-center, single-player only) ----
        if (!state.isMultiplayer) {
            float kcX = -0.18f;  // Starting X position
            float kcY = 0.88f;   // Top of screen
            float kcBgW = 0.36f;
            float kcBgH = 0.10f;

            // Background
            HUD_QUAD(kcX, kcY, kcX + kcBgW, kcY + kcBgH, darkBg);

            // "KILLS:" label
            float lh = 0.045f, lt = 0.006f, lw = 0.024f, lsp = 0.028f;
            float lx = kcX + 0.015f;
            float ly = kcY + 0.028f;
            simd_float3 lblCol = dimWhite;

            // K
            HUD_QUAD(lx, ly, lx+lt, ly+lh, lblCol);
            HUD_QUAD(lx, ly+lh*0.45f, lx+lw*0.5f, ly+lh*0.55f, lblCol);
            HUD_QUAD(lx+lw*0.4f, ly+lh*0.5f, lx+lw, ly+lh, lblCol);
            HUD_QUAD(lx+lw*0.4f, ly, lx+lw, ly+lh*0.5f, lblCol);
            lx += lsp;
            // I
            HUD_QUAD(lx+lw*0.5f-lt*0.5f, ly, lx+lw*0.5f+lt*0.5f, ly+lh, lblCol);
            HUD_QUAD(lx, ly, lx+lw, ly+lt, lblCol);
            HUD_QUAD(lx, ly+lh-lt, lx+lw, ly+lh, lblCol);
            lx += lsp;
            // L
            HUD_QUAD(lx, ly, lx+lt, ly+lh, lblCol);
            HUD_QUAD(lx, ly, lx+lw, ly+lt, lblCol);
            lx += lsp;
            // L
            HUD_QUAD(lx, ly, lx+lt, ly+lh, lblCol);
            HUD_QUAD(lx, ly, lx+lw, ly+lt, lblCol);
            lx += lsp;
            // S
            HUD_QUAD(lx, ly+lh-lt, lx+lw, ly+lh, lblCol);
            HUD_QUAD(lx, ly+lh*0.5f, lx+lt, ly+lh, lblCol);
            HUD_QUAD(lx, ly+lh*0.45f, lx+lw, ly+lh*0.55f, lblCol);
            HUD_QUAD(lx+lw-lt, ly, lx+lw, ly+lh*0.5f, lblCol);
            HUD_QUAD(lx, ly, lx+lw, ly+lt, lblCol);
            lx += lsp + 0.01f;

            // Kill count number
            int kills = state.killCount;
            float dw = 0.028f, dh = 0.05f, dt = 0.006f, ds = 0.035f;
            float dx = lx;
            float dy = kcY + 0.025f;
            simd_float3 numCol = gold;

            #define KILL_DIGIT(d, px, py, c) do { \
                if (d == 0) { HUD_QUAD(px, py, px+dt, py+dh, c); HUD_QUAD(px+dw-dt, py, px+dw, py+dh, c); HUD_QUAD(px, py+dh-dt, px+dw, py+dh, c); HUD_QUAD(px, py, px+dw, py+dt, c); } \
                else if (d == 1) { HUD_QUAD(px+dw*0.5f-dt*0.5f, py, px+dw*0.5f+dt*0.5f, py+dh, c); } \
                else if (d == 2) { HUD_QUAD(px, py+dh-dt, px+dw, py+dh, c); HUD_QUAD(px+dw-dt, py+dh*0.5f, px+dw, py+dh, c); HUD_QUAD(px, py+dh*0.45f, px+dw, py+dh*0.55f, c); HUD_QUAD(px, py, px+dt, py+dh*0.5f, c); HUD_QUAD(px, py, px+dw, py+dt, c); } \
                else if (d == 3) { HUD_QUAD(px, py+dh-dt, px+dw, py+dh, c); HUD_QUAD(px+dw-dt, py, px+dw, py+dh, c); HUD_QUAD(px, py+dh*0.45f, px+dw, py+dh*0.55f, c); HUD_QUAD(px, py, px+dw, py+dt, c); } \
                else if (d == 4) { HUD_QUAD(px, py+dh*0.5f, px+dt, py+dh, c); HUD_QUAD(px+dw-dt, py, px+dw, py+dh, c); HUD_QUAD(px, py+dh*0.45f, px+dw, py+dh*0.55f, c); } \
                else if (d == 5) { HUD_QUAD(px, py+dh-dt, px+dw, py+dh, c); HUD_QUAD(px, py+dh*0.5f, px+dt, py+dh, c); HUD_QUAD(px, py+dh*0.45f, px+dw, py+dh*0.55f, c); HUD_QUAD(px+dw-dt, py, px+dw, py+dh*0.5f, c); HUD_QUAD(px, py, px+dw, py+dt, c); } \
                else if (d == 6) { HUD_QUAD(px, py, px+dt, py+dh, c); HUD_QUAD(px, py+dh-dt, px+dw, py+dh, c); HUD_QUAD(px, py+dh*0.45f, px+dw, py+dh*0.55f, c); HUD_QUAD(px+dw-dt, py, px+dw, py+dh*0.5f, c); HUD_QUAD(px, py, px+dw, py+dt, c); } \
                else if (d == 7) { HUD_QUAD(px, py+dh-dt, px+dw, py+dh, c); HUD_QUAD(px+dw-dt, py, px+dw, py+dh, c); } \
                else if (d == 8) { HUD_QUAD(px, py, px+dt, py+dh, c); HUD_QUAD(px+dw-dt, py, px+dw, py+dh, c); HUD_QUAD(px, py+dh-dt, px+dw, py+dh, c); HUD_QUAD(px, py+dh*0.45f, px+dw, py+dh*0.55f, c); HUD_QUAD(px, py, px+dw, py+dt, c); } \
                else if (d == 9) { HUD_QUAD(px, py+dh*0.5f, px+dt, py+dh, c); HUD_QUAD(px+dw-dt, py, px+dw, py+dh, c); HUD_QUAD(px, py+dh-dt, px+dw, py+dh, c); HUD_QUAD(px, py+dh*0.45f, px+dw, py+dh*0.55f, c); HUD_QUAD(px, py, px+dw, py+dt, c); } \
            } while(0)

            if (kills >= 100) { KILL_DIGIT(kills / 100, dx, dy, numCol); dx += ds; }
            if (kills >= 10) { KILL_DIGIT((kills / 10) % 10, dx, dy, numCol); dx += ds; }
            KILL_DIGIT(kills % 10, dx, dy, numCol);

            #undef KILL_DIGIT
        }

        WeaponSystem *ws = [WeaponSystem shared];
        WeaponType currentWeapon = [ws getCurrentWeapon];
        int currentAmmo = [ws getCurrentAmmo];
        int reserveAmmo = [ws getReserveAmmo];

        // ---- WEAPON SLOTS (bottom-middle) ----
        float slotW = 0.18f;
        float slotH = 0.07f;
        float slotGap = 0.01f;
        float totalWidth = 4 * slotW + 3 * slotGap;
        float slotStartX = -totalWidth / 2.0f;
        float slotY = -0.98f;

        // Letter rendering dimensions for weapon names
        float lh = 0.035f;
        float lt = 0.005f;
        float lw = 0.018f;
        float lsp = 0.022f;

        for (int w = 0; w < 4; w++) {
            float sx = slotStartX + w * (slotW + slotGap);
            BOOL hasWeapon = (w == 0) || (w == 1 && state.hasWeaponShotgun) ||
                             (w == 2 && state.hasWeaponAssaultRifle) || (w == 3 && state.hasWeaponRocketLauncher);
            BOOL isSelected = (w == (int)currentWeapon);

            // Slot background - grey if no weapon, highlighted if selected
            simd_float3 bg = isSelected ? gold : (hasWeapon ? slotBg : darkBg);
            HUD_QUAD(sx, slotY, sx + slotW, slotY + slotH, bg);

            // Text color
            simd_float3 txtCol = isSelected ? darkBg : (hasWeapon ? white : dimWhite);

            // Draw weapon name or number
            const char *name = NULL;
            if (hasWeapon) {
                switch (w) {
                    case 0: name = "PISTOL"; break;
                    case 1: name = "SHOTGUN"; break;
                    case 2: name = "RIFLE"; break;
                    case 3: name = "ROCKET"; break;
                }
            } else {
                switch (w) {
                    case 0: name = "1"; break;
                    case 1: name = "2"; break;
                    case 2: name = "3"; break;
                    case 3: name = "4"; break;
                }
            }

            // Calculate text centering
            int nameLen = (int)strlen(name);
            float textWidth = nameLen * lsp;
            float lx = sx + (slotW - textWidth) / 2.0f;
            float ly = slotY + (slotH - lh) / 2.0f;

            // Render each character
            for (int c = 0; c < nameLen; c++) {
                char ch = name[c];
                if (ch >= '1' && ch <= '4') {
                    // Draw numbers
                    float nw = lw;
                    float nh = lh;
                    float nt = lt;
                    if (ch == '1') { HUD_QUAD(lx + nw*0.5f - nt*0.5f, ly, lx + nw*0.5f + nt*0.5f, ly + nh, txtCol); }
                    else if (ch == '2') { HUD_QUAD(lx, ly + nh - nt, lx + nw, ly + nh, txtCol); HUD_QUAD(lx + nw - nt, ly + nh*0.5f, lx + nw, ly + nh, txtCol); HUD_QUAD(lx, ly + nh*0.45f, lx + nw, ly + nh*0.55f, txtCol); HUD_QUAD(lx, ly, lx + nt, ly + nh*0.5f, txtCol); HUD_QUAD(lx, ly, lx + nw, ly + nt, txtCol); }
                    else if (ch == '3') { HUD_QUAD(lx, ly + nh - nt, lx + nw, ly + nh, txtCol); HUD_QUAD(lx + nw - nt, ly, lx + nw, ly + nh, txtCol); HUD_QUAD(lx, ly + nh*0.45f, lx + nw, ly + nh*0.55f, txtCol); HUD_QUAD(lx, ly, lx + nw, ly + nt, txtCol); }
                    else if (ch == '4') { HUD_QUAD(lx, ly + nh*0.5f, lx + nt, ly + nh, txtCol); HUD_QUAD(lx + nw - nt, ly, lx + nw, ly + nh, txtCol); HUD_QUAD(lx, ly + nh*0.45f, lx + nw, ly + nh*0.55f, txtCol); }
                } else {
                    // Draw letters
                    switch (ch) {
                        case 'P': HUD_QUAD(lx, ly, lx + lt, ly + lh, txtCol); HUD_QUAD(lx, ly + lh - lt, lx + lw, ly + lh, txtCol); HUD_QUAD(lx + lw - lt, ly + lh*0.5f, lx + lw, ly + lh, txtCol); HUD_QUAD(lx, ly + lh*0.45f, lx + lw, ly + lh*0.55f, txtCol); break;
                        case 'I': HUD_QUAD(lx + lw*0.5f - lt*0.5f, ly, lx + lw*0.5f + lt*0.5f, ly + lh, txtCol); HUD_QUAD(lx, ly + lh - lt, lx + lw, ly + lh, txtCol); HUD_QUAD(lx, ly, lx + lw, ly + lt, txtCol); break;
                        case 'S': HUD_QUAD(lx, ly + lh - lt, lx + lw, ly + lh, txtCol); HUD_QUAD(lx, ly + lh*0.5f, lx + lt, ly + lh, txtCol); HUD_QUAD(lx, ly + lh*0.45f, lx + lw, ly + lh*0.55f, txtCol); HUD_QUAD(lx + lw - lt, ly, lx + lw, ly + lh*0.5f, txtCol); HUD_QUAD(lx, ly, lx + lw, ly + lt, txtCol); break;
                        case 'T': HUD_QUAD(lx + lw*0.5f - lt*0.5f, ly, lx + lw*0.5f + lt*0.5f, ly + lh, txtCol); HUD_QUAD(lx, ly + lh - lt, lx + lw, ly + lh, txtCol); break;
                        case 'O': HUD_QUAD(lx, ly, lx + lt, ly + lh, txtCol); HUD_QUAD(lx + lw - lt, ly, lx + lw, ly + lh, txtCol); HUD_QUAD(lx, ly + lh - lt, lx + lw, ly + lh, txtCol); HUD_QUAD(lx, ly, lx + lw, ly + lt, txtCol); break;
                        case 'L': HUD_QUAD(lx, ly, lx + lt, ly + lh, txtCol); HUD_QUAD(lx, ly, lx + lw, ly + lt, txtCol); break;
                        case 'H': HUD_QUAD(lx, ly, lx + lt, ly + lh, txtCol); HUD_QUAD(lx + lw - lt, ly, lx + lw, ly + lh, txtCol); HUD_QUAD(lx, ly + lh*0.45f, lx + lw, ly + lh*0.55f, txtCol); break;
                        case 'G': HUD_QUAD(lx, ly, lx + lt, ly + lh, txtCol); HUD_QUAD(lx, ly + lh - lt, lx + lw, ly + lh, txtCol); HUD_QUAD(lx, ly, lx + lw, ly + lt, txtCol); HUD_QUAD(lx + lw - lt, ly, lx + lw, ly + lh*0.55f, txtCol); HUD_QUAD(lx + lw*0.5f, ly + lh*0.45f, lx + lw, ly + lh*0.55f, txtCol); break;
                        case 'U': HUD_QUAD(lx, ly, lx + lt, ly + lh, txtCol); HUD_QUAD(lx + lw - lt, ly, lx + lw, ly + lh, txtCol); HUD_QUAD(lx, ly, lx + lw, ly + lt, txtCol); break;
                        case 'N': HUD_QUAD(lx, ly, lx + lt, ly + lh, txtCol); HUD_QUAD(lx + lw - lt, ly, lx + lw, ly + lh, txtCol); HUD_QUAD(lx, ly + lh - lt, lx + lw, ly + lh, txtCol); break;
                        case 'R': HUD_QUAD(lx, ly, lx + lt, ly + lh, txtCol); HUD_QUAD(lx, ly + lh - lt, lx + lw, ly + lh, txtCol); HUD_QUAD(lx + lw - lt, ly + lh*0.5f, lx + lw, ly + lh, txtCol); HUD_QUAD(lx, ly + lh*0.45f, lx + lw, ly + lh*0.55f, txtCol); HUD_QUAD(lx + lw*0.5f, ly, lx + lw, ly + lh*0.5f, txtCol); break;
                        case 'F': HUD_QUAD(lx, ly, lx + lt, ly + lh, txtCol); HUD_QUAD(lx, ly + lh - lt, lx + lw, ly + lh, txtCol); HUD_QUAD(lx, ly + lh*0.45f, lx + lw*0.8f, ly + lh*0.55f, txtCol); break;
                        case 'E': HUD_QUAD(lx, ly, lx + lt, ly + lh, txtCol); HUD_QUAD(lx, ly + lh - lt, lx + lw, ly + lh, txtCol); HUD_QUAD(lx, ly + lh*0.45f, lx + lw*0.7f, ly + lh*0.55f, txtCol); HUD_QUAD(lx, ly, lx + lw, ly + lt, txtCol); break;
                        case 'C': HUD_QUAD(lx, ly, lx + lt, ly + lh, txtCol); HUD_QUAD(lx, ly + lh - lt, lx + lw, ly + lh, txtCol); HUD_QUAD(lx, ly, lx + lw, ly + lt, txtCol); break;
                        case 'K': HUD_QUAD(lx, ly, lx + lt, ly + lh, txtCol); HUD_QUAD(lx + lt, ly + lh*0.45f, lx + lw, ly + lh, txtCol); HUD_QUAD(lx + lt, ly, lx + lw, ly + lh*0.55f, txtCol); break;
                        case 'A': HUD_QUAD(lx, ly, lx + lt, ly + lh, txtCol); HUD_QUAD(lx + lw - lt, ly, lx + lw, ly + lh, txtCol); HUD_QUAD(lx, ly + lh - lt, lx + lw, ly + lh, txtCol); HUD_QUAD(lx, ly + lh*0.45f, lx + lw, ly + lh*0.55f, txtCol); break;
                    }
                }
                lx += lsp;
            }
        }

        // ---- AMMO DISPLAY (bottom-left) ----
        float ammoX = -0.85f;
        float ammoY = -0.55f;
        float ammoW = 0.4f;
        float ammoH = 0.12f;

        // Background
        HUD_QUAD(ammoX, ammoY, ammoX + ammoW, ammoY + ammoH, darkBg);

        // Large digit rendering
        float dh = 0.08f;   // digit height
        float dw = 0.045f;  // digit width
        float dt = 0.01f;   // line thickness
        float ds = 0.055f;  // spacing

        #define DIGIT(d, px, py, c) do { \
            if (d == 0) { HUD_QUAD(px, py, px+dt, py+dh, c); HUD_QUAD(px+dw-dt, py, px+dw, py+dh, c); HUD_QUAD(px, py+dh-dt, px+dw, py+dh, c); HUD_QUAD(px, py, px+dw, py+dt, c); } \
            else if (d == 1) { HUD_QUAD(px+dw*0.5f-dt*0.5f, py, px+dw*0.5f+dt*0.5f, py+dh, c); } \
            else if (d == 2) { HUD_QUAD(px, py+dh-dt, px+dw, py+dh, c); HUD_QUAD(px+dw-dt, py+dh*0.5f, px+dw, py+dh, c); HUD_QUAD(px, py+dh*0.45f, px+dw, py+dh*0.55f, c); HUD_QUAD(px, py, px+dt, py+dh*0.5f, c); HUD_QUAD(px, py, px+dw, py+dt, c); } \
            else if (d == 3) { HUD_QUAD(px, py+dh-dt, px+dw, py+dh, c); HUD_QUAD(px+dw-dt, py, px+dw, py+dh, c); HUD_QUAD(px, py+dh*0.45f, px+dw, py+dh*0.55f, c); HUD_QUAD(px, py, px+dw, py+dt, c); } \
            else if (d == 4) { HUD_QUAD(px, py+dh*0.5f, px+dt, py+dh, c); HUD_QUAD(px+dw-dt, py, px+dw, py+dh, c); HUD_QUAD(px, py+dh*0.45f, px+dw, py+dh*0.55f, c); } \
            else if (d == 5) { HUD_QUAD(px, py+dh-dt, px+dw, py+dh, c); HUD_QUAD(px, py+dh*0.5f, px+dt, py+dh, c); HUD_QUAD(px, py+dh*0.45f, px+dw, py+dh*0.55f, c); HUD_QUAD(px+dw-dt, py, px+dw, py+dh*0.5f, c); HUD_QUAD(px, py, px+dw, py+dt, c); } \
            else if (d == 6) { HUD_QUAD(px, py, px+dt, py+dh, c); HUD_QUAD(px, py+dh-dt, px+dw, py+dh, c); HUD_QUAD(px, py+dh*0.45f, px+dw, py+dh*0.55f, c); HUD_QUAD(px+dw-dt, py, px+dw, py+dh*0.5f, c); HUD_QUAD(px, py, px+dw, py+dt, c); } \
            else if (d == 7) { HUD_QUAD(px, py+dh-dt, px+dw, py+dh, c); HUD_QUAD(px+dw-dt, py, px+dw, py+dh, c); } \
            else if (d == 8) { HUD_QUAD(px, py, px+dt, py+dh, c); HUD_QUAD(px+dw-dt, py, px+dw, py+dh, c); HUD_QUAD(px, py+dh-dt, px+dw, py+dh, c); HUD_QUAD(px, py+dh*0.45f, px+dw, py+dh*0.55f, c); HUD_QUAD(px, py, px+dw, py+dt, c); } \
            else if (d == 9) { HUD_QUAD(px, py+dh*0.5f, px+dt, py+dh, c); HUD_QUAD(px+dw-dt, py, px+dw, py+dh, c); HUD_QUAD(px, py+dh-dt, px+dw, py+dh, c); HUD_QUAD(px, py+dh*0.45f, px+dw, py+dh*0.55f, c); HUD_QUAD(px, py, px+dw, py+dt, c); } \
        } while(0)

        float dx = ammoX + 0.02f;
        float dy = ammoY + 0.02f;
        simd_float3 ammoCol = (currentAmmo <= 5 && currentWeapon != WeaponTypePistol) ? red : white;

        if (currentWeapon == WeaponTypePistol) {
            // INF
            HUD_QUAD(dx + dw*0.5f - dt*0.5f, dy, dx + dw*0.5f + dt*0.5f, dy + dh, gold);
            HUD_QUAD(dx, dy, dx + dw, dy + dt, gold);
            HUD_QUAD(dx, dy + dh - dt, dx + dw, dy + dh, gold);
            dx += ds;
            HUD_QUAD(dx, dy, dx + dt, dy + dh, gold);
            HUD_QUAD(dx + dw - dt, dy, dx + dw, dy + dh, gold);
            HUD_QUAD(dx, dy + dh - dt, dx + dw, dy + dh, gold);
            dx += ds;
            HUD_QUAD(dx, dy, dx + dt, dy + dh, gold);
            HUD_QUAD(dx, dy + dh - dt, dx + dw, dy + dh, gold);
            HUD_QUAD(dx, dy + dh*0.45f, dx + dw*0.7f, dy + dh*0.55f, gold);
        } else {
            // Current ammo (always show 2 digits minimum)
            int ca = currentAmmo;
            if (ca >= 100) { DIGIT(ca / 100, dx, dy, ammoCol); dx += ds; }
            DIGIT((ca / 10) % 10, dx, dy, ammoCol); dx += ds;
            DIGIT(ca % 10, dx, dy, ammoCol); dx += ds;

            // Slash
            HUD_QUAD(dx + dw*0.25f, dy, dx + dw*0.75f, dy + dh, dimWhite);
            dx += ds;

            // Reserve ammo
            int ra = reserveAmmo;
            if (ra >= 100) { DIGIT(ra / 100, dx, dy, dimWhite); dx += ds; }
            DIGIT((ra / 10) % 10, dx, dy, dimWhite); dx += ds;
            DIGIT(ra % 10, dx, dy, dimWhite);
        }

        #undef DIGIT

        // ---- PICKUP NOTIFICATION (center screen) ----
        if (state.pickupNotificationTimer > 0 && state.pickupNotificationText) {
            float alpha = (state.pickupNotificationTimer > 60) ? 1.0f : (state.pickupNotificationTimer / 60.0f);
            simd_float3 notifyBg = {0.0f, 0.0f, 0.0f};
            simd_float3 notifyText = {alpha * 0.3f, alpha * 1.0f, alpha * 0.3f};

            float ny = 0.5f;
            float nh = 0.08f;

            // Background bar
            HUD_QUAD(-0.45f, ny, 0.45f, ny + nh, notifyBg);

            // Render notification text
            float lh = 0.05f;
            float lt = 0.007f;
            float lw = 0.028f;
            float lsp = 0.035f;

            NSString *text = state.pickupNotificationText;
            float textWidth = [text length] * lsp;
            float lx = -textWidth * 0.5f;
            float ly = ny + (nh - lh) * 0.5f;

            for (int i = 0; i < [text length] && i < 25; i++) {
                unichar c = [text characterAtIndex:i];
                if (c == ' ') { lx += lsp * 0.6f; continue; }
                if (c == '+') { HUD_QUAD(lx + lw*0.1f, ly + lh*0.4f, lx + lw*0.9f, ly + lh*0.6f, notifyText); HUD_QUAD(lx + lw*0.4f, ly + lh*0.1f, lx + lw*0.6f, ly + lh*0.9f, notifyText); lx += lsp; continue; }
                if (c >= '0' && c <= '9') {
                    int d = c - '0';
                    if (d == 0) { HUD_QUAD(lx, ly, lx+lt, ly+lh, notifyText); HUD_QUAD(lx+lw-lt, ly, lx+lw, ly+lh, notifyText); HUD_QUAD(lx, ly+lh-lt, lx+lw, ly+lh, notifyText); HUD_QUAD(lx, ly, lx+lw, ly+lt, notifyText); }
                    else if (d == 1) { HUD_QUAD(lx+lw*0.5f-lt*0.5f, ly, lx+lw*0.5f+lt*0.5f, ly+lh, notifyText); }
                    else if (d == 5) { HUD_QUAD(lx, ly+lh-lt, lx+lw, ly+lh, notifyText); HUD_QUAD(lx, ly+lh*0.5f, lx+lt, ly+lh, notifyText); HUD_QUAD(lx, ly+lh*0.45f, lx+lw, ly+lh*0.55f, notifyText); HUD_QUAD(lx+lw-lt, ly, lx+lw, ly+lh*0.5f, notifyText); HUD_QUAD(lx, ly, lx+lw, ly+lt, notifyText); }
                    lx += lsp; continue;
                }
                // Letters
                if (c == 'A') { HUD_QUAD(lx, ly, lx+lt, ly+lh, notifyText); HUD_QUAD(lx+lw-lt, ly, lx+lw, ly+lh, notifyText); HUD_QUAD(lx, ly+lh-lt, lx+lw, ly+lh, notifyText); HUD_QUAD(lx, ly+lh*0.45f, lx+lw, ly+lh*0.55f, notifyText); }
                else if (c == 'C') { HUD_QUAD(lx, ly, lx+lt, ly+lh, notifyText); HUD_QUAD(lx, ly+lh-lt, lx+lw, ly+lh, notifyText); HUD_QUAD(lx, ly, lx+lw, ly+lt, notifyText); }
                else if (c == 'D') { HUD_QUAD(lx, ly, lx+lt, ly+lh, notifyText); HUD_QUAD(lx, ly+lh-lt, lx+lw*0.7f, ly+lh, notifyText); HUD_QUAD(lx, ly, lx+lw*0.7f, ly+lt, notifyText); HUD_QUAD(lx+lw-lt, ly+lt, lx+lw, ly+lh-lt, notifyText); }
                else if (c == 'E') { HUD_QUAD(lx, ly, lx+lt, ly+lh, notifyText); HUD_QUAD(lx, ly+lh-lt, lx+lw, ly+lh, notifyText); HUD_QUAD(lx, ly, lx+lw, ly+lt, notifyText); HUD_QUAD(lx, ly+lh*0.45f, lx+lw*0.7f, ly+lh*0.55f, notifyText); }
                else if (c == 'F') { HUD_QUAD(lx, ly, lx+lt, ly+lh, notifyText); HUD_QUAD(lx, ly+lh-lt, lx+lw, ly+lh, notifyText); HUD_QUAD(lx, ly+lh*0.45f, lx+lw*0.7f, ly+lh*0.55f, notifyText); }
                else if (c == 'G') { HUD_QUAD(lx, ly, lx+lt, ly+lh, notifyText); HUD_QUAD(lx, ly+lh-lt, lx+lw, ly+lh, notifyText); HUD_QUAD(lx, ly, lx+lw, ly+lt, notifyText); HUD_QUAD(lx+lw-lt, ly, lx+lw, ly+lh*0.5f, notifyText); HUD_QUAD(lx+lw*0.5f, ly+lh*0.45f, lx+lw, ly+lh*0.55f, notifyText); }
                else if (c == 'H') { HUD_QUAD(lx, ly, lx+lt, ly+lh, notifyText); HUD_QUAD(lx+lw-lt, ly, lx+lw, ly+lh, notifyText); HUD_QUAD(lx, ly+lh*0.45f, lx+lw, ly+lh*0.55f, notifyText); }
                else if (c == 'I') { HUD_QUAD(lx+lw*0.5f-lt*0.5f, ly, lx+lw*0.5f+lt*0.5f, ly+lh, notifyText); HUD_QUAD(lx, ly, lx+lw, ly+lt, notifyText); HUD_QUAD(lx, ly+lh-lt, lx+lw, ly+lh, notifyText); }
                else if (c == 'K') { HUD_QUAD(lx, ly, lx+lt, ly+lh, notifyText); HUD_QUAD(lx, ly+lh*0.45f, lx+lw*0.5f, ly+lh*0.55f, notifyText); HUD_QUAD(lx+lw*0.4f, ly+lh*0.5f, lx+lw, ly+lh, notifyText); HUD_QUAD(lx+lw*0.4f, ly, lx+lw, ly+lh*0.5f, notifyText); }
                else if (c == 'L') { HUD_QUAD(lx, ly, lx+lt, ly+lh, notifyText); HUD_QUAD(lx, ly, lx+lw, ly+lt, notifyText); }
                else if (c == 'M') { HUD_QUAD(lx, ly, lx+lt, ly+lh, notifyText); HUD_QUAD(lx+lw-lt, ly, lx+lw, ly+lh, notifyText); HUD_QUAD(lx, ly+lh-lt, lx+lw, ly+lh, notifyText); HUD_QUAD(lx+lw*0.5f-lt*0.5f, ly+lh*0.4f, lx+lw*0.5f+lt*0.5f, ly+lh, notifyText); }
                else if (c == 'N') { HUD_QUAD(lx, ly, lx+lt, ly+lh, notifyText); HUD_QUAD(lx+lw-lt, ly, lx+lw, ly+lh, notifyText); HUD_QUAD(lx, ly+lh-lt, lx+lw, ly+lh, notifyText); }
                else if (c == 'O') { HUD_QUAD(lx, ly, lx+lt, ly+lh, notifyText); HUD_QUAD(lx+lw-lt, ly, lx+lw, ly+lh, notifyText); HUD_QUAD(lx, ly+lh-lt, lx+lw, ly+lh, notifyText); HUD_QUAD(lx, ly, lx+lw, ly+lt, notifyText); }
                else if (c == 'Q') { HUD_QUAD(lx, ly, lx+lt, ly+lh, notifyText); HUD_QUAD(lx+lw-lt, ly, lx+lw, ly+lh, notifyText); HUD_QUAD(lx, ly+lh-lt, lx+lw, ly+lh, notifyText); HUD_QUAD(lx, ly, lx+lw, ly+lt, notifyText); HUD_QUAD(lx+lw*0.5f, ly, lx+lw, ly+lh*0.3f, notifyText); }
                else if (c == 'R') { HUD_QUAD(lx, ly, lx+lt, ly+lh, notifyText); HUD_QUAD(lx, ly+lh-lt, lx+lw, ly+lh, notifyText); HUD_QUAD(lx+lw-lt, ly+lh*0.5f, lx+lw, ly+lh, notifyText); HUD_QUAD(lx, ly+lh*0.45f, lx+lw, ly+lh*0.55f, notifyText); HUD_QUAD(lx+lw*0.4f, ly, lx+lw, ly+lh*0.45f, notifyText); }
                else if (c == 'S') { HUD_QUAD(lx, ly+lh-lt, lx+lw, ly+lh, notifyText); HUD_QUAD(lx, ly+lh*0.5f, lx+lt, ly+lh, notifyText); HUD_QUAD(lx, ly+lh*0.45f, lx+lw, ly+lh*0.55f, notifyText); HUD_QUAD(lx+lw-lt, ly, lx+lw, ly+lh*0.5f, notifyText); HUD_QUAD(lx, ly, lx+lw, ly+lt, notifyText); }
                else if (c == 'T') { HUD_QUAD(lx+lw*0.5f-lt*0.5f, ly, lx+lw*0.5f+lt*0.5f, ly+lh, notifyText); HUD_QUAD(lx, ly+lh-lt, lx+lw, ly+lh, notifyText); }
                else if (c == 'U') { HUD_QUAD(lx, ly, lx+lt, ly+lh, notifyText); HUD_QUAD(lx+lw-lt, ly, lx+lw, ly+lh, notifyText); HUD_QUAD(lx, ly, lx+lw, ly+lt, notifyText); }
                else if (c == 'V') { HUD_QUAD(lx, ly+lh*0.4f, lx+lt, ly+lh, notifyText); HUD_QUAD(lx+lw-lt, ly+lh*0.4f, lx+lw, ly+lh, notifyText); HUD_QUAD(lx+lw*0.5f-lt*0.5f, ly, lx+lw*0.5f+lt*0.5f, ly+lh*0.5f, notifyText); }
                else if (c == 'W') { HUD_QUAD(lx, ly, lx+lt, ly+lh, notifyText); HUD_QUAD(lx+lw-lt, ly, lx+lw, ly+lh, notifyText); HUD_QUAD(lx, ly, lx+lw, ly+lt, notifyText); HUD_QUAD(lx+lw*0.5f-lt*0.5f, ly, lx+lw*0.5f+lt*0.5f, ly+lh*0.5f, notifyText); }
                else if (c == 'Y') { HUD_QUAD(lx, ly+lh*0.5f, lx+lt, ly+lh, notifyText); HUD_QUAD(lx+lw-lt, ly+lh*0.5f, lx+lw, ly+lh, notifyText); HUD_QUAD(lx+lw*0.5f-lt*0.5f, ly, lx+lw*0.5f+lt*0.5f, ly+lh*0.55f, notifyText); HUD_QUAD(lx, ly+lh*0.45f, lx+lw*0.55f, ly+lh*0.55f, notifyText); HUD_QUAD(lx+lw*0.45f, ly+lh*0.45f, lx+lw, ly+lh*0.55f, notifyText); }
                lx += lsp;
            }
        }

        #undef HUD_QUAD

        // Render HUD
        id<MTLBuffer> ammoHudBuffer = [_device newBufferWithBytes:ammoHudVerts length:sizeof(Vertex)*ahv options:MTLResourceStorageModeShared];
        [encoder setRenderPipelineState:_bgPipelineState];
        [encoder setDepthStencilState:_bgDepthState];
        [encoder setVertexBuffer:ammoHudBuffer offset:0 atIndex:0];
        [encoder setVertexBytes:&IDENTITY_MATRIX length:sizeof(IDENTITY_MATRIX) atIndex:1];
        [encoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:ahv];

        #undef MAX_AMMO_HUD_VERTS
    }

    // ============================================
    // MINIMAP
    // ============================================
    if (!state.gameOver && !_metalView.escapedLock) {
        #define MAX_MINIMAP_VERTS 2000
        Vertex minimapVerts[MAX_MINIMAP_VERTS];
        int mv = 0;

        // Minimap settings
        float mapCenterX = -0.72f;  // Top-left corner
        float mapCenterY = 0.72f;
        float mapRadius = 0.22f;    // Size of minimap
        float mapScale = mapRadius / (ARENA_SIZE * 1.2f);  // World to screen scale

        // Clipping bounds
        float clipMinX = mapCenterX - mapRadius;
        float clipMaxX = mapCenterX + mapRadius;
        float clipMinY = mapCenterY - mapRadius;
        float clipMaxY = mapCenterY + mapRadius;

        // Player position and rotation
        float playerX = _metalView.posX;
        float playerZ = _metalView.posZ;
        float playerYaw = _metalView.camYaw;

        // Colors
        simd_float3 bgColor = {0.1f, 0.1f, 0.12f};
        simd_float3 borderColor = {0.4f, 0.4f, 0.45f};
        simd_float3 wallColor = {0.35f, 0.35f, 0.4f};
        simd_float3 playerColor = {0.2f, 0.8f, 0.3f};
        simd_float3 enemyColor = {0.9f, 0.2f, 0.2f};

        // Helper macro to add a quad (axis-aligned, for UI elements)
        #define MINIMAP_QUAD(x0,y0,x1,y1,col) do { \
            minimapVerts[mv++] = (Vertex){{x0,y0,0},col}; \
            minimapVerts[mv++] = (Vertex){{x1,y0,0},col}; \
            minimapVerts[mv++] = (Vertex){{x1,y1,0},col}; \
            minimapVerts[mv++] = (Vertex){{x0,y0,0},col}; \
            minimapVerts[mv++] = (Vertex){{x1,y1,0},col}; \
            minimapVerts[mv++] = (Vertex){{x0,y1,0},col}; \
        } while(0)

        // Helper to clamp a value
        #define CLAMP_VAL(v, lo, hi) ((v) < (lo) ? (lo) : ((v) > (hi) ? (hi) : (v)))

        // Helper to transform world coords to minimap coords (rotated around player)
        // Player always faces up on minimap, world rotates around them
        #define WORLD_TO_MAP(wx, wz, outX, outY) do { \
            float dx = (wx) - playerX; \
            float dz = (wz) - playerZ; \
            float cosYaw = cosf(-playerYaw); \
            float sinYaw = sinf(-playerYaw); \
            float rotX = dx * cosYaw - dz * sinYaw; \
            float rotZ = dx * sinYaw + dz * cosYaw; \
            outX = mapCenterX + rotX * mapScale; \
            outY = mapCenterY - rotZ * mapScale; \
        } while(0)

        // Helper to add a clipped quad (for world structures)
        #define MINIMAP_CLIPPED_QUAD(wx1,wy1,wx2,wy2,wx3,wy3,wx4,wy4,col) do { \
            float cx1 = CLAMP_VAL(wx1, clipMinX, clipMaxX); \
            float cy1 = CLAMP_VAL(wy1, clipMinY, clipMaxY); \
            float cx2 = CLAMP_VAL(wx2, clipMinX, clipMaxX); \
            float cy2 = CLAMP_VAL(wy2, clipMinY, clipMaxY); \
            float cx3 = CLAMP_VAL(wx3, clipMinX, clipMaxX); \
            float cy3 = CLAMP_VAL(wy3, clipMinY, clipMaxY); \
            float cx4 = CLAMP_VAL(wx4, clipMinX, clipMaxX); \
            float cy4 = CLAMP_VAL(wy4, clipMinY, clipMaxY); \
            minimapVerts[mv++] = (Vertex){{cx1, cy1, 0}, col}; \
            minimapVerts[mv++] = (Vertex){{cx2, cy2, 0}, col}; \
            minimapVerts[mv++] = (Vertex){{cx3, cy3, 0}, col}; \
            minimapVerts[mv++] = (Vertex){{cx1, cy1, 0}, col}; \
            minimapVerts[mv++] = (Vertex){{cx3, cy3, 0}, col}; \
            minimapVerts[mv++] = (Vertex){{cx4, cy4, 0}, col}; \
        } while(0)

        // Draw background (square)
        float bgPad = 0.01f;
        MINIMAP_QUAD(mapCenterX - mapRadius - bgPad, mapCenterY - mapRadius - bgPad,
                     mapCenterX + mapRadius + bgPad, mapCenterY + mapRadius + bgPad, bgColor);

        // Draw border
        float borderW = 0.008f;
        MINIMAP_QUAD(mapCenterX - mapRadius - bgPad, mapCenterY + mapRadius,
                     mapCenterX + mapRadius + bgPad, mapCenterY + mapRadius + borderW, borderColor);
        MINIMAP_QUAD(mapCenterX - mapRadius - bgPad, mapCenterY - mapRadius - borderW,
                     mapCenterX + mapRadius + bgPad, mapCenterY - mapRadius, borderColor);
        MINIMAP_QUAD(mapCenterX - mapRadius - borderW, mapCenterY - mapRadius,
                     mapCenterX - mapRadius, mapCenterY + mapRadius, borderColor);
        MINIMAP_QUAD(mapCenterX + mapRadius, mapCenterY - mapRadius,
                     mapCenterX + mapRadius + borderW, mapCenterY + mapRadius, borderColor);

        // Draw map structures (simplified rectangles) with clipping
        // Command building
        {
            float wx1, wy1, wx2, wy2, wx3, wy3, wx4, wy4;
            float hw = CMD_BUILDING_WIDTH / 2.0f;
            float hd = CMD_BUILDING_DEPTH / 2.0f;
            WORLD_TO_MAP(CMD_BUILDING_X - hw, CMD_BUILDING_Z - hd, wx1, wy1);
            WORLD_TO_MAP(CMD_BUILDING_X + hw, CMD_BUILDING_Z - hd, wx2, wy2);
            WORLD_TO_MAP(CMD_BUILDING_X + hw, CMD_BUILDING_Z + hd, wx3, wy3);
            WORLD_TO_MAP(CMD_BUILDING_X - hw, CMD_BUILDING_Z + hd, wx4, wy4);
            MINIMAP_CLIPPED_QUAD(wx1, wy1, wx2, wy2, wx3, wy3, wx4, wy4, wallColor);
        }

        // Guard towers (4 corners)
        float towerPos[4][2] = {
            {TOWER_OFFSET, TOWER_OFFSET},
            {-TOWER_OFFSET, TOWER_OFFSET},
            {-TOWER_OFFSET, -TOWER_OFFSET},
            {TOWER_OFFSET, -TOWER_OFFSET}
        };
        for (int t = 0; t < 4; t++) {
            float tw = TOWER_SIZE / 2.0f;
            float wx1, wy1, wx2, wy2, wx3, wy3, wx4, wy4;
            WORLD_TO_MAP(towerPos[t][0] - tw, towerPos[t][1] - tw, wx1, wy1);
            WORLD_TO_MAP(towerPos[t][0] + tw, towerPos[t][1] - tw, wx2, wy2);
            WORLD_TO_MAP(towerPos[t][0] + tw, towerPos[t][1] + tw, wx3, wy3);
            WORLD_TO_MAP(towerPos[t][0] - tw, towerPos[t][1] + tw, wx4, wy4);
            MINIMAP_CLIPPED_QUAD(wx1, wy1, wx2, wy2, wx3, wy3, wx4, wy4, wallColor);
        }

        // Bunker
        {
            float hw = BUNKER_WIDTH / 2.0f;
            float hd = BUNKER_DEPTH / 2.0f;
            float wx1, wy1, wx2, wy2, wx3, wy3, wx4, wy4;
            WORLD_TO_MAP(BUNKER_X - hw, BUNKER_Z - hd, wx1, wy1);
            WORLD_TO_MAP(BUNKER_X + hw, BUNKER_Z - hd, wx2, wy2);
            WORLD_TO_MAP(BUNKER_X + hw, BUNKER_Z + hd, wx3, wy3);
            WORLD_TO_MAP(BUNKER_X - hw, BUNKER_Z + hd, wx4, wy4);
            MINIMAP_CLIPPED_QUAD(wx1, wy1, wx2, wy2, wx3, wy3, wx4, wy4, wallColor);
        }

        // Draw enemies as dots (single player mode)
        if (!state.isMultiplayer) {
            for (int i = 0; i < NUM_ENEMIES; i++) {
                if (state.enemyAlive[i]) {
                    float ex, ey;
                    WORLD_TO_MAP(state.enemyX[i], state.enemyZ[i], ex, ey);
                    // Clip to minimap bounds
                    if (ex > clipMinX && ex < clipMaxX && ey > clipMinY && ey < clipMaxY) {
                        float dotSize = 0.012f;
                        MINIMAP_QUAD(ex - dotSize, ey - dotSize, ex + dotSize, ey + dotSize, enemyColor);
                    }
                }
            }
        } else {
            // Multiplayer - draw remote player
            if (state.remotePlayerAlive) {
                float rx = state.remotePlayerPosX;
                float rz = state.remotePlayerPosZ;
                float ex, ey;
                WORLD_TO_MAP(rx, rz, ex, ey);
                if (ex > clipMinX && ex < clipMaxX && ey > clipMinY && ey < clipMaxY) {
                    float dotSize = 0.012f;
                    MINIMAP_QUAD(ex - dotSize, ey - dotSize, ex + dotSize, ey + dotSize, enemyColor);
                }
            }
        }

        // Draw player (triangle pointing in look direction - always centered, pointing up)
        {
            float triSize = 0.018f;
            float px = mapCenterX;
            float py = mapCenterY;
            minimapVerts[mv++] = (Vertex){{px, py + triSize * 1.5f, 0}, playerColor};
            minimapVerts[mv++] = (Vertex){{px - triSize, py - triSize, 0}, playerColor};
            minimapVerts[mv++] = (Vertex){{px + triSize, py - triSize, 0}, playerColor};
        }

        // Render minimap
        id<MTLBuffer> minimapBuffer = [_device newBufferWithBytes:minimapVerts length:sizeof(Vertex)*mv options:MTLResourceStorageModeShared];
        [encoder setRenderPipelineState:_bgPipelineState];
        [encoder setDepthStencilState:_bgDepthState];
        [encoder setVertexBuffer:minimapBuffer offset:0 atIndex:0];
        [encoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:mv];

        #undef MAX_MINIMAP_VERTS
        #undef MINIMAP_QUAD
        #undef CLAMP_VAL
        #undef WORLD_TO_MAP
        #undef MINIMAP_CLIPPED_QUAD
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

    // Draw gun (hide when pause menu is shown)
    if (!state.showPauseMenu) {
        float tiltX = -0.1f, tiltY = -0.45f;
        float cosTiltX = cosf(tiltX), sinTiltX = sinf(tiltX);
        float cosTiltY = cosf(tiltY), sinTiltY = sinf(tiltY);

        simd_float4x4 gunMvp = {{
            {GUN_SCALE * cosTiltY, GUN_SCALE * sinTiltX * sinTiltY, GUN_SCALE * -cosTiltX * sinTiltY, 0},
            {0, GUN_SCALE * cosTiltX, GUN_SCALE * sinTiltX, 0},
            {GUN_SCALE * sinTiltY, GUN_SCALE * -sinTiltX * cosTiltY, GUN_SCALE * cosTiltX * cosTiltY, 0},
            {GUN_SCREEN_X, GUN_SCREEN_Y, GUN_SCREEN_Z, 1}
        }};

        // Select the correct weapon buffer based on current weapon
        WeaponSystem *ws = [WeaponSystem shared];
        WeaponType currentWeapon = [ws getCurrentWeapon];
        id<MTLBuffer> weaponBuffer;
        NSUInteger weaponVertexCount;
        float muzzleZ = 0.25f;  // Default muzzle position

        switch (currentWeapon) {
            case WeaponTypePistol:
                weaponBuffer = _pistolBuffer;
                weaponVertexCount = _pistolVertexCount;
                muzzleZ = 0.25f;
                break;
            case WeaponTypeShotgun:
                weaponBuffer = _shotgunBuffer;
                weaponVertexCount = _shotgunVertexCount;
                muzzleZ = 0.32f;  // Longer barrel
                break;
            case WeaponTypeAssaultRifle:
                weaponBuffer = _rifleBuffer;
                weaponVertexCount = _rifleVertexCount;
                muzzleZ = 0.38f;  // Longer barrel
                break;
            case WeaponTypeRocketLauncher:
                weaponBuffer = _rocketLauncherBuffer;
                weaponVertexCount = _rocketLauncherVertexCount;
                muzzleZ = 0.42f;  // Longest barrel
                break;
            default:
                weaponBuffer = _pistolBuffer;
                weaponVertexCount = _pistolVertexCount;
                muzzleZ = 0.25f;
                break;
        }

        [encoder setRenderPipelineState:_pipelineState];
        [encoder setDepthStencilState:_bgDepthState];
        [encoder setVertexBuffer:weaponBuffer offset:0 atIndex:0];
        [encoder setVertexBytes:&gunMvp length:sizeof(gunMvp) atIndex:1];
        [encoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:weaponVertexCount];

        // Player muzzle flash
        if (state.muzzleFlashTimer > 0) {
            float bx = 0.0f, by = 0.02f, bz = muzzleZ;
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
    } // end if (!state.showPauseMenu)

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

    // Blood effect removed

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
