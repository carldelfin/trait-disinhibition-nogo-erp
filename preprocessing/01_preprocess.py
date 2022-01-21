# ==============================================================================
# EEG data preprocessing script
# Carl Delfin, May, 2020
#
# This script contains several functions, most based on MNE-Python,
# used for preprocessing of EEG data.
#
# Feel free to use and modify as you see fit.
# ==============================================================================

# ------------------------------------------------------------------------------
# import modules
# ------------------------------------------------------------------------------

import os
import sys
import mne
import multiprocessing
from mne.parallel import parallel_func
from mne.preprocessing import ICA
from autoreject import AutoReject
import collections
import matplotlib.pyplot as plt
import matplotlib
matplotlib.use('Agg')
import re
import numpy as np
import pandas as pd
import time
from sinfo import sinfo

# ------------------------------------------------------------------------------
# prepare directories
# ------------------------------------------------------------------------------
    
# current dir
current_pwd = os.path.dirname(os.path.realpath(__file__))

# bad channels input directory
bad_channel_inputdir = current_pwd + '/input/bad_channels/'

# ICA solutions input directory
ica_inputdir = current_pwd + '/input/ica_solutions/'

# temp data directories
cropped_data_outputdir = current_pwd + '/tmp/cropped/'
filtered_data_outputdir = current_pwd + '/tmp/filtered/'
cleaned_data_outputdir = current_pwd + '/tmp/cleaned/'
epoched_data_outputdir = current_pwd + '/tmp/epoched/'
cleaned_epoched_data_outputdir = current_pwd + '/tmp/cleaned_epoched/'
evoked_data_outputdir = current_pwd + '/tmp/evoked/'

# output directories
averaged_data_outputdir = current_pwd + '/output/data/'
raw_averaged_data_outputdir = current_pwd + '/output/raw_data/'
plot_outputdir = current_pwd + '/output/plots/'
log_outputdir = current_pwd + '/output/logs/'

# ------------------------------------------------------------------------------
# preprocessing parameters
# ------------------------------------------------------------------------------

mon = mne.channels.read_custom_montage(current_pwd + '/input/montage/GSN-HydroCel-129.sfp')

# filters
raw_filter_highpass = 0.1
raw_filter_lowpass = 30
raw_ica_filter_highpass = 1
raw_ica_filter_lowpass = 30
filter_method = 'fir'
filter_phase = 'zero'
fir_window = 'hamming'
fir_design = 'firwin'

# epochs
tmin = -0.2
tmax = 0.8
baseline = (-0.2, .0)

# ------------------------------------------------------------------------------
# 0) file splitter
# ------------------------------------------------------------------------------

def file_splitter(file):
    file = file.rstrip(os.sep)
    file = os.path.basename(file)
    file, sep, tail = file.partition('_')
    return(file)

# ------------------------------------------------------------------------------
# 1) prepare data function
# ------------------------------------------------------------------------------

def prepare_data(participant):

    file = current_pwd + '/input/data/' + participant
    participantid = file_splitter(file)
    raw = mne.io.read_raw_egi(file, preload = True)
    raw.set_montage(mon)

    # drop reference electrode (it's silent anyways)
    raw = raw.drop_channels(['E129'])

    # crop a bit of unecessary data at the end of recording, keeps file size down
    final_event = mne.find_events(raw)[-1][0]*0.001
    if raw.times.max() > final_event + 1:
      raw = raw.crop(0, final_event + 1)
    else:
      raw = raw.crop(0, raw.times.max())

    raw.save(cropped_data_outputdir + participantid + '_cropped.raw.fif', 
    overwrite = overwrite_opts)

# ------------------------------------------------------------------------------
# 2) filter data function
# ------------------------------------------------------------------------------

