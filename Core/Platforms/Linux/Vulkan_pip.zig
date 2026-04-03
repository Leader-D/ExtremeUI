const std = @import("std");
const Engine = @import("../Shad-gines/SPIR-V/Runtime/Engine.zig");

const c = @cImport({
    @cInclude("vulkan/vulkan.h");
});

pub const VulkanError = error{
    InstanceFailed,
    SurfaceFailed,
    NoSuitableGPU,
    DeviceFailed,
    SwapchainFailed,
    RenderPassFailed,
    PipelineFailed,
    CommandPoolFailed,
    CommandBufferFailed,
};

pub const VulkanContext = struct {
    instance:        c.VkInstance,
    surface:         c.VkSurfaceKHR,
    physical_device: c.VkPhysicalDevice,
    device:          c.VkDevice,
    graphics_queue:  c.VkQueue,
    swapchain:       c.VkSwapchainKHR,
    render_pass:     c.VkRenderPass,
    pipeline:        c.VkPipeline,
    pipeline_layout: c.VkPipelineLayout,
    command_pool:    c.VkCommandPool,
};

pub fn createInstance() !c.VkInstance {
    const app_info = c.VkApplicationInfo{
        .sType              = c.VK_STRUCTURE_TYPE_APPLICATION_INFO,
        .pNext              = null,
        .pApplicationName   = "ExtremeUI App",
        .applicationVersion = c.VK_MAKE_VERSION(0, 0, 1),
        .pEngineName        = "ExtremeUI",
        .engineVersion      = c.VK_MAKE_VERSION(0, 0, 1),
        .apiVersion         = c.VK_API_VERSION_1_3,
    };

    const extensions = [_][*c]const u8{
        c.VK_KHR_SURFACE_EXTENSION_NAME,
        "VK_KHR_xcb_surface",
    };

    const create_info = c.VkInstanceCreateInfo{
        .sType                   = c.VK_STRUCTURE_TYPE_INSTANCE_CREATE_INFO,
        .pNext                   = null,
        .flags                   = 0,
        .pApplicationInfo        = &app_info,
        .enabledLayerCount       = 0,
        .ppEnabledLayerNames     = null,
        .enabledExtensionCount   = extensions.len,
        .ppEnabledExtensionNames = &extensions,
    };

    var instance: c.VkInstance = undefined;
    if (c.vkCreateInstance(&create_info, null, &instance) != c.VK_SUCCESS)
        return VulkanError.InstanceFailed;

    return instance;
}

pub fn pickPhysicalDevice(instance: c.VkInstance) !c.VkPhysicalDevice {
    var count: u32 = 0;
    _ = c.vkEnumeratePhysicalDevices(instance, &count, null);
    if (count == 0) return VulkanError.NoSuitableGPU;

    var devices: [8]c.VkPhysicalDevice = undefined;
    _ = c.vkEnumeratePhysicalDevices(instance, &count, &devices);

    return devices[0];
}

pub fn createDevice(physical_device: c.VkPhysicalDevice) !struct { device: c.VkDevice, queue: c.VkQueue } {
    const queue_priority: f32 = 1.0;

    const queue_info = c.VkDeviceQueueCreateInfo{
        .sType            = c.VK_STRUCTURE_TYPE_DEVICE_QUEUE_CREATE_INFO,
        .pNext            = null,
        .flags            = 0,
        .queueFamilyIndex = 0,
        .queueCount       = 1,
        .pQueuePriorities = &queue_priority,
    };

    const device_extensions = [_][*c]const u8{
        c.VK_KHR_SWAPCHAIN_EXTENSION_NAME,
    };

    const create_info = c.VkDeviceCreateInfo{
        .sType                   = c.VK_STRUCTURE_TYPE_DEVICE_CREATE_INFO,
        .pNext                   = null,
        .flags                   = 0,
        .queueCreateInfoCount    = 1,
        .pQueueCreateInfos       = &queue_info,
        .enabledLayerCount       = 0,
        .ppEnabledLayerNames     = null,
        .enabledExtensionCount   = device_extensions.len,
        .ppEnabledExtensionNames = &device_extensions,
        .pEnabledFeatures        = null,
    };

    var device: c.VkDevice = undefined;
    if (c.vkCreateDevice(physical_device, &create_info, null, &device) != c.VK_SUCCESS)
        return VulkanError.DeviceFailed;

    var queue: c.VkQueue = undefined;
    c.vkGetDeviceQueue(device, 0, 0, &queue);

    return .{ .device = device, .queue = queue };
}

