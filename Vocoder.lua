-- GLOBALS: app, os, verboseLevel, connect, tie
local app = app
local Class = require "Base.Class"
local Unit = require "Unit"
local BranchMeter = require "Unit.ViewControl.BranchMeter"
local GainBias = require "Unit.ViewControl.GainBias"
local Task = require "Unit.MenuControl.Task"
local MenuHeader = require "Unit.MenuControl.Header"
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


    local inputHPF = self:createObject("StereoFixedHPF","inputHPF")
    local inputHPFf0 = self:createObject("GainBias","inputHPFf0")
    local inputHPFRange = self:createObject("MinMax","inputHPFRange")
    connect(inputHPFf0,"Out",inputHPFRange,"In")

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

    -- create envelope follower controls
    local attack = self:createObject("ParameterAdapter","attack")
    local release = self:createObject("ParameterAdapter","release")

    -- create constant offsets for bpf fundamentals
    local bp1f0 = self:createObject("GainBias","bp1f0")
    local bp2f0 = self:createObject("GainBias","bp2f0")
    local bp3f0 = self:createObject("GainBias","bp3f0")
    local bp4f0 = self:createObject("GainBias","bp4f0")

    -- create frequency ranges for BPF f0s
    local bp1f0Range = self:createObject("MinMax","bp1f0Range")
    local bp2f0Range = self:createObject("MinMax","bp2f0Range")
    local bp3f0Range = self:createObject("MinMax","bp3f0Range")
    local bp4f0Range = self:createObject("MinMax","bp4f0Range")

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
    -- local saw = self:createObject("SawtoothOscillator","saw")
    -- local sawf0 = self:createObject("Constant","sawf0")
    -- sawf0:hardSet("Value",440.0)
    -- connect(sawf0,"Out",saw,"Fundamental")

    -- set f0 for all bpfs
    -- bp1f0:hardSet("Bias",400.0)
    -- bp2f0:hardSet("Bias",1200.0)
    -- bp3f0:hardSet("Bias",3000.0)
    -- bp4f0:hardSet("Bias",6000.0)
    
    -- connect frequency constants to the input filter DSP fundamentals
    connect(bp1f0,"Out",lpI1,"Fundamental")
    connect(bp2f0,"Out",lpI2,"Fundamental")
    connect(bp3f0,"Out",lpI3,"Fundamental")
    connect(bp4f0,"Out",lpI4,"Fundamental")
    connect(bp1f0,"Out",hpI1,"Fundamental")
    connect(bp2f0,"Out",hpI2,"Fundamental")
    connect(bp3f0,"Out",hpI3,"Fundamental")
    connect(bp4f0,"Out",hpI4,"Fundamental")

    -- connect frequency constants to the output filter DSP fundamentals
    connect(bp1f0,"Out",lpO1,"Fundamental")
    connect(bp2f0,"Out",lpO2,"Fundamental")
    connect(bp3f0,"Out",lpO3,"Fundamental")
    connect(bp4f0,"Out",lpO4,"Fundamental")
    connect(bp1f0,"Out",hpO1,"Fundamental")
    connect(bp2f0,"Out",hpO2,"Fundamental")
    connect(bp3f0,"Out",hpO3,"Fundamental")
    connect(bp4f0,"Out",hpO4,"Fundamental")   
    
    -- connect frequency ranges to f0 sliders
    connect(bp1f0,"Out",bp1f0Range,"In")
    connect(bp2f0,"Out",bp2f0Range,"In")
    connect(bp3f0,"Out",bp3f0Range,"In")
    connect(bp4f0,"Out",bp4f0Range,"In")

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

    -- connect modulator (unit input) to fixed HPF
    connect(pUnit,"In1",inputHPF,"Left In")

    -- connect input HPF to BPFs in parallel
    connect(inputHPF,"Left Out",lpI1,"Left In")
    connect(inputHPF,"Left Out",lpI2,"Left In")
    connect(inputHPF,"Left Out",lpI3,"Left In")
    connect(inputHPF,"Left Out",lpI4,"Left In")

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
    connect(gain,"Out",lpO1,"Left In")
    connect(gain,"Out",lpO2,"Left In")
    connect(gain,"Out",lpO3,"Left In")
    connect(gain,"Out",lpO4,"Left In")

    -- tie attack and release
    tie(ef1,"Attack Time",attack,"Out")
    tie(ef2,"Attack Time",attack,"Out")
    tie(ef3,"Attack Time",attack,"Out")
    tie(ef4,"Attack Time",attack,"Out")
    self:addBranch("attack","Attack",attack,"In")
    tie(ef1,"Release Time",release,"Out")
    tie(ef2,"Release Time",release,"Out")
    tie(ef3,"Release Time",release,"Out")
    tie(ef4,"Release Time",release,"Out")
    self:addBranch("release","Release",release,"In")

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
    self:addBranch("inputHPFf0","inHPF", inputHPFf0,"In")
    self:addBranch("bp1f0","f1",bp1f0,"In")
    self:addBranch("bp2f0","f2",bp2f0,"In")
    self:addBranch("bp3f0","f3",bp3f0,"In")
    self:addBranch("bp4f0","f4",bp4f0,"In")

