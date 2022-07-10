using CSyntax
using Quaternions
using GLTF

include(joinpath(@__DIR__, "glutils.jl"))
include(joinpath(@__DIR__, "camera.jl"))

mutable struct JamGltfObject
    position
    positionsAccessor
    positionsBufferView
    normalsAccessor
    normalsBufferView
    texcoordsAccessor
    texcoordsBufferView
    indicesAccessor
    indicesBufferView
    positions_vbo
    normals_vbo
    texcoords_vbo
    indices_ebo
    vao
    
    function JamGltfObject(fileName)
        obj = new()
        obj.position = GLfloat[0, 0, 0]

        gltf = GLTF.load(joinpath(@__DIR__, fileName))
        gltfData = [read(joinpath(@__DIR__, b.uri)) for b in gltf.buffers]
        
        obj.positionsAccessor = gltf.accessors[0]
        obj.normalsAccessor = gltf.accessors[1]
        obj.texcoordsAccessor = gltf.accessors[2]
        obj.indicesAccessor = gltf.accessors[3]
        
        obj.positionsBufferView = gltf.bufferViews[obj.positionsAccessor.bufferView]
        obj.normalsBufferView = gltf.bufferViews[obj.normalsAccessor.bufferView]
        obj.texcoordsBufferView = gltf.bufferViews[obj.texcoordsAccessor.bufferView]
        obj.indicesBufferView = gltf.bufferViews[obj.indicesAccessor.bufferView]

        obj.positions_vbo = GLuint(0)
        @c glGenBuffers(1, &obj.positions_vbo)
        glBindBuffer(GL_ARRAY_BUFFER, obj.positions_vbo)
        glBufferData(GL_ARRAY_BUFFER, obj.positionsBufferView.byteLength, C_NULL, GL_STATIC_DRAW)
        positionsData = gltfData[obj.positionsBufferView.buffer]
        @c glBufferSubData(GL_ARRAY_BUFFER, 0, obj.positionsBufferView.byteLength, &positionsData[obj.positionsBufferView.byteOffset])
        
        obj.normals_vbo = GLuint(0)
        @c glGenBuffers(1, &obj.normals_vbo)
        glBindBuffer(GL_ARRAY_BUFFER, obj.normals_vbo)
        glBufferData(GL_ARRAY_BUFFER, obj.normalsBufferView.byteLength, C_NULL, GL_STATIC_DRAW)
        normalsData = gltfData[obj.normalsBufferView.buffer]
        @c glBufferSubData(GL_ARRAY_BUFFER, 0, obj.normalsBufferView.byteLength, &normalsData[obj.normalsBufferView.byteOffset])
        
        obj.texcoords_vbo = GLuint(0)
        @c glGenBuffers(1, &obj.texcoords_vbo)
        glBindBuffer(GL_ARRAY_BUFFER, obj.texcoords_vbo)
        glBufferData(GL_ARRAY_BUFFER, obj.texcoordsBufferView.byteLength, C_NULL, GL_STATIC_DRAW)
        texcoordsData = gltfData[obj.texcoordsBufferView.buffer]
        @c glBufferSubData(GL_ARRAY_BUFFER, 0, obj.texcoordsBufferView.byteLength, &texcoordsData[obj.texcoordsBufferView.byteOffset])
        
        obj.indices_ebo = GLuint(0)
        @c glGenBuffers(1, &obj.indices_ebo)
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, obj.indices_ebo)
        glBufferData(GL_ELEMENT_ARRAY_BUFFER, obj.indicesBufferView.byteLength, C_NULL, GL_STATIC_DRAW)
        indicesData = gltfData[obj.indicesBufferView.buffer]
        @c glBufferSubData(GL_ELEMENT_ARRAY_BUFFER, 0, obj.indicesBufferView.byteLength, &indicesData[obj.indicesBufferView.byteOffset])
        
        obj.vao = GLuint(0)
        @c glGenVertexArrays(1, &obj.vao)
        glBindVertexArray(obj.vao)
        # bind position vbo
        glBindBuffer(GL_ARRAY_BUFFER, obj.positions_vbo)
        glVertexAttribPointer(0, 3, obj.positionsAccessor.componentType, obj.positionsAccessor.normalized, 0, Ptr{Cvoid}(obj.positionsAccessor.byteOffset))
        glEnableVertexAttribArray(0)
        # bind normal vbo
        glBindBuffer(GL_ARRAY_BUFFER, obj.normals_vbo)
        glVertexAttribPointer(1, 3, obj.normalsAccessor.componentType, obj.normalsAccessor.normalized, 0, Ptr{Cvoid}(obj.normalsAccessor.byteOffset))
        glEnableVertexAttribArray(1)
        # bind texture coordinate vbo
        glBindBuffer(GL_ARRAY_BUFFER, obj.texcoords_vbo)
        glVertexAttribPointer(2, 2, obj.texcoordsAccessor.componentType, obj.texcoordsAccessor.normalized, 0, Ptr{Cvoid}(obj.texcoordsAccessor.byteOffset))
        glEnableVertexAttribArray(2)

        obj
    end
