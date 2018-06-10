-- GLOBALS: app, os, verboseLevel, connect, tie
local app = app
local Class = require "Base.Class"
local Unit = require "Unit"
local BranchMeter = require "Unit.ViewControl.BranchMeter"
local GainBias = require "Unit.ViewControl.GainBias"
local Encoder = require "Encoder"
local ply = app.SECTION_PLY

local Vocoder = Class{}
Vocoder:include(Unit)

function Vocoder:init(args)
  args.title = "Vocoder"
  args.mnemonic = "Vc"
  Unit.init(self,args)
end

function Vocoder:onLoadGraph(pUnit,channelCount)

    -- create the carrier subchain and level control
    local sum = self:createObject("Sum","sum")
    local gain = self:createObject("ConstantGain","gain")
    gain:setClampInDecibels(-59.9)
    gain:hardSet("Gain",1.0)

    -- create input lpfs
    local lpI1 = self:createObject("StereoLadderFilter","lpI1")
    local lpI2 = self:createObject("StereoLadderFilter","lpI2")
    local lpI3 = self:createObject("StereoLadderFilter","lpI3")
    local lpI4 = self:createObject("StereoLadderFilter","lpI4")

    --create input hpfs
    local hpI1 = self:createObject("StereoLadderHPF","hpI1")
    local hpI2 = self:createObject("StereoLadderHPF","hpI2")
    local hpI3 = self:createObject("StereoLadderHPF","hpI3")
    local hpI4 = self:createObject("StereoLadderHPF","hpI4")

    -- create Constants for filter frequencies
    local lpI1f0 = self:createObject("Constant","lpI1f0")
    local lpI2f0 = self:createObject("Constant","lpI2f0")
    local lpI3f0 = self:createObject("Constant","lpI3f0")
    local lpI4f0 = self:createObject("Constant","lpI4f0")
    local hpI1f0 = self:createObject("Constant","hpI1f0")
    local hpI2f0 = self:createObject("Constant","hpI2f0")
    local hpI3f0 = self:createObject("Constant","hpI3f0")
    local hpI4f0 = self:createObject("Constant","hpI4f0")

    -- set f0 for all input bpfs
    lpI1f0:hardSet("Value",400.0)
    hpI1f0:hardSet("Value",400.0)
    lpI2f0:hardSet("Value",1200.0)
    hpI2f0:hardSet("Value",1200.0)
    lpI3f0:hardSet("Value",3000.0)
    hpI3f0:hardSet("Value",3000.0)
    lpI4f0:hardSet("Value",6000.0)
    hpI4f0:hardSet("Value",6000.0)  
    
    -- connect frequency constants to the input filter DSP fundamentals
    connect(lpI1f0,"Out",lpI1,"Fundamental")
    connect(lpI2f0,"Out",lpI2,"Fundamental")
    connect(lpI3f0,"Out",lpI3,"Fundamental")
    connect(lpI4f0,"Out",lpI4,"Fundamental")
    connect(hpI1f0,"Out",hpI1,"Fundamental")
    connect(hpI2f0,"Out",hpI2,"Fundamental")
    connect(hpI3f0,"Out",hpI3,"Fundamental")
    connect(hpI4f0,"Out",hpI4,"Fundamental")

    -- create input mixers
    local imix1 = self:createObject("Sum","sum")
    local imix2 = self:createObject("Sum","sum")
    local imix3 = self:createObject("Sum","sum")
    local imix4 = self:createObject("Sum","sum")

    -- connect filter pairs in series
    connect(lpI1,"Left Out",hpI1,"Left In")
    connect(lpI2,"Left Out",hpI2,"Left In")
    connect(lpI3,"Left Out",hpI3,"Left In")
    connect(lpI4,"Left Out",hpI4,"Left In")

    -- connect modulator (unit input) to BPFs in parallel
    connect(pUnit,"In1",lpI1,"Left In")
    connect(pUnit,"In1",lpI2,"Left In")
    connect(pUnit,"In1",lpI3,"Left In")
    connect(pUnit,"In1",lpI4,"Left In")

    -- mix output of input BPFs
    -- connect(hpI1,"Left Out",imix1,"Left")
    -- connect(hpI2,"Left Out",imix1,"Right")
    -- connect(imix1,"Out",imix2,"Left")
    -- connect(hpI3,"Left Out",imix2,"Right")
    -- connect(imix2,"Out",imix3,"Left")
    connect(hpI4,"Left Out",imix4,"Right")

    -- send band passed mix to unit output
     connect(imix4,"Out",pUnit,"Out1")
    
    -- register exported ports
    self:addBranch("input","Input", gain, "In")

end


function Vocoder:onLoadViews(objects,controls)
  local views = {
    expanded = {"gain"},
    collapsed = {},
  }

  controls.gain = BranchMeter {
    button = "carrier",
    branch = self:getBranch("Input"),
    faderParam = objects.gain:getParameter("Gain")
  }

  --self:addToMuteGroup(controls.gain)


  return views
end

-- function Vocoder:serialize()
--   local t = Unit.serialize(self)
--   t.mute = self.controls.gain:isMuted()
--   t.solo = self.controls.gain:isSolo()
--   return t
-- end

-- function Vocoder:deserialize(t)
--   Unit.deserialize(self,t)
--   if t.mute then
--     self.controls.gain:mute()
--   end
--   if t.solo then
--     self.controls.gain:solo()
--   end
-- end

return Vocoder
