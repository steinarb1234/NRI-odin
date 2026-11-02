// © 2025 NVIDIA Corporation

// Goal: providing easy-to-use access to modern upscalers: DLSS-SR, DLSS-RR, FSR, XeSS, NIS, MetalFX
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

NRI_UPSCALER_H :: 1

Upscaler     :: struct {}

UpscalerType :: enum u8 {
	NIS              = 0, // Name                                     // Notes
	FSR              = 1, // Name                                     // Notes
	XESS             = 2, // Name                                     // Notes
	DLSR             = 3, // Name                                     // Notes
	DLRR             = 4, // Name                                     // Notes
	METALFX_SPATIAL  = 5, // Name                                     // Notes
	METALFX_TEMPORAL = 6, // Name                                     // Notes
	METALFX_DENOISER = 7, // Name                                     // Notes
	MAX_NUM          = 8, // Name                                     // Notes
} // Name                                     // Notes

UpscalerMode :: enum u8 {
	NATIVE            = 0, // Scaling factor       // Min jitter phases (or just use unclamped Halton2D)
	ULTRA_QUALITY     = 1, // Scaling factor       // Min jitter phases (or just use unclamped Halton2D)
	QUALITY           = 2, // Scaling factor       // Min jitter phases (or just use unclamped Halton2D)
	BALANCED          = 3, // Scaling factor       // Min jitter phases (or just use unclamped Halton2D)
	PERFORMANCE       = 4, // Scaling factor       // Min jitter phases (or just use unclamped Halton2D)
	ULTRA_PERFORMANCE = 5, // Scaling factor       // Min jitter phases (or just use unclamped Halton2D)
	MAX_NUM           = 6, // Scaling factor       // Min jitter phases (or just use unclamped Halton2D)
} // Scaling factor       // Min jitter phases (or just use unclamped Halton2D)

UpscalerBitsEnum :: enum u16 {
	HDR            = 0,
	SRGB           = 1,
	USE_EXPOSURE   = 2,
	USE_REACTIVE   = 3,
	DEPTH_INVERTED = 4,
	DEPTH_INFINITE = 5,
	DEPTH_LINEAR   = 6,
	MV_UPSCALED    = 7,
	MV_JITTERED    = 8,
}

UpscalerBits :: bit_set[UpscalerBitsEnum; u16]

DispatchUpscaleBitsEnum :: enum u8 {
	RESET_HISTORY       = 0,
	USE_SPECULAR_MOTION = 1,
}

DispatchUpscaleBits :: bit_set[DispatchUpscaleBitsEnum; u8]

UpscalerDesc :: struct {
	upscaleResolution: Dim2_t,         // output resolution
	type:              UpscalerType,
	mode:              UpscalerMode,   // selects the scaling factor reported by "GetUpscalerProps"
	flags:             UpscalerBits,
	preset:            u8,             // 0: default; DLSR/DLRR: NGX preset; XESS: SDK network model + 1
	outputFormat:      Format,         // needed only for NIS, if "shaderFeatures.storageWriteWithoutFormat" is unsupported
	commandBuffer:     ^CommandBuffer, // DLSR/DLRR: graphics or compute command buffer in recording state; caller submits it (internal submission and wait otherwise)
}

UpscalerProps :: struct {
	scalingFactor:       f32,    // scaling factor per dimension
	mipBias:             f32,    // mip bias for material textures, computed as "-log2(scalingFactor) - 1" (keep an eye on normal maps)
	upscaleResolution:   Dim2_t, // output resolution
	renderResolution:    Dim2_t, // optimal render resolution
	renderResolutionMin: Dim2_t, // minimum render resolution (for dynamic resolution scaling)
	jitterPhaseNum:      u8,     // minimum number of phases in the jitter sequence, computed as "ceil(8 * scalingFactor ^ 2)" ("Halton(2, 3)" recommended)
}

UpscalerResource :: struct {
	texture:    ^Texture,
	descriptor: ^Descriptor, // "TEXTURE" or "STORAGE_TEXTURE" descriptor, see requirements below
}

// Guide textures
UpscalerGuides :: struct {
	mv:       UpscalerResource, // .xy - surface motion
	depth:    UpscalerResource, // .x - HW depth
	exposure: UpscalerResource, // .x - 1x1 exposure
	reactive: UpscalerResource, // .x - bias towards "input"
} // For FSR, XESS, DLSR, METALFX_TEMPORAL

