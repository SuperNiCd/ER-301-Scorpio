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

    -- create a fixed HPF for the modulator
    local inputHPF = self:createObject("StereoFixedHPF","inputHPF")
    local inputHPFf0 = self:createObject("GainBias","inputHPFf0")
    local inputHPFRange = self:createObject("MinMax","inputHPFRange")
    connect(inputHPFf0,"Out",inputHPFRange,"In")

    -- create an output (make up) gain and control
    local outputGain = self:createObject("Multiply","outputGain")
    local outputLevel = self:createObject("GainBias","outputLevel")
    local outputLevelRange = self:createObject("MinMax","outputLevelRange")

    -- create input lpfs
    local lpI1 = self:createObject("StereoLadderFilter","lpI1")
    local lpI2 = self:createObject("StereoLadderFilter","lpI2")
    local lpI3 = self:createObject("StereoLadderFilter","lpI3")
    local lpI4 = self:createObject("StereoLadderFilter","lpI4")
    local lpI5 = self:createObject("StereoLadderFilter","lpI5")
    local lpI6 = self:createObject("StereoLadderFilter","lpI6")
    local lpI7 = self:createObject("StereoLadderFilter","lpI7")
    local lpI8 = self:createObject("StereoLadderFilter","lpI8")
    local lpI9 = self:createObject("StereoLadderFilter","lpI9")
    local lpI10 = self:createObject("StereoLadderFilter","lpI10")


    --create input hpfs
    local hpI1 = self:createObject("StereoLadderHPF","hpI1")
    local hpI2 = self:createObject("StereoLadderHPF","hpI2")
    local hpI3 = self:createObject("StereoLadderHPF","hpI3")
    local hpI4 = self:createObject("StereoLadderHPF","hpI4")
    local hpI5 = self:createObject("StereoLadderHPF","hpI5")
    local hpI6 = self:createObject("StereoLadderHPF","hpI6")
    local hpI7 = self:createObject("StereoLadderHPF","hpI7")
    local hpI8 = self:createObject("StereoLadderHPF","hpI8")
    local hpI9 = self:createObject("StereoLadderHPF","hpI9")
    local hpI10 = self:createObject("StereoLadderHPF","hpI10")

    -- create output lpfs
    local lpO1 = self:createObject("StereoLadderFilter","lpO1")
    local lpO2 = self:createObject("StereoLadderFilter","lpO2")
    local lpO3 = self:createObject("StereoLadderFilter","lpO3")
    local lpO4 = self:createObject("StereoLadderFilter","lpO4")
    local lpO5 = self:createObject("StereoLadderFilter","lpO5")
    local lpO6 = self:createObject("StereoLadderFilter","lpO6")
    local lpO7 = self:createObject("StereoLadderFilter","lpO7")
    local lpO8 = self:createObject("StereoLadderFilter","lpO8")
    local lpO9 = self:createObject("StereoLadderFilter","lpO9")
    local lpO10 = self:createObject("StereoLadderFilter","lpO10")

    -- create output hpfs
    local hpO1 = self:createObject("StereoLadderHPF","hpO1")
    local hpO2 = self:createObject("StereoLadderHPF","hpO2")
    local hpO3 = self:createObject("StereoLadderHPF","hpO3")
    local hpO4 = self:createObject("StereoLadderHPF","hpO4")
    local hpO5 = self:createObject("StereoLadderHPF","hpO5")
    local hpO6 = self:createObject("StereoLadderHPF","hpO6")
    local hpO7 = self:createObject("StereoLadderHPF","hpO7")
    local hpO8 = self:createObject("StereoLadderHPF","hpO8")
    local hpO9 = self:createObject("StereoLadderHPF","hpO8")
    local hpO10 = self:createObject("StereoLadderHPF","hpO10")
  

    -- create envelope followers
    local ef1 = self:createObject("EnvelopeFollower", "ef1")
    local ef2 = self:createObject("EnvelopeFollower", "ef2")
    local ef3 = self:createObject("EnvelopeFollower", "ef3")
    local ef4 = self:createObject("EnvelopeFollower", "ef4")
    local ef5 = self:createObject("EnvelopeFollower", "ef5")
    local ef6 = self:createObject("EnvelopeFollower", "ef6")
    local ef7 = self:createObject("EnvelopeFollower", "ef7")
    local ef8 = self:createObject("EnvelopeFollower", "ef8")
    local ef9 = self:createObject("EnvelopeFollower", "ef9")
    local ef10 = self:createObject("EnvelopeFollower", "ef10")


    -- local localVars = {}

    -- local objectList = {
    --   lpI = { "StereoLadderFilter" },
    --   hpI = { "StereoLadderHPF" },
    --   lpO = { "StereoLadderFilter" },
    --   hpO = { "StereoLadderHPF" },
    --   ef  = { "EvelopeFollower" },
    -- }

    -- for k, v in pairs(objectList) do
    --   for i = 1, 4 do
    --     dynamicvar = k .. i
    --     localVars[dynamicvar] = self:createObject([v[1]],dynamicvar)
    --   end
    -- end

    -- create envelope follower controls
    local attack = self:createObject("ParameterAdapter","attack")
    local release = self:createObject("ParameterAdapter","release")

    -- create constant offsets for bpf fundamentals
    local bp1f0 = self:createObject("GainBias","bp1f0")
    local bp2f0 = self:createObject("GainBias","bp2f0")
    local bp3f0 = self:createObject("GainBias","bp3f0")
    local bp4f0 = self:createObject("GainBias","bp4f0")
    local bp5f0 = self:createObject("GainBias","bp5f0")
    local bp6f0 = self:createObject("GainBias","bp6f0")
    local bp7f0 = self:createObject("GainBias","bp7f0")
    local bp8f0 = self:createObject("GainBias","bp8f0")
    local bp9f0 = self:createObject("GainBias","bp9f0")
    local bp10f0 = self:createObject("GainBias","bp10f0")

    -- create frequency ranges for BPF f0s
    local bp1f0Range = self:createObject("MinMax","bp1f0Range")
    local bp2f0Range = self:createObject("MinMax","bp2f0Range")
    local bp3f0Range = self:createObject("MinMax","bp3f0Range")
    local bp4f0Range = self:createObject("MinMax","bp4f0Range")
    local bp5f0Range = self:createObject("MinMax","bp5f0Range")
    local bp6f0Range = self:createObject("MinMax","bp6f0Range")
    local bp7f0Range = self:createObject("MinMax","bp7f0Range")
    local bp8f0Range = self:createObject("MinMax","bp8f0Range")
    local bp9f0Range = self:createObject("MinMax","bp9f0Range")
    local bp10f0Range = self:createObject("MinMax","bp10f0Range")

    -- create output vcas
    local ogain1 = self:createObject("Multiply","ogain1")
    local ogain2 = self:createObject("Multiply","ogain2")
    local ogain3 = self:createObject("Multiply","ogain3")
    local ogain4 = self:createObject("Multiply","ogain4")
    local ogain5 = self:createObject("Multiply","ogain5")
    local ogain6 = self:createObject("Multiply","ogain6")
    local ogain7 = self:createObject("Multiply","ogain7")
    local ogain8 = self:createObject("Multiply","ogain8")
    local ogain9 = self:createObject("Multiply","ogain9")
    local ogain10 = self:createObject("Multiply","ogain10")
    
    -- create output mixers
    local omix1 = self:createObject("Sum","omix1")
    local omix2 = self:createObject("Sum","omix2")
    local omix3 = self:createObject("Sum","omix3")
    local omix4 = self:createObject("Sum","omix4")
    local omix5 = self:createObject("Sum","omix5")
    local omix6 = self:createObject("Sum","omix6")
    local omix7 = self:createObject("Sum","omix7")
    local omix8 = self:createObject("Sum","omix8")
    local omix9 = self:createObject("Sum","omix9")
    local omix10 = self:createObject("Sum","omix10")

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
    connect(bp5f0,"Out",lpI5,"Fundamental")
    connect(bp6f0,"Out",lpI6,"Fundamental")
    connect(bp7f0,"Out",lpI7,"Fundamental")
    connect(bp8f0,"Out",lpI8,"Fundamental")
    connect(bp9f0,"Out",lpI9,"Fundamental")
    connect(bp10f0,"Out",lpI10,"Fundamental")

    connect(bp1f0,"Out",hpI1,"Fundamental")
    connect(bp2f0,"Out",hpI2,"Fundamental")
    connect(bp3f0,"Out",hpI3,"Fundamental")
    connect(bp4f0,"Out",hpI4,"Fundamental")
    connect(bp5f0,"Out",hpI5,"Fundamental")
    connect(bp6f0,"Out",hpI6,"Fundamental")
    connect(bp7f0,"Out",hpI7,"Fundamental")
    connect(bp8f0,"Out",hpI8,"Fundamental")
    connect(bp9f0,"Out",hpI9,"Fundamental")
    connect(bp10f0,"Out",hpI10,"Fundamental")

    -- connect frequency constants to the output filter DSP fundamentals
    connect(bp1f0,"Out",lpO1,"Fundamental")
    connect(bp2f0,"Out",lpO2,"Fundamental")
    connect(bp3f0,"Out",lpO3,"Fundamental")
    connect(bp4f0,"Out",lpO4,"Fundamental")
    connect(bp5f0,"Out",lpO5,"Fundamental")
    connect(bp6f0,"Out",lpO6,"Fundamental")
    connect(bp7f0,"Out",lpO7,"Fundamental")
    connect(bp8f0,"Out",lpO8,"Fundamental")
    connect(bp9f0,"Out",lpO9,"Fundamental")
    connect(bp10f0,"Out",lpO10,"Fundamental")

    connect(bp1f0,"Out",hpO1,"Fundamental")
    connect(bp2f0,"Out",hpO2,"Fundamental")
    connect(bp3f0,"Out",hpO3,"Fundamental")
    connect(bp4f0,"Out",hpO4,"Fundamental") 
    connect(bp5f0,"Out",hpO5,"Fundamental")
    connect(bp6f0,"Out",hpO6,"Fundamental")
    connect(bp7f0,"Out",hpO7,"Fundamental")
    connect(bp8f0,"Out",hpO8,"Fundamental")  
    connect(bp9f0,"Out",hpO9,"Fundamental")
    connect(bp10f0,"Out",hpO10,"Fundamental")
    
    -- connect frequency ranges to f0 sliders
    connect(bp1f0,"Out",bp1f0Range,"In")
    connect(bp2f0,"Out",bp2f0Range,"In")
    connect(bp3f0,"Out",bp3f0Range,"In")
    connect(bp4f0,"Out",bp4f0Range,"In")
    connect(bp5f0,"Out",bp5f0Range,"In")
    connect(bp6f0,"Out",bp6f0Range,"In")
    connect(bp7f0,"Out",bp7f0Range,"In")
    connect(bp8f0,"Out",bp8f0Range,"In")
    connect(bp9f0,"Out",bp9f0Range,"In")
    connect(bp10f0,"Out",bp10f0Range,"In")


    -- connect input filter pairs in series
    connect(lpI1,"Left Out",hpI1,"Left In")
    connect(lpI2,"Left Out",hpI2,"Left In")
    connect(lpI3,"Left Out",hpI3,"Left In")
    connect(lpI4,"Left Out",hpI4,"Left In")
    connect(lpI5,"Left Out",hpI5,"Left In")
    connect(lpI6,"Left Out",hpI6,"Left In")
    connect(lpI7,"Left Out",hpI7,"Left In")
    connect(lpI8,"Left Out",hpI8,"Left In")
    connect(lpI9,"Left Out",hpI9,"Left In")
    connect(lpI10,"Left Out",hpI10,"Left In")

    -- connect output filter pairs in series
    connect(lpO1,"Left Out",hpO1,"Left In")
    connect(lpO2,"Left Out",hpO2,"Left In")
    connect(lpO3,"Left Out",hpO3,"Left In")
    connect(lpO4,"Left Out",hpO4,"Left In")  
    connect(lpO5,"Left Out",hpO5,"Left In")
    connect(lpO6,"Left Out",hpO6,"Left In")
    connect(lpO7,"Left Out",hpO7,"Left In")
    connect(lpO8,"Left Out",hpO8,"Left In")  
    connect(lpO9,"Left Out",hpO9,"Left In")
    connect(lpO10,"Left Out",hpO10,"Left In")
 

    -- connect modulator (unit input) to fixed HPF
    connect(pUnit,"In1",inputHPF,"Left In")

    -- connect input HPF to BPFs in parallel
    connect(inputHPF,"Left Out",lpI1,"Left In")
    connect(inputHPF,"Left Out",lpI2,"Left In")
    connect(inputHPF,"Left Out",lpI3,"Left In")
    connect(inputHPF,"Left Out",lpI4,"Left In")
    connect(inputHPF,"Left Out",lpI5,"Left In")
    connect(inputHPF,"Left Out",lpI6,"Left In")
    connect(inputHPF,"Left Out",lpI7,"Left In")
    connect(inputHPF,"Left Out",lpI8,"Left In")
    connect(inputHPF,"Left Out",lpI9,"Left In")
    connect(inputHPF,"Left Out",lpI10,"Left In")

    -- connect input BPFs to envelope followers
    connect(hpI1,"Left Out",ef1,"In")
    connect(hpI2,"Left Out",ef2,"In")
    connect(hpI3,"Left Out",ef3,"In")
    connect(hpI4,"Left Out",ef4,"In")
    connect(hpI5,"Left Out",ef5,"In")
    connect(hpI6,"Left Out",ef6,"In")
    connect(hpI7,"Left Out",ef7,"In")
    connect(hpI8,"Left Out",ef8,"In")
    connect(hpI9,"Left Out",ef9,"In")
    connect(hpI10,"Left Out",ef10,"In")

    -- connect output of envelope followers to left side of output VCAs
    connect(ef1,"Out",ogain1,"Left")
    connect(ef2,"Out",ogain2,"Left")
    connect(ef3,"Out",ogain3,"Left")
    connect(ef4,"Out",ogain4,"Left")
    connect(ef5,"Out",ogain5,"Left")
    connect(ef6,"Out",ogain6,"Left")
    connect(ef7,"Out",ogain7,"Left")
    connect(ef8,"Out",ogain8,"Left")
    connect(ef9,"Out",ogain9,"Left")
    connect(ef10,"Out",ogain10,"Left")

    -- connect carrier to the input of the output BPFs
    connect(gain,"Out",lpO1,"Left In")
    connect(gain,"Out",lpO2,"Left In")
    connect(gain,"Out",lpO3,"Left In")
    connect(gain,"Out",lpO4,"Left In")
    connect(gain,"Out",lpO5,"Left In")
    connect(gain,"Out",lpO6,"Left In")
    connect(gain,"Out",lpO7,"Left In")
    connect(gain,"Out",lpO8,"Left In")
    connect(gain,"Out",lpO9,"Left In")
    connect(gain,"Out",lpO10,"Left In")

    -- tie attack and release
    tie(ef1,"Attack Time",attack,"Out")
    tie(ef2,"Attack Time",attack,"Out")
    tie(ef3,"Attack Time",attack,"Out")
    tie(ef4,"Attack Time",attack,"Out")
    tie(ef5,"Attack Time",attack,"Out")
    tie(ef6,"Attack Time",attack,"Out")
    tie(ef7,"Attack Time",attack,"Out")
    tie(ef8,"Attack Time",attack,"Out")
    tie(ef9,"Attack Time",attack,"Out")
    tie(ef10,"Attack Time",attack,"Out")
    self:addBranch("attack","Attack",attack,"In")

    tie(ef1,"Release Time",release,"Out")
    tie(ef2,"Release Time",release,"Out")
    tie(ef3,"Release Time",release,"Out")
    tie(ef4,"Release Time",release,"Out")
    tie(ef5,"Release Time",release,"Out")
    tie(ef6,"Release Time",release,"Out")
    tie(ef7,"Release Time",release,"Out")
    tie(ef8,"Release Time",release,"Out")
    tie(ef9,"Release Time",release,"Out")
    tie(ef10,"Release Time",release,"Out")
    self:addBranch("release","Release",release,"In")

    -- connect output of output BPFs to right side of output mixers
    connect(hpO1,"Left Out",ogain1,"Right")
    connect(hpO2,"Left Out",ogain2,"Right")
    connect(hpO3,"Left Out",ogain3,"Right")
    connect(hpO4,"Left Out",ogain4,"Right")
    connect(hpO5,"Left Out",ogain5,"Right")
    connect(hpO6,"Left Out",ogain6,"Right")
    connect(hpO7,"Left Out",ogain7,"Right")
    connect(hpO8,"Left Out",ogain8,"Right")
    connect(hpO9,"Left Out",ogain9,"Right")
    connect(hpO10,"Left Out",ogain10,"Right")

    -- mix output output of the output VCAs
    connect(ogain1,"Out",omix1,"Left")
    connect(ogain2,"Out",omix1,"Right")
    connect(omix1,"Out",omix2,"Left")
    connect(ogain3,"Out",omix2,"Right")
    connect(omix2,"Out",omix3,"Left")
    connect(ogain4,"Out",omix3,"Right")

    connect(omix3,"Out",omix4,"Left")
    connect(ogain5,"Out",omix4,"Right")
    connect(omix4,"Out",omix5,"Left")
    connect(ogain6,"Out",omix5,"Right")
    connect(omix5,"Out",omix6,"Left")
    connect(ogain7,"Out",omix6,"Right")
    connect(omix6,"Out",omix7,"Left")
    connect(ogain8,"Out",omix7,"Right")
    connect(omix7,"Out",omix8,"Left")
    connect(ogain9,"Out",omix8,"Right")
    connect(omix8,"Out",omix9,"Left")
    connect(ogain10,"Out",omix9,"Right")

    -- send band passed mix to unit output
     connect(omix9,"Out",pUnit,"Out1")
    
    -- register exported ports
    self:addBranch("input","Input", gain, "In")
    self:addBranch("inputHPFf0","inHPF", inputHPFf0,"In")
    self:addBranch("bp1f0","f1",bp1f0,"In")
    self:addBranch("bp2f0","f2",bp2f0,"In")
    self:addBranch("bp3f0","f3",bp3f0,"In")
    self:addBranch("bp4f0","f4",bp4f0,"In")
    self:addBranch("bp5f0","f5",bp5f0,"In")
    self:addBranch("bp6f0","f6",bp6f0,"In")
    self:addBranch("bp7f0","f7",bp7f0,"In")
    self:addBranch("bp8f0","f8",bp8f0,"In")
    self:addBranch("bp9f0","f9",bp9f0,"In")
    self:addBranch("bp10f0","f10",bp10f0,"In")


