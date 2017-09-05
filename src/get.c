/* The MIT License (MIT)
 *
 * Copyright (c) 2016 Stefano Trettel
 *
 * Software repository: MoonGL, https://github.com/stetre/moongl
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

#include "internal.h"

ENUM_STRINGS(PnameStrings) = {
    "context flags",
    "major version",
    "max server wait timeout",
    "min map buffer alignment",
    "minor version",
    "num extensions",
    "num shading language versions",
    "timestamp",
    /* Buffer Binding State */
    "array buffer binding",
    "copy read buffer binding",
    "copy write buffer binding",
    "draw indirect buffer binding",
    "element array buffer binding",
    "query buffer binding",
    "texture buffer binding",
    "vertex array binding",
    "max atomic counter buffer bindings",
    "atomic counter buffer binding",
    "atomic counter buffer start",
    "atomic counter buffer size",
    "max shader storage buffer bindings",
    "shader storage buffer binding",
    "shader storage buffer start",
    "shader storage buffer size",
    "max transform feedback buffers",
    "max transform feedback buffer bindings", /* alias */
    "transform feedback buffer binding",
    "transform feedback buffer start",
    "transform feedback buffer size",
    "max uniform buffer bindings",
    "uniform buffer binding",
    "uniform buffer start",
    "uniform buffer size",
    "max transform feedback interleaved components",
    "max transform feedback separate attribs",
    "max transform feedback separate components",
    "transform feedback paused",
    "transform feedback active",
    /* Debug Output State */
    "debug group stack depth",
    "debug logged messages",
    "debug next logged message length",
    "debug output",
    "debug output synchronous",
    "max debug logged messages",
    "max debug message length",
    "max debug group stack depth",
    "max label length",
    /* Framebuffers */
    "color clear value",
    "color writemask",
    "depth clear value",
    "depth func",
    "depth test",
    "depth writemask",
    "doublebuffer",
    "draw buffer",
    "draw buffer 0",
    "draw buffer 1",
    "draw buffer 2",
    "draw buffer 3",
    "draw buffer 4",
    "draw buffer 5",
    "draw buffer 6",
    "draw buffer 7",
    "draw buffer 8",
    "draw buffer 9",
    "draw buffer 10",
    "draw buffer 11",
    "draw buffer 12",
    "draw buffer 13",
    "draw buffer 14",
    "draw buffer 15",
    "draw framebuffer binding",
    "max color attachments",
    "max color texture samples",
    "max depth texture samples",
    "max draw buffers",
    "max dual source draw buffers",
    "max framebuffer height",
    "max framebuffer layers",
    "max framebuffer samples",
    "max framebuffer width",
    "max integer samples",
    "max samples",
    "read buffer",
    "read framebuffer binding",
    "renderbuffer binding",
    "stencil back fail",
    "stencil back func",
    "stencil back pass depth fail",
    "stencil back pass depth pass",
    "stencil back ref",
    "stencil back value mask",
    "stencil back writemask",
    "stencil clear value",
    "stencil fail",
    "stencil func",
    "stencil pass depth fail",
    "stencil pass depth pass",
    "stencil ref",
    "stencil test",
    "stencil value mask",
    "stencil writemask",
    "stereo",
    /* Hints */
    "fragment shader derivative hint",
    "line smooth hint",
    "polygon smooth hint",
    "texture compression hint",
    /* Image State */
    "image binding access",
    "image binding format",
    "image binding name",
    "image binding layer",
    "image binding layered",
    "image binding level",
    /* Multisampling */
    "max sample mask words",
    "multisample",
    "sample alpha to coverage",
    "sample alpha to one",
    "sample buffers",
    "sample coverage",
    "sample coverage invert",
    "sample coverage value",
    "sample mask",
    "sample mask value",
    "samples",
    /* Pixel Operations */
    "blend",
    "blend color",
    "blend dst alpha",
    "blend dst rgb",
    "blend equation rgb",
    "blend equation alpha",
    "blend src alpha",
    "blend src rgb",
    "color logic op",
    "dither",
    "logic op mode",
    "scissor box",
    "scissor test",
    /* Pixel Transfer Operations */
    "clamp read color",
    "implementation color read format",
    "implementation color read type",
    "pack alignment",
    "pack compressed block depth",
    "pack compressed block height",
    "pack compressed block size",
    "pack compressed block width",
    "pack image height",
    "pack lsb first",
    "pack row length",
    "pack skip images",
    "pack skip pixels",
    "pack skip rows",
    "pack swap bytes",
    "pixel pack buffer binding",
    "pixel unpack buffer binding",
    "unpack alignment",
    "unpack compressed block depth",
    "unpack compressed block height",
    "unpack compressed block size",
    "unpack compressed block width",
    "unpack image height",
    "unpack lsb first",
    "unpack row length",
    "unpack skip images",
    "unpack skip pixels",
    "unpack skip rows",
    "unpack swap bytes",
    /* Programs */
    "current program", 
    "max atomic counter buffer size",
    "max combined shader output resources", 
    "max combined shader storage blocks", 
    "max image samples", 
    "max image units", 
    "max program texel offset", 
    "max shader storage block size", 
    "max subroutines", 
    "max subroutine uniform locations", 
    "max uniform block size", 
    "max uniform locations", 
    "max varying vectors", 
    "max vertex attrib relative offset", 
    "max vertex attrib bindings", 
    "max vertex attrib stride", 
    "min program texel offset", 
    "num program binary formats", 
    "num shader binary formats", 
    "program binary formats", 
    "program pipeline binding", 
    "shader binary formats", 
    "shader compiler",
    "shader storage buffer offset alignment", 
    "uniform buffer offset alignment", 
    /* Provoking Vertices */
    "viewport index provoking vertex",
    "layer provoking vertex",
    "provoking vertex",
    /* Rasterization */
    "aliased line width range",
    "cull face", 
    "cull face mode", 
    "front face", 
    "line smooth", 
    "line width", 
    "point fade threshold size", 
    "point size", 
    "point size granularity", 
    "point size range", 
    "point sprite coord origin", 
    "polygon mode", 
    "polygon offset factor",
    "polygon offset fill", 
    "polygon offset line", 
    "polygon offset point", 
    "polygon offset units",
    "polygon smooth", 
    "program point size", 
    "rasterizer discard", 
    "smooth line width range", 
    "smooth line width granularity", 
    "subpixel bits", 
    /* Shader Execution */
    "fragment interpolation offset bits",
    "max fragment interpolation offset",
    "min fragment interpolation offset",
    /* Shaders */
    "max combined atomic counter buffers",
    "max compute atomic counter buffers",
    "max fragment atomic counter buffers",
    "max geometry atomic counter buffers",
    "max tess control atomic counter buffers",
    "max tess evaluation atomic counter buffers",
    "max vertex atomic counter buffers",
    "max combined atomic counters",
    "max compute atomic counters",
    "max fragment atomic counters",
    "max geometry atomic counters",
    "max tess control atomic counters",
    "max tess evaluation atomic counters",
    "max vertex atomic counters",
    "max combined compute uniform components",
    "max combined fragment uniform components",
    "max combined geometry uniform components",
    "max combined tess control uniform components",
    "max combined tess evaluation uniform components",
    "max combined vertex uniform components",
    "max combined image uniforms",
    "max compute image uniforms",
    "max fragment image uniforms",
    "max geometry image uniforms",
    "max tess control image uniforms",
    "max tess evaluation image uniforms",
    "max vertex image uniforms",
    "max compute shader storage blocks",
    "max fragment shader storage blocks",
    "max geometry shader storage blocks",
    "max tess control shader storage blocks",
    "max tess evaluation shader storage blocks",
    "max vertex shader storage blocks",
    "max compute uniform components",
    "max fragment uniform components",
    "max geometry uniform components",
    "max tess control uniform components",
    "max tess evaluation uniform components",
    "max vertex uniform components",
    "max texture image units",
    "max combined texture image units",
    "max compute texture image units",
    "max geometry texture image units",
    "max tess control texture image units",
    "max tess evaluation texture image units",
    "max vertex texture image units",
    "max combined uniform blocks",
    "max compute uniform blocks",
    "max fragment uniform blocks",
    "max geometry uniform blocks",
    "max tess control uniform blocks",
    "max tess evaluation uniform blocks",
    "max vertex uniform blocks",
    /* Compute Shaders */
    "dispatch indirect buffer binding",
    "max compute shared memory size",
    "max compute work group invocations",
    "max compute work group count",
    "max compute work group size",
    /* Fragment Shaders */
    "max fragment input components",
    "max fragment uniform vectors",
    "max program texture gather offset",
    "min program texture gather offset",
    /* Geometry Shaders */
    "max geometry input components",
    "max geometry output components",
    "max geometry output vertices",
    "max geometry shader invocations",
    "max geometry total output components",
    "max vertex streams",
    /* Tessellation Control Shaders */
    "max patch vertices",
    "max tess control input components",
    "max tess control output components",
    "max tess control total output components",
    "max tess gen level",
    "max tess patch components",
    "patch default inner level",
    "patch default outer level",
    "patch vertices",
    /* Tessellation Evaluation Shaders */
    "max tess evaluation input components",
    "max tess evaluation output components",
    /* Vertex Shaders */
    "max vertex attribs",
    "max vertex output components",
    "max vertex uniform vectors",
    /* Textures */
    "active texture",
    "compressed texture formats",
    "max 3d texture size",
    "max array texture layers",
    "max cube map texture size",
    "max rectangle texture size",
    "max renderbuffer size",
    "max texture buffer size",
    "max texture lod bias",
    "max texture size",
    "num compressed texture formats",
    "sampler binding",
    "texture binding 1d",
    "texture binding 1d array",
    "texture binding 2d",
    "texture binding 2d array",
    "texture binding 2d multisample",
    "texture binding 2d multisample array",
    "texture binding 3d",
    "texture binding buffer",
    "texture binding cube map",
    "texture binding rectangle",
    "texture buffer offset alignment",
    "texture cube map seamless",
    /* Transformation State */
    "clip distance 0",
    "clip distance 1",
    "clip distance 2",
    "clip distance 3",
    "clip distance 4",
    "clip distance 5",
    "clip distance 6",
    "clip distance 7",
    "depth clamp",
    "depth range",
    "max clip distances",
    "max viewport dims",
    "max viewports",
    "transform feedback binding",
    "viewport",
    "viewport bounds range",
    "viewport subpixel bits",
    /* Vertex Arrays */
    "max element index",
    "max elements indices",
    "max elements vertices",
    "primitive restart",
    "primitive restart fixed index",
    "primitive restart for patches supported",
    "primitive restart index",
    "vertex binding divisor",
    "vertex binding offset",
    "vertex binding stride",
    "max varying floats",
    NULL
};
ENUM_CODES(PnameCodes) = {
    GL_CONTEXT_FLAGS,
    GL_MAJOR_VERSION,
    GL_MAX_SERVER_WAIT_TIMEOUT,
    GL_MIN_MAP_BUFFER_ALIGNMENT,
    GL_MINOR_VERSION,
    GL_NUM_EXTENSIONS,
    GL_NUM_SHADING_LANGUAGE_VERSIONS,
    GL_TIMESTAMP,
    /* Buffer Binding State */
    GL_ARRAY_BUFFER_BINDING,
    GL_COPY_READ_BUFFER_BINDING,
    GL_COPY_WRITE_BUFFER_BINDING,
    GL_DRAW_INDIRECT_BUFFER_BINDING,
    GL_ELEMENT_ARRAY_BUFFER_BINDING,
    GL_QUERY_BUFFER_BINDING,
    GL_TEXTURE_BUFFER_BINDING,
    GL_VERTEX_ARRAY_BINDING,
    GL_MAX_ATOMIC_COUNTER_BUFFER_BINDINGS,
    GL_ATOMIC_COUNTER_BUFFER_BINDING,
    GL_ATOMIC_COUNTER_BUFFER_START,
    GL_ATOMIC_COUNTER_BUFFER_SIZE,
    GL_MAX_SHADER_STORAGE_BUFFER_BINDINGS,
    GL_SHADER_STORAGE_BUFFER_BINDING,
    GL_SHADER_STORAGE_BUFFER_START,
    GL_SHADER_STORAGE_BUFFER_SIZE,
    GL_MAX_TRANSFORM_FEEDBACK_BUFFERS, /* for GL_MAX_TRANSFORM_FEEDBACK_BUFFER_BINDINGS */
    GL_MAX_TRANSFORM_FEEDBACK_BUFFERS,
    GL_TRANSFORM_FEEDBACK_BUFFER_BINDING,
    GL_TRANSFORM_FEEDBACK_BUFFER_START,
    GL_TRANSFORM_FEEDBACK_BUFFER_SIZE,
    GL_MAX_UNIFORM_BUFFER_BINDINGS,
    GL_UNIFORM_BUFFER_BINDING,
    GL_UNIFORM_BUFFER_START,
    GL_UNIFORM_BUFFER_SIZE,
    GL_MAX_TRANSFORM_FEEDBACK_INTERLEAVED_COMPONENTS,
    GL_MAX_TRANSFORM_FEEDBACK_SEPARATE_ATTRIBS,
    GL_MAX_TRANSFORM_FEEDBACK_SEPARATE_COMPONENTS,
    GL_TRANSFORM_FEEDBACK_PAUSED,
    GL_TRANSFORM_FEEDBACK_ACTIVE,
    /* Debug Output State */
    GL_DEBUG_GROUP_STACK_DEPTH,
    GL_DEBUG_LOGGED_MESSAGES,
    GL_DEBUG_NEXT_LOGGED_MESSAGE_LENGTH,
    GL_DEBUG_OUTPUT,
    GL_DEBUG_OUTPUT_SYNCHRONOUS,
    GL_MAX_DEBUG_LOGGED_MESSAGES,
    GL_MAX_DEBUG_MESSAGE_LENGTH,
    GL_MAX_DEBUG_GROUP_STACK_DEPTH,
    GL_MAX_LABEL_LENGTH,
    /* Framebuffers */
    GL_COLOR_CLEAR_VALUE,
    GL_COLOR_WRITEMASK,
    GL_DEPTH_CLEAR_VALUE,
    GL_DEPTH_FUNC,
    GL_DEPTH_TEST,
    GL_DEPTH_WRITEMASK,
    GL_DOUBLEBUFFER,
    GL_DRAW_BUFFER,
    GL_DRAW_BUFFER0,
    GL_DRAW_BUFFER1,
    GL_DRAW_BUFFER2,
    GL_DRAW_BUFFER3,
    GL_DRAW_BUFFER4,
    GL_DRAW_BUFFER5,
    GL_DRAW_BUFFER6,
    GL_DRAW_BUFFER7,
    GL_DRAW_BUFFER8,
    GL_DRAW_BUFFER9,
    GL_DRAW_BUFFER10,
    GL_DRAW_BUFFER11,
    GL_DRAW_BUFFER12,
    GL_DRAW_BUFFER13,
    GL_DRAW_BUFFER14,
    GL_DRAW_BUFFER15,
    GL_DRAW_FRAMEBUFFER_BINDING,
    GL_MAX_COLOR_ATTACHMENTS,
    GL_MAX_COLOR_TEXTURE_SAMPLES,
    GL_MAX_DEPTH_TEXTURE_SAMPLES,
    GL_MAX_DRAW_BUFFERS,
    GL_MAX_DUAL_SOURCE_DRAW_BUFFERS,
    GL_MAX_FRAMEBUFFER_HEIGHT,
    GL_MAX_FRAMEBUFFER_LAYERS,
    GL_MAX_FRAMEBUFFER_SAMPLES,
    GL_MAX_FRAMEBUFFER_WIDTH,
    GL_MAX_INTEGER_SAMPLES,
    GL_MAX_SAMPLES,
    GL_READ_BUFFER,
    GL_READ_FRAMEBUFFER_BINDING,
    GL_RENDERBUFFER_BINDING,
    GL_STENCIL_BACK_FAIL,
    GL_STENCIL_BACK_FUNC,
    GL_STENCIL_BACK_PASS_DEPTH_FAIL,
    GL_STENCIL_BACK_PASS_DEPTH_PASS,
    GL_STENCIL_BACK_REF,
    GL_STENCIL_BACK_VALUE_MASK,
    GL_STENCIL_BACK_WRITEMASK,
    GL_STENCIL_CLEAR_VALUE,
    GL_STENCIL_FAIL,
    GL_STENCIL_FUNC,
    GL_STENCIL_PASS_DEPTH_FAIL,
    GL_STENCIL_PASS_DEPTH_PASS,
    GL_STENCIL_REF,
    GL_STENCIL_TEST,
    GL_STENCIL_VALUE_MASK,
    GL_STENCIL_WRITEMASK,
    GL_STEREO,
    /* Hints */
    GL_FRAGMENT_SHADER_DERIVATIVE_HINT,
    GL_LINE_SMOOTH_HINT,
    GL_POLYGON_SMOOTH_HINT,
    GL_TEXTURE_COMPRESSION_HINT,
    /* Image State */
    GL_IMAGE_BINDING_ACCESS,
    GL_IMAGE_BINDING_FORMAT,
    GL_IMAGE_BINDING_NAME,
    GL_IMAGE_BINDING_LAYER,
    GL_IMAGE_BINDING_LAYERED,
    GL_IMAGE_BINDING_LEVEL,
    /* Multisampling */
    GL_MAX_SAMPLE_MASK_WORDS,
    GL_MULTISAMPLE,
    GL_SAMPLE_ALPHA_TO_COVERAGE,
    GL_SAMPLE_ALPHA_TO_ONE,
    GL_SAMPLE_BUFFERS,
    GL_SAMPLE_COVERAGE,
    GL_SAMPLE_COVERAGE_INVERT,
    GL_SAMPLE_COVERAGE_VALUE,
    GL_SAMPLE_MASK,
    GL_SAMPLE_MASK_VALUE,
    GL_SAMPLES,
    /* Pixel Operations */
    GL_BLEND,
    GL_BLEND_COLOR,
    GL_BLEND_DST_ALPHA,
    GL_BLEND_DST_RGB,
    GL_BLEND_EQUATION_RGB,
    GL_BLEND_EQUATION_ALPHA,
    GL_BLEND_SRC_ALPHA,
    GL_BLEND_SRC_RGB,
    GL_COLOR_LOGIC_OP,
    GL_DITHER,
    GL_LOGIC_OP_MODE,
    GL_SCISSOR_BOX,
    GL_SCISSOR_TEST,
    /* Pixel Transfer Operations */
    GL_CLAMP_READ_COLOR,
    GL_IMPLEMENTATION_COLOR_READ_FORMAT,
    GL_IMPLEMENTATION_COLOR_READ_TYPE,
    GL_PACK_ALIGNMENT,
    GL_PACK_COMPRESSED_BLOCK_DEPTH,
    GL_PACK_COMPRESSED_BLOCK_HEIGHT,
    GL_PACK_COMPRESSED_BLOCK_SIZE,
    GL_PACK_COMPRESSED_BLOCK_WIDTH,
    GL_PACK_IMAGE_HEIGHT,
    GL_PACK_LSB_FIRST,
    GL_PACK_ROW_LENGTH,
    GL_PACK_SKIP_IMAGES,
    GL_PACK_SKIP_PIXELS,
    GL_PACK_SKIP_ROWS,
    GL_PACK_SWAP_BYTES,
    GL_PIXEL_PACK_BUFFER_BINDING,
    GL_PIXEL_UNPACK_BUFFER_BINDING,
    GL_UNPACK_ALIGNMENT,
    GL_UNPACK_COMPRESSED_BLOCK_DEPTH,
    GL_UNPACK_COMPRESSED_BLOCK_HEIGHT,
    GL_UNPACK_COMPRESSED_BLOCK_SIZE,
    GL_UNPACK_COMPRESSED_BLOCK_WIDTH,
    GL_UNPACK_IMAGE_HEIGHT,
    GL_UNPACK_LSB_FIRST,
    GL_UNPACK_ROW_LENGTH,
    GL_UNPACK_SKIP_IMAGES,
    GL_UNPACK_SKIP_PIXELS,
    GL_UNPACK_SKIP_ROWS,
    GL_UNPACK_SWAP_BYTES,
    /* Programs */
    GL_CURRENT_PROGRAM, 
    GL_MAX_ATOMIC_COUNTER_BUFFER_SIZE,
    GL_MAX_COMBINED_SHADER_OUTPUT_RESOURCES, 
    GL_MAX_COMBINED_SHADER_STORAGE_BLOCKS, 
    GL_MAX_IMAGE_SAMPLES, 
    GL_MAX_IMAGE_UNITS, 
    GL_MAX_PROGRAM_TEXEL_OFFSET, 
    GL_MAX_SHADER_STORAGE_BLOCK_SIZE, 
    GL_MAX_SUBROUTINES, 
    GL_MAX_SUBROUTINE_UNIFORM_LOCATIONS, 
    GL_MAX_UNIFORM_BLOCK_SIZE, 
    GL_MAX_UNIFORM_LOCATIONS, 
    GL_MAX_VARYING_VECTORS, 
    GL_MAX_VERTEX_ATTRIB_RELATIVE_OFFSET, 
    GL_MAX_VERTEX_ATTRIB_BINDINGS, 
    GL_MAX_VERTEX_ATTRIB_STRIDE, 
    GL_MIN_PROGRAM_TEXEL_OFFSET, 
    GL_NUM_PROGRAM_BINARY_FORMATS, 
    GL_NUM_SHADER_BINARY_FORMATS, 
    GL_PROGRAM_BINARY_FORMATS, 
    GL_PROGRAM_PIPELINE_BINDING, 
    GL_SHADER_BINARY_FORMATS, 
    GL_SHADER_COMPILER,
    GL_SHADER_STORAGE_BUFFER_OFFSET_ALIGNMENT, 
    GL_UNIFORM_BUFFER_OFFSET_ALIGNMENT, 
    /* Provoking Vertices */
    GL_VIEWPORT_INDEX_PROVOKING_VERTEX,
    GL_LAYER_PROVOKING_VERTEX,
    GL_PROVOKING_VERTEX,
    /* Rasterization */
    GL_ALIASED_LINE_WIDTH_RANGE,
    GL_CULL_FACE, 
    GL_CULL_FACE_MODE, 
    GL_FRONT_FACE, 
    GL_LINE_SMOOTH, 
    GL_LINE_WIDTH, 
    GL_POINT_FADE_THRESHOLD_SIZE, 
    GL_POINT_SIZE, 
    GL_POINT_SIZE_GRANULARITY, 
    GL_POINT_SIZE_RANGE, 
    GL_POINT_SPRITE_COORD_ORIGIN, 
    GL_POLYGON_MODE, 
    GL_POLYGON_OFFSET_FACTOR,
    GL_POLYGON_OFFSET_FILL, 
    GL_POLYGON_OFFSET_LINE, 
    GL_POLYGON_OFFSET_POINT, 
    GL_POLYGON_OFFSET_UNITS,
    GL_POLYGON_SMOOTH, 
    GL_PROGRAM_POINT_SIZE, 
    GL_RASTERIZER_DISCARD, 
    GL_SMOOTH_LINE_WIDTH_RANGE, 
    GL_SMOOTH_LINE_WIDTH_GRANULARITY, 
    GL_SUBPIXEL_BITS, 
    /* Shader Execution */
    GL_FRAGMENT_INTERPOLATION_OFFSET_BITS,
    GL_MAX_FRAGMENT_INTERPOLATION_OFFSET,
    GL_MIN_FRAGMENT_INTERPOLATION_OFFSET,
    /* Shaders */
    GL_MAX_COMBINED_ATOMIC_COUNTER_BUFFERS,
    GL_MAX_COMPUTE_ATOMIC_COUNTER_BUFFERS,
    GL_MAX_FRAGMENT_ATOMIC_COUNTER_BUFFERS,
    GL_MAX_GEOMETRY_ATOMIC_COUNTER_BUFFERS,
    GL_MAX_TESS_CONTROL_ATOMIC_COUNTER_BUFFERS,
    GL_MAX_TESS_EVALUATION_ATOMIC_COUNTER_BUFFERS,
    GL_MAX_VERTEX_ATOMIC_COUNTER_BUFFERS,
    GL_MAX_COMBINED_ATOMIC_COUNTERS,
    GL_MAX_COMPUTE_ATOMIC_COUNTERS,
    GL_MAX_FRAGMENT_ATOMIC_COUNTERS,
    GL_MAX_GEOMETRY_ATOMIC_COUNTERS,
    GL_MAX_TESS_CONTROL_ATOMIC_COUNTERS,
    GL_MAX_TESS_EVALUATION_ATOMIC_COUNTERS,
    GL_MAX_VERTEX_ATOMIC_COUNTERS,
    GL_MAX_COMBINED_COMPUTE_UNIFORM_COMPONENTS,
    GL_MAX_COMBINED_FRAGMENT_UNIFORM_COMPONENTS,
    GL_MAX_COMBINED_GEOMETRY_UNIFORM_COMPONENTS,
    GL_MAX_COMBINED_TESS_CONTROL_UNIFORM_COMPONENTS,
    GL_MAX_COMBINED_TESS_EVALUATION_UNIFORM_COMPONENTS,
    GL_MAX_COMBINED_VERTEX_UNIFORM_COMPONENTS,
    GL_MAX_COMBINED_IMAGE_UNIFORMS,
    GL_MAX_COMPUTE_IMAGE_UNIFORMS,
    GL_MAX_FRAGMENT_IMAGE_UNIFORMS,
    GL_MAX_GEOMETRY_IMAGE_UNIFORMS,
    GL_MAX_TESS_CONTROL_IMAGE_UNIFORMS,
    GL_MAX_TESS_EVALUATION_IMAGE_UNIFORMS,
    GL_MAX_VERTEX_IMAGE_UNIFORMS,
    GL_MAX_COMPUTE_SHADER_STORAGE_BLOCKS,
    GL_MAX_FRAGMENT_SHADER_STORAGE_BLOCKS,
    GL_MAX_GEOMETRY_SHADER_STORAGE_BLOCKS,
    GL_MAX_TESS_CONTROL_SHADER_STORAGE_BLOCKS,
    GL_MAX_TESS_EVALUATION_SHADER_STORAGE_BLOCKS,
    GL_MAX_VERTEX_SHADER_STORAGE_BLOCKS,
    GL_MAX_COMPUTE_UNIFORM_COMPONENTS,
    GL_MAX_FRAGMENT_UNIFORM_COMPONENTS,
    GL_MAX_GEOMETRY_UNIFORM_COMPONENTS,
    GL_MAX_TESS_CONTROL_UNIFORM_COMPONENTS,
    GL_MAX_TESS_EVALUATION_UNIFORM_COMPONENTS,
    GL_MAX_VERTEX_UNIFORM_COMPONENTS,
    GL_MAX_TEXTURE_IMAGE_UNITS,
    GL_MAX_COMBINED_TEXTURE_IMAGE_UNITS,
    GL_MAX_COMPUTE_TEXTURE_IMAGE_UNITS,
    GL_MAX_GEOMETRY_TEXTURE_IMAGE_UNITS,
    GL_MAX_TESS_CONTROL_TEXTURE_IMAGE_UNITS,
    GL_MAX_TESS_EVALUATION_TEXTURE_IMAGE_UNITS,
    GL_MAX_VERTEX_TEXTURE_IMAGE_UNITS,
    GL_MAX_COMBINED_UNIFORM_BLOCKS,
    GL_MAX_COMPUTE_UNIFORM_BLOCKS,
    GL_MAX_FRAGMENT_UNIFORM_BLOCKS,
    GL_MAX_GEOMETRY_UNIFORM_BLOCKS,
    GL_MAX_TESS_CONTROL_UNIFORM_BLOCKS,
    GL_MAX_TESS_EVALUATION_UNIFORM_BLOCKS,
    GL_MAX_VERTEX_UNIFORM_BLOCKS,
    /* Compute Shaders */
    GL_DISPATCH_INDIRECT_BUFFER_BINDING,
    GL_MAX_COMPUTE_SHARED_MEMORY_SIZE,
    GL_MAX_COMPUTE_WORK_GROUP_INVOCATIONS,
    GL_MAX_COMPUTE_WORK_GROUP_COUNT,
    GL_MAX_COMPUTE_WORK_GROUP_SIZE,
    /* Fragment Shaders */
    GL_MAX_FRAGMENT_INPUT_COMPONENTS,
    GL_MAX_FRAGMENT_UNIFORM_VECTORS,
    GL_MAX_PROGRAM_TEXTURE_GATHER_OFFSET,
    GL_MIN_PROGRAM_TEXTURE_GATHER_OFFSET,
    /* Geometry Shaders */
    GL_MAX_GEOMETRY_INPUT_COMPONENTS,
    GL_MAX_GEOMETRY_OUTPUT_COMPONENTS,
    GL_MAX_GEOMETRY_OUTPUT_VERTICES,
    GL_MAX_GEOMETRY_SHADER_INVOCATIONS,
    GL_MAX_GEOMETRY_TOTAL_OUTPUT_COMPONENTS,
    GL_MAX_VERTEX_STREAMS,
    /* Tessellation Control Shaders */
    GL_MAX_PATCH_VERTICES,
    GL_MAX_TESS_CONTROL_INPUT_COMPONENTS,
    GL_MAX_TESS_CONTROL_OUTPUT_COMPONENTS,
    GL_MAX_TESS_CONTROL_TOTAL_OUTPUT_COMPONENTS,
    GL_MAX_TESS_GEN_LEVEL,
    GL_MAX_TESS_PATCH_COMPONENTS,
    GL_PATCH_DEFAULT_INNER_LEVEL,
    GL_PATCH_DEFAULT_OUTER_LEVEL,
    GL_PATCH_VERTICES,
    /* Tessellation Evaluation Shaders */
    GL_MAX_TESS_EVALUATION_INPUT_COMPONENTS,
    GL_MAX_TESS_EVALUATION_OUTPUT_COMPONENTS,
    /* Vertex Shaders */
    GL_MAX_VERTEX_ATTRIBS,
    GL_MAX_VERTEX_OUTPUT_COMPONENTS,
    GL_MAX_VERTEX_UNIFORM_VECTORS,
    /* Textures */
    GL_ACTIVE_TEXTURE,
    GL_COMPRESSED_TEXTURE_FORMATS,
    GL_MAX_3D_TEXTURE_SIZE,
    GL_MAX_ARRAY_TEXTURE_LAYERS,
    GL_MAX_CUBE_MAP_TEXTURE_SIZE,
    GL_MAX_RECTANGLE_TEXTURE_SIZE,
    GL_MAX_RENDERBUFFER_SIZE,
    GL_MAX_TEXTURE_BUFFER_SIZE,
    GL_MAX_TEXTURE_LOD_BIAS,
    GL_MAX_TEXTURE_SIZE,
    GL_NUM_COMPRESSED_TEXTURE_FORMATS,
    GL_SAMPLER_BINDING,
    GL_TEXTURE_BINDING_1D,
    GL_TEXTURE_BINDING_1D_ARRAY,
    GL_TEXTURE_BINDING_2D,
    GL_TEXTURE_BINDING_2D_ARRAY,
    GL_TEXTURE_BINDING_2D_MULTISAMPLE,
    GL_TEXTURE_BINDING_2D_MULTISAMPLE_ARRAY,
    GL_TEXTURE_BINDING_3D,
    GL_TEXTURE_BINDING_BUFFER,
    GL_TEXTURE_BINDING_CUBE_MAP,
    GL_TEXTURE_BINDING_RECTANGLE,
    GL_TEXTURE_BUFFER_OFFSET_ALIGNMENT,
    GL_TEXTURE_CUBE_MAP_SEAMLESS,
    /* Transformation State */
    GL_CLIP_DISTANCE0,
    GL_CLIP_DISTANCE1,
    GL_CLIP_DISTANCE2,
    GL_CLIP_DISTANCE3,
    GL_CLIP_DISTANCE4,
    GL_CLIP_DISTANCE5,
    GL_CLIP_DISTANCE6,
    GL_CLIP_DISTANCE7,
    GL_DEPTH_CLAMP,
    GL_DEPTH_RANGE,
    GL_MAX_CLIP_DISTANCES,
    GL_MAX_VIEWPORT_DIMS,
    GL_MAX_VIEWPORTS,
    GL_TRANSFORM_FEEDBACK_BINDING,
    GL_VIEWPORT,
    GL_VIEWPORT_BOUNDS_RANGE,
    GL_VIEWPORT_SUBPIXEL_BITS,
    /* Vertex Arrays */
    GL_MAX_ELEMENT_INDEX,
    GL_MAX_ELEMENTS_INDICES,
    GL_MAX_ELEMENTS_VERTICES,
    GL_PRIMITIVE_RESTART,
    GL_PRIMITIVE_RESTART_FIXED_INDEX,
    GL_PRIMITIVE_RESTART_FOR_PATCHES_SUPPORTED,
    GL_PRIMITIVE_RESTART_INDEX,
    GL_VERTEX_BINDING_DIVISOR,
    GL_VERTEX_BINDING_OFFSET,
    GL_VERTEX_BINDING_STRIDE,
    GL_MAX_VARYING_FLOATS,
};
ENUM_T(PnameEnum, PnameStrings, PnameCodes)
#define CheckPname(L, arg) enumCheck((L), (arg), &PnameEnum)
#define PushPname(L, code) enumPush((L), (code), &PnameEnum)







