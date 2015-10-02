-- GLOBAL DYNAMIC VARIABLES

-- Which note types are counted as part of the stream?
streamNotes = {1,2,4}
-- How many notes per measure to indicate a stream? (16ths)
notesPerMeasure = 16
-- How many sequential measures of streaming indicates a stream? 
measureSequenceThreshold = 4

--maxBreakPerMeasure = 2

-- Utility function to replace regex special characters with escaped characters
function regexEncode(var)
	return (var:gsub('%%', '%%%')
           :gsub('%^', '%%^')
           :gsub('%$', '%%$')
           :gsub('%(', '%%(')
           :gsub('%)', '%%)')
           :gsub('%.', '%%.')
           :gsub('%[', '%%[')
           :gsub('%]', '%%]')
           :gsub('%*', '%%*')
           :gsub('%+', '%%+')
           :gsub('%-', '%%-')
           :gsub('%?', '%%?'))
end

-- Parse the measures section out of our sim file
function getChartMeasuresString(simfilePath, gameType, gameDifficulty)
	-- Open the file
	local file, errorString = io.open(simfilePath, "r")
	local measuresString = nil

	if not file then
		-- Error opening file
		print("File error: " .. errorString)
	else
		-- Read lines from file
		local simfileContents = file:read("*a")
		
		-- Find the section of the sim file for our song difficulty and game type
		measuresString = string.match(simfileContents, "#NOTES[^;]*"..regexEncode(gameType).."[^;]*"..regexEncode(gameDifficulty).."[^;]*;")
		
		-- remove header garbage
		measuresString = measuresString:gsub("#NOTES:.*:","")
		-- remove comments
		measuresString = measuresString:gsub("//[^\n]*","")
		-- remove leading white space
		measuresString = measuresString:gsub("[ ]*","")
	end
	
	return measuresString
end

-- Figure out which measures are considered a stream of notes
function getStreamMeasures(measuresString)	
	-- Make our stream notes array into a string for regex
	local streamNotesString = ""
	for k, v in pairs(streamNotes) 
	do 
		streamNotesString = streamNotesString .. v
	end

	-- Which measures are considered a stream?
	local streamMeasures = {}
	
	-- Keep track of the measure and its timing (8ths, 16ths, etc)
	local measureCount = 1
	local measureTiming = 0
	-- Keep track of the notes in a measure
	local measureNotes = {}
	
	-- How many 
	
	-- Loop through each line in our string of measures
	for line in measuresString:gmatch("[^\r\n]+")
	do
		-- If we hit a comma or a semi-colon, then we've hit the end of our measure
		if(line:match("^[,;]%s*")) then
			-- Does this measure contain a stream of notes based on our notesPerMeasure global?
			if(#measureNotes >= notesPerMeasure) then
				local isStream = true
				
				-- What can the gap be in between notes?
				local noteGapThreshold = measureTiming / notesPerMeasure
				
				-- Loop through our notes and see if they're placed correctly to be considered a stream (every 8th, every 16th, etc.)
				for i=1,(#measureNotes - 1),1 do
					-- Is the gap between this note and the next note greater than what's allowed?
					if((measureNotes[i+1] - measureNotes[i]) > noteGapThreshold) then
						isStream = false
					end
				end
				
				-- This measure is a stream
				if(isStream == true) then
					table.insert(streamMeasures, measureCount)
				end
			end
		
			-- Reset iterative variables
			measureTiming = 0
			measureCount = measureCount + 1
			measureNotes = {}
		else
			-- Iterate the measure timing
			measureTiming = measureTiming + 1
			
			-- Is this a note?
			if(line:match("["..streamNotesString.."]")) then
				table.insert(measureNotes, measureTiming)
			end
		end
	end
	
	return streamMeasures
end

-- Get the start/end of each stream sequence in our table of measures
function getStreamSequences(streamMeasures)
	local streamSequences = {}

	local counter = 1
	local streamEnd = nil
	-- Which sequences of measures are considered a stream?
	for k,v in pairs(streamMeasures) do
		-- Are we still in sequence?
		if(streamMeasures[k-1] == (streamMeasures[k] - 1)) then
			counter = counter + 1
			streamEnd = streamMeasures[k]
		end
		
		-- Are we out of sequence OR at the end of the array?
		if(streamMeasures[k+1] == nil or streamMeasures[k-1] ~= (streamMeasures[k] - 1)) then
			if(counter >= measureSequenceThreshold) then
				streamStart = (streamEnd - counter)
				table.insert(streamSequences, {streamStart=streamStart,streamEnd=streamEnd})
			end
			counter = 1
		end
	end

	return streamSequences
end

-- Proof of concept? Not sure the easiest way to execute/retrieve data for stepmania from this script

-- Where is the sim file located?
local simfilePath = ".\\Electric Angel.sm"
-- Single or Doubles?
local gameType = "dance-single"
-- Basic, Standard, Expert, Challenge?
local gameDifficulty = "Challenge"

measuresString = getChartMeasuresString(simfilePath, gameType, gameDifficulty)
streamMeasures = getStreamMeasures(measuresString)
streamSequences = getStreamSequences(streamMeasures)

-- Display which measures are counted as streams
for k,v in pairs(streamMeasures) do
	print("Measure "..v.." has a stream.")
end

print("-------------------------------------------")

-- Display the streams
for k,v in pairs(streamSequences) do
	print("Stream position: "..v.streamStart .. " / " .. v.streamEnd)
end