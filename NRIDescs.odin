// © 2021 NVIDIA Corporation
package NRI

when ODIN_DEBUG {
	@(private = "file")
	lib_path :: "./Lib/Debug/"
} else {
	@(private = "file")
	lib_path :: "./Lib/Release/"
}

when ODIN_OS == .Windows {
	when ODIN_ARCH == .amd64 {
		foreign import lib {lib_path + "NRI.lib", "system:dxgi.lib", "system:dxguid.lib", "system:d3d12.lib", "system:d3d11.lib", "system:User32.lib"}
	// } else when ODIN_ARCH == .arm64 {
		// foreign import lib {lib_path + "aarch64-windows.lib"}
	} else do #panic("Unsupported architecture")
// } else when ODIN_OS == .Linux { // Todo: add linux binaries
	// when ODIN_ARCH == .amd64 {
	// 	foreign import lib {lib_path + "libx86_64-linux.a"}
	// } else when ODIN_ARCH == .arm64 {
	// 	foreign import lib {lib_path + "libaarch64-linux.a"}
	// } else do #panic("Unsupported architecture")
} else do #panic("Unsupported OS")

Fence            :: struct {} // a synchronization primitive that can be used to insert a dependency between queue operations or between a queue operation and the host
Queue            :: struct {} // a logical queue, providing access to a HW queue
Memory           :: struct {} // a memory blob allocated on DEVICE or HOST
Buffer           :: struct {} // a buffer object: linear arrays of data
Device           :: struct {} // a logical device
Texture          :: struct {} // a texture object: multidimensional arrays of data
Pipeline         :: struct {} // a collection of state needed for rendering: shaders + fixed
SwapChain        :: struct {} // an array of presentable images that are associated with a surface
QueryPool        :: struct {} // a collection of queries of the same type
Descriptor       :: struct {} // a handle or pointer to a resource (potentially with a header)
CommandBuffer    :: struct {} // used to record commands which can be subsequently submitted to a device queue for execution (aka command list)
DescriptorSet    :: struct {} // a continuous set of descriptors
DescriptorPool   :: struct {} // maintains a pool of descriptors, descriptor sets are allocated from (aka descriptor heap)
PipelineLayout   :: struct {} // determines the interface between shader stages and shader resources (aka root signature)
PipelineCache    :: struct {} // a persistent cache of compiled pipeline state objects (PSOs) to accelerate subsequent PSO creations
CommandAllocator :: struct {} // an object that command buffer memory is allocated from

// Basic types
Sample_t :: u8
Dim_t    :: u16
Object   :: struct {}

Uid_t :: struct {
	low:  u64,
	high: u64,
}

Dim2_t :: struct {
	w, h: Dim_t,
}

Float2_t :: struct {
	x, y: f32,
}

// "AdapterDesc::supportedGraphicsAPIs" is a mask of supported graphics APIs
GraphicsAPI :: enum u8 {
	//============================================================================================================================================================================================
	
	// "AdapterDesc::supportedGraphicsAPIs" is a mask of supported graphics APIs
	NONE  = 1,

	//============================================================================================================================================================================================
	
	// "AdapterDesc::supportedGraphicsAPIs" is a mask of supported graphics APIs
	D3D11 = 2,

	//============================================================================================================================================================================================
	
	// "AdapterDesc::supportedGraphicsAPIs" is a mask of supported graphics APIs
	D3D12 = 4,

	//============================================================================================================================================================================================
	
	// "AdapterDesc::supportedGraphicsAPIs" is a mask of supported graphics APIs
	VK    = 8,

	//============================================================================================================================================================================================
	
	// "AdapterDesc::supportedGraphicsAPIs" is a mask of supported graphics APIs
	WGPU  = 16,
}

Result :: enum i8 {
	DEVICE_LOST      = -3,
	OUT_OF_DATE      = -2,
	INVALID_SDK      = -1,
	SUCCESS          = 0,
	FAILURE          = 1,
	INVALID_ARGUMENT = 2,
	OUT_OF_MEMORY    = 3,
	UNSUPPORTED      = 4,
	MAX_NUM          = 5,
}

// The viewport origin is top-left (D3D native) by default, but can be changed to bottom-left (VK native)
// https://docs.vulkan.org/refpages/latest/refpages/source/VkViewport.html
// https://learn.microsoft.com/en-us/windows/win32/api/d3d12/ns-d3d12-d3d12_viewport
Viewport :: struct {
	x:                f32,
	y:                f32,
	width:            f32,
	height:           f32,
	depthMin:         f32,
	depthMax:         f32,
	originBottomLeft: bool, // expects "features.viewportOriginBottomLeft"
}

// https://docs.vulkan.org/refpages/latest/refpages/source/VkRect2D.html
Rect :: struct {
	x:      i16,
	y:      i16,
	width:  Dim_t,
	height: Dim_t,
}

Color32f :: struct {
	x, y, z, w: f32,
}

Color32ui :: struct {
	x, y, z, w: u32,
}

Color32i :: struct {
	x, y, z, w: i32,
}

DepthStencil :: struct {
	depth:   f32,
	stencil: u8,
}

Color :: struct #raw_union {
	f:  Color32f,
	ui: Color32ui,
	i:  Color32i,
}

ClearValue :: struct #raw_union {
	depthStencil: DepthStencil,
	color:        Color,
}

SampleLocation :: struct {
	x, y: i8, // [-8; 7]
}