ENUM_STRINGS(RNStrategyStrings) = {
    "no reset notification",
    "lose context on reset",
    NULL
};
ENUM_CODES(RNStrategyCodes) = {
    GL_NO_RESET_NOTIFICATION,
    GL_LOSE_CONTEXT_ON_RESET,
};
ENUM_T(RNStrategyEnum, RNStrategyStrings, RNStrategyCodes)
#define CheckRNStrategy(L, arg) enumCheck((L), (arg), &RNStrategyEnum)
#define PushRNStrategy(L, code) enumPush((L), (code), &RNStrategyEnum)

ENUM_STRINGS(GRStatusStrings) = {
    "no error",
    "guilty context reset",
    "innocent context reset",
    "unknown context reset",
    NULL
};
ENUM_CODES(GRStatusCodes) = {
    GL_NO_ERROR,
    GL_GUILTY_CONTEXT_RESET,
    GL_INNOCENT_CONTEXT_RESET,
    GL_UNKNOWN_CONTEXT_RESET,
};
ENUM_T(GRStatusEnum, GRStatusStrings, GRStatusCodes)
#define CheckGRStatus(L, arg) enumCheck((L), (arg), &GRStatusEnum)
#define PushGRStatus(L, code) enumPush((L), (code), &GRStatusEnum)