pub fn createRenderPass(device: c.VkDevice) !c.VkRenderPass {
    const attachment = c.VkAttachmentDescription{
        .flags          = 0,
        .format         = c.VK_FORMAT_B8G8R8A8_SRGB,
        .samples        = c.VK_SAMPLE_COUNT_1_BIT,
        .loadOp         = c.VK_ATTACHMENT_LOAD_OP_CLEAR,
        .storeOp        = c.VK_ATTACHMENT_STORE_OP_STORE,
        .stencilLoadOp  = c.VK_ATTACHMENT_LOAD_OP_DONT_CARE,
        .stencilStoreOp = c.VK_ATTACHMENT_STORE_OP_DONT_CARE,
        .initialLayout  = c.VK_IMAGE_LAYOUT_UNDEFINED,
        .finalLayout    = c.VK_IMAGE_LAYOUT_PRESENT_SRC_KHR,
    };

    const attachment_ref = c.VkAttachmentReference{
        .attachment = 0,
        .layout     = c.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL,
    };

    const subpass = c.VkSubpassDescription{
        .flags                   = 0,
        .pipelineBindPoint       = c.VK_PIPELINE_BIND_POINT_GRAPHICS,
        .inputAttachmentCount    = 0,
        .pInputAttachments       = null,
        .colorAttachmentCount    = 1,
        .pColorAttachments       = &attachment_ref,
        .pResolveAttachments     = null,
        .pDepthStencilAttachment = null,
        .preserveAttachmentCount = 0,
        .pPreserveAttachments    = null,
    };

    const render_pass_info = c.VkRenderPassCreateInfo{
        .sType           = c.VK_STRUCTURE_TYPE_RENDER_PASS_CREATE_INFO,
        .pNext           = null,
        .flags           = 0,
        .attachmentCount = 1,
        .pAttachments    = &attachment,
        .subpassCount    = 1,
        .pSubpasses      = &subpass,
        .dependencyCount = 0,
        .pDependencies   = null,
    };

    var render_pass: c.VkRenderPass = undefined;
    if (c.vkCreateRenderPass(device, &render_pass_info, null, &render_pass) != c.VK_SUCCESS)
        return VulkanError.RenderPassFailed;

    return render_pass;
}

fn createShaderModule(device: c.VkDevice, code: []u32) !c.VkShaderModule {
    const create_info = c.VkShaderModuleCreateInfo{
        .sType    = c.VK_STRUCTURE_TYPE_SHADER_MODULE_CREATE_INFO,
        .pNext    = null,
        .flags    = 0,
        .codeSize = code.len * @sizeOf(u32),
        .pCode    = code.ptr,
    };

    var shader_module: c.VkShaderModule = undefined;
    if (c.vkCreateShaderModule(device, &create_info, null, &shader_module) != c.VK_SUCCESS)
        return VulkanError.PipelineFailed;

    return shader_module;
}