def filter_data(participant):
    file = current_pwd + '/input/data/' + participant
    participantid = file_splitter(file)
    raw = mne.io.read_raw_fif(cropped_data_outputdir + participantid + '_cropped.raw.fif', preload = True)
    raw_ica = raw.copy()

    # separate filters for raw data and data used for ICA
    raw.filter(raw_filter_highpass, 
               raw_filter_lowpass, 
               filter_length = 'auto', 
               l_trans_bandwidth = 'auto', 
               h_trans_bandwidth = 'auto', 
               n_jobs = 1, 
               method = filter_method, 
               iir_params = None, 
               phase = filter_phase, 
               fir_window = fir_window, 
               verbose = None, 
               fir_design = fir_design)

    raw_ica.filter(raw_ica_filter_highpass, 
                   raw_ica_filter_lowpass, 
                   filter_length = 'auto', 
                   l_trans_bandwidth = 'auto', 
                   h_trans_bandwidth = 'auto', 
                   n_jobs = 1, 
                   method = filter_method, 
                   iir_params = None, 
                   phase = filter_phase, 
                   fir_window = fir_window, 
                   verbose = None, 
                   fir_design = fir_design)

    with open(bad_channel_inputdir + participantid + '_bad_channels', 'r') as f:
        bad_channels = [line.rstrip('\n') for line in f]

    raw.info['bads'] = bad_channels
    raw_ica.info['bads'] = bad_channels

    if(len(bad_channels) > 0):
        raw.interpolate_bads(reset_bads = True, mode = 'accurate')
        raw_ica.interpolate_bads(reset_bads = True, mode = 'accurate')

    raw.set_eeg_reference()
    raw_ica.set_eeg_reference()

    raw.save(filtered_data_outputdir + participantid + '_filtered.raw.fif', 
             overwrite = overwrite_opts)

    raw_ica.save(filtered_data_outputdir + participantid + '_filtered_ica.raw.fif', 
             overwrite = overwrite_opts)

    filter_log = {
     'ID': participantid, 
     'raw_highpass': raw_filter_highpass, 
     'raw_lowpass': raw_filter_lowpass, 
     'raw_ica_highpass': raw_ica_filter_highpass, 
     'raw_ica_lowpass': raw_ica_filter_lowpass, 
     'filter_method': filter_method, 
     'filter_phase': filter_phase, 
     'fir_window': fir_window, 
     'fir_design': fir_design, 
     'num_bad_channels_interpolated': len(bad_channels), 
    }

    filter_log_df = pd.DataFrame(filter_log, index = [0])
    filter_log_df.to_csv(log_outputdir + participantid + '_filter_log' + '.csv')

# ------------------------------------------------------------------------------
# 3) ICA function
# ------------------------------------------------------------------------------

def apply_ica(participant):
    file = current_pwd + '/input/data/' + participant
    participantid = file_splitter(file)
    raw = mne.io.read_raw_fif(filtered_data_outputdir + participantid + '_filtered.raw.fif', 
                              preload = True)
    raw_clean = raw.copy()
    ica = mne.preprocessing.read_ica(ica_inputdir + participantid + '_ica.fif')

    ica.apply(raw_clean)
    #ica_plot = ica.plot_overlay(raw, ica.exclude, start = 0)
    #ica_plot.savefig(plot_outputdir + participantid + '_before_and_after_ICA' + '.png')

    raw_clean.save(cleaned_data_outputdir + participantid + '_cleaned.raw.fif', 
             overwrite = overwrite_opts)

    ica_log = {
     'ID': participantid, 
     'num_icas_zeroed_out': len(ica.exclude)
     }

    ica_log_df = pd.DataFrame(ica_log, index = [0])
    ica_log_df.to_csv(log_outputdir + participantid + '_ica_log' + '.csv')

# ------------------------------------------------------------------------------
# 4) epoch and resample function
# ------------------------------------------------------------------------------