BITFIELD_STRINGS(ContextFlagStrings) = {
    "forward compatible",
    "debug",
    "robust access",
    NULL
};
BITFIELD_CODES(ContextFlagCodes) = {
    GL_CONTEXT_FLAG_FORWARD_COMPATIBLE_BIT,
    GL_CONTEXT_FLAG_DEBUG_BIT,
    GL_CONTEXT_FLAG_ROBUST_ACCESS_BIT,
};
BITFIELD_T(ContextFlagBitfield, ContextFlagStrings, ContextFlagCodes)
#define CheckContextFlag(L, arg, mand) bitfieldCheck((L), (arg), (mand), &ContextFlagBitfield)
#define PushContextFlag(L, code) bitfieldPush((L), (code), &ContextFlagBitfield)

/*------------------------------------------------------------------------------*
 | exported get() functions                                                     |
 *------------------------------------------------------------------------------*/

GLsizei getSizei(lua_State *L, GLenum pname)
    {
    GLint64 len;
    glGetInteger64v(pname, &len);
    CheckError(L);
    return (GLsizei)len;
    }

/*------------------------------------------------------------------------------*
 | Get()                                                                        |
 *------------------------------------------------------------------------------*/

static int GetActiveTexture(lua_State *L, GLenum pname)
    {
    GLint val;
    glGetIntegerv(pname, &val);
    CheckError(L);
    switch(val)
        {
#define CASE(n) case GL_TEXTURE##n: lua_pushinteger(L, n); break
        CASE(0); CASE(1); CASE(2); CASE(3); CASE(4); CASE(5);
        CASE(6); CASE(7); CASE(8); CASE(9); CASE(10); CASE(11);
        CASE(12); CASE(13); CASE(14); CASE(15); CASE(16); CASE(17);
        CASE(18); CASE(19); CASE(20); CASE(21); CASE(22); CASE(23);
        CASE(24); CASE(25); CASE(26); CASE(27); CASE(28); CASE(29);
        CASE(30); CASE(31);
#undef CASE
        default:
            luaL_error(L, UNEXPECTED_ERROR);
        }
    return 1;
    }

