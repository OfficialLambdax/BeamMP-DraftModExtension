# BeamNG-DraftModExtension
The Server Script for the Draftmod by Olrosse
Link: Will be put here once the DraftMod has been released

Make sure to set a admin in the draft_serverside\data\admins.json.

Format is as follows, if your PlayerName is "ThisIsMe" and your other Admins "AnotherName", "YetSomeoneMore".

{"admins":["ThisIsMe","AnotherName","YetSomeoneMore"]}

	Commands
	
		Note: Whenever a Admin calls any of these Commands, the Successful Result of that Command is
		propagated to every Admin that is currently Online.

		/draftmod updatetimer X
			This script updates the Default Values to each player every so often. This command
			allows you to set the interval time, where X is a Number in Seconds.
			eg.
				/draftmod updatetimer 10
					will update the values every 10 seconds
			
			Setting it to 0 will disable the update entirely
			
			
			
		/draftmod setstate X
			Enables/Disables the DraftMod for each Client. Where X is true or false
			eg. 
				/draftmod setstate false
					disables the draftmod for every player



		/draftmod setforce X
			Sets the Draft force multiplier. Where X is a Number
			eg.
				/draftmod setforce 2
					multiplies the draft force by 2

	
	
		/draftmod setadmin X Y
			Makes a Player a Admin or removes him from the Admins. Sets are Permanent
			Where X is the Player Name and Y the state in true or false
			eg.
				/draftmod setadmin SomeonesName true
					gives SomeonesName admin rights for this script
					
		
		
		/draftmod exclude X Y
			Every player excluded will have their Draft Mod disabled. Usefull for Time trail /
			Qualification Scenarios.
			Where X is the PlayerName and Y the state in true or fals 
			eg.
				/draftmod exclude SomeonesName true
					SomeonesName will have its draftmod disabled



		/draftmod help
			Shows the available Commands ingame
