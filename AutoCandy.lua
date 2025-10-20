-- ✅ Script Auto-Teleport + Camera Spin (Loadstring Ready)
-- Khi up lên GitHub, chỉ cần gọi:
-- loadstring(game:HttpGet("https://raw.githubusercontent.com/<user>/<repo>/main/AutoTP.lua"))()

local httpGetUrl = "https://raw.githubusercontent.com/<user>/<repo>/main/AutoTP.lua" -- 🟢 đổi link GitHub của ông

-- Tự động tải code từ link (hoặc dùng nội bộ nếu không có mạng)
local success, result = pcall(function()
    return game:HttpGet(httpGetUrl)
end)

if success and result and #result > 0 then
    loadstring(result)()
    return
end

-- Dưới đây là fallback: code chạy trực tiếp khi không thể tải từ link
-- Auto-teleport 1→19 + top-down super-fast camera
-- Tự resume khi respawn trong cùng phiên chơi. Dừng khi bấm P (toggle) hoặc khi rời game.
-- CẢNH BÁO: Một số game có anti-cheat; dùng cẩn thận.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
if not player then return end

-- ========== CẤU HÌNH ==========
local delayBetweenTeleports = 0.5
local spinSpeed = 20.0
local cameraHeight = 60
local cameraRadius = 5
local toggleKey = Enum.KeyCode.P
local autoStart = true
-- ==============================

local locations = {
    Vector3.new(584.2, 111.8, -353.8),
    Vector3.new(481.9, 109.9, -350.5),
    Vector3.new(424.4, 110.2, -345.9),
    Vector3.new(389.9, 108.7, -160.8),
    Vector3.new(364.7, 109.5, -87.2),
    Vector3.new(425.7, 110.7, 28.7),
    Vector3.new(468.1, 109.4, 26.4),
    Vector3.new(513.1, 110.7, 32.1),
    Vector3.new(465.7, 109.3, -49.4),
    Vector3.new(463.1, 110.5, -104.2),
    Vector3.new(464.2, 112.0, -140.5),
    Vector3.new(597.1, 113.5, -285.8),
    Vector3.new(594.6, 109.7, -249.8),
    Vector3.new(705.0, 107.3, -360.8),
    Vector3.new(705.5, 109.5, -295.2),
    Vector3.new(803.8, 111.4, -292.5),
    Vector3.new(806.5, 110.3, -241.0),
    Vector3.new(804.4, 111.6, -197.6),
    Vector3.new(804.4, 110.5, -153.1),
}

local enabled = false
local cameraActive = false
local teleportActive = false

local camera = workspace.CurrentCamera
local spinConnection = nil
local teleportThread = nil

local function startCameraSpinForCharacter(char)
    if cameraActive then return end
    local hrp = char and (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("UpperTorso"))
    if not hrp then return end
    cameraActive = true
    camera.CameraType = Enum.CameraType.Scriptable
    local angle = 0
    spinConnection = RunService.RenderStepped:Connect(function(dt)
        if not cameraActive then return end
        if not hrp.Parent then return end
        angle = angle + spinSpeed * dt
        local pos = hrp.Position
        local camY = pos.Y + cameraHeight
        local camX = pos.X + math.cos(angle) * cameraRadius
        local camZ = pos.Z + math.sin(angle) * cameraRadius
        camera.CFrame = CFrame.new(Vector3.new(camX, camY, camZ), pos)
    end)
end

local function stopCameraSpin()
    if not cameraActive then return end
    cameraActive = false
    if spinConnection then
        spinConnection:Disconnect()
        spinConnection = nil
    end
    pcall(function() camera.CameraType = Enum.CameraType.Custom end)
end

local function teleportToPosForCharacter(char, pos)
    if not char or not char.Parent then return false end
    local hrp = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")
    if not hrp then return false end
    pcall(function()
        hrp.CFrame = CFrame.new(pos)
    end)
    return true
end

local function startTeleportLoopForCharacter(char)
    if teleportActive then return end
    if not char then return end
    teleportActive = true
    teleportThread = task.spawn(function()
        while teleportActive and char and char.Parent do
            for _, pos in ipairs(locations) do
                if not teleportActive or not char or not char.Parent then break end
                teleportToPosForCharacter(char, pos)
                local t = 0
                while t < delayBetweenTeleports and teleportActive and char and char.Parent do
                    task.wait(0.05)
                    t = t + 0.05
                end
            end
        end
        teleportActive = false
    end)
end

local function stopTeleportLoop()
    teleportActive = false
end

local function onCharacterAdded(char)
    char:WaitForChild("HumanoidRootPart", 5)
    if enabled then
        startCameraSpinForCharacter(char)
        startTeleportLoopForCharacter(char)
    end
end

local function onCharacterRemoving()
    stopTeleportLoop()
    stopCameraSpin()
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == toggleKey then
        if enabled then
            enabled = false
            stopTeleportLoop()
            stopCameraSpin()
            print("[AutoLoop] Đã tắt. Bấm P để bật lại.")
        else
            enabled = true
            local char = player.Character
            if char and char.Parent then
                startCameraSpinForCharacter(char)
                startTeleportLoopForCharacter(char)
            end
            print("[AutoLoop] Đã bật. Script sẽ resume tự động khi respawn.")
        end
    end
end)

player.CharacterAdded:Connect(onCharacterAdded)
player.CharacterRemoving:Connect(onCharacterRemoving)

if autoStart then
    enabled = true
    local char = player.Character
    if char and char.Parent then
        startCameraSpinForCharacter(char)
        startTeleportLoopForCharacter(char)
    end
end

print("[AutoLoop] Script loaded. P = bật/tắt. Script sẽ tự resume khi respawn trong phiên chơi.")
