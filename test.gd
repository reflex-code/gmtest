extends Node

const SMF = preload( "res://addons/midi/SMF.gd" )
const Utility = preload( "res://addons/midi/Utility.gd" )

onready var midi_player:MidiPlayer = $GodotMIDIPlayer
onready var t = $Timer1
#var tempo_changing:bool = false
#var updating_seek_bar:bool = false
#var ui_channels:Array = []
#var cymbalIndex : int = 0
#var cymbalBaseIndex : int = 0
#var Cymbal =    [1,0,1,1,0,1,0,1,1,1,0,1,0,1,0,1,0,1]
#var bassDrumIndex : int = 0
#var bassDrumBaseIndex : int = 0
#var BassDrum =  [1,0,1,0,0,1,1,0,0,1,0,0,1,0,1,1,0,0]
##var BassDrum =  [1,0,0,0,0,0,1,0,0,1,0,0,1,0,1,1,0,0]
var velocityIndex: int = 0
var velocities = [36, 49, 58, 29, 42]
#var snareIndex : int = 0
#var snareBaseIndex : int = 0
#var Snare =     [1,0,0,0,0,1,1,0,1,0,0,1,1,0,0,1,1,1,0,0,0,0,0,0]
#var crashindex49: int = 0
var tempo: float = 9.0
var note_index: int = 0 #updated at the end of each timer interrupt, 0-31 for now
var radio_station: int = 1
var hover_station: int = -1

#cow bell/ride pattern, use values 0-4 where 0=mute instrument 
var pat_cb_ride = "11111111222222221111111122222222"
var pat_h_tom = "11111111222222221111111122222222"
var pat_l_tom = "11111111222222221111111122222222"
var pat_snare = "11111111222222221111111122222222"
var pat_bass = "11111111222222221111111122222222"
var pat_c_hihat = "11111111222222221111111122222222"
var pat_my_snare = "11111111111111111111111111111111"
var pat_my_bass = "11111111111111111111111111111111"

# notes _ instrument list
#mambo, 0 = rest,1-4 = sustained, 5-9 = staccato
#cow bell/ride
var notes_cb_ride = "30102203402301034020432302324022"
#var  notes_cb_ride = "40104401404101033030333303333033"
#high tom
var notes_h_tom = "00000011000000210000001200000022"
#low tom
var notes_l_tom = "00000000000220000000000000000000"
#snare
var notes_snare = "00300000000000000030000000300000"
#bass
var notes_bass = "30030000300300003002000030020000"
#closed hi-hat
var notes_c_hihat =  "40004000400040000040004000400040"
#my alternative snare patterns
var notes_my_snare = "00300000000000400230000004000000"
#my alternative bass patterns
var notes_my_bass =  "40030010400200033234000042030000"
#                    "30030000300300003002000030020000"
#from https://www.midi.org/specifications-old/item/gm-level-1-sound-set
const midi_ride: int = 51
const midi_h_tom: int = 43
const midi_l_tom: int = 45
const midi_snare: int = 38
const midi_bass: int = 36
const midi_c_hihat: int = 42
const midi_p_hihat: int = 44
const midi_o_hihat: int = 46
const midi_cowbell: int = 56
const crashList = [49, 52, 55]
var triple_timer: int = 0
#Acoustic Bass Drum 35
#Bass Drum 1 36

#Side Stick 37
#Acoustic Snare 38
#OHand Clap 39
#Electric Snare 40 

"""
	Initializes
"""
func _ready( ):
	$LabelTempo.text = "Tempo: " + String(1200/tempo)+ " bpm"
	t.set_wait_time(tempo/60.0)
	if $GodotMIDIPlayer.connect( "midi_event", self, "_on_midi_event" ) != OK:
		print( "error" )
		breakpoint
	for i in $Group1.get_children() :
		if(i.text[0] == "1"):
			i.pressed = true
	#$Group1.CheckBox1.pressed = true #did not work
	#$TextEdit1.Font.set_size(24)

func _unhandled_input( event:InputEvent ):
	if event is InputEventMIDI:
		self.midi_player.receive_raw_midi_message( event )