pub fn createPipeline(
    allocator: std.mem.Allocator,
    device: c.VkDevice,
    render_pass: c.VkRenderPass,
) !struct { pipeline: c.VkPipeline, layout: c.VkPipelineLayout } {

    const vert_code = try Engine.buildShader(allocator, .vertex);
    defer allocator.free(vert_code);

    const frag_code = try Engine.buildShader(allocator, .fragment);
    defer allocator.free(frag_code);

    const vert_module = try createShaderModule(device, vert_code);
    defer c.vkDestroyShaderModule(device, vert_module, null);

    const frag_module = try createShaderModule(device, frag_code);
    defer c.vkDestroyShaderModule(device, frag_module, null);

    const shader_stages = [_]c.VkPipelineShaderStageCreateInfo{
        .{
            .sType               = c.VK_STRUCTURE_TYPE_PIPELINE_SHADER_STAGE_CREATE_INFO,
            .pNext               = null,
            .flags               = 0,
            .stage               = c.VK_SHADER_STAGE_VERTEX_BIT,
            .module              = vert_module,
            .pName               = "main",
            .pSpecializationInfo = null,
        },
        .{
            .sType               = c.VK_STRUCTURE_TYPE_PIPELINE_SHADER_STAGE_CREATE_INFO,
            .pNext               = null,
            .flags               = 0,
            .stage               = c.VK_SHADER_STAGE_FRAGMENT_BIT,
            .module              = frag_module,
            .pName               = "main",
            .pSpecializationInfo = null,
        },
    };

    const vertex_input = c.VkPipelineVertexInputStateCreateInfo{
        .sType                           = c.VK_STRUCTURE_TYPE_PIPELINE_VERTEX_INPUT_STATE_CREATE_INFO,
        .pNext                           = null,
        .flags                           = 0,
        .vertexBindingDescriptionCount   = 0,
        .pVertexBindingDescriptions      = null,
        .vertexAttributeDescriptionCount = 0,
        .pVertexAttributeDescriptions    = null,
    };

    const input_assembly = c.VkPipelineInputAssemblyStateCreateInfo{
        .sType                  = c.VK_STRUCTURE_TYPE_PIPELINE_INPUT_ASSEMBLY_STATE_CREATE_INFO,
        .pNext                  = null,
        .flags                  = 0,
        .topology               = c.VK_PRIMITIVE_TOPOLOGY_TRIANGLE_LIST,
        .primitiveRestartEnable = c.VK_FALSE,
    };

    const rasterizer = c.VkPipelineRasterizationStateCreateInfo{
        .sType                   = c.VK_STRUCTURE_TYPE_PIPELINE_RASTERIZATION_STATE_CREATE_INFO,
        .pNext                   = null,
        .flags                   = 0,
        .depthClampEnable        = c.VK_FALSE,
        .rasterizerDiscardEnable = c.VK_FALSE,
        .polygonMode             = c.VK_POLYGON_MODE_FILL,
        .cullMode                = c.VK_CULL_MODE_BACK_BIT,
        .frontFace               = c.VK_FRONT_FACE_CLOCKWISE,
        .depthBiasEnable         = c.VK_FALSE,
        .depthBiasConstantFactor = 0.0,
        .depthBiasClamp          = 0.0,
        .depthBiasSlopeFactor    = 0.0,
        .lineWidth               = 1.0,
    };

    const multisampling = c.VkPipelineMultisampleStateCreateInfo{
        .sType                 = c.VK_STRUCTURE_TYPE_PIPELINE_MULTISAMPLE_STATE_CREATE_INFO,
        .pNext                 = null,
        .flags                 = 0,
        .rasterizationSamples  = c.VK_SAMPLE_COUNT_1_BIT,
        .sampleShadingEnable   = c.VK_FALSE,
        .minSampleShading      = 1.0,
        .pSampleMask           = null,
        .alphaToCoverageEnable = c.VK_FALSE,
        .alphaToOneEnable      = c.VK_FALSE,
    };

    const color_blend_attachment = c.VkPipelineColorBlendAttachmentState{
        .blendEnable         = c.VK_FALSE,
        .srcColorBlendFactor = c.VK_BLEND_FACTOR_ONE,
        .dstColorBlendFactor = c.VK_BLEND_FACTOR_ZERO,
        .colorBlendOp        = c.VK_BLEND_OP_ADD,
        .srcAlphaBlendFactor = c.VK_BLEND_FACTOR_ONE,
        .dstAlphaBlendFactor = c.VK_BLEND_FACTOR_ZERO,
        .alphaBlendOp        = c.VK_BLEND_OP_ADD,
        .colorWriteMask      = c.VK_COLOR_COMPONENT_R_BIT | c.VK_COLOR_COMPONENT_G_BIT |
                               c.VK_COLOR_COMPONENT_B_BIT | c.VK_COLOR_COMPONENT_A_BIT,
    };

    const color_blending = c.VkPipelineColorBlendStateCreateInfo{
        .sType           = c.VK_STRUCTURE_TYPE_PIPELINE_COLOR_BLEND_STATE_CREATE_INFO,
        .pNext           = null,
        .flags           = 0,
        .logicOpEnable   = c.VK_FALSE,
        .logicOp         = c.VK_LOGIC_OP_COPY,
        .attachmentCount = 1,
        .pAttachments    = &color_blend_attachment,
        .blendConstants  = .{ 0.0, 0.0, 0.0, 0.0 },
    };

    const layout_info = c.VkPipelineLayoutCreateInfo{
        .sType                  = c.VK_STRUCTURE_TYPE_PIPELINE_LAYOUT_CREATE_INFO,
        .pNext                  = null,
        .flags                  = 0,
        .setLayoutCount         = 0,
        .pSetLayouts            = null,
        .pushConstantRangeCount = 0,
        .pPushConstantRanges    = null,
    };

    var layout: c.VkPipelineLayout = undefined;
    if (c.vkCreatePipelineLayout(device, &layout_info, null, &layout) != c.VK_SUCCESS)
        return VulkanError.PipelineFailed;

    const dynamic_states = [_]c.VkDynamicState{
        c.VK_DYNAMIC_STATE_VIEWPORT,
        c.VK_DYNAMIC_STATE_SCISSOR,
    };

    const dynamic_state = c.VkPipelineDynamicStateCreateInfo{
        .sType             = c.VK_STRUCTURE_TYPE_PIPELINE_DYNAMIC_STATE_CREATE_INFO,
        .pNext             = null,
        .flags             = 0,
        .dynamicStateCount = dynamic_states.len,
        .pDynamicStates    = &dynamic_states,
    };

    const viewport_state = c.VkPipelineViewportStateCreateInfo{
        .sType         = c.VK_STRUCTURE_TYPE_PIPELINE_VIEWPORT_STATE_CREATE_INFO,
        .pNext         = null,
        .flags         = 0,
        .viewportCount = 1,
        .pViewports    = null,
        .scissorCount  = 1,
        .pScissors     = null,
    };

    const pipeline_info = c.VkGraphicsPipelineCreateInfo{
        .sType               = c.VK_STRUCTURE_TYPE_GRAPHICS_PIPELINE_CREATE_INFO,
        .pNext               = null,
        .flags               = 0,
        .stageCount          = shader_stages.len,
        .pStages             = &shader_stages,
        .pVertexInputState   = &vertex_input,
        .pInputAssemblyState = &input_assembly,
        .pTessellationState  = null,
        .pViewportState      = &viewport_state,
        .pRasterizationState = &rasterizer,
        .pMultisampleState   = &multisampling,
        .pDepthStencilState  = null,
        .pColorBlendState    = &color_blending,
        .pDynamicState       = &dynamic_state,
        .layout              = layout,
        .renderPass          = render_pass,
        .subpass             = 0,
        .basePipelineHandle  = null,
        .basePipelineIndex   = -1,
    };

    var pipeline: c.VkPipeline = undefined;
    if (c.vkCreateGraphicsPipelines(device, null, 1, &pipeline_info, null, &pipeline) != c.VK_SUCCESS)
        return VulkanError.PipelineFailed;

    return .{ .pipeline = pipeline, .layout = layout };
}

pub fn init(allocator: std.mem.Allocator, surface: c.VkSurfaceKHR) !VulkanContext {
    const instance    = try createInstance();
    const physical    = try pickPhysicalDevice(instance);
    const dev         = try createDevice(physical);
    const render_pass = try createRenderPass(dev.device);
    const pip         = try createPipeline(allocator, dev.device, render_pass);

    return VulkanContext{
        .instance        = instance,
        .surface         = surface,
        .physical_device = physical,
        .device          = dev.device,
        .graphics_queue  = dev.queue,
        .swapchain       = undefined,
        .render_pass     = render_pass,
        .pipeline        = pip.pipeline,
        .pipeline_layout = pip.layout,
        .command_pool    = undefined,
    };
}
