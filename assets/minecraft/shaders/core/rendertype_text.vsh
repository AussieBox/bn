#version 330

#moj_import <minecraft:fog.glsl>
#moj_import <minecraft:dynamictransforms.glsl>
#moj_import <minecraft:projection.glsl>
#moj_import <minecraft:globals.glsl>

in vec3 Position;
in vec4 Color;
in vec2 UV0;
in ivec2 UV2;

uniform sampler2D Sampler2;

out float sphericalVertexDistance;
out float cylindricalVertexDistance;
out vec4 vertexColor;
out vec2 texCoord0;

vec3 channel(float opacity, float c1, float c2) {
    return vec3(opacity, c1, c2);
}

bool matches(vec3 rawChannel, vec3 matchWith255) {
    vec3 current255 = rawChannel * 255.0;
    
    return (distance(current255.g, matchWith255.g) < 0.5) && 
           (distance(current255.b, matchWith255.b) < 0.5);
}

bool matchesWithOpacity(vec3 rawChannel, vec3 matchWith255) {
    vec3 current255 = rawChannel * 255.0;
    
    return (distance(current255.r, matchWith255.r) < 0.5) && 
            (distance(current255.g, matchWith255.g) < 0.5) && 
            (distance(current255.b, matchWith255.b) < 0.5);
}

// Keep in mind that textures MUST be a vertical strip to work. I'm not smart enough to add support for the other way too lol
// Params:
// currentPos - The current vertex position, should just be a variable that equals Position
// channel - The channel to match. My channel system uses RED for opacity, GREEN for the first channel, and BLUE for the second one. RED value is ignored.
// correctedColor - The color to make the vertex if it's being animated. Works in RGBA order.
// textureHeight - The overall height of the texture (EVERY FRAME!!!)
// frameHeight - The height of one frame (they all have to be the same, sadly)
// frames - The number of frames total.
// ticksPerFrame - Number of in-game ticks per frame (again, they all have to be the same sadly)
vec3 animateIfMatchesChannel(vec3 currentPos, vec3 channel, vec4 correctedColor, float textureHeight, float frameHeight, float frames, float ticksPerFrame) {
    if (!matches(Color.rgb, channel)) return currentPos;
    vertexColor = correctedColor;

    float currentFrame = mod(floor((GameTime * 24000.0) / ticksPerFrame), frames);

    int cornerIndex = gl_VertexID % 4;
    vec2 localUV = vec2(0.0);
    if (cornerIndex == 0) localUV = vec2(0.0, 0.0);
    if (cornerIndex == 1) localUV = vec2(0.0, 1.0);
    if (cornerIndex == 2) localUV = vec2(1.0, 1.0);
    if (cornerIndex == 3) localUV = vec2(1.0, 0.0);

    float pixelSizeV = 1.0 / 256.0;
    
    float frameHeightV = frameHeight * pixelSizeV;
    
    float atlasMinV = (localUV.y == 0.0) ? UV0.y : (UV0.y - (textureHeight * pixelSizeV));
    
    float frameShiftV = currentFrame * frameHeightV;
    float finalMinV = atlasMinV + frameShiftV;

    texCoord0.x = UV0.x;
    
    texCoord0.y = (localUV.y == 0.0) ? finalMinV : (finalMinV + frameHeightV);

    currentPos.y *= (frameHeight/textureHeight);
    return currentPos;
}

void main() {
    float alpha = Color.a; 
    
    bool isQueueBossbar = matches(Color.rgb, channel(255.0, 1.0, 0.0));
    
    vertexColor = Color * texelFetch(Sampler2, UV2 / 16, 0);
    texCoord0 = UV0;
    vec3 animationPos = Position;
    
    // Example usage, ofc replace this :3c
    animationPos = animateIfMatchesChannel(animationPos, channel(255.0, 1.0, 0.0), vec4(1.0, 1.0, 1.0, alpha), 248.0, 31.0, 8.0, 20.0);

    gl_Position = ProjMat * ModelViewMat * vec4(animationPos, 1.0);

    sphericalVertexDistance = fog_spherical_distance(Position);
    cylindricalVertexDistance = fog_cylindrical_distance(Position);
}