# -------------------------- Header Parameters --------------------------

scenario = "Go-NoGo Task";

write_codes = EXPARAM( "Send ERP Codes" );

default_font_size = EXPARAM( "Default Font Size" );
default_background_color = EXPARAM( "Default Background Color" );
default_text_color = EXPARAM( "Default Font Color" );
default_font = EXPARAM( "Default Font" );

max_y = 100;

active_buttons = 1;
response_matching = simple_matching;

stimulus_properties = 
	event_cond, string, 
	block_name, string,
	trial_number, number,
	stim_condition, string,
	stim_number, number,
	isi_duration, number;
event_code_delimiter = ";";

# ------------------------------- SDL Part ------------------------------
begin;

sound { wavefile { filename = ""; preload = false; }; };

trial {
	trial_duration = forever;
	trial_type = specific_response;
	terminator_button = 1;
	
	picture { 
		text { 
			caption = "Instructions"; 
			preload = false;
		} instruct_text; 
		x = 0; 
		y = 0; 
	};
} instruct_trial;

trial {
	clear_active_stimuli = false;
	trial_type = specific_response;
	terminator_button = 1;
	all_responses = false;
	
	stimulus_event {
		picture {} tgt_pic; 
	} stim_event;
} stim_trial;

trial {
	stimulus_event {
		picture {
			text { 
				caption = "+"; 
				font_size = EXPARAM( "Fixation Point Size" ); 
			} fix_text;
			x = 0;
			y = 0;
		} ISI_pic;
		code = "ISI";
	} ISI_event;
} ISI_trial;

TEMPLATE "../../Library/lib_rest.tem";

# ----------------------------- PCL Program -----------------------------
begin_pcl;

include_once "../../Library/lib_visual_utilities.pcl";
include_once "../../Library/lib_utilities.pcl";

# --- Constants ---

string SPLIT_LABEL = "[SPLIT]";
string LINE_BREAK = "\n";
int BUTTON_FWD = 1;
int BUTTON_BWD = 0;

string PRACTICE_TYPE_PRACTICE = "Practice";
string PRACTICE_TYPE_MAIN = "Main";

string STIM_EVENT_CODE = "Stim";

string NOGO_STIM_LABEL = "[NOGO_STIMULUS_LABEL]";

string STIM_SOUND = "Sound";
string STIM_IMAGE = "Image";
string STIM_BOX = "Box";
string STIM_ELLIPSE = "Ellipse";
string STIM_STRING = "String";

int TYPE_IDX = 1;
int STIM_IDX = 2;
int ISI_IDX = 3;

int COND_GO_IDX = 1;
int COND_NOGO_IDX = 2;

string COND_GO = "Go";
string COND_NOGO = "NoGo";

int PORT_CODE_GO = 10;
int PORT_CODE_NOGO = 100;

int GO_BUTTON = 1;

string CHARACTER_WRAP = "Character";

# --- Set up fixed stimulus parameters ---

string language = parameter_manager.get_string( "Language" );
language_file lang = load_language_file( scenario_directory + language + ".xml" );
bool char_wrap = ( get_lang_item( lang, "Word Wrap Mode" ).lower() == CHARACTER_WRAP.lower() );

adjust_used_screen_size( parameter_manager.get_bool( "Use Widescreen if Available" ) );

double font_size = parameter_manager.get_double( "Default Font Size" );

# Event Setup
trial_refresh_fix( stim_trial, parameter_manager.get_int( "Stimulus Duration" ) );

if ( !parameter_manager.get_bool( "Show Fixation Point" ) ) then
	ISI_pic.clear();
end;

# Setup rest stuff
rest_event.set_port_code( special_port_code1 );
bool show_progress = parameter_manager.get_bool( "Show Progress Bar During Rests" );
word_wrap( get_lang_item( lang, "Rest Screen Caption" ), used_screen_width, used_screen_height / 2.0, font_size, char_wrap, rest_text );
if ( show_progress ) then
	double bar_width = used_screen_width * 0.5;
	full_box.set_width( bar_width );
	rest_pic.set_part_x( 3, -bar_width/2.0, rest_pic.LEFT_COORDINATE );
	rest_pic.set_part_x( 4, -bar_width/2.0, rest_pic.LEFT_COORDINATE );
	progress_text.set_caption( get_lang_item( lang, "Progress Bar Caption" ), true );
