package main

import "core:math/linalg"
import "core:mem"
import "core:math"
import "core:fmt"
import "core:sys/windows"
import "core:os"
import sdl "vendor:sdl3"

// Nvidia NRI
import nri "../../"

NRI_ABORT_ON_FAILURE :: proc(result: nri.Result, location := #caller_location) {
    if result != .SUCCESS {
        fmt.eprintfln("NRI failure: %v at %s:%d", result, location.file_path, location.line)
        nri.DestroyDevice(device)
        os.exit(-1)
    }
}

NRI_Interface :: struct {
    using core     : nri.CoreInterface,
    using swapchain: nri.SwapChainInterface,
    using helper   : nri.HelperInterface,
}

SwapChainTexture :: struct {
    texture          : ^nri.Texture,
    color_attachment : ^nri.Descriptor,
    acquire_semaphore: ^nri.Fence,
    release_semaphore: ^nri.Fence,
};

Frame :: struct {
    command_allocator             : ^nri.CommandAllocator,
    command_buffer                : ^nri.CommandBuffer,
}

graphics_api :: nri.GraphicsAPI.VK
window : ^sdl.Window
window_height : i32 = 768
window_width  : i32 = 1024
queued_frame_num :: 2

device : ^nri.Device

frag_bytecode :: #load("shaders/triangle.frag.spv")
vert_bytecode :: #load("shaders/triangle.vert.spv")

CubeVertex :: struct{
    position: [3]f32,
    color   : [3]f32,
}

cube_vertices := [?]CubeVertex{
    {{-1.0, -1.0, -1.0}, {1.0, 0.0, 0.0}},
    {{ 1.0, -1.0, -1.0}, {0.0, 1.0, 0.0}},
    {{ 1.0,  1.0, -1.0}, {0.0, 0.0, 1.0}},
    {{-1.0,  1.0, -1.0}, {1.0, 1.0, 0.0}},

    {{-1.0, -1.0,  1.0}, {1.0, 0.0, 1.0}},
    {{ 1.0, -1.0,  1.0}, {0.0, 1.0, 1.0}},
    {{ 1.0,  1.0,  1.0}, {1.0, 1.0, 1.0}},
    {{-1.0,  1.0,  1.0}, {0.2, 0.2, 0.2}},
};

CubeIndex :: u16
CubeIndexType :: nri.IndexType.UINT16
cube_indices := [?]CubeIndex{
    // front
    4, 5, 6,
    4, 6, 7,

    // back
    1, 0, 3,
    1, 3, 2,

    // left
    0, 4, 7,
    0, 7, 3,

    // right
    5, 1, 2,
    5, 2, 6,

    // top
    3, 7, 6,
    3, 6, 2,

    // bottom
    0, 1, 5,
    0, 5, 4,
}
cube_index_count :: size_of(cube_indices) / size_of(cube_indices[0])