end

local controlMode = "yes"

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
    extended = {"gain", "inHPF", "f1", "f2", "f3", "f4", "f5", "f6", "f7", "f8", "f9", "f10", "attack","release"}
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
    initialBias = 200,
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
    initialBias = 250,
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
    initialBias = 500,
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
    initialBias = 800,
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
    initialBias = 1200,
    gainMap = Encoder.getMap("freqGain"),
    scaling = app.octaveScaling
  }

  controls.f5 = GainBias {
    button = "f5",
    branch = self:getBranch("f5"),
    description = "f5",
    gainbias = objects.bp5f0,
    range = objects.bp5f0Range,
    biasMap = Encoder.getMap("filterFreq"),
    biasUnits = app.unitHertz,
    initialBias = 2000,
    gainMap = Encoder.getMap("freqGain"),
    scaling = app.octaveScaling
  }

  controls.f6 = GainBias {
    button = "f6",
    branch = self:getBranch("f6"),
    description = "f6",
    gainbias = objects.bp6f0,
    range = objects.bp6f0Range,
    biasMap = Encoder.getMap("filterFreq"),
    biasUnits = app.unitHertz,
    initialBias = 3200,
    gainMap = Encoder.getMap("freqGain"),
    scaling = app.octaveScaling
  }

  controls.f7 = GainBias {
    button = "f7",
    branch = self:getBranch("f7"),
    description = "f7",
    gainbias = objects.bp7f0,
    range = objects.bp7f0Range,
    biasMap = Encoder.getMap("filterFreq"),
    biasUnits = app.unitHertz,
    initialBias = 5600,
    gainMap = Encoder.getMap("freqGain"),
    scaling = app.octaveScaling
  }

  controls.f8 = GainBias {
    button = "f8",
    branch = self:getBranch("f8"),
    description = "f8",
    gainbias = objects.bp8f0,
    range = objects.bp8f0Range,
    biasMap = Encoder.getMap("filterFreq"),
    biasUnits = app.unitHertz,
    initialBias = 7000,
    gainMap = Encoder.getMap("freqGain"),
    scaling = app.octaveScaling
  }

  controls.f9 = GainBias {
    button = "f9",
    branch = self:getBranch("f9"),
    description = "f9",
    gainbias = objects.bp9f0,
    range = objects.bp9f0Range,
    biasMap = Encoder.getMap("filterFreq"),
    biasUnits = app.unitHertz,
    initialBias = 9000,
    gainMap = Encoder.getMap("freqGain"),
    scaling = app.octaveScaling
  }

  controls.f10 = GainBias {
    button = "f10",
    branch = self:getBranch("f10"),
    description = "f10",
    gainbias = objects.bp10f0,
    range = objects.bp10f0Range,
    biasMap = Encoder.getMap("filterFreq"),
    biasUnits = app.unitHertz,
    initialBias = 12000,
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
    description = string.format("Display advanced controls: %s.",controlMode)
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
