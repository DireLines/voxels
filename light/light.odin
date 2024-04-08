package light
import "core:fmt"
import "core:strings"

import "vendor:raylib"
MAX_LIGHTS :: 4
currentNumLights := 0
LightType :: enum {
    DIRECTIONAL = 0,
    POINT       = 1,
}
Light :: struct {
    type:       LightType,
    position:   raylib.Vector3,
    target:     raylib.Vector3,
    color:      raylib.Color,
    enabled:    bool,
    enabledLoc: raylib.ShaderLocationIndex,
    typeLoc:    raylib.ShaderLocationIndex,
    posLoc:     raylib.ShaderLocationIndex,
    targetLoc:  raylib.ShaderLocationIndex,
    colorLoc:   raylib.ShaderLocationIndex,
}

// Create a light and get shader locations
CreateLight :: proc(
    type: LightType,
    position, target: raylib.Vector3,
    color: raylib.Color,
    shader: raylib.Shader,
) -> Light {
    using raylib
    light := Light{}

    if currentNumLights >= MAX_LIGHTS {
        return light
    }
    light.enabled = true
    light.type = type
    light.position = position
    light.target = target
    light.color = color

    // TODO: Below code doesn't look good to me, 
    // it assumes a specific shader naming and structure
    // Probably this implementation could be improved
    enabledName := fmt.tprintf("lights[%s].enabled", currentNumLights)
    typeName := fmt.tprintf("lights[%s].type", currentNumLights)
    posName := fmt.tprintf("lights[%s].position", currentNumLights)
    targetName := fmt.tprintf("lights[%s].target", currentNumLights)
    colorName := fmt.tprintf("lights[%s].color", currentNumLights)

    light.enabledLoc = GetShaderLocation(shader, strings.clone_to_cstring(enabledName))
    light.typeLoc = GetShaderLocation(shader, strings.clone_to_cstring(typeName))
    light.posLoc = GetShaderLocation(shader, strings.clone_to_cstring(posName))
    light.targetLoc = GetShaderLocation(shader, strings.clone_to_cstring(targetName))
    light.colorLoc = GetShaderLocation(shader, strings.clone_to_cstring(colorName))

    UpdateLightValues(shader, light)

    currentNumLights += 1

    return light
}

// Send light properties to shader
// NOTE: Light shader locations should be available 
UpdateLightValues :: proc(shader: raylib.Shader, light: Light) {
    using raylib
    light := light //needed to take address of param fields
    // Send to shader light enabled state and type
    SetShaderValue(shader, light.enabledLoc, &light.enabled, .INT)
    SetShaderValue(shader, light.typeLoc, &light.type, .INT)
    // Send to shader light position values
    position := [3]f32{light.position.x, light.position.y, light.position.z}
    SetShaderValue(shader, light.posLoc, &position, .VEC3)
    // Send to shader light target position values
    target := [3]f32{light.target.x, light.target.y, light.target.z}
    SetShaderValue(shader, light.targetLoc, &target, .VEC3)
    // Send to shader light color values
    color := [4]f32 {
        f32(light.color.r) / f32(255),
        f32(light.color.g) / f32(255),
        f32(light.color.b) / f32(255),
        f32(light.color.a) / f32(255),
    }
    SetShaderValue(shader, light.colorLoc, &color, .VEC4)
}
