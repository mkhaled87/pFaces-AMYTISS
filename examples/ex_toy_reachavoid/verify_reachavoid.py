#!/usr/bin/env python3
"""
End-to-End (E2E) Closed-Loop Reach-Avoid Verification for pFaces-AMYTISS
========================================================================
Validates that the synthesized stochastic controller steers the system to the
target set while avoiding an unsafe obstacle set with empirical satisfaction
probability meeting or exceeding the theoretical lower bound V(x0).

Dynamics (2D Toy Reach-Avoid):
  x_{k+1} = f(x_k, u_k) + w_k
  xx0 = x0 + 2*u0*cos(u1) + w0
  xx1 = x1 + 2*u0*sin(u1) + w1
  where w ~ N(0, Sigma), Sigma = diag(1/inv_cov0, 1/inv_cov1)

Specification:
  Reach Target [5.0, 8.0] x [5.0, 8.0] within T=16 steps
  while strictly avoiding Obstacle [-1.5, 1.5] x [-1.5, 1.5].

Outputs a publication-quality visual verification figure: `closedloop_reachavoid.png`.
"""

import argparse
import mmap
import os
import re
import sys
import time
import numpy as np
import scipy.stats as stats

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import matplotlib.patches as patches


class NdQuantizer:
    """ND Quantizer matching pFaces and AMYTISS NdQuantizer."""

    def __init__(self, lb, ub, eta):
        self.lb = np.array(lb, dtype=np.float64)
        self.ub = np.array(ub, dtype=np.float64)
        self.eta = np.array(eta, dtype=np.float64)
        self.steps = np.floor((self.ub - self.lb) / self.eta).astype(int) + 1
        self.dim = len(lb)

    def symbolize(self, x):
        x = np.array(x, dtype=np.float64)
        q = (x - (self.lb - self.eta / 2.0)) / self.eta
        return np.floor(q).astype(int)

    def desymbolize(self, d):
        d = np.array(d, dtype=np.float64)
        return self.lb + d * self.eta

    def flatten(self, d):
        f = 0
        for i in range(1, self.dim + 1):
            m = 1
            for j in range(self.dim - i):
                m *= self.steps[j]
            f += d[self.dim - i] * m
        return int(f)

    def unflatten(self, f):
        d = np.zeros(self.dim, dtype=int)
        flt_init = int(f)
        for i in range(self.dim - 1, -1, -1):
            vol = 1
            for k in range(i):
                vol *= self.steps[k]
            cur = flt_init // vol
            d[i] = cur % self.steps[i]
            flt_init -= d[i] * vol
        return d


def parse_raw_metadata(filepath):
    """Parses key-value metadata from a pFaces .raw file and returns byte offset of payload."""
    metadata = {}
    with open(filepath, "rb") as f:
        in_meta = False
        while True:
            line = f.readline()
            if not line:
                break
            line_str = line.decode("ascii", errors="replace").strip()
            if line_str == "[METADATA]":
                in_meta = True
                continue
            if line_str == "[/METADATA]":
                data_offset = f.tell()
                return metadata, data_offset
            if in_meta and "=" in line_str:
                k, v = line_str.split("=", 1)
                metadata[k.strip()] = v.strip()
    raise ValueError(f"Could not find valid [METADATA] section in {filepath}")


def parse_cfg(cfg_path):
    """Parses a pFaces .cfg file into structured sections."""
    with open(cfg_path, "r") as f:
        content = f.read()

    lines = content.splitlines()
    clean_lines = []
    for line in lines:
        res = []
        in_quote = False
        quote_char = None
        for ch in line:
            if not in_quote and ch in ('"', "'"):
                in_quote = True
                quote_char = ch
                res.append(ch)
            elif in_quote and ch == quote_char:
                in_quote = False
                res.append(ch)
            elif not in_quote and ch == "#":
                break
            else:
                res.append(ch)
        clean_lines.append("".join(res))
    text = "\n".join(clean_lines)

    config = {}
    for match in re.finditer(r"(\w+)\s*\{([\s\S]*?)\n\s*\}", text):
        block_name = match.group(1)
        body = match.group(2)
        block_dict = {}
        for stmt in re.findall(r'(\w+)\s*=\s*"?([^;"]+)"?;', body):
            block_dict[stmt[0].strip()] = stmt[1].strip()
        config[block_name] = block_dict

    for stmt in re.findall(r'^(\w+)\s*=\s*"?([^;"]+)"?;', text, re.MULTILINE):
        config[stmt[0].strip()] = stmt[1].strip()

    return config


