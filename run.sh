#!/bin/bash
cd "$(dirname "$0")"

echo "Compiling FPSGame..."
clang -framework Cocoa -framework Metal -framework MetalKit -framework QuartzCore -framework AudioToolbox -framework GameController -fobjc-arc -O2 -o FPSGame \
    main.m AppDelegate.m Renderer.m GameState.m GeometryBuilder.m Collision.c GameMath.c \
    DoorSystem.m Combat.m WeaponSystem.m SoundManager.m PickupSystem.m Enemy.m \
    NetworkManager.m LobbyView.m InputView.m MultiplayerController.m 2>&1

if [ $? -eq 0 ]; then
    echo "Compilation successful. Launching game..."
    ./FPSGame &
else
    echo "Compilation failed!"
    exit 1
fi
