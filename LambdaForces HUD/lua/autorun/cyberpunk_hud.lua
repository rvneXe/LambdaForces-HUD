----------------------------------
------------COPYRIGHT-------------
-- Editing the code as a refrence is allowed. 
-- if u wanna publish your edited code, don't forget to give a refrence in addon descriptions.

-- DONT republish the same addon 
----------------------------------

if SERVER then
	AddCSLuaFile()
end

local accentr = CreateClientConVar( "lfh_accent_color_r", 0, true, false, "LambdaForces HUD Accent Color (R)", 0, 255 )
local accentg = CreateClientConVar( "lfh_accent_color_g", 255, true, false, "LambdaForces HUD Accent Color (G)", 0, 255 )
local accentb = CreateClientConVar( "lfh_accent_color_b", 255, true, false, "LambdaForces HUD Accent Color (B)", 0, 255 )
local accenta = CreateClientConVar( "lfh_accent_color_a", 230, true, false, "LambdaForces HUD BG Opacity", 0, 255 )
local playerwantsaux = CreateClientConVar( "lfh_enable_aux", 1, true, false, "Should HUD Display H.E.V Suit Power?", 0, 1 )
local shape_ele = CreateClientConVar( "lfh_shape_el", "-16", true, false, "LambdaForces HUD Elements Shape\n-16 = Parallelogram\n-1 = Rectangle")

local gmodsuit = GetConVar("gmod_suit")
local mee_spr_multiplier  = GetConVar("scale_multiplier")