#This is left in to show how a button click can play a note
func _on_Button_pressed():
	var input:InputEventMIDI = InputEventMIDI.new( )
	input.message = 0x9 # note on
	input.pitch = 53  # note number
	input.velocity = 0x7F # velocity
	#nput.instrument = 10
	input.channel =  9#9 for drums
	$GodotMIDIPlayer.receive_raw_midi_message( input )

func Play_step(id_i, pat, notes, dy_max: int): 
	#ex.: Play_step(midi_ride, pat_cb_ride, notes_cb_ride, 127)
	var input:InputEventMIDI = InputEventMIDI.new( )
	var dynamics: int = 0
	var pattern: int = 0
	var id_instrument: int = id_i
	var i = 0
#cb/ride pattern to volume conversion
	pattern = pat[note_index].to_int()

	if pattern != 0: #instrument on
		#i= (pattern - 1) * 8 + note_index % 8
		dynamics = notes[(pattern - 1) * 8 + note_index % 8].to_int()
	else:
		dynamics = 0 #instrument1 off
	#print(pattern, ' ', dynamics, " ", i)

	if dynamics == 0: #note off
		input.message = 0x8 # note off
		input.pitch = id_instrument # note number 38,40
		input.channel =  9#9 for drums
		$GodotMIDIPlayer.receive_raw_midi_message( input )
	else:
		input.message = 0x9 # note on
		input.pitch = id_instrument # note number 38,40
		input.channel =  9#9 for drums
		input.velocity = dy_max * (dynamics + 1)/5
		$GodotMIDIPlayer.receive_raw_midi_message( input )	

func _on_Timer1_timeout():	
	triple_timer += 1
	if triple_timer == 2:
		return
	if triple_timer == 3:
		triple_timer = 0	
	#print(triple_timer)
	#$GodotMIDIPlayer.stop( )
	#pat_cb_ride[note_index] = var2str(radio_station)
	#pat_cb_ride[note_index] = String(hover_station)
	var pattern: int = 0 
	var notes_str = "0000\n\n"
	var i: int = note_index
	$TextEdit1.set_text("")
	

	if radio_station == 0: #cb
		if hover_station != -1:
			pat_cb_ride[note_index] = String(hover_station)
		pattern = pat_cb_ride[note_index].to_int()	
		$Circle_bw.position.y = 128 + 32 * pattern
		for p in range(0, 4):
			i = note_index
			for count in range(0, 4):
				notes_str += notes_cb_ride[p * 8 + i % 8]
				i = (i + 1) % 32
			notes_str += "\n\n"
		$TextEdit1.set_text(notes_str)
	elif radio_station == 1: #snare
		if hover_station != -1:
			pat_my_snare[note_index] = String(hover_station)		
		pattern = pat_my_snare[note_index].to_int()	
		$Circle_bw.position.y = 128 + 32 * pattern
		for p in range(0, 4):
			i = note_index
			for count in range(0, 4):
				notes_str += notes_my_snare[p * 8 + i % 8]
				i = (i + 1) % 32
			notes_str += "\n\n"
		$TextEdit1.set_text(notes_str)
	elif radio_station == 2: #bassf
		if hover_station != -1:
			pat_my_bass[note_index] = String(hover_station)		
		pattern = pat_my_bass[note_index].to_int()	
		$Circle_bw.position.y = 128 + 32 * pattern
		for p in range(0, 4):
			i = note_index
			for count in range(0, 4):
				notes_str += notes_my_bass[p * 8 + i % 8]
				i = (i + 1) % 32
			notes_str += "\n\n"
		$TextEdit1.set_text(notes_str)
	#print("ht: ", hover_station)
	
	Play_step(midi_cowbell, pat_cb_ride, notes_cb_ride, 66)
#	Play_step(midi_ride, pat_cb_ride, notes_cb_ride, 127)
	Play_step(midi_h_tom, pat_h_tom, notes_h_tom, 18)
	Play_step(midi_l_tom, pat_l_tom, notes_l_tom, 18)
	Play_step(midi_snare, pat_my_snare, notes_my_snare, 64)
	Play_step(midi_bass, pat_my_bass, notes_my_bass, 90)
	Play_step(midi_p_hihat, pat_c_hihat, notes_c_hihat, 127)
	