def epoch_data(participant):
    file = current_pwd + '/input/data/' + participant
    participantid = file_splitter(file)
    raw_clean = mne.io.read_raw_fif(cleaned_data_outputdir + participantid + '_cleaned.raw.fif', preload = True)

    # reject quiet channels < 5 mV
    flat = dict(eeg = 5e-6)

    # get event IDs
    events = mne.find_events(raw_clean, stim_channel = 'STI 014', verbose = None)

    # some subjects have different event IDs for different stims, 
    # so we'll need to extract and count occurences
    num_events = events[:, 2]
    counted_events = collections.Counter(num_events)

    # we know that the order of counts should be:
    # (1) responses, 300 + usually
    # (2) go trials, 274 (although some have one more due to starting the recording
    # before participants finished practice trials)
    # (3) nogo trials, always 52
    # (4) pause, always 1
    ordered_events = counted_events.most_common()

    if len(ordered_events) == 4:
        response = ordered_events[0][0]
        go = ordered_events[1][0]
        nogo = ordered_events[2][0]
        pause = ordered_events[3][0]

        event_id = {'Response': response, 
                  'Go': go, 
                  'NoGo': nogo, 
                  'Pause': pause}

    elif len(ordered_events) == 3:
        response = ordered_events[0][0]
        go = ordered_events[1][0]
        nogo = ordered_events[2][0]

        event_id = {'Response': response, 
                    'Go': go, 
                    'NoGo': nogo}

    else:
        sys.exit('Error occured during event counting')

    events_old = events
    for j in range(0, len(events)-1):
        if events_old[j, 2] == go and events_old[j + 1, 2] == response:
            events[j, 2] = 11
        elif events_old[j, 2] == nogo and (events_old[j + 1, 2] == go or events_old[j + 1, 2] == nogo):
            events[j, 2] = 101
        elif events_old[j, 2] == response and events_old[j-1, 2] == nogo: # response locked
            events[j, 2] = 102

    event_id = {'gocorr': 11, 'nogocorr': 101, 'nogoincorr': 102}

    if sum(events[:, 2] == 102) == 0:
        event_id = {'gocorr': 11, 'nogocorr': 101}

    picks = mne.pick_types(raw_clean.info, 
                         eeg = True, 
                         exclude = 'bads')

    raw_clean.info['projs'] = list()

    epochs = mne.Epochs(raw_clean, events, event_id, tmin, tmax, 
                        picks = picks, 
                        baseline = baseline, 
                        flat = flat, 
                        preload = True, 
                        verbose = None, 
                        detrend = None)

    epochs.resample(500, npad = 'auto')

    epochs.save(epoched_data_outputdir + participantid + '-epo.fif', 
                split_size = '2GB', 
                fmt = 'double', 
                verbose = None, 
                overwrite = overwrite_opts)

    epoch_log = {
     'ID': participantid, 
     'num_correct_go_trials': sum(events[:, 2] == 11), 
     'num_correct_nogo_trials': sum(events[:, 2] == 101), 
     'num_incorrect_nogo_trials': sum(events[:, 2] == 102)
     }

    epoch_log_df = pd.DataFrame(epoch_log, index = [0])
    epoch_log_df.to_csv(log_outputdir + participantid + '_epoch_log' + '.csv')

# ------------------------------------------------------------------------------
# 5) autoreject function
# ------------------------------------------------------------------------------

