-- Test script to diagnose Numbers file conversion issues
-- Run this in Script Editor to test Numbers file conversion

-- CHANGE THIS to your Numbers file path
set numbersFilePath to "/Users/leeo/Downloads/test.numbers"
set csvFilePath to "/Users/leeo/Downloads/test_output.csv"

try
	-- Check if Numbers is installed
	tell application "Finder"
		if not (exists application file id "com.apple.iWork.Numbers") then
			display dialog "Numbers app is NOT installed!" buttons {"OK"} default button 1
			return
		end if
	end tell

	display dialog "Numbers app is installed. Opening file..." buttons {"OK"} default button 1

	tell application "Numbers"
		activate

		-- Open the file
		set theDoc to open POSIX file numbersFilePath
		delay 2

		display dialog "File opened successfully. Checking structure..." buttons {"OK"} default button 1

		-- Check document structure
		tell theDoc
			set sheetCount to count of sheets
			display dialog "Number of sheets: " & sheetCount buttons {"OK"} default button 1

			if sheetCount is 0 then
				close saving no
				display dialog "ERROR: Document has no sheets!" buttons {"OK"} default button 1
				return
			end if

			set theSheet to sheet 1

			tell theSheet
				set tableCount to count of tables
				display dialog "Number of tables in first sheet: " & tableCount buttons {"OK"} default button 1

				if tableCount is 0 then
					close theDoc saving no
					display dialog "ERROR: First sheet has no tables!" buttons {"OK"} default button 1
					return
				end if
			end tell
		end tell

		display dialog "Structure looks good! Exporting to CSV..." buttons {"OK"} default button 1

		-- Export
		export theDoc to POSIX file csvFilePath as CSV

		close theDoc saving no

		display dialog "SUCCESS! CSV created at: " & csvFilePath buttons {"OK"} default button 1
	end tell

on error errMsg number errNum
	display dialog "ERROR " & errNum & ": " & errMsg buttons {"OK"} default button 1
end try