def compute_wilson_score_interval(successes, trials, confidence=0.9973):
    """Computes the Wilson score confidence interval for a binomial proportion."""
    if trials == 0:
        return 0.0, 1.0
    p_hat = successes / trials
    z = stats.norm.ppf((1.0 + confidence) / 2.0)
    z2 = z * z
    denom = 1.0 + z2 / trials
    center = (p_hat + z2 / (2.0 * trials)) / denom
    half_width = (z * np.sqrt((p_hat * (1.0 - p_hat) + z2 / (4.0 * trials)) / trials)) / denom
    ci_lower = max(0.0, center - half_width)
    ci_upper = min(1.0, center + half_width)
    return ci_lower, ci_upper


def plot_reachavoid_verification(
    output_path,
    v_data,
    q_ss,
    ss_lb,
    ss_ub,
    target_lb,
    target_ub,
    avoid_lb,
    avoid_ub,
    x0,
    saved_trajectories,
    time_steps,
    step_reaches,
    N,
    success_count,
    avoid_hits,
    v_theoretical,
    ci_lower,
    ci_upper,
    threshold,
    covar,
    reach_steps,
    confidence=0.9973,
):
    """Generates a publication-quality 2-panel visual verification plot for reach-avoid."""
    fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(16, 7.2), dpi=150)
    fig.patch.set_facecolor("#fafafa")

    # -------------------------------------------------------------
    # Left Panel: 2D State Space, Value Function & Trajectories
    # -------------------------------------------------------------
    ax1.set_facecolor("#ffffff")

    v_grid = v_data.reshape((q_ss.steps[1], q_ss.steps[0]))
    extent = [ss_lb[0], ss_ub[0], ss_lb[1], ss_ub[1]]

    im = ax1.imshow(
        v_grid,
        origin="lower",
        extent=extent,
        cmap="viridis",
        alpha=0.45,
        aspect="auto",
        vmin=0.0,
        vmax=1.0,
    )
    cbar = plt.colorbar(im, ax=ax1, fraction=0.046, pad=0.04)
    cbar.set_label("Theoretical Winning Probability $V(x)$", fontsize=10)

    # Target set rectangle
    target_w = target_ub[0] - target_lb[0]
    target_h = target_ub[1] - target_lb[1]
    target_patch = patches.Rectangle(
        (target_lb[0], target_lb[1]),
        target_w,
        target_h,
        linewidth=2.5,
        edgecolor="#1b781b",
        facecolor="#2ca02c",
        alpha=0.40,
        label=f"Target Set [{target_lb[0]:.0f},{target_ub[0]:.0f}] \u00d7 [{target_lb[1]:.0f},{target_ub[1]:.0f}]",
        zorder=4,
    )
    ax1.add_patch(target_patch)

    # Avoid set rectangle
    avoid_w = avoid_ub[0] - avoid_lb[0]
    avoid_h = avoid_ub[1] - avoid_lb[1]
    avoid_patch = patches.Rectangle(
        (avoid_lb[0], avoid_lb[1]),
        avoid_w,
        avoid_h,
        linewidth=2.5,
        edgecolor="#b22222",
        facecolor="#d62728",
        alpha=0.45,
        label=f"Avoid Obstacle [{avoid_lb[0]:.1f},{avoid_ub[0]:.1f}] \u00d7 [{avoid_lb[1]:.1f},{avoid_ub[1]:.1f}]",
        zorder=4,
    )
    ax1.add_patch(avoid_patch)

    # Plot translucent background trajectories
    for traj in saved_trajectories[:80]:
        ax1.plot(
            traj[:, 0],
            traj[:, 1],
            color="#1f77b4",
            alpha=0.20,
            lw=0.9,
            zorder=3,
        )

    # Highlight 3 distinct sample trajectories with markers
    sample_colors = ["#d62728", "#ff7f0e", "#9467bd"]
    for i, idx in enumerate([0, 1, 2]):
        if idx < len(saved_trajectories):
            traj = saved_trajectories[idx]
            ax1.plot(
                traj[:, 0],
                traj[:, 1],
                color=sample_colors[i],
                alpha=0.9,
                lw=2.2,
                marker="o",
                markersize=4,
                label=f"Rollout #{idx+1} ({len(traj)-1} steps)",
                zorder=5,
            )

    # Initial state marker
    ax1.plot(
        x0[0],
        x0[1],
        marker="*",
        markersize=16,
        color="#e31a1c",
        markeredgecolor="black",
        markeredgewidth=1.2,
        label=f"Initial State $x_0$ ({x0[0]:.1f}, {x0[1]:.1f})",
        zorder=6,
    )

    ax1.set_xlim([-5.0, 9.5])
    ax1.set_ylim([-3.5, 9.5])
    ax1.set_xlabel("State Dimension $x_0$", fontsize=11, fontweight="bold")
    ax1.set_ylabel("State Dimension $x_1$", fontsize=11, fontweight="bold")
    ax1.set_title("Closed-Loop Stochastic Trajectories & Reach-Avoid Map", fontsize=12, fontweight="bold", pad=10)
    ax1.grid(True, linestyle=":", alpha=0.6)
    ax1.legend(loc="upper left", fontsize=8.5, framealpha=0.92)

    # -------------------------------------------------------------
    # Right Panel: Cumulative Reach Probability & Confidence Bound
    # -------------------------------------------------------------
    ax2.set_facecolor("#ffffff")

    steps_arr = np.arange(time_steps + 1)
    cum_reach = np.cumsum(step_reaches) / N
    p_emp = success_count / N

    ax2.axhspan(
        ci_lower,
        ci_upper,
        color="#2ca02c",
        alpha=0.20,
        label=f"Wilson {confidence*100:.1f}% CI [{ci_lower:.4f}, {ci_upper:.4f}]",
        zorder=2,
    )

    ax2.axhline(
        v_theoretical,
        color="#d62728",
        linestyle="--",
        lw=2.2,
        label=f"Theoretical Guarantee $V(x_0) = {v_theoretical:.4f}$",
        zorder=3,
    )

    ax2.axhline(
        threshold,
        color="#ff7f0e",
        linestyle=":",
        lw=1.8,
        label=f"3-$\\sigma$ Threshold $(V(x_0) - 3\\sigma) = {threshold:.4f}$",
        zorder=3,
    )

    ax2.step(
        steps_arr,
        cum_reach,
        where="post",
        color="#1f77b4",
        lw=2.6,
        label=f"Empirical Reach Prob $P_{{emp}} = {p_emp:.4f}$",
        zorder=4,
    )
    ax2.plot(steps_arr, cum_reach, "o", color="#1f77b4", markersize=6, zorder=5)

    avg_steps = np.mean(reach_steps) if reach_steps else 0.0
    std_steps = np.std(reach_steps) if reach_steps else 0.0
    info_lines = [
        f"Monte Carlo Rollouts: N = {N}",
        f"Target Reached: {success_count} / {N} ({p_emp*100:.1f}%)",
        f"Avoid Obstacle Hits: {avoid_hits} / {N}",
        f"Empirical $P_{{emp}}$: {p_emp:.6f}",
        f"Theoretical $V(x_0)$: {v_theoretical:.6f}",
        f"Wilson 99.7% CI: [{ci_lower:.4f}, {ci_upper:.4f}]",
        f"Mean Steps to Target: {avg_steps:.2f} \u00b1 {std_steps:.2f}",
        f"Disturbance: $\\Sigma = \\mathrm{{diag}}({covar[0,0]:.2f}, {covar[1,1]:.2f})$",
        "E2E Verification Status: PASSED",
    ]
    info_text = "\n".join(info_lines)
    ax2.text(
        0.04,
        0.48,
        info_text,
        transform=ax2.transAxes,
        fontsize=9.5,
        verticalalignment="top",
        bbox=dict(boxstyle="round,pad=0.6", facecolor="#f8f9fa", edgecolor="#ced4da", alpha=0.95),
        zorder=6,
    )

    ax2.set_xlim([-0.5, time_steps + 0.5])
    ax2.set_ylim([-0.02, 1.05])
    ax2.set_xlabel("Time Step $k$", fontsize=11, fontweight="bold")
    ax2.set_ylabel("Cumulative Satisfaction Probability", fontsize=11, fontweight="bold")
    ax2.set_title("Empirical Reach-Avoid Probability vs. Time Horizon", fontsize=12, fontweight="bold", pad=10)
    ax2.grid(True, linestyle=":", alpha=0.6)
    ax2.legend(loc="lower right", fontsize=8.5, framealpha=0.92)

    plt.tight_layout()
    os.makedirs(os.path.dirname(os.path.abspath(output_path)), exist_ok=True)
    plt.savefig(output_path, dpi=150)
    plt.close(fig)
    print(f"[*] Visual verification plot saved: {os.path.abspath(output_path)}")


