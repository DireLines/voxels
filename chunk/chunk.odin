package chunk
import "base:runtime"
import "core:fmt"
import "core:math"
import "core:math/noise"
import "core:time"
import "vendor:raylib"
print :: fmt.println

timing_logs :: #config(timing_logs, false)

Timer :: struct {
    loc:   runtime.Source_Code_Location,
    start: time.Tick,
    time:  proc(state: ^Timer, msg: string),
}
timer :: proc(loc := #caller_location) -> Timer {
    return Timer{loc = loc, start = time.tick_now(), time = proc(state: ^Timer, msg: string) {
                when timing_logs {
                    elapsed := time.tick_since(state.start)
                    prefix := state.loc.procedure
                    fmt.printf(
                        "%v: %v took %v micros\n",
                        prefix,
                        msg,
                        int(time.duration_microseconds(elapsed)),
                    )
                    state.start = time.tick_now()
                }
            }}
}


index_3d :: proc(x, y, z: int, dim: int) -> int {
    return x * dim * dim + y * dim + z
}
CubeFace :: enum {
    North, //+z
    South, //-z
    East, //-x
    West, //+x
    Top, //+y
    Bottom, //-y
}
chunk_size :: 32
Voxel :: enum {
    Air,
    Ground,
}
VoxelChunk :: [chunk_size * chunk_size * chunk_size]Voxel
chunk_to_mesh :: proc(chunk: ^VoxelChunk) -> raylib.Mesh {
    using raylib
    mesh_iterator := allocate_mesh(get_chunk_face_count(chunk))
    count := 0
    for x in 0 ..< chunk_size {
        for y in 0 ..< chunk_size {
            for z in 0 ..< chunk_size {
                if !block_is_solid(x, y, z, chunk) {
                    continue
                }
                faces := bit_set[CubeFace]{}
                if !block_is_solid(x - 1, y, z, chunk) {
                    faces += {.East}
                }

                if !block_is_solid(x + 1, y, z, chunk) {
                    faces += {.West}
                }

                if !block_is_solid(x, y - 1, z, chunk) {
                    faces += {.Bottom}
                }

                if !block_is_solid(x, y + 1, z, chunk) {
                    faces += {.Top}
                }

                if !block_is_solid(x, y, z + 1, chunk) {
                    faces += {.North}
                }

                if !block_is_solid(x, y, z - 1, chunk) {
                    faces += {.South}
                }
                position: Vector3 = {f32(x), f32(y), f32(z)}
                block := chunk[index_3d(x, y, z, chunk_size)]
                add_cube(&mesh_iterator, position, faces, block)
            }
        }
    }
    return mesh_iterator.mesh
}
block_is_solid :: proc(x, y, z: int, chunk: ^VoxelChunk) -> bool {
    if (x < 0 || x >= chunk_size) {
        return false
    }
    if (y < 0 || y >= chunk_size) {
        return false
    }
    if (z < 0 || z >= chunk_size) {
        return false
    }
    return chunk[index_3d(x, y, z, chunk_size)] > Voxel.Air
}
//how many faces should be rendered in the chunk?
get_chunk_face_count :: proc(chunk: ^VoxelChunk) -> int {
    count := 0
    for x in 0 ..< chunk_size {
        for y in 0 ..< chunk_size {
            for z in 0 ..< chunk_size {
                if !block_is_solid(x, y, z, chunk) {
                    continue
                }

                if !block_is_solid(x + 1, y, z, chunk) {
                    count += 1
                }

                if !block_is_solid(x - 1, y, z, chunk) {
                    count += 1
                }

                if !block_is_solid(x, y + 1, z, chunk) {
                    count += 1
                }

                if !block_is_solid(x, y - 1, z, chunk) {
                    count += 1
                }

                if !block_is_solid(x, y, z + 1, chunk) {
                    count += 1
                }

                if !block_is_solid(x, y, z - 1, chunk) {
                    count += 1
                }
            }
        }
    }
    return count
}
push_vertex :: proc(mesh_iterator: ^MeshIterator, vertex: raylib.Vector3, offset: raylib.Vector3) {
    using mesh_iterator
    index := triangle_index * 12 + vert_index * 3
    vert_color := raylib.Color{255, 255, 255, 255}

    if (mesh.colors != nil) {
        mesh.colors[index] = vert_color.r
        mesh.colors[index + 1] = vert_color.g
        mesh.colors[index + 2] = vert_color.b
        mesh.colors[index + 3] = vert_color.a
    }


    if mesh.texcoords != nil {
        index = triangle_index * 6 + vert_index * 2
        mesh.texcoords[index] = uv.x
        mesh.texcoords[index + 1] = uv.y
    }


    if mesh.normals != nil {
        index = triangle_index * 9 + vert_index * 3
        mesh.normals[index] = normal.x
        mesh.normals[index + 1] = normal.y
        mesh.normals[index + 2] = normal.z
    }

    index = triangle_index * 9 + vert_index * 3
    mesh.vertices[index] = vertex.x + offset.x
    mesh.vertices[index + 1] = vertex.y + offset.y
    mesh.vertices[index + 2] = vertex.z + offset.z

    vert_index += 1
    if (vert_index > 2) {
        triangle_index += 1
        vert_index = 0
    }
}
add_cube :: proc(
    mesh_iterator: ^MeshIterator,
    position: raylib.Vector3,
    faces: bit_set[CubeFace],
    block: Voxel,
) {
    using raylib, mesh_iterator
    uvRect := Rectangle{0.5, 0.5, 0.75, 1}
    if (.South in faces) {
        //-z
        normal = {0, 0, -1}
        uv = {uvRect.x, uvRect.y}
        push_vertex(mesh_iterator, position, {0, 0, 0})
        uv = {uvRect.width, uvRect.height}
        push_vertex(mesh_iterator, position, {1, 1, 0})
        uv = {uvRect.width, uvRect.y}
        push_vertex(mesh_iterator, position, {1, 0, 0})
        uv = {uvRect.x, uvRect.y}
        push_vertex(mesh_iterator, position, {0, 0, 0})
        uv = {uvRect.x, uvRect.height}
        push_vertex(mesh_iterator, position, {0, 1, 0})
        uv = {uvRect.width, uvRect.y}
        push_vertex(mesh_iterator, position, {1, 1, 0})
    }
    if (.North in faces) {
        //+z
        normal = {0, 0, 1}
        uv = {uvRect.x, uvRect.y}
        push_vertex(mesh_iterator, position, {0, 0, 1})
        uv = {uvRect.width, uvRect.y}
        push_vertex(mesh_iterator, position, {1, 0, 1})
        uv = {uvRect.width, uvRect.height}
        push_vertex(mesh_iterator, position, {1, 1, 1})
        uv = {uvRect.x, uvRect.y}
        push_vertex(mesh_iterator, position, {0, 0, 1})
        uv = {uvRect.width, uvRect.height}
        push_vertex(mesh_iterator, position, {1, 1, 1})
        uv = {uvRect.x, uvRect.height}
        push_vertex(mesh_iterator, position, {0, 1, 1})
    }
    if (.West in faces) {
        //+x
        normal = {1, 0, 0}
        uv = {uvRect.x, uvRect.height}
        push_vertex(mesh_iterator, position, {1, 0, 1})
        uv = {uvRect.x, uvRect.y}
        push_vertex(mesh_iterator, position, {1, 0, 0})
        uv = {uvRect.width, uvRect.y}
        push_vertex(mesh_iterator, position, {1, 1, 0})
        uv = {uvRect.x, uvRect.height}
        push_vertex(mesh_iterator, position, {1, 0, 1})
        uv = {uvRect.width, uvRect.y}
        push_vertex(mesh_iterator, position, {1, 1, 0})
        uv = {uvRect.width, uvRect.height}
        push_vertex(mesh_iterator, position, {1, 1, 1})
    }
    if (.East in faces) {
        //-x
        normal = {-1, 0, 0}
        uv = {uvRect.x, uvRect.height}
        push_vertex(mesh_iterator, position, {0, 0, 1})
        uv = {uvRect.width, uvRect.y}
        push_vertex(mesh_iterator, position, {0, 1, 0})
        uv = {uvRect.x, uvRect.y}
        push_vertex(mesh_iterator, position, {0, 0, 0})
        uv = {uvRect.x, uvRect.height}
        push_vertex(mesh_iterator, position, {0, 0, 1})
        uv = {uvRect.width, uvRect.height}
        push_vertex(mesh_iterator, position, {0, 1, 1})
        uv = {uvRect.width, uvRect.y}
        push_vertex(mesh_iterator, position, {0, 1, 0})
    }
    if (.Top in faces) {
        //+y
        normal = {0, 1, 0}
        uv = {uvRect.x, uvRect.y}
        push_vertex(mesh_iterator, position, {0, 1, 0})
        uv = {uvRect.width, uvRect.height}
        push_vertex(mesh_iterator, position, {1, 1, 1})
        uv = {uvRect.width, uvRect.y}
        push_vertex(mesh_iterator, position, {1, 1, 0})
        uv = {uvRect.x, uvRect.y}
        push_vertex(mesh_iterator, position, {0, 1, 0})
        uv = {uvRect.x, uvRect.height}
        push_vertex(mesh_iterator, position, {0, 1, 1})
        uv = {uvRect.width, uvRect.height}
        push_vertex(mesh_iterator, position, {1, 1, 1})
    }
    if (.Bottom in faces) {
        //-y
        normal = {0, -1, 0}
        uv = {uvRect.x, uvRect.y}
        push_vertex(mesh_iterator, position, {0, 0, 0})
        uv = {uvRect.width, uvRect.y}
        push_vertex(mesh_iterator, position, {1, 0, 0})
        uv = {uvRect.width, uvRect.height}
        push_vertex(mesh_iterator, position, {1, 0, 1})
        uv = {uvRect.x, uvRect.y}
        push_vertex(mesh_iterator, position, {0, 0, 0})
        uv = {uvRect.width, uvRect.height}
        push_vertex(mesh_iterator, position, {1, 0, 1})
        uv = {uvRect.x, uvRect.height}
        push_vertex(mesh_iterator, position, {0, 0, 1})
    }
}
allocate_mesh :: proc(num_triangles: int) -> MeshIterator {
    mesh := raylib.Mesh{}
    mesh.vertexCount = i32(num_triangles * 6)
    mesh.triangleCount = i32(num_triangles * 2)
    colors := make([]u8, mesh.vertexCount * 4)
    vertices := make([]f32, mesh.vertexCount * 3)
    normals := make([]f32, mesh.vertexCount * 2)
    texcoords := make([]f32, mesh.vertexCount * 2)
    mesh.vertices = raw_data(vertices)
    mesh.normals = raw_data(normals)
    mesh.colors = raw_data(colors)
    mesh.texcoords = raw_data(texcoords)
    return MeshIterator{mesh = mesh}
}

