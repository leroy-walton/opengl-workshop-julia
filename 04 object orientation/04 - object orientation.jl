using CSyntax
using Quaternions
using LinearAlgebra
using StaticArrays
using GLTF

include(joinpath(@__DIR__, "glutils.jl"))
include(joinpath(@__DIR__, "camera.jl"))

mutable struct JamGltfObject
    position
    quaternion::Quaternion{GLfloat}
    rotationMatrix::SMatrix{3,3,GLfloat,9}
    forward::SVector{3,GLfloat}
    right::SVector{3,GLfloat}
    up::SVector{3,GLfloat}

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
        obj.rotationMatrix=Matrix(I,3,3)
        obj.quaternion=qrotation([0,1,0], 0)
        obj.forward=[0,0,-1]
        obj.right=[1,0,0]
        obj.up=[0,1,0]

        gltf = GLTF.load(joinpath(@__DIR__, fileName))
        gltfData = [read(joinpath(@__DIR__, b.uri)) for b in gltf.buffers]
        
        obj.positionsAccessor, obj.normalsAccessor, obj.texcoordsAccessor, obj.indicesAccessor = gltf.accessors

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

function rotate!(obj::JamGltfObject, axis, angle::Real; fwd=[0,0,-1], rgt=[1,0,0], up=[0,1,0])
    obj.quaternion = qrotation(Vector(axis), deg2rad(angle)) * obj.quaternion    # incrementally update quaternion
    obj.rotationMatrix = rotationmatrix(obj.quaternion)    # update new rotation matrix
    obj.forward = obj.rotationMatrix * fwd    # update new forward direction vector
    obj.right = obj.rotationMatrix * rgt    # update new right direction vector
    obj.up = obj.rotationMatrix * up    # update new up direction vector
    return obj
end

function JamDraw(obj::JamGltfObject)

    model_mat = GLfloat[ 
        1.0   0.0   0.0   obj.position[1]
        0.0   1.0   0.0   obj.position[2]
        0.0   0.0   1.0   obj.position[3]
        0.0   0.0   0.0   1.0        
    ]
    #model_mat = model_mat * obj.rotationMatrix

    homogenousMatrix = vcat([obj.rotationMatrix obj.position], SMatrix{1,4,GLfloat,4}(0,0,0,1))

    model_mat = homogenousMatrix


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
setposition!(camera, [0.0, 0.0, 5.0])

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

function mycall(window, x, y )
    println("$x  $y")
end

GLFW.SetCursorPosCallback(window, mycall)
GLFW.SetInputMode(window, GLFW.CURSOR, GLFW.CURSOR_HIDDEN)
# SetCursorPos(window::Window, x::Real, y::Real)
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
        
        α += 0.002
        gl1.position[1] = 2* sin(2*α)
        gl2.position[2] = sin(4*α) 

        rotate!(gl0,[1,0,0], 0.3 )
        rotate!(gl0,[0,1,0], 0.43 )
        rotate!(gl0,[0,0,1], 0.63 )

        rotate!(gl1,[0,1,0], 0.5)

        rotate!(gl2,[0,0,1], 1.3)
        rotate!(gl2,[0,1,0], 3.1 * sin(α) )

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