// https://docs.vulkan.org/refpages/latest/refpages/source/VkFormat.html
// https://learn.microsoft.com/en-us/windows/win32/api/dxgiformat/ne-dxgiformat-dxgi_format
// left -> right : low -> high bits
// Expected (but not guaranteed) "FormatSupportBits" are provided, but "GetFormatSupport" should be used for querying real HW support
// To demote sRGB use the previous format, i.e. "format - 1"
//                                            STORAGE_WRITE_WITHOUT_FORMAT
//                                           STORAGE_READ_WITHOUT_FORMAT |
//                                                       VERTEX_BUFFER | |
//                                            STORAGE_BUFFER_ATOMICS | | |
//                                                  STORAGE_BUFFER | | | |
//                                                        BUFFER | | | | |
//                                         MULTISAMPLE_RESOLVE | | | | | |
//                                            MULTISAMPLE_8X | | | | | | |
//                                          MULTISAMPLE_4X | | | | | | | |
//                                        MULTISAMPLE_2X | | | | | | | | |
//                                               BLEND | | | | | | | | | |
//                          DEPTH_STENCIL_ATTACHMENT | | | | | | | | | | |
//                                COLOR_ATTACHMENT | | | | | | | | | | | |
//                       STORAGE_TEXTURE_ATOMICS | | | | | | | | | | | | |
//                             STORAGE_TEXTURE | | | | | | | | | | | | | |
//                                   TEXTURE | | | | | | | | | | | | | | |
//                                         | | | | | | | | | | | | | | | |
Format :: enum u8 {
	// left -> right : low -> high bits
	// Expected (but not guaranteed) "FormatSupportBits" are provided, but "GetFormatSupport" should be used for querying real HW support
	// To demote sRGB use the previous format, i.e. "format - 1"
	//                                            STORAGE_WRITE_WITHOUT_FORMAT
	//                                           STORAGE_READ_WITHOUT_FORMAT |
	//                                                       VERTEX_BUFFER | |
	//                                            STORAGE_BUFFER_ATOMICS | | |
	//                                                  STORAGE_BUFFER | | | |
	//                                                        BUFFER | | | | |
	//                                         MULTISAMPLE_RESOLVE | | | | | |
	//                                            MULTISAMPLE_8X | | | | | | |
	//                                          MULTISAMPLE_4X | | | | | | | |
	//                                        MULTISAMPLE_2X | | | | | | | | |
	//                                               BLEND | | | | | | | | | |
	//                          DEPTH_STENCIL_ATTACHMENT | | | | | | | | | | |
	//                                COLOR_ATTACHMENT | | | | | | | | | | | |
	//                       STORAGE_TEXTURE_ATOMICS | | | | | | | | | | | | |
	//                             STORAGE_TEXTURE | | | | | | | | | | | | | |
	//                                   TEXTURE | | | | | | | | | | | | | | |
	//                                         | | | | | | | | | | | | | | | |
	UNKNOWN              = 0,   // |      FormatSupportBits      |

	// left -> right : low -> high bits
	// Expected (but not guaranteed) "FormatSupportBits" are provided, but "GetFormatSupport" should be used for querying real HW support
	// To demote sRGB use the previous format, i.e. "format - 1"
	//                                            STORAGE_WRITE_WITHOUT_FORMAT
	//                                           STORAGE_READ_WITHOUT_FORMAT |
	//                                                       VERTEX_BUFFER | |
	//                                            STORAGE_BUFFER_ATOMICS | | |
	//                                                  STORAGE_BUFFER | | | |
	//                                                        BUFFER | | | | |
	//                                         MULTISAMPLE_RESOLVE | | | | | |
	//                                            MULTISAMPLE_8X | | | | | | |
	//                                          MULTISAMPLE_4X | | | | | | | |
	//                                        MULTISAMPLE_2X | | | | | | | | |
	//                                               BLEND | | | | | | | | | |
	//                          DEPTH_STENCIL_ATTACHMENT | | | | | | | | | | |
	//                                COLOR_ATTACHMENT | | | | | | | | | | | |
	//                       STORAGE_TEXTURE_ATOMICS | | | | | | | | | | | | |
	//                             STORAGE_TEXTURE | | | | | | | | | | | | | |
	//                                   TEXTURE | | | | | | | | | | | | | | |
	//                                         | | | | | | | | | | | | | | | |
	R8_UNORM             = 1,   // |      FormatSupportBits      |

	// left -> right : low -> high bits
	// Expected (but not guaranteed) "FormatSupportBits" are provided, but "GetFormatSupport" should be used for querying real HW support
	// To demote sRGB use the previous format, i.e. "format - 1"
	//                                            STORAGE_WRITE_WITHOUT_FORMAT
	//                                           STORAGE_READ_WITHOUT_FORMAT |
	//                                                       VERTEX_BUFFER | |
	//                                            STORAGE_BUFFER_ATOMICS | | |
	//                                                  STORAGE_BUFFER | | | |
	//                                                        BUFFER | | | | |
	//                                         MULTISAMPLE_RESOLVE | | | | | |
	//                                            MULTISAMPLE_8X | | | | | | |
	//                                          MULTISAMPLE_4X | | | | | | | |
	//                                        MULTISAMPLE_2X | | | | | | | | |
	//                                               BLEND | | | | | | | | | |
	//                          DEPTH_STENCIL_ATTACHMENT | | | | | | | | | | |
	//                                COLOR_ATTACHMENT | | | | | | | | | | | |
	//                       STORAGE_TEXTURE_ATOMICS | | | | | | | | | | | | |
	//                             STORAGE_TEXTURE | | | | | | | | | | | | | |
	//                                   TEXTURE | | | | | | | | | | | | | | |
	//                                         | | | | | | | | | | | | | | | |
	R8_SNORM             = 2,   // |      FormatSupportBits      |

	// left -> right : low -> high bits
	// Expected (but not guaranteed) "FormatSupportBits" are provided, but "GetFormatSupport" should be used for querying real HW support
	// To demote sRGB use the previous format, i.e. "format - 1"
	//                                            STORAGE_WRITE_WITHOUT_FORMAT
	//                                           STORAGE_READ_WITHOUT_FORMAT |
	//                                                       VERTEX_BUFFER | |
	//                                            STORAGE_BUFFER_ATOMICS | | |
	//                                                  STORAGE_BUFFER | | | |
	//                                                        BUFFER | | | | |
	//                                         MULTISAMPLE_RESOLVE | | | | | |
	//                                            MULTISAMPLE_8X | | | | | | |
	//                                          MULTISAMPLE_4X | | | | | | | |
	//                                        MULTISAMPLE_2X | | | | | | | | |
	//                                               BLEND | | | | | | | | | |
	//                          DEPTH_STENCIL_ATTACHMENT | | | | | | | | | | |
	//                                COLOR_ATTACHMENT | | | | | | | | | | | |
	//                       STORAGE_TEXTURE_ATOMICS | | | | | | | | | | | | |
	//                             STORAGE_TEXTURE | | | | | | | | | | | | | |
	//                                   TEXTURE | | | | | | | | | | | | | | |
	//                                         | | | | | | | | | | | | | | | |
	R8_UINT              = 3,   // |      FormatSupportBits      |

	// left -> right : low -> high bits
	// Expected (but not guaranteed) "FormatSupportBits" are provided, but "GetFormatSupport" should be used for querying real HW support
	// To demote sRGB use the previous format, i.e. "format - 1"
	//                                            STORAGE_WRITE_WITHOUT_FORMAT
	//                                           STORAGE_READ_WITHOUT_FORMAT |
	//                                                       VERTEX_BUFFER | |
	//                                            STORAGE_BUFFER_ATOMICS | | |
	//                                                  STORAGE_BUFFER | | | |
	//                                                        BUFFER | | | | |
	//                                         MULTISAMPLE_RESOLVE | | | | | |
	//                                            MULTISAMPLE_8X | | | | | | |
	//                                          MULTISAMPLE_4X | | | | | | | |
	//                                        MULTISAMPLE_2X | | | | | | | | |
	//                                               BLEND | | | | | | | | | |
	//                          DEPTH_STENCIL_ATTACHMENT | | | | | | | | | | |
	//                                COLOR_ATTACHMENT | | | | | | | | | | | |
	//                       STORAGE_TEXTURE_ATOMICS | | | | | | | | | | | | |
	//                             STORAGE_TEXTURE | | | | | | | | | | | | | |
	//                                   TEXTURE | | | | | | | | | | | | | | |
	//                                         | | | | | | | | | | | | | | | |
	R8_SINT              = 4,   // |      FormatSupportBits      |

	// left -> right : low -> high bits
	// Expected (but not guaranteed) "FormatSupportBits" are provided, but "GetFormatSupport" should be used for querying real HW support
	// To demote sRGB use the previous format, i.e. "format - 1"
	//                                            STORAGE_WRITE_WITHOUT_FORMAT
	//                                           STORAGE_READ_WITHOUT_FORMAT |
	//                                                       VERTEX_BUFFER | |
	//                                            STORAGE_BUFFER_ATOMICS | | |
	//                                                  STORAGE_BUFFER | | | |
	//                                                        BUFFER | | | | |
	//                                         MULTISAMPLE_RESOLVE | | | | | |
	//                                            MULTISAMPLE_8X | | | | | | |
	//                                          MULTISAMPLE_4X | | | | | | | |
	//                                        MULTISAMPLE_2X | | | | | | | | |
	//                                               BLEND | | | | | | | | | |
	//                          DEPTH_STENCIL_ATTACHMENT | | | | | | | | | | |
	//                                COLOR_ATTACHMENT | | | | | | | | | | | |
	//                       STORAGE_TEXTURE_ATOMICS | | | | | | | | | | | | |
	//                             STORAGE_TEXTURE | | | | | | | | | | | | | |
	//                                   TEXTURE | | | | | | | | | | | | | | |
	//                                         | | | | | | | | | | | | | | | |
	RG8_UNORM            = 5,   // |      FormatSupportBits      |

	// left -> right : low -> high bits
	// Expected (but not guaranteed) "FormatSupportBits" are provided, but "GetFormatSupport" should be used for querying real HW support
	// To demote sRGB use the previous format, i.e. "format - 1"
	//                                            STORAGE_WRITE_WITHOUT_FORMAT
	//                                           STORAGE_READ_WITHOUT_FORMAT |
	//                                                       VERTEX_BUFFER | |
	//                                            STORAGE_BUFFER_ATOMICS | | |
	//                                                  STORAGE_BUFFER | | | |
	//                                                        BUFFER | | | | |
	//                                         MULTISAMPLE_RESOLVE | | | | | |
	//                                            MULTISAMPLE_8X | | | | | | |
	//                                          MULTISAMPLE_4X | | | | | | | |
	//                                        MULTISAMPLE_2X | | | | | | | | |
	//                                               BLEND | | | | | | | | | |
	//                          DEPTH_STENCIL_ATTACHMENT | | | | | | | | | | |
	//                                COLOR_ATTACHMENT | | | | | | | | | | | |
	//                       STORAGE_TEXTURE_ATOMICS | | | | | | | | | | | | |
	//                             STORAGE_TEXTURE | | | | | | | | | | | | | |
	//                                   TEXTURE | | | | | | | | | | | | | | |
	//                                         | | | | | | | | | | | | | | | |
	RG8_SNORM            = 6,   // |      FormatSupportBits      |

	// left -> right : low -> high bits
	// Expected (but not guaranteed) "FormatSupportBits" are provided, but "GetFormatSupport" should be used for querying real HW support
	// To demote sRGB use the previous format, i.e. "format - 1"
	//                                            STORAGE_WRITE_WITHOUT_FORMAT
	//                                           STORAGE_READ_WITHOUT_FORMAT |
	//                                                       VERTEX_BUFFER | |
	//                                            STORAGE_BUFFER_ATOMICS | | |
	//                                                  STORAGE_BUFFER | | | |
	//                                                        BUFFER | | | | |
	//                                         MULTISAMPLE_RESOLVE | | | | | |
	//                                            MULTISAMPLE_8X | | | | | | |
	//                                          MULTISAMPLE_4X | | | | | | | |
	//                                        MULTISAMPLE_2X | | | | | | | | |
	//                                               BLEND | | | | | | | | | |
	//                          DEPTH_STENCIL_ATTACHMENT | | | | | | | | | | |
	//                                COLOR_ATTACHMENT | | | | | | | | | | | |
	//                       STORAGE_TEXTURE_ATOMICS | | | | | | | | | | | | |
	//                             STORAGE_TEXTURE | | | | | | | | | | | | | |
	//                                   TEXTURE | | | | | | | | | | | | | | |
	//                                         | | | | | | | | | | | | | | | |
	RG8_UINT             = 7,   // |      FormatSupportBits      |

	// left -> right : low -> high bits
	// Expected (but not guaranteed) "FormatSupportBits" are provided, but "GetFormatSupport" should be used for querying real HW support
	// To demote sRGB use the previous format, i.e. "format - 1"
	//                                            STORAGE_WRITE_WITHOUT_FORMAT
	//                                           STORAGE_READ_WITHOUT_FORMAT |
	//                                                       VERTEX_BUFFER | |
	//                                            STORAGE_BUFFER_ATOMICS | | |
	//                                                  STORAGE_BUFFER | | | |
	//                                                        BUFFER | | | | |
	//                                         MULTISAMPLE_RESOLVE | | | | | |
	//                                            MULTISAMPLE_8X | | | | | | |
	//                                          MULTISAMPLE_4X | | | | | | | |
	//                                        MULTISAMPLE_2X | | | | | | | | |
	//                                               BLEND | | | | | | | | | |
	//                          DEPTH_STENCIL_ATTACHMENT | | | | | | | | | | |
	//                                COLOR_ATTACHMENT | | | | | | | | | | | |
	//                       STORAGE_TEXTURE_ATOMICS | | | | | | | | | | | | |
	//                             STORAGE_TEXTURE | | | | | | | | | | | | | |
	//                                   TEXTURE | | | | | | | | | | | | | | |
	//                                         | | | | | | | | | | | | | | | |
	RG8_SINT             = 8,   // |      FormatSupportBits      |

	// left -> right : low -> high bits
	// Expected (but not guaranteed) "FormatSupportBits" are provided, but "GetFormatSupport" should be used for querying real HW support
	// To demote sRGB use the previous format, i.e. "format - 1"
	//                                            STORAGE_WRITE_WITHOUT_FORMAT
	//                                           STORAGE_READ_WITHOUT_FORMAT |
	//                                                       VERTEX_BUFFER | |
	//                                            STORAGE_BUFFER_ATOMICS | | |
	//                                                  STORAGE_BUFFER | | | |
	//                                                        BUFFER | | | | |
	//                                         MULTISAMPLE_RESOLVE | | | | | |
	//                                            MULTISAMPLE_8X | | | | | | |
	//                                          MULTISAMPLE_4X | | | | | | | |
	//                                        MULTISAMPLE_2X | | | | | | | | |
	//                                               BLEND | | | | | | | | | |
	//                          DEPTH_STENCIL_ATTACHMENT | | | | | | | | | | |
	//                                COLOR_ATTACHMENT | | | | | | | | | | | |
	//                       STORAGE_TEXTURE_ATOMICS | | | | | | | | | | | | |
	//                             STORAGE_TEXTURE | | | | | | | | | | | | | |
	//                                   TEXTURE | | | | | | | | | | | | | | |
	//                                         | | | | | | | | | | | | | | | |
	BGRA8_UNORM          = 9,   // |      FormatSupportBits      |

	// left -> right : low -> high bits
	// Expected (but not guaranteed) "FormatSupportBits" are provided, but "GetFormatSupport" should be used for querying real HW support
	// To demote sRGB use the previous format, i.e. "format - 1"
	//                                            STORAGE_WRITE_WITHOUT_FORMAT
	//                                           STORAGE_READ_WITHOUT_FORMAT |
	//                                                       VERTEX_BUFFER | |
	//                                            STORAGE_BUFFER_ATOMICS | | |
	//                                                  STORAGE_BUFFER | | | |
	//                                                        BUFFER | | | | |
	//                                         MULTISAMPLE_RESOLVE | | | | | |
	//                                            MULTISAMPLE_8X | | | | | | |
	//                                          MULTISAMPLE_4X | | | | | | | |
	//                                        MULTISAMPLE_2X | | | | | | | | |
	//                                               BLEND | | | | | | | | | |
	//                          DEPTH_STENCIL_ATTACHMENT | | | | | | | | | | |
	//                                COLOR_ATTACHMENT | | | | | | | | | | | |
	//                       STORAGE_TEXTURE_ATOMICS | | | | | | | | | | | | |
	//                             STORAGE_TEXTURE | | | | | | | | | | | | | |
	//                                   TEXTURE | | | | | | | | | | | | | | |
	//                                         | | | | | | | | | | | | | | | |
	BGRA8_SRGB           = 10,  // |      FormatSupportBits      |

	// left -> right : low -> high bits
	// Expected (but not guaranteed) "FormatSupportBits" are provided, but "GetFormatSupport" should be used for querying real HW support
	// To demote sRGB use the previous format, i.e. "format - 1"
	//                                            STORAGE_WRITE_WITHOUT_FORMAT
	//                                           STORAGE_READ_WITHOUT_FORMAT |
	//                                                       VERTEX_BUFFER | |
	//                                            STORAGE_BUFFER_ATOMICS | | |
	//                                                  STORAGE_BUFFER | | | |
	//                                                        BUFFER | | | | |
	//                                         MULTISAMPLE_RESOLVE | | | | | |
	//                                            MULTISAMPLE_8X | | | | | | |
	//                                          MULTISAMPLE_4X | | | | | | | |
	//                                        MULTISAMPLE_2X | | | | | | | | |
	//                                               BLEND | | | | | | | | | |
	//                          DEPTH_STENCIL_ATTACHMENT | | | | | | | | | | |
	//                                COLOR_ATTACHMENT | | | | | | | | | | | |
	//                       STORAGE_TEXTURE_ATOMICS | | | | | | | | | | | | |
	//                             STORAGE_TEXTURE | | | | | | | | | | | | | |
	//                                   TEXTURE | | | | | | | | | | | | | | |
	//                                         | | | | | | | | | | | | | | | |
	RGBA8_UNORM          = 11,  // |      FormatSupportBits      |

	// left -> right : low -> high bits
	// Expected (but not guaranteed) "FormatSupportBits" are provided, but "GetFormatSupport" should be used for querying real HW support
	// To demote sRGB use the previous format, i.e. "format - 1"
	//                                            STORAGE_WRITE_WITHOUT_FORMAT
	//                                           STORAGE_READ_WITHOUT_FORMAT |
	//                                                       VERTEX_BUFFER | |
	//                                            STORAGE_BUFFER_ATOMICS | | |
	//                                                  STORAGE_BUFFER | | | |
	//                                                        BUFFER | | | | |
	//                                         MULTISAMPLE_RESOLVE | | | | | |
	//                                            MULTISAMPLE_8X | | | | | | |
	//                                          MULTISAMPLE_4X | | | | | | | |
	//                                        MULTISAMPLE_2X | | | | | | | | |
	//                                               BLEND | | | | | | | | | |
	//                          DEPTH_STENCIL_ATTACHMENT | | | | | | | | | | |
	//                                COLOR_ATTACHMENT | | | | | | | | | | | |
	//                       STORAGE_TEXTURE_ATOMICS | | | | | | | | | | | | |
	//                             STORAGE_TEXTURE | | | | | | | | | | | | | |
	//                                   TEXTURE | | | | | | | | | | | | | | |
	//                                         | | | | | | | | | | | | | | | |
	RGBA8_SRGB           = 12,  // |      FormatSupportBits      |

	// left -> right : low -> high bits
	// Expected (but not guaranteed) "FormatSupportBits" are provided, but "GetFormatSupport" should be used for querying real HW support
	// To demote sRGB use the previous format, i.e. "format - 1"
	//                                            STORAGE_WRITE_WITHOUT_FORMAT
	//                                           STORAGE_READ_WITHOUT_FORMAT |
	//                                                       VERTEX_BUFFER | |
	//                                            STORAGE_BUFFER_ATOMICS | | |
	//                                                  STORAGE_BUFFER | | | |
	//                                                        BUFFER | | | | |
	//                                         MULTISAMPLE_RESOLVE | | | | | |
	//                                            MULTISAMPLE_8X | | | | | | |
	//                                          MULTISAMPLE_4X | | | | | | | |
	//                                        MULTISAMPLE_2X | | | | | | | | |
	//                                               BLEND | | | | | | | | | |
	//                          DEPTH_STENCIL_ATTACHMENT | | | | | | | | | | |
	//                                COLOR_ATTACHMENT | | | | | | | | | | | |
	//                       STORAGE_TEXTURE_ATOMICS | | | | | | | | | | | | |
	//                             STORAGE_TEXTURE | | | | | | | | | | | | | |
	//                                   TEXTURE | | | | | | | | | | | | | | |
	//                                         | | | | | | | | | | | | | | | |
	RGBA8_SNORM          = 13,  // |      FormatSupportBits      |

	// left -> right : low -> high bits
	// Expected (but not guaranteed) "FormatSupportBits" are provided, but "GetFormatSupport" should be used for querying real HW support
	// To demote sRGB use the previous format, i.e. "format - 1"
	//                                            STORAGE_WRITE_WITHOUT_FORMAT
	//                                           STORAGE_READ_WITHOUT_FORMAT |
	//                                                       VERTEX_BUFFER | |
	//                                            STORAGE_BUFFER_ATOMICS | | |
	//                                                  STORAGE_BUFFER | | | |
	//                                                        BUFFER | | | | |
	//                                         MULTISAMPLE_RESOLVE | | | | | |
	//                                            MULTISAMPLE_8X | | | | | | |
	//                                          MULTISAMPLE_4X | | | | | | | |
	//                                        MULTISAMPLE_2X | | | | | | | | |
	//                                               BLEND | | | | | | | | | |
	//                          DEPTH_STENCIL_ATTACHMENT | | | | | | | | | | |
	//                                COLOR_ATTACHMENT | | | | | | | | | | | |
	//                       STORAGE_TEXTURE_ATOMICS | | | | | | | | | | | | |
	//                             STORAGE_TEXTURE | | | | | | | | | | | | | |
	//                                   TEXTURE | | | | | | | | | | | | | | |
	//                                         | | | | | | | | | | | | | | | |
	RGBA8_UINT           = 14,  // |      FormatSupportBits      |

	// left -> right : low -> high bits
	// Expected (but not guaranteed) "FormatSupportBits" are provided, but "GetFormatSupport" should be used for querying real HW support
	// To demote sRGB use the previous format, i.e. "format - 1"
	//                                            STORAGE_WRITE_WITHOUT_FORMAT
	//                                           STORAGE_READ_WITHOUT_FORMAT |
	//                                                       VERTEX_BUFFER | |
	//                                            STORAGE_BUFFER_ATOMICS | | |
	//                                                  STORAGE_BUFFER | | | |
	//                                                        BUFFER | | | | |
	//                                         MULTISAMPLE_RESOLVE | | | | | |
	//                                            MULTISAMPLE_8X | | | | | | |
	//                                          MULTISAMPLE_4X | | | | | | | |
	//                                        MULTISAMPLE_2X | | | | | | | | |
	//                                               BLEND | | | | | | | | | |
	//                          DEPTH_STENCIL_ATTACHMENT | | | | | | | | | | |
	//                                COLOR_ATTACHMENT | | | | | | | | | | | |
	//                       STORAGE_TEXTURE_ATOMICS | | | | | | | | | | | | |
	//                             STORAGE_TEXTURE | | | | | | | | | | | | | |
	//                                   TEXTURE | | | | | | | | | | | | | | |
	//                                         | | | | | | | | | | | | | | | |
	RGBA8_SINT           = 15,  // |      FormatSupportBits      |

	// left -> right : low -> high bits
	// Expected (but not guaranteed) "FormatSupportBits" are provided, but "GetFormatSupport" should be used for querying real HW support
	// To demote sRGB use the previous format, i.e. "format - 1"
	//                                            STORAGE_WRITE_WITHOUT_FORMAT
	//                                           STORAGE_READ_WITHOUT_FORMAT |
	//                                                       VERTEX_BUFFER | |
	//                                            STORAGE_BUFFER_ATOMICS | | |
	//                                                  STORAGE_BUFFER | | | |
	//                                                        BUFFER | | | | |
	//                                         MULTISAMPLE_RESOLVE | | | | | |
	//                                            MULTISAMPLE_8X | | | | | | |
	//                                          MULTISAMPLE_4X | | | | | | | |
	//                                        MULTISAMPLE_2X | | | | | | | | |
	//                                               BLEND | | | | | | | | | |
	//                          DEPTH_STENCIL_ATTACHMENT | | | | | | | | | | |
	//                                COLOR_ATTACHMENT | | | | | | | | | | | |
	//                       STORAGE_TEXTURE_ATOMICS | | | | | | | | | | | | |
	//                             STORAGE_TEXTURE | | | | | | | | | | | | | |
	//                                   TEXTURE | | | | | | | | | | | | | | |
	//                                         | | | | | | | | | | | | | | | |
	R16_UNORM            = 16,  // |      FormatSupportBits      |

	// left -> right : low -> high bits
	// Expected (but not guaranteed) "FormatSupportBits" are provided, but "GetFormatSupport" should be used for querying real HW support
	// To demote sRGB use the previous format, i.e. "format - 1"
	//                                            STORAGE_WRITE_WITHOUT_FORMAT
	//                                           STORAGE_READ_WITHOUT_FORMAT |
	//                                                       VERTEX_BUFFER | |
	//                                            STORAGE_BUFFER_ATOMICS | | |
	//                                                  STORAGE_BUFFER | | | |
	//                                                        BUFFER | | | | |
	//                                         MULTISAMPLE_RESOLVE | | | | | |
	//                                            MULTISAMPLE_8X | | | | | | |
	//                                          MULTISAMPLE_4X | | | | | | | |
	//                                        MULTISAMPLE_2X | | | | | | | | |
	//                                               BLEND | | | | | | | | | |
	//                          DEPTH_STENCIL_ATTACHMENT | | | | | | | | | | |
	//                                COLOR_ATTACHMENT | | | | | | | | | | | |
	//                       STORAGE_TEXTURE_ATOMICS | | | | | | | | | | | | |
	//                             STORAGE_TEXTURE | | | | | | | | | | | | | |
	//                                   TEXTURE | | | | | | | | | | | | | | |
	//                                         | | | | | | | | | | | | | | | |
	R16_SNORM            = 17,  // |      FormatSupportBits      |

	// left -> right : low -> high bits
	// Expected (but not guaranteed) "FormatSupportBits" are provided, but "GetFormatSupport" should be used for querying real HW support
	// To demote sRGB use the previous format, i.e. "format - 1"
	//                                            STORAGE_WRITE_WITHOUT_FORMAT
	//                                           STORAGE_READ_WITHOUT_FORMAT |
	//                                                       VERTEX_BUFFER | |
	//                                            STORAGE_BUFFER_ATOMICS | | |
	//                                                  STORAGE_BUFFER | | | |
	//                                                        BUFFER | | | | |
	//                                         MULTISAMPLE_RESOLVE | | | | | |
	//                                            MULTISAMPLE_8X | | | | | | |
	//                                          MULTISAMPLE_4X | | | | | | | |
	//                                        MULTISAMPLE_2X | | | | | | | | |
	//                                               BLEND | | | | | | | | | |
	//                          DEPTH_STENCIL_ATTACHMENT | | | | | | | | | | |
	//                                COLOR_ATTACHMENT | | | | | | | | | | | |
	//                       STORAGE_TEXTURE_ATOMICS | | | | | | | | | | | | |
	//                             STORAGE_TEXTURE | | | | | | | | | | | | | |
	//                                   TEXTURE | | | | | | | | | | | | | | |
	//                                         | | | | | | | | | | | | | | | |
	R16_UINT             = 18,  // |      FormatSupportBits      |

	// left -> right : low -> high bits
	// Expected (but not guaranteed) "FormatSupportBits" are provided, but "GetFormatSupport" should be used for querying real HW support
	// To demote sRGB use the previous format, i.e. "format - 1"
	//                                            STORAGE_WRITE_WITHOUT_FORMAT
	//                                           STORAGE_READ_WITHOUT_FORMAT |
	//                                                       VERTEX_BUFFER | |
	//                                            STORAGE_BUFFER_ATOMICS | | |
	//                                                  STORAGE_BUFFER | | | |
	//                                                        BUFFER | | | | |
	//                                         MULTISAMPLE_RESOLVE | | | | | |
	//                                            MULTISAMPLE_8X | | | | | | |
	//                                          MULTISAMPLE_4X | | | | | | | |
	//                                        MULTISAMPLE_2X | | | | | | | | |
	//                                               BLEND | | | | | | | | | |
	//                          DEPTH_STENCIL_ATTACHMENT | | | | | | | | | | |
	//                                COLOR_ATTACHMENT | | | | | | | | | | | |
	//                       STORAGE_TEXTURE_ATOMICS | | | | | | | | | | | | |
	//                             STORAGE_TEXTURE | | | | | | | | | | | | | |
	//                                   TEXTURE | | | | | | | | | | | | | | |
	//                                         | | | | | | | | | | | | | | | |
	R16_SINT             = 19,  // |      FormatSupportBits      |

	// left -> right : low -> high bits
	// Expected (but not guaranteed) "FormatSupportBits" are provided, but "GetFormatSupport" should be used for querying real HW support
	// To demote sRGB use the previous format, i.e. "format - 1"
	//                                            STORAGE_WRITE_WITHOUT_FORMAT
	//                                           STORAGE_READ_WITHOUT_FORMAT |
	//                                                       VERTEX_BUFFER | |
	//                                            STORAGE_BUFFER_ATOMICS | | |
	//                                                  STORAGE_BUFFER | | | |
	//                                                        BUFFER | | | | |
	//                                         MULTISAMPLE_RESOLVE | | | | | |
	//                                            MULTISAMPLE_8X | | | | | | |
	//                                          MULTISAMPLE_4X | | | | | | | |
	//                                        MULTISAMPLE_2X | | | | | | | | |
	//                                               BLEND | | | | | | | | | |
	//                          DEPTH_STENCIL_ATTACHMENT | | | | | | | | | | |
	//                                COLOR_ATTACHMENT | | | | | | | | | | | |
	//                       STORAGE_TEXTURE_ATOMICS | | | | | | | | | | | | |
	//                             STORAGE_TEXTURE | | | | | | | | | | | | | |
	//                                   TEXTURE | | | | | | | | | | | | | | |
	//                                         | | | | | | | | | | | | | | | |
	R16_SFLOAT           = 20,  // |      FormatSupportBits      |

	// left -> right : low -> high bits
	// Expected (but not guaranteed) "FormatSupportBits" are provided, but "GetFormatSupport" should be used for querying real HW support
	// To demote sRGB use the previous format, i.e. "format - 1"
	//                                            STORAGE_WRITE_WITHOUT_FORMAT
	//                                           STORAGE_READ_WITHOUT_FORMAT |
	//                                                       VERTEX_BUFFER | |
	//                                            STORAGE_BUFFER_ATOMICS | | |
	//                                                  STORAGE_BUFFER | | | |
	//                                                        BUFFER | | | | |
	//                                         MULTISAMPLE_RESOLVE | | | | | |
	//                                            MULTISAMPLE_8X | | | | | | |
	//                                          MULTISAMPLE_4X | | | | | | | |
	//                                        MULTISAMPLE_2X | | | | | | | | |
	//                                               BLEND | | | | | | | | | |
	//                          DEPTH_STENCIL_ATTACHMENT | | | | | | | | | | |
	//                                COLOR_ATTACHMENT | | | | | | | | | | | |
	//                       STORAGE_TEXTURE_ATOMICS | | | | | | | | | | | | |
	//                             STORAGE_TEXTURE | | | | | | | | | | | | | |
	//                                   TEXTURE | | | | | | | | | | | | | | |
	//                                         | | | | | | | | | | | | | | | |
	RG16_UNORM           = 21,  // |      FormatSupportBits      |

	// left -> right : low -> high bits
	// Expected (but not guaranteed) "FormatSupportBits" are provided, but "GetFormatSupport" should be used for querying real HW support
	// To demote sRGB use the previous format, i.e. "format - 1"
	//                                            STORAGE_WRITE_WITHOUT_FORMAT
	//                                           STORAGE_READ_WITHOUT_FORMAT |
	//                                                       VERTEX_BUFFER | |
	//                                            STORAGE_BUFFER_ATOMICS | | |
	//                                                  STORAGE_BUFFER | | | |
	//                                                        BUFFER | | | | |
	//                                         MULTISAMPLE_RESOLVE | | | | | |
	//                                            MULTISAMPLE_8X | | | | | | |
	//                                          MULTISAMPLE_4X | | | | | | | |
	//                                        MULTISAMPLE_2X | | | | | | | | |
	//                                               BLEND | | | | | | | | | |
	//                          DEPTH_STENCIL_ATTACHMENT | | | | | | | | | | |
	//                                COLOR_ATTACHMENT | | | | | | | | | | | |
	//                       STORAGE_TEXTURE_ATOMICS | | | | | | | | | | | | |
	//                             STORAGE_TEXTURE | | | | | | | | | | | | | |
	//                                   TEXTURE | | | | | | | | | | | | | | |
	//                                         | | | | | | | | | | | | | | | |
	RG16_SNORM           = 22,  // |      FormatSupportBits      |

	// left -> right : low -> high bits
	// Expected (but not guaranteed) "FormatSupportBits" are provided, but "GetFormatSupport" should be used for querying real HW support
	// To demote sRGB use the previous format, i.e. "format - 1"
	//                                            STORAGE_WRITE_WITHOUT_FORMAT
	//                                           STORAGE_READ_WITHOUT_FORMAT |
	//                                                       VERTEX_BUFFER | |
	//                                            STORAGE_BUFFER_ATOMICS | | |
	//                                                  STORAGE_BUFFER | | | |
	//                                                        BUFFER | | | | |
	//                                         MULTISAMPLE_RESOLVE | | | | | |
	//                                            MULTISAMPLE_8X | | | | | | |
	//                                          MULTISAMPLE_4X | | | | | | | |
	//                                        MULTISAMPLE_2X | | | | | | | | |
	//                                               BLEND | | | | | | | | | |
	//                          DEPTH_STENCIL_ATTACHMENT | | | | | | | | | | |
	//                                COLOR_ATTACHMENT | | | | | | | | | | | |
	//                       STORAGE_TEXTURE_ATOMICS | | | | | | | | | | | | |
	//                             STORAGE_TEXTURE | | | | | | | | | | | | | |
	//                                   TEXTURE | | | | | | | | | | | | | | |
	//                                         | | | | | | | | | | | | | | | |
	RG16_UINT            = 23,  // |      FormatSupportBits      |

	// left -> right : low -> high bits
	// Expected (but not guaranteed) "FormatSupportBits" are provided, but "GetFormatSupport" should be used for querying real HW support
	// To demote sRGB use the previous format, i.e. "format - 1"
	//                                            STORAGE_WRITE_WITHOUT_FORMAT
	//                                           STORAGE_READ_WITHOUT_FORMAT |
	//                                                       VERTEX_BUFFER | |
	//                                            STORAGE_BUFFER_ATOMICS | | |
	//                                                  STORAGE_BUFFER | | | |
	//                                                        BUFFER | | | | |
	//                                         MULTISAMPLE_RESOLVE | | | | | |
	//                                            MULTISAMPLE_8X | | | | | | |
	//                                          MULTISAMPLE_4X | | | | | | | |
	//                                        MULTISAMPLE_2X | | | | | | | | |
	//                                               BLEND | | | | | | | | | |
	//                          DEPTH_STENCIL_ATTACHMENT | | | | | | | | | | |
	//                                COLOR_ATTACHMENT | | | | | | | | | | | |
	//                       STORAGE_TEXTURE_ATOMICS | | | | | | | | | | | | |
	//                             STORAGE_TEXTURE | | | | | | | | | | | | | |
	//                                   TEXTURE | | | | | | | | | | | | | | |
	//                                         | | | | | | | | | | | | | | | |
	RG16_SINT            = 24,  // |      FormatSupportBits      |

	// left -> right : low -> high bits
	// Expected (but not guaranteed) "FormatSupportBits" are provided, but "GetFormatSupport" should be used for querying real HW support
	// To demote sRGB use the previous format, i.e. "format - 1"
	//                                            STORAGE_WRITE_WITHOUT_FORMAT
	//                                           STORAGE_READ_WITHOUT_FORMAT |
	//                                                       VERTEX_BUFFER | |
	//                                            STORAGE_BUFFER_ATOMICS | | |
	//                                                  STORAGE_BUFFER | | | |
	//                                                        BUFFER | | | | |
	//                                         MULTISAMPLE_RESOLVE | | | | | |
	//                                            MULTISAMPLE_8X | | | | | | |
	//                                          MULTISAMPLE_4X | | | | | | | |
	//                                        MULTISAMPLE_2X | | | | | | | | |
	//                                               BLEND | | | | | | | | | |
	//                          DEPTH_STENCIL_ATTACHMENT | | | | | | | | | | |
	//                                COLOR_ATTACHMENT | | | | | | | | | | | |
	//                       STORAGE_TEXTURE_ATOMICS | | | | | | | | | | | | |
	//                             STORAGE_TEXTURE | | | | | | | | | | | | | |
	//                                   TEXTURE | | | | | | | | | | | | | | |
	//                                         | | | | | | | | | | | | | | | |
	RG16_SFLOAT          = 25,  // |      FormatSupportBits      |

	// left -> right : low -> high bits
	// Expected (but not guaranteed) "FormatSupportBits" are provided, but "GetFormatSupport" should be used for querying real HW support
	// To demote sRGB use the previous format, i.e. "format - 1"
	//                                            STORAGE_WRITE_WITHOUT_FORMAT
	//                                           STORAGE_READ_WITHOUT_FORMAT |
	//                                                       VERTEX_BUFFER | |
	//                                            STORAGE_BUFFER_ATOMICS | | |
	//                                                  STORAGE_BUFFER | | | |
	//                                                        BUFFER | | | | |
	//                                         MULTISAMPLE_RESOLVE | | | | | |
	//                                            MULTISAMPLE_8X | | | | | | |
	//                                          MULTISAMPLE_4X | | | | | | | |
	//                                        MULTISAMPLE_2X | | | | | | | | |
	//                                               BLEND | | | | | | | | | |
	//                          DEPTH_STENCIL_ATTACHMENT | | | | | | | | | | |
	//                                COLOR_ATTACHMENT | | | | | | | | | | | |
	//                       STORAGE_TEXTURE_ATOMICS | | | | | | | | | | | | |
	//                             STORAGE_TEXTURE | | | | | | | | | | | | | |
	//                                   TEXTURE | | | | | | | | | | | | | | |
	//                                         | | | | | | | | | | | | | | | |
	RGBA16_UNORM         = 26,  // |      FormatSupportBits      |

	// left -> right : low -> high bits
	// Expected (but not guaranteed) "FormatSupportBits" are provided, but "GetFormatSupport" should be used for querying real HW support
	// To demote sRGB use the previous format, i.e. "format - 1"
	//                                            STORAGE_WRITE_WITHOUT_FORMAT
	//                                           STORAGE_READ_WITHOUT_FORMAT |
	//                                                       VERTEX_BUFFER | |
	//                                            STORAGE_BUFFER_ATOMICS | | |
	//                                                  STORAGE_BUFFER | | | |
	//                                                        BUFFER | | | | |
	//                                         MULTISAMPLE_RESOLVE | | | | | |
	//                                            MULTISAMPLE_8X | | | | | | |
	//                                          MULTISAMPLE_4X | | | | | | | |
	//                                        MULTISAMPLE_2X | | | | | | | | |
	//                                               BLEND | | | | | | | | | |
	//                          DEPTH_STENCIL_ATTACHMENT | | | | | | | | | | |
	//                                COLOR_ATTACHMENT | | | | | | | | | | | |
	//                       STORAGE_TEXTURE_ATOMICS | | | | | | | | | | | | |
	//                             STORAGE_TEXTURE | | | | | | | | | | | | | |
	//                                   TEXTURE | | | | | | | | | | | | | | |
	//                                         | | | | | | | | | | | | | | | |
	RGBA16_SNORM         = 27,  // |      FormatSupportBits      |

	// left -> right : low -> high bits
	// Expected (but not guaranteed) "FormatSupportBits" are provided, but "GetFormatSupport" should be used for querying real HW support
	// To demote sRGB use the previous format, i.e. "format - 1"
	//                                            STORAGE_WRITE_WITHOUT_FORMAT
	//                                           STORAGE_READ_WITHOUT_FORMAT |
	//                                                       VERTEX_BUFFER | |
	//                                            STORAGE_BUFFER_ATOMICS | | |
	//                                                  STORAGE_BUFFER | | | |
	//                                                        BUFFER | | | | |
	//                                         MULTISAMPLE_RESOLVE | | | | | |
	//                                            MULTISAMPLE_8X | | | | | | |
	//                                          MULTISAMPLE_4X | | | | | | | |
	//                                        MULTISAMPLE_2X | | | | | | | | |
	//                                               BLEND | | | | | | | | | |
	//                          DEPTH_STENCIL_ATTACHMENT | | | | | | | | | | |
	//                                COLOR_ATTACHMENT | | | | | | | | | | | |
	//                       STORAGE_TEXTURE_ATOMICS | | | | | | | | | | | | |
	//                             STORAGE_TEXTURE | | | | | | | | | | | | | |
	//                                   TEXTURE | | | | | | | | | | | | | | |
	//                                         | | | | | | | | | | | | | | | |
	RGBA16_UINT          = 28,  // |      FormatSupportBits      |

	// left -> right : low -> high bits
	// Expected (but not guaranteed) "FormatSupportBits" are provided, but "GetFormatSupport" should be used for querying real HW support
	// To demote sRGB use the previous format, i.e. "format - 1"
	//                                            STORAGE_WRITE_WITHOUT_FORMAT
	//                                           STORAGE_READ_WITHOUT_FORMAT |
	//                                                       VERTEX_BUFFER | |
	//                                            STORAGE_BUFFER_ATOMICS | | |
	//                                                  STORAGE_BUFFER | | | |
	//                                                        BUFFER | | | | |
	//                                         MULTISAMPLE_RESOLVE | | | | | |
	//                                            MULTISAMPLE_8X | | | | | | |
	//                                          MULTISAMPLE_4X | | | | | | | |
	//                                        MULTISAMPLE_2X | | | | | | | | |
	//                                               BLEND | | | | | | | | | |
	//                          DEPTH_STENCIL_ATTACHMENT | | | | | | | | | | |
	//                                COLOR_ATTACHMENT | | | | | | | | | | | |
	//                       STORAGE_TEXTURE_ATOMICS | | | | | | | | | | | | |
	//                             STORAGE_TEXTURE | | | | | | | | | | | | | |
	//                                   TEXTURE | | | | | | | | | | | | | | |
	//                                         | | | | | | | | | | | | | | | |
	RGBA16_SINT          = 29,  // |      FormatSupportBits      |

	// left -> right : low -> high bits
	// Expected (but not guaranteed) "FormatSupportBits" are provided, but "GetFormatSupport" should be used for querying real HW support
	// To demote sRGB use the previous format, i.e. "format - 1"
	//                                            STORAGE_WRITE_WITHOUT_FORMAT
	//                                           STORAGE_READ_WITHOUT_FORMAT |
	//                                                       VERTEX_BUFFER | |
	//                                            STORAGE_BUFFER_ATOMICS | | |
	//                                                  STORAGE_BUFFER | | | |
	//                                                        BUFFER | | | | |
	//                                         MULTISAMPLE_RESOLVE | | | | | |
	//                                            MULTISAMPLE_8X | | | | | | |
	//                                          MULTISAMPLE_4X | | | | | | | |
	//                                        MULTISAMPLE_2X | | | | | | | | |
	//                                               BLEND | | | | | | | | | |
	//                          DEPTH_STENCIL_ATTACHMENT | | | | | | | | | | |
	//                                COLOR_ATTACHMENT | | | | | | | | | | | |
	//                       STORAGE_TEXTURE_ATOMICS | | | | | | | | | | | | |
	//                             STORAGE_TEXTURE | | | | | | | | | | | | | |
	//                                   TEXTURE | | | | | | | | | | | | | | |
	//                                         | | | | | | | | | | | | | | | |
	RGBA16_SFLOAT        = 30,  // |      FormatSupportBits      |

	// left -> right : low -> high bits
	// Expected (but not guaranteed) "FormatSupportBits" are provided, but "GetFormatSupport" should be used for querying real HW support
	// To demote sRGB use the previous format, i.e. "format - 1"
	//                                            STORAGE_WRITE_WITHOUT_FORMAT
	//                                           STORAGE_READ_WITHOUT_FORMAT |
	//                                                       VERTEX_BUFFER | |
	//                                            STORAGE_BUFFER_ATOMICS | | |
	//                                                  STORAGE_BUFFER | | | |
	//                                                        BUFFER | | | | |
	//                                         MULTISAMPLE_RESOLVE | | | | | |
	//                                            MULTISAMPLE_8X | | | | | | |
	//                                          MULTISAMPLE_4X | | | | | | | |
	//                                        MULTISAMPLE_2X | | | | | | | | |
	//                                               BLEND | | | | | | | | | |
	//                          DEPTH_STENCIL_ATTACHMENT | | | | | | | | | | |
	//                                COLOR_ATTACHMENT | | | | | | | | | | | |
	//                       STORAGE_TEXTURE_ATOMICS | | | | | | | | | | | | |
	//                             STORAGE_TEXTURE | | | | | | | | | | | | | |
	//                                   TEXTURE | | | | | | | | | | | | | | |
	//                                         | | | | | | | | | | | | | | | |
	R32_UINT             = 31,  // |      FormatSupportBits      |

	// left -> right : low -> high bits
	// Expected (but not guaranteed) "FormatSupportBits" are provided, but "GetFormatSupport" should be used for querying real HW support
	// To demote sRGB use the previous format, i.e. "format - 1"
	//                                            STORAGE_WRITE_WITHOUT_FORMAT
	//                                           STORAGE_READ_WITHOUT_FORMAT |
	//                                                       VERTEX_BUFFER | |
	//                                            STORAGE_BUFFER_ATOMICS | | |
	//                                                  STORAGE_BUFFER | | | |
	//                                                        BUFFER | | | | |
	//                                         MULTISAMPLE_RESOLVE | | | | | |
	//                                            MULTISAMPLE_8X | | | | | | |
	//                                          MULTISAMPLE_4X | | | | | | | |
	//                                        MULTISAMPLE_2X | | | | | | | | |
	//                                               BLEND | | | | | | | | | |
	//                          DEPTH_STENCIL_ATTACHMENT | | | | | | | | | | |
	//                                COLOR_ATTACHMENT | | | | | | | | | | | |
	//                       STORAGE_TEXTURE_ATOMICS | | | | | | | | | | | | |
	//                             STORAGE_TEXTURE | | | | | | | | | | | | | |
	//                                   TEXTURE | | | | | | | | | | | | | | |
	//                                         | | | | | | | | | | | | | | | |
	R32_SINT             = 32,  // |      FormatSupportBits      |

	// left -> right : low -> high bits
	// Expected (but not guaranteed) "FormatSupportBits" are provided, but "GetFormatSupport" should be used for querying real HW support
	// To demote sRGB use the previous format, i.e. "format - 1"
	//                                            STORAGE_WRITE_WITHOUT_FORMAT
	//                                           STORAGE_READ_WITHOUT_FORMAT |
	//                                                       VERTEX_BUFFER | |
	//                                            STORAGE_BUFFER_ATOMICS | | |
	//                                                  STORAGE_BUFFER | | | |
	//                                                        BUFFER | | | | |
	//                                         MULTISAMPLE_RESOLVE | | | | | |
	//                                            MULTISAMPLE_8X | | | | | | |
	//                                          MULTISAMPLE_4X | | | | | | | |
	//                                        MULTISAMPLE_2X | | | | | | | | |
	//                                               BLEND | | | | | | | | | |
	//                          DEPTH_STENCIL_ATTACHMENT | | | | | | | | | | |
	//                                COLOR_ATTACHMENT | | | | | | | | | | | |
	//                       STORAGE_TEXTURE_ATOMICS | | | | | | | | | | | | |
	//                             STORAGE_TEXTURE | | | | | | | | | | | | | |
	//                                   TEXTURE | | | | | | | | | | | | | | |
	//                                         | | | | | | | | | | | | | | | |
	R32_SFLOAT           = 33,  // |      FormatSupportBits      |

	// left -> right : low -> high bits
	// Expected (but not guaranteed) "FormatSupportBits" are provided, but "GetFormatSupport" should be used for querying real HW support
	// To demote sRGB use the previous format, i.e. "format - 1"
	//                                            STORAGE_WRITE_WITHOUT_FORMAT
	//                                           STORAGE_READ_WITHOUT_FORMAT |
	//                                                       VERTEX_BUFFER | |
	//                                            STORAGE_BUFFER_ATOMICS | | |
	//                                                  STORAGE_BUFFER | | | |
	//                                                        BUFFER | | | | |
	//                                         MULTISAMPLE_RESOLVE | | | | | |
	//                                            MULTISAMPLE_8X | | | | | | |
	//                                          MULTISAMPLE_4X | | | | | | | |
	//                                        MULTISAMPLE_2X | | | | | | | | |
	//                                               BLEND | | | | | | | | | |
	//                          DEPTH_STENCIL_ATTACHMENT | | | | | | | | | | |
	//                                COLOR_ATTACHMENT | | | | | | | | | | | |
	//                       STORAGE_TEXTURE_ATOMICS | | | | | | | | | | | | |
	//                             STORAGE_TEXTURE | | | | | | | | | | | | | |
	//                                   TEXTURE | | | | | | | | | | | | | | |
	//                                         | | | | | | | | | | | | | | | |
	RG32_UINT            = 34,  // |      FormatSupportBits      |

	// left -> right : low -> high bits
	// Expected (but not guaranteed) "FormatSupportBits" are provided, but "GetFormatSupport" should be used for querying real HW support
	// To demote sRGB use the previous format, i.e. "format - 1"
	//                                            STORAGE_WRITE_WITHOUT_FORMAT
	//                                           STORAGE_READ_WITHOUT_FORMAT |
	//                                                       VERTEX_BUFFER | |
	//                                            STORAGE_BUFFER_ATOMICS | | |
	//                                                  STORAGE_BUFFER | | | |
	//                                                        BUFFER | | | | |
	//                                         MULTISAMPLE_RESOLVE | | | | | |
	//                                            MULTISAMPLE_8X | | | | | | |
	//                                          MULTISAMPLE_4X | | | | | | | |
	//                                        MULTISAMPLE_2X | | | | | | | | |
	//                                               BLEND | | | | | | | | | |
	//                          DEPTH_STENCIL_ATTACHMENT | | | | | | | | | | |
	//                                COLOR_ATTACHMENT | | | | | | | | | | | |
	//                       STORAGE_TEXTURE_ATOMICS | | | | | | | | | | | | |
	//                             STORAGE_TEXTURE | | | | | | | | | | | | | |
	//                                   TEXTURE | | | | | | | | | | | | | | |
	//                                         | | | | | | | | | | | | | | | |
	RG32_SINT            = 35,  // |      FormatSupportBits      |

	// left -> right : low -> high bits
	// Expected (but not guaranteed) "FormatSupportBits" are provided, but "GetFormatSupport" should be used for querying real HW support
	// To demote sRGB use the previous format, i.e. "format - 1"
	//                                            STORAGE_WRITE_WITHOUT_FORMAT
	//                                           STORAGE_READ_WITHOUT_FORMAT |
	//                                                       VERTEX_BUFFER | |
	//                                            STORAGE_BUFFER_ATOMICS | | |
	//                                                  STORAGE_BUFFER | | | |
	//                                                        BUFFER | | | | |
	//                                         MULTISAMPLE_RESOLVE | | | | | |
	//                                            MULTISAMPLE_8X | | | | | | |
	//                                          MULTISAMPLE_4X | | | | | | | |
	//                                        MULTISAMPLE_2X | | | | | | | | |
	//                                               BLEND | | | | | | | | | |
	//                          DEPTH_STENCIL_ATTACHMENT | | | | | | | | | | |
	//                                COLOR_ATTACHMENT | | | | | | | | | | | |
	//                       STORAGE_TEXTURE_ATOMICS | | | | | | | | | | | | |
	//                             STORAGE_TEXTURE | | | | | | | | | | | | | |
	//                                   TEXTURE | | | | | | | | | | | | | | |
	//                                         | | | | | | | | | | | | | | | |
	RG32_SFLOAT          = 36,  // |      FormatSupportBits      |

	// left -> right : low -> high bits
	// Expected (but not guaranteed) "FormatSupportBits" are provided, but "GetFormatSupport" should be used for querying real HW support
	// To demote sRGB use the previous format, i.e. "format - 1"
	//                                            STORAGE_WRITE_WITHOUT_FORMAT
	//                                           STORAGE_READ_WITHOUT_FORMAT |
	//                                                       VERTEX_BUFFER | |
	//                                            STORAGE_BUFFER_ATOMICS | | |
	//                                                  STORAGE_BUFFER | | | |
	//                                                        BUFFER | | | | |
	//                                         MULTISAMPLE_RESOLVE | | | | | |
	//                                            MULTISAMPLE_8X | | | | | | |
	//                                          MULTISAMPLE_4X | | | | | | | |
	//                                        MULTISAMPLE_2X | | | | | | | | |
	//                                               BLEND | | | | | | | | | |
	//                          DEPTH_STENCIL_ATTACHMENT | | | | | | | | | | |
	//                                COLOR_ATTACHMENT | | | | | | | | | | | |
	//                       STORAGE_TEXTURE_ATOMICS | | | | | | | | | | | | |
	//                             STORAGE_TEXTURE | | | | | | | | | | | | | |
	//                                   TEXTURE | | | | | | | | | | | | | | |
	//                                         | | | | | | | | | | | | | | | |
	RGB32_UINT           = 37,  // |      FormatSupportBits      |

	// left -> right : low -> high bits
	// Expected (but not guaranteed) "FormatSupportBits" are provided, but "GetFormatSupport" should be used for querying real HW support
	// To demote sRGB use the previous format, i.e. "format - 1"
	//                                            STORAGE_WRITE_WITHOUT_FORMAT
	//                                           STORAGE_READ_WITHOUT_FORMAT |
	//                                                       VERTEX_BUFFER | |
	//                                            STORAGE_BUFFER_ATOMICS | | |
	//                                                  STORAGE_BUFFER | | | |
	//                                                        BUFFER | | | | |
	//                                         MULTISAMPLE_RESOLVE | | | | | |
	//                                            MULTISAMPLE_8X | | | | | | |
	//                                          MULTISAMPLE_4X | | | | | | | |
	//                                        MULTISAMPLE_2X | | | | | | | | |
	//                                               BLEND | | | | | | | | | |
	//                          DEPTH_STENCIL_ATTACHMENT | | | | | | | | | | |
	//                                COLOR_ATTACHMENT | | | | | | | | | | | |
	//                       STORAGE_TEXTURE_ATOMICS | | | | | | | | | | | | |
	//                             STORAGE_TEXTURE | | | | | | | | | | | | | |
	//                                   TEXTURE | | | | | | | | | | | | | | |
	//                                         | | | | | | | | | | | | | | | |
	RGB32_SINT           = 38,  // |      FormatSupportBits      |

	// left -> right : low -> high bits
	// Expected (but not guaranteed) "FormatSupportBits" are provided, but "GetFormatSupport" should be used for querying real HW support
	// To demote sRGB use the previous format, i.e. "format - 1"
	//                                            STORAGE_WRITE_WITHOUT_FORMAT
	//                                           STORAGE_READ_WITHOUT_FORMAT |
	//                                                       VERTEX_BUFFER | |
	//                                            STORAGE_BUFFER_ATOMICS | | |
	//                                                  STORAGE_BUFFER | | | |
	//                                                        BUFFER | | | | |
	//                                         MULTISAMPLE_RESOLVE | | | | | |
	//                                            MULTISAMPLE_8X | | | | | | |
	//                                          MULTISAMPLE_4X | | | | | | | |
	//                                        MULTISAMPLE_2X | | | | | | | | |
	//                                               BLEND | | | | | | | | | |
	//                          DEPTH_STENCIL_ATTACHMENT | | | | | | | | | | |
	//                                COLOR_ATTACHMENT | | | | | | | | | | | |
	//                       STORAGE_TEXTURE_ATOMICS | | | | | | | | | | | | |
	//                             STORAGE_TEXTURE | | | | | | | | | | | | | |
	//                                   TEXTURE | | | | | | | | | | | | | | |
	//                                         | | | | | | | | | | | | | | | |
	RGB32_SFLOAT         = 39,  // |      FormatSupportBits      |

	// left -> right : low -> high bits
	// Expected (but not guaranteed) "FormatSupportBits" are provided, but "GetFormatSupport" should be used for querying real HW support
	// To demote sRGB use the previous format, i.e. "format - 1"
	//                                            STORAGE_WRITE_WITHOUT_FORMAT
	//                                           STORAGE_READ_WITHOUT_FORMAT |
	//                                                       VERTEX_BUFFER | |
	//                                            STORAGE_BUFFER_ATOMICS | | |
	//                                                  STORAGE_BUFFER | | | |
	//                                                        BUFFER | | | | |
	//                                         MULTISAMPLE_RESOLVE | | | | | |
	//                                            MULTISAMPLE_8X | | | | | | |
	//                                          MULTISAMPLE_4X | | | | | | | |
	//                                        MULTISAMPLE_2X | | | | | | | | |
	//                                               BLEND | | | | | | | | | |
	//                          DEPTH_STENCIL_ATTACHMENT | | | | | | | | | | |
	//                                COLOR_ATTACHMENT | | | | | | | | | | | |
	//                       STORAGE_TEXTURE_ATOMICS | | | | | | | | | | | | |
	//                             STORAGE_TEXTURE | | | | | | | | | | | | | |
	//                                   TEXTURE | | | | | | | | | | | | | | |
	//                                         | | | | | | | | | | | | | | | |
	RGBA32_UINT          = 40,  // |      FormatSupportBits      |

	// left -> right : low -> high bits
	// Expected (but not guaranteed) "FormatSupportBits" are provided, but "GetFormatSupport" should be used for querying real HW support
	// To demote sRGB use the previous format, i.e. "format - 1"
	//                                            STORAGE_WRITE_WITHOUT_FORMAT
	//                                           STORAGE_READ_WITHOUT_FORMAT |
	//                                                       VERTEX_BUFFER | |
	//                                            STORAGE_BUFFER_ATOMICS | | |
	//                                                  STORAGE_BUFFER | | | |
	//                                                        BUFFER | | | | |
	//                                         MULTISAMPLE_RESOLVE | | | | | |
	//                                            MULTISAMPLE_8X | | | | | | |
	//                                          MULTISAMPLE_4X | | | | | | | |
	//                                        MULTISAMPLE_2X | | | | | | | | |
	//                                               BLEND | | | | | | | | | |
	//                          DEPTH_STENCIL_ATTACHMENT | | | | | | | | | | |
	//                                COLOR_ATTACHMENT | | | | | | | | | | | |
	//                       STORAGE_TEXTURE_ATOMICS | | | | | | | | | | | | |
	//                             STORAGE_TEXTURE | | | | | | | | | | | | | |
	//                                   TEXTURE | | | | | | | | | | | | | | |
	//                                         | | | | | | | | | | | | | | | |
	RGBA32_SINT          = 41,  // |      FormatSupportBits      |

	// left -> right : low -> high bits
	// Expected (but not guaranteed) "FormatSupportBits" are provided, but "GetFormatSupport" should be used for querying real HW support
	// To demote sRGB use the previous format, i.e. "format - 1"
	//                                            STORAGE_WRITE_WITHOUT_FORMAT
	//                                           STORAGE_READ_WITHOUT_FORMAT |
	//                                                       VERTEX_BUFFER | |
	//                                            STORAGE_BUFFER_ATOMICS | | |
	//                                                  STORAGE_BUFFER | | | |
	//                                                        BUFFER | | | | |
	//                                         MULTISAMPLE_RESOLVE | | | | | |
	//                                            MULTISAMPLE_8X | | | | | | |
	//                                          MULTISAMPLE_4X | | | | | | | |
	//                                        MULTISAMPLE_2X | | | | | | | | |
	//                                               BLEND | | | | | | | | | |
	//                          DEPTH_STENCIL_ATTACHMENT | | | | | | | | | | |
	//                                COLOR_ATTACHMENT | | | | | | | | | | | |
	//                       STORAGE_TEXTURE_ATOMICS | | | | | | | | | | | | |
	//                             STORAGE_TEXTURE | | | | | | | | | | | | | |
	//                                   TEXTURE | | | | | | | | | | | | | | |
	//                                         | | | | | | | | | | | | | | | |
	RGBA32_SFLOAT        = 42,  // |      FormatSupportBits      |

	// left -> right : low -> high bits
	// Expected (but not guaranteed) "FormatSupportBits" are provided, but "GetFormatSupport" should be used for querying real HW support
	// To demote sRGB use the previous format, i.e. "format - 1"
	//                                            STORAGE_WRITE_WITHOUT_FORMAT
	//                                           STORAGE_READ_WITHOUT_FORMAT |
	//                                                       VERTEX_BUFFER | |
	//                                            STORAGE_BUFFER_ATOMICS | | |
	//                                                  STORAGE_BUFFER | | | |
	//                                                        BUFFER | | | | |
	//                                         MULTISAMPLE_RESOLVE | | | | | |
	//                                            MULTISAMPLE_8X | | | | | | |
	//                                          MULTISAMPLE_4X | | | | | | | |
	//                                        MULTISAMPLE_2X | | | | | | | | |
	//                                               BLEND | | | | | | | | | |
	//                          DEPTH_STENCIL_ATTACHMENT | | | | | | | | | | |
	//                                COLOR_ATTACHMENT | | | | | | | | | | | |
	//                       STORAGE_TEXTURE_ATOMICS | | | | | | | | | | | | |
	//                             STORAGE_TEXTURE | | | | | | | | | | | | | |
	//                                   TEXTURE | | | | | | | | | | | | | | |
	//                                         | | | | | | | | | | | | | | | |
	B5_G6_R5_UNORM       = 43,  // |      FormatSupportBits      |

	// left -> right : low -> high bits
	// Expected (but not guaranteed) "FormatSupportBits" are provided, but "GetFormatSupport" should be used for querying real HW support
	// To demote sRGB use the previous format, i.e. "format - 1"
	//                                            STORAGE_WRITE_WITHOUT_FORMAT
	//                                           STORAGE_READ_WITHOUT_FORMAT |
	//                                                       VERTEX_BUFFER | |
	//                                            STORAGE_BUFFER_ATOMICS | | |
	//                                                  STORAGE_BUFFER | | | |
	//                                                        BUFFER | | | | |
	//                                         MULTISAMPLE_RESOLVE | | | | | |
	//                                            MULTISAMPLE_8X | | | | | | |
	//                                          MULTISAMPLE_4X | | | | | | | |
	//                                        MULTISAMPLE_2X | | | | | | | | |
	//                                               BLEND | | | | | | | | | |
	//                          DEPTH_STENCIL_ATTACHMENT | | | | | | | | | | |
	//                                COLOR_ATTACHMENT | | | | | | | | | | | |
	//                       STORAGE_TEXTURE_ATOMICS | | | | | | | | | | | | |
	//                             STORAGE_TEXTURE | | | | | | | | | | | | | |
	//                                   TEXTURE | | | | | | | | | | | | | | |
	//                                         | | | | | | | | | | | | | | | |
	B5_G5_R5_A1_UNORM    = 44,  // |      FormatSupportBits      |

	// left -> right : low -> high bits
	// Expected (but not guaranteed) "FormatSupportBits" are provided, but "GetFormatSupport" should be used for querying real HW support
	// To demote sRGB use the previous format, i.e. "format - 1"
	//                                            STORAGE_WRITE_WITHOUT_FORMAT
	//                                           STORAGE_READ_WITHOUT_FORMAT |
	//                                                       VERTEX_BUFFER | |
	//                                            STORAGE_BUFFER_ATOMICS | | |
	//                                                  STORAGE_BUFFER | | | |
	//                                                        BUFFER | | | | |
	//                                         MULTISAMPLE_RESOLVE | | | | | |
	//                                            MULTISAMPLE_8X | | | | | | |
	//                                          MULTISAMPLE_4X | | | | | | | |
	//                                        MULTISAMPLE_2X | | | | | | | | |
	//                                               BLEND | | | | | | | | | |
	//                          DEPTH_STENCIL_ATTACHMENT | | | | | | | | | | |
	//                                COLOR_ATTACHMENT | | | | | | | | | | | |
	//                       STORAGE_TEXTURE_ATOMICS | | | | | | | | | | | | |
	//                             STORAGE_TEXTURE | | | | | | | | | | | | | |
	//                                   TEXTURE | | | | | | | | | | | | | | |
	//                                         | | | | | | | | | | | | | | | |
	B4_G4_R4_A4_UNORM    = 45,  // |      FormatSupportBits      |

	// left -> right : low -> high bits
	// Expected (but not guaranteed) "FormatSupportBits" are provided, but "GetFormatSupport" should be used for querying real HW support
	// To demote sRGB use the previous format, i.e. "format - 1"
	//                                            STORAGE_WRITE_WITHOUT_FORMAT
	//                                           STORAGE_READ_WITHOUT_FORMAT |
	//                                                       VERTEX_BUFFER | |
	//                                            STORAGE_BUFFER_ATOMICS | | |
	//                                                  STORAGE_BUFFER | | | |
	//                                                        BUFFER | | | | |
	//                                         MULTISAMPLE_RESOLVE | | | | | |
	//                                            MULTISAMPLE_8X | | | | | | |
	//                                          MULTISAMPLE_4X | | | | | | | |
	//                                        MULTISAMPLE_2X | | | | | | | | |
	//                                               BLEND | | | | | | | | | |
	//                          DEPTH_STENCIL_ATTACHMENT | | | | | | | | | | |
	//                                COLOR_ATTACHMENT | | | | | | | | | | | |
	//                       STORAGE_TEXTURE_ATOMICS | | | | | | | | | | | | |
	//                             STORAGE_TEXTURE | | | | | | | | | | | | | |
	//                                   TEXTURE | | | | | | | | | | | | | | |
	//                                         | | | | | | | | | | | | | | | |
	R10_G10_B10_A2_UNORM = 46,  // |      FormatSupportBits      |

	// left -> right : low -> high bits
	// Expected (but not guaranteed) "FormatSupportBits" are provided, but "GetFormatSupport" should be used for querying real HW support
	// To demote sRGB use the previous format, i.e. "format - 1"
	//                                            STORAGE_WRITE_WITHOUT_FORMAT
	//                                           STORAGE_READ_WITHOUT_FORMAT |
	//                                                       VERTEX_BUFFER | |
	//                                            STORAGE_BUFFER_ATOMICS | | |
	//                                                  STORAGE_BUFFER | | | |
	//                                                        BUFFER | | | | |
	//                                         MULTISAMPLE_RESOLVE | | | | | |
	//                                            MULTISAMPLE_8X | | | | | | |
	//                                          MULTISAMPLE_4X | | | | | | | |
	//                                        MULTISAMPLE_2X | | | | | | | | |
	//                                               BLEND | | | | | | | | | |
	//                          DEPTH_STENCIL_ATTACHMENT | | | | | | | | | | |
	//                                COLOR_ATTACHMENT | | | | | | | | | | | |
	//                       STORAGE_TEXTURE_ATOMICS | | | | | | | | | | | | |
	//                             STORAGE_TEXTURE | | | | | | | | | | | | | |
	//                                   TEXTURE | | | | | | | | | | | | | | |
	//                                         | | | | | | | | | | | | | | | |
	R10_G10_B10_A2_UINT  = 47,  // |      FormatSupportBits      |

	// left -> right : low -> high bits
	// Expected (but not guaranteed) "FormatSupportBits" are provided, but "GetFormatSupport" should be used for querying real HW support
	// To demote sRGB use the previous format, i.e. "format - 1"
	//                                            STORAGE_WRITE_WITHOUT_FORMAT
	//                                           STORAGE_READ_WITHOUT_FORMAT |
	//                                                       VERTEX_BUFFER | |
	//                                            STORAGE_BUFFER_ATOMICS | | |
	//                                                  STORAGE_BUFFER | | | |
	//                                                        BUFFER | | | | |
	//                                         MULTISAMPLE_RESOLVE | | | | | |
	//                                            MULTISAMPLE_8X | | | | | | |
	//                                          MULTISAMPLE_4X | | | | | | | |
	//                                        MULTISAMPLE_2X | | | | | | | | |
	//                                               BLEND | | | | | | | | | |
	//                          DEPTH_STENCIL_ATTACHMENT | | | | | | | | | | |
	//                                COLOR_ATTACHMENT | | | | | | | | | | | |
	//                       STORAGE_TEXTURE_ATOMICS | | | | | | | | | | | | |
	//                             STORAGE_TEXTURE | | | | | | | | | | | | | |
	//                                   TEXTURE | | | | | | | | | | | | | | |
	//                                         | | | | | | | | | | | | | | | |
	R11_G11_B10_UFLOAT   = 48,  // |      FormatSupportBits      |

	// left -> right : low -> high bits
	// Expected (but not guaranteed) "FormatSupportBits" are provided, but "GetFormatSupport" should be used for querying real HW support
	// To demote sRGB use the previous format, i.e. "format - 1"
	//                                            STORAGE_WRITE_WITHOUT_FORMAT
	//                                           STORAGE_READ_WITHOUT_FORMAT |
	//                                                       VERTEX_BUFFER | |
	//                                            STORAGE_BUFFER_ATOMICS | | |
	//                                                  STORAGE_BUFFER | | | |
	//                                                        BUFFER | | | | |
	//                                         MULTISAMPLE_RESOLVE | | | | | |
	//                                            MULTISAMPLE_8X | | | | | | |
	//                                          MULTISAMPLE_4X | | | | | | | |
	//                                        MULTISAMPLE_2X | | | | | | | | |
	//                                               BLEND | | | | | | | | | |
	//                          DEPTH_STENCIL_ATTACHMENT | | | | | | | | | | |
	//                                COLOR_ATTACHMENT | | | | | | | | | | | |
	//                       STORAGE_TEXTURE_ATOMICS | | | | | | | | | | | | |
	//                             STORAGE_TEXTURE | | | | | | | | | | | | | |
	//                                   TEXTURE | | | | | | | | | | | | | | |
	//                                         | | | | | | | | | | | | | | | |
	R9_G9_B9_E5_UFLOAT   = 49,  // |      FormatSupportBits      |

	// left -> right : low -> high bits
	// Expected (but not guaranteed) "FormatSupportBits" are provided, but "GetFormatSupport" should be used for querying real HW support
	// To demote sRGB use the previous format, i.e. "format - 1"
	//                                            STORAGE_WRITE_WITHOUT_FORMAT
	//                                           STORAGE_READ_WITHOUT_FORMAT |
	//                                                       VERTEX_BUFFER | |
	//                                            STORAGE_BUFFER_ATOMICS | | |
	//                                                  STORAGE_BUFFER | | | |
	//                                                        BUFFER | | | | |
	//                                         MULTISAMPLE_RESOLVE | | | | | |
	//                                            MULTISAMPLE_8X | | | | | | |
	//                                          MULTISAMPLE_4X | | | | | | | |
	//                                        MULTISAMPLE_2X | | | | | | | | |
	//                                               BLEND | | | | | | | | | |
	//                          DEPTH_STENCIL_ATTACHMENT | | | | | | | | | | |
	//                                COLOR_ATTACHMENT | | | | | | | | | | | |
	//                       STORAGE_TEXTURE_ATOMICS | | | | | | | | | | | | |
	//                             STORAGE_TEXTURE | | | | | | | | | | | | | |
	//                                   TEXTURE | | | | | | | | | | | | | | |
	//                                         | | | | | | | | | | | | | | | |
	BC1_RGBA_UNORM       = 50,  // |      FormatSupportBits      |

	// left -> right : low -> high bits
	// Expected (but not guaranteed) "FormatSupportBits" are provided, but "GetFormatSupport" should be used for querying real HW support
	// To demote sRGB use the previous format, i.e. "format - 1"
	//                                            STORAGE_WRITE_WITHOUT_FORMAT
	//                                           STORAGE_READ_WITHOUT_FORMAT |
	//                                                       VERTEX_BUFFER | |
	//                                            STORAGE_BUFFER_ATOMICS | | |
	//                                                  STORAGE_BUFFER | | | |
	//                                                        BUFFER | | | | |
	//                                         MULTISAMPLE_RESOLVE | | | | | |
	//                                            MULTISAMPLE_8X | | | | | | |
	//                                          MULTISAMPLE_4X | | | | | | | |
	//                                        MULTISAMPLE_2X | | | | | | | | |
	//                                               BLEND | | | | | | | | | |
	//                          DEPTH_STENCIL_ATTACHMENT | | | | | | | | | | |
	//                                COLOR_ATTACHMENT | | | | | | | | | | | |
	//                       STORAGE_TEXTURE_ATOMICS | | | | | | | | | | | | |
	//                             STORAGE_TEXTURE | | | | | | | | | | | | | |
	//                                   TEXTURE | | | | | | | | | | | | | | |
	//                                         | | | | | | | | | | | | | | | |
	BC1_RGBA_SRGB        = 51,  // |      FormatSupportBits      |

	// left -> right : low -> high bits
	// Expected (but not guaranteed) "FormatSupportBits" are provided, but "GetFormatSupport" should be used for querying real HW support
	// To demote sRGB use the previous format, i.e. "format - 1"
	//                                            STORAGE_WRITE_WITHOUT_FORMAT
	//                                           STORAGE_READ_WITHOUT_FORMAT |
	//                                                       VERTEX_BUFFER | |
	//                                            STORAGE_BUFFER_ATOMICS | | |
	//                                                  STORAGE_BUFFER | | | |
	//                                                        BUFFER | | | | |
	//                                         MULTISAMPLE_RESOLVE | | | | | |
	//                                            MULTISAMPLE_8X | | | | | | |
	//                                          MULTISAMPLE_4X | | | | | | | |
	//                                        MULTISAMPLE_2X | | | | | | | | |
	//                                               BLEND | | | | | | | | | |
	//                          DEPTH_STENCIL_ATTACHMENT | | | | | | | | | | |
	//                                COLOR_ATTACHMENT | | | | | | | | | | | |
	//                       STORAGE_TEXTURE_ATOMICS | | | | | | | | | | | | |
	//                             STORAGE_TEXTURE | | | | | | | | | | | | | |
	//                                   TEXTURE | | | | | | | | | | | | | | |
	//                                         | | | | | | | | | | | | | | | |
	BC2_RGBA_UNORM       = 52,  // |      FormatSupportBits      |

	// left -> right : low -> high bits
	// Expected (but not guaranteed) "FormatSupportBits" are provided, but "GetFormatSupport" should be used for querying real HW support
	// To demote sRGB use the previous format, i.e. "format - 1"
	//                                            STORAGE_WRITE_WITHOUT_FORMAT
	//                                           STORAGE_READ_WITHOUT_FORMAT |
	//                                                       VERTEX_BUFFER | |
	//                                            STORAGE_BUFFER_ATOMICS | | |
	//                                                  STORAGE_BUFFER | | | |
	//                                                        BUFFER | | | | |
	//                                         MULTISAMPLE_RESOLVE | | | | | |
	//                                            MULTISAMPLE_8X | | | | | | |
	//                                          MULTISAMPLE_4X | | | | | | | |
	//                                        MULTISAMPLE_2X | | | | | | | | |
	//                                               BLEND | | | | | | | | | |
	//                          DEPTH_STENCIL_ATTACHMENT | | | | | | | | | | |
	//                                COLOR_ATTACHMENT | | | | | | | | | | | |
	//                       STORAGE_TEXTURE_ATOMICS | | | | | | | | | | | | |
	//                             STORAGE_TEXTURE | | | | | | | | | | | | | |
	//                                   TEXTURE | | | | | | | | | | | | | | |
	//                                         | | | | | | | | | | | | | | | |
	BC2_RGBA_SRGB        = 53,  // |      FormatSupportBits      |

	// left -> right : low -> high bits
	// Expected (but not guaranteed) "FormatSupportBits" are provided, but "GetFormatSupport" should be used for querying real HW support
	// To demote sRGB use the previous format, i.e. "format - 1"
	//                                            STORAGE_WRITE_WITHOUT_FORMAT
	//                                           STORAGE_READ_WITHOUT_FORMAT |
	//                                                       VERTEX_BUFFER | |
	//                                            STORAGE_BUFFER_ATOMICS | | |
	//                                                  STORAGE_BUFFER | | | |
	//                                                        BUFFER | | | | |
	//                                         MULTISAMPLE_RESOLVE | | | | | |
	//                                            MULTISAMPLE_8X | | | | | | |
	//                                          MULTISAMPLE_4X | | | | | | | |
	//                                        MULTISAMPLE_2X | | | | | | | | |
	//                                               BLEND | | | | | | | | | |
	//                          DEPTH_STENCIL_ATTACHMENT | | | | | | | | | | |
	//                                COLOR_ATTACHMENT | | | | | | | | | | | |
	//                       STORAGE_TEXTURE_ATOMICS | | | | | | | | | | | | |
	//                             STORAGE_TEXTURE | | | | | | | | | | | | | |
	//                                   TEXTURE | | | | | | | | | | | | | | |
	//                                         | | | | | | | | | | | | | | | |
	BC3_RGBA_UNORM       = 54,  // |      FormatSupportBits      |

	// left -> right : low -> high bits
	// Expected (but not guaranteed) "FormatSupportBits" are provided, but "GetFormatSupport" should be used for querying real HW support
	// To demote sRGB use the previous format, i.e. "format - 1"
	//                                            STORAGE_WRITE_WITHOUT_FORMAT
	//                                           STORAGE_READ_WITHOUT_FORMAT |
	//                                                       VERTEX_BUFFER | |
	//                                            STORAGE_BUFFER_ATOMICS | | |
	//                                                  STORAGE_BUFFER | | | |
	//                                                        BUFFER | | | | |
	//                                         MULTISAMPLE_RESOLVE | | | | | |
	//                                            MULTISAMPLE_8X | | | | | | |
	//                                          MULTISAMPLE_4X | | | | | | | |
	//                                        MULTISAMPLE_2X | | | | | | | | |
	//                                               BLEND | | | | | | | | | |
	//                          DEPTH_STENCIL_ATTACHMENT | | | | | | | | | | |
	//                                COLOR_ATTACHMENT | | | | | | | | | | | |
	//                       STORAGE_TEXTURE_ATOMICS | | | | | | | | | | | | |
	//                             STORAGE_TEXTURE | | | | | | | | | | | | | |
	//                                   TEXTURE | | | | | | | | | | | | | | |
	//                                         | | | | | | | | | | | | | | | |
	BC3_RGBA_SRGB        = 55,  // |      FormatSupportBits      |

	// left -> right : low -> high bits
	// Expected (but not guaranteed) "FormatSupportBits" are provided, but "GetFormatSupport" should be used for querying real HW support
	// To demote sRGB use the previous format, i.e. "format - 1"
	//                                            STORAGE_WRITE_WITHOUT_FORMAT
	//                                           STORAGE_READ_WITHOUT_FORMAT |
	//                                                       VERTEX_BUFFER | |
	//                                            STORAGE_BUFFER_ATOMICS | | |
	//                                                  STORAGE_BUFFER | | | |
	//                                                        BUFFER | | | | |
	//                                         MULTISAMPLE_RESOLVE | | | | | |
	//                                            MULTISAMPLE_8X | | | | | | |
	//                                          MULTISAMPLE_4X | | | | | | | |
	//                                        MULTISAMPLE_2X | | | | | | | | |
	//                                               BLEND | | | | | | | | | |
	//                          DEPTH_STENCIL_ATTACHMENT | | | | | | | | | | |
	//                                COLOR_ATTACHMENT | | | | | | | | | | | |
	//                       STORAGE_TEXTURE_ATOMICS | | | | | | | | | | | | |
	//                             STORAGE_TEXTURE | | | | | | | | | | | | | |
	//                                   TEXTURE | | | | | | | | | | | | | | |
	//                                         | | | | | | | | | | | | | | | |
	BC4_R_UNORM          = 56,  // |      FormatSupportBits      |

	// left -> right : low -> high bits
	// Expected (but not guaranteed) "FormatSupportBits" are provided, but "GetFormatSupport" should be used for querying real HW support
	// To demote sRGB use the previous format, i.e. "format - 1"
	//                                            STORAGE_WRITE_WITHOUT_FORMAT
	//                                           STORAGE_READ_WITHOUT_FORMAT |
	//                                                       VERTEX_BUFFER | |
	//                                            STORAGE_BUFFER_ATOMICS | | |
	//                                                  STORAGE_BUFFER | | | |
	//                                                        BUFFER | | | | |
	//                                         MULTISAMPLE_RESOLVE | | | | | |
	//                                            MULTISAMPLE_8X | | | | | | |
	//                                          MULTISAMPLE_4X | | | | | | | |
	//                                        MULTISAMPLE_2X | | | | | | | | |
	//                                               BLEND | | | | | | | | | |
	//                          DEPTH_STENCIL_ATTACHMENT | | | | | | | | | | |
	//                                COLOR_ATTACHMENT | | | | | | | | | | | |
	//                       STORAGE_TEXTURE_ATOMICS | | | | | | | | | | | | |
	//                             STORAGE_TEXTURE | | | | | | | | | | | | | |
	//                                   TEXTURE | | | | | | | | | | | | | | |
	//                                         | | | | | | | | | | | | | | | |
	BC4_R_SNORM          = 57,  // |      FormatSupportBits      |

	// left -> right : low -> high bits
	// Expected (but not guaranteed) "FormatSupportBits" are provided, but "GetFormatSupport" should be used for querying real HW support
	// To demote sRGB use the previous format, i.e. "format - 1"
	//                                            STORAGE_WRITE_WITHOUT_FORMAT
	//                                           STORAGE_READ_WITHOUT_FORMAT |
	//                                                       VERTEX_BUFFER | |
	//                                            STORAGE_BUFFER_ATOMICS | | |
	//                                                  STORAGE_BUFFER | | | |
	//                                                        BUFFER | | | | |
	//                                         MULTISAMPLE_RESOLVE | | | | | |
	//                                            MULTISAMPLE_8X | | | | | | |
	//                                          MULTISAMPLE_4X | | | | | | | |
	//                                        MULTISAMPLE_2X | | | | | | | | |
	//                                               BLEND | | | | | | | | | |
	//                          DEPTH_STENCIL_ATTACHMENT | | | | | | | | | | |
	//                                COLOR_ATTACHMENT | | | | | | | | | | | |
	//                       STORAGE_TEXTURE_ATOMICS | | | | | | | | | | | | |
	//                             STORAGE_TEXTURE | | | | | | | | | | | | | |
	//                                   TEXTURE | | | | | | | | | | | | | | |
	//                                         | | | | | | | | | | | | | | | |
	BC5_RG_UNORM         = 58,  // |      FormatSupportBits      |

	// left -> right : low -> high bits
	// Expected (but not guaranteed) "FormatSupportBits" are provided, but "GetFormatSupport" should be used for querying real HW support
	// To demote sRGB use the previous format, i.e. "format - 1"
	//                                            STORAGE_WRITE_WITHOUT_FORMAT
	//                                           STORAGE_READ_WITHOUT_FORMAT |
	//                                                       VERTEX_BUFFER | |
	//                                            STORAGE_BUFFER_ATOMICS | | |
	//                                                  STORAGE_BUFFER | | | |
	//                                                        BUFFER | | | | |
	//                                         MULTISAMPLE_RESOLVE | | | | | |
	//                                            MULTISAMPLE_8X | | | | | | |
	//                                          MULTISAMPLE_4X | | | | | | | |
	//                                        MULTISAMPLE_2X | | | | | | | | |
	//                                               BLEND | | | | | | | | | |
	//                          DEPTH_STENCIL_ATTACHMENT | | | | | | | | | | |
	//                                COLOR_ATTACHMENT | | | | | | | | | | | |
	//                       STORAGE_TEXTURE_ATOMICS | | | | | | | | | | | | |
	//                             STORAGE_TEXTURE | | | | | | | | | | | | | |
	//                                   TEXTURE | | | | | | | | | | | | | | |
	//                                         | | | | | | | | | | | | | | | |
	BC5_RG_SNORM         = 59,  // |      FormatSupportBits      |

	// left -> right : low -> high bits
	// Expected (but not guaranteed) "FormatSupportBits" are provided, but "GetFormatSupport" should be used for querying real HW support
	// To demote sRGB use the previous format, i.e. "format - 1"
	//                                            STORAGE_WRITE_WITHOUT_FORMAT
	//                                           STORAGE_READ_WITHOUT_FORMAT |
	//                                                       VERTEX_BUFFER | |
	//                                            STORAGE_BUFFER_ATOMICS | | |
	//                                                  STORAGE_BUFFER | | | |
	//                                                        BUFFER | | | | |
	//                                         MULTISAMPLE_RESOLVE | | | | | |
	//                                            MULTISAMPLE_8X | | | | | | |
	//                                          MULTISAMPLE_4X | | | | | | | |
	//                                        MULTISAMPLE_2X | | | | | | | | |
	//                                               BLEND | | | | | | | | | |
	//                          DEPTH_STENCIL_ATTACHMENT | | | | | | | | | | |
	//                                COLOR_ATTACHMENT | | | | | | | | | | | |
	//                       STORAGE_TEXTURE_ATOMICS | | | | | | | | | | | | |
	//                             STORAGE_TEXTURE | | | | | | | | | | | | | |
	//                                   TEXTURE | | | | | | | | | | | | | | |
	//                                         | | | | | | | | | | | | | | | |
	BC6H_RGB_UFLOAT      = 60,  // |      FormatSupportBits      |

	// left -> right : low -> high bits
	// Expected (but not guaranteed) "FormatSupportBits" are provided, but "GetFormatSupport" should be used for querying real HW support
	// To demote sRGB use the previous format, i.e. "format - 1"
	//                                            STORAGE_WRITE_WITHOUT_FORMAT
	//                                           STORAGE_READ_WITHOUT_FORMAT |
	//                                                       VERTEX_BUFFER | |
	//                                            STORAGE_BUFFER_ATOMICS | | |
	//                                                  STORAGE_BUFFER | | | |
	//                                                        BUFFER | | | | |
	//                                         MULTISAMPLE_RESOLVE | | | | | |
	//                                            MULTISAMPLE_8X | | | | | | |
	//                                          MULTISAMPLE_4X | | | | | | | |
	//                                        MULTISAMPLE_2X | | | | | | | | |
	//                                               BLEND | | | | | | | | | |
	//                          DEPTH_STENCIL_ATTACHMENT | | | | | | | | | | |
	//                                COLOR_ATTACHMENT | | | | | | | | | | | |
	//                       STORAGE_TEXTURE_ATOMICS | | | | | | | | | | | | |
	//                             STORAGE_TEXTURE | | | | | | | | | | | | | |
	//                                   TEXTURE | | | | | | | | | | | | | | |
	//                                         | | | | | | | | | | | | | | | |
	BC6H_RGB_SFLOAT      = 61,  // |      FormatSupportBits      |

	// left -> right : low -> high bits
	// Expected (but not guaranteed) "FormatSupportBits" are provided, but "GetFormatSupport" should be used for querying real HW support
	// To demote sRGB use the previous format, i.e. "format - 1"
	//                                            STORAGE_WRITE_WITHOUT_FORMAT
	//                                           STORAGE_READ_WITHOUT_FORMAT |
	//                                                       VERTEX_BUFFER | |
	//                                            STORAGE_BUFFER_ATOMICS | | |
	//                                                  STORAGE_BUFFER | | | |
	//                                                        BUFFER | | | | |
	//                                         MULTISAMPLE_RESOLVE | | | | | |
	//                                            MULTISAMPLE_8X | | | | | | |
	//                                          MULTISAMPLE_4X | | | | | | | |
	//                                        MULTISAMPLE_2X | | | | | | | | |
	//                                               BLEND | | | | | | | | | |
	//                          DEPTH_STENCIL_ATTACHMENT | | | | | | | | | | |
	//                                COLOR_ATTACHMENT | | | | | | | | | | | |
	//                       STORAGE_TEXTURE_ATOMICS | | | | | | | | | | | | |
	//                             STORAGE_TEXTURE | | | | | | | | | | | | | |
	//                                   TEXTURE | | | | | | | | | | | | | | |
	//                                         | | | | | | | | | | | | | | | |
	BC7_RGBA_UNORM       = 62,  // |      FormatSupportBits      |

	// left -> right : low -> high bits
	// Expected (but not guaranteed) "FormatSupportBits" are provided, but "GetFormatSupport" should be used for querying real HW support
	// To demote sRGB use the previous format, i.e. "format - 1"
	//                                            STORAGE_WRITE_WITHOUT_FORMAT
	//                                           STORAGE_READ_WITHOUT_FORMAT |
	//                                                       VERTEX_BUFFER | |
	//                                            STORAGE_BUFFER_ATOMICS | | |
	//                                                  STORAGE_BUFFER | | | |
	//                                                        BUFFER | | | | |
	//                                         MULTISAMPLE_RESOLVE | | | | | |
	//                                            MULTISAMPLE_8X | | | | | | |
	//                                          MULTISAMPLE_4X | | | | | | | |
	//                                        MULTISAMPLE_2X | | | | | | | | |
	//                                               BLEND | | | | | | | | | |
	//                          DEPTH_STENCIL_ATTACHMENT | | | | | | | | | | |
	//                                COLOR_ATTACHMENT | | | | | | | | | | | |
	//                       STORAGE_TEXTURE_ATOMICS | | | | | | | | | | | | |
	//                             STORAGE_TEXTURE | | | | | | | | | | | | | |
	//                                   TEXTURE | | | | | | | | | | | | | | |
	//                                         | | | | | | | | | | | | | | | |
	BC7_RGBA_SRGB        = 63,  // |      FormatSupportBits      |

	// left -> right : low -> high bits
	// Expected (but not guaranteed) "FormatSupportBits" are provided, but "GetFormatSupport" should be used for querying real HW support
	// To demote sRGB use the previous format, i.e. "format - 1"
	//                                            STORAGE_WRITE_WITHOUT_FORMAT
	//                                           STORAGE_READ_WITHOUT_FORMAT |
	//                                                       VERTEX_BUFFER | |
	//                                            STORAGE_BUFFER_ATOMICS | | |
	//                                                  STORAGE_BUFFER | | | |
	//                                                        BUFFER | | | | |
	//                                         MULTISAMPLE_RESOLVE | | | | | |
	//                                            MULTISAMPLE_8X | | | | | | |
	//                                          MULTISAMPLE_4X | | | | | | | |
	//                                        MULTISAMPLE_2X | | | | | | | | |
	//                                               BLEND | | | | | | | | | |
	//                          DEPTH_STENCIL_ATTACHMENT | | | | | | | | | | |
	//                                COLOR_ATTACHMENT | | | | | | | | | | | |
	//                       STORAGE_TEXTURE_ATOMICS | | | | | | | | | | | | |
	//                             STORAGE_TEXTURE | | | | | | | | | | | | | |
	//                                   TEXTURE | | | | | | | | | | | | | | |
	//                                         | | | | | | | | | | | | | | | |
	ETC2_RGB8_UNORM      = 64,  // |      FormatSupportBits      |

	// left -> right : low -> high bits
	// Expected (but not guaranteed) "FormatSupportBits" are provided, but "GetFormatSupport" should be used for querying real HW support
	// To demote sRGB use the previous format, i.e. "format - 1"
	//                                            STORAGE_WRITE_WITHOUT_FORMAT
	//                                           STORAGE_READ_WITHOUT_FORMAT |
	//                                                       VERTEX_BUFFER | |
	//                                            STORAGE_BUFFER_ATOMICS | | |
	//                                                  STORAGE_BUFFER | | | |
	//                                                        BUFFER | | | | |
	//                                         MULTISAMPLE_RESOLVE | | | | | |
	//                                            MULTISAMPLE_8X | | | | | | |
	//                                          MULTISAMPLE_4X | | | | | | | |
	//                                        MULTISAMPLE_2X | | | | | | | | |
	//                                               BLEND | | | | | | | | | |
	//                          DEPTH_STENCIL_ATTACHMENT | | | | | | | | | | |
	//                                COLOR_ATTACHMENT | | | | | | | | | | | |
	//                       STORAGE_TEXTURE_ATOMICS | | | | | | | | | | | | |
	//                             STORAGE_TEXTURE | | | | | | | | | | | | | |
	//                                   TEXTURE | | | | | | | | | | | | | | |
	//                                         | | | | | | | | | | | | | | | |
	ETC2_RGB8_SRGB       = 65,  // |      FormatSupportBits      |

	// left -> right : low -> high bits
	// Expected (but not guaranteed) "FormatSupportBits" are provided, but "GetFormatSupport" should be used for querying real HW support
	// To demote sRGB use the previous format, i.e. "format - 1"
	//                                            STORAGE_WRITE_WITHOUT_FORMAT
	//                                           STORAGE_READ_WITHOUT_FORMAT |
	//                                                       VERTEX_BUFFER | |
	//                                            STORAGE_BUFFER_ATOMICS | | |
	//                                                  STORAGE_BUFFER | | | |
	//                                                        BUFFER | | | | |
	//                                         MULTISAMPLE_RESOLVE | | | | | |
	//                                            MULTISAMPLE_8X | | | | | | |
	//                                          MULTISAMPLE_4X | | | | | | | |
	//                                        MULTISAMPLE_2X | | | | | | | | |
	//                                               BLEND | | | | | | | | | |
	//                          DEPTH_STENCIL_ATTACHMENT | | | | | | | | | | |
	//                                COLOR_ATTACHMENT | | | | | | | | | | | |
	//                       STORAGE_TEXTURE_ATOMICS | | | | | | | | | | | | |
	//                             STORAGE_TEXTURE | | | | | | | | | | | | | |
	//                                   TEXTURE | | | | | | | | | | | | | | |
	//                                         | | | | | | | | | | | | | | | |
	ETC2_RGB8_A1_UNORM   = 66,  // |      FormatSupportBits      |

	// left -> right : low -> high bits
	// Expected (but not guaranteed) "FormatSupportBits" are provided, but "GetFormatSupport" should be used for querying real HW support
	// To demote sRGB use the previous format, i.e. "format - 1"
	//                                            STORAGE_WRITE_WITHOUT_FORMAT
	//                                           STORAGE_READ_WITHOUT_FORMAT |
	//                                                       VERTEX_BUFFER | |
	//                                            STORAGE_BUFFER_ATOMICS | | |
	//                                                  STORAGE_BUFFER | | | |
	//                                                        BUFFER | | | | |
	//                                         MULTISAMPLE_RESOLVE | | | | | |
	//                                            MULTISAMPLE_8X | | | | | | |
	//                                          MULTISAMPLE_4X | | | | | | | |
	//                                        MULTISAMPLE_2X | | | | | | | | |
	//                                               BLEND | | | | | | | | | |
	//                          DEPTH_STENCIL_ATTACHMENT | | | | | | | | | | |
	//                                COLOR_ATTACHMENT | | | | | | | | | | | |
	//                       STORAGE_TEXTURE_ATOMICS | | | | | | | | | | | | |
	//                             STORAGE_TEXTURE | | | | | | | | | | | | | |
	//                                   TEXTURE | | | | | | | | | | | | | | |
	//                                         | | | | | | | | | | | | | | | |
	ETC2_RGB8_A1_SRGB    = 67,  // |      FormatSupportBits      |

	// left -> right : low -> high bits
	// Expected (but not guaranteed) "FormatSupportBits" are provided, but "GetFormatSupport" should be used for querying real HW support
	// To demote sRGB use the previous format, i.e. "format - 1"
	//                                            STORAGE_WRITE_WITHOUT_FORMAT
	//                                           STORAGE_READ_WITHOUT_FORMAT |
	//                                                       VERTEX_BUFFER | |
	//                                            STORAGE_BUFFER_ATOMICS | | |
	//                                                  STORAGE_BUFFER | | | |
	//                                                        BUFFER | | | | |
	//                                         MULTISAMPLE_RESOLVE | | | | | |
	//                                            MULTISAMPLE_8X | | | | | | |
	//                                          MULTISAMPLE_4X | | | | | | | |
	//                                        MULTISAMPLE_2X | | | | | | | | |
	//                                               BLEND | | | | | | | | | |
	//                          DEPTH_STENCIL_ATTACHMENT | | | | | | | | | | |
	//                                COLOR_ATTACHMENT | | | | | | | | | | | |
	//                       STORAGE_TEXTURE_ATOMICS | | | | | | | | | | | | |
	//                             STORAGE_TEXTURE | | | | | | | | | | | | | |
	//                                   TEXTURE | | | | | | | | | | | | | | |
	//                                         | | | | | | | | | | | | | | | |
	ETC2_RGB8_A8_UNORM   = 68,  // |      FormatSupportBits      |

	// left -> right : low -> high bits
	// Expected (but not guaranteed) "FormatSupportBits" are provided, but "GetFormatSupport" should be used for querying real HW support
	// To demote sRGB use the previous format, i.e. "format - 1"
	//                                            STORAGE_WRITE_WITHOUT_FORMAT
	//                                           STORAGE_READ_WITHOUT_FORMAT |
	//                                                       VERTEX_BUFFER | |
	//                                            STORAGE_BUFFER_ATOMICS | | |
	//                                                  STORAGE_BUFFER | | | |
	//                                                        BUFFER | | | | |
	//                                         MULTISAMPLE_RESOLVE | | | | | |
	//                                            MULTISAMPLE_8X | | | | | | |
	//                                          MULTISAMPLE_4X | | | | | | | |
	//                                        MULTISAMPLE_2X | | | | | | | | |
	//                                               BLEND | | | | | | | | | |
	//                          DEPTH_STENCIL_ATTACHMENT | | | | | | | | | | |
	//                                COLOR_ATTACHMENT | | | | | | | | | | | |
	//                       STORAGE_TEXTURE_ATOMICS | | | | | | | | | | | | |
	//                             STORAGE_TEXTURE | | | | | | | | | | | | | |
	//                                   TEXTURE | | | | | | | | | | | | | | |
	//                                         | | | | | | | | | | | | | | | |
	ETC2_RGB8_A8_SRGB    = 69,  // |      FormatSupportBits      |

	// left -> right : low -> high bits
	// Expected (but not guaranteed) "FormatSupportBits" are provided, but "GetFormatSupport" should be used for querying real HW support
	// To demote sRGB use the previous format, i.e. "format - 1"
	//                                            STORAGE_WRITE_WITHOUT_FORMAT
	//                                           STORAGE_READ_WITHOUT_FORMAT |
	//                                                       VERTEX_BUFFER | |
	//                                            STORAGE_BUFFER_ATOMICS | | |
	//                                                  STORAGE_BUFFER | | | |
	//                                                        BUFFER | | | | |
	//                                         MULTISAMPLE_RESOLVE | | | | | |
	//                                            MULTISAMPLE_8X | | | | | | |
	//                                          MULTISAMPLE_4X | | | | | | | |
	//                                        MULTISAMPLE_2X | | | | | | | | |
	//                                               BLEND | | | | | | | | | |
	//                          DEPTH_STENCIL_ATTACHMENT | | | | | | | | | | |
	//                                COLOR_ATTACHMENT | | | | | | | | | | | |
	//                       STORAGE_TEXTURE_ATOMICS | | | | | | | | | | | | |
	//                             STORAGE_TEXTURE | | | | | | | | | | | | | |
	//                                   TEXTURE | | | | | | | | | | | | | | |
	//                                         | | | | | | | | | | | | | | | |
	ETC2_R11_UNORM       = 70,  // |      FormatSupportBits      |

	// left -> right : low -> high bits
	// Expected (but not guaranteed) "FormatSupportBits" are provided, but "GetFormatSupport" should be used for querying real HW support
	// To demote sRGB use the previous format, i.e. "format - 1"
	//                                            STORAGE_WRITE_WITHOUT_FORMAT
	//                                           STORAGE_READ_WITHOUT_FORMAT |
	//                                                       VERTEX_BUFFER | |
	//                                            STORAGE_BUFFER_ATOMICS | | |
	//                                                  STORAGE_BUFFER | | | |
	//                                                        BUFFER | | | | |
	//                                         MULTISAMPLE_RESOLVE | | | | | |
	//                                            MULTISAMPLE_8X | | | | | | |
	//                                          MULTISAMPLE_4X | | | | | | | |
	//                                        MULTISAMPLE_2X | | | | | | | | |
	//                                               BLEND | | | | | | | | | |
	//                          DEPTH_STENCIL_ATTACHMENT | | | | | | | | | | |
	//                                COLOR_ATTACHMENT | | | | | | | | | | | |
	//                       STORAGE_TEXTURE_ATOMICS | | | | | | | | | | | | |
	//                             STORAGE_TEXTURE | | | | | | | | | | | | | |
	//                                   TEXTURE | | | | | | | | | | | | | | |
	//                                         | | | | | | | | | | | | | | | |
	ETC2_R11_SNORM       = 71,  // |      FormatSupportBits      |

	// left -> right : low -> high bits
	// Expected (but not guaranteed) "FormatSupportBits" are provided, but "GetFormatSupport" should be used for querying real HW support
	// To demote sRGB use the previous format, i.e. "format - 1"
	//                                            STORAGE_WRITE_WITHOUT_FORMAT
	//                                           STORAGE_READ_WITHOUT_FORMAT |
	//                                                       VERTEX_BUFFER | |
	//                                            STORAGE_BUFFER_ATOMICS | | |
	//                                                  STORAGE_BUFFER | | | |
	//                                                        BUFFER | | | | |
	//                                         MULTISAMPLE_RESOLVE | | | | | |
	//                                            MULTISAMPLE_8X | | | | | | |
	//                                          MULTISAMPLE_4X | | | | | | | |
	//                                        MULTISAMPLE_2X | | | | | | | | |
	//                                               BLEND | | | | | | | | | |
	//                          DEPTH_STENCIL_ATTACHMENT | | | | | | | | | | |
	//                                COLOR_ATTACHMENT | | | | | | | | | | | |
	//                       STORAGE_TEXTURE_ATOMICS | | | | | | | | | | | | |
	//                             STORAGE_TEXTURE | | | | | | | | | | | | | |
	//                                   TEXTURE | | | | | | | | | | | | | | |
	//                                         | | | | | | | | | | | | | | | |
	ETC2_R11_G11_UNORM   = 72,  // |      FormatSupportBits      |

	// left -> right : low -> high bits
	// Expected (but not guaranteed) "FormatSupportBits" are provided, but "GetFormatSupport" should be used for querying real HW support
	// To demote sRGB use the previous format, i.e. "format - 1"
	//                                            STORAGE_WRITE_WITHOUT_FORMAT
	//                                           STORAGE_READ_WITHOUT_FORMAT |
	//                                                       VERTEX_BUFFER | |
	//                                            STORAGE_BUFFER_ATOMICS | | |
	//                                                  STORAGE_BUFFER | | | |
	//                                                        BUFFER | | | | |
	//                                         MULTISAMPLE_RESOLVE | | | | | |
	//                                            MULTISAMPLE_8X | | | | | | |
	//                                          MULTISAMPLE_4X | | | | | | | |
	//                                        MULTISAMPLE_2X | | | | | | | | |
	//                                               BLEND | | | | | | | | | |
	//                          DEPTH_STENCIL_ATTACHMENT | | | | | | | | | | |
	//                                COLOR_ATTACHMENT | | | | | | | | | | | |
	//                       STORAGE_TEXTURE_ATOMICS | | | | | | | | | | | | |
	//                             STORAGE_TEXTURE | | | | | | | | | | | | | |
	//                                   TEXTURE | | | | | | | | | | | | | | |
	//                                         | | | | | | | | | | | | | | | |
	ETC2_R11_G11_SNORM   = 73,  // |      FormatSupportBits      |

	// left -> right : low -> high bits
	// Expected (but not guaranteed) "FormatSupportBits" are provided, but "GetFormatSupport" should be used for querying real HW support
	// To demote sRGB use the previous format, i.e. "format - 1"
	//                                            STORAGE_WRITE_WITHOUT_FORMAT
	//                                           STORAGE_READ_WITHOUT_FORMAT |
	//                                                       VERTEX_BUFFER | |
	//                                            STORAGE_BUFFER_ATOMICS | | |
	//                                                  STORAGE_BUFFER | | | |
	//                                                        BUFFER | | | | |
	//                                         MULTISAMPLE_RESOLVE | | | | | |
	//                                            MULTISAMPLE_8X | | | | | | |
	//                                          MULTISAMPLE_4X | | | | | | | |
	//                                        MULTISAMPLE_2X | | | | | | | | |
	//                                               BLEND | | | | | | | | | |
	//                          DEPTH_STENCIL_ATTACHMENT | | | | | | | | | | |
	//                                COLOR_ATTACHMENT | | | | | | | | | | | |
	//                       STORAGE_TEXTURE_ATOMICS | | | | | | | | | | | | |
	//                             STORAGE_TEXTURE | | | | | | | | | | | | | |
	//                                   TEXTURE | | | | | | | | | | | | | | |
	//                                         | | | | | | | | | | | | | | | |
	ASTC_4X4_UNORM       = 74,  // |      FormatSupportBits      |

	// left -> right : low -> high bits
	// Expected (but not guaranteed) "FormatSupportBits" are provided, but "GetFormatSupport" should be used for querying real HW support
	// To demote sRGB use the previous format, i.e. "format - 1"
	//                                            STORAGE_WRITE_WITHOUT_FORMAT
	//                                           STORAGE_READ_WITHOUT_FORMAT |
	//                                                       VERTEX_BUFFER | |
	//                                            STORAGE_BUFFER_ATOMICS | | |
	//                                                  STORAGE_BUFFER | | | |
	//                                                        BUFFER | | | | |
	//                                         MULTISAMPLE_RESOLVE | | | | | |
	//                                            MULTISAMPLE_8X | | | | | | |
	//                                          MULTISAMPLE_4X | | | | | | | |
	//                                        MULTISAMPLE_2X | | | | | | | | |
	//                                               BLEND | | | | | | | | | |
	//                          DEPTH_STENCIL_ATTACHMENT | | | | | | | | | | |
	//                                COLOR_ATTACHMENT | | | | | | | | | | | |
	//                       STORAGE_TEXTURE_ATOMICS | | | | | | | | | | | | |
	//                             STORAGE_TEXTURE | | | | | | | | | | | | | |
	//                                   TEXTURE | | | | | | | | | | | | | | |
	//                                         | | | | | | | | | | | | | | | |
	ASTC_4X4_SRGB        = 75,  // |      FormatSupportBits      |

	// left -> right : low -> high bits
	// Expected (but not guaranteed) "FormatSupportBits" are provided, but "GetFormatSupport" should be used for querying real HW support
	// To demote sRGB use the previous format, i.e. "format - 1"
	//                                            STORAGE_WRITE_WITHOUT_FORMAT
	//                                           STORAGE_READ_WITHOUT_FORMAT |
	//                                                       VERTEX_BUFFER | |
	//                                            STORAGE_BUFFER_ATOMICS | | |
	//                                                  STORAGE_BUFFER | | | |
	//                                                        BUFFER | | | | |
	//                                         MULTISAMPLE_RESOLVE | | | | | |
	//                                            MULTISAMPLE_8X | | | | | | |
	//                                          MULTISAMPLE_4X | | | | | | | |
	//                                        MULTISAMPLE_2X | | | | | | | | |
	//                                               BLEND | | | | | | | | | |
	//                          DEPTH_STENCIL_ATTACHMENT | | | | | | | | | | |
	//                                COLOR_ATTACHMENT | | | | | | | | | | | |
	//                       STORAGE_TEXTURE_ATOMICS | | | | | | | | | | | | |
	//                             STORAGE_TEXTURE | | | | | | | | | | | | | |
	//                                   TEXTURE | | | | | | | | | | | | | | |
	//                                         | | | | | | | | | | | | | | | |
	ASTC_5X4_UNORM       = 76,  // |      FormatSupportBits      |

	// left -> right : low -> high bits
	// Expected (but not guaranteed) "FormatSupportBits" are provided, but "GetFormatSupport" should be used for querying real HW support
	// To demote sRGB use the previous format, i.e. "format - 1"
	//                                            STORAGE_WRITE_WITHOUT_FORMAT
	//                                           STORAGE_READ_WITHOUT_FORMAT |
	//                                                       VERTEX_BUFFER | |
	//                                            STORAGE_BUFFER_ATOMICS | | |
	//                                                  STORAGE_BUFFER | | | |
	//                                                        BUFFER | | | | |
	//                                         MULTISAMPLE_RESOLVE | | | | | |
	//                                            MULTISAMPLE_8X | | | | | | |
	//                                          MULTISAMPLE_4X | | | | | | | |
	//                                        MULTISAMPLE_2X | | | | | | | | |
	//                                               BLEND | | | | | | | | | |
	//                          DEPTH_STENCIL_ATTACHMENT | | | | | | | | | | |
	//                                COLOR_ATTACHMENT | | | | | | | | | | | |
	//                       STORAGE_TEXTURE_ATOMICS | | | | | | | | | | | | |
	//                             STORAGE_TEXTURE | | | | | | | | | | | | | |
	//                                   TEXTURE | | | | | | | | | | | | | | |
	//                                         | | | | | | | | | | | | | | | |
	ASTC_5X4_SRGB        = 77,  // |      FormatSupportBits      |

	// left -> right : low -> high bits
	// Expected (but not guaranteed) "FormatSupportBits" are provided, but "GetFormatSupport" should be used for querying real HW support
	// To demote sRGB use the previous format, i.e. "format - 1"
	//                                            STORAGE_WRITE_WITHOUT_FORMAT
	//                                           STORAGE_READ_WITHOUT_FORMAT |
	//                                                       VERTEX_BUFFER | |
	//                                            STORAGE_BUFFER_ATOMICS | | |
	//                                                  STORAGE_BUFFER | | | |
	//                                                        BUFFER | | | | |
	//                                         MULTISAMPLE_RESOLVE | | | | | |
	//                                            MULTISAMPLE_8X | | | | | | |
	//                                          MULTISAMPLE_4X | | | | | | | |
	//                                        MULTISAMPLE_2X | | | | | | | | |
	//                                               BLEND | | | | | | | | | |
	//                          DEPTH_STENCIL_ATTACHMENT | | | | | | | | | | |
	//                                COLOR_ATTACHMENT | | | | | | | | | | | |
	//                       STORAGE_TEXTURE_ATOMICS | | | | | | | | | | | | |
	//                             STORAGE_TEXTURE | | | | | | | | | | | | | |
	//                                   TEXTURE | | | | | | | | | | | | | | |
	//                                         | | | | | | | | | | | | | | | |
	ASTC_5X5_UNORM       = 78,  // |      FormatSupportBits      |

	// left -> right : low -> high bits
	// Expected (but not guaranteed) "FormatSupportBits" are provided, but "GetFormatSupport" should be used for querying real HW support
	// To demote sRGB use the previous format, i.e. "format - 1"
	//                                            STORAGE_WRITE_WITHOUT_FORMAT
	//                                           STORAGE_READ_WITHOUT_FORMAT |
	//                                                       VERTEX_BUFFER | |
	//                                            STORAGE_BUFFER_ATOMICS | | |
	//                                                  STORAGE_BUFFER | | | |
	//                                                        BUFFER | | | | |
	//                                         MULTISAMPLE_RESOLVE | | | | | |
	//                                            MULTISAMPLE_8X | | | | | | |
	//                                          MULTISAMPLE_4X | | | | | | | |
	//                                        MULTISAMPLE_2X | | | | | | | | |
	//                                               BLEND | | | | | | | | | |
	//                          DEPTH_STENCIL_ATTACHMENT | | | | | | | | | | |
	//                                COLOR_ATTACHMENT | | | | | | | | | | | |
	//                       STORAGE_TEXTURE_ATOMICS | | | | | | | | | | | | |
	//                             STORAGE_TEXTURE | | | | | | | | | | | | | |
	//                                   TEXTURE | | | | | | | | | | | | | | |
	//                                         | | | | | | | | | | | | | | | |
	ASTC_5X5_SRGB        = 79,  // |      FormatSupportBits      |

	// left -> right : low -> high bits
	// Expected (but not guaranteed) "FormatSupportBits" are provided, but "GetFormatSupport" should be used for querying real HW support
	// To demote sRGB use the previous format, i.e. "format - 1"
	//                                            STORAGE_WRITE_WITHOUT_FORMAT
	//                                           STORAGE_READ_WITHOUT_FORMAT |
	//                                                       VERTEX_BUFFER | |
	//                                            STORAGE_BUFFER_ATOMICS | | |
	//                                                  STORAGE_BUFFER | | | |
	//                                                        BUFFER | | | | |
	//                                         MULTISAMPLE_RESOLVE | | | | | |
	//                                            MULTISAMPLE_8X | | | | | | |
	//                                          MULTISAMPLE_4X | | | | | | | |
	//                                        MULTISAMPLE_2X | | | | | | | | |
	//                                               BLEND | | | | | | | | | |
	//                          DEPTH_STENCIL_ATTACHMENT | | | | | | | | | | |
	//                                COLOR_ATTACHMENT | | | | | | | | | | | |
	//                       STORAGE_TEXTURE_ATOMICS | | | | | | | | | | | | |
	//                             STORAGE_TEXTURE | | | | | | | | | | | | | |
	//                                   TEXTURE | | | | | | | | | | | | | | |
	//                                         | | | | | | | | | | | | | | | |
	ASTC_6X5_UNORM       = 80,  // |      FormatSupportBits      |

	// left -> right : low -> high bits
	// Expected (but not guaranteed) "FormatSupportBits" are provided, but "GetFormatSupport" should be used for querying real HW support
	// To demote sRGB use the previous format, i.e. "format - 1"
	//                                            STORAGE_WRITE_WITHOUT_FORMAT
	//                                           STORAGE_READ_WITHOUT_FORMAT |
	//                                                       VERTEX_BUFFER | |
	//                                            STORAGE_BUFFER_ATOMICS | | |
	//                                                  STORAGE_BUFFER | | | |
	//                                                        BUFFER | | | | |
	//                                         MULTISAMPLE_RESOLVE | | | | | |
	//                                            MULTISAMPLE_8X | | | | | | |
	//                                          MULTISAMPLE_4X | | | | | | | |
	//                                        MULTISAMPLE_2X | | | | | | | | |
	//                                               BLEND | | | | | | | | | |
	//                          DEPTH_STENCIL_ATTACHMENT | | | | | | | | | | |
	//                                COLOR_ATTACHMENT | | | | | | | | | | | |
	//                       STORAGE_TEXTURE_ATOMICS | | | | | | | | | | | | |
	//                             STORAGE_TEXTURE | | | | | | | | | | | | | |
	//                                   TEXTURE | | | | | | | | | | | | | | |
	//                                         | | | | | | | | | | | | | | | |
	ASTC_6X5_SRGB        = 81,  // |      FormatSupportBits      |

	// left -> right : low -> high bits
	// Expected (but not guaranteed) "FormatSupportBits" are provided, but "GetFormatSupport" should be used for querying real HW support
	// To demote sRGB use the previous format, i.e. "format - 1"
	//                                            STORAGE_WRITE_WITHOUT_FORMAT
	//                                           STORAGE_READ_WITHOUT_FORMAT |
	//                                                       VERTEX_BUFFER | |
	//                                            STORAGE_BUFFER_ATOMICS | | |
	//                                                  STORAGE_BUFFER | | | |
	//                                                        BUFFER | | | | |
	//                                         MULTISAMPLE_RESOLVE | | | | | |
	//                                            MULTISAMPLE_8X | | | | | | |
	//                                          MULTISAMPLE_4X | | | | | | | |
	//                                        MULTISAMPLE_2X | | | | | | | | |
	//                                               BLEND | | | | | | | | | |
	//                          DEPTH_STENCIL_ATTACHMENT | | | | | | | | | | |
	//                                COLOR_ATTACHMENT | | | | | | | | | | | |
	//                       STORAGE_TEXTURE_ATOMICS | | | | | | | | | | | | |
	//                             STORAGE_TEXTURE | | | | | | | | | | | | | |
	//                                   TEXTURE | | | | | | | | | | | | | | |
	//                                         | | | | | | | | | | | | | | | |
	ASTC_6X6_UNORM       = 82,  // |      FormatSupportBits      |

	// left -> right : low -> high bits
	// Expected (but not guaranteed) "FormatSupportBits" are provided, but "GetFormatSupport" should be used for querying real HW support
	// To demote sRGB use the previous format, i.e. "format - 1"
	//                                            STORAGE_WRITE_WITHOUT_FORMAT
	//                                           STORAGE_READ_WITHOUT_FORMAT |
	//                                                       VERTEX_BUFFER | |
	//                                            STORAGE_BUFFER_ATOMICS | | |
	//                                                  STORAGE_BUFFER | | | |
	//                                                        BUFFER | | | | |
	//                                         MULTISAMPLE_RESOLVE | | | | | |
	//                                            MULTISAMPLE_8X | | | | | | |
	//                                          MULTISAMPLE_4X | | | | | | | |
	//                                        MULTISAMPLE_2X | | | | | | | | |
	//                                               BLEND | | | | | | | | | |
	//                          DEPTH_STENCIL_ATTACHMENT | | | | | | | | | | |
	//                                COLOR_ATTACHMENT | | | | | | | | | | | |
	//                       STORAGE_TEXTURE_ATOMICS | | | | | | | | | | | | |
	//                             STORAGE_TEXTURE | | | | | | | | | | | | | |
	//                                   TEXTURE | | | | | | | | | | | | | | |
	//                                         | | | | | | | | | | | | | | | |
	ASTC_6X6_SRGB        = 83,  // |      FormatSupportBits      |

	// left -> right : low -> high bits
	// Expected (but not guaranteed) "FormatSupportBits" are provided, but "GetFormatSupport" should be used for querying real HW support
	// To demote sRGB use the previous format, i.e. "format - 1"
	//                                            STORAGE_WRITE_WITHOUT_FORMAT
	//                                           STORAGE_READ_WITHOUT_FORMAT |
	//                                                       VERTEX_BUFFER | |
	//                                            STORAGE_BUFFER_ATOMICS | | |
	//                                                  STORAGE_BUFFER | | | |
	//                                                        BUFFER | | | | |
	//                                         MULTISAMPLE_RESOLVE | | | | | |
	//                                            MULTISAMPLE_8X | | | | | | |
	//                                          MULTISAMPLE_4X | | | | | | | |
	//                                        MULTISAMPLE_2X | | | | | | | | |
	//                                               BLEND | | | | | | | | | |
	//                          DEPTH_STENCIL_ATTACHMENT | | | | | | | | | | |
	//                                COLOR_ATTACHMENT | | | | | | | | | | | |
	//                       STORAGE_TEXTURE_ATOMICS | | | | | | | | | | | | |
	//                             STORAGE_TEXTURE | | | | | | | | | | | | | |
	//                                   TEXTURE | | | | | | | | | | | | | | |
	//                                         | | | | | | | | | | | | | | | |
	ASTC_8X5_UNORM       = 84,  // |      FormatSupportBits      |

	// left -> right : low -> high bits
	// Expected (but not guaranteed) "FormatSupportBits" are provided, but "GetFormatSupport" should be used for querying real HW support
	// To demote sRGB use the previous format, i.e. "format - 1"
	//                                            STORAGE_WRITE_WITHOUT_FORMAT
	//                                           STORAGE_READ_WITHOUT_FORMAT |
	//                                                       VERTEX_BUFFER | |
	//                                            STORAGE_BUFFER_ATOMICS | | |
	//                                                  STORAGE_BUFFER | | | |
	//                                                        BUFFER | | | | |
	//                                         MULTISAMPLE_RESOLVE | | | | | |
	//                                            MULTISAMPLE_8X | | | | | | |
	//                                          MULTISAMPLE_4X | | | | | | | |
	//                                        MULTISAMPLE_2X | | | | | | | | |
	//                                               BLEND | | | | | | | | | |
	//                          DEPTH_STENCIL_ATTACHMENT | | | | | | | | | | |
	//                                COLOR_ATTACHMENT | | | | | | | | | | | |
	//                       STORAGE_TEXTURE_ATOMICS | | | | | | | | | | | | |
	//                             STORAGE_TEXTURE | | | | | | | | | | | | | |
	//                                   TEXTURE | | | | | | | | | | | | | | |
	//                                         | | | | | | | | | | | | | | | |
	ASTC_8X5_SRGB        = 85,  // |      FormatSupportBits      |

	// left -> right : low -> high bits
	// Expected (but not guaranteed) "FormatSupportBits" are provided, but "GetFormatSupport" should be used for querying real HW support
	// To demote sRGB use the previous format, i.e. "format - 1"
	//                                            STORAGE_WRITE_WITHOUT_FORMAT
	//                                           STORAGE_READ_WITHOUT_FORMAT |
	//                                                       VERTEX_BUFFER | |
	//                                            STORAGE_BUFFER_ATOMICS | | |
	//                                                  STORAGE_BUFFER | | | |
	//                                                        BUFFER | | | | |
	//                                         MULTISAMPLE_RESOLVE | | | | | |
	//                                            MULTISAMPLE_8X | | | | | | |
	//                                          MULTISAMPLE_4X | | | | | | | |
	//                                        MULTISAMPLE_2X | | | | | | | | |
	//                                               BLEND | | | | | | | | | |
	//                          DEPTH_STENCIL_ATTACHMENT | | | | | | | | | | |
	//                                COLOR_ATTACHMENT | | | | | | | | | | | |
	//                       STORAGE_TEXTURE_ATOMICS | | | | | | | | | | | | |
	//                             STORAGE_TEXTURE | | | | | | | | | | | | | |
	//                                   TEXTURE | | | | | | | | | | | | | | |
	//                                         | | | | | | | | | | | | | | | |
	ASTC_8X6_UNORM       = 86,  // |      FormatSupportBits      |

	// left -> right : low -> high bits
	// Expected (but not guaranteed) "FormatSupportBits" are provided, but "GetFormatSupport" should be used for querying real HW support
	// To demote sRGB use the previous format, i.e. "format - 1"
	//                                            STORAGE_WRITE_WITHOUT_FORMAT
	//                                           STORAGE_READ_WITHOUT_FORMAT |
	//                                                       VERTEX_BUFFER | |
	//                                            STORAGE_BUFFER_ATOMICS | | |
	//                                                  STORAGE_BUFFER | | | |
	//                                                        BUFFER | | | | |
	//                                         MULTISAMPLE_RESOLVE | | | | | |
	//                                            MULTISAMPLE_8X | | | | | | |
	//                                          MULTISAMPLE_4X | | | | | | | |
	//                                        MULTISAMPLE_2X | | | | | | | | |
	//                                               BLEND | | | | | | | | | |
	//                          DEPTH_STENCIL_ATTACHMENT | | | | | | | | | | |
	//                                COLOR_ATTACHMENT | | | | | | | | | | | |
	//                       STORAGE_TEXTURE_ATOMICS | | | | | | | | | | | | |
	//                             STORAGE_TEXTURE | | | | | | | | | | | | | |
	//                                   TEXTURE | | | | | | | | | | | | | | |
	//                                         | | | | | | | | | | | | | | | |
	ASTC_8X6_SRGB        = 87,  // |      FormatSupportBits      |

	// left -> right : low -> high bits
	// Expected (but not guaranteed) "FormatSupportBits" are provided, but "GetFormatSupport" should be used for querying real HW support
	// To demote sRGB use the previous format, i.e. "format - 1"
	//                                            STORAGE_WRITE_WITHOUT_FORMAT
	//                                           STORAGE_READ_WITHOUT_FORMAT |
	//                                                       VERTEX_BUFFER | |
	//                                            STORAGE_BUFFER_ATOMICS | | |
	//                                                  STORAGE_BUFFER | | | |
	//                                                        BUFFER | | | | |
	//                                         MULTISAMPLE_RESOLVE | | | | | |
	//                                            MULTISAMPLE_8X | | | | | | |
	//                                          MULTISAMPLE_4X | | | | | | | |
	//                                        MULTISAMPLE_2X | | | | | | | | |
	//                                               BLEND | | | | | | | | | |
	//                          DEPTH_STENCIL_ATTACHMENT | | | | | | | | | | |
	//                                COLOR_ATTACHMENT | | | | | | | | | | | |
	//                       STORAGE_TEXTURE_ATOMICS | | | | | | | | | | | | |
	//                             STORAGE_TEXTURE | | | | | | | | | | | | | |
	//                                   TEXTURE | | | | | | | | | | | | | | |
	//                                         | | | | | | | | | | | | | | | |
	ASTC_8X8_UNORM       = 88,  // |      FormatSupportBits      |

	// left -> right : low -> high bits
	// Expected (but not guaranteed) "FormatSupportBits" are provided, but "GetFormatSupport" should be used for querying real HW support
	// To demote sRGB use the previous format, i.e. "format - 1"
	//                                            STORAGE_WRITE_WITHOUT_FORMAT
	//                                           STORAGE_READ_WITHOUT_FORMAT |
	//                                                       VERTEX_BUFFER | |
	//                                            STORAGE_BUFFER_ATOMICS | | |
	//                                                  STORAGE_BUFFER | | | |
	//                                                        BUFFER | | | | |
	//                                         MULTISAMPLE_RESOLVE | | | | | |
	//                                            MULTISAMPLE_8X | | | | | | |
	//                                          MULTISAMPLE_4X | | | | | | | |
	//                                        MULTISAMPLE_2X | | | | | | | | |
	//                                               BLEND | | | | | | | | | |
	//                          DEPTH_STENCIL_ATTACHMENT | | | | | | | | | | |
	//                                COLOR_ATTACHMENT | | | | | | | | | | | |
	//                       STORAGE_TEXTURE_ATOMICS | | | | | | | | | | | | |
	//                             STORAGE_TEXTURE | | | | | | | | | | | | | |
	//                                   TEXTURE | | | | | | | | | | | | | | |
	//                                         | | | | | | | | | | | | | | | |
	ASTC_8X8_SRGB        = 89,  // |      FormatSupportBits      |

	// left -> right : low -> high bits
	// Expected (but not guaranteed) "FormatSupportBits" are provided, but "GetFormatSupport" should be used for querying real HW support
	// To demote sRGB use the previous format, i.e. "format - 1"
	//                                            STORAGE_WRITE_WITHOUT_FORMAT
	//                                           STORAGE_READ_WITHOUT_FORMAT |
	//                                                       VERTEX_BUFFER | |
	//                                            STORAGE_BUFFER_ATOMICS | | |
	//                                                  STORAGE_BUFFER | | | |
	//                                                        BUFFER | | | | |
	//                                         MULTISAMPLE_RESOLVE | | | | | |
	//                                            MULTISAMPLE_8X | | | | | | |
	//                                          MULTISAMPLE_4X | | | | | | | |
	//                                        MULTISAMPLE_2X | | | | | | | | |
	//                                               BLEND | | | | | | | | | |
	//                          DEPTH_STENCIL_ATTACHMENT | | | | | | | | | | |
	//                                COLOR_ATTACHMENT | | | | | | | | | | | |
	//                       STORAGE_TEXTURE_ATOMICS | | | | | | | | | | | | |
	//                             STORAGE_TEXTURE | | | | | | | | | | | | | |
	//                                   TEXTURE | | | | | | | | | | | | | | |
	//                                         | | | | | | | | | | | | | | | |
	ASTC_10X5_UNORM      = 90,  // |      FormatSupportBits      |

	// left -> right : low -> high bits
	// Expected (but not guaranteed) "FormatSupportBits" are provided, but "GetFormatSupport" should be used for querying real HW support
	// To demote sRGB use the previous format, i.e. "format - 1"
	//                                            STORAGE_WRITE_WITHOUT_FORMAT
	//                                           STORAGE_READ_WITHOUT_FORMAT |
	//                                                       VERTEX_BUFFER | |
	//                                            STORAGE_BUFFER_ATOMICS | | |
	//                                                  STORAGE_BUFFER | | | |
	//                                                        BUFFER | | | | |
	//                                         MULTISAMPLE_RESOLVE | | | | | |
	//                                            MULTISAMPLE_8X | | | | | | |
	//                                          MULTISAMPLE_4X | | | | | | | |
	//                                        MULTISAMPLE_2X | | | | | | | | |
	//                                               BLEND | | | | | | | | | |
	//                          DEPTH_STENCIL_ATTACHMENT | | | | | | | | | | |
	//                                COLOR_ATTACHMENT | | | | | | | | | | | |
	//                       STORAGE_TEXTURE_ATOMICS | | | | | | | | | | | | |
	//                             STORAGE_TEXTURE | | | | | | | | | | | | | |
	//                                   TEXTURE | | | | | | | | | | | | | | |
	//                                         | | | | | | | | | | | | | | | |
	ASTC_10X5_SRGB       = 91,  // |      FormatSupportBits      |

	// left -> right : low -> high bits
	// Expected (but not guaranteed) "FormatSupportBits" are provided, but "GetFormatSupport" should be used for querying real HW support
	// To demote sRGB use the previous format, i.e. "format - 1"
	//                                            STORAGE_WRITE_WITHOUT_FORMAT
	//                                           STORAGE_READ_WITHOUT_FORMAT |
	//                                                       VERTEX_BUFFER | |
	//                                            STORAGE_BUFFER_ATOMICS | | |
	//                                                  STORAGE_BUFFER | | | |
	//                                                        BUFFER | | | | |
	//                                         MULTISAMPLE_RESOLVE | | | | | |
	//                                            MULTISAMPLE_8X | | | | | | |
	//                                          MULTISAMPLE_4X | | | | | | | |
	//                                        MULTISAMPLE_2X | | | | | | | | |
	//                                               BLEND | | | | | | | | | |
	//                          DEPTH_STENCIL_ATTACHMENT | | | | | | | | | | |
	//                                COLOR_ATTACHMENT | | | | | | | | | | | |
	//                       STORAGE_TEXTURE_ATOMICS | | | | | | | | | | | | |
	//                             STORAGE_TEXTURE | | | | | | | | | | | | | |
	//                                   TEXTURE | | | | | | | | | | | | | | |
	//                                         | | | | | | | | | | | | | | | |
	ASTC_10X6_UNORM      = 92,  // |      FormatSupportBits      |

	// left -> right : low -> high bits
	// Expected (but not guaranteed) "FormatSupportBits" are provided, but "GetFormatSupport" should be used for querying real HW support
	// To demote sRGB use the previous format, i.e. "format - 1"
	//                                            STORAGE_WRITE_WITHOUT_FORMAT
	//                                           STORAGE_READ_WITHOUT_FORMAT |
	//                                                       VERTEX_BUFFER | |
	//                                            STORAGE_BUFFER_ATOMICS | | |
	//                                                  STORAGE_BUFFER | | | |
	//                                                        BUFFER | | | | |
	//                                         MULTISAMPLE_RESOLVE | | | | | |
	//                                            MULTISAMPLE_8X | | | | | | |
	//                                          MULTISAMPLE_4X | | | | | | | |
	//                                        MULTISAMPLE_2X | | | | | | | | |
	//                                               BLEND | | | | | | | | | |
	//                          DEPTH_STENCIL_ATTACHMENT | | | | | | | | | | |
	//                                COLOR_ATTACHMENT | | | | | | | | | | | |
	//                       STORAGE_TEXTURE_ATOMICS | | | | | | | | | | | | |
	//                             STORAGE_TEXTURE | | | | | | | | | | | | | |
	//                                   TEXTURE | | | | | | | | | | | | | | |
	//                                         | | | | | | | | | | | | | | | |
	ASTC_10X6_SRGB       = 93,  // |      FormatSupportBits      |

	// left -> right : low -> high bits
	// Expected (but not guaranteed) "FormatSupportBits" are provided, but "GetFormatSupport" should be used for querying real HW support
	// To demote sRGB use the previous format, i.e. "format - 1"
	//                                            STORAGE_WRITE_WITHOUT_FORMAT
	//                                           STORAGE_READ_WITHOUT_FORMAT |
	//                                                       VERTEX_BUFFER | |
	//                                            STORAGE_BUFFER_ATOMICS | | |
	//                                                  STORAGE_BUFFER | | | |
	//                                                        BUFFER | | | | |
	//                                         MULTISAMPLE_RESOLVE | | | | | |
	//                                            MULTISAMPLE_8X | | | | | | |
	//                                          MULTISAMPLE_4X | | | | | | | |
	//                                        MULTISAMPLE_2X | | | | | | | | |
	//                                               BLEND | | | | | | | | | |
	//                          DEPTH_STENCIL_ATTACHMENT | | | | | | | | | | |
	//                                COLOR_ATTACHMENT | | | | | | | | | | | |
	//                       STORAGE_TEXTURE_ATOMICS | | | | | | | | | | | | |
	//                             STORAGE_TEXTURE | | | | | | | | | | | | | |
	//                                   TEXTURE | | | | | | | | | | | | | | |
	//                                         | | | | | | | | | | | | | | | |
	ASTC_10X8_UNORM      = 94,  // |      FormatSupportBits      |

	// left -> right : low -> high bits
	// Expected (but not guaranteed) "FormatSupportBits" are provided, but "GetFormatSupport" should be used for querying real HW support
	// To demote sRGB use the previous format, i.e. "format - 1"
	//                                            STORAGE_WRITE_WITHOUT_FORMAT
	//                                           STORAGE_READ_WITHOUT_FORMAT |
	//                                                       VERTEX_BUFFER | |
	//                                            STORAGE_BUFFER_ATOMICS | | |
	//                                                  STORAGE_BUFFER | | | |
	//                                                        BUFFER | | | | |
	//                                         MULTISAMPLE_RESOLVE | | | | | |
	//                                            MULTISAMPLE_8X | | | | | | |
	//                                          MULTISAMPLE_4X | | | | | | | |
	//                                        MULTISAMPLE_2X | | | | | | | | |
	//                                               BLEND | | | | | | | | | |
	//                          DEPTH_STENCIL_ATTACHMENT | | | | | | | | | | |
	//                                COLOR_ATTACHMENT | | | | | | | | | | | |
	//                       STORAGE_TEXTURE_ATOMICS | | | | | | | | | | | | |
	//                             STORAGE_TEXTURE | | | | | | | | | | | | | |
	//                                   TEXTURE | | | | | | | | | | | | | | |
	//                                         | | | | | | | | | | | | | | | |
	ASTC_10X8_SRGB       = 95,  // |      FormatSupportBits      |

	// left -> right : low -> high bits
	// Expected (but not guaranteed) "FormatSupportBits" are provided, but "GetFormatSupport" should be used for querying real HW support
	// To demote sRGB use the previous format, i.e. "format - 1"
	//                                            STORAGE_WRITE_WITHOUT_FORMAT
	//                                           STORAGE_READ_WITHOUT_FORMAT |
	//                                                       VERTEX_BUFFER | |
	//                                            STORAGE_BUFFER_ATOMICS | | |
	//                                                  STORAGE_BUFFER | | | |
	//                                                        BUFFER | | | | |
	//                                         MULTISAMPLE_RESOLVE | | | | | |
	//                                            MULTISAMPLE_8X | | | | | | |
	//                                          MULTISAMPLE_4X | | | | | | | |
	//                                        MULTISAMPLE_2X | | | | | | | | |
	//                                               BLEND | | | | | | | | | |
	//                          DEPTH_STENCIL_ATTACHMENT | | | | | | | | | | |
	//                                COLOR_ATTACHMENT | | | | | | | | | | | |
	//                       STORAGE_TEXTURE_ATOMICS | | | | | | | | | | | | |
	//                             STORAGE_TEXTURE | | | | | | | | | | | | | |
	//                                   TEXTURE | | | | | | | | | | | | | | |
	//                                         | | | | | | | | | | | | | | | |
	ASTC_10X10_UNORM     = 96,  // |      FormatSupportBits      |

	// left -> right : low -> high bits
	// Expected (but not guaranteed) "FormatSupportBits" are provided, but "GetFormatSupport" should be used for querying real HW support
	// To demote sRGB use the previous format, i.e. "format - 1"
	//                                            STORAGE_WRITE_WITHOUT_FORMAT
	//                                           STORAGE_READ_WITHOUT_FORMAT |
	//                                                       VERTEX_BUFFER | |
	//                                            STORAGE_BUFFER_ATOMICS | | |
	//                                                  STORAGE_BUFFER | | | |
	//                                                        BUFFER | | | | |
	//                                         MULTISAMPLE_RESOLVE | | | | | |
	//                                            MULTISAMPLE_8X | | | | | | |
	//                                          MULTISAMPLE_4X | | | | | | | |
	//                                        MULTISAMPLE_2X | | | | | | | | |
	//                                               BLEND | | | | | | | | | |
	//                          DEPTH_STENCIL_ATTACHMENT | | | | | | | | | | |
	//                                COLOR_ATTACHMENT | | | | | | | | | | | |
	//                       STORAGE_TEXTURE_ATOMICS | | | | | | | | | | | | |
	//                             STORAGE_TEXTURE | | | | | | | | | | | | | |
	//                                   TEXTURE | | | | | | | | | | | | | | |
	//                                         | | | | | | | | | | | | | | | |
	ASTC_10X10_SRGB      = 97,  // |      FormatSupportBits      |

	// left -> right : low -> high bits
	// Expected (but not guaranteed) "FormatSupportBits" are provided, but "GetFormatSupport" should be used for querying real HW support
	// To demote sRGB use the previous format, i.e. "format - 1"
	//                                            STORAGE_WRITE_WITHOUT_FORMAT
	//                                           STORAGE_READ_WITHOUT_FORMAT |
	//                                                       VERTEX_BUFFER | |
	//                                            STORAGE_BUFFER_ATOMICS | | |
	//                                                  STORAGE_BUFFER | | | |
	//                                                        BUFFER | | | | |
	//                                         MULTISAMPLE_RESOLVE | | | | | |
	//                                            MULTISAMPLE_8X | | | | | | |
	//                                          MULTISAMPLE_4X | | | | | | | |
	//                                        MULTISAMPLE_2X | | | | | | | | |
	//                                               BLEND | | | | | | | | | |
	//                          DEPTH_STENCIL_ATTACHMENT | | | | | | | | | | |
	//                                COLOR_ATTACHMENT | | | | | | | | | | | |
	//                       STORAGE_TEXTURE_ATOMICS | | | | | | | | | | | | |
	//                             STORAGE_TEXTURE | | | | | | | | | | | | | |
	//                                   TEXTURE | | | | | | | | | | | | | | |
	//                                         | | | | | | | | | | | | | | | |
	ASTC_12X10_UNORM     = 98,  // |      FormatSupportBits      |

	// left -> right : low -> high bits
	// Expected (but not guaranteed) "FormatSupportBits" are provided, but "GetFormatSupport" should be used for querying real HW support
	// To demote sRGB use the previous format, i.e. "format - 1"
	//                                            STORAGE_WRITE_WITHOUT_FORMAT
	//                                           STORAGE_READ_WITHOUT_FORMAT |
	//                                                       VERTEX_BUFFER | |
	//                                            STORAGE_BUFFER_ATOMICS | | |
	//                                                  STORAGE_BUFFER | | | |
	//                                                        BUFFER | | | | |
	//                                         MULTISAMPLE_RESOLVE | | | | | |
	//                                            MULTISAMPLE_8X | | | | | | |
	//                                          MULTISAMPLE_4X | | | | | | | |
	//                                        MULTISAMPLE_2X | | | | | | | | |
	//                                               BLEND | | | | | | | | | |
	//                          DEPTH_STENCIL_ATTACHMENT | | | | | | | | | | |
	//                                COLOR_ATTACHMENT | | | | | | | | | | | |
	//                       STORAGE_TEXTURE_ATOMICS | | | | | | | | | | | | |
	//                             STORAGE_TEXTURE | | | | | | | | | | | | | |
	//                                   TEXTURE | | | | | | | | | | | | | | |
	//                                         | | | | | | | | | | | | | | | |
	ASTC_12X10_SRGB      = 99,  // |      FormatSupportBits      |

	// left -> right : low -> high bits
	// Expected (but not guaranteed) "FormatSupportBits" are provided, but "GetFormatSupport" should be used for querying real HW support
	// To demote sRGB use the previous format, i.e. "format - 1"
	//                                            STORAGE_WRITE_WITHOUT_FORMAT
	//                                           STORAGE_READ_WITHOUT_FORMAT |
	//                                                       VERTEX_BUFFER | |
	//                                            STORAGE_BUFFER_ATOMICS | | |
	//                                                  STORAGE_BUFFER | | | |
	//                                                        BUFFER | | | | |
	//                                         MULTISAMPLE_RESOLVE | | | | | |
	//                                            MULTISAMPLE_8X | | | | | | |
	//                                          MULTISAMPLE_4X | | | | | | | |
	//                                        MULTISAMPLE_2X | | | | | | | | |
	//                                               BLEND | | | | | | | | | |
	//                          DEPTH_STENCIL_ATTACHMENT | | | | | | | | | | |
	//                                COLOR_ATTACHMENT | | | | | | | | | | | |
	//                       STORAGE_TEXTURE_ATOMICS | | | | | | | | | | | | |
	//                             STORAGE_TEXTURE | | | | | | | | | | | | | |
	//                                   TEXTURE | | | | | | | | | | | | | | |
	//                                         | | | | | | | | | | | | | | | |
	ASTC_12X12_UNORM     = 100, // |      FormatSupportBits      |

	// left -> right : low -> high bits
	// Expected (but not guaranteed) "FormatSupportBits" are provided, but "GetFormatSupport" should be used for querying real HW support
	// To demote sRGB use the previous format, i.e. "format - 1"
	//                                            STORAGE_WRITE_WITHOUT_FORMAT
	//                                           STORAGE_READ_WITHOUT_FORMAT |
	//                                                       VERTEX_BUFFER | |
	//                                            STORAGE_BUFFER_ATOMICS | | |
	//                                                  STORAGE_BUFFER | | | |
	//                                                        BUFFER | | | | |
	//                                         MULTISAMPLE_RESOLVE | | | | | |
	//                                            MULTISAMPLE_8X | | | | | | |
	//                                          MULTISAMPLE_4X | | | | | | | |
	//                                        MULTISAMPLE_2X | | | | | | | | |
	//                                               BLEND | | | | | | | | | |
	//                          DEPTH_STENCIL_ATTACHMENT | | | | | | | | | | |
	//                                COLOR_ATTACHMENT | | | | | | | | | | | |
	//                       STORAGE_TEXTURE_ATOMICS | | | | | | | | | | | | |
	//                             STORAGE_TEXTURE | | | | | | | | | | | | | |
	//                                   TEXTURE | | | | | | | | | | | | | | |
	//                                         | | | | | | | | | | | | | | | |
	ASTC_12X12_SRGB      = 101, // |      FormatSupportBits      |

	// left -> right : low -> high bits
	// Expected (but not guaranteed) "FormatSupportBits" are provided, but "GetFormatSupport" should be used for querying real HW support
	// To demote sRGB use the previous format, i.e. "format - 1"
	//                                            STORAGE_WRITE_WITHOUT_FORMAT
	//                                           STORAGE_READ_WITHOUT_FORMAT |
	//                                                       VERTEX_BUFFER | |
	//                                            STORAGE_BUFFER_ATOMICS | | |
	//                                                  STORAGE_BUFFER | | | |
	//                                                        BUFFER | | | | |
	//                                         MULTISAMPLE_RESOLVE | | | | | |
	//                                            MULTISAMPLE_8X | | | | | | |
	//                                          MULTISAMPLE_4X | | | | | | | |
	//                                        MULTISAMPLE_2X | | | | | | | | |
	//                                               BLEND | | | | | | | | | |
	//                          DEPTH_STENCIL_ATTACHMENT | | | | | | | | | | |
	//                                COLOR_ATTACHMENT | | | | | | | | | | | |
	//                       STORAGE_TEXTURE_ATOMICS | | | | | | | | | | | | |
	//                             STORAGE_TEXTURE | | | | | | | | | | | | | |
	//                                   TEXTURE | | | | | | | | | | | | | | |
	//                                         | | | | | | | | | | | | | | | |
	D16_UNORM            = 102, // |      FormatSupportBits      |

	// left -> right : low -> high bits
	// Expected (but not guaranteed) "FormatSupportBits" are provided, but "GetFormatSupport" should be used for querying real HW support
	// To demote sRGB use the previous format, i.e. "format - 1"
	//                                            STORAGE_WRITE_WITHOUT_FORMAT
	//                                           STORAGE_READ_WITHOUT_FORMAT |
	//                                                       VERTEX_BUFFER | |
	//                                            STORAGE_BUFFER_ATOMICS | | |
	//                                                  STORAGE_BUFFER | | | |
	//                                                        BUFFER | | | | |
	//                                         MULTISAMPLE_RESOLVE | | | | | |
	//                                            MULTISAMPLE_8X | | | | | | |
	//                                          MULTISAMPLE_4X | | | | | | | |
	//                                        MULTISAMPLE_2X | | | | | | | | |
	//                                               BLEND | | | | | | | | | |
	//                          DEPTH_STENCIL_ATTACHMENT | | | | | | | | | | |
	//                                COLOR_ATTACHMENT | | | | | | | | | | | |
	//                       STORAGE_TEXTURE_ATOMICS | | | | | | | | | | | | |
	//                             STORAGE_TEXTURE | | | | | | | | | | | | | |
	//                                   TEXTURE | | | | | | | | | | | | | | |
	//                                         | | | | | | | | | | | | | | | |
	D32_SFLOAT           = 103, // |      FormatSupportBits      |

	// left -> right : low -> high bits
	// Expected (but not guaranteed) "FormatSupportBits" are provided, but "GetFormatSupport" should be used for querying real HW support
	// To demote sRGB use the previous format, i.e. "format - 1"
	//                                            STORAGE_WRITE_WITHOUT_FORMAT
	//                                           STORAGE_READ_WITHOUT_FORMAT |
	//                                                       VERTEX_BUFFER | |
	//                                            STORAGE_BUFFER_ATOMICS | | |
	//                                                  STORAGE_BUFFER | | | |
	//                                                        BUFFER | | | | |
	//                                         MULTISAMPLE_RESOLVE | | | | | |
	//                                            MULTISAMPLE_8X | | | | | | |
	//                                          MULTISAMPLE_4X | | | | | | | |
	//                                        MULTISAMPLE_2X | | | | | | | | |
	//                                               BLEND | | | | | | | | | |
	//                          DEPTH_STENCIL_ATTACHMENT | | | | | | | | | | |
	//                                COLOR_ATTACHMENT | | | | | | | | | | | |
	//                       STORAGE_TEXTURE_ATOMICS | | | | | | | | | | | | |
	//                             STORAGE_TEXTURE | | | | | | | | | | | | | |
	//                                   TEXTURE | | | | | | | | | | | | | | |
	//                                         | | | | | | | | | | | | | | | |
	D24_UNORM_S8_UINT    = 104, // |      FormatSupportBits      |

	// left -> right : low -> high bits
	// Expected (but not guaranteed) "FormatSupportBits" are provided, but "GetFormatSupport" should be used for querying real HW support
	// To demote sRGB use the previous format, i.e. "format - 1"
	//                                            STORAGE_WRITE_WITHOUT_FORMAT
	//                                           STORAGE_READ_WITHOUT_FORMAT |
	//                                                       VERTEX_BUFFER | |
	//                                            STORAGE_BUFFER_ATOMICS | | |
	//                                                  STORAGE_BUFFER | | | |
	//                                                        BUFFER | | | | |
	//                                         MULTISAMPLE_RESOLVE | | | | | |
	//                                            MULTISAMPLE_8X | | | | | | |
	//                                          MULTISAMPLE_4X | | | | | | | |
	//                                        MULTISAMPLE_2X | | | | | | | | |
	//                                               BLEND | | | | | | | | | |
	//                          DEPTH_STENCIL_ATTACHMENT | | | | | | | | | | |
	//                                COLOR_ATTACHMENT | | | | | | | | | | | |
	//                       STORAGE_TEXTURE_ATOMICS | | | | | | | | | | | | |
	//                             STORAGE_TEXTURE | | | | | | | | | | | | | |
	//                                   TEXTURE | | | | | | | | | | | | | | |
	//                                         | | | | | | | | | | | | | | | |
	D32_SFLOAT_S8_UINT   = 105, // |      FormatSupportBits      |

	// left -> right : low -> high bits
	// Expected (but not guaranteed) "FormatSupportBits" are provided, but "GetFormatSupport" should be used for querying real HW support
	// To demote sRGB use the previous format, i.e. "format - 1"
	//                                            STORAGE_WRITE_WITHOUT_FORMAT
	//                                           STORAGE_READ_WITHOUT_FORMAT |
	//                                                       VERTEX_BUFFER | |
	//                                            STORAGE_BUFFER_ATOMICS | | |
	//                                                  STORAGE_BUFFER | | | |
	//                                                        BUFFER | | | | |
	//                                         MULTISAMPLE_RESOLVE | | | | | |
	//                                            MULTISAMPLE_8X | | | | | | |
	//                                          MULTISAMPLE_4X | | | | | | | |
	//                                        MULTISAMPLE_2X | | | | | | | | |
	//                                               BLEND | | | | | | | | | |
	//                          DEPTH_STENCIL_ATTACHMENT | | | | | | | | | | |
	//                                COLOR_ATTACHMENT | | | | | | | | | | | |
	//                       STORAGE_TEXTURE_ATOMICS | | | | | | | | | | | | |
	//                             STORAGE_TEXTURE | | | | | | | | | | | | | |
	//                                   TEXTURE | | | | | | | | | | | | | | |
	//                                         | | | | | | | | | | | | | | | |
	MAX_NUM              = 106, // |      FormatSupportBits      |
} // |      FormatSupportBits      |