MeshIterator :: struct {
    mesh:           raylib.Mesh,
    triangle_index: int,
    vert_index:     int,
    uv:             raylib.Vector2,
    normal:         raylib.Vector3,
}


spawn_chunk :: proc(
    chunk_index: [3]int,
    seed: i64,
) -> (
    chunk: ^VoxelChunk,
    mesh: raylib.Mesh,
    translation: raylib.Matrix,
) {
    using raylib
    top_north_east_corner := [3]int {
        chunk_index.x * chunk_size,
        chunk_index.y * chunk_size,
        chunk_index.z * chunk_size,
    }
    timer := timer()
    chunk = new(VoxelChunk)
    scale: f32 : 0.25
    threshold: f32 : 0.38
    for x in 0 ..< chunk_size {
        for y in 0 ..< chunk_size {
            for z in 0 ..< chunk_size {
                cubePos: Vector3 =  {
                    f32(x + top_north_east_corner.x - chunk_size / 2) * (scale),
                    f32(y + top_north_east_corner.y - chunk_size / 2) * (scale),
                    f32(z + top_north_east_corner.z - chunk_size / 2) * (scale),
                }

                noise_scale: f64 = 0.7 * f64(scale)
                n := noise.noise_3d_improve_xz(
                    seed,
                    {f64(cubePos.x), f64(cubePos.y), f64(cubePos.z)} * noise_scale,
                )
                if n < 0 {
                    n = -1 - n
                }
                v: Voxel
                if n > threshold {
                    v = .Ground
                } else {
                    v = .Air
                }
                chunk[index_3d(x, y, z, chunk_size)] = v
            }
        }
    }
    timer->time("generate chunk")
    mesh = chunk_to_mesh(chunk)
    timer->time("mesh chunk")
    return chunk, mesh, MatrixTranslate(
        f32(top_north_east_corner.x) - chunk_size / 2,
        f32(top_north_east_corner.y) - chunk_size / 2,
        f32(top_north_east_corner.z) - chunk_size / 2,
    )
}
