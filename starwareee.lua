-- Roblox Lua KeyAuth 驗證範例 我已經寫出來完整的給你看了 你還說你不會用我就真沒法救你了
-- 請確保您的執行器支援 http_request 或 syn.request 不支援別狗叫說不能用
local HttpService = game:GetService("HttpService")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")

local appName = "dinoware's Application"
local ownerId = "29Z30W"
local publicKey = "384d9eb0fce192c16d2a7322f67b7ab08e212fb9a02d8dc50a53402e194ba484"
local apiBase = "https://keyauth-frontend.vercel.app/api/license_1"

local ScreenGui = Instance.new("ScreenGui", game.CoreGui)
ScreenGui.Name = "LicenseGui"

local Frame = Instance.new("Frame", ScreenGui)
Frame.AnchorPoint = Vector2.new(0.5, 0.5)
Frame.Position = UDim2.new(0.5, 0, 0.5, 0)
Frame.Size = UDim2.new(0, 350, 0, 200)
Frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
Frame.BorderSizePixel = 0
Frame.BackgroundTransparency = 0.1
Frame.Active = true

local dragging, dragInput, dragStart, startPos
local function update(input)
	local delta = input.Position - dragStart
	Frame.Position = UDim2.new(
		startPos.X.Scale, startPos.X.Offset + delta.X,
		startPos.Y.Scale, startPos.Y.Offset + delta.Y
	)
end

Frame.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = input.Position
		startPos = Frame.Position

		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				dragging = false
			end
		end)
	end
end)

Frame.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
		dragInput = input
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if input == dragInput and dragging then
		update(input)
	end
end)

local Title = Instance.new("TextLabel", Frame)
Title.Text = "License Verification"
Title.Font = Enum.Font.GothamBold
Title.TextSize = 20
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.BackgroundTransparency = 1
Title.Position = UDim2.new(0, 0, 0, 10)
Title.Size = UDim2.new(1, 0, 0, 30)

local InputBox = Instance.new("TextBox", Frame)
InputBox.PlaceholderText = "Enter your license key..."
InputBox.Text = ""
InputBox.Font = Enum.Font.Gotham
InputBox.TextSize = 16
InputBox.TextColor3 = Color3.fromRGB(255, 255, 255)
InputBox.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
InputBox.BorderSizePixel = 0
InputBox.Position = UDim2.new(0.1, 0, 0.35, 0)
InputBox.Size = UDim2.new(0.8, 0, 0, 35)
InputBox.ClearTextOnFocus = false

local VerifyButton = Instance.new("TextButton", Frame)
VerifyButton.Text = "Verify License"
VerifyButton.Font = Enum.Font.GothamBold
VerifyButton.TextSize = 16
VerifyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
VerifyButton.BackgroundColor3 = Color3.fromRGB(0, 120, 255)
VerifyButton.BorderSizePixel = 0
VerifyButton.Position = UDim2.new(0.1, 0, 0.65, 0)
VerifyButton.Size = UDim2.new(0.8, 0, 0, 35)

local StatusText = Instance.new("TextLabel", Frame)
StatusText.Text = ""
StatusText.Font = Enum.Font.Gotham
StatusText.TextSize = 14
StatusText.TextColor3 = Color3.fromRGB(255, 255, 255)
StatusText.BackgroundTransparency = 1

StatusText.Position = UDim2.new(0, 0, 0.88, 0)
StatusText.Size = UDim2.new(1, 0, 0, 20)



local function verifyLicense(key)
	local httpRequest = (syn and syn.request) or (http and http.request) or http_request
	if not httpRequest then
		StatusText.Text = "Executor does not support HTTP requests."
		StatusText.TextColor3 = Color3.fromRGB(255, 80, 80)
		return
	end
 --這裡不會就別動 這綁HWID
	local HWID = game:GetService("RbxAnalyticsService"):GetClientId()
	local url = string.format(
		"%s/verify?key=%s&hwid=%s&app_name=%s&owner_id=%s",
		apiBase,
		HttpService:UrlEncode(key),
		HttpService:UrlEncode(HWID),
		HttpService:UrlEncode(appName),
		HttpService:UrlEncode(ownerId)
	)

	StatusText.Text = "Verifying..."
	StatusText.TextColor3 = Color3.fromRGB(255, 255, 0)

	local res
	pcall(function()
		res = httpRequest({ Url = url, Method = "GET" })
	end)

	if not res then
		StatusText.Text = "Failed to connect to server."
		StatusText.TextColor3 = Color3.fromRGB(255, 120, 50)
		return
	end

	if res.StatusCode and res.StatusCode ~= 200 then
		StatusText.Text = "HTTP Error: " .. tostring(res.StatusCode)
		StatusText.TextColor3 = Color3.fromRGB(255, 120, 50)
		return
	end

	if res.Success == false then
		StatusText.Text = "Connection failed."
		StatusText.TextColor3 = Color3.fromRGB(255, 120, 50)
		return
	end

	local success, data = pcall(function()
		
		return HttpService:JSONDecode(res.Body)
		
	end)

	if not success or not data then
		warn("JSON Decode Failed:", res.Body)
		StatusText.Text = "Failed to parse response."
		StatusText.TextColor3 = Color3.fromRGB(255, 80, 80)
		return
	end

	if data.valid then
		local vars = data.variables or {}
		if vars.program_data then
			StatusText.Text = "Verified & Data Received!"
			StatusText.TextColor3 = Color3.fromRGB(100, 255, 100)
		else
			StatusText.Text = "Note: Missing 'program_data' (Recommended)"
		end
		
		print("Authorized successfully!")
	else
		StatusText.Text = "Invalid key or HWID mismatch."
		StatusText.TextColor3 = Color3.fromRGB(255, 80, 80)
	end
end

VerifyButton.MouseButton1Click:Connect(function()
	local key = InputBox.Text
	if key == "" then
		StatusText.Text = "Please enter your license key."
		StatusText.TextColor3 = Color3.fromRGB(255, 180, 80)
	else
		verifyLicense(key)
	end
end)
