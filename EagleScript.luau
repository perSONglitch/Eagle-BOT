
local Players = game:GetService('Players')
local RunService = game:GetService('RunService')
local UIS = game:GetService('UserInputService')
local lp = Players.LocalPlayer
local pg = lp:WaitForChild('PlayerGui')
local previous = pg:FindFirstChild('VXPEStandaloneCommands')
if previous then previous:Destroy() end
local oldController = getgenv().VXPEStandaloneController
if oldController and oldController.Stop then pcall(oldController.Stop) end
if oldController and oldController.Cleanup then pcall(oldController.Cleanup) end
if oldController and oldController.CancelGuns then pcall(oldController.CancelGuns) end
local gui = Instance.new('ScreenGui')
gui.Name='VXPEStandaloneCommands'; gui.ResetOnSpawn=false; gui.Parent=pg
local frame=Instance.new('Frame',gui)
frame.Size=UDim2.fromOffset(300,128); frame.AnchorPoint=Vector2.new(0,1); frame.Position=UDim2.new(0,10,1,-10)
frame.BackgroundColor3=Color3.fromRGB(24,27,34); frame.Active=false; frame.Draggable=false
Instance.new('UICorner',frame).CornerRadius=UDim.new(0,9)
local function text(y,height,value,size)
 local x=Instance.new('TextLabel',frame)
 x.Position=UDim2.fromOffset(12,y); x.Size=UDim2.new(1,-24,0,height)
 x.BackgroundTransparency=1; x.TextColor3=Color3.fromRGB(238,240,245)
 x.TextXAlignment=Enum.TextXAlignment.Left; x.TextWrapped=true
 x.Font=Enum.Font.Gotham; x.TextSize=size or 13; x.Text=value
 return x
end
local title=text(6,18,'VXPE CMD',13); title.Font=Enum.Font.GothamBold
local status=text(24,24,'F6: connect Vape command box',10)
local input=Instance.new('TextBox',frame)
input.Position=UDim2.fromOffset(8,52); input.Size=UDim2.new(1,-16,0,30)
input.PlaceholderText=".kill name | .kill name 5 | .kill team guards wl names"
input.Text=''; input.ClearTextOnFocus=false; input.Font=Enum.Font.Code
input.TextSize=12; input.TextColor3=Color3.new(1,1,1)
input.BackgroundColor3=Color3.fromRGB(41,46,56)
Instance.new('UICorner',input).CornerRadius=UDim.new(0,6)
local function button(label,x,y,w)
 local b=Instance.new('TextButton',frame); b.Position=UDim2.fromOffset(x,y)
 b.Size=UDim2.fromOffset(w,34); b.Text=label; b.Font=Enum.Font.GothamBold
 b.TextSize=12; b.TextColor3=Color3.new(1,1,1)
 b.BackgroundColor3=Color3.fromRGB(63,103,178)
 Instance.new('UICorner',b).CornerRadius=UDim.new(0,6)
 return b
end
local send=button('SEND',8,88,284)
local stop=button('STOP K',214,139,194)
stop.Visible=false
local wl=button('.WL',12,187,94)
wl.Visible=false
local unwl=button('.UNWL',112,187,94)
unwl.Visible=false
local help=button('HELP',212,187,94)
help.Visible=false
local close=button('CLOSE',312,187,96)
close.Visible=false
local gunsButton=button('GUNS: MP5 + REMINGTON',12,232,396)
gunsButton.Visible=false
local kickButton=button('KICK',12,274,94)
kickButton.Visible=false
local kickOffButton=button('KICK OFF',112,274,94)
kickOffButton.Visible=false
local kickTeamButton=button('KICK TEAM',212,274,94)
kickTeamButton.Visible=false
local teamButton=button('TEAM',312,274,96)
teamButton.Visible=false
local targetButton=button('TARGET',12,315,94)
targetButton.Visible=false
local untargetButton=button('UNTARGET',112,315,94)
untargetButton.Visible=false
local wlAllButton=button('WL ALL',212,315,94)
wlAllButton.Visible=false
local cmdsButton=button('COMMANDS',312,315,96)
cmdsButton.Visible=false
local info=text(358,35,'Kill: .kill name | .kill name 5 | .kill team guards wl names',11)
info.Visible=false
frame.Active=false
frame.Draggable=false
local controller={active=false,serial=0,connections={},gunsBusy=false,gunsSerial=0}
local killTeamSerial=0
getgenv().VXPEStandaloneController=controller
local function disconnect()
 for _,c in ipairs(controller.connections) do pcall(function() c:Disconnect() end) end
 table.clear(controller.connections)
end
local function humanoid(p)
 local ch=p and p.Character
 return ch and ch:FindFirstChildOfClass('Humanoid')
end
local function root(p)
 local ch=p and p.Character
 return ch and ch:FindFirstChild('HumanoidRootPart')