PlaneBitsEnum :: enum u8 {
	NONE    = 7,
	COLOR   = 0,
	DEPTH   = 1,
	STENCIL = 2,
}

// https://learn.microsoft.com/en-us/windows/win32/direct3d12/subresources#plane-slice
// https://docs.vulkan.org/refpages/latest/refpages/source/VkImageAspectFlagBits.html
PlaneBits :: bit_set[PlaneBitsEnum; u8]

FormatSupportBitsEnum :: enum u16 {
	// WGPU: typed buffer views are unsupported; storage textures cannot be multisampled
	TEXTURE                      = 0,

	// WGPU: typed buffer views are unsupported; storage textures cannot be multisampled
	STORAGE_TEXTURE              = 1,

	// WGPU: typed buffer views are unsupported; storage textures cannot be multisampled
	STORAGE_TEXTURE_ATOMICS      = 2,

	// WGPU: typed buffer views are unsupported; storage textures cannot be multisampled
	COLOR_ATTACHMENT             = 3,

	// WGPU: typed buffer views are unsupported; storage textures cannot be multisampled
	DEPTH_STENCIL_ATTACHMENT     = 4,

	// WGPU: typed buffer views are unsupported; storage textures cannot be multisampled
	BLEND                        = 5,

	// WGPU: typed buffer views are unsupported; storage textures cannot be multisampled
	MULTISAMPLE_2X               = 6,

	// WGPU: typed buffer views are unsupported; storage textures cannot be multisampled
	MULTISAMPLE_4X               = 7,

	// WGPU: typed buffer views are unsupported; storage textures cannot be multisampled
	MULTISAMPLE_8X               = 8,

	// WGPU: typed buffer views are unsupported; storage textures cannot be multisampled
	MULTISAMPLE_RESOLVE          = 9,

	// WGPU: typed buffer views are unsupported; storage textures cannot be multisampled
	BUFFER                       = 10,

	// WGPU: typed buffer views are unsupported; storage textures cannot be multisampled
	STORAGE_BUFFER               = 11,

	// WGPU: typed buffer views are unsupported; storage textures cannot be multisampled
	STORAGE_BUFFER_ATOMICS       = 12,

	// WGPU: typed buffer views are unsupported; storage textures cannot be multisampled
	VERTEX_BUFFER                = 13,

	// WGPU: typed buffer views are unsupported; storage textures cannot be multisampled
	STORAGE_READ_WITHOUT_FORMAT  = 14,

	// WGPU: typed buffer views are unsupported; storage textures cannot be multisampled
	STORAGE_WRITE_WITHOUT_FORMAT = 15,
}