static int GetEnum(lua_State *L, GLenum pname, enum_t *e)
    {
    GLint val;
    glGetIntegerv(pname, &val);
    CheckError(L);
    return enumPush(L, val, e);
    }

static int GetEnum2(lua_State *L, GLenum pname, enum_t *e)
    {
    GLint val[2];
    glGetIntegerv(pname, val);
    CheckError(L);
    enumPush(L, val[0], e);
    enumPush(L, val[1], e);
    return 2;
    }

static int GetEnumN(lua_State *L, GLenum pname, GLenum numpname, enum_t *e)
    {
    GLint *val;
    GLsizei i, num = getSizei(L, numpname);
    if(num==0) return 0;
    val = (GLint*)Malloc(L, num*sizeof(GLint));
    glGetIntegerv(pname, val);
    CheckErrorFree(L, val);
    for(i = 0; i<num; i++)
        enumPush(L, val[i], e);
    Free(L, val);
    return num;
    }

static int GetEnumOptIndex(lua_State *L, GLenum pname, enum_t *e) /* index is optional */
    {
    GLint data;
    GLuint index;
    if(!lua_isnoneornil(L, 2))
        {
        index = luaL_checkinteger(L, 2);
        glGetIntegeri_v(pname, index, &data);
        }
    else
        glGetIntegerv(pname, &data);
    CheckError(L);
    return enumPush(L, data, e);
    }

static int GetBitfield(lua_State *L, GLenum pname, bitfield_t *b)
    {
    GLint val;
    glGetIntegerv(pname, &val);
    CheckError(L);
    return bitfieldPush(L, val, b);
    }

static int GetInt(lua_State *L, GLenum pname)
    {
    GLint64 data;
    glGetInteger64v(pname, &data);
    CheckError(L);
    lua_pushinteger(L, data);
    return 1;
    }

#if 0
static int GetInt2(lua_State *L, GLenum pname)
    {
    GLint64 data[2];
    glGetInteger64v(pname, data);
    CheckError(L);
    lua_pushinteger(L, data[0]);
    lua_pushinteger(L, data[1]);
    return 2;
    }

static int GetInt4(lua_State *L, GLenum pname)
    {
    GLint64 data[4];
    glGetInteger64v(pname, data);
    CheckError(L);
    lua_pushinteger(L, data[0]);
    lua_pushinteger(L, data[1]);
    lua_pushinteger(L, data[2]);
    lua_pushinteger(L, data[3]);
    return 4;
    }
#endif

static int GetIntN(lua_State *L, GLenum pname, GLenum numpname)
    {
    GLint64 *data;
    GLsizei i, num = getSizei(L, numpname);
    if(num==0) return 0;
    data = (GLint64*)Malloc(L, num*sizeof(GLint64));
    glGetInteger64v(pname, data);
    CheckErrorFree(L, data);
    for(i = 0; i<num; i++)
        lua_pushinteger(L, data[i]);
    Free(L, data);
    return num;
    }