else
	rest_pic.clear();
	rest_pic.add_part( rest_text, 0, 0 );
end;

# --- Stimulus Setup ---

string go_stim_type = parameter_manager.get_string( "Go Stimulus Type" );
int go_stim_ct = parameter_manager.get_int( "Go Stimulus Count" );

array<stimulus> all_stim[2][0];

if ( go_stim_type == STIM_SOUND ) then
	array<sound> go_snds[0];
	parameter_manager.get_sounds( "Go Stimulus Sounds", go_snds );
	if ( go_snds.count() != go_stim_ct ) then
		exit( "Error: 'Go Stimulus Sounds' must contain " + string( go_stim_ct ) + " sounds." );
	end;
	loop
		int i = 1
	until
		i > go_stim_ct
	begin
		all_stim[COND_GO_IDX].add( go_snds[i] );
		i = i + 1;
	end;
	stim_trial.set_type( stim_trial.FIXED );
elseif ( go_stim_type == STIM_IMAGE ) then
	array<bitmap> go_bmps[0];
	parameter_manager.get_bitmaps( "Go Stimulus Images", go_bmps );
	if ( go_bmps.count() != go_stim_ct ) then
		exit( "Error: 'Go Stimulus Images' must contain " + string( go_stim_ct ) + " filenames." );
	end;
	loop
		int scaling = parameter_manager.get_int( "Go Stimulus Image Scaling" );
		int i = 1
	until
		i > go_stim_ct
	begin
		go_bmps[i].set_load_size( 0.0, 0.0, double( scaling ) * 0.01 );
		go_bmps[i].load();
		picture this_pic = new picture();
		this_pic.add_part( go_bmps[i], 0, 0 );
		all_stim[COND_GO_IDX].add( this_pic );
		i = i + 1;
	end;
else
	array<rgb_color> go_colors[0];
	parameter_manager.get_colors( "Go Stimulus Colors", go_colors );
	if ( go_colors.count() != go_stim_ct ) then
		exit( "Error: 'Go Stimulus Colors' must contain " + string( go_stim_ct ) + " colors." );
	end;
	
	if ( go_stim_type == STIM_STRING ) then
		array<double> go_font_sizes[0];
		parameter_manager.get_doubles( "Go Stimulus Font Sizes", go_font_sizes );
		if ( go_font_sizes.count() != go_stim_ct ) then
			exit( "Error: 'Go Stimulus Font Sizes' must contain " + string( go_stim_ct ) + " values." );
		end;

		array<string> go_strings[0];
		parameter_manager.get_strings( "Go Stimulus Strings", go_strings );
		if ( go_strings.count() != go_stim_ct ) then
			exit( "Error: 'Go Stimulus Strings' must contain " + string( go_stim_ct ) + " strings." );
		end;
		
		loop
			int i = 1
		until
			i > go_stim_ct
		begin
			text this_text = new text();
			this_text.set_font_size( go_font_sizes[i] );
			this_text.set_font_color( go_colors[i] );
			this_text.set_caption( go_strings[i], true );
			
			picture this_pic = new picture();
			this_pic.add_part( this_text, 0, 0 );
			all_stim[COND_GO_IDX].add( this_pic );
			i = i + 1;
		end;
	else
		array<double> go_heights[0];
		parameter_manager.get_doubles( "Go Stimulus Heights", go_heights );
		if ( go_heights.count() != go_stim_ct ) then
			exit( "Error: 'Go Stimulus Heights' must contain " + string( go_stim_ct ) + " values." );
		end;
		
		array<double> go_widths[0];
		parameter_manager.get_doubles( "Go Stimulus Widths", go_widths );
		if ( go_widths.count() != go_stim_ct ) then
			exit( "Error: 'Go Stimulus Widths' must contain " + string( go_stim_ct ) + " values." );
		end;
		
		loop
			int i = 1
		until
			i > go_stim_ct
		begin
			box this_box = new box( go_heights[i], go_widths[i], go_colors[i] );
			ellipse_graphic this_ellipse = new ellipse_graphic;
			this_ellipse.set_dimensions( go_widths[i], go_heights[i] );
			this_ellipse.set_color( go_colors[i] );
			this_ellipse.redraw();
			
			picture this_pic = new picture();
			if ( go_stim_type == STIM_BOX ) then
				this_pic.add_part( this_box, 0, 0 );
			else
				this_pic.add_part( this_ellipse, 0, 0 );
			end;
			all_stim[COND_GO_IDX].add( this_pic );
			i = i + 1;
		end;
	end;
