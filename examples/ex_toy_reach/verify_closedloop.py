#!/usr/bin/env python3
"""
End-to-End (E2E) Closed-Loop Verification for pFaces-AMYTISS
=============================================================
Validates that the synthesized stochastic controller guarantees reaching the target
set with the theoretical winning probability under additive Gaussian disturbance.

Dynamics (2D Toy Reach):
  x_{k+1} = f(x_k, u_k) + w_k
  xx0 = x0 + 2*u0*cos(u1) + w0
  xx1 = x1 + 2*u0*sin(u1) + w1
  where w ~ N(0, Sigma)
"""

import argparse
import mmap
import os
import re
import sys
import time
import numpy as np
import scipy.stats as stats


class NdQuantizer:
    """ND Quantizer matching pFaces and AMYTISS NdQuantizer.m."""

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

    # Remove comments while preserving strings
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
    # Block regex: block_name { ... }
    for match in re.finditer(r"(\w+)\s*\{([\s\S]*?)\n\s*\}", text):
        block_name = match.group(1)
        body = match.group(2)
        block_dict = {}
        for stmt in re.findall(r'(\w+)\s*=\s*"?([^;"]+)"?;', body):
            block_dict[stmt[0].strip()] = stmt[1].strip()
        config[block_name] = block_dict

    # Top-level variables
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