// A bit represents a feature, supported by a format
// https://learn.microsoft.com/en-us/windows/win32/api/d3d12/ns-d3d12-d3d12_feature_data_format_support
// https://docs.vulkan.org/refpages/latest/refpages/source/VkFormatFeatureFlagBits2.html
// WGPU: typed buffer views are unsupported; storage textures cannot be multisampled
FormatSupportBits :: bit_set[FormatSupportBitsEnum; u16]

StageBitsEnum :: enum u32 {
	INDEX_INPUT              = 0,
	VERTEX_SHADER            = 1,
	TESS_CONTROL_SHADER      = 2,
	TESS_EVALUATION_SHADER   = 3,
	GEOMETRY_SHADER          = 4,
	TASK_SHADER              = 5,
	MESH_SHADER              = 6,
	FRAGMENT_SHADER          = 7,
	DEPTH_STENCIL_ATTACHMENT = 8,
	COLOR_ATTACHMENT         = 9,
	SHADING_RATE_ATTACHMENT  = 10,
	COMPUTE_SHADER           = 11,
	RAYGEN_SHADER            = 12,
	MISS_SHADER              = 13,
	INTERSECTION_SHADER      = 14,
	CLOSEST_HIT_SHADER       = 15,
	ANY_HIT_SHADER           = 16,
	CALLABLE_SHADER          = 17,
	ACCELERATION_STRUCTURE   = 18,
	MICROMAP                 = 19,
	COPY                     = 20,
	RESOLVE                  = 21,
	CLEAR_STORAGE            = 22,
	INDIRECT                 = 23,
}