def autoreject_data(participant, njobs, ar_threshold, autoreject_cv, autoreject_random_state):
    file = current_pwd + '/input/data/' + participant
    participantid = file_splitter(file)
    epochs = mne.read_epochs(epoched_data_outputdir + participantid + '-epo.fif', 
                            proj = True, 
                            preload = True, 
                            verbose = None)

    ar = AutoReject(thresh_method = 'bayesian_optimization', 
    cv = autoreject_cv, 
    random_state = autoreject_random_state, 
    n_jobs = njobs, 
    verbose = False)

    epochs_clean, reject_log = ar.fit_transform(epochs, return_log = True)

    num_go_correct = int(re.findall(r'(\d+) events', str(epochs['gocorr']))[0])
    num_nogo_correct = int(re.findall(r'(\d+) events', str(epochs['nogocorr']))[0])
    # no 'get' attribute for epochs, hence the exception handler
    try:
        num_nogo_incorrect = int(re.findall(r'(\d+) events', str(epochs['nogoincorr']))[0])
    except KeyError:
        num_nogo_incorrect = 0

    # look at number of epochs after autoreject
    num_go_correct_ar = int(re.findall(r'(\d+) events', str(epochs_clean['gocorr']))[0])
    num_nogo_correct_ar = int(re.findall(r'(\d+) events', str(epochs_clean['nogocorr']))[0])
    try:
        num_nogo_incorrect_ar = int(re.findall(r'(\d+) events', str(epochs_clean['nogoincorr']))[0])
    except KeyError:
        num_nogo_incorrect_ar = 0

    # percent incorrect nogo trials left after autoreject
    if num_nogo_incorrect == 0 and num_nogo_incorrect_ar == 0:
        percent_incorr_nogo_ar = 0
    else:
        percent_incorr_nogo_ar = round(num_nogo_incorrect_ar / num_nogo_incorrect * 100, 2)

    # how many individual channels per epoch were good, bad or interpolated?
    rejected_channels = np.concatenate(reject_log.labels)
    total = len(rejected_channels)
    bad = np.count_nonzero(rejected_channels == 1)
    interpolated = np.count_nonzero(rejected_channels == 2)

	# optional plotting
    # plt.ioff()
    # fig, ax = plt.subplots(2, 1)
    # fig.tight_layout()
    # ylim = dict(eeg = (-15, 15))
    # epochs.average().plot(ylim = ylim, spatial_colors = True, axes = ax[0])
    # epochs_clean.average().plot(ylim = ylim, spatial_colors = True, axes = ax[1])
    # fig.savefig(plot_outputdir + participantid + '_before_after_AR' + '.png')
    # plt.close(fig)

    # save cleaned epoched data only if number of correct nogo trials left after
    # AR exceeds a certain threshold
    if num_nogo_correct_ar >= ar_threshold:
        epochs_clean.save(cleaned_epoched_data_outputdir + participantid + '_cleaned-epo.fif', 
                split_size = '2GB', fmt = 'double', 
                verbose = None, overwrite = overwrite_opts)

    autoreject_log = {
     'ID': participantid, 
     'num_correct_go_trials_after_ar': num_go_correct_ar, 
     'perc_correct_go_trials_after_ar': num_go_correct_ar / num_go_correct * 100, 
     'num_correct_nogo_trials_after_ar': num_nogo_correct_ar, 
     'perc_correct_nogo_trials_after_ar': num_nogo_correct_ar / num_nogo_correct * 100, 
     'num_incorrect_nogo_trials_after_ar': num_nogo_incorrect_ar, 
     'perc_incorrect_nogo_trials_after_ar': percent_incorr_nogo_ar, 
     'perc_bad_and_rejected_channels': bad / total * 100, 
     'perc_bad_and_interpolated_channels': interpolated / total * 100, 
    }

    autoreject_log_df = pd.DataFrame(autoreject_log, index = [0])
    autoreject_log_df.to_csv(log_outputdir + participantid + '_autoreject_log' + '.csv')

# ------------------------------------------------------------------------------
# 6) save data function
# ------------------------------------------------------------------------------

