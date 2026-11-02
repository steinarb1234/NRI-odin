// © 2025 NVIDIA Corporation

// Goal: ImGui rendering
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

NRI_IMGUI_H :: 1

ImDrawList    :: struct {}
ImTextureData :: struct {}
Imgui         :: struct {}

ImguiDesc :: struct {
	descriptorPoolSize: u32, // upper bound of textures used by Imgui for drawing across all threads: {number of queued frames} * {number of "CmdDrawImgui" calls} * (1 + {"drawList->AddImage*" calls})
}

CopyImguiDataDesc :: struct {
	drawLists:   [^]^ImDrawList,    // ImDrawData::CmdLists.Data
	drawListNum: u32,               // ImDrawData::CmdLists.Size
	textures:    [^]^ImTextureData, // ImDrawData::Textures->Data (same as "ImGui::GetPlatformIO().Textures.Data")
	textureNum:  u32,               // ImDrawData::Textures->Size (same as "ImGui::GetPlatformIO().Textures.Size")
}

DrawImguiDesc :: struct {
	displaySize:      Dim2_t, // ImDrawData::DisplaySize
	hdrScale:         f32,    // SDR intensity in HDR mode (1 by default)
	attachmentFormat: Format, // destination attachment (render target) format
	linearColor:      bool,   // apply de-gamma to vertex colors (needed for sRGB attachments and HDR)
}

// Read-only input for "CmdDrawImgui"
ImguiRenderData :: struct {
	imgui:             ^Imgui,       // producing instance
	drawCommands:      rawptr,       // in transient Streamer host data
	vertices:          BufferOffset, // in transient Streamer buffer
	indexBufferOffset: u64,          // in "vertices.buffer"
	drawCmdNum:        u32,
}

// Threadsafe: yes, if command buffers are externally synchronized and Streamer thread safety is enabled (or provided externally).
// Access to shared "ImTextureData" is internally synchronized.
ImguiInterface :: struct {
	CreateImgui:  proc "c" (device: ^Device, imguiDesc: ^ImguiDesc, imgui: ^^Imgui) -> Result,
	DestroyImgui: proc "c" (imgui: ^Imgui),

	// Command buffer
	// {
	// Copy
	CmdCopyImguiData: proc "c" (commandBuffer: ^CommandBuffer, streamer: ^Streamer, imgui: ^Imgui, copyImguiDataDesc: ^CopyImguiDataDesc, imguiRenderData: ^ImguiRenderData),

	// Draw (changes descriptor pool, pipeline layout and pipeline, barriers are externally controlled)
	CmdDrawImgui: proc "c" (commandBuffer: ^CommandBuffer, imguiRenderData: ^ImguiRenderData, drawImguiDesc: ^DrawImguiDesc),
}