// https://docs.vulkan.org/refpages/latest/refpages/source/VkPipelineStageFlagBits2.html
// https://microsoft.github.io/DirectX-Specs/d3d/D3D12EnhancedBarriers.html#d3d12_barrier_sync
StageBits :: bit_set[StageBitsEnum; u32]
STAGEBITS_ALL                  :: StageBits {}
STAGEBITS_NONE                 :: transmute(StageBits)(u32(0x7FFFFFFF))
STAGEBITS_MESH_SHADERS         :: StageBits {.TASK_SHADER, .MESH_SHADER}
STAGEBITS_GRAPHICS             :: StageBits {.INDEX_INPUT, .VERTEX_SHADER, .TESS_CONTROL_SHADER, .TESS_EVALUATION_SHADER, .GEOMETRY_SHADER, .TASK_SHADER, .MESH_SHADER, .FRAGMENT_SHADER, .DEPTH_STENCIL_ATTACHMENT, .COLOR_ATTACHMENT, .SHADING_RATE_ATTACHMENT}
STAGEBITS_TESSELLATION_SHADERS :: StageBits {.TESS_CONTROL_SHADER, .TESS_EVALUATION_SHADER}
STAGEBITS_ALL_SHADERS          :: StageBits {.VERTEX_SHADER, .TESS_CONTROL_SHADER, .TESS_EVALUATION_SHADER, .GEOMETRY_SHADER, .TASK_SHADER, .MESH_SHADER, .FRAGMENT_SHADER, .COMPUTE_SHADER, .RAYGEN_SHADER, .MISS_SHADER, .INTERSECTION_SHADER, .CLOSEST_HIT_SHADER, .ANY_HIT_SHADER, .CALLABLE_SHADER}
STAGEBITS_RAY_TRACING_SHADERS  :: StageBits {.RAYGEN_SHADER, .MISS_SHADER, .INTERSECTION_SHADER, .CLOSEST_HIT_SHADER, .ANY_HIT_SHADER, .CALLABLE_SHADER}
STAGEBITS_GRAPHICS_SHADERS     :: StageBits {.VERTEX_SHADER, .TESS_CONTROL_SHADER, .TESS_EVALUATION_SHADER, .GEOMETRY_SHADER, .TASK_SHADER, .MESH_SHADER, .FRAGMENT_SHADER}

