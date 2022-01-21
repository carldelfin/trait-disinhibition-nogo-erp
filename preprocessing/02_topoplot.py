# ------------------------------------------------------------------------------
# import modules
# ------------------------------------------------------------------------------

import os
import mne
import multiprocessing
from mne.parallel import parallel_func
from mne.preprocessing import ICA
from autoreject import AutoReject
import collections
from datetime import datetime
import matplotlib.pyplot as plt
import matplotlib
matplotlib.use('Agg')
import re
import numpy as np
import pandas as pd
import glob
import time

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
evoked_data_outputdir = current_pwd + '/tmp/evoked/'

# results directories
log_outputdir = current_pwd + '/output/logs/'
averaged_data_outputdir = current_pwd + '/output/data/'
plot_outputdir = current_pwd + '/output/plots/'

# ------------------------------------------------------------------------------
# prepare data
# ------------------------------------------------------------------------------

def cm2inch(*tupl):
    inch = 2.54
    if isinstance(tupl[0], tuple):
        return tuple(i/inch for i in tupl[0])
    else:
        return tuple(i/inch for i in tupl)

# list all evoked files from EEG preprocessing
evoked_files_con = glob.glob(evoked_data_outputdir + 'KON*.fif')
evoked_files_pat = glob.glob(evoked_data_outputdir + 'RPK*.fif')

# include only files matching 'nogocorr'
nogocorr = re.compile('.*nogocorr')
evoked_files_con = list(filter(nogocorr.match, evoked_files_con))
evoked_files_pat = list(filter(nogocorr.match, evoked_files_pat))

con = []
pat = []

for files in evoked_files_con:
    file = files
    con.append(mne.read_evokeds(file, condition = 'nogocorr', proj = True, verbose = None))

for files in evoked_files_pat:
    file = files
    pat.append(mne.read_evokeds(file, condition = 'nogocorr', proj = True, verbose = None))

# average
grand_average_con = mne.grand_average(con)
grand_average_pat = mne.grand_average(pat)

# select channels for marking
frontal_channels = 19, 11, 4, 117, 12, 5, 111, 6, 105

# set plot arguments
mask = np.zeros_like(grand_average_con.data, dtype = bool)
mask_params = dict(marker = 'o', markerfacecolor = 'w', markeredgecolor = 'k', linewidth = 0, markersize = 4)
mask[[frontal_channels], :] = True

fig, ax = plt.subplots(2, 13, figsize = (cm2inch(24, 6)))

# ------------------------------------------------------------------------------
# N2 plot
# ------------------------------------------------------------------------------

times = (0.290)
vmin = -3
vmax = 3

# kwargs
kwargs = dict(times = times,
              res = 32,
              cmap = 'Spectral_r',
              vmin = vmin,
              vmax = vmax,
              contours = 6,
              extrapolate = 'box',
              sphere = None,
              mask = mask,
              sensors = False,
              time_unit = 's',
              colorbar = True)

con_topo = grand_average_con.plot_topomap(**kwargs)
pat_topo = grand_average_pat.plot_topomap(**kwargs)

con_topo.savefig(plot_outputdir + 'con_topo_n2_290.svg', dpi = 300, bbox_inches = 'tight',
    pad_inches = 0)

pat_topo.savefig(plot_outputdir + 'pat_topo_n2_290.svg', dpi = 300, bbox_inches = 'tight',
    pad_inches = 0)

# ------------------------------------------------------------------------------
# P3 plot
# ------------------------------------------------------------------------------

times = (0.450)
vmin = -9
vmax = 9

# kwargs
kwargs = dict(times = times,
              res = 32,
              cmap = 'Spectral_r',
              vmin = vmin,
              vmax = vmax,
              contours = 6,
              extrapolate = 'box',
              sphere = None,
              mask = mask,
              sensors = False,
              time_unit = 's',
              colorbar = True)

con_topo = grand_average_con.plot_topomap(**kwargs)
pat_topo = grand_average_pat.plot_topomap(**kwargs)

con_topo.savefig(plot_outputdir + 'con_topo_p3_400.svg', dpi = 300, bbox_inches = 'tight',
    pad_inches = 0)

pat_topo.savefig(plot_outputdir + 'pat_topo_p3_400.svg', dpi = 300, bbox_inches = 'tight',
    pad_inches = 0)