#	const midi_snare: int = 38
#const midi_bass: int = 36
#const midi_c_hihat: int = 42
#const midi_p_hihat: int = 44
#const midi_o_hihat: int = 46

	note_index = (note_index + 1) % 32					
	if note_index == 0 || note_index == 31:
		var input:InputEventMIDI = InputEventMIDI.new( )
		input.message = 0x9 # note on
		var crashList = [49, 52, 55]
		input.pitch =  crashList[randi() % 3]
		input.velocity = velocities[velocityIndex]
		input.channel =  9#9 for drums
		$GodotMIDIPlayer.receive_raw_midi_message( input )

	#print(note_index)
#	if Cymbal[cymbalBaseIndex + cymbalIndex] != 0 && (randi() % 5) != 0:		
#		input.message = 0x9 # note on
#		input.pitch = 51 # note number
#		input.velocity = 0x7F - randi() % 30
#		#input.
#		input.channel =  9#9 for drums
#		$GodotMIDIPlayer.receive_raw_midi_message( input )
#	cymbalIndex += 1
#	if cymbalIndex == 12:
#		cymbalIndex = 0
#		cymbalBaseIndex = 0 #6 * (randi() % 2)
#		#print('cymbalBaseIndex = ', cymbalBaseIndex)	
#	if bassDrumIndex < 6 && BassDrum[bassDrumBaseIndex + bassDrumIndex] != 0 && (randi() % 4) != 0:
#		input.message = 0x9 # note on
#		input.pitch = 36 # note number
#		input.velocity = velocities[velocityIndex] 
#		#input.
#		input.channel =  9#9 for drums
#		$GodotMIDIPlayer.receive_raw_midi_message( input )
#	bassDrumIndex += 1
#	if bassDrumIndex == 12:
#		bassDrumIndex= 0
#		1
#		bassDrumBaseIndex = 6 * (randi() % 3)
#
#	velocityIndex += 1
#	if velocityIndex == 3:
#		velocityIndex = 0	
#
#	if snareIndex >= 6 && Snare[snareBaseIndex + snareIndex - 6] != 0:
#		input.message = 0x8 # note off
#		input.pitch = 40 # note number 38,40
#		#input.
#		input.channel =  9#9 for drums
#		$GodotMIDIPlayer.receive_raw_midi_message( input )
#		input.message = 0x9 # note on
#		input.pitch = 40 # note number
#		input.velocity = velocities[velocityIndex] - 30
#		#input.
#		input.channel =  9#9 for drums
#		$GodotMIDIPlayer.receive_raw_midi_message( input )
#	snareIndex += 1
#	if snareIndex == 12:
#		snareIndex= 0
#		#snareBaseIndex = 6 * (randi() % 3)
#
#	velocityIndex += 1
#	if velocityIndex == 3:
#		velocityIndex = 0						
#	if crashindex49 == 0 || crashindex49 == 47:
#		input.message = 0x9 # note on
#		var crashList = [49, 52, 55]
#		input.pitch =  crashList[randi() % 3]
#		input.velocity = velocities[velocityIndex]
#		#input.
#		input.channel =  9#9 for drums
#		$GodotMIDIPlayer.receive_raw_midi_message( input )
#	crashindex49 += 1
#	if crashindex49 == 48:
#		crashindex49 = 0
	#Ride Cymbal 1 51 snareBaseIndex


func _on_radio_toggled(button_pressed, value):
#if the checkbox is unchecked we don't need to do any thing
	if(!button_pressed):
		return
#looping through the group node children and uncheck every on expect the sender checkbox
	for i in $Group1.get_children() :
		if(i.text[0] != String(value)):
			i.pressed = false
		else:
			#print(value)
			radio_station = value #0-4
			#snareBaseIndex = value * 6

func _on_Button_mouse_entered(value):
	hover_station = value 

func _on_Button_0to4_mouse_exited():
	hover_station = -1 #invalid 

func _on_ButtonFaster_pressed():
	tempo -= 1.0
	t.set_wait_time(tempo/60.0)
	$LabelTempo.text = "Tempo: " + String(1200/tempo)+ " bpm"

func _on_ButtonSlower_pressed():
	tempo += 1.0
	t.set_wait_time(tempo/60.0)
	$LabelTempo.text = "Tempo: " + String(1200/tempo)+ " bpm"