main :: proc() {
    sdl.SetMainReady()

    // Init SDL and create window
    ok := sdl.Init({.AUDIO, .VIDEO}); sdl_assert(ok) 
    defer sdl.Quit()

    when graphics_api == .VK{
        window = sdl.CreateWindow("Hello World!", window_width, window_height, {.VULKAN}); sdl_assert(window != nil)
    } else {
        window = sdl.CreateWindow("Hello World!", window_width, window_height, {}); sdl_assert(window != nil)
    }
	defer sdl.DestroyWindow(window)

    // -------- Init NRI ---------

	adapters_num : u32 = 1 // This should choose the best adapter (graphics card)
	adapter_desc : nri.AdapterDesc // Getting multiple adapters with [^]nri.AdapterDesc is buggy
	NRI_ABORT_ON_FAILURE(nri.EnumerateAdapters(&adapter_desc, &adapters_num))
    // fmt.printfln("Adapter: %v", adapter_desc)

    callback_interface := nri.CallbackInterface {
        MessageCallback = nri_message_callback,
        AbortExecution  = nri_abort_callback,
    }
    device_creation_desc := nri.DeviceCreationDesc{
        graphicsAPI                      = graphics_api,
        // robustness                       = Robustness,
        adapterDesc                      = &adapter_desc,
        callbackInterface                = callback_interface,
        // allocationCallbacks              = AllocationCallbacks,
        // queueFamilies                    = ^QueueFamilyDesc,
        // queueFamilyNum                   = u32,
        // d3dShaderExtRegister             = u32,
        // d3dZeroBufferSize                = u32,
        // vkBindingOffsets                 = VKBindingOffsets,
        // vkExtensions                     = VKExtensions,
        enableNRIValidation              = true,
        enableGraphicsAPIValidation      = true,
        // enableD3D11CommandBufferEmulation= bool,
        // enableD3D12RayTracingValidation  = bool,
        // enableMemoryZeroInitialization   = bool,
        // disableVKRayTracing              = bool,
        // disableD3D12EnhancedBarriers     = bool,
    }
    if nri.CreateDevice(&device_creation_desc, &device) != .SUCCESS {
        fmt.printfln("Failed to init nri device")
        os.exit(-1)
    }
    
    NRI: NRI_Interface
    NRI_ABORT_ON_FAILURE(nri.GetInterface(device, "NriCoreInterface", size_of(NRI.core), &NRI.core))
    NRI_ABORT_ON_FAILURE(nri.GetInterface(device, "NriSwapChainInterface", size_of(NRI.swapchain), &NRI.swapchain))
    NRI_ABORT_ON_FAILURE(nri.GetInterface(device, "NriHelperInterface", size_of(NRI.helper), &NRI.helper))

    command_queue : ^nri.Queue
    NRI_ABORT_ON_FAILURE(NRI.GetQueue(device, .GRAPHICS, 0, &command_queue))
    
    pipeline_layout : ^nri.PipelineLayout
    { // Pipeline layout
        pipeline_layout_desc := nri.PipelineLayoutDesc{
            shaderStages     = {.VERTEX_SHADER, .FRAGMENT_SHADER},
        }

        NRI_ABORT_ON_FAILURE(NRI.CreatePipelineLayout(device, &pipeline_layout_desc, &pipeline_layout))
    }


    swapchain : ^nri.SwapChain
    swapchain_format : nri.Format
    swapchain_texture_num: u32
    swapchain_textures : [queued_frame_num + 1]SwapChainTexture

    { // Create swapchain
        when ODIN_OS == .Windows {
            window_handle := sdl.GetPointerProperty(sdl.GetWindowProperties(window), sdl.PROP_WINDOW_WIN32_HWND_POINTER, nil)
            fmt.printfln("props %v", sdl.GetWindowProperties(window))
            fmt.printfln("props %v", window_handle)
        } else {
            fmt.printfln("Unsupported OS: %s", ODIN_OS)
            return
        }
        nri_swapchain_desc := nri.SwapChainDesc{
            window        = {
                windows = nri.WindowsWindow{window_handle},
                // x11     = nri.X11Window,
                // wayland = nri.WaylandWindow,
                // metal   = nri.MetalWindow,
            },
            queue         = command_queue,
            width         = nri.Dim_t(window_width),
            height        = nri.Dim_t(window_height),
            textureNum    = queued_frame_num + 1, // framebuffers
            format        = .BT709_G22_8BIT,
            flags         = {
                .VSYNC,
                // .WAITABLE,
                // .ALLOW_TEARING,
                // .ALLOW_LOW_LATENCY,
            },
            queuedFrameNum= queued_frame_num,
            // scaling       = .STRETCH,
            // gravityX      = Gravity,
            // gravityY      = Gravity,
        }
        NRI_ABORT_ON_FAILURE(NRI.CreateSwapChain(device, &nri_swapchain_desc, &swapchain))


        { // Create swapchain textures
            textures := NRI.GetSwapChainTextures(swapchain, &swapchain_texture_num)
            if textures == nil || swapchain_texture_num == 0 {
                fmt.printfln("Swap chain returned no textures\n")
            }
            
            fmt.printfln("Swapchain texture num: %v", swapchain_texture_num)
            fmt.printfln("Swapchain texture num: %v", queued_frame_num + 1)
            
            swapchain_format = NRI.GetTextureDesc(textures[0]).format
            
            for i:u32=0; i<swapchain_texture_num; i+=1 {
                texture_view_desc := nri.TextureViewDesc{
                    texture= textures[i],
                    type   = .COLOR_ATTACHMENT,
                    format = swapchain_format,
                }

                color_attachment : ^nri.Descriptor
                NRI_ABORT_ON_FAILURE(NRI.CreateTextureView(&texture_view_desc, &color_attachment))

                SWAPCHAIN_SEMAPHORE :: ~u64(0)

                acquire_semaphore : ^nri.Fence
                NRI_ABORT_ON_FAILURE(NRI.CreateFence(device, SWAPCHAIN_SEMAPHORE, &acquire_semaphore))

                release_semaphore : ^nri.Fence
                NRI_ABORT_ON_FAILURE(NRI.CreateFence(device, SWAPCHAIN_SEMAPHORE, &release_semaphore))

                swapchain_texture := SwapChainTexture{
                    acquire_semaphore = acquire_semaphore,
                    release_semaphore = release_semaphore,
                    texture           = textures[i],
                    color_attachment  = color_attachment,
                }

                swapchain_textures[i] = swapchain_texture
            }
        }
    }
    
    pipeline : ^nri.Pipeline
    { // Pipeline
        Vertex := nri.ShaderDesc{
            stage         = {.VERTEX_SHADER},
            bytecode      = raw_data(vert_bytecode),
            size          = u64(len(vert_bytecode)),
            entryPointName= "main",
        }
        
        Fragment := nri.ShaderDesc{
            stage         = {.FRAGMENT_SHADER},
            bytecode      = raw_data(frag_bytecode),
            size          = u64(len(frag_bytecode)),
            entryPointName= "main",
        }

        shader_stages := []nri.ShaderDesc{
            Fragment,
            Vertex,
        }

        input_assembly_desc := nri.InputAssemblyDesc{
	        topology           = .TRIANGLE_LIST,
        }

        rasterization_desc := nri.RasterizationDesc{
            // depthBias            = DepthBiasDesc,
            fillMode             = .SOLID,
            cullMode             = .NONE,
            // frontCounterClockwise= bool,
            // depthClamp           = bool,
            // lineSmoothing        = bool,            // requires "features.lineSmoothing"
            // conservativeRaster   = bool,            // requires "tiers.conservativeRaster != 0"
            // shadingRate          = bool,            // requires "tiers.shadingRate != 0", expects "CmdSetShadingRate" and optionally "AttachmentsDesc::shadingRate"
        }

        color_attachment_desc := nri.ColorAttachmentDesc{
            format        = swapchain_format,
            // colorBlend    = {
            //     srcFactor= .ONE,
            //     dstFactor= .ZERO,
            //     op       = .ADD,
            // },
            // alphaBlend    = {
            //     srcFactor= .ONE,
            //     dstFactor= .ZERO,
            //     op       = .ADD,
            // },
            colorWriteMask= nri.COLORWRITEBITS_RGBA,
            // blendEnabled  = false,
        }

        output_merger_desc := nri.OutputMergerDesc{
            colors            = &color_attachment_desc,
            colorNum          = 1,
            depth             = {
                compareOp = .LESS,
                write     = true,
            },
            // stencil           = StencilAttachmentDesc,
            depthStencilFormat= .D32_SFLOAT,
            // logicOp           = LogicOp,                  // requires "features.logicOp"
            // viewMask          = u32,                      // if non-0, requires "viewMaxNum > 1"
	        // multiview         = Multiview,                // if "viewMask != 0", requires "features.(xxx)Multiview"
        }

        vertex_stream_desc := []nri.VertexStreamDesc{
            {
                bindingSlot= 0,
                // stepRate   = .PER_VERTEX,
            }
        }
        vertex_attribute_descs : []nri.VertexAttributeDesc = {
            {
                d3d        = {"POSITION", 0},
                vk         = { location = 0 },
                offset     = u32(offset_of(CubeVertex, position)),
                format     = .RGB32_SFLOAT,
                streamIndex= 0,
            },
            {
                d3d        = {"COLOR", 0},
                vk         = { location = 1 },
                offset     = u32(offset_of(CubeVertex, color)),
                format     = .RGB32_SFLOAT,
                streamIndex= 0,
            },
        }

        vertex_input_desc := nri.VertexInputDesc{
            attributes  = raw_data(vertex_attribute_descs),
            attributeNum= u8(len(vertex_attribute_descs)),
            streams     = raw_data(vertex_stream_desc),
            streamNum   = u8(len(vertex_stream_desc)),
        }

        graphics_pipeline_desc := nri.GraphicsPipelineDesc{
            pipelineLayout= pipeline_layout,
            vertexInput   = &vertex_input_desc,
            inputAssembly = input_assembly_desc,
            rasterization = rasterization_desc,
            // multisample   = ^MultisampleDesc,
            outputMerger  = output_merger_desc,
            shaders       = raw_data(shader_stages),
            shaderNum     = u32(len(shader_stages)),
            // robustness    = Robustness,
        }

        fmt.printfln("v", graphics_pipeline_desc.pipelineLayout)

        fmt.printfln("Creating graphics pipeline...")
        NRI_ABORT_ON_FAILURE(NRI.CreateGraphicsPipeline(device, &graphics_pipeline_desc, &pipeline))
        fmt.printfln("Graphics pipeline created.")
    }

    vertex_buffer : ^nri.Buffer
    index_buffer : ^nri.Buffer
    { // Create and upload buffers
        NRI_ABORT_ON_FAILURE(NRI.CreateCommittedBuffer(
            device, 
            .DEVICE, 
            0.5, 
            &{
                size           = size_of(cube_vertices),
                structureStride= size_of(CubeVertex),
                usage          = {.VERTEX_BUFFER},
            }, 
            &vertex_buffer
        ))
    
        // // Copy data into vertex_buffer (CPU side)
        // mem.copy(
        //     dst = NRI.MapBuffer(vertex_buffer, 0, size_of(cube_vertices)), 
        //     src = &cube_vertices, 
        //     len = size_of(cube_vertices)
        // )
    
        // NRI.UnmapBuffer(vertex_buffer)
    
        NRI_ABORT_ON_FAILURE(NRI.CreateCommittedBuffer(
            device, 
            .DEVICE, 
            0.5, 
            &{
                size           = size_of(cube_indices),
                structureStride= size_of(CubeIndex),
                usage          = {.INDEX_BUFFER},
            }, 
            &index_buffer
        ))
    
        // // Copy data into index_buffer (CPU side)
        // mem.copy(
        //     dst = NRI.MapBuffer(index_buffer, 0, size_of(cube_indices)), 
        //     src = &cube_indices, 
        //     len = size_of(cube_indices)
        // )
    
        // NRI.UnmapBuffer(index_buffer)


        uploads := []nri.BufferUploadDesc{
            {
                data  = &cube_vertices,        // if provided, must be data for the whole buffer
                buffer= vertex_buffer,
                after = {
                    access = {.VERTEX_BUFFER}
                },
            },
            {
                data  = &cube_indices,        // if provided, must be data for the whole buffer
                buffer= index_buffer,
                after = {
                    access = {.INDEX_BUFFER}
                },
            },
        }

        NRI_ABORT_ON_FAILURE(NRI.UploadData(
            command_queue,
            nil,
            0,
            raw_data(uploads),
            u32(len(uploads)),
        ))

    }
    
    depth_texture : ^nri.Texture
    depth_attachment : ^nri.Descriptor
    { // Add a depth texture
        NRI_ABORT_ON_FAILURE(NRI.CreateCommittedTexture(
            device,
            .DEVICE,
            0.5,
            &{
                type               = .TEXTURE_2D,
                usage              = {.DEPTH_STENCIL_ATTACHMENT},
                format             = .D32_SFLOAT,
                width              = u16(window_width),
                height             = u16(window_height),
                // depth              = Dim_t,
                mipNum             = 1,
                layerNum           = 1,
                sampleNum          = 1,
                // sharingMode        = SharingMode,
                // optimizedClearValue= ClearValue,         // D3D12: not needed on desktop, since any HW can track many clear values
            },
            &depth_texture,
        ))

        NRI_ABORT_ON_FAILURE(NRI.CreateTextureView(
            &{
                texture       = depth_texture,
                type          = .DEPTH_STENCIL_ATTACHMENT,
                format        = .D32_SFLOAT,
                // mipOffset     = Dim_t,
                // mipNum        = Dim_t,              // can be "REMAINING"
                // layerOffset   = Dim_t,
                // layerNum      = Dim_t,              // can be "REMAINING"
                // sliceOffset   = Dim_t,
                // sliceNum      = Dim_t,              // can be "REMAINING"
                // readonlyPlanes= {.DEPTH},          // "DEPTH" and/or "STENCIL"
                // components    = ComponentMapping,
            },
            &depth_attachment
        ))
    }







    frames : [queued_frame_num]Frame 
    for &frame in frames[:] {
        NRI_ABORT_ON_FAILURE(NRI.CreateCommandAllocator(command_queue, &frame.command_allocator))
        NRI_ABORT_ON_FAILURE(NRI.CreateCommandBuffer(frame.command_allocator, &frame.command_buffer))
    }
    
    frame_fence : ^nri.Fence
    NRI_ABORT_ON_FAILURE(NRI.CreateFence(device, 0, &frame_fence))
    

    frame_index : u64 = 0
    game_loop: for {
        { // Handle keyboard and mouse input
			e: sdl.Event
			for sdl.PollEvent(&e) {
				#partial switch e.type {
                    case .QUIT:
                        break game_loop
                        
					case .KEY_DOWN: // holding .KEY_DOWN has a delay then repeats downs, designed for writing text
						#partial switch e.key.scancode {
						case .ESCAPE:
							break game_loop
					}
                }
            }
		}

        // wait for in-flight frame (CPU waits for GPU)
        if frame_index >= queued_frame_num {
            NRI.Wait(frame_fence, 1 + frame_index - queued_frame_num)
        }
        queued_frame_index := frame_index % queued_frame_num
        queued_frame := frames[queued_frame_index]
        NRI.ResetCommandAllocator(queued_frame.command_allocator)



        // Acquire swapchain texture
        recycled_semaphore_index := u32(frame_index) % swapchain_texture_num
        swapchain_acquire_semaphore := swapchain_textures[recycled_semaphore_index].acquire_semaphore
        current_swapchain_texture_index : u32 = 0
        NRI_ABORT_ON_FAILURE(NRI.AcquireNextTexture(swapchain, swapchain_acquire_semaphore, &current_swapchain_texture_index))

        swapchain_texture := swapchain_textures[current_swapchain_texture_index]

        command_buffer := queued_frame.command_buffer
        
        NRI_ABORT_ON_FAILURE(NRI.BeginCommandBuffer(command_buffer, nil))
        {
            texture_barriers := []nri.TextureBarrierDesc{
                { // Swapchain texture
                    texture    = swapchain_texture.texture,
                    before     = {
                        access = {},
                        layout = .UNDEFINED,
                        stages = nri.STAGEBITS_NONE,
                    },
                    after      = {
                        access = nri.ACCESSBITS_COLOR_ATTACHMENT,
                        layout = .COLOR_ATTACHMENT,
                        stages = {.COLOR_ATTACHMENT},
                    },
                    // mipOffset  = Dim_t,
                    // mipNum     = 1,               // can be "REMAINING"
                    // layerOffset= Dim_t,
                    // layerNum   = 1,               // can be "REMAINING"
                    // planes     = PlaneBits,
                    // srcQueue   = ^Queue,
                    // dstQueue   = ^Queue,
                },
                { // Depth texture
                    texture    = depth_texture,
                    before     = {
                        access = {},
                        layout = .UNDEFINED,
                        stages = nri.STAGEBITS_NONE,
                    },
                    after      = {
                        access = {.DEPTH_STENCIL_ATTACHMENT_WRITE},
                        layout = .DEPTH_STENCIL_ATTACHMENT,
                        stages = {.DEPTH_STENCIL_ATTACHMENT},
                    },
                    // mipOffset  = Dim_t,
                    // mipNum     = 1,               // can be "REMAINING"
                    // layerOffset= Dim_t,
                    // layerNum   = 1,               // can be "REMAINING"
                    // planes     = PlaneBits,
                    // srcQueue   = ^Queue,
                    // dstQueue   = ^Queue,                
                }
            }

            barrier_desc := nri.BarrierDesc{
                // globals   = [^]GlobalBarrierDesc,
                // globalNum = u32,
                // buffers   = [^]BufferBarrierDesc,
                // bufferNum = u32,
                textures  = raw_data(texture_barriers),
                textureNum= u32(len(texture_barriers)),
            }
            NRI.CmdBarrier(command_buffer, &barrier_desc)

            color_attachment_desc := nri.AttachmentDesc{
                descriptor= swapchain_texture.color_attachment,
                loadOp = .CLEAR,
                storeOp = .STORE,
                clearValue = {color = {f = {
                    x = 0.03,
                    y = 0.04,
                    z = 0.07,
                    w = 1.00,
                }}}
            }

            rendering_desc := nri.RenderingDesc{
                colors     = &color_attachment_desc,
                colorNum   = 1,
                // depth      = {descriptor = depth_attachment},      // may be treated as "depth-stencil"
                depth      = {
                    descriptor = depth_attachment,
                    loadOp = .CLEAR,
                    storeOp = .STORE,
                    clearValue = {depthStencil = {depth = 1.0}}
                },      // may be treated as "depth-stencil"
                // stencil    = AttachmentDesc,      // (optional) separation is needed for multisample resolve
                // shadingRate= ^Descriptor,         // requires "tiers.shadingRate >= 2"
                // viewMask   = 0,                 // if non-0, requires "viewMaxNum > 1"

            }
            // fmt.printfln("Begin rendering")
            NRI.CmdBeginRendering(command_buffer, &rendering_desc)
            {
                NRI.CmdSetPipelineLayout(command_buffer, .GRAPHICS, pipeline_layout)
                NRI.CmdSetPipeline(command_buffer, pipeline)
                
                viewport := nri.Viewport{
                    x               = 0,
                    y               = 0,
                    width           = f32(window_width),
                    height          = f32(window_height),
                    depthMin        = 0.0,
                    depthMax        = 1.0,
                }
                NRI.CmdSetViewports(command_buffer, &viewport, 1)

                scissor_rect := nri.Rect{
                    x     = 0,
                    y     = 0,
                    width = u16(window_width),
                    height= u16(window_height),
                }
                NRI.CmdSetScissors(command_buffer, &scissor_rect, 1)

                
                NRI.CmdSetIndexBuffer(command_buffer, index_buffer, 0, CubeIndexType)
                vertex_buffer_desc := nri.VertexBufferDesc{
                    buffer = vertex_buffer,
                    offset = 0,
                    stride = size_of(CubeVertex),
                }
                NRI.CmdSetVertexBuffers(command_buffer, 0, &vertex_buffer_desc, 1)
                draw_indexed_desc := nri.DrawIndexedDesc{
                    indexNum    = u32(len(cube_indices)),
                    instanceNum = 1,
                    baseIndex   = 0,   // index buffer offset = CmdSetIndexBuffer.offset + baseIndex * sizeof(CmdSetIndexBuffer.indexType)
                    baseVertex  = 0,   // index += baseVertex
                    baseInstance= 0,
                }
                // fmt.printfln("Draw")
                draw_desc := nri.DrawDesc{
                    vertexNum   = 3,
                    instanceNum = 1,
                }
                NRI.CmdDrawIndexed(command_buffer, &{
                    indexNum    = cube_index_count,
                    instanceNum = 1,
                    baseIndex   = 0,   // index buffer offset = CmdSetIndexBuffer.offset + baseIndex * sizeof(CmdSetIndexBuffer.indexType)
                    baseVertex  = 0,   // index += baseVertex
                    baseInstance= 0,
                })
            }
            // fmt.printfln("End rendering")
            NRI.CmdEndRendering(command_buffer)

            present_barrier := nri.TextureBarrierDesc{
                texture = swapchain_texture.texture,
                before = {
                    access = nri.ACCESSBITS_COLOR_ATTACHMENT,
                    layout = .COLOR_ATTACHMENT,
                    stages = {.COLOR_ATTACHMENT},
                },
                after = {
                    access = {},
                    layout = .PRESENT,
                    stages = nri.STAGEBITS_NONE,
                },
            }

            // texture_barriers[0].before = texture_barriers[0].after
            // texture_barriers[0].after = {
            //     access = {},
            //     layout = .PRESENT,
            //     stages = nri.STAGEBITS_NONE,
            // }
            // NRI.CmdBarrier(command_buffer, &barrier_desc)
            NRI.CmdBarrier(command_buffer, &{
                textures = &present_barrier,
                textureNum = 1,
            })
        }
        
        // fmt.printfln("End commandbuffer")
        NRI_ABORT_ON_FAILURE(NRI.EndCommandBuffer(command_buffer))

        { // Submit
            texture_acquired_fence := nri.FenceSubmitDesc{
                fence = swapchain_acquire_semaphore,
                stages= {.COLOR_ATTACHMENT},
            }

            rendering_finished_fence := nri.FenceSubmitDesc{
                fence = swapchain_texture.release_semaphore,
                stages = nri.STAGEBITS_ALL,
            }

            frame_done_fence := nri.FenceSubmitDesc{
                fence = frame_fence,
                value = 1 + frame_index,
                stages = nri.STAGEBITS_ALL,
            }

            signal_fences := []nri.FenceSubmitDesc{
                rendering_finished_fence,
                frame_done_fence
            }

            queue_submit_desc := nri.QueueSubmitDesc{
                waitFences      = &texture_acquired_fence,
                waitFenceNum    = 1,
                commandBuffers  = &queued_frame.command_buffer,
                commandBufferNum= 1,
                signalFences    = raw_data(signal_fences),
                signalFenceNum  = 2,
                // swapChain       = swapchain, // required if "NRILowLatency" is enabled in the swap chain
            }
            NRI_ABORT_ON_FAILURE(NRI.QueueSubmit(command_queue, &queue_submit_desc))
        }

        // Present
        NRI_ABORT_ON_FAILURE(NRI.QueuePresent(swapchain, swapchain_texture.release_semaphore))

        frame_index += 1
    }

    NRI.DeviceWaitIdle(device)

    // GPU work is idle now. Destroy resources/views first.
    if depth_attachment != nil {
        NRI.DestroyDescriptor(depth_attachment)
        depth_attachment = nil
    }

    if depth_texture != nil {
        NRI.DestroyTexture(depth_texture)
        depth_texture = nil
    }

    if index_buffer != nil {
        NRI.DestroyBuffer(index_buffer)
        index_buffer = nil
    }

    if vertex_buffer != nil {
        NRI.DestroyBuffer(vertex_buffer)
        vertex_buffer = nil
    }


    for i := 0; i < queued_frame_num; i+=1 {
        NRI.DestroyCommandBuffer(frames[i].command_buffer);
        NRI.DestroyCommandAllocator(frames[i].command_allocator);
    }

    if frame_fence != nil {
        NRI.DestroyFence(frame_fence)
        frame_fence = nil
    }

    if pipeline != nil {
        NRI.DestroyPipeline(pipeline)
        pipeline = nil
    }

    if pipeline_layout != nil {
        NRI.DestroyPipelineLayout(pipeline_layout)
        pipeline_layout = nil
    }

    for i :u32= 0; i < swapchain_texture_num; i+=1 {
        NRI.DestroyFence(swapchain_textures[i].acquire_semaphore);
        NRI.DestroyFence(swapchain_textures[i].release_semaphore);
        NRI.DestroyDescriptor(swapchain_textures[i].color_attachment);
    }

    NRI.DestroySwapChain(swapchain);

    // Destroy 
    nri.DestroyDevice(device)
}