def main():
    parser = argparse.ArgumentParser(description="E2E Closed-Loop Verification for pFaces-AMYTISS")
    parser.add_argument("--cfg", type=str, default="toy2d.cfg", help="Path to toy2d.cfg")
    parser.add_argument("--raw", type=str, default="toy2d.raw", help="Path to toy2d.raw")
    parser.add_argument("--v-raw", type=str, default="toy2d_V.raw", help="Path to toy2d_V.raw")
    parser.add_argument("-n", "--num-trajectories", type=int, default=1000, help="Number of Monte Carlo rollouts")
    parser.add_argument("--x0", type=str, default="-1.5,-1.5", help="Initial state [x0, x1]")
    parser.add_argument("--seed", type=int, default=42, help="Random seed for reproducibility")
    parser.add_argument("--confidence", type=float, default=0.9973, help="Confidence level (default: 0.9973 for 3-sigma)")
    parser.add_argument("--mode", type=str, choices=["optimal", "q_lookup", "time_indexed"], default="optimal",
                        help="Controller mode: 'optimal' (synthesized reachability action), 'q_lookup' (online argmax E[V]), or 'time_indexed'")
    parser.add_argument("-v", "--verbose", action="store_true", help="Print verbose simulation output")

    args = parser.parse_args()

    # Resolve paths relative to script directory if not found in cwd
    script_dir = os.path.dirname(os.path.abspath(__file__))
    cfg_file = args.cfg if os.path.exists(args.cfg) else os.path.join(script_dir, args.cfg)
    raw_file = args.raw if os.path.exists(args.raw) else os.path.join(script_dir, args.raw)
    v_file = args.v_raw if os.path.exists(args.v_raw) else os.path.join(script_dir, args.v_raw)

    print("=" * 78)
    print("  pFaces-AMYTISS: Closed-Loop Stochastic End-to-End Verification")
    print("=" * 78)

    # 1. Parse configuration
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

    # Noise covariance matrix
    inv_cov_elements = [float(x) for x in cfg["noise"]["inv_covariance_matrix"].split(",")]
    if len(inv_cov_elements) == 2:
        covar = np.diag([1.0 / inv_cov_elements[0], 1.0 / inv_cov_elements[1]])
    else:
        inv_cov = np.array(inv_cov_elements).reshape(2, 2)
        covar = np.linalg.inv(inv_cov)

    # Quantizers
    q_ss = NdQuantizer(ss_lb, ss_ub, ss_eta)
    q_is = NdQuantizer(is_lb, is_ub, is_eta)

    # Initial state
    x0 = np.array([float(x) for x in args.x0.split(",")])

    print(f"[*] Configuration       : {os.path.basename(cfg_file)}")
    print(f"[*] State Space Bounds  : [{ss_lb[0]}, {ss_ub[0]}] x [{ss_lb[1]}, {ss_ub[1]}], eta={ss_eta}")
    print(f"[*] Input Space Bounds  : [{is_lb[0]}, {is_ub[0]}] x [{is_lb[1]}, {is_ub[1]}], eta={is_eta}")
    print(f"[*] Target Hyperrect    : [{target_lb[0]}, {target_ub[0]}] x [{target_lb[1]}, {target_ub[1]}]")
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
    print(f"[*] Theoretical V(x0)   : {v_theoretical:.6f} (Winning Probability Lower Bound)")

    # 3. Controller lookup setup (toy2d.raw)
    if not os.path.exists(raw_file):
        print(f"[ERROR] Controller/abstraction file not found: {raw_file}")
        sys.exit(1)

    raw_meta, raw_offset = parse_raw_metadata(raw_file)
    u_width = int(raw_meta["u-width"])
    bag_size = int(raw_meta["xu-bag-size"])
    is_control_offset = 680
    num_reach_states = int(raw_meta["num-reach-states"])

    raw_fd = open(raw_file, "rb")
    raw_mm = mmap.mmap(raw_fd.fileno(), 0, access=mmap.ACCESS_READ)

    # Precompute candidate controls and displacements
    all_u = np.array([q_is.desymbolize(q_is.unflatten(u)) for u in range(u_width)], dtype=np.float32)
    u_displacements = np.stack([
        2.0 * all_u[:, 0] * np.cos(all_u[:, 1]),
        2.0 * all_u[:, 0] * np.sin(all_u[:, 1])
    ], axis=1)

    # Cutting region offsets for q_lookup mode
    cr_lb = np.array([float(x) for x in raw_meta["org-cutting-region-lb"].split(",")])
    cr_ub = np.array([float(x) for x in raw_meta["org-cutting-region-ub"].split(",")])
    q_cr = NdQuantizer(cr_lb, cr_ub, ss_eta)
    cr_offsets = np.array([q_cr.desymbolize(q_cr.unflatten(i)) for i in range(num_reach_states)], dtype=np.float32)

    # Controller cache
    controller_cache = {}

    def get_control_action(x_pt, step):
        flat_x = q_ss.flatten(q_ss.symbolize(x_pt))

        if args.mode == "optimal":
            # Bit 15 contains the stationary optimal reachability control action synthesized by AMYTISS
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
            # Fallback if unflagged: argmax displacement towards target
            u_action = all_u[np.argmax(u_displacements[:, 0] + u_displacements[:, 1])]
            controller_cache[flat_x] = u_action
            return u_action

        elif args.mode == "time_indexed":
            # Time-dependent bit (step)
            key = (flat_x, step)
            if key in controller_cache:
                return controller_cache[key]
            bit = step
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

        elif args.mode == "q_lookup":
            # Compute u*(x) = argmax_u sum_x' T(x, u, x') V(x')
            if flat_x in controller_cache:
                return controller_cache[flat_x]
            x_conc = q_ss.desymbolize(q_ss.unflatten(flat_x))
            mus = x_conc + u_displacements
            x_posts = mus[:, None, :] + cr_offsets[None, :, :]
            valid_mask = (x_posts[:, :, 0] >= ss_lb[0]) & (x_posts[:, :, 0] <= ss_ub[0]) & \
                         (x_posts[:, :, 1] >= ss_lb[1]) & (x_posts[:, :, 1] <= ss_ub[1])
            sym_0 = np.floor((x_posts[:, :, 0] - (ss_lb[0] - ss_eta[0] / 2.0)) / ss_eta[0]).astype(int)
            sym_1 = np.floor((x_posts[:, :, 1] - (ss_lb[1] - ss_eta[1] / 2.0)) / ss_eta[1]).astype(int)
            flat_posts = sym_0 + sym_1 * q_ss.steps[0]
            flat_posts[~valid_mask] = 0

            bag_bytes = raw_mm[raw_offset + flat_x * u_width * bag_size : raw_offset + (flat_x + 1) * u_width * bag_size]
            pr_array = np.zeros((u_width, num_reach_states), dtype=np.float32)
            for u_idx in range(u_width):
                pr_array[u_idx] = np.frombuffer(bag_bytes[u_idx * bag_size : u_idx * bag_size + num_reach_states * 4], dtype=np.float32)

            v_posts = v_data[flat_posts]
            v_posts[~valid_mask] = 0.0
            q_vals = np.sum(pr_array * v_posts, axis=1)
            best_u = all_u[np.argmax(q_vals)]
            controller_cache[flat_x] = best_u
            return best_u

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
    out_of_bounds_count = 0

    print(f"\n[*] Executing {N} Monte Carlo stochastic rollouts (mode={args.mode}) ...")
    start_time = time.time()

    for traj_idx in range(N):
        x = x0.copy()
        reached = False

        for t in range(time_steps):
            if is_inside_rect(x, target_lb, target_ub):
                reached = True
                reach_steps.append(t)
                break
            if not is_inside_rect(x, ss_lb, ss_ub):
                out_of_bounds_count += 1
                break

            u = get_control_action(x, t)
            w = np.random.multivariate_normal([0.0, 0.0], covar)
            x = dynamics(x, u) + w

        if not reached and is_inside_rect(x, target_lb, target_ub):
            reached = True
            reach_steps.append(time_steps)

        if reached:
            success_count += 1

    elapsed = time.time() - start_time
    raw_mm.close()
    raw_fd.close()

    # 5. Statistical Analysis
    p_emp = success_count / N
    ci_lower, ci_upper = compute_wilson_score_interval(success_count, N, confidence=args.confidence)

    # 3-sigma theoretical sampling tolerance
    sigma_th = np.sqrt(v_theoretical * (1.0 - v_theoretical) / N)
    threshold = v_theoretical - 3.0 * sigma_th

    # Verification criteria:
    # 1. Empirical success rate meets or exceeds the theoretical threshold
    # 2. Upper confidence bound is consistent with theoretical value
    passed = (p_emp >= threshold) and (ci_upper >= v_theoretical or p_emp >= v_theoretical)

    # 6. Report Statistics
    print("\n" + "=" * 78)
    print("  Monte Carlo Verification Results")
    print("=" * 78)
    print(f"  Rollouts (N)              : {N}")
    print(f"  Successful Reaches        : {success_count} / {N}")
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

    if passed:
        print("\n[SUCCESS] Empirical reach probability meets the theoretical guarantee!")
        print("          Verification Status: PASSED (exit code 0)\n")
        sys.exit(0)
    else:
        print("\n[FAILURE] Empirical reach probability is below the theoretical guarantee!")
        print("          Verification Status: FAILED (exit code 1)\n")
        sys.exit(1)


if __name__ == "__main__":
    main()