if LocalPlayer then

	-- Add Typefaces for HUD
	surface.CreateFont( "Numbers", {
		font = "TEST",
		extended = true,
		size = 89,
		weight = 0,
		blursize = 0,
		scanlines = 0,
		antialias = true,
		underline = false,
		italic = false,
		strikeout = false,
		symbol = false,
		rotary = false,
		shadow = false,
		additive = false,
		outline = false,
	} )

	surface.CreateFont( "Trebuchet", {
		font = "Trebuchet MS",
		extended = true,
		size = 24,
		weight = 0,
		blursize = 0,
		scanlines = 0,
		antialias = true,
		underline = false,
		italic = false,
		strikeout = false,
		symbol = false,
		rotary = false,
		shadow = false,
		additive = false,
		outline = false,
	} )

	surface.CreateFont( "WPIcons", {
		font = "LFHUD_GMODICONS",
		extended = false,
		size = 150,
		weight = 0,
		blursize = 0,
		scanlines = 0,
		antialias = true,
		underline = false,
		italic = false,
		strikeout = false,
		symbol = false,
		rotary = false,
		shadow = false,
		additive = false,
		outline = false,
	} )

	surface.CreateFont( "OrbitMed", {
		font = "Orbitron-Medium",
		extended = false,
		size = 22,
		weight = 0,
		blursize = 0,
		scanlines = 0,
		antialias = true,
		underline = false,
		italic = false,
		strikeout = false,
		symbol = false,
		rotary = false,
		shadow = false,
		additive = false,
		outline = false,
	} )

	-- Add HUD Colors
	local BGColor = Color(10,10,10,accenta:GetInt())
	local AccentColor = Color(accentr:GetInt(), accentg:GetInt(), accentb:GetInt(),255)
	local DisabledColor = Color(128,128,128,225)
	local Warning = Color(255,156,0,255)
	local EmptyMag = Color(255,0,0,255)
	local DamageColor = Color(200,10,10,225)
	local ArmorRecharge = Color(88,174,255,225)
	local ArmorDecrease = Color(225,10,10,225)
	local HealingColor = Color(88,255,205,225)

	--print(AccentColor)
	
	-- Define some variables to fit the HUD better in screen space
	local ScreenVars = {
		['x']=1/64,
		['y']=1/64*ScrW()/ScrH()
	}

	-- Heal/Lose Animation Variables
	local HealthColor = Color(AccentColor.r,AccentColor.g,AccentColor.b,AccentColor.a)

	local ArmorColor = Color(AccentColor.r,AccentColor.g,AccentColor.b,AccentColor.a)

	local FadeSpeed = 300

	local OldHealth = 100
	local OldAUX = 100

	local OldArmor = 0

	-- Hide default gmod HUD
	local HiddenElements = {
		['CHudHealth']=true,
		['CHudBattery']=true,
		['CHudAmmo']=true,
		['CHudSecondaryAmmo']=true,
		['CHudSuitPower']=true
	}


	-- Define Some information for drawing HP & Armor Icons
	local HealthNumInfo = {
		['text'] = nil,
		['font'] = "Numbers",
		['pos'] = {125,-55},
		['xalign'] = TEXT_ALIGN_CENTER,
		['yalign'] = TEXT_ALIGN_CENTER,
		['color'] = nil
	}
	local HealthIconInfo = {
		['text'] = "A",
		['font'] = "Numbers",
		['pos'] = {3,3},
		['xalign'] = TEXT_ALIGN_LEFT,
		['yalign'] = TEXT_ALIGN_CENTER,
		['color'] = nil
	}
	local ArmorNumInfo = {
		['text'] = nil,
		['font'] = "Numbers",
		['pos'] = {0,0},
		['xalign'] = TEXT_ALIGN_CENTER,
		['yalign'] = TEXT_ALIGN_CENTER,
		['color'] = nil
	}
	local ArmorIconInfo = {
		['text'] = "B",
		['font'] = "Numbers",
		['pos'] = {0,0},
		['xalign'] = TEXT_ALIGN_CENTER,
		['yalign'] = TEXT_ALIGN_CENTER,
		['color'] = nil
	}
	local AUXInfo = {
		['text'] = nil,
		['font'] = "OrbitMed",
		['pos'] = {0,0},
		['xalign'] = TEXT_ALIGN_LEFT,
		['yalign'] = TEXT_ALIGN_CENTER,
		['color'] = nil
	}
	
	local function ShouldDraw()
		local myplayer = LocalPlayer()
		if !IsValid(myplayer) then 
			return 
		elseif !myplayer:Alive() then 
			return false 
		end
		return ( GetConVarNumber("cl_drawhud",1) == 1 ) and true or false
	end

	local function HideHUD( el )
		if HiddenElements[el] then 
			return false
		end
	end

	local w,h = ScrW(), ScrH()
	local xx, yy

	function CyberpunkUIShape( leftx, downy, fillcolor, linecolor, wid, hei, bendsize, offset, identifier )
		local shapebg = {
			{ x = leftx+bendsize, y = downy-hei }, -- top left
			{ x = leftx , y = downy }, -- down left
			{ x = leftx+wid, y = downy }, -- down right
			{ x = leftx+wid+bendsize, y = downy-hei } -- top right
		}

		surface.SetDrawColor(fillcolor)
		surface.DrawPoly( shapebg )
		 
		surface.SetDrawColor(linecolor)
		surface.DrawLine(leftx+bendsize+offset, downy-hei+offset, leftx+wid+bendsize-offset-2, downy-hei+offset) -- top
		surface.DrawLine(leftx+offset+1, downy-offset-1, leftx+wid-offset, downy-offset-1) -- down
		surface.DrawLine(leftx+bendsize+offset, downy-hei+offset, leftx+offset+1, downy-offset) -- left
		surface.DrawLine(leftx+wid+bendsize-offset-2, downy-hei+offset, leftx+wid-offset-1, downy-offset)
	end

	local function DrawTheHUD()

		if !ShouldDraw() then return end

		local myplayer = LocalPlayer()

		AccentColor = Color(accentr:GetInt(), accentg:GetInt(), accentb:GetInt(), 255)
		BGColor = Color(10,10,10,accenta:GetInt())
		
		local EleShape = shape_ele:GetInt()
		local SuitEnabled = gmodsuit:GetInt()
		local HUDSuitEnabled = playerwantsaux:GetInt()
		
		xx=w*ScreenVars.x
		yy=h-h*(ScreenVars.y)
		
		if !myplayer:IsValid() then return end

		

		---\/------------------------------\/--
		---     Health
		---\/------------------------------\/--
		if myplayer:Health()<1 then
			HealthNumInfo.color = DisabledColor
			HealthIconInfo.color = DisabledColor
		else
			HealthNumInfo.color = AccentColor
			HealthIconInfo.color = AccentColor
		end

		local healthpercent = myplayer:Health() / myplayer:GetMaxHealth()
		if healthpercent > 1 then healthpercent = 1 end
		
		if HealthColor.r>AccentColor.r then
			HealthColor.r = math.Clamp(math.max(HealthColor.r-FrameTime()*FadeSpeed,AccentColor.r),0,255)
		elseif HealthColor.r<AccentColor.r then
			HealthColor.r = math.Clamp(math.min(HealthColor.r+FrameTime()*FadeSpeed,AccentColor.r),0,255)
		end
		
		if HealthColor.g>AccentColor.g then
			HealthColor.g = math.Clamp(math.max(HealthColor.g-FrameTime()*FadeSpeed,AccentColor.g),0,255)
		elseif HealthColor.g<AccentColor.g then
			HealthColor.g = math.Clamp(math.min(HealthColor.g+FrameTime()*FadeSpeed,AccentColor.g),0,255)
		end
		
		if HealthColor.b>AccentColor.b then
			HealthColor.b = math.Clamp(math.max(HealthColor.b-FrameTime()*FadeSpeed,AccentColor.b),0,255)
		elseif HealthColor.b<AccentColor.b then
			HealthColor.b = math.Clamp(math.min(HealthColor.b+FrameTime()*FadeSpeed,AccentColor.b),0,255)
		end
		
		if HealthColor.a>AccentColor.a then
			HealthColor.a = math.Clamp(math.max(HealthColor.a-FrameTime()*FadeSpeed,AccentColor.a),0,255)
		elseif HealthColor.a<AccentColor.a then
			HealthColor.a = math.Clamp(math.min(HealthColor.a+FrameTime()*FadeSpeed,AccentColor.a),0,255)
		end
		
		if myplayer:Health()<OldHealth then
			for k,v in pairs(DamageColor) do
				HealthColor[k]=v
			end
		elseif myplayer:Health()>OldHealth then
			for k,v in pairs(HealingColor) do
				HealthColor[k]=v
			end	
		end
		
		OldHealth = myplayer:Health()

		CyberpunkUIShape(xx, yy, BGColor, HealthColor, 200, 80, -EleShape, 2, "health")

		
		HealthIconInfo.pos = {xx+5,yy-45}
		HealthIconInfo.color = HealthColor
		draw.Text( HealthIconInfo )
		
		HealthNumInfo.pos = {xx+125,yy-45}
		HealthNumInfo.color = HealthColor
		HealthNumInfo.text =  myplayer:Health()
		draw.Text( HealthNumInfo )
		
		surface.SetDrawColor(HealthColor)
		surface.DrawRect( xx+14, yy-12, 175*healthpercent,4 )
		


		---\/------------------------------\/--
		---     Armor
		---\/------------------------------\/--
		if myplayer:Armor()!=0 then
			local ArmorGlobalColor

			if myplayer:Armor()!=0 then
				ArmorGlobalColor = ArmorColor
			end
		
			ArmorIconInfo.color = ArmorGlobalColor
			ArmorIconInfo.pos = {xx+210,yy-39}
			ArmorIconInfo.text = 'B'
		
			if myplayer:Armor()==0 then
				ArmorColor = DisabledColor
				ArmorIconInfo.color = DisabledColor
				ArmorIconInfo.color = DisabledColor
			else
				ArmorIconInfo.color = AccentColor
				ArmorIconInfo.color = AccentColor
			end

			local armorpercent = math.Clamp( myplayer:Armor() / 100, 0, 1)
		
		
			if ArmorColor.r>AccentColor.r then
				ArmorColor.r = math.Clamp(math.max(ArmorColor.r-FrameTime()*FadeSpeed,AccentColor.r),0,255)
			elseif ArmorColor.r<AccentColor.r then
				ArmorColor.r = math.Clamp(math.min(ArmorColor.r+FrameTime()*FadeSpeed,AccentColor.r),0,255)
			end
		
			if ArmorColor.g>AccentColor.g then
				ArmorColor.g = math.Clamp(math.max(ArmorColor.g-FrameTime()*FadeSpeed,AccentColor.g),0,255)
			elseif ArmorColor.g<AccentColor.g then
				ArmorColor.g = math.Clamp(math.min(ArmorColor.g+FrameTime()*FadeSpeed,AccentColor.g),0,255)
			end
		
			if ArmorColor.b>AccentColor.b then
				ArmorColor.b = math.Clamp(math.max(ArmorColor.b-FrameTime()*FadeSpeed,AccentColor.b),0,255)
			elseif ArmorColor.b<AccentColor.b then
				ArmorColor.b = math.Clamp(math.min(ArmorColor.b+FrameTime()*FadeSpeed,AccentColor.b),0,255)
			end
		
			if ArmorColor.a>AccentColor.a then
				ArmorColor.a = math.Clamp(math.max(ArmorColor.a-FrameTime()*FadeSpeed,AccentColor.a),0,255)
			elseif ArmorColor.a<AccentColor.a then
				ArmorColor.a = math.Clamp(math.min(ArmorColor.a+FrameTime()*FadeSpeed,AccentColor.a),0,255)
			end
		
			if myplayer:Armor()<OldArmor then
				for k,v in pairs(ArmorDecrease) do
				ArmorColor[k]=v
			end
			elseif myplayer:Armor()>OldArmor then
				for k,v in pairs(ArmorRecharge) do
					ArmorColor[k]=v
				end	
			end
		
			OldArmor = myplayer:Armor()
			
			CyberpunkUIShape(xx+210, yy, BGColor, ArmorGlobalColor, 200, 80, -EleShape, 2, "armor")

			ArmorNumInfo.pos = {xx+335,yy-45}
			ArmorNumInfo.color = ArmorGlobalColor
			ArmorNumInfo.text = myplayer:Armor()
			draw.Text( ArmorNumInfo )

			ArmorIconInfo.pos = {xx+240,yy-45}
			ArmorIconInfo.color = ArmorGlobalColor
			draw.Text( ArmorIconInfo )
			
			surface.SetDrawColor(ArmorColor)
			surface.DrawRect(xx+223, yy-12, 180*armorpercent,4 )
			
		
		end


		---\/------------------------------\/--
		---     AUX POWER
		---\/------------------------------\/--
		local AUXVarTable = {
			['text'] = "A",
			['font'] = "Numbers",
			['pos'] = {3,3},
			['xalign'] = TEXT_ALIGN_LEFT,
			['yalign'] = TEXT_ALIGN_CENTER,
			['color'] = HealthColor
		}

		if SuitEnabled == 1 and myplayer:IsSuitEquipped() == true and HUDSuitEnabled == 1 then
			--print(myplayer:GetSuitPower())
			--print(myplayer:FlashlightIsOn())
			--print(myplayer:IsSprinting())
			--print(myplayer:WaterLevel())

			local AUXColor = Color(AccentColor.r, AccentColor.g, AccentColor.b, 255)
			local AUXBGColor = Color(BGColor.r, BGColor.g, BGColor.b, accenta:GetInt())
			local auxpercent = myplayer:GetSuitPower() / 100

			if auxpercent == 0 then
				AUXColor = Color(255,0,0)
			end

			if myplayer:GetSuitPower()>OldAUX then
				AUXColor = ArmorRecharge
			end

			if myplayer:GetSuitPower() == 100 then
				AUXColor = Color(0,0,0,0)
				AUXBGColor = Color(0,0,0,0)
			end
			
			if myplayer:GetSuitPower()>OldAUX then AUXColor = ArmorRecharge end

			OldAUX = myplayer:GetSuitPower()

			CyberpunkUIShape(xx-xx+47, yy-84, AUXBGColor, AUXColor, 204, 40, 1, 2, "power")


			AUXInfo.pos = {xx+35,yy-110}
			AUXInfo.color = AUXColor
			AUXInfo.text = "AUX Power"
			draw.Text( AUXInfo )

			surface.SetDrawColor(AUXColor)
			surface.DrawRect(xx-xx+61, yy-96, 180*auxpercent,4 )
		end	


		xx = ScrW() -- to sync positions with resolution

		-- =============================================================================================
		------------------------------     RIGHT HUD SIDE
		-- =============================================================================================
		---\/------------------------------\/--
		---     Weapon & Ammo
		---\/------------------------------\/--

		if myplayer:GetActiveWeapon():IsValid() == false then return end

		local AmmoGlobalColor = AccentColor
		local ShapeWidth
		local wp = myplayer:GetActiveWeapon()
		local wpid = wp:GetClass()
		local wpname = wp:GetPrintName() 
		local wpdisp
		local wpcode
		
		


		--⨌***** Half-Life/Gmod weapons
		if wpid=="weapon_smg1" then wpcode = "a"   wpdisp = "SMG"
		elseif wpid=="weapon_shotgun" then wpcode = "b"  wpdisp = "Shotgun"
		elseif wpid=="weapon_crowbar" then wpcode = "c"  wpdisp = "Crowbar"
		elseif wpid=="weapon_pistol"  then wpcode = "d"  wpdisp = "9mm Pistol"
		elseif wpid=="weapon_357"     then wpcode = "e"  wpdisp = ".357 Magnum"
		elseif wpid=="weapon_crossbow" then wpcode = "g"  wpdisp = "Crossbow"
		elseif wpid=="weapon_rpg"     then wpcode = "i"  wpdisp = "RPG Launcher"
		elseif wpid=="weapon_ar2"     then wpcode = "l"  wpdisp = "Pulse-Rifle"
		elseif wpid=="weapon_bugbait" then wpcode = "j"  wpdisp = "Bug Bait"
		elseif wpid=="weapon_physcannon" then wpcode = "m"   wpdisp = "Gravity Gun"
		elseif wpid=="weapon_physgun" then wpcode = "m"   wpdisp = "Physic Gun"
		elseif wpid=="weapon_stunstick" then wpcode = "n"   wpdisp = "Stunstick"
		elseif wpid=="weapon_frag"    then wpcode = "k"  wpdisp = "Frag Grenade"
		elseif wpid=="weapon_slam"	  then wpcode = "0"  wpdisp = "S.L.A.M"
		-- elseif wpid=="weapon_medkit"  then wpcode = "+" wpdisp = "Medkit"
		
		--⨌***** ICONS for addons
		--elseif string.find(wpid,"ak47")!=nil 
		--or string.find(wpid,"ak74")!=nil 
		--or string.find(wpid,"an94")!=nil then wpcode = "1"  wpdisp = wpname
		--elseif string.find(wpid,"glock")!=nil
		--or string.find(wpid,"m9k_hk45")!=nil
		--or string.find(wpid,"colt1911")!=nil  then wpcode = "4"  wpdisp = wpname
		--elseif string.find(wpid,"csgo_default_t")!=nil then wpcode = "3"  wpdisp = "Default T Knife"
		--elseif string.find(wpid,"csgo_default")!=nil or string.find(wpid,"csgo_knife_t")!=nil then wpcode = "3"  wpdisp = "Default T Knife"
		--elseif string.find(wpid,"csgo_knife")!=nil then wpcode = "2"  wpdisp = "Default CT Knife"

		--⨌***** NAMES for addons
		elseif string.find(wpid,"csgo_bayonet")!=nil then wpcode = "0"  wpdisp = "Bayonet Knife"
		elseif string.find(wpid,"csgo_bowie")!=nil then wpcode = "0"  wpdisp = "Bowie Knife"
		elseif string.find(wpid,"csgo_butterfly")!=nil then wpcode = "0"  wpdisp = "Butterfly Knife"
		elseif string.find(wpid,"csgo_falchion")!=nil then wpcode = "0"  wpdisp = "Falchion Knife"
		elseif string.find(wpid,"csgo_flip")!=nil then wpcode = "0"  wpdisp = "Flip Knife"
		elseif string.find(wpid,"csgo_gut")!=nil then wpcode = "0"  wpdisp = "Gut Knife"
		elseif string.find(wpid,"csgo_huntsman")!=nil then wpcode = "0"  wpdisp = "Huntsman Knife"
		elseif string.find(wpid,"csgo_karambit")!=nil then wpcode = "0"  wpdisp = "Karambit Knife"
		elseif string.find(wpid,"csgo_m9")!=nil then wpcode = "0"  wpdisp = "M9 Bayonet Knife"
		elseif string.find(wpid,"csgo_daggers")!=nil then wpcode = "0"  wpdisp = "Shadow Daggers"

		--⨌***** If was'nt any of them
		else
			wpcode="0"
			wpdisp=wpname
		end

		local WeaponNameInfo = {
			['text'] = wpdisp,
			['font'] = "OrbitMed",
			['pos'] = {0,0},
			['xalign'] = TEXT_ALIGN_RIGHT,
			['yalign'] = TEXT_ALIGN_CENTER,
			['color'] = AmmoGlobalColor
		}
		local WeaponIconInfo = {
			['text'] = wpcode,
			['font'] = "WPIcons",
			['pos'] = {0,0},
			['xalign'] = TEXT_ALIGN_RIGHT,
			['yalign'] = TEXT_ALIGN_CENTER,
			['color'] = AmmoGlobalColor
		}
		local AmmoInfo = {
			['text'] = nil,
			['font'] = "Numbers",
			['pos'] = {0,0},
			['xalign'] = TEXT_ALIGN_RIGHT,
			['yalign'] = TEXT_ALIGN_CENTER,
			['color'] = AmmoGlobalColor
		}



		local ammo1 = wp:Clip1()
		local ammo1type = wp:GetPrimaryAmmoType()
		local ammo1invt = myplayer:GetAmmoCount(ammo1type)
		local ammo1percentage = ammo1 * 100 / wp:GetMaxClip1()

		local ammo2type = wp:GetSecondaryAmmoType()
		local ammo2invt = myplayer:GetAmmoCount(ammo2type)

		ShapeWidth = 460
		ShapeLeftX = 0

		local ammoleng = string.len(ammo1) + string.len(ammo1invt) + 1
		local ammoaddi = ammoleng - 5
		local ammolengaddi = 60 * ammoaddi

		if wpcode=="0" then
			WeaponNameInfo.pos = {xx-95,yy-67}
			AmmoInfo.pos = {xx-90,yy-34}
		elseif wpcode=="4" then
			WeaponNameInfo.pos = {xx-140,yy-67}
			AmmoInfo.pos = {xx-140,yy-34}
		else
			WeaponNameInfo.pos = {xx-200,yy-67}
			AmmoInfo.pos = {xx-200,yy-34}
		end


		

		if ammo1type!=-1 then
			
			if ammoleng>= 6 then
				ShapeWidth = ShapeWidth + ammolengaddi
				ShapeLeftX = ShapeLeftX - ammolengaddi
				if wpcode == "0" then
					ShapeWidth = ShapeWidth - 85
					ShapeLeftX = ShapeLeftX + 85
				end
			end

			if ammo1percentage >= 25 then
				AmmoGlobalColor = AccentColor
			elseif ammo1percentage < 25 then
				AmmoGlobalColor = Warning

				if ammo1percentage == 0 then
					AmmoGlobalColor = EmptyMag
				end

			end
		else 
			ShapeWidth = 460
			ShapeLeftX = xx
			AmmoGlobalColor = AccentColor
			ShapeWidth = 400
		end
		

		WeaponNameInfo.color = AmmoGlobalColor

		if wpid=="weapon_357" then WeaponIconInfo.pos = {xx-25,yy-45}
		else WeaponIconInfo.pos = {xx-25,yy-40}
		end

		WeaponIconInfo.color = AmmoGlobalColor

		CyberpunkUIShape(xx-ShapeWidth-10, yy, BGColor, AmmoGlobalColor, ShapeWidth, 80, EleShape+2, 2, "weapon")
		draw.Text(WeaponNameInfo)
		draw.Text(WeaponIconInfo)
	
		if ammo1type != -1 then
			
			AmmoInfo.color = AmmoGlobalColor
			if ammo1 == -1 then
				AmmoInfo.text = ammo1invt
				AmmoInfo.xalign = TEXT_ALIGN_RIGHT
				draw.Text(AmmoInfo)
			else
				AmmoInfo.text = ammo1.." ⁄ "..ammo1invt
				AmmoInfo.xalign = TEXT_ALIGN_RIGHT
				draw.Text(AmmoInfo)
			end
		end

		
		---- SECOND AMMO ------------------
		WeaponNameInfo.pos = {xx-40,yy-150}
		AmmoInfo.pos = {xx-40,yy-117}
		if ammo2type!=-1 then
			if ammo2invt != 0 and ammo2type!=11 then
				if ammo2invt > 99 then 
					AmmoInfo.text = "99+"
				else 
					AmmoInfo.text = ammo2invt
				end

				if ammo2type == 9 then WeaponNameInfo.text = "SMG Grenade"
				elseif ammo2type == 2 then WeaponNameInfo.text = "AR2 Orb"
				else
					WeaponNameInfo.text = "[UNKNOWN]"
				end

				CyberpunkUIShape(xx-212, yy-85, BGColor, AmmoGlobalColor, 200, 80, EleShape+2, 2, "clip2")
				draw.Text(WeaponNameInfo)
				draw.Text(AmmoInfo)
			else
				hook.Remove("HUDPaint", "clip2")
			end
		else
			hook.Remove("HUDPaint", "clip2")
		end

		xx = ScrW()-ShapeWidth-10

		-------- STYLE ----------------------
		local wpstyle = string.sub(wpname, string.len(wpdisp)+4 )

		local StyleInfo = {
			['text'] = "Weapon Style:  "..wpstyle,
			['font'] = "OrbitMed",
			['pos'] = {xx-5,yy-105},
			['xalign'] = TEXT_ALIGN_LEFT,
			['yalign'] = TEXT_ALIGN_CENTER,
			['color'] = AmmoGlobalColor
		}



		if string.StartWith(wpid, "csgo_") and wpstyle != "" then 
			CyberpunkUIShape(xx-15, yy-84, BGColor, AmmoGlobalColor, ShapeWidth, 40, 1, 2, "wpstyle")
			draw.Text(StyleInfo)
		else
			hook.Remove("HUDPaint", "wpstyle")
		end

		render.SetScissorRect( 0, 0, 0, 0, false )
		
	end

	local rn = math.random(1000000000, 999999999999) / math.random(1, 100) * math.random(1, 100)

	local function PlayerInfo()
		if input.IsKeyDown(KEY_C) == false then return end

		local myplayer = LocalPlayer()
		local cl = -305

		xx=w*ScreenVars.x
		yy=h-h*(ScreenVars.y)	

		CyberpunkUIShape(47, yy-84, BGColor, AccentColor, 300, 240, 1, 2, "plrinfo")

		AUXInfo.pos = {xx+30,yy+cl}
		AUXInfo.color = AccentColor
		AUXInfo.text = "Clone>   " .. myplayer:GetName()
		draw.Text( AUXInfo )
		cl = cl+20

		AUXInfo.pos = {xx+30,yy+cl}
		AUXInfo.color = AccentColor
		AUXInfo.text = "Clone ID>   " .. math.SnapTo(rn, 1)
		draw.Text( AUXInfo )
		cl = cl+20

		AUXInfo.pos = {xx+30,yy+cl}
		AUXInfo.color = AccentColor
		AUXInfo.text = "Sample>   " .. string.gsub(string.gsub(string.lower(myplayer:GetInfo( "cl_playermodel" )), '[- ]', '_' ), '[.:,;"\'()!@#$%^&*`~]', '')
		draw.Text( AUXInfo )
		cl = cl+20

		AUXInfo.pos = {xx+30,yy+cl}
		AUXInfo.color = AccentColor
		AUXInfo.text = "DNA: Resistance>   " .. myplayer:GetMaxHealth()
		draw.Text( AUXInfo )
		cl = cl+20

		AUXInfo.pos = {xx+30,yy+cl}
		AUXInfo.color = AccentColor
		if !mee_spr_multiplier then AUXInfo.text = "DNA: Legs Power>   " .. math.SnapTo(myplayer:GetRunSpeed() / 400, 0.01) .. "x"
		else AUXInfo.text = "DNA: Legs Power>   " .. math.SnapTo(myplayer:GetRunSpeed() / mee_spr_multiplier:GetFloat() / 400, 0.01) .. "x" end
		draw.Text( AUXInfo )
		cl = cl+20

		if mee_spr_multiplier then 
			AUXInfo.pos = {xx+30,yy+cl}
			AUXInfo.color = AccentColor
			AUXInfo.text = "DNA: Growth>   " .. math.SnapTo(mee_spr_multiplier:GetFloat(), 0.01) .."x"
			draw.Text( AUXInfo )
			cl = cl+20
		end

		cl = cl+20

		if input.IsKeyDown(KEY_W) == true or input.IsKeyDown(KEY_A) == true or input.IsKeyDown(KEY_S) == true or input.IsKeyDown(KEY_D) == true then
			AUXInfo.pos = {xx+30,yy+cl}
			AUXInfo.color = AccentColor
			if myplayer:IsSprinting() == true then AUXInfo.text = "CNS: Legs.Run"
			else
				AUXInfo.text = "CNS: Legs.Walk"
			end
			draw.Text( AUXInfo )
			cl = cl+20
		end

		if myplayer:GetEyeTraceNoCursor().Entity:GetClass() != "worldspawn" then
			AUXInfo.pos = {xx+30,yy+cl}
			AUXInfo.color = AccentColor
			AUXInfo.text = "CNS: Mind " .. myplayer:GetEyeTraceNoCursor().Entity:GetClass()
			draw.Text( AUXInfo )
			cl = cl+20
		end
	end

	hook.Add( 'HUDPaint', 'zLFHUD_DrawHUD', DrawTheHUD )
	hook.Add( 'HUDPaint', 'zLFHUD_PlayerInfo', PlayerInfo )

	-- if input.IsKeyDown(KEY_C) == false then hook.Remove('HUDPaint', 'zLFHUD_PlayerInfo') end

	hook.Add( 'HUDShouldDraw', 'HideHUD', HideHUD )


	local function CusElMenu( Panel )
		Panel:ClearControls()
		Panel:AddControl( "Color", {
			Label = "Lines Color",
			Red = "lfh_accent_color_r",
			Green = "lfh_accent_color_g",
			Blue = "lfh_accent_color_b",
			Alpha = "lfh_accent_color_a"
			} )

		local elembox, label = Panel:ComboBox("Shape:", "lfh_shape_el")
		elembox:AddChoice("Parallelogram (default)", "-16")
		elembox:AddChoice("Rectangle", "-1")
	end
	
	local function CreateMenus()
		spawnmenu.AddToolMenuOption( "Options", "LambdaForces", "lfh_cus_el", "Elements Customize", "", "",CusElMenu )
	end
	hook.Add( "PopulateToolMenu", "lfhud", CreateMenus )

end