end;

string nogo_stim_type = parameter_manager.get_string( "NoGo Stimulus Type" );
picture nogo_picture = new picture();

if ( go_stim_type == STIM_SOUND ) || ( nogo_stim_type == STIM_SOUND ) then
	if ( go_stim_type != nogo_stim_type ) then
		exit( "Error: 'Go Stimulus Type' and 'NoGo Stimulus Type' must be the same modality (auditory or visual)." );
	end;
end;

if ( nogo_stim_type == STIM_SOUND ) then
	sound nogo_sound = parameter_manager.get_sound( "NoGo Sound" );
	all_stim[COND_NOGO_IDX].add( nogo_sound );
else
	if ( nogo_stim_type == STIM_IMAGE ) then
		bitmap nogo_bmp = parameter_manager.get_bitmap( "NoGo Image" );
		nogo_bmp.set_load_size( 0.0, 0.0, double( parameter_manager.get_int( "NoGo Image Scaling" ) ) * 0.01 );
		nogo_bmp.load();
		nogo_picture.add_part( nogo_bmp, 0, 0 );
	elseif ( nogo_stim_type == STIM_BOX ) then
		box nogo_box = new box( 1.0, 1.0, parameter_manager.get_color( "NoGo Color" ) );
		nogo_box.set_height( parameter_manager.get_double( "NoGo Height" ) );
		nogo_box.set_width( parameter_manager.get_double( "NoGo Width" ) );
		nogo_picture.add_part( nogo_box, 0, 0 );
	elseif ( nogo_stim_type == STIM_STRING ) then
		string nogo_string = parameter_manager.get_string( "NoGo String" );
		if ( nogo_string.count() == 0 ) then
			exit( "'NoGo String' cannot be empty." );
		end;
		text nogo_text = new text();
		nogo_text.set_font_color( parameter_manager.get_color( "NoGo Color" ) );
		nogo_text.set_font_size( parameter_manager.get_double( "NoGo Font Size" ) );
		nogo_text.set_caption( nogo_string, true );
		nogo_picture.add_part( nogo_text, 0, 0 );
	elseif ( nogo_stim_type == STIM_ELLIPSE ) then
		ellipse_graphic nogo_ellipse = new ellipse_graphic();
		nogo_ellipse.set_color( parameter_manager.get_color( "NoGo Color" ) );
		nogo_ellipse.set_dimensions( parameter_manager.get_double( "NoGo Width" ), parameter_manager.get_double( "NoGo Height" ) );
		nogo_ellipse.redraw();
		nogo_picture.add_part( nogo_ellipse, 0, 0 );
	end;
	all_stim[COND_NOGO_IDX].add( nogo_picture );
end;
	

# --- sub main_instructions --- #

string next_screen = get_lang_item( lang, "Next Screen Caption" );
string prev_screen = get_lang_item( lang, "Previous Screen Caption" );
string final_screen = get_lang_item( lang, "Start Experiment Caption" );
string split_final_screen = get_lang_item( lang, "Multi-Screen Start Experiment Caption" );

bool split_instrucs = parameter_manager.get_bool( "Multi-Screen Instructions" );

sub
	main_instructions( string instruct_string )