end

local controlMode = "no"

function Vocoder:changeControlMode(mode)
  controlMode = mode
  if controlMode=="no" then
    self:switchView("expanded")
  else
      self:switchView("extended")
  end
end

function Vocoder:onLoadViews(objects,controls)
    local views = {
    expanded = {"gain", "inHPF"},
    collapsed = {},
    extended = {"gain", "inHPF", "f1", "f2", "f3", "f4","attack","release"}
  }
  

  controls.gain = BranchMeter {
    button = "carrier",
    branch = self:getBranch("Input"),
    faderParam = objects.gain:getParameter("Gain")
  }

  controls.inHPF = GainBias {
    button = "inHPF",
    branch = self:getBranch("inHPF"),
    description = "inHPF",
    gainbias = objects.inputHPFf0,
    range = objects.inputHPFRange,
    biasMap = Encoder.getMap("filterFreq"),
    biasUnits = app.unitHertz,
    initialBias = 440,
    gainMap = Encoder.getMap("freqGain"),
    scaling = app.octaveScaling
  }

  controls.f1 = GainBias {
    button = "f1",
    branch = self:getBranch("f1"),
    description = "f1",
    gainbias = objects.bp1f0,
    range = objects.bp1f0Range,
    biasMap = Encoder.getMap("filterFreq"),
    biasUnits = app.unitHertz,
    initialBias = 440,
    gainMap = Encoder.getMap("freqGain"),
    scaling = app.octaveScaling
  }

  controls.f2 = GainBias {
    button = "f2",
    branch = self:getBranch("f2"),
    description = "f2",
    gainbias = objects.bp2f0,
    range = objects.bp2f0Range,
    biasMap = Encoder.getMap("filterFreq"),
    biasUnits = app.unitHertz,
    initialBias = 1200,
    gainMap = Encoder.getMap("freqGain"),
    scaling = app.octaveScaling
  }

  controls.f3 = GainBias {
    button = "f3",
    branch = self:getBranch("f3"),
    description = "f3",
    gainbias = objects.bp3f0,
    range = objects.bp3f0Range,
    biasMap = Encoder.getMap("filterFreq"),
    biasUnits = app.unitHertz,
    initialBias = 3000,
    gainMap = Encoder.getMap("freqGain"),
    scaling = app.octaveScaling
  }  
  
  controls.f4 = GainBias {
    button = "f4",
    branch = self:getBranch("f4"),
    description = "f4",
    gainbias = objects.bp4f0,
    range = objects.bp4f0Range,
    biasMap = Encoder.getMap("filterFreq"),
    biasUnits = app.unitHertz,
    initialBias = 6000,
    gainMap = Encoder.getMap("freqGain"),
    scaling = app.octaveScaling
  }

  controls.attack = GainBias {
    button = "attack",
    description = "Attack Time",
    branch = self:getBranch("Attack"),
    gainbias = objects.attack,
    range = objects.attack,
    biasMap = Encoder.getMap("unit"),
    biasUnits = app.unitSecs,
    initialBias = 0.001
  }

  controls.release = GainBias {
    button = "release",
    description = "Release Time",
    branch = self:getBranch("Release"),
    gainbias = objects.release,
    range = objects.release,
    biasMap = Encoder.getMap("unit"),
    biasUnits = app.unitSecs,
    initialBias = 0.010
  }

  --self:addToMuteGroup(controls.gain)


  return views
end

local menu = {
  "setHeader",
  "setControlsNo",
  "setControlsYes",
}



function Vocoder:onLoadMenu(objects,controls)

  controls.setHeader = MenuHeader {
    description = string.format("Display fundamental controls: %s.",controlMode)
  }

  controls.setControlsNo = Task {
    description = "no",
    task = function() self:changeControlMode("no") end
  }

  controls.setControlsYes = Task {
    description = "yes",
    task = function() self:changeControlMode("yes") end
  }

  return menu
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
