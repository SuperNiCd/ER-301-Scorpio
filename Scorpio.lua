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

local Scorpio = Class{}
Scorpio:include(Unit)

function Scorpio:init(args)
  args.title = "Scorpio"
  args.mnemonic = "SC"
  Unit.init(self,args)
end

--[[ 
     To change the number of bands, change numBands to the desired number of bands.  Note that each band
     requires ~6% CPU usage.  You will need to supply a default frequency for each band in the table freqInitialBias.
     If an initial frequency is not supplied it will default to 0Hz, which will block the band.  Minimum 4 bands.
  ]]

local numBands = 10
local bw = (5000-300)/numBands

function Scorpio:onLoadGraph(pUnit,channelCount)

    -- create the carrier subchain and level control
    local sum = self:createObject("Sum","sum")
    local gain = self:createObject("ConstantGain","gain")
    gain:setClampInDecibels(-59.9)
    gain:hardSet("Gain",1.0)

    -- create a fixed HPF for the modulator - 20 Hz DC blocker
    local inputHPF = self:createObject("StereoFixedHPF","inputHPF")
    local inputHPFf0 = self:createObject("GainBias","inputHPFf0")
    inputHPFf0:hardSet("Bias",20.0)

    -- create an output (make up) gain and control
    local outputGain = self:createObject("Multiply","outputGain")
    local outputLevel = self:createObject("GainBias","outputLevel")
    local outputLevelRange = self:createObject("MinMax","outputLevelRange")

    -- create envelope follower controls - this will adjust attack and decay for all envelope followers together
    local envelope = self:createObject("ParameterAdapter", "envelope")

    -- create resonance (Q) controls for input and output BPFs
    local qIn = self:createObject("GainBias", "qIn")
    local qOut = self:createObject("GainBias", "qOut")
    local qInRange = self:createObject("MinMax", "qInRange")
    local qOutRange = self:createObject("MinMax", "qOutRange")

    -- create a fixed HPF for the modulator output mix
    local outputHPF = self:createObject("StereoLadderHPF","outputHPF")
    local outputHPFf0 = self:createObject("GainBias","outputHPFf0")
    local outputHPFf0Range = self:createObject("MinMax","outputHPFf0Range")

    -- create a mixer for the modulator output
    local outputModMix = self:createObject("Sum","outputModMix")
    local outputModLevel = self:createObject("GainBias","outputModLevel")
    local outputModGain = self:createObject("Multiply","outputModGain")
    local outputModLevelRange = self:createObject("MinMax", "outputModLevelRange")


    -- Create the objects that require one per band.  This is done in a nested loop for convenience and shorter code
    local localVars = {}

    -- define the different objects to be mass created
    local objectList = {
      lpI = { "StereoLadderFilter" },
      hpI = { "StereoLadderHPF" },
      lpO = { "StereoLadderFilter" },
      hpO = { "StereoLadderHPF" },
      ef  = { "EnvelopeFollower" },
      bpf0 = { "GainBias" },
      bpf0Range = { "MinMax" },
      fShiftSumLP = { "Sum" },
      fShiftSumHP  =  { "Sum" },
      ogain = { "Multiply" },
      omix = { "Sum" },
     }

     -- create numBands # instances of each object in objectList
    for k, v in pairs(objectList) do
      for i = 1, numBands do
        local dynamicVar = k .. i
        local dynamicDSPUnit = v[1]
        localVars[dynamicVar] = self:createObject(dynamicDSPUnit,dynamicVar)
      end
    end

    -- create the fShift control.  This control shifts the fundamentals of the output BPFs away from the input BPFs to
    -- change the timbre/character of the output sound
    local fShiftf0 = self:createObject("GainBias","fShiftf0")
    local fShiftf0Range = self:createObject("MinMax","fShiftf0Range")
    connect(fShiftf0,"Out",fShiftf0Range,"In")

    -- connect modulator (unit input) to fixed HPF
    connect(pUnit,"In1",inputHPF,"Left In")

    -- This loop wires the objects that were created in mass above together
    for i = 1,numBands do
      -- connect frequency constants to the input filter DSP fundamentals.  These controls are shown in the Display
      -- Frequency controls view, and adjust the center frequencies of the bandpass filters.
      connect(localVars["bpf0" .. i],"Out",localVars["lpI" .. i],"Fundamental")
      connect(localVars["bpf0" .. i],"Out",localVars["hpI" .. i],"Fundamental")

      -- connect frequency constants to the fshift summers
      connect(localVars["bpf0" .. i],"Out",localVars["fShiftSumLP" .. i],"Left")
      connect(localVars["bpf0" .. i],"Out",localVars["fShiftSumHP" .. i],"Left")

      -- connect fshift to right side of frequency shift summer
      connect(fShiftf0,"Out",localVars["fShiftSumLP" .. i],"Right")
      connect(fShiftf0,"Out",localVars["fShiftSumHP" .. i],"Right")

      -- connect fshift control to output filter inputs
      connect(localVars["fShiftSumLP" .. i],"Out",localVars["lpO" .. i],"Fundamental")
      connect(localVars["fShiftSumHP" .. i],"Out",localVars["hpO" .. i],"Fundamental")

      -- connect frequency ranges to f0 slider
      connect(localVars["bpf0" .. i],"Out",localVars["bpf0Range" .. i],"In")

      -- connect input filter pairs in series
      connect(localVars["lpI" .. i],"Left Out",localVars["hpI" .. i],"Left In")

      -- connect output filter pairs in series
      connect(localVars["lpO" .. i],"Left Out",localVars["hpO" .. i],"Left In")

      -- connect input to input BPFs in parallel
      connect(inputHPF,"Left Out",localVars["lpI" .. i],"Left In")

      -- connect input BPFs to envelope followers
      connect(localVars["hpI" .. i],"Left Out",localVars["ef" .. i],"In")

      -- connect output of envelope followers gains to left side of output VCAs
      connect(localVars["ef" .. i],"Out",localVars["ogain" .. i],"Left")

      -- connect carrier to the input of the output BPFs
      connect(gain,"Out",localVars["lpO" .. i],"Left In")

      -- tie envelope controls to the envelope followers
      tie(localVars["ef" .. i],"Attack Time",envelope,"Out")
      tie(localVars["ef" .. i],"Release Time",envelope,"Out")

       -- connect resonance parameters to input and output bpfs
       connect(qIn,"Out",localVars["lpI" .. i],"Resonance")
       connect(qIn,"Out",localVars["hpI" .. i],"Resonance")
       connect(qOut,"Out",localVars["hpO" .. i],"Resonance")
       connect(qOut,"Out",localVars["lpO" .. i],"Resonance")


      -- connect output of output BPFs to right side of output mixers
      connect(localVars["hpO" .. i],"Left Out",localVars["ogain" .. i],"Right")
    end

    -- connect the output BPFs to the array of mixers
    connect(localVars["ogain1"],"Out",localVars["omix1"],"Left") 
    connect(localVars["ogain" .. numBands-1],"Out",localVars["omix" .. numBands],"Right")
    for i=1,numBands-1 do
        connect(localVars["ogain" .. i+1],"Out",localVars["omix" .. i],"Right")
        connect(localVars["omix" .. i],"Out",localVars["omix" .. i+1],"Left")
    end

    -- connect summed signal to post /gain, and gain bias to post gain
    connect(localVars["omix" .. numBands-1],"Out",outputGain,"Left")

    -- connect(localVars["omix9"],"Out",outputGain,"Left")
    connect(outputLevel,"Out",outputGain,"Right")
    connect(outputLevel,"Out",outputLevelRange,"In")

    -- connect Q controls to their range objects
    connect(qIn,"Out",qInRange,"In")
    connect(qOut,"Out",qOutRange,"In")

    -- connect modulator to output HPF
    connect(inputHPF,"Left Out",outputHPF,"Left In")

    --connect frequency control for output mod HPF
    connect(outputHPFf0,"Out",outputHPF,"Fundamental")
    connect(outputHPFf0,"Out",outputHPFf0Range,"In")

    -- connect HPF modulator out to gain block
    connect(outputHPF,"Left Out",outputModGain,"Left")
    connect(outputModLevel,"Out",outputModGain,"Right")
    connect(outputModLevel,"Out",outputModLevelRange,"In")

    -- connect HPF modulator gain out to right side of final mixer
    connect(outputModGain,"Out",outputModMix,"Right")

    -- connect vocoded signal to left side of final mixer
    connect(outputGain,"Out",outputModMix,"Left")

    -- connect to unit output
     connect(outputModMix,"Out",pUnit,"Out1")
     if channelCount == 2 then
      connect(outputModMix,"Out",pUnit,"Out2")
     end
    
    -- register exported ports
    self:addBranch("input","Input", gain, "In")
    self:addBranch("envelope","Envelope",envelope,"In")
    self:addBranch("qIn","QIn",qIn,"In")
    self:addBranch("qOut","QOut",qOut,"In")
    self:addBranch("outputLevel","OutputLevel",outputLevel,"In")
    self:addBranch("fshift","Fshift",fShiftf0,"In")
    self:addBranch("hpModMix","HpModMix",outputModLevel,"In")
    self:addBranch("hpModf0","HpModf0",inputHPFf0,"In")

    for i = 1,numBands do
      self:addBranch("bpf0" .. i,"f" .. i,localVars["bpf0" .. i],"In")
    end