begin
	bool has_splits = instruct_string.find( SPLIT_LABEL ) > 0;
	
	# Split screens only if requested and split labels are present
	if ( has_splits ) then
		if ( split_instrucs ) then
			# Split at split points
			array<string> split_instructions[0];
			instruct_string.split( SPLIT_LABEL, split_instructions );
			
			# Hold onto the old terminator buttons for later
			array<int> old_term_buttons[0];
			instruct_trial.get_terminator_buttons( old_term_buttons );
			
			array<int> new_term_buttons[0];
			new_term_buttons.add( BUTTON_FWD );

			# Present each screen in sequence
			loop
				int i = 1
			until
				i > split_instructions.count()
			begin
				# Remove labels and add screen switching/start experiment instructions
				# Remove leading whitespace
				string this_screen = split_instructions[i];
				this_screen = this_screen.trim();
				this_screen = this_screen.replace( SPLIT_LABEL, "" );
				this_screen.append( LINE_BREAK + LINE_BREAK );
				
				# Add the correct button options
				bool can_go_backward = ( i > 1 ) && ( BUTTON_BWD > 0 );
				new_term_buttons.resize( 0 );
				new_term_buttons.add( BUTTON_FWD );
				if ( can_go_backward ) then
					new_term_buttons.add( BUTTON_BWD );
					this_screen.append( prev_screen + " " );
				end;
				
				if ( i < split_instructions.count() ) then
					this_screen.append( next_screen );
				else
					this_screen.append( split_final_screen );
				end;
				
				instruct_trial.set_terminator_buttons( new_term_buttons );
				
				# Word wrap & present the screen
				full_size_word_wrap( this_screen, font_size, char_wrap, instruct_text );
				instruct_trial.present();
				if ( response_manager.last_response_data().button() == BUTTON_BWD ) then
					if ( i > 1 ) then
						i = i - 1;
					end;
				else
					i = i + 1;
				end;
			end;
			# Reset terminator buttons
			instruct_trial.set_terminator_buttons( old_term_buttons );
		else
			# If the caption has splits but multi-screen isn't requested
			# Remove split labels and present everything on one screen
			string this_screen = instruct_string.replace( SPLIT_LABEL, "" );
			this_screen = this_screen.trim();
			this_screen.append( LINE_BREAK + LINE_BREAK + final_screen );
			full_size_word_wrap( this_screen, font_size, char_wrap, instruct_text );
			instruct_trial.present();
		end;
	else
		# If no splits and no multi-screen, present the entire caption at once
		full_size_word_wrap( instruct_string, font_size, char_wrap, instruct_text );
		instruct_trial.present();
	end; 
	default.present();
end;

# --- sub present_instructions --- 

sub
	present_instructions( string instruct_string )
begin
	full_size_word_wrap( instruct_string, font_size, char_wrap, instruct_text );
	instruct_trial.present();
	default.present();
end;

# --- sub show_rest ---

int rest_every = parameter_manager.get_int( "Trials Between Rests" );

sub 
	bool show_rest( int counter_variable, int num_trials )
begin
	if ( rest_every != 0 ) then
		if ( counter_variable >= rest_every ) && ( counter_variable % rest_every == 0 ) && ( counter_variable < num_trials ) then
			if ( show_progress ) then
				progress_box.set_width( used_screen_width * 0.5 * ( double(counter_variable) / double(num_trials) ) );
			end;
			rest_trial.present();
			default.present();
			return true
		end;
	end;
	return false
end;

# --- show_block ---

array<string> stim_conds[2];
stim_conds[COND_GO_IDX] = COND_GO;
stim_conds[COND_NOGO_IDX] = COND_NOGO;

# -- Set up info for summary stats -- #
int SUM_COND_IDX = 1;
int SUM_STIM_IDX = 2;

# Put all the condition names into an array
# Used later to add column headings
array<string> cond_names[2][0];
cond_names[SUM_COND_IDX].assign( stim_conds );

loop
	int i = 1
until
	i > all_stim[COND_GO_IDX].count()
begin
	cond_names[SUM_STIM_IDX].add( string( i ) );
	i = i + 1;
end;

# Now build an empty array for all DVs of interest
array<int> acc_stats[cond_names[1].count()][cond_names[2].count()][0];
array<int> RT_stats[cond_names[1].count()][cond_names[2].count()][0];
# --- End Summary Stats --- #

sub
	double show_block( string prac_check, array<int,2>& trial_array )
