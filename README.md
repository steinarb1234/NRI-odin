# NRI-odin

Bindings for [Nvidia NRI](https://github.com/NVIDIA-RTX/NRI) version 177 in Odin.

Copy NRI.dll to the root directory of your project to use the library. Currently, only Windows binaries are included. You can use them directly, or compile NRI from source and replace the lib and dll files yourself. 

Every graphics API is enabled in the included binaries (D3D11, D3D12 and Vulkan). The Imgui extension is also enabled.

I have made sample code for using these bindings public on github [here](https://github.com/steinarb1234/NRI-odin-samples).

Credit to lodinukal for his NRI bindings. These bindings are built upon his work.