static int GetIntOptIndex(lua_State *L, GLenum pname) /* index is optional */
    {
    GLint64 data;
    GLuint index;
    if(!lua_isnoneornil(L, 2))
        {
        index = luaL_checkinteger(L, 2);
        glGetInteger64i_v(pname, index, &data);
        }
    else
        glGetInteger64v(pname, &data);
    CheckError(L);
    lua_pushinteger(L, data);
    return 1;
    }

static int GetInt4OptIndex(lua_State *L, GLenum pname) /* index is optional */
    {
    GLint64 data[4];
    GLuint index;
    if(!lua_isnoneornil(L, 2))
        {
        index = luaL_checkinteger(L, 2);
        glGetInteger64i_v(pname, index, data);
        }
    else
        glGetInteger64v(pname, data);
    CheckError(L);
    lua_pushinteger(L, data[0]);
    lua_pushinteger(L, data[1]);
    lua_pushinteger(L, data[2]);
    lua_pushinteger(L, data[3]);
    return 4;
    }

static int GetIntIndex(lua_State *L, GLenum pname)
    {
    GLint64 data;
    GLuint index = luaL_checkinteger(L, 2);
    glGetInteger64i_v(pname, index, &data);
    CheckError(L);
    lua_pushinteger(L, data);
    return 1;
    }

static int GetBoolean(lua_State *L, GLenum pname)
    {
    GLboolean data;
    glGetBooleanv(pname, &data);
    CheckError(L);
    lua_pushboolean(L, (data == GL_TRUE));
    return 1;
    }

#if 0
static int GetBoolean4(lua_State *L, GLenum pname)
    {
    GLboolean data[4];
    glGetBooleanv(pname, data);
    CheckError(L);
    lua_pushboolean(L, (data[0] == GL_TRUE));
    lua_pushboolean(L, (data[1] == GL_TRUE));
    lua_pushboolean(L, (data[2] == GL_TRUE));
    lua_pushboolean(L, (data[3] == GL_TRUE));
    return 4;
    }

static int GetBooleanIndex(lua_State *L, GLenum pname)
    {
    GLboolean data;
    GLuint index;
    index = luaL_checkinteger(L, 2);
    glGetBooleani_v(pname, index, &data);
    CheckError(L);
    lua_pushboolean(L, data);
    return 1;
    }
#endif

static int GetBooleanOptIndex(lua_State *L, GLenum pname) /* index is optional */
    {
    GLboolean data;
    GLuint index;
    if(!lua_isnoneornil(L, 2))
        {
        index = luaL_checkinteger(L, 2);
        glGetBooleani_v(pname, index, &data);
        }
    else
        glGetBooleanv(pname, &data);
    CheckError(L);
    lua_pushboolean(L, data);
    return 1;
    }

static int GetBoolean4Index(lua_State *L, GLenum pname)
    {
    GLboolean data[4];
    GLuint index;
    index = luaL_checkinteger(L, 2);
    glGetBooleani_v(pname, index, data);
    CheckError(L);
    lua_pushboolean(L, data[0]);
    lua_pushboolean(L, data[1]);
    lua_pushboolean(L, data[2]);
    lua_pushboolean(L, data[3]);
    return 4;
    }

static int GetBoolean4OptIndex(lua_State *L, GLenum pname) /* index is optional */
    {
    GLboolean data[4];
    GLuint index;
    if(!lua_isnoneornil(L, 2))
        {
        index = luaL_checkinteger(L, 2);
        glGetBooleani_v(pname, index, data);
        }
    else
        glGetBooleanv(pname, data);
    CheckError(L);
    lua_pushboolean(L, data[0]);
    lua_pushboolean(L, data[1]);
    lua_pushboolean(L, data[2]);
    lua_pushboolean(L, data[3]);
    return 4;
    }



static int GetFloat(lua_State *L, GLenum pname)
    {
    GLfloat data;
    glGetFloatv(pname, &data);
    CheckError(L);
    lua_pushnumber(L, data);
    return 1;
    }

static int GetFloat2(lua_State *L, GLenum pname)
    {
    GLfloat data[2];
    glGetFloatv(pname, data);
    CheckError(L);
    lua_pushnumber(L, data[0]);
    lua_pushnumber(L, data[1]);
    return 2;
    }

static int GetFloat4(lua_State *L, GLenum pname)
    {
    GLfloat data[4];
    glGetFloatv(pname, data);
    CheckError(L);
    lua_pushnumber(L, data[0]);
    lua_pushnumber(L, data[1]);
    lua_pushnumber(L, data[2]);
    lua_pushnumber(L, data[3]);
    return 4;
    }

static int GetFloat4Index(lua_State *L, GLenum pname)
    {
    GLfloat data[4];
    GLuint index;
    index = luaL_checkinteger(L, 2);
    glGetFloati_v(pname, index, data);
    CheckError(L);
    lua_pushnumber(L, data[0]);
    lua_pushnumber(L, data[1]);
    lua_pushnumber(L, data[2]);
    lua_pushnumber(L, data[3]);
    return 4;
    }


static int GetFloat4OptIndex(lua_State *L, GLenum pname) /* index is optional */
    {
    GLfloat data[4];
    GLuint index;
    if(!lua_isnoneornil(L, 2))
        {
        index = luaL_checkinteger(L, 2);
        glGetFloati_v(pname, index, data);
        }
    else
        glGetFloatv(pname, data);
    CheckError(L);
    lua_pushnumber(L, data[0]);
    lua_pushnumber(L, data[1]);
    lua_pushnumber(L, data[2]);
    lua_pushnumber(L, data[3]);
    return 4;
    }


#if 0
void glGetBooleanv (GLenum pname, GLboolean *data);
void glGetDoublev (GLenum pname, GLdouble *data);
void glGetFloatv (GLenum pname, GLfloat *data);
void glGetIntegerv (GLenum pname, GLint *data);
void glGetInteger64v (GLenum pname, GLint64 *data);
void glGetBooleani_v(GLenum target, GLuint index, GLboolean *data);
void glGetIntegeri_v(GLenum target, GLuint index, GLint *data);
void glGetFloati_v(GLenum target, GLuint index, GLfloat *data);
void glGetDoublei_v(GLenum target, GLuint index, GLdouble *data);
void glGetInteger64i_v(GLenum target, GLuint index, GLint64 *data);
void glGetPointerv(GLenum pname, void **params);
#endif