begin
	# Shuffle the trial order
	trial_array.shuffle();
	
	# Start with an ISI
	trial_refresh_fix( ISI_trial, trial_array[random(1,trial_array.count())][ISI_IDX] );
	ISI_trial.present();
	
	# Loop to present the trials
	double block_acc = 0.0;
	loop
		int hits = 0;
		int i = 1
	until
		i > trial_array.count()
	begin
		# Get some info about this trial
		int this_type = trial_array[i][TYPE_IDX];
		int this_stim = trial_array[i][STIM_IDX];
		int this_ISI = trial_array[i][ISI_IDX];
		
		# Set the target button & port code
		int p_code = PORT_CODE_GO;
		if ( this_type == COND_GO_IDX ) then
			stim_event.set_target_button( GO_BUTTON );
		else
			stim_event.set_target_button( 0 );
			stim_event.set_response_active( true );
			p_code = PORT_CODE_NOGO;
		end;
		stim_event.set_port_code( p_code );
	
		# Set the stimulus
		stim_event.set_stimulus( all_stim[this_type][this_stim] );

		# Set the ISI
		trial_refresh_fix( ISI_trial, this_ISI );
		
		# Set the event code
		stim_event.set_event_code( 
			STIM_EVENT_CODE + ";" +
			prac_check + ";" +
			string( i ) + ";" +
			stim_conds[this_type] + ";" +
			string( this_stim ) + ";" +
			string( this_ISI )
		);
		
		# Trial sequence
		stim_trial.present();
		stimulus_data last = stimulus_manager.last_stimulus_data();
		ISI_trial.present();

		# Update the block accuracy
		if ( last.type() == last.HIT ) || ( last.type() == last.OTHER ) then
			hits = hits + 1;
		end;
		block_acc = double( hits ) / double( i );
		
		# Record trial info for summary stats
		# Make an int array specifying the condition we're in
		# This tells us which subarray to store the trial info
		if ( prac_check == PRACTICE_TYPE_MAIN ) then
			array<int> this_trial[cond_names.count()];
			this_trial[SUM_COND_IDX] = this_type;
			this_trial[SUM_STIM_IDX] = this_stim;
			
			int this_hit = int( last.type() == last.HIT || last.type() == last.OTHER );
			acc_stats[this_trial[1]][this_trial[2]].add( this_hit );
			if ( last.reaction_time() > 0 ) then
				RT_stats[this_trial[1]][this_trial[2]].add( last.reaction_time() );
			end;
		end;
		
		# Rest
		if ( prac_check == PRACTICE_TYPE_MAIN ) then
			if ( show_rest( i, trial_array.count() ) ) then
				ISI_trial.present();
			end;
		end;
		
		i = i + 1;
	end;
	return block_acc
end;

# --- Conditions & Trial Order --- #

array<int> cond_array[0][0];
array<int> prac_array[0][0];

begin
	# Get the possible ISIs	
	array<int> ISI_durations[0];
	parameter_manager.get_ints( "ISI Durations", ISI_durations );
	if ( ISI_durations.count() == 0 ) then
		exit( "'ISI Durations' must contain at least one value." );
	end;
	
	# Add no-go trials
	int nogo_trials = parameter_manager.get_int( "NoGo Trials" );
	loop
		array<int> temp[3];
		int i = 1
	until
		i > nogo_trials
	begin
		if ( i % ISI_durations.count() == 0 ) then
			ISI_durations.shuffle();
		end;
		temp[TYPE_IDX] = COND_NOGO_IDX;
		temp[STIM_IDX] = 1;
		temp[ISI_IDX] = ISI_durations[ ( i % ISI_durations.count() ) + 1 ];
		cond_array.add( temp );
		i = i + 1;
	end;
	
	# Get the go stimulus trial counts
	array<int> go_trial_counts[0];
	parameter_manager.get_ints( "Go Stimulus Trial Counts", go_trial_counts );
	if ( go_trial_counts.count() != go_stim_ct ) then
		exit( "'Go Trial Counts' must contain 'Go Stimulus Count' values." );
	end;
	
	# Add go stimulus trials to the array
	loop
		array<int> temp[3];
		int i = 1;
	until
		i > go_trial_counts.count()
	begin
		loop
			int j = 1
		until
			j > go_trial_counts[i]
		begin
			if ( j % ISI_durations.count() == 0 ) then
				ISI_durations.shuffle();
			end;
			temp[TYPE_IDX] = COND_GO_IDX;
			temp[STIM_IDX] = i;
			temp[ISI_IDX] = ISI_durations[ ( i % ISI_durations.count() ) + 1 ];
			cond_array.add( temp );
			j = j + 1;
		end;
		i = i + 1;
	end;
	
	# Build the practice array
	int prac_trials = parameter_manager.get_int( "Practice Trials" );
	
	# Start by adding a no-go trial to ensure one occurs in short practice sessions
	if ( prac_trials > 1 ) then
		prac_array.add( cond_array[1] );
	end;
	
	# Add random trials & resize
	loop
	until
		prac_array.count() >= prac_trials
	begin
		prac_array.add( cond_array[random(1,cond_array.count())] );
	end;
	prac_array.resize( prac_trials );