end


function JamDraw(obj::JamGltfObject)

    model_mat = GLfloat[ 
        1.0   0.0   0.0   obj.position[1]
        0.0   1.0   0.0   obj.position[2]
        0.0   0.0   1.0   obj.position[3]
        0.0   0.0   0.0   1.0        
    ]
    glUniformMatrix4fv(model_loc, 1, GL_FALSE, model_mat)

    glBindVertexArray(obj.vao)
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, obj.indices_ebo)
    glDrawElements(GL_TRIANGLES, obj.indicesAccessor.count, obj.indicesAccessor.componentType, Ptr{Cvoid}(0))    
end

width, height = fb_width, fb_height = 1600, 1200
window = startgl(width, height)

glEnable(GL_DEPTH_TEST)
glDepthFunc(GL_LESS)

vao = GLuint(0)
@c glGenVertexArrays(1, &vao)
glBindVertexArray(vao)

vert_shader = createshader(joinpath(@__DIR__, "jamShader.vert"), GL_VERTEX_SHADER)
frag_shader = createshader(joinpath(@__DIR__, "jamShader.frag"), GL_FRAGMENT_SHADER)
shader_prog = createprogram(vert_shader, frag_shader)

glEnable(GL_CULL_FACE)
glCullFace(GL_BACK)
glFrontFace(GL_CCW)
glClearColor(0.1, 0.05, 0.05, 1.0)

camera = PerspectiveCamera()
setposition!(camera, [0.0, 0.0, 2.0])

model_loc = glGetUniformLocation(shader_prog, "model")
view_loc = glGetUniformLocation(shader_prog, "view")
proj_loc = glGetUniformLocation(shader_prog, "proj")
glUseProgram(shader_prog)

gl0 = JamGltfObject("cube1m.gltf")
gl1 = JamGltfObject("monkey2.gltf")
gl2 = JamGltfObject("planetest2.gltf")

gl0.position = GLfloat[-3, 0, 0]
gl1.position = GLfloat[0, 0, -4]
gl2.position = GLfloat[3, 0, 0]

let
    updatefps = FPSCounter()
    α = 0
    while !GLFW.WindowShouldClose(window)
        updatefps(window)
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)
        #glPolygonMode(GL_FRONT_AND_BACK, GL_LINE)
        glViewport(0, 0, GLFW.GetFramebufferSize(window)...)
        glUseProgram(shader_prog)
        glBindVertexArray(vao)
        glUniformMatrix4fv(view_loc, 1, GL_FALSE, get_view_matrix(camera))
        glUniformMatrix4fv(proj_loc, 1, GL_FALSE, get_projective_matrix(window, camera))
        
        α += 0.01
        gl1.position[1] = 2* sin(2*α)
        gl2.position[2] = sin(4*α) 

        JamDraw(gl0)
        JamDraw(gl1)
        JamDraw(gl2)

        GLFW.PollEvents()
        updatecamera!(window, camera)
        glUniformMatrix4fv(view_loc, 1, GL_FALSE, get_view_matrix(camera))
        GLFW.SwapBuffers(window)
    end
end

GLFW.DestroyWindow(window)