static int Get(lua_State *L)
    {
    GLenum pname = CheckPname(L, 1);
    switch(pname)
        {
        case GL_CONTEXT_FLAGS: return GetBitfield(L, pname, &ContextFlagBitfield);
        case GL_MAJOR_VERSION: return GetInt(L, pname);
        case GL_MAX_SERVER_WAIT_TIMEOUT: return GetInt(L, pname);
        case GL_MIN_MAP_BUFFER_ALIGNMENT: return GetInt(L, pname);
        case GL_MINOR_VERSION: return GetInt(L, pname);
        case GL_NUM_EXTENSIONS: return GetInt(L, pname);
        case GL_NUM_SHADING_LANGUAGE_VERSIONS: return GetInt(L, pname);
        case GL_TIMESTAMP: return GetInt(L, pname);
        /* Buffer Binding State */
        case GL_ARRAY_BUFFER_BINDING: return GetInt(L, pname);
        case GL_COPY_READ_BUFFER_BINDING: return GetInt(L, pname);
        case GL_COPY_WRITE_BUFFER_BINDING: return GetInt(L, pname);
        case GL_DRAW_INDIRECT_BUFFER_BINDING: return GetInt(L, pname);
        case GL_ELEMENT_ARRAY_BUFFER_BINDING: return GetInt(L, pname);
        case GL_QUERY_BUFFER_BINDING: return GetInt(L, pname);
        case GL_TEXTURE_BUFFER_BINDING: return GetInt(L, pname);
        case GL_VERTEX_ARRAY_BINDING: return GetInt(L, pname);
        case GL_MAX_ATOMIC_COUNTER_BUFFER_BINDINGS: return GetInt(L, pname);
        case GL_ATOMIC_COUNTER_BUFFER_BINDING: return GetIntOptIndex(L, pname);
        case GL_ATOMIC_COUNTER_BUFFER_START: return GetIntOptIndex(L, pname);
        case GL_ATOMIC_COUNTER_BUFFER_SIZE: return GetIntOptIndex(L, pname);
        case GL_MAX_SHADER_STORAGE_BUFFER_BINDINGS: return GetInt(L, pname);
        case GL_SHADER_STORAGE_BUFFER_BINDING: return GetIntOptIndex(L, pname);
        case GL_SHADER_STORAGE_BUFFER_START: return GetIntIndex(L, pname);
        case GL_SHADER_STORAGE_BUFFER_SIZE: return GetIntIndex(L, pname);
    /*  case GL_MAX_TRANSFORM_FEEDBACK_BUFFER_BINDINGS: */
        case GL_MAX_TRANSFORM_FEEDBACK_BUFFERS: return GetInt(L, pname);
        case GL_TRANSFORM_FEEDBACK_BUFFER_BINDING: return GetIntOptIndex(L, pname);
        case GL_TRANSFORM_FEEDBACK_BUFFER_START: return GetIntIndex(L, pname);
        case GL_TRANSFORM_FEEDBACK_BUFFER_SIZE: return GetIntIndex(L, pname);
        case GL_MAX_UNIFORM_BUFFER_BINDINGS: return GetInt(L, pname);
        case GL_UNIFORM_BUFFER_BINDING: return GetIntOptIndex(L, pname);
        case GL_UNIFORM_BUFFER_START: return GetIntIndex(L, pname);
        case GL_UNIFORM_BUFFER_SIZE: return GetIntIndex(L, pname);
        case GL_MAX_TRANSFORM_FEEDBACK_INTERLEAVED_COMPONENTS: return GetInt(L, pname);
        case GL_MAX_TRANSFORM_FEEDBACK_SEPARATE_ATTRIBS: return GetInt(L, pname);
        case GL_MAX_TRANSFORM_FEEDBACK_SEPARATE_COMPONENTS: return GetInt(L, pname);
        case GL_TRANSFORM_FEEDBACK_PAUSED: return GetBoolean(L, pname);
        case GL_TRANSFORM_FEEDBACK_ACTIVE: return GetBoolean(L, pname);
        /* Debug Output State */
        case GL_DEBUG_GROUP_STACK_DEPTH: return GetInt(L, pname);
        case GL_DEBUG_LOGGED_MESSAGES: return GetInt(L, pname);
        case GL_DEBUG_NEXT_LOGGED_MESSAGE_LENGTH: return GetInt(L, pname);
        case GL_DEBUG_OUTPUT: return GetBoolean(L, pname);
        case GL_DEBUG_OUTPUT_SYNCHRONOUS: return GetBoolean(L, pname);
        case GL_MAX_DEBUG_LOGGED_MESSAGES: return GetInt(L, pname);
        case GL_MAX_DEBUG_MESSAGE_LENGTH: return GetInt(L, pname);
        case GL_MAX_DEBUG_GROUP_STACK_DEPTH: return GetInt(L, pname);
        case GL_MAX_LABEL_LENGTH: return GetInt(L, pname);
        /* Framebuffers */
        case GL_COLOR_CLEAR_VALUE: return GetFloat4(L, pname);
        case GL_COLOR_WRITEMASK: return GetBoolean4OptIndex(L, pname);
        case GL_DEPTH_CLEAR_VALUE: return GetFloat(L, pname);
        case GL_DEPTH_FUNC: return GetEnum(L, pname, enumStencilFunc());
        case GL_DEPTH_TEST: return GetBoolean(L, pname);
        case GL_DEPTH_WRITEMASK: return GetBoolean(L, pname);
        case GL_DOUBLEBUFFER: return GetBoolean(L, pname);
        case GL_DRAW_BUFFER:
        case GL_DRAW_BUFFER0:
        case GL_DRAW_BUFFER1:
        case GL_DRAW_BUFFER2:
        case GL_DRAW_BUFFER3:
        case GL_DRAW_BUFFER4:
        case GL_DRAW_BUFFER5:
        case GL_DRAW_BUFFER6:
        case GL_DRAW_BUFFER7:
        case GL_DRAW_BUFFER8:
        case GL_DRAW_BUFFER9:
        case GL_DRAW_BUFFER10:
        case GL_DRAW_BUFFER11:
        case GL_DRAW_BUFFER12:
        case GL_DRAW_BUFFER13:
        case GL_DRAW_BUFFER14:
        case GL_DRAW_BUFFER15: return GetEnum(L, pname, enumBuffer());
        case GL_DRAW_FRAMEBUFFER_BINDING: return GetInt(L, pname);
        case GL_MAX_COLOR_ATTACHMENTS: return GetInt(L, pname);
        case GL_MAX_COLOR_TEXTURE_SAMPLES: return GetInt(L, pname);
        case GL_MAX_DEPTH_TEXTURE_SAMPLES: return GetInt(L, pname);
        case GL_MAX_DRAW_BUFFERS: return GetInt(L, pname);
        case GL_MAX_DUAL_SOURCE_DRAW_BUFFERS: return GetInt(L, pname);
        case GL_MAX_FRAMEBUFFER_HEIGHT: return GetInt(L, pname);
        case GL_MAX_FRAMEBUFFER_LAYERS: return GetInt(L, pname);
        case GL_MAX_FRAMEBUFFER_SAMPLES: return GetInt(L, pname);
        case GL_MAX_FRAMEBUFFER_WIDTH: return GetInt(L, pname);
        case GL_MAX_INTEGER_SAMPLES: return GetInt(L, pname);
        case GL_MAX_SAMPLES: return GetInt(L, pname);
        case GL_READ_BUFFER: return GetEnum(L, pname, enumBuffer());
        case GL_READ_FRAMEBUFFER_BINDING: return GetInt(L, pname);
        case GL_RENDERBUFFER_BINDING: return GetInt(L, pname);
        case GL_STENCIL_BACK_FAIL: return GetEnum(L, pname, enumStencilOp());
        case GL_STENCIL_BACK_FUNC:  return GetEnum(L, pname, enumStencilFunc());
        case GL_STENCIL_BACK_PASS_DEPTH_FAIL:  return GetEnum(L, pname, enumStencilOp());
        case GL_STENCIL_BACK_PASS_DEPTH_PASS:  return GetEnum(L, pname, enumStencilOp());
        case GL_STENCIL_BACK_REF: return GetInt(L, pname);
        case GL_STENCIL_BACK_VALUE_MASK:  return GetInt(L, pname);
        case GL_STENCIL_BACK_WRITEMASK: return GetInt(L, pname);
        case GL_STENCIL_CLEAR_VALUE: return GetInt(L, pname);
        case GL_STENCIL_FAIL: return GetEnum(L, pname, enumStencilOp());
        case GL_STENCIL_FUNC: return GetEnum(L, pname, enumStencilFunc());
        case GL_STENCIL_PASS_DEPTH_FAIL:  return GetEnum(L, pname, enumStencilOp());
        case GL_STENCIL_PASS_DEPTH_PASS:  return GetEnum(L, pname, enumStencilOp());
        case GL_STENCIL_REF: return GetInt(L, pname);
        case GL_STENCIL_TEST: return GetBoolean(L, pname);
        case GL_STENCIL_VALUE_MASK: return GetInt(L, pname);
        case GL_STENCIL_WRITEMASK: return GetInt(L, pname);
        case GL_STEREO: return GetBoolean(L, pname);
        /* Hints */
        case GL_FRAGMENT_SHADER_DERIVATIVE_HINT: return GetEnum(L, pname, enumHintMode());
        case GL_LINE_SMOOTH_HINT: return GetEnum(L, pname, enumHintMode());
        case GL_POLYGON_SMOOTH_HINT:  return GetEnum(L, pname, enumHintMode());
        case GL_TEXTURE_COMPRESSION_HINT: return GetEnum(L, pname, enumHintMode());
        /* Image State */
        case GL_IMAGE_BINDING_ACCESS: return GetIntIndex(L, pname);
        case GL_IMAGE_BINDING_FORMAT: return GetIntIndex(L, pname);
        case GL_IMAGE_BINDING_NAME: return GetIntIndex(L, pname);
        case GL_IMAGE_BINDING_LAYER: return GetIntIndex(L, pname);
        case GL_IMAGE_BINDING_LAYERED: return GetIntIndex(L, pname);
        case GL_IMAGE_BINDING_LEVEL: return GetIntIndex(L, pname);
        /* Multisampling */
        case GL_MAX_SAMPLE_MASK_WORDS: return GetInt(L, pname);
        case GL_MULTISAMPLE: return GetBoolean(L, pname);
        case GL_SAMPLE_ALPHA_TO_COVERAGE: return GetBoolean(L, pname);
        case GL_SAMPLE_ALPHA_TO_ONE: return GetBoolean(L, pname);
        case GL_SAMPLE_BUFFERS: return GetInt(L, pname);
        case GL_SAMPLE_COVERAGE: return GetBoolean(L, pname);
        case GL_SAMPLE_COVERAGE_INVERT: return GetBoolean(L, pname);
        case GL_SAMPLE_COVERAGE_VALUE: return GetFloat(L, pname);
        case GL_SAMPLE_MASK: return GetBoolean(L, pname);
        case GL_SAMPLE_MASK_VALUE: return GetIntIndex(L, pname);
        case GL_SAMPLES: return GetInt(L, pname);
        /* Pixel Operations */
        case GL_BLEND: return GetBooleanOptIndex(L, pname);
        case GL_BLEND_COLOR: return GetFloat4OptIndex(L, pname);
        case GL_BLEND_DST_ALPHA: return GetEnum(L, pname, enumBlendFactor());
        case GL_BLEND_DST_RGB:  return GetEnumOptIndex(L, pname, enumBlendFactor());
        case GL_BLEND_EQUATION_RGB: return GetEnumOptIndex(L, pname, enumBlendMode());
        case GL_BLEND_EQUATION_ALPHA: return GetEnumOptIndex(L, pname, enumBlendMode());
        case GL_BLEND_SRC_ALPHA: return GetEnumOptIndex(L, pname, enumBlendFactor());
        case GL_BLEND_SRC_RGB: return GetEnumOptIndex(L, pname, enumBlendFactor());
        case GL_COLOR_LOGIC_OP: return GetBoolean(L, pname);
        case GL_DITHER: return GetBoolean(L, pname);
        case GL_LOGIC_OP_MODE: return GetEnum(L, pname, enumLogicOp());
        case GL_SCISSOR_BOX: return GetFloat4Index(L, pname);
        case GL_SCISSOR_TEST: return GetBoolean4Index(L, pname);
        /* Pixel Transfer Operations */
        case GL_CLAMP_READ_COLOR: return GetEnum(L, pname, enumClamp());
        case GL_IMPLEMENTATION_COLOR_READ_FORMAT: return GetEnum(L, pname, enumFormat());
        case GL_IMPLEMENTATION_COLOR_READ_TYPE: return GetEnum(L, pname, enumType());
        case GL_PACK_ALIGNMENT: return GetInt(L, pname);
        case GL_PACK_COMPRESSED_BLOCK_DEPTH: return GetInt(L, pname);
        case GL_PACK_COMPRESSED_BLOCK_HEIGHT: return GetInt(L, pname);
        case GL_PACK_COMPRESSED_BLOCK_SIZE: return GetInt(L, pname);
        case GL_PACK_COMPRESSED_BLOCK_WIDTH: return GetInt(L, pname);
        case GL_PACK_IMAGE_HEIGHT: return GetInt(L, pname);
        case GL_PACK_LSB_FIRST: return GetBoolean(L, pname);
        case GL_PACK_ROW_LENGTH: return GetInt(L, pname);
        case GL_PACK_SKIP_IMAGES: return GetInt(L, pname);
        case GL_PACK_SKIP_PIXELS: return GetInt(L, pname);
        case GL_PACK_SKIP_ROWS: return GetInt(L, pname);
        case GL_PACK_SWAP_BYTES: return GetBoolean(L, pname);
        case GL_PIXEL_PACK_BUFFER_BINDING: return GetInt(L, pname);
        case GL_PIXEL_UNPACK_BUFFER_BINDING: return GetInt(L, pname);
        case GL_UNPACK_ALIGNMENT: return GetInt(L, pname);
        case GL_UNPACK_COMPRESSED_BLOCK_DEPTH: return GetInt(L, pname);
        case GL_UNPACK_COMPRESSED_BLOCK_HEIGHT: return GetInt(L, pname);
        case GL_UNPACK_COMPRESSED_BLOCK_SIZE: return GetInt(L, pname);
        case GL_UNPACK_COMPRESSED_BLOCK_WIDTH: return GetInt(L, pname);
        case GL_UNPACK_IMAGE_HEIGHT: return GetInt(L, pname);
        case GL_UNPACK_LSB_FIRST: return GetBoolean(L, pname);
        case GL_UNPACK_ROW_LENGTH: return GetInt(L, pname);
        case GL_UNPACK_SKIP_IMAGES: return GetInt(L, pname);
        case GL_UNPACK_SKIP_PIXELS: return GetInt(L, pname);
        case GL_UNPACK_SKIP_ROWS: return GetInt(L, pname);
        case GL_UNPACK_SWAP_BYTES: return GetBoolean(L, pname);
        /* Programs */
        case GL_CURRENT_PROGRAM: return GetInt(L, pname);
        case GL_MAX_ATOMIC_COUNTER_BUFFER_SIZE: return GetInt(L, pname);
        case GL_MAX_COMBINED_SHADER_OUTPUT_RESOURCES: return GetInt(L, pname);
        case GL_MAX_COMBINED_SHADER_STORAGE_BLOCKS: return GetInt(L, pname);
        case GL_MAX_IMAGE_SAMPLES: return GetInt(L, pname);
        case GL_MAX_IMAGE_UNITS: return GetInt(L, pname);
        case GL_MAX_PROGRAM_TEXEL_OFFSET: return GetInt(L, pname);
        case GL_MAX_SHADER_STORAGE_BLOCK_SIZE: return GetInt(L, pname);
        case GL_MAX_SUBROUTINES: return GetInt(L, pname);
        case GL_MAX_SUBROUTINE_UNIFORM_LOCATIONS: return GetInt(L, pname);
        case GL_MAX_UNIFORM_BLOCK_SIZE: return GetInt(L, pname);
        case GL_MAX_UNIFORM_LOCATIONS: return GetInt(L, pname);
        case GL_MAX_VARYING_VECTORS: return GetInt(L, pname);
        case GL_MAX_VERTEX_ATTRIB_RELATIVE_OFFSET: return GetInt(L, pname);
        case GL_MAX_VERTEX_ATTRIB_BINDINGS: return GetInt(L, pname);
        case GL_MAX_VERTEX_ATTRIB_STRIDE: return GetInt(L, pname);
        case GL_MIN_PROGRAM_TEXEL_OFFSET: return GetInt(L, pname);
        case GL_NUM_PROGRAM_BINARY_FORMATS: return GetInt(L, pname);
        case GL_NUM_SHADER_BINARY_FORMATS: return GetInt(L, pname);
        case GL_PROGRAM_BINARY_FORMATS: return GetIntN(L, pname, GL_NUM_PROGRAM_BINARY_FORMATS);
        case GL_PROGRAM_PIPELINE_BINDING: return GetInt(L, pname);
        case GL_SHADER_BINARY_FORMATS: return GetIntN(L, pname, GL_NUM_SHADER_BINARY_FORMATS);
        case GL_SHADER_COMPILER: return GetBoolean(L, pname);
        case GL_SHADER_STORAGE_BUFFER_OFFSET_ALIGNMENT: return GetInt(L, pname);
        case GL_UNIFORM_BUFFER_OFFSET_ALIGNMENT: return GetInt(L, pname);
        /* Provoking Vertices */
        case GL_VIEWPORT_INDEX_PROVOKING_VERTEX:  return GetEnum(L, pname, enumProvokeMode());
        case GL_LAYER_PROVOKING_VERTEX: return GetEnum(L, pname, enumProvokeMode());
        case GL_PROVOKING_VERTEX: return GetEnum(L, pname, enumProvokeMode());
        /* Rasterization */
        case GL_ALIASED_LINE_WIDTH_RANGE: return GetFloat2(L, pname);
        case GL_CULL_FACE: return GetBoolean(L, pname);
        case GL_CULL_FACE_MODE: return GetEnum(L, pname, enumCullFaceMode()); 
        case GL_FRONT_FACE: return GetEnum(L, pname, enumFrontFaceMode()); 
        case GL_LINE_SMOOTH: return GetBoolean(L, pname);
        case GL_LINE_WIDTH: return GetFloat(L, pname);
        case GL_POINT_FADE_THRESHOLD_SIZE: return GetFloat(L, pname);
        case GL_POINT_SIZE: return GetFloat(L, pname);
        case GL_POINT_SIZE_GRANULARITY: return GetFloat(L, pname);
        case GL_POINT_SIZE_RANGE: return GetFloat2(L, pname);
        case GL_POINT_SPRITE_COORD_ORIGIN: return GetEnum(L, pname, enumOrigin());
        case GL_POLYGON_MODE: return GetEnum2(L, pname, enumPolygonModeMode()); 
        case GL_POLYGON_OFFSET_FACTOR: return GetFloat(L, pname);
        case GL_POLYGON_OFFSET_FILL: return GetBoolean(L, pname);
        case GL_POLYGON_OFFSET_LINE: return GetBoolean(L, pname);
        case GL_POLYGON_OFFSET_POINT: return GetBoolean(L, pname);
        case GL_POLYGON_OFFSET_UNITS: return GetFloat(L, pname);
        case GL_POLYGON_SMOOTH: return GetBoolean(L, pname);
        case GL_PROGRAM_POINT_SIZE: return GetBoolean(L, pname);
        case GL_RASTERIZER_DISCARD: return GetBoolean(L, pname);
        case GL_SMOOTH_LINE_WIDTH_RANGE: return GetFloat2(L, pname);
        case GL_SMOOTH_LINE_WIDTH_GRANULARITY: return GetFloat(L, pname);
        case GL_SUBPIXEL_BITS: return GetInt(L, pname);
        /* Shader Execution */
        case GL_FRAGMENT_INTERPOLATION_OFFSET_BITS: return GetInt(L, pname);
        case GL_MAX_FRAGMENT_INTERPOLATION_OFFSET: return GetFloat(L, pname);
        case GL_MIN_FRAGMENT_INTERPOLATION_OFFSET: return GetFloat(L, pname);
        /* Shaders */
        case GL_MAX_COMBINED_ATOMIC_COUNTER_BUFFERS:
        case GL_MAX_COMPUTE_ATOMIC_COUNTER_BUFFERS:
        case GL_MAX_FRAGMENT_ATOMIC_COUNTER_BUFFERS:
        case GL_MAX_GEOMETRY_ATOMIC_COUNTER_BUFFERS:
        case GL_MAX_TESS_CONTROL_ATOMIC_COUNTER_BUFFERS:
        case GL_MAX_TESS_EVALUATION_ATOMIC_COUNTER_BUFFERS:
        case GL_MAX_VERTEX_ATOMIC_COUNTER_BUFFERS:
        case GL_MAX_COMBINED_ATOMIC_COUNTERS:
        case GL_MAX_COMPUTE_ATOMIC_COUNTERS:
        case GL_MAX_FRAGMENT_ATOMIC_COUNTERS:
        case GL_MAX_GEOMETRY_ATOMIC_COUNTERS:
        case GL_MAX_TESS_CONTROL_ATOMIC_COUNTERS:
        case GL_MAX_TESS_EVALUATION_ATOMIC_COUNTERS:
        case GL_MAX_VERTEX_ATOMIC_COUNTERS:
        case GL_MAX_COMBINED_COMPUTE_UNIFORM_COMPONENTS:
        case GL_MAX_COMBINED_FRAGMENT_UNIFORM_COMPONENTS:
        case GL_MAX_COMBINED_GEOMETRY_UNIFORM_COMPONENTS:
        case GL_MAX_COMBINED_TESS_CONTROL_UNIFORM_COMPONENTS:
        case GL_MAX_COMBINED_TESS_EVALUATION_UNIFORM_COMPONENTS:
        case GL_MAX_COMBINED_VERTEX_UNIFORM_COMPONENTS:
        case GL_MAX_COMBINED_IMAGE_UNIFORMS:
        case GL_MAX_COMPUTE_IMAGE_UNIFORMS:
        case GL_MAX_FRAGMENT_IMAGE_UNIFORMS:
        case GL_MAX_GEOMETRY_IMAGE_UNIFORMS:
        case GL_MAX_TESS_CONTROL_IMAGE_UNIFORMS:
        case GL_MAX_TESS_EVALUATION_IMAGE_UNIFORMS:
        case GL_MAX_VERTEX_IMAGE_UNIFORMS:
        case GL_MAX_COMPUTE_SHADER_STORAGE_BLOCKS:
        case GL_MAX_FRAGMENT_SHADER_STORAGE_BLOCKS:
        case GL_MAX_GEOMETRY_SHADER_STORAGE_BLOCKS:
        case GL_MAX_TESS_CONTROL_SHADER_STORAGE_BLOCKS:
        case GL_MAX_TESS_EVALUATION_SHADER_STORAGE_BLOCKS:
        case GL_MAX_VERTEX_SHADER_STORAGE_BLOCKS:
        case GL_MAX_COMPUTE_UNIFORM_COMPONENTS:
        case GL_MAX_FRAGMENT_UNIFORM_COMPONENTS:
        case GL_MAX_GEOMETRY_UNIFORM_COMPONENTS:
        case GL_MAX_TESS_CONTROL_UNIFORM_COMPONENTS:
        case GL_MAX_TESS_EVALUATION_UNIFORM_COMPONENTS:
        case GL_MAX_VERTEX_UNIFORM_COMPONENTS:
        case GL_MAX_TEXTURE_IMAGE_UNITS:
        case GL_MAX_COMBINED_TEXTURE_IMAGE_UNITS:
        case GL_MAX_COMPUTE_TEXTURE_IMAGE_UNITS:
        case GL_MAX_GEOMETRY_TEXTURE_IMAGE_UNITS:
        case GL_MAX_TESS_CONTROL_TEXTURE_IMAGE_UNITS:
        case GL_MAX_TESS_EVALUATION_TEXTURE_IMAGE_UNITS:
        case GL_MAX_VERTEX_TEXTURE_IMAGE_UNITS:
        case GL_MAX_COMBINED_UNIFORM_BLOCKS:
        case GL_MAX_COMPUTE_UNIFORM_BLOCKS:
        case GL_MAX_FRAGMENT_UNIFORM_BLOCKS:
        case GL_MAX_GEOMETRY_UNIFORM_BLOCKS:
        case GL_MAX_TESS_CONTROL_UNIFORM_BLOCKS:
        case GL_MAX_TESS_EVALUATION_UNIFORM_BLOCKS:
        case GL_MAX_VERTEX_UNIFORM_BLOCKS: return GetInt(L, pname);
        /* Compute Shaders */
        case GL_DISPATCH_INDIRECT_BUFFER_BINDING: return GetInt(L, pname);
        case GL_MAX_COMPUTE_SHARED_MEMORY_SIZE: return GetInt(L, pname);
        case GL_MAX_COMPUTE_WORK_GROUP_INVOCATIONS: return GetInt(L, pname);
        case GL_MAX_COMPUTE_WORK_GROUP_COUNT: return GetIntIndex(L, pname);
        case GL_MAX_COMPUTE_WORK_GROUP_SIZE: return GetIntIndex(L, pname);
        /* Fragment Shaders */
        case GL_MAX_FRAGMENT_INPUT_COMPONENTS: return GetInt(L, pname);
        case GL_MAX_FRAGMENT_UNIFORM_VECTORS: return GetInt(L, pname);
        case GL_MAX_PROGRAM_TEXTURE_GATHER_OFFSET: return GetInt(L, pname);
        case GL_MIN_PROGRAM_TEXTURE_GATHER_OFFSET: return GetInt(L, pname);
        /* Geometry Shaders */
        case GL_MAX_GEOMETRY_INPUT_COMPONENTS: return GetInt(L, pname);
        case GL_MAX_GEOMETRY_OUTPUT_COMPONENTS: return GetInt(L, pname);
        case GL_MAX_GEOMETRY_OUTPUT_VERTICES: return GetInt(L, pname);
        case GL_MAX_GEOMETRY_SHADER_INVOCATIONS: return GetInt(L, pname);
        case GL_MAX_GEOMETRY_TOTAL_OUTPUT_COMPONENTS: return GetInt(L, pname);
        case GL_MAX_VERTEX_STREAMS: return GetInt(L, pname);
        /* Tessellation Control Shaders */
        case GL_MAX_PATCH_VERTICES: return GetInt(L, pname);
        case GL_MAX_TESS_CONTROL_INPUT_COMPONENTS: return GetInt(L, pname);
        case GL_MAX_TESS_CONTROL_OUTPUT_COMPONENTS: return GetInt(L, pname);
        case GL_MAX_TESS_CONTROL_TOTAL_OUTPUT_COMPONENTS: return GetInt(L, pname);
        case GL_MAX_TESS_GEN_LEVEL: return GetInt(L, pname);
        case GL_MAX_TESS_PATCH_COMPONENTS: return GetInt(L, pname);
        case GL_PATCH_DEFAULT_INNER_LEVEL: return GetFloat2(L, pname);
        case GL_PATCH_DEFAULT_OUTER_LEVEL: return GetFloat4(L, pname);
        case GL_PATCH_VERTICES: return GetInt(L, pname);
        /* Tessellation Evaluation Shaders */
        case GL_MAX_TESS_EVALUATION_INPUT_COMPONENTS: return GetInt(L, pname);
        case GL_MAX_TESS_EVALUATION_OUTPUT_COMPONENTS: return GetInt(L, pname);
        /* Vertex Shaders */
        case GL_MAX_VERTEX_ATTRIBS: return GetInt(L, pname);
        case GL_MAX_VERTEX_OUTPUT_COMPONENTS: return GetInt(L, pname);
        case GL_MAX_VERTEX_UNIFORM_VECTORS: return GetInt(L, pname);
        /* Textures */
        case GL_ACTIVE_TEXTURE: return GetActiveTexture(L, pname); 
        case GL_COMPRESSED_TEXTURE_FORMATS:
                return GetEnumN(L, pname, GL_NUM_COMPRESSED_TEXTURE_FORMATS, enumInternalFormat());
        case GL_MAX_3D_TEXTURE_SIZE: return GetInt(L, pname);
        case GL_MAX_ARRAY_TEXTURE_LAYERS: return GetInt(L, pname);
        case GL_MAX_CUBE_MAP_TEXTURE_SIZE: return GetInt(L, pname);
        case GL_MAX_RECTANGLE_TEXTURE_SIZE: return GetInt(L, pname);
        case GL_MAX_RENDERBUFFER_SIZE: return GetInt(L, pname);
        case GL_MAX_TEXTURE_BUFFER_SIZE: return GetInt(L, pname);
        case GL_MAX_TEXTURE_LOD_BIAS: return GetFloat(L, pname);
        case GL_MAX_TEXTURE_SIZE: return GetInt(L, pname);
        case GL_NUM_COMPRESSED_TEXTURE_FORMATS: return GetInt(L, pname);
        case GL_SAMPLER_BINDING: return GetInt(L, pname);
        case GL_TEXTURE_BINDING_1D: return GetInt(L, pname);
        case GL_TEXTURE_BINDING_1D_ARRAY: return GetInt(L, pname);
        case GL_TEXTURE_BINDING_2D: return GetInt(L, pname);
        case GL_TEXTURE_BINDING_2D_ARRAY: return GetInt(L, pname);
        case GL_TEXTURE_BINDING_2D_MULTISAMPLE: return GetInt(L, pname);
        case GL_TEXTURE_BINDING_2D_MULTISAMPLE_ARRAY: return GetInt(L, pname);
        case GL_TEXTURE_BINDING_3D: return GetInt(L, pname);
        case GL_TEXTURE_BINDING_BUFFER: return GetInt(L, pname);
        case GL_TEXTURE_BINDING_CUBE_MAP: return GetInt(L, pname);
        case GL_TEXTURE_BINDING_RECTANGLE: return GetInt(L, pname);
        case GL_TEXTURE_BUFFER_OFFSET_ALIGNMENT: return GetInt(L, pname);
        case GL_TEXTURE_CUBE_MAP_SEAMLESS: return GetBoolean(L, pname);
        /* Transformation State */
        case GL_CLIP_DISTANCE0:
        case GL_CLIP_DISTANCE1:
        case GL_CLIP_DISTANCE2:
        case GL_CLIP_DISTANCE3:
        case GL_CLIP_DISTANCE4:
        case GL_CLIP_DISTANCE5:
        case GL_CLIP_DISTANCE6:
        case GL_CLIP_DISTANCE7: return GetBoolean(L, pname);
        case GL_DEPTH_CLAMP: return GetBoolean(L, pname);
        case GL_DEPTH_RANGE: return GetFloat2(L, pname);
        case GL_MAX_CLIP_DISTANCES: return GetInt(L, pname);
        case GL_MAX_VIEWPORT_DIMS: return GetFloat2(L, pname);
        case GL_MAX_VIEWPORTS: return GetInt(L, pname);
        case GL_TRANSFORM_FEEDBACK_BINDING: return GetInt(L, pname);
        case GL_VIEWPORT: return GetInt4OptIndex(L, pname);
        case GL_VIEWPORT_BOUNDS_RANGE: return GetFloat2(L, pname);
        case GL_VIEWPORT_SUBPIXEL_BITS: return GetInt(L, pname);
        /* Vertex Arrays */
        case GL_MAX_ELEMENT_INDEX: return GetInt(L, pname);
        case GL_MAX_ELEMENTS_INDICES: return GetInt(L, pname);
        case GL_MAX_ELEMENTS_VERTICES: return GetInt(L, pname);
        case GL_PRIMITIVE_RESTART: return GetBoolean(L, pname);
        case GL_PRIMITIVE_RESTART_FIXED_INDEX:  return GetBoolean(L, pname);
        case GL_PRIMITIVE_RESTART_FOR_PATCHES_SUPPORTED:  return GetBoolean(L, pname);
        case GL_PRIMITIVE_RESTART_INDEX: return GetInt(L, pname);
        case GL_VERTEX_BINDING_DIVISOR: return GetIntIndex(L, pname);
        case GL_VERTEX_BINDING_OFFSET: return GetIntIndex(L, pname);
        case GL_VERTEX_BINDING_STRIDE: return GetIntIndex(L, pname);
//      case GL_MAX_VARYING_COMPONENTS = GL_MAX_VARYING_FLOATS
        case GL_MAX_VARYING_FLOATS: return GetInt(L, pname);
        case GL_RESET_NOTIFICATION_STRATEGY: return GetEnum(L, pname, &RNStrategyEnum);
        default:
            luaL_error(L, UNEXPECTED_ERROR);
        }
    return 0;
    }


static int GetGraphicsResetStatus(lua_State *L)
    {
    GLenum status = glGetGraphicsResetStatus();
    PushGRStatus(L, status);
    return 1;
    }

/*------------------------------------------------------------------------------*
 | Registration                                                                 |
 *------------------------------------------------------------------------------*/

static const struct luaL_Reg Functions[] = 
    {
        { "get", Get },
        { "get_graphics_reset_status", GetGraphicsResetStatus },
        { NULL, NULL } /* sentinel */
    };

void moongl_open_get(lua_State *L)
    {
    enumAssert(L, &PnameEnum, GL_VERTEX_BINDING_STRIDE, "vertex binding stride");
    luaL_setfuncs(L, Functions, 0);
    }