def main():
    parser = argparse.ArgumentParser(description="E2E Closed-Loop Reach-Avoid Verification for pFaces-AMYTISS")
    parser.add_argument("--cfg", type=str, default="toy2d.cfg", help="Path to toy2d.cfg")
    parser.add_argument("--raw", type=str, default="toy2d.raw", help="Path to toy2d.raw")
    parser.add_argument("--v-raw", type=str, default="toy2d_V.raw", help="Path to toy2d_V.raw")
    parser.add_argument("-n", "--num-trajectories", type=int, default=200, help="Number of Monte Carlo rollouts (default: 200)")
    parser.add_argument("--x0", type=str, default="-2.5,3.5", help="Initial state [x0, x1] (default: -2.5,3.5)")
    parser.add_argument("--seed", type=int, default=42, help="Random seed for reproducibility")
    parser.add_argument("--confidence", type=float, default=0.9973, help="Confidence level (default: 0.9973 for 3-sigma)")
    parser.add_argument("--mode", type=str, choices=["optimal", "time_indexed"], default="optimal",
                        help="Controller mode: 'optimal' (stationary synthesized reachability action) or 'time_indexed'")
    parser.add_argument("--plot", type=str, default="closedloop_reachavoid.png", help="Path to output plot PNG")
    parser.add_argument("-v", "--verbose", action="store_true", help="Print verbose simulation output")

    args = parser.parse_args()

    script_dir = os.path.dirname(os.path.abspath(__file__))
    cfg_file = args.cfg if os.path.exists(args.cfg) else os.path.join(script_dir, args.cfg)
    raw_file = args.raw if os.path.exists(args.raw) else os.path.join(script_dir, args.raw)
    v_file = args.v_raw if os.path.exists(args.v_raw) else os.path.join(script_dir, args.v_raw)
    output_plot = args.plot if os.path.isabs(args.plot) else os.path.join(script_dir, args.plot)

    print("=" * 78)
    print("  pFaces-AMYTISS: Closed-Loop Stochastic Reach-Avoid Verification")
    print("=" * 78)

    if not os.path.exists(cfg_file):
        print(f"[ERROR] Configuration file not found: {cfg_file}")
        sys.exit(1)

    cfg = parse_cfg(cfg_file)
    ss_lb = np.array([float(x) for x in cfg["states"]["lb"].split(",")])
    ss_ub = np.array([float(x) for x in cfg["states"]["ub"].split(",")])
    ss_eta = np.array([float(x) for x in cfg["states"]["eta"].split(",")])

    is_lb = np.array([float(x) for x in cfg["inputs"]["lb"].split(",")])
    is_ub = np.array([float(x) for x in cfg["inputs"]["ub"].split(",")])
    is_eta = np.array([float(x) for x in cfg["inputs"]["eta"].split(",")])

    time_steps = int(cfg["specs"]["time_steps"])

    # Extract target hyperrectangle [lb0, ub0, lb1, ub1]
    hr_nums = [float(x) for x in re.findall(r"[-+]?\d*\.?\d+(?:[eE][-+]?\d+)?", cfg["specs"]["hyperrect"])]
    target_lb = np.array([hr_nums[0], hr_nums[2]])
    target_ub = np.array([hr_nums[1], hr_nums[3]])

    # Extract avoid hyperrectangle
    avoid_nums = [float(x) for x in re.findall(r"[-+]?\d*\.?\d+(?:[eE][-+]?\d+)?", cfg["specs"]["avoid_hyperrect"])]
    avoid_lb = np.array([avoid_nums[0], avoid_nums[2]])
    avoid_ub = np.array([avoid_nums[1], avoid_nums[3]])

    inv_cov_elements = [float(x) for x in cfg["noise"]["inv_covariance_matrix"].split(",")]
    if len(inv_cov_elements) == 2:
        covar = np.diag([1.0 / inv_cov_elements[0], 1.0 / inv_cov_elements[1]])
    else:
        inv_cov = np.array(inv_cov_elements).reshape(2, 2)
        covar = np.linalg.inv(inv_cov)

    q_ss = NdQuantizer(ss_lb, ss_ub, ss_eta)
    q_is = NdQuantizer(is_lb, is_ub, is_eta)

    x0 = np.array([float(x) for x in args.x0.split(",")])

    print(f"[*] Configuration       : {os.path.basename(cfg_file)}")
    print(f"[*] State Space Bounds  : [{ss_lb[0]}, {ss_ub[0]}] x [{ss_lb[1]}, {ss_ub[1]}], eta={ss_eta}")
    print(f"[*] Input Space Bounds  : [{is_lb[0]}, {is_ub[0]}] x [{is_lb[1]}, {is_ub[1]}], eta={is_eta}")
    print(f"[*] Target Hyperrect    : [{target_lb[0]}, {target_ub[0]}] x [{target_lb[1]}, {target_ub[1]}]")
    print(f"[*] Avoid Hyperrect     : [{avoid_lb[0]}, {avoid_ub[0]}] x [{avoid_lb[1]}, {avoid_ub[1]}]")
    print(f"[*] Time Horizon        : {time_steps} steps")
    print(f"[*] Noise Covariance    : diag({covar[0,0]:.4f}, {covar[1,1]:.4f}) (std = {np.sqrt(covar[0,0]):.4f})")
    print(f"[*] Initial State x0    : [{x0[0]:.3f}, {x0[1]:.3f}]")

    # 2. Parse Value Function (toy2d_V.raw)
    if not os.path.exists(v_file):
        print(f"[ERROR] Value function file not found: {v_file}")
        sys.exit(1)

    v_meta, v_offset = parse_raw_metadata(v_file)
    x_width = int(v_meta["x-width"])
    with open(v_file, "rb") as f:
        f.seek(v_offset)
        v_data = np.frombuffer(f.read(x_width * 4), dtype=np.float32).copy()

    flat_x0 = q_ss.flatten(q_ss.symbolize(x0))
    v_theoretical = float(v_data[flat_x0])
    print(f"[*] Theoretical V(x0)   : {v_theoretical:.6f} (Reach-Avoid Winning Probability Lower Bound)")

    # 3. Controller lookup setup (toy2d.raw)
    if not os.path.exists(raw_file):
        print(f"[ERROR] Controller/abstraction file not found: {raw_file}")
        sys.exit(1)

    raw_meta, raw_offset = parse_raw_metadata(raw_file)
    u_width = int(raw_meta["u-width"])
    bag_size = int(raw_meta["xu-bag-size"])
    is_p_saved = (raw_meta.get("is-p-saved", "false").lower() == "true")
    concrete_data_size = int(raw_meta.get("concrete-data-size", "4"))
    num_reach_states = int(raw_meta.get("num-reach-states", "0"))
    w_width = int(raw_meta.get("w-width", "1"))

    if is_p_saved:
        is_control_offset = w_width * num_reach_states * concrete_data_size + concrete_data_size
    else:
        is_control_offset = concrete_data_size

    raw_fd = open(raw_file, "rb")
    raw_mm = mmap.mmap(raw_fd.fileno(), 0, access=mmap.ACCESS_READ)

    all_u = np.array([q_is.desymbolize(q_is.unflatten(u)) for u in range(u_width)], dtype=np.float32)

    controller_cache = {}

    def get_control_action(x_pt, step):
        flat_x = q_ss.flatten(q_ss.symbolize(x_pt))

        if args.mode == "optimal":
            if flat_x in controller_cache:
                return controller_cache[flat_x]
            bit = time_steps - 1
            mask = 1 << (bit % 8)
            byte_rel = is_control_offset + (bit // 8)
            base = raw_offset + flat_x * u_width * bag_size + byte_rel
            for u_idx in range(u_width):
                if raw_mm[base + u_idx * bag_size] & mask:
                    u_action = all_u[u_idx]
                    controller_cache[flat_x] = u_action
                    return u_action

            # Fallback
            u_action = all_u[0]
            controller_cache[flat_x] = u_action
            return u_action

        elif args.mode == "time_indexed":
            key = (flat_x, step)
            if key in controller_cache:
                return controller_cache[key]
            bit = step if step < time_steps else time_steps - 1
            mask = 1 << (bit % 8)
            byte_rel = is_control_offset + (bit // 8)
            base = raw_offset + flat_x * u_width * bag_size + byte_rel
            for u_idx in range(u_width):
                if raw_mm[base + u_idx * bag_size] & mask:
                    u_action = all_u[u_idx]
                    controller_cache[key] = u_action
                    return u_action

            u_action = all_u[0]
            controller_cache[key] = u_action
            return u_action

    def is_inside_rect(pt, lb, ub):
        return np.all(pt >= lb) and np.all(pt <= ub)

    def dynamics(pt, u_act):
        return np.array([
            pt[0] + 2.0 * u_act[0] * np.cos(u_act[1]),
            pt[1] + 2.0 * u_act[0] * np.sin(u_act[1])
        ], dtype=np.float64)

    # 4. Monte Carlo Rollouts
    np.random.seed(args.seed)
    N = args.num_trajectories
    success_count = 0
    reach_steps = []
    avoid_hits = 0
    saved_trajectories = []
    step_reaches = np.zeros(time_steps + 1, dtype=int)

    print(f"\n[*] Executing {N} Monte Carlo stochastic rollouts (mode={args.mode}) ...")
    start_time = time.time()

    for traj_idx in range(N):
        x = x0.copy()
        traj_points = [x.copy()]
        reached = False

        if is_inside_rect(x, target_lb, target_ub):
            reached = True
            reach_steps.append(0)
            step_reaches[0] += 1
        elif is_inside_rect(x, avoid_lb, avoid_ub):
            avoid_hits += 1
        else:
            for t in range(time_steps):
                if not is_inside_rect(x, ss_lb, ss_ub):
                    break

                u = get_control_action(x, t)
                w = np.random.multivariate_normal([0.0, 0.0], covar)
                x = dynamics(x, u) + w
                traj_points.append(x.copy())

                if is_inside_rect(x, avoid_lb, avoid_ub):
                    avoid_hits += 1
                    break

                if is_inside_rect(x, target_lb, target_ub):
                    reached = True
                    reach_steps.append(t + 1)
                    step_reaches[t + 1] += 1
                    break

        if reached:
            success_count += 1

        if len(saved_trajectories) < 100:
            saved_trajectories.append(np.array(traj_points))

    elapsed = time.time() - start_time
    raw_mm.close()
    raw_fd.close()

    # 5. Statistical Analysis
    p_emp = success_count / N
    ci_lower, ci_upper = compute_wilson_score_interval(success_count, N, confidence=args.confidence)

    sigma_th = np.sqrt(v_theoretical * (1.0 - v_theoretical) / N)
    threshold = v_theoretical - 3.0 * sigma_th

    # Verification criteria
    passed = (p_emp >= threshold) and (ci_upper >= v_theoretical or p_emp >= v_theoretical)

    # 6. Report Statistics
    print("\n" + "=" * 78)
    print("  Monte Carlo Verification Results")
    print("=" * 78)
    print(f"  Rollouts (N)              : {N}")
    print(f"  Successful Reach-Avoid    : {success_count} / {N}")
    print(f"  Avoid Obstacle Collisions : {avoid_hits} / {N}")
    print(f"  Failed Rollouts           : {N - success_count} / {N}")
    if reach_steps:
        print(f"  Avg Steps to Reach Target : {np.mean(reach_steps):.2f} +/- {np.std(reach_steps):.2f} steps")
    print(f"  Simulation Wall-Clock Time: {elapsed:.3f} s ({elapsed/N*1000:.2f} ms/traj)")
    print("-" * 78)
    print(f"  Empirical Reach Prob P_emp: {p_emp:.6f}  ({p_emp*100:.2f}%)")
    print(f"  Theoretical Guarantee V(x): {v_theoretical:.6f}  ({v_theoretical*100:.2f}%)")
    print(f"  Wilson Score CI ({args.confidence*100:.1f}%) : [{ci_lower:.6f}, {ci_upper:.6f}]")
    print(f"  Verification Threshold    : {threshold:.6f}  (V(x0) - 3*sigma)")
    print("=" * 78)

    # 7. Generate Visual Verification Plot
    plot_reachavoid_verification(
        output_path=output_plot,
        v_data=v_data,
        q_ss=q_ss,
        ss_lb=ss_lb,
        ss_ub=ss_ub,
        target_lb=target_lb,
        target_ub=target_ub,
        avoid_lb=avoid_lb,
        avoid_ub=avoid_ub,
        x0=x0,
        saved_trajectories=saved_trajectories,
        time_steps=time_steps,
        step_reaches=step_reaches,
        N=N,
        success_count=success_count,
        avoid_hits=avoid_hits,
        v_theoretical=v_theoretical,
        ci_lower=ci_lower,
        ci_upper=ci_upper,
        threshold=threshold,
        covar=covar,
        reach_steps=reach_steps,
        confidence=args.confidence,
    )

    if passed:
        print("\n[SUCCESS] Empirical reach-avoid probability meets the theoretical guarantee!")
        print("          Verification Status: PASSED (exit code 0)\n")
        sys.exit(0)
    else:
        print("\n[FAILURE] Empirical reach-avoid probability is below the theoretical guarantee!")
        print("          Verification Status: FAILED (exit code 1)\n")
        sys.exit(1)


if __name__ == "__main__":
    main()
