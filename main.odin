package main

import "base:runtime"
import "chunk"
import "core:c"
import "core:fmt"
import "core:math"
import "core:math/noise"
import "core:time"
import "light"
import "vendor:raylib"
print :: fmt.println

index_3d :: proc(x, y, z: int, dim: int) -> int {
    return x * dim * dim + y * dim + z
}
seed :: 0
get_axis :: proc(key_neg, key_pos: raylib.KeyboardKey) -> f32 {
    return f32(int(raylib.IsKeyDown(key_pos))) - f32(int(raylib.IsKeyDown(key_neg)))
}
main :: proc() {
    using raylib, chunk, light
    SetTraceLogLevel(TraceLogLevel.NONE)
    base_width :: 1.0
    screenWidth :: i32(2400 * base_width)
    screenHeight :: i32(1350 * base_width)
    darkgray :: raylib.Color{32, 32, 30, 255}
    InitWindow(screenWidth, screenHeight, "raylib [models] example - voxel")
    defer CloseWindow()


    tileTexture := LoadRenderTexture(64, 16)
    BeginTextureMode(tileTexture)
    ClearBackground(BLANK)
    DrawRectangle(0, 0, 16, 16, DARKBROWN)
    DrawRectangle(16, 0, 16, 16, BROWN)
    DrawRectangle(32, 0, 16, 16, GRAY)
    DrawRectangle(48, 0, 16, 16, GOLD)
    EndTextureMode()

    camera: Camera3D
    camera.position = {0, 0, 0} // Camera position
    camera.up = {0.0, 1.0, 0.0} // Camera up vector (rotation towards target)
    camera.target = {0, 0, 0}
    camera.fovy = 70 // Camera field-of-view Y
    camera.projection = CameraProjection.PERSPECTIVE // Camera projection type

    shader := LoadShader("base_lighting.vs", "lighting.fs")
    shader.locs[ShaderLocationIndex.VECTOR_VIEW] = c.int(GetShaderLocation(shader, "viewPos"))
    ambientLoc := GetShaderLocation(shader, "ambient")
    val := [4]f32{0.1, 0.1, 0.1, 1.0}
    SetShaderValue(shader, ambientLoc, &val, .VEC4)

    lights := [4]Light{}
    // lights[0] = CreateLight(.POINT, Vector3{70, 0, 0}, Vector3{0, 0, 0}, WHITE, shader)
    lights[1] = CreateLight(.DIRECTIONAL, Vector3{20, 30, 40}, Vector3{2, -30, 5}, GRAY, shader)


    // set the mesh to the correct material/shader
    mat := LoadMaterialDefault()
    mat.maps[0].color = WHITE
    mat.maps[0].texture = tileTexture.texture
    mat.shader = shader

    SetTargetFPS(60)
    ChunkDrawInfo :: struct {
        mesh:      raylib.Mesh,
        transform: raylib.Matrix,
    }

    chunks := [dynamic]ChunkDrawInfo{}
    for x in -3 ..= 3 {
        for z in -3 ..= 3 {
            for y in -1 ..= 1 {
                chunk, mesh, translate := chunk.spawn_chunk({x, y, z}, seed)
                UploadMesh(&mesh, false)
                append(&chunks, ChunkDrawInfo{mesh, translate})
            }
        }
    }
    camera_angle: f32 = 0.0
    camera_radius: f32 = 40.0
    for (!WindowShouldClose()) {
        time := f32(GetTime())
        camera.position += {get_axis(.D, .A) * 0.5, get_axis(.Q, .E) * 0.5, get_axis(.S, .W) * 0.5}
        light := lights[0]
        light.position = camera.position
        UpdateLightValues(shader, light)

        BeginDrawing()
        defer EndDrawing()
        ClearBackground(darkgray)
        BeginMode3D(camera)
        defer EndMode3D()
        DrawGrid(16, 16)
        DrawSphere(Vector3(0), 0.4, GRAY)
        DrawSphere(Vector3{1, 0, 0}, 0.2, RED)
        DrawSphere(Vector3{0, 1, 0}, 0.2, BLUE)
        DrawSphere(Vector3{0, 0, 1}, 0.2, GREEN)
        for chunk in chunks {
            DrawMesh(chunk.mesh, mat, chunk.transform)
        }
    }
}