end

local controlMode = "no"

function Scorpio:changeControlMode(mode)
  controlMode = mode
  if controlMode=="no" then
    self:switchView("expanded")
  else
    self:switchView("extended")
  end
end

function Scorpio:onLoadViews(objects,controls)

    -- add frequency buttons based on numBands
    local bandButtons = {}
    for i=1,numBands do
      table.insert(bandButtons, "f" .. i)
    end

    local ext = {"gain","envelope","fshift","outputLevel","hpModMix","hpModf0","qIn","qOut"}

    for i=1,#bandButtons do
      ext[#ext+1] = bandButtons[i]
    end

    local views = {
    expanded = {"gain","envelope","fshift","outputLevel","hpModMix"},
    collapsed = {},
    extended = ext
  }
  
  controls.fshift = GainBias {
    button = "fshift",
    branch = self:getBranch("Fshift"),
    description = "spectrum shift",
    gainbias = objects.fShiftf0,
    range = objects.fShiftf0Range,
    biasMap = Encoder.getMap("filterFreq"),
    biasUnits = app.unitHertz,
    initialBias = 0,
    gainMap = Encoder.getMap("freqGain"),
    scaling = app.octaveScaling
  }

  controls.hpModf0 = GainBias {
    button = "hpModf0",
    branch = self:getBranch("HpModf0"),
    description = "mod mixin hpf freq",
    gainbias = objects.outputHPFf0,
    range = objects.outputHPFf0Range,
    biasMap = Encoder.getMap("filterFreq"),
    biasUnits = app.unitHertz,
    initialBias = 13000,
    gainMap = Encoder.getMap("freqGain"),
    scaling = app.octaveScaling
  }

  controls.gain = BranchMeter {
    button = "carrier",
    branch = self:getBranch("Input"),
    faderParam = objects.gain:getParameter("Gain")
  }


  controls.hpModMix = GainBias {
    button = "modmix",
    description = "mix in modulator",
    branch = self:getBranch("HpModMix"),
    gainbias = objects.outputModLevel,
    range = objects.outputModLevelRange,
    initialBias = 0.0,
    biasMap = Encoder.getMap("volume"),
    biasUnits = app.unitDecibels,
    gainMap = Encoder.getMap("[-10,10]"),
  }

  controls.outputLevel = GainBias {
    button = "postgain",
    description = "postgain",
    branch = self:getBranch("outputLevel"),
    gainbias = objects.outputLevel,
    range = objects.outputLevelRange,
    initialBias = 1.0,
    biasMap = Encoder.getMap("[0,10]"),
  }

  for i=1,numBands do
    controls["f" .. i] = GainBias {
      button = "f" .. i,
      branch = self:getBranch("f" .. i),
      description = "f" .. i,
      gainbias = objects["bpf0" ..i],
      range = objects["bpf0Range" .. i],
      biasMap = Encoder.getMap("filterFreq"),
      biasUnits = app.unitHertz,
      initialBias = 300 + (i-1) * bw,
      gainMap = Encoder.getMap("freqGain"),
      scaling = app.octaveScaling
    }
  end

  controls.envelope = GainBias {
    button = "envelope",
    description = "Env atk/dcy",
    branch = self:getBranch("Envelope"),
    gainbias = objects.envelope,
    range = objects.envelope,
    biasMap = Encoder.getMap("unit"),
    biasUnits = app.unitSecs,
    initialBias = 0.035,
  }

  controls.qIn = GainBias {
    button = "QIn",
    description = "Input filter resonance",
    branch = self:getBranch("QIn"),
    gainbias = objects.qIn,
    range = objects.qInRange,
    biasMap = Encoder.getMap("unit"),
    biasUnits = app.unitNone,
    initialBias = 0.2,
    gainMap = Encoder.getMap("[-10,10]")
  }

  controls.qOut = GainBias {
    button = "QOut",
    description = "Output filter resonance",
    branch = self:getBranch("QOut"),
    gainbias = objects.qOut,
    range = objects.qOutRange,
    biasMap = Encoder.getMap("unit"),
    biasUnits = app.unitNone,
    initialBias = 0.2,
    gainMap = Encoder.getMap("[-10,10]")
  }

  return views
end

local menu = {
  "setHeader",
  "setControlsNo",
  "setControlsYes",
  "infoHeader",
  "rename",
  "load",
  "save"
}

function Scorpio:onLoadMenu(objects,controls)

  controls.setHeader = MenuHeader {
    description = string.format("Display frequency controls: %s.",controlMode)
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


function Scorpio:serialize()
  local t = Unit.serialize(self)
  t.mute = self.controls.gain:isMuted()
  t.solo = self.controls.gain:isSolo()
  return t
end

function Scorpio:deserialize(t)
  Unit.deserialize(self,t)
  if t.mute then
    self.controls.gain:mute()
  end
  if t.solo then
    self.controls.gain:solo()
  end
end

return Scorpio
