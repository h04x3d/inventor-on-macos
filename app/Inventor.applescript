property runner : "@RUNNER@"

on run
	do shell script quoted form of runner & " launch > /dev/null 2>&1 &"
end run

on open location theURL
	do shell script quoted form of runner & " url " & quoted form of theURL & " > /dev/null 2>&1 &"
end open location

on open theFiles
	set args to ""
	repeat with f in theFiles
		set args to args & " " & quoted form of POSIX path of f
	end repeat
	do shell script quoted form of runner & " launch" & args & " > /dev/null 2>&1 &"
end open