end;

# --- Main Sequence ---

if ( go_stim_type == STIM_SOUND ) then
	lang.set_map( STIM_SOUND );
end;
string instructions = get_lang_item( lang, "Instructions" );
instructions = instructions.replace( NOGO_STIM_LABEL, parameter_manager.get_string( "NoGo Stimulus Description" ) );
int prac_threshold = parameter_manager.get_int( "Minimum Percent Correct to Complete Practice" );

# Show practice trials or instructions
if ( prac_array.count() > 0 ) then
	main_instructions( instructions + " " + get_lang_item( lang, "Practice Caption" ) );
	loop 
		double block_accuracy = -1.0
	until 
		block_accuracy >= ( double( prac_threshold ) / 100.0 )
	begin
		block_accuracy = show_block( PRACTICE_TYPE_PRACTICE, prac_array );
	end;
	present_instructions( get_lang_item( lang, "Practice Complete Caption" ) );
else
	main_instructions( instructions );
end;
show_block( PRACTICE_TYPE_MAIN, cond_array );
present_instructions( get_lang_item( lang, "Completion Screen Caption" ) );

# --- Print Summary Stats --- #

string sum_log = logfile.filename();
if ( sum_log.count() > 0 ) then
	# Open & name the output file
	string TAB = "\t";
	int ext = sum_log.find( ".log" );
	sum_log = sum_log.substring( 1, ext - 1 ) + "-Summary-" + date_time( "yyyymmdd-hhnnss" ) + ".txt";
	string subj = logfile.subject();
	output_file out = new output_file;
	out.open( sum_log );

	# Print the headings for each columns
	array<string> cond_headings[cond_names.count() + 1];
	cond_headings[1] = "Subject ID";
	cond_headings[SUM_COND_IDX + 1] = "Condition";
	cond_headings[SUM_STIM_IDX + 1] = "Stimulus Number";
	cond_headings.add( "Accuracy" );
	cond_headings.add( "Accuracy (SD)" );
	cond_headings.add( "Avg RT" );
	cond_headings.add( "Avg RT (SD)" );
	cond_headings.add( "Median RT" );
	cond_headings.add( "Number of Trials" );
	cond_headings.add( "Date/Time" );

	loop
		int i = 1
	until
		i > cond_headings.count()
	begin
		out.print( cond_headings[i] + TAB );
		i = i + 1;
	end;

	# Loop through the DV arrays to print each condition in its own row
	# Following the headings set up above
	loop
		int i = 1
	until
		i > acc_stats.count()
	begin
		loop
			int j = 1
		until
			j > acc_stats[i].count()
		begin
			if ( acc_stats[i][j].count() > 0 ) then
				out.print( "\n" + subj + TAB );
				out.print( cond_names[1][i] + TAB );
				out.print( cond_names[2][j] + TAB );
				out.print( round( arithmetic_mean( acc_stats[i][j] ), 3 ) );
				out.print( TAB );
				out.print( round( sample_std_dev( acc_stats[i][j] ), 3 ) );
				out.print( TAB );
				out.print( round( arithmetic_mean( RT_stats[i][j] ), 3 ) );
				out.print( TAB );
				out.print( round( sample_std_dev( RT_stats[i][j] ), 3 ) );
				out.print( TAB );
				out.print( round( median_value( RT_stats[i][j] ), 3 ) );
				out.print( TAB );
				out.print( acc_stats[i][j].count() );
				out.print( TAB );
				out.print( date_time() );
			end;
			j = j + 1;
		end;
		i = i + 1;
	end;

	# Close the file and exit
	out.close();
end;