AccessBitsEnum :: enum u32 {
	INDEX_BUFFER                   = 0,
	VERTEX_BUFFER                  = 1,
	CONSTANT_BUFFER                = 2,
	ARGUMENT_BUFFER                = 3,
	SCRATCH_BUFFER                 = 4,
	COLOR_ATTACHMENT_READ          = 5,
	COLOR_ATTACHMENT_WRITE         = 6,
	DEPTH_STENCIL_ATTACHMENT_READ  = 7,
	DEPTH_STENCIL_ATTACHMENT_WRITE = 8,
	SHADING_RATE_ATTACHMENT        = 9,
	INPUT_ATTACHMENT               = 10,
	ACCELERATION_STRUCTURE_READ    = 11,
	ACCELERATION_STRUCTURE_WRITE   = 12,
	MICROMAP_READ                  = 13,
	MICROMAP_WRITE                 = 14,
	SHADER_RESOURCE                = 15,
	SHADER_RESOURCE_STORAGE        = 16,
	SHADER_BINDING_TABLE           = 17,
	COPY_SOURCE                    = 18,
	COPY_DESTINATION               = 19,
	RESOLVE_SOURCE                 = 20,
	RESOLVE_DESTINATION            = 21,
	CLEAR_STORAGE                  = 22,
}

// https://docs.vulkan.org/refpages/latest/refpages/source/VkAccessFlagBits2.html
// https://microsoft.github.io/DirectX-Specs/d3d/D3D12EnhancedBarriers.html#d3d12_barrier_access
AccessBits :: bit_set[AccessBitsEnum; u32]
ACCESSBITS_ACCELERATION_STRUCTURE   :: AccessBits {.ACCELERATION_STRUCTURE_READ, .ACCELERATION_STRUCTURE_WRITE}
ACCESSBITS_DEPTH_STENCIL_ATTACHMENT :: AccessBits {.DEPTH_STENCIL_ATTACHMENT_READ, .DEPTH_STENCIL_ATTACHMENT_WRITE}
ACCESSBITS_MICROMAP                 :: AccessBits {.MICROMAP_READ, .MICROMAP_WRITE}
ACCESSBITS_COLOR_ATTACHMENT         :: AccessBits {.COLOR_ATTACHMENT_READ, .COLOR_ATTACHMENT_WRITE}

// "Layout" is ignored if "features.enhancedBarriers" is not supported
// https://docs.vulkan.org/refpages/latest/refpages/source/VkImageLayout.html
// https://microsoft.github.io/DirectX-Specs/d3d/D3D12EnhancedBarriers.html#d3d12_barrier_layout
Layout :: enum u8 {
	UNDEFINED                         = 0,  // Compatible "AccessBits":
	GENERAL                           = 1,  // Compatible "AccessBits":
	PRESENT                           = 2,  // Compatible "AccessBits":
	COLOR_ATTACHMENT                  = 3,  // Compatible "AccessBits":
	DEPTH_STENCIL_ATTACHMENT          = 4,  // Compatible "AccessBits":
	DEPTH_READONLY_STENCIL_ATTACHMENT = 5,  // Compatible "AccessBits":
	DEPTH_ATTACHMENT_STENCIL_READONLY = 6,  // Compatible "AccessBits":
	DEPTH_STENCIL_READONLY            = 7,  // Compatible "AccessBits":
	SHADING_RATE_ATTACHMENT           = 8,  // Compatible "AccessBits":
	INPUT_ATTACHMENT                  = 9,  // Compatible "AccessBits":
	SHADER_RESOURCE                   = 10, // Compatible "AccessBits":
	SHADER_RESOURCE_STORAGE           = 11, // Compatible "AccessBits":
	COPY_SOURCE                       = 12, // Compatible "AccessBits":
	COPY_DESTINATION                  = 13, // Compatible "AccessBits":
	RESOLVE_SOURCE                    = 14, // Compatible "AccessBits":
	RESOLVE_DESTINATION               = 15, // Compatible "AccessBits":
	MAX_NUM                           = 16, // Compatible "AccessBits":
} // Compatible "AccessBits":

AccessStage :: struct {
	access: AccessBits,
	stages: StageBits,
}

AccessLayoutStage :: struct {
	access: AccessBits,
	layout: Layout,
	stages: StageBits,
}

GlobalBarrierDesc :: struct {
	before: AccessStage,
	after:  AccessStage,
}

BufferBarrierDesc :: struct {
	buffer: ^Buffer, // use "GetAccelerationStructureBuffer" and "GetMicromapBuffer" for related barriers
	before: AccessStage,
	after:  AccessStage,
}

TextureBarrierDesc :: struct {
	texture:     ^Texture,
	before:      AccessLayoutStage,
	after:       AccessLayoutStage,
	mipOffset:   Dim_t,
	mipNum:      Dim_t, // can be "REMAINING"
	layerOffset: Dim_t,
	layerNum:    Dim_t, // can be "REMAINING"
	planes:      PlaneBits,
	srcQueue:    ^Queue,
	dstQueue:    ^Queue,
}

// Using "CmdBarrier" inside a rendering pass is allowed, but only for "Layout::INPUT_ATTACHMENT" access transitions
// D3D12 filters out "transitioning to the same state" barriers if "features.enhancedBarriers" is not supported
BarrierDesc :: struct {
	globals:    [^]GlobalBarrierDesc,
	globalNum:  u32,
	buffers:    [^]BufferBarrierDesc,
	bufferNum:  u32,
	textures:   [^]TextureBarrierDesc,
	textureNum: u32,
}

// https://docs.vulkan.org/refpages/latest/refpages/source/VkImageType.html
// https://learn.microsoft.com/en-us/windows/win32/api/d3d12/ne-d3d12-d3d12_resource_dimension
TextureType :: enum u8 {
	TEXTURE_1D = 0,
	TEXTURE_2D = 1,
	TEXTURE_3D = 2,
	MAX_NUM    = 3,
}

// NRI tries to ease your life and avoid using "queue ownership transfers" (see "TextureBarrierDesc").
// In most of cases "SharingMode" can be ignored. Where is it needed?
// - VK: use "EXCLUSIVE" for attachments participating into multi-queue activities to preserve DCC (Delta Color Compression) on some HW
// - D3D12: use "SIMULTANEOUS" to concurrently use a texture as a "SHADER_RESOURCE" (or "SHADER_RESOURCE_STORAGE") and as a "COPY_DESTINATION" for non overlapping texture regions
// https://docs.vulkan.org/refpages/latest/refpages/source/VkSharingMode.html
SharingMode :: enum u8 {
	CONCURRENT   = 0,
	EXCLUSIVE    = 1,
	SIMULTANEOUS = 2,
	MAX_NUM      = 3,
}

TextureUsageBitsEnum :: enum u8 {
	SHADER_RESOURCE          = 0, // Min compatible access:                   Usage:
	SHADER_RESOURCE_STORAGE  = 1, // Min compatible access:                   Usage:
	COLOR_ATTACHMENT         = 2, // Min compatible access:                   Usage:
	DEPTH_STENCIL_ATTACHMENT = 3, // Min compatible access:                   Usage:
	SHADING_RATE_ATTACHMENT  = 4, // Min compatible access:                   Usage:
	INPUT_ATTACHMENT         = 5, // Min compatible access:                   Usage:
}

// https://docs.vulkan.org/refpages/latest/refpages/source/VkImageUsageFlagBits.html
// https://learn.microsoft.com/en-us/windows/win32/api/d3d12/ne-d3d12-d3d12_resource_flags
TextureUsageBits :: bit_set[TextureUsageBitsEnum; u8]

BufferUsageBitsEnum :: enum u16 {
	SHADER_RESOURCE                    = 0,  // Min compatible access:                   Usage:
	SHADER_RESOURCE_STORAGE            = 1,  // Min compatible access:                   Usage:
	VERTEX_BUFFER                      = 2,  // Min compatible access:                   Usage:
	INDEX_BUFFER                       = 3,  // Min compatible access:                   Usage:
	CONSTANT_BUFFER                    = 4,  // Min compatible access:                   Usage:
	ARGUMENT_BUFFER                    = 5,  // Min compatible access:                   Usage:
	SCRATCH_BUFFER                     = 6,  // Min compatible access:                   Usage:
	SHADER_BINDING_TABLE               = 7,  // Min compatible access:                   Usage:
	ACCELERATION_STRUCTURE_BUILD_INPUT = 8,  // Min compatible access:                   Usage:
	ACCELERATION_STRUCTURE_STORAGE     = 9,  // Min compatible access:                   Usage:
	MICROMAP_BUILD_INPUT               = 10, // Min compatible access:                   Usage:
	MICROMAP_STORAGE                   = 11, // Min compatible access:                   Usage:
}

// https://docs.vulkan.org/refpages/latest/refpages/source/VkBufferUsageFlagBits.html
BufferUsageBits :: bit_set[BufferUsageBitsEnum; u16]

TextureDesc :: struct {
	type:                TextureType,
	usage:               TextureUsageBits,
	format:              Format,
	width:               Dim_t,
	height:              Dim_t,
	depth:               Dim_t,
	mipNum:              Dim_t,
	layerNum:            Dim_t,
	sampleNum:           Sample_t,
	sharingMode:         SharingMode,
	optimizedClearValue: ClearValue, // D3D12: not needed on desktop, since any HW can track many clear values
}

// - VK: buffers are always created with sharing mode "CONCURRENT" to match D3D12 spec
// - "structureStride" values:
//   - 0  - allows only "typed" views
//          WGPU: typed buffer views are unsupported
//   - 4  - allows "typed", "byte address" and "structured" views
//          D3D11: allows to create multiple "structured" views for a single resource, disobeying the spec
//   - >4 - allows only "structured" views
//          D3D11: locks this buffer to a single "structured" layout
BufferDesc :: struct {
	size:            u64,
	structureStride: u32,
	usage:           BufferUsageBits,
}

// Contains some encoded implementation specific details
MemoryType :: u32

// https://learn.microsoft.com/en-us/windows/win32/api/d3d12/ne-d3d12-d3d12_heap_type
MemoryLocation :: enum u8 {
	DEVICE        = 0,
	DEVICE_UPLOAD = 1,
	HOST_UPLOAD   = 2,
	HOST_READBACK = 3,
	MAX_NUM       = 4,
}

// Memory requirements for a resource (buffer or texture)
MemoryDesc :: struct {
	size:            u64,
	alignment:       u32,
	type:            MemoryType,
	mustBeDedicated: bool, // must be put into a dedicated "Memory" object, containing only 1 object with offset = 0
}

// A group of non-dedicated "MemoryDesc"s of the SAME "MemoryType" can be merged into a single memory allocation
AllocateMemoryDesc :: struct {
	size:     u64,
	type:     MemoryType,
	priority: f32, // [-1; 1]: low < 0, normal = 0, high > 0

	vma: struct {
		enable:    bool,
		alignment: u32, // by default worst-case alignment applied
	},

	// If "false", may reduce alignment requirements
	allowMultisampleTextures: bool,
}

// Binding resources to a memory (resources can overlap, i.e. alias)
BindBufferMemoryDesc :: struct {
	buffer: ^Buffer,
	memory: ^Memory,
	offset: u64, // in memory
}

BindTextureMemoryDesc :: struct {
	texture: ^Texture,
	memory:  ^Memory,
	offset:  u64, // in memory
}

// https://microsoft.github.io/DirectX-Specs/d3d/ResourceBinding.html#creating-descriptors
TextureView :: enum u8 {
	TEXTURE                  = 0,
	TEXTURE_ARRAY            = 1,
	TEXTURE_CUBE             = 2,
	TEXTURE_CUBE_ARRAY       = 3,
	STORAGE_TEXTURE          = 4,
	STORAGE_TEXTURE_ARRAY    = 5,
	SUBPASS_INPUT            = 6,
	COLOR_ATTACHMENT         = 7,
	DEPTH_STENCIL_ATTACHMENT = 8,
	SHADING_RATE_ATTACHMENT  = 9,
	MAX_NUM                  = 10,
}

BufferView :: enum u8 {
	BUFFER                      = 0,
	STRUCTURED_BUFFER           = 1,
	BYTE_ADDRESS_BUFFER         = 2,
	STORAGE_BUFFER              = 3,
	STORAGE_STRUCTURED_BUFFER   = 4,
	STORAGE_BYTE_ADDRESS_BUFFER = 5,
	CONSTANT_BUFFER             = 6,
	MAX_NUM                     = 7,
}

// https://docs.vulkan.org/refpages/latest/refpages/source/VkFilter.html
// https://docs.vulkan.org/refpages/latest/refpages/source/VkSamplerMipmapMode.html
// https://learn.microsoft.com/en-us/windows/win32/api/d3d12/ne-d3d12-d3d12_filter
Filter :: enum u8 {
	NEAREST = 0,
	LINEAR  = 1,
	MAX_NUM = 2,
}

// https://learn.microsoft.com/en-us/windows/win32/api/d3d12/ne-d3d12-d3d12_filter_reduction_type
// https://docs.vulkan.org/refpages/latest/refpages/source/VkSamplerReductionMode.html
FilterOp :: enum u8 {
	AVERAGE = 0,
	MIN     = 1,
	MAX     = 2,
	MAX_NUM = 3,
}

// https://docs.vulkan.org/refpages/latest/refpages/source/VkSamplerAddressMode.html
// https://learn.microsoft.com/en-us/windows/win32/api/d3d12/ne-d3d12-d3d12_texture_address_mode
AddressMode :: enum u8 {
	REPEAT               = 0,
	MIRRORED_REPEAT      = 1,
	CLAMP_TO_EDGE        = 2,
	CLAMP_TO_BORDER      = 3,
	MIRROR_CLAMP_TO_EDGE = 4,
	MAX_NUM              = 5,
}

// https://docs.vulkan.org/refpages/latest/refpages/source/VkCompareOp.html
// https://learn.microsoft.com/en-us/windows/win32/api/d3d12/ne-d3d12-d3d12_comparison_func
// R - fragment depth, stencil reference or "SampleCmp" reference
// D - depth or stencil buffer
CompareOp :: enum u8 {
	// R - fragment depth, stencil reference or "SampleCmp" reference
	// D - depth or stencil buffer
	NONE          = 0,

	// R - fragment depth, stencil reference or "SampleCmp" reference
	// D - depth or stencil buffer
	ALWAYS        = 1,

	// R - fragment depth, stencil reference or "SampleCmp" reference
	// D - depth or stencil buffer
	NEVER         = 2,

	// R - fragment depth, stencil reference or "SampleCmp" reference
	// D - depth or stencil buffer
	EQUAL         = 3,

	// R - fragment depth, stencil reference or "SampleCmp" reference
	// D - depth or stencil buffer
	NOT_EQUAL     = 4,

	// R - fragment depth, stencil reference or "SampleCmp" reference
	// D - depth or stencil buffer
	LESS          = 5,

	// R - fragment depth, stencil reference or "SampleCmp" reference
	// D - depth or stencil buffer
	LESS_EQUAL    = 6,

	// R - fragment depth, stencil reference or "SampleCmp" reference
	// D - depth or stencil buffer
	GREATER       = 7,

	// R - fragment depth, stencil reference or "SampleCmp" reference
	// D - depth or stencil buffer
	GREATER_EQUAL = 8,

	// R - fragment depth, stencil reference or "SampleCmp" reference
	// D - depth or stencil buffer
	MAX_NUM       = 9,
}

