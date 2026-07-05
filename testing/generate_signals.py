# generate_signals_bad_sensor.py
# Enhanced randomized sensor data with realistic bad-sensor behaviors.
import numpy as np
from scipy.signal import medfilt, lfilter

np.random.seed(0)
N = 200
t = np.arange(N)

# ---------- helper functions ----------
def lowpass_noise(N, sigma, tau):
    """Generate low-pass (correlated) noise using a simple IIR filter.
       tau = smoothing time constant in samples (larger => smoother)."""
    white = np.random.normal(0, sigma, N)
    b = [1.0]
    a = [1.0, -(1 - 1.0/max(1, tau))]
    # simple one-pole lowpass (approx). Use exponential smoothing manually:
    out = np.zeros(N)
    alpha = 1.0 / max(1, tau)
    out[0] = white[0]
    for i in range(1, N):
        out[i] = (1-alpha)*out[i-1] + alpha*white[i]
    return out

def inject_spikes(x, prob=0.005, mag_range=(10,50), burst_prob=0.001, burst_len=(2,10)):
    """Random isolated spikes and occasional bursts. prob = per-sample isolate spike chance."""
    y = x.copy()
    for i in range(N):
        if np.random.rand() < prob:
            # isolated spike (additive)
            sign = 1 if np.random.rand() < 0.5 else -1
            y[i] += sign * np.random.uniform(*mag_range)
        if np.random.rand() < burst_prob:
            L = np.random.randint(burst_len[0], burst_len[1]+1)
            sign = 1 if np.random.rand() < 0.5 else -1
            mag = np.random.uniform(*mag_range)
            for k in range(i, min(N, i+L)):
                y[k] += sign * mag * np.random.uniform(0.6, 1.4)  # burst with variation
    return y

def inject_dropouts(x, prob=0.002, hold_prev=True):
    """Random dropouts. If hold_prev True, repeat previous value (stuck), else insert NaN sentinel."""
    y = x.copy()
    for i in range(N):
        if np.random.rand() < prob:
            L = np.random.randint(1, 10)  # dropout length
            for k in range(i, min(N, i+L)):
                if hold_prev and k>0:
                    y[k] = y[k-1]
                else:
                    y[k] = np.nan
    return y

def clamp(x, lo, hi):
    return np.minimum(np.maximum(x, lo), hi)

# ---------- randomized base signals ----------
# randomize baseline, amplitude, frequency
def rand_base(min_b, max_b): return np.random.uniform(min_b, max_b)
def rand_amp(min_a, max_a): return np.random.uniform(min_a, max_a)
def rand_freq(min_f, max_f): return np.random.uniform(min_f, max_f)

# Temperature
temp_base = rand_base(28, 32)
temp_amp  = rand_amp(0.5, 2.0)
temp_freq = rand_freq(0.008, 0.03)
temp_clean = temp_base + temp_amp * np.sin(2*np.pi*temp_freq*t)

# Humidity
hum_base = rand_base(55, 70)
hum_amp  = rand_amp(2, 6)
hum_freq = rand_freq(0.006, 0.02)
hum_clean = hum_base + hum_amp * np.sin(2*np.pi*hum_freq*t)

# PM2.5
pm_base = rand_base(20, 120)
pm_amp  = rand_amp(6, 30)
pm_freq = rand_freq(0.02, 0.07)
pm_clean = pm_base + pm_amp * np.sin(2*np.pi*pm_freq*t)

# ---------- noise (white + correlated) ----------
temp_noise = lowpass_noise(N, sigma=np.random.uniform(0.3,0.9), tau=8)
hum_noise  = lowpass_noise(N, sigma=np.random.uniform(0.8,2.0), tau=12)
pm_noise   = lowpass_noise(N, sigma=np.random.uniform(3.0,8.0), tau=6)

# additive measurement
temp_noisy = temp_clean + temp_noise
hum_noisy  = hum_clean  + hum_noise
pm_noisy   = pm_clean   + pm_noise

# ---------- inject more realistic bad behaviors ----------
# spikes (rare), bursts (rarer)
temp_noisy = inject_spikes(temp_noisy, prob=0.001, mag_range=(1,4), burst_prob=0.0005, burst_len=(2,6))
hum_noisy  = inject_spikes(hum_noisy,  prob=0.003, mag_range=(6,14), burst_prob=0.001,  burst_len=(2,12))
pm_noisy   = inject_spikes(pm_noisy,   prob=0.004, mag_range=(20,80), burst_prob=0.001,  burst_len=(3,20))