def save_data(participant):
    file = current_pwd + '/input/data/' + participant
    participantid = file_splitter(file)

    # only load data if ar_threshold was satisfied
    if os.path.isfile(cleaned_epoched_data_outputdir + participantid + '_cleaned-epo.fif'):
        epochs_clean = mne.read_epochs(cleaned_epoched_data_outputdir + participantid + '_cleaned-epo.fif', 
                                proj = True, 
                                preload = True, 
                                verbose = None)
                            
        # save averaged evoked data
        evoked_data_nogo_correct = epochs_clean['nogocorr'].average()
        evoked_data_nogo_correct.save(evoked_data_outputdir + participantid + '_nogocorr-ave.fif')

        #evoked_data_go_correct = epochs_clean['gocorr'].average()
        #evoked_data_go_correct.save(evoked_data_outputdir + participantid + '_gocorr-ave.fif')

        # save as csv for import to R
        
        # averaged
        evoked_data_nogo_correct_csv = evoked_data_nogo_correct.to_data_frame()
        evoked_data_nogo_correct_csv.to_csv(averaged_data_outputdir + participantid + '_nogocorr.csv')

        #evoked_data_go_correct_csv = evoked_data_go_correct.to_data_frame()
        #evoked_data_go_correct_csv.to_csv(averaged_data_outputdir + participantid + '_gocorr.csv')
        
        # non-averaged (raw)
        raw_evoked_data_nogo_correct = epochs_clean['nogocorr']
        #raw_evoked_data_go_correct = epochs_clean['gocorr']

        raw_evoked_data_nogo_correct_csv = raw_evoked_data_nogo_correct.to_data_frame()
        raw_evoked_data_nogo_correct_csv.to_csv(raw_averaged_data_outputdir + participantid + '_nogocorr_raw.csv')

        #raw_evoked_data_go_correct_csv = raw_evoked_data_go_correct.to_data_frame()
        #raw_evoked_data_go_correct_csv.to_csv(raw_averaged_data_outputdir + participantid + '_gocorr_raw.csv')


# ------------------------------------------------------------------------------
# select functions
# ------------------------------------------------------------------------------

def run_preprocess(participant):

    # start timer
    start = time.time()

    file = current_pwd + '/input/data/' + participant
    participantid = file_splitter(file)

    print('Preproccesing participant', participantid)

    # functions
    prepare_data(participant)
    filter_data(participant)
    apply_ica(participant)
    epoch_data(participant)
    autoreject_data(participant, 1, ar_threshold, autoreject_cv, autoreject_random_state)
    save_data(participant)

    # stop timer
    end = time.time()
    print('Done! Preprocessing took', round((end-start) / 60, 2), 'minutes to complete for participant', participantid)

    # save timer log
    timer_log = {
     'ID': participantid, 
     'preprocessing_time_in_minutes': round((end-start) / 60, 2)
    }

    timer_log_df = pd.DataFrame(timer_log, index = [0])
    timer_log_df.to_csv(log_outputdir + participantid + '_timer_log' + '.csv')

# ------------------------------------------------------------------------------
# run pipeline
# ------------------------------------------------------------------------------

parallel_cores = int(12)
ar_threshold = int(4)
autoreject_cv = int(10)
autoreject_random_state = int(2020)

overwrite_opts = True
mne.set_config('MNE_LOGGING_LEVEL', 'CRITICAL')

print('\nPreprocessing will begin with the following parameters:', 
      '\nCPU cores = ', parallel_cores, 
      '\nAR threshold = ', ar_threshold, 
      '\nAR CV folds = ', autoreject_cv,
      '\nAR random state = ', autoreject_random_state,
      '\nOverwrite = ', overwrite_opts, 
      '\nVerbose outout = ', mne.get_config(key = 'MNE_LOGGING_LEVEL'), '\n')

files = os.listdir(current_pwd + '/input/data/')
parallel, run_func, _ = parallel_func(run_preprocess, n_jobs = parallel_cores, total = None)
parallel(run_func(participant) for participant in files)

# ------------------------------------------------------------------------------
# session info
# ------------------------------------------------------------------------------

class Logger(object):
    def __init__(self):
        self.terminal = sys.stdout

    def write(self, message):
        with open (log_outputdir + "session_info.txt", "a", encoding = 'utf-8') as self.log:            
            self.log.write(message)
        self.terminal.write(message)

    def flush(self):
        pass

sys.stdout = Logger()
sinfo()