// https://docs.vulkan.org/refpages/latest/refpages/source/VkComponentSwizzle.html
// https://learn.microsoft.com/en-us/windows/win32/api/d3d12/ne-d3d12-d3d12_shader_component_mapping
ComponentSwizzle :: enum u8 {
	IDENTITY = 0,
	ZERO     = 1,
	ONE      = 2,
	R        = 3,
	G        = 4,
	B        = 5,
	A        = 6,
	MAX_NUM  = 7,
}

ComponentMapping :: struct {
	// Only for non-"STORAGE" views
	r: ComponentSwizzle,
	g: ComponentSwizzle,
	b: ComponentSwizzle,
	a: ComponentSwizzle,
}

TextureViewDesc :: struct {
	texture:     ^Texture,
	type:        TextureView,
	format:      Format,
	mipOffset:   Dim_t,
	mipNum:      Dim_t,     // can be "REMAINING"
	layerOffset: Dim_t,
	layerNum:    Dim_t,     // can be "REMAINING"
	sliceOffset: Dim_t,
	sliceNum:    Dim_t,     // can be "REMAINING"
	planes:      PlaneBits, // accessible planes (missing planes for a "DEPTH_STENCIL_ATTACHMENT" are considered read-only)
	components:  ComponentMapping,
}

BufferViewDesc :: struct {
	buffer:          ^Buffer,
	type:            BufferView,
	offset:          u64,    // expects "memoryAlignment.bufferShaderResourceOffset" for shader resources
	size:            u64,    // can be "WHOLE_SIZE"
	format:          Format, // needed for typed views, i.e. "BUFFER" and "STORAGE_BUFFER"
	structureStride: u32,    // needed for structured views, i.e. "STRUCTURED_BUFFER" and "STORAGE_STRUCTURED_BUFFER" (= "BufferDesc::structureStride", if not provided)
}

AddressModes :: struct {
	u, v, w: AddressMode,
}

Filters :: struct {
	min, mag, mip: Filter,
	op:            FilterOp,
}

// https://docs.vulkan.org/refpages/latest/refpages/source/VkSamplerCreateInfo.html
// https://learn.microsoft.com/en-us/windows/win32/api/d3d12/ns-d3d12-d3d12_sampler_desc
SamplerDesc :: struct {
	filters:                 Filters,
	anisotropy:              u8,
	mipBias:                 f32,
	mipMin:                  f32,
	mipMax:                  f32,
	addressModes:            AddressModes,
	compareOp:               CompareOp,
	borderColor:             Color, // used only with "AddressMode::CLAMP_TO_BORDER"
	isInteger:               bool,
	unnormalizedCoordinates: bool,  // requires "shaderFeatures.unnormalizedCoordinates"
}

// https://docs.vulkan.org/refpages/latest/refpages/source/VkPipelineBindPoint.html
BindPoint :: enum u8 {
	INHERIT     = 0,
	GRAPHICS    = 1,
	COMPUTE     = 2,
	RAY_TRACING = 3,
	MAX_NUM     = 4,
}

PipelineLayoutBitsEnum :: enum u8 {
	IGNORE_GLOBAL_SPIRV_OFFSETS      = 0,
	ENABLE_DRAW_PARAMETERS_EMULATION = 1,
	ENABLE_DRAW_INDEX_EMULATION      = 2,
	SAMPLER_HEAP_DIRECTLY_INDEXED    = 3,
	RESOURCE_HEAP_DIRECTLY_INDEXED   = 4,
}

PipelineLayoutBits :: bit_set[PipelineLayoutBitsEnum; u8]

DescriptorPoolBitsEnum :: enum u8 {
	ALLOW_UPDATE_AFTER_SET = 0,
}

DescriptorPoolBits :: bit_set[DescriptorPoolBitsEnum; u8]

DescriptorSetBitsEnum :: enum u8 {
	ALLOW_UPDATE_AFTER_SET = 0,
}
DescriptorSetBits :: bit_set[DescriptorSetBitsEnum; u8]

DescriptorRangeBitsEnum :: enum u8 {
	PARTIALLY_BOUND        = 0,
	ARRAY                  = 1,
	VARIABLE_SIZED_ARRAY   = 2,
	ALLOW_UPDATE_AFTER_SET = 3,
}

// https://docs.vulkan.org/refpages/latest/refpages/source/VkDescriptorBindingFlagBits.html
DescriptorRangeBits :: bit_set[DescriptorRangeBitsEnum; u8]

// https://docs.vulkan.org/refpages/latest/refpages/source/VkDescriptorType.html
DescriptorType :: enum u8 {
	SAMPLER                   = 0,
	MUTABLE                   = 1,
	TEXTURE                   = 2,
	STORAGE_TEXTURE           = 3,
	INPUT_ATTACHMENT          = 4,
	BUFFER                    = 5,
	STORAGE_BUFFER            = 6,
	CONSTANT_BUFFER           = 7,
	STRUCTURED_BUFFER         = 8,
	STORAGE_STRUCTURED_BUFFER = 9,
	ACCELERATION_STRUCTURE    = 10,
	MAX_NUM                   = 11,
}

// "DescriptorRange" consists of "Descriptor" entities
DescriptorRangeDesc :: struct {
	baseRegisterIndex: u32, // "VKBindingOffsets" not applied to "MUTABLE" and "INPUT_ATTACHMENT" to avoid confusion
	descriptorNum:     u32, // treated as max size if "VARIABLE_SIZED_ARRAY" flag is set
	descriptorType:    DescriptorType,
	shaderStages:      StageBits,
	flags:             DescriptorRangeBits,
}

// "DescriptorSet" consists of "DescriptorRange" entities
DescriptorSetDesc :: struct {
	registerSpace: u32, // must be unique, avoid big gaps
	ranges:        [^]DescriptorRangeDesc,
	rangeNum:      u32,
	flags:         DescriptorSetBits,
}

// "PipelineLayout" consists of "DescriptorSet" descriptions and root parameters
RootConstantDesc :: struct {
	registerIndex: u32,
	size:          u32,
	shaderStages:  StageBits,
} // aka push constants block

RootDescriptorDesc :: struct {
	registerIndex:  u32,
	descriptorType: DescriptorType, // a non-typed descriptor type
	shaderStages:   StageBits,
} // aka push descriptor

// https://learn.microsoft.com/en-us/windows/win32/direct3d12/root-signature-limits#static-samplers
RootSamplerDesc :: struct {
	registerIndex: u32,
	desc:          SamplerDesc,
	shaderStages:  StageBits,
} // aka static (immutable) sampler

// https://docs.vulkan.org/refpages/latest/refpages/source/VkPipelineLayoutCreateInfo.html
// https://microsoft.github.io/DirectX-Specs/d3d/ResourceBinding.html#root-signature
// https://microsoft.github.io/DirectX-Specs/d3d/ResourceBinding.html#root-signature-version-11
/*
All indices are local in the currently bound pipeline layout. Pipeline layout example:
RootConstantDesc                #0          // "rootConstantIndex" - an index in "rootConstants" in the currently bound pipeline layout
...

RootDescriptorDesc              #0          // "rootDescriptorIndex" - an index in "rootDescriptors" in the currently bound pipeline layout
...

RootSamplerDesc                 #0
...

Descriptor set                  #0          // "setIndex" - a descriptor set index in the pipeline layout, provided as an argument or bound to the pipeline
Descriptor range                #0      // "rangeIndex" - a descriptor range index in the descriptor set
Descriptor num                  N   // "descriptorIndex" and "baseDescriptor" - a descriptor (base) index in the descriptor range, i.e. sub-range start
...
...
*/
PipelineLayoutDesc :: struct {
	rootRegisterSpace: u32, // must be unique, avoid big gaps
	rootConstants:     [^]RootConstantDesc,
	rootConstantNum:   u32,
	rootDescriptors:   [^]RootDescriptorDesc,
	rootDescriptorNum: u32,
	rootSamplers:      [^]RootSamplerDesc,
	rootSamplerNum:    u32,
	descriptorSets:    [^]DescriptorSetDesc,
	descriptorSetNum:  u32,
	shaderStages:      StageBits,
	flags:             PipelineLayoutBits,
}

// Descriptor pool
// https://learn.microsoft.com/en-us/windows/win32/direct3d12/descriptor-heaps
// https://learn.microsoft.com/en-us/windows/win32/api/d3d12/ns-d3d12-d3d12_descriptor_heap_desc
// https://docs.vulkan.org/refpages/latest/refpages/source/VkDescriptorPoolCreateInfo.html
DescriptorPoolDesc :: struct {
	// Maximum number of descriptor sets that can be allocated from this pool
	descriptorSetMaxNum: u32,
	mutableMaxNum:       u32, // number of "MUTABLE" descriptors, requires "features.mutableDescriptorType"

	// Sampler heap
	// - may be directly indexed in shaders via "SAMPLER_HEAP_DIRECTLY_INDEXED" pipeline layout flag
	// - root samplers do not count (not allocated from a descriptor pool)
	samplerMaxNum: u32, // number of "SAMPLER" descriptors

	// Optimized resources (may have various sizes depending on Vulkan implementation)
	constantBufferMaxNum:          u32, // number of "CONSTANT_BUFFER" descriptors
	textureMaxNum:                 u32, // number of "TEXTURE" descriptors
	storageTextureMaxNum:          u32, // number of "STORAGE_TEXTURE" descriptors
	bufferMaxNum:                  u32, // number of "BUFFER" descriptors
	storageBufferMaxNum:           u32, // number of "STORAGE_BUFFER" descriptors
	structuredBufferMaxNum:        u32, // number of "STRUCTURED_BUFFER" descriptors
	storageStructuredBufferMaxNum: u32, // number of "STORAGE_STRUCTURED_BUFFER" descriptors
	accelerationStructureMaxNum:   u32, // number of "ACCELERATION_STRUCTURE" descriptors, requires "features.rayTracing"
	inputAttachmentMaxNum:         u32, // number of "INPUT_ATTACHMENT" descriptors
	flags:                         DescriptorPoolBits,
}

// Updating/initializing descriptors in a descriptor set
UpdateDescriptorRangeDesc :: struct {
	// Destination
	descriptorSet:  ^DescriptorSet,
	rangeIndex:     u32,
	baseDescriptor: u32,

	// Source & count
	descriptors:   [^]^Descriptor, // all descriptors must have the same type
	descriptorNum: u32,
}

// Copying descriptors between descriptor sets
CopyDescriptorRangeDesc :: struct {
	// Destination
	dstDescriptorSet:  ^DescriptorSet,
	dstRangeIndex:     u32,
	dstBaseDescriptor: u32,

	// Source & count
	srcDescriptorSet:  ^DescriptorSet,
	srcRangeIndex:     u32,
	srcBaseDescriptor: u32,
	descriptorNum:     u32, // can be "ALL" (source)
}

// Binding
SetDescriptorSetDesc :: struct {
	setIndex:      u32,
	descriptorSet: ^DescriptorSet,
	bindPoint:     BindPoint,
}

SetRootConstantsDesc :: struct {
	rootConstantIndex: u32,
	data:              rawptr,
	size:              u32,
	offset:            u32, // requires "features.rootConstantsOffset"
	bindPoint:         BindPoint,
} // requires "pipelineLayoutRootConstantMaxSize > 0"

SetRootDescriptorDesc :: struct {
	rootDescriptorIndex: u32,
	descriptor:          ^Descriptor,
	offset:              u32, // a non-"CONSTANT_BUFFER" descriptor requires "features.nonConstantBufferRootDescriptorOffset"
	bindPoint:           BindPoint,
} // requires "pipelineLayoutRootDescriptorMaxNum > 0"

//============================================================================================================================================================================================
IndexType :: enum u8 {
	//============================================================================================================================================================================================
	UINT16  = 0,

	//============================================================================================================================================================================================
	UINT32  = 1,

	//============================================================================================================================================================================================
	MAX_NUM = 2,
}

PrimitiveRestart :: enum u8 {
	DISABLED       = 0,
	INDICES_UINT16 = 1,
	INDICES_UINT32 = 2,
	MAX_NUM        = 3,
}

// https://docs.vulkan.org/refpages/latest/refpages/source/VkVertexInputRate.html
VertexStreamStepRate :: enum u8 {
	PER_VERTEX   = 0,
	PER_INSTANCE = 1,
	MAX_NUM      = 2,
}

// https://docs.vulkan.org/refpages/latest/refpages/source/VkPrimitiveTopology.html
// https://learn.microsoft.com/en-us/windows/win32/api/d3dcommon/ne-d3dcommon-d3d_primitive_topology
// https://learn.microsoft.com/en-us/windows/win32/api/d3d12/ne-d3d12-d3d12_primitive_topology_type
Topology :: enum u8 {
	POINT_LIST                    = 0,
	LINE_LIST                     = 1,
	LINE_STRIP                    = 2,
	TRIANGLE_LIST                 = 3,
	TRIANGLE_STRIP                = 4,
	LINE_LIST_WITH_ADJACENCY      = 5,
	LINE_STRIP_WITH_ADJACENCY     = 6,
	TRIANGLE_LIST_WITH_ADJACENCY  = 7,
	TRIANGLE_STRIP_WITH_ADJACENCY = 8,
	PATCH_LIST                    = 9,
	MAX_NUM                       = 10,
}

InputAssemblyDesc :: struct {
	topology:            Topology,
	tessControlPointNum: u8,
	primitiveRestart:    PrimitiveRestart,
}

VertexAttributeD3D :: struct {
	semanticName:  cstring,
	semanticIndex: u32,
}

VertexAttributeVK :: struct {
	location: u32,
}

VertexAttributeDesc :: struct {
	d3d:         VertexAttributeD3D,
	vk:          VertexAttributeVK,
	offset:      u32,
	format:      Format,
	streamIndex: u16,
}

VertexStreamDesc :: struct {
	bindingSlot: u16,
	stepRate:    VertexStreamStepRate,
	stride:      u16, // fallback if "features.extendedDynamicState" is not supported
}

VertexInputDesc :: struct {
	attributes:   [^]VertexAttributeDesc,
	attributeNum: u8,
	streams:      [^]VertexStreamDesc,
	streamNum:    u8,
}

VertexBufferDesc :: struct {
	buffer: ^Buffer,
	offset: u64,
	stride: u32, // requires "features.extendedDynamicState", ignored otherwise, use "VertexStreamDesc::stride" instead
}

// https://docs.vulkan.org/refpages/latest/refpages/source/VkPolygonMode.html
// https://learn.microsoft.com/en-us/windows/win32/api/d3d12/ne-d3d12-d3d12_fill_mode
FillMode :: enum u8 {
	SOLID     = 0,
	WIREFRAME = 1,
	MAX_NUM   = 2,
}

// https://docs.vulkan.org/refpages/latest/refpages/source/VkCullModeFlagBits.html
// https://learn.microsoft.com/en-us/windows/win32/api/d3d12/ne-d3d12-d3d12_cull_mode
CullMode :: enum u8 {
	NONE    = 0,
	FRONT   = 1,
	BACK    = 2,
	MAX_NUM = 3,
}

// https://docs.vulkan.org/samples/latest/samples/extensions/fragment_shading_rate_dynamic/README.html
// https://microsoft.github.io/DirectX-Specs/d3d/VariableRateShading.html
ShadingRate :: enum u8 {
	FRAGMENT_SIZE_1X1 = 0,
	FRAGMENT_SIZE_1X2 = 1,
	FRAGMENT_SIZE_2X1 = 2,
	FRAGMENT_SIZE_2X2 = 3,
	FRAGMENT_SIZE_2X4 = 4,
	FRAGMENT_SIZE_4X2 = 5,
	FRAGMENT_SIZE_4X4 = 6,
	MAX_NUM           = 7,
}

// https://docs.vulkan.org/refpages/latest/refpages/source/VkFragmentShadingRateCombinerOpKHR.html
// https://learn.microsoft.com/en-us/windows/win32/api/d3d12/ne-d3d12-d3d12_shading_rate_combiner
//    "primitiveCombiner"      "attachmentCombiner"
// A   Pipeline shading rate    Result of Op1
// B   Primitive shading rate   Attachment shading rate
ShadingRateCombiner :: enum u8 {
	//    "primitiveCombiner"      "attachmentCombiner"
	// A   Pipeline shading rate    Result of Op1
	// B   Primitive shading rate   Attachment shading rate
	KEEP    = 0,

	//    "primitiveCombiner"      "attachmentCombiner"
	// A   Pipeline shading rate    Result of Op1
	// B   Primitive shading rate   Attachment shading rate
	REPLACE = 1,

	//    "primitiveCombiner"      "attachmentCombiner"
	// A   Pipeline shading rate    Result of Op1
	// B   Primitive shading rate   Attachment shading rate
	MIN     = 2,

	//    "primitiveCombiner"      "attachmentCombiner"
	// A   Pipeline shading rate    Result of Op1
	// B   Primitive shading rate   Attachment shading rate
	MAX     = 3,

	//    "primitiveCombiner"      "attachmentCombiner"
	// A   Pipeline shading rate    Result of Op1
	// B   Primitive shading rate   Attachment shading rate
	SUM     = 4,

	//    "primitiveCombiner"      "attachmentCombiner"
	// A   Pipeline shading rate    Result of Op1
	// B   Primitive shading rate   Attachment shading rate
	MAX_NUM = 5,
}

/*
https://registry.khronos.org/vulkan/specs/latest/html/vkspec.html#primsrast-depthbias-computation
https://learn.microsoft.com/en-us/windows/win32/direct3d11/d3d10-graphics-programming-guide-output-merger-stage-depth-bias
R - minimum resolvable difference
S - maximum slope

bias = constant * R + slopeFactor * S
if (clamp > 0)
bias = min(bias, clamp)
else if (clamp < 0)
bias = max(bias, clamp)

enabled if constant != 0 or slope != 0
*/
DepthBiasDesc :: struct {
	constant: f32,
	clamp:    f32,
	slope:    f32,
}

RasterizationDesc :: struct {
	depthBias:             DepthBiasDesc,
	fillMode:              FillMode,
	cullMode:              CullMode,
	frontCounterClockwise: bool,
	depthClamp:            bool,
	lineSmoothing:         bool, // requires "features.lineSmoothing"
	conservativeRaster:    bool, // requires "tiers.conservativeRaster != 0"
	shadingRate:           bool, // requires "tiers.shadingRate != 0", expects "CmdSetShadingRate" and optionally "RenderingDesc::shadingRate"
}

MultisampleDesc :: struct {
	sampleMask:      u32,  // can be "ALL"
	sampleNum:       Sample_t,
	alphaToCoverage: bool,
	sampleLocations: bool, // requires "tiers.sampleLocations != 0", expects "CmdSetSampleLocations"
}

ShadingRateDesc :: struct {
	shadingRate:        ShadingRate,
	primitiveCombiner:  ShadingRateCombiner,
	attachmentCombiner: ShadingRateCombiner,
}

//============================================================================================================================================================================================
Multiview :: enum u8 {
	//============================================================================================================================================================================================
	FLEXIBLE       = 0,

	//============================================================================================================================================================================================
	LAYER_BASED    = 1,

	//============================================================================================================================================================================================
	VIEWPORT_BASED = 2,

	//============================================================================================================================================================================================
	MAX_NUM        = 3,
}

// https://docs.vulkan.org/refpages/latest/refpages/source/VkLogicOp.html
// https://learn.microsoft.com/en-us/windows/win32/api/d3d12/ne-d3d12-d3d12_logic_op
// S - source color 0
// D - destination color
LogicOp :: enum u8 {
	// S - source color 0
	// D - destination color
	NONE          = 0,

	// S - source color 0
	// D - destination color
	CLEAR         = 1,

	// S - source color 0
	// D - destination color
	AND           = 2,

	// S - source color 0
	// D - destination color
	AND_REVERSE   = 3,

	// S - source color 0
	// D - destination color
	COPY          = 4,

	// S - source color 0
	// D - destination color
	AND_INVERTED  = 5,

	// S - source color 0
	// D - destination color
	XOR           = 6,

	// S - source color 0
	// D - destination color
	OR            = 7,

	// S - source color 0
	// D - destination color
	NOR           = 8,

	// S - source color 0
	// D - destination color
	EQUIVALENT    = 9,

	// S - source color 0
	// D - destination color
	INVERT        = 10,

	// S - source color 0
	// D - destination color
	OR_REVERSE    = 11,

	// S - source color 0
	// D - destination color
	COPY_INVERTED = 12,

	// S - source color 0
	// D - destination color
	OR_INVERTED   = 13,

	// S - source color 0
	// D - destination color
	NAND          = 14,

	// S - source color 0
	// D - destination color
	SET           = 15,

	// S - source color 0
	// D - destination color
	MAX_NUM       = 16,
}

// https://docs.vulkan.org/refpages/latest/refpages/source/VkStencilOp.html
// https://learn.microsoft.com/en-us/windows/win32/api/d3d12/ne-d3d12-d3d12_stencil_op
// R - reference, set by "CmdSetStencilReference"
// D - stencil buffer
StencilOp :: enum u8 {
	// R - reference, set by "CmdSetStencilReference"
	// D - stencil buffer
	KEEP                = 0,

	// R - reference, set by "CmdSetStencilReference"
	// D - stencil buffer
	ZERO                = 1,

	// R - reference, set by "CmdSetStencilReference"
	// D - stencil buffer
	REPLACE             = 2,

	// R - reference, set by "CmdSetStencilReference"
	// D - stencil buffer
	INCREMENT_AND_CLAMP = 3,

	// R - reference, set by "CmdSetStencilReference"
	// D - stencil buffer
	DECREMENT_AND_CLAMP = 4,

	// R - reference, set by "CmdSetStencilReference"
	// D - stencil buffer
	INVERT              = 5,

	// R - reference, set by "CmdSetStencilReference"
	// D - stencil buffer
	INCREMENT_AND_WRAP  = 6,

	// R - reference, set by "CmdSetStencilReference"
	// D - stencil buffer
	DECREMENT_AND_WRAP  = 7,

	// R - reference, set by "CmdSetStencilReference"
	// D - stencil buffer
	MAX_NUM             = 8,
}

// https://docs.vulkan.org/refpages/latest/refpages/source/VkBlendFactor.html
// https://learn.microsoft.com/en-us/windows/win32/api/d3d12/ne-d3d12-d3d12_blend
// S0 - source color 0
// S1 - source color 1
// D - destination color
// C - blend constants, set by "CmdSetBlendConstants"
BlendFactor :: enum u8 {
	// S0 - source color 0
	// S1 - source color 1
	// D - destination color
	// C - blend constants, set by "CmdSetBlendConstants"
	ZERO                     = 0,  // RGB                               ALPHA

	// S0 - source color 0
	// S1 - source color 1
	// D - destination color
	// C - blend constants, set by "CmdSetBlendConstants"
	ONE                      = 1,  // RGB                               ALPHA

	// S0 - source color 0
	// S1 - source color 1
	// D - destination color
	// C - blend constants, set by "CmdSetBlendConstants"
	SRC_COLOR                = 2,  // RGB                               ALPHA

	// S0 - source color 0
	// S1 - source color 1
	// D - destination color
	// C - blend constants, set by "CmdSetBlendConstants"
	ONE_MINUS_SRC_COLOR      = 3,  // RGB                               ALPHA

	// S0 - source color 0
	// S1 - source color 1
	// D - destination color
	// C - blend constants, set by "CmdSetBlendConstants"
	DST_COLOR                = 4,  // RGB                               ALPHA

	// S0 - source color 0
	// S1 - source color 1
	// D - destination color
	// C - blend constants, set by "CmdSetBlendConstants"
	ONE_MINUS_DST_COLOR      = 5,  // RGB                               ALPHA

	// S0 - source color 0
	// S1 - source color 1
	// D - destination color
	// C - blend constants, set by "CmdSetBlendConstants"
	SRC_ALPHA                = 6,  // RGB                               ALPHA

	// S0 - source color 0
	// S1 - source color 1
	// D - destination color
	// C - blend constants, set by "CmdSetBlendConstants"
	ONE_MINUS_SRC_ALPHA      = 7,  // RGB                               ALPHA

	// S0 - source color 0
	// S1 - source color 1
	// D - destination color
	// C - blend constants, set by "CmdSetBlendConstants"
	DST_ALPHA                = 8,  // RGB                               ALPHA

	// S0 - source color 0
	// S1 - source color 1
	// D - destination color
	// C - blend constants, set by "CmdSetBlendConstants"
	ONE_MINUS_DST_ALPHA      = 9,  // RGB                               ALPHA

	// S0 - source color 0
	// S1 - source color 1
	// D - destination color
	// C - blend constants, set by "CmdSetBlendConstants"
	CONSTANT_COLOR           = 10, // RGB                               ALPHA

	// S0 - source color 0
	// S1 - source color 1
	// D - destination color
	// C - blend constants, set by "CmdSetBlendConstants"
	ONE_MINUS_CONSTANT_COLOR = 11, // RGB                               ALPHA

	// S0 - source color 0
	// S1 - source color 1
	// D - destination color
	// C - blend constants, set by "CmdSetBlendConstants"
	CONSTANT_ALPHA           = 12, // RGB                               ALPHA

	// S0 - source color 0
	// S1 - source color 1
	// D - destination color
	// C - blend constants, set by "CmdSetBlendConstants"
	ONE_MINUS_CONSTANT_ALPHA = 13, // RGB                               ALPHA

	// S0 - source color 0
	// S1 - source color 1
	// D - destination color
	// C - blend constants, set by "CmdSetBlendConstants"
	SRC_ALPHA_SATURATE       = 14, // RGB                               ALPHA

	// S0 - source color 0
	// S1 - source color 1
	// D - destination color
	// C - blend constants, set by "CmdSetBlendConstants"
	SRC1_COLOR               = 15, // RGB                               ALPHA

	// S0 - source color 0
	// S1 - source color 1
	// D - destination color
	// C - blend constants, set by "CmdSetBlendConstants"
	ONE_MINUS_SRC1_COLOR     = 16, // RGB                               ALPHA

	// S0 - source color 0
	// S1 - source color 1
	// D - destination color
	// C - blend constants, set by "CmdSetBlendConstants"
	SRC1_ALPHA               = 17, // RGB                               ALPHA

	// S0 - source color 0
	// S1 - source color 1
	// D - destination color
	// C - blend constants, set by "CmdSetBlendConstants"
	ONE_MINUS_SRC1_ALPHA     = 18, // RGB                               ALPHA

	// S0 - source color 0
	// S1 - source color 1
	// D - destination color
	// C - blend constants, set by "CmdSetBlendConstants"
	MAX_NUM                  = 19, // RGB                               ALPHA
} // RGB                               ALPHA

// https://docs.vulkan.org/refpages/latest/refpages/source/VkBlendOp.html
// https://learn.microsoft.com/en-us/windows/win32/api/d3d12/ne-d3d12-d3d12_blend_op
// S - source color
// D - destination color
// Sf - source factor, produced by "BlendFactor"
// Df - destination factor, produced by "BlendFactor"
BlendOp :: enum u8 {
	// S - source color
	// D - destination color
	// Sf - source factor, produced by "BlendFactor"
	// Df - destination factor, produced by "BlendFactor"
	ADD              = 0,

	// S - source color
	// D - destination color
	// Sf - source factor, produced by "BlendFactor"
	// Df - destination factor, produced by "BlendFactor"
	SUBTRACT         = 1,

	// S - source color
	// D - destination color
	// Sf - source factor, produced by "BlendFactor"
	// Df - destination factor, produced by "BlendFactor"
	REVERSE_SUBTRACT = 2,

	// S - source color
	// D - destination color
	// Sf - source factor, produced by "BlendFactor"
	// Df - destination factor, produced by "BlendFactor"
	MIN              = 3,

	// S - source color
	// D - destination color
	// Sf - source factor, produced by "BlendFactor"
	// Df - destination factor, produced by "BlendFactor"
	MAX              = 4,

	// S - source color
	// D - destination color
	// Sf - source factor, produced by "BlendFactor"
	// Df - destination factor, produced by "BlendFactor"
	MAX_NUM          = 5,
}

ColorWriteBitsEnum :: enum u8 {
	R = 0,
	G = 1,
	B = 2,
	A = 3,
}

// https://docs.vulkan.org/refpages/latest/refpages/source/VkColorComponentFlagBits.html
ColorWriteBits :: bit_set[ColorWriteBitsEnum; u8]
COLORWRITEBITS_RGBA :: ColorWriteBits {.R, .G, .B, .A}
COLORWRITEBITS_RGB  :: ColorWriteBits {.R, .G, .B}

// https://docs.vulkan.org/refpages/latest/refpages/source/VkStencilOpState.html
// https://learn.microsoft.com/en-us/windows/win32/api/d3d12/ns-d3d12-d3d12_depth_stencil_desc
StencilDesc :: struct {
	compareOp:   CompareOp, // "compareOp != NONE", expects "CmdSetStencilReference"
	failOp:      StencilOp,
	passOp:      StencilOp,
	depthFailOp: StencilOp,
	writeMask:   u8,
	compareMask: u8,
}

