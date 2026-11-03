@echo off
setlocal

echo Compiling shaders...
@REM echo Compiling dxil shaders...
@REM dxc -T vs_6_6 -E vertexMain -Fo shaders/cube_shader.dxil -WX -Zi -Qembed_debug shaders/cube_shader.hlsl -I shaders
@REM if %errorlevel% neq 0 (
@REM     echo Vertex shader compilation failed!
@REM     exit /b %errorlevel%
@REM )
@REM dxc -T ps_6_6 -E fragmentMain -Fo shaders/cube_shader.dxil -WX -Zi -Qembed_debug shaders/cube_shader.hlsl -I shaders
@REM if %errorlevel% neq 0 (
@REM     echo Pixel shader compilation failed!
@REM     exit /b %errorlevel%
@REM )

echo Compiling spirv shaders for D3D12...
"%VULKAN_SDK%\Bin\dxc.exe" -T vs_6_6 -E main -Fo shaders/triangle.vert.dxil shaders/triangle.vert.hlsl
if %errorlevel% neq 0 (
    echo Vertex shader compilation failed!
    exit /b %errorlevel%
)
"%VULKAN_SDK%\Bin\dxc.exe" -T ps_6_6 -E main -Fo shaders/triangle.frag.dxil shaders/triangle.frag.hlsl
if %errorlevel% neq 0 (
    echo Pixel shader compilation failed!
    exit /b %errorlevel%
)

echo Compiling spirv shaders for Vulkan...
"%VULKAN_SDK%\Bin\dxc.exe" -spirv -T vs_6_6 -E main -Fo shaders/triangle.vert.spv -WX -Zi -Qembed_debug shaders/triangle.vert.hlsl -I shaders -fspv-target-env=vulkan1.3 -fvk-use-dx-layout -fvk-use-dx-position-w
if %errorlevel% neq 0 (
    echo Vertex shader compilation failed!
    exit /b %errorlevel%
)
"%VULKAN_SDK%\Bin\dxc.exe" -spirv -T ps_6_6 -E main -Fo shaders/triangle.frag.spv -WX -Zi -Qembed_debug shaders/triangle.frag.hlsl -I shaders -fspv-target-env=vulkan1.3 -fvk-use-dx-layout
if %errorlevel% neq 0 (
    echo Pixel shader compilation failed!
    exit /b %errorlevel%
)

@REM echo Building Odin project...

@REM odin build . -o:speed -subsystem:windows
@REM if %errorlevel% neq 0 (
@REM     echo Build failed!
@REM     exit /b %errorlevel%
@REM )
@REM echo Build created successfully.

endlocal
