module Jam3D
    using CSyntax
    using Quaternions
    using LinearAlgebra
    using StaticArrays
    using GLTF
    using ModernGL

    mutable struct GltfObject
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
        
        function GltfObject(fileName)
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
end