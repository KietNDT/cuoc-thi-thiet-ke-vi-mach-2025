# compare.py  --- No external libraries used

def load_file(path):
    data = []
    with open(path, "r") as f:
        for line in f:
            line = line.strip()
            if line:
                data.append(int(line))
    return data


def compute_error(a, b):
    """Return absolute error."""
    return abs(a - b)


def detect_latency_shift(dut, gold, max_shift=50):
    """
    Try shifts from [-max_shift, +max_shift].
    Return the shift that gives the smallest total absolute error.
    """
    best_shift = 0
    best_err = 10**30

    for shift in range(-max_shift, max_shift + 1):
        total_err = 0
        count = 0

        for i in range(len(gold)):
            j = i + shift
            if 0 <= j < len(dut):
                total_err += abs(dut[j] - gold[i])
                count += 1

        if count > 0 and total_err < best_err:
            best_err = total_err
            best_shift = shift

    return best_shift


def analyze(dut_file, gold_file, label, critical_factor=5):
    print("\n==============================")
    print("CHANNEL:", label)
    print("==============================")

    dut  = load_file(dut_file)
    gold = load_file(gold_file)

    print("Loaded DUT samples :", len(dut))
    print("Loaded GOLD samples:", len(gold))

    # ------------------------------------------------------
    #  Detect latency shift automatically
    # ------------------------------------------------------
    shift = detect_latency_shift(dut, gold)
    print("Detected latency shift:", shift)

    # ------------------------------------------------------
    #  Compare with shift
    # ------------------------------------------------------
    length = min(len(gold), len(dut))

    max_err = 0
    total_err = 0
    mismatch_count = 0
    total_valid = 0

    print("\nDetailed mismatches (first 20 shown):")
    shown = 0

    print("\nCritical mismatches (error > {}× margin):".format(critical_factor))
    crit_shown = 0

    for i in range(length):
        j = i + shift
        if j < 0 or j >= len(dut):
            continue

        d = dut[j]
        g = gold[i]
        err = compute_error(d, g)

        total_err += err
        total_valid += 1
        if err > max_err:
            max_err = err

        # error margin = 1% of golden
        margin = max(1, int(0.01 * abs(g)))

        # normal mismatch
        if err > margin:
            mismatch_count += 1
            if shown < 20:
                print(f" index {i}:  DUT={d}  GOLD={g}  ERR={err}  margin={margin}")
                shown += 1

        # critical mismatch
        if err > critical_factor * margin:
            if crit_shown < 20:
                print(f" ***CRITICAL*** index {i}:  DUT={d}  GOLD={g}  ERR={err}  margin={margin}")
                crit_shown += 1

    print("\n----- SUMMARY -----")
    print("Latency shift applied :", shift)
    print("Valid comparisons     :", total_valid)
    print("Max absolute error    :", max_err)
    print("Mean absolute error   :", (total_err / total_valid) if total_valid else 0)
    print("Mismatch count        :", mismatch_count)
    print("Pass rate             :", f"{100 - 100*mismatch_count/total_valid:.2f} %")
    print("--------------------")



# ==============================================================
# Run analysis for all 3 channels
# ==============================================================

analyze("output_pm_q88.txt",   "gold_pm_q88.txt",   "PM2.5")
analyze("output_temp_q88.txt", "gold_temp_q88.txt", "TEMP")
analyze("output_hum_q88.txt",  "gold_hum_q88.txt",  "HUMIDITY")