// https://docs.vulkan.org/refpages/latest/refpages/source/VkPipelineDepthStencilStateCreateInfo.html
DepthAttachmentDesc :: struct {
	compareOp:  CompareOp,
	write:      bool,
	boundsTest: bool, // requires "features.depthBoundsTest", expects "CmdSetDepthBounds"
}

StencilAttachmentDesc :: struct {
	front: StencilDesc,
	back:  StencilDesc, // requires "features.independentFrontAndBackStencilReferenceAndMasks" for "back.writeMask"
}

// https://docs.vulkan.org/refpages/latest/refpages/source/VkPipelineColorBlendAttachmentState.html
// https://learn.microsoft.com/en-us/windows/win32/api/d3d12/ns-d3d12-d3d12_render_target_blend_desc
BlendDesc :: struct {
	srcFactor: BlendFactor,
	dstFactor: BlendFactor,
	op:        BlendOp,
}

ColorAttachmentDesc :: struct {
	format:         Format,
	colorBlend:     BlendDesc,
	alphaBlend:     BlendDesc,
	colorWriteMask: ColorWriteBits,
	blendEnabled:   bool,
}

OutputMergerDesc :: struct {
	colors:             [^]ColorAttachmentDesc,
	colorNum:           u32,
	depth:              DepthAttachmentDesc,
	stencil:            StencilAttachmentDesc,
	depthStencilFormat: Format,
	logicOp:            LogicOp,   // requires "features.logicOp"
	viewMask:           u32,       // if non-0, requires "viewMaxNum > 1"
	multiview:          Multiview, // if "viewMask != 0", requires "features.(xxx)Multiview"
}

// https://docs.vulkan.org/guide/latest/robustness.html
Robustness :: enum u8 {
	DEFAULT = 0,
	OFF     = 1,
	VK      = 2,
	D3D12   = 3,
	MAX_NUM = 4,
}

GraphicsPipelineBits :: enum u8 {
	NONE               = 0,
	FAIL_ON_CACHE_MISS = 1,
}

ComputePipelineBits :: enum u8 {
	NONE               = 0,
	FAIL_ON_CACHE_MISS = 1,
}

PipelineCacheDesc :: struct {
	data: rawptr, // "data = NULL" means empty cache
	size: u64,
}

// It's recommended to use "NRI.hlsl" in the shader code
ShaderDesc :: struct {
	stage:          StageBits,
	bytecode:       rawptr, // see "features.shaderBytecodeXXX"
	size:           u64,
	entryPointName: cstring,
}

GraphicsPipelineDesc :: struct {
	pipelineLayout: ^PipelineLayout,
	vertexInput:    ^VertexInputDesc,
	inputAssembly:  InputAssemblyDesc,
	rasterization:  RasterizationDesc,
	multisample:    ^MultisampleDesc,
	outputMerger:   OutputMergerDesc,
	shaders:        [^]ShaderDesc,
	shaderNum:      u32,
	flags:          GraphicsPipelineBits,
	robustness:     Robustness,
	cache:          ^PipelineCache, // if non-NULL, pipeline creation can be served from a cached blob and the result will be added to the cache on a miss
}

ComputePipelineDesc :: struct {
	pipelineLayout: ^PipelineLayout,
	shader:         ShaderDesc,
	flags:          ComputePipelineBits,
	robustness:     Robustness,
	cache:          ^PipelineCache, // if non-NULL, pipeline creation can be served from a cached blob and the result will be added to the cache on a miss
}

// https://learn.microsoft.com/en-us/windows/win32/api/d3d12/ne-d3d12-d3d12_render_pass_beginning_access_type
// https://docs.vulkan.org/refpages/latest/refpages/source/VkAttachmentLoadOp.html
LoadOp :: enum u8 {
	LOAD    = 0,
	CLEAR   = 1,
	MAX_NUM = 2,
}

// https://learn.microsoft.com/en-us/windows/win32/api/d3d12/ne-d3d12-d3d12_render_pass_ending_access_type
// https://docs.vulkan.org/refpages/latest/refpages/source/VkAttachmentStoreOp.html
StoreOp :: enum u8 {
	STORE   = 0,
	DISCARD = 1,
	MAX_NUM = 2,
}

// https://learn.microsoft.com/en-us/windows/win32/api/d3d12/ne-d3d12-d3d12_resolve_mode
// https://docs.vulkan.org/refpages/latest/refpages/source/VkResolveModeFlagBits.html
ResolveOp :: enum u8 {
	AVERAGE = 0,
	MIN     = 1,
	MAX     = 2,
	MAX_NUM = 3,
}

AttachmentDesc :: struct {
	descriptor: ^Descriptor,
	clearValue: ClearValue,
	loadOp:     LoadOp,
	storeOp:    StoreOp,
	resolveOp:  ResolveOp,
	resolveDst: ^Descriptor, // must be in "COLOR_ATTACHMENT" state and valid during "CmdEndRendering"
}

// If "VK_KHR_dynamic_rendering" is not supported:
// - "VkRenderPass" is used under the hood
// - input attachments must be transitioned to "Layout::INPUT_ATTACHMENT" in the same command buffer before "CmdBeginRendering"
// - matching pipeline input attachment indices are inferred from these transitions
RenderingDesc :: struct {
	colors:      [^]AttachmentDesc,
	colorNum:    u32,
	depth:       AttachmentDesc, // may be treated as "depth-stencil"
	stencil:     AttachmentDesc, // (optional) separation is needed for multisample resolve
	shadingRate: ^Descriptor,    // requires "tiers.shadingRate >= 2"
	viewMask:    u32,            // if non-0, requires "viewMaxNum > 1"
}

// https://microsoft.github.io/DirectX-Specs/d3d/CountersAndQueries.html
// https://docs.vulkan.org/refpages/latest/refpages/source/VkQueryType.html
QueryType :: enum u8 {
	TIMESTAMP                             = 0,
	TIMESTAMP_COPY_QUEUE                  = 1,
	OCCLUSION                             = 2,
	PIPELINE_STATISTICS                   = 3,
	ACCELERATION_STRUCTURE_SIZE           = 4,
	ACCELERATION_STRUCTURE_COMPACTED_SIZE = 5,
	MICROMAP_COMPACTED_SIZE               = 6,
	MAX_NUM                               = 7,
}

QueryPoolDesc :: struct {
	queryType: QueryType,
	capacity:  u32,
}

// Data layout for QueryType::PIPELINE_STATISTICS
// https://docs.vulkan.org/refpages/latest/refpages/source/VkQueryPipelineStatisticFlagBits.html
// https://learn.microsoft.com/en-us/windows/win32/api/d3d12/ns-d3d12-d3d12_query_data_pipeline_statistics
PipelineStatisticsDesc :: struct {
	// Common part
	inputVertexNum:                    u64,
	inputPrimitiveNum:                 u64,
	vertexShaderInvocationNum:         u64,
	geometryShaderInvocationNum:       u64,
	geometryShaderPrimitiveNum:        u64,
	rasterizerInPrimitiveNum:          u64,
	rasterizerOutPrimitiveNum:         u64,
	fragmentShaderInvocationNum:       u64,
	tessControlShaderInvocationNum:    u64,
	tessEvaluationShaderInvocationNum: u64,
	computeShaderInvocationNum:        u64,

	// If "features.meshShaderPipelineStats"
	taskShaderInvocationNum: u64,
	meshShaderInvocationNum: u64,

	// D3D12: if "features.meshShaderPipelineStats"
	meshShaderPrimitiveNum: u64,
}

// Command signatures (default)
DrawDesc :: struct {
	vertexNum:    u32,
	instanceNum:  u32,
	baseVertex:   u32, // vertex buffer offset = CmdSetVertexBuffers.offset + baseVertex * VertexStreamDesc::stride
	baseInstance: u32,
} // see NRI_FILL_DRAW_DESC

DrawIndexedDesc :: struct {
	indexNum:     u32,
	instanceNum:  u32,
	baseIndex:    u32, // index buffer offset = CmdSetIndexBuffer.offset + baseIndex * sizeof(CmdSetIndexBuffer.indexType)
	baseVertex:   i32, // index += baseVertex
	baseInstance: u32,
} // see NRI_FILL_DRAW_INDEXED_DESC

DispatchDesc :: struct {
	x, y, z: u32,
}

// Modified draw command signatures, if the bound pipeline layout has "PipelineLayoutBits::ENABLE_DRAW_PARAMETERS_EMULATION"
// "PipelineLayoutBits::ENABLE_DRAW_INDEX_EMULATION" does not change the command layout
DrawBaseDesc :: struct {
	shaderEmulatedBaseVertex:   u32, // root constant
	shaderEmulatedBaseInstance: u32, // root constant
	vertexNum:                  u32,
	instanceNum:                u32,
	baseVertex:                 u32, // vertex buffer offset = CmdSetVertexBuffers.offset + baseVertex * VertexStreamDesc::stride
	baseInstance:               u32,
} // see NRI_FILL_DRAW_DESC

DrawIndexedBaseDesc :: struct {
	shaderEmulatedBaseVertex:   i32, // root constant
	shaderEmulatedBaseInstance: u32, // root constant
	indexNum:                   u32,
	instanceNum:                u32,
	baseIndex:                  u32, // index buffer offset = CmdSetIndexBuffer.offset + baseIndex * sizeof(CmdSetIndexBuffer.indexType)
	baseVertex:                 i32, // index += baseVertex
	baseInstance:               u32,
} // see NRI_FILL_DRAW_INDEXED_DESC

// Copy
TextureRegionDesc :: struct {
	x:           Dim_t,
	y:           Dim_t,
	z:           Dim_t,
	width:       Dim_t, // can be "WHOLE_SIZE" (mip)
	height:      Dim_t, // can be "WHOLE_SIZE" (mip)
	depth:       Dim_t, // can be "WHOLE_SIZE" (mip)
	mipOffset:   Dim_t,
	layerOffset: Dim_t,
	planes:      PlaneBits,
}

TextureDataLayoutDesc :: struct {
	offset:     u64, // a buffer offset must be a multiple of "uploadBufferTextureSliceAlignment" (data placement alignment)
	rowPitch:   u32, // must be a multiple of "uploadBufferTextureRowAlignment"
	slicePitch: u32, // must be a multiple of "uploadBufferTextureSliceAlignment"
}

// Work submission
FenceSubmitDesc :: struct {
	fence:  ^Fence,
	value:  u64,
	stages: StageBits,
}

QueueSubmitDesc :: struct {
	waitFences:       [^]FenceSubmitDesc,
	waitFenceNum:     u32,
	commandBuffers:   [^]^CommandBuffer,
	commandBufferNum: u32,
	signalFences:     [^]FenceSubmitDesc,
	signalFenceNum:   u32,
	swapChain:        ^SwapChain, // required if "NRILowLatency" is enabled in the swap chain
}

// Clear
ClearAttachmentDesc :: struct {
	value:                ClearValue,
	planes:               PlaneBits,
	colorAttachmentIndex: u8,
}

// Required synchronization
// - variant 1: "SHADER_RESOURCE_STORAGE" access ("SHADER_RESOURCE_STORAGE" layout) and "CLEAR_STORAGE" stage + any shader stage (or "ALL")
// - variant 2: "CLEAR_STORAGE" access ("SHADER_RESOURCE_STORAGE" layout) and "CLEAR_STORAGE" stage
ClearStorageDesc :: struct {
	// For any buffers and textures with integer formats:
	//  - Clears a storage descriptor with bit-precise values, copying the lower "N" bits from "value.[f/ui/i].channel"
	//    to the corresponding channel, where "N" is the number of bits in the "channel" of the resource format
	// For textures with non-integer formats:
	//  - Clears a storage descriptor with float values with format conversion from "FLOAT" to "UNORM/SNORM" where appropriate
	// For buffers:
	//  - To avoid discrepancies in behavior between GAPIs use "R32f/ui/i" formats for views
	//  - D3D: structured buffers are unsupported!
	descriptor:      ^Descriptor, // a "STORAGE" descriptor
	value:           Color,       // avoid overflow
	setIndex:        u32,
	rangeIndex:      u32,
	descriptorIndex: u32,
}

//============================================================================================================================================================================================
Vendor :: enum u8 {
	//============================================================================================================================================================================================
	UNKNOWN = 0,

	//============================================================================================================================================================================================
	NVIDIA  = 1,

	//============================================================================================================================================================================================
	AMD     = 2,

	//============================================================================================================================================================================================
	INTEL   = 3,

	//============================================================================================================================================================================================
	MAX_NUM = 4,
}

// https://docs.vulkan.org/refpages/latest/refpages/source/VkPhysicalDeviceType.html
Architecture :: enum u8 {
	UNKNOWN    = 0,
	SOFTWARE   = 1,
	VIRTUAL    = 2,
	INTEGRATED = 3,
	DISCRETE   = 4,
	MAX_NUM    = 5,
}

// https://docs.vulkan.org/refpages/latest/refpages/source/VkQueueFlagBits.html
// https://learn.microsoft.com/en-us/windows/win32/api/d3d12/ne-d3d12-d3d12_command_list_type
QueueType :: enum u8 {
	GRAPHICS = 0,
	COMPUTE  = 1,
	COPY     = 2,
	MAX_NUM  = 3,
}

AdapterDesc :: struct {
	name:                   [256]i8,
	uid:                    Uid_t, // "LUID" (preferred) if "uid.high = 0", or "UUID" otherwise
	videoMemorySize:        u64,
	sharedSystemMemorySize: u64,
	deviceId:               u32,
	driverVersion:          u32,   // GAPI and OS dependent
	queueNum:               [3]u32,
	vendor:                 Vendor,
	architecture:           Architecture,
	supportedGraphicsAPIs:  GraphicsAPI,
}

// Feature support coverage: https://vulkan.gpuinfo.org/ and https://d3d12infodb.boolka.dev/
DeviceDesc :: struct {
	// Common
	adapterDesc: AdapterDesc, // "queueNum" reflects available number of queues per "QueueType"
	graphicsAPI: GraphicsAPI,
	nriVersion:  u16,
	shaderModel: u16,         // see "NriShaderModel"

	viewport: struct {
		maxNum:    u32,
		boundsMin: i32,
		boundsMax: i32,
	},

	dimensions: struct {
		typedBufferMaxDim:     u32,
		attachmentMaxDim:      Dim_t,
		attachmentLayerMaxNum: Dim_t,
		texture1DMaxDim:       Dim_t,
		texture2DMaxDim:       Dim_t,
		texture3DMaxDim:       Dim_t,
		textureLayerMaxNum:    Dim_t,
	},

	precision: struct {
		viewportBits: u32,
		subPixelBits: u32,
		subTexelBits: u32,
		mipmapBits:   u32,
	},

	memory: struct {
		deviceUploadHeapSize:     u64, // ReBAR
		bufferMaxSize:            u64,
		allocationMaxSize:        u64,
		allocationMaxNum:         u32,
		samplerAllocationMaxNum:  u32,
		constantBufferMaxRange:   u32,
		storageBufferMaxRange:    u32,
		bufferTextureGranularity: u32, // specifies a page-like granularity at which linear and non-linear resources must be placed in adjacent memory locations to avoid aliasing
		alignmentDefault:         u32, // (INTERNAL) worst-case alignment for a memory allocation respecting all possible placed resources, excluding multisample textures
		alignmentMultisample:     u32, // (INTERNAL) worst-case alignment for a memory allocation respecting all possible placed resources, including multisample textures
	},

	memoryAlignment: struct {
		uploadBufferTextureRow:      u32,
		uploadBufferTextureSlice:    u32,
		bufferShaderResourceOffset:  u32,
		constantBufferOffset:        u32,
		scratchBufferOffset:         u32,
		shaderBindingTable:          u32,
		accelerationStructureOffset: u32,
		micromapOffset:              u32,
	},

	pipelineLayout: struct {
		descriptorSetMaxNum:  u32,
		rootConstantMaxSize:  u32,
		rootDescriptorMaxNum: u32,
	},

	descriptorSet: struct {
		samplerMaxNum:        u32,
		constantBufferMaxNum: u32,
		storageBufferMaxNum:  u32,
		textureMaxNum:        u32,
		storageTextureMaxNum: u32,

		updateAfterSet: struct {
			samplerMaxNum:        u32,
			constantBufferMaxNum: u32,
			storageBufferMaxNum:  u32,
			textureMaxNum:        u32,
			storageTextureMaxNum: u32,
		},
	},

	shaderStage: struct {
		// Per stage resources
		descriptorSamplerMaxNum:        u32,
		descriptorConstantBufferMaxNum: u32,
		descriptorStorageBufferMaxNum:  u32,
		descriptorTextureMaxNum:        u32,
		descriptorStorageTextureMaxNum: u32,
		resourceMaxNum:                 u32,

		updateAfterSet: struct {
			descriptorSamplerMaxNum:        u32,
			descriptorConstantBufferMaxNum: u32,
			descriptorStorageBufferMaxNum:  u32,
			descriptorTextureMaxNum:        u32,
			descriptorStorageTextureMaxNum: u32,
			resourceMaxNum:                 u32,
		},

		vertex: struct {
			attributeMaxNum:       u32,
			streamMaxNum:          u32,
			outputComponentMaxNum: u32,
		},

		tesselationControl: struct {
			generationMaxLevel:             f32,
			patchPointMaxNum:               u32,
			perVertexInputComponentMaxNum:  u32,
			perVertexOutputComponentMaxNum: u32,
			perPatchOutputComponentMaxNum:  u32,
			totalOutputComponentMaxNum:     u32,
		},

		tesselationEvaluation: struct {
			inputComponentMaxNum:  u32,
			outputComponentMaxNum: u32,
		},

		geometry: struct {
			invocationMaxNum:           u32,
			inputComponentMaxNum:       u32,
			outputComponentMaxNum:      u32,
			outputVertexMaxNum:         u32,
			totalOutputComponentMaxNum: u32,
		},

		fragment: struct {
			inputComponentMaxNum:       u32,
			attachmentMaxNum:           u32,
			dualSourceAttachmentMaxNum: u32,
		},

		compute: struct {
			dispatchMaxDim:            [3]u32,
			workGroupInvocationMaxNum: u32,
			workGroupMaxDim:           [3]u32,
			sharedMemoryMaxSize:       u32,
		},

		task: struct {
			dispatchWorkGroupMaxNum:   u32,
			dispatchMaxDim:            [3]u32,
			workGroupInvocationMaxNum: u32,
			workGroupMaxDim:           [3]u32,
			sharedMemoryMaxSize:       u32,
			payloadMaxSize:            u32,
		},

		mesh: struct {
			dispatchWorkGroupMaxNum:   u32,
			dispatchMaxDim:            [3]u32,
			workGroupInvocationMaxNum: u32,
			workGroupMaxDim:           [3]u32,
			sharedMemoryMaxSize:       u32,
			outputVerticesMaxNum:      u32,
			outputPrimitiveMaxNum:     u32,
			outputComponentMaxNum:     u32,
		},

		rayTracing: struct {
			shaderGroupIdentifierSize:   u32,
			shaderBindingTableMaxStride: u32,
			recursionMaxDepth:           u32,
		},
	},

	accelerationStructure: struct {
		primitiveMaxNum:             u64, // per BLAS
		geometryMaxNum:              u64, // per BLAS
		instanceMaxNum:              u64, // per TLAS
		micromapSubdivisionMaxLevel: u32,
	},

	wave: struct {
		laneMinNum:          u32,
		laneMaxNum:          u32,
		waveOpsStages:       StageBits, // SM 6.0+ (see "shaderFeatures.waveX")
		quadOpsStages:       StageBits, // SM 6.0+ (see "shaderFeatures.waveQuad")
		derivativeOpsStages: StageBits, // SM 6.6+ (https://microsoft.github.io/DirectX-Specs/d3d/HLSL_SM_6_6_Derivatives.html#derivative-functions)
	},

	other: struct {
		timestampFrequencyHz:              u64,
		drawIndirectMaxNum:                u32,
		samplerLodBiasMax:                 f32,
		samplerAnisotropyMax:              f32,
		texelGatherOffsetMin:              i8,
		texelOffsetMin:                    i8,
		texelOffsetMax:                    u8,
		texelGatherOffsetMax:              u8,
		clipDistanceMaxNum:                u8,
		cullDistanceMaxNum:                u8,
		combinedClipAndCullDistanceMaxNum: u8,
		viewMaxNum:                        u8, // multiview is supported if > 1
		shadingRateAttachmentTileSize:     u8, // square size
	},

	tiers: struct {
		// 1 - 1/2 pixel uncertainty region and does not support post-snap degenerates
		// 2 - reduces the maximum uncertainty region to 1/256 and requires post-snap degenerates not be culled
		// 3 - maintains a maximum 1/256 uncertainty region and adds support for inner input coverage, aka "SV_InnerCoverage"
		conservativeRaster: u8,

		// 1 - a single sample pattern can be specified to repeat for every pixel ("locationNum / sampleNum" ratio must be 1 in "CmdSetSampleLocations"),
		//     1x and 16x sample counts do not support programmable locations
		// 2 - four separate sample patterns can be specified for each pixel in a 2x2 grid ("locationNum / sampleNum" ratio can be 1 or 4 in "CmdSetSampleLocations"),
		//     all sample counts support programmable positions
		sampleLocations: u8,

		// 1 - DXR 1.0: full raytracing functionality, except features below
		// 2 - DXR 1.1: adds - ray query, "CmdDispatchRaysIndirect", "GeometryIndex()" intrinsic, additional ray flags & vertex formats
		// 3 - DXR 1.2: adds - micromap, shader execution reordering
		rayTracing: u8,

		// 1 - shading rate can be specified only per draw
		// 2 - adds: per primitive shading rate, per "shadingRateAttachmentTileSize" shading rate, combiners, "SV_ShadingRate" support
		shadingRate: u8,

		// 0 - ALL descriptors in range must be valid by the time the command list executes
		// 1 - only "CONSTANT_BUFFER" and "STORAGE" descriptors in range must be valid
		// 2 - only referenced descriptors must be valid
		resourceBinding: u8,
		bindless:        u8,

		// 1 - a "Memory" can support resources from all 3 categories: buffers, attachments, all other textures
		memory: u8,
	},

	features: struct {
		// Swap chain
		swapChain:          bool, // NRISwapChain
		presentFromCompute: bool, // see "SwapChainDesc::queue"
		waitableSwapChain:  bool, // see "SwapChainDesc::waitable"
		resizableSwapChain: bool, // swap chain can be resized without triggering an "OUT_OF_DATE" error

		// Multi view
		flexibleMultiview:      bool, // see "Multiview::FLEXIBLE"
		layerBasedMultiview:    bool, // see "Multiview::LAYRED_BASED"
		viewportBasedMultiview: bool, // see "Multiview::VIEWPORT_BASED"

		// Texture compression
		textureCompressionBC:   bool, // all "BC" texture formats are supported
		textureCompressionETC2: bool, // all "ETC2" texture formats are supported
		textureCompressionASTC: bool, // all "ASTC" texture formats are supported

		// Shader bytecode
		shaderBytecodeDXBC:  bool, // DXBC can be passed to "ShaderDesc::bytecode"
		shaderBytecodeDXIL:  bool, // DXIL can be passed to "ShaderDesc::bytecode"
		shaderBytecodeSPIRV: bool, // SPIRV can be passed to "ShaderDesc::bytecode", WGPU expects Vulkan 1.2 environment
		shaderBytecodeWGSL:  bool, // WGSL can be passed to "ShaderDesc::bytecode"

		// Queries
		occlusion:            bool, // see "QueryType::OCCLUSION"
		timestamp:            bool, // see "QueryType::TIMESTAMP"
		timestampCopyQueue:   bool, // see "QueryType::TIMESTAMP_COPY_QUEUE"
		calibratedTimestamps: bool, // see "GetCalibratedTimestamps"

		// Shading rate
		additionalShadingRates: bool, // see "ShadingRate"
		sumShadingRateCombiner: bool, // see "ShadingRateCombiner::SUM"

		// Resolve
		regionResolve:   bool, // see "CmdResolveTexture"
		resolveOpMinMax: bool, // see "ResolveOp"

		// Pipeline cache
		pipelineCache:        bool, // "PipelineCache" support (NOP fallback if unsupported, except on error)
		pipelineCacheControl: bool, // "FAIL_ON_CACHE_MISS" enforces "FAILURE", useful for platforms that prohibit runtime PSO compilation (e.g., Xbox GDK)

		// Other
		getMemoryDesc2:                                  bool, // "GetXxxMemoryDesc2" support (VK: requires "maintenance4", D3D: supported)
		enhancedBarriers:                                bool, // VK: supported, D3D12: requires "AgilitySDK", D3D11: unsupported
		tessellationShader:                              bool, // Tessellation control and evaluation shader stages
		geometryShader:                                  bool, // Geometry shader stage
		meshShader:                                      bool, // NRIMeshShader
		lowLatency:                                      bool, // NRILowLatency
		componentSwizzle:                                bool, // see "ComponentSwizzle" (unsupported only in D3D11)
		independentFrontAndBackStencilReferenceAndMasks: bool, // see "StencilAttachmentDesc::back"
		filterOpMinMax:                                  bool, // see "FilterOp"
		logicOp:                                         bool, // see "LogicOp"
		depthBoundsTest:                                 bool, // see "DepthAttachmentDesc::boundsTest"
		drawIndirectCount:                               bool, // see "countBuffer" and "countBufferOffset"
		lineSmoothing:                                   bool, // see "RasterizationDesc::lineSmoothing"
		meshShaderPipelineStats:                         bool, // see "PipelineStatisticsDesc"
		dynamicDepthBias:                                bool, // see "CmdSetDepthBias"
		viewportOriginBottomLeft:                        bool, // see "Viewport"
		pipelineStatistics:                              bool, // see "QueryType::PIPELINE_STATISTICS"
		rootConstantsOffset:                             bool, // see "SetRootConstantsDesc" (unsupported only in D3D11)
		nonConstantBufferRootDescriptorOffset:           bool, // see "SetRootDescriptorDesc" (unsupported only in D3D11)
		mutableDescriptorType:                           bool, // see "DescriptorType::MUTABLE"
		extendedDynamicState:                            bool, // VK: allows to use "VertexBufferDesc::stride" (dynamic) instead of "VertexStreamDesc::stride" (static). Widely supported
		unifiedTextureLayouts:                           bool, // VK: allows to use "GENERAL" everywhere: https://docs.vulkan.org/refpages/latest/refpages/source/VK_KHR_unified_image_layouts.html
	},

	shaderFeatures: struct {
		nativeI8:                  bool, // "(u)int8_t"
		nativeI16:                 bool, // "(u)int16_t"
		nativeF16:                 bool, // "float16_t"
		nativeI64:                 bool, // "(u)int64_t"
		nativeF64:                 bool, // "double"
		atomicsI16:                bool, // "(u)int16_t" atomics
		atomicsF16:                bool, // "float16_t" atomics
		atomicsF32:                bool, // "float" atomics
		atomicsI64:                bool, // "(u)int64_t" atomics
		atomicsF64:                bool, // "double" atomics
		storageReadWithoutFormat:  bool, // NRI_FORMAT("unknown") is allowed for storage reads
		storageWriteWithoutFormat: bool, // NRI_FORMAT("unknown") is allowed for storage writes
		waveQuery:                 bool, // WaveIsFirstLane, WaveGetLaneCount, WaveGetLaneIndex
		waveVote:                  bool, // WaveActiveAllTrue, WaveActiveAnyTrue, WaveActiveAllEqual
		waveShuffle:               bool, // WaveReadLaneFirst, WaveReadLaneAt
		waveArithmetic:            bool, // WaveActiveSum, WaveActiveProduct, WaveActiveMin, WaveActiveMax, WavePrefixProduct, WavePrefixSum
		waveReduction:             bool, // WaveActiveCountBits, WaveActiveBitAnd, WaveActiveBitOr, WaveActiveBitXor, WavePrefixCountBits
		waveQuad:                  bool, // QuadReadLaneAt, QuadReadAcrossX, QuadReadAcrossY, QuadReadAcrossDiagonal

		// Other
		viewportIndex:           bool, // SV_ViewportArrayIndex, always can be used in geometry shaders
		layerIndex:              bool, // SV_RenderTargetArrayIndex, always can be used in geometry shaders
		unnormalizedCoordinates: bool, // https://microsoft.github.io/DirectX-Specs/d3d/VulkanOn12.html#non-normalized-texture-sampling-coordinates
		clock:                   bool, // https://github.com/Microsoft/DirectXShaderCompiler/blob/main/docs/SPIR-V.rst#readclock
		rasterizedOrderedView:   bool, // https://microsoft.github.io/DirectX-Specs/d3d/RasterOrderViews.html (aka fragment shader interlock)
		barycentric:             bool, // https://github.com/microsoft/DirectXShaderCompiler/wiki/SV_Barycentrics
		rayTracingPositionFetch: bool, // https://docs.vulkan.org/features/latest/features/proposals/VK_KHR_ray_tracing_position_fetch.html
		integerDotProduct:       bool, // https://github.com/microsoft/DirectXShaderCompiler/wiki/Shader-Model-6.4
		inputAttachments:        bool, // https://github.com/Microsoft/DirectXShaderCompiler/blob/main/docs/SPIR-V.rst#subpass-inputs
		drawParameters:          bool, // GAPI-independent "NRI_BASE_VERTEX", "NRI_BASE_INSTANCE", "NRI_VERTEX_ID_OFFSET" and "NRI_INSTANCE_ID_OFFSET" (see "NRI.hlsl" for expected usage)
		drawIndex:               bool, // GAPI-independent "NRI_DRAW_ID" (see "NRI.hlsl" for expected usage)
	},
}

