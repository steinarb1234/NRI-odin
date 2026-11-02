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
            // depth             = DepthAttachmentDesc,
            // stencil           = StencilAttachmentDesc,
            // depthStencilFormat= Format,
            // logicOp           = LogicOp,                  // requires "features.logicOp"
            // viewMask          = u32,                      // if non-0, requires "viewMaxNum > 1"
	        // multiview         = Multiview,                // if "viewMask != 0", requires "features.(xxx)Multiview"
        }

        graphics_pipeline_desc := nri.GraphicsPipelineDesc{
            pipelineLayout= pipeline_layout,
            // vertexInput   = &vertex_input_desc,
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
            texture_barriers := nri.TextureBarrierDesc{
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
            }

            barrier_desc := nri.BarrierDesc{
                // globals   = [^]GlobalBarrierDesc,
                // globalNum = u32,
                // buffers   = [^]BufferBarrierDesc,
                // bufferNum = u32,
                textures  = &texture_barriers,
                textureNum= 1,
            }
            NRI.CmdBarrier(command_buffer, &barrier_desc)

            color_attachment_desc := nri.AttachmentDesc{
                descriptor= swapchain_texture.color_attachment,
            }

            rendering_desc := nri.RenderingDesc{
                colors     = &color_attachment_desc,
                colorNum   = 1,
                // depth      = AttachmentDesc,      // may be treated as "depth-stencil"
                // stencil    = AttachmentDesc,      // (optional) separation is needed for multisample resolve
                // shadingRate= ^Descriptor,         // requires "tiers.shadingRate >= 2"
                // viewMask   = 0,                 // if non-0, requires "viewMaxNum > 1"

            }
            // fmt.printfln("Begin rendering")
            NRI.CmdBeginRendering(command_buffer, &rendering_desc)
            {
                { // Clear screen
					NRI.CmdBeginAnnotation(command_buffer, "Clear screen", 0); defer(NRI.CmdEndAnnotation(command_buffer))

	                clear_desc := nri.ClearAttachmentDesc{
	                    value = {
	                        color = {
	                            f = {0.03, 0.04, 0.07, 1.0}
	                        }
	                    },
	                    planes = {.COLOR},
	                }
	                NRI.CmdClearAttachments(command_buffer, &clear_desc, 1, nil, 0)
				}
                // Draw cube
                // fmt.printfln("Set pipeline")

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

                
                // fmt.printfln("Draw")
                draw_desc := nri.DrawDesc{
                    vertexNum   = 3,
                    instanceNum = 1,
                }
                NRI.CmdDraw(command_buffer, &draw_desc)
            }
            // fmt.printfln("End rendering")
            NRI.CmdEndRendering(command_buffer)


            texture_barriers.before = texture_barriers.after
            texture_barriers.after = {
                access = {},
                layout = .PRESENT,
                stages = nri.STAGEBITS_NONE,
            }
            NRI.CmdBarrier(command_buffer, &barrier_desc)
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

    for i := 0; i < queued_frame_num; i+=1 {
        NRI.DestroyCommandBuffer(frames[i].command_buffer);
        NRI.DestroyCommandAllocator(frames[i].command_allocator);
    }

    NRI.DestroyFence(frame_fence);
    NRI.DestroyPipeline(pipeline);
    NRI.DestroyPipelineLayout(pipeline_layout);

    for i :u32= 0; i < swapchain_texture_num; i+=1 {
        NRI.DestroyFence(swapchain_textures[i].acquire_semaphore);
        NRI.DestroyFence(swapchain_textures[i].release_semaphore);
        NRI.DestroyDescriptor(swapchain_textures[i].color_attachment);
    }

    NRI.DestroySwapChain(swapchain);

    // Destroy 
    nri.DestroyDevice(device)

}