end
local function findPlayer(fragment)
 fragment=tostring(fragment or ''):lower():match('^%s*(.-)%s*$')
 if fragment=='' then return nil,'Missing username' end
 local prefix,partial
 for _,p in ipairs(Players:GetPlayers()) do
  local n=p.Name:lower(); local d=p.DisplayName:lower()
  if n==fragment or d==fragment then return p end
  if n:sub(1,#fragment)==fragment or d:sub(1,#fragment)==fragment then
   if prefix and prefix~=p then return nil,'Ambiguous username prefix' end
   prefix=p
  elseif n:find(fragment,1,true) or d:find(fragment,1,true) then
   partial=partial or p
  end
 end
 if prefix or partial then return prefix or partial end
 return nil,'Player not found'
end
local function module(name)
 local v=shared.vape or (getgenv and getgenv().vape)
 if type(v)~='table' then return nil end
 if v.Modules and v.Modules[name] then return v.Modules[name] end
 if v.Categories then
  for _,category in pairs(v.Categories) do
   if type(category)=='table' and category.Modules and category.Modules[name] then
    return category.Modules[name]
   end
  end
 end
 return nil
end
-- Automatically whitelist every player in Vape's Friends list.
-- The active K target is temporarily excluded, then restored when K ends.
local whitelistExcluded = nil
local function friendsList()
 local v=shared.vape or (getgenv and getgenv().vape)
 return v and v.Categories and v.Categories.Friends
end
local function setFriend(name, enabled)
 local friends=friendsList()
 if not friends or not friends.ListEnabled or type(friends.ChangeValue)~='function' then
  return false
 end
 local present=table.find(friends.ListEnabled,name)~=nil
 if present~=enabled then
  local ok=pcall(function() friends:ChangeValue(name) end)
  return ok
 end
 return true
end
local function whitelistAll()
 local count=0
 for _,p in ipairs(Players:GetPlayers()) do
  if p~=lp and p.Name~=whitelistExcluded and setFriend(p.Name,true) then
   count+=1
  end
 end
 return count
end
local whitelistConnection=Players.PlayerAdded:Connect(function(p)
 task.defer(function()
  for attempt=1,20 do
   if not p.Parent then return end
   if p.Name~=whitelistExcluded and setFriend(p.Name,true) then return end
   task.wait(0.5)
  end
 end)
end)
controller.Cleanup=function() whitelistConnection:Disconnect() end
task.spawn(function()
 for attempt=1,20 do
  if friendsList() then
   whitelistAll()
   return
  end
  task.wait(0.5)
 end
 status.Text='Vape Friends list unavailable; auto-whitelist waiting for module.'
end)
-- Standalone weapon collector, adapted from the supplied JARVIS guns routine.
-- Requires the game's ReplicatedStorage.Remotes.GiverPressed RemoteEvent and
-- workspace pickup models carrying the matching ToolName attributes.
local function hasGun(name)
 local backpack=lp:FindFirstChildOfClass('Backpack')
 local char=lp.Character
 return (backpack and backpack:FindFirstChild(name)) or (char and char:FindFirstChild(name))
end
local function findGunPickup(name)
 local best,part,distance
 local reference=Vector3.new(817.030823,90.320610,2229.855957)
 for _,item in ipairs(workspace:GetDescendants()) do
  if item:IsA('Model') and item:GetAttribute('ToolName')==name then
   local candidate=item.PrimaryPart or item:FindFirstChildWhichIsA('BasePart',true)
   if candidate then
    local d=(candidate.Position-reference).Magnitude
    if not distance or d<distance then best,part,distance=item,candidate,d end
   end
  end
 end
 return best,part
end
local function collectGuns()
 if controller.gunsBusy then status.Text='Gun pickup already running.'; return end
 if controller.active then status.Text='Stop K before collecting guns.'; return end
 if hasGun('MP5') and hasGun('Remington 870') then
  status.Text='Already have MP5 and Remington 870.'; return
 end
 local remotes=game:GetService('ReplicatedStorage'):FindFirstChild('Remotes')
 local giver=remotes and remotes:FindFirstChild('GiverPressed')
 if not giver or not giver:IsA('RemoteEvent') then
  status.Text='GiverPressed remote unavailable in this game.'; return
 end
 local character=lp.Character; local me=root(lp); local hum=humanoid(lp)
 if not character or not me or not hum or hum.Health<=0 then
  status.Text='Your character is unavailable.'; return
 end
 controller.gunsBusy=true
 controller.gunsSerial+=1
 local serial=controller.gunsSerial
 local original=me.CFrame
 local oldSpeed,oldJump,oldRotate=hum.WalkSpeed,hum.JumpPower,hum.AutoRotate
 local oldAnchored=me.Anchored
 task.spawn(function()
  local ok,err=xpcall(function()
   hum.WalkSpeed=0; hum.JumpPower=0; hum.AutoRotate=false
   me.Anchored=false
   for _,name in ipairs({'MP5','Remington 870'}) do
    if serial~=controller.gunsSerial then break end
    if hasGun(name) then continue end
    local model,part=findGunPickup(name)
    if not model then status.Text='Pickup not found: '..name; continue end
    status.Text='Collecting '..name..'...'
    local deadline=os.clock()+12
    repeat
     if serial~=controller.gunsSerial or lp.Character~=character or hum.Health<=0 then break end
     if not model.Parent or not part.Parent then
      model,part=findGunPickup(name)
      if not model then break end
     end
     me.CFrame=CFrame.new(part.Position+Vector3.new(0,2.5,0))
     me.AssemblyLinearVelocity=Vector3.zero
     giver:FireServer(model)
     task.wait(0.35)
    until hasGun(name) or os.clock()>=deadline
    if serial~=controller.gunsSerial then break end
    status.Text=name..(hasGun(name) and ' collected.' or ' pickup failed.')
   end
  end,debug.traceback)
  if me.Parent then
   me.Anchored=false
   me.CFrame=original
   me.AssemblyLinearVelocity=Vector3.zero
   me.Anchored=oldAnchored
  end
  if hum.Parent then
   hum.WalkSpeed=oldSpeed; hum.JumpPower=oldJump; hum.AutoRotate=oldRotate
  end
  controller.gunsBusy=false
  if not ok then warn('[VXPE GUNS]',err) end
  status.Text=(ok and 'Pickup finished. ' or 'Pickup error. ')..'MP5: '..(hasGun('MP5') and 'YES' or 'NO')..' | Remington: '..(hasGun('Remington 870') and 'YES' or 'NO')
 end)
end
controller.CancelGuns=function() controller.gunsSerial+=1 end
local function equipGun()
 local ch=lp.Character; local backpack=lp:FindFirstChildOfClass('Backpack')
 local h=humanoid(lp)
 if not ch or not h then return nil end
 for _,folder in ipairs({ch,backpack}) do
  if folder then
   for _,item in ipairs(folder:GetChildren()) do
    if item:IsA('Tool') and (item:FindFirstChild('Handle') or item:FindFirstChildWhichIsA('BasePart')) then
     if item.Parent~=ch then h:EquipTool(item) end
     return item
    end
   end
  end
 end
 return nil
end
-- Velocity-driven staged targeting. No CFrame teleports in K.
local function resetCamera()
 local char=lp.Character
 local hum=char and char:FindFirstChildOfClass('Humanoid')
 local cam=workspace.CurrentCamera
 if cam then
  cam.CameraType=Enum.CameraType.Custom
  if hum then cam.CameraSubject=hum end
 end
 -- Always leave command routines in normal third-person-capable mode.
 lp.CameraMode=Enum.CameraMode.Classic
 lp.CameraMinZoomDistance=0.5
 if lp.CameraMaxZoomDistance<12 then lp.CameraMaxZoomDistance=128 end
 pcall(function()
  if UserInputService.MouseBehavior==Enum.MouseBehavior.LockCenter then
   UserInputService.MouseBehavior=Enum.MouseBehavior.Default
  end
 end)
end

local function stopRoutine(message)
 controller.serial+=1; controller.active=false
 disconnect()
 local me=root(lp)
 if me then
  me.Anchored=false
  me.AssemblyLinearVelocity=Vector3.zero
  if controller.saved then
   -- Return is velocity-driven too; no instant position changes.
   local destination=controller.saved.Position
   local attachment=Instance.new('Attachment',me)
   local mover=Instance.new('LinearVelocity')
   mover.Attachment0=attachment
   mover.MaxForce=math.huge
   mover.RelativeTo=Enum.ActuatorRelativeTo.World
   mover.VectorVelocity=Vector3.zero
   mover.Parent=me
   local started=os.clock()
   local returning
   returning=RunService.Heartbeat:Connect(function()
    if not me.Parent or os.clock()-started>5 then
     returning:Disconnect(); mover:Destroy(); attachment:Destroy(); return
    end
    local delta=destination-me.Position
    if delta.Magnitude<3 then
     returning:Disconnect(); mover:Destroy(); attachment:Destroy()
     me.AssemblyLinearVelocity=Vector3.zero
     return
    end
    mover.VectorVelocity=delta.Unit*math.min(220,math.max(30,delta.Magnitude*7))
   end)
  end
 end
 if controller.cameraSubject and workspace.CurrentCamera then
  workspace.CurrentCamera.CameraSubject=controller.cameraSubject
 end
 if controller.savedCameraMode then
  lp.CameraMode=controller.savedCameraMode
  controller.savedCameraMode=nil
 end
 if controller.savedMinZoom then lp.CameraMinZoomDistance=controller.savedMinZoom; controller.savedMinZoom=nil end
 if controller.savedMaxZoom then lp.CameraMaxZoomDistance=controller.savedMaxZoom; controller.savedMaxZoom=nil end
 local sa=controller.silentModule
 if sa and controller.enabledSilent and sa.Enabled then pcall(function() sa:Toggle() end) end
 if whitelistExcluded then setFriend(whitelistExcluded,true); whitelistExcluded=nil end
 controller.saved=nil; controller.silentModule=nil; controller.enabledSilent=false
 if message then status.Text=message end
 resetCamera()
end
controller.Stop=function() stopRoutine('Stopped; returning by velocity.') end
local function isReloading(tool)
 if not tool then return true end

 -- Prison Life / VXPE reload state from AutoReload:
 -- Local_ReloadSession > 0 means the weapon is actively in a reload session.
 local reloadSession=tonumber(tool:GetAttribute('Local_ReloadSession') or 0) or 0
 if reloadSession>0 then
  return true
 end

 -- If ammo has reached zero, AutoReload calls pl.Reload. Treat the interval
 -- before Local_ReloadSession updates as reload time too.
 local ammo=tool:GetAttribute('Local_CurrentAmmo')
 if ammo~=nil and tonumber(ammo) and tonumber(ammo)<=0 then
  return true
 end

 -- Keep explicit flags as fallbacks for other weapons.
 for _,container in ipairs({tool,lp.Character}) do
  if container then
   for _,name in ipairs({'Reloading','IsReloading','IsReload','reload','reloading'}) do
    if container:GetAttribute(name)==true then return true end
    local value=container:FindFirstChild(name)
    if value and value:IsA('BoolValue') and value.Value then return true end
   end
  end
 end

 -- Animation fallback: if the equipped weapon/character is playing a reload
 -- animation whose Animation.Name contains "reload", freeze the timer.
 local hum=lp.Character and lp.Character:FindFirstChildOfClass('Humanoid')
 local animator=hum and hum:FindFirstChildOfClass('Animator')
 if animator then
  for _,track in ipairs(animator:GetPlayingAnimationTracks()) do
   local anim=track.Animation
   local animName=anim and tostring(anim.Name):lower() or ''
   if animName:find('reload',1,true) then return true end
  end
 end

 return false
end

local function beginKill(fragment, onFinished)
 local target,err=findPlayer(fragment)
 if not target then status.Text=err or 'No target'; return end
 if target==lp then status.Text='Cannot target yourself.'; return end
 local tr=root(target); local th=humanoid(target); local own=root(lp)
 if not tr or not th or th.Health<=0 or not own then status.Text='Target or local character unavailable.'; return end
 stopRoutine()
 whitelistAll()
 whitelistExcluded=target.Name; setFriend(target.Name,false)
 controller.active=true; controller.serial+=1
 local serial=controller.serial
 controller.saved=own.CFrame
 local lockedX=own.Position.X
 local lockedZ=own.Position.Z
 controller.cameraSubject=workspace.CurrentCamera and workspace.CurrentCamera.CameraSubject
 controller.savedCameraMode=lp.CameraMode
 controller.savedMinZoom=lp.CameraMinZoomDistance
 controller.savedMaxZoom=lp.CameraMaxZoomDistance
 lp.CameraMode=Enum.CameraMode.LockFirstPerson
 lp.CameraMinZoomDistance=0.5
 lp.CameraMaxZoomDistance=0.5
 if workspace.CurrentCamera then
  workspace.CurrentCamera.CameraSubject=humanoid(lp)
  workspace.CurrentCamera.CameraType=Enum.CameraType.Custom
 end
 -- Do not toggle SilentAim, TriggerBot, or any firing module.
 controller.silentModule=nil
 controller.enabledSilent=false
 local tool=equipGun()
 local previousHealth=th.Health
 local reloadPausedAt=nil
 local lastDamage=os.clock()
 local stageStart=os.clock()
 local NO_DAMAGE_TIMEOUT=1
 local NEAR_DISTANCE=75
 local SIMILAR_Y=24
 local far=(own.Position-tr.Position).Magnitude>NEAR_DISTANCE
 local similarY=math.abs(own.Position.Y-tr.Position.Y)<=SIMILAR_Y
 -- Nearby players at similar elevation need only aim; distant elevated targets
 -- start by approaching the corresponding height through velocity.
 local stage=(far and not similarY and tr.Position.Y>=110) and 3 or 1
 local stageArrived=stage==1
 local maxStageWait=3
 local finished=false
 local function finish(reason, died)
  if finished then return end
  finished=true
  stopRoutine(reason)
  if onFinished then task.defer(onFinished, died) end
 end
 local moveAttachment=Instance.new('Attachment',own)
 local mover=Instance.new('LinearVelocity')
 mover.Attachment0=moveAttachment
 mover.MaxForce=math.huge
 mover.RelativeTo=Enum.ActuatorRelativeTo.World
 mover.VectorVelocity=Vector3.zero
 mover.Parent=own
 local function removeMover()
  if mover.Parent then mover:Destroy() end
  if moveAttachment.Parent then moveAttachment:Destroy() end
 end
 table.insert(controller.connections,{Disconnect=removeMover})
 local function moveToY(me,y,horizontalVelocity)
  local difference=y-me.Position.Y
  if math.abs(difference)<1.5 then
   -- Hold X/Z correction while stopping vertical movement at the requested level.
   mover.VectorVelocity=Vector3.new(horizontalVelocity.X,0,horizontalVelocity.Z)
   me.AssemblyLinearVelocity=Vector3.new(horizontalVelocity.X,0,horizontalVelocity.Z)
   return true
  end
  -- Strong vertical drive so Y=16 / Y=166 is reached quickly.
  local yVelocity=math.clamp(difference*18,-300,300)
  mover.VectorVelocity=Vector3.new(horizontalVelocity.X,yVelocity,horizontalVelocity.Z)
  return false
 end
 status.Text=stage==3 and 'Distant elevated target: approaching Y=166.' or 'Equipped + aiming from current position.'
 table.insert(controller.connections,RunService.Heartbeat:Connect(function()
  if serial~=controller.serial or not controller.active then return end
  local me=root(lp); local enemy=root(target); local hp=humanoid(target)
  if not me or not enemy or not hp or not target.Parent then finish('Target left or character unavailable.',false); return end
  if hp.Health<=0 then finish(target.Name..' died; returning.',true); return end
  local now=os.clock()

  -- Keep the kill attempt horizontally anchored to its starting X/Z.
  -- Y remains fully controlled by the stage mover.
  local horizontalError=Vector3.new(lockedX-me.Position.X,0,lockedZ-me.Position.Z)
  local horizontalVelocity=horizontalError*14
  if horizontalVelocity.Magnitude>90 then
   horizontalVelocity=horizontalVelocity.Unit*90
  end
  -- Do not count any reload time toward the one-second stage timer.
  if not tool or tool.Parent~=lp.Character then tool=equipGun() end
  if isReloading(tool) then
   if not reloadPausedAt then reloadPausedAt=now end
   previousHealth=hp.Health
   status.Text='Waiting for reload to finish...'
   return
  elseif reloadPausedAt then
   local pausedFor=now-reloadPausedAt
   lastDamage+=pausedFor
   stageStart+=pausedFor
   reloadPausedAt=nil
   status.Text='Reload finished; timer resumed.'
  end
  if hp.Health<previousHealth then
   lastDamage=now
   stageStart=now
   status.Text=target.Name..' lost health: '..math.floor(hp.Health)..' HP (stage '..stage..')'
  end
  previousHealth=hp.Health

  -- First-person camera lock + mouse lock toward the target.
  local cam=workspace.CurrentCamera
  if cam then
   local aimPart=target.Character and (target.Character:FindFirstChild('Head') or enemy)
   if aimPart then
    local aimPos=aimPart.Position
    cam.CFrame=CFrame.lookAt(cam.CFrame.Position,aimPos)

    -- Keep executor mouse aim centered on the same target when mousemoverel is available.
    local ok,screenPos,onScreen=pcall(function()
     local p,visible=cam:WorldToViewportPoint(aimPos)
     return p,visible
    end)
    if ok and onScreen and typeof(mousemoverel)=='function' then
     local viewport=cam.ViewportSize
     local dx=screenPos.X-(viewport.X/2)
     local dy=screenPos.Y-(viewport.Y/2)
     pcall(mousemoverel,dx,dy)
    end
   end
  end

  -- Do not shoot while moving, while the tool is absent, or while SilentAim is unavailable.
  local atStage=true
  if stage==2 then atStage=moveToY(me,16,horizontalVelocity)
  elseif stage==3 then atStage=moveToY(me,166,horizontalVelocity)
  else mover.VectorVelocity=horizontalVelocity end
  if not atStage then
   -- Moving time does not count as a no-damage window.
   lastDamage=now
   if now-stageStart>maxStageWait then finish('Could not reach requested height.',false) end
   return
  end
  if not stageArrived then
   stageArrived=true
   lastDamage=now
  end
  if now-lastDamage>=NO_DAMAGE_TIMEOUT then
   if stage==1 then
    stage=2; stageArrived=false; stageStart=now; lastDamage=now
    status.Text='No damage: moving to Y=16.'
   elseif stage==2 then
    stage=3; stageArrived=false; stageStart=now; lastDamage=now
    status.Text='No damage: moving to Y=166.'
   else
    finish('No damage at Y=166; attempt ended.',false)
    return
   end
  end
  -- Equip only. The game/VXPE handles firing automatically.
  if not tool or tool.Parent~=lp.Character then tool=equipGun() end
  if not tool then
   status.Text='Waiting for a gun to equip.'
   return
  end
 end))
end

-- Direct team switch adapted from the uploaded working implementation.
local teamSwitchBusy=false
local function isNeutral()
 return lp.Neutral or lp.Team==nil or (lp.Team and lp.Team.Name=='Neutral')
end
local function clickTeamPoint(point)
 local ok=pcall(function()
  local vim=game:GetService('VirtualInputManager')
  local inset=game:GetService('GuiService'):GetGuiInset()
  local x,y=math.floor(point.X+0.5),math.floor(point.Y+inset.Y+0.5)
  vim:SendMouseMoveEvent(x,y,game); vim:SendMouseButtonEvent(x,y,0,true,game,0)
  task.wait(0.12); vim:SendMouseButtonEvent(x,y,0,false,game,0)
 end)
 return ok
end
local function awaitTeam(wanted,timeout)
 local deadline=os.clock()+timeout
 repeat
  if wanted=='Neutral' then
   if isNeutral() then return true end
  elseif lp.Team and lp.Team.Name==wanted and not lp.Neutral then return true end
  task.wait(0.15)
 until os.clock()>=deadline
 return false
end
local function joinNeutral()
 if isNeutral() then return true end
 local pg=lp:FindFirstChildOfClass('PlayerGui')
 local home=pg and pg:FindFirstChild('Home')
 local hud=home and home:FindFirstChild('hud')
 local topbar=hud and hud:FindFirstChild('Topbar')
 local menu=topbar and topbar:FindFirstChild('MenuButton')
 local switch=menu and menu:FindFirstChild('MenuFrame') and menu.MenuFrame:FindFirstChild('respawn')
 local alt=topbar and topbar:FindFirstChild('MenuFrame') and topbar.MenuFrame:FindFirstChild('SwitchTeams')
 if menu and menu.AbsoluteSize.X>0 then clickTeamPoint(menu.AbsolutePosition+menu.AbsoluteSize/2); task.wait(0.4) end
 local button=(switch and switch.AbsoluteSize.X>0 and switch) or (alt and alt.AbsoluteSize.X>0 and alt)
 return button and clickTeamPoint(button.AbsolutePosition+button.AbsoluteSize/2) and awaitTeam('Neutral',4) or false
end
local function findTeamButton(wanted)
 local pg=lp:FindFirstChildOfClass('PlayerGui')
 local frame=pg and pg:FindFirstChild('TeamsFrame',true)
 if not frame then return nil end
 for _,holder in ipairs(frame:GetChildren()) do
  local button=holder:FindFirstChild('Button')
  if button and button:IsA('GuiButton') and holder.Name:lower()==wanted:lower()
   and button.AbsoluteSize.X>0 and button.AbsoluteSize.Y>0 then return button end
 end
end
local function selectGuiTeam(wanted)
 local deadline=os.clock()+8
 repeat
  local button=findTeamButton(wanted)
  if button then
   local exposed=(getgenv and getgenv().pickTeam) or nil
   if type(exposed)=='function' then pcall(exposed,button) end
   pcall(function() button:Activate() end)
   if awaitTeam(wanted,1) then return true end
   clickTeamPoint(button.AbsolutePosition+button.AbsoluteSize/2)
   if awaitTeam(wanted,1) then return true end
  end
  task.wait(0.25)
 until os.clock()>=deadline
 return false
end
local function selectRemoteTeam(wanted)
 local value=({Guards='Bright blue',Inmates='Bright orange'})[wanted]
 if not value then return false end
 local remote=workspace:FindFirstChild('TeamEvent',true)
 if not remote or not remote:IsA('RemoteEvent') then return false end
 local ok=pcall(function() remote:FireServer(value) end)
 return ok and awaitTeam(wanted,3)
end
local function switchTeam(alias)
 if teamSwitchBusy then status.Text='Team switch already running.'; return false end
 local aliases={g='Guards',guard='Guards',guards='Guards',i='Inmates',inmate='Inmates',
  inmates='Inmates',c='Criminals',criminal='Criminals',criminals='Criminals'}
 local wanted=aliases[tostring(alias or ''):lower():gsub('^%s+',''):gsub('%s+$','')]
 if not wanted then status.Text='Use teamg / teami / teamc or .team g/i/c'; return false end
 if lp.Team and lp.Team.Name==wanted and not lp.Neutral then status.Text='Already on '..wanted; return true end
 teamSwitchBusy=true; status.Text='Switching to '..wanted..'...'
 local ok,result=pcall(function()
  if not isNeutral() then
   if not joinNeutral() then return false end
   task.wait(2)
  end
  if selectGuiTeam(wanted) then return true end
  return selectRemoteTeam(wanted)
 end)
 teamSwitchBusy=false
 if ok and result then status.Text='Joined '..wanted; return true end
 status.Text='Could not confirm '..wanted; return false
end


local function vapeObject()
 return shared.vape or (getgenv and getgenv().vape)
end

local function kickModuleDirect()
 local v=vapeObject()
 if not v then return nil end
 if v.Modules and v.Modules.KickExploit then return v.Modules.KickExploit end
 local world=v.Categories and v.Categories.World
 if world and world.Modules and world.Modules.KickExploit then return world.Modules.KickExploit end
 return nil
end

local function changeListValue(list,name,enabled)
 if not list then return false end
 local enabledList=list.ListEnabled or list.List
 if enabledList then
  local has=table.find(enabledList,name)~=nil
  if has~=enabled then
   if type(list.ChangeValue)=='function' then
    local ok=pcall(function() list:ChangeValue(name) end)
    if ok then return true end
   end
  else
   return true
  end
 end
 if type(list.ChangeValue)=='function' then
  return pcall(function() list:ChangeValue(name) end)
 end
 return false
end

local function kickTargetListDirect(mod)
 if not mod then return nil end
 return (mod.Options and mod.Options.Targets) or mod.List or mod.Targets
end

local function setKickModeDirect(mod,mode)
 local opt=(mod.Options and mod.Options.Mode) or mod.Mode
 if not opt then return end
 if type(opt.SetValue)=='function' then pcall(function() opt:SetValue(mode) end)
 elseif type(opt.SetValue)=='function' then pcall(opt.SetValue,opt,mode) end
end

local function directKick(arg)
 local mod=kickModuleDirect()
 if not mod then
  status.Text='KickExploit module not found in loaded VXPE.'
  return
 end
 arg=tostring(arg or ''):match('^%s*(.-)%s*$')
 if arg=='' then status.Text='Enter a player, all, or none.'; return end
 local lower=arg:lower()

 if lower=='none' or lower=='off' or lower=='stop' then
  if mod.Enabled and type(mod.Toggle)=='function' then pcall(function() mod:Toggle() end) end
  status.Text='KickExploit stopped.'
  return
 end

 if lower=='all' then
  setKickModeDirect(mod,'All')
  if not mod.Enabled and type(mod.Toggle)=='function' then pcall(function() mod:Toggle() end) end
  status.Text='KickExploit mode: All.'
  return
 end

 local plr,err=findPlayer(arg)
 if not plr then status.Text=err or 'No player found.'; return end
 setKickModeDirect(mod,'Individual')
 local list=kickTargetListDirect(mod)
 if not changeListValue(list,plr.Name,true) then
  status.Text='KickExploit target list unavailable.'
  return
 end
 if not mod.Enabled and type(mod.Toggle)=='function' then pcall(function() mod:Toggle() end) end
 status.Text='Kick target: '..plr.Name
end

local function directKickTeam(alias)
 local wanted=({g='Guards',guard='Guards',guards='Guards',i='Inmates',inmate='Inmates',inmates='Inmates',c='Criminals',criminal='Criminals',criminals='Criminals'})[tostring(alias or ''):lower()]
 if not wanted then status.Text='Use .kickteam g, i, or c.'; return end
 local mod=kickModuleDirect()
 if not mod then status.Text='KickExploit module not found in loaded VXPE.'; return end
 setKickModeDirect(mod,'Individual')
 local list=kickTargetListDirect(mod)
 if not list then status.Text='KickExploit target list unavailable.'; return end
 local count=0
 for _,plr in ipairs(Players:GetPlayers()) do
  if plr~=lp and plr.Team and plr.Team.Name==wanted then
   if changeListValue(list,plr.Name,true) then count+=1 end
  end
 end
 if count==0 then status.Text='No '..wanted..' players found.'; return end
 if not mod.Enabled and type(mod.Toggle)=='function' then pcall(function() mod:Toggle() end) end
 status.Text='Kick targets: '..count..' '..wanted..'.'
end


local function targetProtected(player)
 local char=player and player.Character
 if not char then return true end
 if char:FindFirstChildOfClass('ForceField') then return true end
 for _,obj in ipairs(char:GetChildren()) do
  if obj:IsA('ForceField') then return true end
 end
 return false
end

local repeatSerial=0
local function repeatedKill(fragment, requested, completedCallback)
 local target,err=findPlayer(fragment)
 if not target then status.Text=err or 'Target not found'; return end
 if target==lp then status.Text='Cannot target yourself'; return end
 requested=math.floor(tonumber(requested) or 1)
 if requested<1 or requested>1000 then status.Text='Repeat count must be 1–1000.'; return end
 repeatSerial+=1
 local serial=repeatSerial
 task.spawn(function()
  local completed=0
  local unsuccessful=0
  while serial==repeatSerial and completed<requested do
   if not target.Parent then break end
   -- Wait for respawn, full health and removal of spawn protection.
   status.Text=('Waiting for %s to respawn / lose FF (%d/%d)'):format(target.Name,completed,requested)
   local ready=false
   while serial==repeatSerial and target.Parent do
    local h=humanoid(target)
    if h and h.Health>0 and root(target) and not targetProtected(target) then
     ready=true
     break
    end
    task.wait(0.15)
   end
   if not ready or serial~=repeatSerial then break end
   local done=false
   local died=false
   beginKill(target.Name,function(wasKilled)
    died=wasKilled
    done=true
   end)
   while serial==repeatSerial and controller.active and not done do task.wait(0.1) end
   if serial~=repeatSerial then break end
   -- A completed attempt only counts when target death was observed.
   resetCamera()
   if died then
    completed+=1
    unsuccessful=0
    status.Text=('Confirmed deaths: %d/%d'):format(completed,requested)
   else
    -- Do not count an unsuccessful stage cycle as a kill.
    unsuccessful+=1
    if unsuccessful>=4 then
     status.Text=('Stopped: 4 unsuccessful attempts on %s (%d/%d confirmed).'):format(target.Name,completed,requested)
     break
    end
    task.wait(0.3)
   end
  end
  if serial==repeatSerial then
   status.Text=('Kill sequence ended: %d/%d confirmed deaths.'):format(completed,requested)
  end
  if completedCallback then completedCallback(completed,requested) end
 end)
end

local function killTeam(spec)
 spec=tostring(spec or ''):match('^%s*(.-)%s*$')
 local teamPart,wlPart=spec:match('^(.-)%s+[Ww][Ll]%s+(.+)$')
 teamPart=(teamPart or spec):match('^%s*(.-)%s*$')
 wlPart=wlPart and wlPart:match('^%s*(.-)%s*$') or nil

 local wanted=({
  g='Guards', guard='Guards', guards='Guards',
  i='Inmates', inmate='Inmates', inmates='Inmates',
  c='Criminals', criminal='Criminals', criminals='Criminals'
 })[teamPart:lower()]
 if not wanted then
  status.Text='Use .kill team guards wl name1,name2.'
  return
 end

 -- Resolve this run's exclusions. Partial names work through findPlayer().
 local excluded={}
 local excludedNames={}
 if wlPart and wlPart~='' then
  for token in wlPart:gmatch('[^,]+') do
   token=token:match('^%s*(.-)%s*$')
   if token~='' then
    local plr=findPlayer(token)
    if plr then
     excluded[plr]=true
     table.insert(excludedNames,plr.Name)
    end
   end
  end
 end

 killTeamSerial+=1
 local serial=killTeamSerial
 task.spawn(function()
  local targets={}
  for _,plr in ipairs(Players:GetPlayers()) do
   local h=humanoid(plr)
   if plr~=lp and not excluded[plr] and plr.Team and plr.Team.Name==wanted and h and h.Health>0 then
    table.insert(targets,plr)
   end
  end
  if #targets==0 then
   status.Text='No eligible living '..wanted..' targets.'
   return
  end

  -- Process the selected team from closest to furthest.
  local origin=root(lp)
  local originPos=origin and origin.Position
  if originPos then
   table.sort(targets,function(a,b)
    local ar=root(a)
    local br=root(b)
    local ad=ar and (ar.Position-originPos).Magnitude or math.huge
    local bd=br and (br.Position-originPos).Magnitude or math.huge
    return ad<bd
   end)
  end

  local suffix=#excludedNames>0 and (' | WL: '..table.concat(excludedNames,', ')) or ''
  status.Text='Kill team '..wanted..': '..#targets..' target(s).'..suffix
  for _,plr in ipairs(targets) do
   if serial~=killTeamSerial then return end
   if not plr.Parent or excluded[plr] then continue end
   local h=humanoid(plr)
   if not h or h.Health<=0 then continue end

   beginKill(plr.Name)
   while serial==killTeamSerial and controller.active do
    task.wait(0.05)
   end
   if serial~=killTeamSerial then return end
   resetCamera()
   task.wait(0.1)
  end
  if serial==killTeamSerial then
   status.Text='Kill team '..wanted..' sequence finished.'..suffix
  end
 end)
end


local shootBackEnabled=false
local shootBackConnection=nil

local function findVapeEvents()
 local env=(getgenv and getgenv()) or _G
 return rawget(env,'vapeEvents') or rawget(shared,'vapeEvents')
end

local function setShootBack(enabled)
 shootBackEnabled=enabled and true or false
 if shootBackConnection then
  pcall(function() shootBackConnection:Disconnect() end)
  shootBackConnection=nil
 end
 if not shootBackEnabled then
  status.Text='SB OFF'
  return
 end

 local events=findVapeEvents()
 local playerKill=events and events.PlayerKill
 local signal=playerKill and playerKill.Event
 if not signal then
  shootBackEnabled=false
  status.Text='SB unavailable: vapeEvents.PlayerKill not found.'
  return
 end

 shootBackConnection=signal:Connect(function(killer,victim)
  if not shootBackEnabled then return end
  if victim~=lp.Name or killer==lp.Name then return end
  local attacker=findPlayer(killer)
  if not attacker then
   status.Text='SB: killer '..tostring(killer)..' not found.'
   return
  end
  status.Text='SB retaliation: '..attacker.Name
  task.spawn(function()
   -- Wait for our character to exist again before retaliation.
   while shootBackEnabled and (not lp.Character or not humanoid(lp) or humanoid(lp).Health<=0 or not root(lp)) do
    task.wait(0.15)
   end
   if shootBackEnabled and attacker.Parent then
    beginKill(attacker.Name)
   end
  end)
 end)
 status.Text='SB ON: retaliates against reported killers.'
end

-- Easy aliases for VXPE/backend module commands.
-- Forwarded through shared.VapeBotCommand; this box does not reimplement the modules.
local MODULE_ALIASES={
 diedtp='diedtp', deathtp='diedtp', dtp='diedtp',
 autore='autoreload', ar='autoreload', reloadauto='autoreload',
 notaze='antitaze', notaser='antitaze', antitazer='antitaze', at='antitaze',
 af='antifling', nofling='antifling',
 sa='silentaim', rb='ragebot', ta='toolaura', esp='esp'
}

local function submit(raw)
 local cmd=tostring(raw or ''):match('^%s*(.-)%s*$')
 if cmd=='' then status.Text='Enter a command.'; return end
 local name,args=cmd:gsub('^[%.\' ]+',''):match('^(%S+)%s*(.*)$')
 name=name and name:lower()
 -- Rephrase easy aliases to the backend's canonical module command.
 -- Any arguments such as on/off are preserved.
 if name and MODULE_ALIASES[name] then
  name=MODULE_ALIASES[name]
  cmd=name..((args and args~='') and (' '..args) or '')
 end
 -- Clear any camera state left by a previous command before dispatch.
 if name~='kill' then
  resetCamera()
 end
 -- Accept teamg/teami/teamc as well as .team g/.team i/.team c.
 if name=='sb' or name=='shootback' then
  local v=tostring(args or ''):lower():match('^%s*(.-)%s*$')
  if v=='on' or v=='1' or v=='true' then setShootBack(true)
  elseif v=='off' or v=='0' or v=='false' then setShootBack(false)
  else status.Text='Use .sb on or .sb off' end
  return
 end
  local compactTeam=name and name:match('^team([gic])$')
 if compactTeam then name='team'; args=compactTeam end
 if name=='team' then task.spawn(switchTeam,args); return end
 if name=='kick' then task.spawn(directKick,args); return end
 if name=='kickteam' then task.spawn(directKickTeam,args); return end
 if name=='kill' then
  local teamSpec=args:match('^[Tt][Ee][Aa][Mm]%s+(.+)$')
  if teamSpec then killTeam(teamSpec); return end
 end
 if name=='kill' then
  local playerArg,count=args:match('^(.-)%s+(%d+)%s*$')
  if count then repeatedKill(playerArg,tonumber(count))
  else beginKill(args) end
  return
 end
 
 if name=='guns' or name=='getguns' then collectGuns(); return end
 if name=='wlall' or name=='whitelistall' then
  status.Text='Whitelisted '..whitelistAll()..' players (excluding active K target).'
  return
 end
 if name=='help' then
  status.Text=".kill name | .kill name 5 | .kill team guards wl name1,name2 | .guns | .team g/i/c | .kickteam c/i/g"
  return
 end
 local bridge=shared.VapeBotCommand
 if type(bridge)~='function' then
  status.Text='No VapeBotCommand bridge. Direct team/kick still work; other commands need ChatCommand.'
  return
 end
 local normalized=(name=='team' and '.team '..args) or ('.'..cmd:gsub('^[%.\' ]+',''))
 local ok,accepted,message=pcall(bridge,normalized)
 if not ok then status.Text='Bridge error: '..tostring(accepted)
 elseif accepted then status.Text='Accepted: '..normalized..' | '..tostring(message or '')
 else status.Text='Rejected: '..tostring(message or normalized) end
end

-- Export the exact VXPE command-box parser as JARVIS's communication layer.
-- Native commands (guns/kill/kickteam/team/etc.) execute here.
-- Everything else falls through to the modified Vape V4 ChatCommand bridge.
getgenv().VXPECommandDispatch = function(raw)
 local ok,err=pcall(submit,tostring(raw or ''))
 if not ok then
  warn('[VXPE Command Layer] dispatch error:',err)
  return false,tostring(err)
 end
 return true,'dispatched'
end
shared.VXPECommandDispatch=getgenv().VXPECommandDispatch

send.MouseButton1Click:Connect(function() submit(input.Text) end)
input.FocusLost:Connect(function(enter) if enter then submit(input.Text) end end)
stop.MouseButton1Click:Connect(function() killTeamSerial+=1; repeatSerial+=1; stopRoutine('Stopped.') end)
local function quick(command)
 local name=input.Text:match('([%w_]+)%s*$')
 if not name then status.Text='Enter a username.'; return end
 input.Text=command..' '..name; submit(input.Text)
end
wl.MouseButton1Click:Connect(function() quick('.wl') end)
unwl.MouseButton1Click:Connect(function() quick('.unwl') end)
help.MouseButton1Click:Connect(function() submit('.help') end)
gunsButton.MouseButton1Click:Connect(collectGuns)
kickButton.MouseButton1Click:Connect(function() quick('.kick') end)
kickOffButton.MouseButton1Click:Connect(function() submit('.kick none') end)
kickTeamButton.MouseButton1Click:Connect(function()
 local team=input.Text:lower():match('^%s*%.?team%s*([cig])%s*$') or input.Text:lower():match('^%s*team([cig])%s*$') or input.Text:lower():match('^%s*([cig])%s*$')
 if not team then status.Text='Enter c, i or g for .kickteam'; return end
 submit('.kickteam '..team:lower())
end)
teamButton.MouseButton1Click:Connect(function()
 local team=input.Text:lower():match('^%s*%.?team%s*([cig])%s*$') or input.Text:lower():match('^%s*team([cig])%s*$') or input.Text:lower():match('^%s*([cig])%s*$')
 if not team then status.Text='Enter c, i or g for .team'; return end
 submit('.team '..team:lower())
end)
targetButton.MouseButton1Click:Connect(function() quick('.target') end)
untargetButton.MouseButton1Click:Connect(function() quick('.untarget') end)
wlAllButton.MouseButton1Click:Connect(function() submit('.wlall') end)
cmdsButton.MouseButton1Click:Connect(function() submit('.help') end)
close.MouseButton1Click:Connect(function() stopRoutine(); controller.CancelGuns(); whitelistConnection:Disconnect(); gui:Destroy() end)
print('[VXPE Command Box] Ready; requires modified ChatCommand bridge for ordinary commands.')

end


--[[ JARVIS BOT LAYER ]]
-- JARVIS MULTI-BOT SPACING UPDATE
-- Rejoin before switching from an older build so its movement loops are removed.
-- Run this complete script on EVERY bot and select the SAME owner username.
-- Automatic roster: shared executor workspace or supported TextChat metadata.
-- Fallback: owner says 'bots FullBotUsername1 FullBotUsername2 FullBotUsername3
-- 'bots lists the roster. 'bots reset clears manual entries. 'botspacing 6 sets spacing.
-- 'slot FullBotUsername 2 prefers a slot; duplicate requests resolve by UserId.
-- 'slots restores automatic ordering. Peers are allies, never command owners.
-- 'shut silences JARVIS conversational/public replies only.
-- Admin command traffic (.kill/.combo/etc.) uses the VXPE command layer while shut. 'unshut restores speech.
-- 'k team criminals sorts usernames A-Z and deals targets round-robin across bots.
-- Targets are divided round-robin across 1–4 active bots.
getgenv().JARVIS_CHAT_EPOCH = (getgenv().JARVIS_CHAT_EPOCH or 0) + 1
getgenv().JARVIS_SQUAD_CONFIG = {names = {}, slots = {}, spacing = 6}
-- How many JARVIS bot slots are active: 'bot 1 / 'bot 2 / 'bot 3 / 'bot 4
getgenv().JARVIS_ACTIVE_BOT_COUNT = math.clamp(
    tonumber(getgenv().JARVIS_ACTIVE_BOT_COUNT) or 4, 1, 4
)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TextChatService = game:GetService("TextChatService")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local UserInputService = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local GuiService = game:GetService("GuiService")
local VirtualInputManager = nil
pcall(function()
    VirtualInputManager = game:GetService("VirtualInputManager")
end)
local bot = Players.LocalPlayer
-- FPS CAP: requires an executor-provided frame limiter.
-- A LocalScript cannot impose a true render FPS limit on its own.
do
    local FPS_TARGET = 165
    local function findCap()
        local env = (type(getgenv) == "function" and getgenv()) or {}
        local candidates = {
            {name="setfpscap", fn=setfpscap},
            {name="getgenv().setfpscap", fn=env.setfpscap},
            {name="set_fps_cap", fn=env.set_fps_cap},
            {name="setfps", fn=env.setfps},
        }
        for _,candidate in ipairs(candidates) do
            if type(candidate.fn) == "function" then
                return candidate.fn, candidate.name
            end
        end
        return nil, nil
    end

    task.spawn(function()
        local applied = false
        -- Some executors register their FPS API shortly after injection.
        for attempt=1,10 do
            local cap, name = findCap()
            if cap then
                local ok, err = pcall(cap, FPS_TARGET)
                if ok then
                    applied = true
                    print("[JARVIS FPS] Requested 165 FPS via "..name)
                    break
                end
                warn("[JARVIS FPS] "..name.." failed: "..tostring(err))
            end
            task.wait(0.5)
        end

        if not applied then
            warn("[JARVIS FPS] No working FPS limiter exposed by this executor. "..
                "Set the 165 FPS cap in the executor or Roblox client settings.")
        end

        -- Independently measure real rendered FPS. A successful API call
        -- does not guarantee that the executor actually enforced the cap.
        local frames, started = 0, os.clock()
        local conn
        conn = RunService.RenderStepped:Connect(function()
            frames += 1
            local elapsed = os.clock() - started
            if elapsed >= 5 then
                local measured = math.floor(frames / elapsed + 0.5)
                print("[JARVIS FPS] Actual render FPS over 5s: "..measured)
                if measured > 170 then
                    warn("[JARVIS FPS] Still above 165 FPS. "..
                        "The executor did not enforce the cap; use its native FPS limiter.")
                end
                conn:Disconnect()
            end
        end)
    end)
end

local camera = workspace.CurrentCamera
getgenv().JARVIS_SAVED_OWNER = "x4ay3"
local MASTER_NAME = "x4ay3"
local HOST_NAME = "x4ay3"
local ROLE = nil
JARVIS_KX_ADMIN_ENABLED = true
local PREFIX = "'"
local CMD_PREFIX = "'"

-- Hardcoded owner: cannot be changed by local menu or saved owner.txt.
getgenv().JARVIS_GET_OWNER = function() return "x4ay3" end
getgenv().JARVIS_SET_OWNER = function() return false end
local DOT = "."
local PRISON_SPEED = 29
local OUTSIDE_SPEED = 90
local MIN_SPEED = 1
local MAX_SPEED = 150
local PRISON_BOUNDS = {
    minX = 470,
    maxX = 1040,
    minZ = 2160,
    maxZ = 2660,
}
local FOLLOW_DIST = 4
local SIDE = 4
local PUNCH_SAFE = 14
local CAR_SPAWNER_POSITION = Vector3.new(624.152, 98.403, 2495.038)
local CAR_SPAWN_REMOTE_NAME = "CarSpawn"
local CAR_BUTTON_RADIUS = 40
local CAR_SEARCH_RADIUS = 100
local CAR_MOVE_TEST_TIME = 0.9
local CAR_MOVE_THRESHOLD = 1.25
local CAR_SEAT_RETRY_DELAY = 0.35
local INVIS_DEPTH = 8
local followDistance = FOLLOW_DIST
local sideDistance = SIDE
local cloakDepth = INVIS_DEPTH
local followVerticalOffset = 0
local savedMarks = {}
local freezeCFrame = nil
local MAX_SLOTS = 128 -- manual preference limit; automatic slots never wrap
local FORMATION_BACK = 4
local FORMATION_SIDE = 4
local FORMATION_ROW = 3.5
local DEFAULT_ORBIT_RADIUS = 10
local MIN_ORBIT_RADIUS = 4
local MAX_ORBIT_RADIUS = 50
local PATROL_RADIUS = 18
local SCOUT_DISTANCE = 35
local STUCK_TIME = 2
local STUCK_DISTANCE = 0.5
local SLOT_MAP = {
}
local masterLower = ""
local IS_LEADER = false
local extraOwners = {}
local sharedAccessLevel = {}
local revokedOwners = {}
JARVIS_WHITELIST = JARVIS_WHITELIST or {
}
local mySlot = IS_LEADER and 0 or 1
local manualSlot = nil
local shut = false
local mode = "idle"
local hiddenLock = false
local HIDE_CFRAME = CFrame.new(874.332336, 116.509766, 2419.012939, -0.883117, 0.000000, 0.469153, 0.000000, 1.000000, -0.000000, -0.469153, -0.000000, -0.883117)
local targetPlayer = nil
local followCamPlayer = nil
local flying = false
local spinning = false
local frozen = false
local punchOn = false
local protecting = false
local protectedPlayer = nil
local followPosition = "center"
local invisFollow = false
local invisPosition = nil
JARVIS_CLOAK_RELEASE_UNTIL = 0
JARVIS_CLOAK_DEADZONE = 1.35
JARVIS_CLOAK_SPEED = 22
JARVIS_CLOAK_ADMIN_RELEASE = 1.35
JARVIS_CLOAK_COMBAT_RELEASE = 2.10
JARVIS_FOLLOW_RELEASE_UNTIL = JARVIS_FOLLOW_RELEASE_UNTIL or 0
JARVIS_FOLLOW_DEADZONE = JARVIS_FOLLOW_DEADZONE or 1.6
JARVIS_FOLLOW_SPEED = JARVIS_FOLLOW_SPEED or 18
JARVIS_FOLLOW_ADMIN_RELEASE = JARVIS_FOLLOW_ADMIN_RELEASE or 1.35
JARVIS_FOLLOW_COMBAT_RELEASE = JARVIS_FOLLOW_COMBAT_RELEASE or 2.35
JARVIS_IDLE_HOLD_CFRAME = JARVIS_IDLE_HOLD_CFRAME or nil
JARVIS_CLOAK_Y_HOLD_NAME = "JARVIS_CloakYHold"
local flySpeed = PRISON_SPEED
local manualSpeedOverride = false
local groundLock = true
local noclipOn = false
local NoclipParts = {}
local Noclipping = nil
local noSit = true
local vehicleRoutineActive = false
local carFlingBusy = false
local rejoinAttempted = false

-- Exclusive kill-state lock kept in one environment table to avoid adding
-- more locals/register pressure to the already-large JARVIS chunk.
getgenv().JARVIS_KILL_STATE = getgenv().JARVIS_KILL_STATE or {
    busyUntil=0, label="", lastSignature="", lastAt=0
}
function jarvisKillBusy()
    return os.clock() < (getgenv().JARVIS_KILL_STATE.busyUntil or 0)
end
local camLocked = false
local sayBusy = false
local sayQ = {}
local CHAT_MIN_DELAY = 2.25
local CHAT_MAX_DELAY = 5.50
local CHAT_BACKOFF = 0.40
local CHAT_RECOVERY_STEP = 0.025
local adaptiveChatDelay = 2.40
local lastChatFloodAt = -math.huge
local chatMessagesSent = 0
local didJoinFly = false
local lastHash = ""
local lastAt = 0
local usingTextChat = false
local lastRevenge = {}
local ownerTeamStrikes = {}
local protectionConnection = nil
local protectionCharacterConnection = nil
local protectionConnections = {}
local cheaterGui, cheaterLabel
local cheaterTarget = nil
local cheaterActive = false
local cheaterNextLine = 0
local cheaterLineIndex = 0
local CHEATER_LINES = {
    "Please play fair!",
    "Fair play only, everyone!",
    "If you spot cheating, use the report feature.",
    "No exploits, just fair gameplay!",
    "Keep the match fair!",
    "Suspicious gameplay? Report it for review.",
    "Let's keep this server fair!",
    "Play fair and have fun!",
}
local orbiting = false
local orbitTarget = nil
local orbitAngle = 0
local orbitRadius = DEFAULT_ORBIT_RADIUS
local dancing = false
local danceTime = 0
local guardMode = false
local patrolOrigin = nil
local patrolAngle = 0
local scoutOrigin = nil
local scoutReturning = false
local formationType = "dynamic"
local JARVIS_CONFIG_VERSION = 2
local JARVIS_CONFIG_FILE = string.format(
    "JARVIS_%s_%s.json",
    tostring(game.PlaceId),
    tostring(bot.UserId)
)
local JARVIS_FS = {
    read = type(readfile) == "function",
    write = type(writefile) == "function",
    exists = type(isfile) == "function",
}
local persistentLastEncoded = nil
local persistentLoaded = false
local persistentSaveBusy = false
local function persistentCanUse()
    return JARVIS_FS.read and JARVIS_FS.write
end
local function serializeCFrame(cf)
    if typeof(cf) ~= "CFrame" then
        return nil
    end
    return {cf:GetComponents()}
end
local function deserializeCFrame(data)
    if type(data) ~= "table" or #data ~= 12 then
        return nil
    end
    local ok, cf = pcall(CFrame.new, table.unpack(data))
    return ok and cf or nil
end
local function buildPersistentState()
    local marks = {}
    for name, cf in pairs(savedMarks) do
        local encoded = serializeCFrame(cf)
        if encoded then
            marks[name] = encoded
        end
    end
    return {
        version = JARVIS_CONFIG_VERSION,
        squadNames = getgenv().JARVIS_SQUAD_CONFIG.names,
        squadSlots = getgenv().JARVIS_SQUAD_CONFIG.slots,
        botSpacing = getgenv().JARVIS_SQUAD_CONFIG.spacing,
        role = ROLE,
        hostName = HOST_NAME,
        whitelist = JARVIS_WHITELIST,
        extraOwners = extraOwners,
        sharedAccessLevel = sharedAccessLevel,
        revokedOwners = revokedOwners,
        followDistance = followDistance,
        sideDistance = sideDistance,
        cloakDepth = cloakDepth,
        followVerticalOffset = followVerticalOffset,
        followPosition = followPosition,
        formationType = formationType,
        noSit = noSit,
        shut = shut,
        manualSlot = manualSlot,
        manualSpeedOverride = manualSpeedOverride,
        flySpeed = flySpeed,
        kxAdminEnabled = JARVIS_KX_ADMIN_ENABLED,
        marks = marks,
    }
end
local function savePersistentState(force)
    if not persistentCanUse() or persistentSaveBusy then
        return false
    end
    persistentSaveBusy = true
    local ok, encoded = pcall(function()
        return HttpService:JSONEncode(buildPersistentState())
    end)
    if ok and encoded and (force or encoded ~= persistentLastEncoded) then
        ok = pcall(function()
            writefile(JARVIS_CONFIG_FILE, encoded)
        end)
        if ok then
            persistentLastEncoded = encoded
        end
    end
    persistentSaveBusy = false
    return ok == true
end
local function loadPersistentState()
-- Protection is session-only. Never resume it after execute/rejoin.
protecting = false
protectedPlayer = nil
targetPlayer = nil

    if persistentLoaded or not persistentCanUse() then
        return false
    end
    persistentLoaded = true
    if JARVIS_FS.exists then
        local existsOk, exists = pcall(isfile, JARVIS_CONFIG_FILE)
        if not existsOk or not exists then
            return false
        end
    end
    local readOk, raw = pcall(readfile, JARVIS_CONFIG_FILE)
    if not readOk or type(raw) ~= "string" or raw == "" then
        return false
    end
    local decodeOk, data = pcall(function()
        return HttpService:JSONDecode(raw)
    end)
    if not decodeOk or type(data) ~= "table" then
        return false
    end
    if type(data.role) == "string" and (data.role == "host" or data.role == "bot") then
        ROLE = data.role
    end
    if type(data.hostName) == "string" and data.hostName ~= "" then
        HOST_NAME = data.hostName
    end
    if type(data.whitelist) == "table" then
        table.clear(JARVIS_WHITELIST)
        for name, enabled in pairs(data.whitelist) do
            if type(name) == "string" and enabled == true then
                JARVIS_WHITELIST[name:lower()] = true
            end
        end
    end
    if type(data.extraOwners) == "table" then
        table.clear(extraOwners)
        for name, enabled in pairs(data.extraOwners) do
            if type(name) == "string" and enabled == true then
                extraOwners[name:lower()] = true
            end
        end
    end
    if type(data.sharedAccessLevel) == "table" then
        table.clear(sharedAccessLevel)
        for name, level in pairs(data.sharedAccessLevel) do
            if type(name) == "string" and (level == 1 or level == 2) then
                sharedAccessLevel[name:lower()] = level
            end
        end
    end
    if type(data.revokedOwners) == "table" then
        table.clear(revokedOwners)
        for name, enabled in pairs(data.revokedOwners) do
            if type(name) == "string" and enabled == true then
                revokedOwners[name:lower()] = true
            end
        end
    end
    if type(data.squadNames) == "table" then
        for name, enabled in pairs(data.squadNames) do
            if type(name) == "string" and enabled == true then
                getgenv().JARVIS_SQUAD_CONFIG.names[name:lower()] = true
            end
        end
    end
    if type(data.squadSlots) == "table" then
        for name, slot in pairs(data.squadSlots) do
            if type(name) == "string" and type(slot) == "number" and slot >= 1 then
                getgenv().JARVIS_SQUAD_CONFIG.slots[name:lower()] = math.clamp(math.floor(slot), 1, MAX_SLOTS)
            end
        end
    end
    if type(data.botSpacing) == "number" then
        getgenv().JARVIS_SQUAD_CONFIG.spacing = math.clamp(data.botSpacing, 4, 20)
    end
    if type(data.followDistance) == "number" then followDistance = math.clamp(data.followDistance, 1, 50) end
    if type(data.sideDistance) == "number" then sideDistance = math.clamp(data.sideDistance, 0, 50) end
    if type(data.cloakDepth) == "number" then cloakDepth = math.clamp(data.cloakDepth, 2, 30) end
    if type(data.followVerticalOffset) == "number" then followVerticalOffset = math.clamp(data.followVerticalOffset, -30, 30) end
    if type(data.followPosition) == "string" and (data.followPosition == "left" or data.followPosition == "center" or data.followPosition == "right" or data.followPosition == "front" or data.followPosition == "behind") then
        followPosition = data.followPosition
    end
    if type(data.formationType) == "string" then formationType = data.formationType end
    if type(data.noSit) == "boolean" then noSit = data.noSit end
    if type(data.shut) == "boolean" then shut = data.shut end
    if type(data.manualSlot) == "number" then manualSlot = math.clamp(math.floor(data.manualSlot), 1, MAX_SLOTS) end
    if type(data.manualSpeedOverride) == "boolean" then manualSpeedOverride = data.manualSpeedOverride end
    if type(data.flySpeed) == "number" then flySpeed = math.clamp(data.flySpeed, MIN_SPEED, MAX_SPEED) end
    if type(data.kxAdminEnabled) == "boolean" then JARVIS_KX_ADMIN_ENABLED = data.kxAdminEnabled end
    if type(data.marks) == "table" then
        table.clear(savedMarks)
        for name, encoded in pairs(data.marks) do
            local cf = deserializeCFrame(encoded)
            if type(name) == "string" and cf then
                savedMarks[name] = cf
            end
        end
    end
    targetPlayer = nil
    followCamPlayer = nil
    protectedPlayer = nil
    protecting = false
    hiddenLock = false
    frozen = false
    freezeCFrame = nil
    orbiting = false
    dancing = false
    guardMode = false
    invisFollow = false
    invisPosition = nil
    mode = "idle"
    persistentLastEncoded = raw
    return true
end
loadPersistentState()

-- Automatically choose the host account; every other account runs as a bot.
-- Ignore any previous role/host stored in persistent configuration.
HOST_NAME = "x4ay3"
MASTER_NAME = "x4ay3"
masterLower = "x4ay3"
ROLE = bot.Name:lower() == masterLower and "host" or "bot"
IS_LEADER = ROLE == "host"

local function startPersistentSaver()
    if not persistentCanUse() then
        warn("[JARVIS] persistent config unavailable; executor needs readfile/writefile/isfile")
        return
    end
    task.spawn(function()
        while true do
            task.wait(1.5)
            savePersistentState(false)
        end
    end)
end
local lastPosition = nil
local stuckTimer = 0
local sessionCommandCount = 0
local lastCommand = "none"
local LOCAL = {
    follow = true,
    unfollow = true,
    loopfollow = true,
    unloopfollow = true,
    line = true,
    unline = true,
    stop = true,
    idle = true,
    halt = true,
    fly = true,
    unfly = true,
    noclip = true,
    clip = true,
    cam = true,
    view = true,
    uncam = true,
    unview = true,
    reset = true,
    re = true,
    rejoin = true,
    rj = true,
    invis = true,
    invisible = true,
    vis = true,
    uninvis = true,
    visible = true,
    hide = true,
    unhide = true,
    freeze = true,
    unfreeze = true,
    thaw = true,
    panic = true,
    mark = true,
    recall = true,
    marks = true,
    target = true,
    distance = true,
    dist = true,
    face = true,
    front = true,
    behind = true,
    above = true,
    below = true,
    followdist = true,
    sidedist = true,
    cloakdepth = true,
    vertical = true,
    selfcheck = true,
    diag = true,
    diagnostics = true,
    nearest = true,
    near = true,
    untarget = true,
    where = true,
    coords = true,
    recover = true,
    unstuck = true,
    resetoffsets = true,
    settings = true,
    cmdspeed = true,
    park = true,
    unpark = true,
    spin = true,
    unheadsit = true,
    headsit = true,
    unbounce = true,
    unspin = true,
    cmd = true,
    cmds = true,
    help = true,
    commands = true,
    cmdlist = true,
    say = true,
    punchaura = true,
    pa = true,
    share = true,
    share1 = true,
    share2 = true,
    unshare = true,
    owners = true,
    whitelist = true,
    unwhitelist = true,
    wl = true,
    unwl = true,
    shut = true,
    unshut = true,
    slot = true,
    slots = true,
    bots = true,
    botspacing = true,
    call = true,
    who = true,
    hello = true,
    hi = true,
    protect = true,
    fullprotect = true,
    fprotect = true,
    halfprotect = true,
    limitedprotect = true,
    lprotect = true,
    unprotect = true,
    speed = true,
    autospeed = true,
    formation = true,
    form = true,
    cheater = true, uncheater = true,
    orbit = true,
    unorbit = true,
    spiral = true,
    unspiral = true,
    dance = true,
    undance = true,
    cheer = true,
    laugh = true,
    point = true,
    wave = true,
    salute = true,
    bounce = true,
    guard = true,
    unguard = true,
    scout = true,
    unscout = true,
    patrol = true,
    unpatrol = true,
    surround = true,
    unsurround = true,
    assemble = true,
    regroup = true,
    disperse = true,
    ["return"] = true,
    status = true,
    report = true,
    radio = true,
    personality = true,
    mood = true,
    captain = true,
    sit = true,
    nosit = true,
    stand = true,
    invisfollow = true,
    cloakfollow = true,
    ipa = true,
    invispunchaura = true,
    unipa = true,
    sb = true,
    shootback = true,
    ap = true,
    antipunch = true,
}
local ADMIN = {
    kill = true,
    kick = true,
    fling = true,
    dfling = true,
    unfling = true,
    hitbox = true,
    combo1 = true,
    combo2 = true,
    combo3 = true,
    ragebot = true,
    silentaim = true,
    esp = true,
    m4a1 = true,
    reming = true,
    ak = true,
    riot = true,
    mafia = true,
    serverhop = true,
    hop = true,
    toolaura = true,
    bring = true,
    antifling = true,
}
-- Commands available to users granted access with 'share.
-- Destructive/admin escalation commands such as fling remain owner-only.
-- SHARE LEVELS
-- share1: broad access to normal JARVIS commands, but no fling/carfling.
-- share2: basic harmless commands only.
JARVIS_SHARE2_ALLOWED_COMMANDS = {
    spin=true, unspin=true, bounce=true, unbounce=true, headsit=true, unheadsit=true, dance=true,
    cmds=true, help=true, commands=true, cmdlist=true,
    follow=true, stop=true, line=true,
    nearest=true, untarget=true, where=true, coords=true,
    left=true, center=true, right=true, front=true, behind=true,
    above=true, below=true,
    view=true, unview=true,
    orbit=true, unorbit=true,
    dance=true, cheer=true, laugh=true, point=true,
    status=true, report=true, settings=true,
}

JARVIS_SHARE1_BLOCKED_COMMANDS = {
    fling=true, carfling=true,
}

local COMMAND_HELP = {
    {
        "CORE  follow line stop fly protect punchaura invis vis hide unhide share shut cmds",
        "TARGET  target <player> | nearest | untarget | distance | face <player>",
        "POSITION  left center right front behind above below | park unpark",
    },
    {
        "ADMIN  kill <player> | kill <player> <number> | k guards/inmates/criminals",
        "WEAPONS  .combo1 .combo2 .combo3 .m4a1 .reming .ak",
        "SAFETY  protect [player] = 10-stud orbit guard; same team = punch aura, enemy = .kill | unprotect | panic | recover",
    },
    {
        "FOLLOW  follow [player] / loopfollow [player] / line / left center right",
        "TUNING  followdist <n> / sidedist <n> / vertical <n> / cloakdepth <n>",
        "RESET  resetoffsets restores default follow/side/vertical/cloak values",
    },
    {
        "CLOAK  invis [player] / invisfollow [player] / vis / hide / unhide",
        "FORMATION  dynamic v diamond wall circle columns",
        "BOT SPACING  bots [full usernames] | bots reset | botspacing 4-20 | slots",
        "SQUAD  assemble regroup disperse line guard surround return",
    },
    {
        "POSITION  mark [name] / recall [name] / marks / freeze / unfreeze",
        "LOCATION  where / coords / distance",
        "CAMERA  .view .unview | 'view <player> | face <player>",
    },
    {
        "FUN  orbit spiral dance [1-3] wave cheer laugh point salute bounce scout patrol spin",
        "CONTROL  share unshare owners | whitelist/wl <player> | unwhitelist/unwl <player>",
        "INFO  status report selfcheck settings radio captain who personality mood",
    },
    {
        "CHAT  cmds [page] / cmdspeed | full list is queued with adaptive pacing",
        "ADMIN  'cmd <full command> keeps every word/argument and forwards it to the bot.",
        "NOCLIP  continuous local noclip | 'noclip enables | 'clip disables",
    },
    {
        "RECOVERY  panic = clean idle reset | recover/unstuck = movement repair",
        "TARGETING  nearest selects closest player; untarget returns target to owner",
        "STATUS  settings shows movement tuning + adaptive chat interval",
    },
}
local function findPlayer(name)
    if not name or name == "" then
        return nil
    end
    name = tostring(name):lower()
    if name == "me" or name == "master" then
        name = masterLower
    end
    local exact
    local prefix
    local partial
    for _, p in ipairs(Players:GetPlayers()) do
        local n = p.Name:lower()
        local d = (p.DisplayName or ""):lower()
        if n == name or d == name then
            exact = p
            break
        end
        if n:sub(1, #name) == name
            or d:sub(1, #name) == name
        then
            prefix = prefix or p
        end
        if n:find(name, 1, true)
            or d:find(name, 1, true)
        then
            partial = partial or p
        end
    end
    return exact or prefix or partial
end
local function getMaster()
    return findPlayer(MASTER_NAME)
end
local function rootOf(plr)
    local character = plr and plr.Character
    return character and character:FindFirstChild("HumanoidRootPart")
end
local function humOf(plr)
    local character = plr and plr.Character
    return character and character:FindFirstChildOfClass("Humanoid")
end
local function headOf(plr)
    local character = plr and plr.Character
    if not character then
        return nil
    end
    return character:FindFirstChild("Head")
        or character:FindFirstChild("HumanoidRootPart")
end
local function myRoot()
    return rootOf(bot)
end
local function myHum()
    return humOf(bot)
end
local noSitConnection = nil
local otherCmd
local function applyNoSitState()
    local hum = myHum()
    if not hum then
        return
    end
    if noSitConnection then
        noSitConnection:Disconnect()
        noSitConnection = nil
    end
    hum:SetStateEnabled(Enum.HumanoidStateType.Seated, not noSit)
    if noSit then
        hum.Sit = false
        if hum:GetState() == Enum.HumanoidStateType.Seated then
            hum:ChangeState(Enum.HumanoidStateType.GettingUp)
        end
        noSitConnection = hum.Seated:Connect(function(seated)
            if seated and noSit then
                hum.Sit = false
                hum:ChangeState(Enum.HumanoidStateType.GettingUp)
            end
        end)
    end
end
local function setNoSit(on)
    noSit = on == true
    applyNoSitState()
end
local respawnRecoverySerial = 0
local function runRespawnNoclipRecovery(char)
    if IS_LEADER then
        return
    end
    respawnRecoverySerial += 1
    local mySerial = respawnRecoverySerial
    task.spawn(function()
        local activeChar = char or bot.Character
        if not activeChar then
            activeChar = bot.CharacterAdded:Wait()
        end
        local hum = activeChar:WaitForChild("Humanoid", 8)
        local root = activeChar:WaitForChild("HumanoidRootPart", 8)
        if not hum or not root then
            return
        end
        task.wait(0.35)
        if mySerial ~= respawnRecoverySerial or bot.Character ~= activeChar then
            return
        end
        applyNoSitState()
        if frozen and not hiddenLock then
            frozen = false
            freezeCFrame = nil
        end
        if hiddenLock then
            task.wait(0.05)
            local newRoot = myRoot()
            if newRoot then
                newRoot.AssemblyLinearVelocity = Vector3.zero
                newRoot.AssemblyAngularVelocity = Vector3.zero
                newRoot.CFrame = getgenv().JARVIS_SQUAD.frame(HIDE_CFRAME)
            end
        end
    end)
end
bot.CharacterAdded:Connect(function(char)
    runRespawnNoclipRecovery(char)
end)
local function activeTarget()
    if targetPlayer and targetPlayer.Parent then
        return targetPlayer
    end
    return getMaster()
end
local function isMasterTarget()
    local target = activeTarget()
    return target
        and target.Name:lower() == masterLower
end
local function camRoot()
    if followCamPlayer and followCamPlayer.Parent then
        return rootOf(followCamPlayer)
    end
    return rootOf(getMaster())
end
local function isOwnerName(name)
    if not name then
        return false
    end
    name = tostring(name):lower()
    if name == masterLower then
        return true
    end
    if revokedOwners[name] then
        return false
    end
    if extraOwners[name] then
        return true
    end
    local p = findPlayer(name)
    if p then
        local canonical = p.Name:lower()
        if revokedOwners[canonical] then
            return false
        end
        if extraOwners[canonical] then
            return true
        end
        if targetPlayer == p
            and (mode == "follow" or mode == "loopfollow" or invisFollow)
        then
            return true
        end
    end
    return false
end
local function isAlly(p)
    if not p then
        return false
    end
    if getgenv().JARVIS_SQUAD and getgenv().JARVIS_SQUAD.isPeer(p) then
        return true
    end
    local n = p.Name:lower()
    if n == masterLower then
        return true
    end
    if n == bot.Name:lower() then
        return true
    end
    if extraOwners[n] then
        return true
    end
    if p:GetAttribute("EagleBot") == true then
        return true
    end
    if n:find("eagletestsubject", 1, true) then
        return true
    end
    return false
end
local function isEagleUnit(p)
    if getgenv().JARVIS_SQUAD then return getgenv().JARVIS_SQUAD.isPeer(p) end
    if not p or p.Name:lower() == masterLower then return false end
    return p == bot or p:GetAttribute("EagleBot") == true
        or p.Name:lower():find("eagletestsubject", 1, true) ~= nil
end
local function getEagleUnits()
    if getgenv().JARVIS_SQUAD then return getgenv().JARVIS_SQUAD.units() end
    local units = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if isEagleUnit(p) then
            table.insert(units, p)
        end
    end
    table.sort(units, function(a, b)
        if a.UserId == b.UserId then
            return a.Name:lower() < b.Name:lower()
        end
        return a.UserId < b.UserId
    end)
    return units
end
local function getJarvisNumber()
    if IS_LEADER then
        return 0
    end
    return mySlot
end
local function getJarvisName()
    if IS_LEADER then
        return "JARVIS-MASTER"
    end
    return string.format("JARVIS-%02d", getJarvisNumber())
end
local function getAutomaticSlot()
    if IS_LEADER then return 0 end
    if getgenv().JARVIS_SQUAD then
        getgenv().JARVIS_SQUAD.dirty = true
        getgenv().JARVIS_SQUAD.units()
        return getgenv().JARVIS_SQUAD.slots[bot.UserId] or 1
    end
    for index, player in ipairs(getEagleUnits()) do
        if player == bot then return index end
    end
    return 1
end
local function refreshSlot()
    if IS_LEADER then
        mySlot = 0
        return
    end
    mySlot = getAutomaticSlot()
    print(
        "[JARVIS] automatic slot:",
        mySlot
    )
end
local function canTalk()
    return not IS_LEADER
        and not shut
        and ((getgenv().JARVIS_SQUAD and getgenv().JARVIS_SQUAD.index() == 1)
            or (not getgenv().JARVIS_SQUAD and mySlot == 1))
end
local function isInsidePrison()
    local root = myRoot()
    if not root then
        return false
    end
    local p = root.Position
    return p.X >= PRISON_BOUNDS.minX
        and p.X <= PRISON_BOUNDS.maxX
        and p.Z >= PRISON_BOUNDS.minZ
        and p.Z <= PRISON_BOUNDS.maxZ
end
local function updateAutomaticSpeed()
    if manualSpeedOverride then
        return
    end
    if isInsidePrison() then
        flySpeed = PRISON_SPEED
    else
        flySpeed = OUTSIDE_SPEED
    end
end
local function floorY()
    local masterRoot = rootOf(getMaster())
    if masterRoot then
        return masterRoot.Position.Y
    end
    local me = myRoot()
    if me then
        return me.Position.Y
    end
    return 0
end
local function flatten(v)
    if not v then
        return nil
    end
    if not groundLock then
        return v
    end
    return Vector3.new(
        v.X,
        floorY(),
        v.Z
    )
end
local function say(text, bypassMute)
    if type(text) ~= "string" or text == "" then
        return
    end
    -- 'shut only silences JARVIS speech. Internal/admin commands still need to
    -- be typed into chat so the game's admin parser can receive them.
    if shut and not bypassMute then
        return
    end
    table.insert(sayQ, {text = text, bypassMute = bypassMute == true})
    if sayBusy then
        return
    end
    sayBusy = true
    task.spawn(function()
        while #sayQ > 0 do
            local item = table.remove(sayQ, 1)
            local line = type(item) == "table" and item.text or item
            local force = type(item) == "table" and item.bypassMute == true

            -- While shut, discard ordinary speech but KEEP command traffic.
            if shut and not force then
                continue
            end

            local epoch = getgenv().JARVIS_CHAT_EPOCH
            local sent = false
            pcall(function()
                local channels = TextChatService:FindFirstChild("TextChannels")
                local channel = channels and (
                    channels:FindFirstChild("RBXGeneral")
                    or channels:FindFirstChild("General")
                )
                if channel and (not shut or force) then
                    channel:SendAsync(
                        line,
                        getgenv().JARVIS_SQUAD and getgenv().JARVIS_SQUAD.metadata() or ""
                    )
                    sent = true
                end
            end)
            if not sent and (not shut or force) then
                pcall(function()
                    local folder = ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents")
                    local request = folder and folder:FindFirstChild("SayMessageRequest")
                    if request then
                        request:FireServer(line, "All")
                        sent = true
                    end
                end)
            end
            if sent then
                chatMessagesSent += 1
            end
            if os.clock() - lastChatFloodAt > 12 then
                adaptiveChatDelay = math.max(CHAT_MIN_DELAY, adaptiveChatDelay - CHAT_RECOVERY_STEP)
            end
            task.wait(adaptiveChatDelay)
        end
        sayBusy = false
    end)
end
local function voice(text)
    if canTalk() then
        say(text)
    end
end
-- JARVIS MULTI-BOT FORMATION LINK
-- Discovery is informational: it never gives a peer command/owner access.
-- Same-workspace clients exchange short-lived JSON records. TextChat clients
-- also announce themselves using message metadata; normal chat permissions apply.
do
    local env = getgenv()
    if env.JARVIS_SQUAD and env.JARVIS_SQUAD.stop then
        env.JARVIS_SQUAD.stop()
    end
    local squad = {peers = {}, cache = {}, slots = {}, dirty = true, running = true}
    env.JARVIS_SQUAD = squad
    local connections = {}
    local config = env.JARVIS_SQUAD_CONFIG
    local nextCache = 0
    local nextHello = 0
    local helloPending = false
    local prefix = "JARVIS_SQUAD_V1|"
    local job = tostring(game.JobId)
    local place = game.PlaceId
    local owner = masterLower
    local filePrefix = "JARVIS/squad_" .. tostring(place) .. "_"
        .. job:gsub("[^%w%-]", "_") .. "_" .. owner .. "_"
    local fileOK = type(readfile) == "function" and type(writefile) == "function"
        and type(isfile) == "function" and type(isfolder) == "function"
        and type(makefolder) == "function"
    if fileOK then
        fileOK = pcall(function()
            if not isfolder("JARVIS") then makefolder("JARVIS") end
        end)
    end

    function squad.now()
        -- Shared phase, independent of each client's start time and frame rate.
        -- API: https://create.roblox.com/docs/reference/engine/classes/Workspace#GetServerTimeNow
        local ok, now = pcall(function() return workspace:GetServerTimeNow() end)
        if ok then return now end
        return os.time()
    end

    function squad.isPeer(player)
        if not player or not player.Parent then return false end
        if player.Name:lower() == owner then return false end
        if player == bot then return not IS_LEADER end
        local name = player.Name:lower()
        if config.names[name] then return true end
        local peer = squad.peers[player.UserId]
        -- Keep an already-discovered roster while every bot is deliberately silent.
        -- Departures still remove peers immediately; file discovery continues.
        if peer and (shut or peer.expires > os.clock()) then return true end
        -- Retain support for existing server-marked/named Eagle units.
        return player:GetAttribute("EagleBot") == true
            or name:find("eagletestsubject", 1, true) ~= nil
    end

    function squad.units()
        if not squad.dirty and os.clock() < nextCache then return squad.cache end
        local units = {}
        for _, player in ipairs(Players:GetPlayers()) do
            if squad.isPeer(player) then table.insert(units, player) end
        end
        -- Do not remove dead/respawning units and reshuffle every other bot.
        table.sort(units, function(a, b) return a.UserId < b.UserId end)
        local slots, occupied = {}, {}
        for _, player in ipairs(units) do
            local peer = squad.peers[player.UserId]
            local preferred = config.slots[player.Name:lower()]
                or (player == bot and manualSlot)
                or (peer and peer.slot) or SLOT_MAP[player.Name:lower()]
            preferred = tonumber(preferred)
            if preferred and preferred >= 1 and preferred <= MAX_SLOTS then
                preferred = math.floor(preferred)
                if not occupied[preferred] then
                    slots[player.UserId], occupied[preferred] = preferred, true
                end
            end
        end
        local available = 1
        for _, player in ipairs(units) do
            if not slots[player.UserId] then
                while occupied[available] do available = available + 1 end
                slots[player.UserId], occupied[available] = available, true
            end
        end
        table.sort(units, function(a, b) return slots[a.UserId] < slots[b.UserId] end)
        squad.cache, squad.slots = units, slots
        squad.dirty, nextCache = false, os.clock() + 0.5
        if not IS_LEADER then mySlot = slots[bot.UserId] or 1 end
        return units
    end

    function squad.index()
        local units = squad.units()
        for index, player in ipairs(units) do
            if player == bot then return index, #units end
        end
        return 1, math.max(1, #units)
    end

    function squad.gap()
        return math.clamp(tonumber(config.spacing) or 6, 4, 20)
    end

    function squad.offset(goal, cf)
        if not goal then return nil end
        local index, count = squad.index()
        if count < 2 then return goal end
        -- Five columns at most; larger groups receive extra rows.
        local row = math.floor((index - 1) / 5)
        local columns = math.min(5, count - row * 5)
        local column = (index - 1) % 5 + 1
        local side = (column - (columns + 1) / 2) * squad.gap()
        local right = Vector3.new(cf.RightVector.X, 0, cf.RightVector.Z)
        if right.Magnitude < 0.001 then right = Vector3.new(1, 0, 0) end
        right = right.Unit
        local back = Vector3.new(-right.Z, 0, right.X)
        return goal + right * side + back * (row * squad.gap())
    end

    function squad.frame(cf)
        return CFrame.new(squad.offset(cf.Position, cf)) * (cf - cf.Position)
    end

    function squad.ring(radius, speed)
        local index, count = squad.index()
        if count > 1 then
            radius = math.max(radius, squad.gap() / (2 * math.sin(math.pi / count)))
        end
        local phase = (squad.now() * (speed or 0)) % (2 * math.pi)
        return phase + (index - 1) * 2 * math.pi / count, radius
    end

    function squad.avoid(position, dt)
        -- Move only this bot. No peer part, hitbox or collision group is changed.
        local correction = Vector3.zero
        local distance = math.min(4, squad.gap() * 0.75)
        for _, peer in ipairs(squad.units()) do
            if peer ~= bot then
                local other = rootOf(peer)
                local hum = humOf(peer)
                if other and hum and hum.Health > 0
                    and math.abs(position.Y - other.Position.Y) < 4 then
                    local delta = Vector3.new(position.X - other.Position.X, 0,
                        position.Z - other.Position.Z)
                    local length = delta.Magnitude
                    if length < distance then
                        if length < 0.001 then
                            -- Exact overlap needs a repeatable, opposite escape direction.
                            local angle = ((math.min(bot.UserId, peer.UserId)
                                + math.max(bot.UserId, peer.UserId)) % 360) * math.pi / 180
                            local sign = bot.UserId < peer.UserId and -1 or 1
                            delta = Vector3.new(math.cos(angle), 0, math.sin(angle)) * sign
                        else
                            delta = delta / length
                        end
                        correction = correction + delta * (distance - length)
                    end
                end
            end
        end
        local length = correction.Magnitude
        if length > 0 then
            correction = correction / length * math.min(length, 18 * math.clamp(dt, 0, 0.1))
        end
        return position + correction
    end

    local function receive(player, slot, lifetime)
        if not squad.running or not player or player == bot
            or player.Name:lower() == owner then return end
        local old = squad.peers[player.UserId]
        squad.peers[player.UserId] = {slot = tonumber(slot) or 0,
            expires = os.clock() + lifetime}
        squad.dirty = true
        if not old and squad.hello then squad.hello() end
    end

    function squad.metadata()
        if IS_LEADER or owner == "" then return "" end
        return prefix .. owner .. "|" .. tostring(bot.UserId) .. "|"
            .. tostring(manualSlot or config.slots[bot.Name:lower()] or 0)
    end

    function squad.hello()
        if shut or IS_LEADER or owner == "" or helloPending or os.clock() < nextHello then return end
        local epoch = getgenv().JARVIS_CHAT_EPOCH
        helloPending = true
        task.delay(1 + (math.abs(bot.UserId) % 7) * 0.25, function()
            helloPending = false
            if not squad.running or shut or epoch ~= getgenv().JARVIS_CHAT_EPOCH then return end
            nextHello = os.clock() + 30
            -- Uses the existing paced queue; metadata is attached in say().
            say("JARVIS formation link ready.")
        end)
    end

    function squad.receiveChat(sender, text, metadata)
        local raw = tostring(metadata or "")
        if raw:sub(1, #prefix) ~= prefix then return false end
        local claimedOwner, uid, slot = raw:match("^JARVIS_SQUAD_V1|([%w_]+)|(%d+)|(%d+)$")
        local player = Players:FindFirstChild(sender)
        if claimedOwner == owner and player and player.UserId == tonumber(uid) then
            receive(player, slot, 180)
        end
        return text == "JARVIS formation link ready."
    end

    local function exchangeFiles()
        if not fileOK or IS_LEADER or owner == "" or job == "" then return end
        local now = squad.now()
        pcall(function()
            writefile(filePrefix .. tostring(bot.UserId) .. ".json", HttpService:JSONEncode({
                version = 1, owner = owner, job = job, place = place, uid = bot.UserId,
                slot = manualSlot or config.slots[bot.Name:lower()] or 0, at = now,
            }))
        end)
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= bot and player.Name:lower() ~= owner then
                pcall(function()
                    local path = filePrefix .. tostring(player.UserId) .. ".json"
                    if not isfile(path) then return end
                    local record = HttpService:JSONDecode(readfile(path))
                    if type(record) == "table" and record.version == 1
                        and record.owner == owner and record.job == job
                        and record.place == place and record.uid == player.UserId
                        and type(record.at) == "number" and now - record.at >= -2
                        and now - record.at <= 15 then
                        receive(player, record.slot, 15)
                    end
                end)
            end
        end
    end

    function squad.command(cmd, rest, sender)
        if cmd ~= "bots" and cmd ~= "botspacing" then return false end
        if tostring(sender or ""):lower() ~= owner then
            voice("only the owner can change the bot roster or spacing.")
            return true
        end
        if cmd == "botspacing" then
            local amount = tonumber(rest)
            if amount then config.spacing = math.clamp(amount, 4, 20) end
            voice("bot spacing " .. tostring(squad.gap()) .. " studs.")
        elseif rest == "reset" then
            table.clear(config.names)
            table.clear(config.slots)
            manualSlot = nil
            voice("manual bot roster cleared; automatic discovery active.")
        elseif rest ~= "" then
            -- Exact account usernames avoid selecting someone by an ambiguous prefix.
            local names = {}
            for name in rest:lower():gmatch("[%w_]+") do
                local found = nil
                for _, player in ipairs(Players:GetPlayers()) do
                    if player.Name:lower() == name then found = player break end
                end
                if not found or name == owner then
                    voice("bot username not found: " .. name .. ". Use full account usernames.")
                    return true
                end
                names[name] = true
            end
            if next(names) then config.names = names end
        end
        squad.dirty = true
        local units = squad.units()
        local names = {}
        for _, player in ipairs(units) do
            table.insert(names, tostring(squad.slots[player.UserId]) .. "=" .. player.Name)
        end
        print("[JARVIS] bot roster | " .. table.concat(names, ", "))
        if cmd == "bots" then voice("bots: " .. table.concat(names, ", ")) end
        savePersistentState(true)
        squad.hello()
        return true
    end

    function squad.setMuted(enabled)
        shut = enabled == true
        getgenv().JARVIS_CHAT_EPOCH = (getgenv().JARVIS_CHAT_EPOCH or 0) + 1
        table.clear(sayQ)
        -- An unmute must not briefly turn each bot into a one-member squad.
        for _, peer in pairs(squad.peers) do
            peer.expires = math.max(peer.expires, os.clock() + 180)
        end
        squad.dirty = true
        savePersistentState(true)
        if not shut then nextHello = 0 squad.hello() end
    end

    function squad.stop()
        squad.running = false
        for _, connection in ipairs(connections) do connection:Disconnect() end
    end
    table.insert(connections, Players.PlayerAdded:Connect(function()
        squad.dirty = true
        squad.hello()
    end))
    table.insert(connections, Players.PlayerRemoving:Connect(function(player)
        squad.peers[player.UserId] = nil
        squad.dirty = true
    end))
    task.spawn(function()
        local nextAnnounce = 0
        while squad.running do
            exchangeFiles()
            squad.units()
            if os.clock() >= nextAnnounce then
                squad.hello()
                nextAnnounce = os.clock() + 60 + math.abs(bot.UserId) % 11
            end
            task.wait(3)
        end
    end)
end

TextChatService.MessageReceived:Connect(function(msg)
    local ok, text, source = pcall(function()
        return tostring(msg.Text or ""), msg.TextSource
    end)
    if not ok then return end
    local lower = text:lower()
    if source == nil and (
        lower:find("wait before sending another message", 1, true)
        or lower:find("wait before sending", 1, true)
        or lower:find("too many messages", 1, true)
    ) then
        lastChatFloodAt = os.clock()
        adaptiveChatDelay = math.min(
            CHAT_MAX_DELAY,
            adaptiveChatDelay + CHAT_BACKOFF
        )
        warn(string.format(
            "[JARVIS] chat throttle detected; adaptive delay now %.2fs",
            adaptiveChatDelay
        ))
    end
end)
-- F6-selected Vape V4 command-box transport.
-- Focus/click the REAL Vape V4 command TextBox, then press F6 once.
-- JARVIS remembers that exact TextBox and uses it for future admin/module commands.
do
local UIS_CMD = game:GetService("UserInputService")
local VIM_CMD = game:GetService("VirtualInputManager")
local capturedCommandBox = nil

local MODULE_ALIASES = {
    diedtp='diedtp', deathtp='diedtp', dtp='diedtp',
    autore='autoreload', ar='autoreload', reloadauto='autoreload',
    notaze='antitaze', notaser='antitaze', antitazer='antitaze', at='antitaze',
    af='antifling', nofling='antifling',
    sa='silentaim', rb='ragebot', ta='toolaura', esp='esp'
}

local function normalizeCommand(body)
    body=tostring(body or ''):gsub('^%s+',''):gsub('%s+$','')
    body=body:gsub('^[%.;]+','')
    local name,args=body:match('^(%S+)%s*(.*)$')
    if not name then return '' end
    name=name:lower()
    name=MODULE_ALIASES[name] or name
    return name..((args and args~='') and (' '..args) or '')
end

local function boxAlive(box)
    return box and box.Parent and box:IsA("TextBox")
end

local function captureFocusedBox()
    local focused=UIS_CMD:GetFocusedTextBox()
    if not focused or not focused:IsA("TextBox") then
        warn("[JARVIS] F6: click/focus the Vape V4 command box first, then press F6.")
        return false
    end
    capturedCommandBox=focused
    getgenv().JARVIS_VAPE_COMMAND_BOX=focused
    print("[JARVIS] F6 connected to command box:",focused:GetFullName())
    return true
end

-- Reuse a still-live capture after script-side reinitialization when possible.
local previous=(getgenv and getgenv().JARVIS_VAPE_COMMAND_BOX)
if boxAlive(previous) then
    capturedCommandBox=previous
end

UIS_CMD.InputBegan:Connect(function(input,gpe)
    if input.KeyCode==Enum.KeyCode.F6 then
        captureFocusedBox()
    end
end)

otherCmd = function(body, prefixOverride)
    if IS_LEADER then return false end
    if JARVIS_KX_ADMIN_ENABLED == false then return false end

    body=normalizeCommand(body)
    if body=='' then return false end

    local releaseCmd=(body:match('^(%S+)') or ''):lower()
    if releaseCmd~='invis' and releaseCmd~='vis'
        and releaseCmd~='noclip' and releaseCmd~='clip'
        and releaseCmd~='antifling' then
        local combatRelease={
            combo1=true,combo2=true,combo3=true,
            kill=true,
            fling=true,bring=true,hitbox=true,
            ragebot=true,silentaim=true,
            m4a1=true,reming=true,ak=true,riot=true,mafia=true,
        }
        local releaseTime=combatRelease[releaseCmd]
            and JARVIS_FOLLOW_COMBAT_RELEASE or JARVIS_FOLLOW_ADMIN_RELEASE
        releaseSoftFollow(releaseTime)
        if invisFollow then
            releaseSoftCloak(combatRelease[releaseCmd]
                and JARVIS_CLOAK_COMBAT_RELEASE or JARVIS_CLOAK_ADMIN_RELEASE)
        end
    end

    if not boxAlive(capturedCommandBox) then
        local saved=(getgenv and getgenv().JARVIS_VAPE_COMMAND_BOX)
        if boxAlive(saved) then capturedCommandBox=saved end
    end
    if not boxAlive(capturedCommandBox) then
        warn("[JARVIS] No Vape command box connected. Focus it and press F6.")
        return false
    end

    local prefix=prefixOverride or DOT or '.'
    if prefix=='' then prefix='.' end
    local fullCommand=prefix..body

    local ok,err=pcall(function()
        capturedCommandBox:CaptureFocus()
        capturedCommandBox.Text=fullCommand
        capturedCommandBox.CursorPosition=#fullCommand+1
        task.wait()
        VIM_CMD:SendKeyEvent(true,Enum.KeyCode.Return,false,game)
        VIM_CMD:SendKeyEvent(false,Enum.KeyCode.Return,false,game)
        capturedCommandBox:ReleaseFocus(true)
    end)
    if not ok then
        warn("[JARVIS] command-box send failed:",err)
        return false
    end

    print("[JARVIS] -> captured Vape box:",fullCommand)
    return true
end
end

local lastTeamRecoveryAt = 0
bot:GetPropertyChangedSignal("Team"):Connect(function()
    if IS_LEADER then
        return
    end
    local stamp = os.clock()
    lastTeamRecoveryAt = stamp
    task.delay(0.75, function()
        if lastTeamRecoveryAt ~= stamp then
            return
        end
        local char = bot.Character
        if not char then
            return
        end
        local hum = char:FindFirstChildOfClass("Humanoid")
        local root = char:FindFirstChild("HumanoidRootPart")
        if hum and root and hum.Health > 0 then
            if hiddenLock then
                root.AssemblyLinearVelocity = Vector3.zero
                root.AssemblyAngularVelocity = Vector3.zero
                root.CFrame = getgenv().JARVIS_SQUAD.frame(HIDE_CFRAME)
            end
        end
    end)
end)
local function setNoclipAdmin(on)
    if IS_LEADER then
        return
    end
    if on then
        -- Never reactivate noclip while Combo2 is collecting weapons.
        if os.clock() < (JARVIS_COMBO2_EXCLUSIVE_UNTIL or 0) then
            return
        end
        pcall(function()
            if Noclipping then
                Noclipping:Disconnect()
            end
        end)
        noclipOn = true
        NoclipParts = {}
        local firstChar = bot.Character
        if firstChar then
            for _, child in ipairs(firstChar:GetDescendants()) do
                if child:IsA("BasePart") and child.CanCollide == true then
                    child.CanCollide = false
                    NoclipParts[child] = true
                end
            end
        end
        Noclipping = RunService.Stepped:Connect(function()
            if not noclipOn then
                return
            end
            local char = bot.Character
            if not char then
                return
            end
            for _, child in ipairs(char:GetDescendants()) do
                if child:IsA("BasePart") then
                    if child.CanCollide == true then
                        NoclipParts[child] = true
                    end
                    child.CanCollide = false
                end
            end
        end)
    else
        noclipOn = false
        if Noclipping then
            pcall(function()
                Noclipping:Disconnect()
            end)
            Noclipping = nil
        end
        for part in pairs(NoclipParts) do
            if part and part.Parent then
                pcall(function()
                    part.CanCollide = true
                end)
            end
        end
        NoclipParts = {}
    end
end
task.spawn(function()
    task.wait(0.35)
    if not IS_LEADER then
        setNoclipAdmin(true)
        print("[JARVIS] continuous client noclip enabled")
    end
end)
local function partPositionForInteraction(inst)
    if not inst then return nil end
    if inst:IsA("BasePart") then return inst.Position end
    local current = inst
    while current and current ~= workspace do
        if current:IsA("BasePart") then
            return current.Position
        end
        if current:IsA("Model") then
            return current:GetPivot().Position
        end
        current = current.Parent
    end
    return nil
end
local function nearestBasePartAncestor(inst)
    local current = inst
    while current and current ~= workspace do
        if current:IsA("BasePart") then
            return current
        end
        current = current.Parent
    end
    return nil
end
local function looksLikeCarSpawner(inst)
    local pieces = {}
    local function add(v)
        if v ~= nil then
            table.insert(pieces, tostring(v):lower())
        end
    end
    add(inst.Name)
    if inst:IsA("TextLabel") or inst:IsA("TextButton") or inst:IsA("TextBox") then
        add(inst.Text)
    elseif inst:IsA("ProximityPrompt") then
        add(inst.ActionText)
        add(inst.ObjectText)
    end
    local current = inst.Parent
    for _ = 1, 4 do
        if not current or current == workspace then break end
        add(current.Name)
        current = current.Parent
    end
    local text = table.concat(pieces, " ")
    return (
        text:find("spawn car", 1, true)
        or text:find("spawncar", 1, true)
        or text:find("car spawn", 1, true)
        or text:find("carspawn", 1, true)
        or text:find("vehicle spawn", 1, true)
        or text:find("vehicle", 1, true) and text:find("spawn", 1, true)
    ) ~= nil
end
local function findCarSpawnerCandidates()
    local found = {}
    local added = {}
    local function push(inst, kind, bonus)
        if not inst or added[inst] then return end
        local pos = partPositionForInteraction(inst)
        if not pos then return end
        local distance = (pos - CAR_SPAWNER_POSITION).Magnitude
        if distance > CAR_BUTTON_RADIUS then return end
        added[inst] = true
        table.insert(found, {
            object = inst,
            kind = kind,
            distance = distance,
            score = distance + (bonus or 0),
        })
    end
    for _, inst in ipairs(workspace:GetDescendants()) do
        if inst:IsA("ClickDetector") then
            push(inst, "click", -50)
        elseif inst:IsA("ProximityPrompt") then
            push(inst, "prompt", -45)
        elseif (inst:IsA("TextLabel") or inst:IsA("TextButton") or inst:IsA("TextBox"))
            and looksLikeCarSpawner(inst)
        then
            local part = nearestBasePartAncestor(inst)
            if part then
                push(part, "labelpart", -70)
            end
        elseif inst:IsA("BasePart") and looksLikeCarSpawner(inst) then
            push(inst, "namedpart", -60)
        end
    end
    for _, inst in ipairs(workspace:GetPartBoundsInRadius(CAR_SPAWNER_POSITION, 14)) do
        if inst:IsA("BasePart") then
            push(inst, "physical", 25)
        end
    end
    table.sort(found, function(a, b)
        if a.score == b.score then
            return a.distance < b.distance
        end
        return a.score < b.score
    end)
    return found
end
local function faceInteractionPosition(pos)
    local root = myRoot()
    if not root or not pos then return end
    local flat = Vector3.new(pos.X, root.Position.Y, pos.Z)
    if (flat - root.Position).Magnitude > 0.05 then
        root.CFrame = CFrame.lookAt(root.Position, flat)
    end
end
local function screenClickWorldPosition(pos)
    if not pos then return false end
    local point, visible = camera:WorldToViewportPoint(pos)
    if not visible or point.Z <= 0 then
        return false
    end
    local x, y = point.X, point.Y
    if VirtualInputManager then
        local ok = pcall(function()
            VirtualInputManager:SendMouseButtonEvent(x, y, 0, true, game, 0)
            task.wait(0.05)
            VirtualInputManager:SendMouseButtonEvent(x, y, 0, false, game, 0)
        end)
        if ok then return true end
    end
    local ok = pcall(function()
        VirtualUser:CaptureController()
        VirtualUser:Button1Down(Vector2.new(x, y), camera.CFrame)
        task.wait(0.05)
        VirtualUser:Button1Up(Vector2.new(x, y), camera.CFrame)
    end)
    return ok
end
local function physicallyTouchSpawner(part)
    if not part or not part:IsA("BasePart") then
        return false
    end
    local root = myRoot()
    if not root then return false end
    if type(firetouchinterest) == "function" then
        local ok = pcall(function()
            firetouchinterest(root, part, 0)
            task.wait(0.08)
            firetouchinterest(root, part, 1)
        end)
        if ok then
            return true
        end
    end
    local original = root.CFrame
    local topY = part.Position.Y + (part.Size.Y * 0.5)
    local target = CFrame.new(part.Position.X, topY + 1.8, part.Position.Z)
    pcall(function()
        root.CFrame = target
        root.AssemblyLinearVelocity = Vector3.new(0, -10, 0)
    end)
    task.wait(0.18)
    pcall(function()
        root.CFrame = CFrame.new(part.Position.X, topY + 0.4, part.Position.Z)
    end)
    task.wait(0.18)
    return true
end
local function activateSpawnerCandidate(item)
    if not item or not item.object then return false end
    local obj = item.object
    local pos = partPositionForInteraction(obj)
    if pos then
        faceInteractionPosition(pos)
    end
    if obj:IsA("ClickDetector") then
        if type(fireclickdetector) == "function" then
            local ok = pcall(function()
                fireclickdetector(obj)
            end)
            if ok then return true end
        end
        if pos and screenClickWorldPosition(pos) then
            return true
        end
        local part = nearestBasePartAncestor(obj)
        if part then
            return physicallyTouchSpawner(part)
        end
    elseif obj:IsA("ProximityPrompt") then
        if type(fireproximityprompt) == "function" then
            local ok = pcall(function()
                fireproximityprompt(obj)
            end)
            if ok then return true end
        end
        local ok = pcall(function()
            obj:InputHoldBegin()
            task.wait(math.max(obj.HoldDuration, 0.05))
            obj:InputHoldEnd()
        end)
        if ok then return true end
        local part = nearestBasePartAncestor(obj)
        if part then
            return physicallyTouchSpawner(part)
        end
    elseif obj:IsA("BasePart") then
        for _, d in ipairs(obj:GetDescendants()) do
            if d:IsA("ClickDetector") then
                if type(fireclickdetector) == "function" then
                    local ok = pcall(function() fireclickdetector(d) end)
                    if ok then return true end
                end
            elseif d:IsA("ProximityPrompt") then
                if type(fireproximityprompt) == "function" then
                    local ok = pcall(function() fireproximityprompt(d) end)
                    if ok then return true end
                end
            end
        end
        if pos then
            screenClickWorldPosition(pos)
        end
        return physicallyTouchSpawner(obj)
    end
    return false
end
local function snapshotVehicleSeats()
    local seen = {}
    for _, inst in ipairs(workspace:GetDescendants()) do
        if inst:IsA("VehicleSeat") then
            seen[inst] = true
        end
    end
    return seen
end
local function nearestDriverSeat(existing, preferNew)
    local candidates = {}
    for _, inst in ipairs(workspace:GetDescendants()) do
        if inst:IsA("VehicleSeat") and inst.Parent then
            local distance = (inst.Position - CAR_SPAWNER_POSITION).Magnitude
            if distance <= CAR_SEARCH_RADIUS then
                local occupantOkay = (not inst.Occupant) or inst.Occupant == myHum()
                if occupantOkay then
                    local modelName = inst.Parent and inst.Parent.Name:lower() or ""
                    local policeBonus = (modelName:find("police", 1, true) or modelName:find("car", 1, true)) and -20 or 0
                    local newBonus = (existing and not existing[inst]) and -80 or 0
                    if preferNew and existing and existing[inst] then
                        newBonus = newBonus + 50
                    end
                    table.insert(candidates, {
                        seat = inst,
                        score = distance + policeBonus + newBonus,
                    })
                end
            end
        end
    end
    table.sort(candidates, function(a, b)
        return a.score < b.score
    end)
    return candidates[1] and candidates[1].seat or nil
end
local function waitForDriverSeat(existing, timeout)
    local deadline = os.clock() + (timeout or 6)
    repeat
        local seat = nearestDriverSeat(existing, true)
        if seat and (not existing[seat] or os.clock() > deadline - 3) then
            return seat
        end
        task.wait(0.1)
    until os.clock() >= deadline
    return nearestDriverSeat(existing, false)
end
local function seatAsDriver(seat)
    if not seat or not seat:IsA("VehicleSeat") or not seat.Parent then
        return false
    end
    local hum = myHum()
    local root = myRoot()
    if not hum or not root then return false end
    hum:SetStateEnabled(Enum.HumanoidStateType.Seated, true)
    hum.Sit = false
    root.CFrame = seat.CFrame * CFrame.new(0, 2.65, 0)
    root.AssemblyLinearVelocity = Vector3.zero
    root.AssemblyAngularVelocity = Vector3.zero
    task.wait(0.12)
    pcall(function()
        seat:Sit(hum)
    end)
    local deadline = os.clock() + 2.2
    repeat
        if seat.Occupant == hum and hum.SeatPart == seat then
            return true
        end
        pcall(function()
            seat:Sit(hum)
        end)
        task.wait(0.05)
    until os.clock() >= deadline
    return seat.Occupant == hum and hum.SeatPart == seat
end
local function jumpOutOfVehicle()
    local hum = myHum()
    local root = myRoot()
    if not hum then return end
    hum.Sit = false
    hum.Jump = true
    pcall(function()
        hum:ChangeState(Enum.HumanoidStateType.Jumping)
    end)
    if root then
        root.AssemblyLinearVelocity = Vector3.new(0, 12, 0)
    end
    task.wait(CAR_SEAT_RETRY_DELAY)
end
local function holdForward(seat, duration)
    if not seat or not seat.Parent then return false, 0, 0 end
    duration = duration or CAR_MOVE_TEST_TIME
    local startPos = seat.Position
    if VirtualInputManager then
        pcall(function()
            VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.W, false, game)
        end)
    end
    pcall(function()
        VirtualUser:CaptureController()
        VirtualUser:SetKeyDown("w")
    end)
    pcall(function() seat.ThrottleFloat = 1 end)
    pcall(function() seat.Throttle = 1 end)
    task.wait(duration)
    local moved = seat.Parent and (seat.Position - startPos).Magnitude or 0
    local speed = seat.Parent and seat.AssemblyLinearVelocity.Magnitude or 0
    if VirtualInputManager then
        pcall(function()
            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.W, false, game)
        end)
    end
    pcall(function()
        VirtualUser:SetKeyUp("w")
    end)
    pcall(function() seat.ThrottleFloat = 0 end)
    pcall(function() seat.Throttle = 0 end)
    return (moved >= CAR_MOVE_THRESHOLD or speed >= 2), moved, speed
end
local function waitForNewCar(existing, timeout)
    local newSeat = nil
    local connection
    connection = workspace.DescendantAdded:Connect(function(inst)
        if newSeat then return end
        if inst:IsA("VehicleSeat") then
            task.defer(function()
                if inst.Parent
                    and (inst.Position - CAR_SPAWNER_POSITION).Magnitude <= CAR_SEARCH_RADIUS
                    and (not existing or not existing[inst])
                then
                    newSeat = inst
                end
            end)
        end
    end)
    local deadline = os.clock() + (timeout or 6)
    repeat
        if newSeat and newSeat.Parent then
            connection:Disconnect()
            return newSeat
        end
        local seat = nearestDriverSeat(existing, true)
        if seat and (not existing or not existing[seat]) then
            connection:Disconnect()
            return seat
        end
        task.wait(0.08)
    until os.clock() >= deadline
    connection:Disconnect()
    return nil
end
local function spawnPoliceCar(existing)
    local candidates = findCarSpawnerCandidates()
    if #candidates == 0 then
        return nil, "no spawn pad/control found near supplied coordinates"
    end
    print("[JARVIS] car spawner candidates:", #candidates)
    for i = 1, math.min(#candidates, 12) do
        local item = candidates[i]
        local obj = item.object
        local pos = partPositionForInteraction(obj)
        local root = myRoot()
        if root and pos then
            local approach = pos + Vector3.new(0, 2.5, 0)
            root.CFrame = CFrame.new(approach, Vector3.new(pos.X, approach.Y, pos.Z))
            root.AssemblyLinearVelocity = Vector3.zero
            root.AssemblyAngularVelocity = Vector3.zero
            task.wait(0.10)
        end
        print(
            "[JARVIS] trying spawner",
            i,
            item.kind,
            obj:GetFullName(),
            string.format("%.2f", item.distance)
        )
        activateSpawnerCandidate(item)
        local seat = waitForNewCar(existing, 2.0)
        if seat then
            print("[JARVIS] NEW driver seat:", seat:GetFullName())
            return seat
        end
    end
    local delayedSeat = waitForDriverSeat(existing, 3.5)
    if delayedSeat and (not existing or not existing[delayedSeat]) then
        return delayedSeat
    end
    return nil, "spawn interaction completed but no NEW VehicleSeat appeared"
end
local function findCarSpawnRemote()
    local direct = ReplicatedStorage:FindFirstChild(CAR_SPAWN_REMOTE_NAME, true)
    if direct and direct:IsA("RemoteEvent") then
        return direct
    end
    return nil
end
local forceAntiFlingOn
local restoreOwnCam
local setFly
function jarvisDisableEverythingForCarFling()
    frozen = false
    freezeCFrame = nil
    hiddenLock = false
    protecting = false
    protectedPlayer = nil
    orbiting = false
    dancing = false
    guardMode = false
    punchOn = false
    spinning = false
    patrolOrigin = nil
    scoutOrigin = nil
    scoutReturning = false
    invisFollow = false
    invisPosition = nil
    groundLock = false
    targetPlayer = nil
    followCamPlayer = nil
    mode = "idle"
    if stopJarvisIPA then
        stopJarvisIPA()
    else
        JARVIS_IPA_ACTIVE = false
        JARVIS_IPA_TARGET = nil
    end
    JARVIS_PUNCHAURA_ACTIVE = false
    JARVIS_PUNCHAURA_TARGET = nil
    if clearJarvisPriorityTarget then
        clearJarvisPriorityTarget()
    else
        JARVIS_PRIORITY_TARGET_ACTIVE = false
        JARVIS_PRIORITY_TARGET = nil
    end
    if disconnectProtectDamageWatcher then
        disconnectProtectDamageWatcher()
    end
    if disconnectProtection then
        disconnectProtection()
    end
    if stopMove then
        stopMove()
    end
    restoreOwnCam()
    setNoSit(false)
    setFly(false)
    if setNoclipAdmin then
        setNoclipAdmin(false)
    else
        noclipOn = false
        if Noclipping then
            pcall(function()
                Noclipping:Disconnect()
            end)
            Noclipping = nil
        end
    end
    local r = myRoot()
    if r then
        r.Anchored = false
        r.AssemblyLinearVelocity = Vector3.zero
        r.AssemblyAngularVelocity = Vector3.zero
    end
end
-- Persistent car fling replacement.
-- 'fling <player>  = car fling regardless of target health.
-- 'dfling <player> = same routine, but only while the target is dead.
-- 'unfling         = stop immediately and clean up.
JARVIS_CAR_FLING_TOKEN = 0
JARVIS_CAR_FLING_CONN = nil
JARVIS_CAR_FLING_SEAT = nil
JARVIS_CAR_FLING_TARGET = nil
JARVIS_CAR_FLING_RETURN_CF = nil
JARVIS_CAR_FLING_ACTIVE = false
JARVIS_CAR_FLING_DEAD_ONLY = false

function stopJarvisPersistentCarFling(reason)
    JARVIS_CAR_FLING_TOKEN += 1
    JARVIS_CAR_FLING_ACTIVE = false
    carFlingBusy = false
    vehicleRoutineActive = false
    if JARVIS_CAR_FLING_CONN then
        pcall(function() JARVIS_CAR_FLING_CONN:Disconnect() end)
        JARVIS_CAR_FLING_CONN = nil
    end
    local seat = JARVIS_CAR_FLING_SEAT
    if seat and seat.Parent then
        pcall(function()
            seat.AssemblyLinearVelocity = Vector3.zero
            seat.AssemblyAngularVelocity = Vector3.zero
        end)
    end
    pcall(function() sethiddenproperty(seat, "PhysicsRepRootPart", nil) end)
    JARVIS_CAR_FLING_SEAT = nil
    JARVIS_CAR_FLING_TARGET = nil
    forceAntiFlingOn()
    JARVIS_CAR_FLING_RETURN_CF = nil
    mode = "idle"
    if reason == "manual" then voice("car fling stopped.") end
end

function runJarvisPersistentCarFling(targetText, deadOnly)
    targetText = tostring(targetText or ""):gsub("^%s+", ""):gsub("%s+$", "")
    local target = findPlayer(targetText)
    if not target or target == bot then
        voice("fling target not found.")
        return
    end

    stopJarvisPersistentCarFling("replace")
    JARVIS_CAR_FLING_TOKEN += 1
    local token = JARVIS_CAR_FLING_TOKEN
    JARVIS_CAR_FLING_ACTIVE = true
    JARVIS_CAR_FLING_DEAD_ONLY = deadOnly == true
    JARVIS_CAR_FLING_TARGET = target
    carFlingBusy = true
    vehicleRoutineActive = true

    -- IMPORTANT: JARVIS itself performs no positioning, following, seating,
    -- oscillation, or target movement here. It only runs the existing .tp cop
    -- command once, then enables the supplied owned-car fling routine.
    otherCmd("tp cop")
    task.wait(0.35)

    local function cancelled()
        return token ~= JARVIS_CAR_FLING_TOKEN
            or not JARVIS_CAR_FLING_ACTIVE
            or not target.Parent
    end

    JARVIS_CAR_FLING_CONN = RunService.Heartbeat:Connect(function()
        if cancelled() then
            stopJarvisPersistentCarFling(target.Parent and "cancelled" or "left")
            return
        end

        local char = target.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if JARVIS_CAR_FLING_DEAD_ONLY and (not hum or hum.Health > 0) then
            return
        end

        local part = char and (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Head"))
        if not part or not part:IsA("BasePart") then return end

        -- Same nearby-spawner activation used by the supplied fling script.
        -- This does NOT move the local character to the spawner.
        local root = myRoot()
        local buttons = workspace:FindFirstChild("Prison_ITEMS")
        buttons = buttons and buttons:FindFirstChild("buttons")
        local remotes = ReplicatedStorage:FindFirstChild("Remotes")
        local interact = remotes and remotes:FindFirstChild("InteractWithItem")
        if root and buttons and interact then
            for _, button in ipairs(buttons:GetChildren()) do
                if button.Name == "Car Spawner" then
                    local pad = button:FindFirstChild("Car Spawner")
                    if pad and (pad.Position - root.Position).Magnitude < 20 then
                        pcall(function() interact:InvokeServer(pad) end)
                    end
                end
            end
        end

        -- Activate the supplied fling behavior on any car seat this client owns.
        -- No Humanoid.Sit, Seat:Sit(), character CFrame, PivotTo, or extra movement.
        local box = workspace:FindFirstChild("CarContainer")
        if not box then return end
        for _, seat in ipairs(box:GetDescendants()) do
            if seat:IsA("VehicleSeat") then
                local owned = false
                pcall(function() owned = isnetworkowner(seat) end)
                if owned then
                    JARVIS_CAR_FLING_SEAT = seat
                    pcall(function()
                        seat.AssemblyLinearVelocity = Vector3.new(19999, 19999, 0)
                        seat.AssemblyAngularVelocity = Vector3.new(19999, 19999, 19999)
                        seat.CFrame = CFrame.new(part.Position) * CFrame.new(-2, -2, -12)
                        sethiddenproperty(seat, "PhysicsRepRootPart", part)
                        local wheels = seat.Parent and seat.Parent.Parent and seat.Parent.Parent:FindFirstChild("Wheels")
                        if wheels then wheels:Destroy() end
                    end)
                end
            end
        end
    end)

    voice((deadOnly and "dead car fling " or "car fling ") .. target.Name)
end

local function runRemoteCarFling(targetText)
    targetText = tostring(targetText or ""):gsub("^%s+", ""):gsub("%s+$", "")
    if targetText == "" then
        voice("fling target required.")
        return
    end
    jarvisDisableEverythingForCarFling()
    vehicleRoutineActive = true
    local Players = game:GetService("Players")
    local Workspace = game:GetService("Workspace")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local LocalPlayer = Players.LocalPlayer
    local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local humanoid = character:WaitForChild("Humanoid")
    local root = character:WaitForChild("HumanoidRootPart")
    local spawner = nil
    local buttons = Workspace:FindFirstChild("Prison_ITEMS") and Workspace.Prison_ITEMS:FindFirstChild("buttons")
    if buttons then
        for _, b in ipairs(buttons:GetChildren()) do
            local p = b:FindFirstChild("Car Spawner")
            local t = p and p:FindFirstChild("type")
            if p and p:IsA("BasePart") and t and t:IsA("StringValue") and t.Value == "Squad" then
                spawner = p
                break
            end
        end
    end
    if spawner then
        character:PivotTo(spawner.CFrame + Vector3.new(0, 2.5, 0))
        task.wait(0.15)
        local interact = ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("InteractWithItem")
        if interact and interact:IsA("RemoteFunction") then
            pcall(function()
                interact:InvokeServer(spawner)
            end)
        end
        task.wait(0.25)
        local car = nil
        local seat = nil
        local container = Workspace:FindFirstChild("CarContainer")
        local spawnDeadline = os.clock() + 4.0
        repeat
            if container then
                for _, c in ipairs(container:GetChildren()) do
                    if c:IsA("Model") then
                        local s = c:FindFirstChild("VehicleSeat", true)
                        if s and s:IsA("VehicleSeat") and (s.Position - spawner.Position).Magnitude <= 35 then
                            car = c
                            seat = s
                            break
                        end
                    end
                end
            end
            if not car then
                task.wait(0.05)
            end
        until car ~= nil or os.clock() >= spawnDeadline
        if car and seat then
            humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, true)
            seat.Disabled = false
            seat.CanTouch = true
            character:PivotTo(seat.CFrame + Vector3.new(0, 1.5, 0))
            seat:Sit(humanoid)
            local boardDeadline = os.clock() + 3.0
            repeat
                if humanoid.SeatPart ~= seat then
                    character:PivotTo(seat.CFrame + Vector3.new(0, 1.5, 0))
                    seat:Sit(humanoid)
                end
                task.wait(0.05)
            until humanoid.SeatPart == seat or os.clock() >= boardDeadline
        end
    end
    task.wait(1.5)
    otherCmd("fling " .. targetText)
    vehicleRoutineActive = false
    mode = "idle"
    setFly(false)
    setNoSit(false)
    setNoclipAdmin(false)
end
forceAntiFlingOn = function()
    pcall(function()
        otherCmd("antifling on")
    end)
end
-- Legacy runCarFling removed; persistent car-fling commands are used instead.
restoreOwnCam = function()
    camLocked = false
    camera.CameraType =
        Enum.CameraType.Custom
    local h = myHum()
    if h then
        camera.CameraSubject = h
    end
end
local function lockCam(plr)
    if IS_LEADER then
        return
    end
    camLocked = true
    if plr then
        targetPlayer = plr
        followCamPlayer = plr
    end
end
setFly = function(on)
    if IS_LEADER then
        return
    end
    flying = on
    local hum = myHum()
    local root = myRoot()
    if hum then
        hum.PlatformStand = on
        hum.AutoRotate = not on
    end
    if root then
        root.Anchored = false
        if not on then
            local hover = root:FindFirstChild("JARVIS_FlightHover")
            if hover then hover:Destroy() end
        end
        root.AssemblyLinearVelocity =
            Vector3.zero
    end
end
local function setTrueIdleAnchor()
    if IS_LEADER then
        return
    end
    flying = false
    local hum = myHum()
    local root = myRoot()
    if root then
        local hover = root:FindFirstChild("JARVIS_FlightHover")
        if hover then hover:Destroy() end
    end
    if hum then
        hum.PlatformStand = false
        hum.AutoRotate = true
    end
    if root then
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
        root.Anchored = true
    end
end
local function releaseTrueIdleAnchor()
    local root = myRoot()
    if root and root.Anchored then
        root.Anchored = false
    end
end
-- Smooth hover: keep gravity from pulling a bot down between movement frames.
local function ensureJarvisFlightHover(part)
    if not part then return end
    local hover = part:FindFirstChild("JARVIS_FlightHover")
    if not hover then
        hover = Instance.new("BodyVelocity")
        hover.Name = "JARVIS_FlightHover"
        hover.P = 1800
        hover.Parent = part
    end
    hover.MaxForce = Vector3.new(0, math.max(100000, part.AssemblyMass * workspace.Gravity * 8), 0)
    hover.Velocity = Vector3.zero
end

local stableFollowY, pendingFollowY, pendingFollowAt, lastFollowTarget
local function steadyFollowAltitude(target, rawY)
    if target ~= lastFollowTarget or stableFollowY == nil then
        lastFollowTarget, stableFollowY = target, rawY
        pendingFollowY, pendingFollowAt = nil, 0
        return rawY
    end
    -- Ignore short jumps and animation-driven root height oscillations.
    if math.abs(rawY - stableFollowY) < 1.4 then
        pendingFollowY, pendingFollowAt = nil, 0
    elseif pendingFollowY == nil or math.abs(rawY - pendingFollowY) > 1.2 then
        pendingFollowY, pendingFollowAt = rawY, os.clock()
    elseif os.clock() - pendingFollowAt > 0.38 then
        stableFollowY = rawY
        pendingFollowY, pendingFollowAt = nil, 0
    end
    return stableFollowY
end

local function flyStep(
    part,
    goal,
    dt,
    preserveGoalY
)
    local hum = myHum()
    if hum then
        hum.PlatformStand = true
    end
    if not part or not goal then
        return true
    end
    ensureJarvisFlightHover(part)
    part.AssemblyLinearVelocity =
        Vector3.zero
    if not preserveGoalY then
        goal = flatten(goal)
    end
    local delta =
        goal - part.Position
    if delta.Magnitude < 0.35 then
        return true
    end
    local step = math.min(
        flySpeed * dt,
        delta.Magnitude
    )
    local pos =
        part.Position
        + delta.Unit * step
    if not preserveGoalY then
        pos = flatten(pos)
    end
    pos = getgenv().JARVIS_SQUAD.avoid(pos, dt)
    local lookRoot = camRoot()
    local lookDirection
    if lookRoot then
        lookDirection =
            lookRoot.CFrame.LookVector
    else
        lookDirection =
            part.CFrame.LookVector
    end
    if spinning then
        local rotationOnly = part.CFrame - part.Position
        part.CFrame = CFrame.new(pos) * rotationOnly
    else
        part.CFrame =
            CFrame.lookAt(
                pos,
                pos + Vector3.new(
                    lookDirection.X,
                    0,
                    lookDirection.Z
                )
            )
    end
    return false
end
local function getUnitIndex()
    return getgenv().JARVIS_SQUAD.index()
end
function getFormationPosition(masterRoot, requestedFormation)
    if not masterRoot then return nil end
    local index, count = getUnitIndex()
    local squad = getgenv().JARVIS_SQUAD
    local gap = squad.gap()
    local formation = requestedFormation or formationType
    local back = math.max(FORMATION_BACK, followDistance)
    local x, z = 0, back
    if formation == "singlefile" then
        local spacing = math.max(3.5, gap)
        x = 0
        z = math.max(3.5, back) + (index - 1) * spacing
    elseif formation == "circle" then
        local angle, radius = squad.ring(10, 0)
        return masterRoot.Position + Vector3.new(math.cos(angle) * radius, 0, math.sin(angle) * radius)
    elseif formation == "wall" then
        x = (index - (count + 1) / 2) * gap
    elseif formation == "diamond" then
        local ring = math.floor((index - 1) / 4) + 1
        local arm = (index - 1) % 4
        local radius = math.max(back, gap) * ring
        if arm == 0 then x, z = 0, radius
        elseif arm == 1 then x, z = -radius, 0
        elseif arm == 2 then x, z = radius, 0
        else x, z = 0, -radius end
    elseif formation == "v" then
        if index > 1 then
            local row = math.ceil((index - 1) / 2)
            x = row * gap * (index % 2 == 0 and -1 or 1)
            z = back + row * gap
        end
    elseif formation == "dynamic" and count <= 3 then
        if count == 2 then x = (index == 1 and -0.5 or 0.5) * gap
        elseif count == 3 and index > 1 then
            x = (index == 2 and -1 or 1) * gap
            z = back + gap
        end
    else
        -- Columns (and larger dynamic groups): every row has its own depth.
        x = ((index - 1) % 2 == 0 and -0.5 or 0.5) * gap
        z = back + math.floor((index - 1) / 2) * gap
    end
    local right = masterRoot.CFrame.RightVector
    right = Vector3.new(right.X, 0, right.Z)
    if right.Magnitude < 0.001 then right = Vector3.new(1, 0, 0) end
    right = right.Unit
    return masterRoot.Position + right * x + Vector3.new(-right.Z, 0, right.X) * z
end
JARVIS_INVIS_FLOOR = JARVIS_INVIS_FLOOR or {
    target = nil,
    lockedY = nil,
    pendingY = nil,
    pendingAt = 0,
}
function resetInvisibleFloorLatch(player)
    local targetRoot = rootOf(player)
    JARVIS_INVIS_FLOOR.target = player
    JARVIS_INVIS_FLOOR.pendingY = nil
    JARVIS_INVIS_FLOOR.pendingAt = 0
    JARVIS_INVIS_FLOOR.lockedY = targetRoot and targetRoot.Position.Y or nil
end
function getLatchedInvisibleTargetY(player)
    local targetRoot = rootOf(player)
    if not targetRoot then
        return nil
    end
    local state = JARVIS_INVIS_FLOOR
    if state.target ~= player or state.lockedY == nil then
        resetInvisibleFloorLatch(player)
    end
    local hum = humOf(player)
    if not hum then
        return state.lockedY or targetRoot.Position.Y
    end
    local humState = hum:GetState()
    local grounded =
        hum.FloorMaterial ~= Enum.Material.Air
        and humState ~= Enum.HumanoidStateType.Jumping
        and humState ~= Enum.HumanoidStateType.Freefall
        and humState ~= Enum.HumanoidStateType.FallingDown
    if grounded then
        local currentY = targetRoot.Position.Y
        local lockedY = state.lockedY or currentY
        if math.abs(currentY - lockedY) >= 2.25 then
            if state.pendingY == nil or math.abs(currentY - state.pendingY) > 0.75 then
                state.pendingY = currentY
                state.pendingAt = os.clock()
            elseif os.clock() - state.pendingAt >= 0.22 then
                state.lockedY = currentY
                state.pendingY = nil
                state.pendingAt = 0
            end
        else
            state.pendingY = nil
            state.pendingAt = 0
        end
    else
        state.pendingY = nil
        state.pendingAt = 0
    end
    return state.lockedY or targetRoot.Position.Y
end
function ensureCloakYHold(part)
    if not part or not part.Parent then
        return
    end
    local mover = part:FindFirstChild(JARVIS_CLOAK_Y_HOLD_NAME)
    if not mover then
        mover = Instance.new("BodyVelocity")
        mover.Name = JARVIS_CLOAK_Y_HOLD_NAME
        mover.P = 30000
        mover.MaxForce = Vector3.new(0, math.huge, 0)
        mover.Velocity = Vector3.zero
        mover.Parent = part
    else
        mover.MaxForce = Vector3.new(0, math.huge, 0)
        mover.Velocity = Vector3.zero
    end
end
function removeCloakYHold()
    local root = myRoot()
    if not root then
        return
    end
    local mover = root:FindFirstChild(JARVIS_CLOAK_Y_HOLD_NAME)
    if mover then
        mover:Destroy()
    end
end
function releaseSoftFollow(seconds)
    JARVIS_FOLLOW_RELEASE_UNTIL = math.max(
        JARVIS_FOLLOW_RELEASE_UNTIL or 0,
        os.clock() + (tonumber(seconds) or JARVIS_FOLLOW_ADMIN_RELEASE or 1.35)
    )
end
function captureIdleHold()
    local root = myRoot()
    if root then
        JARVIS_IDLE_HOLD_CFRAME = root.CFrame
    end
end
function softFollowStep(part, goal, dt)
    if jarvisKillBusy() then return false end
    if not part or not goal then
        return true
    end
    if os.clock() < (JARVIS_FOLLOW_RELEASE_UNTIL or 0) then
        return false
    end
    local delta = goal - part.Position
    local distance = delta.Magnitude
    local deadzone = JARVIS_FOLLOW_DEADZONE or 1.6
    if distance <= deadzone then
        part.AssemblyLinearVelocity = Vector3.zero
        return true
    end
    local allowed = math.max(0, distance - deadzone)
    local step = math.min((JARVIS_FOLLOW_SPEED or 18) * dt, allowed)
    if distance > 0 and step > 0 then
        local pos = getgenv().JARVIS_SQUAD.avoid(part.Position + delta.Unit * step, dt)
        local targetRoot = camRoot()
        local look = targetRoot and targetRoot.CFrame.LookVector or part.CFrame.LookVector
        local flatLook = Vector3.new(look.X, 0, look.Z)
        if flatLook.Magnitude < 0.001 then
            flatLook = Vector3.new(0, 0, -1)
        else
            flatLook = flatLook.Unit
        end
        part.AssemblyLinearVelocity = Vector3.zero
        part.CFrame = CFrame.lookAt(pos, pos + flatLook)
    end
    return false
end
function releaseSoftCloak(seconds)
    if not invisFollow then
        return
    end
    JARVIS_CLOAK_RELEASE_UNTIL = math.max(
        JARVIS_CLOAK_RELEASE_UNTIL or 0,
        os.clock() + (tonumber(seconds) or JARVIS_CLOAK_ADMIN_RELEASE)
    )
end
function softCloakStep(part, goal, dt)
    if jarvisKillBusy() then return false end
    if not part or not goal then
        return true
    end
    ensureCloakYHold(part)
    if os.clock() < (JARVIS_CLOAK_RELEASE_UNTIL or 0) then
        return false
    end
    local current = part.Position
    local dx = goal.X - current.X
    local dz = goal.Z - current.Z
    local horizontalDistance = math.sqrt(dx * dx + dz * dz)
    local newX = current.X
    local newZ = current.Z
    if horizontalDistance > (JARVIS_CLOAK_DEADZONE or 1.35) then
        local maxHorizontalStep = (JARVIS_CLOAK_SPEED or 22) * dt
        local desiredStep = math.max(
            0,
            horizontalDistance - (JARVIS_CLOAK_DEADZONE or 1.35)
        )
        local horizontalStep = math.min(maxHorizontalStep, desiredStep)
        if horizontalDistance > 0 then
            newX = current.X + (dx / horizontalDistance) * horizontalStep
            newZ = current.Z + (dz / horizontalDistance) * horizontalStep
        end
    end
    local yDelta = goal.Y - current.Y
    local maxYStep = 70 * dt
    local newY = current.Y
    if math.abs(yDelta) > 0.08 then
        newY = current.Y + math.clamp(yDelta, -maxYStep, maxYStep)
    else
        newY = goal.Y
    end
    if math.abs(newX - current.X) < 0.001
        and math.abs(newY - current.Y) < 0.001
        and math.abs(newZ - current.Z) < 0.001
    then
        return true
    end
    local look = part.CFrame.LookVector
    local flatLook = Vector3.new(look.X, 0, look.Z)
    if flatLook.Magnitude < 0.001 then
        flatLook = Vector3.new(0, 0, -1)
    else
        flatLook = flatLook.Unit
    end
    local newPos = getgenv().JARVIS_SQUAD.avoid(Vector3.new(newX, newY, newZ), dt)
    part.CFrame = CFrame.lookAt(newPos, newPos + flatLook)
    return false
end
function getInvisibleGoal(player)
    local targetRoot = rootOf(player)
    if not targetRoot then return nil end
    local latchedY = getLatchedInvisibleTargetY(player)
    if not latchedY then return nil end
    return getgenv().JARVIS_SQUAD.offset(Vector3.new(targetRoot.Position.X,
        latchedY - cloakDepth, targetRoot.Position.Z), targetRoot.CFrame)
end
function followGoal()
    local target = activeTarget()
    local targetRoot = rootOf(target)
    if not targetRoot then return nil end

    if invisFollow then
        local latchedY = getLatchedInvisibleTargetY(target)
        if not latchedY then return nil end
        return getgenv().JARVIS_SQUAD.offset(Vector3.new(
            targetRoot.Position.X, latchedY - cloakDepth, targetRoot.Position.Z
        ), targetRoot.CFrame)
    end

    local squad = getgenv().JARVIS_SQUAD
    local index = 1
    if squad and squad.index then
        index = tonumber((squad.index())) or 1
    end

    -- FOLLOW = single-file column directly behind the target.
    -- Bot 1 closest, then Bot 2, then Bot 3.
    local spacing = math.max(3.5, (squad and squad.gap and squad.gap()) or 6)
    local firstDistance = math.max(3.5, followDistance)
    local distanceBehind = firstDistance + (index - 1) * spacing

    local goal =
        targetRoot.Position
        - targetRoot.CFrame.LookVector * distanceBehind

    return Vector3.new(
        goal.X,
        steadyFollowAltitude(target, targetRoot.Position.Y) + followVerticalOffset,
        goal.Z
    )
end
function protectGoal(dt)
    if jarvisKillBusy() then return nil end
    local target = protectedPlayer or activeTarget() or getMaster()
    local targetRoot = rootOf(target)
    if not targetRoot then
        return nil
    end
    return getgenv().JARVIS_SQUAD.offset(targetRoot.Position, targetRoot.CFrame)
end
function orbitGoal()
    if jarvisKillBusy() then return nil end
    local target =
        orbitTarget
        or getMaster()
    local targetRoot =
        rootOf(target)
    if not targetRoot then
        return nil
    end
    local angle, radius = getgenv().JARVIS_SQUAD.ring(
        cheaterActive and 8 or orbitRadius,
        cheaterActive and 1 or 1.5
    )
    orbitAngle = angle
    local y = targetRoot.Position.Y
    if dancing then
        y =
            y
            + math.sin(
                danceTime * 4
            ) * 2
    end
    if invisFollow then
        local latchedY = getLatchedInvisibleTargetY(target)
        y = (latchedY or targetRoot.Position.Y) - cloakDepth
    end
    return Vector3.new(
        targetRoot.Position.X
            + math.cos(angle)
                * radius,
        y,
        targetRoot.Position.Z
            + math.sin(angle)
                * radius
    )
end
function guardGoal()
    if jarvisKillBusy() then return nil end
    local guardTarget = activeTarget() or getMaster()
    local masterRoot =
        rootOf(guardTarget)
    if not masterRoot then
        return nil
    end
    local angle, radius = getgenv().JARVIS_SQUAD.ring(11, 0)
    local pos =
        masterRoot.Position
        + Vector3.new(
            math.cos(angle)
                * radius,
            0,
            math.sin(angle)
                * radius
        )
    if invisFollow then
        local latchedY = getLatchedInvisibleTargetY(guardTarget)
        pos = Vector3.new(
            pos.X,
            (latchedY or masterRoot.Position.Y) - cloakDepth,
            pos.Z
        )
    end
    return pos
end
function patrolGoal()
    if jarvisKillBusy() then return nil end
    local masterRoot =
        rootOf(getMaster())
    if not masterRoot then
        return nil
    end
    if not patrolOrigin then
        patrolOrigin =
            masterRoot.Position
    end
    local angle, radius = getgenv().JARVIS_SQUAD.ring(PATROL_RADIUS, 0.5)
    patrolAngle = angle
    return patrolOrigin + Vector3.new(math.cos(angle) * radius, 0, math.sin(angle) * radius)
end
function scoutGoal()
    local masterRoot =
        rootOf(getMaster())
    if not masterRoot then
        return nil
    end
    if not scoutOrigin then
        scoutOrigin =
            masterRoot.Position
    end
    local forward =
        masterRoot.CFrame.LookVector
    local goal = masterRoot.Position
    if not scoutReturning then goal = goal + forward * SCOUT_DISTANCE end
    return getgenv().JARVIS_SQUAD.offset(goal, masterRoot.CFrame)
end
function stopMove()
    mode = "idle"
    captureIdleHold()
    protecting = false
    orbiting = false
    dancing = false
    guardMode = false
    lastRevenge = {}
    patrolOrigin = nil
    scoutOrigin = nil
    scoutReturning = false
    targetPlayer = nil
    followCamPlayer = nil
end
function returnToMaster()
    protecting = false
    orbiting = false
    dancing = false
    guardMode = false
    targetPlayer = getMaster()
    followCamPlayer = getMaster()
    mode = "follow"
    JARVIS_IDLE_HOLD_CFRAME = nil
    setFly(true)
    lockCam(getMaster())
end
function lockOnPlayer(p)
    if IS_LEADER or not p then
        return
    end
    protecting = false
    targetPlayer = p
    followCamPlayer = p
    mode = "loopfollow"
    JARVIS_IDLE_HOLD_CFRAME = nil
    setFly(true)
    lockCam(p)
end
function updateStuckRecovery(root, dt)
    if not root then
        return
    end
    if not lastPosition then
        lastPosition =
            root.Position
        stuckTimer = 0
        return
    end
    local moved =
        (
            root.Position
            - lastPosition
        ).Magnitude
    lastPosition =
        root.Position
    if moved < STUCK_DISTANCE
        and (
            mode ~= "idle"
            or protecting
            or orbiting
            or dancing
        )
    then
        stuckTimer =
            stuckTimer + dt
    else
        stuckTimer = 0
    end
    if stuckTimer >= STUCK_TIME then
        stuckTimer = 0
        setFly(true)
        if mode == "follow"
            or mode == "loopfollow"
        then
            local target = activeTarget()
            if target and rootOf(target) then
                targetPlayer = target
            end
        end
        print(
            "[JARVIS] movement recovery"
        )
    end
end
JARVIS_SIMPLE_COMMAND_PAGES = {
    "CMDS 1/4 | follow stop fly noclip invis vis target nearest view unview spin bounce dance",
    "CMDS 2/4 | fprotect halfprotect lprotect unprotect sb ap pa unpa kill combo1 combo2 combo3",
    "CMDS 3/4 | orbit guard patrol surround assemble regroup mark recall freeze recover reset rejoin",
    "CMDS 4/4 | share share1 share2 unshare wl unwl bots slots status settings shut unshut cmd cmds",
}
JARVIS_SIMPLE_CMD_PAGE_DELAY = 3.00
function dumpPage(_)
    announceCmds()
end
function getJarvisWhisperChannel(target)
    if not target or not target:IsA("Player") then
        return nil
    end
    local channels = TextChatService:FindFirstChild("TextChannels")
    if not channels then
        return nil
    end
    local id1 = tostring(bot.UserId)
    local id2 = tostring(target.UserId)
    local direct =
        channels:FindFirstChild("RBXWhisper:" .. id1 .. "_" .. id2)
        or channels:FindFirstChild("RBXWhisper:" .. id2 .. "_" .. id1)
    if direct and direct:IsA("TextChannel") then
        return direct
    end
    for _, channel in ipairs(channels:GetChildren()) do
        if channel:IsA("TextChannel") then
            local name = channel.Name
            if name:find("RBXWhisper:", 1, true)
                and name:find(id1, 1, true)
                and name:find(id2, 1, true)
            then
                return channel
            end
        end
    end
    return nil
end
function announceCmds(targetPlayer)
    -- 'cmds is PRIVATE ONLY. Never fall back to public voice/general chat.
    local epoch = getgenv().JARVIS_CHAT_EPOCH
    local function cancelled()
        return epoch ~= getgenv().JARVIS_CHAT_EPOCH
    end

    task.spawn(function()
        if cancelled() then return end

        local target = targetPlayer
        if typeof(target) ~= "Instance" or not target:IsA("Player") then
            target = getMaster()
        end
        if not target then return end

        local whisper = getJarvisWhisperChannel(target)

        -- Open/create the Roblox whisper channel privately if needed.
        if not whisper then
            local channels = TextChatService:FindFirstChild("TextChannels")
            local general = channels and (
                channels:FindFirstChild("RBXGeneral")
                or channels:FindFirstChild("General")
            )
            if general and general:IsA("TextChannel") and not cancelled() then
                pcall(function()
                    -- This is Roblox's whisper command; it opens the private
                    -- channel instead of publishing the command pages publicly.
                    general:SendAsync("/w @" .. target.Name .. " .")
                end)
            end

            local deadline = os.clock() + 5
            repeat
                task.wait(0.10)
                if cancelled() then return end
                whisper = getJarvisWhisperChannel(target)
            until whisper or os.clock() >= deadline
        end

        -- No public fallback under any circumstance.
        if not whisper then
            return
        end

        local myIndex, botCount = 1, 1
        if getgenv().JARVIS_SQUAD and getgenv().JARVIS_SQUAD.index then
            myIndex, botCount = getgenv().JARVIS_SQUAD.index()
            myIndex = tonumber(myIndex) or 1
            botCount = math.max(1, tonumber(botCount) or 1)
        end

        for pageIndex, line in ipairs(JARVIS_SIMPLE_COMMAND_PAGES) do
            if cancelled() then return end
            if ((pageIndex - 1) % botCount) + 1 == myIndex then
                pcall(function()
                    if not cancelled() then
                        whisper:SendAsync(line)
                    end
                end)
                task.wait(JARVIS_SIMPLE_CMD_PAGE_DELAY or 3)
            end
        end
    end)
end
-- HOST COMMAND BAR
-- Press apostrophe (') to open it.
-- This intentionally does NOT use Roblox whisper/private-message channels.
-- `sendJarvisRemoteCommand` is the transport hook for the user's external EXE.

JARVIS_PROTECT_MODE = JARVIS_PROTECT_MODE or "half"
JARVIS_FULLPROTECT_SCAN_RANGE = 250
JARVIS_FULLPROTECT_SCAN_DELAY = 0.025
JARVIS_FULLPROTECT_LAST_SCAN = 0
JARVIS_PROTECT_RADIUS = 10
JARVIS_PROTECT_ORBIT_SPEED = 2.2
JARVIS_PROTECT_ORBIT_ANGLE = 0
JARVIS_PROTECT_ACTION_COOLDOWN = 1.0
JARVIS_PROTECT_LAST_ACTION = {}
-- In FPROTECT/IPROTECT, unarmed inmates are never automatic targets.
-- A weapon must be visibly equipped; Backpack contents alone do not count.
function JARVIS_PROTECT_CAN_TARGET(player)
    if not player then return false end
    local teamName = player.Team and player.Team.Name:lower() or ""
    if not (teamName:find("inmate", 1, true)
        or teamName:find("prisoner", 1, true)) then
        return true
    end

    local character = player.Character
    if not character then return false end
    for _, item in ipairs(character:GetChildren()) do
        if item:IsA("Tool") then
            local name = item.Name:lower()
            -- Exclude non-weapons commonly carried in Prison Life.
            if not (name:find("keycard", 1, true)
                or name:find("key card", 1, true)
                or name:find("handcuff", 1, true)
                or name:find("flashlight", 1, true)
                or name:find("food", 1, true)
                or name:find("hammer", 1, true)) then
                return true
            end
        end
    end
    return false
end

-- Shared one-second per-player throttle for FPROTECT and IPROTECT.
-- All their kill paths use this same clock, preventing duplicate sends.
function JARVIS_PROTECT_SEND_KILL(player)
    if not player or not player.Parent or not protecting then return false end
    if JARVIS_PROTECT_MODE ~= "full" and JARVIS_PROTECT_MODE ~= "invisfull" then return false end
    if player == bot or player == protectedPlayer or isAlly(player)
        or isJarvisOwnerPlayer(player)
        or (isWhitelistedPlayer and isWhitelistedPlayer(player)) then return false end
    if not JARVIS_PROTECT_CAN_TARGET(player) then return false end
    local key = player.UserId
    local now = os.clock()
    if now - (JARVIS_PROTECT_LAST_ACTION[key] or -math.huge) < 1 then return false end
    JARVIS_PROTECT_LAST_ACTION[key] = now
    otherCmd("kill " .. player.Name)
    return true
end
JARVIS_MELEE_RANGE = 12
JARVIS_PROTECT_ORBIT_RADIUS = 4.25
JARVIS_PROTECT_ORBIT_SPEED = 2.6
JARVIS_PROTECT_RESPAWN_GRACE = 4.0
JARVIS_PROTECT_RESPAWN_GRACE_UNTIL = 0
JARVIS_LAST_SAFE_CFRAME = nil
JARVIS_LAST_SAFE_UPDATE = 0
JARVIS_SAFE_UPDATE_INTERVAL = 0.15
JARVIS_FALL_RECOVERY_DROP = 42
JARVIS_FALL_EMERGENCY_Y = -45
function jarvisGroundBelow(root)
    if not root then
        return false
    end
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    local exclude = {}
    if bot.Character then
        table.insert(exclude, bot.Character)
    end
    params.FilterDescendantsInstances = exclude
    params.IgnoreWater = true
    local result = workspace:Raycast(
        root.Position,
        Vector3.new(0, -10, 0),
        params
    )
    return result ~= nil
end
function updateJarvisSafePosition(root, hum)
    if not root or not hum then
        return
    end
    if not jarvisGroundBelow(root) then
        return
    end
    local now = os.clock()
    if now - JARVIS_LAST_SAFE_UPDATE
        < JARVIS_SAFE_UPDATE_INTERVAL
    then
        return
    end
    JARVIS_LAST_SAFE_UPDATE = now
    JARVIS_LAST_SAFE_CFRAME = root.CFrame
end
function recoverJarvisFromFall(root)
    if not root then
        return false
    end
    local shouldRecover = false
    if JARVIS_LAST_SAFE_CFRAME then
        if root.Position.Y
            < JARVIS_LAST_SAFE_CFRAME.Position.Y
                - JARVIS_FALL_RECOVERY_DROP
        then
            shouldRecover = true
        end
    elseif root.Position.Y < JARVIS_FALL_EMERGENCY_Y then
        shouldRecover = true
    end
    if not shouldRecover then
        return false
    end
    root.AssemblyLinearVelocity = Vector3.zero
    root.AssemblyAngularVelocity = Vector3.zero
    if JARVIS_LAST_SAFE_CFRAME then
        root.CFrame = JARVIS_LAST_SAFE_CFRAME
    else
        root.CFrame =
            CFrame.new(
                root.Position.X,
                5,
                root.Position.Z
            )
    end
    return true
end
JARVIS_PUNCHAURA_ACTIVE = false
JARVIS_IPA_ACTIVE = false
JARVIS_IPA_TARGET = nil
JARVIS_IPA_PREDICTION = 0.18
JARVIS_IPA_DISTANCE = 3.25
function stopJarvisIPA()
    JARVIS_IPA_ACTIVE = false
    JARVIS_IPA_TARGET = nil
end
function jarvisIPAGoal(target)
    if not target then
        return nil
    end
    local tr = rootOf(target)
    if not tr then
        return nil
    end
    local velocity = tr.AssemblyLinearVelocity or Vector3.zero
    local horizontalVelocity =
        Vector3.new(velocity.X, 0, velocity.Z)
    local predicted =
        tr.Position
        + horizontalVelocity * JARVIS_IPA_PREDICTION
    local backOffset =
        -tr.CFrame.LookVector * JARVIS_IPA_DISTANCE
    return getgenv().JARVIS_SQUAD.offset(predicted + backOffset, tr.CFrame)
end
function jarvisIPAStep(root, dt)
    if jarvisKillBusy() then return nil end
    if not JARVIS_IPA_ACTIVE then
        return false
    end
    local target = JARVIS_IPA_TARGET
    if not target
        or not target.Parent
        or target == bot
    then
        stopJarvisIPA()
        return false
    end
    if isJarvisOwnerPlayer
        and isJarvisOwnerPlayer(target)
    then
        stopJarvisIPA()
        return false
    end
    local targetRoot = rootOf(target)
    local targetHum = humOf(target)
    if not targetRoot
        or not targetHum
        or targetHum.Health <= 0
    then
        releaseTrueIdleAnchor()
        if not flying then
            setFly(true)
        end
        return true
    end
    local goal = jarvisIPAGoal(target)
    if not goal then
        return true
    end
    releaseTrueIdleAnchor()
    if not flying then
        setFly(true)
    end
    flyStep(
        root,
        goal,
        dt,
        true
    )
    if (root.Position - targetRoot.Position).Magnitude
        <= (JARVIS_MELEE_RANGE or 12)
        and not isJarvisProtectedFromAura(target, nil)
    then
        local shouldSkip = false
        pcall(function()
            local myTeamName = bot.Team and bot.Team.Name or ""
            local theirTeamName = target.Team and target.Team.Name or ""
            if myTeamName:lower():find("guard", 1, true)
                and theirTeamName:lower():find("inmate", 1, true)
                and target.Character
                and not target.Character:GetAttribute("Hostile")
            then
                shouldSkip = true
            end
        end)
        if not shouldSkip then
            jarvisMeleeAttack(target)
        end
    end
    return true
end
JARVIS_PUNCHAURA_TARGET = nil
JARVIS_PUNCHAURA_PREDICT = 0.18
JARVIS_PUNCHAURA_FRONT_DISTANCE = 3.5
JARVIS_PUNCHAURA_NEARBY_WHITELIST_RADIUS = 18
JARVIS_DYNAMIC_WHITELIST = JARVIS_DYNAMIC_WHITELIST or {}
JARVIS_MELEE_LAST_HIT = JARVIS_MELEE_LAST_HIT or {}
JARVIS_MELEE_HIT_COOLDOWN = 0.10
JARVIS_PROTECT_DAMAGE_CONNECTION = nil
JARVIS_PROTECT_CHARACTER_CONNECTION = nil
JARVIS_PROTECT_LAST_HEALTH = nil
JARVIS_PROTECT_ATTACK_SCAN_RANGE = 180
JARVIS_PROTECT_ATTACK_FACING_DOT = 0.35
JARVIS_PROTECT_ATTACK_COOLDOWN = 0.3125
JARVIS_PROTECT_LAST_RETALIATE = {}
JARVIS_PRIORITY_TARGET = nil
JARVIS_PRIORITY_TARGET_ACTIVE = false
JARVIS_PRIORITY_TARGET_LAST_ACTION = 0
JARVIS_PRIORITY_TARGET_ACTION_DELAY = 0.75
JARVIS_PRIORITY_TARGET_RESPAWN_GRACE_UNTIL = 0
JARVIS_TARGET_KILL_CHECK_DELAY = 1.25
JARVIS_TARGET_KILL_PENDING = false
JARVIS_TARGET_KILL_CHECK_AT = 0
JARVIS_TARGET_KILL_START_HEALTH = nil
JARVIS_TARGET_KILL_RETRY_COOLDOWN = 1.5
JARVIS_TARGET_KILL_LAST_RETRY = 0
JARVIS_TARGET_NEARBY_DISTANCE = 7
JARVIS_TARGET_HIDE_CFRAME = CFrame.new(
    874.332336, 116.509766, 2419.012939,
    -0.883117, 0, 0.469153,
    0, 1, 0,
    -0.469153, 0, -0.883117
)
JARVIS_TARGET_PA_PREDICTION = 0.22
function jarvisPriorityTargetExempt(player)
    if not player or player == bot then
        return true
    end
    if isJarvisOwnerPlayer
        and isJarvisOwnerPlayer(player)
    then
        return true
    end
    if isWhitelistedPlayer
        and isWhitelistedPlayer(player)
    then
        return true
    end
    return false
end
function clearJarvisPriorityTarget()
    JARVIS_PRIORITY_TARGET_ACTIVE = false
    JARVIS_PRIORITY_TARGET = nil
    JARVIS_PRIORITY_TARGET_LAST_ACTION = 0
    JARVIS_TARGET_KILL_PENDING = false
    JARVIS_TARGET_KILL_CHECK_AT = 0
    JARVIS_TARGET_KILL_START_HEALTH = nil
    JARVIS_TARGET_KILL_LAST_RETRY = 0
    if JARVIS_PUNCHAURA_ACTIVE then
        JARVIS_PUNCHAURA_ACTIVE = false
        JARVIS_PUNCHAURA_TARGET = nil
    end
    local r = myRoot()
    if r and r.Anchored then
        r.Anchored = false
    end
end
function prepareJarvisPriorityTarget(player)
    if jarvisKillBusy() then return end
    frozen = false
    freezeCFrame = nil
    hiddenLock = false
    protecting = false
    protectedPlayer = nil
    orbiting = false
    dancing = false
    guardMode = false
    punchOn = false
    spinning = false
    patrolOrigin = nil
    scoutOrigin = nil
    scoutReturning = false
    invisFollow = false
    invisPosition = nil
    groundLock = false
    if stopJarvisIPA then
        stopJarvisIPA()
    else
        JARVIS_IPA_ACTIVE = false
        JARVIS_IPA_TARGET = nil
    end
    JARVIS_PUNCHAURA_ACTIVE = false
    JARVIS_PUNCHAURA_TARGET = nil
    if disconnectProtectDamageWatcher then
        disconnectProtectDamageWatcher()
    end
    if disconnectProtection then
        disconnectProtection()
    end
    targetPlayer = player
    followCamPlayer = player
    mode = "idle"
    releaseTrueIdleAnchor()
    setFly(true)
    lockCam(player)
end
function setJarvisPriorityTarget(player)
    if not player
        or player == bot
        or jarvisPriorityTargetExempt(player)
    then
        return false
    end
    prepareJarvisPriorityTarget(player)
    JARVIS_PRIORITY_TARGET = player
    JARVIS_PRIORITY_TARGET_ACTIVE = true
    JARVIS_PRIORITY_TARGET_LAST_ACTION = 0
    JARVIS_TARGET_KILL_PENDING = false
    JARVIS_TARGET_KILL_CHECK_AT = 0
    JARVIS_TARGET_KILL_START_HEALTH = nil
    JARVIS_TARGET_KILL_LAST_RETRY = 0
    return true
end
function jarvisTargetHoldAtHide(root)
    if not root or not root.Parent then
        return
    end
    root.AssemblyLinearVelocity = Vector3.zero
    root.AssemblyAngularVelocity = Vector3.zero
    root.CFrame = getgenv().JARVIS_SQUAD.frame(JARVIS_TARGET_HIDE_CFRAME)
    root.Anchored = true
end
function jarvisTargetReleaseHide(root)
    if not root or not root.Parent then
        return
    end
    root.Anchored = false
    releaseTrueIdleAnchor()
    if not flying then
        setFly(true)
    end
end
function jarvisPriorityTargetStep(root, dt)
    if not JARVIS_PRIORITY_TARGET_ACTIVE then
        return false
    end
    local target = JARVIS_PRIORITY_TARGET
    if not target
        or not target.Parent
        or jarvisPriorityTargetExempt(target)
    then
        clearJarvisPriorityTarget()
        return false
    end
    local targetHum = humOf(target)
    local targetRoot = rootOf(target)
    if not targetHum
        or targetHum.Health <= 0
        or not targetRoot
    then
        jarvisTargetHoldAtHide(root)
        return true
    end
    local myTeam = bot.Team
    local theirTeam = target.Team
    local myTeamName =
        myTeam and myTeam.Name:lower() or ""
    local theirTeamName =
        theirTeam and theirTeam.Name:lower() or ""
    local sameTeam =
        myTeam ~= nil
        and theirTeam ~= nil
        and myTeam == theirTeam
    local now = os.clock()
    if sameTeam
        and myTeamName:find("guard", 1, true)
        and theirTeamName:find("guard", 1, true)
    then
        JARVIS_PUNCHAURA_ACTIVE = false
        JARVIS_PUNCHAURA_TARGET = nil
        jarvisTargetHoldAtHide(root)
        if now - (JARVIS_PRIORITY_TARGET_LAST_ACTION or 0) >= 1.25 then
            JARVIS_PRIORITY_TARGET_LAST_ACTION = now
            otherCmd("team inmate")
        end
        return true
    end
    if sameTeam then
        jarvisTargetReleaseHide(root)
        JARVIS_PUNCHAURA_TARGET = target
        JARVIS_PUNCHAURA_ACTIVE = true
        local velocity = targetRoot.AssemblyLinearVelocity
        local horizontalVelocity = Vector3.new(
            velocity.X,
            0,
            velocity.Z
        )
        local predicted =
            targetRoot.Position
            + horizontalVelocity * (JARVIS_TARGET_PA_PREDICTION or 0.22)
        local goal = Vector3.new(
            predicted.X,
            targetRoot.Position.Y,
            predicted.Z
        )
        goal = getgenv().JARVIS_SQUAD.offset(goal, targetRoot.CFrame)
        flyStep(root, goal, dt, true)
        if (root.Position - targetRoot.Position).Magnitude
            <= (JARVIS_MELEE_RANGE or 12)
        then
            if not isJarvisProtectedFromAura(target, nil) then
                jarvisMeleeAttack(target)
            end
        end
        return true
    end
    JARVIS_PUNCHAURA_ACTIVE = false
    JARVIS_PUNCHAURA_TARGET = nil
    jarvisTargetHoldAtHide(root)
    if JARVIS_TARGET_KILL_PENDING then
        if targetHum.Health <= 0 then
            JARVIS_TARGET_KILL_PENDING = false
            JARVIS_TARGET_KILL_START_HEALTH = nil
            jarvisTargetHoldAtHide(root)
            return true
        end
        if now >= (JARVIS_TARGET_KILL_CHECK_AT or 0) then
            local startHealth = JARVIS_TARGET_KILL_START_HEALTH
            local unchanged =
                startHealth ~= nil
                and targetHum.Health >= startHealth
            JARVIS_TARGET_KILL_PENDING = false
            JARVIS_TARGET_KILL_START_HEALTH = nil
            if unchanged
                and now - (JARVIS_TARGET_KILL_LAST_RETRY or 0)
                    >= (JARVIS_TARGET_KILL_RETRY_COOLDOWN or 1.5)
            then
                JARVIS_TARGET_KILL_LAST_RETRY = now
                task.spawn(function()
                    local liveRoot = myRoot()
                    if not liveRoot then
                        return
                    end
                    jarvisTargetReleaseHide(liveRoot)
                    otherCmd("tp " .. target.Name)
                    task.wait(0.12)
                    if JARVIS_PRIORITY_TARGET_ACTIVE
                        and JARVIS_PRIORITY_TARGET == target
                        and target.Parent
                    then
                        otherCmd("kill " .. target.Name)
                    end
                    task.wait(0.18)
                    local returnRoot = myRoot()
                    if returnRoot
                        and JARVIS_PRIORITY_TARGET_ACTIVE
                        and JARVIS_PRIORITY_TARGET == target
                    then
                        jarvisTargetHoldAtHide(returnRoot)
                    end
                end)
            end
        end
        return true
    end
    if now - (JARVIS_PRIORITY_TARGET_LAST_ACTION or 0)
        >= (JARVIS_PRIORITY_TARGET_ACTION_DELAY or 0.75)
    then
        JARVIS_PRIORITY_TARGET_LAST_ACTION = now
        JARVIS_TARGET_KILL_START_HEALTH = targetHum.Health
        JARVIS_TARGET_KILL_PENDING = true
        JARVIS_TARGET_KILL_CHECK_AT =
            now + (JARVIS_TARGET_KILL_CHECK_DELAY or 1.25)
        otherCmd("kill " .. target.Name)
    end
    return true
end
JARVIS_SELF_RETALIATE_COOLDOWN = 1.0
JARVIS_SHOOTBACK_ENABLED = false
JARVIS_ANTIPUNCH_ENABLED = false
JARVIS_SELF_LAST_RETALIATE = {}
JARVIS_ANTIPUNCH_TARGET = nil
JARVIS_ANTIPUNCH_ACTIVE = false
JARVIS_ANTIPUNCH_RANGE = JARVIS_MELEE_RANGE or 12
JARVIS_SELF_DAMAGE_CONN = nil
JARVIS_SELF_CHAR_CONN = nil
function isJarvisOwnerPlayer(player)
    if not player then
        return false
    end
    if player.Name:lower() == masterLower then
        return true
    end
    local key = player.Name:lower()
    if extraOwners and extraOwners[key] then
        return true
    end
    if isWhitelistedPlayer
        and isWhitelistedPlayer(player)
    then
        return true
    end
    return false
end
function clearJarvisAntiPunch()
    JARVIS_ANTIPUNCH_TARGET = nil
    JARVIS_ANTIPUNCH_ACTIVE = false
end
function startJarvisAntiPunch(target)
    if not JARVIS_ANTIPUNCH_ENABLED then
        clearJarvisAntiPunch()
        return
    end
    if not target or target == bot then
        clearJarvisAntiPunch()
        return
    end
    if isJarvisOwnerPlayer(target) then
        clearJarvisAntiPunch()
        return
    end
    JARVIS_ANTIPUNCH_TARGET = target
    JARVIS_ANTIPUNCH_ACTIVE = true
end
function jarvisAntiPunchStep()
    if not JARVIS_ANTIPUNCH_ENABLED or not JARVIS_ANTIPUNCH_ACTIVE then return end
    local target = JARVIS_ANTIPUNCH_TARGET
    if not target or not target.Parent or isJarvisOwnerPlayer(target)
        or (isWhitelistedPlayer and isWhitelistedPlayer(target)) then
        clearJarvisAntiPunch()
        return
    end
    local myR, tr = myRoot(), rootOf(target)
    local th = humOf(target)
    if not myR or not tr or not th or th.Health <= 0 then
        clearJarvisAntiPunch()
        return
    end
    if (myR.Position - tr.Position).Magnitude <= (JARVIS_ANTIPUNCH_RANGE or 12) then
        jarvisMeleeAttack(target)
    end
end
function jarvisSBAPRespond(attacker, damagedPlayer, kind)
    if not attacker or attacker == bot then return false end
    if isJarvisOwnerPlayer(attacker)
        or (isWhitelistedPlayer and isWhitelistedPlayer(attacker))
    then return false end

    JARVIS_SBAP_LAST = JARVIS_SBAP_LAST or {}
    local key = tostring(kind) .. ":" .. tostring(attacker.UserId or attacker.Name)
    local now = os.clock()
    if now - (JARVIS_SBAP_LAST[key] or 0) < 0.0375 then return false end
    JARVIS_SBAP_LAST[key] = now

    if kind == "ap" then
        -- AP stays in the bot's current path/location. It never chases.
        JARVIS_AP_STATIONARY_TARGET = attacker
        JARVIS_AP_STATIONARY_UNTIL = now + 0.65
        JARVIS_PUNCHAURA_TARGET = attacker
        JARVIS_PUNCHAURA_ACTIVE = true
        otherCmd("kill " .. attacker.Name)
        return true
    end

    -- Every new shot+damage match can trigger another .kill.
    otherCmd("kill " .. attacker.Name)
    return true
end

function retaliateJarvisSelfDamage(attacker)
    return jarvisSBAPRespond(attacker, bot, "sb")
end

function disconnectJarvisSelfDamageWatcher()
    if JARVIS_SELF_DAMAGE_CONN then JARVIS_SELF_DAMAGE_CONN:Disconnect() end
    if JARVIS_SELF_CHAR_CONN then JARVIS_SELF_CHAR_CONN:Disconnect() end
    JARVIS_SELF_DAMAGE_CONN = nil
    JARVIS_SELF_CHAR_CONN = nil
end

function attachJarvisSelfDamageWatcher()
    disconnectJarvisSelfDamageWatcher()

    local function hookCharacter(char)
        local hum = char and (char:FindFirstChildOfClass("Humanoid")
            or char:WaitForChild("Humanoid", 8))
        if not hum then return end

        local lastHealth = hum.Health
        JARVIS_SELF_DAMAGE_CONN = hum.HealthChanged:Connect(function(newHealth)
            local oldHealth = lastHealth
            lastHealth = newHealth
            if not oldHealth or newHealth >= oldHealth then return end

            -- Damage must occur inside that exact player's tiny attack window.
            if JARVIS_ANTIPUNCH_ENABLED then
                local puncher = jarvisFindWindowAttacker(bot, "ap")
                if puncher then
                    jarvisSBAPRespond(puncher, bot, "ap")
                    return
                end
            end

            if JARVIS_SHOOTBACK_ENABLED then
                local shooter = jarvisFindWindowAttacker(bot, "sb")
                if shooter then
                    jarvisSBAPRespond(shooter, bot, "sb")
                end
            end
        end)
    end

    if bot.Character then hookCharacter(bot.Character) end
    JARVIS_SELF_CHAR_CONN = bot.CharacterAdded:Connect(function(char)
        task.defer(function() hookCharacter(char) end)
    end)
end

-- Defensive modes stay enabled until explicitly turned off.
-- IMPORTANT: AntiPunch must NOT select arbitrary nearby players.
-- A response is only allowed after the existing damage/punch detector identifies
-- a specific attacker and calls startJarvisAntiPunch(attacker).

-- OWNER SHOT RESPONSE:
-- If the owner/master loses health and the game supplies a direct attacker tag,
-- exactly ONE JARVIS bot (squad index 1) starts PA on that attacker.
-- Other bots ignore the same hit. No nearest-player/facing guessing is used.
JARVIS_OWNER_DAMAGE_CONN = nil
JARVIS_OWNER_CHAR_CONN = nil
JARVIS_OWNER_WATCHED_PLAYER = nil
JARVIS_OWNER_PA_LAST = JARVIS_OWNER_PA_LAST or {}
JARVIS_OWNER_PA_COOLDOWN = 2.0

function disconnectJarvisOwnerDamageWatcher()
    if JARVIS_OWNER_DAMAGE_CONN then
        pcall(function() JARVIS_OWNER_DAMAGE_CONN:Disconnect() end)
        JARVIS_OWNER_DAMAGE_CONN = nil
    end
    if JARVIS_OWNER_CHAR_CONN then
        pcall(function() JARVIS_OWNER_CHAR_CONN:Disconnect() end)
        JARVIS_OWNER_CHAR_CONN = nil
    end
    JARVIS_OWNER_WATCHED_PLAYER = nil
end

function jarvisIsPrimaryDefenseBot()
    if IS_LEADER then return false end
    if getgenv().JARVIS_SQUAD and getgenv().JARVIS_SQUAD.index then
        local index = getgenv().JARVIS_SQUAD.index()
        return (tonumber(index) or 1) == 1
    end
    return (tonumber(mySlot) or 1) == 1
end

function startOwnerDefensePA(attacker)
    -- Compatibility name only. Automatic PA is disabled.
    local owner = getMaster()
    if not owner then return end
    jarvisSBAPRespond(attacker, owner)
end
function attachJarvisOwnerDamageWatcher()
    disconnectJarvisOwnerDamageWatcher()

    local owner = getMaster()
    if not owner or owner == bot then return end
    JARVIS_OWNER_WATCHED_PLAYER = owner

    local function hookOwnerCharacter(char)
        if not char then return end
        local hum = char:FindFirstChildOfClass("Humanoid")
            or char:WaitForChild("Humanoid", 8)
        if not hum then return end

        if JARVIS_OWNER_DAMAGE_CONN then
            pcall(function() JARVIS_OWNER_DAMAGE_CONN:Disconnect() end)
            JARVIS_OWNER_DAMAGE_CONN = nil
        end

        local lastHealth = hum.Health
        JARVIS_OWNER_DAMAGE_CONN = hum.HealthChanged:Connect(function(newHealth)
            if newHealth < lastHealth then
                -- Exact attacker only. This depends on the game's creator/
                -- attacker tag replicating to the client.
                local attacker = findLikelyProtectAttacker(owner)
                if attacker then
                    startOwnerDefensePA(attacker)
                end
            end
            lastHealth = newHealth
        end)
    end

    if owner.Character then
        hookOwnerCharacter(owner.Character)
    end

    JARVIS_OWNER_CHAR_CONN = owner.CharacterAdded:Connect(function(char)
        task.defer(function()
            hookOwnerCharacter(char)
        end)
    end)
end

function disconnectProtectDamageWatcher()
    if JARVIS_PROTECT_DAMAGE_CONNECTION then
        pcall(function()
            JARVIS_PROTECT_DAMAGE_CONNECTION:Disconnect()
        end)
        JARVIS_PROTECT_DAMAGE_CONNECTION = nil
    end
    if JARVIS_PROTECT_CHARACTER_CONNECTION then
        pcall(function()
            JARVIS_PROTECT_CHARACTER_CONNECTION:Disconnect()
        end)
        JARVIS_PROTECT_CHARACTER_CONNECTION = nil
    end
    JARVIS_PROTECT_LAST_HEALTH = nil
end
function protectRayVisible(attacker, target)
    local ar = rootOf(attacker)
    local tr = rootOf(target)
    if not ar or not tr then
        return false
    end
    local origin = ar.Position + Vector3.new(0, 1.5, 0)
    local targetPos = tr.Position + Vector3.new(0, 1.2, 0)
    local direction = targetPos - origin
    if direction.Magnitude <= 0.01 then
        return true
    end
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    local exclude = {}
    if attacker.Character then
        table.insert(exclude, attacker.Character)
    end
    if bot.Character then
        table.insert(exclude, bot.Character)
    end
    params.FilterDescendantsInstances = exclude
    params.IgnoreWater = true
    local result = workspace:Raycast(
        origin,
        direction,
        params
    )
    if not result then
        return true
    end
    if target.Character
        and result.Instance
        and result.Instance:IsDescendantOf(target.Character)
    then
        return true
    end
    return false
end
function protectFacingScore(attacker, target)
    local ar = rootOf(attacker)
    local tr = rootOf(target)
    if not ar or not tr then
        return nil
    end
    local delta = tr.Position - ar.Position
    local distance = delta.Magnitude
    if distance <= 0.01
        or distance > JARVIS_PROTECT_ATTACK_SCAN_RANGE
    then
        return nil
    end
    local flatDelta = Vector3.new(
        delta.X,
        0,
        delta.Z
    )
    local flatFacing = Vector3.new(
        ar.CFrame.LookVector.X,
        0,
        ar.CFrame.LookVector.Z
    )
    if flatDelta.Magnitude <= 0.01
        or flatFacing.Magnitude <= 0.01
    then
        return nil
    end
    local facingDot =
        flatFacing.Unit:Dot(flatDelta.Unit)
    if facingDot < JARVIS_PROTECT_ATTACK_FACING_DOT then
        return nil
    end
    if not protectRayVisible(attacker, target) then
        return nil
    end
    local score =
        distance * 0.08
        + (1 - facingDot) * 35
    return score
end

-- ============================================================
-- JARVIS 3-BOT DEFENSE / ATTACKER OBSERVER
-- Direct creator/attacker tags remain first choice.
-- Fallback records recent weapon Tool activation from other players, then
-- correlates it with health loss. Close-range health loss can also feed AP.
-- The squad code already supports 3+ bots; defense ownership below distributes
-- attackers across the current bot roster so active bots do not collide.
-- ============================================================
JARVIS_DEFENSE_RECENT_FIRE = JARVIS_DEFENSE_RECENT_FIRE or {}
JARVIS_DEFENSE_RECENT_PUNCH = JARVIS_DEFENSE_RECENT_PUNCH or {}
JARVIS_DEFENSE_TOOL_CONNECTIONS = JARVIS_DEFENSE_TOOL_CONNECTIONS or {}
JARVIS_DEFENSE_FIRE_WINDOW = 0.45
JARVIS_DEFENSE_PUNCH_WINDOW = 0.40
JARVIS_PUNCH_ANIMATION_ID = "180435571"

local function jarvisOpenAttackWindow(player, kind)
    if not player or player == bot then return end
    if kind == "ap" then
        JARVIS_DEFENSE_RECENT_PUNCH[player] = os.clock()
    else
        JARVIS_DEFENSE_RECENT_FIRE[player] = os.clock()
    end
end

local function jarvisHookReplicatedAttackSignals(player, char)
    if not player or not char then return end

    -- Prison Life punch animation: this is a much more reliable AP signal than
    -- expecting another client's Tool.Activated event to replicate.
    local hum = char:FindFirstChildOfClass("Humanoid")
    local animator = hum and (hum:FindFirstChildOfClass("Animator") or hum:WaitForChild("Animator", 3))
    if animator then
        animator.AnimationPlayed:Connect(function(track)
            local anim = track and track.Animation
            local id = anim and tostring(anim.AnimationId or "") or ""
            if id:find(JARVIS_PUNCH_ANIMATION_ID, 1, true) then
                jarvisOpenAttackWindow(player, "ap")
            end
        end)
    end

    local function hookTool(tool)
        if not tool:IsA("Tool") then return end

        -- Keep Activated as one signal where it does replicate.
        tool.Activated:Connect(function()
            local n=tostring(tool.Name or ""):lower()
            if n:find("punch",1,true) or n:find("fist",1,true) then
                jarvisOpenAttackWindow(player,"ap")
            else
                jarvisOpenAttackWindow(player,"sb")
            end
        end)

        -- Gun fire sounds replicate more reliably than another client's
        -- Activated event in many games.
        for _,d in ipairs(tool:GetDescendants()) do
            if d:IsA("Sound") then
                d.Played:Connect(function()
                    jarvisOpenAttackWindow(player,"sb")
                end)
            end
        end
        tool.DescendantAdded:Connect(function(d)
            if d:IsA("Sound") then
                d.Played:Connect(function()
                    jarvisOpenAttackWindow(player,"sb")
                end)
            end
        end)

        -- Ammo decreasing is another shot signal when the weapon exposes ammo.
        for _,d in ipairs(tool:GetDescendants()) do
            if (d:IsA("IntValue") or d:IsA("NumberValue"))
                and tostring(d.Name):lower():find("ammo",1,true)
            then
                local last=d.Value
                d.Changed:Connect(function(v)
                    local nv=tonumber(v)
                    if nv and tonumber(last) and nv < tonumber(last) then
                        jarvisOpenAttackWindow(player,"sb")
                    end
                    last=v
                end)
            end
        end
    end

    for _,v in ipairs(char:GetChildren()) do hookTool(v) end
    char.ChildAdded:Connect(hookTool)
end

for _,p in ipairs(Players:GetPlayers()) do
    if p ~= bot then
        if p.Character then jarvisHookReplicatedAttackSignals(p,p.Character) end
        p.CharacterAdded:Connect(function(c)
            task.defer(function() jarvisHookReplicatedAttackSignals(p,c) end)
        end)
    end
end
Players.PlayerAdded:Connect(function(p)
    p.CharacterAdded:Connect(function(c)
        task.defer(function() jarvisHookReplicatedAttackSignals(p,c) end)
    end)
end)

JARVIS_DEFENSE_GUN_RANGE = 600
JARVIS_DEFENSE_CLOSE_RANGE = 14

function jarvisDefenseDisconnectPlayer(player)
    local list = JARVIS_DEFENSE_TOOL_CONNECTIONS[player]
    if list then
        for _, c in ipairs(list) do
            pcall(function() c:Disconnect() end)
        end
    end
    JARVIS_DEFENSE_TOOL_CONNECTIONS[player] = nil
    JARVIS_DEFENSE_RECENT_FIRE[player] = nil
    JARVIS_DEFENSE_RECENT_PUNCH[player] = nil
end

function jarvisDefenseWatchTool(player, tool)
    if not player or player == bot or not tool or not tool:IsA("Tool") then return end
    local list = JARVIS_DEFENSE_TOOL_CONNECTIONS[player]
    if not list then
        list = {}
        JARVIS_DEFENSE_TOOL_CONNECTIONS[player] = list
    end
    local ok, conn = pcall(function()
        return tool.Activated:Connect(function()
            local name = tostring(tool.Name or ""):lower()
            local now = os.clock()
            if name:find("punch", 1, true)
                or name:find("fist", 1, true)
                or name:find("melee", 1, true)
            then
                JARVIS_DEFENSE_RECENT_PUNCH[player] = now
            else
                JARVIS_DEFENSE_RECENT_FIRE[player] = now
            end
        end)
    end)
    if ok and conn then table.insert(list, conn) end
end

function jarvisDefenseWatchCharacter(player, char)
    if not player or player == bot or not char then return end
    for _, item in ipairs(char:GetChildren()) do
        if item:IsA("Tool") then jarvisDefenseWatchTool(player, item) end
    end
    local list = JARVIS_DEFENSE_TOOL_CONNECTIONS[player]
    if not list then
        list = {}
        JARVIS_DEFENSE_TOOL_CONNECTIONS[player] = list
    end
    table.insert(list, char.ChildAdded:Connect(function(item)
        if item:IsA("Tool") then jarvisDefenseWatchTool(player, item) end
    end))
end

function jarvisDefenseWatchPlayer(player)
    if not player or player == bot then return end
    jarvisDefenseDisconnectPlayer(player)
    JARVIS_DEFENSE_TOOL_CONNECTIONS[player] = {}
    if player.Character then
        jarvisDefenseWatchCharacter(player, player.Character)
    end
    table.insert(JARVIS_DEFENSE_TOOL_CONNECTIONS[player],
        player.CharacterAdded:Connect(function(char)
            task.wait(0.05)
            jarvisDefenseWatchCharacter(player, char)
        end))
end

function jarvisDefenseLineClear(attacker, target)
    local ar, tr = rootOf(attacker), rootOf(target)
    if not ar or not tr then return false end
    local delta = tr.Position - ar.Position
    if delta.Magnitude > JARVIS_DEFENSE_GUN_RANGE then return false end
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = attacker.Character and {attacker.Character} or {}
    params.IgnoreWater = true
    local hit = workspace:Raycast(ar.Position + Vector3.new(0, 1.5, 0), delta, params)
    return (not hit)
        or (target.Character and hit.Instance and hit.Instance:IsDescendantOf(target.Character))
end

function jarvisDefenseFallbackAttacker(target)
    if not target then return nil end
    local now = os.clock()
    local tr = rootOf(target)
    if not tr then return nil end

    -- Prefer a player whose equipped Tool was activated immediately before damage.
    local best, bestAge = nil, math.huge
    for player, firedAt in pairs(JARVIS_DEFENSE_RECENT_FIRE) do
        if player and player.Parent and player ~= target and player ~= bot
            and not isJarvisOwnerPlayer(player)
            and not (isWhitelistedPlayer and isWhitelistedPlayer(player))
        then
            local age = now - (tonumber(firedAt) or 0)
            if age >= 0 and age <= JARVIS_DEFENSE_FIRE_WINDOW
                and age < bestAge and jarvisDefenseLineClear(player, target)
            then
                best, bestAge = player, age
            end
        end
    end
    if best then return best end

    -- Melee fallback: only for very close health loss. This is intentionally
    -- limited to AP range so a distant innocent player is never selected.
    local close, closeDist = nil, JARVIS_DEFENSE_CLOSE_RANGE
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= target and player ~= bot
            and not isJarvisOwnerPlayer(player)
            and not (isWhitelistedPlayer and isWhitelistedPlayer(player))
        then
            local pr, ph = rootOf(player), humOf(player)
            if pr and ph and ph.Health > 0 then
                local d = (pr.Position - tr.Position).Magnitude
                if d < closeDist then
                    close, closeDist = player, d
                end
            end
        end
    end
    return close
end

function jarvisActiveBotCount()
    return math.clamp(tonumber(getgenv().JARVIS_ACTIVE_BOT_COUNT) or 4, 1, 4)
end

function jarvisThisBotIsActive()
    if IS_LEADER then return false end
    local squad = getgenv().JARVIS_SQUAD
    if not squad or not squad.index then return true end
    local index = tonumber((squad.index())) or 1
    return index <= jarvisActiveBotCount()
end

function jarvisDefenseAssignedToThisBot(attacker)
    local squad = getgenv().JARVIS_SQUAD
    if not squad or not squad.index then return true end

    local index = tonumber((squad.index())) or 1
    local activeCount = jarvisActiveBotCount()

    -- Bots above the selected count stay out of defense work.
    if index > activeCount then return false end

    -- Split attackers only across the selected 1/2/3/4 active bot slots.
    local uid = tonumber(attacker and attacker.UserId) or 0
    local assigned = (math.abs(uid) % activeCount) + 1
    return index == assigned
end
for _, p in ipairs(Players:GetPlayers()) do
    if p ~= bot then task.defer(jarvisDefenseWatchPlayer, p) end
end
Players.PlayerAdded:Connect(function(p)
    task.defer(jarvisDefenseWatchPlayer, p)
end)
Players.PlayerRemoving:Connect(jarvisDefenseDisconnectPlayer)

function getTaggedDamageAttacker(target)
    local hum = humOf(target)
    if not hum then return nil end

    -- Many Roblox weapon systems tag the damaged Humanoid with the responsible
    -- Player. Prefer this whenever it exists because it is direct attribution.
    for _, tagName in ipairs({"creator", "Creator", "attacker", "Attacker", "killer", "Killer"}) do
        local tag = hum:FindFirstChild(tagName)
        if tag and tag:IsA("ObjectValue") then
            local value = tag.Value
            if value and value:IsA("Player") and value ~= target and value ~= bot then
                return value
            end
            if value and value:IsA("Model") then
                local p = Players:GetPlayerFromCharacter(value)
                if p and p ~= target and p ~= bot then return p end
            end
        end
    end
    return nil
end

local function jarvisFindWindowAttacker(victim, kind)
    local tagged = getTaggedDamageAttacker(victim)
    if tagged and tagged.Parent and tagged ~= bot and tagged ~= victim
        and not isJarvisOwnerPlayer(tagged)
        and not (isWhitelistedPlayer and isWhitelistedPlayer(tagged))
    then
        return tagged
    end

    local now = os.clock()
    local source = kind == "ap"
        and JARVIS_DEFENSE_RECENT_PUNCH
        or JARVIS_DEFENSE_RECENT_FIRE
    local window = kind == "ap"
        and (JARVIS_DEFENSE_PUNCH_WINDOW or 0.40)
        or (JARVIS_DEFENSE_FIRE_WINDOW or 0.45)

    local best, bestAge = nil, math.huge
    for player, t in pairs(source or {}) do
        local age = now - (tonumber(t) or 0)
        if age >= 0 and age <= window
            and player and player.Parent
            and player ~= bot and player ~= victim
            and not isJarvisOwnerPlayer(player)
            and not (isWhitelistedPlayer and isWhitelistedPlayer(player))
        then
            if kind == "ap" then
                local vr, pr = rootOf(victim), rootOf(player)
                if vr and pr
                    and (vr.Position - pr.Position).Magnitude <= (JARVIS_ANTIPUNCH_RANGE or 12)
                    and age < bestAge
                then
                    best, bestAge = player, age
                end
            elseif age < bestAge then
                best, bestAge = player, age
            end
        end
    end
    return best
end

function findLikelyProtectAttacker(target)
    if not target then return nil end

    -- Best signal: an actual creator/attacker/killer tag on the damaged Humanoid.
    local tagged = getTaggedDamageAttacker(target)
    if tagged and tagged.Parent and tagged ~= bot and tagged ~= target
        and not isJarvisOwnerPlayer(tagged)
        and not (isWhitelistedPlayer and isWhitelistedPlayer(tagged))
    then
        return tagged
    end

    -- IMPORTANT: this function is called from HealthChanged AFTER target really
    -- lost health. Recent weapon activation alone NEVER causes retaliation.
    -- It is only used to attribute an already-confirmed hit when the game does
    -- not replicate a creator tag.
    local now = os.clock()
    local tr = rootOf(target)
    if not tr then return nil end

    local best, bestAge = nil, math.huge
    for player, firedAt in pairs(JARVIS_DEFENSE_RECENT_FIRE or {}) do
        if player and player.Parent and player ~= bot and player ~= target
            and not isJarvisOwnerPlayer(player)
            and not (isWhitelistedPlayer and isWhitelistedPlayer(player))
        then
            local age = now - (tonumber(firedAt) or 0)
            local pr, ph = rootOf(player), humOf(player)
            if pr and ph and ph.Health > 0
                and age >= 0 and age <= 0.90
                and (pr.Position - tr.Position).Magnitude <= 600
                and age < bestAge
            then
                best, bestAge = player, age
            end
        end
    end
    if best then return best end

    -- Melee attribution fallback, still only after confirmed health loss.
    -- Tight radius avoids selecting somebody who is merely standing nearby.
    local close, closeDist = nil, 8
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= bot and player ~= target
            and not isJarvisOwnerPlayer(player)
            and not (isWhitelistedPlayer and isWhitelistedPlayer(player))
        then
            local pr, ph = rootOf(player), humOf(player)
            if pr and ph and ph.Health > 0 then
                local d = (pr.Position - tr.Position).Magnitude
                if d < closeDist then
                    close, closeDist = player, d
                end
            end
        end
    end
    return close
end
function retaliateProtectDamage(target)
    if not protecting or not target or protectedPlayer ~= target then return end

    local attacker = findLikelyProtectAttacker(target)
    if not attacker then
        print("[JARVIS] protect: damage confirmed but attacker unresolved.")
        return
    end
    if isJarvisOwnerPlayer(attacker)
        or (isWhitelistedPlayer and isWhitelistedPlayer(attacker))
    then return end
    if not jarvisDefenseAssignedToThisBot(attacker) then return end

    local now = os.clock()
    local key = attacker.UserId or attacker.Name
    if now - (JARVIS_PROTECT_LAST_RETALIATE[key] or 0)
        < (JARVIS_PROTECT_ATTACK_COOLDOWN or 0.3125)
    then return end
    JARVIS_PROTECT_LAST_RETALIATE[key] = now

    -- PROTECT: anybody who actually damages the protected player -> .kill.
    -- FPROTECT also uses this for damage, plus protectGuardScan() kills on sight.
    if JARVIS_PROTECT_MODE == "full" or JARVIS_PROTECT_MODE == "invisfull" then
        JARVIS_PROTECT_SEND_KILL(attacker)
    else
        otherCmd("kill " .. attacker.Name)
    end
    print("[JARVIS] protect confirmed attacker -> .kill", attacker.Name)
end
function attachProtectDamageWatcher(target)
    disconnectProtectDamageWatcher()
    if not target then
        return
    end
    local function hookCharacter(char)
        if not char then
            return
        end
        local hum =
            char:FindFirstChildOfClass("Humanoid")
            or char:WaitForChild("Humanoid", 8)
        if not hum then
            return
        end
        JARVIS_PROTECT_LAST_HEALTH = hum.Health
        JARVIS_PROTECT_DAMAGE_CONNECTION =
            hum.HealthChanged:Connect(function(newHealth)
                local oldHealth =
                    JARVIS_PROTECT_LAST_HEALTH
                JARVIS_PROTECT_LAST_HEALTH =
                    newHealth
                if not protecting
                    or protectedPlayer ~= target
                then
                    return
                end
                if oldHealth and newHealth < oldHealth then
                    local attacker = findLikelyProtectAttacker(target)
                    if attacker
                        and not isJarvisOwnerPlayer(attacker)
                        and not (isWhitelistedPlayer and isWhitelistedPlayer(attacker))
                        and jarvisDefenseAssignedToThisBot(attacker)
                    then
                        local key = attacker.UserId or attacker.Name
                        local now = os.clock()
                        if now - (JARVIS_PROTECT_LAST_RETALIATE[key] or 0)
                            >= (JARVIS_PROTECT_ATTACK_COOLDOWN or 0.3125)
                        then
                            JARVIS_PROTECT_LAST_RETALIATE[key] = now
                            if JARVIS_PROTECT_MODE == "full" or JARVIS_PROTECT_MODE == "invisfull" then
                                JARVIS_PROTECT_SEND_KILL(attacker)
                            else
                                otherCmd("kill " .. attacker.Name)
                            end
                        end
                    end
                end
            end)
    end
    if target.Character then
        hookCharacter(target.Character)
    end
    JARVIS_PROTECT_CHARACTER_CONNECTION =
        target.CharacterAdded:Connect(function(char)
            task.wait(0.25)
            if protecting
                and protectedPlayer == target
            then
                hookCharacter(char)
            end
        end)
end

-- SHOT -> .kill TARGET
-- Uses the same HealthChanged idea as Protect, but only acts after this client
-- has just fired while holding a Tool. It then chooses the damaged player that
-- was most plausibly in the shot direction and sends the normal admin .kill.
do
    local env = getgenv()
    env.JARVIS_SHOTKILL_ENABLED = true
    env.JARVIS_SHOTKILL_WINDOW = 0.75
    env.JARVIS_SHOTKILL_MAX_RANGE = 500
    env.JARVIS_SHOTKILL_LAST_SHOT = 0
    env.JARVIS_SHOTKILL_CONNECTIONS = env.JARVIS_SHOTKILL_CONNECTIONS or {}

    local function clearPlayer(player)
        local old = env.JARVIS_SHOTKILL_CONNECTIONS[player]
        if old then
            for _, connection in ipairs(old) do
                pcall(function() connection:Disconnect() end)
            end
        end
        env.JARVIS_SHOTKILL_CONNECTIONS[player] = nil
    end

    local function holdingGunLikeTool()
        local char = bot.Character
        if not char then return false end
        local tool = char:FindFirstChildOfClass("Tool")
        if not tool then return false end
        -- Generic on purpose: you said you'll swap/limit the gun later.
        return true
    end

    local function plausibleShotVictim(player)
        if player == bot or not player.Character then
            return false
        end
        local camera = workspace.CurrentCamera
        local root = rootOf(player)
        if not camera or not root then
            return false
        end

        local delta = root.Position - camera.CFrame.Position
        local distance = delta.Magnitude
        if distance <= 0.01 or distance > env.JARVIS_SHOTKILL_MAX_RANGE then
            return false
        end

        -- Require the victim to be reasonably close to the direction the
        -- shooter was looking when the shot was fired.
        local dot = camera.CFrame.LookVector:Dot(delta.Unit)
        if dot < 0.94 then
            return false
        end

        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Exclude
        params.FilterDescendantsInstances = bot.Character and {bot.Character} or {}
        params.IgnoreWater = true

        local hit = workspace:Raycast(
            camera.CFrame.Position,
            delta,
            params
        )

        return not hit
            or (hit.Instance and hit.Instance:IsDescendantOf(player.Character))
    end

    local function onDamaged(player, oldHealth, newHealth)
        if not env.JARVIS_SHOTKILL_ENABLED then return end
        if not oldHealth or newHealth >= oldHealth then return end
        if os.clock() - env.JARVIS_SHOTKILL_LAST_SHOT > env.JARVIS_SHOTKILL_WINDOW then
            return
        end
        if not plausibleShotVictim(player) then
            return
        end

        -- Consume this shot so one click cannot trigger several victims.
        env.JARVIS_SHOTKILL_LAST_SHOT = 0
        print("[JARVIS] shot target -> .kill", player.Name)
        otherCmd("kill " .. player.Name)
    end

    local function watchCharacter(player, character)
        clearPlayer(player)
        local connections = {}
        env.JARVIS_SHOTKILL_CONNECTIONS[player] = connections

        local hum = character:FindFirstChildOfClass("Humanoid")
            or character:WaitForChild("Humanoid", 8)
        if not hum then return end

        local lastHealth = hum.Health
        table.insert(connections, hum.HealthChanged:Connect(function(newHealth)
            local oldHealth = lastHealth
            lastHealth = newHealth
            onDamaged(player, oldHealth, newHealth)
        end))
    end

    local function watchPlayer(player)
        if player == bot then return end
        if player.Character then
            task.defer(watchCharacter, player, player.Character)
        end
        local list = env.JARVIS_SHOTKILL_CONNECTIONS[player] or {}
        env.JARVIS_SHOTKILL_CONNECTIONS[player] = list
        table.insert(list, player.CharacterAdded:Connect(function(character)
            task.wait(0.15)
            watchCharacter(player, character)
        end))
    end

    for _, player in ipairs(Players:GetPlayers()) do
        watchPlayer(player)
    end
    Players.PlayerAdded:Connect(watchPlayer)
    Players.PlayerRemoving:Connect(clearPlayer)

    -- Record a shot only while a Tool is equipped.
    UserInputService.InputBegan:Connect(function(input, processed)
        if processed then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1
            and holdingGunLikeTool()
        then
            env.JARVIS_SHOTKILL_LAST_SHOT = os.clock()
        end
    end)
end


-- CLIENT-ONLY GUN TARGET HOOK
-- Left click while holding any Tool -> identify the player under the mouse.
-- Replace/extend JARVIS_LOCAL_GUN_TARGET_CALLBACK for your own game's
-- authorized weapon/admin handling.
do
    local env = getgenv()

    env.JARVIS_LOCAL_GUN_TARGET_ENABLED = true

    if type(env.JARVIS_LOCAL_GUN_TARGET_CALLBACK) ~= "function" then
        env.JARVIS_LOCAL_GUN_TARGET_CALLBACK = function(targetPlayer)
            print("[JARVIS] local gun target:", targetPlayer.Name)
        end
    end

    local function equippedTool()
        local character = bot.Character
        return character and character:FindFirstChildOfClass("Tool")
    end

    local function playerFromPart(part)
        if not part then return nil end

        local model = part:FindFirstAncestorOfClass("Model")
        while model do
            local player = Players:GetPlayerFromCharacter(model)
            if player then
                return player
            end
            model = model.Parent and model.Parent:FindFirstAncestorOfClass("Model")
        end

        return nil
    end

    local function targetUnderMouse()
        local mouse = bot:GetMouse()
        local target = mouse and mouse.Target
        local player = playerFromPart(target)

        if player and player ~= bot then
            return player
        end

        -- Fallback: client camera ray through current mouse position.
        local camera = workspace.CurrentCamera
        if not camera then return nil end

        local pos = UserInputService:GetMouseLocation()
        local ray = camera:ViewportPointToRay(pos.X, pos.Y)

        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Exclude
        params.FilterDescendantsInstances =
            bot.Character and {bot.Character} or {}
        params.IgnoreWater = true

        local result = workspace:Raycast(
            ray.Origin,
            ray.Direction * 1000,
            params
        )

        return result and playerFromPart(result.Instance) or nil
    end

    UserInputService.InputBegan:Connect(function(input, processed)
        if processed or not env.JARVIS_LOCAL_GUN_TARGET_ENABLED then
            return
        end

        if input.UserInputType ~= Enum.UserInputType.MouseButton1 then
            return
        end

        if not equippedTool() then
            return
        end

        local targetPlayer = targetUnderMouse()
        if not targetPlayer then
            return
        end

        local callback = env.JARVIS_LOCAL_GUN_TARGET_CALLBACK
        if type(callback) == "function" then
            task.spawn(callback, targetPlayer)
        end
    end)
end

function jarvisWhitelistName(name)
    return tostring(name or ""):lower()
end
function isJarvisProtectedFromAura(p, protected)
    if isAlly(p) then return true end
    if not p then
        return true
    end
    if p == bot then
        return true
    end
    if p.Name:lower() == MASTER_NAME:lower() then
        return true
    end
    if protected and p == protected then
        return true
    end
    if JARVIS_WHITELIST
        and JARVIS_WHITELIST[jarvisWhitelistName(p.Name)]
    then
        return true
    end
    if JARVIS_DYNAMIC_WHITELIST
        and JARVIS_DYNAMIC_WHITELIST[p.UserId]
    then
        return true
    end
    return false
end
function refreshPunchauraNearbyWhitelist(target)
    table.clear(JARVIS_DYNAMIC_WHITELIST)
    if not target then
        return
    end
    local tr = rootOf(target)
    if not tr then
        return
    end
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= bot then
            local pr = rootOf(p)
            if pr then
                local d = (pr.Position - tr.Position).Magnitude
                if d <= JARVIS_PUNCHAURA_NEARBY_WHITELIST_RADIUS
                    and p ~= target
                then
                    JARVIS_DYNAMIC_WHITELIST[p.UserId] = true
                end
            end
        end
    end
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Name:lower() == MASTER_NAME:lower() then
            JARVIS_DYNAMIC_WHITELIST[p.UserId] = true
        end
    end
end
function getMeleeRemote()
    return ReplicatedStorage:FindFirstChild("meleeEvent")
        or ReplicatedStorage:FindFirstChild("MeleeEvent")
end
function jarvisMeleeAttack(target)
    if not target or target == bot then
        return
    end
    local now = os.clock()
    local key = target.UserId
    if now - (JARVIS_MELEE_LAST_HIT[key] or 0)
        < JARVIS_MELEE_HIT_COOLDOWN
    then
        return
    end
    local melee = getMeleeRemote()
    if not melee or not melee:IsA("RemoteEvent") then
        return
    end
    JARVIS_MELEE_LAST_HIT[key] = now
    pcall(function()
        melee:FireServer(target, 1, 1)
    end)
end
function runJarvisMeleeAura(centerPlayer, protectedPlayerForAura)
    local centerRoot = rootOf(centerPlayer or bot)
    if not centerRoot then
        return
    end
    for _, p in ipairs(Players:GetPlayers()) do
        if not isJarvisProtectedFromAura(p, protectedPlayerForAura)
            and (not protectedPlayerForAura
                or (JARVIS_PROTECT_MODE ~= "full" and JARVIS_PROTECT_MODE ~= "invisfull")
                or JARVIS_PROTECT_CAN_TARGET(p)) then
            local pr = rootOf(p)
            local ph = humOf(p)
            if pr
                and ph
                and ph.Health > 0
                and (pr.Position - centerRoot.Position).Magnitude <= JARVIS_MELEE_RANGE
            then
                local shouldSkip = false
                pcall(function()
                    local myTeamName = bot.Team and bot.Team.Name or ""
                    local theirTeamName = p.Team and p.Team.Name or ""
                    if myTeamName:lower():find("guard", 1, true)
                        and theirTeamName:lower():find("inmate", 1, true)
                        and p.Character
                        and not p.Character:GetAttribute("Hostile")
                    then
                        shouldSkip = true
                    end
                end)
                if not shouldSkip then
                    jarvisMeleeAttack(p)
                end
            end
        end
    end
end
function punchauraPredictionGoal(target)
    local tr = rootOf(target)
    if not tr then return nil end

    local squad = getgenv().JARVIS_SQUAD
    local index = 1
    if squad and squad.index then
        index = tonumber((squad.index())) or 1
    end

    -- PA formation: bots 1/2 front-left/right, bot 3 center,
    -- bot 4 rear (separate from the first three).
    if index == 3 then
        return tr.Position
    end
    if index == 4 then
        return tr.Position - tr.CFrame.LookVector * 3.5
            + tr.CFrame.RightVector * 2.25
    end

    local velocity = tr.AssemblyLinearVelocity
    local horizontalVelocity = Vector3.new(velocity.X, 0, velocity.Z)
    local frontDistance = JARVIS_PUNCHAURA_FRONT_DISTANCE or 3.5
    local sideDistance = 2.25
    local side = (index == 1) and -sideDistance or sideDistance

    return tr.Position
        + horizontalVelocity * (JARVIS_PUNCHAURA_PREDICT or 0.18)
        + tr.CFrame.LookVector * frontDistance
        + tr.CFrame.RightVector * side
end
function punchauraStep(root, dt)
    local target = JARVIS_PUNCHAURA_TARGET
    if not JARVIS_PUNCHAURA_ACTIVE or not target or not target.Parent then
        return false
    end

    if JARVIS_AP_STATIONARY_TARGET == target then
        local tr = rootOf(target)
        if not root or not tr then
            JARVIS_AP_STATIONARY_TARGET = nil
            JARVIS_PUNCHAURA_ACTIVE = false
            return false
        end

        local distance = (root.Position - tr.Position).Magnitude
        if distance > (JARVIS_ANTIPUNCH_RANGE or 12) + 3
            or os.clock() > (JARVIS_AP_STATIONARY_UNTIL or 0)
        then
            JARVIS_AP_STATIONARY_TARGET = nil
            JARVIS_PUNCHAURA_TARGET = nil
            JARVIS_PUNCHAURA_ACTIVE = false
            return false
        end

        -- Stay in the current path/position; only PA this puncher.
        root.AssemblyLinearVelocity = Vector3.zero
        jarvisMeleeAttack(target)
        return true
    end

    if invisFollow then return false end
    local tr = rootOf(target)
    if not tr then return true end
    local goal = punchauraPredictionGoal(target)
    if goal then flyStep(root, goal, dt, true) end
    refreshPunchauraNearbyWhitelist(target)
    runJarvisMeleeAura(bot, nil)
    return true
end
JARVIS_RESPAWN_COMBO_DELAY = 0.75
JARVIS_RESPAWN_COMBO_RETRIES = 5
JARVIS_RESPAWN_COMBO_RETRY_DELAY = 0.85
JARVIS_COMBO2_EXCLUSIVE_UNTIL = 0

local function jarvisCombo2ExclusiveActive()
    return os.clock() < (JARVIS_COMBO2_EXCLUSIVE_UNTIL or 0)
end

local JARVIS_COMBO2_SAVED_FLY = nil
local JARVIS_COMBO2_SAVED_NOCLIP = nil
local JARVIS_COMBO2_TOKEN = 0

local function jarvisBeginCombo2Exclusive()
    -- Temporary panic-like PAUSE, not the destructive 'panic' command.
    -- Preserve follow/protection/target settings for automatic resumption.
    JARVIS_COMBO2_TOKEN += 1
    local token = JARVIS_COMBO2_TOKEN
    JARVIS_COMBO2_SAVED_FLY = flying
    JARVIS_COMBO2_SAVED_NOCLIP = noclipOn
    JARVIS_COMBO2_EXCLUSIVE_UNTIL = os.clock() + 2.0
    -- Disable noclip completely BEFORE the first Combo2 teleport.
    -- setNoclipAdmin(false) disconnects its Stepped loop and restores
    -- CanCollide on all body parts previously changed by noclip.
    setNoclipAdmin(false)
    releaseTrueIdleAnchor()
    JARVIS_IDLE_HOLD_CFRAME = nil
    setFly(true)

    task.delay(2.0, function()
        if token ~= JARVIS_COMBO2_TOKEN then return end
        JARVIS_COMBO2_EXCLUSIVE_UNTIL = 0
        -- Restore the exact noclip state from before weapon collection.
        if JARVIS_COMBO2_SAVED_NOCLIP ~= nil then
            setNoclipAdmin(JARVIS_COMBO2_SAVED_NOCLIP)
        end
        JARVIS_COMBO2_SAVED_NOCLIP = nil
        local root = myRoot()
        if root then
            local hover = root:FindFirstChild("JARVIS_Combo2Hover")
            if hover then hover:Destroy() end
            -- Do not reset velocity here; allow the resumed task to move.
        end
        -- Restore the prior fly state; the ordinary movement loop then
        -- resumes the exact existing follow/protect/target behavior.
        if JARVIS_COMBO2_SAVED_FLY ~= nil then
            setFly(JARVIS_COMBO2_SAVED_FLY)
        end
        JARVIS_COMBO2_SAVED_FLY = nil
    end)
end

function shouldAutoCombo2ForTeam()
    local teamName = ""
    if bot.Team then
        teamName = tostring(bot.Team.Name or ""):lower()
    end
    local teamColorName = ""
    pcall(function()
        teamColorName = tostring(bot.TeamColor.Name or ""):lower()
    end)

    local combined = teamName .. " " .. teamColorName
    if combined:find("criminal", 1, true)
        or combined:find("crim", 1, true)
    then
        return false
    end

    if combined:find("guard", 1, true)
        or combined:find("police", 1, true)
        or combined:find("inmate", 1, true)
        or combined:find("prisoner", 1, true)
    then
        return true
    end

    return false
end

local JARVIS_RESPAWN_COMBO_TOKEN = 0

function runRespawnCombo2()
    JARVIS_RESPAWN_COMBO_TOKEN += 1
    local myToken = JARVIS_RESPAWN_COMBO_TOKEN

    task.spawn(function()
        task.wait(JARVIS_RESPAWN_COMBO_DELAY)

        for attempt = 1, JARVIS_RESPAWN_COMBO_RETRIES do
            if myToken ~= JARVIS_RESPAWN_COMBO_TOKEN then
                return
            end

            local char = bot.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            local root = char and char:FindFirstChild("HumanoidRootPart")

            -- Wait until the new character is genuinely ready. The old version
            -- could fire .combo2 while the respawn was still loading.
            if char and char.Parent and hum and hum.Health > 0 and root then
                if shouldAutoCombo2ForTeam() then
                    print(
                        "[JARVIS] respawn ready -> .combo2 attempt",
                        attempt
                    )
                    jarvisBeginCombo2Exclusive()
                    otherCmd("combo2")

                    -- Send a second confirmation shortly after the first.
                    -- This handles command systems that are not ready on the
                    -- exact frame the character finishes spawning.
                    task.wait(0.35)
                    if myToken == JARVIS_RESPAWN_COMBO_TOKEN
                        and bot.Character == char
                        and hum.Parent
                        and hum.Health > 0
                    then
                        otherCmd("combo2")
                    end
                    return
                end
            end

            task.wait(JARVIS_RESPAWN_COMBO_RETRY_DELAY)
        end

        print("[JARVIS] respawn combo2: character/team never became ready.")
    end)
end
function disconnectProtection()
    if protectionCharacterConnection then
        pcall(function()
            protectionCharacterConnection:Disconnect()
        end)
        protectionCharacterConnection = nil
    end
    for _, connection in ipairs(protectionConnections) do
        if connection then
            pcall(function()
                connection:Disconnect()
            end)
        end
    end
    table.clear(protectionConnections)
    protectionConnection = nil
end
function watchProtectedPlayer(plr)
    protectedPlayer = plr
end
function sameProtectTeam(a, b)
    if not a or not b then
        return false
    end
    if a.Team ~= nil and b.Team ~= nil then
        return a.Team == b.Team
    end
    if a.TeamColor ~= nil and b.TeamColor ~= nil then
        return a.TeamColor == b.TeamColor
    end
    return false
end
function protectPunchAuraTarget(target)
    if isAlly(target) then return end
    if not target or target == bot then
        return
    end
    otherCmd("punchaura " .. target.Name)
end
function protectKillTarget(target)
    if isAlly(target) then return end
    if not target or target == bot then
        return
    end
    if isWhitelistedPlayer and isWhitelistedPlayer(target) then
        return
    end
    if JARVIS_PROTECT_MODE == "full" or JARVIS_PROTECT_MODE == "invisfull" then
        JARVIS_PROTECT_SEND_KILL(target)
    else
        otherCmd("kill " .. target.Name)
    end
end
function protectGuardScan()
    -- FULL/FPROTECT: proactively .kill every visible hostile in range.
    -- Normal protect does NOT use this scan; it retaliates only after damage.
    if not protecting or (JARVIS_PROTECT_MODE ~= "full" and JARVIS_PROTECT_MODE ~= "invisfull") then return end

    local protected = protectedPlayer or getMaster()
    local pr = rootOf(protected)
    if not protected or not pr then return end

    local now = os.clock()
    if now - (JARVIS_FULLPROTECT_LAST_SCAN or 0)
        < (JARVIS_FULLPROTECT_SCAN_DELAY or 0.025)
    then
        return
    end
    JARVIS_FULLPROTECT_LAST_SCAN = now

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= bot and p ~= protected
            and not isJarvisOwnerPlayer(p)
            and not (isWhitelistedPlayer and isWhitelistedPlayer(p))
            and not isAlly(p)
        then
            local ph, rr = humOf(p), rootOf(p)
            if ph and ph.Health > 0 and rr
                and (rr.Position - pr.Position).Magnitude <= (JARVIS_FULLPROTECT_SCAN_RANGE or 250)
                and protectRayVisible(p, protected)
            then
                JARVIS_PROTECT_SEND_KILL(p)
            end
        end
    end
end
function protectOrbitStep(root, dt)
    if not protecting then return false end

    -- LIMITED: absolutely no protect movement/orbit/camera steering.
    if JARVIS_PROTECT_MODE == "limited" then
        return false
    end

    protectGuardScan()

    -- IPROTECT / INVISPROTECT: perform the same full-protect scan using the
    -- protected player's line of sight, while the bot stays underground.
    if JARVIS_PROTECT_MODE == "invisfull" then
        local protected = protectedPlayer or getMaster()
        local protectedRoot = rootOf(protected)
        if not protectedRoot then return true end
        releaseTrueIdleAnchor()
        setFly(true)
        local depth = math.max(8, tonumber(cloakDepth) or 8)
        local goal = protectedRoot.Position - Vector3.new(0, depth, 0)
        flyStep(root, goal, dt, true)
        return true
    end
    local protected = protectedPlayer or getMaster()
    local protectedRoot = rootOf(protected)
    if not protectedRoot then
        return true
    end
    releaseTrueIdleAnchor()
    setFly(true)
    local angle, radius = getgenv().JARVIS_SQUAD.ring(
        JARVIS_PROTECT_ORBIT_RADIUS, JARVIS_PROTECT_ORBIT_SPEED)
    JARVIS_PROTECT_ORBIT_ANGLE = angle
    local offset = Vector3.new(math.cos(angle) * radius, 0, math.sin(angle) * radius)
    local goal =
        protectedRoot.Position
        + offset
    goal = Vector3.new(
        goal.X,
        protectedRoot.Position.Y,
        goal.Z
    )
    flyStep(
        root,
        goal,
        dt,
        true
    )
    runJarvisMeleeAura(bot, protected)

    -- Do NOT hard-lock Y every frame here. That prevented gun/pickup
    -- routines from moving vertically to the pickup.
    -- Fall recovery elsewhere in the script remains active.
    return true
end
function setFormation(name)
    name = string.lower(
        tostring(name or "")
    )
    local aliases = {
        v = "v",
        wedge = "v",
        diamond = "diamond",
        d = "diamond",
        wall = "wall",
        circle = "circle",
        ring = "circle",
        columns = "columns",
        column = "columns",
        dynamic = "dynamic",
        auto = "dynamic",
    }
    local selected =
        aliases[name]
    if not selected then
        voice(
            "formations: dynamic, v, diamond, wall, circle, columns"
        )
        return
    end
    formationType = selected
    voice(
        "formation "
        .. selected
    )
end
function firstArg(rest)
    return rest:match(
        "^(%S+)"
    ) or ""
end
function secondArg(rest)
    return rest:match(
        "^%S+%s+(%S+)"
    ) or ""
end
function normalizeCommandBody(body)
    body = tostring(body or ""):gsub("^%s+", ""):gsub("%s+$", "")
    local lower = body:lower()
    local capture = lower:match("^eliminate%s+(.+)$")
        or lower:match("^take out%s+(.+)$")
        or lower:match("^go after%s+(.+)$")
    if capture then
        return "kill " .. capture
    end
    if lower == "come here" or lower == "follow me" or lower == "can you follow me" then
        return "follow"
    end
    if lower == "guard me" or lower == "protect me" then
        return "protect"
    end
    if lower == "hide" or lower == "go invisible" then
        return "invis"
    end
    if lower == "show" or lower == "be visible" then
        return "vis"
    end
    if lower == "halt" then
        return "stop"
    end

    -- New simplified team-kill shorthand.
    -- 'k is NOT a player-kill alias anymore: it only expands recognized teams.
    local kteam = lower:match("^k%s+(%S+)%s*$")
    if kteam then
        local teamAliases = {
            g="guards", guard="guards", guards="guards",
            i="inmates", inmate="inmates", inmates="inmates", prisoner="inmates", prisoners="inmates",
            c="criminals", criminal="criminals", criminals="criminals",
        }
        local resolvedTeam = teamAliases[kteam]
        if resolvedTeam then
            return "kill team " .. resolvedTeam
        end
    end
    return body
end
MASTER_BLOCKED_COMMANDS = {
    kill = true,
    kick = true,
    fling = true,
    hitbox = true,
    bring = true,
    punchaura = true,
    pa = true,
    unshare = true,
}
function isMasterReference(text)
    text = tostring(text or ""):lower():gsub("^%s+", ""):gsub("%s+$", "")
    local first = text:match("^(%S+)") or ""
    if first == "master" or first == "owner" or first == "me"
        or first == masterLower then
        return true
    end
    local p = findPlayer(first)
    return (p and p.Name:lower() == masterLower) or false
end
function normalizeTeamName(name)
    name = tostring(name or ""):lower():gsub("^%s+", ""):gsub("%s+$", "")
    name = name:gsub("%s+team$", "")
    if name:sub(-1) == "s" then
        name = name:sub(1, -2)
    end
    return name
end
function isWhitelistedPlayer(player)
    if getgenv().JARVIS_SQUAD and getgenv().JARVIS_SQUAD.isPeer(player) then return true end
    if not player then
        return false
    end
    if protecting
        and protectedPlayer
        and protectedPlayer == player
    then
        return true
    end
    return JARVIS_WHITELIST[player.Name:lower()] == true
end
function setWhitelisted(player, enabled)
    if not player then
        return false
    end
    local key = player.Name:lower()
    if enabled then
        JARVIS_WHITELIST[key] = true
    else
        JARVIS_WHITELIST[key] = nil
    end
    return true
end
function getWhitelistNames()
    local names = {}
    for username, enabled in pairs(JARVIS_WHITELIST) do
        if enabled then
            table.insert(names, username)
        end
    end
    table.sort(names)
    return names
end
function resolveTeamSelector(rest)
    rest = tostring(rest or ""):gsub("^%s+", ""):gsub("%s+$", "")
    local requested = rest:match("^[Tt][Ee][Aa][Mm]%s+(.+)$")
    if not requested or requested == "" then
        return nil
    end
    local wanted = normalizeTeamName(requested)
    for _, player in ipairs(Players:GetPlayers()) do
        if player.Team and normalizeTeamName(player.Team.Name) == wanted then
            return player.Team
        end
    end
    return nil
end
-- Build the command-box WL from JARVIS's CURRENT protected identities.
-- Includes permanent owner, shared users, explicit JARVIS whitelist and JARVIS peers.
function getJarvisCommandWhitelistNames()
    local seen, names = {}, {}
    local function addName(name)
        name = tostring(name or ""):gsub("^%s+", ""):gsub("%s+$", "")
        if name == "" then return end
        local key = name:lower()
        if seen[key] then return end
        seen[key] = true
        local p = findPlayer(name)
        table.insert(names, p and p.Name or name)
    end

    addName(MASTER_NAME)
    local master = getMaster()
    if master then addName(master.Name) end

    for name, enabled in pairs(extraOwners) do
        if enabled then addName(name) end
    end
    for name, enabled in pairs(JARVIS_WHITELIST) do
        if enabled then addName(name) end
    end
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= bot and getgenv().JARVIS_SQUAD
            and getgenv().JARVIS_SQUAD.isPeer
            and getgenv().JARVIS_SQUAD.isPeer(p)
        then
            addName(p.Name)
        end
    end

    table.sort(names, function(x,y) return x:lower() < y:lower() end)
    return names
end

function normalizeKillTeamName(text)
    text=tostring(text or ""):lower():gsub("^%s+",""):gsub("%s+$","")
    local aliases={
        g="guards", guard="guards", guards="guards",
        i="inmates", inmate="inmates", inmates="inmates", prisoner="inmates", prisoners="inmates",
        c="criminals", criminal="criminals", criminals="criminals"
    }
    return aliases[text]
end

-- Kill safety / anti-collision state.
JARVIS_KNOWN_GUNS = {
    ["Remington 870"]=true, ["M9"]=true, ["AK-47"]=true,
    ["M4A1"]=true, ["MP5"]=true, ["Riot Shotgun"]=true,
}

function jarvisHasUsableGun()
    local character=bot.Character
    local backpack=bot:FindFirstChildOfClass("Backpack")
    local function scan(container)
        if not container then return false end
        for _,item in ipairs(container:GetChildren()) do
            if item:IsA("Tool") then
                if JARVIS_KNOWN_GUNS[item.Name] then return true end
                -- Accept gun-like tools from modified/back-end versions too.
                local low=item.Name:lower()
                if low:find("gun",1,true) or low:find("rifle",1,true)
                    or low:find("shotgun",1,true) or low:find("pistol",1,true)
                then
                    return true
                end
            end
        end
        return false
    end
    return scan(character) or scan(backpack)
end

function cancelEverythingForKill()
    -- Kill owns movement/combat exclusively. Old modes are cancelled, not resumed.
    frozen=false
    freezeCFrame=nil
    protecting=false
    protectedPlayer=nil
    orbiting=false
    orbitTarget=nil
    dancing=false
    guardMode=false
    punchOn=false
    spinning=false
    patrolOrigin=nil
    scoutOrigin=nil
    scoutReturning=false
    invisFollow=false
    invisPosition=nil
    targetPlayer=nil
    followCamPlayer=nil
    cheaterActive=false
    cheaterTarget=nil
    mode="idle"

    JARVIS_FOLLOW_RELEASE_UNTIL=math.huge
    JARVIS_CLOAK_RELEASE_UNTIL=math.huge

    if stopJarvisIPA then
        stopJarvisIPA()
    else
        JARVIS_IPA_ACTIVE=false
        JARVIS_IPA_TARGET=nil
    end
    JARVIS_PUNCHAURA_ACTIVE=false
    JARVIS_PUNCHAURA_TARGET=nil
    JARVIS_PRIORITY_TARGET_ACTIVE=false
    JARVIS_PRIORITY_TARGET=nil
    JARVIS_TARGET_KILL_PENDING=false

    if disconnectProtectDamageWatcher then
        disconnectProtectDamageWatcher()
    end
    if disconnectProtection then
        disconnectProtection()
    end
    if removeCloakYHold then
        removeCloakYHold()
    end
    if stopMove then
        stopMove()
    end
    if restoreOwnCam then
        restoreOwnCam()
    end

    local r=myRoot()
    if r then
        r.AssemblyLinearVelocity=Vector3.zero
        r.AssemblyAngularVelocity=Vector3.zero
        if r.Anchored then r.Anchored=false end
    end
end

function finishJarvisKillSafety()
    getgenv().JARVIS_KILL_STATE.busyUntil=0
    getgenv().JARVIS_KILL_STATE.label=""
    JARVIS_FOLLOW_RELEASE_UNTIL=0
    JARVIS_CLOAK_RELEASE_UNTIL=0
    mode="idle"
    targetPlayer=nil
    followCamPlayer=nil
    captureIdleHold()
end

function beginJarvisKillSafety(label, seconds)
    cancelEverythingForKill()
    getgenv().JARVIS_KILL_STATE.label=tostring(label or "kill")
    local duration=math.max(1,tonumber(seconds) or 3)
    getgenv().JARVIS_KILL_STATE.busyUntil=os.clock()+duration
    local deadline=getgenv().JARVIS_KILL_STATE.busyUntil
    task.delay(duration,function()
        -- Only the newest kill operation may release the exclusive lock.
        if getgenv().JARVIS_KILL_STATE.busyUntil==deadline and os.clock()>=deadline then
            finishJarvisKillSafety()
        end
    end)
end

function killSafetyDuration(isTeam,count)
    if isTeam then return 8 end
    count=math.max(1,tonumber(count) or 1)
    return math.min(12,2.5+(count-1)*0.65)
end

-- ONLY canonical backend kill forms:
--   kill <username>
--   kill <username> <number>
--   kill team <guards|inmates|criminals> wl <auto protected names>
function handleJarvisKillCommand(cmd, rest)
    if tostring(cmd or ""):lower() ~= "kill" then
        return false
    end

    rest=tostring(rest or ""):gsub("^%s+",""):gsub("%s+$","")
    if rest=="" then
        voice("use kill <username>, kill <username> <number>, or k <team>.")
        return true
    end

    if not jarvisHasUsableGun() then
        voice("kill blocked: no gun.")
        return true
    end
    if jarvisKillBusy() then
        voice("busy: "..getgenv().JARVIS_KILL_STATE.label..". wait for it to finish.")
        return true
    end

    local signature=("kill "..rest):lower()
    if signature==getgenv().JARVIS_KILL_STATE.lastSignature and os.clock()-getgenv().JARVIS_KILL_STATE.lastAt<0.75 then
        voice("duplicate kill ignored.")
        return true
    end

    local teamText=rest:match("^[Tt][Ee][Aa][Mm]%s+(%S+)")
    if teamText then
        local team=normalizeKillTeamName(teamText)
        if not team then
            voice("team must be guards, inmates, or criminals.")
            return true
        end
        local wl=getJarvisCommandWhitelistNames()
        local command="kill team "..team
        if #wl>0 then
            command=command.." wl "..table.concat(wl,",")
        end
        getgenv().JARVIS_KILL_STATE.lastSignature=signature
        getgenv().JARVIS_KILL_STATE.lastAt=os.clock()
        beginJarvisKillSafety("kill team "..team,killSafetyDuration(true,1))
        if not otherCmd(command) then
            finishJarvisKillSafety()
            voice("kill command failed to send.")
        end
        return true
    end

    local targetText,countText=rest:match("^(.-)%s+(%d+)$")
    if not targetText then
        targetText=rest
        countText=nil
    end
    targetText=tostring(targetText or ""):gsub("^%s+",""):gsub("%s+$","")
    if targetText=="" then return true end

    local target=findPlayer(targetText)
    local targetKey=targetText:lower()
    if targetKey=="owner" or targetKey=="master" or targetKey=="me"
        or targetKey==masterLower
        or (target and target.Name:lower()==masterLower)
    then
        voice("permanent owner is protected; kill cancelled.")
        return true
    end
    if target and isWhitelistedPlayer(target) then
        voice(target.Name.." is protected.")
        return true
    end

    local resolved=target and target.Name or targetText
    local command="kill "..resolved
    local count=tonumber(countText)
    if count then
        count=math.max(1,math.min(25,math.floor(count)))
        command=command.." "..tostring(count)
    end
    getgenv().JARVIS_KILL_STATE.lastSignature=signature
    getgenv().JARVIS_KILL_STATE.lastAt=os.clock()
    beginJarvisKillSafety("kill "..resolved,killSafetyDuration(false,count))
    if not otherCmd(command) then
        getgenv().JARVIS_KILL_STATE.busyUntil=0
        voice("kill command failed to send.")
    end
    return true
end
function teamSelectorIncludesMaster(rest)
    rest = tostring(rest or ""):lower():gsub("^%s+", ""):gsub("%s+$", "")
    local teamName = rest:match("^team%s+(.+)$")
    if not teamName then
        return false
    end
    local master = getMaster()
    if not master or not master.Team then
        return false
    end
    local wanted = normalizeTeamName(teamName)
    local actual = normalizeTeamName(master.Team.Name)
    return wanted ~= "" and wanted == actual
end
function revokeOwnerAccess(fromName, reason, retaliate)
    if not fromName or fromName:lower() == masterLower then
        return false
    end
    local key = fromName:lower()
    extraOwners[key] = nil
    revokedOwners[key] = true
    ownerTeamStrikes[key] = nil
    local p = findPlayer(fromName)
    if p and targetPlayer == p then
        targetPlayer = getMaster()
        followCamPlayer = getMaster()
        followPosition = "center"
        formationType = "singlefile"
        mode = "follow"
        invisFollow = false
    end
    say("WARNING: " .. fromName .. " cannot target the permanent owner. Access revoked.")
    if retaliate ~= false then
        otherCmd("kill " .. fromName)
    end
    print("[JARVIS] OWNER ACCESS REVOKED:", fromName, reason or "blocked")
    return true
end
function blockMasterAttack(body, fromName)
    if fromName and fromName:lower() == masterLower then
        return false
    end
    local clean = tostring(body or "")
        :gsub("^%s+", "")
        :gsub("%s+$", "")
    if clean:sub(1, 1) == "."
        or clean:sub(1, 1) == ";"
    then
        clean = clean:sub(2)
    end
    local cmd, rest = clean:match("^(%S+)%s*(.*)$")
    cmd = (cmd or ""):lower()
    rest = rest or ""
    if not MASTER_BLOCKED_COMMANDS[cmd] then
        return false
    end
    if isMasterReference(rest) then
        return revokeOwnerAccess(
            fromName,
            cmd .. " permanent owner",
            true
        )
    end
    return false
end
HIDE_BLOCKED_COMMANDS = {
    follow = true, unfollow = true, loopfollow = true, unloopfollow = true,
    line = true, unline = true,
    left = true, right = true, center = true, centre = true, middle = true,
    formation = true, form = true,
    cheater = true, uncheater = true,
    orbit = true, unorbit = true, spiral = true, unspiral = true,
    guard = true, unguard = true,
    scout = true, unscout = true,
    patrol = true, unpatrol = true,
    surround = true, unsurround = true,
    assemble = true, regroup = true, disperse = true, ["return"] = true,
    protect = true, unprotect = true,
    invis = true, invisible = true, vis = true, uninvis = true, visible = true,
    invisfollow = true, cloakfollow = true,
    fly = true, unfly = true,
    speed = true, autospeed = true,
    freeze = true, unfreeze = true, thaw = true,
    recall = true, face = true, front = true, behind = true, above = true, below = true,
    followdist = true, sidedist = true, cloakdepth = true, vertical = true,
    recover = true, unstuck = true, park = true, unpark = true, resetoffsets = true,
}
function enterHideLock()
    hiddenLock = true
    mode = "idle"
    orbiting = false
    dancing = false
    protecting = false
    guardMode = false
    invisFollow = false
    orbitTarget = nil
    targetPlayer = nil
    followCamPlayer = nil
    invisPosition = nil
    groundLock = false
    local root = myRoot()
    local hum = myHum()
    if hum then
        hum.Sit = false
    end
    if root then
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
        root.CFrame = getgenv().JARVIS_SQUAD.frame(HIDE_CFRAME)
    end
end
function leaveHideLock()
    hiddenLock = false
    mode = "idle"
    targetPlayer = nil
    followCamPlayer = nil
    invisPosition = nil
    orbiting = false
    dancing = false
    protecting = false
    guardMode = false
    groundLock = false
end
local function getHostUserId()
    if HOST_NAME == "" then return nil end
    local ok, id = pcall(function()
        return Players:GetUserIdFromNameAsync(HOST_NAME)
    end)
    return ok and id or nil
end

local function callHostServer()
    if IS_LEADER then return false, "Host cannot call itself." end
    local hostId = getHostUserId()
    if not hostId then return false, "Host not found." end
    local ok, _, _, placeId, jobId = pcall(function()
        return TeleportService:GetPlayerPlaceInstanceAsync(hostId)
    end)
    if not ok or type(placeId) ~= "number" or type(jobId) ~= "string" or jobId == "" then
        return false, "Host server could not be found."
    end
    if placeId == game.PlaceId and jobId == game.JobId then
        return true, "Already with Host."
    end
    savePersistentState(true)
    local teleported = pcall(function()
        TeleportService:TeleportToPlaceInstance(placeId, jobId, bot)
    end)
    return teleported, teleported and "Joining Host..." or "Teleport failed."
end

function handle(body, fromName)
    if IS_LEADER then
        return
    end
    body = tostring(body or "")
    body = body:gsub(
        "^%s+",
        ""
    )
    body = body:gsub(
        "%s+$",
        ""
    )
    body = normalizeCommandBody(body)
    if body == "" then
        return
    end
    if tostring(body):lower() == "call" then
        if tostring(fromName or ""):lower() ~= masterLower then
            voice("access denied.")
            return
        end
        local ok, message = callHostServer()
        voice(message)
        return
    end
    sessionCommandCount =
        sessionCommandCount + 1
    lastCommand = body
    do
        local preCmd, preRest = tostring(body or ""):match("^(%S+)%s*(.*)$")
        preCmd = (preCmd or ""):gsub("^[%.;]", ""):lower()
        preRest = preRest or ""
    end
    if blockMasterAttack(body, fromName) then
        return
    end
    if body:sub(1, 1) == "."
        or body:sub(1, 1) == ";"
    then
        local rawClean = body:sub(2)
        local rawCmd, rawRest = rawClean:match("^(%S+)%s*(.*)$")
        rawCmd = (rawCmd or ""):lower()
        rawRest = rawRest or ""
        if rawCmd == "kill" then
            handleJarvisKillCommand("kill",rawRest)
            return
        end
        if jarvisKillBusy() then
            voice("busy: "..getgenv().JARVIS_KILL_STATE.label..". command ignored.")
            return
        end
        otherCmd(body)
        return
    end
    local cmd, rest =
        body:match(
            "^(%S+)%s*(.*)$"
        )
    cmd = string.lower(
        cmd or ""
    )
    rest = rest or ""

    -- Do not allow another behavior/admin command to collide with an active kill.
    -- Read-only status/help commands remain available.
    if jarvisKillBusy() then
        local safeDuringKill={
            status=true,report=true,cmds=true,help=true,commands=true,cmdlist=true,
            where=true,coords=true,who=true,owners=true,panic=true,
        }
        if not safeDuringKill[cmd] then
            voice("busy: "..getgenv().JARVIS_KILL_STATE.label..". command ignored.")
            return
        end
    end

    -- 'bot 1 / 'bot 2 / 'bot 3 / 'bot 4
    -- Select how many bot slots participate. Every client sees the owner's
    -- same chat command, so they converge on the same count without a server script.
    if cmd == "bot" then
        if tostring(fromName or ""):lower() ~= masterLower then
            voice("bot count access denied.")
            return
        end
        local n = tonumber(tostring(rest or ""):match("^%s*(%d+)%s*$"))
        if not n or n < 1 or n > 4 then
            voice("use 'bot 1, 'bot 2, 'bot 3, or 'bot 4.")
            return
        end
        getgenv().JARVIS_ACTIVE_BOT_COUNT = n

        local squad = getgenv().JARVIS_SQUAD
        if squad then
            squad.dirty = true
            if squad.units then squad.units() end
        end

        -- If this bot is outside the selected count, stop its current active
        -- movement/protection modes immediately.
        if not jarvisThisBotIsActive() then
            protecting = false
            protectedPlayer = nil
            orbiting = false
            guardMode = false
            dancing = false
            targetPlayer = nil
            followCamPlayer = nil
            mode = "idle"
            if setFly then setFly(false) end
        end

        local myIndex = 1
        if squad and squad.index then
            myIndex = tonumber((squad.index())) or 1
        end
        if myIndex == 1 then
            voice("active bots set to " .. tostring(n) .. ".")
        end
        return
    end

    -- Bots outside the chosen 1/2/3/4 count ignore normal owner commands.
    if not jarvisThisBotIsActive() then
        return
    end

    if getgenv().JARVIS_SQUAD.command(cmd, rest, fromName) then return end
    local speaker =
        findPlayer(fromName)
    if getgenv().JARVIS_ACTION_COMMAND
        and getgenv().JARVIS_ACTION_COMMAND(cmd, rest)
    then
        return
    end

    if cmd == "kx" then
        if tostring(fromName or ""):lower() ~= masterLower then
            voice("kx access denied.")
            return
        end
        local setting = tostring(rest or ""):lower()
            :gsub("^%s+", "")
            :gsub("%s+$", "")
        if setting == "off"
            or setting == "0"
            or setting == "false"
        then
            JARVIS_KX_ADMIN_ENABLED = false
            voice("kx off. admin commands disabled.")
        elseif setting == "on"
            or setting == "1"
            or setting == "true"
        then
            JARVIS_KX_ADMIN_ENABLED = true
            voice("kx on. admin commands enabled.")
        else
            voice(
                "kx is "
                .. (JARVIS_KX_ADMIN_ENABLED and "on." or "off.")
                .. " use kx on or kx off."
            )
        end
        return
    end
    if cmd == "hide" then
        enterHideLock()
        voice("hide lock active. movement commands disabled.")
        return
    end
    if cmd == "unhide" then
        leaveHideLock()
        voice("hide lock released. movement commands restored.")
        return
    end
    if hiddenLock
        and HIDE_BLOCKED_COMMANDS[cmd]
        and tostring(fromName or ""):lower() ~= masterLower
    then
        voice("access denied. JARVIS is hidden. use eagle unhide first.")
        return
    end
    if cmd == "panic" then
        if jarvisKillBusy() then finishJarvisKillSafety() end
        stopMove()
        frozen = false
        freezeCFrame = nil
        hiddenLock = false
        invisFollow = false
        invisPosition = nil
        protecting = false
        protectedPlayer = nil
        guardMode = false
        orbiting = false
        dancing = false
        punchOn = false
        spinning = false
        disconnectProtection()
        restoreOwnCam()
        setFly(false)
        pcall(function() otherCmd("antifling on") end)
        voice("emergency reset complete.")
        return
    end
    if cmd == "freeze" then
        local root = myRoot()
        if root then
            freezeCFrame = root.CFrame
            frozen = true
            root.AssemblyLinearVelocity = Vector3.zero
            root.AssemblyAngularVelocity = Vector3.zero
            voice("position frozen.")
        end
        return
    end
    if cmd == "unfreeze" or cmd == "thaw" then
        frozen = false
        freezeCFrame = nil
        voice("position released.")
        return
    end
    if cmd == "mark" then
        local root = myRoot()
        if not root then return end
        local markName = firstArg(rest):lower()
        if markName == "" then markName = "default" end
        savedMarks[markName] = root.CFrame
        voice("saved mark " .. markName .. ".")
        return
    end
    if cmd == "recall" then
        local markName = firstArg(rest):lower()
        if markName == "" then markName = "default" end
        local cf = savedMarks[markName]
        local root = myRoot()
        if not cf then
            voice("mark not found: " .. markName)
            return
        end
        if root then
            stopMove()
            setFly(true)
            root.AssemblyLinearVelocity = Vector3.zero
            root.AssemblyAngularVelocity = Vector3.zero
            root.CFrame = cf
            voice("recalled " .. markName .. ".")
        end
        return
    end
    if cmd == "marks" then
        local names = {}
        for name in pairs(savedMarks) do table.insert(names, name) end
        table.sort(names)
        voice(#names > 0 and ("marks: " .. table.concat(names, ", ")) or "no saved marks.")
        return
    end
    if cmd == "target" then
        local p = findPlayer(firstArg(rest)) or speaker
        if not p then
            voice("target not found.")
            return
        end
        if isWhitelistedPlayer and isWhitelistedPlayer(p) then
            voice(p.Name .. " is protected.")
            return
        end

        -- TARGET uses the canonical repeated-kill path and safety checks.
        if not handleJarvisKillCommand("kill",p.Name.." 25") then return end

        -- Keep the existing priority-target tracking as well.
        setJarvisPriorityTarget(p)
        releaseTrueIdleAnchor()
        setFly(true)

        -- If bot + target are currently teammates, also PA/follow them.
        if jarvisSameTeamForSmartCommand(bot, p) then
            jarvisSmartPA(p)
            voice("target " .. p.Name .. ": kill 25 + PA.")
        else
            voice("target " .. p.Name .. ": kill 25.")
        end
        return
    end
    if cmd == "distance" or cmd == "dist" then
        local p = findPlayer(firstArg(rest)) or activeTarget()
        local root = myRoot()
        local tr = rootOf(p)
        if root and tr and p then
            local d = (root.Position - tr.Position).Magnitude
            voice(string.format("%s distance %.1f studs.", p.Name, d))
        else
            voice("distance unavailable.")
        end
        return
    end
    if cmd == "face" then
        local p = findPlayer(firstArg(rest)) or activeTarget() or speaker
        local root = myRoot()
        local tr = rootOf(p)
        if root and tr then
            root.CFrame = CFrame.lookAt(root.Position, Vector3.new(tr.Position.X, root.Position.Y, tr.Position.Z))
            voice("facing " .. p.Name .. ".")
        end
        return
    end
    if cmd == "followdist" then
        local n = tonumber(firstArg(rest))
        if n then followDistance = math.clamp(n, 1, 50) end
        voice("follow distance " .. tostring(followDistance) .. ".")
        return
    end
    if cmd == "sidedist" then
        local n = tonumber(firstArg(rest))
        if n then sideDistance = math.clamp(n, 0, 50) end
        voice("side distance " .. tostring(sideDistance) .. ".")
        return
    end
    if cmd == "cloakdepth" then
        local n = tonumber(firstArg(rest))
        if n then cloakDepth = math.clamp(n, 2, 30) end
        voice("cloak depth " .. tostring(cloakDepth) .. ".")
        return
    end
    if cmd == "vertical" or cmd == "above" or cmd == "below" then
        local n
        if cmd == "above" then
            n = tonumber(firstArg(rest)) or 5
            n = math.abs(n)
        elseif cmd == "below" then
            n = -(math.abs(tonumber(firstArg(rest)) or 5))
        else
            n = tonumber(firstArg(rest))
        end
        if n then followVerticalOffset = math.clamp(n, -30, 30) end
        voice("follow vertical " .. tostring(followVerticalOffset) .. ".")
        return
    end
    if cmd == "selfcheck" or cmd == "diag" or cmd == "diagnostics" then
        local root = myRoot()
        local hum = myHum()
        local target = activeTarget()
        local tr = rootOf(target)
        local dist = (root and tr) and (root.Position - tr.Position).Magnitude or -1
        local report = string.format(
            "check mode=%s target=%s dist=%.1f fly=%s noclip=%s hidden=%s frozen=%s protect=%s speed=%d",
            tostring(mode), target and target.Name or "none", dist,
            tostring(flying), tostring(noclipOn), tostring(hiddenLock), tostring(frozen),
            tostring(protecting), math.floor(flySpeed)
        )
        print("[JARVIS SELF-CHECK] " .. report)
        voice(report)
        return
    end
    if cmd == "nearest" or cmd == "near" then
        local root = myRoot()
        if not root then return end
        local best, bestDist = nil, math.huge
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= bot then
                local r = rootOf(p)
                if r then
                    local d = (r.Position - root.Position).Magnitude
                    if d < bestDist then
                        best, bestDist = p, d
                    end
                end
            end
        end
        if best then
            targetPlayer = best
            followCamPlayer = best
            voice(string.format("nearest target %s at %.1f studs.", best.Name, bestDist))
        else
            voice("no nearby target found.")
        end
        return
    end
    if cmd == "untarget" then
        targetPlayer = getMaster()
        followCamPlayer = targetPlayer
        voice("target returned to permanent owner.")
        return
    end
    if cmd == "where" or cmd == "coords" then
        local root = myRoot()
        if root then
            local p = root.Position
            voice(string.format("position X %.1f Y %.1f Z %.1f", p.X, p.Y, p.Z))
            print(string.format("[JARVIS COORDS] Vector3.new(%.6f, %.6f, %.6f)", p.X, p.Y, p.Z))
        end
        return
    end
    if cmd == "recover" or cmd == "unstuck" then
        local root = myRoot()
        local hum = myHum()
        if root then
            root.AssemblyLinearVelocity = Vector3.zero
            root.AssemblyAngularVelocity = Vector3.zero
        end
        if hum then
            hum.Sit = false
            hum:ChangeState(Enum.HumanoidStateType.GettingUp)
        end
        stuckTimer = 0
        lastPosition = root and root.Position or nil
        setFly(true)
        voice("movement recovery complete.")
        return
    end
    if cmd == "resetoffsets" then
        followDistance = FOLLOW_DIST
        sideDistance = SIDE
        followVerticalOffset = 0
        cloakDepth = INVIS_DEPTH
        voice("movement offsets reset to defaults.")
        return
    end
    if cmd == "settings" then
        voice(string.format(
            "settings fd %.1f side %.1f vertical %.1f cloak %.1f speed %d chat %.2fs saved=%s",
            followDistance, sideDistance, followVerticalOffset, cloakDepth,
            math.floor(flySpeed + 0.5), adaptiveChatDelay,
            tostring(persistentCanUse())
        ))
        return
    end
    if cmd == "cmdspeed" then
        voice(string.format(
            "adaptive command-chat interval %.2fs, queued %d, sent %d.",
            adaptiveChatDelay, #sayQ, chatMessagesSent
        ))
        return
    end
    if cmd == "park" then
        local root = myRoot()
        if root then
            frozen = true
            freezeCFrame = root.CFrame
            mode = "idle"
            orbiting = false
            dancing = false
            guardMode = false
            voice("parked in place.")
        end
        return
    end
    if cmd == "unpark" then
        frozen = false
        freezeCFrame = nil
        voice("park released.")
        return
    end
    if cmd == "say" then
        voice(rest)
        return
    end
    if cmd == "shut" then
        getgenv().JARVIS_SQUAD.setMuted(true)
        return
    end
    if cmd == "unshut" then
        getgenv().JARVIS_SQUAD.setMuted(false)
        voice("JARVIS voice restored.")
        return
    end
    if cmd == "slot" then
        local who, requested = rest:match("^(%S+)%s+(%d+)$")
        local player = who and findPlayer(who)
        if player and requested and player.Name:lower() ~= masterLower then
            local squad = getgenv().JARVIS_SQUAD
            local config = getgenv().JARVIS_SQUAD_CONFIG
            local slot = math.clamp(tonumber(requested), 1, MAX_SLOTS)
            config.names[player.Name:lower()] = true
            config.slots[player.Name:lower()] = slot
            if player == bot then manualSlot = slot end
            squad.dirty = true
            refreshSlot()
            savePersistentState(true)
            squad.hello()
            voice("slot preference " .. player.Name .. " = " .. tostring(slot))
        end
        return
    end
    if cmd == "slots" then
        manualSlot = nil
        table.clear(getgenv().JARVIS_SQUAD_CONFIG.slots)
        for _, peer in pairs(getgenv().JARVIS_SQUAD.peers) do peer.slot = 0 end
        refreshSlot()
        savePersistentState(true)
        getgenv().JARVIS_SQUAD.hello()
        voice("automatic slots restored.")
        return
    end
    if cmd == "who"
        or cmd == "hello"
        or cmd == "hi"
    then
        voice(
            "I am "
            .. getJarvisName()
            .. "."
        )
        return
    end
    if cmd == "nosit" or cmd == "stand" then
        setNoSit(true)
        local hum = myHum()
        if hum then
            hum.Sit = false
            hum:ChangeState(Enum.HumanoidStateType.GettingUp)
        end
        voice("sitting disabled.")
        return
    end
    if cmd == "sit" then
        local arg = firstArg(rest):lower()
        if arg == "on" then
            setNoSit(false)
            voice("sitting allowed.")
        elseif arg == "off" then
            setNoSit(true)
            local hum = myHum()
            if hum then
                hum.Sit = false
                hum:ChangeState(Enum.HumanoidStateType.GettingUp)
            end
            voice("sitting disabled.")
        else
            voice(noSit and "sitting is off. use eagle sit on." or "sitting is on. use eagle sit off.")
        end
        return
    end
    if cmd == "unpunchaura" or cmd == "unpa" then
        JARVIS_PUNCHAURA_ACTIVE = false
        JARVIS_PUNCHAURA_TARGET = nil
        table.clear(JARVIS_DYNAMIC_WHITELIST)
        voice("punchaura disabled.")
        return
    end
    if cmd == "protect"
        or cmd == "fullprotect"
        or cmd == "fprotect"
        or cmd == "halfprotect"
        or cmd == "limitedprotect"
        or cmd == "lprotect"
        or cmd == "iprotect"
        or cmd == "invisprotect"
    then
        local requestedName = tostring(rest or ""):gsub("^%s+", ""):gsub("%s+$", "")
        local p = requestedName ~= "" and findPlayer(requestedName) or nil
        p = p or speaker or getMaster()
        if not p then
            voice("protect target not found.")
            return
        end

        if cmd == "fullprotect" or cmd == "fprotect" then
            JARVIS_PROTECT_MODE = "full"
        elseif cmd == "iprotect" or cmd == "invisprotect" then
            JARVIS_PROTECT_MODE = "invisfull"
        elseif cmd == "limitedprotect" or cmd == "lprotect" then
            JARVIS_PROTECT_MODE = "limited"
        else
            JARVIS_PROTECT_MODE = "half"
        end

        JARVIS_PUNCHAURA_ACTIVE = false
        JARVIS_PUNCHAURA_TARGET = nil
        table.clear(JARVIS_DYNAMIC_WHITELIST)
        protecting = true
        protectedPlayer = p
        targetPlayer = p
        frozen = false
        freezeCFrame = nil
        hiddenLock = false
        orbiting = false
        dancing = false
        guardMode = false
        JARVIS_PROTECT_ORBIT_ANGLE = 0
        table.clear(JARVIS_PROTECT_LAST_ACTION)
        JARVIS_FULLPROTECT_LAST_SCAN = 0
        attachProtectDamageWatcher(p)

        -- FULL: orbit + PA/melee defense + kill every visible hostile.
        -- HALF: orbit + PA/melee defense + exact damage retaliation.
        -- LIMITED: stay exactly where you are; only exact shootback/antipunch.
        if JARVIS_PROTECT_MODE == "limited" then
            mode = "idle"
            flying = false
            groundLock = true
            followCamPlayer = nil
            camLocked = false
            disconnectProtection()
            voice("limited protect on " .. p.Name .. ". stationary exact retaliation only.")
        else
            followCamPlayer = p
            mode = "idle"
            invisPosition = nil
            groundLock = false
            refreshSlot()
            releaseTrueIdleAnchor()
            setFly(true)
            disconnectProtection()
            lockCam(p)
            if JARVIS_PROTECT_MODE == "full" then
                voice("full protect on " .. p.Name .. ". orbit, aura, sight clear, and exact retaliation active.")
            else
                voice("half protect on " .. p.Name .. ". orbit, punch aura, and exact retaliation active.")
            end
        end
        return
    end
    if cmd == "unprotect" then
        protecting = false
        JARVIS_PROTECT_MODE = "half"
        disconnectProtectDamageWatcher()
        protectedPlayer = nil
        targetPlayer = nil
        setFly(false)
        table.clear(JARVIS_PROTECT_LAST_ACTION)
        disconnectProtection()
        voice("protection disabled.")
        return
    end
    if cmd == "invis"
        or cmd == "invisible"
    then
        local requestedName = firstArg(rest)
        local p = nil
        if requestedName ~= "" then
            p = findPlayer(requestedName)
        end
        p = p or speaker or activeTarget() or getMaster()
        if not p then
            voice("target not found.")
            return
        end
        otherCmd("invis")
        invisFollow = true
        invisPosition = nil
        resetInvisibleFloorLatch(p)
        protecting = false
        orbiting = false
        dancing = false
        guardMode = false
        groundLock = false
        targetPlayer = p
        followCamPlayer = p
        mode = "loopfollow"
        setFly(true)
        lockCam(p)
        voice("cloak active under " .. p.Name .. ".")
        return
    end
    if cmd == "invisfollow"
        or cmd == "cloakfollow"
    then
        local name =
            firstArg(rest)
        local p
        if name ~= "" then
            p = findPlayer(name)
        else
            p = speaker or activeTarget() or getMaster()
        end
        if not p then
            voice("target not found.")
            return
        end
        otherCmd("invis")
        invisFollow = true
        invisPosition = nil
        resetInvisibleFloorLatch(p)
        groundLock = false
        targetPlayer = p
        followCamPlayer = p
        mode = "loopfollow"
        setFly(true)
        lockCam(p)
        voice(
            "cloak follow "
            .. p.Name
        )
        return
    end
    if cmd == "vis"
        or cmd == "uninvis"
        or cmd == "visible"
    then
        invisFollow = false
        invisPosition = nil
        resetInvisibleFloorLatch(nil)
        removeCloakYHold()
        groundLock = not (mode == "follow" or mode == "loopfollow")
        otherCmd("vis")
        voice(
            "cloak disabled."
        )
        return
    end
    if cmd == "punchaura" or cmd == "pa" then
        local requestedName = firstArg(rest)
        if requestedName == "" then
            voice("punchaura target required.")
            return
        end
        local p = findPlayer(requestedName)
        if not p then
            voice("punchaura target not found.")
            return
        end
        protecting = false
        protectedPlayer = nil
        JARVIS_PUNCHAURA_ACTIVE = true
        JARVIS_PUNCHAURA_TARGET = p
        targetPlayer = p
        followCamPlayer = p
        mode = "idle"
        orbiting = false
        dancing = false
        guardMode = false
        invisFollow = false
        invisPosition = nil
        groundLock = false
        frozen = false
        freezeCFrame = nil
        hiddenLock = false
        refreshPunchauraNearbyWhitelist(p)
        refreshSlot()
        releaseTrueIdleAnchor()
        setFly(true)
        lockCam(p)
        voice(
            "punchaura tracking "
            .. p.Name
            .. ". predictive front follow active."
        )
        return
    end
    if cmd == "share1" or cmd == "share2" or cmd == "share" then
        if fromName:lower() ~= masterLower then
            voice("access denied.")
            return
        end

        local level = (cmd == "share2") and 2 or 1
        local p = findPlayer(firstArg(rest))
        if p then
            local key = p.Name:lower()
            extraOwners[key] = true
            sharedAccessLevel[key] = level
            revokedOwners[key] = nil
            voice("shared access " .. tostring(level) .. " complete: " .. p.Name)
            refreshSlot()
            savePersistentState(true)
        else
            voice("shared access " .. tostring(level) .. " incomplete: player not found.")
        end
        return
    end
    if cmd == "unshare" then
        if isMasterReference(rest) and fromName:lower() ~= masterLower then
            punishOwnerViolation(fromName, "unshare permanent owner")
            return
        end
        if fromName:lower() ~= masterLower then
            voice("only the permanent owner can unshare access.")
            return
        end
        local name =
            firstArg(rest)
        local p =
            findPlayer(name)
        if p then
            extraOwners[
                p.Name:lower()
            ] = nil
            sharedAccessLevel[p.Name:lower()] = nil
        else
            extraOwners[
                name:lower()
            ] = nil
            sharedAccessLevel[name:lower()] = nil
        end
        refreshSlot()
        savePersistentState(true)
        return
    end
    if cmd == "owners" then
        local owners = {
            MASTER_NAME
        }
        for name in pairs(
            extraOwners
        ) do
            table.insert(
                owners,
                name
            )
        end
        voice(
            "owners: "
            .. table.concat(
                owners,
                ", "
            )
        )
        return
    end
    if cmd == "speed" then
        local value =
            tonumber(
                firstArg(rest)
            )
        if not value then
            voice(
                "speed "
                .. tostring(
                    math.floor(flySpeed)
                )
            )
            return
        end
        flySpeed =
            math.clamp(
                value,
                MIN_SPEED,
                MAX_SPEED
            )
        manualSpeedOverride = true
        voice(
            "manual speed "
            .. tostring(
                math.floor(flySpeed)
            )
        )
        return
    end
    if cmd == "autospeed" then
        manualSpeedOverride = false
        updateAutomaticSpeed()
        voice(
            "automatic speed "
            .. tostring(
                math.floor(flySpeed)
            )
        )
        return
    end
    if cmd == "formation"
        or cmd == "form"
    then
        setFormation(
            firstArg(rest)
        )
        return
    end
    if cmd == "cheater" then
        if tostring(fromName or ""):lower() ~= masterLower then return end
        local p = findPlayer(firstArg(rest))
        if not p or p == bot or isAlly(p) then
            voice("choose a non-allied player.")
            return
        end
        cheaterTarget = p
        cheaterActive = true
        cheaterNextLine = os.clock() + math.random(8, 12)
        cheaterLineIndex = (getgenv().JARVIS_SQUAD.index() or 1) - 1
        orbitTarget = p
        orbitRadius = 8
        orbiting = true
        protecting = false
        dancing = false
        JARVIS_PUNCHAURA_ACTIVE = false
        JARVIS_PUNCHAURA_TARGET = nil
        mode = "orbit"
        setFly(true)
        return
    end
    if cmd == "uncheater" then
        cheaterActive = false
        cheaterTarget = nil
        if cheaterGui then cheaterGui.Enabled = false end
        orbiting = false
        orbitTarget = nil
        returnToMaster()
        return
    end
    if cmd == "orbit" then
        local name =
            firstArg(rest)
        local p =
            name ~= ""
            and findPlayer(name)
            or getMaster()
        if not p then
            voice("orbit target not found.")
            return
        end
        local radius =
            tonumber(
                secondArg(rest)
            )
        if radius then
            orbitRadius =
                math.clamp(
                    radius,
                    MIN_ORBIT_RADIUS,
                    MAX_ORBIT_RADIUS
                )
        end
        orbitTarget = p
        orbitAngle = 0
        orbiting = true
        dancing = false
        protecting = false
        targetPlayer = p
        mode = "orbit"
        setFly(true)
        lockCam(p)
        voice(
            "orbiting "
            .. p.Name
        )
        return
    end
    if cmd == "unorbit" then
        orbiting = false
        orbitTarget = nil
        returnToMaster()
        voice("orbit disabled.")
        return
    end
    if cmd == "spiral" then
        local p =
            findPlayer(
                firstArg(rest)
            )
            or getMaster()
        if not p then
            voice("spiral target not found.")
            return
        end
        orbitTarget = p
        orbitAngle = 0
        orbitRadius =
            DEFAULT_ORBIT_RADIUS
        orbiting = true
        dancing = true
        protecting = false
        targetPlayer = p
        mode = "orbit"
        setFly(true)
        lockCam(p)
        voice(
            "spiral protocol active."
        )
        return
    end
    if cmd == "unspiral" then
        orbiting = false
        dancing = false
        returnToMaster()
        return
    end
    if cmd == "dance" then
        local arg = firstArg(rest):lower()
        local danceNumber = tonumber(arg)
        if danceNumber then
            danceNumber = math.clamp(math.floor(danceNumber), 1, 3)
            if getgenv().JARVIS_ACTION_COMMAND then
                getgenv().JARVIS_ACTION_COMMAND("dance", tostring(danceNumber))
            end
            return
        end
        local p =
            findPlayer(arg)
            or getMaster()
        if not p then
            voice("dance target not found.")
            return
        end
        orbitTarget = p
        orbitRadius = DEFAULT_ORBIT_RADIUS
        dancing = true
        orbiting = true
        danceTime = 0
        protecting = false
        mode = "dance"
        targetPlayer = p
        setFly(true)
        voice("dance protocol engaged.")
        return
    end
    if cmd == "undance" then
        if getgenv().JARVIS_ACTION_COMMAND then
            getgenv().JARVIS_ACTION_COMMAND("undance", "")
        end
        return
    end
    if cmd == "cheer" or cmd == "laugh" or cmd == "point" then
        say("/e " .. cmd)
        return
    end
    if cmd == "wave" then
        local root = myRoot()
        if root then
            local base =
                root.CFrame
            task.spawn(function()
                for i = 1, 6 do
                    if jarvisKillBusy() then break end
                    if not root.Parent then
                        break
                    end
                    root.CFrame =
                        base
                        * CFrame.new(
                            math.sin(i)
                                * 1.5,
                            0,
                            0
                        )
                    task.wait(0.12)
                end
            end)
        end
        voice("hello, commander.")
        return
    end
    if cmd == "salute" then
        local root = myRoot()
        if root then
            local base =
                root.CFrame
            task.spawn(function()
                root.CFrame =
                    base
                    * CFrame.Angles(
                        0,
                        0,
                        math.rad(-25)
                    )
                task.wait(0.5)
                if root.Parent then
                    root.CFrame = base
                end
            end)
        end
        voice("at your service.")
        return
    end
    if cmd == "bounce" then
        local root = myRoot()
        if root then
            local base =
                root.Position
            task.spawn(function()
                for i = 1, 6 do
                    if jarvisKillBusy() then break end
                    if not root.Parent then
                        break
                    end
                    local offset =
                        math.sin(
                            (i / 6)
                            * math.pi
                        ) * 4
                    root.CFrame =
                        CFrame.new(
                            base
                            + Vector3.new(
                                0,
                                offset,
                                0
                            )
                        )
                    task.wait(0.08)
                end
            end)
        end
        return
    end
    if cmd == "guard"
        or cmd == "surround"
    then
        guardMode = true
        protecting = false
        targetPlayer = getMaster()
        followCamPlayer = getMaster()
        mode = "guard"
        setFly(true)
        lockCam(getMaster())
        voice(
            "guard formation deployed."
        )
        return
    end
    if cmd == "unguard"
        or cmd == "unsurround"
    then
        guardMode = false
        returnToMaster()
        voice("guard formation dismissed.")
        return
    end
    if cmd == "scout" then
        scoutOrigin = nil
        scoutReturning = false
        mode = "scout"
        protecting = false
        targetPlayer = getMaster()
        setFly(true)
        voice(
            "scouting ahead."
        )
        return
    end
    if cmd == "unscout" then
        scoutReturning = true
        returnToMaster()
        voice("scout returning.")
        return
    end
    if cmd == "patrol" then
        patrolOrigin = nil
        patrolAngle = 0
        mode = "patrol"
        protecting = false
        setFly(true)
        voice(
            "patrol route active."
        )
        return
    end
    if cmd == "unpatrol" then
        returnToMaster()
        voice("patrol complete.")
        return
    end
    if cmd == "assemble"
        or cmd == "regroup"
        or cmd == "return"
    then
        formationType = "dynamic"
        orbiting = false
        dancing = false
        guardMode = false
        protecting = false
        invisFollow = false
        invisPosition = nil
        targetPlayer = getMaster()
        followCamPlayer = getMaster()
        mode = "follow"
        groundLock = true
        setFly(true)
        lockCam(getMaster())
        voice(
            "squad assembled."
        )
        return
    end
    if cmd == "disperse" then
        local root = myRoot()
        if root then
            local index =
                getUnitIndex()
            local angle =
                index * 1.7
            local masterRoot =
                rootOf(getMaster())
            if masterRoot then
                local pos =
                    masterRoot.Position
                    + Vector3.new(
                        math.cos(angle)
                            * 25,
                        0,
                        math.sin(angle)
                            * 25
                    )
                mode = "follow"
                targetPlayer = getMaster()
                setFly(true)
                task.spawn(function()
                    flyStep(
                        root,
                        pos,
                        1,
                        true
                    )
                end)
            end
        end
        voice("squad dispersed.")
        return
    end
    if cmd == "halt" then
        mode = "idle"
        orbiting = false
        dancing = false
        protecting = false
        guardMode = false
        targetPlayer = nil
        local root = myRoot()
        if root then
            invisPosition = root.Position
        end
        voice("halt.")
        return
    end
    if cmd == "follow" then
        local requestedName =
            firstArg(rest)
        local p
        if requestedName ~= "" then
            p =
                findPlayer(
                    requestedName
                )
            if not p then
                voice(
                    "player not found: "
                    .. requestedName
                )
                return
            end
        else
            p = speaker or getMaster()
            if not p then
                voice("follow target not found.")
                return
            end
        end
        protecting = false
        orbiting = false
        dancing = false
        guardMode = false
        targetPlayer = p
        followCamPlayer = p
        followPosition = "center"
        mode = "follow"
        groundLock = false
        setFly(true)
        lockCam(p)
        voice(
            "following "
            .. p.Name
        )
        return
    end
    if cmd == "left" or cmd == "right"
        or cmd == "center" or cmd == "centre" or cmd == "middle"
        or cmd == "front" or cmd == "behind"
    then
        local p = activeTarget() or speaker or getMaster()
        if not p then
            voice("follow target not found.")
            return
        end
        if cmd == "centre" or cmd == "middle" then
            followPosition = "center"
        else
            followPosition = cmd
        end
        targetPlayer = p
        followCamPlayer = p
        mode = "follow"
        JARVIS_IDLE_HOLD_CFRAME = nil
        protecting = false
        orbiting = false
        dancing = false
        guardMode = false
        groundLock = not invisFollow
        setFly(true)
        lockCam(p)
        voice("following " .. p.Name .. " " .. followPosition .. ".")
        return
    end
    if cmd == "unfollow"
        or cmd == "unline"
        or cmd == "unloopfollow"
    then
        stopMove()
        voice("halted.")
        return
    end
    if cmd == "loopfollow" then
        local requestedName =
            firstArg(rest)
        local p
        if requestedName ~= "" then
            p =
                findPlayer(
                    requestedName
                )
            if not p then
                voice(
                    "player not found: "
                    .. requestedName
                )
                return
            end
        else
            p = speaker or getMaster()
            if not p then
                voice("follow target not found.")
                return
            end
        end
        protecting = false
        orbiting = false
        dancing = false
        targetPlayer = p
        followCamPlayer = p
        followPosition = "center"
        mode = "loopfollow"
        JARVIS_IDLE_HOLD_CFRAME = nil
        groundLock = false
        setFly(true)
        lockCam(p)
        voice(
            "continuous follow "
            .. p.Name
        )
        return
    end
    if cmd == "line" then
        formationType = "singlefile"
        protecting = false
        orbiting = false
        dancing = false
        guardMode = false
        mode = "line"
        if not invisFollow then
            groundLock = true
        end
        targetPlayer = getMaster()
        setFly(true)
        lockCam(getMaster())
        voice(
            "formation line. "
            .. getJarvisName()
        )
        return
    end
    if cmd == "stop"
        or cmd == "idle"
    then
        stopMove()
        if invisFollow then
            local root = myRoot()
            if root then
                invisPosition =
                    root.Position
            end
        end
        setFly(false)
        restoreOwnCam()
        voice("idle.")
        return
    end
    if cmd == "fly" then
        setFly(true)
        return
    end
    if cmd == "unfly" then
        setFly(false)
        return
    end
    if cmd == "noclip" then
        setNoclipAdmin(true)
        voice("continuous noclip enabled.")
        return
    end
    if cmd == "clip" then
        setNoclipAdmin(false)
        voice("noclip disabled.")
        return
    end
    if cmd == "cam"
        or cmd == "view"
    then
        lockCam(
            findPlayer(
                firstArg(rest)
            )
            or speaker
            or activeTarget()
        )
        return
    end
    if cmd == "uncam"
        or cmd == "unview"
    then
        restoreOwnCam()
        return
    end
    if cmd == "reset"
        or cmd == "re"
    then
        setFly(false)
        local h = myHum()
        if h then
            h.Health = 0
        end
        return
    end
    if cmd == "rejoin"
        or cmd == "rj"
    then
        savePersistentState(true)
        pcall(function()
            TeleportService:
                TeleportToPlaceInstance(
                    game.PlaceId,
                    game.JobId,
                    bot
                )
        end)
        return
    end
    if cmd == "spin" then
        spinning = true
        camera.CameraType = Enum.CameraType.Custom
        local hum = myHum()
        if hum then
            camera.CameraSubject = hum
        end
        voice("spin on.")
        return
    end
    if cmd == "unspin" then
        spinning = false
        voice("spin off.")
        return
    end
    if cmd == "status"
        or cmd == "report"
    then
        local target =
            activeTarget()
        local zone =
            isInsidePrison()
        voice(
            string.format(
                "%s | mode=%s | slot=%d | target=%s | speed=%d | zone=%s | protect=%s | hide=%s | freeze=%s | fd=%.1f | cloak=%.1f",
                getJarvisName(),
                mode,
                mySlot,
                target
                    and target.Name
                    or "none",
                math.floor(flySpeed),
                zone
                    and "PRISON"
                    or "OUTSIDE",
                tostring(protecting),
                tostring(hiddenLock),
                tostring(frozen),
                followDistance,
                cloakDepth
            )
        )
        return
    end
    if cmd == "radio" then
        local text = rest
        if text == "" then
            voice(
                "radio online. "
                .. getJarvisName()
            )
        else
            voice(
                "["
                .. getJarvisName()
                .. "] "
                .. text
            )
        end
        return
    end
    if cmd == "personality"
        or cmd == "mood"
    then
        local mood =
            firstArg(rest):lower()
        if mood == ""
            or mood == "normal"
        then
            voice(
                "Personality: professional."
            )
        elseif mood == "funny" then
            voice(
                "Personality: mildly chaotic."
            )
        elseif mood == "serious" then
            voice(
                "Personality: tactical."
            )
        elseif mood == "goofy" then
            voice(
                "Personality: questionable."
            )
        else
            voice(
                "moods: normal, funny, serious, goofy."
            )
        end
        return
    end
    if cmd == "captain" then
        if mySlot == 1 then
            voice(
                "Captain JARVIS online."
            )
        else
            voice(
                "Captain is JARVIS-01."
            )
        end
        return
    end
    if cmd == "cmds"
        or cmd == "help"
        or cmd == "commands"
        or cmd == "cmdlist"
    then
        announceCmds(speaker)
        return
    end
    if handleJarvisKillCommand(cmd, rest) then
        return
    elseif cmd == "whitelist" or cmd == "wl" then
        local clean = tostring(rest or ""):gsub("^%s+", ""):gsub("%s+$", "")
        if clean == "" then
            local names = getWhitelistNames()
            if #names == 0 then
                voice("whitelist is empty.")
            else
                voice("whitelist: " .. table.concat(names, ", "))
            end
            return
        end
        local player = findPlayer(clean)
        if not player then
            voice("whitelist player not found.")
            return
        end
        setWhitelisted(player, true)
        voice(player.Name .. " whitelisted.")
        return
    end
    if cmd == "unwhitelist" or cmd == "unwl" then
        local clean = tostring(rest or ""):gsub("^%s+", ""):gsub("%s+$", "")
        local player = findPlayer(clean)
        if not player then
            local key = clean:lower()
            if key ~= "" and JARVIS_WHITELIST[key] then
                JARVIS_WHITELIST[key] = nil
                voice(clean .. " removed from whitelist.")
            else
                voice("whitelist player not found.")
            end
            return
        end
        setWhitelisted(player, false)
        voice(player.Name .. " removed from whitelist.")
        return
    end
    if cmd == "cmd" then
        if JARVIS_KX_ADMIN_ENABLED == false then
            voice("kx off. admin commands disabled.")
            return
        end
        local forwardedCmd, forwardedRest = tostring(rest or ""):match("^(%S+)%s*(.*)$")
        forwardedCmd = (forwardedCmd or ""):gsub("^[%.;]", ""):lower()
        forwardedRest = forwardedRest or ""
        if forwardedCmd == "kill"
            and isMasterReference(forwardedRest)
        then
            voice("permanent owner is protected; kill cancelled.")
            return
        end
        otherCmd(rest)
        return
    end
    if cmd == "ipa"
        or cmd == "invispunchaura"
    then
        local p = findPlayer(rest)
        if not p then
            voice("player not found.")
            return
        end
        if isJarvisOwnerPlayer
            and isJarvisOwnerPlayer(p)
        then
            voice("owner target blocked.")
            return
        end
        JARVIS_PUNCHAURA_ACTIVE = false
        JARVIS_PUNCHAURA_TARGET = nil
        JARVIS_IPA_TARGET = p
        JARVIS_IPA_ACTIVE = true
        frozen = false
        freezeCFrame = nil
        hiddenLock = false
        orbiting = false
        dancing = false
        protecting = false
        guardMode = false
        invisFollow = false
        invisPosition = nil
        groundLock = false
        mode = "idle"
        releaseTrueIdleAnchor()
        setFly(true)
        lockCam(p)
        voice("predictive aura on " .. p.Name)
        return
    end
    if cmd == "unipa" then
        stopJarvisIPA()
        voice("predictive aura off.")
        return
    end
    if cmd == "sb"
        or cmd == "shootback"
    then
        local setting = tostring(rest or ""):lower()
            :gsub("^%s+", "")
            :gsub("%s+$", "")
        if setting == "off"
            or setting == "false"
            or setting == "0"
        then
            JARVIS_SHOOTBACK_ENABLED = false
            voice("Eagle shootback off.")
        elseif setting == "on"
            or setting == "true"
            or setting == "1"
        then
            JARVIS_SHOOTBACK_ENABLED = true
            voice("Eagle shootback on.")
        else
            voice("use 'sb on or 'sb off.")
        end
        return
    end
    if cmd == "ap"
        or cmd == "antipunch"
    then
        local setting = tostring(rest or ""):lower()
            :gsub("^%s+", "")
            :gsub("%s+$", "")
        if setting == "off"
            or setting == "false"
            or setting == "0"
        then
            JARVIS_ANTIPUNCH_ENABLED = false
            clearJarvisAntiPunch()
            voice("Eagle anti punch off.")
        elseif setting == "on"
            or setting == "true"
            or setting == "1"
        then
            JARVIS_ANTIPUNCH_ENABLED = true
            voice("Eagle anti punch on.")
        else
            voice("use 'ap on or 'ap off.")
        end
        return
    end
    if cmd == "untarget" then
        local old =
            JARVIS_PRIORITY_TARGET
            and JARVIS_PRIORITY_TARGET.Name
            or "target"
        clearJarvisPriorityTarget()
        pcall(function()
            -- old loopkill stop removed
        end)
        voice("priority target cleared " .. old)
        return
    end
    if cmd == "carfling" or cmd == "cf" then
        task.spawn(function()
            runRemoteCarFling(rest)
        end)
        return
    end
    if cmd == "fling" then
        task.spawn(function()
            runJarvisPersistentCarFling(rest, false)
        end)
        return
    end
    if cmd == "dfling" then
        task.spawn(function()
            runJarvisPersistentCarFling(rest, true)
        end)
        return
    end
    if cmd == "unfling" then
        stopJarvisPersistentCarFling("manual")
        return
    end
    if cmd == "revenge" then
        local target = rest
        if target == "" then
            voice("revenge requires a player name.")
            return
        end
        local p = findPlayer(target)
        if not p then
            voice("player not found.")
            return
        end
        handleJarvisKillCommand("kill",p.Name)
        voice("revenge on " .. p.Name)
        return
    end
    if handleJarvisKillCommand(cmd, rest) then
        return
    end
    if ADMIN[cmd]
        and not LOCAL[cmd]
    then
        otherCmd(body)
        voice(cmd)
        return
    end
    if not LOCAL[cmd] then
        otherCmd(body)
        return
    end
end
attachJarvisSelfDamageWatcher()
attachJarvisOwnerDamageWatcher()
bot.CharacterAdded:Connect(function()
    if JARVIS_PRIORITY_TARGET_ACTIVE then
        JARVIS_PRIORITY_TARGET_RESPAWN_GRACE_UNTIL =
            os.clock() + 2.2
    end
end)

task.spawn(function()
    while task.wait(2) do
        local owner = getMaster()
        if owner and JARVIS_OWNER_WATCHED_PLAYER ~= owner then
            attachJarvisOwnerDamageWatcher()
        end
    end
end)

-- Local-only announcement panel. This does not broadcast accusations in chat.
local function showCheaterLine(message)
    local pg = bot:FindFirstChildOfClass("PlayerGui")
    if not pg then return end
    if not cheaterGui or not cheaterGui.Parent then
        cheaterGui = Instance.new("ScreenGui")
        cheaterGui.Name = "JARVIS_CheaterLocalCallouts"
        cheaterGui.ResetOnSpawn = false
        cheaterGui.DisplayOrder = 9998
        cheaterGui.Parent = pg
        local frame = Instance.new("Frame")
        frame.Size = UDim2.fromOffset(380, 62)
        frame.Position = UDim2.new(0.5, -190, 0.12, 0)
        frame.BackgroundColor3 = Color3.fromRGB(20, 20, 26)
        frame.BackgroundTransparency = 0.15
        frame.Parent = cheaterGui
        Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)
        cheaterLabel = Instance.new("TextLabel")
        cheaterLabel.Size = UDim2.new(1, -20, 1, -12)
        cheaterLabel.Position = UDim2.fromOffset(10, 6)
        cheaterLabel.BackgroundTransparency = 1
        cheaterLabel.TextColor3 = Color3.fromRGB(255, 230, 130)
        cheaterLabel.Font = Enum.Font.GothamBold
        cheaterLabel.TextSize = 16
        cheaterLabel.TextWrapped = true
        cheaterLabel.Parent = frame
    end
    cheaterGui.Enabled = true
    cheaterLabel.Text = message
end

-- Independent Cheater Mode announcement loop. Runs for the entire active mode,
-- even if movement/protection returns early on individual Heartbeat frames.
task.spawn(function()
    while true do
        if cheaterActive and cheaterTarget and cheaterTarget.Parent then
            if os.clock() >= cheaterNextLine then
                cheaterLineIndex += 1
                local index = (cheaterLineIndex - 1) % #CHEATER_LINES + 1
                say(CHEATER_LINES[index], true) -- public chat, bypasses shut; normal chat pacing still applies
                cheaterNextLine = os.clock() + math.random(8, 12)
            end
        end
        task.wait(0.25)
    end
end)

RunService.Heartbeat:Connect(
    function(dt)
        if not invisFollow then
            removeCloakYHold()
        end
        if IS_LEADER then
            return
        end
        local root = myRoot()
        local hum = myHum()
        if not root or not hum then
            return
        end
        -- Dancing is animation-only: follow/protect movement continues normally.
        -- Action4 overrides default run/fall animations without anchoring the bot.
        local danceState = getgenv().JARVIS_ACTION_STATE
        if danceState and danceState.danceTrack then
            local track = danceState.danceTrack
            if not track.IsPlaying then
                track:Play(0.1)
            end
        end

        -- Temporary panic: pause every competing action, but keep its state.
        -- Hover prevents gravity from pulling noclipped bots through floors,
        -- including while combo2 teleports to and from weapon pickups.
        if jarvisCombo2ExclusiveActive() then
            local flightHover = root:FindFirstChild("JARVIS_FlightHover")
            if flightHover then flightHover:Destroy() end
            releaseTrueIdleAnchor()
            JARVIS_IDLE_HOLD_CFRAME = nil
            if not flying then setFly(true) end
            hum.PlatformStand = not (getgenv().JARVIS_ACTION_STATE and getgenv().JARVIS_ACTION_STATE.danceChoice)
            hum.AutoRotate = false
            -- Keep the SAME fly state used by follow, without running follow.
            -- Do not zero velocity every frame: that was interrupting the
            -- weapon pickup's own teleport/movement and causing floor falls.
            -- The Y-only fly stabilizer cancels gravity without changing X/Z.
            local hover = root:FindFirstChild("JARVIS_Combo2Hover")
            if not hover then
                hover = Instance.new("BodyVelocity")
                hover.Name = "JARVIS_Combo2Hover"
                hover.MaxForce = Vector3.new(0, math.max(1e5, root.AssemblyMass * workspace.Gravity * 12), 0)
                hover.Velocity = Vector3.zero
                hover.P = 1250
                hover.Parent = root
            end
            return
        end
        local oldHover = root:FindFirstChild("JARVIS_Combo2Hover")
        if oldHover then oldHover:Destroy() end

        if vehicleRoutineActive then
            releaseTrueIdleAnchor()
            JARVIS_IDLE_HOLD_CFRAME = nil
            if root.Anchored then
                root.Anchored = false
            end
            return
        end
        jarvisAntiPunchStep()
        local trulyIdle =
            mode == "idle"
            and not hiddenLock
            and not vehicleRoutineActive
            and not invisFollow
            and not protecting
            and not orbiting
            and not dancing
            and not guardMode
            and not JARVIS_PUNCHAURA_ACTIVE
            and not JARVIS_IPA_ACTIVE
            and not JARVIS_PRIORITY_TARGET_ACTIVE
            and not frozen
        if trulyIdle then
            if os.clock() < (JARVIS_FOLLOW_RELEASE_UNTIL or 0) then
                releaseTrueIdleAnchor()
                JARVIS_IDLE_HOLD_CFRAME = root.CFrame
            else
                if not JARVIS_IDLE_HOLD_CFRAME then
                    JARVIS_IDLE_HOLD_CFRAME = root.CFrame
                end
                setTrueIdleAnchor()
                root.CFrame = JARVIS_IDLE_HOLD_CFRAME
            end
        else
            releaseTrueIdleAnchor()
            JARVIS_IDLE_HOLD_CFRAME = nil
        end
        if hiddenLock then
            mode = "idle"
            orbiting = false
            dancing = false
            protecting = false
            guardMode = false
            invisFollow = false
            targetPlayer = nil
            followCamPlayer = nil
            groundLock = false
            root.AssemblyLinearVelocity = Vector3.zero
            root.AssemblyAngularVelocity = Vector3.zero
            root.CFrame = getgenv().JARVIS_SQUAD.frame(HIDE_CFRAME)
        end
        updateAutomaticSpeed()
        if noSit and not vehicleRoutineActive then
            hum:SetStateEnabled(Enum.HumanoidStateType.Seated, false)
            if hum.Sit or hum:GetState() == Enum.HumanoidStateType.Seated then
                hum.Sit = false
                hum:ChangeState(Enum.HumanoidStateType.GettingUp)
            end
        end
        updateStuckRecovery(
            root,
            dt
        )
        if spinning and not frozen and not hiddenLock then
            root.CFrame =
                root.CFrame
                * CFrame.Angles(
                    0,
                    math.rad(180)
                        * dt,
                    0
                )
        end
        local cameraTarget =
            camRoot()
        local myHead =
            headOf(bot)
        if (
            not spinning
            and (
                camLocked
                or mode ~= "idle"
                or (protecting and JARVIS_PROTECT_MODE ~= "limited")
                or orbiting
            )
        )
        and cameraTarget
        and myHead
        then
            camera.CameraType =
                Enum.CameraType.Scriptable
            local look =
                myHead.Position
                + cameraTarget.CFrame.LookVector
                    * 12
            camera.CFrame =
                CFrame.lookAt(
                    myHead.Position,
                    look
                )
        end
        local hum = myHum()
        if hum then
            updateJarvisSafePosition(root, hum)
        end
        if recoverJarvisFromFall(root) then
            return
        end
        if cheaterActive then
            local target = cheaterTarget
            local tr = rootOf(target)
            if not target or not target.Parent or isAlly(target) then
                -- A player leaving ends the orbit; only 'uncheater stops it otherwise.
                cheaterActive = false
                cheaterTarget = nil
                orbiting = false
                orbitTarget = nil
                returnToMaster()
                return
            end
            if not tr then
                -- Respawning: keep the mode active and resume once the target returns.
                return
            end
            if not flying then setFly(true) end
            local goal = orbitGoal()
            if goal then
                flyStep(root, goal, dt, true)
                -- Face away from the target rather than following the camera.
                local outward = Vector3.new(
                    root.Position.X - tr.Position.X, 0,
                    root.Position.Z - tr.Position.Z
                )
                if outward.Magnitude > 0.01 then
                    root.CFrame = CFrame.lookAt(root.Position, root.Position + outward.Unit)
                end
            end
            -- Punch only when the orbit naturally enters melee range.
            if (root.Position - tr.Position).Magnitude <= (JARVIS_MELEE_RANGE or 7) then
                jarvisMeleeAttack(target)
            end
            return
        end
        if jarvisPriorityTargetStep(root, dt) then
            return
        end
        if jarvisIPAStep(root, dt) then
            return
        end
        if JARVIS_PUNCHAURA_ACTIVE then
            if punchauraStep(root, dt) then
                return
            end
        end
        if protecting then
            protectOrbitStep(root, dt)
            return
        end
        if frozen then
            if freezeCFrame and not hiddenLock then
                root.AssemblyLinearVelocity = Vector3.zero
                root.AssemblyAngularVelocity = Vector3.zero
                root.CFrame = freezeCFrame
            end
            return
        end
        if mode == "follow"
            or mode == "loopfollow"
        then
            if not flying then
                setFly(true)
            end
            local goal =
                followGoal()
            if goal then
                if invisFollow then
                    softCloakStep(root, goal, dt)
                else
                    flyStep(
                        root,
                        goal,
                        dt,
                        true
                    )
                end
            end
            return
        end
        if mode == "line" then
            if not flying then
                setFly(true)
            end
            local masterRoot =
                rootOf(getMaster())
            if masterRoot then
                local goal =
                    getFormationPosition(
                        masterRoot
                    )
                if goal and not invisFollow then
                    goal = Vector3.new(goal.X,
                        steadyFollowAltitude(getMaster(), masterRoot.Position.Y) + followVerticalOffset,
                        goal.Z)
                end
                if goal then
                    if invisFollow then
                        local latchedY = getLatchedInvisibleTargetY(getMaster())
                        goal = Vector3.new(
                            goal.X,
                            (latchedY or masterRoot.Position.Y) - cloakDepth,
                            goal.Z
                        )
                    else
                        goal = flatten(goal)
                    end
                    flyStep(
                        root,
                        goal,
                        dt,
                        invisFollow
                    )
                end
            end
            return
        end
        if mode == "orbit"
            or mode == "dance"
        then
            if not flying then
                setFly(true)
            end
            danceTime =
                danceTime + dt
            local goal =
                orbitGoal()
            if goal then
                flyStep(
                    root,
                    goal,
                    dt,
                    true
                )
            end
            return
        end
        if mode == "guard" then
            if not flying then
                setFly(true)
            end
            local goal =
                guardGoal()
            if goal then
                flyStep(
                    root,
                    goal,
                    dt,
                    true
                )
            end
            local masterRoot =
                rootOf(getMaster())
            if masterRoot then
                local outward =
                    root.Position
                    - masterRoot.Position
                if outward.Magnitude > 0.1 then
                    root.CFrame =
                        CFrame.lookAt(
                            root.Position,
                            root.Position
                                + outward.Unit
                        )
                end
            end
            return
        end
        if mode == "patrol" then
            if not flying then
                setFly(true)
            end
            local goal =
                patrolGoal()
            if goal then
                flyStep(
                    root,
                    goal,
                    dt,
                    false
                )
            end
            return
        end
        if mode == "scout" then
            if not flying then
                setFly(true)
            end
            local masterRoot =
                rootOf(getMaster())
            if masterRoot then
                local distance =
                    (
                        root.Position
                        - masterRoot.Position
                    ).Magnitude
                if not scoutReturning
                    and distance
                        >= SCOUT_DISTANCE
                then
                    scoutReturning = true
                end
            end
            local goal =
                scoutGoal()
            if goal then
                flyStep(
                    root,
                    goal,
                    dt,
                    false
                )
            end
            return
        end
        if mode == "idle"
            and invisFollow
            and invisPosition
        then
            if not flying then
                setFly(true)
            end
            softCloakStep(
                root,
                invisPosition,
                dt
            )
            return
        end
        if flying and not hiddenLock then
            hum.PlatformStand = not (getgenv().JARVIS_ACTION_STATE and getgenv().JARVIS_ACTION_STATE.danceChoice)
            root.AssemblyLinearVelocity =
                Vector3.zero
            if groundLock and mode ~= "idle" then
                local pos =
                    flatten(
                        root.Position
                    )
                if (
                    root.Position
                    - pos
                ).Magnitude > 0.15 then
                    root.CFrame =
                        CFrame.new(pos)
                        * (
                            root.CFrame
                            - root.CFrame.Position
                        )
                end
            end
        end
        if hiddenLock then
            root.AssemblyLinearVelocity = Vector3.zero
            root.AssemblyAngularVelocity = Vector3.zero
            root.CFrame = getgenv().JARVIS_SQUAD.frame(HIDE_CFRAME)
        end
    end
)

do
    local env = getgenv()

    env.JARVIS_SHARED_OWNER_PROTECTION = function(senderName, commandBody)
        local senderKey = tostring(senderName or ""):lower()
        if senderKey == masterLower or extraOwners[senderKey] ~= true then
            return false
        end

        local body = tostring(commandBody or "")
        local cmd, rest = body:match("^%s*(%S+)%s*(.-)%s*$")
        cmd = tostring(cmd or ""):lower()
        rest = tostring(rest or "")

        -- Commands that can directly harm/force the owner are never allowed
        -- from a shared account when the owner is the requested target.
        local harmful = {
            kill=true, k=true, fling=true, carfling=true, bring=true,
            hitbox=true, ragebot=true, silentaim=true,
            toolaura=true, combo1=true, combo2=true, combo3=true,
            m4a1=true, reming=true, ak=true, riot=true, mafia=true,
        }

        if not harmful[cmd] then
            return false
        end

        local target = rest:match("^%s*(%S+)")
        if not target or target == "" then
            return false
        end

        local owner = Players:FindFirstChild(MASTER_NAME)
        local targetPlayer = findPlayer(target)
        local targetsOwner =
            (owner and targetPlayer == owner)
            or target:lower() == tostring(MASTER_NAME):lower()
            or target:lower() == "owner"
            or target:lower() == "master"

        if not targetsOwner then
            return false
        end

        extraOwners[senderKey] = nil
        sharedAccessLevel[senderKey] = nil
        revokedOwners[senderKey] = true
        savePersistentState(true)
        refreshSlot()
        voice("access revoked: " .. tostring(senderName) .. " attempted to harm the owner.")
        return true
    end
end


local function JARVIS_INIT_ACTION_CONTROLLER()
    local env = getgenv()
    env.JARVIS_ACTION_STATE = env.JARVIS_ACTION_STATE or {
        spin = false,
        spinSpeed = 8,
        bounce = false,
        bounceHeight = 2.5,
        bounceSpeed = 4,
        headSitTarget = nil,
        danceTrack = nil,
    }

    local state = env.JARVIS_ACTION_STATE

    -- R6-only dance controller. The stock Animate script otherwise replaces
    -- the dance whenever flight/follow changes the Humanoid's state.
    local danceIds = {182435998, 182436842, 182436935}
    local function stopDanceTrack(preserveChoice)
        if not preserveChoice then state.danceChoice = nil end
        if state.danceTrack then
            pcall(function() state.danceTrack:Stop(0.12) end)
            pcall(function() state.danceTrack:Destroy() end)
            state.danceTrack = nil
        end
        if state.danceAnimation then
            state.danceAnimation:Destroy()
            state.danceAnimation = nil
        end
        if state.disabledAnimate and state.disabledAnimate.Parent then
            state.disabledAnimate.Disabled = false
        end
        state.disabledAnimate = nil
    end

    local function startDance(choice)
        local char = bot.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if not hum then return false, "character has no Humanoid" end
        if hum.RigType ~= Enum.HumanoidRigType.R6 then
            return false, "R6 required; avatar is R15"
        end
        local animator = hum:FindFirstChildOfClass("Animator")
        if not animator then
            animator = Instance.new("Animator")
            animator.Parent = hum
        end
        -- Disable the local default R6 controller while dancing, but never
        -- interrupt JARVIS's actual movement/follow/protection logic.
        local animate = char:FindFirstChild("Animate")
        if animate and animate:IsA("LocalScript") and not animate.Disabled then
            animate.Disabled = true
            state.disabledAnimate = animate
        end
        local anim = Instance.new("Animation")
        anim.Name = "JARVIS_R6_Dance" .. choice
        anim.AnimationId = "rbxassetid://" .. danceIds[choice]
        local ok, track = pcall(function() return animator:LoadAnimation(anim) end)
        if not ok or not track then
            if state.disabledAnimate then state.disabledAnimate.Disabled = false end
            state.disabledAnimate = nil
            anim:Destroy()
            return false, tostring(track)
        end
        track.Priority = Enum.AnimationPriority.Action4
        track.Looped = true
        track:Play(0.1, 1, 1)
        track:AdjustWeight(1, 0.1)
        state.danceAnimation = anim
        state.danceTrack = track
        state.danceChoice = choice
        state.danceAnimator = animator
        state.danceCharacter = char
        print("[JARVIS R6 DANCE] Started dance", choice, "asset", danceIds[choice])
        return true
    end

    local function stopDanceStation()
        state.danceStation = false
        stopDanceTrack()
        -- Clean up platforms left by an older build, if any.
        if state.dancePlatform then
            state.dancePlatform:Destroy()
            state.dancePlatform = nil
        end
        state.danceRoot = nil
        state.danceFrame = nil
    end

    bot.CharacterAdded:Connect(function()
        -- Heartbeat reloads the selected dance on the new character.
        state.danceCharacter = nil
    end)

    env.JARVIS_ACTION_COMMAND = function(cmd, rest)
        cmd = tostring(cmd or ""):lower()
        rest = tostring(rest or "")

        if cmd == "spin" then
            state.spin = true
            local n = tonumber(rest:match("[-+]?%d+%.?%d*"))
            if n then state.spinSpeed = math.clamp(n, 0.5, 30) end
            voice("spin enabled.")
            return true
        elseif cmd == "unspin" then
            state.spin = false
            voice("spin disabled.")
            return true
        elseif cmd == "bounce" then
            state.bounce = true
            voice("bounce enabled.")
            return true
        elseif cmd == "unbounce" then
            state.bounce = false
            voice("bounce disabled.")
            return true
        elseif cmd == "headsit" then
            local name = rest:match("^%s*(%S+)")
            local p = name and findPlayer(name)
            if not p or p == bot then
                voice("headsit target not found.")
                return true
            end
            state.headSitTarget = p
            voice("headsit tracking " .. p.Name .. ".")
            return true
        elseif cmd == "unheadsit" then
            state.headSitTarget = nil
            voice("headsit disabled.")
            return true
        elseif cmd == "undance" then
            stopDanceStation()
            voice("dance stopped; movement continues.")
            return true
        elseif cmd == "dance" then
            local choice = math.clamp(tonumber(rest:match("%d+")) or 1, 1, 3)
            stopDanceStation()
            local ok, err = startDance(choice)
            if ok then
                voice("dance " .. choice .. " active while moving.")
            else
                warn("[JARVIS DANCE] " .. tostring(err))
                voice("dance failed; check output.")
            end
            return true
        end
        return false
    end

    RunService.Heartbeat:Connect(function()
        local char = bot.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if not root then return end
        if state.danceChoice then
            if char ~= state.danceCharacter then
                local choice = state.danceChoice
                stopDanceTrack(true)
                startDance(choice)
            else
                local hum = char:FindFirstChildOfClass("Humanoid")
                local track = state.danceTrack
                if track and not track.IsPlaying then
                    track:Play(0.05, 1, 1)
                    track:AdjustWeight(1, 0)
                end
            end
        end

        -- Apply spin AFTER movement/follow logic each frame so follow, orbit,
        -- idle, etc. do not overwrite the rotation.
        if state.spin then
            root.CFrame = root.CFrame * CFrame.Angles(0, state.spinSpeed * (1/60), 0)
        end

        -- Bounce is an additive vertical motion and does not replace follow.
        if state.bounce and not state.headSitTarget then
            local y = math.sin(os.clock() * state.bounceSpeed) * state.bounceHeight
            root.CFrame = root.CFrame + Vector3.new(0, math.max(0,y) * 0.08, 0)
        end

        -- Headsit: position above the target's head while preserving a normal
        -- upright orientation. This is a local movement utility, not a fling.
        local target = state.headSitTarget
        if target then
            local tc = target.Character
            local head = tc and tc:FindFirstChild("Head")
            if head then
                local goal = getgenv().JARVIS_SQUAD.frame(head.CFrame * CFrame.new(0, 1.65, 0))
                root.CFrame = CFrame.new(goal.Position) * CFrame.Angles(0, select(2, root.CFrame:ToEulerAnglesYXZ()), 0)
                root.AssemblyLinearVelocity = Vector3.zero
            else
                state.headSitTarget = nil
            end
        end
    end)
end

-- Reliable dual-chat command intake. Roblox can deliver some lines through
-- TextChatService and others through Player.Chatted depending on the chat stack.
-- Keep BOTH listeners active and deduplicate identical deliveries briefly.
local JARVIS_CHAT_DEDUPE = {}
local function isDuplicateCommandMessage(sender, text)
    local key = tostring(sender or ""):lower() .. "\0" .. tostring(text or "")
    local now = os.clock()
    local previous = JARVIS_CHAT_DEDUPE[key]
    JARVIS_CHAT_DEDUPE[key] = now
    if previous and (now - previous) < 0.80 then return true end
    if math.random(1, 20) == 1 then
        for k, stamp in pairs(JARVIS_CHAT_DEDUPE) do
            if now - stamp > 4 then JARVIS_CHAT_DEDUPE[k] = nil end
        end
    end
    return false
end

function onChat(sender, message, metadata)
    if IS_LEADER or not sender or not message then return end
    if sender:lower() == bot.Name:lower() then return end

    local text = tostring(message)
    text = text:gsub("’", "'"):gsub("‘", "'"):gsub("`", "'")
    text = text:gsub("\239\187\191", ""):gsub("^%s+", ""):gsub("%s+$", "")

    -- IMPORTANT: filter public-chat prefixes BEFORE squad receiveChat().
    -- Previously "." / ";" reached the squad parser first, so bot/admin chat
    -- could be mistaken for squad/JARVIS traffic and make multiple bots glitch.
    local first = text:sub(1, 1)
    if first == "." or first == ";" then
        return
    end

    -- Keep squad coordination available for its own non-admin traffic.
    if sender and getgenv().JARVIS_SQUAD.receiveChat(sender, text, metadata) then
        return
    end

    if isDuplicateCommandMessage(sender, text) then return end
    local lower = text:lower()
    local senderLower = sender:lower()
    local isHost = senderLower == masterLower
    local isShared = extraOwners[senderLower] == true
        and revokedOwners[senderLower] ~= true
    local hasAccess = isHost or isShared

    -- Public Roblox chat command input is apostrophe ONLY.
    -- Any other ordinary chat is ignored by the command parser.
    -- Permanent owner AND users granted with 'share use the same apostrophe
    -- prefix. Previously this branch checked only isHost, so shared users
    -- could never reach handle().
    if lower:sub(1, #CMD_PREFIX) == CMD_PREFIX then
        if not hasAccess then
            voice("access denied.")
            return
        end

        local body = text:sub(#CMD_PREFIX + 1)
        if isShared and not isHost
            and getgenv().JARVIS_SHARED_OWNER_PROTECTION
            and getgenv().JARVIS_SHARED_OWNER_PROTECTION(sender, body)
        then
            return
        end
        if isShared and not isHost then
            local sharedCmd = tostring(body):match("^%s*(%S+)")
            sharedCmd = sharedCmd and sharedCmd:lower() or ""
            local level = sharedAccessLevel[senderLower] or 2

            if level == 1 then
                -- Share1 has the full normal command surface.
                -- Owner protection/revocation is enforced separately below.
            elseif not JARVIS_SHARE2_ALLOWED_COMMANDS[sharedCmd] then
                voice("access denied: share2 has basic access only.")
                return
            end
        end

        handle(body, sender)
        return
    end


end
pcall(function()
    TextChatService.MessageReceived:Connect(
        function(msg)
            local src =
                msg.TextSource
            if not src then
                return
            end
            if src.UserId
                == bot.UserId
            then
                return
            end
            local plr =
                Players:GetPlayerByUserId(
                    src.UserId
                )
            if plr then
                usingTextChat = true
                onChat(
                    plr.Name,
                    msg.Text,
                    msg.Metadata
                )
            end
        end
    )
end)
function hook(plr)
    if plr == bot then
        return
    end
    plr.Chatted:Connect(
        function(message)
            -- Do not disable this fallback merely because TextChatService worked once.
            -- Some commands can otherwise disappear when Roblox mixes delivery paths.
            onChat(
                plr.Name,
                message
            )
        end
    )
end
Players.PlayerAdded:Connect(
    function(p)
        hook(p)
        if protecting and protectedPlayer == p then
            watchProtectedPlayer(p)
        end
        task.defer(function()
            refreshSlot()
        end)
    end
)
-- Keep the startup player iteration inside a callback function.
-- This avoids allocating another top-level Luau local register for `p`.
table.foreach(
    Players:GetPlayers(),
    function(_, player)
        hook(player)
        if protecting and protectedPlayer == player then
            watchProtectedPlayer(player)
        end
    end
)
Players.PlayerRemoving:Connect(
    function(p)
        task.defer(function()
            if p.Name:lower()
                ~= bot.Name:lower()
            then
                refreshSlot()
            end
        end)
    end
)
bot.Idled:Connect(
    function()
        pcall(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(
                Vector2.new()
            )
        end)
    end
)
if not IS_LEADER then
    pcall(function()
        local ev =
            ReplicatedStorage:FindFirstChild(
                "EagleHello"
            )
        if ev then
            ev:FireServer()
        end
    end)
end
task.spawn(function()
    local messages = {
        "systems nominal.",
        "JARVIS standing by.",
        "squad link stable.",
        "all systems operational.",
        "awaiting commander.",
    }
    while task.wait(
        math.random(45, 90)
    ) do
        if not IS_LEADER
            and not shut
            and canTalk()
            and mode == "idle"
        then
            voice(
                messages[
                    math.random(
                        1,
                        #messages
                    )
                ]
            )
        end
    end
end)
task.defer(function()
    local pg =
        bot:WaitForChild(
            "PlayerGui"
        )
    local old =
        pg:FindFirstChild(
            "JarvisPanel"
        )
    if old then
        old:Destroy()
    end
    local gui =
        Instance.new("ScreenGui")
    gui.Name = "JarvisPanel"
    gui.ResetOnSpawn = false
    gui.Enabled = false
    gui.Parent = pg
    local frame =
        Instance.new("Frame")
    frame.Size =
        UDim2.fromOffset(
            350,
            410
        )
    frame.Position =
        UDim2.fromOffset(
            16,
            80
        )
    frame.BackgroundColor3 =
        Color3.fromRGB(
            16,
            16,
            20
        )
    frame.Parent = gui
    local corner =
        Instance.new("UICorner")
    corner.CornerRadius =
        UDim.new(
            0,
            10
        )
    corner.Parent = frame
    local title =
        Instance.new("TextLabel")
    title.Size =
        UDim2.new(
            1,
            -20,
            0,
            38
        )
    title.Position =
        UDim2.fromOffset(
            10,
            8
        )
    title.BackgroundTransparency = 1
    title.Font =
        Enum.Font.Code
    title.TextSize = 20
    title.TextXAlignment =
        Enum.TextXAlignment.Left
    title.TextColor3 =
        Color3.fromRGB(
            230,
            230,
            240
        )
    title.Text =
        "J.A.R.V.I.S."
    title.Parent = frame
    local lab =
        Instance.new("TextLabel")
    lab.Size =
        UDim2.new(
            1,
            -20,
            1,
            -55
        )
    lab.Position =
        UDim2.fromOffset(
            10,
            48
        )
    lab.BackgroundTransparency = 1
    lab.Font =
        Enum.Font.Code
    lab.TextSize = 14
    lab.TextColor3 =
        Color3.fromRGB(
            220,
            220,
            220
        )
    lab.TextXAlignment =
        Enum.TextXAlignment.Left
    lab.TextYAlignment =
        Enum.TextYAlignment.Top
    lab.TextWrapped = true
    lab.Parent = frame
    local function updatePanel()
        local eagleCount =
            #getEagleUnits()
        local target =
            activeTarget()
        local zone =
            isInsidePrison()
        local captain =
            mySlot == 1
        lab.Text =
            string.format(
                "UNIT       %s\n"
                .. "SLOT       %s / %s\n"
                .. "CAPTAIN    %s\n"
                .. "MODE       %s\n"
                .. "TARGET     %s\n\n"
                .. "SQUAD      %s JARVIS units\n"
                .. "FORMATION  %s\n"
                .. "SPEED      %d\n"
                .. "ZONE       %s\n\n"
                .. "PROTECT    %s\n"
                .. "INVIS      %s\n"
                .. "FLY        %s\n"
                .. "NOCLIP     %s\n"
                .. "PUNCH      %s\n"
                .. "NO-SIT     %s\n"
                .. "HIDDEN     %s\n"
                .. "FROZEN     %s\n"
                .. "FOLLOW D   %.1f\n"
                .. "CLOAK D    %.1f\n\n"
                .. "COMMANDS   %d\n"
                .. "LAST       %s\n\n"
                .. "` close",
                getJarvisName(),
                tostring(mySlot),
                tostring(
                    math.max(
                        eagleCount,
                        1
                    )
                ),
                tostring(captain),
                mode,
                target
                    and target.Name
                    or "none",
                tostring(eagleCount),
                formationType,
                math.floor(flySpeed),
                zone
                    and "PRISON"
                    or "OUTSIDE",
                tostring(protecting),
                tostring(invisFollow),
                tostring(flying),
                tostring(noclipOn),
                tostring(punchOn),
                tostring(noSit),
                tostring(hiddenLock),
                tostring(frozen),
                followDistance,
                cloakDepth,
                sessionCommandCount,
                lastCommand
            )
    end
    UserInputService.InputBegan:Connect(
        function(inp, gp)
            if gp then
                return
            end
            if inp.KeyCode
                == Enum.KeyCode.F8
            then
                gui.Enabled =
                    not gui.Enabled
                if gui.Enabled then
                    updatePanel()
                end
            end
        end
    )
    task.spawn(function()
        while gui.Parent do
            if gui.Enabled then
                updatePanel()
            end
            task.wait(0.25)
        end
    end)
end)
function tryAutoRejoin(reason)
    if rejoinAttempted then return end
    rejoinAttempted = true
    savePersistentState(true)
    warn("[JARVIS] reconnect detected:", reason or "unknown")
    task.defer(function()
        pcall(function()
            TeleportService:Teleport(game.PlaceId, bot)
        end)
    end)
end
pcall(function()
    GuiService.ErrorMessageChanged:Connect(function(message)
        message = tostring(message or "")
        if message ~= "" then
            tryAutoRejoin(message)
        end
    end)
end)
pcall(function()
    TeleportService.TeleportInitFailed:Connect(function(player)
        if player == bot then
            rejoinAttempted = false
            task.delay(0.5, function()
                tryAutoRejoin("teleport retry")
            end)
        end
    end)
end)
startPersistentSaver()
task.spawn(function()
    task.wait(1)
    refreshSlot()
    applyNoSitState()
    if IS_LEADER then
        print(
            "[JARVIS] Master detected. "
            .. "No autonomous movement."
        )
        return
    end
    if not didJoinFly then
        didJoinFly = true
        setFly(true)
        voice(
            "JARVIS online. "
            .. getJarvisName()
            .. " ready."
        )
    end
end)
refreshSlot()
JARVIS_AUTO_PROTECT_SERIAL = JARVIS_AUTO_PROTECT_SERIAL or 0
function autoProtectMaster()
    if IS_LEADER then
        return false
    end
    local master = getMaster()
    if not master or not master.Parent then
        return false
    end
    protecting = true
    protectedPlayer = master
    targetPlayer = master
    attachProtectDamageWatcher(master)
    followCamPlayer = master
    mode = "idle"
    orbiting = false
    groundLock = false
    JARVIS_PROTECT_ORBIT_ANGLE = 0
    table.clear(JARVIS_PROTECT_LAST_ACTION)
    refreshSlot()
    setFly(true)
    disconnectProtection()
    lockCam(master)
    print(
        "[JARVIS] Auto-protect 10-stud orbit guard:",
        master.Name
    )
    return true
end
function scheduleAutoProtect(delaySeconds)
    if IS_LEADER then
        return
    end
    JARVIS_AUTO_PROTECT_SERIAL += 1
    local serial = JARVIS_AUTO_PROTECT_SERIAL
    task.spawn(function()
        task.wait(tonumber(delaySeconds) or 0)
        for _ = 1, 30 do
            if serial ~= JARVIS_AUTO_PROTECT_SERIAL then
                return
            end
            if autoProtectMaster() then
                voice("Protecting you, Sir. Auto-protect engaged.")
                return
            end
            task.wait(0.5)
        end
        warn("[JARVIS] Master not found; auto-protect will arm on PlayerAdded.")
    end)
end
scheduleAutoProtect(1.5)
Players.PlayerAdded:Connect(function(p)
    if p == bot then
        return
    end
    if p.Name:lower() == masterLower then
        scheduleAutoProtect(0.5)
    end
end)
Players.PlayerRemoving:Connect(function(p)
    if p.Name:lower() ~= masterLower then
        return
    end
    if protectedPlayer == p then
        protecting = false
        protectedPlayer = nil
        targetPlayer = nil
        followCamPlayer = nil
        disconnectProtection()
    end
end)
if not IS_LEADER then
    task.spawn(function()
        while task.wait(8) do
            if ROLE == "bot" and HOST_NAME ~= "" then
                local hostId = getHostUserId()
                if hostId then
                    local ok, _, _, placeId, jobId = pcall(function()
                        return TeleportService:GetPlayerPlaceInstanceAsync(hostId)
                    end)
                    if ok and placeId == game.PlaceId and type(jobId) == "string"
                        and jobId ~= "" and jobId ~= game.JobId
                    then
                        -- Host-server discovery is available, but only the explicit
                        -- "call" command should trigger the teleport.
                    end
                end
            end
        end
    end)
end

print(
    "[JARVIS] ready | unit="
    .. getJarvisName()
    .. " | slot="
    .. tostring(mySlot)
    .. " | formation="
    .. formationType
)
print(
    "[JARVIS] speed system: "
    .. tostring(PRISON_SPEED)
    .. " inside current Prison Life bounds / "
    .. tostring(OUTSIDE_SPEED)
    .. " outside"
)
task.defer(applyNoSitState)
bot.CharacterAdded:Connect(function()
    stopJarvisIPA()
    clearJarvisAntiPunch()
    JARVIS_LAST_SAFE_CFRAME = nil
    JARVIS_LAST_SAFE_UPDATE = 0
    JARVIS_PROTECT_RESPAWN_GRACE_UNTIL =
        os.clock() + JARVIS_PROTECT_RESPAWN_GRACE
    runRespawnCombo2()
end)
if bot.Character and bot.Character.Parent then
    runRespawnCombo2()
end
JARVIS_INIT_ACTION_CONTROLLER()

task.defer(function()
    protecting = false
    protectedPlayer = nil
    if disconnectProtectDamageWatcher then
        disconnectProtectDamageWatcher()
    end
    if JARVIS_PROTECT_LAST_ACTION then
        table.clear(JARVIS_PROTECT_LAST_ACTION)
    end
    if disconnectProtection then
        disconnectProtection()
    end
    print("[JARVIS] startup protection state: OFF")
end)

getgenv().JARVIS_VOLT_COMMAND_DISPATCH = function(commandText)
    handleJarvisKillCommand(getMaster(), commandText)
end