DenoiserGuides :: struct {
	mv:               UpscalerResource, // .xy - surface motion
	depth:            UpscalerResource, // .x - hardware depth (DLRR also supports linear view-space Z via "DEPTH_LINEAR")
	normalRoughness:  UpscalerResource, // .xyz - world-space normal (not encoded), .w - linear roughness
	diffuseAlbedo:    UpscalerResource, // .xyz - diffuse albedo (LDR sky color for sky)
	specularAlbedo:   UpscalerResource, // .xyz - specular albedo (environment BRDF)
	specularMvOrHitT: UpscalerResource, // .xy - specular virtual motion when "USE_SPECULAR_MOTION" is set; .x - specular hit distance otherwise (METALFX_DENOISER requires hit distance)
	exposure:         UpscalerResource, // .x - 1x1 exposure
	reactive:         UpscalerResource, // .x - bias towards "input"

	// DLRR only
	preTransparency: UpscalerResource, // .xyz - color before transparency (aka transparency guide)
	sss:             UpscalerResource, // .x - subsurface scattering, computed as "Luminance(colorAfterSSS - colorBeforeSSS)"
} // For DLRR, METALFX_DENOISER

// Settings
NISSettings :: struct {
	sharpness: f32, // [0; 1]
}

FSRSettings :: struct {
	zNear:                   f32, // distance to the near plane (units)
	zFar:                    f32, // distance to the far plane, unused if "DEPTH_INFINITE" is set (units)
	verticalFov:             f32, // vertical field of view angle (radians)
	frameTime:               f32, // the time elapsed since the last frame (ms)
	viewSpaceToMetersFactor: f32, // for converting view space units to meters (m/unit)
	sharpness:               f32, // [0; 1]
}

DLRRSettings :: struct {
	worldToViewMatrix: [16]f32, // {Xx, Yx, Zx, 0, Xy, Yy, Zy, 0, Xz, Yz, Zz, 0, Tx, Ty, Tz, 1}, where {X, Y, Z} - axes, T - translation
	viewToClipMatrix:  [16]f32, // {-, -, -, 0, -, -, -, 0, -, -, -, A, -, -, -, B}, where {A; B} = {0; 1} for ortho or {-1/+1; 0} for perspective projections
}

DispatchUpscaleDesc :: struct {
	// Output (requires "SHADER_RESOURCE_STORAGE" state and a "STORAGE_TEXTURE" descriptor)
	// - MetalFX: requires "COLOR_ATTACHMENT" usage
	output: UpscalerResource, // .xyz - upscaled RGB color

	// Input (requires "SHADER_RESOURCE" state and a "TEXTURE" descriptor)
	input: UpscalerResource, // .xyz - input RGB color

	guides: struct #raw_union {
		upscaler: UpscalerGuides, //      FSR, XESS, DLSR, METALFX_TEMPORAL
		denoiser: DenoiserGuides, //      DLRR, METALFX_DENOISER (sRGB not supported)
	},

	settings: struct #raw_union {
		nis:  NISSettings,  //      NIS settings
		fsr:  FSRSettings,  //      FSR settings
		dlrr: DLRRSettings, //      DLRR and METALFX_DENOISER settings
	},

	currentResolution: Dim2_t,   // active input resolution, renderResolutionMin <= currentResolution <= renderResolution
	cameraJitter:      Float2_t, // jitter offset in pixels, towards the pixel center, each component in [-0.5; 0.5]
	mvScale:           Float2_t, // component-wise multiplier converting motion vectors to pixel space
	preExposure:       f32,      // multiplier already applied to the "input" color, 0 means 1 (FSR, XESS, DLSR, DLRR, METALFX_TEMPORAL, METALFX_DENOISER)
	flags:             DispatchUpscaleBits,
}

// Threadsafe: yes
UpscalerInterface :: struct {
	CreateUpscaler:      proc "c" (device: ^Device, upscalerDesc: ^UpscalerDesc, upscaler: ^^Upscaler) -> Result,
	DestroyUpscaler:     proc "c" (upscaler: ^Upscaler),
	IsUpscalerSupported: proc "c" (device: ^Device, type: UpscalerType) -> bool,
	GetUpscalerProps:    proc "c" (upscaler: ^Upscaler, upscalerProps: ^UpscalerProps),

	// Command buffer
	// {
	// Dispatch (changes descriptor pool, pipeline layout and pipeline, barriers are externally controlled)
	// MetalFX:
	// - Native creation occurs on the first dispatch and may cause a hitch
	// - Resource dimensions and formats must remain unchanged after the first dispatch
	CmdDispatchUpscale: proc "c" (commandBuffer: ^CommandBuffer, upscaler: ^Upscaler, dispatchUpscaleDesc: ^DispatchUpscaleDesc),
}

