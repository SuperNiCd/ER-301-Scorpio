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
     If an initial frequency is not supplied it will default to 0Hz, which will block the band. 
  ]]

-- local numBands = 12
-- local freqInitialBias = {200,500,800,1200,1500,1800,2600,3900,5500,7800,12800,15000}

local numBands = 10
local freqInitialBias = {200,500,800,1200,1800,2600,3900,5500,7800,12800}




function Scorpio:onLoadGraph(pUnit,channelCount)

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

    -- create envelope follower controls
    local attack = self:createObject("ParameterAdapter","attack")
    local release = self:createObject("ParameterAdapter","release")

    -- Create the objects that require one per band
    local localVars = {}

    local objectList = {
      lpI = { "StereoLadderFilter" },
      hpI = { "StereoLadderHPF" },
      lpO = { "StereoLadderFilter" },
      hpO = { "StereoLadderHPF" },
      ef  = { "EnvelopeFollower" },
      efgain = { "Multiply" },
      efgainLvl = { "GainBias" },
      efgainLvlRange = { "MinMax" },
      bpf0 = { "GainBias" },
      bpf0Range = { "MinMax" },
      ogain = { "Multiply" },
      omix = { "Sum" }
    }

    for k, v in pairs(objectList) do
      for i = 1, numBands do
        dynamicVar = k .. i
        dynamicDSPUnit = v[1]
        localVars[dynamicVar] = self:createObject(dynamicDSPUnit,dynamicVar)
      end
    end

    for i = 1,numBands do
      -- connect frequency constants to the input filter DSP fundamentals
      connect(localVars["bpf0" .. i],"Out",localVars["lpI" .. i],"Fundamental")
      connect(localVars["bpf0" .. i],"Out",localVars["hpI" .. i],"Fundamental")

      -- connect frequency constants to the output filter DSP fundamentals
      connect(localVars["bpf0" .. i],"Out",localVars["lpO" .. i],"Fundamental")
      connect(localVars["bpf0" .. i],"Out",localVars["hpO" .. i],"Fundamental")

      -- connect frequency ranges to f0 slider
      connect(localVars["bpf0" .. i],"Out",localVars["bpf0Range" .. i],"In")

      -- connect input filter pairs in series
      connect(localVars["lpI" .. i],"Left Out",localVars["hpI" .. i],"Left In")

      -- connect output filter pairs in series
      connect(localVars["lpO" .. i],"Left Out",localVars["hpO" .. i],"Left In")

      -- connect input HPF to BPFs in parallel
      connect(inputHPF,"Left Out",localVars["lpI" .. i],"Left In")

      -- connect input BPFs to envelope followers
      connect(localVars["hpI" .. i],"Left Out",localVars["ef" .. i],"In")

      -- connect the envelope follower outputs to individual VCAs
      connect(localVars["ef" .. i],"Out",localVars["efgain" .. i],"Left")

      -- connect the EF VCAs to level controls
      connect(localVars["efgainLvl" .. i],"Out",localVars["efgain" .. i],"Right")

      -- connect the EF level ranges to the EF gain controls
      connect(localVars["efgainLvl" .. i],"Out",localVars["efgainLvlRange" .. i],"In")

      -- connect output of envelope followers gains to left side of output VCAs
      connect(localVars["efgain" .. i],"Out",localVars["ogain" .. i],"Left")

      -- connect carrier to the input of the output BPFs
      connect(gain,"Out",localVars["lpO" .. i],"Left In")

      -- tie attack and release
      tie(localVars["ef" .. i],"Attack Time",attack,"Out")
      tie(localVars["ef" .. i],"Release Time",release,"Out")

      -- connect output of output BPFs to right side of output mixers
      connect(localVars["hpO" .. i],"Left Out",localVars["ogain" .. i],"Right")
    end

    -- connect modulator (unit input) to fixed HPF
    connect(pUnit,"In1",inputHPF,"Left In")

    -- mix output output of the output VCAs
    connect(localVars["ogain1"],"Out",localVars["omix1"],"Left")
    connect(localVars["ogain2"],"Out",localVars["omix1"],"Right")
    connect(localVars["omix1"],"Out",localVars["omix2"],"Left")
    connect(localVars["ogain3"],"Out",localVars["omix2"],"Right")
    connect(localVars["omix2"],"Out",localVars["omix3"],"Left")
    connect(localVars["ogain4"],"Out",localVars["omix3"],"Right")
    connect(localVars["omix3"],"Out",localVars["omix4"],"Left")
    connect(localVars["ogain5"],"Out",localVars["omix4"],"Right")
    connect(localVars["omix4"],"Out",localVars["omix5"],"Left")
    connect(localVars["ogain6"],"Out",localVars["omix5"],"Right")
    connect(localVars["omix5"],"Out",localVars["omix6"],"Left")
    connect(localVars["ogain7"],"Out",localVars["omix6"],"Right")
    connect(localVars["omix6"],"Out",localVars["omix7"],"Left")
    connect(localVars["ogain8"],"Out",localVars["omix7"],"Right")
    connect(localVars["omix7"],"Out",localVars["omix8"],"Left")
    connect(localVars["ogain9"],"Out",localVars["omix8"],"Right")
    connect(localVars["omix8"],"Out",localVars["omix9"],"Left")
    connect(localVars["ogain10"],"Out",localVars["omix9"],"Right")

    -- connect summed signal to post gain, and gain bias to post gain
    connect(localVars["omix9"],"Out",outputGain,"Left")
    connect(outputLevel,"Out",outputGain,"Right")
    connect(outputLevel,"Out",outputLevelRange,"In")

    -- send band passed mix to unit output
     connect(outputGain,"Out",pUnit,"Out1")
    
    -- register exported ports
    self:addBranch("input","Input", gain, "In")
    self:addBranch("inputHPFf0","preHPF", inputHPFf0,"In")
    self:addBranch("attack","Attack",attack,"In")
    self:addBranch("release","Release",release,"In")
    self:addBranch("outputLevel","OutputLevel",outputLevel,"In")

    for i = 1,numBands do
      self:addBranch("bpf0" .. i,"f" .. i,localVars["bpf0" .. i],"In")
    end

    for i = 1,numBands do
      self:addBranch("lvl" .. i,"Lvl" .. i,localVars["efgainLvl" .. i],"In")
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

    -- add level and frequency buttons based on numBands
    local bandButtons = {}
    for i=1,numBands do
      table.insert(bandButtons, "f" .. i)
      table.insert(bandButtons, "lvl" .. i)
    end

    local ext = {"gain", "preHPF", "outputLevel","attack","release"}

    for i=1,#bandButtons do
      ext[#ext+1] = bandButtons[i]
    end

    local views = {
    expanded = {"gain", "preHPF", "outputLevel","attack","release"},
    collapsed = {},
    extended = ext
  }
  

  controls.gain = BranchMeter {
    button = "carrier",
    branch = self:getBranch("Input"),
    faderParam = objects.gain:getParameter("Gain")
  }

  controls.preHPF = GainBias {
    button = "preHPF",
    branch = self:getBranch("preHPF"),
    description = "preHPF",
    gainbias = objects.inputHPFf0,
    range = objects.inputHPFRange,
    biasMap = Encoder.getMap("filterFreq"),
    biasUnits = app.unitHertz,
    initialBias = 100,
    gainMap = Encoder.getMap("freqGain"),
    scaling = app.octaveScaling
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

  --local freqInitialBias = {200,500,800,1200,1800,2600,3900,5500,7800,12800}
  for i=1,numBands do
    controls["f" .. i] = GainBias {
      button = "f" .. i,
      branch = self:getBranch("f" .. i),
      description = "f" .. i,
      gainbias = objects["bpf0" ..i],
      range = objects["bpf0Range" .. i],
      biasMap = Encoder.getMap("filterFreq"),
      biasUnits = app.unitHertz,
      initialBias = freqInitialBias[i],
      gainMap = Encoder.getMap("freqGain"),
      scaling = app.octaveScaling
    }
  end

  for i=1,numBands do
    controls["lvl" .. i] = GainBias {
      button = "lvl" .. i,
      branch = self:getBranch("lvl" .. i),
      description = "lvl" .. i,
      gainbias = objects["efgainLvl" ..i],
      range = objects["efgainLvlRange" .. i],
      initialBias = 1.0,
      biasMap = Encoder.getMap("[0,10]"),
    }
  end


  controls.attack = GainBias {
    button = "attack",
    description = "Attack Time",
    branch = self:getBranch("Attack"),
    gainbias = objects.attack,
    range = objects.attack,
    biasMap = Encoder.getMap("unit"),
    biasUnits = app.unitSecs,
    initialBias = 0.035
  }

  controls.release = GainBias {
    button = "release",
    description = "Release Time",
    branch = self:getBranch("Release"),
    gainbias = objects.release,
    range = objects.release,
    biasMap = Encoder.getMap("unit"),
    biasUnits = app.unitSecs,
    initialBias = 0.035
  }

  --self:addToMuteGroup(controls.gain)


  return views
end

local menu = {
  "setHeader",
  "setControlsNo",
  "setControlsYes",
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