# small drift (random walk)
temp_drift = np.cumsum(np.random.normal(0, 0.0005, N))   # small
hum_drift  = np.cumsum(np.random.normal(0, 0.002, N))
pm_drift   = np.cumsum(np.random.normal(0, 0.01, N))

temp_noisy += temp_drift
hum_noisy  += hum_drift
pm_noisy   += pm_drift

# occasional stuck-at or dropout
temp_noisy = inject_dropouts(temp_noisy, prob=0.0005, hold_prev=True)
hum_noisy  = inject_dropouts(hum_noisy,  prob=0.001,  hold_prev=True)
pm_noisy   = inject_dropouts(pm_noisy,   prob=0.0008, hold_prev=True)

# occasional calibration offset jump (bias step)
if np.random.rand() < 0.5:
    idx = np.random.randint(100, 900)
    temp_noisy[idx:] += np.random.uniform(-1.5, 1.5)  # step bias
if np.random.rand() < 0.5:
    idx = np.random.randint(100, 900)
    hum_noisy[idx:] += np.random.uniform(-5, 5)
if np.random.rand() < 0.5:
    idx = np.random.randint(100, 900)
    pm_noisy[idx:] += np.random.uniform(-20, 40)

# sensor saturation/clipping by physical limits
temp_noisy = clamp(temp_noisy, -40, 85)
hum_noisy  = clamp(hum_noisy,  0, 100)
pm_noisy   = clamp(pm_noisy,   0, 1000)  # PM sometimes can spike high

# ---------- filters (same logic you requested) ----------
def moving_average(x, N=8):
    return np.convolve(x, np.ones(N)/N, mode='same')

# temp: MA-8 (apply sensor dynamics: simple first-order response)
alpha = 0.6
temp_dynamic = np.zeros_like(temp_noisy)
temp_dynamic[0] = temp_noisy[0]
for i in range(1,N):
    temp_dynamic[i] = alpha*temp_dynamic[i-1] + (1-alpha)*temp_noisy[i]
temp_filtered = moving_average(temp_dynamic, N=8)

# hum: outlier(raw) -> MA8
hum_out = hum_noisy.copy()
for i in range(1, N):
    # use 8 units threshold as in your design (absolute units)
    if abs(hum_noisy[i] - hum_noisy[i-1]) > 6:
        hum_out[i] = hum_out[i-1]
hum_filtered = moving_average(hum_out, N=8)

# pm: med3 -> ma4
pm_med3 = medfilt(pm_noisy, kernel_size=3)
pm_filtered = moving_average(pm_med3, N=4)

# ---------- save float files ----------
np.savetxt("temp_noisy.txt", temp_noisy, fmt="%.6f")
np.savetxt("temp_filtered_python.txt", temp_filtered, fmt="%.6f")

np.savetxt("hum_noisy.txt", hum_noisy, fmt="%.6f")
np.savetxt("hum_filtered_python.txt", hum_filtered, fmt="%.6f")

np.savetxt("pm_noisy.txt", pm_noisy, fmt="%.6f")
np.savetxt("pm_filtered_python.txt", pm_filtered, fmt="%.6f")

# ---------- Q8.8 conversion and saving ----------
def to_q88(arr):
    # replace NaN/dropout sentinel with previous value or zero before quantizing
    a = np.array(arr, dtype=float)
    # forward-fill NaNs with previous valid value; if first entries NaN -> set to 0
    for i in range(len(a)):
        if np.isnan(a[i]):
            a[i] = a[i-1] if i>0 else 0.0
    return np.round(a * 256).astype(int)

np.savetxt("input_temp_q88.txt", to_q88(temp_noisy), fmt="%d")
np.savetxt("gold_temp_q88.txt", to_q88(temp_filtered), fmt="%d")

np.savetxt("input_hum_q88.txt", to_q88(hum_noisy), fmt="%d")
np.savetxt("gold_hum_q88.txt", to_q88(hum_filtered), fmt="%d")

np.savetxt("input_pm_q88.txt", to_q88(pm_noisy), fmt="%d")
np.savetxt("gold_pm_q88.txt", to_q88(pm_filtered), fmt="%d")

np.savetxt("temp_clean.txt", to_q88(temp_clean), fmt="%d")
np.savetxt("hum_clean.txt", to_q88(hum_clean), fmt="%d")
np.savetxt("pm_clean.txt", to_q88(pm_clean), fmt="%d")
