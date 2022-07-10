using CSyntax
using GLTF

#monkey = GLTF.load(joinpath(@__DIR__, "monkey2.gltf"))
#monkey = GLTF.load(joinpath(@__DIR__, "cube1m.gltf"))
monkey = GLTF.load(joinpath(@__DIR__, "planetest2.gltf"))

include(joinpath(@__DIR__, "glutils.jl"))
include(joinpath(@__DIR__, "camera.jl"))

width, height = fb_width, fb_height = 800, 600
window = startgl(width, height)

glEnable(GL_DEPTH_TEST)
glDepthFunc(GL_LESS)

monkeyData = [read(joinpath(@__DIR__, b.uri)) for b in monkey.buffers]

positionsAccessor = monkey.accessors[0]
normalsAccessor = monkey.accessors[1]
texcoordsAccessor = monkey.accessors[2]
indicesAccessor = monkey.accessors[3]

positionsBufferView = monkey.bufferViews[positionsAccessor.bufferView]
normalsBufferView = monkey.bufferViews[normalsAccessor.bufferView]
texcoordsBufferView = monkey.bufferViews[texcoordsAccessor.bufferView]
indicesBufferView = monkey.bufferViews[indicesAccessor.bufferView]

positions_vbo = GLuint(0)
@c glGenBuffers(1, &positions_vbo)
glBindBuffer(GL_ARRAY_BUFFER, positions_vbo)
glBufferData(GL_ARRAY_BUFFER, positionsBufferView.byteLength, C_NULL, GL_STATIC_DRAW)
positionsData = monkeyData[positionsBufferView.buffer]
@c glBufferSubData(GL_ARRAY_BUFFER, 0, positionsBufferView.byteLength, &positionsData[positionsBufferView.byteOffset])

normals_vbo = GLuint(0)
@c glGenBuffers(1, &normals_vbo)
glBindBuffer(GL_ARRAY_BUFFER, normals_vbo)
glBufferData(GL_ARRAY_BUFFER, normalsBufferView.byteLength, C_NULL, GL_STATIC_DRAW)
normalsData = monkeyData[normalsBufferView.buffer]
@c glBufferSubData(GL_ARRAY_BUFFER, 0, normalsBufferView.byteLength, &normalsData[normalsBufferView.byteOffset])

texcoords_vbo = GLuint(0)
@c glGenBuffers(1, &texcoords_vbo)
glBindBuffer(GL_ARRAY_BUFFER, texcoords_vbo)
glBufferData(GL_ARRAY_BUFFER, texcoordsBufferView.byteLength, C_NULL, GL_STATIC_DRAW)
texcoordsData = monkeyData[texcoordsBufferView.buffer]
@c glBufferSubData(GL_ARRAY_BUFFER, 0, texcoordsBufferView.byteLength, &texcoordsData[texcoordsBufferView.byteOffset])

indices_ebo = GLuint(0)
@c glGenBuffers(1, &indices_ebo)
glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, indices_ebo)
glBufferData(GL_ELEMENT_ARRAY_BUFFER, indicesBufferView.byteLength, C_NULL, GL_STATIC_DRAW)
indicesData = monkeyData[indicesBufferView.buffer]
@c glBufferSubData(GL_ELEMENT_ARRAY_BUFFER, 0, indicesBufferView.byteLength, &indicesData[indicesBufferView.byteOffset])

# create VAO
vao = GLuint(0)
@c glGenVertexArrays(1, &vao)
glBindVertexArray(vao)
# bind position vbo
glBindBuffer(GL_ARRAY_BUFFER, positions_vbo)
glVertexAttribPointer(0, 3, positionsAccessor.componentType, positionsAccessor.normalized, 0, Ptr{Cvoid}(positionsAccessor.byteOffset))
glEnableVertexAttribArray(0)
# bind normal vbo
glBindBuffer(GL_ARRAY_BUFFER, normals_vbo)
glVertexAttribPointer(1, 3, normalsAccessor.componentType, normalsAccessor.normalized, 0, Ptr{Cvoid}(normalsAccessor.byteOffset))
glEnableVertexAttribArray(1)
# bind texture coordinate vbo
glBindBuffer(GL_ARRAY_BUFFER, texcoords_vbo)
glVertexAttribPointer(2, 2, texcoordsAccessor.componentType, texcoordsAccessor.normalized, 0, Ptr{Cvoid}(texcoordsAccessor.byteOffset))
glEnableVertexAttribArray(2)



camera = PerspectiveCamera()
setposition!(camera, [0.0, 0.0, 5.0])

# create shader program
vert_shader = createshader(joinpath(@__DIR__, "jamShader.vert"), GL_VERTEX_SHADER)
frag_shader = createshader(joinpath(@__DIR__, "jamShader.frag"), GL_FRAGMENT_SHADER)

# link program
shader_prog = createprogram(vert_shader, frag_shader)
model_loc = glGetUniformLocation(shader_prog, "model")
view_loc = glGetUniformLocation(shader_prog, "view")
proj_loc = glGetUniformLocation(shader_prog, "proj")
glUseProgram(shader_prog)
glUniformMatrix4fv(view_loc, 1, GL_FALSE, get_view_matrix(camera))
glUniformMatrix4fv(proj_loc, 1, GL_FALSE, get_projective_matrix(window, camera))

glEnable(GL_CULL_FACE)
glCullFace(GL_BACK)
glFrontFace(GL_CCW)
glClearColor(0.2, 0.2, 0.2, 1.0)

let
updatefps = FPSCounter()
while !GLFW.WindowShouldClose(window)
    updatefps(window)
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)
    glViewport(0, 0, GLFW.GetFramebufferSize(window)...)
    glUseProgram(shader_prog)

    model_mat = GLfloat[ 
            1.0   0.0   0.0   0
            0.0   1.0   0.0   0
            0.0   0.0   1.0   0
            0.0   0.0   0.0   1.0        
        ]

    glUniformMatrix4fv(view_loc, 1, GL_FALSE, get_view_matrix(camera))
    glUniformMatrix4fv(proj_loc, 1, GL_FALSE, get_projective_matrix(window, camera))
    glUniformMatrix4fv(model_loc, 1, GL_FALSE, model_mat)
    
    glBindVertexArray(vao)
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, indices_ebo)
    glDrawElements(GL_TRIANGLES, indicesAccessor.count, indicesAccessor.componentType, Ptr{Cvoid}(0))
    
    GLFW.PollEvents()
    updatecamera!(window, camera)

    GLFW.SwapBuffers(window)
end
end # let

GLFW.DestroyWindow(window)
