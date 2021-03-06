# https://www.youtube.com/watch?v=lRUaQ_Hcno8
using CSyntax
include(joinpath(@__DIR__, "glutils.jl"))

function createBuffers(vertices::Array{GLfloat}, colors::Array{GLfloat}, triangles::Array{GLuint})
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

abstract type Drawable    
end

mutable struct Square <: Drawable
    position::Array{GLfloat}
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
            0,1,2,
            1,3,2,
        ]
        vbo, ibo, vertices_count, triangles_count = createBuffers(vertices, colors, triangles)
        new([0 0 0], vbo, ibo, vertices_count, triangles_count )
    end
end

mutable struct Triforce <: Drawable
    position::Array{GLfloat}
    vbo
    ibo
    vertices_count
    triangles_count
    function Triforce()
        vertices = GLfloat[           # indices
                 0.0,  0.5, 0.0,          # 0
                -0.25, 0.0, 0.0,          # 1
                 0.25, 0.0, 0.0,          # 2
                -0.5, -0.5, 0.0,          # 3
                 0.0, -0.5, 0.0,          # 4
                 0.5, -0.5, 0.0           # 5
                ]
        colors = GLfloat[
                    1.0, 1.0, 0.0, 1.0,
                    1.0, 1.0, 0.0, 1.0,
                    1.0, 1.0, 0.0, 1.0,
                    1.0, 0.0, 1.0, 1.0,
                    1.0, 0.0, 0.0, 1.0,
                    1.0, 0.0, 1.0, 1.0
                ]
        triangles = GLuint[
                    0, 1 , 2,
                    1, 3 , 4,
                    2, 4 , 5
                ]

        vbo, ibo, vertices_count, triangles_count = createBuffers(vertices, colors, triangles)
        new([0 0 0], vbo, ibo, vertices_count, triangles_count)
    end
end

mutable struct TriforceRed <: Drawable
    position::Array{GLfloat}
    vbo
    ibo
    vertices_count
    triangles_count
    function TriforceRed()
        vertices = GLfloat[           # indices
                 0.0,  0.5, 0.0,          # 0
                -0.25, 0.0, 0.0,          # 1
                 0.25, 0.0, 0.0,          # 2
                -0.5, -0.5, 0.0,          # 3
                 0.0, -0.5, 0.0,          # 4
                 0.5, -0.5, 0.0           # 5
                ]                
        colors = GLfloat[
                    1.0, 0.0, 0.0, 1.0,
                    1.0, 0.0, 0.0, 1.0,
                    1.0, 0.0, 0.0, 1.0,
                    1.0, 0.0, 1.0, 1.0,
                    1.0, 0.0, 0.0, 1.0,
                    1.0, 0.0, 1.0, 1.0
                ]
        triangles = GLuint[
                    0, 1 , 2,
                    1, 3 , 4,
                    2, 4 , 5
                ]
        vbo, ibo, vertices_count, triangles_count = createBuffers(vertices, colors, triangles)
        new([0 0 0], vbo, ibo, vertices_count, triangles_count)
    end
end

# init window
width, height = fb_width, fb_height = 1000, 1000
window = startgl(width, height)

glEnable(GL_DEPTH_TEST)
glDepthFunc(GL_LESS)
glClearColor(0.1, 0.05, 0.05, 1.0)

# compile shader
vert_shader = createshader(joinpath(@__DIR__, "shader.vert"), GL_VERTEX_SHADER)
frag_shader = createshader(joinpath(@__DIR__, "shader.frag"), GL_FRAGMENT_SHADER)
shader_prog = createprogram(vert_shader, frag_shader)

gWorldLocation = glGetUniformLocation(shader_prog, "gWorld")
println(gWorldLocation)

vao = GLuint(0)
@c glGenVertexArrays(1,&vao)
glBindVertexArray(vao)

tri = Triforce()
tri.position = [-5.0, 5.0, 0.0]

tri2 = TriforceRed()
tri2.position = [5.0, 0.0, 0.0]

quad = Square()
quad.position = [0.0, 0.0, 0.0]

function draw(obj::Drawable)
    glBindBuffer(GL_ARRAY_BUFFER, obj.vbo)
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, obj.ibo)
    glVertexAttribPointer( 0, 3, GL_FLOAT, GL_FALSE, 0, C_NULL)
    glVertexAttribPointer( 1, 4, GL_FLOAT, GL_FALSE, 0, C_NULL+(obj.vertices_count))
    glEnableVertexAttribArray(0)
    glEnableVertexAttribArray(1)
    glDrawElements(GL_TRIANGLES, obj.triangles_count, GL_UNSIGNED_INT, C_NULL)

end

let
    wScale = 0.1
    updatefps = FPSCounter()
    while !GLFW.WindowShouldClose(window)
        updatefps(window)
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)
        #glPolygonMode(GL_FRONT_AND_BACK, GL_LINE)
        glViewport(0, 0, width, height)
        glUseProgram(shader_prog)

        worldScaling = GLfloat[
            wScale 0 0 0 
            0 wScale 0 0
            0 0 wScale 0
            0 0 0     1
        ]

        ### draw tri      
        translate = GLfloat[
            1 0 0 tri.position[1]
            0 1 0 tri.position[2]
            0 0 1 tri.position[3]
            0 0 0 1
        ]
        ?? = 1
        rotation = GLfloat[
            cos(??) -sin(??)  0   0
            sin(??)  cos(??)  0   0
            0       0       1   0
            0       0       0   1
        ]
        transform =  rotation * translate' * worldScaling
        glUniformMatrix4fv(gWorldLocation, 1, GL_TRUE, transform)
        draw(tri)

        ### draw tri2
        translate = [
            1 0 0 tri2.position[1]
            0 1 0 tri2.position[2]
            0 0 1 tri2.position[3]
            0 0 0 1
        ]
        transform = translate' * worldScaling
        glUniformMatrix4fv(gWorldLocation, 1, GL_TRUE, transform)
        draw(tri2)

        # draw quad
        transform = worldScaling
        glUniformMatrix4fv(gWorldLocation, 1, GL_TRUE, transform)
        draw(quad)

        # check/call events & swap buffers
        GLFW.PollEvents()
        GLFW.SwapBuffers(window)
    end
end

GLFW.DestroyWindow(window)
