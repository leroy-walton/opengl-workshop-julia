using CSyntax
using Quaternions

include(joinpath(@__DIR__, "glutils.jl"))
include(joinpath(@__DIR__, "camera.jl"))

abstract type JamDrawable    
end

function JamCreateBuffers(vertices::Array{GLfloat}, colors::Array{GLfloat}, triangles::Array{GLuint})
    vertices_count = sizeof(vertices)
    triangles_count = sizeof(triangles)    
    vbo = GLuint(0)
    @c glGenBuffers(1, &vbo)
    glBindBuffer(GL_ARRAY_BUFFER, vbo)
    glBufferData(GL_ARRAY_BUFFER, vertices_count + sizeof(colors), C_NULL, GL_STATIC_DRAW)
    glBufferSubData(GL_ARRAY_BUFFER, 0, vertices_count, vertices)
    glBufferSubData(GL_ARRAY_BUFFER, vertices_count, sizeof(colors), colors)
    ibo = GLuint(0)
    @c glGenBuffers(1, &ibo)
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, ibo)
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, triangles_count, triangles, GL_STATIC_DRAW)
    vbo, ibo, vertices_count, triangles_count
end

function JamDraw(obj::JamDrawable)
    glBindBuffer(GL_ARRAY_BUFFER, obj.vbo)
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, obj.ibo)
    glVertexAttribPointer( 0, 3, GL_FLOAT, GL_FALSE, 0, C_NULL)
    glVertexAttribPointer( 1, 4, GL_FLOAT, GL_FALSE, 0, C_NULL+(obj.vertices_count))
    glEnableVertexAttribArray(0)
    glEnableVertexAttribArray(1)
    glDrawElements(GL_TRIANGLES, obj.triangles_count, GL_UNSIGNED_INT, C_NULL)
end

function JamTranslate(obj::JamDrawable, t)
    obj.position = obj.position + t
end

mutable struct Square <: JamDrawable
    position::SVector{3,GLfloat}
    vbo
    ibo
    vertices_count
    triangles_count
    function Square()
        vertices = GLfloat[
            -1.0, 1.0, 0.0,
             1.0, 1.0, 0.0,
            -1.0,-1.0, 0.0,
             1.0,-1.0, 0.0
        ]
        colors = GLfloat[
            1.0, 1.0, 1.0, 1.0,
            1.0, 1.0, 1.0, 1.0,
            1.0, 1.0, 1.0, 1.0,
            1.0, 1.0, 1.0, 1.0,
        ]
        triangles = GLuint[
            0,2,1,
            1,2,3,
        ]
        vbo, ibo, vertices_count, triangles_count = JamCreateBuffers(vertices, colors, triangles)
        new([0 0 0], vbo, ibo, vertices_count, triangles_count )
    end
end

mutable struct Cube <: JamDrawable
    position::SVector{3,GLfloat}
    vbo
    ibo
    vertices_count
    triangles_count
    function Cube()

    vertices = GLfloat[
        # coords / color
         0.5,  0.5,  0.5, 
        -0.5,  0.5, -0.5, 
        -0.5,  0.5,  0.5, 
         0.5, -0.5, -0.5, 
        -0.5, -0.5, -0.5, 
         0.5,  0.5, -0.5, 
         0.5, -0.5,  0.5, 
        -0.5, -0.5,  0.5, 
    ]
    colors = GLfloat[
        rand(), rand(), rand(),1,
        rand(), rand(), rand(),1,
        rand(), rand(), rand(),1,
        rand(), rand(), rand(),1,
        rand(), rand(), rand(),1,
        rand(), rand(), rand(),1,
        rand(), rand(), rand(),1,
        rand(), rand(), rand(),1,
    ]

    triangles = GLuint[
        0, 1, 2,
        1, 3, 4,
        5, 6, 3,
        7, 3, 6,
        2, 4, 7,
        0, 7, 6,
        0, 5, 1,
        1, 5, 3,
        5, 0, 6,
        7, 4, 3,
        2, 1, 4,
        0, 2, 7
    ] 
        vbo, ibo, vertices_count, triangles_count = JamCreateBuffers(vertices, colors, triangles)
        new([0 0 0], vbo, ibo, vertices_count, triangles_count )
    end
end

width, height = fb_width, fb_height = 800, 600
window = startgl(width, height)

glEnable(GL_DEPTH_TEST)
glDepthFunc(GL_LESS)

vao = GLuint(0)
@c glGenVertexArrays(1, &vao)
glBindVertexArray(vao)

vert_shader = createshader(joinpath(@__DIR__, "jamShader.vert"), GL_VERTEX_SHADER)
frag_shader = createshader(joinpath(@__DIR__, "jamShader.frag"), GL_FRAGMENT_SHADER)
shader_prog = createprogram(vert_shader, frag_shader)

# enable cull face
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

quad_1 = Cube()
quad_1.position = [0, 0, 0]

let
    updatefps = FPSCounter()
    α = 0
    while !GLFW.WindowShouldClose(window)
        updatefps(window)
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)
        glPolygonMode(GL_FRONT_AND_BACK, GL_LINE)
        glViewport(0, 0, GLFW.GetFramebufferSize(window)...)
        glUseProgram(shader_prog)
        glBindVertexArray(vao)

        model_mat = GLfloat[ 
            1.0   0.0   0.0   quad_1.position[1]
            0.0   1.0   0.0   quad_1.position[2]
            0.0   0.0   1.0   quad_1.position[3]
            0.0   0.0   0.0         1.0        
        ]

        α += 0.01
        β = α/3.2
        θ = α*1.02

        rotationY = GLfloat[
            cos(α)    0   sin(α)  0
              0       1     0     0
            -sin(α)   0   cos(α)  0
              0       0     0     1
        ]

        rotationX = GLfloat[
            1       0       0     0
            0   cos(β)  -sin(β)   0
            0   sin(β)   cos(β)   0
            0       0       0     1
        ]

        rotationZ = GLfloat[
            cos(θ)  -sin(θ)   0   0
            sin(θ)   cos(θ)   0   0
               0       0      1   0
               0       0      0   1
        ]

        model_mat = rotationX * rotationY * rotationZ * model_mat

        glUniformMatrix4fv(view_loc, 1, GL_FALSE, get_view_matrix(camera))
        glUniformMatrix4fv(proj_loc, 1, GL_FALSE, get_projective_matrix(window, camera))
        glUniformMatrix4fv(model_loc, 1, GL_FALSE, model_mat)
        JamDraw(quad_1)

        GLFW.PollEvents()
        updatecamera!(window, camera)
        glUniformMatrix4fv(view_loc, 1, GL_FALSE, get_view_matrix(camera))
        GLFW.SwapBuffers(window)
    end
end

GLFW.DestroyWindow(window)
