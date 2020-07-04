extends Control

var tab_scene = preload("res://Scenes/Tab.tscn")

onready var save_as_file_dialog = get_node('SaveAsFileDialog')
onready var open_file_dialog = get_node('OpenFileDialog')
onready var about_popup = get_node('AboutPopup')
onready var tab_container = get_node("HSplitContainer/TabContainer")

#Reference to current working tab
var current_tab = null

const UNTITLED = 'Untitled'
var current_file = UNTITLED
var max_recents = 10

func _ready():
	title_update()
	#Create new file
	new_file()

#Get file name from File path
#e.g "user/folder/file.txt" will return "file.txt" 
func get_file_name(file : String):
	var strings = file.split("/")
	return strings[strings.size() - 1]


#Update title
func title_update():
	# This sets the title for the current title
	OS.set_window_title('Signum - ' + current_file)
	


# File Menu IDs:
# Open File = 0
# Save As File = 1
# Save File = 4
# Quit = 2
# New File = 3
# ----------------
# Help Menu IDs:
# About = 0
# Github Page = 1
# Github Issues = 2

func file_item_pressed(id):
	match id:
		0:
			# Opens file select dialog
			open_file_dialog.popup()
		1:
			# Opens save file dialog
			save_as_file_dialog.popup()
		2:
			# Closes the program
			get_tree().quit()
		3:
			# Creates file
			new_file()
		4:
			# Saves file without changing the name
			save_file()

func help_item_pressed(id):
	match id:
		0:
			# Opens about popup
			about_popup.popup()
		1:
			# Opens the github page in the browser
			OS.shell_open('https://github.com/MintStudios/Signum')
		2:
			# Opens issues in github
			OS.shell_open('https://github.com/MintStudios/Signum/issues')

# Creates a new file
func new_file():
	current_file = UNTITLED
	create_new_tab(UNTITLED)
	title_update()
	# Resets the text back to nothing
	current_tab.get_node("TextEdit").text = ''

# Opens an existing file
func open_file_selected(path):
	#Do not open file if its already opened in editor.
	#instead switch to that tab
	if is_file_open(path):
		switch_to_tab(path)
		return
	
	# Creates and reads the file
	var file = File.new()
	file.open(path, 1)
	create_new_tab(path)
	# Makes the TextEdit text the same as the file's
	current_tab.get_node("TextEdit").text = file.get_as_text()
	# Closes to prevent memory leaks
	file.close()
	# Changes the title to the file path
	current_file = path
	title_update()
	# Checks if the recents list exceeds 10, if not, continues.
	if $HSplitContainer/Sidebar/Recents/Recents.get_child_count() < max_recents:
		# Creates button for recent files
		var button = Button.new()
		button.focus_mode = Control.FOCUS_NONE
		$HSplitContainer/Sidebar/Recents/Recents.add_child(button)
		button.text = path.get_file()
		# Signal to go to the recent file
		button.connect("pressed", self, "go_to_recent", [path])


# Saves the file as a file type
func save_as_file_selected(path):
	# Creates and writes the file
	var file = File.new()
	file.open(path, 2)
	file.store_string(current_tab.get_node("TextEdit").text)
	# Closes to prevent memory leaks
	file.close()
	# Changes the title to the file path
	current_file = path
	title_update()
	# Changes tab title to file name
	tab_container.set_tab_title(tab_container.current_tab, get_file_name(current_file))
	
	current_tab.file_path = current_file


func save_file():
	# Path to file, 
	var path = current_tab.file_path
	# Checks if the file hasn't been created. If it has, then it triggers the 'Save As` Dialog
	if path == UNTITLED:
		save_as_file_dialog.popup()
	# If the file exists, writes the file.
	else:
		var file = File.new()
		file.open(path, 2)
		file.store_string(current_tab.get_node("TextEdit").text)
		# Closes to prevent memory leaks
		file.close()
		# Changes the title to the file path
		current_file = path

# Signal for going to the recent file
func go_to_recent(path):
	#Do not open file if its already opened in editor.
	#instead switch to that tab
	if is_file_open(path):
		switch_to_tab(path)
		return

	# Creates and reads the file
	var file = File.new()
	file.open(path, 1)
	# Makes the TextEdit text the same as the file's
	current_tab.get_node("TextEdit").text = file.get_as_text()
	# Closes to prevent memory leaks
	file.close()
	# Changes the title to the file path
	current_file = path
	title_update()

# Clears the recents list
func clear_recents():
	for rcnt in $HSplitContainer/Sidebar/Recents/Recents.get_children():
		# Deletes itself
		rcnt.queue_free()


#Create a new Tab 
func create_new_tab(file_path):
	var tab = tab_scene.instance()
	tab.file_path = file_path
	
	#Apply Editor settings to this tab
	GlobalData.apply_settings_to_tab(tab)

	#set as current tab
	current_tab = tab
	
	#add to tab container and switch to this tab
	tab_container.add_child(tab)
	var tab_id =  tab_container.get_child_count() - 1
	#switch to tab "tab_id"
	tab_container.current_tab = tab_id
	#set tab title to file name
	tab_container.set_tab_title(tab_id, get_file_name(file_path))
	


#Check if File is open in editor
func is_file_open(file_path : String) -> bool:
	var tabs = tab_container.get_children()
	for i in tabs:
		if i.file_path == file_path:
			return true
	
	return false


#Switch to tab with given file path
func switch_to_tab(file_path : String):
	var tabs = tab_container.get_children()
	var id = 0
	for i in tabs:
		if i.file_path == file_path:
			current_tab = i
			tab_container.current_tab = id
		
		id += 1


func _on_TabContainer_tab_changed(tab):
	current_tab = tab_container.get_child(tab)
	print(current_tab.file_path)
