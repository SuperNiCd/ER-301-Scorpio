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

    -- create output lpfs
    local lpO1 = self:createObject("StereoLadderFilter","lpO1")
    local lpO2 = self:createObject("StereoLadderFilter","lpO2")
    local lpO3 = self:createObject("StereoLadderFilter","lpO3")
    local lpO4 = self:createObject("StereoLadderFilter","lpO4")

    -- create output hpfs
    local hpO1 = self:createObject("StereoLadderHPF","hpI1")
    local hpO2 = self:createObject("StereoLadderHPF","hpO2")
    local hpO3 = self:createObject("StereoLadderHPF","hpO3")
    local hpO4 = self:createObject("StereoLadderHPF","hpO4")

    -- create envelope followers
    local ef1 = self:createObject("EnvelopeFollower", "ef1")
    local ef2 = self:createObject("EnvelopeFollower", "ef2")
    local ef3 = self:createObject("EnvelopeFollower", "ef3")
    local ef4 = self:createObject("EnvelopeFollower", "ef4")

    -- create Constants for input filter frequencies
    local lpI1f0 = self:createObject("Constant","lpI1f0")
    local lpI2f0 = self:createObject("Constant","lpI2f0")
    local lpI3f0 = self:createObject("Constant","lpI3f0")
    local lpI4f0 = self:createObject("Constant","lpI4f0")
    local hpI1f0 = self:createObject("Constant","hpI1f0")
    local hpI2f0 = self:createObject("Constant","hpI2f0")
    local hpI3f0 = self:createObject("Constant","hpI3f0")
    local hpI4f0 = self:createObject("Constant","hpI4f0")

    -- create Constants for output filter frequencies
    local lpO1f0 = self:createObject("Constant","lpO1f0")
    local lpO2f0 = self:createObject("Constant","lpO2f0")
    local lpO3f0 = self:createObject("Constant","lpO3f0")
    local lpO4f0 = self:createObject("Constant","lpO4f0")
    local hpO1f0 = self:createObject("Constant","hpO1f0")
    local hpO2f0 = self:createObject("Constant","hpO2f0")
    local hpO3f0 = self:createObject("Constant","hpO3f0")
    local hpO4f0 = self:createObject("Constant","hpO4f0")  

    -- create output vcas
    local ogain1 = self:createObject("Multiply","ogain1")
    local ogain2 = self:createObject("Multiply","ogain2")
    local ogain3 = self:createObject("Multiply","ogain3")
    local ogain4 = self:createObject("Multiply","ogain4")
    
    -- create output mixers
    local omix1 = self:createObject("Sum","omix1")
    local omix2 = self:createObject("Sum","omix2")
    local omix3 = self:createObject("Sum","omix3")
    local omix4 = self:createObject("Sum","omix4")

    -- create a saw osc (just for testing for now)
    local saw = self:createObject("SawtoothOscillator","saw")
    local sawf0 = self:createObject("Constant","sawf0")
    sawf0:hardSet("Value",440.0)
    connect(sawf0,"Out",saw,"Fundamental")

    -- set f0 for all input bpfs
    lpI1f0:hardSet("Value",400.0)
    hpI1f0:hardSet("Value",400.0)
    lpI2f0:hardSet("Value",1200.0)
    hpI2f0:hardSet("Value",1200.0)
    lpI3f0:hardSet("Value",3000.0)
    hpI3f0:hardSet("Value",3000.0)
    lpI4f0:hardSet("Value",6000.0)
    hpI4f0:hardSet("Value",6000.0)  

    -- set f0 for all output bpfs
    lpO1f0:hardSet("Value",400.0)
    hpO1f0:hardSet("Value",400.0)
    lpO2f0:hardSet("Value",1200.0)
    hpO2f0:hardSet("Value",1200.0)
    lpO3f0:hardSet("Value",3000.0)
    hpO3f0:hardSet("Value",3000.0)
    lpO4f0:hardSet("Value",6000.0)
    hpO4f0:hardSet("Value",6000.0)     
    
    -- connect frequency constants to the input filter DSP fundamentals
    connect(lpI1f0,"Out",lpI1,"Fundamental")
    connect(lpI2f0,"Out",lpI2,"Fundamental")
    connect(lpI3f0,"Out",lpI3,"Fundamental")
    connect(lpI4f0,"Out",lpI4,"Fundamental")
    connect(hpI1f0,"Out",hpI1,"Fundamental")
    connect(hpI2f0,"Out",hpI2,"Fundamental")
    connect(hpI3f0,"Out",hpI3,"Fundamental")
    connect(hpI4f0,"Out",hpI4,"Fundamental")

    -- connect frequency constants to the output filter DSP fundamentals
    connect(lpO1f0,"Out",lpO1,"Fundamental")
    connect(lpO2f0,"Out",lpO2,"Fundamental")
    connect(lpO3f0,"Out",lpO3,"Fundamental")
    connect(lpO4f0,"Out",lpO4,"Fundamental")
    connect(hpO1f0,"Out",hpO1,"Fundamental")
    connect(hpO2f0,"Out",hpO2,"Fundamental")
    connect(hpO3f0,"Out",hpO3,"Fundamental")
    connect(hpO4f0,"Out",hpO4,"Fundamental")    

    -- connect input filter pairs in series
    connect(lpI1,"Left Out",hpI1,"Left In")
    connect(lpI2,"Left Out",hpI2,"Left In")
    connect(lpI3,"Left Out",hpI3,"Left In")
    connect(lpI4,"Left Out",hpI4,"Left In")

    -- connect output filter pairs in series
    connect(lpO1,"Left Out",hpO1,"Left In")
    connect(lpO2,"Left Out",hpO2,"Left In")
    connect(lpO3,"Left Out",hpO3,"Left In")
    connect(lpO4,"Left Out",hpO4,"Left In")    

    -- connect modulator (unit input) to BPFs in parallel
    connect(pUnit,"In1",lpI1,"Left In")
    connect(pUnit,"In1",lpI2,"Left In")
    connect(pUnit,"In1",lpI3,"Left In")
    connect(pUnit,"In1",lpI4,"Left In")

    -- connect input BPFs to envelope followers
    connect(hpI1,"Left Out",ef1,"In")
    connect(hpI2,"Left Out",ef2,"In")
    connect(hpI3,"Left Out",ef3,"In")
    connect(hpI4,"Left Out",ef4,"In")

    -- connect output of envelope followers to left side of output VCAs
    connect(ef1,"Out",ogain1,"Left")
    connect(ef2,"Out",ogain2,"Left")
    connect(ef3,"Out",ogain3,"Left")
    connect(ef4,"Out",ogain4,"Left")

    -- connect saw oscillator to the input of the output BPFs
    connect(saw,"Out",lpO1,"Left In")
    connect(saw,"Out",lpO2,"Left In")
    connect(saw,"Out",lpO3,"Left In")
    connect(saw,"Out",lpO4,"Left In")

    -- connect output of output BPFs to right side of output mixers
    connect(hpO1,"Left Out",ogain1,"Right")
    connect(hpO2,"Left Out",ogain2,"Right")
    connect(hpO3,"Left Out",ogain3,"Right")
    connect(hpO4,"Left Out",ogain4,"Right")

    -- mix output output of the output VCAs
    connect(ogain1,"Out",omix1,"Left")
    connect(ogain2,"Out",omix1,"Right")
    connect(omix1,"Out",omix2,"Left")
    connect(ogain3,"Out",omix2,"Right")
    connect(omix2,"Out",omix3,"Left")
    connect(ogain4,"Out",omix3,"Right")

    -- send band passed mix to unit output
     connect(omix3,"Out",pUnit,"Out1")
    
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
